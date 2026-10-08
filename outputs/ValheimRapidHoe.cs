using System;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class RapidHoeV1
    {
        public static int Enabled;
        public static string LastError;
        private static Player owner;
        private static RapidHoeDriverV1 driver;
        internal static FieldInfo Field(string name)
        {
            var field = typeof(Player).GetField(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (field == null || field.FieldType != typeof(float)) throw new MissingFieldException("Player." + name);
            return field;
        }
        internal static readonly FieldInfo Stamina = Field("m_stamina");
        internal static readonly FieldInfo Delay = Field("m_placeDelay");
        internal static readonly FieldInfo Pressed = Field("m_placePressedTime");
        internal static readonly FieldInfo LastUse = Field("m_lastToolUseTime");
        internal static readonly MethodInfo RightItem = typeof(Humanoid).GetMethod("GetRightItem", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        public static void Configure(Player player) { owner = player; LastError = null; Enabled = 1; }
        // Unity work and restoration run on the game thread, including after disable.
        public static void Disable() { Enabled = 0; owner = null; }
        internal static bool Owns(Player player) { return Enabled == 1 && player && player == owner && player == Player.m_localPlayer; }
        internal static void Fault(Exception error) { LastError = error.Message; Disable(); }
        // Called before the original Player.UpdatePlacement(bool, float).
        public static void Tick(Player player, bool takeInput, float dt)
        {
            if (!Owns(player)) return;
            try
            {
                if (driver && driver.Owner != player)
                {
                    driver.Release(); UnityEngine.Object.Destroy(driver.gameObject); driver = null;
                }
                if (!driver)
                {
                    driver = new GameObject("SoloToolkit_RapidHoe").AddComponent<RapidHoeDriverV1>();
                    driver.Owner = player;
                }
                driver.Step(takeInput);
            }
            catch (Exception error) { Fault(error); if (driver) driver.Release(); }
        }
    }

    public sealed class RapidHoeDriverV1 : MonoBehaviour
    {
        public Player Owner;
        private bool changed;
        private float originalDelay;
        private const float Interval = 0.05f;
        private ItemDrop.ItemData Hoe()
        {
            if (!RapidHoeV1.Owns(Owner) || Owner.IsDead()) return null;
            var item = (ItemDrop.ItemData)RapidHoeV1.RightItem.Invoke(Owner, null);
            return item != null && item.m_shared.m_name == "$item_hoe" ? item : null;
        }
        public void Release()
        {
            if (changed && Owner) RapidHoeV1.Delay.SetValue(Owner, originalDelay);
            changed = false;
        }
        public void Step(bool takeInput)
        {
            var item = Hoe();
            if (item == null || !Owner.InPlaceMode() || !takeInput || Hud.IsPieceSelectionVisible() || Hud.InRadial())
            { Release(); return; }
            if (!changed)
            {
                originalDelay = (float)RapidHoeV1.Delay.GetValue(Owner);
                changed = true;
            }
            RapidHoeV1.Delay.SetValue(Owner, Math.Min(originalDelay, Interval));
            RapidHoeV1.Stamina.SetValue(Owner, Owner.GetMaxStamina());
            item.m_durability = item.GetMaxDurability();
            // Queue only when an action can run now: releasing never leaves an auto-repeat queued.
            if (!ZInput.GetButton("JoyAltKeys") && (ZInput.GetButton("Attack") || ZInput.GetButton("JoyPlace"))
                && Time.time - (float)RapidHoeV1.LastUse.GetValue(Owner) > Interval)
                RapidHoeV1.Pressed.SetValue(Owner, Time.time);
        }
        private void Update()
        {
            try
            {
                if (Hoe() == null) Release();
                if (!RapidHoeV1.Owns(Owner)) Destroy(gameObject);
            }
            catch (Exception error) { RapidHoeV1.Fault(error); Release(); }
        }
        private void OnDestroy() { Release(); }
    }
}
