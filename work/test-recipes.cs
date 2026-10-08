using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}}
 public class GameObject:Object {public object component;public T GetComponent<T>()where T:class{return component as T;}}
}
public class Player:UnityEngine.Object {public static Player m_localPlayer;public HashSet<string> m_knownRecipes=new HashSet<string>();public bool dead,teleporting,noCost;public int refreshes;public bool IsDead(){return dead;}public bool IsTeleporting(){return teleporting;}private void UpdateAvailablePiecesList(){refreshes++;}}
public class ItemDrop:UnityEngine.Object {public ItemData m_itemData=new ItemData();public class ItemData {public SharedData m_shared=new SharedData();}public class SharedData {public string m_name;public PieceTable m_buildPieces;}}
public class PieceTable:UnityEngine.Object {public List<UnityEngine.GameObject> m_pieces=new List<UnityEngine.GameObject>();}
public class Piece:UnityEngine.Object {public string m_name;public bool m_enabled=true;}
public class Recipe:UnityEngine.Object {public bool m_enabled=true;public ItemDrop m_item;}
public class ObjectDB:UnityEngine.Object {public static ObjectDB instance;public List<Recipe> m_recipes=new List<Recipe>();public List<UnityEngine.GameObject> m_items=new List<UnityEngine.GameObject>();}
class Tests {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static ItemDrop Item(string name){var i=new ItemDrop();i.m_itemData.m_shared.m_name=name;return i;}
 static void Main(){
  var p=new Player();Player.m_localPlayer=p;p.m_knownRecipes.Add("existing");ObjectDB.instance=new ObjectDB();
  ObjectDB.instance.m_recipes.Add(new Recipe{m_item=Item("forge sword")});ObjectDB.instance.m_recipes.Add(new Recipe{m_item=Item("forge sword")});
  ObjectDB.instance.m_recipes.Add(new Recipe{m_enabled=false,m_item=Item("disabled")});ObjectDB.instance.m_recipes.Add(null);
  var tool=Item("hammer");tool.m_itemData.m_shared.m_buildPieces=new PieceTable();
  tool.m_itemData.m_shared.m_buildPieces.m_pieces.Add(new UnityEngine.GameObject{component=new Piece{m_name="forge"}});
  tool.m_itemData.m_shared.m_buildPieces.m_pieces.Add(new UnityEngine.GameObject{component=new Piece{m_name="disabled piece",m_enabled=false}});
  ObjectDB.instance.m_items.Add(new UnityEngine.GameObject{component=tool});ObjectDB.instance.m_items.Add(null);
  LearnRecipesV1.Configure(p);Check(p.m_knownRecipes.Count==1,"Configure changed game state off-thread");LearnRecipesV1.Tick(new Player());Check(LearnRecipesV1.Enabled==1,"Other player consumed grant");
  LearnRecipesV1.Tick(p);Check(p.m_knownRecipes.SetEquals(new[]{"existing","forge sword","forge"})&&p.refreshes==1&&!p.noCost&&LearnRecipesV1.Enabled==0,"Recipe grant scope/refresh");
  LearnRecipesV1.Tick(p);Check(p.refreshes==1,"One-shot repeated");LearnRecipesV1.Configure(p);LearnRecipesV1.Tick(p);Check(LearnRecipesV1.Status.Contains("0 new"),"Repeat grant not idempotent");
  LearnRecipesV1.Configure(p);LearnRecipesV1.Disable();LearnRecipesV1.Tick(p);Check(p.refreshes==2,"Cancelled grant applied");
  LearnRecipesV1.Configure(p);Player.m_localPlayer=new Player();LearnRecipesV1.Tick(p);Check(LearnRecipesV1.Enabled==0&&p.refreshes==2,"World swap guard");
  Player.m_localPlayer=p;p.dead=true;LearnRecipesV1.Configure(p);LearnRecipesV1.Tick(p);Check(LearnRecipesV1.Status.Contains("Wait until alive")&&p.refreshes==2,"Dead player modified");
  System.Console.WriteLine("PASS: queued main-thread grant, local-player ownership, craft/build discovery, disabled/null filtering, dedup, existing knowledge, repeat/cancel/death/world guards, no free-crafting changes");
 }
}
