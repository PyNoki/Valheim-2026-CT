using System;
using System.Collections.Generic;
using UnityEngine;
namespace ValheimSoloToolkit
{
    internal static class DragRowPlan
    {
        internal static int Count(float distance,float spacing){return Math.Max(1,Math.Min(24,(int)Math.Floor(Math.Abs(distance)/spacing+0.5f)+1));}
        internal static float Span(List<Vector3> points,bool x)
        {
            float best=0;
            foreach(var a in points)foreach(var b in points)
            {
                if(Math.Abs(a.y-b.y)>0.02f||Math.Abs(x?a.z-b.z:a.x-b.x)>0.02f)continue;
                best=Math.Max(best,Math.Abs(x?a.x-b.x:a.z-b.z));
            }
            return best;
        }
    }
}
