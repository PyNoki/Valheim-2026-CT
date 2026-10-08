using System;
using System.Collections.Generic;
using System.Collections;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class EnemyFormV4
    {
        public static int Enabled;
        public static string Status, LastError;
        internal static Player Owner;
        internal static int Generation, Choice;
        internal static bool CycleRequested;
        internal static EnemyFormDriverV4 Driver;
        internal const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        internal static readonly MethodInfo CameraLook=typeof(PlayerController).GetMethod("LateUpdate",Flags);
        internal static readonly MethodInfo EyeRotation=typeof(Player).GetMethod("UpdateEyeRotation",Flags);
        internal static readonly MethodInfo CanInput=typeof(Player).GetMethod("TakeInput",Flags);
        internal static readonly FieldInfo SkipTarget=typeof(Character).GetField("m_aiSkipTarget",Flags);
        public static void Configure(Player player,int form)
        {
            if(form<0||form>5)throw new ArgumentException("Choose an enemy form from 1 to 6.");
            if(CameraLook==null||EyeRotation==null||CanInput==null||SkipTarget==null)throw new MissingMemberException("Enemy form control methods unavailable.");
            Owner=player;Choice=form;Generation++;CycleRequested=false;LastError=null;Enabled=1;Status="Queued. Return to the game and unpause to transform.";
        }
        // Called by Cheat Engine. Unity restoration runs on the next game update.
        public static void Disable(){Enabled=0;CycleRequested=false;Status="Returning to player on the next game update.";}
        public static void NextWeapon(){if(Enabled==1)CycleRequested=true;}
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
                    Driver=new GameObject("SoloToolkit_EnemyForm").AddComponent<EnemyFormDriverV4>();
                    Driver.Owner=Owner;Driver.Generation=Generation;Driver.Setup(Choice);
                }
                Driver.Step();
            }
            catch(Exception e){Fault(e);if(Driver)Driver.Restore();}
        }
    }

    public sealed class EnemyFormDriverV4:MonoBehaviour
    {
        public Player Owner;
        internal int Generation;
        private static readonly string[] Forms={"Greydwarf","Skeleton","Draugr","Wolf","Troll","Serpent"};
        private GameObject bodyObject;
        private Humanoid body;
        private PlayerController controller;
        private Rigidbody playerBody;
        private readonly Dictionary<Renderer,bool> renderers=new Dictionary<Renderer,bool>();
        private readonly Dictionary<Collider,bool> colliders=new Dictionary<Collider,bool>();
        private readonly List<ItemDrop.ItemData> weapons=new List<ItemDrop.ItemData>();
        private bool saved,restored,playerEnabled,controllerEnabled,kinematic,skipTarget;
        private Vector3 eyeLocal,returnPosition;
        private int weaponIndex;
        private float nextAttack,nextStatus;
        private int spawnFrame,formChoice;
        private float initializationDeadline;
        private readonly Dictionary<CanvasGroup,float> hiddenUi=new Dictionary<CanvasGroup,float>();
        private readonly List<CanvasGroup> addedUi=new List<CanvasGroup>();
        private ZNet disguiseNet;
        private bool originalPublicPosition,disguiseSaved;
        private ZNetView playerView;
        private ZDO playerZdo;
        private string originalName;
        private static readonly FieldInfo PublicPosition=typeof(ZNet).GetField("m_publicReferencePosition",EnemyFormV4.Flags);
        private static readonly FieldInfo Huds=typeof(EnemyHud).GetField("m_huds",EnemyFormV4.Flags);
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
                var field=typeof(Minimap).GetField(name,EnemyFormV4.Flags);
                if(field==null)throw new MissingFieldException("Minimap."+name);
                var marker=field.GetValue(map) as Component;if(marker)HideUi(marker.gameObject);
            }
            var hud=EnemyHud.instance;
            if(hud)
            {
                var entries=Huds.GetValue(hud) as IDictionary;
                if(entries!=null && entries.Contains(Owner))
                {
                    var entry=entries[Owner];var field=entry.GetType().GetField("m_gui",EnemyFormV4.Flags);
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
        public void Setup(int choice)
        {
            if(!Owner.enabled)throw new InvalidOperationException("Return from the previous enemy form and unpause before transforming again.");
            if(Owner.IsDead()||Owner.InAttack()||Owner.InDodge()||Owner.IsTeleporting())throw new InvalidOperationException("Finish your action/teleport and stand still before transforming.");
            var prefab=ZNetScene.instance.GetPrefab(Forms[choice]);
            if(!prefab||!prefab.GetComponent<Humanoid>()||!prefab.GetComponent<MonsterAI>())throw new InvalidOperationException("Enemy form unavailable: "+Forms[choice]);
            controller=Owner.GetComponent<PlayerController>();playerBody=Owner.GetComponent<Rigidbody>();
            if(!controller||!playerBody||!Owner.m_eye)throw new InvalidOperationException("Player controller, body or camera anchor unavailable.");
            returnPosition=Owner.transform.position;
            bodyObject=UnityEngine.Object.Instantiate(prefab,returnPosition+Vector3.up*0.2f,Owner.transform.rotation);
            body=bodyObject.GetComponent<Humanoid>();
            var view=bodyObject.GetComponent<ZNetView>();
            if(!view||!view.IsValid()||!view.IsOwner())throw new InvalidOperationException("The transformed body is not locally owned.");
            // Only this newly spawned body loses AI. Existing enemies are untouched.
            foreach(var ai in bodyObject.GetComponents<BaseAI>())ai.enabled=false;
            body.m_faction=Character.Faction.Players;
            // Humanoid.Start gives default/random equipment AFTER Instantiate returns.
            // Keep the real player active until Unity has initialized the new body.
            spawnFrame=Time.frameCount;initializationDeadline=Time.time+3f;formChoice=choice;
            EnemyFormV4.Status="Waiting for "+Forms[choice]+" native weapons to initialize...";
        }
        private bool FinishSetup()
        {
            if(Time.frameCount<=spawnFrame)return false;
            weapons.Clear();
            foreach(var item in body.GetInventory().GetAllItems())
                if(item.HavePrimaryAttack())weapons.Add(item);
            // Some creatures use m_unarmedWeapon, which is not an inventory item.
            // GetCurrentWeapon exposes it; do not try to EquipItem that fallback.
            var current=body.GetCurrentWeapon();
            if(weapons.Count==0 && current!=null && current.HavePrimaryAttack())weapons.Add(current);
            if(weapons.Count==0)
            {
                if(Time.time<initializationDeadline)return false;
                throw new InvalidOperationException(Forms[formChoice]+" did not initialize any native attacks within 3 seconds. Your player was left unchanged.");
            }
            if(Owner.InAttack()||Owner.InDodge()||Owner.IsTeleporting())throw new InvalidOperationException("Player started an action while transforming. Stand still and try again.");
            weaponIndex=weapons.IndexOf(body.GetCurrentWeapon());
            if(weaponIndex<0){weaponIndex=0;if(!body.EquipItem(weapons[0],false))throw new InvalidOperationException("Could not equip the enemy's native weapon.");}
            playerEnabled=Owner.enabled;controllerEnabled=controller.enabled;kinematic=playerBody.isKinematic;
            skipTarget=(bool)EnemyFormV4.SkipTarget.GetValue(Owner);eyeLocal=Owner.m_eye.localPosition;saved=true;
            controller.enabled=false;Owner.enabled=false;EnemyFormV4.SkipTarget.SetValue(Owner,true);
            playerBody.linearVelocity=Vector3.zero;playerBody.angularVelocity=Vector3.zero;playerBody.isKinematic=true;
            HidePlayer();
            HideIdentity();
            EnemyFormV4.Status=Forms[formChoice]+" form. Move/run/jump normally; Attack = native attack; Block = secondary; Use = cycle weapon; F8 = return.";
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
            return Application.isFocused && (bool)EnemyFormV4.CanInput.Invoke(Owner,null)
                && !InventoryGui.IsVisible() && !Menu.IsVisible() && !Console.IsVisible() && !Minimap.IsOpen()
                && !Hud.IsPieceSelectionVisible() && !Hud.InRadial() && !(Chat.instance&&Chat.instance.HasFocus());
        }
        public void Step()
        {
            if(restored)return;
            if(!EnemyFormV4.Owns(Owner)||Generation!=EnemyFormV4.Generation){Restore();return;}
            if(!body||body.IsDead()||Owner.IsDead())
            {EnemyFormV4.Disable();Restore();EnemyFormV4.Status="Enemy body ended. Your player has been restored.";return;}
            if(Input.GetKeyDown(KeyCode.F8)){EnemyFormV4.Disable();Restore();return;}
            if(!saved && !FinishSetup())return;
            // Stream/save around the controlled body's location; do not replace the local-player singleton.
            returnPosition=body.transform.position;Owner.transform.position=returnPosition;
            Owner.m_eye.position=body.GetEyePoint();HidePlayer();HideIdentity();
            bool input=InputAllowed();
            if(input)
            {
                // Reuse the game's camera input preferences, including gamepad sensitivity/inversion.
                EnemyFormV4.CameraLook.Invoke(controller,null);EnemyFormV4.EyeRotation.Invoke(Owner,null);
                Vector3 forward=Owner.m_eye.forward;forward.y=0;forward.Normalize();Vector3 right=Vector3.Cross(Vector3.up,forward);
                var stick=ZInput.GetJoyLeftStick();
                float x=(ZInput.GetButton("Right")?1:0)-(ZInput.GetButton("Left")?1:0)+stick.x;
                float z=(ZInput.GetButton("Forward")?1:0)-(ZInput.GetButton("Backward")?1:0)+stick.y;
                body.SetMoveDir(Vector3.ClampMagnitude(forward*z+right*x,1));
                body.SetLookDir(Owner.m_eye.forward,Time.deltaTime);body.SetRun(ZInput.GetButton("Run")||ZInput.GetButton("JoyRun"));body.SetWalk(false);
                if(ZInput.GetButtonDown("Jump")||ZInput.GetButtonDown("JoyJump"))body.Jump(false);
                if(ZInput.GetButtonDown("Use")||ZInput.GetButtonDown("JoyUse"))EnemyFormV4.CycleRequested=true;
                if(EnemyFormV4.CycleRequested&&!body.InAttack())
                {
                    EnemyFormV4.CycleRequested=false;int next=(weaponIndex+1)%weapons.Count;
                    if(body.EquipItem(weapons[next],false))weaponIndex=next;
                }
                bool primary=ZInput.GetButton("Attack")||ZInput.GetButton("JoyAttack"),secondary=ZInput.GetButton("SecondaryAttack")||ZInput.GetButton("JoySecondaryAttack")||ZInput.GetButton("Block")||ZInput.GetButton("JoyBlock");
                if((primary||secondary)&&Time.time>=nextAttack&&!body.InAttack())
                {
                    nextAttack=Time.time+0.15f;
                    body.StartAttack(null,!primary&&weapons[weaponIndex].HaveSecondaryAttack());
                }
            }
            else {body.SetMoveDir(Vector3.zero);body.SetRun(false);}
            if(Time.time>=nextStatus)
            {
                nextStatus=Time.time+0.5f;
                EnemyFormV4.Status="Enemy health: "+Mathf.CeilToInt(body.GetHealth())+" / "+Mathf.CeilToInt(body.GetMaxHealth())+
                    ". Weapon "+(weaponIndex+1)+"/"+weapons.Count+": "+weapons[weaponIndex].m_shared.m_name+". Use cycles attacks; F8 returns.";
            }
        }
        public void Restore()
        {
            if(restored)return;restored=true;
            try { RestoreIdentity(); }
            finally
            {
            if(saved&&Owner)
            {
                Owner.transform.position=returnPosition;Owner.m_eye.localPosition=eyeLocal;
                foreach(var entry in renderers)if(entry.Key)entry.Key.forceRenderingOff=entry.Value;
                foreach(var entry in colliders)if(entry.Key)entry.Key.enabled=entry.Value;
                EnemyFormV4.SkipTarget.SetValue(Owner,skipTarget);
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
            if(!EnemyFormV4.Owns(Owner)||Generation!=EnemyFormV4.Generation)
            {Restore();Destroy(gameObject);}
        }
        private void OnDestroy(){Restore();}
    }
}
