using System;
using System.Collections.Generic;

namespace ValheimSoloToolkit
{
    internal static class BombPlan
    {
        internal const int DamageBudget=48, TerrainBudget=6;
        internal static float Radius(int mode){return mode==3?120f:40f;}
        internal static float Speed(int mode){return mode==3?6f:9f;}
        internal struct Point {internal float X,Z;internal Point(float x,float z){X=x;Z=z;}}
        internal static List<Point> Crater(float radius)
        {
            var points=new List<Point>();
            const float spacing=3f;
            int steps=(int)Math.Ceiling(radius/spacing);
            for(int x=-steps;x<=steps;x++)for(int z=-steps;z<=steps;z++)
                if(x*x*spacing*spacing+z*z*spacing*spacing<=radius*radius)
                    points.Add(new Point(x*spacing,z*spacing));
            points.Sort(delegate(Point a,Point b){return (a.X*a.X+a.Z*a.Z).CompareTo(b.X*b.X+b.Z*b.Z);});
            return points;
        }
    }
}
