local helper={pid=1,queue='queue',sortState='state',sortStop='stop',sortStatus='status'}
local enabled,queued,stops=0,0,0
local env={testHelper=helper};setmetatable(env,{__index=_G})
env.getOpenedProcessID=function()return 1 end;env.getProcessIDFromProcessName=function()return 1 end
env.invoke=function(method,_,args)
 if method=='queue' then assert(args[2].value==40 and args[1].value==123 and args[3].value=='world','Wrong sorting request');queued=queued+1 end
 if method=='stop' then enabled=0;stops=stops+1 end
 if method=='state' then return enabled end
 if method=='status' then return 'Ready for F9' end
end
local timers={};env.createTimer=function()local t={};timers[#timers+1]=t;return t end
local prelude=[[
local sortingButton,status={},{}
local form={OnClose=function()end,OnDestroy=function()end}
local window={hide=function()end}
local pending,hook;local poll={};local vtPointer,vtDword,vtString=18,8,14
local function hint()end
local function context()return {player=123,world='world'}end
local function loadRecovery()return testHelper end
local function installHook(s,h)hook={recovery=h}end
local function stopTeleport()pending=nil;hook=nil end
local function readCatalogueString(s)return s end
]]
local f=assert(io.open('outputs/ValheimChestSorting.lua'));local source=f:read('*a');f:close()
local ui=assert(load(prelude..source..[[
return {click=function()sortingButton.OnClick()end,complete=function()pending=nil end,
 close=function()form.OnClose()end,caption=function()return sortingButton.Caption end,
 message=function()return status.Caption end,other=function()status.Caption='Other action result'end}
]],'chest sorting','t',env))()
ui.click();assert(queued==1 and ui.message():find('Open a chest with E',1,true),'Enable must queue once and explain native chest action')
timers[1].OnTimer();assert(ui.caption()=='Chest sorting: STARTING','Pending enable must not appear OFF')
ui.click();assert(stops==1 and ui.caption()=='Chest sorting: OFF','Second click must cancel unsent enable')
ui.click();ui.complete();enabled=1;timers[1].OnTimer();assert(ui.caption()=='Chest sorting: ON','Active state not shown')
ui.other();timers[1].OnTimer();assert(ui.message()=='Other action result','Unchanged sorting status must not overwrite another result')
ui.click();assert(stops==2 and enabled==0,'Disable must stop helper')
ui.click();ui.close();assert(stops==3,'Closing toolkit must cancel queued sorting and stop helper')
print('PASS: sorting queue, exact action/session signature, pending cancellation, state/unchanged-status polling, disable and close cleanup')
