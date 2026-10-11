namespace ValheimSoloToolkit
{
    // Track physical press edges across render and physics frames. A held key
    // never repeats, while separate taps queue independently without a cooldown.
    public sealed class BoatJumpInput
    {
        bool held;
        int pending;
        public void Sample(bool down, bool allowed)
        {
            if (!allowed) pending = 0;
            else if (down && !held && pending < 8) pending++;
            held = down;
        }
        public bool Consume() { if (pending == 0) return false; pending--; return true; }
        public void Clear() { pending = 0; }
    }
}
