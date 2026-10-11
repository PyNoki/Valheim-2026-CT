using System;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class ReplenishV1 {
  [ThreadStatic] static ItemDrop.ItemData prepared;
  public static Inventory Prepare(Inventory target,Inventory source,ItemDrop.ItemData item) {
   prepared=null;
   var player=Player.m_localPlayer;
   if(!player || source!=player.GetInventory() || target==source || item==null || !source.ContainsItem(item))return null;
   var copy=item.Clone();copy.m_equipped=false;copy.m_gridPos=new Vector2i(0,0);
   var temporary=new Inventory("Replenish transfer",null,1,1);
   if(!temporary.AddItem(copy))return null;
   prepared=copy;return temporary;
  }
  public static ItemDrop.ItemData Copy(){var copy=prepared;prepared=null;return copy;}
  // -1 = native path, 0 = handled but declined, 1 = dropped successfully.
  public static int Drop(Humanoid actor,Inventory source,ItemDrop.ItemData item,int amount){
   var player=Player.m_localPlayer;
   if(!player || actor!=player || (source!=null && source!=player.GetInventory()))return -1;
   if(item==null || !player.GetInventory().ContainsItem(item) || item.m_shared.m_questItem || amount<=0)return -1;
   try {
    var copy=item.Clone();copy.m_equipped=false;
    var drop=ItemDrop.DropItem(copy,Math.Min(amount,item.m_stack),player.transform.position+player.transform.forward+Vector3.up,player.transform.rotation);
    if(!drop)return 0;
    drop.OnPlayerDrop();var body=drop.GetComponent<Rigidbody>();
    if(body)body.linearVelocity=(player.transform.forward+Vector3.up)*(item.GetWeight()<200f?5f:0.5f);
    return 1;
   }catch(Exception e){Debug.LogWarning("Replenish drop failed: "+e.Message);return 0;}
  }
 }
}
