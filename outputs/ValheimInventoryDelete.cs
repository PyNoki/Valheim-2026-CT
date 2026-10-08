using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

namespace ValheimSoloToolkit
{
    public static class InventoryDeleteV1
    {
        public static int Enabled;
        public static string LastError;
        private static Player owner;
        private static InventoryDeletePanel panel;
        public static void Configure(Player player) { owner=player;LastError=null;Enabled=1; }
        public static void Disable() { Enabled=0;owner=null; }
        internal static bool Owns(Player player) { return Enabled==1 && player && player==owner && player==Player.m_localPlayer; }
        internal static void Fault(Exception e) { Enabled=0;LastError=e.GetType().Name+": "+e.Message;if(LastError.Length>400)LastError=LastError.Substring(0,400); }
        public static void Tick(InventoryGui gui)
        {
            if(!Owns(owner) || !gui) return;
            try
            {
                if(!panel || panel.Owner!=owner || panel.Gui!=gui)
                {
                    if(panel) UnityEngine.Object.Destroy(panel.gameObject);
                    GameObject go=new GameObject("SoloToolkit_InventoryDeleteDriver");
                    panel=go.AddComponent<InventoryDeletePanel>();panel.Setup(gui,owner);
                }
            }
            catch(Exception e) { Fault(e); }
        }
    }

    public sealed class InventoryDeletePanel:MonoBehaviour
    {
        public Player Owner;
        public InventoryGui Gui;
        private GameObject root;
        private TMP_Text label;
        private TMP_Text buttonLabel;
        private Button destroyButton,cancelButton;
        private ItemDrop.ItemData armed;
        private int armedCount;
        private string result;
        private float resultUntil;
        private static readonly BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        private static readonly FieldInfo DragItem=typeof(InventoryGui).GetField("m_dragItem",Flags);
        private static readonly FieldInfo DragInventory=typeof(InventoryGui).GetField("m_dragInventory",Flags);
        private static readonly FieldInfo DragAmount=typeof(InventoryGui).GetField("m_dragAmount",Flags);
        private static readonly MethodInfo ClearDrag=typeof(InventoryGui).GetMethod("SetupDragItem",Flags);

