using System;
using UnityEngine;
using UnityEngine.Rendering;
namespace ValheimSoloToolkit
{
    public sealed class KayokenAuraV1:MonoBehaviour
    {
        public Player Owner;
        private Material material;
        private Texture2D texture;
        private readonly Transform[] shells=new Transform[3];
        private ParticleSystem flames;
        private Light glow;
        internal void Setup(Player player)
        {
            Owner=player;
            var shader=Shader.Find("Legacy Shaders/Particles/Additive")??Shader.Find("Sprites/Default");
            if(!shader)throw new InvalidOperationException("Kayoken aura shader unavailable.");
            texture=new Texture2D(32,32,TextureFormat.RGBA32,false);
            var pixels=new Color[1024];
            for(int y=0;y<32;y++)for(int x=0;x<32;x++){float dx=(x-15.5f)/15.5f,dy=(y-15.5f)/15.5f;float a=Mathf.Clamp01(1-dx*dx-dy*dy);pixels[y*32+x]=new Color(1,1,1,a*a*a);}
            texture.SetPixels(pixels);texture.Apply();texture.wrapMode=TextureWrapMode.Clamp;
            material=new Material(shader);material.mainTexture=texture;
            material.SetInt("_SrcBlend",(int)BlendMode.SrcAlpha);material.SetInt("_DstBlend",(int)BlendMode.One);material.SetInt("_ZWrite",0);
            var red=new Color(4f,.015f,.025f,.2f);material.color=red;
            if(material.HasProperty("_TintColor"))material.SetColor("_TintColor",red);material.renderQueue=3000;
            for(int i=0;i<shells.Length;i++)
            {
                var go=GameObject.CreatePrimitive(PrimitiveType.Sphere);go.name="Kayoken red pressure shell";go.transform.SetParent(transform,false);
                var collider=go.GetComponent<Collider>();collider.enabled=false;Destroy(collider);
                var renderer=go.GetComponent<Renderer>();renderer.sharedMaterial=material;renderer.shadowCastingMode=ShadowCastingMode.Off;renderer.receiveShadows=false;shells[i]=go.transform;
            }
            var emitter=new GameObject("Kayoken rising flames");emitter.transform.SetParent(transform,false);
            flames=emitter.AddComponent<ParticleSystem>();flames.Stop(true,ParticleSystemStopBehavior.StopEmittingAndClear);
            var main=flames.main;main.loop=true;main.maxParticles=300;main.startLifetime=.7f;main.startSpeed=0;main.startSize=.65f;
            main.startColor=new Color(5f,.02f,.04f,.8f);main.simulationSpace=ParticleSystemSimulationSpace.World;
            var emission=flames.emission;emission.rateOverTime=180;
            var shape=flames.shape;shape.shapeType=ParticleSystemShapeType.Sphere;shape.radius=.85f;
            var velocity=flames.velocityOverLifetime;velocity.enabled=true;velocity.space=ParticleSystemSimulationSpace.World;velocity.y=4f;
            var noise=flames.noise;noise.enabled=true;noise.strength=.8f;noise.frequency=2f;noise.scrollSpeed=4f;
            var fade=flames.colorOverLifetime;fade.enabled=true;var gradient=new Gradient();
            gradient.SetKeys(new[]{new GradientColorKey(Color.white,0),new GradientColorKey(Color.red,1)},new[]{new GradientAlphaKey(0,0),new GradientAlphaKey(1,.1f),new GradientAlphaKey(0,1)});fade.color=gradient;
            flames.GetComponent<ParticleSystemRenderer>().sharedMaterial=material;flames.Play();
            glow=gameObject.AddComponent<Light>();glow.color=new Color(1,.01f,.02f);glow.range=12;glow.intensity=6;glow.shadows=LightShadows.None;
            Follow();
        }
        private void Follow()
        {
            transform.position=Owner.transform.position+Vector3.up;
            float pulse=1+.13f*Mathf.Sin(Time.time*19f)+.06f*Mathf.Sin(Time.time*43f);
            for(int i=0;i<shells.Length;i++)shells[i].localScale=new Vector3(1.25f+i*.3f,2.2f+i*.3f,1.25f+i*.3f)*pulse;
            glow.intensity=6*pulse;
        }
        private void Update()
        {
            if(!BowBeamV6.Owns(Owner)||BowBeamV6.Kayoken!=1||Owner.IsDead()||Owner.IsTeleporting()){Destroy(gameObject);return;}
            Follow();
        }
        private void OnDestroy(){if(material)Destroy(material);if(texture)Destroy(texture);}
    }
}
