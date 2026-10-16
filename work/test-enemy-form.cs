using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object { public static List<Humanoid> pending=new List<Humanoid>();public static bool unarmedOnly,noWeapons,noJump; public static void RunStarts(){foreach(var h in pending){if(h.gameObject.destroyed)continue;if(unarmedOnly)h.weapon=new ItemDrop.ItemData("unarmed");else if(!noWeapons){h.inventory.items.Add(new ItemDrop.ItemData("claws"));h.inventory.items.Add(new ItemDrop.ItemData("bite"));}}pending.Clear();} public bool destroyed;public static implicit operator bool(Object o){return o!=null&&!o.destroyed;}public static void Destroy(Object o){if(o!=null)o.destroyed=true;}
  public static GameObject Instantiate(GameObject prefab,Vector3 pos,Quaternion rot){var g=new GameObject(prefab.name);g.transform.position=pos;var h=g.AddComponent<Humanoid>();if(noJump)h.m_jumpForce=0;pending.Add(h);g.AddComponent<MonsterAI>();g.AddComponent<ZNetView>();return g;}}
 public class Component:Object {public GameObject gameObject;public Transform transform{get{return gameObject.transform;}}public T GetComponent<T>()where T:class{return gameObject.GetComponent<T>();}public T[] GetComponents<T>()where T:class{return gameObject.GetComponents<T>();}public T[] GetComponentsInChildren<T>(bool inactive)where T:class{return gameObject.GetComponents<T>();}}
 public class MonoBehaviour:Component {public bool enabled=true;}
 public class GameObject:Object {public string name;public Transform transform=new Transform();private List<object> components=new List<object>();public GameObject(string n){name=n;}public T AddComponent<T>()where T:Component,new(){var c=new T();c.gameObject=this;components.Add(c);return c;}public T GetComponent<T>()where T:class{foreach(var c in components)if(c is T && (!(c is Object)||!((Object)c).destroyed))return c as T;return null;}public T[] GetComponents<T>()where T:class{var list=new List<T>();foreach(var c in components)if(c is T)list.Add(c as T);return list.ToArray();}}
 public class Transform:Object {public Vector3 position,localPosition;public Quaternion rotation;public Vector3 forward=new Vector3(0,0,1);}
 public struct Quaternion {} public struct Vector2 {public float x,y;}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}public float sqrMagnitude{get{return x*x+y*y+z*z;}}public static Vector3 zero{get{return new Vector3();}}public static Vector3 up{get{return new Vector3(0,1,0);}}public static Vector3 operator+(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);}public static Vector3 operator*(Vector3 a,float n){return new Vector3(a.x*n,a.y*n,a.z*n);}public static Vector3 Cross(Vector3 a,Vector3 b){return new Vector3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x);}public static Vector3 ClampMagnitude(Vector3 a,float max){return a;}public void Normalize(){}}
 public class CanvasGroup:Component {public float alpha=1;}
 public class Renderer:Component {public bool forceRenderingOff;}
 public class Collider:Component {public bool enabled=true;}
 public class Rigidbody:Component {public bool isKinematic;public Vector3 linearVelocity,angularVelocity;}
 public static class Application {public static bool isFocused=true;}
 public static class Input {public static bool exit;public static bool GetKeyDown(KeyCode k){return exit;}}
 public enum KeyCode {F8}
 public static class Time {public static int frameCount;public static float time,deltaTime=0.02f;}
 public static class Mathf {public static int CeilToInt(float v){return (int)Math.Ceiling(v);}}
}
public class Projectile:MonoBehaviour {public bool m_hitFriendly,m_noDamageFriendly=true;}
public class Attack {public bool m_hitFriendly; public Attack Clone(){return (Attack)MemberwiseClone();}}
public class ItemDrop {public class ItemData {public class SharedData {public string m_name;public Attack m_attack=new Attack(),m_secondaryAttack=new Attack();}public SharedData m_shared=new SharedData();public bool primary=true,secondary=true;public ItemData(string name){m_shared.m_name=name;}public bool HavePrimaryAttack(){return primary;}public bool HaveSecondaryAttack(){return secondary;}}}
public class Inventory {public List<ItemDrop.ItemData> items=new List<ItemDrop.ItemData>();public List<ItemDrop.ItemData> GetAllItems(){return items;}}
public class Character:MonoBehaviour {
 public float m_speed=6,m_walkSpeed=2,m_runSpeed=10,m_crouchSpeed=1,m_swimSpeed=3,m_jumpForce=8;
 public enum Faction {Monsters,Players}public Faction m_faction;public bool m_aiSkipTarget,dead,attacking,dodging,teleporting,run;public Vector3 move,look;public Transform m_eye=new Transform();
 public bool IsDead(){return dead;}public bool InAttack(){return attacking;}public bool InDodge(){return dodging;}public bool IsTeleporting(){return teleporting;}public Vector3 GetEyePoint(){return transform.position+Vector3.up;}public void SetMoveDir(Vector3 v){move=v;}public void SetRun(bool v){run=v;}public void SetWalk(bool v){}public void SetLookDir(Vector3 v,float transitionTime){if(transitionTime<=0)look=v;}public void Jump(bool f){}public float GetHealth(){return 75;}public float GetMaxHealth(){return 100;}
}
public class Humanoid:Character {public Inventory inventory=new Inventory();public ItemDrop.ItemData weapon;public int attacks;public bool usedSecondary;public Inventory GetInventory(){return inventory;}public ItemDrop.ItemData GetCurrentWeapon(){return weapon;}public bool EquipItem(ItemDrop.ItemData i,bool effect){if(weapon==i)return false;weapon=i;return true;}public bool StartAttack(Character target,bool secondary){attacks++;usedSecondary=secondary;return true;}}
public class Player:Humanoid {public static Player m_localPlayer;public bool input=true;private bool TakeInput(){return input;}private void UpdateEyeRotation(){}}
public class PlayerController:MonoBehaviour {public static int cameraUpdates;private void LateUpdate(){cameraUpdates++;}}
public class BaseAI:MonoBehaviour {}public class MonsterAI:BaseAI {}
public class ZNetView:MonoBehaviour {public ZDO data=new ZDO();public ZDO GetZDO(){return data;}public static bool owned=true;public bool IsValid(){return true;}public bool IsOwner(){return owned;}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public GameObject prefab;public string requestedPrefab;public int removed;public GameObject GetPrefab(string name){requestedPrefab=name;return prefab;}public void Destroy(GameObject g){removed++;UnityEngine.Object.Destroy(g);}}
public class GameCamera:MonoBehaviour {}
public class ZDO {public string Name="Noki";public string GetString(int key,string fallback){return Name;}public void Set(int key,string value){Name=value;}}
public static class ZDOVars {public static int s_playerName=12;}
public class ZNet:UnityEngine.Object {public static ZNet instance=new ZNet();public Vector3 reference;public int referenceUpdates;public void SetReferencePosition(Vector3 pos){reference=pos;referenceUpdates++;}public bool m_publicReferencePosition=true;public void SetPublicReferencePosition(bool value){m_publicReferencePosition=value;}}
public class EnemyHud:MonoBehaviour {public static EnemyHud instance;public class HudData {public GameObject m_gui;}public Dictionary<Character,HudData> m_huds=new Dictionary<Character,HudData>();}

