local file=assert(io.open('outputs/ValheimUnlimitedResources.lua'));local template=file:read('*a');file:close()
local env={};env._G=env;setmetatable(env,{__index=_G})
local pid,valid,dead=7,true,false
local installed,removed,failInstall,failRemove,failWrite=0,0,false,false,false
local errors={};local script,watch;local legacyStops,otherLabels=0,0
local mem={[4096+32]=1,[4096+36]=100,[4096+40]=0,[4096+44]=0,[4096+48]=2}
env.session=7;env.vtPointer=12
local maxAdrenaline=50
local failCheck,failRollback,throwInstall,partialCode=false,false,false,false
local preflight,emergencyRestores,checks=nil,0,0
local helperDisables,failConfigure=0,false
local helperEnabledAddress=0x9000
local methods={UseStamina=10000,HaveStamina=11000,UseEitr=12000,HaveEitr=13000,TryUseEitr=14000,UseHealth=15000,HaveHealth=16000,GetAdrenaline=17000,AddAdrenaline=18000,GetMaxAdrenaline=19000,IsDead=20000}
local function check(v,m)assert(v,m)end
env.form={OnClose=function()return 9 end,OnDestroy=function()end};env.staminaButton={};env.playerStatus={};env.playerClass=10
function env.playerLabels()otherLabels=otherLabels+1;env.staminaButton.Caption='Unlimited stamina: OFF'end
function env.ValheimPlayerCheatsStop()legacyStops=legacyStops+1 end
function env.createTimer()watch={};return watch end
function env.playerContext()return {pid=7,player=4096,storage=8192,vtable=99}end
function env.playerIdentity()return valid and pid==7 end
function env.getOpenedProcessID()return pid end
function env.getProcessIDFromProcessName()return pid end
function env.typedPlayerOffset(n,t)
 check(t=='System.Single','Only validated single fields');return assert(({m_stamina=32,m_maxStamina=36,m_eitr=40,m_maxEitr=44,m_adrenaline=48})[n],n)
