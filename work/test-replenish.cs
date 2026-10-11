using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
using UnityEngine;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}}
 public class Transform {public Vector3 position,forward;public Quaternion rotation;}
 public struct Vector3 {public static Vector3 up{get{return new Vector3();}}public static Vector3 operator +(Vector3 a,Vector3 b){return a;}public static Vector3 operator *(Vector3 a,float b){return a;}}
 public struct Quaternion {}
 public class Rigidbody {public Vector3 linearVelocity;public static implicit operator bool(Rigidbody o){return o!=null;}}
 public static class Debug {public static void LogWarning(string s){}}
}
public struct Vector2i {public int x,y;public Vector2i(int a,int b){x=a;y=b;}}
public class Humanoid:UnityEngine.Object {public Transform transform=new Transform();}
public class Player:Humanoid {public static Player m_localPlayer;public Inventory inv=new Inventory("player",null,8,4);public Inventory GetInventory(){return inv;}}
public class ItemDrop:UnityEngine.Object {
 public class ItemData {public class SharedData {public bool m_questItem,m_teleportable;public int m_toolTier;}public bool m_equipped;public Vector2i m_gridPos;public int m_stack;public SharedData m_shared=new SharedData();public ItemData Clone(){return (ItemData)MemberwiseClone();}public float GetWeight(){return 1;}}
 public static int drops,quantity;public static ItemDrop DropItem(ItemData item,int amount,Vector3 p,Quaternion q){drops++;quantity=amount;return new ItemDrop();}
 public void OnPlayerDrop(){}public T GetComponent<T>() where T:class {return null;}
}
public class Inventory {
 public List<ItemDrop.ItemData> items=new List<ItemDrop.ItemData>();public bool full;
 public List<ItemDrop.ItemData> GetAllItems(){return items;}
 public Inventory(string name,object icon,int w,int h){}
 public bool ContainsItem(ItemDrop.ItemData item){return items.Contains(item);}public bool AddItem(ItemDrop.ItemData item){items.Add(item);return true;}
 public bool Transfer(Inventory source,ItemDrop.ItemData copy,int amount){if(full)return false;copy.m_stack-=amount;if(copy.m_stack==0)source.items.Remove(copy);return true;}
}
class TestReplenish {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  var p=new Player();Player.m_localPlayer=p;var item=new ItemDrop.ItemData{m_stack=50,m_equipped=true,m_gridPos=new Vector2i(3,2)};p.inv.AddItem(item);var chest=new Inventory("chest",null,8,4);
  var temp=ReplenishV1.Prepare(chest,p.inv,item);var copy=ReplenishV1.Copy();Check(temp!=null&&copy!=item&&temp.ContainsItem(copy)&&!copy.m_equipped,"copy belongs to temporary inventory");
  chest.Transfer(temp,copy,10);Check(item.m_stack==50&&p.inv.ContainsItem(item)&&item.m_equipped&&item.m_gridPos.x==3,"partial deposit preserves source and slot");
  temp=ReplenishV1.Prepare(chest,p.inv,item);copy=ReplenishV1.Copy();chest.full=true;Check(!chest.Transfer(temp,copy,50)&&item.m_stack==50,"full destination retains source");
  Check(ReplenishV1.Prepare(p.inv,p.inv,item)==null,"same inventory passthrough");Check(ReplenishV1.Prepare(p.inv,chest,item)==null,"withdrawals passthrough");
  Check(ReplenishV1.Drop(p,p.inv,item,10)==1&&ItemDrop.quantity==10&&item.m_stack==50,"partial ground drop replenishes");
  Check(ReplenishV1.Drop(p,null,item,99)==1&&ItemDrop.quantity==50&&p.inv.ContainsItem(item),"full ground drop clamps quantity and keeps original");
  item.m_shared.m_questItem=true;Check(ReplenishV1.Drop(p,p.inv,item,10)==-1,"quest items keep native restriction");item.m_shared.m_questItem=false;
  Check(ReplenishV1.Drop(new Player(),p.inv,item,10)==-1,"other players passthrough");Check(ReplenishV1.Drop(p,chest,item,10)==-1,"container drops passthrough");
  Check(ItemDrop.drops==2,"no extra ground items");Console.WriteLine("PASS: partial/full deposits and drops, source slot/equipment preservation, full destination, quest and ownership guards.");
 }
}
