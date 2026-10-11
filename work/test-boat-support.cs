using System;
using ValheimSoloToolkit;
class TestBoatSupport {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  Check(BoatSupport.Lift(false,-1,0,5,-22)==0,"submerged terrain must never push boat up");
  Check(BoatSupport.Lift(false,0.1f,0,5,-22)==0,"shoreline waves must not activate land lift");
  Check(BoatSupport.Lift(true,10,0,2,-5)==0,"airborne jump must have no land spring");
  Check(BoatSupport.Lift(false,10,0,0,0)>0,"dry land supports gravity");
  Check(BoatSupport.Lift(false,10,0,1,5)<BoatSupport.Lift(false,10,0,1,0),"upward movement is damped");
  float y=1,v=0;
  for(int i=0;i<2000;i++){float error=-y;float a=BoatSupport.Lift(false,10,0,error,v)-9.81f;v+=a*0.02f;y+=v*0.02f;}
  Check(Math.Abs(y)<0.01f && Math.Abs(v)<0.01f,"land suspension settles instead of endless bounce");
  Console.WriteLine("PASS: no lift in water, shoreline or air; damped dry-land support settles.");
 }
}
