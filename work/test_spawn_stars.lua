local controls,timers,calls={},{},{}
local function control(parent,kind)
  local c={Parent=parent,kind=kind,Font={},ItemIndex=-1,Text=''}
  c.Items={};c.Items.add=function(value)table.insert(c.Items,value)end;c.Items.clear=function()for i=#c.Items,1,-1 do c.Items[i]=nil end end
  c.show=function()end;c.hide=function()end;c.destroy=function()end
  controls[#controls+1]=c;return c
end
local env={};setmetatable(env,{__index=_G})
for _,kind in ipairs({'Form','Label','Button','ComboBox','ListBox'})do env['create'..kind]=function(parent)return control(parent,kind)end end
env.createTimer=function(parent)local t={Parent=parent};timers[#timers+1]=t;return t end
local helper={pid=1,prefab='prefab',queue='queue',spawnCatalogue='catalogue',tameStatus='tameStatus',tameCatalogue='animals'}
env.getOpenedProcessID=function()return 1 end;env.getProcessIDFromProcessName=function()return 1 end
local prelude=[[
local pending,hook,spawnWindow,spawnStatus,tamingWindow,tamingStatus
local window={hide=function()end};local poll={}
local form={OnClose=function()end,OnDestroy=function()end}
local spawnButton,tamingButton={},{}
local vtPointer,vtString,vtDword=18,14,8
local function action(fn)fn()end
local function hint()end
local function context()return {player=123,world='0100000000000000'}end
local function loadRecovery()return testHelper end
local function installHook(s,h)hook={recovery=h}end
local function stopTeleport()pending=nil;hook=nil end
]]
env.testHelper=helper
local catalogue='0|Wolf\n1|Haldor\n2|Wood\n3|Wolf'
env.invoke=function(method,_,args)
 if method=='catalogue'then return catalogue end
 if method=='tameStatus'then return 'Ready' end
 if method=='animals'then return '' end
 calls[#calls+1]={method=method,args=args}
end
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local suffix=[[
return {openSpawn=function()spawnButton.OnClick()end,openTaming=function()tamingButton.OnClick()end,reset=function()pending=nil end}
]]
local ui=assert(load(prelude..read('outputs/ValheimSpawn.lua')..'\n'..read('outputs/ValheimTaming.lua')..suffix,'spawn stars','t',env))()
local function find(parent,key,value)for _,c in ipairs(controls)do if c.Parent==parent and c[key]==value then return c end end;error('Control missing: '..tostring(value))end
local function form(caption)for _,c in ipairs(controls)do if c.Caption==caption then return c end end;error('Form missing')end
local function tick(parent)for _,t in ipairs(timers)do if t.Parent==parent then t.OnTimer()end end end
local function checkCall(kind,stars)
 local call=calls[#calls];assert(call.method=='prefab','Expected prefab request')
 local a=call.args;assert(#a==5 and a[1].value==123 and a[3].value==kind and a[4].value==stars and a[4].type==8 and a[5].value=='0100000000000000','Wrong spawn signature or star value')
end
-- Loading Taming first used to consume the shared cache and leave Spawn empty.
ui.openTaming();local taming=form('Valheim | Taming');tick(taming);ui.reset()
ui.openSpawn();local spawn=form('Valheim | Spawn');tick(spawn);ui.reset()
for _,top in ipairs({116,170,224})do assert(#find(spawn,'Top',top).Items==1,'Taming-first must populate every Spawn dropdown')end
local stars=find(spawn,'Top',76);assert(stars.kind=='ComboBox' and stars.ItemIndex==0 and #stars.Items==3,'Default normal stars and all choices')
local creature=find(spawn,'Top',116);creature.ItemIndex=0
local function spawnButtonAt(top)for _,c in ipairs(controls)do if c.Parent==spawn and c.kind=='Button' and c.Top==top then return c end end end
for value=0,2 do stars.ItemIndex=value;spawnButtonAt(116).OnClick();checkCall(0,value);ui.reset()end
stars.ItemIndex=2
for _,entry in ipairs({{170,1},{224,2}})do spawnButtonAt(entry[1]).OnClick();checkCall(entry[2],0);ui.reset()end
ui.openTaming();tick(taming);ui.reset()
local tameStars=find(taming,'Left',355);assert(tameStars.ItemIndex==0 and #tameStars.Items==3,'Taming stars default and choices')
local tameSpawn=find(taming,'Caption','Spawn selected tameable')
for value=0,2 do tameStars.ItemIndex=value;tameSpawn.OnClick();checkCall(3,value);ui.reset()end
print('PASS: both spawn windows send 0/1/2 stars with the exact helper signature; merchants/resources always send zero.')
creature.Text='Wolf'
catalogue='0|Troll\n0|Wolf\n1|Hildir\n2|CarrotPlant\n3|Wolf'
tick(taming);tick(spawn)
assert(#creature.Items==2 and creature.Items[1]=='Troll' and creature.ItemIndex==1,'Other window must not consume Spawn refresh')
assert(find(spawn,'Top',170).Items[1]=='Hildir' and find(spawn,'Top',224).Items[1]=='CarrotPlant','Merchant/plant refresh lost')
catalogue='';tick(taming);tick(spawn)
assert(#creature.Items==2 and #tameStars.Items==3,'Empty helper response must retain valid lists')
print('PASS: Taming-first, interleaved catalogue refreshes and empty responses retain populated Spawn dropdowns.')
catalogue='0|Wolf\n1|Haldor\n2|Gold|Bloodgold\n2|Wood\n3|Wolf'
tick(taming);tick(spawn)
local items=find(spawn,'Top',224)
assert(items.Items[1]=='Bloodgold [Gold]' and items.Items[2]=='Wood','Localized and legacy item rows must display correctly')
items.ItemIndex=0;spawnButtonAt(224).OnClick();checkCall(2,0)
assert(calls[#calls].args[2].value=='Gold','Localized labels must send the original prefab name');ui.reset()
catalogue='0|Wolf\n1|Haldor\n2|Wood\n2|Gold|Renamed gold\n3|Wolf'
tick(taming);tick(spawn)
assert(items.ItemIndex==1 and items.Items[2]=='Renamed gold [Gold]','Refresh must retain selected prefab across label and order changes')
print('PASS: localized item labels preserve native spawn names and selection across catalogue refreshes.')
