using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ValheimSoloToolkit
{
    public sealed class DbzBombV2:MonoBehaviour
    {
        public Player Owner;
        public int Mode;
        public int Generation;
        private bool held, flying, exploding, boosted;
        private float born, detonated, nextWork;
        private Vector3 position, direction, center;
        private GameObject orb;
        private readonly List<Material> materials=new List<Material>();
        private readonly List<LineRenderer> rings=new List<LineRenderer>();
        private Light glow;
        private Collider[] targets;
        private int targetCursor, terrainCursor;
        private List<BombPlan.Point> crater;
        private readonly HashSet<IDestructible> hit=new HashSet<IDestructible>();
        private float Radius {get{return BombPlan.Radius(Mode)*DbzPower.Scale(boosted);}}
        public void Fire()
        {
            if(held)return;
            held=true;
            if(flying||exploding||!InputAllowed())return;
            boosted=BowBeamV6.Kayoken==1;
            direction=Owner.GetAimDir(Owner.GetEyePoint()).normalized;
            position=Owner.GetEyePoint()+direction*10f+Vector3.up*4f;
            born=Time.time;flying=true;
            BuildVisual();
            BowBeamV6.Status=(Mode==3?"Supernova":"Spirit Bomb")+" in flight. Impact or 20 seconds detonates; toggle OFF cancels.";
        }
        private bool InputAllowed()
        {
            return Owner&&Owner.enabled&&!Owner.IsDead()&&!Owner.IsTeleporting()&&Application.isFocused
                &&BowBeamV6.CanInput(Owner)&&!InventoryGui.IsVisible()&&!Menu.IsVisible()&&!Console.IsVisible()
                &&!Minimap.IsOpen()&&!(Chat.instance&&Chat.instance.HasFocus());
        }
        private Material MakeMaterial(Color color)
        {
            var shader=Shader.Find("Legacy Shaders/Particles/Additive")??Shader.Find("Sprites/Default");
            if(!shader)throw new InvalidOperationException("DBZ sphere shader unavailable.");
            var m=new Material(shader);m.color=color;m.SetInt("_SrcBlend",(int)BlendMode.SrcAlpha);
            m.SetInt("_DstBlend",(int)BlendMode.One);m.SetInt("_ZWrite",0);m.renderQueue=3000;
            materials.Add(m);return m;
        }
        private void BuildVisual()
        {
            orb=new GameObject(Mode==3?"Supernova":"Spirit Bomb");orb.transform.position=position;
            var hot=Mode==3?new Color(3f,0.7f,0.06f,0.55f):new Color(1.5f,3f,5f,0.55f);
            var corona=Mode==3?new Color(2f,0.05f,0.4f,0.18f):new Color(0.1f,0.8f,3f,0.18f);
            for(int i=0;i<3;i++)
            {
                var ball=GameObject.CreatePrimitive(PrimitiveType.Sphere);ball.transform.SetParent(orb.transform,false);
                var collider=ball.GetComponent<Collider>();collider.enabled=false;Destroy(collider);
                ball.transform.localScale=Vector3.one*(1f+i*0.3f);
                var renderer=ball.GetComponent<Renderer>();renderer.sharedMaterial=MakeMaterial(i==0?hot:corona);
                renderer.shadowCastingMode=ShadowCastingMode.Off;renderer.receiveShadows=false;
            }
            for(int i=0;i<7;i++)
            {
                var go=new GameObject("Energy orbit "+i);go.transform.SetParent(orb.transform,false);
                var line=go.AddComponent<LineRenderer>();line.useWorldSpace=true;line.positionCount=65;
                line.sharedMaterial=MakeMaterial(i%2==0?hot:corona);line.startWidth=0.15f;line.endWidth=0.15f;
                line.shadowCastingMode=ShadowCastingMode.Off;line.receiveShadows=false;rings.Add(line);
            }
            glow=orb.AddComponent<Light>();glow.color=Mode==3?new Color(1f,0.2f,0.02f):new Color(0.2f,0.65f,1f);
            glow.intensity=4;glow.range=45;glow.shadows=LightShadows.None;
        }
        private void Animate()
        {
            if(!orb)return;
            float size=(Mode==3?18f:12f)*DbzPower.Scale(boosted);
            if(exploding)size=Mathf.Lerp(size,Radius*2f,Mathf.Clamp01((Time.time-detonated)/3f));
            else size*=1f+0.04f*Mathf.Sin(Time.time*7f);
            orb.transform.position=position;orb.transform.localScale=Vector3.one*size;
            float fade=exploding?Mathf.Clamp01(1f-(Time.time-detonated)/6f):1f;
            for(int i=0;i<materials.Count;i++){var c=materials[i].color;c.a=(i==0?0.55f:0.18f)*fade;materials[i].color=c;}
            for(int ring=0;ring<rings.Count;ring++)for(int i=0;i<65;i++)
            {
                float a=i*Mathf.PI*2f/64f+Time.time*(ring%2==0?1f:-1f);
                var offset=new Vector3(Mathf.Cos(a),0,Mathf.Sin(a))*(size*(0.65f+ring*0.025f));
                rings[ring].SetPosition(i,position+Quaternion.Euler(ring*27f,Time.time*12f,ring*31f)*offset);
            }
            glow.intensity=4f*fade;glow.range=Mathf.Min(100f,size*3f);
        }
        private void Detonate()
        {
            flying=false;exploding=true;detonated=Time.time;center=position;
            // Snapshot once; actual damage and terrain work are bounded per update.
            targets=Physics.OverlapSphere(center,Radius,~0,QueryTriggerInteraction.Ignore);
            crater=BombPlan.Crater(Radius);targetCursor=0;terrainCursor=0;hit.Clear();
        }
        private void WorkBlast()
        {
            if(Time.time<nextWork)return;nextWork=Time.time+0.05f;
            for(int i=0;i<BombPlan.DamageBudget&&targetCursor<targets.Length;i++,targetCursor++)
                BeamDamage.Hit(Owner,targets[targetCursor],center,Vector3.up,DbzPower.Damage(Mode,boosted),hit);
            for(int i=0;i<BombPlan.TerrainBudget&&terrainCursor<crater.Count;i++,terrainCursor++)
            {
                var offset=crater[terrainCursor];var point=center+new Vector3(offset.X,0,offset.Z);
                float height;if(!Heightmap.GetHeight(point,out height))continue;
                // Do not excavate remote ground beneath an airborne explosion.
                if((height-center.y)*(height-center.y)+offset.X*offset.X+offset.Z*offset.Z>Radius*Radius)continue;
                point.y=height;BeamTerrain.Dig(Owner,point);
            }
            BowBeamV6.Status=(Mode==3?"Supernova":"Spirit Bomb")+" blast: objects "+targetCursor+"/"+targets.Length+", terrain "+terrainCursor+"/"+crater.Count+". Toggle OFF cancels remaining work.";
            if(targetCursor>=targets.Length&&terrainCursor>=crater.Count&&Time.time-detonated>6f)
            {exploding=false;ClearVisual();targets=null;crater=null;hit.Clear();BowBeamV6.Status="Blast complete. Release and click bow attack to launch again.";}
        }
        private void Update()
        {
            try
            {
                if(!BowBeamV6.Owns(Owner)||BowBeamV6.Mode!=Mode||BowBeamV6.Generation!=Generation||!Owner||Owner.IsDead()||Owner.IsTeleporting())
                {Destroy(gameObject);return;}
                if(!Input.GetMouseButton(0))held=false;
                if(!InputAllowed())return;
                if(flying)
                {
                    float distance=BombPlan.Speed(Mode)*Mathf.Min(Time.deltaTime,0.1f);
                    float nearest=distance;bool collision=false;
                    foreach(var contact in Physics.SphereCastAll(position,2f*DbzPower.Scale(boosted),direction,distance,~0,QueryTriggerInteraction.Ignore))
                    {
                        if(!contact.collider||contact.collider.GetComponentInParent<Character>()==Owner)continue;
                        if(contact.distance<=nearest){nearest=contact.distance;collision=true;}
                    }
                    position+=direction*nearest;
                    // Also detect starting inside a hillside or another solid object.
                    foreach(var c in Physics.OverlapSphere(position,2f*DbzPower.Scale(boosted),~0,QueryTriggerInteraction.Ignore))
                        if(c&&c.GetComponentInParent<Character>()!=Owner){collision=true;break;}
                    if(collision||Time.time-born>=20f)Detonate();
                }
                if(exploding)WorkBlast();
                Animate();
            }
            catch(Exception e){BowBeamV6.Fault(e);Destroy(gameObject);}
        }
        private void ClearVisual()
        {
            if(orb)Destroy(orb);orb=null;rings.Clear();foreach(var m in materials)if(m)Destroy(m);materials.Clear();
        }
        private void OnDestroy(){ClearVisual();targets=null;crater=null;hit.Clear();}
    }
}
