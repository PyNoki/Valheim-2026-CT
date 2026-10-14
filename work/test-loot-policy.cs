using System;
using ValheimSoloToolkit;
class TestLootPolicy {
 static void Check(bool value,string name){if(!value)throw new Exception(name);}
 static void Main(){
  Check(LootPolicy.Eligible(1,true,false,true,10000,100),"cheated drop at radius boundary");
  Check(!LootPolicy.Eligible(1,false,false,true,1,100),"ordinary drop excluded from cheated mode");
  Check(LootPolicy.Eligible(2,false,false,true,1,100),"ordinary drop included in all loot");
  Check(!LootPolicy.Eligible(2,true,true,true,1,100),"placed item excluded");
  Check(!LootPolicy.Eligible(2,true,false,false,1,100),"full inventory excluded");
  Check(!LootPolicy.Eligible(2,true,false,true,10001,100),"outside radius excluded");
  Check(!LootPolicy.Eligible(0,true,false,true,0,100),"disabled mode excluded");
  Console.WriteLine("PASS: cheated-only/all-loot selection, placed-item exclusion, full inventory protection and radius boundary.");
 }
}
