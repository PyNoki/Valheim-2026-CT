using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
class BombTests
{
    static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
    static void Main()
    {
        Check(BombPlan.Radius(2)==40&&BombPlan.Radius(3)==120,"Blast sizes");
        Check(BombPlan.Speed(3)<BombPlan.Speed(2)&&BombPlan.Speed(2)<10,"Slow travel");
        foreach(int mode in new[]{2,3})
        {
            float radius=BombPlan.Radius(mode),previous=-1;
            var cells=BombPlan.Crater(radius);var unique=new HashSet<string>();
            Check(cells.Count>500&&cells.Count<6000,"Bounded loaded-area work");
            foreach(var p in cells)
            {
                float distance=p.X*p.X+p.Z*p.Z;
                Check(distance<=radius*radius&&distance>=previous,"Radial order/boundary");previous=distance;
                Check(unique.Add(p.X+","+p.Z),"Duplicate terrain edit");
            }
            Check(cells[0].X==0&&cells[0].Z==0&&previous>=(radius-3)*(radius-3),"Center/edge coverage");
            int processed=0;
            while(processed<cells.Count){int batch=Math.Min(BombPlan.TerrainBudget,cells.Count-processed);Check(batch<=6,"Unbounded terrain batch");processed+=batch;}
            Check(processed==cells.Count&&BombPlan.DamageBudget==48,"Budget completion");
        }
        Console.WriteLine("PASS: Spirit Bomb/Supernova sizes, slow speeds, bounded unique radial crater coverage, per-update work budgets");
    }
}
