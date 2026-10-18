using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {
  public bool destroyed;public static List<Object> all=new List<Object>();
  public static implicit operator bool(Object o){return o!=null&&!o.destroyed;}
  public static T[] FindObjectsByType<T>(FindObjectsSortMode mode) where T:Object {var list=new List<T>();foreach(var o in all)if(o is T&&o)list.Add((T)o);return list.ToArray();}
  public static GameObject Instantiate(GameObject original,Transform parent){
   var clone=new GameObject(original.name);var rect=clone.AddComponent<RectTransform>();rect.parent=parent;
   var source=original.GetComponent<RectTransform>();rect.anchorMin=source.anchorMin;rect.anchorMax=source.anchorMax;rect.pivot=source.pivot;rect.sizeDelta=source.sizeDelta;rect.anchoredPosition=source.anchoredPosition;
   var button=clone.AddComponent<UnityEngine.UI.Button>();button.onClick=original.GetComponent<UnityEngine.UI.Button>().onClick;
   clone.AddComponent<TMPro.TMP_Text>();return clone;
  }
  public static void Destroy(Object o){if(!o)return;o.destroyed=true;var go=o as GameObject;if(go!=null)foreach(var c in go.components){var m=c.GetType().GetMethod("OnDestroy",BindingFlags.Instance|BindingFlags.NonPublic);if(m!=null)m.Invoke(c,null);c.destroyed=true;}}
 }
 public enum FindObjectsSortMode {None}
 public class Component:Object {public GameObject gameObject;public string name{get{return gameObject.name;}}public Transform transform{get{return gameObject.transform;}}public T GetComponent<T>() where T:class{return gameObject.GetComponent<T>();}public T GetComponentInChildren<T>(bool inactive)where T:class{return GetComponent<T>();}public int GetInstanceID(){return GetHashCode();}}
 public class MonoBehaviour:Component {public bool enabled=true;}
 public class GameObject:Object {
  public string name;public Transform transform=new Transform();public List<Component> components=new List<Component>();
  public GameObject(string n){name=n;transform.gameObject=this;all.Add(this);}public bool active=true;public void SetActive(bool value){active=value;}
  public T AddComponent<T>()where T:Component,new(){var c=new T{gameObject=this};components.Add(c);all.Add(c);if(c is RectTransform)transform=(Transform)(object)c;return c;}
  public T GetComponent<T>()where T:class{if(transform is T&&transform)return transform as T;foreach(var c in components)if(c is T&&c)return c as T;return null;}
  public T GetComponentInParent<T>()where T:class{return GetComponent<T>();}public T GetComponentInChildren<T>(bool inactive)where T:class{return GetComponent<T>();}
 }
 public class Transform:Component {public Vector3 position,localPosition;public Transform parent;}
 public class RectTransform:Transform {public Vector2 anchorMin,anchorMax,pivot=new Vector2(0.5f,0.5f),sizeDelta=new Vector2(150,30);Vector2 pos;public Vector2 anchoredPosition{get{return pos;}set{pos=value;localPosition=new Vector3(value.x,value.y,0);}}public Rect rect{get{return new Rect(0,0,sizeDelta.x,sizeDelta.y);}}}
 public class CanvasGroup:MonoBehaviour {public bool interactable=true,blocksRaycasts=true;}
 public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}public static Vector3 zero{get{return new Vector3();}}public static float Distance(Vector3 a,Vector3 b){return (float)Math.Sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)+(a.z-b.z)*(a.z-b.z));}}
 public struct Vector2 {public float x,y;public Vector2(float a,float b){x=a;y=b;}public static Vector2 zero{get{return new Vector2();}}}
 public struct Rect {public float width,height;public Rect(float a,float b,float c,float d){width=c;height=d;}}
 public enum CursorLockMode {None,Locked}
 public static class Cursor {public static bool visible;public static CursorLockMode lockState=CursorLockMode.Locked;}
 public static class Application {public static bool isFocused=true;}
 public static class Screen {public static int width=1280,height=720;}
 public static class Time {public static float unscaledTime;}
 public enum KeyCode {F9,Escape}
 public static class Input {public static HashSet<KeyCode> keys=new HashSet<KeyCode>();public static bool GetKeyDown(KeyCode k){return keys.Contains(k);}}
 public static class GUI {
  public static bool enabled=true;public static HashSet<string> clicks=new HashSet<string>();public delegate void WindowFunction(int id);
  public static Rect Window(int id,Rect area,WindowFunction draw,string text){draw(id);return area;}public static void BringWindowToFront(int id){}public static void Box(Rect r,string t){}public static void Label(Rect r,string t){}
  public static bool Button(Rect r,string text){return enabled&&clicks.Remove(text);}public static Vector2 BeginScrollView(Rect r,Vector2 s,Rect v){return s;}public static void EndScrollView(){}
 }
}
namespace UnityEngine.UI {
 public class Button:MonoBehaviour {
  public bool interactable=true;public ButtonClickedEvent onClick=new ButtonClickedEvent();
  public class ButtonClickedEvent {readonly List<Action> callbacks=new List<Action>();public void AddListener(Action action){callbacks.Add(action);}public void RemoveAllListeners(){callbacks.Clear();}public void Invoke(){foreach(var action in new List<Action>(callbacks))action();}}
 }
}
namespace TMPro {public class TMP_Text:MonoBehaviour {public string text;public bool enableAutoSizing;public float fontSizeMin;}}
public class Piece:MonoBehaviour {}
public class ZDO {public string m_uid;public Dictionary<string,string> data=new Dictionary<string,string>();public string GetString(string key,string fallback){string value;return data.TryGetValue(key,out value)?value:fallback;}public void Set(string key,string value){data[key]=value;}}
public class ZNetView:MonoBehaviour {public bool owned=true;public ZDO zdo=new ZDO();public bool IsValid(){return true;}public bool IsOwner(){return owned;}public ZDO GetZDO(){return zdo;}}
public class Container:MonoBehaviour {
 public Inventory inventory=new Inventory();public bool busy,allowed=true;public int loads;
 public bool IsInUse(){return busy;}private bool CheckAccess(long id){return allowed;}private bool Load(){loads++;return true;}public Inventory GetInventory(){return inventory;}
}
public static class PrivateArea {public static bool allowed=true;public static bool CheckAccess(Vector3 p,float r,bool a,bool b){return allowed;}}
public class ItemDrop:MonoBehaviour {
 public ItemData m_itemData;public class ItemData {
  public class SharedData {public bool m_questItem;public string m_name;}
  public GameObject m_dropPrefab;public SharedData m_shared=new SharedData();public int m_stack=1,m_quality=1;public bool m_equipped,cheated;public string custom;
 }
}
public class Inventory {
 public List<ItemDrop.ItemData> items=new List<ItemDrop.ItemData>();public int slots=4,maxStack=50,moves;
 public List<ItemDrop.ItemData> GetAllItems(){return items;}public bool ContainsItem(ItemDrop.ItemData i){return items.Contains(i);}
 // Emulate native partial stacking and item movement; only this mock owns capacity logic.
 public void MoveItemToThis(Inventory source,ItemDrop.ItemData item){
  moves++;foreach(var target in items)if(target.m_dropPrefab==item.m_dropPrefab&&target.m_quality==item.m_quality&&target.cheated==item.cheated&&target.custom==item.custom){int n=Math.Min(item.m_stack,maxStack-target.m_stack);target.m_stack+=n;item.m_stack-=n;if(item.m_stack==0){source.items.Remove(item);return;}}
  if(items.Count<slots){source.items.Remove(item);items.Add(item);}
 }
}
public class Player:MonoBehaviour {public static Player m_localPlayer;public bool dead,teleport;public GameObject hover;public bool IsDead(){return dead;}public bool IsTeleporting(){return teleport;}public long GetPlayerID(){return 7;}public GameObject GetHoverObject(){return hover;}public void SetMoveDir(Vector3 v){}public void SetRun(bool b){}public void Message(MessageHud.MessageType t,string s){}}
public class PlayerController:MonoBehaviour {}
public class GameCamera:MonoBehaviour {
 public static GameCamera instance=new GameObject("camera").AddComponent<GameCamera>();
 public bool m_mouseCapture=true;
 public void UpdateMouseCapture(){if(m_mouseCapture){ZCursor.LockState=CursorLockMode.Locked;ZCursor.Hide();}}
}
public static class ZCursor {
 public static bool IsRequested;
 public static CursorLockMode LockState{get{return Cursor.lockState;}set{Cursor.lockState=value;}}
 public static void Show(){IsRequested=true;Cursor.visible=true;}
 public static void Hide(){IsRequested=false;Cursor.visible=false;}
}

