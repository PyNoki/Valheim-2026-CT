using System;
using System.Reflection;
using System.Collections.Generic;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object { public static implicit operator bool(Object x) { return x != null; } public static void Destroy(Object x) {} }
 public class GameObject : Object { public GameObject(string name) {} public T AddComponent<T>() where T:new() { return new T(); } }
 public class MonoBehaviour : Object { public GameObject gameObject = new GameObject("test"); }
 public class Animator : Object { public float speed=1.25f; }
 public static class Application { public static bool isFocused=true; }
 public static class Time { public static float fixedDeltaTime=0.02f; }
 public static class Mathf { public static float Min(float a,float b){return Math.Min(a,b);} }
}
public class Skills { public enum SkillType { None,Swords,Knives,Clubs,Polearms,Spears,Axes,Bows,Crossbows,Unarmed,Pickaxes,ElementalMagic,BloodMagic,Farming } }
public class ItemDrop { public class ItemData { public class SharedData { public Skills.SkillType m_skillType; public Attack m_attack=new Attack(); public Attack m_secondaryAttack=new Attack(); } public SharedData m_shared=new SharedData(); public float m_durability=2; public float GetMaxDurability() { return 150; } public float GetWeaponLoadingTime(){return 2;} } }
public class Humanoid : UnityEngine.Object { public Attack m_currentAttack; public float m_attackDrawTime; protected bool m_attackHold; public void HoldAttack(bool hold){m_attackHold=hold;} }
public class Attack {
 public enum AttackType { Horizontal,Projectile }
 public AttackType m_attackType=AttackType.Projectile;
 public bool m_requiresReload,m_bowDraw; public float m_reloadEitrDrain;
 public float m_burstInterval=0.2f,m_projectileFireTimer;
 public Humanoid m_character;
 public ItemDrop.ItemData m_weapon;
 public int shots,projectilesPerBurst=1;
 public void NativeTick(float dt,Player caster){m_projectileFireTimer-=dt;if(m_projectileFireTimer<=0){m_projectileFireTimer=m_burstInterval;shots++;caster.eitr-=2;}}
}
public class Player : Humanoid {
 public enum ActionType { Equip,Unequip,Reload }
 public class MinorActionData { public ActionType m_type; public ItemDrop.ItemData m_item; public float m_time,m_duration=2,m_eitrDrain; }
 public List<MinorActionData> m_actionQueue=new List<MinorActionData>();
 public float m_actionQueuePause;
 public ItemDrop.ItemData m_weaponLoaded;
 public bool canInput=true;
 public int bolts=20,shots;
 private bool TakeInput(){return canInput;}
 public bool TryUseEitr(float cost){return eitr>cost;} public void UseEitr(float cost){eitr-=cost;}
 public void SetWeaponLoaded(ItemDrop.ItemData item){m_weaponLoaded=item;}
 private void CancelReloadAction(){m_actionQueue.RemoveAll(a=>a.m_type==ActionType.Reload);}
 // Model native held-attack dispatch and per-shot ammo spending; the helper never calls this.
 public void NativeAttackStep(){if(canInput&&m_attackHold&&m_weaponLoaded==weapon&&bolts>0){bolts--;shots++;m_weaponLoaded=null;}}

