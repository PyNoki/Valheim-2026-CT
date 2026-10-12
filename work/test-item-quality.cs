using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
public class ItemDrop {public class ItemData {public class SharedData {public int m_maxQuality=4;}public SharedData m_shared=new SharedData();public int m_quality=1,m_stack=1;public bool m_cheated,m_equipped=true,equipable=true;public float m_durability=50;public bool IsEquipable(){return equipable;}public float GetMaxDurability(){return 100f*m_quality;}}}
public class Inventory {public List<ItemDrop.ItemData> items=new List<ItemDrop.ItemData>();public int notifications;public bool ContainsItem(ItemDrop.ItemData item){return items.Contains(item);}private void Changed(bool success,bool flags){if(success||flags)throw new Exception("No cheated-state notification should be sent");notifications++;}}
public class Humanoid {public int updates;public bool fail;private void UpdateEquipmentStatusEffects(){updates++;if(fail)throw new Exception("equipment update failed");}}
public class Player:Humanoid {public Inventory inventory=new Inventory();public Inventory GetInventory(){return inventory;}}
class TestItemQuality {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static bool Reject(Action a){try{a();return false;}catch{return true;}}
 static void Main(){
  var p=new Player();var item=new ItemDrop.ItemData();p.inventory.items.Add(item);var shared=item.m_shared;
  ItemQualityV1.Set(p,item,10);Check(item.m_quality==10&&item.m_durability==500&&!item.m_cheated,"refinement quality applies without setting cheated flag and preserves wear fraction");
  Check(item.m_shared==shared&&item.m_stack==1&&item.m_equipped&&p.inventory.items[0]==item&&p.inventory.notifications==1&&p.updates==1,"same item, shared data, quantity and equipment preserved; native refresh called");
  ItemQualityV1.Set(p,item,10);Check(p.inventory.notifications==1,"same quality is no-op");
  item.m_cheated=true;ItemQualityV1.Set(p,item,2);Check(item.m_cheated&&item.m_quality==2,"existing cheated flag retained");
  Check(Reject(()=>ItemQualityV1.Set(p,item,0))&&Reject(()=>ItemQualityV1.Set(p,item,1001))&&item.m_quality==2,"invalid quality does not mutate item");
  var berry=new ItemDrop.ItemData{equipable=false};berry.m_shared.m_maxQuality=1;p.inventory.items.Add(berry);Check(Reject(()=>ItemQualityV1.Set(p,berry,10))&&berry.m_quality==1,"non-upgradeable resource rejected");
  p.inventory.items.Remove(item);Check(Reject(()=>ItemQualityV1.Set(p,item,3))&&item.m_quality==2,"removed item rejected");p.inventory.items.Add(item);
  p.fail=true;float previous=item.m_durability;Check(Reject(()=>ItemQualityV1.Set(p,item,4))&&item.m_quality==2&&item.m_durability==previous&&item.m_cheated,"failed refresh rolls back quality and durability");
  Console.WriteLine("PASS: chosen refinement quality, no deliberate cheat marking, existing flag/shared/item preservation, notifications, invalid/stale guards and rollback.");
 }
}