public static class ZInput {public static HashSet<string> pressed=new HashSet<string>();public static bool GetButton(string key){return pressed.Contains(key);}public static bool GetButtonDown(string key){return pressed.Contains(key);}public static Vector2 GetJoyLeftStick(){return new Vector2();}}
public static class InventoryGui {public static bool visible;public static bool IsVisible(){return visible;}}public static class Menu {public static bool IsVisible(){return false;}}public static class Console {public static bool IsVisible(){return false;}}public class Minimap:MonoBehaviour {public static Minimap instance;public Component m_smallMarker,m_largeMarker,m_smallShipMarker,m_largeShipMarker;public static bool IsOpen(){return false;}}public static class Hud {public static bool IsPieceSelectionVisible(){return false;}public static bool InRadial(){return false;}}
public class Chat:UnityEngine.Object {public static Chat instance;public bool HasFocus(){return false;}}
class Tests {
 static void Check(bool value,string label){if(!value)throw new Exception(label);}
 static Humanoid Body(){var f=typeof(EnemyFormDriverV8).GetField("body",System.Reflection.BindingFlags.NonPublic|System.Reflection.BindingFlags.Instance);return (Humanoid)f.GetValue(EnemyFormV8.Driver);}
 static void Transform(Player p,int form){EnemyFormV8.Configure(p,form);EnemyFormV8.Tick(null);Check(p.enabled,"Suspended before Start");Time.frameCount++;UnityEngine.Object.RunStarts();EnemyFormV8.Tick(null);}
 static void Main(){
  var g=new GameObject("player");var p=g.AddComponent<Player>();Player.m_localPlayer=p;p.inventory.items.Add(new ItemDrop.ItemData("player sword"));var control=g.AddComponent<PlayerController>();var rigid=g.AddComponent<Rigidbody>();var renderer=g.AddComponent<Renderer>();var collider=g.AddComponent<Collider>();p.m_eye.localPosition=new Vector3(0,1.6f,0);
  var playerView=g.AddComponent<ZNetView>();
  Minimap.instance=new GameObject("map").AddComponent<Minimap>();
  Minimap.instance.m_smallMarker=new GameObject("small").AddComponent<Collider>();Minimap.instance.m_largeMarker=new GameObject("large").AddComponent<Collider>();
  var largeGroup=Minimap.instance.m_largeMarker.gameObject.AddComponent<CanvasGroup>();largeGroup.alpha=0.4f;
  EnemyHud.instance=new GameObject("huds").AddComponent<EnemyHud>();var nameplate=new GameObject("nameplate");EnemyHud.instance.m_huds[p]=new EnemyHud.HudData{m_gui=nameplate};
  var otherPlayer=new GameObject("otherPlayer").AddComponent<Player>();var otherHud=new GameObject("otherHud");EnemyHud.instance.m_huds[otherPlayer]=new EnemyHud.HudData{m_gui=otherHud};
  var prefab=new GameObject("enemy");prefab.AddComponent<Humanoid>();prefab.AddComponent<MonsterAI>();ZNetScene.instance.prefab=prefab;
  Transform(p,0);var body=Body();
  Check(EnemyFormV8.Enabled==1&&!p.enabled&&!control.enabled&&rigid.isKinematic&&renderer.forceRenderingOff&&!collider.enabled&&p.m_aiSkipTarget,"Original player suspension");
  Check(!ZNet.instance.m_publicReferencePosition && playerView.data.Name=="" && largeGroup.alpha==0 && nameplate.GetComponent<CanvasGroup>().alpha==0,"Disguise visibility");
  Check(otherHud.GetComponent<CanvasGroup>()==null,"Other player HUD changed");
  ZNet.instance.m_publicReferencePosition=true;largeGroup.alpha=1;EnemyFormV8.Tick(null);Check(!ZNet.instance.m_publicReferencePosition&&largeGroup.alpha==0,"Disguise not maintained");
  Check(!body.GetComponent<MonsterAI>().enabled&&body.m_faction==Character.Faction.Players,"Only body AI disabled/faction");
  ZInput.pressed.Add("Forward");ZInput.pressed.Add("Run");ZInput.pressed.Add("Attack");Time.time=1;EnemyFormV8.Tick(null);Check(body.move.z==1&&body.run&&body.attacks==1,"Native move/attack");
  InventoryGui.visible=true;Time.time=2;EnemyFormV8.Tick(null);Check(body.move.z==0&&body.attacks==1,"Menu guard");InventoryGui.visible=false;
  Application.isFocused=false;Time.time=3;EnemyFormV8.Tick(null);Check(body.attacks==1,"Focus guard");Application.isFocused=true;
  ZInput.pressed.Clear();ZInput.pressed.Add("Use");EnemyFormV8.Tick(null);Check(body.weapon.m_shared.m_name=="bite","Weapon cycle");ZInput.pressed.Clear();ZInput.pressed.Add("Block");Time.time=4;EnemyFormV8.Tick(null);Check(body.usedSecondary,"Native secondary");
  body.transform.position=new Vector3(5,2,3);EnemyFormV8.Tick(null);Input.exit=true;EnemyFormV8.Tick(null);Input.exit=false;
  Check(EnemyFormV8.Enabled==0&&p.enabled&&control.enabled&&!rigid.isKinematic&&!renderer.forceRenderingOff&&collider.enabled&&!p.m_aiSkipTarget,"Return restoration");
  Check(p.transform.position.x==5&&p.m_eye.localPosition.y==1.6f&&p.inventory.items.Count==1,"Return position/eye/inventory");
  Check(ZNet.instance.m_publicReferencePosition && playerView.data.Name=="Noki" && largeGroup.alpha==0.4f && nameplate.GetComponent<CanvasGroup>()==null,"Identity restoration");
  ZNet.instance.m_publicReferencePosition=false;
  Transform(p,1);body=Body();body.dead=true;EnemyFormV8.Tick(null);Check(p.enabled&&EnemyFormV8.Enabled==0&&!ZNet.instance.m_publicReferencePosition&&playerView.data.Name=="Noki","Death return and prior private setting");
  Transform(p,2);var old=EnemyFormV8.Driver;EnemyFormV8.Disable();Transform(p,3);Check(EnemyFormV8.Driver!=old&&!p.enabled,"Fast reenable lifecycle");
  EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();Check(p.enabled,"Explicit cleanup");
  int removed=ZNetScene.instance.removed;ZNetView.owned=false;EnemyFormV8.Configure(p,4);EnemyFormV8.Tick(null);Check(EnemyFormV8.Enabled==0&&p.enabled&&control.enabled&&ZNetScene.instance.removed==removed+1,"Partial setup cleanup");ZNetView.owned=true;
  Transform(p,0);Player.m_localPlayer=null;EnemyFormV8.Tick(null);EnemyFormV8.Driver.Restore();Check(p.enabled,"World unload restoration");
  Player.m_localPlayer=p;UnityEngine.Object.unarmedOnly=true;Transform(p,3);Check(EnemyFormV8.Enabled==1&&!p.enabled&&Body().GetInventory().GetAllItems().Count==0,"Built-in unarmed weapon unsupported");EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();UnityEngine.Object.unarmedOnly=false;
  EnemyFormV8.Configure(p,0);EnemyFormV8.Tick(null);Check(p.enabled,"Pending setup modified player");EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();Check(p.enabled,"Pending cancellation");
  UnityEngine.Object.noWeapons=true;EnemyFormV8.Configure(p,0);EnemyFormV8.Tick(null);Time.frameCount++;UnityEngine.Object.RunStarts();EnemyFormV8.Tick(null);Check(p.enabled&&EnemyFormV8.Enabled==1,"Empty inventory should wait");Time.time+=4;EnemyFormV8.Tick(null);Check(p.enabled&&EnemyFormV8.Enabled==0&&EnemyFormV8.LastError.Contains("3 seconds"),"Initialization timeout cleanup");
  UnityEngine.Object.noWeapons=false;Transform(p,0);playerView.data=new ZDO();playerView.data.Name="Replacement identity";ZNet.instance=new ZNet();EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();Check(playerView.data.Name=="Replacement identity"&&ZNet.instance.m_publicReferencePosition,"Restore overwrote replacement world/name storage");
  ZInput.pressed.Clear();Transform(p,5);body=Body();
  Check(ZNetScene.instance.requestedPrefab=="Serpent"&&EnemyFormV8.Enabled==1&&!p.enabled,"Serpent prefab selection/setup");
  ZInput.pressed.Add("Forward");ZInput.pressed.Add("Attack");Time.time+=1;EnemyFormV8.Tick(null);
  Check(body.move.z==1&&body.move.y==0&&body.attacks==1,"Serpent native movement/attack input");
  body.transform.position=new Vector3(25,-1,30);EnemyFormV8.Tick(null);Input.exit=true;EnemyFormV8.Tick(null);Input.exit=false;
  Check(p.enabled&&p.transform.position.x==25&&p.transform.position.y==-1&&playerView.data.Name=="Replacement identity","Serpent return position/identity");
  ZInput.pressed.Clear();Transform(p,0);body=Body();
  for(int sector=1;sector<=20;sector++){
   body.transform.position=new Vector3(sector*64,sector,sector*128);EnemyFormV8.Tick(null);
   Check(ZNet.instance.reference.x==sector*64&&ZNet.instance.reference.z==sector*128&&p.transform.position.x==sector*64,"World streaming stopped at sector "+sector);
  }
  body.transform.position=new Vector3(1500,1,2500);
  typeof(EnemyFormDriverV8).GetMethod("FixedUpdate",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).Invoke(EnemyFormV8.Driver,null);
  Check(ZNet.instance.reference.x==1500,"Physics step did not follow body");
  var originalPrimary=body.weapon.m_shared.m_attack;var originalSecondary=body.weapon.m_shared.m_secondaryAttack;
  var ownProjectile=new GameObject("own projectile").AddComponent<Projectile>();var unrelatedProjectile=new GameObject("other projectile").AddComponent<Projectile>();
  EnemyFormV8.SetOptions(1,1);EnemyFormV8.Tick(null);
  EnemyFormV8.TuneProjectile(ownProjectile,body);EnemyFormV8.TuneProjectile(unrelatedProjectile,otherPlayer);
  Check(ownProjectile.m_hitFriendly&&!ownProjectile.m_noDamageFriendly&&!unrelatedProjectile.m_hitFriendly&&unrelatedProjectile.m_noDamageFriendly,"Projectile duel tuning/owner isolation");
  Check(body.m_faction==Character.Faction.Monsters&&body.m_aiSkipTarget,"Red allegiance/creature targeting");
  foreach(var weapon in body.inventory.items)Check(weapon.m_shared.m_attack.m_hitFriendly&&weapon.m_shared.m_secondaryAttack.m_hitFriendly,"Duel must enable primary/secondary on every weapon");
  EnemyFormV8.SetOptions(0,0);EnemyFormV8.Tick(null);
  Check(!ownProjectile.m_hitFriendly&&ownProjectile.m_noDamageFriendly,"In-flight projectile settings did not restore");
  EnemyFormV8.SetOptions(1,1);EnemyFormV8.Tick(null);Check(ownProjectile.m_hitFriendly,"In-flight duel enable missing");
  EnemyFormV8.SetOptions(0,0);EnemyFormV8.Tick(null);
  Check(body.m_faction==Character.Faction.Players&&!body.m_aiSkipTarget&&!originalPrimary.m_hitFriendly&&!originalSecondary.m_hitFriendly,"Live options did not restore green/native targeting");
  EnemyFormV8.SetOptions(1,1);EnemyFormV8.Tick(null);
  EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();Check(!ownProjectile.m_hitFriendly&&ownProjectile.m_noDamageFriendly,"Projectile cleanup");Check(ZNet.instance.reference.x==1500&&p.transform.position.x==1500,"Return reset streaming position");EnemyFormV8.SetOptions(0,0);
  // A weapon asset shared with another creature must remain untouched.
  EnemyFormV8.Configure(p,0);EnemyFormV8.Tick(null);Time.frameCount++;UnityEngine.Object.RunStarts();
  var pendingBody=Body();var sharedAsset=pendingBody.inventory.items[0].m_shared;sharedAsset.m_secondaryAttack.m_hitFriendly=true;
  EnemyFormV8.SetOptions(1,1);EnemyFormV8.Tick(null);
  Check(!object.ReferenceEquals(sharedAsset,pendingBody.weapon.m_shared)&&!sharedAsset.m_attack.m_hitFriendly&&pendingBody.weapon.m_shared.m_attack.m_hitFriendly,"Duel changed shared weapon prefab");
  EnemyFormV8.SetOptions(0,0);EnemyFormV8.Tick(null);
  Check(!pendingBody.weapon.m_shared.m_attack.m_hitFriendly&&pendingBody.weapon.m_shared.m_secondaryAttack.m_hitFriendly,"Duel OFF must restore native attack flags");
  EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();
  UnityEngine.Object.unarmedOnly=true;EnemyFormV8.SetOptions(1,1);Transform(p,0);
  Check(Body().weapon.m_shared.m_attack.m_hitFriendly,"Unarmed duel attack missing");EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();UnityEngine.Object.unarmedOnly=false;EnemyFormV8.SetOptions(0,0);
  bool badOption=false;try{EnemyFormV8.SetOptions(2,0);}catch(ArgumentException){badOption=true;}Check(badOption,"Invalid option accepted");
  System.Console.WriteLine("PASS: 20-sector world-streaming travel, physics follow, return reference, red/green allegiance and AI skip, live duel primary/secondary/unarmed, shared-asset isolation, owner-only ranged tuning, in-flight toggles/cleanup and native flag restoration");
  bool rejected=false;try{EnemyFormV8.Configure(p,26);}catch(ArgumentException){rejected=true;}Check(rejected&&EnemyFormV8.Enabled==0,"Invalid form bounds");
  EnemyFormV8.SetMovement(2,3);ZInput.pressed.Clear();Transform(p,0);body=Body();
  Check(body.m_speed==12&&body.m_walkSpeed==4&&body.m_runSpeed==20&&body.m_crouchSpeed==2&&body.m_swimSpeed==6&&body.m_jumpForce==24,"Pre-transform modifiers did not scale creature-native movement");
  for(int tick=0;tick<10;tick++)EnemyFormV8.Tick(null);
  Check(body.m_runSpeed==20&&body.m_jumpForce==24,"Repeated updates compounded movement");
  EnemyFormV8.SetMovement(0.5f,4);EnemyFormV8.Tick(null);
  Check(body.m_speed==3&&body.m_runSpeed==5&&body.m_swimSpeed==1.5f&&body.m_jumpForce==32,"Live independent speed/jump change");
  Check(p.m_speed==6&&p.m_runSpeed==10&&p.m_jumpForce==8&&otherPlayer.m_runSpeed==10,"Modifier changed original player or another creature");
  EnemyFormV8.SetMovement(1,1);
  typeof(EnemyFormDriverV8).GetMethod("FixedUpdate",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic).Invoke(EnemyFormV8.Driver,null);
  Check(body.m_speed==6&&body.m_walkSpeed==2&&body.m_runSpeed==10&&body.m_crouchSpeed==1&&body.m_swimSpeed==3&&body.m_jumpForce==8,"Reset failed to restore native form movement before physics");
  EnemyFormV8.SetMovement(2,3);EnemyFormV8.Tick(null);EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();Transform(p,3);body=Body();
  Check(body.m_runSpeed==20&&body.m_jumpForce==24,"Changing forms lost modifiers or compounded previous body");
  EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();UnityEngine.Object.noJump=true;Transform(p,5);
  Check(Body().m_jumpForce==0&&Body().m_swimSpeed==6,"Non-jumping/swimming form did not preserve native zero jump");
  EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();UnityEngine.Object.noJump=false;
  foreach(float invalid in new[]{float.NaN,float.PositiveInfinity,0f,21f}){
   bool bad=false;try{EnemyFormV8.SetMovement(invalid,1);}catch(ArgumentException){bad=true;}Check(bad,"Invalid speed accepted");
  }
  bool badJump=false;try{EnemyFormV8.SetMovement(1,11);}catch(ArgumentException){badJump=true;}Check(badJump&&EnemyFormV8.MovementSpeed==2&&EnemyFormV8.JumpForce==3,"Invalid settings mutated valid modifiers");
  EnemyFormV8.SetMovement(1,1);
  System.Console.WriteLine("PASS: creature-native speed/walk/run/crouch/swim and jump multipliers, pre-transform/live updates, no compounding, reset before physics, body changes, player isolation and native zero jump");
  // Native SetLookDir only changes facing immediately when transitionTime is zero.
  // Exercise every prefab; the old per-frame transition restart leaves look unchanged.
  for(int form=0;form<26;form++){
   ZInput.pressed.Clear();p.m_eye.forward=new Vector3(1,0,0);Transform(p,form);body=Body();
   Check(ZNetScene.instance.requestedPrefab==EnemyFormDriverV8.Forms[form],"Prefab mapping form "+form);
   Check(body.look.x==1&&body.look.z==0,"Idle camera facing form "+form);
   p.m_eye.forward=new Vector3(0,0,1);EnemyFormV8.Tick(null);Check(body.look.z==1&&body.look.x==0,"Camera changed facing form "+form);
   ZInput.pressed.Add("Right");EnemyFormV8.Tick(null);Check(body.look.x==1&&body.look.z==0&&body.move.x==1,"Right movement facing form "+form);
   ZInput.pressed.Clear();ZInput.pressed.Add("Left");EnemyFormV8.Tick(null);Check(body.look.x==-1,"Left movement facing form "+form);
   ZInput.pressed.Clear();ZInput.pressed.Add("Backward");EnemyFormV8.Tick(null);Check(body.look.z==-1,"Backward movement facing form "+form);
   ZInput.pressed.Add("Attack");Time.time+=1;EnemyFormV8.Tick(null);Check(body.look.z==1&&body.attacks==1&&body.move.z==-1,"Attack faces camera while retreating form "+form);
   ZInput.pressed.Clear();ZInput.pressed.Add("Right");body.attacking=true;EnemyFormV8.Tick(null);Check(body.look.z==1,"Ongoing attack camera facing form "+form);body.attacking=false;
   InventoryGui.visible=true;p.m_eye.forward=new Vector3(-1,0,0);EnemyFormV8.Tick(null);Check(body.look.z==1&&body.move.x==0,"Menu changed facing form "+form);InventoryGui.visible=false;
   EnemyFormV8.Disable();EnemyFormV8.Driver.Restore();
  }
  System.Console.WriteLine("PASS: all 26 forms follow idle camera, WASD direction, attack aim and menu guard without restarting look transitions");
  System.Console.WriteLine("PASS: serpent prefab/native control/return, selection bounds, name/map/minimap/shared-position hide/restore and other-player isolation, deferred Unity Start, unarmed fallback, pending cancel/timeout, native body controls/attacks, menu/focus guards, weapon cycling, return/death, original inventory/camera/collision, fast reenable and partial failure cleanup");
 }
}
