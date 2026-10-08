namespace ValheimSoloToolkit
{
    internal static class DbzPower
    {
        internal static float Scale(bool kayoken){return kayoken?2f:1f;}
        internal static float Range(bool kayoken){return kayoken?120f:80f;}
        internal static float Damage(int mode,bool kayoken)
        {
            float normal=mode==0?100f:mode==1?500f:mode==2?5000f:20000f;
            return normal*(kayoken?32f:1f);
        }
    }
}
