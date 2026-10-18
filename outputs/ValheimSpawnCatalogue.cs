using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class SpawnCatalogueV1 {
  static HashSet<string>[] groups={new HashSet<string>(),new HashSet<string>(),new HashSet<string>(),new HashSet<string>()};
  static string catalogue="";
  public static string Catalogue(){return catalogue;}
  static bool Merchant(string name){return name=="Haldor"||name=="Hildir"||name=="BogWitch";}
  public static string Refresh(){
   if(!ZNetScene.instance)throw new InvalidOperationException("Load your world first.");
   var field=typeof(ZNetScene).GetField("m_namedPrefabs",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
   var prefabs=field==null?null:field.GetValue(ZNetScene.instance) as IDictionary;
   if(prefabs==null)throw new InvalidOperationException("Registered prefab catalogue is unavailable.");
   // Build privately so an incomplete/failed refresh keeps the last valid lists.
   var groups=new[]{new HashSet<string>(),new HashSet<string>(),new HashSet<string>(),new HashSet<string>()};
   foreach(GameObject prefab in prefabs.Values){
    if(!prefab||!prefab.GetComponent<ZNetView>())continue;
    string name=prefab.name;if(string.IsNullOrEmpty(name)||name.IndexOfAny(new[]{'|','\r','\n'})>=0)continue;
    if(Merchant(name)){groups[1].Add(name);continue;}
    var creature=prefab.GetComponent<Character>();
    if(creature){
     if(prefab.GetComponent<Player>())continue;
     groups[0].Add(name);
     if(prefab.GetComponent<Tameable>())groups[3].Add(name);
     continue;
    }
    bool resource=prefab.GetComponent<Pickable>()||prefab.GetComponent<Plant>()||prefab.GetComponent<MineRock>()||prefab.GetComponent<MineRock5>()||name.IndexOf("Bush",StringComparison.OrdinalIgnoreCase)>=0;
    var drop=prefab.GetComponent<ItemDrop>();
    if(drop&&drop.m_itemData!=null&&drop.m_itemData.m_shared!=null){var type=drop.m_itemData.m_shared.m_itemType;resource|=type==ItemDrop.ItemData.ItemType.Material||type==ItemDrop.ItemData.ItemType.Consumable||type==ItemDrop.ItemData.ItemType.Trophy;}
    if(resource)groups[2].Add(name);
   }
   var rows=new List<string>();
   for(int kind=0;kind<groups.Length;kind++){var names=new List<string>(groups[kind]);names.Sort(StringComparer.OrdinalIgnoreCase);foreach(var name in names)rows.Add(kind+"|"+name);}
   if(rows.Count==0)throw new InvalidOperationException("World prefabs are not ready. Return to Valheim, press Esc to close the pause menu, then refresh the spawn catalogue again.");
   catalogue=string.Join("\n",rows.ToArray());
   SpawnCatalogueV1.groups=groups;
   return "Loaded "+groups[0].Count+" creatures, "+groups[1].Count+" merchants, "+groups[2].Count+" resources and "+groups[3].Count+" native tameable creatures.";
  }
  public static string Spawn(Player player,string name,int kind,Vector3 point,int stars){
   if(stars<0||stars>2||((kind!=0&&kind!=3)&&stars!=0))throw new InvalidOperationException("Choose 0, 1 or 2 stars for creatures only.");
   if(kind<0||kind>3||name==null||!groups[kind].Contains(name))throw new InvalidOperationException("Select a registered prefab from the current catalogue; refresh the list first.");
   var prefab=ZNetScene.instance.GetPrefab(name);
   if(!prefab||!prefab.GetComponent<ZNetView>())throw new InvalidOperationException("Selected prefab is no longer available.");
   if((kind==0||kind==3)&&(!prefab.GetComponent<Character>()||prefab.GetComponent<Player>()))throw new InvalidOperationException("This prefab is not a spawnable creature.");
   if(kind==3&&!prefab.GetComponent<Tameable>())throw new InvalidOperationException("This creature no longer has native taming support.");
   var spawned=UnityEngine.Object.Instantiate(prefab,point,player.transform.rotation);
   if(!spawned)throw new InvalidOperationException("Game did not create the selected prefab.");
   if(kind==0||kind==3)spawned.GetComponent<Character>().SetLevel(stars+1);
   return "Spawned "+name+((kind==0||kind==3)?" ("+stars+" stars)":"")+"."+(kind==3?" Native default tame state applies; use wheel-click taming if needed.":"");
  }
 }
}
