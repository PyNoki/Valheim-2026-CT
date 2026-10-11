using System;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 internal static class DeathBeamTerrain {
  const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  delegate bool ReadBaseHeight(Heightmap map,Vector3 point,out float height);
  static readonly ReadBaseHeight GetBaseHeight=(ReadBaseHeight)Delegate.CreateDelegate(typeof(ReadBaseHeight),typeof(Heightmap).GetMethod("GetWorldBaseHeight",Flags));
  static object Field(object o,string name){var f=o.GetType().GetField(name,Flags);if(f==null)throw new MissingFieldException(name);return f.GetValue(o);}
  internal static void Excavate(Vector3 origin,Vector3 direction,float length,float radius){
   Vector3 end=origin+direction*length;
   float minX=Mathf.Min(origin.x,end.x)-radius,maxX=Mathf.Max(origin.x,end.x)+radius;
   float minZ=Mathf.Min(origin.z,end.z)-radius,maxZ=Mathf.Max(origin.z,end.z)+radius;
   foreach(var map in Heightmap.GetAllHeightmaps()){
    try {
     if(!map||map.IsDistantLod)continue;
     float scale=map.m_scale;int width=map.m_width;Vector3 tile=map.transform.position;float half=width*scale*0.5f;
     if(tile.x+half<minX||tile.x-half>maxX||tile.z+half<minZ||tile.z-half>maxZ)continue;
     var heights=(System.Collections.Generic.List<float>)Field(map,"m_heights");
     if(heights==null||heights.Count<(width+1)*(width+1))continue;
     var compiler=(TerrainComp)typeof(Heightmap).GetMethod("GetAndCreateTerrainCompiler",Flags).Invoke(map,null);
     if(!compiler)continue;
     // Initialize clears all existing height/paint arrays. Native Start owns
     // initialization and loading; skip new tiles until that has completed.
     if(!(bool)Field(compiler,"m_initialized"))continue;
     var view=compiler.GetComponent<ZNetView>();if(!view||!view.IsValid())continue;
     if(!view.IsOwner())view.ClaimOwnership();if(!view.IsOwner())continue;
     var level=(float[])Field(compiler,"m_levelDelta");var smooth=(float[])Field(compiler,"m_smoothDelta");var modified=(bool[])Field(compiler,"m_modifiedHeight");
     if(level==null||smooth==null||modified==null)continue;
     if(level.Length!=(width+1)*(width+1)||smooth.Length!=level.Length||modified.Length!=level.Length)throw new InvalidOperationException("Terrain compiler layout changed.");
     bool changed=false;
     for(int z=0;z<=width;z++)for(int x=0;x<=width;x++){
      float wx=tile.x+(x-width*0.5f)*scale,wz=tile.z+(z-width*0.5f)*scale;
      float height=tile.y+map.GetHeight(x,z),bottom;
      if(!DeathBeamCut.Bottom(origin.x,origin.y,origin.z,direction.x,direction.y,direction.z,length,radius,wx,wz,height,out bottom))continue;
      float natural;
      if(GetBaseHeight(map,new Vector3(wx,height,wz),out natural))bottom=Mathf.Max(bottom,natural-8f);
      if(bottom>=height-0.02f)continue;
      int i=z*(width+1)+x;
      // Change existing deltas downward only; the rendered surface may already
      // be clipped by Valheim's native terrain depth limit.
      level[i]=DeathBeamCut.LowerDelta(level[i],smooth[i],height,bottom);smooth[i]=0;modified[i]=true;changed=true;
     }
     if(!changed)continue;
     typeof(TerrainComp).GetField("m_operations",Flags).SetValue(compiler,(int)Field(compiler,"m_operations")+1);
     typeof(TerrainComp).GetField("m_lastOpPoint",Flags).SetValue(compiler,end);
     typeof(TerrainComp).GetField("m_lastOpRadius",Flags).SetValue(compiler,radius);
     typeof(TerrainComp).GetMethod("Save",Flags).Invoke(compiler,new object[]{false});
     map.Poke(0,false);
    }catch(Exception error){Debug.LogWarning("Death Beam terrain tile skipped: "+error.GetBaseException());}
   }
  }
 }
 internal static class DeathBeamCut {
  internal static float LowerDelta(float level,float smooth,float height,float target)
  {return level+smooth+Math.Min(0,target-height);}
  internal static bool Bottom(float ox,float oy,float oz,float dx,float dy,float dz,float length,float radius,float x,float z,float height,out float bottom){
   bottom=height;
   float norm=dx*dx+dy*dy+dz*dz;if(norm<0.0001f)return false;
   float t=Math.Max(0,Math.Min(length,((x-ox)*dx+(height-oy)*dy+(z-oz)*dz)/norm));
   float px=ox+dx*t,pz=oz+dz*t;float distance=(x-px)*(x-px)+(z-pz)*(z-pz);
   float axisY=oy+dy*t;
   if(distance+(height-axisY)*(height-axisY)>radius*radius)return false;
   bottom=axisY-(float)Math.Sqrt(Math.Max(0,radius*radius-distance));
   return bottom<height-0.02f;
  }
 }
}
