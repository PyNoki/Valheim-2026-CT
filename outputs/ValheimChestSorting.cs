using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 // All calls run on Unity's game thread. Metadata belongs to the actual chest ZDO.
 public static class ChestSortStorage {
  public const string SharedRoute="shared-world-route-v1";
  const string RoleKey="SoloToolkit.Sort.Role.v1",ItemTagKey="SoloToolkit.Sort.Item.v1",NetworkKey="SoloToolkit.Sort.Network.v1";
  static readonly BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  static readonly MethodInfo Access=typeof(Container).GetMethod("CheckAccess",Flags,null,new Type[]{typeof(long)},null);
  static readonly MethodInfo Load=typeof(Container).GetMethod("Load",Flags);
  static readonly FieldInfo CurrentContainer=typeof(InventoryGui).GetField("m_currentContainer",Flags);
  public static Container OpenChest(Player player){return player&&player==Player.m_localPlayer&&InventoryGui.instance&&InventoryGui.IsVisible()&&CurrentContainer!=null?CurrentContainer.GetValue(InventoryGui.instance) as Container:null;}
  public static bool IsChest(Container chest){return chest&&chest.name.StartsWith("piece_chest",StringComparison.OrdinalIgnoreCase)&&chest.GetComponent<Piece>()&&View(chest)&&View(chest).IsValid();}
  static ZNetView View(Container chest){return chest?chest.GetComponent<ZNetView>():null;}
  static string Read(Container chest,string key){return IsChest(chest)?View(chest).GetZDO().GetString(key,""):"";}
  public static string Role(Container chest){return Read(chest,RoleKey);}
  public static string Item(Container chest){return Read(chest,ItemTagKey);}
  // A legacy single-item value is already a valid one-entry list.
  public static string[] Items(Container chest){return Item(chest).Split(new[]{'\n'},StringSplitOptions.RemoveEmptyEntries);}
  public static bool Accepts(Container chest,string item){foreach(var key in Items(chest))if(string.Equals(key,item,StringComparison.Ordinal))return true;return false;}
  public static string Network(Container chest){return Read(chest,NetworkKey);}
  public static string Identity(Container chest){return IsChest(chest)?View(chest).GetZDO().m_uid.ToString():"";}
  public static string ItemKey(ItemDrop.ItemData item){return item!=null&&item.m_dropPrefab?item.m_dropPrefab.name:"";}
  public static bool Accessible(Container chest,Player player){
   return IsChest(chest)&&player
    &&Access!=null&&(bool)Access.Invoke(chest,new object[]{player.GetPlayerID()})&&PrivateArea.CheckAccess(chest.transform.position,0,false,false);
  }
  public static void Ready(Container chest,Player player){
   if(!Accessible(chest,player))throw new InvalidOperationException("Chest is unavailable or protected.");
   bool localOpen=OpenChest(player)==chest;
   if(chest.IsInUse()&&!localOpen)throw new InvalidOperationException("Someone is using this chest. Try another chest.");
   // Never seize a chest from a remote owner or write a stale client inventory.
   if(!View(chest).IsOwner())throw new InvalidOperationException("Open and close this chest with E first, then try F9 again.");
   if(Load==null)throw new MissingMethodException("Container.Load is unavailable.");
   if(!localOpen)Load.Invoke(chest,null);
   if(chest.GetInventory()==null)throw new InvalidOperationException("Chest inventory is not ready.");
  }
  public static void MakeSource(Container chest,Player player){
   Ready(chest,player);var zdo=View(chest).GetZDO();
   zdo.Set(ItemTagKey,"");zdo.Set(NetworkKey,SharedRoute);zdo.Set(RoleKey,"source");
  }
  public static void Assign(Container chest,Container source,Player player,string item){
   AssignItems(chest,source,player,new[]{item});
  }
  // Older callers can still pass a master; destination filters now belong to the shared route.
  public static void AssignItems(Container chest,Container source,Player player,IEnumerable<string> items){
   AssignItems(chest,player,items);
  }
  public static void AssignItems(Container chest,Player player,IEnumerable<string> items){
   Ready(chest,player);
   if(Role(chest)=="source")throw new InvalidOperationException("Choose a separate destination chest.");
   var allowed=new HashSet<string>(StringComparer.Ordinal);
   if(Role(chest)=="destination")foreach(var key in Items(chest))allowed.Add(key);
   foreach(var entry in chest.GetInventory().GetAllItems())if(!entry.m_shared.m_questItem&&!entry.m_equipped)allowed.Add(ItemKey(entry));
   var selected=new HashSet<string>(StringComparer.Ordinal);
   if(items==null)throw new InvalidOperationException("Select at least one item.");
   foreach(var item in items){
    if(string.IsNullOrEmpty(item)||item.IndexOfAny(new[]{'\n','\r'})>=0||!allowed.Contains(item))throw new InvalidOperationException("Put one sample of each new item in this chest first.");
    selected.Add(item);
   }
   if(selected.Count==0)throw new InvalidOperationException("Select at least one item, or remove the chest assignment.");
   var names=new List<string>(selected);names.Sort(StringComparer.Ordinal);
   var zdo=View(chest).GetZDO();zdo.Set(ItemTagKey,string.Join("\n",names.ToArray()));zdo.Set(NetworkKey,SharedRoute);zdo.Set(RoleKey,"destination");
  }
  public static void Clear(Container chest,Player player){
   Ready(chest,player);var zdo=View(chest).GetZDO();zdo.Set(RoleKey,"");zdo.Set(ItemTagKey,"");zdo.Set(NetworkKey,"");
  }
  // Existing destination roles/filters join the shared route without rewriting
  // old chest records, even if their original master has been removed.
  public static bool Linked(Container chest,Container source){return chest!=source&&IsChest(source)&&Role(source)=="source"&&Role(chest)=="destination";}
  public static string Sort(Container source,Player player,IEnumerable<Container> loaded){
   Ready(source,player);if(Role(source)!="source")throw new InvalidOperationException("Mark a sorting chest first.");
   var targets=new List<Container>();var seen=new HashSet<string>();int skipped=0;
   foreach(var chest in loaded){
    if(!Linked(chest,source)||!seen.Add(Identity(chest)))continue;
    if(!Accessible(chest,player)||chest.IsInUse()||!View(chest).IsOwner()){skipped++;continue;}
    targets.Add(chest);
   }
   targets.Sort(delegate(Container a,Container b){int distance=Vector3.Distance(a.transform.position,source.transform.position).CompareTo(Vector3.Distance(b.transform.position,source.transform.position));return distance!=0?distance:StringComparer.Ordinal.Compare(Identity(a),Identity(b));});
   var inventory=source.GetInventory();int moved=0;
   // A snapshot prevents native transfers changing the list being enumerated.
   foreach(var item in new List<ItemDrop.ItemData>(inventory.GetAllItems())){
    if(item==null||item.m_shared.m_questItem||item.m_equipped||string.IsNullOrEmpty(ItemKey(item)))continue;
    foreach(var target in targets){
     if(!inventory.ContainsItem(item))break;
     if(!Accepts(target,ItemKey(item)))continue;
     // Revalidate immediately before each transfer, including network ownership.
     Ready(source,player);Ready(target,player);
     if(!inventory.ContainsItem(item))break;
     int before=item.m_stack;
     target.GetInventory().MoveItemToThis(inventory,item);
     moved+=Math.Max(0,before-(inventory.ContainsItem(item)?item.m_stack:0));
     // Native Changed callbacks save both containers; no cloning or item recreation.
    }
   }
   int remaining=0;foreach(var item in inventory.GetAllItems())remaining+=item.m_stack;
   return "Moved "+moved+" items. "+remaining+" remain (unmatched, unavailable or no room). Loaded chests only."+(skipped>0?" Skipped "+skipped+" busy, protected or remotely owned chests.":"");
  }
 }
}
