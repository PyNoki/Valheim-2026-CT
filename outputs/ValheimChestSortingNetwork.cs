using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 // Request the same owner-approved handoff as opening a chest with E. Never
 // ClaimOwnership on another peer's chest or write its cached client inventory.
 public sealed class ChestSortJob {
  readonly Container source;readonly Player player;readonly ZNet net;readonly long world;
  readonly List<Container> loaded=new List<Container>();
  readonly List<Request> requests=new List<Request>();
  readonly float deadline;
  public bool Done {get;private set;}
  public string Status {get;private set;}
  public ChestSortJob(Container source,Player player,IEnumerable<Container> loaded){
   ChestSortStorage.Ready(source,player);
   if(ChestSortStorage.Role(source)!="source")throw new InvalidOperationException("Mark a sorting chest first.");
   this.source=source;this.player=player;net=ZNet.instance;world=net.GetWorldUID();deadline=Time.unscaledTime+10f;
   var items=new HashSet<string>(StringComparer.Ordinal);
   foreach(var item in source.GetInventory().GetAllItems())if(!item.m_equipped&&!item.m_shared.m_questItem)items.Add(ChestSortStorage.ItemKey(item));
   var seen=new HashSet<string>();
   try{
    foreach(var chest in loaded){
     if(!ChestSortStorage.Linked(chest,source)||!seen.Add(ChestSortStorage.Identity(chest)))continue;
     this.loaded.Add(chest);
     if(!ChestSortStorage.Accessible(chest,player)||ChestSortStorage.Busy(chest,player)||ChestSortStorage.View(chest).IsOwner())continue;
     bool matching=false;foreach(var key in ChestSortStorage.Items(chest))if(items.Contains(key)){matching=true;break;}
     if(matching)requests.Add(Request.Start(chest,player));
    }
    Tick();
   }catch{Cancel();throw;}
  }
  bool Session(){return player&&player==Player.m_localPlayer&&player.enabled&&!player.IsDead()&&!player.IsTeleporting()&&net&&net==ZNet.instance&&net.GetWorldUID()==world;}
  public void Tick(){
   if(Done)return;
   if(!Session()){Cancel();return;}
   int pending=0;foreach(var request in requests)if(request.Waiting)pending++;
   if(pending>0&&Time.unscaledTime<deadline){Status="Requesting chest access: "+pending+" remaining. Items stay in the sorting chest until access is ready.";return;}
   try{
    var ready=new List<Container>(loaded);int denied=0,timedOut=0;
    foreach(var request in requests)if(!request.Ready){ready.Remove(request.Chest);if(request.Denied)denied++;else timedOut++;}
    Status=ChestSortStorage.Sort(source,player,ready);
    if(denied+timedOut>0)Status+=" Network access: "+denied+" denied, "+timedOut+" timed out. Open unavailable chests with E, then retry.";
   }
   finally{Done=true;foreach(var request in requests)request.Finish();}
  }
  public void Cancel(){if(Done)return;Done=true;Status="Sort cancelled. No further items moved.";foreach(var request in requests)request.Finish();}
  internal sealed class Request {
   static readonly Dictionary<ZNetView,Request> outstanding=new Dictionary<ZNetView,Request>();
   public static Request Start(Container chest,Player player){
    foreach(var view in new List<ZNetView>(outstanding.Keys))if(!view||!view.IsValid())outstanding.Remove(view);
    var current=ChestSortStorage.View(chest);Request previous;
    if(outstanding.TryGetValue(current,out previous)&&!previous.answered)return previous;
    var request=new Request(chest,player);if(!request.answered)outstanding[current]=request;return request;
   }
   static readonly FieldInfo Functions=typeof(ZNetView).GetField("m_functions",BindingFlags.Instance|BindingFlags.NonPublic|BindingFlags.Public);
   static readonly string Response="RPC_OpenResponse";
   readonly Container chest;readonly ZNetView view;readonly long owner;
   readonly IDictionary functions;readonly int key;
   readonly object original;object replacement;
   bool answered,granted;
   public Container Chest {get{return chest;}}
   public bool Denied {get{return answered&&!granted;}}
   public bool Ready {get{return answered&&granted&&chest&&view&&view.IsValid()&&view.IsOwner();}}
   public bool Waiting {get{return chest&&view&&view.IsValid()&&(!answered||(granted&&!view.IsOwner()));}}
   public Request(Container chest,Player player){
    this.chest=chest;view=ChestSortStorage.View(chest);owner=view.GetZDO().GetOwner();
    if(owner==0){answered=true;return;}
    functions=Functions!=null?Functions.GetValue(view) as IDictionary:null;key=Response.GetStableHashCode();
    if(functions==null||!functions.Contains(key))throw new InvalidOperationException("Chest network response is unavailable. Open this chest with E first.");
    original=functions[key];
    // Keep the exact original registration, including callbacks installed by mods.
    view.Unregister(Response);
    try{view.Register<bool>(Response,OnResponse);replacement=functions[key];}
    catch{functions[key]=original;throw;}
    try{view.InvokeRPC("RPC_RequestOpen",player.GetPlayerID());}
    catch{Restore();throw;}
   }
   void OnResponse(long sender,bool allowed){
    if(sender!=owner)return;
    answered=true;granted=allowed;Request current;if(outstanding.TryGetValue(view,out current)&&ReferenceEquals(current,this))outstanding.Remove(view);Restore();
   }
   void Restore(){if(functions!=null&&replacement!=null&&ReferenceEquals(functions[key],replacement))functions[key]=original;}
   public void Finish(){
    // A cancelled/timed-out request may still receive a delayed native reply.
    // Consume that reply before restoring the handler so it cannot open a chest
    // GUI unexpectedly. This callback never transfers items or starts another job.
    if(answered)Restore();
   }
  }
 }
}
