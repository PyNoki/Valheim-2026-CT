using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}public static string spawned;public static Vector3 point;public static GameObject last;public static int spawns;public static GameObject Instantiate(GameObject prefab,Vector3 p,Quaternion q){spawns++;spawned=prefab.name;point=p;last=new GameObject(prefab.name);if(prefab.GetComponent<Character>())last.components.Add(new Character());return last;}}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}}
 public struct Quaternion {}
 public class Transform {public Quaternion rotation;}
 public class GameObject:Object {public string name;public List<object> components=new List<object>();public GameObject(string n){name=n;}public T GetComponent<T>() where T:class{foreach(var component in components)if(component is T)return component as T;return null;}}
}
public class Character:UnityEngine.Object {public Transform transform=new Transform();public int level=1;public void SetLevel(int value){level=value;}}
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
  var player=new Player();SpawnCatalogueV1.Spawn(player,"ModdedPet",3,new Vector3(3,1,0),0);Check(UnityEngine.Object.spawned=="ModdedPet"&&UnityEngine.Object.point.x==3,"selected native tameable prefab spawned at supplied landing point");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Troll",3,new Vector3(),0)),"cannot force an untameable prefab into taming list");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Player",0,new Vector3(),0)),"player spawn rejected");
  ZNetScene.instance.m_namedPrefabs.Remove("Wolf");Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Wolf",0,new Vector3(),0)),"removed prefab rejected");
  foreach(int kind in new[]{0,3})foreach(int stars in new[]{0,1,2}){
   string message=SpawnCatalogueV1.Spawn(player,"ModdedPet",kind,new Vector3(),stars);Check(UnityEngine.Object.last.GetComponent<Character>().level==stars+1,"stars map to native level on the spawned instance");Check(message.Contains(stars+" stars"),"status reports selected stars");Check(ZNetScene.instance.GetPrefab("ModdedPet").GetComponent<Character>().level==1,"prefab level unchanged");
  }
  int before=UnityEngine.Object.spawns;
  foreach(int stars in new[]{-1,3})Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Troll",0,new Vector3(),stars)),"invalid star count rejected");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Haldor",1,new Vector3(),2)),"merchant stars rejected");
  Check(Reject(()=>SpawnCatalogueV1.Spawn(player,"Wood",2,new Vector3(),1)),"resource stars rejected");
  Check(UnityEngine.Object.spawns==before,"invalid selections never instantiate");
  SpawnCatalogueV1.Spawn(player,"Haldor",1,new Vector3(),0);SpawnCatalogueV1.Spawn(player,"Wood",2,new Vector3(),0);
  string valid=SpawnCatalogueV1.Catalogue();var registered=ZNetScene.instance.m_namedPrefabs;
  ZNetScene.instance.m_namedPrefabs=new Dictionary<string,GameObject>();
  Check(Reject(()=>SpawnCatalogueV1.Refresh()),"empty registry reports not ready");
  Check(SpawnCatalogueV1.Catalogue()==valid,"empty refresh preserves catalogue");
  ZNetScene.instance.m_namedPrefabs=registered;
  SpawnCatalogueV1.Spawn(player,"Troll",0,new Vector3(),0);
  Check(Reject(()=>{ZNetScene.instance=null;SpawnCatalogueV1.Refresh();}),"world unavailable refresh rejected");
  Check(SpawnCatalogueV1.Catalogue()==valid,"failed refresh preserves catalogue");
  ZNetScene.instance=new ZNetScene{m_namedPrefabs=registered};
  Console.WriteLine("PASS: 0/1/2 stars and native levels, unchanged prefabs, star guards, dynamic monster/merchant/resource/tameable categories, modded pet discovery, selection/position and invalid/player/missing guards.");
 }
}
