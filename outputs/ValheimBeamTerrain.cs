using System;
using UnityEngine;

namespace ValheimSoloToolkit
{
    internal static class BeamTerrain
    {
        // TerrainOp.Settings.Serialize sends only a registered prefab hash.
        // Use the pickaxe's real impact prefab, not an ad-hoc TerrainOp object.
        internal static void Excavate(Player owner, Vector3 origin, Vector3 direction, float length, float radius, ref int cursor)
        {
            var prefab=ZNetScene.instance.GetPrefab("PickaxeIron");
            var item=prefab?prefab.GetComponent<ItemDrop>():null;
            var weapon=item?item.m_itemData:null;
            var shared=weapon!=null?weapon.m_shared:null;
            var dig=shared!=null?shared.m_spawnOnHitTerrain:null;
            if(!dig)throw new InvalidOperationException("Iron pickaxe terrain impact prefab unavailable.");
            int samples=Mathf.CeilToInt(length/2f)+1;
            for(int i=0;i<6;i++)
            {
                int sample=cursor%samples;cursor=(sample+1)%samples;
                Vector3 point=origin+direction*Mathf.Min(length,sample*2f);
                float height;
                if(!Heightmap.GetHeight(point,out height)||point.y-radius>height)continue;
                // Strike the current surface like a pickaxe; subsequent sweeps dig deeper.
                point.y=height;
                Attack.SpawnOnHitTerrain(point,dig,owner,0f,weapon,null,false);
            }
        }
    }
}
