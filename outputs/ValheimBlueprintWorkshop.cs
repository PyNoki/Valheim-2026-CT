using System;
using System.IO;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
namespace ValheimSoloToolkit
{
    // All Unity/world work runs from the game's placement callback, never the CE thread.
    internal sealed class BlueprintWorkshop
    {
        private Player owner;
        private string name;
        private Vector3 origin,size=new Vector3(20,12,20);
        private float yaw,height,nextScan;
        private bool selecting,previewing,locked,building,undoing,haveAim;
        private int index;
        private readonly List<Piece> selection=new List<Piece>();
        private List<BlueprintEntry> entries=new List<BlueprintEntry>();
        private readonly List<GameObject> meshes=new List<GameObject>();
        private readonly List<Placed> undo=new List<Placed>();
        private Material material;
        private GameObject outline;
        private sealed class Placed {internal Piece Piece;internal ZDO Zdo;internal ZDOID Id;}
        internal static string Folder {get{return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"ValheimSoloToolkit","Blueprints");}}
        internal static string Catalog(){return Directory.Exists(Folder)?String.Join(", ",Array.ConvertAll(Directory.GetFiles(Folder,"*.vbp"),Path.GetFileNameWithoutExtension)):"No saved blueprints yet";}
        private static Vector3 Position(BlueprintEntry e){return new Vector3(e.X,e.Y,e.Z);}
        private static Quaternion Rotation(BlueprintEntry e){return new Quaternion(e.QX,e.QY,e.QZ,e.QW);}
        private void Status(string s){bool changed=DragBuildV4.Status!=s;DragBuildV4.Status=s;if(changed&&owner)owner.Message(MessageHud.MessageType.TopLeft,s);}
        private void ClearPreview()
        {
            foreach(var go in meshes)if(go)UnityEngine.Object.Destroy(go);meshes.Clear();
            if(outline)UnityEngine.Object.Destroy(outline);outline=null;
        }
        internal void Cancel(){selecting=previewing=locked=building=undoing=haveAim=false;ClearPreview();}
        internal void Dispose(){Cancel();undo.Clear();if(material)UnityEngine.Object.Destroy(material);}
        private GameObject Mesh(GameObject source)
        {
            if(!material){var shader=Shader.Find("Sprites/Default");if(!shader)throw new InvalidOperationException("Preview shader unavailable");material=new Material(shader);material.color=new Color(.15f,.9f,1,.3f);}
            var root=new GameObject("Blueprint preview");meshes.Add(root);
            foreach(var mesh in source.GetComponentsInChildren<MeshFilter>(true))
            {
                if(!mesh.sharedMesh)continue;
                var go=new GameObject("Blueprint mesh");go.transform.SetParent(root.transform,false);
                go.transform.localPosition=source.transform.InverseTransformPoint(mesh.transform.position);
                go.transform.localRotation=Quaternion.Inverse(source.transform.rotation)*mesh.transform.rotation;
                go.transform.localScale=mesh.transform.lossyScale;
                go.AddComponent<MeshFilter>().sharedMesh=mesh.sharedMesh;
                var renderer=go.AddComponent<MeshRenderer>();var mats=new Material[mesh.sharedMesh.subMeshCount];
                for(int i=0;i<mats.Length;i++)mats[i]=material;
                renderer.sharedMaterials=mats;renderer.shadowCastingMode=ShadowCastingMode.Off;renderer.receiveShadows=false;
            }
            return root;
        }
        private bool Aim(out Vector3 point,bool snap)
        {
            point=Vector3.zero;
            if(snap)
            {
                DragBuildV4.UpdateGhost.Invoke(owner,new object[]{false});
                var ghost=DragBuildV4.Ghost.GetValue(owner) as GameObject;
                if(ghost&&ghost.activeSelf){point=ghost.transform.position;return true;}
            }
            RaycastHit hit;var camera=GameCamera.instance.transform;
            if(!Physics.Raycast(camera.position,camera.forward,out hit,100f,~(1<<2),QueryTriggerInteraction.Ignore))return false;
            point=hit.point;return true;
        }
        private void Scan()
        {
            selection.Clear();ClearPreview();
            var found=new List<Piece>();Piece.GetAllPiecesInRadius(origin+Vector3.up*size.y*.5f,size.magnitude,found);
            var bounds=new Bounds(origin+Vector3.up*(size.y*.5f-.1f),size+Vector3.up*.2f);
            foreach(var piece in found)
            {
                if(!piece||!piece.IsPlacedByPlayer()||!bounds.Contains(piece.transform.position))continue;
                var view=piece.GetComponent<ZNetView>();
                if(!view||view.GetZDO()==null)continue;
                string prefab=Utils.GetPrefabName(piece.gameObject);
                var template=ZNetScene.instance.GetPrefab(prefab);
                if(!template||!template.GetComponent<Piece>())continue;
                selection.Add(piece);
                if(selection.Count>BlueprintData.Limit)throw new InvalidOperationException("Selection exceeds 512 pieces. Reduce the box dimensions.");
                var mesh=Mesh(piece.gameObject);mesh.transform.position=piece.transform.position;mesh.transform.rotation=piece.transform.rotation;
            }
            if(!material){var shader=Shader.Find("Sprites/Default");material=new Material(shader);material.color=Color.cyan;}
            outline=new GameObject("Blueprint selection bounds");var line=outline.AddComponent<LineRenderer>();line.sharedMaterial=material;line.startWidth=line.endWidth=.06f;line.useWorldSpace=true;
            Vector3 a=bounds.min,b=bounds.max;
            Vector3[] corners={new Vector3(a.x,a.y,a.z),new Vector3(b.x,a.y,a.z),new Vector3(b.x,a.y,b.z),new Vector3(a.x,a.y,b.z),new Vector3(a.x,b.y,a.z),new Vector3(b.x,b.y,a.z),new Vector3(b.x,b.y,b.z),new Vector3(a.x,b.y,b.z)};
            int[] path={0,1,2,3,0,4,5,1,5,6,2,6,7,3,7,4};line.positionCount=path.Length;for(int i=0;i<path.Length;i++)line.SetPosition(i,corners[path[i]]);
            Status("Capture "+name+": "+selection.Count+" pieces highlighted. Aim at foundation level. F6 locks/unlocks box; F7 saves locked selection.");
        }
        private void Save()
        {
            if(!locked||selection.Count==0)throw new InvalidOperationException("Lock a nonempty selection with F6 before saving.");
            var data=new List<BlueprintEntry>();
            foreach(var piece in selection)
            {
                if(!piece)throw new InvalidOperationException("A selected piece disappeared; capture again.");
                Vector3 p=piece.transform.position-origin;Quaternion q=piece.transform.rotation;var sign=piece.GetComponent<Sign>();
                data.Add(new BlueprintEntry{Prefab=Utils.GetPrefabName(piece.gameObject),X=p.x,Y=p.y,Z=p.z,QX=q.x,QY=q.y,QZ=q.z,QW=q.w,Sign=sign?sign.GetText():""});
            }
            data.Sort((a,b)=>a.Y.CompareTo(b.Y));BlueprintData.Validate(data);
            Directory.CreateDirectory(Folder);string path=Path.Combine(Folder,BlueprintData.SafeName(name)+".vbp");
            // Existing names are never silently overwritten.
            using(var stream=new FileStream(path,FileMode.CreateNew,FileAccess.Write))BlueprintData.Write(stream,data);
            Cancel();Status("Saved "+name+" ("+data.Count+" furnished pieces). Use Load blueprint to paste it.");
        }
        private void Load(string value)
        {
            var loaded=new List<BlueprintEntry>();
            using(var stream=File.OpenRead(Path.Combine(Folder,BlueprintData.SafeName(value)+".vbp")))loaded=BlueprintData.Read(stream);
            foreach(var e in loaded){var p=ZNetScene.instance.GetPrefab(e.Prefab);if(!p||!p.GetComponent<Piece>())throw new InvalidOperationException("Missing build prefab: "+e.Prefab);}
            Cancel();name=value;entries=loaded;yaw=height=0;previewing=true;
            foreach(var e in entries){var mesh=Mesh(ZNetScene.instance.GetPrefab(e.Prefab));mesh.SetActive(false);}
            Status("Preview "+name+": aim to position; Q/E rotate 15 degrees; Page Up/Down adjust height; F6 locks; F7 builds locked preview.");
        }
        private void BeginBuild()
        {
            if(!locked||!haveAim)throw new InvalidOperationException("Lock the placement preview with F6 before building.");
            // Preflight every prefab and the combined material bill before touching the world.
            var costs=new Dictionary<string,int>();
            foreach(var e in entries)
            {
                var prefab=ZNetScene.instance.GetPrefab(e.Prefab);if(!prefab)throw new InvalidOperationException("Missing prefab: "+e.Prefab);
                var piece=prefab.GetComponent<Piece>();
                if(owner.NoCostCheat())continue;
                if(!owner.HaveRequirements(piece,Player.RequirementMode.CanBuild))throw new InvalidOperationException("Missing materials/station for "+e.Prefab+". Enable Free Crafting or supply requirements.");
                if(ZoneSystem.instance.GetGlobalKey(piece.FreeBuildKey()))continue;
                foreach(var r in piece.m_resources)if(r.m_resItem&&r.GetAmount(0)>0)
                {string key=r.m_resItem.m_itemData.m_shared.m_name;int n;costs.TryGetValue(key,out n);costs[key]=checked(n+r.GetAmount(0));}
            }
            foreach(var pair in costs)if(owner.GetInventory().CountItems(pair.Key,-1,true)<pair.Value)throw new InvalidOperationException("Whole blueprint needs "+pair.Value+" "+pair.Key+". Nothing placed.");
            undo.Clear();building=true;previewing=false;index=0;Status("Building "+name+"...");
        }
        private void Build()
        {
            for(int batch=0;batch<4&&building;batch++)
            {
                var e=entries[index];var prefab=ZNetScene.instance.GetPrefab(e.Prefab).GetComponent<Piece>();
                var tool=(ItemDrop.ItemData)DragBuildV4.RightItem.Invoke(owner,null);bool free=owner.NoCostCheat();
                if(!free&&(!owner.HaveRequirements(prefab,Player.RequirementMode.CanBuild)||!owner.HaveStamina(tool.m_shared.m_attack.m_attackStamina)||(tool.m_shared.m_useDurability&&tool.m_durability<=0)))
                {Cancel();Status("Blueprint stopped after "+index+" pieces: materials, station, stamina or hammer depleted. Undo can remove placed pieces.");return;}
                Quaternion rot=Quaternion.Euler(0,yaw,0);Vector3 pos=origin+Vector3.up*height+rot*Position(e);
                var before=new List<Piece>();Piece.GetAllPiecesInRadius(pos,.1f,before);
                Piece created=null;
                try{DragBuildV4.Place.Invoke(owner,new object[]{prefab,pos,rot*Rotation(e),false,!PlayerProfile.s_bypassCheatChecks});}
                finally
                {
                    var after=new List<Piece>();Piece.GetAllPiecesInRadius(pos,.1f,after);
                    foreach(var piece in after)if(piece&&!before.Contains(piece)&&Utils.GetPrefabName(piece.gameObject)==e.Prefab)
                    {var view=piece.GetComponent<ZNetView>();if(view&&view.GetZDO()!=null){undo.Add(new Placed{Piece=piece,Zdo=view.GetZDO(),Id=view.GetZDO().m_uid});created=piece;}}
                }
                if(!created)throw new InvalidOperationException("Native piece creation could not be verified; paste stopped.");
                index++;meshes[index-1].SetActive(false);
                if(!free&&!ZoneSystem.instance.GetGlobalKey(prefab.FreeBuildKey()))owner.ConsumeResources(prefab.m_resources,0,-1,1);
                if(!free)
                {owner.UseStamina((float)DragBuildV4.BuildStamina.Invoke(owner,null));if(tool.m_shared.m_useDurability)tool.m_durability=Mathf.Max(0,tool.m_durability-(float)DragBuildV4.BuildDurability.Invoke(owner,new object[]{tool})*Game.m_durabilityRate);}
                var sign=created.GetComponent<Sign>();if(sign&&!String.IsNullOrEmpty(e.Sign))sign.SetText(e.Sign);
                DragBuildV4.LastUse.SetValue(owner,Time.time);
                Status("Built "+index+"/"+entries.Count+" pieces from "+name+". Undo affects only this paste.");
                if(index==entries.Count)Cancel();
            }
        }
        private void Undo()
        {
            for(int n=0;n<8&&undo.Count>0;n++)
            {
                var p=undo[undo.Count-1];
                if(p.Piece)
                {
                    var view=p.Piece.GetComponent<ZNetView>();
                    if(!view||view.GetZDO()!=p.Zdo||view.GetZDO().m_uid!=p.Id)throw new InvalidOperationException("Undo identity changed; refusing to remove that object.");
                    var container=p.Piece.GetComponent<Container>();
                    if(container&&container.GetInventory().GetAllItems().Count>0)throw new InvalidOperationException("Empty the pasted container before undoing it. Retry Undo afterward.");
                    var stand=p.Piece.GetComponent<ItemStand>();
                    if(stand&&stand.HaveAttachment())throw new InvalidOperationException("Remove displayed items from the pasted stand before Undo.");
                    var armor=p.Piece.GetComponent<ArmorStand>();
                    if(armor)for(int slot=0;slot<armor.m_slots.Count;slot++)if(armor.HaveAttachment(slot))throw new InvalidOperationException("Remove equipment from the pasted armor stand before Undo.");
                    view.ClaimOwnership();if(!view.IsOwner())throw new InvalidOperationException("Could not own pasted piece for Undo. Retry afterward.");
                    ZNetScene.instance.Destroy(p.Piece.gameObject);
                }
                else if(ZDOMan.instance.GetZDO(p.Id)!=null)
                    throw new InvalidOperationException("A pasted piece is outside the loaded area. Return to the pasted structure and retry Undo.");
                undo.RemoveAt(undo.Count-1);
            }
            Status("Undo: "+undo.Count+" pasted pieces remaining. Removed pieces do not drop/refund materials.");if(undo.Count==0)undoing=false;
        }
        internal bool Step(Player player,bool allowed)
        {
            owner=player;
            if(!allowed){if(building||undoing){Cancel();Status("Building paused/cancelled: controls or hammer unavailable. Already placed pieces remain; Undo is available.");}return true;}
            try
            {
                var command=DragBuildV4.TakeRequest();
                if(command!=null)
                {
                    if(command.Code==1)
                    {
                        var parts=command.Text.Split('|');if(parts.Length!=4)throw new InvalidDataException("Capture requires name and width, height, depth.");
                        name=BlueprintData.SafeName(parts[0]);float[] values=new float[3];
                        for(int i=0;i<3;i++)if(!Single.TryParse(parts[i+1],System.Globalization.NumberStyles.Float,System.Globalization.CultureInfo.InvariantCulture,out values[i])||Single.IsNaN(values[i])||values[i]<2||values[i]>80)throw new InvalidDataException("Box dimensions must be 2-80 metres.");
                        Cancel();size=new Vector3(values[0],values[1],values[2]);selecting=true;nextScan=0;
                    }
                    else if(command.Code==2)Load(command.Text);
                    else if(command.Code==3){Cancel();Status("Preview cancelled. Saved blueprints and pasted pieces remain.");}
                    else if(command.Code==4){Cancel();undoing=true;}
                }
                if(Input.GetKeyDown(KeyCode.Escape)){Cancel();Status("Blueprint operation cancelled.");return true;}
                if(building){Build();return true;}if(undoing){Undo();return true;}
                if(!selecting&&!previewing)return true;
                if(!locked){Vector3 point;haveAim=Aim(out point,previewing);if(haveAim)origin=point;}
                if(Input.GetKeyDown(KeyCode.F6)&&haveAim){if(selecting&&!locked)Scan();locked=!locked;Status(locked?"Preview locked. F7 saves selection / builds blueprint; F6 unlocks.":"Preview unlocked; aim to reposition.");}
                if(selecting)
                {
                    if(!locked&&haveAim&&Time.time>=nextScan){nextScan=Time.time+.25f;Scan();}
                    if(Input.GetKeyDown(KeyCode.F7))Save();
                }
                else
                {
                    if(Input.GetKeyDown(KeyCode.Q))yaw-=15;if(Input.GetKeyDown(KeyCode.E))yaw+=15;
                    if(Input.GetKeyDown(KeyCode.PageUp))height+=.5f;if(Input.GetKeyDown(KeyCode.PageDown))height-=.5f;
                    Quaternion rot=Quaternion.Euler(0,yaw,0);
                    for(int i=0;i<entries.Count;i++){meshes[i].SetActive(haveAim);meshes[i].transform.position=origin+Vector3.up*height+rot*Position(entries[i]);meshes[i].transform.rotation=rot*Rotation(entries[i]);}
                    if(Input.GetKeyDown(KeyCode.F7))BeginBuild();
                }
            }
            catch(Exception e){Cancel();Status("Blueprint stopped: "+e.GetBaseException().Message+" Existing pieces remain; Undo retains the last paste.");}
            return true;
        }
    }
}
