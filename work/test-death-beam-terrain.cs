using System;
using System.Collections.Generic;
using UnityEngine;
using ValheimSoloToolkit;
namespace UnityEngine {
 public class Object {public static implicit operator bool(Object o){return o!=null;}}
 public struct Vector3 {public static Vector3 operator +(Vector3 a,Vector3 b){return new Vector3(a.x+b.x,a.y+b.y,a.z+b.z);}public static Vector3 operator *(Vector3 a,float n){return new Vector3(a.x*n,a.y*n,a.z*n);}public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}}
 public class Transform {public Vector3 position;}
 public static class Mathf {public static float Min(float a,float b){return Math.Min(a,b);}public static float Max(float a,float b){return Math.Max(a,b);}public static float Abs(float a){return Math.Abs(a);}}
}
namespace ValheimSoloToolkit {internal static class BlastDiagnostics {internal static int Skipped;internal static void Warn(string s,Exception e){Skipped++;}}}
public class ZNetView:UnityEngine.Object {public bool owner=true;public bool IsValid(){return true;}public bool IsOwner(){return owner;}public void ClaimOwnership(){} }
public class TerrainComp:UnityEngine.Object {
 public float[] m_levelDelta=new float[25],m_smoothDelta=new float[25];public bool[] m_modifiedHeight=new bool[25];
 public int m_operations,saves;public Vector3 m_lastOpPoint;public float m_lastOpRadius;public ZNetView view=new ZNetView();
 public bool m_initialized=true;public int initializeCalls;
 public bool fail;public T GetComponent<T>() where T:class{return view as T;}public void Initialize(){initializeCalls++;m_initialized=true;m_levelDelta=new float[25];m_smoothDelta=new float[25];m_modifiedHeight=new bool[25];if(fail)throw new NullReferenceException("unloaded tile");}
 public void Save(bool paintOnly){if(paintOnly)throw new Exception("Height edits need unconditional Save(false)");saves++;}
}
public class Heightmap:UnityEngine.Object {
 public static List<Heightmap> maps=new List<Heightmap>();public Transform transform=new Transform();public bool IsDistantLod;
 public float m_scale=1;public int m_width=4;public TerrainComp compiler=new TerrainComp();public int rebuilds;
 public List<float> m_heights=new List<float>(new float[25]);
 public static List<Heightmap> GetAllHeightmaps(){return maps;}public TerrainComp GetAndCreateTerrainCompiler(){return compiler;}
 public float GetHeight(int x,int z){int i=z*5+x;return compiler.m_levelDelta[i]+compiler.m_smoothDelta[i];}
 public bool GetWorldBaseHeight(Vector3 p,out float height){height=0;return true;}
 public void Poke(int delay,bool paintOnly){if(delay!=0||paintOnly)throw new Exception("Immediate full terrain rebuild required");rebuilds++;}
}
namespace UnityEngine {public static class Debug {public static void LogWarning(object o){}}}
class TestDeathTerrain {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  float bottom;
  Check(DeathBeamCut.Bottom(0,10,0,0,0,1,240,2,0,230,10,out bottom)&&bottom==8,"full 240m path cuts in one pass");
  Check(!DeathBeamCut.Bottom(0,20,0,0,0,1,240,2,0,100,10,out bottom),"beam above surface cannot dig distant ground");
  Check(!DeathBeamCut.Bottom(0,10,0,0,0,1,240,2,4,100,10,out bottom),"outside beam footprint excluded");
  Check(DeathBeamCut.Bottom(0,20,0,0,-1,0,40,2,0,0,10,out bottom)&&bottom==8,"vertical aiming only excavates at visible surface contact");
  Check(DeathBeamCut.Bottom(0,10,0,0,0,1,2000,3.2f,0,1900,10,out bottom),"2km excavation follows beam reach");
  Check(!DeathBeamCut.Bottom(0,-10,0,0,0,1,2000,2,0,100,0,out bottom),"buried beam cannot automatically trench untouched surface");
  Check(DeathBeamCut.LowerDelta(-100,0,-8,-9)==-101&&DeathBeamCut.LowerDelta(-100,0,-8,0)==-100,"clipped existing terrain delta is never raised");
  var map=new Heightmap();map.compiler.m_levelDelta[0]=-6;map.compiler.m_modifiedHeight[0]=true;Heightmap.maps.Add(map);
  DeathBeamTerrain.Excavate(new Vector3(0,0,-2),new Vector3(0,0,1),4,1);
  Check(map.compiler.saves==1&&map.rebuilds==1&&map.compiler.m_levelDelta[12]==-1,"bulk full tile save/rebuild, no pickaxe tick sequence");
  Check(map.compiler.initializeCalls==0&&map.compiler.m_levelDelta[0]==-6&&map.compiler.m_modifiedHeight[0],"existing off-beam excavation remains intact; compiler never reset");
  DeathBeamTerrain.Excavate(new Vector3(0,0,-2),new Vector3(0,0,1),4,1);
  Check(map.compiler.saves==1,"unchanged aim does not repeat terrain network writes");
  DeathBeamTerrain.Excavate(new Vector3(0,-1,-2),new Vector3(0,0,1),4,1);
  Check(map.compiler.m_levelDelta[12]==-2&&map.compiler.saves==2,"aim at lowered surface to deepen cut immediately");
  map.compiler.m_initialized=false;DeathBeamTerrain.Excavate(new Vector3(0,-2,-2),new Vector3(0,0,1),4,1);
  Check(map.compiler.saves==2&&map.compiler.initializeCalls==0,"new tile waits for native initialization instead of clearing terrain");
  map.compiler.m_initialized=true;DeathBeamTerrain.Excavate(new Vector3(0,-2,-2),new Vector3(0,0,1),4,1);
  Check(map.compiler.saves==3&&map.compiler.m_levelDelta[0]==-6&&map.compiler.m_levelDelta[12]==-3,"resumed cuts retain earlier terrain data");
  Check(DbzPower.DeathRange(false)==2000&&DbzPower.DeathRange(true)==2000&&DbzPower.Range(false)==80,"2km Death Beam range leaves Kameha unchanged");
  Console.WriteLine("PASS: 2km range, surface-contact excavation, no automatic buried trench, never raise old cuts, bulk saves and unchanged-aim dedup.");
 }
}
