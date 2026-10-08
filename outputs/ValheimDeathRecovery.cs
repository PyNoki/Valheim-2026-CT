using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    // CE queues requests; all Unity and world operations run in Player.UpdateTeleport.
    public static class DeathRecoveryV2
    {
        static readonly object Gate = new object();
        static Player owner;
        static long world, character;
        static int action, state, index;
        static string status = "Idle", prefab;
        static readonly List<ZDO> stones = new List<ZDO>();
        static Vector3 destination;
        static readonly FieldInfo TombPrefab = typeof(Player).GetField("m_tombstone", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        public static int GetState() { lock (Gate) return state; }
        public static string GetStatus() { lock (Gate) return status; }
        public static void Cancel() { lock (Gate) { state = 0; owner = null; stones.Clear(); } }
        public static void Queue(Player player, int mode, string worldHex)
        {
            lock (Gate)
            {
                if (mode < 1 || mode > 3 || worldHex == null || worldHex.Length != 16) throw new ArgumentException("Invalid recovery request");
                byte[] bytes = new byte[8];
                for (int i = 0; i < 8; ++i) bytes[i] = Convert.ToByte(worldHex.Substring(i * 2, 2), 16);
                world = BitConverter.ToInt64(bytes, 0);
                owner = player; action = mode; character = 0; index = 0; prefab = null; stones.Clear();
                status = "Queued: return to Valheim and unpause."; state = 1;
            }
        }
        static void Finish(string text, bool success) { status = text; state = success ? 3 : 4; stones.Clear(); owner = null; }
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
            // The server has the full world database and authority over unloaded objects.
            if (!ZNet.instance.IsServer()) throw new InvalidOperationException("Bring tombstone requires a solo world or being the host. Use Teleport to tombstone or Last death on a remote server.");
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
