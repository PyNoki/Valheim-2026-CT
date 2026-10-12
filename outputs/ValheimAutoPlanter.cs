using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
public static class AutoPlanterV1 {
 static readonly BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
 internal static ItemDrop.ItemData Right(Player p){return (ItemDrop.ItemData)typeof(Humanoid).GetMethod("GetRightItem",Flags).Invoke(p,null);}
 static readonly MethodInfo Place=typeof(Player).GetMethod("PlacePiece",Flags);
 static readonly MethodInfo Consume=typeof(Player).GetMethod("ConsumeResources",Flags);
 static readonly MethodInfo Requirements=typeof(Player).GetMethod("HaveRequirements",Flags,null,new Type[]{typeof(Piece),typeof(Player.RequirementMode)},null);
 static AutoPlanterDriver driver;
 public static string Status="Idle";
 public static string Catalogue(){
 var tool=ZNetScene.instance.GetPrefab("Cultivator").GetComponent<ItemDrop>();
 var names=new List<string>();
 foreach(var go in tool.m_itemData.m_shared.m_buildPieces.m_pieces) if(go && go.GetComponent<Plant>() && go.GetComponent<Piece>() && go.GetComponent<Piece>().m_enabled) names.Add(go.name);
 names.Sort(StringComparer.Ordinal);return string.Join("\n",names.ToArray());
 }
 public static string Start(Player p,string name){
 Stop();if(string.IsNullOrEmpty(name))return Status;
 var tool=Right(p);if(tool==null||tool.m_shared.m_name!="$item_cultivator")throw new InvalidOperationException("Equip your cultivator first.");
 GameObject prefab=null;foreach(var go in tool.m_shared.m_buildPieces.m_pieces)if(go && go.name==name && go.GetComponent<Plant>() && go.GetComponent<Piece>().m_enabled)prefab=go;
 if(!prefab)throw new InvalidOperationException("Select a cultivator plant.");
 var origin=p.transform.position;var map=Heightmap.FindHeightmap(origin);if(!map||!map.IsCultivated(origin))throw new InvalidOperationException("Stand on cultivated ground first.");
 driver=new GameObject("Toolkit_AutoPlanterBeta").AddComponent<AutoPlanterDriver>();driver.Owner=p;driver.Prefab=prefab;driver.Origin=origin;driver.World=ZNet.instance.GetWorldUID();driver.Prepare();return Status="Auto planter started. Filling connected cultivated ground within 20m; maximum 256 plants.";
 }
 public static void Stop(){if(driver){driver.Cancelled=true;driver=null;}Status="Auto planter stopped.";}
 internal static bool Affordable(Player p,Piece piece){return (bool)Requirements.Invoke(p,new object[]{piece,Player.RequirementMode.CanBuild});}
 internal static void PlantAt(Player p,Piece piece,Vector3 pos){Place.Invoke(p,new object[]{piece,pos,Quaternion.identity,false,false});if(!p.NoCostCheat())Consume.Invoke(p,new object[]{piece.m_resources,0,-1,1});}
}
public sealed class AutoPlanterDriver:MonoBehaviour {
 public bool Cancelled;public Player Owner;public GameObject Prefab;public Vector3 Origin;public long World;
 readonly Queue<Vector2Int> scan=new Queue<Vector2Int>();readonly HashSet<Vector2Int> visited=new HashSet<Vector2Int>();readonly List<Vector3> planted=new List<Vector3>();int count,checkedPoints;float next;
 public void Prepare(){scan.Enqueue(Vector2Int.zero);visited.Add(Vector2Int.zero);}
 void Update(){try{if(Cancelled){Destroy(gameObject);return;}
 if(!Owner||Owner!=Player.m_localPlayer||Owner.IsDead()||Owner.IsTeleporting()||!ZNet.instance||ZNet.instance.GetWorldUID()!=World||Vector3.Distance(Owner.transform.position,Origin)>25f){End("Player moved away or world changed.");return;}
 var tool=AutoPlanterV1.Right(Owner);if(tool==null||tool.m_shared.m_name!="$item_cultivator"){End("Cultivator unequipped.");return;}
 if(Time.time<next)return;next=Time.time+0.05f;
 var plant=Prefab.GetComponent<Plant>();var piece=Prefab.GetComponent<Piece>();float spacing=Math.Max(1.5f,plant.m_growRadius*2f+0.25f);
 for(int budget=0;budget<16&&scan.Count>0;budget++){
 var cell=scan.Dequeue();checkedPoints++;var point=Origin+new Vector3(cell.x,0,cell.y);if(cell.sqrMagnitude>400)continue;
 var map=Heightmap.FindHeightmap(point);float height;if(!map||!map.IsCultivated(point)||!Heightmap.GetHeight(point,out height))continue;point.y=height;
 foreach(var d in new[]{Vector2Int.up,Vector2Int.down,Vector2Int.left,Vector2Int.right}){var c=cell+d;if(c.sqrMagnitude<=400&&visited.Add(c))scan.Enqueue(c);}
 if((plant.m_biome&map.GetBiome(point))==0)continue;
 bool occupied=false;foreach(var pos in planted)if(Utils.DistanceXZ(pos,point)<spacing){occupied=true;break;}if(occupied)continue;
 foreach(var collider in Physics.OverlapSphere(point+Vector3.up*0.5f,spacing)){if(collider.isTrigger||collider.GetComponentInParent<Heightmap>()||collider.GetComponentInParent<Player>())continue;if(collider.GetComponentInParent<Plant>()||collider.GetComponentInParent<Piece>()||collider.GetComponentInParent<Destructible>()||collider.GetComponentInParent<TreeBase>()){occupied=true;break;}}
 if(occupied||Physics.Raycast(point+Vector3.up*0.2f,Vector3.up,100f,LayerMask.GetMask("piece"))||!PrivateArea.CheckAccess(point,0,false,false))continue;
 if(!AutoPlanterV1.Affordable(Owner,piece)){End("No planting materials or recipe requirements unavailable.");return;}
 AutoPlanterV1.PlantAt(Owner,piece,point);planted.Add(point);count++;AutoPlanterV1.Status="Planted "+count+"; scanning cultivated ground...";
 if(count>=256){End("Reached 256-plant limit.");return;}
 }
 if(scan.Count==0)End("Connected cultivated patch complete (20m search limit).");
 }catch(Exception e){End("Stopped: "+e.GetBaseException().Message);}}
 void End(string reason){AutoPlanterV1.Status=reason+" Planted "+count+".";Destroy(gameObject);}
}
}
