using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;

namespace ValheimSoloToolkit
{
    public static class BowBeamV4
    {
        public static int Enabled;
        public static int Mode;
        public static string LastError;
        private static Player owner;
        private static BowBeamVisualV4 visual;
        internal static readonly FieldInfo DrawTime = typeof(Humanoid).GetField("m_attackDrawTime", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        private static readonly MethodInfo TakeInput = typeof(Player).GetMethod("TakeInput", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        internal static bool CanInput(Player player) { return TakeInput != null && (bool)TakeInput.Invoke(player, null); }
        public static void Configure(Player player, int mode) { if(mode<0||mode>1)throw new ArgumentException("Invalid beam mode"); Mode=mode; owner = player; LastError = null; Enabled = 1; }
        // Called from CE's Mono thread: Unity cleanup is left to the driver's Update.
        public static void Disable() { Enabled = 0; owner = null; }
        internal static bool Owns(Player player) { return Enabled == 1 && player && player == owner && player == Player.m_localPlayer; }
        internal static bool IsBow(ItemDrop.ItemData weapon) { return weapon != null && weapon.m_shared.m_itemType == ItemDrop.ItemData.ItemType.Bow; }
        internal static void Fault(Exception e) { Enabled = 0; LastError = e.GetType().Name + ": " + e.Message; if (LastError.Length > 400) LastError = LastError.Substring(0, 400); }

        // Runs on the game thread in place of the local player's ordinary bow draw.
        public static bool OnBowUpdate(Player player, ItemDrop.ItemData weapon, float dt)
        {
            if (!Owns(player) || !IsBow(weapon)) return false;
            try
            {
                if (DrawTime == null) throw new MissingFieldException("Humanoid.m_attackDrawTime");
                DrawTime.SetValue(player, -1f); // No queued arrow on release or after disabling.
                if (!visual || visual.Owner != player || visual.ModeChanged)
                {
                    if (visual) UnityEngine.Object.Destroy(visual.gameObject);
                    GameObject root = new GameObject("SoloToolkit_BowBeamDriver");
                    visual = root.AddComponent<BowBeamVisualV4>();
                    visual.Setup(player);
                }
                visual.Step(weapon);
            }
            catch (Exception e) { Fault(e); if (visual) visual.Hide(); }
            return true;
        }
    }

    public sealed class BowBeamVisualV4 : MonoBehaviour
    {
        public Player Owner;
        public bool ModeChanged { get { return mode!=BowBeamV4.Mode; } }
        private GameObject effects;
        private Material material;
        private Material particleMaterial;
        private Texture2D softTexture;
        private readonly LineRenderer[] gusts = new LineRenderer[12];
        private ParticleSystem vortex;
        private float nextParticles;
        private int mode, terrainCursor;
        private Color Tint(Color c) { return mode==1 ? new Color(c.b,c.r*0.12f,c.g*0.25f,c.a) : c; }
        private LineRenderer halo, sheath, core, coilA, coilB, muzzleA, muzzleB, impactRing;
        private ParticleSystem sparks;
        private Light muzzleLight, endLight;
        private ZSyncAnimation animation;
        private string drawAnimation;
        private float lastStep, started, nextDamage;
        private bool firing;
        private const float Range = 80f;
        private const float Radius = 1.6f;
        private const float DamagePerTick = 100f;

        public void Setup(Player player)
        {
            Owner = player;mode=BowBeamV4.Mode;
            animation = player.GetComponent<ZSyncAnimation>();
            Shader shader = Shader.Find("Legacy Shaders/Particles/Additive") ?? Shader.Find("Particles/Standard Unlit") ?? Shader.Find("Sprites/Default");
            if (!shader) throw new InvalidOperationException("No compatible beam shader found");
            material = new Material(shader);
            material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
            material.SetInt("_DstBlend", (int)BlendMode.One);
            material.SetInt("_ZWrite", 0);
            material.renderQueue = 3000;
            effects = new GameObject("BeamVisuals");
            effects.transform.SetParent(transform, false);
            halo = Line("Turbulent corona", 2.4f, new Color(0.05f, 0.45f, 3f, 0.12f), 65);
            sheath = Line("Cyan plasma", 1.05f, new Color(0.2f, 3f, 5f, 0.55f), 65);
            core = Line("White hot core", 0.34f, new Color(4f, 5f, 6f, 1f), 65);
            coilA = Line("Energy helix A", 0.09f, new Color(0.3f, 3f, 5f, 0.8f), 96);
            coilB = Line("Energy helix B", 0.06f, new Color(3f, 5f, 6f, 0.75f), 96);
            muzzleA = Line("Charging ring A", 0.10f, new Color(0.1f, 3f, 5f, 0.85f), 65);
            muzzleB = Line("Charging ring B", 0.05f, new Color(3f, 5f, 6f, 0.9f), 65);
            impactRing = Line("Impact halo", 0.16f, new Color(0.2f, 4f, 6f, 0.8f), 65);
            foreach (LineRenderer arc in new LineRenderer[]{muzzleA,muzzleB,impactRing})
            {
                float width=arc.startWidth;
                arc.widthCurve = new AnimationCurve(new Keyframe(0,0),new Keyframe(0.2f,1),new Keyframe(0.7f,0.7f),new Keyframe(1,0));
                arc.widthMultiplier=width;
            }
            for(int i=0;i<gusts.Length;i++)
            {
                gusts[i]=Line("Vortex wind ribbon "+i,0.04f+(i%3)*0.025f,new Color(0.25f,0.8f,1.2f,0.28f),24);
                gusts[i].widthCurve=new AnimationCurve(new Keyframe(0,0),new Keyframe(0.35f,1),new Keyframe(1,0));
                gusts[i].widthMultiplier=0.04f+(i%3)*0.025f;
            }
            softTexture = new Texture2D(32,32,TextureFormat.RGBA32,false);
            Color[] pixels=new Color[32*32];
            for(int y=0;y<32;y++) for(int x=0;x<32;x++)
            {
                float dx=(x-15.5f)/15.5f,dy=(y-15.5f)/15.5f;
                float alpha=Mathf.Clamp01(1f-dx*dx-dy*dy);
                pixels[y*32+x]=new Color(1,1,1,alpha*alpha*alpha);
            }
            softTexture.SetPixels(pixels);softTexture.Apply();softTexture.wrapMode=TextureWrapMode.Clamp;
            particleMaterial=new Material(shader);particleMaterial.mainTexture=softTexture;
            particleMaterial.SetInt("_SrcBlend",(int)BlendMode.SrcAlpha);particleMaterial.SetInt("_DstBlend",(int)BlendMode.One);particleMaterial.SetInt("_ZWrite",0);
            GameObject swirl=new GameObject("Swirling pressure particles");swirl.transform.SetParent(effects.transform,false);
            vortex=swirl.AddComponent<ParticleSystem>();vortex.Stop(true,ParticleSystemStopBehavior.StopEmittingAndClear);
            ParticleSystem.MainModule vm=vortex.main;vm.loop=true;vm.maxParticles=360;vm.startLifetime=0.65f;
            vm.startSpeed=0;vm.startSize=0.18f;vm.simulationSpace=ParticleSystemSimulationSpace.World;
            ParticleSystem.EmissionModule ve=vortex.emission;ve.rateOverTime=0;
            ParticleSystem.NoiseModule vn=vortex.noise;vn.enabled=true;vn.strength=1.2f;vn.frequency=1.1f;vn.scrollSpeed=3f;
            ParticleSystem.ColorOverLifetimeModule vc=vortex.colorOverLifetime;vc.enabled=true;
            Gradient fade=new Gradient();fade.SetKeys(new GradientColorKey[]{new GradientColorKey(Color.white,0),new GradientColorKey(Color.white,1)},new GradientAlphaKey[]{new GradientAlphaKey(0,0),new GradientAlphaKey(1,0.12f),new GradientAlphaKey(0,1)});vc.color=fade;
            vortex.GetComponent<ParticleSystemRenderer>().sharedMaterial=particleMaterial;
            GameObject emitter = new GameObject("Impact sparks");
            emitter.transform.SetParent(effects.transform, false);
            sparks = emitter.AddComponent<ParticleSystem>();
            sparks.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            ParticleSystem.MainModule main = sparks.main;
            main.loop = true; main.startLifetime = 0.4f; main.startSpeed = 12f;
            main.startSize = 0.2f; main.startColor = Tint(new Color(0.4f, 3f, 5f, 1f));
            main.maxParticles = 160; main.simulationSpace = ParticleSystemSimulationSpace.World;
            ParticleSystem.EmissionModule emission = sparks.emission; emission.rateOverTime = 220f;
            ParticleSystem.ShapeModule shape = sparks.shape; shape.shapeType = ParticleSystemShapeType.Sphere; shape.radius = 0.35f;
            sparks.GetComponent<ParticleSystemRenderer>().sharedMaterial = particleMaterial;
            muzzleLight = MakeLight("Muzzle light", 6f); endLight = MakeLight("Impact light", 9f);
            effects.SetActive(false);
        }
        private LineRenderer Line(string name, float width, Color color, int count)
        {
            GameObject go = new GameObject(name); go.transform.SetParent(effects.transform, false);
            LineRenderer line = go.AddComponent<LineRenderer>();
            line.sharedMaterial = material; line.useWorldSpace = true; line.positionCount = count;
            line.startWidth = width; line.endWidth = width * 0.8f;
            line.startColor = Tint(color); line.endColor = Tint(color);
            line.numCapVertices = 6; line.alignment = LineAlignment.View;
            line.shadowCastingMode = ShadowCastingMode.Off; line.receiveShadows = false;
            return line;
        }
        private Light MakeLight(string name, float range)
        {
            GameObject go = new GameObject(name);go.transform.SetParent(effects.transform, false);
            Light light = go.AddComponent<Light>();light.color = Tint(new Color(0.1f,0.65f,1f));
            light.range = range;light.intensity = 3f;light.shadows = LightShadows.None;return light;
        }
        public void Hide()
        {
            if (effects) effects.SetActive(false);
            if (firing && animation && !String.IsNullOrEmpty(drawAnimation)) animation.SetBool(drawAnimation, false);
            firing = false;
        }
        private void Update()
        {
            if (!BowBeamV4.Owns(Owner)) { Hide(); Destroy(gameObject); return; }
            if (Time.time-lastStep > 0.12f || !Application.isFocused || !Input.GetMouseButton(0)
                || !BowBeamV4.CanInput(Owner) || !BowBeamV4.IsBow(Owner.GetCurrentWeapon())) Hide();
        }
        private void OnDestroy() { Hide(); if (material) Destroy(material); if(particleMaterial) Destroy(particleMaterial);if(softTexture) Destroy(softTexture); }
        public void Step(ItemDrop.ItemData weapon)
        {
            lastStep = Time.time;
            if (!Application.isFocused || !Input.GetMouseButton(0) || !BowBeamV4.CanInput(Owner)
                || Owner.IsDead() || Owner.IsTeleporting()) { Hide(); return; }
            if (!firing) { firing = true;started = Time.time;nextDamage = Time.time;nextParticles=Time.time;effects.SetActive(true);sparks.Play();vortex.Play(); }
            drawAnimation = weapon.m_shared.m_attack.m_drawAnimationState;
            if (animation && !String.IsNullOrEmpty(drawAnimation)) { animation.SetBool(drawAnimation, true); animation.SetFloat("drawpercent", 1f); }
            Vector3 anchor = Owner.GetEyePoint() - Vector3.up * 0.45f;
            Vector3 direction = Owner.GetAimDir(anchor).normalized;
            Vector3 origin = anchor + direction * 0.65f;
            float length = Range;
            int mask = LayerMask.GetMask("Default", "static_solid", "Default_small", "piece", "terrain", "vehicle");
            if(mode==0) foreach (RaycastHit hit in Physics.RaycastAll(anchor, direction, Range+0.65f, mask, QueryTriggerInteraction.Ignore))
            {
                if (!hit.collider || hit.collider.GetComponentInParent<Character>()) continue;
                if (hit.distance-0.65f < length) length = Mathf.Max(0f, hit.distance-0.65f);
            }
            if (length<=0f) { Hide(); return; }
            Vector3 end = origin + direction * length;
            Vector3 side = Vector3.Cross(direction, Vector3.up).normalized;
            if (side.sqrMagnitude < 0.01f) side = Vector3.right;
            Vector3 up = Vector3.Cross(side,direction).normalized;
            float power = Mathf.Lerp(0.2f,1f,Mathf.Clamp01((Time.time-started)/0.2f));
            float pulse = 1f + 0.16f * Mathf.Sin(Time.time*29f)+0.09f*Mathf.Sin(Time.time*67f);
            halo.startWidth = 2.4f*power*pulse; halo.endWidth=halo.startWidth*0.8f;
            sheath.startWidth=1.05f*power;sheath.endWidth=sheath.startWidth*0.8f;
            core.startWidth=0.34f*power;core.endWidth=core.startWidth*0.8f;
            for(int i=0;i<65;i++)
            {
                float t=i/64f;
                Vector3 jitter=(side*Mathf.Sin(i*1.73f-Time.time*33f)+up*Mathf.Sin(i*2.17f+Time.time*41f))*Mathf.Sin(t*Mathf.PI)*power;
                Vector3 center=Vector3.Lerp(origin,end,t);
                halo.SetPosition(i,center+jitter*0.3f);sheath.SetPosition(i,center+jitter*0.12f);core.SetPosition(i,center+jitter*0.035f);
            }
            for (int i=0;i<96;i++)
            {
                float t=i/95f;float a=t*length*1.5f-Time.time*19f+0.4f*Mathf.Sin(i*1.9f+Time.time*24f);
                Vector3 offset=(side*Mathf.Cos(a)+up*Mathf.Sin(a))*(0.7f+0.24f*Mathf.Sin(i*2.5f-Time.time*31f))*power*Mathf.Sin(t*Mathf.PI);
                Vector3 center=Vector3.Lerp(origin,end,t);
                coilA.SetPosition(i,center+offset);coilB.SetPosition(i,center-offset);
            }
            Ring(muzzleA,origin,side,up,0.6f*power);Ring(muzzleB,origin+direction*0.2f,side,up,1.0f*power);
            Ring(impactRing,end,side,up,1.4f*power*pulse);
            for(int g=0;g<gusts.Length;g++)
            {
                float travel=(Time.time*(0.65f+g*0.017f)+g*0.137f)%1f;
                for(int i=0;i<24;i++)
                {
                    float t=i/23f;
                    float a=g*2.4f-Time.time*(7f+g*0.2f)+t*2.7f;
                    float r=(2.5f-1.4f*travel)*(0.85f+0.15f*Mathf.Sin(a*3f+g));
                    float along=Mathf.Min(length,travel*9f+t*1.5f);
                    gusts[g].SetPosition(i,origin+direction*along+(side*Mathf.Cos(a)+up*Mathf.Sin(a))*r);
                }
            }
            if(Time.time>=nextParticles)
            {
                nextParticles=Time.time+0.02f;
                for(int i=0;i<8;i++)
                {
                    float a=UnityEngine.Random.Range(0f,Mathf.PI*2f),r=UnityEngine.Random.Range(0.8f,2.7f);
                    Vector3 radial=side*Mathf.Cos(a)+up*Mathf.Sin(a);
                    Vector3 tangent=up*Mathf.Cos(a)-side*Mathf.Sin(a);
                    ParticleSystem.EmitParams ep=new ParticleSystem.EmitParams();
                    ep.position=origin+radial*r+direction*UnityEngine.Random.Range(0f,Mathf.Min(length,6f));
                    ep.velocity=tangent*UnityEngine.Random.Range(6f,12f)-radial*2f+direction*UnityEngine.Random.Range(8f,18f);
                    ep.startLifetime=0.55f;ep.startSize=UnityEngine.Random.Range(0.06f,0.24f);
                    ep.startColor=Tint(new Color(0.3f,1.3f,2f,0.65f));vortex.Emit(ep,1);
                }
            }
            muzzleLight.intensity=3f*pulse;endLight.intensity=4f*pulse;
            sparks.transform.position=end;muzzleLight.transform.position=origin;endLight.transform.position=end;
            if (Time.time>=nextDamage) { nextDamage=Time.time+0.1f; if(mode==1) { BeamDamage.Death(Owner,origin,direction,length,Radius); BeamTerrain.Excavate(Owner,origin,direction,length,Radius,ref terrainCursor); } else DamageMonsters(origin,direction,length); }
        }
        private static void Ring(LineRenderer line,Vector3 center,Vector3 side,Vector3 up,float radius)
        {
            // Open, uneven arcs rather than mechanically perfect closed circles.
            for(int i=0;i<65;i++)
            {
                float t=i/64f,a=t*3.9f+Time.time*(7f+radius*2f)+radius*5f;
                float r=radius*(1f+0.18f*Mathf.Sin(i*1.7f+Time.time*35f)+0.09f*Mathf.Sin(i*3.2f-Time.time*53f));
                line.SetPosition(i,center+(side*Mathf.Cos(a)+up*Mathf.Sin(a))*r);
            }
        }
        private void DamageMonsters(Vector3 origin,Vector3 direction,float length)
        {
            foreach(Character target in Character.GetAllCharacters().ToArray())
            {
                if (!target || target.IsPlayer() || target.IsDead() || target.IsTamed()
                    || !(target.GetBaseAI() is MonsterAI) || !BaseAI.IsEnemy(Owner,target)) continue;
                Vector3 delta=target.GetCenterPoint()-origin;
                float along=Vector3.Dot(delta,direction);
                if(along<0f || along>length || (delta-direction*along).sqrMagnitude>Radius*Radius) continue;
                HitData hit=new HitData();hit.m_damage.m_lightning=DamagePerTick;
                hit.m_point=target.GetCenterPoint();hit.m_dir=direction;hit.m_pushForce=3f;
                hit.m_ranged=true;hit.m_skill=Skills.SkillType.None;hit.SetAttacker(Owner);
                target.Damage(hit);
            }
        }
    }
}
