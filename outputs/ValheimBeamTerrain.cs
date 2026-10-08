using System.Collections.Generic;
using UnityEngine;

namespace ValheimSoloToolkit
{
    internal static class BeamTerrain
    {
        // Native heightmaps make open trenches, not underground tunnels.
        // Spread edits across ticks to bound terrain rebuilds/RPC traffic.
        internal static void Excavate(Vector3 origin, Vector3 direction, float length, float radius, ref int cursor)
        {
            int samples=Mathf.CeilToInt(length/2f)+1;
            GameObject operation=null;
            try
            {
                var maps=new List<Heightmap>();
                for(int i=0;i<6;i++)
                {
                    int sample=cursor%samples;cursor=(sample+1)%samples;
                    Vector3 point=origin+direction*Mathf.Min(length,sample*2f);
                    float height;
                    if(!Heightmap.GetHeight(point,out height)||point.y-radius>height)continue;
                    if(!operation)
                    {
                        operation=new GameObject("SoloToolkit_DeathBeamDig");
                        operation.SetActive(false); // Set settings before Awake; submit edits explicitly.
                        var op=operation.AddComponent<TerrainOp>();
                        op.m_settings=new TerrainOp.Settings();
                        op.m_settings.m_level=false;op.m_settings.m_smooth=false;
                        op.m_settings.m_paintCleared=false;
                        op.m_settings.m_raise=true;op.m_settings.m_raiseRadius=radius;
                        op.m_settings.m_raiseDelta=-1f;op.m_settings.m_raisePower=0f;
                        op.m_settings.m_square=false;
                    }
                    point.y=Mathf.Min(height,point.y-radius);
                    operation.transform.position=point;
                    maps.Clear();Heightmap.FindHeightmap(point,radius,maps);
                    foreach(var map in maps)
                        map.GetAndCreateTerrainCompiler().ApplyOperation(operation.GetComponent<TerrainOp>());
                }
            }
            finally { if(operation)Object.Destroy(operation); }
        }
    }
}
