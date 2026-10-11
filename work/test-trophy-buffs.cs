using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
public static class HashExtensions {public static int GetStableHashCode(this string name){return name.GetHashCode();}}
public class StatusEffect {public string name;public float duration=300;public static implicit operator bool(StatusEffect e){return e!=null;}}
public class ObjectDB {
 public static ObjectDB instance=new ObjectDB();public Dictionary<int,StatusEffect> effects=new Dictionary<int,StatusEffect>();
 public static implicit operator bool(ObjectDB db){return db!=null;}public StatusEffect GetStatusEffect(int hash){StatusEffect e;return effects.TryGetValue(hash,out e)?e:null;}
}
public class SEMan {
 public Dictionary<int,StatusEffect> active=new Dictionary<int,StatusEffect>();public int additions,requests;public bool remote;
 public StatusEffect AddStatusEffect(int hash,bool reset,int level,float skill,short flags){if(flags!=-1)throw new Exception("Use native guardian flag");if(remote){requests++;return null;}return AddStatusEffect(ObjectDB.instance.GetStatusEffect(hash),reset,level,skill,flags);}
 public StatusEffect AddStatusEffect(StatusEffect effect,bool reset,int level,float skill,short flags){if(!reset)throw new Exception("Buff must refresh");additions++;active[effect.name.GetStableHashCode()]=effect;return effect;}
 public bool RemoveStatusEffect(int hash,bool quiet){return active.Remove(hash);}
}
public class Player {public static List<Player> players=new List<Player>();public float position;public Transform transform=new Transform();public static implicit operator bool(Player p){return p!=null;}public SEMan manager=new SEMan();public SEMan GetSEMan(){return manager;}public static void GetPlayersInRange(float center,float radius,List<Player> result){if(radius!=10)throw new Exception("Native 10m radius");foreach(var p in players)if(Math.Abs(p.position-center)<=radius)result.Add(p);}}
public class Transform {public float position;}
class TestTrophy {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static void Main(){
  string[] names={"GP_Eikthyr","GP_TheElder","GP_Bonemass","GP_Moder","GP_Yagluth","GP_Queen","GP_Ashlands","GP_DeepNorth"};
  foreach(var name in names)ObjectDB.instance.effects[name.GetStableHashCode()]=new StatusEffect{name=name};
  var p=new Player();var friend=new Player{position=10,manager=new SEMan{remote=true}};var far=new Player{position=11,manager=new SEMan{remote=true}};Player.players.Add(p);Player.players.Add(friend);Player.players.Add(friend);Player.players.Add(far);
  TrophyBuffsV1.Apply(p,0);Check(p.manager.active.Count==1&&p.manager.active.ContainsKey(names[0].GetStableHashCode()),"selected trophy only");
  Check(friend.manager.requests==1&&far.manager.requests==0&&p.manager.additions==1,"10m native sharing, duplicate peer and self dedup, remote null is success");
  TrophyBuffsV1.Apply(p,8);Check(p.manager.active.Count==8&&p.manager.additions==9,"all eight powers coexist, including selected refresh");
  Check(friend.manager.requests==9&&far.manager.requests==0,"all eight powers shared with nearby friend");
  foreach(var effect in p.manager.active.Values)Check(effect.duration==300,"native duration unchanged");
  p.manager.active["food".GetStableHashCode()]=new StatusEffect{name="food"};TrophyBuffsV1.Apply(p,9);Check(p.manager.active.Count==1&&p.manager.active.ContainsKey("food".GetStableHashCode()),"remove only trophy buffs");
  Check(friend.manager.requests==9,"remove does not change friends' buffs");
  ObjectDB.instance.effects.Remove(names[7].GetStableHashCode());TrophyBuffsV1.Apply(p,8);Check(p.manager.active.Count==8,"all mode skips missing power but retains food");
  int prior=p.manager.additions;bool rejected=false;try{TrophyBuffsV1.Apply(p,7);}catch(InvalidOperationException){rejected=true;}Check(rejected&&p.manager.additions==prior,"missing selected power causes no extra effect");
  Console.WriteLine("PASS: selected/all eight trophy powers, refresh/native durations, missing power handling and trophy-only removal.");
 }
}
