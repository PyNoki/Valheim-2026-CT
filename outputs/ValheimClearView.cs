using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class ClearViewV1 {
  static ClearViewDriver driver;public static int Enabled;public static string Status="Clear weather disabled.";
  public static void Stop(){Enabled=0;if(driver!=null)driver.Cancelled=true;}
  public static string Toggle(Player p){if(Enabled==1){Stop();return Status="Clear weather disabled; restoring environment.";}if(driver){driver.Release();UnityEngine.Object.Destroy(driver.gameObject);driver=null;}driver=new GameObject("Toolkit_ClearView").AddComponent<ClearViewDriver>();driver.Owner=p;driver.World=ZNet.instance.GetWorldUID();try{driver.Prepare();}catch{UnityEngine.Object.Destroy(driver.gameObject);driver=null;throw;}Enabled=1;return Status="Clear weather active: rain, fog and mist hidden locally.";}
 }
 public sealed class ClearViewDriver:MonoBehaviour {
  public Player Owner;public long World;public volatile bool Cancelled;
  EnvMan environment;string previous;EnvSetup clear;float[] densities;bool fog;float density;float scan;
  readonly Dictionary<Renderer,bool> renderers=new Dictionary<Renderer,bool>();
  public void Prepare(){fog=RenderSettings.fog;density=RenderSettings.fogDensity;environment=EnvMan.instance;previous=environment.m_debugEnv;clear=(EnvSetup)typeof(EnvMan).GetMethod("GetEnv",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).Invoke(environment,new object[]{"Clear"});if(clear==null)throw new InvalidOperationException("Clear environment unavailable.");previous=environment.m_debugEnv;densities=new[]{clear.m_fogDensityNight,clear.m_fogDensityMorning,clear.m_fogDensityDay,clear.m_fogDensityEvening};fog=RenderSettings.fog;density=RenderSettings.fogDensity;Apply();}
  void Apply(){clear.m_fogDensityNight=clear.m_fogDensityMorning=clear.m_fogDensityDay=clear.m_fogDensityEvening=0;environment.m_debugEnv="Clear";environment.ForceInstantEnvironmentSwitch();}
  void LateUpdate(){try{
   if(Cancelled||!Owner||Owner!=Player.m_localPlayer||Owner.IsDead()||!ZNet.instance||ZNet.instance.GetWorldUID()!=World){Restore();Destroy(gameObject);return;}
   if(environment!=EnvMan.instance){Restore();Destroy(gameObject);return;}
   environment.m_debugEnv="Clear";RenderSettings.fog=false;RenderSettings.fogDensity=0;
   if(Time.time>=scan){scan=Time.time+1;
    foreach(var mist in UnityEngine.Object.FindObjectsByType<ParticleMist>(FindObjectsSortMode.None))Hide(mist,"m_ps");
    foreach(var mist in UnityEngine.Object.FindObjectsByType<MistEmitter>(FindObjectsSortMode.None))Hide(mist,"m_psystem");
   }
   foreach(var entry in renderers)if(entry.Key)entry.Key.enabled=false;
  }catch(Exception e){Restore();ClearViewV1.Status="Clear weather stopped: "+e.GetBaseException().Message;Destroy(gameObject);}}
  void Hide(Component mist,string field){var ps=mist.GetType().GetField(field,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).GetValue(mist) as ParticleSystem;if(!ps)return;foreach(var renderer in ps.GetComponentsInChildren<Renderer>(true))if(renderer&&!renderers.ContainsKey(renderer))renderers.Add(renderer,renderer.enabled);}
  public void Release(){Restore();}
  bool restored;
  void Restore(){if(restored)return;restored=true;if(clear!=null&&densities!=null){clear.m_fogDensityNight=densities[0];clear.m_fogDensityMorning=densities[1];clear.m_fogDensityDay=densities[2];clear.m_fogDensityEvening=densities[3];}if(environment&&environment==EnvMan.instance){environment.m_debugEnv=previous;environment.ForceInstantEnvironmentSwitch();}RenderSettings.fog=fog;RenderSettings.fogDensity=density;foreach(var entry in renderers)if(entry.Key)entry.Key.enabled=entry.Value;renderers.Clear();ClearViewV1.Enabled=0;ClearViewV1.Status="Clear weather disabled; normal visibility restored.";}
  void OnDestroy(){Restore();}
 }
}
