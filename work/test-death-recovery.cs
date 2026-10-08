// Execute the production recovery helper against a controlled world, without loading Unity.
using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object { public static implicit operator bool(Object o) { return o != null; } }
 public class Component : Object { public Transform transform = new Transform(); public T GetComponent<T>() where T:class { return null; } }
 public class GameObject : Component { public string name = "Player_tombstone"; public Container container; public new T GetComponent<T>() where T:class { return container as T; } }
 public class Transform { public Vector3 position, forward = Vector3.right; public Quaternion rotation; }
 public struct Vector3 {
  public float x,y,z; public Vector3(float a,float b,float c) { x=a;y=b;z=c; }
  public static Vector3 up { get { return new Vector3(0,1,0); } } public static Vector3 right { get { return new Vector3(1,0,0); } } public static Vector3 down { get { return new Vector3(0,-1,0); } } public static Vector3 zero { get { return new Vector3(); } }
  public static Vector3 operator +(Vector3 a,Vector3 b) { return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z); }
  public static Vector3 operator *(Vector3 a,float b) { return new Vector3(a.x*b,a.y*b,a.z*b); }
 }
 public struct Quaternion { public static Quaternion Euler(float a,float b,float c) { return new Quaternion(); } public static Vector3 operator *(Quaternion q,Vector3 v) { return v; } }
 public class Rigidbody:Component { public Vector3 position,linearVelocity,angularVelocity; }
 public struct RaycastHit { public Vector3 point,normal; }
 public enum QueryTriggerInteraction { Ignore }
 public static class LayerMask { public static int GetMask(params string[] a) { return 1; } }
 public static class Physics {
  public static bool ground=true;
  public static bool Raycast(Vector3 start,Vector3 dir,out RaycastHit hit,float distance,int mask,QueryTriggerInteraction q) { hit=new RaycastHit {point=new Vector3(start.x,0,start.z),normal=Vector3.up}; return ground; }
  public static bool CheckSphere(Vector3 p,float r,int mask,QueryTriggerInteraction q) { return false; }
 }
}
public class Player:Component {
 public static Player m_localPlayer; public GameObject m_tombstone=new GameObject(); public bool dead,teleporting,accept=true;
 public bool IsDead() { return dead; } public bool IsTeleporting() { return teleporting; }
 public bool TeleportTo(Vector3 p,Quaternion q,bool distant) { if(!accept)return false; transform.position=p; teleporting=true; return true; }
}
public class PlayerProfile { public long id=42; public bool have=true; public Vector3 death=new Vector3(100,10,100); public long GetPlayerID(){return id;} public bool HaveDeathPoint(){return have;} public Vector3 GetDeathPoint(){return death;} }
public class Game { public static Game instance=new Game(); public PlayerProfile profile=new PlayerProfile(); public PlayerProfile GetPlayerProfile(){return profile;} }
public class ZNet:UnityEngine.Object { public static ZNet instance=new ZNet(); public long world=1; public bool server=true; public long GetWorldUID(){return world;} public bool IsServer(){return server;} }
public static class ZDOVars { public const int s_owner=1,s_timeOfDeath=2,s_spawnPoint=3,s_bodyVelHash=4,s_bodyAVelHash=5,s_velHash=6; }
public class ZDO {
 public int m_uid; public long owner,time,networkOwner; public Vector3 position,spawn; public string inventory="valuable contents";
 public long GetLong(int key,long fallback){return key==1?owner:time;}
 public Vector3 GetPosition(){return position;} public void SetPosition(Vector3 p){position=p;} public void SetOwner(long id){networkOwner=id;} public void Set(int key,Vector3 p){if(key==3)spawn=p;}
}
public class ZDOMan {
 public static ZDOMan instance=new ZDOMan(); public List<ZDO> stones=new List<ZDO>(); public bool delay;
 public static long GetSessionID(){return 7;}
 public ZDO GetZDO(int id){return stones.Find(x=>x.m_uid==id);}
 public bool GetAllZDOsWithPrefabIterative(string name,List<ZDO> list,ref int index){if(delay && index++==0)return false;list.AddRange(stones);return true;}
}
public class ZNetScene { public static ZNetScene instance=new ZNetScene(); public GameObject loaded; public GameObject FindInstance(int id){return loaded;} }
public class Container:Component { public bool inUse; public bool IsInUse(){return inUse;} }
public class ZSyncTransform:Component { public void SyncNow(){} }
public static class Utils { public static float DistanceXZ(Vector3 a,Vector3 b){return (float)Math.Sqrt((a.x-b.x)*(a.x-b.x)+(a.z-b.z)*(a.z-b.z));} }
class Test {
 static Player p;
 static void Check(bool result,string reason){if(!result)throw new Exception(reason+": "+DeathRecoveryV2.GetStatus());}
 static void Reset(){DeathRecoveryV2.Cancel();p=new Player();Player.m_localPlayer=p;ZNet.instance=new ZNet();Game.instance=new Game();ZDOMan.instance=new ZDOMan();ZNetScene.instance=new ZNetScene();Physics.ground=true;}
 static ZDO Stone(int id,long owner,long time){var s=new ZDO{m_uid=id,owner=owner,time=time,position=new Vector3(500,0,500),spawn=new Vector3(500,0,500)};ZDOMan.instance.stones.Add(s);return s;}
 static void Run(int mode){DeathRecoveryV2.Queue(p,mode,"0100000000000000");DeathRecoveryV2.Tick(p);}
 static void Failed(string message){Check(DeathRecoveryV2.GetState()==4 && DeathRecoveryV2.GetStatus().Contains(message),message);}
 static void Main(){
  Reset();Run(1);Check(p.teleporting && p.transform.position.x==100,"last death");p.teleporting=false;DeathRecoveryV2.Tick(p);Check(DeathRecoveryV2.GetState()==3,"arrival");
  Reset();Game.instance.profile.have=false;Run(1);Failed("No death location");
  Reset();p.accept=false;Run(1);Failed("declined");
  Reset();Run(3);Failed("No remaining tombstone");
  Reset();var old=Stone(1,42,10);var other=Stone(2,77,99);var latest=Stone(3,42,20);Run(3);
  Check(DeathRecoveryV2.GetState()==3 && latest.position.x==3 && latest.spawn.x==3,"latest own stone moves and resets spawn");
  Check(latest.inventory=="valuable contents" && ReferenceEquals(latest,ZDOMan.instance.GetZDO(3)) && ZDOMan.instance.stones.Count==3,"same object inventory intact");
  Check(old.position.x==500 && other.position.x==500 && Game.instance.profile.death.x==100,"other stones and death marker unchanged");
  Reset();latest=Stone(1,42,20);Run(2);Check(p.teleporting && p.transform.position.x==502 && latest.position.x==500,"teleport beside stone");
  Reset();latest=Stone(1,42,20);ZNet.instance.server=false;Run(3);Failed("solo world");Check(latest.position.x==500 && latest.networkOwner==0,"remote mutation denied");
  Reset();latest=Stone(1,42,20);Physics.ground=false;Run(3);Failed("No clear landing");Check(latest.position.x==500,"no unsafe landing mutation");
  Reset();Stone(1,42,20);ZNetScene.instance.loaded=new GameObject{container=new Container{inUse=true}};Run(3);Failed("currently open");
  Reset();ZNet.instance.world=2;Run(1);Failed("changed");
  Reset();p.dead=true;Run(1);Failed("died");
  // Respawning replaces the Player object while retaining the same profile/world.
  p=new Player();Player.m_localPlayer=p;Run(1);Check(p.teleporting,"new request after death and respawn");
  Reset();DeathRecoveryV2.Queue(p,1,"0100000000000000");p=new Player();Player.m_localPlayer=p;DeathRecoveryV2.Tick(p);Failed("Player reference changed");
  Run(1);Check(p.teleporting,"fresh request after stale pre-respawn request");
  Reset();latest=Stone(1,42,20);ZDOMan.instance.delay=true;Run(3);Check(DeathRecoveryV2.GetState()==1,"incremental scan");DeathRecoveryV2.Cancel();DeathRecoveryV2.Tick(p);Check(latest.position.x==500,"cancel prevents movement");
  Reset();latest=Stone(1,42,20);ZDOMan.instance.delay=true;Run(3);Game.instance.profile.id=99;DeathRecoveryV2.Tick(p);Failed("Character changed");Check(latest.position.x==500,"character change prevents movement");
  Console.WriteLine("PASS: recovery destinations, latest character-owned selection, same-object inventory preservation, spawn reset, remote authority, landing/in-use guards, cancellation, death/world/character changes.");
 }
}
