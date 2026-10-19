using System;
using System.Collections;
using System.Reflection;
using UnityEngine;
namespace ValheimSoloToolkit {
 public static class UnlimitedSummonsV1 {
  public static int Enabled;
  public static string LastError;
  private static Player owner;
  const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
  internal static readonly FieldInfo Maximum=typeof(SpawnAbility).GetField("m_maxSpawned",Flags);
  internal static readonly FieldInfo FromQuality=typeof(SpawnAbility).GetField("m_setMaxInstancesFromWeaponLevel",Flags);
  internal static readonly FieldInfo Levels=typeof(SpawnAbility).GetField("m_levelUpSettings",Flags);
  internal static readonly MethodInfo Clone=typeof(System.Object).GetMethod("MemberwiseClone",Flags);
  internal static FieldInfo LevelMaximum;
  public static void Configure(Player player){
   if(Maximum==null||FromQuality==null||Levels==null||Clone==null)throw new MissingFieldException("Summon-control fields unavailable");
   Type[] args=Levels.FieldType.GetGenericArguments();
   if(args.Length!=1)throw new InvalidOperationException("Unexpected summon level settings");
   LevelMaximum=args[0].GetField("m_maxSpawns",Flags);
   if(LevelMaximum==null)throw new MissingFieldException("Summon level cap unavailable");
   owner=player;LastError=null;Enabled=1;
  }
  public static void Disable(){Enabled=0;owner=null;}
  internal static bool Owns(Character caster){return Enabled==1&&caster&&owner&&caster==owner&&owner==Player.m_localPlayer;}
  // Called before native SpawnAbility.Setup on the game thread. Only this cast is changed.
  public static void OnSetup(SpawnAbility ability,Character caster){
   if(!ability||!Owns(caster))return;
   UnlimitedSummonsStateV1 state=null;
   try{
    state=ability.GetComponent<UnlimitedSummonsStateV1>();
    if(!state)state=ability.gameObject.AddComponent<UnlimitedSummonsStateV1>();
    state.Apply(ability,caster);
   }catch(Exception error){LastError=error.Message;Disable();if(state)state.Release();}
  }
 }
 public sealed class UnlimitedSummonsStateV1:MonoBehaviour {
  private SpawnAbility ability;
  private Character caster;
  private int maximum;
  private bool fromQuality,applied;
  private object levels;
  public void Apply(SpawnAbility value,Character owner){
   if(applied)return;
   ability=value;caster=owner;
   maximum=(int)UnlimitedSummonsV1.Maximum.GetValue(value);
   fromQuality=(bool)UnlimitedSummonsV1.FromQuality.GetValue(value);
   levels=UnlimitedSummonsV1.Levels.GetValue(value);
   IList original=levels as IList;
   IList copies=original==null?null:(IList)Activator.CreateInstance(original.GetType());
   if(original!=null)foreach(object level in original){
    if(level==null){copies.Add(null);continue;}
    object copy=UnlimitedSummonsV1.Clone.Invoke(level,null);
    UnlimitedSummonsV1.LevelMaximum.SetValue(copy,0);
    copies.Add(copy);
   }
   applied=true;
   UnlimitedSummonsV1.Maximum.SetValue(value,0);
   UnlimitedSummonsV1.FromQuality.SetValue(value,false);
   if(copies!=null)UnlimitedSummonsV1.Levels.SetValue(value,copies);
  }
  public void Release(){
   if(!applied)return;
   if(ability){
    UnlimitedSummonsV1.Maximum.SetValue(ability,maximum);
    UnlimitedSummonsV1.FromQuality.SetValue(ability,fromQuality);
    UnlimitedSummonsV1.Levels.SetValue(ability,levels);
   }
   applied=false;
  }
  private void Update(){if(!UnlimitedSummonsV1.Owns(caster)){Release();Destroy(this);}}
  private void OnDestroy(){Release();}
 }
}
