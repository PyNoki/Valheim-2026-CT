using System;
namespace ValheimSoloToolkit
{
    public static class BoatSupport
    {
        public static bool DryGround(float ground, float water)
        { return !float.IsNaN(ground) && !float.IsNaN(water) && ground > water + 0.25f; }
        public static float Lift(bool airborne, float ground, float water, float error, float verticalSpeed)
        {
            if (airborne || !DryGround(ground, water) || error <= -0.5f) return 0f;
            return Math.Max(-15f, Math.Min(20f, error * 18f - verticalSpeed * 8.5f + 9.81f));
        }
    }
}
