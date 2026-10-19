using System;
using System.Reflection;
using UnityEngine;
using ValheimSoloToolkit;
public class Tests {
 static void Check(bool value,string message){if(!value)throw new Exception(message);}
 static void Call(string name){typeof(BoatFunDriverV5).GetMethod(name,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(BoatFunV5.Driver,null);}
 static Ship Boat(){var go=new GameObject("boat");go.AddComponent<Rigidbody>();go.AddComponent<ZNetView>();go.AddComponent<WearNTear>();return go.AddComponent<Ship>();}
 public static void Main(){
  var p=new GameObject("player").AddComponent<Player>();Player.m_localPlayer=p;var boat=Boat();var other=Boat();var wear=boat.GetComponent<WearNTear>();var body=boat.GetComponent<Rigidbody>();p.controlled=boat;Ship.local=boat;
  Check(BoatFunV5.NoDamage,"Durability protection not default");BoatFunV5.Toggle(p);Call("FixedUpdate");
  for(int i=0;i<10;i++)Check(!wear.Damage(1000),"Native damage/wear was not blocked");
  Check(wear.health==137&&other.GetComponent<WearNTear>().Damage(10)&&other.GetComponent<WearNTear>().health==127,"Protection changed health or leaked to another boat");
  Check(body.linearVelocity.z>0&&boat.m_sailForceFactor==0&&boat.m_waterImpactDamage==0,"Original motor or impact protection failed");
  Input.keys.Add(KeyCode.LeftControl);Call("Update");Call("FixedUpdate");Check(body.linearVelocity.y==22,"Original jump failed");body.linearVelocity.y=0;Call("Update");Call("FixedUpdate");Check(body.linearVelocity.y==0,"Held jump repeated");Input.keys.Clear();Call("Update");
  InventoryGui.visible=true;Call("FixedUpdate");Check(BoatFunV5.Protects(wear),"Opening inventory removed boat protection");InventoryGui.visible=false;
  p.controlled=null;Call("FixedUpdate");Check(BoatFunV5.Protects(wear),"Seated rider lost boat protection");p.controlled=boat;
  BoatFunV5.SetOptions(0);Call("FixedUpdate");Check(wear.Damage(10)&&wear.health==127&&boat.m_waterImpactDamage==7&&boat.m_upsideDownDmg==8,"Disabling protection failed to restore damage");BoatFunV5.SetOptions(1);Call("FixedUpdate");Check(!wear.Damage(1000)&&wear.health==127,"Re-enabling healed or failed to protect boat");
  bool bad=false;try{BoatFunV5.SetOptions(2);}catch(ArgumentException){bad=true;}Check(bad&&BoatFunV5.NoDamage,"Invalid option changed protection");
  var view=boat.GetComponent<ZNetView>();view.owned=false;Call("FixedUpdate");Check(!BoatFunV5.Protects(wear)&&boat.m_sailForceFactor==1,"Ownership loss retained local physics/protection");view.owned=true;Call("FixedUpdate");Check(BoatFunV5.Protects(wear),"Native ownership recovery failed");
  BoatFunV5.Stop();Call("FixedUpdate");Check(!BoatFunV5.Driver&&!BoatFunV5.Protects(wear)&&boat.m_sailForceFactor==1&&boat.m_dampingSideway==2&&boat.m_waterImpactDamage==7&&boat.m_upsideDownDmg==8&&wear.health==127,"Stop did not restore exact values or inventory/health");
  BoatFunV5.Toggle(p);Call("FixedUpdate");ZNet.instance=new ZNet();Check(!BoatFunV5.Protects(wear),"Protection crossed network session");Call("FixedUpdate");Check(!BoatFunV5.Driver&&boat.m_sailForceFactor==1,"World/session cleanup failed");
  BoatFunV5.Toggle(p);Call("FixedUpdate");p.dead=true;Call("FixedUpdate");Check(!BoatFunV5.Driver&&!BoatFunV5.Protects(wear)&&boat.m_sailForceFactor==1,"Death cleanup failed");
  System.Console.WriteLine("PASS: default boat durability, native damage/wear rejection, other-boat isolation, live options without healing, original jump/motor, inventory/passenger retention, ownership recovery and exact stop/world/death restoration");
 }
}
