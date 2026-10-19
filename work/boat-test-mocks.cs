using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public bool destroyed;public static implicit operator bool(Object o){return o!=null&&!o.destroyed;}public static void Destroy(Object o){if(!o)return;if(o is Component){var component=(Component)o;var callback=component.GetType().GetMethod("OnDestroy",BindingFlags.NonPublic|BindingFlags.Instance);if(callback!=null)callback.Invoke(component,null);}var go=o as GameObject;if(go!=null)foreach(var c in go.components){var method=c.GetType().GetMethod("OnDestroy",BindingFlags.NonPublic|BindingFlags.Instance);if(method!=null)method.Invoke(c,null);c.destroyed=true;}o.destroyed=true;}}
 public class Component:Object {public GameObject gameObject;public Transform transform{get{return gameObject.transform;}}public T GetComponent<T>()where T:class{return gameObject.GetComponent<T>();}public T GetComponentInParent<T>()where T:class{var current=gameObject.transform;while(current!=null){var result=current.gameObject.GetComponent<T>();if(result!=null)return result;current=current.parent;}return null;}public T[] GetComponentsInChildren<T>(bool inactive)where T:class{return gameObject.GetComponentsInChildren<T>();}}
 public class MonoBehaviour:Component {public bool enabled=true;}
 public class GameObject:Object {
  public string name;public List<Component> components=new List<Component>();public Transform transform;
  public GameObject(string name){this.name=name;transform=new Transform{gameObject=this};}
  public T AddComponent<T>()where T:Component,new(){var c=new T{gameObject=this};components.Add(c);return c;}
  public T GetComponent<T>()where T:class{if(transform is T)return transform as T;foreach(var c in components)if(c is T&&c)return c as T;return null;}
  public T GetComponentInParent<T>()where T:class{return transform.GetComponentInParent<T>();}
  public T[] GetComponentsInChildren<T>()where T:class{var values=new List<T>();foreach(var c in components)if(c is T&&c)values.Add(c as T);foreach(var child in transform.children)values.AddRange(child.gameObject.GetComponentsInChildren<T>());return values.ToArray();}
 }
 public class Transform:Component {
  public Transform parent;public List<Transform> children=new List<Transform>();public Vector3 localPosition;public Quaternion rotation;public Vector3 forward=new Vector3(0,0,1);
  public Vector3 position {get{return parent!=null?parent.position+localPosition:localPosition;}set{localPosition=parent!=null?value-parent.position:value;}}
  public void SetParent(Transform value,bool world){Vector3 position=this.position;if(parent!=null)parent.children.Remove(this);parent=value;if(value!=null)value.children.Add(this);if(world)this.position=position;}
  public bool IsChildOf(Transform value){for(var current=this;current!=null;current=current.parent)if(current==value)return true;return false;}
 }
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}public static float Distance(Vector3 a,Vector3 b){return (a-b).magnitude;}public float magnitude{get{return (float)Math.Sqrt(x*x+y*y+z*z);}}public static Vector3 zero{get{return new Vector3();}}public static Vector3 operator-(Vector3 a,Vector3 b){return new Vector3(a.x-b.x,a.y-b.y,a.z-b.z);}public static Vector3 up{get{return new Vector3(0,1,0);}}public static Vector3 down{get{return new Vector3(0,-1,0);}}public Vector3 normalized{get{float n=(float)Math.Sqrt(x*x+y*y+z*z);return n>0?new Vector3(x/n,y/n,z/n):new Vector3();}}public static Vector3 operator+(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);}public static Vector3 operator*(Vector3 a,float b){return new Vector3(a.x*b,a.y*b,a.z*b);}public float sqrMagnitude{get{return x*x+y*y+z*z;}}public static float Dot(Vector3 a,Vector3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}public static Vector3 ProjectOnPlane(Vector3 v,Vector3 n){return v-n*(Dot(v,n)/Math.Max(0.000001f,n.sqrMagnitude));}public static Vector3 MoveTowards(Vector3 a,Vector3 b,float d){var delta=new Vector3(b.x-a.x,b.y-a.y,b.z-a.z);float length=(float)Math.Sqrt(delta.x*delta.x+delta.y*delta.y+delta.z*delta.z);return length<=d?b:a+delta.normalized*d;}}
 public struct Quaternion {public static Quaternion identity{get{return new Quaternion();}}public static Quaternion AngleAxis(float angle,Vector3 v){return new Quaternion();}public static Vector3 operator*(Quaternion q,Vector3 v){return v;}public static Quaternion LookRotation(Vector3 a,Vector3 b){return new Quaternion();}public static Quaternion RotateTowards(Quaternion a,Quaternion b,float c){return b;}}
 public class Rigidbody:Component {public bool isKinematic,useGravity=true;public Vector3 position{get{return transform.position;}set{transform.position=value;}}public Vector3 linearVelocity,angularVelocity;public Quaternion rotation{get{return transform.rotation;}set{transform.rotation=value;}}public void MovePosition(Vector3 value){position=value;}public Vector3 worldCenterOfMass{get{return position;}}public void MoveRotation(Quaternion q){rotation=q;}public void AddForce(Vector3 v,ForceMode mode){linearVelocity=linearVelocity+v*Time.fixedDeltaTime;}}
 public enum ForceMode {Acceleration}
 public struct Bounds {public Vector3 center,extents;public Bounds(Vector3 center,Vector3 size){this.center=center;extents=size*0.5f;}public Vector3 min{get{return center-extents;}}public Vector3 max{get{return center+extents;}}public void Encapsulate(Bounds other){var a=min;var b=max;var c=other.min;var d=other.max;a=new Vector3(Math.Min(a.x,c.x),Math.Min(a.y,c.y),Math.Min(a.z,c.z));b=new Vector3(Math.Max(b.x,d.x),Math.Max(b.y,d.y),Math.Max(b.z,d.z));center=(a+b)*0.5f;extents=(b-a)*0.5f;}}
 public class Collider:Component {public bool enabled=true,isTrigger;public Bounds localBounds=new Bounds(new Vector3(0,0.5f,0),new Vector3(3,1,1));public Bounds bounds{get{return new Bounds(transform.position+localBounds.center,localBounds.extents*2);}}}
 public class WaterVolume {}
 public struct RaycastHit {public Vector3 point,normal;public Collider collider;public float distance;}
 public static class Physics {public static bool ground,floor=true,wall,initialGround;public static int wallCasts;public static Collider groundCollider=new GameObject("terrain").AddComponent<Collider>(),wallCollider=new GameObject("wall").AddComponent<Collider>();
 public static RaycastHit[] RaycastAll(Vector3 p,Vector3 d,float distance,int mask,QueryTriggerInteraction trigger){return floor?new[]{new RaycastHit{point=new Vector3(p.x,0,p.z),normal=Vector3.up,collider=groundCollider,distance=p.y}}:new RaycastHit[0];}
 public static RaycastHit[] BoxCastAll(Vector3 p,Vector3 extents,Vector3 direction,Quaternion rot,float distance,int mask,QueryTriggerInteraction trigger){if(initialGround)return new[]{new RaycastHit{point=p,normal=new Vector3(0,-1,0),collider=groundCollider,distance=0}};if(wall&&direction.z>0.0001f){wallCasts++;return new[]{new RaycastHit{point=p,normal=new Vector3(0,0,-1),collider=wallCollider,distance=0.025f}};}return new RaycastHit[0];}
 public static bool ComputePenetration(Collider a,Vector3 ap,Quaternion ar,Collider b,Vector3 bp,Quaternion br,out Vector3 outward,out float depth){outward=Vector3.up;depth=0.01f;return initialGround&&b==groundCollider;}
 public static bool Raycast(Vector3 p,Vector3 d,out RaycastHit hit,float length,int mask,QueryTriggerInteraction trigger){hit=new RaycastHit();return ground;}}
 public static class LayerMask {public static int GetMask(params string[] values){return 1;}}
 public enum QueryTriggerInteraction {Ignore}
 public static class Time {public static float fixedDeltaTime=0.1f;}
 public static class Mathf {public static float Abs(float value){return Math.Abs(value);}public static float MoveTowards(float a,float b,float step){return Math.Abs(b-a)<=step?b:a+Math.Sign(b-a)*step;}}
 public static class Application {public static bool isFocused=true;}
 public enum KeyCode {LeftControl,LeftShift,RightShift,A,D,Space}
 public static class Input {public static HashSet<KeyCode> keys=new HashSet<KeyCode>();public static bool GetKey(KeyCode key){return keys.Contains(key);}}
}
public class WearNTear:MonoBehaviour {public float health=137;public bool Damage(float amount){if(BoatFunV5.Protects(this))return false;health-=amount;return true;}}
public class ZDO {public Vector3 position;public Quaternion rotation;public void SetPosition(Vector3 value){position=value;}public void SetRotation(Quaternion value){rotation=value;}}
public class ZSyncTransform:MonoBehaviour {public bool m_syncPosition,m_syncRotation;}
public class Piece:MonoBehaviour {}
public class Chair:MonoBehaviour {public Transform m_attachPoint;public bool occupied;public bool IsInUse(){return occupied;}}
public static class PrivateArea {public static bool allowed=true;public static bool CheckAccess(Vector3 p,float r,bool a,bool b){return allowed;}}
public interface IDoodadController {void OnUseStop(Player p);void ApplyControlls(Vector3 move,Vector3 look,bool run,bool autoRun,bool block);Component GetControlledComponent();Vector3 GetPosition();bool IsValid();}
public class ZNetView:MonoBehaviour {public ZDO zdo=new ZDO();public ZDO GetZDO(){return zdo;}public bool owned=true;public bool IsOwner(){return owned;}public bool IsValid(){return true;}}
public class Ship:MonoBehaviour {public static Ship local;public static Ship GetLocalShip(){return local;}public bool IsOwner(){return GetComponent<ZNetView>().IsOwner();}public float m_sailForceFactor=1,m_dampingSideway=2,m_dampingForward=3,m_stearForce=4,m_stearVelForceFactor=5,m_backwardForce=6,m_waterImpactDamage=7,m_upsideDownDmg=8,m_force=20,m_waterLevelOffset=1;public Collider m_floatCollider;public enum Speed{Full,Stop}public Speed speed=Speed.Full;public Speed GetSpeedSetting(){return speed;}}
public class Character:MonoBehaviour {public float m_maxAirAltitude,m_fallTimer;}
public static class ZInput {public static HashSet<string> keys=new HashSet<string>();public static bool GetButton(string key){return keys.Contains(key);}}
public class Player:Character {public int nativeControls,jumps;public void NativeControls(bool jump){nativeControls++;if(jump){StopDoodadControl();AttachStop();jumps++;}}public GameObject hover;public Transform seat;public IDoodadController doodad;public GameObject GetHoverObject(){return hover;}public bool IsAttached(){return seat!=null;}public Transform GetAttachPoint(){return seat;}public IDoodadController GetDoodadController(){return doodad;}public void StartDoodadControl(IDoodadController value){doodad=value;}public void StopDoodadControl(){var previous=doodad;doodad=null;if(previous!=null)previous.OnUseStop(this);}public void AttachStop(){seat=null;}public void AttachStart(Transform point,GameObject o,bool a,bool b,bool c,string anim,Vector3 offset,Transform cam){seat=point;transform.position=point.position;}public static Player m_localPlayer;public Ship controlled;public bool dead,teleport;public bool IsDead(){return dead;}public bool IsTeleporting(){return teleport;}public Ship GetControlledShip(){return controlled;}}
public class ZNet:UnityEngine.Object {public static ZNet instance=new ZNet();public long world=1;public long GetWorldUID(){return world;}}
public static class Floating {public static float level=-10;public static float GetWaterLevel(Vector3 point,ref WaterVolume water){return level;}}
public static class Menu {public static bool visible;public static bool IsVisible(){return visible;}}
public static class InventoryGui {public static bool visible;public static bool IsVisible(){return visible;}}
public static class Console {public static bool IsVisible(){return false;}}
public static class Minimap {public static bool IsOpen(){return false;}}
public class Chat:UnityEngine.Object {public static Chat instance;public bool HasFocus(){return false;}}
