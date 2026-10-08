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
                if (!collider || collider.GetComponentInParent<Character>() == owner) continue;
                var target = collider.GetComponentInParent<IDestructible>();
                if (target == null || !seen.Add(target)) continue;
                var hit = new HitData();
                hit.m_damage.m_damage = 500f;
                hit.m_damage.m_chop = 500f;
                hit.m_damage.m_pickaxe = 500f;
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
}
