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
  ChestSortJob sortJob;
  PlayerController controller;bool controllerEnabled,panel;
  bool fromInventory;
  readonly ChestSortInventoryButton native=new ChestSortInventoryButton();
  bool cursorVisible;CursorLockMode cursorLock;
  bool cursorRequested,cameraCapture;GameCamera captureCamera;
  static readonly FieldInfo MouseCapture=typeof(GameCamera).GetField("m_mouseCapture",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
  Vector2 scroll,statusScroll;
  string lastStatusMessage;
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
     if(captureCamera!=GameCamera.instance||(!selected||!ChestSortStorage.Accessible(selected,Owner))||menu||Input.GetKeyDown(KeyCode.Escape)||Input.GetKeyDown(KeyCode.F9)){Close();return;}
     if(sortJob!=null){sortJob.Tick();message=sortJob.Status;ChestSortingV1.Status=message;if(sortJob.Done)sortJob=null;}
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
   ChestSortStorage.Ready(chest,Owner);selected=chest;RefreshChest();
   ShowPanel(inventory);
   message="Click Reassign all items + save to replace old filters with this chest's current contents.";
  }
  void RefreshChest(){
   var chest=selected;selectedItems.Clear();choices.Clear();samples.Clear();scroll=Vector2.zero;
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
  }
  void ShowPanel(bool inventory){
   controller=Owner.GetComponent<PlayerController>();if(!controller)throw new InvalidOperationException("Player controls unavailable.");
   if(MouseCapture==null||MouseCapture.FieldType!=typeof(bool)||!GameCamera.instance)throw new InvalidOperationException("Game mouse capture is unavailable. Close the panel and try again.");
   captureCamera=GameCamera.instance;cameraCapture=(bool)MouseCapture.GetValue(captureCamera);
   controllerEnabled=controller.enabled;cursorVisible=Cursor.visible;cursorLock=Cursor.lockState;
   cursorRequested=ZCursor.IsRequested;
   Owner.SetMoveDir(Vector3.zero);Owner.SetRun(false);controller.enabled=false;panel=true;fromInventory=inventory;
   if(fromInventory)native.BlockInventory();
   ReleaseMouse();
   window=new Rect(Math.Max(10,(Screen.width-520)/2),Math.Max(10,(Screen.height-586)/2),520,586);
  }
  static string Name(ItemDrop.ItemData item){return Localization.instance.Localize(item.m_shared.m_name);}
  void Close(){
   if(sortJob!=null){sortJob.Cancel();sortJob=null;}
   if(!panel)return;panel=false;
   native.UnblockInventory();fromInventory=false;
   if(controller&&Owner&&Owner==Player.m_localPlayer&&Owner.enabled)controller.enabled=controllerEnabled;
   if(captureCamera&&captureCamera==GameCamera.instance)MouseCapture.SetValue(captureCamera,cameraCapture);
   captureCamera=null;
   if(cursorRequested)ZCursor.Show();else ZCursor.Hide();
   ZCursor.LockState=cursorLock;Cursor.visible=cursorVisible;selected=null;samples.Clear();
  }
  void OnDisable(){Close();native.Dispose();}
  void OnDestroy(){Close();native.Dispose();foreach(var texture in themeTextures)if(texture)Destroy(texture);themeTextures.Clear();ChestSortingV1.Retired(this);}
  void Act(Action action){try{action();ChestSortingV1.Status=message;}catch(Exception e){message=e.GetBaseException().Message;ChestSortingV1.Status=message;}}
  const float PanelWidth=660f,PanelHeight=704f;
  readonly List<Texture2D> themeTextures=new List<Texture2D>();
  GUIStyle panelStyle,titleStyle,bodyStyle,mutedStyle,sectionStyle,rowStyle,buttonStyle,primaryStyle,statusStyle,badgeStyle;
  Texture2D cardTexture,borderTexture,shadeTexture;
  Texture2D Solid(Color color){var texture=new Texture2D(1,1);texture.hideFlags=HideFlags.HideAndDontSave;texture.SetPixel(0,0,color);texture.Apply();themeTextures.Add(texture);return texture;}
  GUIStyle Text(int size,Color color,bool bold=false){
   var style=new GUIStyle(GUI.skin.label);style.fontSize=size;style.fontStyle=bold?FontStyle.Bold:FontStyle.Normal;
   style.wordWrap=true;style.richText=false;style.alignment=TextAnchor.UpperLeft;style.padding=new RectOffset(0,0,0,0);style.normal.textColor=color;return style;
  }
  GUIStyle ButtonStyle(Texture2D normal,Texture2D hover,Texture2D active,Color ink){
   var style=new GUIStyle(GUI.skin.button);style.fontSize=18;style.fontStyle=FontStyle.Bold;style.wordWrap=true;style.richText=false;
   style.alignment=TextAnchor.MiddleCenter;style.padding=new RectOffset(14,14,8,8);style.border=new RectOffset(0,0,0,0);style.fixedWidth=0;style.fixedHeight=0;
   foreach(var state in new[]{style.normal,style.onNormal}){state.background=normal;state.textColor=ink;}
   foreach(var state in new[]{style.hover,style.onHover,style.focused,style.onFocused}){state.background=hover;state.textColor=ink;}
   foreach(var state in new[]{style.active,style.onActive}){state.background=active;state.textColor=ink;}
   return style;
  }
  void EnsureTheme(){
   if(panelStyle!=null)return;
   var white=new Color(0.95f,0.96f,0.98f,1f);var muted=new Color(0.72f,0.78f,0.86f,1f);var gold=new Color(0.91f,0.73f,0.43f,1f);
   panelStyle=new GUIStyle();var panelTexture=Solid(new Color(0.065f,0.085f,0.12f,1f));
   foreach(var state in new[]{panelStyle.normal,panelStyle.onNormal,panelStyle.hover,panelStyle.onHover,panelStyle.active,panelStyle.onActive,panelStyle.focused,panelStyle.onFocused})state.background=panelTexture;
   cardTexture=Solid(new Color(0.105f,0.14f,0.19f,1f));borderTexture=Solid(new Color(0.23f,0.29f,0.37f,1f));shadeTexture=Solid(new Color(0,0,0,0.6f));
   titleStyle=Text(28,white,true);bodyStyle=Text(18,white);mutedStyle=Text(16,muted);sectionStyle=Text(14,gold,true);rowStyle=Text(18,white);statusStyle=Text(17,white);badgeStyle=Text(13,gold,true);
   buttonStyle=ButtonStyle(Solid(new Color(0.19f,0.25f,0.33f,1f)),Solid(new Color(0.26f,0.34f,0.44f,1f)),Solid(new Color(0.13f,0.18f,0.25f,1f)),white);
   primaryStyle=ButtonStyle(Solid(new Color(0.86f,0.66f,0.34f,1f)),Solid(new Color(0.96f,0.77f,0.45f,1f)),Solid(new Color(0.72f,0.52f,0.25f,1f)),new Color(0.075f,0.09f,0.12f,1f));
  }
  void OnGUI(){
   if(!Session()||!Application.isFocused)return;
   if(panel){
    ReleaseMouse();EnsureTheme();
    Color color=GUI.color,background=GUI.backgroundColor,content=GUI.contentColor;var matrix=GUI.matrix;int depth=GUI.depth;
    try{
     // In-game IMGUI colors/skin can be translucent. Use explicit opaque panel
     // textures and neutral tint, then restore all shared GUI state afterward.
     GUI.color=Color.white;GUI.backgroundColor=Color.white;GUI.contentColor=Color.white;GUI.depth=-100;
     GUI.matrix=Matrix4x4.identity;GUI.DrawTexture(new Rect(0,0,Screen.width,Screen.height),shadeTexture);
     float scale=Math.Max(0.1f,Math.Min(1.15f,Math.Min((Screen.width-32f)/PanelWidth,(Screen.height-32f)/PanelHeight)));
     GUI.matrix=Matrix4x4.TRS(Vector3.zero,Quaternion.identity,new Vector3(scale,scale,1));
     window=new Rect((Screen.width/scale-PanelWidth)/2f,(Screen.height/scale-PanelHeight)/2f,PanelWidth,PanelHeight);
     window=GUI.Window(GetInstanceID(),window,Draw,"",panelStyle);GUI.BringWindowToFront(GetInstanceID());
    }finally{GUI.color=color;GUI.backgroundColor=background;GUI.contentColor=content;GUI.matrix=matrix;GUI.depth=depth;}
   }
   else if(hover&&!GameMenu()){
    string hint=ChestSortStorage.Role(hover)=="source"?"[F9] Open sorting chest":"[F9] Chest sorting setup";
    GUI.Box(new Rect(Screen.width/2-180,Screen.height/2+80,360,36),hint);
   }
  }
  void Card(Rect rect){GUI.DrawTexture(rect,cardTexture);}
  void Heading(string title,string subtitle){
   GUI.Label(new Rect(24,22,540,38),title,titleStyle);
   GUI.Label(new Rect(24,64,612,24),subtitle,mutedStyle);
   GUI.DrawTexture(new Rect(24,96,612,1),borderTexture);
  }
  void StatusAndBack(){
   Card(new Rect(24,528,612,96));GUI.Label(new Rect(40,540,580,20),"STATUS",sectionStyle);
   if(message!=lastStatusMessage){statusScroll=Vector2.zero;lastStatusMessage=message;}
   float textHeight=Math.Max(52f,statusStyle.CalcHeight(new GUIContent(message),556));
   statusScroll=GUI.BeginScrollView(new Rect(40,565,580,52),statusScroll,new Rect(0,0,556,textHeight));
   GUI.Label(new Rect(0,0,556,textHeight),message,statusStyle);GUI.EndScrollView();
   if(GUI.Button(new Rect(24,644,612,40),fromInventory?"Back to chest":"Close (F9 / Esc)",buttonStyle))Close();
  }
  void Draw(int id){
   bool source=ChestSortStorage.Role(selected)=="source";
   Heading("Chest sorting",source?"Sort mixed items into your shared storage route.":"Choose what this chest receives from sorting chests.");
   Card(new Rect(24,112,612,52));
   int assigned=ChestSortStorage.Items(selected).Length;
   GUI.Label(new Rect(40,127,580,28),source?"Sorting chest  /  shared route":assigned==0?"Destination chest  /  no saved item types":"Destination chest  /  "+assigned+" saved item types",bodyStyle);
   GUI.Label(new Rect(24,182,612,22),source?"LOADED DESTINATIONS  /  "+destinations.Count:"ITEM FILTERS & CURRENT CONTENTS",sectionStyle);
   Card(new Rect(24,214,612,174));
   float height=0;var rows=source?destinations:choices;
   foreach(var key in rows)height+=Math.Max(40f,rowStyle.CalcHeight(new GUIContent(source?key:DisplayItem(key)),source?560:456)+12f);
   scroll=GUI.BeginScrollView(new Rect(32,222,596,158),scroll,new Rect(0,0,570,Math.Max(158,height)));
   float y=0;
   foreach(var key in rows){
    string text=source?key:DisplayItem(key);float h=Math.Max(40f,rowStyle.CalcHeight(new GUIContent(text),source?560:456)+12f);
    if(!source)GUI.Label(new Rect(8,y+8,92,h-8),selectedItems.Contains(key)?"SAVED":"IN CHEST",badgeStyle);
    GUI.Label(new Rect(source?8:108,y+6,source?552:454,h-6),text,rowStyle);y+=h;
   }
   if(rows.Count==0)GUI.Label(new Rect(8,12,550,96),source?"No loaded destinations yet. Set up another chest to receive its current item types.":"No item types yet. Put sample items in the chest, then use the button below.",mutedStyle);
   GUI.EndScrollView();
   bool enabled=GUI.enabled;GUI.enabled=enabled&&sortJob==null;
   if(source){
    if(GUI.Button(new Rect(24,404,612,48),sortJob==null?"SORT ITEMS":"REQUESTING CHEST ACCESS...",primaryStyle))Act(delegate{sortJob=new ChestSortJob(selected,Owner,UnityEngine.Object.FindObjectsByType<Container>(FindObjectsSortMode.None));message=sortJob.Status;if(sortJob.Done)sortJob=null;});
   }else{
    if(GUI.Button(new Rect(24,404,612,48),"Reassign all items + save",primaryStyle))Act(delegate{
     int count=ChestSortStorage.ReassignContents(selected,Owner);RefreshChest();
     message=count>0?"Saved! Replaced old filters with "+count+" item types currently in this chest.":"Saved! No assignable items in this chest; old item filters removed.";
    });
   }
   if(GUI.Button(new Rect(24,468,612,42),source?"Remove sorting role":"Make this a sorting chest",buttonStyle))Act(delegate{
    if(source){ChestSortStorage.Clear(selected,Owner);message="Sorting role removed. Items are unchanged.";}
    else {ChestSortStorage.MakeSource(selected,Owner);message="Sorting chest ready. All sorting chests share the same destinations.";}
    RefreshChest();
   });
   GUI.enabled=enabled;StatusAndBack();
  }
  string DisplayItem(string key){foreach(var item in samples)if(ChestSortStorage.ItemKey(item)==key)return Name(item);var prefab=ZNetScene.instance.GetPrefab(key);var drop=prefab?prefab.GetComponent<ItemDrop>():null;return drop?Name(drop.m_itemData):key;}
 }
}
