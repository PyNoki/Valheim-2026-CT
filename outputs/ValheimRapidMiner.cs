using System;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class RapidMinerV1
    {
        public static int Enabled;
        public static string LastError;
        private static Player owner;
        private static RapidMinerDriverV1 driver;
        internal static readonly FieldInfo Stamina = typeof(Player).GetField("m_stamina", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        public static void Configure(Player player)
        {
            if (Stamina == null) throw new MissingFieldException("Player.m_stamina");
            owner = player; LastError = null; Enabled = 1;
        }
        // CE invokes this outside Unity's game thread; the driver restores animation.
        public static void Disable() { Enabled = 0; owner = null; }
        internal static bool Owns(Player player) { return Enabled == 1 && player && player == owner && player == Player.m_localPlayer; }
        internal static void Fault(Exception error) { LastError = error.Message; Disable(); }
        public static void Tick(Player player)
        {
            if (!Owns(player)) return;
            try
            {
                if (driver && driver.Owner != player)
                {
                    driver.Release();
                    UnityEngine.Object.Destroy(driver.gameObject);
                    driver = null;
                }
                if (!driver)
                {
                    driver = new GameObject("SoloToolkit_RapidMiner").AddComponent<RapidMinerDriverV1>();
                    driver.Owner = player;
                }
                driver.Protect();
            }
            catch (Exception error) { Fault(error); }
        }
    }

    public sealed class RapidMinerDriverV1 : MonoBehaviour
    {
        public Player Owner;
        private Animator animator;
        private bool accelerated;
        private float originalSpeed;
        private ItemDrop.ItemData Pickaxe()
        {
            if (!RapidMinerV1.Owns(Owner) || Owner.IsDead()) return null;
            ItemDrop.ItemData item = Owner.GetCurrentWeapon();
            return item != null && item.m_shared.m_skillType == Skills.SkillType.Pickaxes ? item : null;
        }
        public void Protect()
        {
            ItemDrop.ItemData item = Pickaxe();
            if (item == null) return;
            RapidMinerV1.Stamina.SetValue(Owner, Owner.GetMaxStamina());
            item.m_durability = item.GetMaxDurability();
        }
        private void Restore()
        {
            if (accelerated && animator) animator.speed = originalSpeed;
            accelerated = false;
        }
        public void Release() { Restore(); }
        private void Update()
        {
            if (!RapidMinerV1.Owns(Owner)) { Restore(); Destroy(gameObject); return; }
            try { Protect(); }
            catch (Exception error) { RapidMinerV1.Fault(error); Restore(); }
        }
        private void LateUpdate()
        {
            try
            {
                if (Pickaxe() == null || !Owner.InAttack()) { Restore(); return; }
                if (!animator) animator = Owner.GetComponentInChildren<Animator>();
                if (!animator) throw new InvalidOperationException("Player animator unavailable");
                if (!accelerated) { originalSpeed = animator.speed; accelerated = true; }
                animator.speed = 10f;
                Protect();
            }
            catch (Exception error) { RapidMinerV1.Fault(error); Restore(); }
        }
        private void OnDestroy() { Restore(); }
    }
}
