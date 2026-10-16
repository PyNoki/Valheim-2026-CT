local template=assert(io.open('outputs/ValheimFixedHealth.lua')):read('*a')
local env={};env._G=env;setmetatable(env,{__index=_G})
local pid,valid,god,dead=7,true,0,0
local installed,removed,script,failInstall,failRemove=0,0,nil,false,false
local errors={};local godClicks=0;local watch
local function check(v,m) assert(v,m) end
local form={OnClose=function()return 9 end,OnDestroy=function()end}
env.form=form;env.fixedHealthButton={};env.godButton={OnClick=function()godClicks=godClicks+1 end};env.playerStatus={};env.playerClass=10
function env.createTimer()watch={};return watch end
function env.playerContext()return {pid=7,player=4096,storage=8192,vtable=99}end
function env.playerIdentity()return valid and pid==7 end
function env.getOpenedProcessID()return pid end
function env.getProcessIDFromProcessName()return pid end
function env.typedPlayerOffset(n)check(n=='m_godMode','Only verified god flag may use a field offset');return 32 end
function env.readBytes(a,n,all)if all then local b={}for i=1,n do b[i]=144 end;return b end;return god end
function env.pointer(p)return assert(p)end
function env.mono_findClass(_,n)return n=='Hud' and 12 or 11 end
function env.matchingMethod(c,n,t,r)
 if n=='Save' then check(c==10 and t[1]==18 and r==1,'Save signature');return 9000 end
 if n=='IsDead' then check(c==10 and #t==0 and r==2,'Player.IsDead signature');return 13000 end
 if n=='SetHealthBarSize' then check(c==12 and #t==1 and t[1]==12 and r==1,'HUD sizing signature');return 14000 end
 check(c==11,'Character methods');return ({GetHealth=10000,GetMaxHealth=11000,SetHealth=12000})[n]
end
function env.invoke(m,p,args)check(m==13000 and p==4096 and #args==0,'Invoke player death query');return dead end
function env.mono_compile_method(m)return m end
function env.mono_getJitInfo(m)return {code_start=m,code_size=500}end
function env.getInstructionSize()return 1 end
function env.hint()end
function env.showMessage(e)errors[#errors+1]=e end
function env.autoAssemble(s,_,info)
 if info then if failRemove then return false,'remove failure' end;removed=removed+1;return true end
 if failInstall then return false,'install failure' end
 installed=installed+1;script=s;return true,{installed=true}
end
local source=assert(io.open('outputs/ValheimInventory.lua')):read('*a')
local prefix=assert(source:match('^(.-)%-%- Valheim inventory editor'))
assert(load(prefix..template,'fixed-health','t',env))()
local click=env.fixedHealthButton.OnClick
click();check(installed==1 and watch.Enabled,'enable');check(env.fixedHealthButton.Caption=='Fixed HP 999: ON','ON label')
check(script:find('mov eax,4479C000',1,true),'999 float')
check(script:find('cmp [rsp+10],rax',1,true) and script:find('mov rax,2328',1,true) and script:find('mov rax,251C',1,true),'save caller range')
check(script:find('call vhFixedHP3Original',1,true) and script:find('comiss xmm0,[rsp+28]',1,true),'native food cap and stored HP clamp')
check(not script:find('dealloc',1,true),'in-flight trampolines retained')
check(not script:match('alloc%([^%)]+,[^%)]+,'),'fixed HP must never request nearby memory')
check(not script:find('m_godMode',1,true),'no god writes')
check(script:find('dq 32C8',1,true) and script:find('movss [rsp+28],xmm1',1,true) and script:find('movss xmm1,[rsp+28]',1,true),'Native Player.IsDead check preserves health argument')
check(script:find('alloc(vhFixedHP4,2048)',1,true) and script:find('divss xmm0,[vhFixedHPHud25]',1,true) and script:find('mulss xmm0,[vhFixedHPHud32]',1,true),'HUD sizes from native food maximum using native scaling')
check(script:find('jmp vhFixedHP4Original',1,true),'HUD sizing must continue through native method')
local declared,defined={},{}
for n in script:gmatch('label%(([%w]+)%)')do declared[n]=true end
for n in script:gmatch('\n([%w]+):')do defined[n]=true end
for n in pairs(declared)do check(defined[n],'Declared assembly label must be defined: '..n)end
for n in script:gmatch('j%w+ (vhFixedHP[%w]+)')do check(declared[n] and defined[n],'branch label '..n)end
click();check(removed==1 and not watch.Enabled,'disable')
god=1;click();check(installed==1 and errors[#errors]:find('God Mode'),'god exclusion');god=0
dead=1;click();check(installed==1,'dead rejection');dead=0
failInstall=true;click();check(not watch.Enabled,'failed activation stays off');failInstall=false
click();valid=false;watch.OnTimer();check(removed==2 and not watch.Enabled,'stale player removal');valid=true
click();env.godButton.OnClick();check(removed==3 and godClicks==1,'god enable removes health')
click();failRemove=true;env.godButton.OnClick();check(godClicks==1 and watch.Enabled,'failed cleanup blocks god');failRemove=false
check(form.OnClose()==9 and not watch.Enabled,'close cleanup')
click();form.OnDestroy();check(not watch.Enabled,'destroy cleanup')
click();pid=8;watch.OnTimer();check(not watch.Enabled,'process change stops toggle');check(removed==5,'never restore code into a different process');pid=7
click();local beforeDeath=removed;dead=1;watch.OnTimer();check(not watch.Enabled and removed==beforeDeath+1,'Native death-state transition removes health overlay');dead=0
local beforeFailure=installed;env.invoke=function()error('death query unavailable')end;click();check(installed==beforeFailure and not watch.Enabled,'Failed death query must not install hooks')
print('PASS: fixed HP signatures, local guards, save exception, food cap, lifecycle, God Mode exclusion and failure recovery')
