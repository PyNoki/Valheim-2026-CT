using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object { public bool destroyed;public static implicit operator bool(Object o){return o!=null&&!o.destroyed;}public static void Destroy(Object o){if(o!=null)o.destroyed=true;}
  public static GameObject Instantiate(GameObject prefab,Vector3 pos,Quaternion rot){var g=new GameObject(prefab.name);g.transform.position=pos;var h=g.AddComponent<Humanoid>();h.inventory.items.Add(new ItemDrop.ItemData("claws"));h.inventory.items.Add(new ItemDrop.ItemData("bite"));h.weapon=h.inventory.items[0];g.AddComponent<MonsterAI>();g.AddComponent<ZNetView>();return g;}}
 public class Component:Object {public GameObject gameObject;public Transform transform{get{return gameObject.transform;}}public T GetComponent<T>()where T:class{return gameObject.GetComponent<T>();}public T[] GetComponents<T>()where T:class{return gameObject.GetComponents<T>();}public T[] GetComponentsInChildren<T>(bool inactive)where T:class{return gameObject.GetComponents<T>();}}
 public class MonoBehaviour:Component {public bool enabled=true;}
 public class GameObject:Object {public string name;public Transform transform=new Transform();private List<object> components=new List<object>();public GameObject(string n){name=n;}public T AddComponent<T>()where T:Component,new(){var c=new T();c.gameObject=this;components.Add(c);return c;}public T GetComponent<T>()where T:class{foreach(var c in components)if(c is T)return c as T;return null;}public T[] GetComponents<T>()where T:class{var list=new List<T>();foreach(var c in components)if(c is T)list.Add(c as T);return list.ToArray();}}
 public class Transform:Object {public Vector3 position,localPosition;public Quaternion rotation;public Vector3 forward=new Vector3(0,0,1);}
 public struct Quaternion {} public struct Vector2 {public float x,y;}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}public static Vector3 zero{get{return new Vector3();}}public static Vector3 up{get{return new Vector3(0,1,0);}}public static Vector3 operator+(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);}public static Vector3 operator*(Vector3 a,float n){return new Vector3(a.x*n,a.y*n,a.z*n);}public static Vector3 Cross(Vector3 a,Vector3 b){return new Vector3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x);}public static Vector3 ClampMagnitude(Vector3 a,float max){return a;}public void Normalize(){}}
 public class Renderer:Component {public bool forceRenderingOff;}
 public class Collider:Component {public bool enabled=true;}
 public class Rigidbody:Component {public bool isKinematic;public Vector3 linearVelocity,angularVelocity;}
 public static class Application {public static bool isFocused=true;}
 public static class Input {public static bool exit;public static bool GetKeyDown(KeyCode k){return exit;}}
 public enum KeyCode {F8}
 public static class Time {public static float time,deltaTime=0.02f;}
 public static class Mathf {public static int CeilToInt(float v){return (int)Math.Ceiling(v);}}
}
public class ItemDrop {public class ItemData {public class SharedData {public string m_name;}public SharedData m_shared=new SharedData();public bool primary=true,secondary=true;public ItemData(string name){m_shared.m_name=name;}public bool HavePrimaryAttack(){return primary;}public bool HaveSecondaryAttack(){return secondary;}}}
public class Inventory {public List<ItemDrop.ItemData> items=new List<ItemDrop.ItemData>();public List<ItemDrop.ItemData> GetAllItems(){return items;}}
public class Character:MonoBehaviour {
 public enum Faction {Monsters,Players}public Faction m_faction;public bool m_aiSkipTarget,dead,attacking,dodging,teleporting,run;public Vector3 move;public Transform m_eye=new Transform();
 public bool IsDead(){return dead;}public bool InAttack(){return attacking;}public bool InDodge(){return dodging;}public bool IsTeleporting(){return teleporting;}public Vector3 GetEyePoint(){return transform.position+Vector3.up;}public void SetMoveDir(Vector3 v){move=v;}public void SetRun(bool v){run=v;}public void SetWalk(bool v){}public void SetLookDir(Vector3 v,float dt){}public void Jump(bool f){}public float GetHealth(){return 75;}public float GetMaxHealth(){return 100;}
}
public class Humanoid:Character {public Inventory inventory=new Inventory();public ItemDrop.ItemData weapon;public int attacks;public bool usedSecondary;public Inventory GetInventory(){return inventory;}public ItemDrop.ItemData GetCurrentWeapon(){return weapon;}public bool EquipItem(ItemDrop.ItemData i,bool effect){if(weapon==i)return false;weapon=i;return true;}public bool StartAttack(Character target,bool secondary){attacks++;usedSecondary=secondary;return true;}}
public class Player:Humanoid {public static Player m_localPlayer;public bool input=true;private bool TakeInput(){return input;}private void UpdateEyeRotation(){}}
public class PlayerController:MonoBehaviour {public static int cameraUpdates;private void LateUpdate(){cameraUpdates++;}}
public class BaseAI:MonoBehaviour {}public class MonsterAI:BaseAI {}
public class ZNetView:MonoBehaviour {public static bool owned=true;public bool IsValid(){return true;}public bool IsOwner(){return owned;}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public GameObject prefab;public int removed;public GameObject GetPrefab(string name){return prefab;}public void Destroy(GameObject g){removed++;UnityEngine.Object.Destroy(g);}}
public class GameCamera:MonoBehaviour {}
public static class ZInput {public static HashSet<string> pressed=new HashSet<string>();public static bool GetButton(string key){return pressed.Contains(key);}public static bool GetButtonDown(string key){return pressed.Contains(key);}public static Vector2 GetJoyLeftStick(){return new Vector2();}}
public static class InventoryGui {public static bool visible;public static bool IsVisible(){return visible;}}public static class Menu {public static bool IsVisible(){return false;}}public static class Console {public static bool IsVisible(){return false;}}public static class Minimap {public static bool IsOpen(){return false;}}public static class Hud {public static bool IsPieceSelectionVisible(){return false;}public static bool InRadial(){return false;}}
public class Chat:UnityEngine.Object {public static Chat instance;public bool HasFocus(){return false;}}
class Tests {
 static void Check(bool value,string label){if(!value)throw new Exception(label);}
 static Humanoid Body(){var f=typeof(EnemyFormDriverV1).GetField("body",System.Reflection.BindingFlags.NonPublic|System.Reflection.BindingFlags.Instance);return (Humanoid)f.GetValue(EnemyFormV1.Driver);}
 static void Main(){
  var g=new GameObject("player");var p=g.AddComponent<Player>();Player.m_localPlayer=p;p.inventory.items.Add(new ItemDrop.ItemData("player sword"));var control=g.AddComponent<PlayerController>();var rigid=g.AddComponent<Rigidbody>();var renderer=g.AddComponent<Renderer>();var collider=g.AddComponent<Collider>();p.m_eye.localPosition=new Vector3(0,1.6f,0);
  var prefab=new GameObject("enemy");prefab.AddComponent<Humanoid>();prefab.AddComponent<MonsterAI>();ZNetScene.instance.prefab=prefab;
  EnemyFormV1.Configure(p,0);EnemyFormV1.Tick(null);var body=Body();
  Check(EnemyFormV1.Enabled==1&&!p.enabled&&!control.enabled&&rigid.isKinematic&&renderer.forceRenderingOff&&!collider.enabled&&p.m_aiSkipTarget,"Original player suspension");
  Check(!body.GetComponent<MonsterAI>().enabled&&body.m_faction==Character.Faction.Players,"Only body AI disabled/faction");
  ZInput.pressed.Add("Forward");ZInput.pressed.Add("Run");ZInput.pressed.Add("Attack");Time.time=1;EnemyFormV1.Tick(null);Check(body.move.z==1&&body.run&&body.attacks==1,"Native move/attack");
  InventoryGui.visible=true;Time.time=2;EnemyFormV1.Tick(null);Check(body.move.z==0&&body.attacks==1,"Menu guard");InventoryGui.visible=false;
  Application.isFocused=false;Time.time=3;EnemyFormV1.Tick(null);Check(body.attacks==1,"Focus guard");Application.isFocused=true;
  ZInput.pressed.Clear();ZInput.pressed.Add("Use");EnemyFormV1.Tick(null);Check(body.weapon.m_shared.m_name=="bite","Weapon cycle");ZInput.pressed.Clear();ZInput.pressed.Add("Block");Time.time=4;EnemyFormV1.Tick(null);Check(body.usedSecondary,"Native secondary");
  body.transform.position=new Vector3(5,2,3);EnemyFormV1.Tick(null);Input.exit=true;EnemyFormV1.Tick(null);Input.exit=false;
  Check(EnemyFormV1.Enabled==0&&p.enabled&&control.enabled&&!rigid.isKinematic&&!renderer.forceRenderingOff&&collider.enabled&&!p.m_aiSkipTarget,"Return restoration");
  Check(p.transform.position.x==5&&p.m_eye.localPosition.y==1.6f&&p.inventory.items.Count==1,"Return position/eye/inventory");
  EnemyFormV1.Configure(p,1);EnemyFormV1.Tick(null);body=Body();body.dead=true;EnemyFormV1.Tick(null);Check(p.enabled&&EnemyFormV1.Enabled==0,"Death return");
  EnemyFormV1.Configure(p,2);EnemyFormV1.Tick(null);var old=EnemyFormV1.Driver;EnemyFormV1.Disable();EnemyFormV1.Configure(p,3);EnemyFormV1.Tick(null);Check(EnemyFormV1.Driver!=old&&!p.enabled,"Fast reenable lifecycle");
  EnemyFormV1.Disable();EnemyFormV1.Driver.Restore();Check(p.enabled,"Explicit cleanup");
  int removed=ZNetScene.instance.removed;ZNetView.owned=false;EnemyFormV1.Configure(p,4);EnemyFormV1.Tick(null);Check(EnemyFormV1.Enabled==0&&p.enabled&&control.enabled&&ZNetScene.instance.removed==removed+1,"Partial setup cleanup");ZNetView.owned=true;
  EnemyFormV1.Configure(p,0);EnemyFormV1.Tick(null);Player.m_localPlayer=null;EnemyFormV1.Tick(null);EnemyFormV1.Driver.Restore();Check(p.enabled,"World unload restoration");
  System.Console.WriteLine("PASS: native body controls/attacks, menu/focus guards, weapon cycling, return/death, original inventory/camera/collision, fast reenable and partial failure cleanup");
 }
}
