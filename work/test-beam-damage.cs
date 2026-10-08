using System;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}public static int destroyed;public static void Destroy(Object o){destroyed++;}}
 public class Transform {public Vector3 position;}
 public class GameObject:Object {public ItemDrop item;public GameObject(string n){}public T GetComponent<T>()where T:class{return item as T;}}
 public static class Mathf {public static int CeilToInt(float f){return (int)Math.Ceiling(f);}public static float Min(float a,float b){return Math.Min(a,b);}}
 public struct Vector3 { public float x,y,z; public Vector3(float a,float b,float c){x=a;y=b;z=c;}public static Vector3 operator+(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);} public static Vector3 operator*(Vector3 a,float n){return new Vector3(a.x*n,a.y*n,a.z*n);} }
 public class Collider {public Character character;public IDestructible target;public static implicit operator bool(Collider c){return c!=null;}public T GetComponentInParent<T>()where T:class {return typeof(T)==typeof(Character)?character as T:target as T;}public Vector3 ClosestPoint(Vector3 p){return p;}}
 public enum QueryTriggerInteraction {Ignore}
 public static class Physics {public static Collider[] hits;public static int calls;public static Collider[] OverlapCapsule(Vector3 a,Vector3 b,float r,int mask,QueryTriggerInteraction q){if(b.z!=80||r!=1.6f||mask!=-1)throw new Exception("Incomplete beam query");calls++;return hits;}}
}
public interface IDestructible {void Damage(HitData hit);}
public class Character:IDestructible {public int hits;public HitData last;public void Damage(HitData hit){hits++;last=hit;}}
public class Player:Character {}
public class Prop:IDestructible {public int hits;public HitData last;public void Damage(HitData hit){hits++;last=hit;}}
public class HitData {public struct DamageTypes {public float m_damage,m_chop,m_pickaxe;}public DamageTypes m_damage;public short m_toolTier;public Collider m_hitCollider;public Vector3 m_point,m_dir;public bool m_ranged;public Skills.SkillType m_skill;public Player attacker;public void SetAttacker(Player p){attacker=p;}}
public class Skills {public enum SkillType {None}}
public class Heightmap {public static bool loaded=true;public static bool GetHeight(Vector3 p,out float h){h=10;return loaded;}}
public class ItemDrop:UnityEngine.Object {public ItemData m_itemData=new ItemData();public class ItemData {public SharedData m_shared=new SharedData();}public class SharedData {public GameObject m_spawnOnHitTerrain;}}
public class ZNetScene {public static ZNetScene instance=new ZNetScene();public GameObject prefab;public GameObject GetPrefab(string name){if(name!="PickaxeIron")throw new Exception("Wrong pickaxe");return prefab;}}
public class Attack {public static GameObject registeredDig;public static int edits;public static float farthest;public static GameObject SpawnOnHitTerrain(Vector3 p,GameObject prefab,Character owner,float noise,ItemDrop.ItemData weapon,ItemDrop.ItemData ammo,bool random){if(prefab!=registeredDig||p.y!=10||owner==null||weapon!=ZNetScene.instance.prefab.item.m_itemData)throw new Exception("Unregistered or incorrect native terrain impact");edits++;farthest=Math.Max(farthest,p.z);return null;}}
class Tests {
 static void Check(bool ok,string message){if(!ok)throw new Exception(message);}
 static void Main(){
  var owner=new Player();var pet=new Character();var otherPlayer=new Player();var building=new Prop();var rock=new Prop();var tree=new Prop();
  Physics.hits=new[]{new Collider{character=owner,target=owner},new Collider(),new Collider{target=building},new Collider{target=building},new Collider{target=rock},new Collider{target=tree},new Collider{character=pet,target=pet},new Collider{character=otherPlayer,target=otherPlayer},null};
  BeamDamage.Death(owner,new Vector3(),new Vector3(0,0,1),80,1.6f);
  Check(owner.hits==0,"Caster damaged");Check(building.hits==1&&rock.hits==1&&tree.hits==1,"Props beyond obstruction or collider dedup failed");
  Check(pet.hits==1&&otherPlayer.hits==1,"All creature damage dispatch failed");
  Check(rock.last.m_hitCollider!=null&&rock.last.m_toolTier==100&&rock.last.m_damage.m_pickaxe==500&&tree.last.m_damage.m_chop==500&&building.last.m_damage.m_damage==500&&building.last.attacker==owner,"Damage metadata missing");
  BeamDamage.Death(owner,new Vector3(),new Vector3(0,0,1),80,1.6f);Check(building.hits==2&&Physics.calls==2,"Damage ticks did not reset dedup");
  System.Console.WriteLine("PASS: full-length all-layer death beam query, terrain without damage handler ignored, props/pets/players dispatched, caster excluded, multi-collider dedup, repeat tick and hit metadata");
  var blastSeen=new System.Collections.Generic.HashSet<IDestructible>();int prior=building.hits;
  BeamDamage.Hit(owner,Physics.hits[2],new Vector3(),new Vector3(0,1,0),20000,blastSeen);
  BeamDamage.Hit(owner,Physics.hits[3],new Vector3(),new Vector3(0,1,0),20000,blastSeen);
  BeamDamage.Hit(owner,Physics.hits[0],new Vector3(),new Vector3(0,1,0),20000,blastSeen);
  Check(building.hits==prior+1&&building.last.m_damage.m_damage==20000&&owner.hits==0,"Bomb damage/dedup across batches or owner exclusion failed");
  Attack.registeredDig=new GameObject("digg_v2");ZNetScene.instance.prefab=new GameObject("PickaxeIron");ZNetScene.instance.prefab.item=new ItemDrop();ZNetScene.instance.prefab.item.m_itemData.m_shared.m_spawnOnHitTerrain=Attack.registeredDig;int cursor=0;BeamTerrain.Excavate(owner,new Vector3(0,20,0),new Vector3(0,0,1),80,1.6f,ref cursor);Check(Attack.edits==0,"Air beam excavated terrain");
  cursor=0;BeamTerrain.Excavate(owner,new Vector3(0,8,0),new Vector3(0,0,1),80,1.6f,ref cursor);Check(Attack.edits==6&&cursor==6,"Terrain work not bounded");
  for(int i=0;i<6;i++)BeamTerrain.Excavate(owner,new Vector3(0,8,0),new Vector3(0,0,1),80,1.6f,ref cursor);
  Check(Attack.farthest==80,"Full path excavation or cleanup failed");
  int before=Attack.edits;Heightmap.loaded=false;BeamTerrain.Excavate(owner,new Vector3(),new Vector3(0,0,1),80,1.6f,ref cursor);Check(Attack.edits==before,"Unloaded terrain edited");
  System.Console.WriteLine("PASS: terrain penetration, air/unloaded guards, native lowering operations, full-range bounded sweeps and registered pickaxe prefab dispatch");
 }
}
