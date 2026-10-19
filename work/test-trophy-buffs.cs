using System;
using System.Collections.Generic;
using ValheimSoloToolkit;
public static class HashExtensions {public static int GetStableHashCode(this string name){return name.GetHashCode();}}
public class StatusEffect {public string name;public float duration=300,m_ttl=300,m_time;public static implicit operator bool(StatusEffect e){return e!=null;}}
public class SE_Rested:StatusEffect {public float m_baseTTL=300,m_TTLPerComfortLevel=60;}
public class Piece {public string m_name;public int m_comfort,m_comfortGroup;public static implicit operator bool(Piece p){return p!=null;}}
public class PieceTable {public List<GameObject> m_pieces=new List<GameObject>();public static implicit operator bool(PieceTable p){return p!=null;}}
public class ItemDrop {public ItemData m_itemData=new ItemData();public class ItemData {public Shared m_shared=new Shared();}public class Shared {public PieceTable m_buildPieces;}public static implicit operator bool(ItemDrop p){return p!=null;}}
public class GameObject {public object component;public string name;public T GetComponent<T>() where T:class{return component as T;}public static implicit operator bool(GameObject p){return p!=null;}}
public class ObjectDB {
 public static ObjectDB instance=new ObjectDB();public Dictionary<int,StatusEffect> effects=new Dictionary<int,StatusEffect>();public List<GameObject> m_items=new List<GameObject>();
 public static implicit operator bool(ObjectDB db){return db!=null;}public StatusEffect GetStatusEffect(int hash){StatusEffect e;return effects.TryGetValue(hash,out e)?e:null;}
}
public class SEMan {
 public Dictionary<int,StatusEffect> active=new Dictionary<int,StatusEffect>();public int additions,requests;public bool remote;
 public StatusEffect AddStatusEffect(int hash,bool reset,int level,float skill,short flags){if(flags!=-1||!reset)throw new Exception("Use native refresh/flags");if(remote){requests++;return null;}
  StatusEffect effect;if(active.TryGetValue(hash,out effect))return effect;
  var template=ObjectDB.instance.GetStatusEffect(hash);if(template==null)return null;
  effect=new StatusEffect{name=template.name,duration=template.duration,m_ttl=template.m_ttl};additions++;active[hash]=effect;return effect;
 }
 public bool RemoveStatusEffect(int hash,bool quiet){return active.Remove(hash);}
}
public class Player {public static List<Player> players=new List<Player>();public float position;public Transform transform=new Transform();public static implicit operator bool(Player p){return p!=null;}public SEMan manager=new SEMan();public SEMan GetSEMan(){return manager;}public static void GetPlayersInRange(float center,float radius,List<Player> result){if(radius!=10)throw new Exception("Native 10m radius");foreach(var p in players)if(Math.Abs(p.position-center)<=radius)result.Add(p);}}
public class Transform {public float position;}
class TestTrophy {
 static void Check(bool ok,string why){if(!ok)throw new Exception(why);}
 static GameObject Furniture(string name,int group,int value){return new GameObject{name=name,component=new Piece{m_name=name,m_comfortGroup=group,m_comfort=value}};}
 static void Main(){
  string[] names={"GP_Eikthyr","GP_TheElder","GP_Bonemass","GP_Moder","GP_Yagluth","GP_Queen","GP_Ashlands","GP_DeepNorth"};
  foreach(var name in names)ObjectDB.instance.effects[name.GetStableHashCode()]=new StatusEffect{name=name};
  var restedTemplate=new SE_Rested{name="Rested"};ObjectDB.instance.effects["Rested".GetStableHashCode()]=restedTemplate;
  var table=new PieceTable();table.m_pieces.Add(Furniture("chair",1,2));table.m_pieces.Add(Furniture("throne",1,7));table.m_pieces.Add(Furniture("rug",2,2));table.m_pieces.Add(Furniture("banner",0,3));
  ObjectDB.instance.m_items.Add(new GameObject{component=new ItemDrop{m_itemData=new ItemDrop.ItemData{m_shared=new ItemDrop.Shared{m_buildPieces=table}}}});
  // Same table on another tool cannot double-count furniture.
  ObjectDB.instance.m_items.Add(ObjectDB.instance.m_items[0]);
  Check(TrophyRestedV1.MaximumComfort(new[]{new TrophyRestedV1.Comfort("a",0,2),new TrophyRestedV1.Comfort("a",0,3),new TrophyRestedV1.Comfort("b",1,4),new TrophyRestedV1.Comfort("c",1,7),new TrophyRestedV1.Comfort("d",2,2)})==14,"group maxima, unique ungrouped names, shelter base");
  var p=new Player();var friend=new Player{position=10,manager=new SEMan{remote=true}};var far=new Player{position=11,manager=new SEMan{remote=true}};Player.players.Add(p);Player.players.Add(friend);Player.players.Add(friend);Player.players.Add(far);
  var text=TrophyBuffsV1.Apply(p,0);Check(p.manager.active.Count==2&&p.manager.active.ContainsKey(names[0].GetStableHashCode()),"selected trophy plus Rested");
  Check(friend.manager.requests==2&&far.manager.requests==0&&p.manager.additions==2,"10m native sharing, duplicate peer and self dedup, remote null is normal");
  var rested=p.manager.active["Rested".GetStableHashCode()];Check(rested.m_ttl==1080&&restedTemplate.m_ttl==300,"max comfort duration on live instance only");
  rested.m_time=200;TrophyBuffsV1.Apply(p,0);Check(rested.m_ttl==1280,"full duration refresh after time elapsed");
  rested.m_ttl=5000;TrophyBuffsV1.Apply(p,8);Check(rested.m_ttl==5000,"does not shorten longer existing Rested");
  Check(p.manager.active.Count==9,"all eight powers coexist with Rested");
  Check(friend.manager.requests==13&&far.manager.requests==0,"all eight powers plus one Rested request per ally");
  Check(text.Contains("allies use their own comfort duration"),"status states remote duration limitation");
  p.manager.active["food".GetStableHashCode()]=new StatusEffect{name="food"};TrophyBuffsV1.Apply(p,9);Check(p.manager.active.Count==2&&p.manager.active.ContainsKey("food".GetStableHashCode())&&p.manager.active.ContainsKey("Rested".GetStableHashCode()),"remove only trophy buffs; preserve food and Rested");
  Check(friend.manager.requests==13,"remove does not change friends' buffs");
  ObjectDB.instance.effects.Remove(names[7].GetStableHashCode());TrophyBuffsV1.Apply(p,8);Check(p.manager.active.Count==9,"all mode skips unavailable power");
  int prior=p.manager.additions;bool rejected=false;try{TrophyBuffsV1.Apply(p,7);}catch(InvalidOperationException){rejected=true;}Check(rejected&&p.manager.additions==prior,"missing selected power applies nothing");
  ObjectDB.instance.effects.Remove("Rested".GetStableHashCode());rejected=false;prior=p.manager.additions;try{TrophyBuffsV1.Apply(p,0);}catch(InvalidOperationException){rejected=true;}Check(rejected&&p.manager.additions==prior,"missing Rested reports failure without applying powers");
  Console.WriteLine("PASS: trophy+Rested, maximum comfort groups/names, clone isolation, elapsed refresh, longer buff preservation, remote 10m sharing/dedup, missing effects and trophy-only removal.");
 }
}
