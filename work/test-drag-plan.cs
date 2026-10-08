using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
namespace UnityEngine {public struct Vector3 {public float x,y,z;public Vector3(float a,float b,float c){x=a;y=b;z=c;}}}
class Test {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  var floor=new List<UnityEngine.Vector3>{new UnityEngine.Vector3(-1,0,-1),new UnityEngine.Vector3(1,0,-1),new UnityEngine.Vector3(-1,0,1),new UnityEngine.Vector3(1,0,1)};
  Check(DragRowPlan.Span(floor,true)==2&&DragRowPlan.Span(floor,false)==2,"Floor edge-to-edge spacing");
  var wall=new List<UnityEngine.Vector3>{new UnityEngine.Vector3(-1,0,0),new UnityEngine.Vector3(1,0,0),new UnityEngine.Vector3(-1,2,0),new UnityEngine.Vector3(1,2,0)};
  Check(DragRowPlan.Span(wall,true)==2&&DragRowPlan.Span(wall,false)==0,"Wall thickness must not form a row axis");
  var diagonal=new List<UnityEngine.Vector3>{new UnityEngine.Vector3(0,0,0),new UnityEngine.Vector3(2,2,0)};
  Check(DragRowPlan.Span(diagonal,true)==0,"Nonmatching-height snaps accepted");
  Check(DragRowPlan.Count(0,2)==1&&DragRowPlan.Count(4,2)==3&&DragRowPlan.Count(-4,2)==3,"Anchored/reverse count");
  Check(DragRowPlan.Count(1000,1)==24&&DragRowPlan.Span(new List<UnityEngine.Vector3>(),true)==0,"Row cap/missing snaps");
  Console.WriteLine("PASS: floor/wall snap spacing, matching-height/aligned snap requirement, forward/reverse rows and 24-piece cap");
 }
}