        private static RectTransform Rect(GameObject go,Transform parent,float x,float y,float w,float h)
        {
            RectTransform r=go.GetComponent<RectTransform>();r.SetParent(parent,false);
            r.anchorMin=Vector2.zero;r.anchorMax=Vector2.zero;r.pivot=Vector2.zero;
            r.anchoredPosition=new Vector2(x,y);r.sizeDelta=new Vector2(w,h);return r;
        }
        private TMP_Text Text(string name,Transform parent,float x,float y,float w,float h,TMP_FontAsset font)
        {
            GameObject go=new GameObject(name,typeof(RectTransform));Rect(go,parent,x,y,w,h);
            TMP_Text text=go.AddComponent<TextMeshProUGUI>();text.font=font;text.fontSize=16;
            text.color=Color.white;text.alignment=TextAlignmentOptions.MidlineLeft;
            text.raycastTarget=false;return text;
        }
        private Button Button(string name,float x,float w,TMP_FontAsset font,out TMP_Text caption)
        {
            GameObject go=new GameObject(name,typeof(RectTransform),typeof(CanvasRenderer),typeof(Image),typeof(Button));
            Rect(go,root.transform,x,10,w,32);
            Image image=go.GetComponent<Image>();image.color=new Color(0.4f,0.13f,0.10f,1f);
            Button button=go.GetComponent<Button>();button.targetGraphic=image;
            caption=Text(name+" label",go.transform,8,0,w-16,32,font);caption.alignment=TextAlignmentOptions.Center;
            return button;
        }
        public void Setup(InventoryGui gui,Player player)
        {
            Gui=gui;Owner=player;
            if(DragItem==null||DragInventory==null||DragAmount==null||ClearDrag==null)throw new MissingMemberException("Inventory drag UI changed");
            Canvas canvas=gui.GetComponentInParent<Canvas>();
            if(!canvas)throw new InvalidOperationException("Inventory canvas unavailable");
            Transform parent=canvas.rootCanvas.transform;
            TMP_Text template=gui.GetComponentInChildren<TMP_Text>(true);
            TMP_FontAsset font=template?template.font:TMP_Settings.defaultFontAsset;
            root=new GameObject("SoloToolkit_DestroyStack",typeof(RectTransform),typeof(CanvasRenderer),typeof(Image));
            RectTransform panelRect=Rect(root,parent,0,0,440,88);
            panelRect.anchorMin=new Vector2(0.025f,0.12f);panelRect.anchorMax=panelRect.anchorMin;
            root.GetComponent<Image>().color=new Color(0.07f,0.08f,0.09f,0.96f);
            label=Text("Selected stack",root.transform,12,48,416,34,font);
            destroyButton=Button("Destroy stack",12,286,font,out buttonLabel);
            TMP_Text cancelLabel;cancelButton=Button("Cancel",310,118,font,out cancelLabel);cancelLabel.text="Cancel";
            destroyButton.onClick.AddListener(ClickDestroy);cancelButton.onClick.AddListener(Cancel);
            root.SetActive(false);
        }
        private ItemDrop.ItemData Candidate()
        {
            if(!InventoryDeleteV1.Owns(Owner)||!Gui||!InventoryGui.IsVisible())return null;
            Inventory inventory=DragInventory.GetValue(Gui) as Inventory;
            ItemDrop.ItemData item=DragItem.GetValue(Gui) as ItemDrop.ItemData;
            if(inventory!=Owner.GetInventory()||item==null||!inventory.GetAllItems().Contains(item))return null;
            return item;
        }
        private static bool Allowed(ItemDrop.ItemData item) { return item!=null && item.m_stack>0 && !item.m_equipped && !item.m_shared.m_questItem; }
        private bool WholeStack(ItemDrop.ItemData item) { return item!=null && (int)DragAmount.GetValue(Gui)==item.m_stack; }
        private static string Name(ItemDrop.ItemData item)
        {
            string name=Localization.instance.Localize(item.m_shared.m_name);
            return name.Length>48?name.Substring(0,48)+"...":name;
        }
        private void Cancel() {armed=null;armedCount=0;}
        private void ClickDestroy()
        {
            try
            {
                ItemDrop.ItemData item=Candidate();
                if(!Allowed(item)||!WholeStack(item)){Cancel();return;}
                if(armed!=item||armedCount!=item.m_stack){armed=item;armedCount=item.m_stack;return;}
                // Revalidate at the click, then clear the drag reference before removing the object.
                Inventory inventory=Owner.GetInventory();
                if(Candidate()!=armed||!inventory.GetAllItems().Contains(armed)){Cancel();return;}
                string name=Name(item);int count=item.m_stack;
                ClearDrag.Invoke(Gui,new object[]{null,null,0});
                if(!inventory.RemoveItem(item))throw new InvalidOperationException("Stack was not removed");
                Cancel();result="Destroyed "+count+" x "+name;resultUntil=Time.time+3f;
            }
            catch(Exception e){Cancel();InventoryDeleteV1.Fault(e);}
        }
        private void Update()
        {
            try
            {
                if(!InventoryDeleteV1.Owns(Owner)||!Gui){if(root)root.SetActive(false);Destroy(gameObject);return;}
                if(!root)return;
                bool visible=InventoryGui.IsVisible();root.SetActive(visible);
                if(!visible){Cancel();return;}
                ItemDrop.ItemData item=Candidate();
                if(armed!=item || (item!=null&&(armedCount!=item.m_stack||!WholeStack(item))))Cancel();
                destroyButton.interactable=Allowed(item)&&WholeStack(item);cancelButton.interactable=armed!=null;
                buttonLabel.text=armed==null?"Destroy entire stack":"Confirm destroy "+armedCount+" items";
                if(item==null)label.text=Time.time<resultUntil?result:"Pick up a stack from your own inventory.";
                else if(!Allowed(item))label.text="Equipped and quest items cannot be destroyed.";
                else if(!WholeStack(item))label.text="Split drag: place it in an empty slot first, then pick up that stack.";
                else label.text=Name(item)+" x "+item.m_stack+(armed!=null?" — permanently delete?":" — entire stack.");
            }
            catch(Exception e){InventoryDeleteV1.Fault(e);if(root)root.SetActive(false);Destroy(gameObject);}
        }
        private void OnDestroy(){if(root)Destroy(root);}
    }
}
