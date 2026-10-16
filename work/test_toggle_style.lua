local source=assert(io.open('outputs/ValheimToggleStyle.lua')):read('*a')
local env={};setmetatable(env,{__index=_G})
local panels,timers={},{};local foreground=false;local clicks=0;local parentWrites=0;local paints=0;local resizeCalls=0
local function control(values)
 local data=values or {};data.Font=data.Font or {}
 data.repaint=function()paints=paints+1 end;data.bringToFront=function()end
 return setmetatable({}, {__index=data,__newindex=function(_,k,v)if k=='Parent' then parentWrites=parentWrites+1 end;data[k]=v end})
end
local group=control();env.playerGroup=group
local names={'godButton','staminaButton','craftingButton','flightButton','beamButton','carryButton','deleteButton','enemyButton','keepFlagsButton','rapidButton','freezeReplenishButton','freeze','speedButton','jumpButton','boatButton','edit','cloneButton','maxItemQualityButton','refresh','maxStacksButton','dragButton','spawnButton','tamingButton','trophyButton','maxSkills','customSkills','resetMovementButton','teleportButton'}
for _,n in ipairs(names)do env[n]=control({Parent=group,Left=12,Top=20,Width=180,Height=28,Caption=n..': OFF',OnClick=function()clicks=clicks+1 end})end
function env.createPanel(parent)local p=control({Parent=parent});panels[#panels+1]=p;return p end
function env.createTimer()local t={};timers[#timers+1]=t;return t end
env.form=control({OnResize=function()resizeCalls=resizeCalls+1 end,OnShow=function()end,OnClose=function()return 9 end,OnDestroy=function()end,isForegroundWindow=function()return foreground end})
assert(load(source,'styles','t',env))()
local poll=timers[1];local writes=parentWrites
poll.OnTimer();poll.OnTimer();assert(parentWrites==writes,'Idle updates must not reparent panels')
assert(paints==0 and clicks==0,'Idle updates must not paint or trigger actions')
foreground=true;poll.OnTimer();local first=paints;assert(first>0,'Focus regain must repaint')
poll.OnTimer();assert(paints==first*2,'Second paint repairs delayed desktop invalidation')
poll.OnTimer();assert(paints==first*2,'No continuous forced painting')
foreground=false;poll.OnTimer();panels[1].Visible=false;panels[2].Caption='';foreground=true;poll.OnTimer()
assert(panels[1].Visible and panels[2].Caption=='staminaButton','Recover missing visual and text')
env.staminaButton.Caption='staminaButton: ON';poll.OnTimer();assert(panels[2].Color==0x32852E,'Toggle state survives repaint')
assert(clicks==0,'Repainting must never toggle a feature')
env.form.OnResize();assert(resizeCalls==1 and parentWrites==writes,'Preserve layout callback without unnecessary reparenting')
env.staminaButton.Parent=control();poll.OnTimer();assert(panels[1].Parent==env.staminaButton.Parent,'Real parent changes must propagate')
panels[2].OnClick();assert(clicks==1,'Original click handler survives')
local fixed=control({Parent=group,Left=12,Top=20,Width=180,Height=28,Caption='Fixed HP 999: OFF'})
env.styleToggle(fixed,true);assert(panels[#panels-1].Color==0x666666,'Fixed health uses the normal border')
assert(env.form.OnClose()==9,'Close behavior preserved');env.form.OnDestroy();assert(not poll.Enabled,'Destroy stops style timer')
print('PASS: stable panel parents, focus regain/deferred repaint, visual recovery, toggle state, clicks, layout and cleanup')
