using System.Collections.Generic;
using UnityEngine;

namespace ValheimSoloToolkit
{
    internal static class BeamDamage
    {
        // Overlap the entire beam instead of stopping at the first wall/terrain hit.
        internal static void Death(Player owner, Vector3 origin, Vector3 direction, float length, float radius)
        {
            var seen = new HashSet<IDestructible>();
            foreach (var collider in Physics.OverlapCapsule(origin, origin + direction * length, radius, ~0, QueryTriggerInteraction.Ignore))
            {
                Hit(owner,collider,origin,direction,500f,seen);
            }
        }
        internal static void Hit(Player owner, Collider collider, Vector3 origin, Vector3 direction, float damage, HashSet<IDestructible> seen)
        {
                if (!collider || collider.GetComponentInParent<Character>() == owner) return;
                var target = collider.GetComponentInParent<IDestructible>();
                if (target == null || !seen.Add(target)) return;
                var hit = new HitData();
                hit.m_damage.m_damage = damage;
                hit.m_damage.m_chop = damage;
                hit.m_damage.m_pickaxe = damage;
                hit.m_toolTier = 100;
                hit.m_hitCollider = collider;
                hit.m_point = collider.ClosestPoint(origin);
                hit.m_dir = direction;
                hit.m_ranged = true;
                hit.m_skill = Skills.SkillType.None;
                hit.SetAttacker(owner);
                target.Damage(hit);
        }
    }
}
