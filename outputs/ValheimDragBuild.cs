using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;

namespace ValheimSoloToolkit
{
    public static class DragBuildV2
    {
        public static int Enabled;
        public static string Status;
        internal static Player Owner;
        internal static bool Bypass;
        internal static int Generation;
        private static DragBuildDriverV2 driver;
        internal const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        internal static readonly FieldInfo Ghost=typeof(Player).GetField("m_placementGhost",Flags);
        internal static readonly FieldInfo PlacementStatus=typeof(Player).GetField("m_placementStatus",Flags);
        internal static readonly FieldInfo Pressed=typeof(Player).GetField("m_placePressedTime",Flags);
        internal static readonly FieldInfo LastUse=typeof(Player).GetField("m_lastToolUseTime",Flags);
        internal static readonly FieldInfo Delay=typeof(Player).GetField("m_placeDelay",Flags);
        internal static readonly MethodInfo UpdateGhost=typeof(Player).GetMethod("UpdatePlacementGhost",Flags);
        internal static readonly MethodInfo UpdatePlacement=typeof(Player).GetMethod("UpdatePlacement",Flags);
        internal static readonly MethodInfo Selected=typeof(Player).GetMethod("GetSelectedPiece",Flags);
        internal static readonly MethodInfo RightItem=typeof(Humanoid).GetMethod("GetRightItem",Flags);
        public static void Configure(Player p)
        {
            if(Ghost==null||PlacementStatus==null||Pressed==null||LastUse==null||Delay==null||UpdateGhost==null||UpdatePlacement==null||Selected==null||RightItem==null)
                throw new MissingMemberException("Drag-build placement metadata unavailable.");
            Generation++;Owner=p;Enabled=1;Status="Hammer: Ctrl + left-drag previews a row; release left click to build. Right click cancels.";
        }
        public static void Disable(){Enabled=0;Owner=null;}
        internal static bool Owns(Player p){return Enabled==1&&p&&p==Owner&&p==Player.m_localPlayer;}
        // True consumes placement input; false runs the unmodified placement method.
        public static bool Tick(Player p,bool input,float dt)
        {
            if(Bypass||!Owns(p))return false;
            try
            {
                if(driver&&(driver.Owner!=p||driver.Generation!=Generation)){driver.Cancel();UnityEngine.Object.Destroy(driver.gameObject);driver=null;}
                if(!driver){driver=new GameObject("SoloToolkit_DragBuild").AddComponent<DragBuildDriverV2>();driver.Owner=p;driver.Generation=Generation;}
                return driver.Step(input,dt);
            }
            catch(Exception e){Status="Drag build stopped: "+e.GetBaseException().Message;if(driver)driver.Cancel();Disable();return true;}
        }
    }
    public sealed class DragBuildDriverV2:MonoBehaviour
    {
        public Player Owner;
        internal int Generation;
        private bool dragging,committing,releaseGuard;
        private Piece selected;
        private Vector3 anchor,step;
        private Quaternion rotation,aimRotation;
        private Vector3 aimPosition;
        private int count=1,index;
        private float nextPlace;
        private readonly List<GameObject> previews=new List<GameObject>();
        private Material previewMaterial;
        private List<Vector3> snapPoints=new List<Vector3>();
        private float spanX,spanZ;
        public void Cancel()
        {
            dragging=false;committing=false;selected=null;
            if(Owner)DragBuildV2.Pressed.SetValue(Owner,-9999f);
            foreach(var p in previews)if(p)Destroy(p);previews.Clear();
            if(previewMaterial)Destroy(previewMaterial);previewMaterial=null;
        }
        private bool Allowed(bool input)
        {
            var item=(ItemDrop.ItemData)DragBuildV2.RightItem.Invoke(Owner,null);
            return input&&Application.isFocused&&Owner.enabled&&!Owner.IsDead()&&!Owner.IsTeleporting()&&Owner.InPlaceMode()
                &&item!=null&&item.m_shared.m_name=="$item_hammer"&&!InventoryGui.IsVisible()&&!Menu.IsVisible()
                &&!Console.IsVisible()&&!Minimap.IsOpen()&&!Hud.IsPieceSelectionVisible()&&!Hud.InRadial()
                &&!(Chat.instance&&Chat.instance.HasFocus());
        }
        private bool Begin()
        {
            DragBuildV2.UpdateGhost.Invoke(Owner,new object[]{false});
            var ghost=DragBuildV2.Ghost.GetValue(Owner) as GameObject;
            selected=DragBuildV2.Selected.Invoke(Owner,null) as Piece;
            if(!ghost||!selected||Convert.ToInt32(DragBuildV2.PlacementStatus.GetValue(Owner))!=0)return false;
            string name=selected.gameObject.name.ToLowerInvariant();
            if(!(name.Contains("floor")||name.Contains("wall")||name.Contains("beam"))||name.Contains("roof")||name.Contains("26")||name.Contains("45"))return false;
            anchor=ghost.transform.position;rotation=ghost.transform.rotation;
            aimPosition=GameCamera.instance.transform.position;aimRotation=GameCamera.instance.transform.rotation;
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
        private void PlaceNext(float dt)
        {
            if(Time.time<nextPlace)return;
            float before=(float)DragBuildV2.LastUse.GetValue(Owner);
            if(Time.time-before<=(float)DragBuildV2.Delay.GetValue(Owner))return;
            nextPlace=Time.time+Mathf.Max(0.15f,(float)DragBuildV2.Delay.GetValue(Owner)+0.02f);
            var camera=GameCamera.instance.transform;var oldPos=camera.position;var oldRot=camera.rotation;
            bool placed=false;
            try
            {
                Vector3 target=anchor+step*index;
                // Temporary ray for the synchronous native validator. Player/eye position
                // stays put, so native reach, ward, support and collision checks still run.
                camera.position=aimPosition+(target-anchor);camera.rotation=aimRotation;
                DragBuildV2.UpdateGhost.Invoke(Owner,new object[]{false});
                var ghost=DragBuildV2.Ghost.GetValue(Owner) as GameObject;
                if(!ghost||!ghost.activeSelf)
                {DragBuildV2.Status="Row stopped at piece "+(index+1)+": no placement surface within build reach.";return;}
                var status=DragBuildV2.PlacementStatus.GetValue(Owner);
                if(Convert.ToInt32(status)!=0)
                {DragBuildV2.Status="Row stopped at piece "+(index+1)+": "+status+".";return;}
                float shift=Vector3.Distance(ghost.transform.position,target);
                if(shift>0.15f||Quaternion.Angle(ghost.transform.rotation,rotation)>1f)
                {DragBuildV2.Status="Row stopped at piece "+(index+1)+": native snap moved "+shift.ToString("0.00")+" m from the preview. Try a clear, level row.";return;}
                DragBuildV2.Pressed.SetValue(Owner,Time.time);
                DragBuildV2.Bypass=true;
                // Re-enter the original method: it owns costs, stamina, durability,
                // placement, cheat flags, effects and build-skill progression.
                DragBuildV2.UpdatePlacement.Invoke(Owner,new object[]{true,dt});
                placed=(float)DragBuildV2.LastUse.GetValue(Owner)>before;
                DragBuildV2.Status=placed?"Built "+(index+1)+"/"+count+" pieces.":"Row stopped: missing materials, station, stamina or usable hammer.";
            }
            finally
            {
                DragBuildV2.Bypass=false;DragBuildV2.Pressed.SetValue(Owner,-9999f);
                camera.position=oldPos;camera.rotation=oldRot;
                if(placed){index++;if(index<count){previews[index-1].SetActive(false);}else Cancel();}
                else Cancel();
                DragBuildV2.UpdateGhost.Invoke(Owner,new object[]{false});
            }
        }
        public bool Step(bool input,float dt)
        {
            bool down=Input.GetMouseButton(0),ctrl=Input.GetKey(KeyCode.LeftControl)||Input.GetKey(KeyCode.RightControl);
            bool busy=dragging||committing;
            if(!Allowed(input)){if(busy){Cancel();releaseGuard=down;DragBuildV2.Status="Row cancelled: controls or tool changed.";}return busy;}
            if(releaseGuard){releaseGuard=down;return true;}
            if(busy&&((Piece)DragBuildV2.Selected.Invoke(Owner,null)!=selected||Input.GetMouseButtonDown(1)||Input.GetKeyDown(KeyCode.Escape)))
            {Cancel();releaseGuard=down;DragBuildV2.Status="Row cancelled. Already placed pieces remain.";return true;}
            if(committing){PlaceNext(dt);return true;}
            if(!dragging)
            {
                if(!ctrl||!Input.GetMouseButtonDown(0))return false;
                releaseGuard=true;
                if(!Begin()){Cancel();DragBuildV2.Status="Choose a valid straight floor, wall or horizontal beam with snap points.";return true;}
                releaseGuard=false;
            }
            if(!ctrl){Cancel();releaseGuard=down;DragBuildV2.Status="Row cancelled: Ctrl released.";return true;}
            if(!down){dragging=false;committing=true;index=0;nextPlace=Time.time;return true;}
            var ray=new Ray(GameCamera.instance.transform.position,GameCamera.instance.transform.forward);
            float distance;
            if(new Plane(Vector3.up,anchor).Raycast(ray,out distance)&&distance<100f)
            {
                Vector3 local=Quaternion.Inverse(rotation)*(ray.GetPoint(distance)-anchor);
                bool x=spanX>=0.5f&&(spanZ<0.5f||Mathf.Abs(local.x)>=Mathf.Abs(local.z));
                float extent=x?spanX:spanZ,value=x?local.x:local.z;
                step=rotation*((x?Vector3.right:Vector3.forward)*extent*(value<0?-1:1));
                count=DragRowPlan.Count(value,extent);ShowPreview((GameObject)DragBuildV2.Ghost.GetValue(Owner));
            }
            DragBuildV2.Pressed.SetValue(Owner,-9999f);
            DragBuildV2.Status="Preview: "+count+" pieces. Release left click (hold Ctrl) to place; right click cancels. Each placement is validated.";
            return true;
        }
        private void Update(){if(!DragBuildV2.Owns(Owner)||Generation!=DragBuildV2.Generation){Cancel();Destroy(gameObject);}}
        private void OnDestroy(){Cancel();}
    }
}
