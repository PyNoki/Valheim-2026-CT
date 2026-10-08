using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class WorldToolsV1
    {
        public static int Enabled;
        public static string LastError, Status = "Ready. Return to the game to run queued actions.";
        private static Player owner;
        internal static int Generation;
        internal static WorldToolsDriverV1 Driver;
        private static readonly Queue<float[]> commands = new Queue<float[]>();
        internal const BindingFlags Flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
        internal static FieldInfo Field(string name) { var field=typeof(Player).GetField(name, Flags); if(field==null) throw new MissingFieldException(name); return field; }
        internal static readonly FieldInfo Ghost = Field("m_placementGhost"), Rotation = Field("m_placeRotation"), Degrees = Field("m_placeRotationDegrees"), Distance = Field("m_maxPlaceDistance");
        internal static readonly MethodInfo Right = typeof(Humanoid).GetMethod("GetRightItem", Flags);
        internal static readonly MethodInfo TakeInput = typeof(Player).GetMethod("TakeInput", Flags);
        internal static readonly MethodInfo Selected = typeof(Player).GetMethod("GetSelectedPiece", Flags);
        internal static readonly MethodInfo TryPlace = typeof(Player).GetMethod("TryPlacePiece", Flags);
        internal static readonly MethodInfo Consume = typeof(Player).GetMethod("ConsumeResources", Flags);
        internal static readonly MethodInfo BuildStamina = typeof(Player).GetMethod("GetBuildStamina", Flags);
        internal static readonly MethodInfo Durability = typeof(Player).GetMethod("GetPlaceDurability", Flags);
        internal static readonly MethodInfo Requirements = FindRequirements();
        private static MethodInfo FindRequirements()
        {
            foreach (var m in typeof(Player).GetMethods(Flags))
                if (m.Name == "HaveRequirements" && m.GetParameters().Length == 2 && m.GetParameters()[0].ParameterType == typeof(Piece)) return m;
            throw new MissingMethodException("Player.HaveRequirements(Piece, RequirementMode)");
        }
        public static void Configure(Player player) { lock(commands) commands.Clear(); Generation++; owner=player; Enabled=1; LastError=null; Status="Ready. Return to the game to run queued actions."; }
        public static void Disable() { Enabled=0; owner=null; lock(commands) commands.Clear(); }
        internal static bool Owns(Player p) { return Enabled==1 && p && p==owner && p==Player.m_localPlayer; }
        public static void Command(int action, float a, float b, float c)
        {
            if (Enabled!=1) throw new InvalidOperationException("Open World tools first.");
            if (float.IsNaN(a)||float.IsNaN(b)||float.IsNaN(c)||float.IsInfinity(a)||float.IsInfinity(b)||float.IsInfinity(c)) throw new ArgumentException("Use finite numbers.");
            lock(commands) { if(commands.Count>=16) throw new InvalidOperationException("Too many queued actions."); commands.Enqueue(new float[]{action,a,b,c}); }
            Status="Action queued. Return to Valheim and unpause.";
        }
        public static void Tick(Player player)
        {
            if (!Owns(player)) return;
            try
            {
                if (Driver && (Driver.Owner!=player || Driver.Generation!=Generation)) { Driver.Cleanup(); UnityEngine.Object.Destroy(Driver.gameObject); Driver=null; }
                if (!Driver) { Driver=new GameObject("SoloToolkit_WorldTools").AddComponent<WorldToolsDriverV1>(); Driver.Owner=player; Driver.Generation=Generation; }
                float[] cmd=null; lock(commands) { if(commands.Count>0) cmd=commands.Dequeue(); }
                if(cmd!=null) Driver.Execute((int)cmd[0],cmd[1],cmd[2],cmd[3]);
                Driver.Step();
            }
            catch(Exception e) { LastError=e.GetBaseException().Message; Status="Stopped: "+LastError; if(Driver) Driver.CancelFarm(); }
        }
        // Post-process a successful vanilla ray BEFORE vanilla placement validation.
        public static bool AdjustRay(Player player, ref Vector3 point, ref Vector3 normal, ref Piece piece, ref Heightmap heightmap, ref Collider waterSurface, bool water)
        {
            if(!Owns(player)||!Driver||Driver.Generation!=Generation) return true;
            try { return Driver.AdjustRay(ref point,ref normal,ref piece,ref heightmap,ref waterSurface); }
            catch(Exception e) { LastError=e.Message; Status="Placement stopped: "+e.Message; return false; }
        }
    }

    public sealed class WorldToolsDriverV1 : MonoBehaviour
    {
        public Player Owner;
        internal int Generation;
        private readonly List<GameObject> raid=new List<GameObject>();
        private readonly List<GameObject> markers=new List<GameObject>();
        private readonly List<Vector3> grid=new List<Vector3>();
        private static readonly string[] enemies={"Greydwarf","Skeleton","Draugr"};
        private Vector3 offset;
        private bool precision, rotationSaved, planting;
        private float originalDegrees, yaw, nextPlant;
        private int originalRotation, gridIndex, planted, skipped;
        private Piece crop;
        private ItemDrop.ItemData farmTool;
        private Vector3? farmTarget;
        private ItemDrop.ItemData Tool() { return (ItemDrop.ItemData)WorldToolsV1.Right.Invoke(Owner,null); }
        private bool IsTool(string name) { var t=Tool(); return t!=null && t.m_shared.m_name==name; }
        private bool CanInput() { return !Owner.IsDead() && (bool)WorldToolsV1.TakeInput.Invoke(Owner,null) && !Hud.IsPieceSelectionVisible() && !Hud.InRadial(); }
        private void Require(bool condition,string message) { if(!condition) throw new InvalidOperationException(message); }
        public void Execute(int action,float a,float b,float c)
        {
            switch(action)
            {
                case 1: StartRaid((int)a,(int)b,(int)c); break;
                case 2: EndRaid(); WorldToolsV1.Status="Pocket raid ended. Surviving spawned enemies removed."; break;
                case 3:
                    Require(Math.Abs(a)<=3 && Math.Abs(b)<=3 && Math.Abs(c)<=3,"Position offsets must be within -3 to +3 metres.");
                    if(!precision) yaw=((float)WorldToolsV1.Degrees.GetValue(Owner)*(int)WorldToolsV1.Rotation.GetValue(Owner))%360;
                    offset=new Vector3(a,b,c); precision=true; WorldToolsV1.Status="Position offsets enabled (world X/Y/Z). Equip hammer; hold AltPlace to avoid snapping."; break;
                case 4: Require(a>=0 && a<360,"Rotation must be 0 to 359 degrees."); yaw=a; precision=true; WorldToolsV1.Status="Exact rotation enabled. Equip hammer to preview."; break;
                case 5: PreviewGrid((int)a,b); break;
                case 6:
                    Require(grid.Count>0 && crop,"Preview a crop grid first.");
                    Require(IsTool("$item_cultivator") && Tool()==farmTool,"Re-equip the same cultivator and preview again.");
                    planting=true;gridIndex=planted=skipped=0;WorldToolsV1.Status="Planting queued. Return to game, aim at ground and keep the selected crop.";break;
                case 7: Harvest(a);break;
                case 8: precision=false;offset=Vector3.zero;RestoreRotation();WorldToolsV1.Status="Building precision reset.";break;
                case 9: CancelFarm();WorldToolsV1.Status="Farm preview and queued planting cancelled.";break;
                default: throw new ArgumentException("Unknown world-tool action.");
            }
        }
        public void Step()
        {
            if(!WorldToolsV1.Owns(Owner)||Generation!=WorldToolsV1.Generation) { Cleanup(); return; }
            if(precision && !Owner.IsDead() && IsTool("$item_hammer"))
            {
                if(!rotationSaved) { originalDegrees=(float)WorldToolsV1.Degrees.GetValue(Owner);originalRotation=(int)WorldToolsV1.Rotation.GetValue(Owner);rotationSaved=true; }
                WorldToolsV1.Degrees.SetValue(Owner,1f);WorldToolsV1.Rotation.SetValue(Owner,(int)yaw);
            }
            else RestoreRotation();
            if(planting && Time.time>=nextPlant)
            {
                if(!CanInput()) { WorldToolsV1.Status="Planting paused. Return to game; close menus to continue.";return; }
                if(!IsTool("$item_cultivator") || Tool()!=farmTool || (Piece)WorldToolsV1.Selected.Invoke(Owner,null)!=crop)
                { CancelFarm();WorldToolsV1.Status="Planting cancelled: tool or selected crop changed.";return; }
                nextPlant=Time.time+0.15f;PlantNext();
            }
            raid.RemoveAll(x=>!x);
        }
        private void RestoreRotation()
        {
            if(rotationSaved && Owner) { WorldToolsV1.Degrees.SetValue(Owner,originalDegrees);WorldToolsV1.Rotation.SetValue(Owner,originalRotation); }
            rotationSaved=false;
        }
        public bool AdjustRay(ref Vector3 point,ref Vector3 normal,ref Piece piece,ref Heightmap heightmap,ref Collider water)
        {
            Vector3 desired;
            if(farmTarget.HasValue)
            {
                RaycastHit hit;
                if(!Ground(farmTarget.Value,out hit)) return false;
                desired=hit.point;normal=hit.normal;piece=null;heightmap=hit.collider.GetComponent<Heightmap>();water=null;
            }
            else if(precision && IsTool("$item_hammer")) desired=point+offset;
            else return true;
            var ghost=(GameObject)WorldToolsV1.Ghost.GetValue(Owner);
            var selected=ghost ? ghost.GetComponent<Piece>() : null;
            float range=(float)WorldToolsV1.Distance.GetValue(Owner)+(selected ? selected.m_extraPlacementDistance : 0);
            if(Vector3.Distance(Owner.GetEyePoint(),desired)>=range) return false;
            point=desired;return true;
        }
        private bool Ground(Vector3 position,out RaycastHit hit)
        {
            return Physics.Raycast(position+Vector3.up*5f,Vector3.down,out hit,15f,LayerMask.GetMask("terrain"),QueryTriggerInteraction.Ignore);
        }
        private void StartRaid(int enemy,int count,int stars)
        {
            Require(enemy>=0 && enemy<enemies.Length && count>=1 && count<=20 && stars>=0 && stars<=2,"Raid: enemy 1-3, count 1-20, stars 0-2.");
            Require(!Owner.IsDead(),"Load a living player first.");
            Require(raid.Count==0,"End the existing raid before starting another.");
            var prefab=ZNetScene.instance.GetPrefab(enemies[enemy]);
            Require(prefab && prefab.GetComponent<MonsterAI>(),"Enemy prefab unavailable in this game build.");
            var positions=new List<Vector3>();
            for(int i=0;i<count;i++)
            {
                float angle=i*Mathf.PI*2/count;
                Vector3 target=Owner.transform.position+new Vector3(Mathf.Cos(angle)*14,0,Mathf.Sin(angle)*14);
                RaycastHit hit;Require(Ground(target,out hit),"No nearby ground for the full raid. Move to open terrain.");
                Require(hit.normal.y>0.65f && hit.point.y>ZoneSystem.instance.m_waterLevel,"Raid needs dry, reasonably flat ground.");
                Require(!Physics.CheckSphere(hit.point+Vector3.up,0.6f,LayerMask.GetMask("piece","Default","static_solid"),QueryTriggerInteraction.Ignore),"Raid spawn area is obstructed. Move into the open.");
                positions.Add(hit.point+Vector3.up*0.2f);
            }
            try
            {
                foreach(var p in positions)
                {
                    var spawned=UnityEngine.Object.Instantiate(prefab,p,Quaternion.identity);raid.Add(spawned);
                    spawned.GetComponent<Character>().SetLevel(stars+1);
                    var ai=spawned.GetComponent<MonsterAI>();typeof(MonsterAI).GetMethod("SetTarget",WorldToolsV1.Flags).Invoke(ai,new object[]{Owner});
                    typeof(BaseAI).GetMethod("SetAlerted",WorldToolsV1.Flags).Invoke(ai,new object[]{true});
                }
            }
            catch { EndRaid();throw; }
            WorldToolsV1.Status="Pocket raid started: "+count+" "+enemies[enemy]+", "+stars+" stars. Enemies can damage you and buildings.";
        }
        private void EndRaid()
        {
            foreach(var obj in raid) if(obj && ZNetScene.instance) ZNetScene.instance.Destroy(obj);
            raid.Clear();
        }
        private void PreviewGrid(int side,float spacing)
        {
            Require(!planting,"Cancel the active planting job first.");
            Require(side>=1 && side<=7 && spacing>=1 && spacing<=5,"Grid: 1-7 rows/columns, spacing 1-5 metres.");
            Require(IsTool("$item_cultivator"),"Equip a cultivator and select a crop first.");
            var selected=(Piece)WorldToolsV1.Selected.Invoke(Owner,null);
            var plant=selected ? selected.GetComponent<Plant>() : null;
            Require(plant && Array.Exists(plant.m_grownPrefabs,p=>p && p.GetComponent<Pickable>()),"Select a harvestable crop, not cultivate/grass or a tree.");
            var ghost=(GameObject)WorldToolsV1.Ghost.GetValue(Owner);Require(ghost && ghost.activeSelf,"Aim the crop preview at ground first, then open World tools.");
            CancelFarm();crop=selected;farmTool=Tool();
            Vector3 center=ghost.transform.position;
            Vector3 right=Owner.transform.right;right.y=0;right.Normalize();Vector3 forward=Vector3.Cross(right,Vector3.up);
            for(int z=0;z<side;z++) for(int x=0;x<side;x++)
            {
                Vector3 target=center+right*((x-(side-1)*0.5f)*spacing)+forward*((z-(side-1)*0.5f)*spacing);
                RaycastHit hit;if(!Ground(target,out hit)) continue;
                grid.Add(hit.point);
                var marker=GameObject.CreatePrimitive(PrimitiveType.Sphere);
                marker.name="Farm preview (local)";marker.transform.position=hit.point+Vector3.up*0.12f;marker.transform.localScale=Vector3.one*0.18f;
                var collider=marker.GetComponent<Collider>();collider.enabled=false;UnityEngine.Object.Destroy(collider);
                markers.Add(marker);
            }
            Require(grid.Count>0,"No ground beneath the crop grid.");
            WorldToolsV1.Status="Preview: "+grid.Count+" crop positions. Plant grid uses seeds/stamina and skips invalid or out-of-reach spots. Crop spacing is your choice.";
        }
        private void PlantNext()
        {
            if(gridIndex>=grid.Count) { FinishFarm();return; }
            var mode=Enum.ToObject(WorldToolsV1.Requirements.GetParameters()[1].ParameterType,0);
            bool free=Owner.NoCostCheat();
            if(!free && !(bool)WorldToolsV1.Requirements.Invoke(Owner,new object[]{crop,mode}))
            { planting=false;WorldToolsV1.Status="Planting stopped: missing seeds/materials or crafting requirements. Planted "+planted+".";return; }
            float stamina=(float)WorldToolsV1.BuildStamina.Invoke(Owner,null);
            if(!Owner.HaveStamina(stamina) || (farmTool.m_shared.m_useDurability && farmTool.m_durability<=0))
            { planting=false;WorldToolsV1.Status="Planting stopped: insufficient stamina or broken cultivator. Planted "+planted+".";return; }
            farmTarget=grid[gridIndex++];
            try
            {
                if((bool)WorldToolsV1.TryPlace.Invoke(Owner,new object[]{crop}))
                {
                    if(!free) WorldToolsV1.Consume.Invoke(Owner,new object[]{crop.m_resources,0,-1,1});
                    Owner.UseStamina(stamina);
                    if(farmTool.m_shared.m_useDurability) farmTool.m_durability=Math.Max(0,farmTool.m_durability-(float)WorldToolsV1.Durability.Invoke(Owner,new object[]{farmTool}));
                    planted++;
                }
                else skipped++;
            }
            finally { farmTarget=null; }
            WorldToolsV1.Status="Planting: "+planted+" placed, "+skipped+" skipped, "+(grid.Count-gridIndex)+" remaining.";
            if(gridIndex>=grid.Count) FinishFarm();
        }
        private void FinishFarm() { string result="Grid finished: "+planted+" planted, "+skipped+" skipped.";CancelFarm();WorldToolsV1.Status=result; }
        private void Harvest(float radius)
        {
            Require(radius>=1 && radius<=10,"Harvest radius must be 1-10 metres.");
            Require(!Owner.IsDead(),"Load a living player first.");
            var cropNames=new HashSet<string>();
            foreach(var prefab in ZNetScene.instance.m_prefabs)
            {
                var plant=prefab ? prefab.GetComponent<Plant>() : null;
                if(plant) foreach(var grown in plant.m_grownPrefabs) if(grown && grown.GetComponent<Pickable>()) cropNames.Add(grown.name);
            }
            int count=0;
            foreach(var pickable in UnityEngine.Object.FindObjectsByType<Pickable>(FindObjectsSortMode.None))
            {
                if(count>=100) break;
                if(!cropNames.Contains(pickable.gameObject.name.Replace("(Clone)","").Trim())) continue;
                if(Vector3.Distance(Owner.transform.position,pickable.transform.position)>radius || !pickable.CanBePicked()) continue;
                if(!PrivateArea.CheckAccess(pickable.transform.position,0,false,false)) continue;
                if(pickable.Interact(Owner,false,false)) count++;
            }
            WorldToolsV1.Status="Harvested "+count+" mature crops. Normal harvest drops appear in the world.";
        }
        public void CancelFarm()
        {
            planting=false;farmTarget=null;grid.Clear();crop=null;farmTool=null;
            foreach(var marker in markers) if(marker) UnityEngine.Object.Destroy(marker);
            markers.Clear();
        }
        public void Cleanup() { precision=false;RestoreRotation();CancelFarm();EndRaid(); }
        private void Update() { if(!WorldToolsV1.Owns(Owner)||Generation!=WorldToolsV1.Generation) { Cleanup();Destroy(gameObject); } }
        private void OnDestroy() { Cleanup(); }
    }
}
