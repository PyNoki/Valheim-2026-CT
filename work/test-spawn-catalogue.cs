using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}public static string spawned;public static Vector3 point;public static GameObject Instantiate(GameObject prefab,Vector3 p,Quaternion q){spawned=prefab.name;point=p;return new GameObject(prefab.name);}}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}}
 public struct Quaternion {}
 public class Transform {public Quaternion rotation;}
 public class GameObject:Object {public string name;public List<object> components=new List<object>();public GameObject(string n){name=n;}public T GetComponent<T>() where T:class{foreach(var component in components)if(component is T)return component as T;return null;}}
}
public class Character:UnityEngine.Object {public Transform transform=new Transform();}
public class Player:Character {}
public class ZNetView:UnityEngine.Object {}
public class Tameable:UnityEngine.Object {}
public class Plant:UnityEngine.Object {}
public class Pickable:UnityEngine.Object {}
public class MineRock:UnityEngine.Object {}
public class MineRock5:UnityEngine.Object {}
public class ItemDrop:UnityEngine.Object {public ItemData m_itemData=new ItemData();public class ItemData {public enum ItemType {Material,Consumable,Trophy,Weapon}public class SharedData {public ItemType m_itemType;}public SharedData m_shared=new SharedData();}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public Dictionary<string,GameObject> m_namedPrefabs=new Dictionary<string,GameObject>();public GameObject GetPrefab(string name){GameObject prefab;return m_namedPrefabs.TryGetValue(name,out prefab)?prefab:null;}}
class TestSpawnCatalogue {
 static void Check(bool ok,string reason){if(!ok)throw new Exception(reason);}
 static void Register(string name,params object[] components){var prefab=new GameObject(name);prefab.components.Add(new ZNetView());prefab.components.AddRange(components);ZNetScene.instance.m_namedPrefabs[name]=prefab;}
 static bool Reject(Action a){try{a();return false;}catch(InvalidOperationException){return true;}}
 static void Main(){
  Register("Wolf",new Character(),new Tameable());Register("Troll",new Character());Register("ModdedPet",new Character(),new Tameable());Register("Player",new Player());
  Register("Haldor");Register("Hildir");Register("BogWitch");Register("CloudberryBush",new Pickable());Register("CarrotPlant",new Plant());Register("CopperDeposit",new MineRock5());Register("Wood",new ItemDrop());
  var weapon=new ItemDrop();weapon.m_itemData.m_shared.m_itemType=ItemDrop.ItemData.ItemType.Weapon;Register("Sword",weapon);
  SpawnCatalogueV1.Refresh();string text=SpawnCatalogueV1.Catalogue();
  Check(text.Contains("0|Troll")&&text.Contains("0|Wolf")&&text.Contains("3|Wolf")&&text.Contains("3|ModdedPet"),"registered creatures and native tameables discovered dynamically");
  Check(!text.Contains("3|Troll")&&!text.Contains("|Player"),"untameable and player prefabs excluded from taming/player spawn");
  Check(text.Contains("1|Haldor")&&text.Contains("1|BogWitch")&&text.Contains("2|CloudberryBush")&&text.Contains("2|CopperDeposit")&&text.Contains("2|Wood")&&!text.Contains("2|Sword"),"categories keep merchants, plants, harvest nodes and materials separate");
  var player=new Player();SpawnCatalogueV1.Spawn(player,"ModdedPet",3,new Vector3(3,1,0));Check(UnityEngine.Object.spawned=="ModdedPet"&&UnityEngine.Object.point.x==3,"selected native tameable prefab spawned at supplied landing point");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Troll",3,new Vector3())),"cannot force an untameable prefab into taming list");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Player",0,new Vector3())),"player spawn rejected");
  ZNetScene.instance.m_namedPrefabs.Remove("Wolf");Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Wolf",0,new Vector3())),"removed prefab rejected");
  Console.WriteLine("PASS: dynamic monster/merchant/resource/tameable categories, modded pet discovery, selection/position and invalid/player/missing guards.");
 }
}
