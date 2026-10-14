namespace ValheimSoloToolkit {
 public static class LootPolicy {
  public static bool Eligible(int mode,bool cheated,bool placed,bool hasRoom,float distanceSquared,float radius){return (mode==1||mode==2)&&(!placed)&&hasRoom&&distanceSquared<=radius*radius&&(mode==2||cheated);}
 }
}
