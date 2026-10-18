using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
namespace ValheimSoloToolkit {
 // Add a third action to the existing chest button row; restore native layout
 // when storage closes or sorting stops. Never reuse a cloned native callback.
 public sealed class ChestSortInventoryButton {
  static readonly BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  static readonly FieldInfo Take=typeof(InventoryGui).GetField("m_takeAllButton",Flags),Stack=typeof(InventoryGui).GetField("m_stackAllButton",Flags);
  static readonly FieldInfo Root=typeof(InventoryGui).GetField("m_inventoryRoot",Flags),Drag=typeof(InventoryGui).GetField("m_dragItem",Flags);
  InventoryGui gui;Button button;TMP_Text label;RectTransform take,stack;Layout savedTake,savedStack;
  CanvasGroup group,ownedGroup;bool blocked,interactable,raycasts;
  struct Layout {
   public Vector2 min,max,pivot,size,position;public Vector3 local;
   public Layout(RectTransform r){min=r.anchorMin;max=r.anchorMax;pivot=r.pivot;size=r.sizeDelta;position=r.anchoredPosition;local=r.localPosition;}
   public void Restore(RectTransform r){if(!r)return;r.anchorMin=min;r.anchorMax=max;r.pivot=pivot;r.sizeDelta=size;r.anchoredPosition=position;}
  }
  public static bool Dragging(){return InventoryGui.instance&&Drag!=null&&Drag.GetValue(InventoryGui.instance)!=null;}
  public bool Available {get{return button;}}
  public void Ensure(Action clicked){
   if(button&&gui==InventoryGui.instance)return;
   Dispose();gui=InventoryGui.instance;
   var takeButton=gui&&Take!=null?Take.GetValue(gui) as Button:null;
   var stackButton=gui&&Stack!=null?Stack.GetValue(gui) as Button:null;
   if(!takeButton||!stackButton)throw new InvalidOperationException("Chest buttons are unavailable.");
   var takeRect=takeButton.GetComponent<RectTransform>();var stackRect=stackButton.GetComponent<RectTransform>();
   if(!takeRect||!stackRect||takeRect.parent!=stackRect.parent||!(takeRect.parent is RectTransform))throw new InvalidOperationException("Chest button layout is unavailable. F9 remains available.");
   take=takeRect;stack=stackRect;
   savedTake=new Layout(take);savedStack=new Layout(stack);
   float left=Math.Min(take.localPosition.x-take.pivot.x*take.rect.width,stack.localPosition.x-stack.pivot.x*stack.rect.width);
   float right=Math.Max(take.localPosition.x+(1-take.pivot.x)*take.rect.width,stack.localPosition.x+(1-stack.pivot.x)*stack.rect.width);
   float width=(right-left-12f)/3f,height=Math.Min(take.rect.height,stack.rect.height);
   if(width<65f||height<15f)throw new InvalidOperationException("Chest button row is too small. F9 remains available.");
   GameObject clone=UnityEngine.Object.Instantiate(takeButton.gameObject,take.parent);
   clone.name="SoloToolkit_ChestSortingButton";button=clone.GetComponent<Button>();
   button.onClick=new Button.ButtonClickedEvent();button.onClick.AddListener(delegate{clicked();});
   label=clone.GetComponentInChildren<TMP_Text>(true);
   var parent=(RectTransform)take.parent;
   float y=take.localPosition.y+(0.5f-take.pivot.y)*take.rect.height;
   Place(take,parent,left,y,width,height);Place(stack,parent,left+width+6,y,width,height);
   Place(clone.GetComponent<RectTransform>(),parent,left+2*(width+6),y,width,height);
   clone.SetActive(true);Refresh();
  }
  static void Place(RectTransform r,RectTransform parent,float x,float y,float width,float height){r.anchorMin=parent.pivot;r.anchorMax=parent.pivot;r.pivot=new Vector2(0,0.5f);r.sizeDelta=new Vector2(width,height);r.anchoredPosition=new Vector2(x,y);}
  public void Refresh(){if(!button)return;button.interactable=!Dragging();if(label){label.text="Chest sorting";label.enableAutoSizing=true;label.fontSizeMin=10;}}
  public void BlockInventory(){
   if(blocked)return;
   var current=gui?gui:InventoryGui.instance;
   var root=current&&Root!=null?Root.GetValue(current) as Transform:null;
   if(!root)throw new InvalidOperationException("Inventory input root unavailable.");
   group=root.GetComponent<CanvasGroup>();if(!group){group=root.gameObject.AddComponent<CanvasGroup>();ownedGroup=group;}
   interactable=group.interactable;raycasts=group.blocksRaycasts;group.interactable=false;group.blocksRaycasts=false;blocked=true;
  }
  public void UnblockInventory(){if(!blocked)return;blocked=false;if(group){group.interactable=interactable;group.blocksRaycasts=raycasts;}group=null;}
  public void Dispose(){UnblockInventory();if(ownedGroup)UnityEngine.Object.Destroy(ownedGroup);ownedGroup=null;savedTake.Restore(take);savedStack.Restore(stack);if(button){button.onClick.RemoveAllListeners();UnityEngine.Object.Destroy(button.gameObject);}button=null;label=null;gui=null;take=null;stack=null;}
 }
}