 public static Player m_localPlayer;
 public float m_stamina=3, max=120,eitr=200;
 public bool dead, attacking,teleporting;
 public ItemDrop.ItemData weapon;
 public UnityEngine.Animator animator=new UnityEngine.Animator();
 public bool IsDead() { return dead; } public bool IsTeleporting(){return teleporting;} public bool InAttack() { return attacking; }
 public ItemDrop.ItemData GetCurrentWeapon() { return weapon; }
 public float GetMaxStamina() { return max; }
 public T GetComponentInChildren<T>() where T:class { return animator as T; }
}
class Test {
 static void Check(bool value,string message) { if (!value) throw new Exception(message); }
 static bool Near(float a,float b){return Math.Abs(a-b)<0.0001f;}
 static void Call(object obj,string method) { obj.GetType().GetMethod(method,BindingFlags.NonPublic|BindingFlags.Instance).Invoke(obj,null); }
 static void Main() {
  var p=new Player(); Player.m_localPlayer=p; RapidMinerV5.Configure(p);
  var d=new RapidMinerDriverV5();d.Owner=p;p.weapon=new ItemDrop.ItemData();
  d.Protect();Check(p.m_stamina==3&&p.weapon.m_durability==2,"Nonweapon modified");
  foreach(Skills.SkillType skill in Enum.GetValues(typeof(Skills.SkillType))){
   if(skill==Skills.SkillType.None||skill==Skills.SkillType.Farming)continue;
   p.weapon.m_shared.m_skillType=skill;p.m_stamina=3;p.weapon.m_durability=2;p.attacking=true;
   Call(d,"LateUpdate");Check(p.animator.speed==(skill==Skills.SkillType.Crossbows?37.5f:12.5f)&&p.m_stamina==120&&p.weapon.m_durability==150,"Weapon not accelerated: "+skill);
   p.attacking=false;Call(d,"LateUpdate");Check(p.animator.speed==1.25f,"Attack end restoration: "+skill);
  }
  p.weapon.m_shared.m_skillType=Skills.SkillType.Bows;p.m_attackDrawTime=0.02f;Call(d,"FixedUpdate");Check(Near(p.m_attackDrawTime,0.2f),"Bow progress not 10x");
  p.m_attackDrawTime=-1;Call(d,"FixedUpdate");Check(p.m_attackDrawTime==-1,"Cancelled bow draw restarted");
  p.m_attackDrawTime=0;Call(d,"FixedUpdate");Check(p.m_attackDrawTime==0,"Idle bow draw started");
  p.weapon.m_shared.m_skillType=Skills.SkillType.Crossbows;
  var crossbow=p.weapon;
  var equip=new Player.MinorActionData{m_type=Player.ActionType.Equip,m_item=new ItemDrop.ItemData(),m_time=0.02f};
  p.m_actionQueue.Add(new Player.MinorActionData{m_type=Player.ActionType.Reload,m_item=crossbow});p.m_actionQueue.Add(equip);
  p.HoldAttack(true);Call(d,"FixedUpdate");
  Check(p.m_weaponLoaded==crossbow&&p.m_actionQueue.Count==1&&p.m_actionQueue[0]==equip&&equip.m_time==0.02f,"Instant loading must remove reloads and preserve equipment actions");
  for(int i=0;i<20;i++){Call(d,"FixedUpdate");Check(p.m_weaponLoaded==crossbow,"Crossbow not rearmed between shots");p.NativeAttackStep();}
  Check(p.shots==20&&p.bolts==0,"Continuous crossbow fire must use one real bolt per shot");
  Call(d,"FixedUpdate");p.NativeAttackStep();Check(p.shots==20,"Empty ammo created a shot");
  p.HoldAttack(false);Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Release left helper-loaded shot");
  p.bolts=5;p.NativeAttackStep();Check(p.shots==20,"Fired on release");
  p.m_weaponLoaded=crossbow;p.HoldAttack(true);Call(d,"FixedUpdate");p.HoldAttack(false);Call(d,"FixedUpdate");Check(p.m_weaponLoaded==crossbow,"Unloading a naturally loaded shot");
  p.m_weaponLoaded=null;p.HoldAttack(true);Call(d,"FixedUpdate");p.canInput=false;Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Menu input guard");
  p.canInput=true;UnityEngine.Application.isFocused=false;Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Focus guard");UnityEngine.Application.isFocused=true;
  Call(d,"FixedUpdate");RapidMinerV5.Disable();Call(d,"Update");Check(p.m_weaponLoaded==null,"Disabled left helper loading active");
  RapidMinerV5.Configure(p);Call(d,"FixedUpdate");p.weapon=new ItemDrop.ItemData();Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Weapon switch left helper loading active");
  p.weapon=crossbow;Call(d,"FixedUpdate");var other=new ItemDrop.ItemData();p.m_weaponLoaded=other;d.Release();Check(p.m_weaponLoaded==other,"Cleanup unloaded another weapon");p.m_weaponLoaded=null;
  Call(d,"FixedUpdate");p.dead=true;Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Dead player rearmed crossbow");p.dead=false;
  Call(d,"FixedUpdate");p.teleporting=true;Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"Teleporting player rearmed crossbow");p.teleporting=false;
  Call(d,"FixedUpdate");Player.m_localPlayer=new Player();Call(d,"FixedUpdate");Check(p.m_weaponLoaded==null,"World change left helper-loaded crossbow");Player.m_localPlayer=p;
  p.m_actionQueue.Clear();p.HoldAttack(false);
  p.weapon.m_shared.m_skillType=Skills.SkillType.Swords;p.attacking=true;Call(d,"LateUpdate");
  p.weapon.m_shared.m_skillType=Skills.SkillType.Farming;Call(d,"LateUpdate");Check(p.animator.speed==1.25f,"Tool switch did not restore");
  p.weapon.m_shared.m_skillType=Skills.SkillType.Swords;p.max=180;d.Protect();Check(p.m_stamina==180,"Dynamic stamina");Call(d,"LateUpdate");
  RapidMinerV5.Disable();Call(d,"Update");Check(p.animator.speed==1.25f,"Disable restoration");p.m_stamina=7;d.Protect();Check(p.m_stamina==7,"Disabled refill");
  RapidMinerV5.Configure(p);Call(d,"LateUpdate");Player.m_localPlayer=new Player();Call(d,"LateUpdate");Check(p.animator.speed==1.25f,"World change restoration");
  Player.m_localPlayer=p;p.dead=true;p.m_stamina=9;d.Protect();Check(p.m_stamina==9,"Dead player refill");
  p.dead=false;p.teleporting=true;d.Protect();Check(p.m_stamina==9,"Teleporting refill");
  var caster=new Player();Player.m_localPlayer=caster;RapidMinerV5.Configure(caster);
  var magic=new ItemDrop.ItemData();magic.m_shared.m_skillType=Skills.SkillType.ElementalMagic;caster.weapon=magic;
  var md=new RapidMinerDriverV5{Owner=caster};
  magic.m_shared.m_attack.m_bowDraw=true;caster.m_attackDrawTime=0.02f;Call(md,"FixedUpdate");Check(Near(caster.m_attackDrawTime,0.2f),"Charged magic draw not 10x");
  caster.m_attackDrawTime=-1;Call(md,"FixedUpdate");Check(caster.m_attackDrawTime==-1,"Cancelled charged magic restarted");
  magic.m_shared.m_attack.m_bowDraw=false;caster.m_attackDrawTime=0.02f;Call(md,"FixedUpdate");Check(caster.m_attackDrawTime==0.02f,"Non-draw spell changed bow timer");
  caster.HoldAttack(true);Call(md,"FixedUpdate");Check(caster.m_weaponLoaded==null,"Non-reload spell marked loaded");
  magic.m_shared.m_attack.m_requiresReload=true;caster.m_actionQueue.Add(new Player.MinorActionData{m_type=Player.ActionType.Reload,m_item=magic});Call(md,"FixedUpdate");
  Check(caster.m_weaponLoaded==magic&&caster.m_actionQueue.Count==0,"Dundr-style spell reload not bypassed");
  caster.HoldAttack(false);Call(md,"FixedUpdate");Check(caster.m_weaponLoaded==magic,"Paid magic reload must remain ready on release");
  caster.m_weaponLoaded=null;caster.HoldAttack(true);magic.m_shared.m_attack.m_reloadEitrDrain=10;caster.eitr=100;
  caster.m_actionQueue.Add(new Player.MinorActionData{m_type=Player.ActionType.Reload,m_item=magic,m_time=0.5f,m_duration=2,m_eitrDrain=10});
  Call(md,"FixedUpdate");Check(caster.m_weaponLoaded==magic&&caster.eitr==85,"Only remaining native reload eitr must be paid");
  Call(md,"FixedUpdate");Check(caster.eitr==85,"Ready magic shot was charged twice");
  caster.m_weaponLoaded=null;caster.eitr=0;Call(md,"FixedUpdate");Check(caster.m_weaponLoaded==null,"Spell rearmed without required eitr");
  caster.HoldAttack(false);magic.m_shared.m_attack.m_requiresReload=false;caster.eitr=200;
  var channel=new Attack{m_character=caster,m_weapon=magic,m_projectileFireTimer=0.1f};caster.m_currentAttack=channel;
  Call(md,"FixedUpdate");Check(Near(channel.m_burstInterval,0.02f)&&Near(channel.m_projectileFireTimer,0.01f),"Live projectile interval and remaining timer not 10x");
  Call(md,"FixedUpdate");Check(Near(channel.m_burstInterval,0.02f)&&Near(channel.m_projectileFireTimer,0.01f),"Repeated spell scaling compounded");
  Check(magic.m_shared.m_attack.m_burstInterval==0.2f&&magic.m_shared.m_secondaryAttack.m_burstInterval==0.2f,"Shared attack definition changed");
  var normal=new Attack();var normalCaster=new Player();channel.m_projectileFireTimer=0;caster.eitr=200;
  for(int i=0;i<50;i++){Call(md,"FixedUpdate");channel.NativeTick(0.02f,caster);normal.NativeTick(0.02f,normalCaster);}
  Check(channel.shots>=normal.shots*8&&channel.shots==50,"Channel spell projectile cadence not accelerated");
  Check(caster.eitr==200-2*channel.shots&&channel.projectilesPerBurst==1,"Native per-burst cost/projectile count changed");
  channel.m_projectileFireTimer=0.01f;var second=new Attack{m_character=caster,m_weapon=magic,m_projectileFireTimer=0.1f};caster.m_currentAttack=second;
  Call(md,"FixedUpdate");Check(Near(channel.m_burstInterval,0.2f)&&Near(channel.m_projectileFireTimer,0.1f)&&Near(second.m_burstInterval,0.02f),"Cast replacement failed to restore old cast");
  caster.canInput=false;Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.2f),"Menu did not restore spell timing");caster.canInput=true;
  Call(md,"FixedUpdate");UnityEngine.Application.isFocused=false;Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.2f),"Focus loss did not restore spell timing");UnityEngine.Application.isFocused=true;
  var foreign=new Attack{m_character=new Player(),m_weapon=magic};caster.m_currentAttack=foreign;Call(md,"FixedUpdate");Check(foreign.m_burstInterval==0.2f,"Another caster modified");
  caster.m_currentAttack=magic.m_shared.m_attack;magic.m_shared.m_attack.m_character=caster;magic.m_shared.m_attack.m_weapon=magic;Call(md,"FixedUpdate");Check(magic.m_shared.m_attack.m_burstInterval==0.2f,"Shared primary attack modified");
  caster.m_currentAttack=magic.m_shared.m_secondaryAttack;magic.m_shared.m_secondaryAttack.m_character=caster;magic.m_shared.m_secondaryAttack.m_weapon=magic;Call(md,"FixedUpdate");Check(magic.m_shared.m_secondaryAttack.m_burstInterval==0.2f,"Shared secondary attack modified");
  caster.m_currentAttack=second;magic.m_shared.m_skillType=Skills.SkillType.BloodMagic;Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.02f),"Blood magic projectile timing not accelerated");
  RapidMinerV5.Disable();Call(md,"Update");Check(Near(second.m_burstInterval,0.2f),"Disable did not restore spell timing");
  RapidMinerV5.Configure(caster);Call(md,"FixedUpdate");caster.dead=true;Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.2f),"Death did not restore spell timing");caster.dead=false;
  Call(md,"FixedUpdate");caster.teleporting=true;Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.2f),"Teleport did not restore spell timing");caster.teleporting=false;
  Call(md,"FixedUpdate");caster.weapon=new ItemDrop.ItemData();Call(md,"FixedUpdate");Check(Near(second.m_burstInterval,0.2f),"Weapon switch did not restore spell timing");
  Console.WriteLine("PASS: magic charge/reload/burst timing, faster native projectile cadence and per-shot eitr costs, no compounding/shared/foreign mutation, cast/menu/focus/disable/death/teleport/weapon cleanup");
  Console.WriteLine("PASS: all 12 weapon skills, bow draw, instant crossbow rearming, continuous native fire/ammo exhaustion, release/menu/focus/disable cleanup, equip queue and naturally loaded shot preservation, tool exclusion, stamina/durability, animation restoration, disable/death/teleport/world guards");
 }
}
