using System;
using System.Collections.Generic;
using System.Reflection;
namespace ValheimSoloToolkit {
 public static class TrophyRestedV1 {
  static readonly FieldInfo TimeField=typeof(StatusEffect).GetField("m_time",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
  // Native comfort permits one of each ungrouped name and the best of each group.
  public struct Comfort {public string Name;public int Group,Value;public Comfort(string name,int group,int value){Name=name;Group=group;Value=value;}}
  public static int MaximumComfort(IEnumerable<Comfort> pieces){
   var groups=new Dictionary<int,int>();var names=new Dictionary<string,int>(StringComparer.Ordinal);
   foreach(var piece in pieces){if(piece.Value<=0)continue;var map=piece.Group==0?names:null;
    if(map!=null){int prior;map.TryGetValue(piece.Name,out prior);map[piece.Name]=Math.Max(prior,piece.Value);}
    else {int prior;groups.TryGetValue(piece.Group,out prior);groups[piece.Group]=Math.Max(prior,piece.Value);}
   }
   int total=2;foreach(var value in groups.Values)total+=value;foreach(var value in names.Values)total+=value;return total;
  }
  public static float Apply(Player player){
   if(TimeField==null)throw new MissingFieldException("Rested timer is unavailable.");
   if(!ObjectDB.instance)throw new InvalidOperationException("Status effect database is unavailable.");
   var template=ObjectDB.instance.GetStatusEffect("Rested".GetStableHashCode()) as SE_Rested;
   if(!template)throw new InvalidOperationException("Native Rested effect is unavailable.");
   var pieces=new List<Comfort>();var seen=new HashSet<string>(StringComparer.Ordinal);
   foreach(var item in ObjectDB.instance.m_items){
    var drop=item?item.GetComponent<ItemDrop>():null;var table=drop?drop.m_itemData.m_shared.m_buildPieces:null;
    if(!table)continue;
    foreach(var prefab in table.m_pieces){var piece=prefab?prefab.GetComponent<Piece>():null;
     if(piece&&piece.m_comfort>0&&seen.Add(prefab.name))pieces.Add(new Comfort(piece.m_name,(int)piece.m_comfortGroup,piece.m_comfort));
    }
   }
   if(pieces.Count==0)throw new InvalidOperationException("Comfort build pieces are not ready.");
   float duration=template.m_baseTTL+(MaximumComfort(pieces)-1)*template.m_TTLPerComfortLevel;
   var effect=player.GetSEMan().AddStatusEffect(template.name.GetStableHashCode(),true,0,0f,(short)-1);
   if(!effect)throw new InvalidOperationException("The game declined Rested.");
   // Extend only this player's live clone. Never edit ObjectDB or shorten an existing buff.
   float elapsed=(float)TimeField.GetValue(effect);effect.m_ttl=Math.Max(effect.m_ttl,elapsed+duration);
   return duration;
  }
  public static void Share(Player player){player.GetSEMan().AddStatusEffect("Rested".GetStableHashCode(),true,0,0f,(short)-1);}
 }
}
