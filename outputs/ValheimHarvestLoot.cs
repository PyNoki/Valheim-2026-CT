using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class HarvestLootV1 {
  static HarvestLootDriver driver;
  public static string HarvestStatus="Auto harvest disabled.",MagnetStatus="Loot magnet disabled.";
  public static int State(){return driver==null?0:(driver.Harvest?1:0)|(driver.Mode<<1);}
  public static void StopAll(){if(driver!=null){driver.Cancelled=true;driver=null;}HarvestStatus="Auto harvest disabled.";MagnetStatus="Loot magnet disabled.";}
  public static void StopHarvest(){if(driver!=null)driver.Harvest=false;HarvestStatus="Auto harvest disabled.";}
  public static void StopMagnet(){if(driver!=null)driver.Mode=0;MagnetStatus="Loot magnet disabled.";}
  public static string Configure(Player p,int mode,int radius){
   if(radius<5||radius>500)throw new ArgumentException("Choose a radius from 5 to 500 metres.");
   if(!driver||driver.Owner!=p||driver.World!=ZNet.instance.GetWorldUID()){StopAll();driver=new GameObject("Toolkit_HarvestLoot").AddComponent<HarvestLootDriver>();driver.Owner=p;driver.World=ZNet.instance.GetWorldUID();driver.Prepare();}
   if(mode==36){driver.Harvest=!driver.Harvest;return HarvestStatus=driver.Harvest?"Auto harvest active: ripe cultivator crops within 20m. Harvest drops fly to your inventory.":"Auto harvest disabled.";}
   if(mode==37||mode==38){int wanted=mode-36;driver.Mode=driver.Mode==wanted?0:wanted;driver.Radius=radius;return MagnetStatus=driver.Mode==0?"Loot magnet disabled.":(driver.Mode==1?"Cheated-item magnet":"All-loot magnet")+" active within "+radius+"m (loaded drops only).";}
   throw new ArgumentException("Invalid loot action.");
  }
 }
 public sealed class HarvestLootDriver:MonoBehaviour {
  public Player Owner;public long World;public volatile bool Cancelled,Harvest;public volatile int Mode;public float Radius=100;
  static readonly MethodInfo SaveDrop=typeof(ItemDrop).GetMethod("Save",BindingFlags.Instance|BindingFlags.NonPublic|BindingFlags.Public);
  static readonly FieldInfo Drops=typeof(ItemDrop).GetField("s_instances",BindingFlags.Static|BindingFlags.NonPublic|BindingFlags.Public);
  readonly HashSet<int> cropPrefabs=new HashSet<int>(),seenDrops=new HashSet<int>();readonly List<ItemDrop> cropLoot=new List<ItemDrop>();
  readonly List<Ticket> tickets=new List<Ticket>();readonly Dictionary<int,float> picked=new Dictionary<int,float>();
  struct Ticket {public Vector3 Point;public string Item;public float Until;}
  float scanTime;int harvested,collected,cursor;ItemDrop[] snapshot=new ItemDrop[0];
  public void Prepare(){
   var cultivator=ZNetScene.instance.GetPrefab("Cultivator").GetComponent<ItemDrop>();
   foreach(var go in cultivator.m_itemData.m_shared.m_buildPieces.m_pieces){var plant=go?go.GetComponent<Plant>():null;if(!plant)continue;foreach(var grown in plant.m_grownPrefabs)if(grown&&grown.GetComponent<Pickable>())cropPrefabs.Add(grown.name.GetStableHashCode());}
   foreach(var drop in CurrentDrops())if(drop)seenDrops.Add(drop.GetInstanceID());
  }
  static ItemDrop[] CurrentDrops(){var list=Drops.GetValue(null) as List<ItemDrop>;return list==null?new ItemDrop[0]:list.ToArray();}
  void Update(){try{
   if(Cancelled){Destroy(gameObject);return;}
   if(!Owner||Owner!=Player.m_localPlayer||Owner.IsDead()||Owner.IsTeleporting()||!ZNet.instance||ZNet.instance.GetWorldUID()!=World){HarvestLootV1.StopAll();Destroy(gameObject);return;}
   if(!Harvest){tickets.Clear();cropLoot.Clear();}
   if(!Harvest&&Mode==0)return;
   if(Time.time>=scanTime){scanTime=Time.time+0.5f;snapshot=CurrentDrops();if(Harvest)HarvestCrops();TrackHarvestDrops();}
   int examined=Math.Min(64,snapshot.Length);for(int i=0;i<examined;i++){var drop=snapshot[(cursor+i)%snapshot.Length];if(!drop)continue;
    var view=drop.GetComponent<ZNetView>();if(!view||!view.IsValid())continue;
    drop.Load();var item=drop.m_itemData;if(item==null)continue;
    bool room=Owner.GetInventory().CanAddItem(item,item.m_stack);bool crop=cropLoot.Contains(drop);
    float distance=(drop.transform.position-Owner.transform.position).sqrMagnitude;
    if(!crop&&!LootPolicy.Eligible(Mode,item.m_cheated,drop.IsPiece(),room,distance,Radius))continue;
    if(drop.IsPiece()||!room||drop.InTar()||!PrivateArea.CheckAccess(drop.transform.position,0,false,false))continue;
    if(!view.IsOwner()){float last;int id=drop.GetInstanceID();if(!picked.TryGetValue(id,out last)||Time.time-last>2){drop.RequestOwn();picked[id]=Time.time;}continue;}
    var destination=Owner.transform.position+Vector3.up*0.8f;var position=Vector3.MoveTowards(drop.transform.position,destination,120f*Time.deltaTime);
    var body=drop.GetComponent<Rigidbody>();if(body){body.linearVelocity=Vector3.zero;body.position=position;}drop.transform.position=position;view.GetZDO().SetPosition(position);
    if((position-destination).sqrMagnitude<2f && drop.CanPickup(false)){if(Owner.Pickup(drop.gameObject,false,false)){collected++;cropLoot.Remove(drop);}if(drop)SaveDrop.Invoke(drop,null);}
   }
   if(snapshot.Length>0)cursor=(cursor+examined)%snapshot.Length;
   if(Mode!=0)HarvestLootV1.MagnetStatus=(Mode==1?"Cheated-item magnet":"All-loot magnet")+": "+Radius+"m; collected "+collected+". Full inventory, protected and unavailable drops stay in the world.";
  }catch(Exception e){HarvestLootV1.StopAll();HarvestLootV1.MagnetStatus=HarvestLootV1.HarvestStatus="Stopped: "+e.GetBaseException().Message;Destroy(gameObject);}}
  void HarvestCrops(){int budget=0;foreach(var crop in UnityEngine.Object.FindObjectsByType<Pickable>(FindObjectsSortMode.None)){
   if(budget>=16)break;if(!crop||!crop.m_harvestable||!crop.CanBePicked())continue;
   var view=crop.GetComponent<ZNetView>();if(!view||!view.IsValid()||!cropPrefabs.Contains(view.GetZDO().GetPrefab()))continue;
   var pos=crop.transform.position;if((pos-Owner.transform.position).sqrMagnitude>400||!PrivateArea.CheckAccess(pos,0,false,false))continue;
   var map=Heightmap.FindHeightmap(pos);if(!map||!map.IsCultivated(pos)||!crop.m_itemPrefab||!Owner.GetInventory().CanAddItem(crop.m_itemPrefab,Math.Max(1,crop.m_amount)))continue;
   int id=crop.GetInstanceID();float last;if(picked.TryGetValue(id,out last)&&Time.time-last<5)continue;
   picked[id]=Time.time;tickets.Add(new Ticket{Point=pos,Item=crop.m_itemPrefab.GetComponent<ItemDrop>().m_itemData.m_shared.m_name,Until=Time.time+10});
   crop.Interact(Owner,false,false);budget++;harvested++;
  }HarvestLootV1.HarvestStatus="Auto harvest active (20m): "+harvested+" harvest requests; native growth timers unchanged.";}
  void TrackHarvestDrops(){snapshot=CurrentDrops();tickets.RemoveAll(t=>Time.time>t.Until);cropLoot.RemoveAll(d=>!d);
   foreach(var drop in snapshot){if(!drop||!seenDrops.Add(drop.GetInstanceID())||drop.IsPiece()||drop.m_itemData==null)continue;foreach(var t in tickets)if(drop.m_itemData.m_shared.m_name==t.Item&&(drop.transform.position-t.Point).sqrMagnitude<=36){cropLoot.Add(drop);break;}}
   if(seenDrops.Count>50000){seenDrops.Clear();foreach(var drop in snapshot)if(drop)seenDrops.Add(drop.GetInstanceID());}
  }
 }
}
