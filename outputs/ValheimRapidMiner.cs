using System;
using System.Reflection;
using System.Collections;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class RapidMinerV5
    {
        public static int Enabled;
        public static string LastError;
        private static Player owner;
        private static RapidMinerDriverV5 driver;
        internal static readonly FieldInfo Stamina = typeof(Player).GetField("m_stamina", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly FieldInfo DrawTime = typeof(Humanoid).GetField("m_attackDrawTime", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly FieldInfo LoadedWeapon = typeof(Player).GetField("m_weaponLoaded", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly FieldInfo AttackHold = FindField(typeof(Player), "m_attackHold");
        internal static readonly MethodInfo SetLoaded = typeof(Player).GetMethod("SetWeaponLoaded", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly MethodInfo CancelReload = typeof(Player).GetMethod("CancelReloadAction", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly MethodInfo TakeInput = typeof(Player).GetMethod("TakeInput", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly FieldInfo CurrentAttack = FindField(typeof(Humanoid), "m_currentAttack");
        internal static readonly FieldInfo AttackOwner = FindField(typeof(Attack), "m_character");
        internal static readonly FieldInfo AttackWeapon = FindField(typeof(Attack), "m_weapon");
        internal static readonly FieldInfo FireTimer = FindField(typeof(Attack), "m_projectileFireTimer");
        internal static readonly FieldInfo ActionQueue = FindField(typeof(Player), "m_actionQueue");
        internal static readonly Type MinorAction = typeof(Player).GetNestedType("MinorActionData", BindingFlags.Public | BindingFlags.NonPublic);
        internal static readonly FieldInfo ActionKind = MinorAction == null ? null : FindField(MinorAction, "m_type");
        internal static readonly FieldInfo ActionItem = MinorAction == null ? null : FindField(MinorAction, "m_item");
        internal static readonly FieldInfo ActionTime = MinorAction == null ? null : FindField(MinorAction, "m_time");
        internal static readonly FieldInfo ActionDuration = MinorAction == null ? null : FindField(MinorAction, "m_duration");
        internal static readonly FieldInfo ActionEitr = MinorAction == null ? null : FindField(MinorAction, "m_eitrDrain");
        private static FieldInfo FindField(Type type, string name)
        {
            while (type != null)
            {
                FieldInfo field = type.GetField(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
                if (field != null) return field;
                type = type.BaseType;
            }
            return null;
        }
        public static void Configure(Player player)
        {
            if (Stamina == null) throw new MissingFieldException("Player.m_stamina");
            if (DrawTime == null || LoadedWeapon == null || AttackHold == null || SetLoaded == null || CancelReload == null || TakeInput == null || CurrentAttack == null || AttackOwner == null || AttackWeapon == null || FireTimer == null || ActionQueue == null || ActionKind == null || ActionItem == null || ActionTime == null || ActionDuration == null || ActionEitr == null)
                throw new MissingFieldException("Fast attacks: weapon loading/spell timing fields unavailable");
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
                    driver = new GameObject("SoloToolkit_RapidMiner").AddComponent<RapidMinerDriverV5>();
                    driver.Owner = player;
                }
                driver.Protect();
                driver.UpdateSpell();
            }
            catch (Exception error) { Fault(error); }
        }
    }

    public sealed class RapidMinerDriverV5 : MonoBehaviour
    {
        public Player Owner;
        private Animator animator;
        private bool accelerated;
        private float originalSpeed;
        private ItemDrop.ItemData preparedReloadWeapon;
        private Attack spell;
        private float originalBurstInterval;
        private bool scaledBursts;
        private static bool IsMagic(ItemDrop.ItemData item)
        {
            return item != null && item.m_shared != null &&
                (item.m_shared.m_skillType == Skills.SkillType.ElementalMagic || item.m_shared.m_skillType == Skills.SkillType.BloodMagic);
        }
        private void RestoreSpell()
        {
            if (spell != null && scaledBursts)
            {
                spell.m_burstInterval = originalBurstInterval;
                float remaining = (float)RapidMinerV5.FireTimer.GetValue(spell);
                if (remaining > 0f) RapidMinerV5.FireTimer.SetValue(spell, remaining * 10f);
            }
            spell = null; scaledBursts = false;
        }
        private void AccelerateSpell(ItemDrop.ItemData item)
        {
            if (!IsMagic(item) || !Application.isFocused || !(bool)RapidMinerV5.TakeInput.Invoke(Owner, null))
            { RestoreSpell(); return; }
            Attack current = RapidMinerV5.CurrentAttack.GetValue(Owner) as Attack;
            // Native StartAttack clones a weapon definition. Change only that live cast,
            // never shared item attacks, another caster, projectile count or damage.
            if (current == null || current.m_attackType != Attack.AttackType.Projectile ||
                !System.Object.ReferenceEquals(RapidMinerV5.AttackOwner.GetValue(current), Owner) ||
                !System.Object.ReferenceEquals(RapidMinerV5.AttackWeapon.GetValue(current), item) ||
                System.Object.ReferenceEquals(current, item.m_shared.m_attack) ||
                System.Object.ReferenceEquals(current, item.m_shared.m_secondaryAttack))
            { RestoreSpell(); return; }
            if (System.Object.ReferenceEquals(current, spell)) return;
            RestoreSpell();spell = current;
            originalBurstInterval = current.m_burstInterval;
            if (originalBurstInterval > 0f && !Single.IsNaN(originalBurstInterval) && !Single.IsInfinity(originalBurstInterval))
            {
                scaledBursts = true;
                current.m_burstInterval = originalBurstInterval / 10f;
                float remaining = (float)RapidMinerV5.FireTimer.GetValue(current);
                if (remaining > 0f) RapidMinerV5.FireTimer.SetValue(current, remaining / 10f);
            }
        }
        private bool ReloadWeaponInput(ItemDrop.ItemData item)
        {
            return item != null && (item.m_shared.m_skillType == Skills.SkillType.Crossbows ||
                (IsMagic(item) && item.m_shared.m_attack != null && item.m_shared.m_attack.m_requiresReload)) &&
                Application.isFocused && (bool)RapidMinerV5.TakeInput.Invoke(Owner, null) &&
                (bool)RapidMinerV5.AttackHold.GetValue(Owner);
        }
        private void ReleaseReloadWeapon()
        {
            // Never unload another weapon or an original, naturally loaded shot.
            if (preparedReloadWeapon != null && Owner &&
                System.Object.ReferenceEquals(RapidMinerV5.LoadedWeapon.GetValue(Owner), preparedReloadWeapon))
                RapidMinerV5.SetLoaded.Invoke(Owner, new object[] { null });
            preparedReloadWeapon = null;
        }
        private bool PayMagicReload(ItemDrop.ItemData item)
        {
            float remaining = item.GetWeaponLoadingTime();
            float drain = item.m_shared.m_attack.m_reloadEitrDrain;
            IList queue = RapidMinerV5.ActionQueue.GetValue(Owner) as IList;
            if (queue != null) foreach (object action in queue)
            {
                if (RapidMinerV5.ActionKind.GetValue(action).ToString() != "Reload" ||
                    !System.Object.ReferenceEquals(RapidMinerV5.ActionItem.GetValue(action), item)) continue;
                remaining = Math.Max(0f, (float)RapidMinerV5.ActionDuration.GetValue(action) - (float)RapidMinerV5.ActionTime.GetValue(action));
                drain = (float)RapidMinerV5.ActionEitr.GetValue(action);
                break;
            }
            float cost = Math.Max(0f, remaining) * Math.Max(0f, drain);
            if (Single.IsNaN(cost) || Single.IsInfinity(cost)) throw new InvalidOperationException("Invalid spell reload cost");
            if (cost > 0f)
            {
                if (!Owner.TryUseEitr(cost)) return false;
                Owner.UseEitr(cost);
            }
            return true;
        }
        private void PrepareReloadWeapon(ItemDrop.ItemData item)
        {
            if (!ReloadWeaponInput(item)) { ReleaseReloadWeapon(); return; }
            if (preparedReloadWeapon != null && !System.Object.ReferenceEquals(preparedReloadWeapon, item)) ReleaseReloadWeapon();
            // Native held-attack logic fires repeatedly once loaded. Do not synthesize input,
            // spawn projectiles or call attack events: native attacks still spend real bolts.
            if (!System.Object.ReferenceEquals(RapidMinerV5.LoadedWeapon.GetValue(Owner), item))
            {
                bool magic = IsMagic(item);
                if (magic && !PayMagicReload(item)) return;
                RapidMinerV5.CancelReload.Invoke(Owner, null);
                RapidMinerV5.SetLoaded.Invoke(Owner, new object[] { item });
                // Mana-paid spell reloads are genuine ready shots, retained on release.
                if (!magic) preparedReloadWeapon = item;
            }
        }
        private ItemDrop.ItemData RapidTool()
        {
            if (!RapidMinerV5.Owns(Owner) || Owner.IsDead() || Owner.IsTeleporting()) return null;
            ItemDrop.ItemData item = Owner.GetCurrentWeapon();
            if (item == null || item.m_shared == null) return null;
            switch (item.m_shared.m_skillType)
            {
                case Skills.SkillType.Swords: case Skills.SkillType.Knives: case Skills.SkillType.Clubs:
                case Skills.SkillType.Polearms: case Skills.SkillType.Spears: case Skills.SkillType.Axes:
                case Skills.SkillType.Bows: case Skills.SkillType.Crossbows: case Skills.SkillType.Unarmed:
                case Skills.SkillType.Pickaxes: case Skills.SkillType.ElementalMagic: case Skills.SkillType.BloodMagic:
                    return item;
                default: return null;
            }
        }
        public void Protect()
        {
            ItemDrop.ItemData item = RapidTool();
            if (item == null) return;
            RapidMinerV5.Stamina.SetValue(Owner, Owner.GetMaxStamina());
            item.m_durability = item.GetMaxDurability();
        }
        public void UpdateSpell()
        {
            ItemDrop.ItemData item = RapidTool();
            if (item == null) RestoreSpell(); else AccelerateSpell(item);
        }
        private void FixedUpdate()
        {
            try
            {
                ItemDrop.ItemData item = RapidTool();
                if (item == null) { ReleaseReloadWeapon(); RestoreSpell(); return; }
                PrepareReloadWeapon(item);
                AccelerateSpell(item);
                float extra = 9f * Time.fixedDeltaTime;
                if (item.m_shared.m_skillType == Skills.SkillType.Bows ||
                    (IsMagic(item) && item.m_shared.m_attack != null && item.m_shared.m_attack.m_bowDraw))
                {
                    float draw = (float)RapidMinerV5.DrawTime.GetValue(Owner);
                    if (draw > 0f) RapidMinerV5.DrawTime.SetValue(Owner, draw + extra);
                }
            }
            catch (Exception error) { RapidMinerV5.Fault(error); Release(); }
        }
        private void Restore()
        {
            if (accelerated && animator) animator.speed = originalSpeed;
            accelerated = false;
        }
        public void Release() { Restore(); ReleaseReloadWeapon(); RestoreSpell(); }
        private void Update()
        {
            if (!RapidMinerV5.Owns(Owner)) { Release(); Destroy(gameObject); return; }
            try { Protect(); UpdateSpell(); }
            catch (Exception error) { RapidMinerV5.Fault(error); Release(); }
        }
        private void LateUpdate()
        {
            try
            {
                ItemDrop.ItemData item = RapidTool();
                if (item == null || !Owner.InAttack()) { Restore(); return; }
                if (!animator) animator = Owner.GetComponentInChildren<Animator>();
                if (!animator) throw new InvalidOperationException("Player animator unavailable");
                if (!accelerated) { originalSpeed = animator.speed; accelerated = true; }
                animator.speed = originalSpeed * (item.m_shared.m_skillType == Skills.SkillType.Crossbows ? 30f : 10f);
                Protect();
            }
            catch (Exception error) { RapidMinerV5.Fault(error); Release(); }
        }
        private void OnDestroy() { Release(); }
    }
}
