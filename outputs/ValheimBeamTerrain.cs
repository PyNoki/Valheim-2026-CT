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
            int samples=Mathf.CeilToInt(length/2f)+1;
            int lanes=radius>2f?3:1;
            float horizontal=(float)Math.Sqrt(direction.x*direction.x+direction.z*direction.z);
            Vector3 side=horizontal>.001f?new Vector3(-direction.z/horizontal,0,direction.x/horizontal):new Vector3(1,0,0);
            for(int i=0;i<6;i++)
            {
                int sample=cursor%(samples*lanes);cursor=(sample+1)%(samples*lanes);
                Vector3 point=origin+direction*Mathf.Min(length,(sample/lanes)*2f);
                if(lanes>1)point=point+side*((sample%lanes-1)*radius*.65f);
                float height;
                if(!Heightmap.GetHeight(point,out height)||point.y-radius>height)continue;
                point.y=height;
                Dig(owner,point);
            }
        }
        internal static void Dig(Player owner, Vector3 point)
        {
            var prefab=ZNetScene.instance.GetPrefab("PickaxeIron");
            var item=prefab?prefab.GetComponent<ItemDrop>():null;
            var weapon=item?item.m_itemData:null;
            var shared=weapon!=null?weapon.m_shared:null;
            var dig=shared!=null?shared.m_spawnOnHitTerrain:null;
            if(!dig)throw new InvalidOperationException("Iron pickaxe terrain impact prefab unavailable.");
            Attack.SpawnOnHitTerrain(point,dig,owner,0f,weapon,null,false);
        }
    }
}