end
function env.readFloat(p)return mem[p]end
function env.writeFloat(p,v)if failWrite then return false end;mem[p]=v;return true end
function env.pointer(p)return assert(p)end
function env.mono_findClass(namespace,name)if name=='UnlimitedSummonsV1' then check(namespace=='ValheimSoloToolkit','Helper namespace');return 12 end;if name=='SpawnAbility' then return 13 end;check(name=='Character','Character class only');return 11 end
function env.field(c,n)check(c==12 and n=='Enabled','Helper enabled field');return {isStatic=true,typename='System.Int32',staticAddress=helperEnabledAddress,offset=16}end
function env.readInteger(p)return mem[p]end
function env.matchingMethod(c,n,t,r)
 if c==12 then
  check(r==1,'Helper return type');if n=='Configure' then check(#t==1 and t[1]==18,'Configure signature');return 21000 end
  if n=='Disable' then check(#t==0,'Disable signature');return 22000 end
  check(n=='OnSetup' and #t==2 and t[1]==18 and t[2]==18,'OnSetup signature');return 23000
 elseif c==13 then
  check(n=='Setup' and r==1 and table.concat(t,',')=='18,17,12,18,18,18','Native summon setup signature');return 24000
 elseif n=='IsDead' then check(c==10 and #t==0 and r==2,'Death signature')
 elseif n=='GetAdrenaline' then error('Native adrenaline getter must not be detoured')
 elseif n=='GetMaxAdrenaline' then check(c==10 and #t==0 and r==12,'Adrenaline getter signature')
 else
  local character=n=='TryUseEitr' or n=='UseHealth' or n=='HaveHealth'
  check(c==(character and 11 or 10) and #t==1 and t[1]==12,'Resource method signature '..n)
  local yes=n=='HaveStamina' or n=='HaveEitr' or n=='TryUseEitr' or n=='HaveHealth'
  check(r==(yes and 2 or 1),'Resource return type '..n)
 end
 return assert(methods[n],n)
end
function env.invoke(m,p,args)
 if m==21000 then check(p==0 and #args==1 and args[1].value==4096,'Configure local player');if failConfigure then error('helper configure failed') end;mem[helperEnabledAddress]=1;return end
 if m==22000 then check(p==0 and #args==0,'Helper stop');helperDisables=helperDisables+1;mem[helperEnabledAddress]=0;return end
 check(p==4096 and #args==0,'Getter target');if m==20000 then return dead end;check(m==19000,'Maximum getter');return maxAdrenaline end
function env.mono_compile_method(m)return m end
function env.mono_getJitInfo(m)return {code_start=m,code_size=120}end
function env.readBytes(_,n,all)check(all,'Only read hook code');local b={};for i=1,n do b[i]=144 end;return b end
function env.getInstructionSize()return 1 end
function env.hint()end
function env.showMessage(e)errors[#errors+1]=e end
function env.autoAssembleCheck(s,enable,targetself)
 check(enable==true and targetself==false,'Native syntax check targets enabled game script')
 checks=checks+1;preflight=s
 if failCheck then return false,'simulated comparison assembly failure' end
 return true
end
function env.autoAssemble(s,_,info)
 if s:find('// resource emergency restore',1,true) then
  if failRollback then return false,'restore failure' end
  emergencyRestores=emergencyRestores+1;partialCode=false;return true,{}
 end
 if info then if failRemove then return false,'remove failure' end;removed=removed+1;return true end
 if throwInstall then partialCode=true;error('installation exception') end
 if failInstall then partialCode=true;return false,'install failure' end
 installed=installed+1;script=s;return true,{installed=true}
end
local base=assert(io.open('outputs/ValheimInventory.lua')):read('*a');local prefix=assert(base:match('^(.-)%-%- Valheim inventory editor'))
assert(load(prefix..template,'unlimited resources','t',env))()
check(env.staminaButton.Caption=='Unlimited resources: OFF','Initial label')
local click=env.staminaButton.OnClick
click();check(installed==1 and watch.Enabled and mem[4128]==100 and mem[4136]==0 and mem[4144]==50,'Zero-eitr food activation and three pools')
check(env.staminaButton.Caption=='Unlimited resources: ON','ON label')
-- Assert actual hook targets and generated return paths, rather than only tooltip wording.
for i=1,8 do
 local name='vhAbilityResource'..i
 local start=assert(script:find('\n'..name..':',1,true));local finish=assert(script:find('\n'..name..'Pass:',start,true))
 local code=script:sub(start,finish-1)
 check(code:find('cmp rcx,rax',1,true) and code:find('cmp [rax],rcx',1,true),'Local object and current static guard '..i)
 if i==2 or i==4 or i==5 or i==7 then check(code:find('mov eax,1\nret',1,true),'Sufficiency bypass '..i) end
 if i==8 then check(code:find('comiss xmm1,xmm0',1,true) and code:find('movdqu [rsp],xmm0',1,true) and code:find('movdqu xmm0,[rsp]',1,true) and not code:find('comiss xmm1,[',1,true) and code:find('jae vhAbilityResource8Pass',1,true) and code:find('jp vhAbilityResource8Pass',1,true),'Natural positive adrenaline/NaN pass-through') end
end
check(script:find('cmp rdx,rax',1,true) and script:find('cmp [rax],rdx',1,true),'Summon hook must guard local caster, not cast object')
check(script:find('5DC0:\ndb FF 25 00 00 00 00',1,true) and script:find('dq 59D8',1,true),'Native setup patched and helper callback used')
check(script:find('push qword ptr [rsp+D0]',1,true) and script:find('movdqu xmm3,[rsp+90]',1,true) and script:find('mov rdx,[rsp+30]',1,true),'Setup callback preserves flags, native arguments and SIMD registers')
check(not script:find('sub rsp,28',1,true) and not script:find('dq 4A38',1,true),'Resource hooks must never call another native method or replace GetAdrenaline')
check(not script:find('dd (float)',1,true) and not script:find('vhAbilityResource9Zero',1,true),'Resource hooks must not write zero constants after a native method patch')
check(preflight==script and checks==1,'Syntax preflight and installation must use identical normalized assembly')
check(not script:find('dealloc',1,true) and not script:match('alloc%([^%)]+,[^%)]+,'),'Safe retained far trampolines')
local declared,defined={},{}
for n in script:gmatch('label%(([%w]+)%)')do declared[n]=true end
for n in script:gmatch('\n([%w]+):')do defined[n]=true end
for n in pairs(declared)do check(defined[n],'Declared label missing '..n)end
for n in script:gmatch('j%w+ (vhAbilityResource[%w]+)')do check(declared[n] and defined[n],'Undeclared branch '..n)end
mem[4132]=150;mem[4140]=120;maxAdrenaline=75;watch.OnTimer()
check(mem[4128]==150 and mem[4136]==120 and mem[4144]==75,'Food/equipment dynamic maxima')
env.playerLabels();check(env.staminaButton.Caption=='Unlimited resources: ON' and otherLabels>2,'Unrelated toggles retain resource caption')
click();check(removed==1 and not watch.Enabled and env.staminaButton.Caption=='Unlimited resources: OFF','Disable unhooks all costs')
check(mem[4128]==150 and mem[4136]==120,'Refilled resources persist without changing capacities')
local beforePreflight=installed;local beforeRestore=emergencyRestores
failCheck=true;click();check(installed==beforePreflight and emergencyRestores==beforeRestore and not watch.Enabled,'Syntax errors must not attempt installation or rollback writes');failCheck=false
failInstall=true;click();check(not watch.Enabled and env.staminaButton.Caption=='Unlimited resources: OFF' and not partialCode and emergencyRestores==beforeRestore+1,'Partial installation restores original code');failInstall=false
throwInstall=true;click();check(not watch.Enabled and not partialCode and emergencyRestores==beforeRestore+2,'Thrown installation error restores original code');throwInstall=false
failInstall=true;failRollback=true;click();check(watch.Enabled and partialCode and env.staminaButton.Caption=='Unlimited resources: ON','Failed rollback must remain tracked for recovery');failInstall=false;failRollback=false
watch.OnTimer();check(not watch.Enabled and not partialCode and emergencyRestores==beforeRestore+3,'Watcher retries failed rollback before any resource refills')
failWrite=true;click();check(removed==2 and not watch.Enabled,'Activation refill failure removes installed hooks');failWrite=false
click();local before=removed;failRemove=true;click();check(watch.Enabled and removed==before and env.staminaButton.Caption=='Unlimited resources: ON','Cleanup failure keeps state truthful');failRemove=false;click()
click();dead=true;watch.OnTimer();check(not watch.Enabled,'Death unhooks all resources');dead=false
click();valid=false;mem[4128]=7;watch.OnTimer();check(not watch.Enabled and mem[4128]==7,'World change stops writes');valid=true
click();local beforePid=removed;pid=8;watch.OnTimer();check(not watch.Enabled and removed==beforePid,'No writes/unhooks in another process');pid=7
click();check(env.form.OnClose()==9 and not watch.Enabled,'Close cleanup and prior callback')
click();env.form.OnDestroy();check(not watch.Enabled,'Destroy cleanup')
click();env.ValheimPlayerCheatsStop();check(not watch.Enabled and legacyStops==1,'Reload/global player cleanup chains')
local beforeDead=installed;dead=true;click();check(installed==beforeDead and not watch.Enabled,'Dead enable rejected');dead=false
failConfigure=true;click();check(not watch.Enabled and mem[helperEnabledAddress]==0,'Helper configure failure must remove all hooks and disable helper');failConfigure=false
click();mem[helperEnabledAddress]=0;watch.OnTimer();check(not watch.Enabled and env.staminaButton.Caption=='Unlimited resources: OFF','Summon callback fault stops the whole resource toggle')
check(helperDisables>0,'Resource cleanup must disable summon helper')
mem[4140]=0/0;local beforeInvalid=removed;click();check(not watch.Enabled and removed==beforeInvalid+1,'Invalid maximum activation rolls hooks back')
local release=assert(io.open('outputs/ValheimBeta.lua')):read('*a')
check(release:find(template,1,true),'Release must include the tested resource implementation')
check(release:sub(1,100):find('ValheimUnlimitedResourcesStop',1,true),'Reload cleanup runs before creating the replacement form')
print('PASS: resource/summon setup signatures, scoped summon callback and helper lifecycle, sufficiency/cost hooks, zero-eitr food, dynamic stamina/eitr/equipment adrenaline with native getter retained, health-cost scope, gains preserved, far-safe register comparison, native syntax preflight, partial/exception/retry rollback and disable/death/world/close/reload cleanup')
