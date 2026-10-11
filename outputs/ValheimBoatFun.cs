using System;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class BoatFunV4
    {
        internal static bool Enabled;
        internal static int Generation;
        internal static BoatFunDriverV4 Driver;
        public static string Status = "Pixie boat: OFF";
        public static void Stop() { Enabled = false; Generation++; }
        public static void Toggle(Player p)
        {
            if (Enabled) { Stop(); Status = "Pixie boat: OFF; restoring boat physics."; return; }
            if (Driver) { Status = "Pixie boat: wait one game frame for restoration, then enable again."; return; }
            var driver = new GameObject("AdminToolkit_PixieBoat").AddComponent<BoatFunDriverV4>();
            Driver = driver;
            driver.Owner = p; driver.World = ZNet.instance.GetWorldUID();
            driver.Generation = ++Generation;
            Enabled = true; Status = "Pixie boat: ON. Take the helm; W/S throttle, A/D steer, Tap Left Ctrl to jump; no cooldown.";
        }
    }
    public sealed class BoatFunDriverV4 : MonoBehaviour
    {
        public Player Owner;
        public long World;
        public int Generation;
        Ship ship; Rigidbody body; ZNetView view;
        readonly BoatJumpInput jumps = new BoatJumpInput();
        bool airborne, descending;
        WaterVolume previousWater;
        static readonly BindingFlags Flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
        // Preserve native vertical damping and buoyancy: removing m_damping
        // makes the water suspension oscillate after a jump.
        static readonly string[] Names = { "m_sailForceFactor", "m_dampingSideway", "m_dampingForward", "m_stearForce", "m_stearVelForceFactor", "m_backwardForce", "m_waterImpactDamage", "m_upsideDownDmg" };
        float[] originals;
        bool Controls()
        {
            return Owner && Owner == Player.m_localPlayer && !Owner.IsDead() && !Owner.IsTeleporting()
                && Application.isFocused && !Menu.IsVisible() && !InventoryGui.IsVisible()
                && !Console.IsVisible() && !Minimap.IsOpen() && !(Chat.instance && Chat.instance.HasFocus());
        }
        void Update()
        {
            jumps.Sample(Input.GetKey(KeyCode.LeftControl), BoatFunV4.Enabled && Controls() && ship && view && view.IsOwner());
        }
        void Restore()
        {
            if (ship && originals != null)
                for (int i = 0; i < Names.Length; i++) typeof(Ship).GetField(Names[i], Flags).SetValue(ship, originals[i]);
            ship = null; body = null; view = null; originals = null; jumps.Clear(); airborne = descending = false;
        }
        void Attach(Ship target)
        {
            var fields = new FieldInfo[Names.Length]; var values = new float[Names.Length];
            for (int i = 0; i < Names.Length; i++)
            {
                fields[i] = typeof(Ship).GetField(Names[i], Flags);
                if (fields[i] == null || fields[i].FieldType != typeof(float)) throw new MissingFieldException("Boat physics changed: " + Names[i]);
                values[i] = (float)fields[i].GetValue(target);
            }
            body = target.GetComponent<Rigidbody>(); view = target.GetComponent<ZNetView>();
            if (!body || !view || !view.IsValid()) throw new InvalidOperationException("Boat body or network view unavailable.");
            ship = target; originals = values;
            for (int i = 0; i < Names.Length; i++) fields[i].SetValue(ship, 0f);
        }
        void FixedUpdate()
        {
            try
            {
                if (!BoatFunV4.Enabled || Generation != BoatFunV4.Generation || !Owner || Owner != Player.m_localPlayer || !ZNet.instance || ZNet.instance.GetWorldUID() != World)
                { if (Generation == BoatFunV4.Generation) { BoatFunV4.Stop(); BoatFunV4.Status = "Pixie boat: OFF"; } Restore(); Destroy(gameObject); return; }
                Ship target = Controls() ? Owner.GetControlledShip() : null;
                if (target && !target.IsOwner()) { Restore(); BoatFunV4.Status = "Pixie boat: waiting for normal boat ownership. Stay at the helm."; return; }
                if (target != ship) { Restore(); if (target) Attach(target); }
                if (!ship) { BoatFunV4.Status = "Pixie boat: ON. Take the helm to drive."; return; }
                if (!view.IsOwner()) { jumps.Clear(); BoatFunV4.Status = "Pixie boat: waiting for normal boat ownership. Stay at the helm."; return; }
                float dt = Time.fixedDeltaTime;
                // Retain normal sail/throttle controls; replace propulsion with a motor.
                string setting = ship.GetSpeedSetting().ToString();
                float throttle = setting == "Back" ? -0.35f : setting == "Slow" ? 0.35f : setting == "Half" ? 0.65f : setting == "Full" ? 1f : 0f;
                float speed = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift) ? 40f : 25f;
                Vector3 forward = Vector3.ProjectOnPlane(ship.transform.forward, Vector3.up).normalized;
                Vector3 velocity = body.linearVelocity;
                float waterLevel = Floating.GetWaterLevel(body.worldCenterOfMass, ref previousWater);
                if (airborne && velocity.y <= 0f) descending = true;
                if (airborne && descending && body.worldCenterOfMass.y <= waterLevel + ship.m_waterLevelOffset + 0.5f)
                    airborne = descending = false;
                Vector3 horizontal = Vector3.MoveTowards(new Vector3(velocity.x, 0, velocity.z), forward * throttle * speed, 12f * dt);
                body.linearVelocity = new Vector3(horizontal.x, velocity.y, horizontal.z);
                float turn = (Input.GetKey(KeyCode.D) ? 1f : 0f) - (Input.GetKey(KeyCode.A) ? 1f : 0f);
                Vector3 heading = Quaternion.AngleAxis(turn * 65f * dt, Vector3.up) * forward;
                body.MoveRotation(Quaternion.RotateTowards(body.rotation, Quaternion.LookRotation(heading, Vector3.up), 100f * dt));
                // Terrain clearance lets the physical hull travel on land; collisions remain active.
                RaycastHit hit;
                if (Physics.Raycast(body.position + Vector3.up * 4, Vector3.down, out hit, 10f, LayerMask.GetMask("terrain"), QueryTriggerInteraction.Ignore))
                {
                    var hull = ship.m_floatCollider;
                    float clearance = hull ? body.position.y - hull.bounds.min.y : 1.5f;
                    float error = hit.point.y + clearance + 0.6f - body.position.y;
                    bool dry = BoatSupport.DryGround(hit.point.y, waterLevel);
                    if (dry && airborne && descending && error > -0.2f && Mathf.Abs(velocity.y) < 2f)
                        airborne = descending = false;
                    float lift = BoatSupport.Lift(airborne, hit.point.y, waterLevel, error, velocity.y);
                    if (lift != 0f) body.AddForce(Vector3.up * lift, ForceMode.Acceleration);
                }
                if (jumps.Consume())
                { velocity = body.linearVelocity; velocity.y = 22f; body.linearVelocity = velocity; airborne = true; descending = false; }
                BoatFunV4.Status = "Pixie boat: ON | " + setting + " | " + speed + " m/s max | Left Ctrl: high jump | Shift: boost";
            }
            catch (Exception e)
            { BoatFunV4.Stop(); BoatFunV4.Status = "Pixie boat stopped: " + e.GetBaseException().Message; Restore(); Destroy(gameObject); }
        }
        void OnDestroy() { Restore(); if (BoatFunV4.Driver == this) BoatFunV4.Driver = null; }
    }
}
