using System;
using System.Collections.Generic;
namespace ValheimSoloToolkit {
 public static class TrophyBuffsV1 {
  static readonly string[] Powers={"GP_Eikthyr","GP_TheElder","GP_Bonemass","GP_Moder","GP_Yagluth","GP_Queen","GP_Ashlands","GP_DeepNorth"};
  public static string Apply(Player p,int choice){
   var manager=p.GetSEMan();if(manager==null)throw new InvalidOperationException("Player status effects are unavailable.");
   if(choice==9){foreach(var name in Powers)manager.RemoveStatusEffect(name.GetStableHashCode(),true);return "Trophy buffs removed. Other status effects are unchanged.";}
   if(choice<0||choice>8)throw new ArgumentException("Invalid trophy power.");
   if(!ObjectDB.instance)throw new InvalidOperationException("Status effect database is not ready.");
   var effects=new List<StatusEffect>();
   for(int i=0;i<Powers.Length;i++){
    if(choice!=8&&choice!=i)continue;
    var effect=ObjectDB.instance.GetStatusEffect(Powers[i].GetStableHashCode());
    if(effect)effects.Add(effect);
    else if(choice!=8)throw new InvalidOperationException("This trophy power is unavailable in the loaded game: "+Powers[i]);
   }
   if(effects.Count==0)throw new InvalidOperationException("No trophy powers found in the loaded game.");
   int added=0;
   foreach(var effect in effects)if(manager.AddStatusEffect(effect.name.GetStableHashCode(),true,0,0f,(short)-1))added++;
   if(added!=effects.Count)throw new InvalidOperationException("Applied "+added+"/"+effects.Count+" powers; the game declined the remainder.");
   var nearby=new List<Player>();Player.GetPlayersInRange(p.transform.position,10f,nearby);
   var recipients=new HashSet<Player>();int shared=0;
   foreach(var target in nearby){
    if(!target||target==p||!recipients.Add(target))continue;
    var targetManager=target.GetSEMan();if(targetManager==null)continue;
    // Match ActivateGuardianPower: hash-based AddStatusEffect routes the
    // request to a remote player's owning client. A remote null return is normal.
    foreach(var effect in effects)targetManager.AddStatusEffect(effect.name.GetStableHashCode(),true,0,0f,(short)-1);
    shared++;
   }
   return "Activated "+added+" trophy buff"+(added==1?".":"s together.")+" Shared with "+shared+" nearby player(s) within 10m via native buff requests. Native durations apply.";
  }
 }
}
