using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;

namespace ValheimSoloToolkit
{
    public static class DragBuildV5
    {
        public static int Enabled;
        internal static int Mode;
        internal sealed class RequestData {internal int Code;internal string Text;}
        private static readonly Queue<RequestData> requests=new Queue<RequestData>();
        public static void Request(int code,string text){lock(requests){if(requests.Count>=8)throw new InvalidOperationException("Wait for the queued building command.");if(code==1||code==2)BlueprintCapture.Clear();requests.Enqueue(new RequestData{Code=code,Text=text});Status="Building command queued. Return to Valheim with your hammer and close game menus to process it.";}}
        internal static RequestData TakeRequest(){lock(requests){return requests.Count==0?null:requests.Dequeue();}}
        public static string SaveCaptured()
        {
            if(Enabled!=1||Mode!=1)throw new InvalidOperationException("Enable Blueprint mode and capture a selection first.");
            string path=BlueprintCapture.Save(BlueprintWorkshop.Folder);Status="Saved blueprint: "+path;return path;
        }
        public static string SavedNames(){return BlueprintWorkshop.Catalog();}
        public static void ConfigureBlueprint(Player p){Configure(p);Mode=1;Status="Blueprint tools ready. Use Capture or Load in the Building window, then return to the game with your hammer.";}
        public static string Status;
        internal static Player Owner;
        internal static int Generation;
        private static DragBuildDriverV5 driver;
        internal const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        internal static readonly FieldInfo Ghost=typeof(Player).GetField("m_placementGhost",Flags);
        internal static readonly FieldInfo PlacementStatus=typeof(Player).GetField("m_placementStatus",Flags);
        internal static readonly FieldInfo Pressed=typeof(Player).GetField("m_placePressedTime",Flags);
        internal static readonly FieldInfo LastUse=typeof(Player).GetField("m_lastToolUseTime",Flags);
        internal static readonly MethodInfo Place=typeof(Player).GetMethod("PlacePiece",Flags,null,new Type[]{typeof(Piece),typeof(Vector3),typeof(Quaternion),typeof(bool),typeof(bool)},null);
        internal static readonly MethodInfo BuildStamina=typeof(Player).GetMethod("GetBuildStamina",Flags);
        internal static readonly MethodInfo BuildDurability=typeof(Player).GetMethod("GetPlaceDurability",Flags);
        internal static readonly MethodInfo UpdateGhost=typeof(Player).GetMethod("UpdatePlacementGhost",Flags);
        internal static readonly MethodInfo Selected=typeof(Player).GetMethod("GetSelectedPiece",Flags);
        internal static readonly MethodInfo RightItem=typeof(Humanoid).GetMethod("GetRightItem",Flags);
        public static void Configure(Player p)
        {
            if(Ghost==null||PlacementStatus==null||Pressed==null||LastUse==null||Place==null||BuildStamina==null||BuildDurability==null||UpdateGhost==null||Selected==null||RightItem==null)
                throw new MissingMemberException("Drag-build placement metadata unavailable.");
            BlueprintCapture.Clear();Generation++;Owner=p;Enabled=1;Mode=0;lock(requests){requests.Clear();}Status="Hammer: Ctrl + left-drag previews a row; release left click to build. Right click cancels.";
        }
        public static void Disable(){BlueprintCapture.Clear();Enabled=0;Owner=null;lock(requests){requests.Clear();}}
        internal static bool Owns(Player p){return Enabled==1&&p&&p==Owner&&p==Player.m_localPlayer;}
        // True consumes placement input; false runs the unmodified placement method.
        public static bool Tick(Player p,bool input,float dt)
        {
            if(!Owns(p))return false;
            try
            {
                if(driver&&(driver.Owner!=p||driver.Generation!=Generation)){driver.Cancel();UnityEngine.Object.Destroy(driver.gameObject);driver=null;}
                if(!driver){driver=new GameObject("SoloToolkit_DragBuild").AddComponent<DragBuildDriverV5>();driver.Owner=p;driver.Generation=Generation;}
                return driver.Step(input,dt);
            }
            catch(Exception e){Status="Drag build stopped: "+e.GetBaseException().Message;if(driver)driver.Cancel();Disable();return true;}
        }
    }
    public sealed class DragBuildDriverV5:MonoBehaviour
    {
        public Player Owner;
        internal int Generation;
        private bool dragging,committing,releaseGuard;
        private readonly BlueprintWorkshop blueprint=new BlueprintWorkshop();
        private Piece selected;
        private Vector3 anchor,step;
        private Quaternion rotation;
        private int count=1,index;
        private readonly List<GameObject> previews=new List<GameObject>();
        private Material previewMaterial;
        private List<Vector3> snapPoints=new List<Vector3>();
        private float spanX,spanZ;
        public void Cancel()
        {
            dragging=false;committing=false;selected=null;
            if(Owner)DragBuildV5.Pressed.SetValue(Owner,-9999f);
            foreach(var p in previews)if(p)Destroy(p);previews.Clear();
            if(previewMaterial)Destroy(previewMaterial);previewMaterial=null;
        }
        private bool Allowed(bool input)
        {
            var item=(ItemDrop.ItemData)DragBuildV5.RightItem.Invoke(Owner,null);
            return input&&Application.isFocused&&Owner.enabled&&!Owner.IsDead()&&!Owner.IsTeleporting()&&Owner.InPlaceMode()
                &&item!=null&&item.m_shared.m_name=="$item_hammer"&&!InventoryGui.IsVisible()&&!Menu.IsVisible()
                &&!Console.IsVisible()&&!Minimap.IsOpen()&&!Hud.IsPieceSelectionVisible()&&!Hud.InRadial()
                &&!(Chat.instance&&Chat.instance.HasFocus());
        }
        private bool Begin()
        {
            DragBuildV5.UpdateGhost.Invoke(Owner,new object[]{false});
            var ghost=DragBuildV5.Ghost.GetValue(Owner) as GameObject;
            selected=DragBuildV5.Selected.Invoke(Owner,null) as Piece;
            if(!ghost||!selected||Convert.ToInt32(DragBuildV5.PlacementStatus.GetValue(Owner))!=0)return false;
            string name=selected.gameObject.name.ToLowerInvariant();
            if(!(name.Contains("floor")||name.Contains("wall")||name.Contains("beam"))||name.Contains("roof")||name.Contains("26")||name.Contains("45"))return false;
            anchor=ghost.transform.position;rotation=ghost.transform.rotation;
            var points=new List<Transform>();ghost.GetComponent<Piece>().GetSnapPoints(points);snapPoints.Clear();
            foreach(var point in points)snapPoints.Add(ghost.transform.InverseTransformPoint(point.position));
            spanX=DragRowPlan.Span(snapPoints,true);spanZ=DragRowPlan.Span(snapPoints,false);
            if(spanX<0.5f&&spanZ<0.5f)return false;
            step=rotation*(spanX>=0.5f?Vector3.right*spanX:Vector3.forward*spanZ);count=1;index=0;
            dragging=true;ShowPreview(ghost);return true;
        }
        private void ShowPreview(GameObject ghost)
        {
            if(!previewMaterial)
            {
                var shader=Shader.Find("Sprites/Default");if(!shader)throw new InvalidOperationException("Preview shader unavailable.");
                previewMaterial=new Material(shader);previewMaterial.color=new Color(0.2f,0.85f,1f,0.3f);
            }
            while(previews.Count<count)
            {
                var root=new GameObject("Row preview");
                foreach(var mesh in ghost.GetComponentsInChildren<MeshFilter>(true))
                {
                    if(!mesh.sharedMesh)continue;
                    var obj=new GameObject("Preview mesh");obj.transform.SetParent(root.transform,false);
                    obj.transform.localPosition=ghost.transform.InverseTransformPoint(mesh.transform.position);
                    obj.transform.localRotation=Quaternion.Inverse(ghost.transform.rotation)*mesh.transform.rotation;
                    obj.transform.localScale=mesh.transform.lossyScale;
                    obj.AddComponent<MeshFilter>().sharedMesh=mesh.sharedMesh;
                    var renderer=obj.AddComponent<MeshRenderer>();var mats=new Material[mesh.sharedMesh.subMeshCount];
                    for(int n=0;n<mats.Length;n++)mats[n]=previewMaterial;
                    renderer.sharedMaterials=mats;renderer.shadowCastingMode=ShadowCastingMode.Off;renderer.receiveShadows=false;
                }
                previews.Add(root);
            }
            for(int i=0;i<previews.Count;i++)
            {previews[i].SetActive(i<count&&i>=index);previews[i].transform.position=anchor+step*i;previews[i].transform.rotation=rotation;}
        }
        private void PlaceNext()
        {
            // Build a bounded batch each frame at the committed coordinates. Do not
            // re-raycast, move the camera/player, or re-enter hammer input/cooldown.
            for(int batch=0;batch<4&&committing;batch++)
            {
                var tool=(ItemDrop.ItemData)DragBuildV5.RightItem.Invoke(Owner,null);
                bool free=Owner.NoCostCheat();
                bool freeMaterials=free||ZoneSystem.instance.GetGlobalKey(selected.FreeBuildKey());
                if(!free)
                {
                    if(!Owner.HaveRequirements(selected,Player.RequirementMode.CanBuild))
                    {StopRow("missing materials or crafting station");return;}
                    if(!Owner.HaveStamina(tool.m_shared.m_attack.m_attackStamina))
                    {StopRow("not enough stamina (enable Unlimited stamina or Free Crafting)");return;}
                    if(tool.m_shared.m_useDurability&&tool.m_durability<=0)
                    {StopRow("hammer needs repair");return;}
                }
                // Use native creation: creator, network identity, support, placement
                // callbacks and effects are initialized by Player.PlacePiece.
                // Direct placement is a toolkit override, so retain cheat marking.
                bool cheated=!PlayerProfile.s_bypassCheatChecks;
                DragBuildV5.Place.Invoke(Owner,new object[]{selected,anchor+step*index,rotation,false,cheated});
                // Advance immediately after creation so a later bookkeeping failure
                // can never retry and duplicate an already placed piece.
                index++;
                previews[index-1].SetActive(false);
                if(!freeMaterials)Owner.ConsumeResources(selected.m_resources,0,-1,1);
                if(!free)
                {
                    Owner.UseStamina((float)DragBuildV5.BuildStamina.Invoke(Owner,null));
                    if(tool.m_shared.m_useDurability)
                        tool.m_durability=Mathf.Max(0,tool.m_durability-(float)DragBuildV5.BuildDurability.Invoke(Owner,new object[]{tool})*Game.m_durabilityRate);
                }
                DragBuildV5.LastUse.SetValue(Owner,Time.time);
                DragBuildV5.Status="Auto-built "+index+"/"+count+" pieces.";
                if(index>=count)Cancel();
            }
        }
        private void StopRow(string reason)
        {
            DragBuildV5.Status="Row stopped after "+index+"/"+count+" pieces: "+reason+".";
            Cancel();
        }
        public bool Step(bool input,float dt)
        {
            if(DragBuildV5.Mode==1)return blueprint.Step(Owner,Allowed(input));
            bool down=Input.GetMouseButton(0),ctrl=Input.GetKey(KeyCode.LeftControl)||Input.GetKey(KeyCode.RightControl);
            bool busy=dragging||committing;
            if(!Allowed(input)){if(busy){Cancel();releaseGuard=down;DragBuildV5.Status="Row cancelled: controls or tool changed.";}return busy;}
            if(releaseGuard){releaseGuard=down;return true;}
            if(busy&&((Piece)DragBuildV5.Selected.Invoke(Owner,null)!=selected||Input.GetMouseButtonDown(1)||Input.GetKeyDown(KeyCode.Escape)))
            {Cancel();releaseGuard=down;DragBuildV5.Status="Row cancelled. Already placed pieces remain.";return true;}
            if(committing){PlaceNext();return true;}
            if(!dragging)
            {
                if(!ctrl||!Input.GetMouseButtonDown(0))return false;
                releaseGuard=true;
                if(!Begin()){Cancel();DragBuildV5.Status="Choose a valid straight floor, wall or horizontal beam with snap points.";return true;}
                releaseGuard=false;
            }
            if(!ctrl){Cancel();releaseGuard=down;DragBuildV5.Status="Row cancelled: Ctrl released.";return true;}
            if(!down){dragging=false;committing=true;index=0;return true;}
            var ray=new Ray(GameCamera.instance.transform.position,GameCamera.instance.transform.forward);
            float distance;
            if(new Plane(Vector3.up,anchor).Raycast(ray,out distance)&&distance<100f)
            {
                Vector3 local=Quaternion.Inverse(rotation)*(ray.GetPoint(distance)-anchor);
                bool x=spanX>=0.5f&&(spanZ<0.5f||Mathf.Abs(local.x)>=Mathf.Abs(local.z));
                float extent=x?spanX:spanZ,value=x?local.x:local.z;
                step=rotation*((x?Vector3.right:Vector3.forward)*extent*(value<0?-1:1));
                count=DragRowPlan.Count(value,extent);ShowPreview((GameObject)DragBuildV5.Ghost.GetValue(Owner));
            }
            DragBuildV5.Pressed.SetValue(Owner,-9999f);
            DragBuildV5.Status="Preview: "+count+" pieces. Release left click (hold Ctrl) to place; right click cancels. Auto-builds at the preview positions; no chasing or line of sight needed.";
            return true;
        }
        private void Update(){if(!DragBuildV5.Owns(Owner)||Generation!=DragBuildV5.Generation){Cancel();Destroy(gameObject);}}
        private void OnDestroy(){Cancel();blueprint.Dispose();}
    }
}
