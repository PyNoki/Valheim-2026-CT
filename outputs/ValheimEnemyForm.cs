using System;
using System.Collections.Generic;
using System.Collections;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class EnemyFormV11
    {
        public static int Enabled;
        public static string Status, LastError;
        internal static Player Owner;
        internal static int Generation, Choice, Stars;
        internal static bool CycleRequested;
        internal static bool MonsterAllegiance, Duel;
        internal static float MovementSpeed=1f, JumpForce=1f;
        internal static EnemyFormDriverV11 Driver;
        internal const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        internal static readonly MethodInfo CameraLook=typeof(PlayerController).GetMethod("LateUpdate",Flags);
        internal static readonly MethodInfo EyeRotation=typeof(Player).GetMethod("UpdateEyeRotation",Flags);
        internal static readonly MethodInfo CanInput=typeof(Player).GetMethod("TakeInput",Flags);
        internal static readonly FieldInfo SkipTarget=typeof(Character).GetField("m_aiSkipTarget",Flags);
        public static void Configure(Player player,int form,int stars)
        {
            if(form<0||form>=EnemyFormDriverV11.Forms.Length)throw new ArgumentException("Choose a supported enemy form.");
            if(stars<0||stars>2)throw new ArgumentException("Choose 0, 1 or 2 stars.");
            if(CameraLook==null||EyeRotation==null||CanInput==null||SkipTarget==null)throw new MissingMemberException("Enemy form control methods unavailable.");
            Owner=player;Choice=form;Stars=stars;Generation++;CycleRequested=false;LastError=null;Enabled=1;Status="Queued. Return to the game and unpause to transform.";
        }
        public static void SetOptions(int monster,int duel)
        {
            if((monster!=0&&monster!=1)||(duel!=0&&duel!=1))throw new ArgumentException("Options must be 0 or 1.");
            MonsterAllegiance=monster==1;Duel=duel==1;
        }
        public static void SetMovement(float speed,float jump)
        {
            if(float.IsNaN(speed)||speed<0.1f||speed>20f||float.IsNaN(jump)||jump<0.1f||jump>10f)
                throw new ArgumentException("Speed must be 0.1-20 and jump must be 0.1-10.");
            MovementSpeed=speed;JumpForce=jump;
        }
        // Called by Cheat Engine. Unity restoration runs on the next game update.
        public static void Disable(){Enabled=0;CycleRequested=false;Status="Returning to player on the next game update.";}
        public static void NextWeapon(){if(Enabled==1)CycleRequested=true;}
        // Prefix of Projectile.Setup: tune only projectiles fired by this form,
        // before their first physics update. No projectile prefab assets are edited.
        public static void TuneProjectile(Projectile projectile,Character owner)
        {
            try {if(Driver&&Owns(Owner)&&Driver.IsBody(owner))Driver.TuneProjectile(projectile);}
            catch(Exception e){Fault(e);}
        }
        internal static bool Owns(Player player){return Enabled==1&&player&&player==Owner&&player==Player.m_localPlayer;}
        internal static void Fault(Exception e){LastError=e.GetBaseException().Message;Enabled=0;Status="Enemy form stopped: "+LastError;}
        // Camera keeps updating while the original Player component is suspended.
        public static void Tick(GameCamera camera)
        {
            if(Enabled!=1)return;
            try
            {
                if(!Owns(Owner)){Disable();return;}
                if(Driver&&(Driver.Owner!=Owner||Driver.Generation!=Generation)){Driver.Restore();UnityEngine.Object.Destroy(Driver.gameObject);Driver=null;}
                if(!Driver)
                {
                    Driver=new GameObject("SoloToolkit_EnemyForm").AddComponent<EnemyFormDriverV11>();
                    Driver.Owner=Owner;Driver.Generation=Generation;Driver.Setup(Choice,Stars);
                }
                Driver.Step();
                Driver.ApplyCamera(camera);
            }
            catch(Exception e){Fault(e);if(Driver)Driver.Restore();}
        }
    }

    public sealed class EnemyFormDriverV11:MonoBehaviour
    {
        public Player Owner;
        internal int Generation;
        internal static readonly string[] Forms={"Greydwarf","Skeleton","Draugr","Wolf","Troll","Serpent","Greyling","Neck","Greydwarf_Elite","Greydwarf_Shaman","Draugr_Elite","Draugr_Ranged","Skeleton_Poison","Blob","BlobElite","Surtling","Fenring","Fenring_Cultist","Goblin","GoblinBrute","GoblinShaman","Lox","SeekerBrood","SeekerBrute","Abomination","Asksvin","Hatchling","Dragon","StoneGolem","Seeker","Tick","Morgen","BlobTar","BlobLava","Dverger","DvergerMageFire","DvergerMageIce","DvergerMageSupport","Charred_Melee","Charred_Archer","Charred_Mage","Charred_Twitcher","Eikthyr","gd_king","Bonemass","GoblinKing","SeekerQueen","Fader"};
        private GameObject bodyObject;
        private Humanoid body;
        private PlayerController controller;
        private Rigidbody playerBody;
        private readonly Dictionary<Renderer,bool> renderers=new Dictionary<Renderer,bool>();
        private readonly Dictionary<Collider,bool> colliders=new Dictionary<Collider,bool>();
        private readonly List<ItemDrop.ItemData> weapons=new List<ItemDrop.ItemData>();
        private readonly Dictionary<Attack,bool> duelAttacks=new Dictionary<Attack,bool>();
        private readonly Dictionary<Projectile,bool[]> projectiles=new Dictionary<Projectile,bool[]>();
        private readonly List<Projectile> expiredProjectiles=new List<Projectile>();
        private Character.Faction nativeFaction;
        private static readonly string[] MovementNames={"m_speed","m_walkSpeed","m_runSpeed","m_crouchSpeed","m_swimSpeed","m_flySlowSpeed","m_flyFastSpeed","m_jumpForce"};
        private readonly FieldInfo[] movementFields=new FieldInfo[MovementNames.Length];
        private readonly float[] nativeMovement=new float[MovementNames.Length];
        private float appliedSpeed=-1f,appliedJump=-1f;
        private static readonly MethodInfo CopyShared=typeof(object).GetMethod("MemberwiseClone",BindingFlags.Instance|BindingFlags.NonPublic);
        private bool saved,restored,playerEnabled,controllerEnabled,kinematic,skipTarget;
        private Vector3 eyeLocal,returnPosition;
        private int weaponIndex;
        private float nextAttack,nextStatus;
        private int spawnFrame,formChoice,formStars;
        private float initializationDeadline;
        private bool flyer;
        private Vector3 safeReturnPosition;
        private GameCamera flightCamera;
        private static readonly string[] CameraNames={"m_distance","m_minDistance","m_maxDistance","m_flyingDistance"};
        private readonly FieldInfo[] cameraFields=new FieldInfo[CameraNames.Length];
        private readonly float[] cameraValues=new float[CameraNames.Length];
        private static int GroundMask {get{return LayerMask.GetMask("Default","static_solid","terrain","piece");}}
        internal void ApplyCamera(GameCamera camera)
        {
            if(!flyer||!saved||restored||!camera||flightCamera)return;
            // Validate every field before changing any camera setting.
            for(int i=0;i<CameraNames.Length;i++)
            {
                cameraFields[i]=typeof(GameCamera).GetField(CameraNames[i],EnemyFormV11.Flags);
                if(cameraFields[i]==null||cameraFields[i].FieldType!=typeof(float))throw new MissingFieldException("GameCamera."+CameraNames[i]);
                cameraValues[i]=(float)cameraFields[i].GetValue(camera);
            }
            flightCamera=camera;
            float distance=formChoice==27?24f:10f;
            cameraFields[0].SetValue(camera,Math.Max(distance,cameraValues[0]));
            cameraFields[2].SetValue(camera,Math.Max(distance,cameraValues[2]));
            cameraFields[3].SetValue(camera,Math.Max(distance,cameraValues[3]));
        }
        private bool GroundBelow(float distance,out RaycastHit hit)
        {
            return Physics.Raycast(body.transform.position+Vector3.up,Vector3.down,out hit,distance,GroundMask,QueryTriggerInteraction.Ignore);
        }
        private readonly Dictionary<CanvasGroup,float> hiddenUi=new Dictionary<CanvasGroup,float>();
        private readonly List<CanvasGroup> addedUi=new List<CanvasGroup>();
        private ZNet disguiseNet;
        private bool originalPublicPosition,disguiseSaved;
        private ZNetView playerView;
        private ZDO playerZdo;
        private string originalName;
        private static readonly FieldInfo PublicPosition=typeof(ZNet).GetField("m_publicReferencePosition",EnemyFormV11.Flags);
        private static readonly FieldInfo Huds=typeof(EnemyHud).GetField("m_huds",EnemyFormV11.Flags);
        private static readonly string[] MapMarkers={"m_smallMarker","m_largeMarker","m_smallShipMarker","m_largeShipMarker"};
        private void HideUi(GameObject obj)
        {
            if(!obj)return;
            var group=obj.GetComponent<CanvasGroup>();
            if(!group){group=obj.AddComponent<CanvasGroup>();addedUi.Add(group);}
            if(!hiddenUi.ContainsKey(group))hiddenUi.Add(group,group.alpha);
            group.alpha=0; // Remains invisible even if the game's HUD update reactivates it.
        }
        private void HideIdentity()
        {
            if(!disguiseSaved)
            {
                if(PublicPosition==null||Huds==null)throw new MissingFieldException("Enemy disguise HUD metadata unavailable.");
                disguiseNet=ZNet.instance;
                if(!disguiseNet)throw new InvalidOperationException("Network world unavailable.");
                originalPublicPosition=(bool)PublicPosition.GetValue(disguiseNet);
                playerView=Owner.GetComponent<ZNetView>();
                if(!playerView||!playerView.IsValid()||!playerView.IsOwner())throw new InvalidOperationException("Player name storage is not locally owned.");
                playerZdo=playerView.GetZDO();originalName=playerZdo.GetString(ZDOVars.s_playerName,"");
                disguiseSaved=true;
            }
            if(disguiseNet && disguiseNet==ZNet.instance)disguiseNet.SetPublicReferencePosition(false);
            if(playerView && playerView.IsValid() && playerView.IsOwner() && playerView.GetZDO()==playerZdo)
                playerZdo.Set(ZDOVars.s_playerName,""); // Temporary network display name, not profile/account identity.
            var map=Minimap.instance;
            if(map)foreach(var name in MapMarkers)
            {
                var field=typeof(Minimap).GetField(name,EnemyFormV11.Flags);
                if(field==null)throw new MissingFieldException("Minimap."+name);
                var marker=field.GetValue(map) as Component;if(marker)HideUi(marker.gameObject);
            }
            var hud=EnemyHud.instance;
            if(hud)
            {
                var entries=Huds.GetValue(hud) as IDictionary;
                if(entries!=null && entries.Contains(Owner))
                {
                    var entry=entries[Owner];var field=entry.GetType().GetField("m_gui",EnemyFormV11.Flags);
                    if(field!=null)HideUi(field.GetValue(entry) as GameObject);
                }
            }
        }
        private void RestoreIdentity()
        {
            foreach(var entry in hiddenUi)if(entry.Key)entry.Key.alpha=entry.Value;
            foreach(var group in addedUi)if(group)UnityEngine.Object.Destroy(group);
            hiddenUi.Clear();addedUi.Clear();
            if(disguiseSaved)
            {
                if(disguiseNet && disguiseNet==ZNet.instance)disguiseNet.SetPublicReferencePosition(originalPublicPosition);
                if(playerView && playerView.IsValid() && playerView.IsOwner() && playerView.GetZDO()==playerZdo)
                    playerZdo.Set(ZDOVars.s_playerName,originalName);
                disguiseSaved=false;
            }
        }
        public void Setup(int choice,int stars)
        {
            if(!Owner.enabled)throw new InvalidOperationException("Return from the previous enemy form and unpause before transforming again.");
            if(Owner.IsDead()||Owner.InAttack()||Owner.InDodge()||Owner.IsTeleporting())throw new InvalidOperationException("Finish your action/teleport and stand still before transforming.");
            var prefab=ZNetScene.instance.GetPrefab(Forms[choice]);
            if(!prefab||!prefab.GetComponent<Humanoid>()||!prefab.GetComponent<MonsterAI>())throw new InvalidOperationException("Enemy form unavailable: "+Forms[choice]);
            controller=Owner.GetComponent<PlayerController>();playerBody=Owner.GetComponent<Rigidbody>();
            if(!controller||!playerBody||!Owner.m_eye)throw new InvalidOperationException("Player controller, body or camera anchor unavailable.");
            returnPosition=Owner.transform.position;
            // New entries follow the two original flyers; appended ground forms
            // must not inherit flight controls just because their index is higher.
            safeReturnPosition=returnPosition;flyer=choice==26||choice==27;
            bodyObject=UnityEngine.Object.Instantiate(prefab,returnPosition+Vector3.up*0.2f,Owner.transform.rotation);
            body=bodyObject.GetComponent<Humanoid>();
            var view=bodyObject.GetComponent<ZNetView>();
            if(!view||!view.IsValid()||!view.IsOwner())throw new InvalidOperationException("The transformed body is not locally owned.");
            body.SetLevel(stars+1);
            // Only this newly spawned body loses AI. Existing enemies are untouched.
            foreach(var ai in bodyObject.GetComponents<BaseAI>())ai.enabled=false;
            // Humanoid.Start gives default/random equipment AFTER Instantiate returns.
            // Keep the real player active until Unity has initialized the new body.
            spawnFrame=Time.frameCount;initializationDeadline=Time.time+3f;formChoice=choice;formStars=stars;
            EnemyFormV11.Status="Waiting for "+Forms[choice]+" native weapons to initialize...";
        }
        private bool FinishSetup()
        {
            if(Time.frameCount<=spawnFrame)return false;
            weapons.Clear();
            foreach(var item in body.GetInventory().GetAllItems())
                if(item.HavePrimaryAttack()&&(!flyer||!item.m_shared.m_attack.m_toggleFlying))weapons.Add(item);
            // Some creatures use m_unarmedWeapon, which is not an inventory item.
            // GetCurrentWeapon exposes it; do not try to EquipItem that fallback.
            var current=body.GetCurrentWeapon();
            if(weapons.Count==0 && current!=null && current.HavePrimaryAttack()&&(!flyer||!current.m_shared.m_attack.m_toggleFlying))weapons.Add(current);
            if(weapons.Count==0)
            {
                if(Time.time<initializationDeadline)return false;
                throw new InvalidOperationException(Forms[formChoice]+" did not initialize any native attacks within 3 seconds. Your player was left unchanged.");
            }
            if(Owner.InAttack()||Owner.InDodge()||Owner.IsTeleporting())throw new InvalidOperationException("Player started an action while transforming. Stand still and try again.");
            nativeFaction=body.m_faction;
            for(int i=0;i<MovementNames.Length;i++)
            {
                movementFields[i]=typeof(Character).GetField(MovementNames[i],EnemyFormV11.Flags);
                if(movementFields[i]==null||movementFields[i].FieldType!=typeof(float))throw new MissingFieldException("Character."+MovementNames[i]);
                nativeMovement[i]=(float)movementFields[i].GetValue(body);
            }
            ApplyMovement();
            // Drakes have no walking locomotion. Moder starts grounded and can
            // take off on Jump; native Character physics handles both flyers.
            if(formChoice==26&&!body.IsFlying())body.TakeOff();
            // SharedData/Attack belong to prefab assets. Copy them before enabling
            // friendly hits, including unarmed attacks; never edit other creatures' weapons.
            foreach(var weapon in weapons)
            {
                var shared=(ItemDrop.ItemData.SharedData)CopyShared.Invoke(weapon.m_shared,null);
                if(shared.m_attack!=null){shared.m_attack=shared.m_attack.Clone();duelAttacks.Add(shared.m_attack,shared.m_attack.m_hitFriendly);}
                if(shared.m_secondaryAttack!=null){shared.m_secondaryAttack=shared.m_secondaryAttack.Clone();duelAttacks.Add(shared.m_secondaryAttack,shared.m_secondaryAttack.m_hitFriendly);}
                weapon.m_shared=shared;
            }
            ApplyOptions();
            weaponIndex=weapons.IndexOf(body.GetCurrentWeapon());
            if(weaponIndex<0){weaponIndex=0;if(!body.EquipItem(weapons[0],false))throw new InvalidOperationException("Could not equip the enemy's native weapon.");}
            playerEnabled=Owner.enabled;controllerEnabled=controller.enabled;kinematic=playerBody.isKinematic;
            skipTarget=(bool)EnemyFormV11.SkipTarget.GetValue(Owner);eyeLocal=Owner.m_eye.localPosition;saved=true;
            controller.enabled=false;Owner.enabled=false;EnemyFormV11.SkipTarget.SetValue(Owner,true);
            playerBody.linearVelocity=Vector3.zero;playerBody.angularVelocity=Vector3.zero;playerBody.isKinematic=true;
            HidePlayer();
            HideIdentity();
            EnemyFormV11.Status=Forms[formChoice]+" ("+formStars+" stars) form. Move/run/jump normally; Attack = native attack; Block = secondary; Use = cycle weapon; F8 = return.";
            return true;
        }
        private void HidePlayer()
        {
            foreach(var r in Owner.GetComponentsInChildren<Renderer>(true))
            {if(!renderers.ContainsKey(r))renderers.Add(r,r.forceRenderingOff);r.forceRenderingOff=true;}
            foreach(var c in Owner.GetComponentsInChildren<Collider>(true))
            {if(!colliders.ContainsKey(c))colliders.Add(c,c.enabled);c.enabled=false;}
        }
        private bool InputAllowed()
        {
            return Application.isFocused && (bool)EnemyFormV11.CanInput.Invoke(Owner,null)
                && !InventoryGui.IsVisible() && !Menu.IsVisible() && !Console.IsVisible() && !Minimap.IsOpen()
                && !Hud.IsPieceSelectionVisible() && !Hud.InRadial() && !(Chat.instance&&Chat.instance.HasFocus());
        }
        private void ApplyOptions()
        {
            body.m_faction=EnemyFormV11.MonsterAllegiance?nativeFaction:Character.Faction.Players;
            // Red disguise is ignored by creature target searches, including rival factions.
            EnemyFormV11.SkipTarget.SetValue(body,EnemyFormV11.MonsterAllegiance);
            foreach(var attack in duelAttacks)attack.Key.m_hitFriendly=EnemyFormV11.Duel||attack.Value;
            expiredProjectiles.Clear();
            foreach(var entry in projectiles)
            {
                if(!entry.Key){expiredProjectiles.Add(entry.Key);continue;}
                entry.Key.m_hitFriendly=EnemyFormV11.Duel||entry.Value[0];
                entry.Key.m_noDamageFriendly=!EnemyFormV11.Duel&&entry.Value[1];
            }
            foreach(var expired in expiredProjectiles)projectiles.Remove(expired);
        }
        private void ApplyMovement()
        {
            float speed=EnemyFormV11.MovementSpeed,jump=EnemyFormV11.JumpForce;
            if(speed==appliedSpeed&&jump==appliedJump)return;
            // Each form retains its own native speeds/jump, including zero values.
            // Always scale that snapshot, never already-multiplied player/body values.
            for(int i=0;i<movementFields.Length;i++)movementFields[i].SetValue(body,nativeMovement[i]*(i==movementFields.Length-1?jump:speed));
            appliedSpeed=speed;appliedJump=jump;
        }
        internal bool IsBody(Character character){return body&&character==body;}
        internal void TuneProjectile(Projectile projectile)
        {
            if(!projectile||restored)return;
            if(!projectiles.ContainsKey(projectile))projectiles.Add(projectile,new[]{projectile.m_hitFriendly,projectile.m_noDamageFriendly});
            if(EnemyFormV11.Duel){projectile.m_hitFriendly=true;projectile.m_noDamageFriendly=false;}
        }
        private void FollowBody()
        {
            returnPosition=body.transform.position;Owner.transform.position=returnPosition;
            if(flyer){RaycastHit ground;if(GroundBelow(10000f,out ground))safeReturnPosition=ground.point+Vector3.up*1.5f;}
            // Player.LateUpdate normally supplies this. It is suspended in a form;
            // moving its Transform alone leaves ZoneSystem/ZNetScene at the old area.
            if(ZNet.instance)ZNet.instance.SetReferencePosition(returnPosition);
        }
        private bool SelectWeapon(bool cycle)
        {
            int start=cycle?(weaponIndex+1)%weapons.Count:weaponIndex;
            for(int i=0;i<weapons.Count;i++)
            {
                int index=(start+i)%weapons.Count;var weapon=weapons[index];
                if(flyer&&!(body.IsFlying()?weapon.m_shared.m_aiWhenFlying:weapon.m_shared.m_aiWhenWalking))continue;
                if(body.GetCurrentWeapon()!=weapon&&!body.EquipItem(weapon,false))continue;
                weaponIndex=index;return true;
            }
            return false;
        }
        public void Step()
        {
            if(restored)return;
            if(!EnemyFormV11.Owns(Owner)||Generation!=EnemyFormV11.Generation){Restore();return;}
            if(!body||body.IsDead()||Owner.IsDead())
            {EnemyFormV11.Disable();Restore();EnemyFormV11.Status="Enemy body ended. Your player has been restored.";return;}
            if(Input.GetKeyDown(KeyCode.F8)){EnemyFormV11.Disable();Restore();return;}
            if(!saved && !FinishSetup())return;
            // Stream/save around the controlled body's location; do not replace the local-player singleton.
            FollowBody();ApplyMovement();ApplyOptions();
            Owner.m_eye.position=body.GetEyePoint();HidePlayer();HideIdentity();
            bool input=InputAllowed();
            if(input)
            {
                // Reuse the game's camera input preferences, including gamepad sensitivity/inversion.
                EnemyFormV11.CameraLook.Invoke(controller,null);EnemyFormV11.EyeRotation.Invoke(Owner,null);
                Vector3 forward=Owner.m_eye.forward;forward.y=0;forward.Normalize();Vector3 right=Vector3.Cross(Vector3.up,forward);
                var stick=ZInput.GetJoyLeftStick();
                float x=(ZInput.GetButton("Right")?1:0)-(ZInput.GetButton("Left")?1:0)+stick.x;
                float z=(ZInput.GetButton("Forward")?1:0)-(ZInput.GetButton("Backward")?1:0)+stick.y;
                Vector3 movement=Vector3.ClampMagnitude(forward*z+right*x,1);
                bool jumping=ZInput.GetButton("Jump")||ZInput.GetButton("JoyJump");
                bool jumpDown=ZInput.GetButtonDown("Jump")||ZInput.GetButtonDown("JoyJump");
                if(flyer)
                {
                    if(!body.IsFlying()&&jumpDown&&!body.InAttack())body.TakeOff();
                    if(body.IsFlying())
                    {
                        movement.y=(jumping?1f:0f)-(Input.GetKey(KeyCode.LeftControl)?1f:0f);
                        movement=Vector3.ClampMagnitude(movement,1);
                        if(formChoice==27&&Input.GetKeyDown(KeyCode.G)&&!body.InAttack())
                        {
                            RaycastHit ground;
                            if(GroundBelow(5f,out ground))body.Land();
                            else EnemyFormV11.Status="Descend close to the ground before pressing G to land.";
                        }
                    }
                }
                bool primary=ZInput.GetButton("Attack")||ZInput.GetButton("JoyAttack"),secondary=ZInput.GetButton("SecondaryAttack")||ZInput.GetButton("JoySecondaryAttack")||ZInput.GetButton("Block")||ZInput.GetButton("JoyBlock");
                body.SetMoveDir(movement);
                // SetLookDir's second argument is a transition duration, not delta time.
                // Restarting it each camera frame prevents the fixed-step transition advancing.
                // Native Character rotation still applies the creature's turn speed/attack limits.
                Vector3 facing=movement.sqrMagnitude>0.01f&&!primary&&!secondary&&!body.InAttack()?movement:Owner.m_eye.forward;
                body.SetLookDir(facing,0f);body.SetRun(ZInput.GetButton("Run")||ZInput.GetButton("JoyRun"));body.SetWalk(false);
                if(!flyer&&jumpDown)body.Jump(false);
                if(ZInput.GetButtonDown("Use")||ZInput.GetButtonDown("JoyUse"))EnemyFormV11.CycleRequested=true;
                if(EnemyFormV11.CycleRequested&&!body.InAttack())
                {
                    EnemyFormV11.CycleRequested=false;SelectWeapon(true);
                }
                if((primary||secondary)&&Time.time>=nextAttack&&!body.InAttack())
                {
                    nextAttack=Time.time+0.15f;
                    if(SelectWeapon(false))
                        body.StartAttack(null,!primary&&weapons[weaponIndex].HaveSecondaryAttack()&&(!flyer||!weapons[weaponIndex].m_shared.m_secondaryAttack.m_toggleFlying));
                }
            }
            else {body.SetMoveDir(Vector3.zero);body.SetRun(false);}
            if(Time.time>=nextStatus)
            {
                nextStatus=Time.time+0.5f;
                EnemyFormV11.Status=Forms[formChoice]+" ("+formStars+" stars). Enemy health: "+Mathf.CeilToInt(body.GetHealth())+" / "+Mathf.CeilToInt(body.GetMaxHealth())+
                    ". Weapon "+(weaponIndex+1)+"/"+weapons.Count+": "+weapons[weaponIndex].m_shared.m_name+
                    (EnemyFormV11.MonsterAllegiance?". Red monster allegiance (creatures ignore you)":". Green player allegiance")+
                    (EnemyFormV11.Duel?". Duel ON: attacks can hit friendly creatures/players.":". Duel OFF: native targeting.")+
                    (flyer?" Space: take off/rise; Left Ctrl: descend; "+(formChoice==27?"G: land near ground; ":""):"")+"Use cycles attacks; F8 returns.";
            }
        }
        public void Restore()
        {
            if(restored)return;restored=true;
            if(flightCamera)for(int i=0;i<cameraFields.Length;i++)cameraFields[i].SetValue(flightCamera,cameraValues[i]);
            foreach(var entry in projectiles)if(entry.Key){entry.Key.m_hitFriendly=entry.Value[0];entry.Key.m_noDamageFriendly=entry.Value[1];}
            projectiles.Clear();
            try { RestoreIdentity(); }
            finally
            {
            if(saved&&Owner)
            {
                if(flyer)returnPosition=safeReturnPosition;
                Owner.transform.position=returnPosition;Owner.m_eye.localPosition=eyeLocal;
                if(Owner==Player.m_localPlayer && disguiseNet && disguiseNet==ZNet.instance)disguiseNet.SetReferencePosition(returnPosition);
                foreach(var entry in renderers)if(entry.Key)entry.Key.forceRenderingOff=entry.Value;
                foreach(var entry in colliders)if(entry.Key)entry.Key.enabled=entry.Value;
                EnemyFormV11.SkipTarget.SetValue(Owner,skipTarget);
                if(playerBody){playerBody.isKinematic=kinematic;if(!kinematic){playerBody.linearVelocity=Vector3.zero;playerBody.angularVelocity=Vector3.zero;}}
                Owner.SetMoveDir(Vector3.zero);Owner.SetRun(false);
                Owner.enabled=playerEnabled;if(controller)controller.enabled=controllerEnabled;
            }
            if(bodyObject&&ZNetScene.instance)ZNetScene.instance.Destroy(bodyObject);
            bodyObject=null;body=null;
            }
        }
        private void Update()
        {
            if(!EnemyFormV11.Owns(Owner)||Generation!=EnemyFormV11.Generation)
            {Restore();Destroy(gameObject);}
        }
        private void FixedUpdate()
        {
            if(saved&&!restored&&body&&EnemyFormV11.Owns(Owner)&&Generation==EnemyFormV11.Generation){FollowBody();ApplyMovement();}
        }
        private void OnDestroy(){Restore();}
    }
}
