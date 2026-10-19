using System;
using System.Reflection;
using System.Collections.Generic;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object value){return value!=null;} public static void Destroy(Object value){} }
 public class GameObject:Object {public T AddComponent<T>() where T:new(){return new T();}}
 public class MonoBehaviour:Object {public GameObject gameObject=new GameObject();public T GetComponent<T>() where T:class{return null;}}
}
public class Character:UnityEngine.MonoBehaviour{}
public class Player:Character{public static Player m_localPlayer;}
public class SpawnAbility:UnityEngine.MonoBehaviour {
 public class LevelUpSettings {public int m_maxSpawns,m_setLevel;public float m_skillLevel;}
 public int m_maxSpawned=4;
 public bool m_setMaxInstancesFromWeaponLevel=true;
 public List<LevelUpSettings> m_levelUpSettings=new List<LevelUpSettings>();
}
class Test {
 static void Check(bool value,string message){if(!value)throw new Exception(message);}
 static void Update(object driver){driver.GetType().GetMethod("Update",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(driver,null);}
 static void Main(){
  var p=new Player();Player.m_localPlayer=p;UnlimitedSummonsV1.Configure(p);
  var shared=new List<SpawnAbility.LevelUpSettings>{new SpawnAbility.LevelUpSettings{m_maxSpawns=3,m_setLevel=2,m_skillLevel=100}};
  var ability=new SpawnAbility{m_levelUpSettings=shared};var other=new SpawnAbility{m_levelUpSettings=shared};
  var state=new UnlimitedSummonsStateV1();state.Apply(ability,p);
  Check(ability.m_maxSpawned==0&&!ability.m_setMaxInstancesFromWeaponLevel&&ability.m_levelUpSettings[0].m_maxSpawns==0,"Both summon control gates must be removed");
  Check(ability.m_levelUpSettings!=shared&&ability.m_levelUpSettings[0]!=shared[0]&&shared[0].m_maxSpawns==3&&other.m_maxSpawned==4,"No prefab/shared list mutation");
  Check(ability.m_levelUpSettings[0].m_setLevel==2&&ability.m_levelUpSettings[0].m_skillLevel==100,"Skill thresholds and creature levels retained");
  state.Apply(ability,p);UnlimitedSummonsV1.Disable();Update(state);
  Check(ability.m_maxSpawned==4&&ability.m_setMaxInstancesFromWeaponLevel&&ability.m_levelUpSettings==shared,"Disable restores original cast settings");
  UnlimitedSummonsV1.Configure(p);state.Apply(ability,p);Player.m_localPlayer=new Player();Update(state);Check(ability.m_maxSpawned==4,"World/player change restoration");
  Player.m_localPlayer=p;UnlimitedSummonsV1.OnSetup(other,new Player());Check(other.m_maxSpawned==4&&other.m_levelUpSettings==shared,"Remote caster must retain limits");
  UnlimitedSummonsV1.OnSetup(other,new Character());Check(other.m_maxSpawned==4,"Creature caster must retain limits");
  UnlimitedSummonsV1.OnSetup(ability,p);Check(ability.m_maxSpawned==0&&shared[0].m_maxSpawns==3,"Local native setup applies scoped bypass");
  UnlimitedSummonsV1.Disable();var disabled=new SpawnAbility();UnlimitedSummonsV1.OnSetup(disabled,p);Check(disabled.m_maxSpawned==4,"Disabled casts retain limits");
  Console.WriteLine("PASS: local summon gates removed, shared prefab/settings untouched, summon strength retained, remote/NPC exclusion, disable and player-change restoration");
 }
}
