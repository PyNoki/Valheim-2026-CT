using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class TamingV1 {
  internal static bool Enabled;
  internal static TamingDriverV1 Driver;
  static Player owner;static long world;static ZDO[] scan;static int cursor;
  static readonly Dictionary<string,ZDO> animals=new Dictionary<string,ZDO>();
  static readonly Dictionary<string,Minimap.PinData> pins=new Dictionary<string,Minimap.PinData>();
  static Minimap pinMap;static float nextUpdate;
  static string catalogue="",status="Ready. Refresh tamed animals, then return to Valheim and unpause.";
  const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  public static string Catalogue(){return catalogue;}
  public static string Status(){return status;}
  public static void Stop(){Enabled=false;}
  public static string EnableHotkey(Player player){
   if(Driver&&(!ReferenceEquals(owner,player)||world!=ZNet.instance.GetWorldUID()))throw new InvalidOperationException("Wait one game frame for the previous taming session to close.");
   owner=player;world=ZNet.instance.GetWorldUID();Enabled=true;
   if(!Driver)Driver=new GameObject("AdminToolkit_Taming").AddComponent<TamingDriverV1>();
   status="middle mouse taming enabled. Aim at a native tameable creature within 10m and press middle mouse in Valheim.";return status;
  }
  internal static void Hotkey(){
   if(!Enabled||!owner||owner!=Player.m_localPlayer||owner.IsDead()||!Application.isFocused||owner.IsTeleporting()
    ||Menu.IsVisible()||InventoryGui.IsVisible()||Console.IsVisible()||Minimap.IsOpen()||(Chat.instance&&Chat.instance.HasFocus())||!Input.GetMouseButtonDown(2))return;
   string result;
   try{result=TameAimed(owner);}catch(Exception error){result="Taming: "+error.GetBaseException().Message;}
   status=result;owner.Message(MessageHud.MessageType.TopLeft,result);
  }
  public static void Refresh(Player player){
   if(Driver && (!ReferenceEquals(owner,player)||world!=ZNet.instance.GetWorldUID()))throw new InvalidOperationException("Wait one game frame for the previous taming session to close.");
   var field=typeof(ZDOMan).GetField("m_objectsByID",Flags);
   if(field==null)throw new MissingFieldException("World object dictionary changed.");
   var objects=field.GetValue(ZDOMan.instance) as IDictionary;
   if(objects==null)throw new InvalidOperationException("World object records are unavailable.");
   scan=new ZDO[objects.Count];objects.Values.CopyTo(scan,0);cursor=0;animals.Clear();catalogue="";
   owner=player;world=ZNet.instance.GetWorldUID();Enabled=true;
   if(!Driver)Driver=new GameObject("AdminToolkit_Taming").AddComponent<TamingDriverV1>();
   status="Scanning "+scan.Length+" known world objects. Return to Valheim and unpause.";
  }
  static string Clean(string text){return (text??"").Replace('|',' ').Replace('\n',' ').Replace('\r',' ');}
  static string Name(ZDO zdo){
   var name=zdo.GetString(ZDOVars.s_tamedName,"");
   if(!string.IsNullOrEmpty(name))return Clean(name);
   var prefab=ZNetScene.instance.GetPrefab(zdo.GetPrefab());
   return Clean(prefab?prefab.name:"Unnamed tamed creature");
  }
  static bool Valid(ZDO zdo){return zdo!=null&&ReferenceEquals(ZDOMan.instance.GetZDO(zdo.m_uid),zdo)&&zdo.GetBool(ZDOVars.s_tamed,false);}
  static void ClearPins(){if(pinMap&&pinMap==Minimap.instance)foreach(var pin in pins.Values)pinMap.RemovePin(pin);pins.Clear();pinMap=null;}
  static void Publish(){
   if(!Minimap.instance)return;
   if(pinMap!=Minimap.instance){pins.Clear();pinMap=Minimap.instance;}
   var lines=new List<string>();var current=new HashSet<string>();
   foreach(var pair in animals){
    var zdo=pair.Value;if(!Valid(zdo))continue;current.Add(pair.Key);
    Vector3 point=zdo.GetPosition();string name=Name(zdo);Minimap.PinData pin;
    if(!pins.TryGetValue(pair.Key,out pin)){pin=pinMap.AddPin(point,Minimap.PinType.Icon3,"Tamed: "+name,false,false);pins[pair.Key]=pin;}
    else {pin.m_pos=point;pin.m_name="Tamed: "+name;}
    lines.Add(pair.Key+"|"+name+"|"+point.x.ToString("F1",CultureInfo.InvariantCulture)+"|"+point.y.ToString("F1",CultureInfo.InvariantCulture)+"|"+point.z.ToString("F1",CultureInfo.InvariantCulture));
   }
   var stale=new List<string>();foreach(var key in pins.Keys)if(!current.Contains(key))stale.Add(key);
   foreach(var key in stale){pinMap.RemovePin(pins[key]);pins.Remove(key);}
   lines.Sort(StringComparer.OrdinalIgnoreCase);catalogue=string.Join("\n",lines.ToArray());
   status="Located "+lines.Count+" known tamed animals. Temporary map pins are visible; remote clients may not know unseen distant animals.";
  }
  internal static void Tick(){
   if(!Enabled||!owner||owner!=Player.m_localPlayer||!ZNet.instance||ZNet.instance.GetWorldUID()!=world){ClearPins();animals.Clear();scan=null;catalogue="";Enabled=false;if(Driver)UnityEngine.Object.Destroy(Driver.gameObject);return;}
   if(scan!=null){
    int end=Math.Min(scan.Length,cursor+1024);
    while(cursor<end){var zdo=scan[cursor++];if(!Valid(zdo))continue;var prefab=ZNetScene.instance.GetPrefab(zdo.GetPrefab());if(!prefab||!prefab.GetComponent<Character>()||prefab.GetComponent<Player>())continue;animals[zdo.m_uid.ToString()]=zdo;}
    status="Scanning known animal records: "+cursor+"/"+scan.Length+"; "+animals.Count+" tamed creatures found.";
    if(cursor==scan.Length){scan=null;nextUpdate=0;}
   }
   if(scan==null&&Time.time>=nextUpdate){Publish();nextUpdate=Time.time+1f;}
  }
  public static string Bring(Player player,string key,Vector3 point){
   if(!ReferenceEquals(player,owner)||!ZNet.instance||world!=ZNet.instance.GetWorldUID())throw new InvalidOperationException("Refresh animals in this world first.");
   ZDO zdo;if(key==null||!animals.TryGetValue(key,out zdo)||!Valid(zdo))throw new InvalidOperationException("Selected animal changed, died or is no longer tamed. Refresh animals.");
   var instance=ZNetScene.instance.FindInstance(zdo.m_uid);var creature=instance?instance.GetComponent<Character>():null;
   if(creature&&creature.IsDead())throw new InvalidOperationException("Selected animal is dead.");
   var view=instance?instance.GetComponent<ZNetView>():null;
   if(view){if(!view.IsOwner())view.ClaimOwnership();if(!view.IsOwner())throw new InvalidOperationException("Animal ownership is not ready. Try again shortly.");}
   else zdo.SetOwner(ZDOMan.GetSessionID());
   string name=Name(zdo);zdo.Set(ZDOVars.s_spawnPoint,point);zdo.SetPosition(point);
   zdo.Set(ZDOVars.s_bodyVelHash,Vector3.zero);zdo.Set(ZDOVars.s_bodyAVelHash,Vector3.zero);zdo.Set(ZDOVars.s_velHash,Vector3.zero);
   if(instance){
    instance.transform.position=point;var body=instance.GetComponent<Rigidbody>();if(body){body.position=point;body.linearVelocity=Vector3.zero;body.angularVelocity=Vector3.zero;}
    var ai=instance.GetComponent<BaseAI>();if(ai){var spawn=typeof(BaseAI).GetField("m_spawnPoint",Flags);if(spawn!=null&&spawn.FieldType==typeof(Vector3))spawn.SetValue(ai,point);typeof(BaseAI).GetMethod("ResetPatrolPoint",Flags).Invoke(ai,null);}
    var sync=instance.GetComponent<ZSyncTransform>();if(sync)sync.SyncNow();
   }
   ZDOMan.instance.ForceSendZDO(zdo.m_uid);nextUpdate=0;
   return "Moved "+name+" beside you using its existing network object. Confirm arrival; server synchronization may take a moment.";
  }
  public static string TameAimed(Player player){
   Character creature=player.GetHoverCreature();
   if(!creature){
    Vector3 eye=player.GetEyePoint();float nearest=10f;
    foreach(var hit in Physics.RaycastAll(eye,player.GetAimDir(eye),10f,~0,QueryTriggerInteraction.Ignore)){
     if(!hit.collider||hit.collider.GetComponentInParent<Character>()==player||hit.distance>nearest)continue;
     nearest=hit.distance;creature=hit.collider.GetComponentInParent<Character>();
    }
   }
   if(!creature||creature==player||creature.IsDead()||Vector3.Distance(creature.transform.position,player.transform.position)>10f)throw new InvalidOperationException("Aim at a live tameable creature within 10m and press middle mouse in game.");
   var tameable=creature.GetComponent<Tameable>();var view=creature.GetComponent<ZNetView>();
   if(!tameable||!creature.GetComponent<MonsterAI>()||!view||!view.IsValid())throw new InvalidOperationException("This creature has no native taming support.");
   if(tameable.IsTamed())return "This creature is already tamed.";
   if(!view.IsOwner())view.ClaimOwnership();if(!view.IsOwner())throw new InvalidOperationException("Creature ownership is not ready. Try again shortly.");
   typeof(Tameable).GetMethod("Tame",Flags).Invoke(tameable,null);if(!tameable.IsTamed())throw new InvalidOperationException("Game did not confirm taming. Try again after ownership settles.");
   return "Tamed "+creature.GetHoverName()+". Refresh tamed animals to list it and add its map pin.";
  }
 }
 public sealed class TamingDriverV1:MonoBehaviour {
  void Update(){try{TamingV1.Tick();TamingV1.Hotkey();}catch(Exception e){Debug.LogWarning("Taming tools: "+e);TamingV1.Stop();}}
  void OnDestroy(){if(TamingV1.Driver==this)TamingV1.Driver=null;}
 }
}
