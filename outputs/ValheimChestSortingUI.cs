using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class ChestSortingV1 {
  public static int Enabled;
  public static string Status="Off";
  static ChestSortingDriverV1 driver;
  public static string Start(Player owner){
   if(!owner||owner!=Player.m_localPlayer||!owner.enabled)throw new InvalidOperationException("Return to your player first.");
   if(driver){
    if(driver.Owner!=owner||driver.World!=ZNet.instance.GetWorldUID())throw new InvalidOperationException("Wait one game update for the previous world to close.");
    Enabled=1;driver.enabled=true;return Status="Chest sorting enabled. Open any chest with E, then click Chest sorting.";
   }
   driver=new GameObject("SoloToolkit_ChestSorting").AddComponent<ChestSortingDriverV1>();
   driver.Owner=owner;driver.World=ZNet.instance.GetWorldUID();Enabled=1;
   return Status="Chest sorting enabled. Open any chest with E, then click Chest sorting.";
  }
  // CE only requests stop; Unity UI/input restoration stays on the game thread.
  public static void Stop(){Enabled=0;}
  internal static void Retired(ChestSortingDriverV1 retiring){if(driver==retiring){driver=null;Enabled=0;Status="Chest sorting off. Saved chest assignments remain.";}}
 }
 public sealed class ChestSortingDriverV1:MonoBehaviour {
  public Player Owner;public long World;
  Container selected,hover;
  PlayerController controller;bool controllerEnabled,panel;
  bool fromInventory;
  readonly ChestSortInventoryButton native=new ChestSortInventoryButton();
  bool cursorVisible;CursorLockMode cursorLock;
  bool cursorRequested,cameraCapture;GameCamera captureCamera;
  static readonly FieldInfo MouseCapture=typeof(GameCamera).GetField("m_mouseCapture",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
  Vector2 scroll;
  readonly List<ItemDrop.ItemData> samples=new List<ItemDrop.ItemData>();
  readonly List<string> destinations=new List<string>();
  readonly List<string> choices=new List<string>();
  readonly HashSet<string> selectedItems=new HashSet<string>(StringComparer.Ordinal);
  string message="";
  float nextHover,nextNativeAttempt;Rect window;
  bool Session(){return ChestSortingV1.Enabled==1&&Owner&&Owner==Player.m_localPlayer&&Owner.enabled&&!Owner.IsDead()&&!Owner.IsTeleporting()&&ZNet.instance&&ZNet.instance.GetWorldUID()==World;}
  static bool GameMenu(){return Menu.IsVisible()||InventoryGui.IsVisible()||Console.IsVisible()||Minimap.IsOpen()||(Chat.instance&&Chat.instance.HasFocus());}
  void Update(){
   try{
    if(!Session()){Close();Destroy(gameObject);return;}
    if(!Application.isFocused){Close();hover=null;return;}
    Container open=ChestSortStorage.OpenChest(Owner);
    if(panel){
     bool menu=fromInventory?(open!=selected||Menu.IsVisible()||Console.IsVisible()||Minimap.IsOpen()||(Chat.instance&&Chat.instance.HasFocus())):GameMenu();
     if(captureCamera!=GameCamera.instance||!selected||!ChestSortStorage.Accessible(selected,Owner)||menu||Input.GetKeyDown(KeyCode.Escape)||Input.GetKeyDown(KeyCode.F9)){Close();return;}
     Owner.SetMoveDir(Vector3.zero);Owner.SetRun(false);return;
    }
    if(open&&ChestSortStorage.IsChest(open)){
     if(native.Available||Time.unscaledTime>=nextNativeAttempt){
      try{native.Ensure(delegate{try{var current=ChestSortStorage.OpenChest(Owner);if(current)Open(current,true);}catch(Exception error){Close();ChestSortingV1.Status=error.GetBaseException().Message;}});native.Refresh();}
      catch(Exception error){native.Dispose();nextNativeAttempt=Time.unscaledTime+2f;ChestSortingV1.Status=error.GetBaseException().Message;}
     }
     if(Input.GetKeyDown(KeyCode.F9))Open(open,true);
     return;
    }
    native.Dispose();
    if(GameMenu()){hover=null;return;}
    if(Time.unscaledTime>=nextHover||Input.GetKeyDown(KeyCode.F9)){
     nextHover=Time.unscaledTime+0.15f;var go=Owner.GetHoverObject();hover=go?go.GetComponentInParent<Container>():null;
     if(!ChestSortStorage.IsChest(hover)||Vector3.Distance(Owner.transform.position,hover.transform.position)>5f)hover=null;
    }
    if(Input.GetKeyDown(KeyCode.F9)&&hover)Open(hover);
   }catch(Exception e){Close();ChestSortingV1.Status="Sorting: "+e.GetBaseException().Message;Owner.Message(MessageHud.MessageType.TopLeft,ChestSortingV1.Status);}
  }
  // GameCamera.UpdateMouseCapture runs independently of PlayerController.
  // Release its capture flag, rather than competing over Cursor each frame.
  void ReleaseMouse(){
   if(captureCamera&&captureCamera==GameCamera.instance)MouseCapture.SetValue(captureCamera,false);
   ZCursor.LockState=CursorLockMode.None;ZCursor.Show();
  }
  void LateUpdate(){if(panel)ReleaseMouse();}
  void Open(Container chest,bool inventory=false){
   if(ChestSortInventoryButton.Dragging())throw new InvalidOperationException("Finish moving the dragged item first.");
   ChestSortStorage.Ready(chest,Owner);selected=chest;selectedItems.Clear();choices.Clear();samples.Clear();scroll=Vector2.zero;
   destinations.Clear();
   if(ChestSortStorage.Role(chest)=="source"){
    foreach(var target in UnityEngine.Object.FindObjectsByType<Container>(FindObjectsSortMode.None))
     if(ChestSortStorage.Linked(target,chest))foreach(var key in ChestSortStorage.Items(target))destinations.Add(DisplayItem(key)+"  ("+Math.Round(Vector3.Distance(target.transform.position,chest.transform.position))+"m)");
    destinations.Sort(StringComparer.CurrentCultureIgnoreCase);
   }
   var seen=new HashSet<string>();foreach(var item in chest.GetInventory().GetAllItems()){
    string key=ChestSortStorage.ItemKey(item);if(key!=""&&!item.m_shared.m_questItem&&!item.m_equipped&&seen.Add(key))samples.Add(item);
   }
   samples.Sort(delegate(ItemDrop.ItemData a,ItemDrop.ItemData b){return StringComparer.CurrentCultureIgnoreCase.Compare(Name(a),Name(b));});
   foreach(var item in samples)choices.Add(ChestSortStorage.ItemKey(item));
   if(ChestSortStorage.Role(chest)=="destination")foreach(var key in ChestSortStorage.Items(chest)){
    selectedItems.Add(key);if(!choices.Contains(key))choices.Add(key);
   }
   choices.Sort(delegate(string a,string b){return StringComparer.CurrentCultureIgnoreCase.Compare(DisplayItem(a),DisplayItem(b));});
   controller=Owner.GetComponent<PlayerController>();if(!controller)throw new InvalidOperationException("Player controls unavailable.");
   if(MouseCapture==null||MouseCapture.FieldType!=typeof(bool)||!GameCamera.instance)throw new InvalidOperationException("Game mouse capture is unavailable. Close the panel and try again.");
   captureCamera=GameCamera.instance;cameraCapture=(bool)MouseCapture.GetValue(captureCamera);
   controllerEnabled=controller.enabled;cursorVisible=Cursor.visible;cursorLock=Cursor.lockState;
   cursorRequested=ZCursor.IsRequested;
   Owner.SetMoveDir(Vector3.zero);Owner.SetRun(false);controller.enabled=false;panel=true;fromInventory=inventory;
   if(fromInventory)native.BlockInventory();
   ReleaseMouse();
   window=new Rect(Math.Max(10,(Screen.width-520)/2),Math.Max(10,(Screen.height-540)/2),520,540);
   message="Sorting stays enabled. Close this panel to continue with the next chest.";
  }
  static string Name(ItemDrop.ItemData item){return Localization.instance.Localize(item.m_shared.m_name);}
  void Close(){
   if(!panel)return;panel=false;
   native.UnblockInventory();fromInventory=false;
   if(controller&&Owner&&Owner==Player.m_localPlayer&&Owner.enabled)controller.enabled=controllerEnabled;
   if(captureCamera&&captureCamera==GameCamera.instance)MouseCapture.SetValue(captureCamera,cameraCapture);
   captureCamera=null;
   if(cursorRequested)ZCursor.Show();else ZCursor.Hide();
   ZCursor.LockState=cursorLock;Cursor.visible=cursorVisible;selected=null;samples.Clear();
  }
  void OnDisable(){Close();native.Dispose();}
  void OnDestroy(){Close();native.Dispose();ChestSortingV1.Retired(this);}
  void Act(Action action){try{action();ChestSortingV1.Status=message;}catch(Exception e){message=e.GetBaseException().Message;ChestSortingV1.Status=message;}}
  void OnGUI(){
   if(!Session()||!Application.isFocused)return;
   if(panel){ReleaseMouse();window=GUI.Window(GetInstanceID(),window,Draw,"Chest sorting");GUI.BringWindowToFront(GetInstanceID());}
   else if(hover&&!GameMenu()){
    string hint=ChestSortStorage.Role(hover)=="source"?"[F9] Open sorting chest":"[F9] Chest sorting setup";
    GUI.Box(new Rect(Screen.width/2-180,Screen.height/2+80,360,36),hint);
   }
  }
  void Draw(int id){
   GUI.Label(new Rect(20,30,480,30),"Shared route: all sorting chests use the same storage");
   bool source=ChestSortStorage.Role(selected)=="source";
   if(source){
    GUI.Label(new Rect(20,68,480,30),"SORTING CHEST - shared destination route");
    GUI.Label(new Rect(20,102,480,48),"All sorting chests feed the same loaded destinations.\nNo distance cap; full chests overflow to the next match.");
    if(GUI.Button(new Rect(20,162,480,48),"SORT ITEMS"))Act(delegate{message=ChestSortStorage.Sort(selected,Owner,UnityEngine.Object.FindObjectsByType<Container>(FindObjectsSortMode.None));});
    GUI.Label(new Rect(20,226,480,28),"Loaded item destinations: "+destinations.Count);
    scroll=GUI.BeginScrollView(new Rect(20,258,480,92),scroll,new Rect(0,0,450,Math.Max(92,destinations.Count*26)));
    for(int i=0;i<destinations.Count;i++)GUI.Label(new Rect(0,i*26,445,26),destinations[i]);
    GUI.EndScrollView();
    GUI.Label(new Rect(20,360,480,42),"To add a chest: open it with E, click Chest sorting,\nthen tick its items and save your selection.");
   }else{
    int assigned=ChestSortStorage.Items(selected).Length;
    GUI.Label(new Rect(20,68,480,30),assigned==0?"This chest has no items assigned.":"Shared destination: receives "+assigned+" item types.");
    GUI.Label(new Rect(20,106,480,30),"Tick the items this chest should receive ("+selectedItems.Count+" selected):");
    scroll=GUI.BeginScrollView(new Rect(20,140,480,165),scroll,new Rect(0,0,450,Math.Max(165,choices.Count*36)));
    for(int i=0;i<choices.Count;i++){
     string key=choices[i];
     if(GUI.Button(new Rect(0,i*36,445,32),(selectedItems.Contains(key)?"[x] ":"[ ] ")+DisplayItem(key))){if(!selectedItems.Add(key))selectedItems.Remove(key);}
    }
    GUI.EndScrollView();
    if(choices.Count==0)GUI.Label(new Rect(26,150,445,70),"Put sample items in the chest, then click\nChest sorting again.");
    bool enabled=GUI.enabled;GUI.enabled=enabled&&selectedItems.Count>0;
    if(GUI.Button(new Rect(20,316,310,38),"Save selected items"))Act(delegate{ChestSortStorage.AssignItems(selected,Owner,selectedItems);message="Saved! This chest receives "+selectedItems.Count+" item types. Continue with the next chest; sorting stays ON.";});
    GUI.enabled=enabled;
    if(GUI.Button(new Rect(340,316,160,38),"Select all"))foreach(var key in choices)selectedItems.Add(key);
    if(GUI.Button(new Rect(20,365,480,36),"Make this a sorting chest"))Act(delegate{ChestSortStorage.MakeSource(selected,Owner);message="Sorting chest ready. All sorting chests share the same destinations.";});
   }
   if(ChestSortStorage.Role(selected)!=""&&GUI.Button(new Rect(20,410,225,32),"Remove chest assignment"))Act(delegate{ChestSortStorage.Clear(selected,Owner);message="Assignment removed. Items are unchanged.";});
   if(GUI.Button(new Rect(260,410,240,32),fromInventory?"Back to chest":"Close (F9 / Esc)"))Close();
   GUI.Label(new Rect(20,457,480,65),message);
  }
  string DisplayItem(string key){foreach(var item in samples)if(ChestSortStorage.ItemKey(item)==key)return Name(item);var prefab=ZNetScene.instance.GetPrefab(key);var drop=prefab?prefab.GetComponent<ItemDrop>():null;return drop?Name(drop.m_itemData):key;}
 }
}