public class ZNet:UnityEngine.Object {public static ZNet instance=new ZNet();public long world=1;public long GetWorldUID(){return world;}}
public class ZNetScene:UnityEngine.Object {public static ZNetScene instance=new ZNetScene();public GameObject GetPrefab(string n){foreach(var go in UnityEngine.Object.all)if(go is GameObject&&((GameObject)go).name==n)return (GameObject)go;return null;}}
public class Localization {public static Localization instance=new Localization();public string Localize(string s){return s;}}
public static class Menu {public static bool visible;public static bool IsVisible(){return visible;}}
public class InventoryGui:MonoBehaviour {
 public static InventoryGui instance;public static bool visible;
 public Container m_currentContainer;public ItemDrop.ItemData m_dragItem;
 public Transform m_inventoryRoot;public UnityEngine.UI.Button m_takeAllButton,m_stackAllButton;
 public static bool IsVisible(){return visible;}
 public void Setup(){
  var root=new GameObject("inventory root");m_inventoryRoot=root.AddComponent<RectTransform>();
  m_takeAllButton=MakeButton("Take all",-160);m_stackAllButton=MakeButton("Stack all",10);
 }
 UnityEngine.UI.Button MakeButton(string name,float x){var go=new GameObject(name);var rect=go.AddComponent<RectTransform>();rect.parent=m_inventoryRoot;rect.pivot=new Vector2(0,0.5f);rect.anchoredPosition=new Vector2(x,0);go.AddComponent<TMPro.TMP_Text>();return go.AddComponent<UnityEngine.UI.Button>();}
}
public static class Console {public static bool IsVisible(){return false;}}
public static class Minimap {public static bool IsOpen(){return false;}}
public class Chat:UnityEngine.Object {public static Chat instance;public bool HasFocus(){return false;}}
public class MessageHud {public enum MessageType {TopLeft}}
public class Tests {
 static void Check(bool value,string message){if(!value)throw new Exception(message);}
 static bool Reject(Action action){try{action();return false;}catch(InvalidOperationException){return true;}}
 static ItemDrop.ItemData Item(GameObject prefab,int n){return new ItemDrop.ItemData{m_dropPrefab=prefab,m_stack=n,m_shared=new ItemDrop.ItemData.SharedData{m_name=prefab.name}};}
 static Container Chest(string id,float x){var go=new GameObject("piece_chest_wood(Clone)");go.transform.position=new Vector3(x,0,0);go.AddComponent<Piece>();go.AddComponent<ZNetView>().zdo.m_uid=id;return go.AddComponent<Container>();}
 static int Count(GameObject prefab,params Container[] chests){int n=0;foreach(var c in chests)foreach(var i in c.inventory.items)if(i.m_dropPrefab==prefab)n+=i.m_stack;return n;}
 static void Call(object target,string method){target.GetType().GetMethod(method,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(target,null);}
 static ChestSortingDriverV1 Driver(){return (ChestSortingDriverV1)typeof(ChestSortingV1).GetField("driver",BindingFlags.Static|BindingFlags.NonPublic).GetValue(null);}
 static void Key(ChestSortingDriverV1 d,KeyCode key){Input.keys.Add(key);Call(d,"Update");Input.keys.Clear();}
 public static void Main(){
  var p=new GameObject("player").AddComponent<Player>();Player.m_localPlayer=p;var control=p.gameObject.AddComponent<PlayerController>();
  var wood=new GameObject("Wood");var stone=new GameObject("Stone");var source=Chest("source",0);var first=Chest("wood1",3);var second=Chest("wood2",4);var other=Chest("stone",5);
  ChestSortStorage.MakeSource(source,p);first.inventory.items.Add(Item(wood,49));second.inventory.items.Add(Item(wood,45));other.inventory.items.Add(Item(stone,1));
  ChestSortStorage.Assign(first,source,p,"Wood");ChestSortStorage.Assign(second,source,p,"Wood");ChestSortStorage.Assign(other,source,p,"Stone");
  first.inventory.slots=1;second.inventory.slots=1;source.inventory.items.Add(Item(wood,20));source.inventory.items.Add(Item(stone,3));
  string result=ChestSortStorage.Sort(source,p,new[]{first,first,second,other});
  Check(result.Contains("Moved 9 items")&&source.inventory.items[0].m_stack==14,"partial stacks/overflow or duplicate discovery");
  Check(Count(wood,source,first,second)==114&&Count(stone,source,other)==4,"item conservation");
  ChestSortStorage.Sort(source,p,new[]{first,second,other});Check(Count(wood,source,first,second)==114,"repeat sort duplicated items");
  var quality=Item(stone,1);quality.m_quality=5;quality.cheated=true;quality.custom="crafted-by-player";source.inventory.items.Add(quality);
  ChestSortStorage.Sort(source,p,new[]{other});Check(other.inventory.items.Contains(quality)&&quality.m_quality==5&&quality.cheated&&quality.custom=="crafted-by-player","metadata/instance preserved");
  var quest=Item(stone,1);quest.m_shared.m_questItem=true;source.inventory.items.Add(quest);var equipped=Item(stone,1);equipped.m_equipped=true;source.inventory.items.Add(equipped);
  ChestSortStorage.Sort(source,p,new[]{other});Check(source.inventory.ContainsItem(quest)&&source.inventory.ContainsItem(equipped),"quest/equipped guard");
  var unassigned=Chest("empty",2);Check(Reject(()=>ChestSortStorage.Assign(unassigned,source,p,"Wood")),"sample required");
  Check(Reject(()=>ChestSortStorage.Assign(source,source,p,"Wood")),"source cannot target itself");
  var secondSource=Chest("source2",1);ChestSortStorage.MakeSource(secondSource,p);Check(ChestSortStorage.Linked(other,secondSource),"masters must share destinations");
  var saved=other.GetComponent<ZNetView>().zdo;var reloaded=Chest("reload",6);reloaded.GetComponent<ZNetView>().zdo=saved;Check(ChestSortStorage.Linked(reloaded,source)&&ChestSortStorage.Item(reloaded)=="Stone","assignments not stored on chest");
  other.busy=true;int before=other.inventory.moves;ChestSortStorage.Sort(source,p,new[]{other});Check(other.inventory.moves==before,"busy destination touched");other.busy=false;
  other.allowed=false;ChestSortStorage.Sort(source,p,new[]{other});Check(other.inventory.moves==before,"private destination touched");other.allowed=true;
  other.GetComponent<ZNetView>().owned=false;ChestSortStorage.Sort(source,p,new[]{other});Check(other.inventory.moves==before,"remote destination touched");other.GetComponent<ZNetView>().owned=true;
  source.inventory.items.Add(Item(stone,1));other.transform.position=new Vector3(10000,0,0);ChestSortStorage.Sort(source,p,new[]{other});Check(other.inventory.moves>before&&ChestSortStorage.Linked(other,source),"loaded distant destination excluded by a distance cap");other.transform.position=new Vector3(5,0,0);
  source.busy=true;Check(Reject(()=>ChestSortStorage.Sort(source,p,new[]{first})),"busy source accepted");source.busy=false;
  source.GetComponent<ZNetView>().owned=false;Check(Reject(()=>ChestSortStorage.Sort(source,p,new[]{first})),"remote source accepted");source.GetComponent<ZNetView>().owned=true;
  PrivateArea.allowed=false;Check(Reject(()=>ChestSortStorage.MakeSource(source,p)),"ward restriction ignored");PrivateArea.allowed=true;
  var grave=Chest("grave",1);grave.gameObject.name="Tombstone";Check(!ChestSortStorage.IsChest(grave),"tombstone accepted");
  Check(Reject(()=>ChestSortStorage.Sort(unassigned,p,new Container[0])),"unmarked chest sorted");
  var overflowSource=Chest("overflow-source",0);ChestSortStorage.MakeSource(overflowSource,p);
  var full=Chest("overflow-full",1);var partial=Chest("overflow-partial",200);var far=Chest("overflow-far",10000);
  full.inventory.items.Add(Item(wood,50));partial.inventory.items.Add(Item(wood,48));far.inventory.items.Add(Item(wood,1));
  foreach(var target in new[]{full,partial,far}){target.inventory.slots=1;ChestSortStorage.Assign(target,overflowSource,p,"Wood");}
  overflowSource.inventory.items.Add(Item(wood,10));ChestSortStorage.Sort(overflowSource,p,new[]{far,partial,full,far});
  Check(Count(wood,full)==50&&Count(wood,partial)==50&&Count(wood,far)==9&&Count(wood,overflowSource)==0,"nearest-full then partial then far overflow order failed");
  Check(Count(wood,full,partial,far,overflowSource)==109,"overflow lost or duplicated items");
  overflowSource.inventory.items.Add(Item(wood,2));ChestSortStorage.Sort(overflowSource,p,new[]{full,partial});
  Check(Count(wood,overflowSource)==2&&Count(wood,far)==9,"unloaded/undiscovered destination was touched");
  ChestSortStorage.Sort(overflowSource,p,new[]{full,partial,far});Check(Count(wood,overflowSource)==0&&Count(wood,far)==11,"destination did not resume overflow after becoming loaded");
  far.inventory.items[0].m_stack=50;overflowSource.inventory.items.Add(Item(wood,3));ChestSortStorage.Sort(overflowSource,p,new[]{full,partial,far});
  Check(Count(wood,overflowSource)==3,"all-full overflow did not remain in sorting chest");
  System.Console.WriteLine("PASS: no distance cap on loaded destinations, nearest-first full/partial/far overflow, deduplication, conservation, unloaded omission/reload and all-full remainder");
  ChestSortStorage.Clear(other,p);Check(ChestSortStorage.Role(other)==""&&ChestSortStorage.Item(other)==""&&other.inventory.items.Contains(quality),"remove assignment changed inventory");
  var multiSource=Chest("multi-source",0);var mixed=Chest("mixed",2);var fineWood=new GameObject("FineWood");
  ChestSortStorage.MakeSource(multiSource,p);mixed.inventory.items.Add(Item(wood,1));mixed.inventory.items.Add(Item(stone,1));
  ChestSortStorage.Assign(mixed,multiSource,p,"Wood");Check(ChestSortStorage.Items(mixed).Length==1,"legacy single-item assignment lost");
  ChestSortStorage.AssignItems(mixed,multiSource,p,new[]{"Wood","Stone","Wood"});
  Check(ChestSortStorage.Items(mixed).Length==2&&ChestSortStorage.Accepts(mixed,"Wood")&&ChestSortStorage.Accepts(mixed,"Stone")&&!ChestSortStorage.Accepts(mixed,"FineWood"),"multi-item dedup/exact match");
  multiSource.inventory.items.Add(Item(wood,8));multiSource.inventory.items.Add(Item(stone,6));multiSource.inventory.items.Add(Item(fineWood,3));
  ChestSortStorage.Sort(multiSource,p,new[]{mixed});
  Check(Count(wood,mixed)==9&&Count(stone,mixed)==7&&Count(fineWood,multiSource)==3,"two item types did not sort into the same chest");
  var loadedMixed=Chest("loaded mixed",2);loadedMixed.GetComponent<ZNetView>().zdo=mixed.GetComponent<ZNetView>().zdo;
  Check(ChestSortStorage.Items(loadedMixed).Length==2&&ChestSortStorage.Linked(loadedMixed,multiSource),"multiple filters not persisted");
  mixed.inventory.items.Clear();ChestSortStorage.AssignItems(mixed,multiSource,p,new[]{"Stone","Wood"});
  Check(ChestSortStorage.Items(mixed).Length==2,"saved filters required consumed samples");
  string validFilters=ChestSortStorage.Item(mixed);
  Check(Reject(()=>ChestSortStorage.AssignItems(mixed,multiSource,p,new[]{"Wood","Unknown"}))&&ChestSortStorage.Item(mixed)==validFilters,"invalid batch partially overwrote filters");
  Check(Reject(()=>ChestSortStorage.AssignItems(mixed,multiSource,p,new string[0]))&&ChestSortStorage.Item(mixed)==validFilters,"empty selection erased filters");
  ChestSortStorage.AssignItems(mixed,multiSource,p,new[]{"Wood"});
  multiSource.inventory.items.Add(Item(stone,2));ChestSortStorage.Sort(multiSource,p,new[]{mixed});Check(Count(stone,multiSource)==2&&!ChestSortStorage.Accepts(mixed,"Stone"),"removed filter still sorted");
  System.Console.WriteLine("PASS: multiple item types in one chest, legacy single filters, exact matching/dedup, persistence, samples no longer present, removed filters and all-or-nothing validation");
  System.Console.WriteLine("PASS: chest persistence/shared routing, sample assignment, partial stacks/overflow, conservation/repeat sort, metadata, quest/equipped, access/ward, busy/remote guards and clear-without-item-changes");
  p.hover=source.gameObject;ChestSortingV1.Start(p);var driver=Driver();Key(driver,KeyCode.F9);Call(driver,"LateUpdate");
  Check(!control.enabled&&Cursor.visible&&Cursor.lockState==CursorLockMode.None,"F9 did not open panel/release cursor");
  for(int frame=0;frame<10;frame++){
   GameCamera.instance.UpdateMouseCapture();Call(driver,"Update");Call(driver,"LateUpdate");
   GameCamera.instance.UpdateMouseCapture();Call(driver,"OnGUI");GameCamera.instance.UpdateMouseCapture();
   Check(!GameCamera.instance.m_mouseCapture&&ZCursor.IsRequested&&Cursor.visible&&Cursor.lockState==CursorLockMode.None,"Game camera recaptured cursor while sorting");
  }
  Key(driver,KeyCode.Escape);Check(control.enabled&&!Cursor.visible&&Cursor.lockState==CursorLockMode.Locked,"Esc did not restore controls/cursor");
  Check(GameCamera.instance.m_mouseCapture&&!ZCursor.IsRequested,"Esc did not restore native capture/request state");
  other.inventory.items.Add(Item(wood,1));
  p.hover=other.gameObject;Key(driver,KeyCode.F9);GUI.clicks.Add("[ ] Stone");Call(driver,"OnGUI");GUI.clicks.Add("[ ] Wood");Call(driver,"OnGUI");GUI.clicks.Add("Save selected items");Call(driver,"OnGUI");
  Check(ChestSortStorage.Items(other).Length==2&&ChestSortStorage.Accepts(other,"Stone")&&ChestSortStorage.Accepts(other,"Wood")&&ChestSortStorage.Network(other)==ChestSortStorage.SharedRoute,"multi-selection and Save button failed");
  Key(driver,KeyCode.Escape);Key(driver,KeyCode.F9);GUI.clicks.Add("[x] Stone");Call(driver,"OnGUI");GUI.clicks.Add("Save selected items");Call(driver,"OnGUI");
  Check(ChestSortStorage.Item(other)=="Wood","reopen did not preselect saved filters or unchecking failed");
  Key(driver,KeyCode.Escape);p.hover=source.gameObject;Key(driver,KeyCode.F9);GUI.clicks.Add("SORT ITEMS");Call(driver,"OnGUI");
  Check(ChestSortingV1.Status.Contains("Moved"),"Sort button failed");Key(driver,KeyCode.Escape);
  Key(driver,KeyCode.F9);Application.isFocused=false;Call(driver,"Update");Check(control.enabled,"focus loss stranded controls");Application.isFocused=true;
  Key(driver,KeyCode.F9);InventoryGui.visible=true;Call(driver,"Update");Check(control.enabled,"native inventory conflict stranded controls");InventoryGui.visible=false;
  Key(driver,KeyCode.F9);ChestSortingV1.Stop();Call(driver,"Update");Check(control.enabled&&ChestSortingV1.Enabled==0,"stop did not restore controls");
  Check(ChestSortStorage.Role(source)=="source","stop removed saved assignments");
  ChestSortingV1.Start(p);driver=Driver();Key(driver,KeyCode.F9);ZNet.instance.world=2;Call(driver,"Update");Check(control.enabled&&ChestSortingV1.Enabled==0,"world unload cleanup");ZNet.instance.world=1;
  ChestSortingV1.Start(p);driver=Driver();Key(driver,KeyCode.F9);p.dead=true;Call(driver,"Update");Check(control.enabled&&ChestSortingV1.Enabled==0,"death cleanup");p.dead=false;

  GameCamera.instance.m_mouseCapture=false;ZCursor.Show();ZCursor.LockState=CursorLockMode.None;
  ChestSortingV1.Start(p);driver=Driver();Key(driver,KeyCode.F9);Key(driver,KeyCode.Escape);
  Check(!GameCamera.instance.m_mouseCapture&&ZCursor.IsRequested&&Cursor.visible&&Cursor.lockState==CursorLockMode.None,"Close overwrote prior free-cursor settings");
  ChestSortingV1.Stop();Call(driver,"Update");
  GameCamera.instance.m_mouseCapture=true;ZCursor.Hide();ZCursor.LockState=CursorLockMode.Locked;
  ChestSortingV1.Start(p);driver=Driver();Key(driver,KeyCode.F9);Call(driver,"OnDisable");
  Check(control.enabled&&GameCamera.instance.m_mouseCapture&&!ZCursor.IsRequested,"Disable did not release modal capture state");
  ChestSortingV1.Stop();Call(driver,"Update");
  ChestSortingV1.Start(p);driver=Driver();Key(driver,KeyCode.F9);
  GameCamera.instance=new GameObject("replacement camera").AddComponent<GameCamera>();Call(driver,"Update");
  Check(control.enabled&&GameCamera.instance.m_mouseCapture,"Panel changed replacement camera capture");
  ChestSortingV1.Stop();Call(driver,"Update");

  InventoryGui.instance=new GameObject("inventory gui").AddComponent<InventoryGui>();InventoryGui.instance.Setup();
  var gui=InventoryGui.instance;var take=gui.m_takeAllButton.GetComponent<RectTransform>();float nativeWidth=take.sizeDelta.x,nativeX=take.anchoredPosition.x;
  int nativeClicks=0;gui.m_takeAllButton.onClick.AddListener(delegate{nativeClicks++;});
  InventoryGui.visible=true;gui.m_currentContainer=source;source.busy=true;
  ChestSortingV1.Start(p);driver=Driver();Call(driver,"Update");
  UnityEngine.UI.Button nativeSort=null;
  foreach(var b in UnityEngine.Object.FindObjectsByType<UnityEngine.UI.Button>(FindObjectsSortMode.None))if(b.name=="SoloToolkit_ChestSortingButton")nativeSort=b;
  Check(nativeSort&&take.sizeDelta.x<nativeWidth,"sorting button not inserted beside native chest actions");
  int loads=source.loads;nativeSort.onClick.Invoke();
  Check(nativeClicks==0&&!control.enabled&&ChestSortingV1.Enabled==1&&source.loads==loads,"native action leaked, mode stopped or open inventory reloaded");
  var input=gui.m_inventoryRoot.GetComponent<CanvasGroup>();Check(input&&!input.interactable&&!input.blocksRaycasts,"underlying chest input not blocked during assignment");
  GUI.clicks.Add("SORT ITEMS");Call(driver,"OnGUI");Check(ChestSortingV1.Status.Contains("Moved"),"own open sorting chest rejected as busy");
  GUI.clicks.Add("Back to chest");Call(driver,"OnGUI");Check(control.enabled&&input.interactable&&ChestSortingV1.Enabled==1,"back to chest disabled sorting or stranded native input");
  InventoryGui.visible=false;gui.m_currentContainer=null;source.busy=false;Call(driver,"Update");
  Check(!nativeSort&&take.sizeDelta.x==nativeWidth&&take.anchoredPosition.x==nativeX,"native row not restored after chest closes");
  gui.m_takeAllButton.onClick.Invoke();Check(nativeClicks==1,"original Take All callback was changed");
  var configA=Chest("configA",3);var configB=Chest("configB",4);configA.inventory.items.Add(Item(wood,1));configA.inventory.items.Add(Item(stone,1));configB.inventory.items.Add(Item(stone,1));
  foreach(var chest in new[]{configA,configB}){
   InventoryGui.visible=true;gui.m_currentContainer=chest;chest.busy=true;Call(driver,"Update");
   foreach(var b in UnityEngine.Object.FindObjectsByType<UnityEngine.UI.Button>(FindObjectsSortMode.None))if(b.name=="SoloToolkit_ChestSortingButton")nativeSort=b;
   nativeSort.onClick.Invoke();GUI.clicks.Add("Select all");Call(driver,"OnGUI");GUI.clicks.Add("Save selected items");Call(driver,"OnGUI");
   Check(ChestSortStorage.Items(chest).Length==chest.inventory.items.Count&&ChestSortStorage.Network(chest)==ChestSortStorage.SharedRoute&&ChestSortingV1.Enabled==1,"open-chest assignment lost item selection/master/active mode");
   GUI.clicks.Add("Back to chest");Call(driver,"OnGUI");InventoryGui.visible=false;gui.m_currentContainer=null;chest.busy=false;Call(driver,"Update");
   Check(ChestSortingV1.Enabled==1,"moving between chests disabled sorting");
  }
  InventoryGui.visible=true;gui.m_currentContainer=configA;configA.busy=true;Call(driver,"Update");
  foreach(var b in UnityEngine.Object.FindObjectsByType<UnityEngine.UI.Button>(FindObjectsSortMode.None))if(b.name=="SoloToolkit_ChestSortingButton")nativeSort=b;
  gui.m_dragItem=Item(wood,1);Call(driver,"Update");Check(!nativeSort.interactable,"sorting setup allowed while dragging an item");gui.m_dragItem=null;Call(driver,"Update");Check(nativeSort.interactable,"sorting button did not recover after item drag");
  nativeSort.onClick.Invoke();InventoryGui.visible=false;gui.m_currentContainer=null;configA.busy=false;Call(driver,"Update");Call(driver,"Update");
  Check(control.enabled&&ChestSortingV1.Enabled==1,"closing native storage while modal open stopped mode or stranded controls");
  ChestSortingV1.Stop();ChestSortingV1.Start(p);Check(Driver()==driver&&ChestSortingV1.Enabled==1,"rapid stop/start requires a second activation");
  ChestSortingV1.Stop();Call(driver,"Update");Check(ChestSortingV1.Enabled==0&&take.sizeDelta.x==nativeWidth,"stop failed to clean native integration");
  var routeA=Chest("shared-master-A",0);var routeB=Chest("shared-master-B",10);var routeNear=Chest("shared-dest-near",2);var routeFar=Chest("shared-dest-far",1000);
  ChestSortStorage.MakeSource(routeA,p);ChestSortStorage.MakeSource(routeB,p);
  routeNear.inventory.items.Add(Item(wood,49));routeNear.inventory.items.Add(Item(stone,49));routeNear.inventory.slots=2;
  routeFar.inventory.items.Add(Item(wood,1));routeFar.inventory.items.Add(Item(stone,1));routeFar.inventory.slots=2;
  ChestSortStorage.AssignItems(routeNear,p,new[]{"Wood","Stone"});ChestSortStorage.AssignItems(routeFar,p,new[]{"Wood","Stone"});
  // Simulate saved destinations from two pre-shared-route installations.
  routeNear.GetComponent<ZNetView>().zdo.Set("SoloToolkit.Sort.Network.v1",ChestSortStorage.Identity(routeA));
  routeFar.GetComponent<ZNetView>().zdo.Set("SoloToolkit.Sort.Network.v1",ChestSortStorage.Identity(routeB));
  routeA.inventory.items.Add(Item(wood,3));routeA.inventory.items.Add(Item(stone,4));routeB.inventory.items.Add(Item(wood,5));routeB.inventory.items.Add(Item(stone,6));
  var sharedLoaded=new[]{routeA,routeB,routeNear,routeFar,routeNear};
  ChestSortStorage.Sort(routeA,p,sharedLoaded);Check(Count(wood,routeB)==5&&Count(stone,routeB)==6,"master used another master as a destination");
  ChestSortStorage.Sort(routeB,p,sharedLoaded);
  Check(routeA.inventory.items.Count==0&&routeB.inventory.items.Count==0&&Count(wood,routeNear)==50&&Count(wood,routeFar)==8&&Count(stone,routeNear)==50&&Count(stone,routeFar)==10,"masters did not share legacy destinations and overflow");
  Check(ChestSortStorage.Network(routeNear)==ChestSortStorage.Identity(routeA)&&ChestSortStorage.Network(routeFar)==ChestSortStorage.Identity(routeB),"legacy migration unnecessarily rewrote chest data");
  ChestSortStorage.Clear(routeA,p);routeB.inventory.items.Add(Item(wood,2));ChestSortStorage.Sort(routeB,p,sharedLoaded);
  Check(Count(wood,routeFar)==10&&ChestSortStorage.Linked(routeNear,routeB),"removing original master broke shared destinations");
  ChestSortStorage.Sort(routeB,p,sharedLoaded);Check(Count(wood,routeNear,routeFar)==60&&Count(stone,routeNear,routeFar)==60,"repeat shared sorting duplicated items");
  var direct=Chest("direct shared destination",1);direct.inventory.items.Add(Item(wood,1));direct.busy=true;
  InventoryGui.visible=true;gui.m_currentContainer=direct;
  ChestSortingV1.Start(p);driver=Driver();Call(driver,"Update");
  foreach(var b in UnityEngine.Object.FindObjectsByType<UnityEngine.UI.Button>(FindObjectsSortMode.None))if(b.name=="SoloToolkit_ChestSortingButton")nativeSort=b;
  nativeSort.onClick.Invoke();GUI.clicks.Add("Select all");Call(driver,"OnGUI");GUI.clicks.Add("Save selected items");Call(driver,"OnGUI");
  Check(ChestSortStorage.Accepts(direct,"Wood")&&ChestSortStorage.Network(direct)==ChestSortStorage.SharedRoute&&ChestSortingV1.Enabled==1,"destination setup still required selecting a master");
  GUI.clicks.Add("Back to chest");Call(driver,"OnGUI");InventoryGui.visible=false;gui.m_currentContainer=null;direct.busy=false;ChestSortingV1.Stop();Call(driver,"Update");
  System.Console.WriteLine("PASS: two masters share mixed-item legacy destinations/overflow, masters never target each other, removed-original-master compatibility, repeat-sort conservation and native destination setup without selecting a master");
  System.Console.WriteLine("PASS: native chest action/callback isolation, own-open inventory access, multi-item setup across two chests without reactivation, modal input restoration, drag guard, quick toggle and native row cleanup");
  System.Console.WriteLine("PASS: game-camera capture ordering, native cursor visibility/request state, prior free-cursor preservation and disable cleanup");
  System.Console.WriteLine("PASS: F9 panel, Esc, cursor/controller restoration, focus/native-menu guards, stop/world/death cleanup and persistent assignments");
 }
}
