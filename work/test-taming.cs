using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public bool destroyed;public static implicit operator bool(Object o){return o!=null&&!o.destroyed;}public static void Destroy(Object o){o.destroyed=true;var go=o as GameObject;if(go!=null)foreach(var v in go.components.Values){var obj=v as Object;if(obj!=null)obj.destroyed=true;}}}
 public class Component:Object {public GameObject gameObject;public Transform transform{get{return gameObject.transform;}}public T GetComponent<T>() where T:class{return gameObject.GetComponent<T>();}}
 public class MonoBehaviour:Component {protected new static void Destroy(Object o){Object.Destroy(o);}}
 public class GameObject:Object {public string name;public Transform transform=new Transform();public Dictionary<Type,object> components=new Dictionary<Type,object>();public GameObject(string n){name=n;}public T AddComponent<T>() where T:Component,new(){var t=new T();t.gameObject=this;components[typeof(T)]=t;return t;}public T GetComponent<T>() where T:class{foreach(var v in components.Values)if(v is T)return v as T;return null;}}
 public class Transform {public Vector3 position,forward=new Vector3(0,0,1);}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}public static Vector3 zero{get{return new Vector3();}}public static float Distance(Vector3 a,Vector3 b){return (float)Math.Sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)+(a.z-b.z)*(a.z-b.z));}}
 public class Rigidbody:Component {public Vector3 position,linearVelocity,angularVelocity;}
 public class Collider:Component {public T GetComponentInParent<T>() where T:class{return GetComponent<T>();}}
 public struct RaycastHit {public Collider collider;public float distance;}
 public enum QueryTriggerInteraction {Ignore}
 public static class Physics {public static RaycastHit[] RaycastAll(Vector3 a,Vector3 b,float length,int mask,QueryTriggerInteraction q){return new RaycastHit[0];}}
 public static class Time {public static float time;}

 public static class Input {public static bool down;public static bool GetMouseButtonDown(int button){if(button!=2)throw new Exception("Taming must use wheel click");bool result=down;down=false;return result;}}
 public static class Application {public static bool isFocused=true;}
 public static class Debug {public static void LogWarning(object o){}}
}
public class Character:Component {public bool dead;public bool IsDead(){return dead;}public string GetHoverName(){return gameObject.name;}}
public class Player:Character {public static Player m_localPlayer;public string lastMessage;public bool teleporting;public bool IsTeleporting(){return teleporting;}public void Message(MessageHud.MessageType type,string text){lastMessage=text;}public Character hover;public Character GetHoverCreature(){return hover;}public Vector3 GetEyePoint(){return transform.position;}public Vector3 GetAimDir(Vector3 eye){return transform.forward;}}
public class MessageHud {public enum MessageType {TopLeft}}
public static class Menu {public static bool visible;public static bool IsVisible(){return visible;}}
public static class InventoryGui {public static bool IsVisible(){return false;}}
public static class Console {public static bool IsVisible(){return false;}public static void WriteLine(string text){System.Console.WriteLine(text);}}
public class Chat:UnityEngine.Object {public static Chat instance;public bool HasFocus(){return false;}}
public class BaseAI:Component {public Vector3 m_spawnPoint;public bool patrol=true;public void ResetPatrolPoint(){patrol=false;}}
public class MonsterAI:BaseAI {}
public class Tameable:Component {public bool tamed;public bool IsTamed(){return tamed;}private void Tame(){tamed=true;}}
public class ZNetView:Component {public bool owner=true,claim=true;public bool IsValid(){return true;}public bool IsOwner(){return owner;}public void ClaimOwnership(){if(claim)owner=true;}}
public class ZSyncTransform:Component {public int syncs;public void SyncNow(){syncs++;}}
public class ZNet:UnityEngine.Object {public static ZNet instance=new ZNet();public long world=1;public long GetWorldUID(){return world;}}
public static class ZDOVars {public const int s_tamed=1,s_tamedName=2,s_spawnPoint=3,s_bodyVelHash=4,s_bodyAVelHash=5,s_velHash=6;}
public class ZDO {public int m_uid,prefab;public bool tamed;public string name;public Vector3 position;public long owner;public bool GetBool(int k,bool fallback){return tamed;}public string GetString(int k,string fallback){return name??fallback;}public int GetPrefab(){return prefab;}public Vector3 GetPosition(){return position;}public void SetPosition(Vector3 p){position=p;}public void SetOwner(long o){owner=o;}public void Set(int k,Vector3 v){} }
public class ZDOMan {public static ZDOMan instance=new ZDOMan();public Dictionary<int,ZDO> m_objectsByID=new Dictionary<int,ZDO>();public int sends;public ZDO GetZDO(int id){ZDO z;return m_objectsByID.TryGetValue(id,out z)?z:null;}public static long GetSessionID(){return 7;}public void ForceSendZDO(int id){sends++;}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public Dictionary<int,GameObject> prefabs=new Dictionary<int,GameObject>(),loaded=new Dictionary<int,GameObject>();public GameObject GetPrefab(int id){GameObject go;return prefabs.TryGetValue(id,out go)?go:null;}public GameObject FindInstance(int id){GameObject go;return loaded.TryGetValue(id,out go)?go:null;}}
public class Minimap:UnityEngine.Object {public static bool IsOpen(){return false;}public static Minimap instance=new Minimap();public enum PinType {Icon3}public class PinData {public Vector3 m_pos;public string m_name;}public List<PinData> pins=new List<PinData>();public PinData AddPin(Vector3 p,PinType t,string name,bool save,bool check){if(save)throw new Exception("Markers must be temporary");var pin=new PinData{m_pos=p,m_name=name};pins.Add(pin);return pin;}public void RemovePin(PinData p){pins.Remove(p);}}
class TestTaming {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static bool Reject(Action a){try{a();return false;}catch(InvalidOperationException){return true;}}
 static void Main(){
  var p=new GameObject("Player").AddComponent<Player>();Player.m_localPlayer=p;
  var wolf=new GameObject("Wolf");wolf.AddComponent<Character>();ZNetScene.instance.prefabs[1]=wolf;
  var named=new ZDO{m_uid=1,prefab=1,tamed=true,name="Fluffy",position=new Vector3(100,0,100)};
  var unnamed=new ZDO{m_uid=2,prefab=1,tamed=true};var wild=new ZDO{m_uid=3,prefab=1,tamed=false};
  ZDOMan.instance.m_objectsByID[1]=named;ZDOMan.instance.m_objectsByID[2]=unnamed;ZDOMan.instance.m_objectsByID[3]=wild;
  var ownPin=Minimap.instance.AddPin(new Vector3(),Minimap.PinType.Icon3,"My marker",false,false);
  TamingV1.Refresh(p);TamingV1.Tick();
  Check(TamingV1.Catalogue().Contains("Fluffy")&&TamingV1.Catalogue().Contains("Wolf")&&Minimap.instance.pins.Count==3,"named/unnamed tame records get transient pins; wild excluded");
  var loaded=new GameObject("Wolf");loaded.AddComponent<Character>();loaded.AddComponent<ZNetView>();var ai=loaded.AddComponent<MonsterAI>();loaded.AddComponent<Rigidbody>();loaded.AddComponent<ZSyncTransform>();ZNetScene.instance.loaded[1]=loaded;
  TamingV1.Bring(p,"1",new Vector3(3,1,0));Check(ReferenceEquals(named,ZDOMan.instance.GetZDO(1))&&named.position.x==3&&named.name=="Fluffy"&&ZDOMan.instance.sends==1,"bring preserves existing object/name and publishes movement");
  Check(loaded.transform.position.x==3&&ai.m_spawnPoint.x==3&&!ai.patrol,"loaded animal and home point move; stale patrol cleared");
  named.tamed=false;Check(Reject(()=>TamingV1.Bring(p,"1",new Vector3())),"stale untamed target rejected");named.tamed=true;
  var creature=new GameObject("Boar").AddComponent<Character>();creature.gameObject.AddComponent<MonsterAI>();var tame=creature.gameObject.AddComponent<Tameable>();creature.gameObject.AddComponent<ZNetView>();p.hover=creature;
  Check(TamingV1.TameAimed(p).Contains("Tamed")&&tame.IsTamed(),"aimed creature uses native taming method");
  Check(TamingV1.TameAimed(p).Contains("already"),"already tamed not duplicated");
  tame.tamed=false;TamingV1.EnableHotkey(p);TamingV1.Hotkey();Check(!tame.tamed,"looking alone does not tame");
  Input.down=true;Menu.visible=true;TamingV1.Hotkey();Check(!tame.tamed,"menu blocks hotkey");Menu.visible=false;Input.down=false;
  Input.down=true;Application.isFocused=false;TamingV1.Hotkey();Check(!tame.tamed,"focus loss blocks hotkey");Application.isFocused=true;Input.down=false;
  Input.down=true;TamingV1.Hotkey();Check(tame.tamed&&p.lastMessage.Contains("Tamed"),"middle mouse press tames aimed creature with in-game feedback");
  p.hover=new GameObject("Non tameable").AddComponent<Character>();Check(Reject(()=>TamingV1.TameAimed(p)),"unsupported creature rejected");
  p.hover=creature;creature.transform.position=new Vector3(20,0,0);Check(Reject(()=>TamingV1.TameAimed(p)),"distant hover rejected");
  TamingV1.Stop();TamingV1.Tick();Check(Minimap.instance.pins.Count==1&&Minimap.instance.pins[0]==ownPin,"cleanup removes only toolkit pins");
  tame.tamed=false;p.hover=creature;creature.transform.position=new Vector3();Input.down=true;TamingV1.Hotkey();Check(!tame.tamed,"stopped mode disables middle mouse");
  TamingV1.Refresh(p);TamingV1.Tick();ZNet.instance.world=2;TamingV1.Tick();Check(Minimap.instance.pins.Count==1,"world change clears temporary markers");
  Console.WriteLine("PASS: named tame scan/pins, existing-object relocation, stale target guards, native hover taming, unsupported/distant rejection and pin/world cleanup.");
 }
}
