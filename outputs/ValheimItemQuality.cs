using System;
using System.Reflection;
namespace ValheimSoloToolkit {
 public static class ItemQualityV1 {
  const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  public static string Set(Player player,ItemDrop.ItemData item,int quality){
   if(quality<1||quality>1000)throw new ArgumentException("Choose quality 1-1000.");
   if(item==null||item.m_shared==null||!player.GetInventory().ContainsItem(item))throw new InvalidOperationException("Selected item left your inventory. Refresh and select it again.");
   if(!item.IsEquipable()&&item.m_shared.m_maxQuality<=1)throw new InvalidOperationException("This item has no equipment quality upgrades.");
   if(item.m_quality==quality)return "Selected item is already quality "+quality+".";
   int previous=item.m_quality;float durability=item.m_durability;float oldMax=item.GetMaxDurability();
   try {
    item.m_quality=quality;float newMax=item.GetMaxDurability();
    if(float.IsNaN(newMax)||float.IsInfinity(newMax)||newMax<0)throw new InvalidOperationException("This quality produced invalid durability.");
    item.m_durability=oldMax>0?newMax*Math.Max(0f,Math.Min(1f,durability/oldMax)):0f;
    // No change to m_cheated, shared item definitions, stack count or item identity.
    typeof(Inventory).GetMethod("Changed",Flags).Invoke(player.GetInventory(),new object[]{false,false});
    typeof(Humanoid).GetMethod("UpdateEquipmentStatusEffects",Flags).Invoke(player,null);
   }catch {
    item.m_quality=previous;item.m_durability=durability;throw;
   }
   return "Selected item quality changed from "+previous+" to "+quality+". Existing cheated flag unchanged; normal maximum is "+item.m_shared.m_maxQuality+".";
  }
 }
}
