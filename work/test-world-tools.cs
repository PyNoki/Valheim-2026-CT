using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {
  public bool destroyed; public static List<Pickable> pickables=new List<Pickable>();
  public static implicit operator bool(Object o) { return o!=null && !o.destroyed; }
  public static void Destroy(Object o) { if(o!=null)o.destroyed=true; }
  public static GameObject Instantiate(GameObject prefab,Vector3 p,Quaternion q) { var g=new GameObject(prefab.name);g.transform.position=p;g.AddComponent<Character>();g.AddComponent<MonsterAI>();return g; }
  public static T[] FindObjectsByType<T>(FindObjectsSortMode mode) { return (T[])(object)pickables.ToArray(); }
 }
 public class Component:Object { public GameObject gameObject;public Transform transform { get { return gameObject.transform; } } public T GetComponent<T>() where T:class { return gameObject.GetComponent<T>(); } }
 public class MonoBehaviour:Component {}
 public class GameObject:Object {
  public string name;public bool activeSelf=true;public Transform transform=new Transform();private Dictionary<Type,object> components=new Dictionary<Type,object>();
  public GameObject(string n) { name=n; }
  public T AddComponent<T>() where T:Component,new() { var c=new T();c.gameObject=this;components[typeof(T)]=c;return c; }
  public T GetComponent<T>() where T:class { object c;return components.TryGetValue(typeof(T),out c)?(T)c:null; }
  public static GameObject CreatePrimitive(PrimitiveType t) { var g=new GameObject("sphere");g.AddComponent<Collider>();return g; }
 }
 public class Transform { public Vector3 position,localScale; public Vector3 right= new Vector3(1,0,0); }
 public struct Vector3 {
  public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}
  public static Vector3 zero {get{return new Vector3();}}public static Vector3 up {get{return new Vector3(0,1,0);}}public static Vector3 down {get{return new Vector3(0,-1,0);}}public static Vector3 one {get{return new Vector3(1,1,1);}}
  public static Vector3 operator+(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);}public static Vector3 operator*(Vector3 a,float v){return new Vector3(a.x*v,a.y*v,a.z*v);}
  public static float Distance(Vector3 a,Vector3 b){return (float)Math.Sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)+(a.z-b.z)*(a.z-b.z));}
  public static Vector3 Cross(Vector3 a,Vector3 b){return new Vector3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x);}public void Normalize(){}
 }
 public struct Quaternion { public static Quaternion identity { get {return new Quaternion();} } }
 public class Collider:Component { public bool enabled=true; }
 public struct RaycastHit { public Vector3 point,normal;public Collider collider; }
 public static class Physics {
  public static bool ground=true,blocked;public static Collider terrain;
  public static bool Raycast(Vector3 p,Vector3 direction,out RaycastHit hit,float length,int mask,QueryTriggerInteraction q){hit=new RaycastHit{point=new Vector3(p.x,1,p.z),normal=Vector3.up,collider=terrain};return ground;}
  public static bool CheckSphere(Vector3 p,float r,int mask,QueryTriggerInteraction q){return blocked;}
 }
 public static class Mathf {public const float PI=(float)Math.PI;public static float Cos(float x){return (float)Math.Cos(x);}public static float Sin(float x){return (float)Math.Sin(x);}}
 public static class Time {public static float time;}
 public static class LayerMask {public static int GetMask(params string[] s){return 1;}}
 public enum QueryTriggerInteraction {Ignore} public enum PrimitiveType {Sphere} public enum FindObjectsSortMode {None}
}
public class ItemDrop {public class ItemData {public class SharedData {public string m_name;public bool m_useDurability=true;}public SharedData m_shared=new SharedData();public float m_durability=50;}}
public class Character:MonoBehaviour {public int level;public bool dead;public void SetLevel(int v){level=v;}public bool IsDead(){return dead;}}
public class Humanoid:Character {public ItemDrop.ItemData tool;private ItemDrop.ItemData GetRightItem(){return tool;}}
public class Player:Humanoid {
 public static Player m_localPlayer; public GameObject m_placementGhost;public float m_placeRotationDegrees=22.5f,m_maxPlaceDistance=6;public int m_placeRotation=3;
 public Piece selected;public bool input=true,free,valid=true;public int seeds=100,placed,spent;public float stamina=100;public Vector3 lastPoint;
 public bool TakeInput(){return input;}public Piece GetSelectedPiece(){return selected;}public bool NoCostCheat(){return free;}public Vector3 GetEyePoint(){return transform.position+Vector3.up;}
 public bool HaveStamina(float n){return stamina>=n;}public void UseStamina(float n){stamina-=n;}
 public enum RequirementMode {CanBuild}public bool HaveRequirements(Piece p,RequirementMode mode){return seeds>0;}
 public void ConsumeResources(object[] r,int quality,int itemQuality,int multiplier){if(quality!=0||itemQuality!=-1||multiplier!=1)throw new Exception("Resource args");seeds--;spent++;}
 public float GetBuildStamina(){return 2;}public float GetPlaceDurability(ItemDrop.ItemData t){return 1;}
 public bool TryPlacePiece(Piece p){Vector3 point=Vector3.zero,normal=Vector3.up;Piece piece=null;Heightmap map=null;Collider water=null;if(!WorldToolsV1.AdjustRay(this,ref point,ref normal,ref piece,ref map,ref water,false)||!valid)return false;lastPoint=point;placed++;return true;}
}
public class Piece:MonoBehaviour {public int m_extraPlacementDistance;public object[] m_resources=new object[0];}
public class Plant:MonoBehaviour {public GameObject[] m_grownPrefabs;}
public class Pickable:MonoBehaviour {public bool picked;public bool CanBePicked(){return !picked;}public bool Interact(Player p,bool hold,bool alt){picked=true;return true;}}
public class Heightmap:MonoBehaviour {}
public class BaseAI:MonoBehaviour {public bool alert;private void SetAlerted(bool v){alert=v;}}
public class MonsterAI:BaseAI {public Character target;private void SetTarget(Character p){target=p;}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public List<GameObject> m_prefabs=new List<GameObject>();public List<GameObject> removed=new List<GameObject>();public GameObject GetPrefab(string n){return m_prefabs.Find(p=>p.name==n);}public void Destroy(GameObject g){removed.Add(g);UnityEngine.Object.Destroy(g);}}
public class ZoneSystem {public static ZoneSystem instance=new ZoneSystem();public float m_waterLevel;}
public static class PrivateArea {public static bool access=true;public static bool CheckAccess(Vector3 p,float r,bool flash,bool ward){return access;}}
public static class Hud {public static bool menu;public static bool IsPieceSelectionVisible(){return menu;}public static bool InRadial(){return false;}}
class Tests {
 static void Check(bool v,string m){if(!v)throw new Exception(m);}
 static void Reject(Action a){try{a();}catch(InvalidOperationException){return;}throw new Exception("Expected rejection");}
 static void Main(){
  var terrain=new GameObject("terrain");Physics.terrain=terrain.AddComponent<Collider>();terrain.AddComponent<Heightmap>();
  var pg=new GameObject("player");var p=pg.AddComponent<Player>();Player.m_localPlayer=p;p.tool=new ItemDrop.ItemData();p.tool.m_shared.m_name="$item_hammer";
  WorldToolsV1.Configure(p);WorldToolsV1.Tick(p);var d=WorldToolsV1.Driver;
  d.Execute(3,0.1f,0.2f,0.3f);d.Execute(4,37,0,0);d.Step();Check(p.m_placeRotationDegrees==1 && p.m_placeRotation==37,"Rotation");
  Vector3 point=Vector3.zero,normal=Vector3.up;Piece piece=null;Heightmap map=null;Collider water=null;
  Check(d.AdjustRay(ref point,ref normal,ref piece,ref map,ref water)&&Math.Abs(point.y-0.2f)<0.001f,"Offsets");
  point=new Vector3(99,0,0);Check(!d.AdjustRay(ref point,ref normal,ref piece,ref map,ref water),"Range guard");
  p.tool.m_shared.m_name="$item_cultivator";d.Step();Check(p.m_placeRotationDegrees==22.5f && p.m_placeRotation==3,"Restore tool switch");d.Execute(8,0,0,0);
  Reject(()=>d.Execute(3,4,0,0));Reject(()=>d.Execute(4,360,0,0));
  var grown=new GameObject("Carrot");grown.AddComponent<Pickable>();var seed=new GameObject("CarrotSeedling");p.selected=seed.AddComponent<Piece>();seed.AddComponent<Plant>().m_grownPrefabs=new[]{grown};ZNetScene.instance.m_prefabs.Add(seed);p.m_placementGhost=seed;
  d.Execute(5,3,2,0);d.Execute(6,0,0,0);for(int i=0;i<9;i++){Time.time+=1;d.Step();}
  Check(p.placed==9 && p.spent==9 && p.stamina==82 && p.tool.m_durability==41,"Grid costs");
  p.valid=false;d.Execute(5,1,2,0);d.Execute(6,0,0,0);Time.time+=1;d.Step();Check(p.spent==9,"Invalid crop consumed resources");p.valid=true;
  d.Execute(5,1,2,0);d.Execute(6,0,0,0);p.input=false;Time.time+=1;d.Step();Check(p.spent==9,"Paused input planted");p.input=true;d.Execute(9,0,0,0);Time.time+=1;d.Step();Check(p.spent==9,"Cancel planted");
  p.seeds=0;d.Execute(5,1,2,0);d.Execute(6,0,0,0);Time.time+=1;d.Step();Check(p.spent==9,"Missing seeds planted");d.Execute(9,0,0,0);
  p.free=true;d.Execute(5,1,2,0);d.Execute(6,0,0,0);Time.time+=1;d.Step();Check(p.placed==10 && p.spent==9,"Free crafting costs");p.free=false;
  var mature=new GameObject("Carrot(Clone)").AddComponent<Pickable>();var wild=new GameObject("RaspberryBush(Clone)").AddComponent<Pickable>();UnityEngine.Object.pickables.Add(mature);UnityEngine.Object.pickables.Add(wild);
  PrivateArea.access=false;d.Execute(7,6,0,0);Check(!mature.picked,"Ward ignored");PrivateArea.access=true;d.Execute(7,6,0,0);Check(mature.picked && !wild.picked,"Crop filter");
  var enemy=new GameObject("Greydwarf");enemy.AddComponent<MonsterAI>();ZNetScene.instance.m_prefabs.Add(enemy);
  Reject(()=>d.Execute(1,0,21,0));Physics.blocked=true;Reject(()=>d.Execute(1,0,2,0));Physics.blocked=false;
  d.Execute(1,0,3,2);Reject(()=>d.Execute(1,0,1,0));d.Execute(2,0,0,0);Check(ZNetScene.instance.removed.Count==3,"Raid cleanup count");
  foreach(var obj in ZNetScene.instance.removed)Check(obj.GetComponent<Character>().level==3 && obj.GetComponent<MonsterAI>().target==p,"Raid stars/target");
  d.Execute(1,0,2,0);d.Execute(5,1,2,0);p.tool.m_shared.m_name="$item_hammer";d.Execute(4,45,0,0);d.Step();WorldToolsV1.Disable();d.Cleanup();Check(ZNetScene.instance.removed.Count==5 && p.m_placeRotationDegrees==22.5f,"Shutdown restoration");
  WorldToolsV1.Configure(p);WorldToolsV1.Tick(p);d=WorldToolsV1.Driver;d.Execute(1,0,1,0);WorldToolsV1.Disable();WorldToolsV1.Configure(p);WorldToolsV1.Tick(p);
  Check(ZNetScene.instance.removed.Count==6 && WorldToolsV1.Driver!=d,"Fast reopen retained old raid/session");
  Console.WriteLine("PASS: precision/range/restore, grid costs/invalid points/menu/cancel/free crafting, mature crop/ward filters, bounded raid/target/stars/cleanup and fast reopen");
 }
}
