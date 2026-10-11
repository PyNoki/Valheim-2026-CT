using System;
using ValheimSoloToolkit;
class TestBoatJump {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  var input=new BoatJumpInput();
  input.Sample(true,true);Check(input.Consume(),"first press jumps");
  for(int i=0;i<100;i++){input.Sample(true,true);Check(!input.Consume(),"holding must not repeat");}
  input.Sample(false,true);input.Sample(true,true);Check(input.Consume(),"immediate second tap jumps without cooldown");
  input.Sample(false,true);input.Sample(true,true);input.Sample(false,true);input.Sample(true,true);
  Check(input.Consume()&&input.Consume()&&!input.Consume(),"rapid taps between physics frames preserved exactly once");
  input.Sample(false,true);input.Sample(true,true);input.Sample(true,false);Check(!input.Consume(),"menu/control loss clears queued jump");
  input.Sample(true,true);Check(!input.Consume(),"returning while held does not jump");
  input.Sample(false,true);input.Sample(true,true);input.Clear();Check(!input.Consume(),"disable clears request");
  Console.WriteLine("PASS: one jump per tap, no hold repeat, no cooldown, rapid taps and stale-input cleanup.");
 }
}
