using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    // CE queues requests; all Unity and world operations run in Player.UpdateTeleport.
    public static class RecoverySpawnBetaV23
    {
        static readonly object Gate = new object();
        static Player owner;
        static long world, character;
        static int action, state, index;
        static string status = "Idle", prefab;
        static string summonTarget;
        static string animalTarget;
        static string spawnTarget;static int spawnKind;static int lootRadius;
        static ItemDrop.ItemData qualityItem;static int chosenQuality;
        static readonly FieldInfo UserKey = typeof(ZDOID).GetField("<UserKey>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic);
        static readonly List<ZDO> stones = new List<ZDO>();
        static Vector3 destination;
        static readonly FieldInfo TombPrefab = typeof(Player).GetField("m_tombstone", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        public static int GetState() { lock (Gate) return state; }
        public static string GetStatus() { lock (Gate) return status; }
        public static void Cancel() { lock (Gate) { state = 0; owner = null; qualityItem=null; stones.Clear(); } }
        public static void StopBoat() { BoatFunV4.Stop(); }
        public static string BoatStatus() { return BoatFunV4.Status; }
        public static string TamingCatalogue(){return TamingV1.Catalogue();}
        public static string TamingStatus(){return TamingV1.Status();}
        public static void StopTaming(){TamingV1.Stop();}
        public static int ClearState(){return ClearViewV1.Enabled;}
        public static void StopClear(){ClearViewV1.Stop();}
        public static string HarvestStatus(){return HarvestLootV1.HarvestStatus;}
        public static string MagnetStatus(){return HarvestLootV1.MagnetStatus;}
        public static int LootState(){return HarvestLootV1.State();}
        public static void StopLoot(){HarvestLootV1.StopAll();}
        public static void StopHarvest(){HarvestLootV1.StopHarvest();}
        public static void StopMagnet(){HarvestLootV1.StopMagnet();}
        public static void QueueLoot(Player player,int mode,int radius,string worldHex){lock(Gate){if(state==1||state==2)throw new InvalidOperationException("Another action is pending.");if(mode<36||mode>38||radius<5||radius>500)throw new ArgumentException("Invalid loot action or radius.");Queue(player,mode,worldHex);lootRadius=radius;}}
        public static string PlantCatalogue(){return AutoPlanterV1.Catalogue();}
        public static string PlantStatus(){return AutoPlanterV1.Status;}
        public static void StopPlant(){AutoPlanterV1.Stop();}
        public static void QueuePlant(Player player,string name,string worldHex){lock(Gate){if(state==1||state==2)throw new InvalidOperationException("Another action is pending.");Queue(player,35,worldHex);spawnTarget=name;}}
        public static string SpawnCatalogue(){return SpawnCatalogueV1.Catalogue();}
        public static void QueuePrefab(Player player,string name,int kind,string worldHex){lock(Gate){if(state==1||state==2)throw new InvalidOperationException("Another action is pending.");if(kind<0||kind>3)throw new ArgumentException("Invalid spawn category.");Queue(player,33,worldHex);spawnTarget=name;spawnKind=kind;}}
        public static void QueueItemQuality(Player player,ItemDrop.ItemData item,int quality,string worldHex){lock(Gate){if(state==1||state==2)throw new InvalidOperationException("Another action is pending.");if(quality<1||quality>1000)throw new ArgumentException("Choose quality 1-1000.");Queue(player,34,worldHex);qualityItem=item;chosenQuality=quality;}}
        public static void QueueAnimal(Player player,string target,string worldHex){lock(Gate){if(state==1||state==2)throw new InvalidOperationException("Another action is pending.");Queue(player,28,worldHex);animalTarget=target;}}
        public static Inventory PrepareTransfer(Inventory target, Inventory source, ItemDrop.ItemData item) { return ReplenishV1.Prepare(target, source, item); }
        public static ItemDrop.ItemData PreparedCopy() { return ReplenishV1.Copy(); }
        public static int DropReplenished(Humanoid actor, Inventory source, ItemDrop.ItemData item, int amount) { return ReplenishV1.Drop(actor, source, item, amount); }
        public static void Queue(Player player, int mode, string worldHex)
        {
            lock (Gate)
            {
                if (mode < 1 || mode > 39 || mode == 5 || worldHex == null || worldHex.Length != 16) throw new ArgumentException("Invalid toolkit request");
                byte[] bytes = new byte[8];
                for (int i = 0; i < 8; ++i) bytes[i] = Convert.ToByte(worldHex.Substring(i * 2, 2), 16);
                world = BitConverter.ToInt64(bytes, 0);
                owner = player; action = mode; character = 0; index = 0; prefab = null; stones.Clear();
                status = "Queued: return to Valheim and unpause."; state = 1;
            }
        }
        public static void QueueSummon(Player player, string targetHex, string worldHex)
        {
            lock (Gate)
            {
                if (state == 1 || state == 2) throw new InvalidOperationException("Another request is pending.");
                if (targetHex == null || targetHex.Length != 12) throw new ArgumentException("Invalid player identity.");
                for (int i = 0; i < 12; i += 2) Convert.ToByte(targetHex.Substring(i, 2), 16);
                Queue(player, 1, worldHex);
                summonTarget = targetHex; action = 5;
            }
        }
        static string Identity(ZDOID id)
        {
            if (UserKey == null) throw new MissingFieldException("Player network identity layout changed.");
            return BitConverter.ToString(BitConverter.GetBytes((ushort)UserKey.GetValue(id))).Replace("-", "")
                + BitConverter.ToString(BitConverter.GetBytes(id.ID)).Replace("-", "");
        }
        static void Summon(Player admin)
        {
            if (ZRoutedRpc.instance == null) throw new InvalidOperationException("Network routing is not ready.");
            foreach (var info in ZNet.instance.GetPlayerList())
            {
                if (!string.Equals(Identity(info.m_characterID), summonTarget, StringComparison.OrdinalIgnoreCase)) continue;
                if (info.m_characterID == ZNet.instance.LocalPlayerCharacterID) throw new InvalidOperationException("Select another player.");
                Vector3 point = Landing(admin);
                ZDO zdo = ZDOMan.instance.GetZDO(info.m_characterID);
                // A distant character's ZDO may not be replicated locally. Its creator
                // is the player client; use current ownership when the ZDO is available.
                long recipient = zdo != null ? zdo.GetOwner() : info.m_characterID.UserID;
                if (recipient == 0) throw new InvalidOperationException("Target player has no network owner. Refresh players and retry.");
                ZRoutedRpc.instance.InvokeRoutedRPC(recipient, info.m_characterID, "RPC_TeleportTo", point, admin.transform.rotation, true);
                Finish("Summon request sent to " + info.m_name + ". Ask them to confirm arrival; teleport cooldown/loading can delay or decline it.", true);
                return;
            }
            throw new InvalidOperationException("Selected player disconnected or changed character. Refresh players.");
        }
        static void Finish(string text, bool success) { status = text; state = success ? 3 : 4; stones.Clear(); owner = null;qualityItem=null; }
        static bool Valid(Vector3 p) { return !float.IsNaN(p.x) && !float.IsNaN(p.y) && !float.IsNaN(p.z) && Math.Abs(p.x) <= 20000 && Math.Abs(p.y) <= 10000 && Math.Abs(p.z) <= 20000; }
        static void Teleport(Player p, Vector3 point)
        {
            if (!Valid(point)) throw new InvalidOperationException("Destination is outside supported world coordinates.");
            destination = point;
            if (!p.TeleportTo(point, p.transform.rotation, true)) throw new InvalidOperationException("Game declined teleport. Wait a few seconds and retry.");
            state = 2; status = "Teleporting: loading destination terrain...";
        }
        public static void Tick(Player p)
        {
            lock (Gate)
            {
                if (state != 1 && state != 2) return;
                try
                {
                    if (!ReferenceEquals(p, owner))
                        throw new InvalidOperationException("Player reference changed after queuing. Finish respawning, then click recovery again.");
                    if (!p || p != Player.m_localPlayer)
                        throw new InvalidOperationException("Local player is unavailable. Finish respawning, then click recovery again.");
                    if (!ZNet.instance || ZNet.instance.GetWorldUID() != world)
                        throw new InvalidOperationException("World changed after queuing; recovery cancelled.");
                    if (p.IsDead())
                        throw new InvalidOperationException("Player died or is still respawning. Wait until you can move, then click recovery again.");
                    if (state == 2)
                    {
                        if (!p.IsTeleporting()) Finish(Utils.DistanceXZ(p.transform.position, destination) < 10 ? "Arrived at recovery destination." : "Teleport ended; arrival could not be confirmed.", true);
                        return;
                    }
                    if (p.IsTeleporting()) throw new InvalidOperationException("Finish the current teleport first.");
                    if (action == 5) { Summon(p); return; }
                    if (action == 6) { BoatFunV4.Toggle(p); Finish(BoatFunV4.Status, true); return; }
                    if(action==27){TamingV1.Refresh(p);Finish("Taming scan started. Results appear in the Taming window.",true);return;}
                    if(action==28){Finish(TamingV1.Bring(p,animalTarget,Landing(p)),true);return;}
                    if(action==29){Finish(TamingV1.TameAimed(p),true);return;}
                    if(action==30){TamingV1.Stop();Finish("Taming map markers hidden.",true);return;}
                    if(action==31){Finish(TamingV1.EnableHotkey(p),true);return;}
                    if(action==32){Finish(SpawnCatalogueV1.Refresh(),true);return;}
                    if(action==33){Finish(SpawnCatalogueV1.Spawn(p,spawnTarget,spawnKind,spawnKind==2?p.transform.position:Landing(p)),true);return;}
                    if(action==39){Finish(ClearViewV1.Toggle(p),true);return;}
                    if(action>=36&&action<=38){Finish(HarvestLootV1.Configure(p,action,lootRadius),true);return;}
                    if(action==35){Finish(AutoPlanterV1.Start(p,spawnTarget),true);return;}
                    if(action==34){try{Finish(ItemQualityV1.Set(p,qualityItem,chosenQuality),true);}finally{qualityItem=null;}return;}
                    if (action >= 10 && action <= 19) { Finish(TrophyBuffsV1.Apply(p,action-10),true);return; }
                    if (action >= 7 && action <= 9)
                    {
                        string merchant=new[]{"Haldor","Hildir","BogWitch"}[action-7];
                        if (!ZNetScene.instance) throw new InvalidOperationException("World prefabs are not ready.");
                        var template=ZNetScene.instance.GetPrefab(merchant);
                        if (!template || !template.GetComponent<ZNetView>()) throw new InvalidOperationException("Registered merchant prefab unavailable: "+merchant);
                        var placed=UnityEngine.Object.Instantiate(template,Landing(p),p.transform.rotation);
                        if(!placed)throw new InvalidOperationException("Game did not create the merchant.");
                        Finish("Spawned "+merchant+" beside you. Normal shop and world-progression requirements apply.",true);return;
                    }
                    if (action == 4 || action >= 20 && action <= 26)
                    {
                        if (!ZNetScene.instance) throw new InvalidOperationException("World prefabs are not ready.");
                        string[] plants={"BlueberryBush","RaspberryBush","CloudberryBush","LingonberryBush","VineAsh","VineGreen","Bush01","Bush01_deepnorth"};
                        int choice=action==4?0:action-19;
                        string plant=plants[choice];
                        GameObject bush = ZNetScene.instance.GetPrefab(plant);
                        if (!bush || choice<=5 && !bush.GetComponent<Pickable>() || !bush.GetComponent<ZNetView>())
                            throw new InvalidOperationException("Registered plant prefab unavailable or incompatible: "+plant);
                        Vector3 point = p.transform.position;
                        if (!Valid(point)) throw new InvalidOperationException("Player position is invalid.");
                        GameObject placed = UnityEngine.Object.Instantiate(bush, point, Quaternion.identity);
                        if (!placed) throw new InvalidOperationException("Game did not create the plant.");
                        Finish("Spawned "+plant+" at your feet."+(choice==4||choice==5?" Vines need suitable support.":""), true);
                        return;
                    }
                    PlayerProfile profile = Game.instance.GetPlayerProfile();
                    if (action == 1)
                    {
                        if (!profile.HaveDeathPoint()) throw new InvalidOperationException("No death location recorded for this character in this world.");
                        Teleport(p, profile.GetDeathPoint() + Vector3.up); return;
                    }
                    if (prefab == null)
                    {
                        character = profile.GetPlayerID();
                        GameObject template = TombPrefab == null ? null : TombPrefab.GetValue(p) as GameObject;
                        if (!template || character == 0) throw new InvalidOperationException("Cannot identify your tombstone prefab or character.");
                        prefab = template.name;
                    }
                    if (profile.GetPlayerID() != character) throw new InvalidOperationException("Character changed; recovery cancelled.");
                    status = "Searching for your latest tombstone...";
                    if (!ZDOMan.instance.GetAllZDOsWithPrefabIterative(prefab, stones, ref index)) return;
                    ZDO latest = null; long newest = long.MinValue;
                    foreach (ZDO stone in stones)
                    {
                        if (stone.GetLong(ZDOVars.s_owner, 0) != character) continue;
                        long time = stone.GetLong(ZDOVars.s_timeOfDeath, 0);
                        if (latest == null || time > newest) { latest = stone; newest = time; }
                    }
                    if (latest == null) throw new InvalidOperationException(ZNet.instance.IsServer() ? "No remaining tombstone found for your character." : "No known tombstone found. Remote clients may not have distant tombstone data; try Last death.");
                    if (!ReferenceEquals(ZDOMan.instance.GetZDO(latest.m_uid), latest) || latest.GetLong(ZDOVars.s_owner, 0) != character)
                        throw new InvalidOperationException("Tombstone changed during search. Retry.");
                    if (action == 2) { Teleport(p, latest.GetPosition() + Vector3.up + Vector3.right * 2); return; }
                    Bring(p, latest);
                    Finish("Your latest tombstone is beside you, with its inventory preserved. Last death still points to the original location.", true);
                }
                catch (Exception ex) { Finish("Recovery stopped: " + ex.Message, false); }
            }
        }
        static Vector3 Landing(Player p)
        {
            int mask = LayerMask.GetMask("terrain", "piece", "Default", "static_solid", "Default_small");
            for (int i = 0; i < 8; ++i)
            {
                Vector3 offset = Quaternion.Euler(0, i * 45, 0) * p.transform.forward * 3;
                RaycastHit hit;
                if (!Physics.Raycast(p.transform.position + offset + Vector3.up * 2, Vector3.down, out hit, 6, mask, QueryTriggerInteraction.Ignore) || hit.normal.y < 0.7f) continue;
                Vector3 point = hit.point + Vector3.up * 0.6f;
                if (!Physics.CheckSphere(point + Vector3.up * 0.4f, 0.5f, mask, QueryTriggerInteraction.Ignore) && Valid(point)) return point;
            }
            throw new InvalidOperationException("No clear landing spot nearby. Stand on open, solid ground and retry.");
        }
        static void Bring(Player p, ZDO stone)
        {
            GameObject instance = ZNetScene.instance.FindInstance(stone.m_uid);
            Container container = instance ? instance.GetComponent<Container>() : null;
            if (container && container.IsInUse()) throw new InvalidOperationException("Tombstone is currently open. Close it and retry.");
            Vector3 point = Landing(p);
            stone.SetOwner(ZDOMan.GetSessionID());
            // PositionCheck uses spawnPoint and otherwise snaps the stone back after moving.
            stone.Set(ZDOVars.s_spawnPoint, point);
            stone.SetPosition(point);
            // Ownership handoff and later loading restore these networked velocities.
            stone.Set(ZDOVars.s_bodyVelHash, Vector3.zero);
            stone.Set(ZDOVars.s_bodyAVelHash, Vector3.zero);
            stone.Set(ZDOVars.s_velHash, Vector3.zero);
            if (instance)
            {
                instance.transform.position = point;
                Rigidbody body = instance.GetComponent<Rigidbody>();
                if (body) { body.position = point; body.linearVelocity = Vector3.zero; body.angularVelocity = Vector3.zero; }
                ZSyncTransform sync = instance.GetComponent<ZSyncTransform>();
                if (sync) sync.SyncNow();
            }
        }
    }
}
