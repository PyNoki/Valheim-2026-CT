local f=assert(io.open('outputs/ValheimBeta.lua'));local source=f:read('*a');f:close()
local start=assert(source:find('-- The original controls retain their helpers;',1,true))
local finish=assert(source:find('\ndo\nfreezeAll.Visible=false',start,true))
local block=source:sub(start,finish-1)
local env={minerButton={Caption='Fast attacks: OFF'},hoeButton={Caption='Rapid hoe: OFF'},rapidButton={},boatButton={},playerStatus={},form={OnClose=function()return 9 end,OnDestroy=function()end}}
setmetatable(env,{__index=_G})
local monitor;local messages={};local minerStarts,hoeStarts=0,0
function env.hint()end
function env.createTimer()monitor={};return monitor end
function env.showMessage(m)messages[#messages+1]=m end
function env.ValheimRapidMinerStop()env.minerButton.Caption='Fast attacks: OFF'end
function env.ValheimRapidHoeStop()env.hoeButton.Caption='Rapid hoe: OFF'end
env.minerButton.OnClick=function()minerStarts=minerStarts+1;env.minerButton.Caption=env.minerButton.Caption=='Fast attacks: ON' and 'Fast attacks: OFF' or 'Fast attacks: ON'end
env.hoeButton.OnClick=function()hoeStarts=hoeStarts+1;env.hoeButton.Caption='Rapid hoe: ON'end
assert(load(block,'rapid tools combat coordination','t',env))()
assert(env.minerButton.Visible~=false and env.hoeButton.Visible==false,'Standalone Fast attacks must stay visible')
env.minerButton.OnClick();env.rapidButton.OnClick()
assert(env.rapidButton.Caption=='Rapid tools: ON' and minerStarts==1 and hoeStarts==1,'Combine with existing Fast attacks without disabling/restarting it')
env.rapidButton.OnClick();assert(env.minerButton.Caption=='Fast attacks: OFF' and env.hoeButton.Caption=='Rapid hoe: OFF' and not monitor.Enabled,'Combined OFF cleanup')
env.rapidButton.OnClick();env.minerButton.OnClick();monitor.OnTimer()
assert(env.rapidButton.Caption=='Rapid tools: OFF' and env.hoeButton.Caption=='Rapid hoe: OFF','Standalone OFF must stop active combination')
env.rapidButton.OnClick();env.hoeButton.Caption='Rapid hoe: OFF';monitor.OnTimer()
assert(env.minerButton.Caption=='Fast attacks: OFF','Building/helper stop must clear combination')
env.rapidButton.OnClick();assert(env.form.OnClose()==9 and env.minerButton.Caption=='Fast attacks: OFF' and not monitor.Enabled,'Close cleans both helpers')
env.hoeButton.OnClick=function()end;env.rapidButton.OnClick()
assert(#messages==1 and env.minerButton.Caption=='Fast attacks: OFF' and not monitor.Enabled,'Partial enable failure cleans up')
print('PASS: visible standalone Fast attacks, existing-combat combination, coordinated off/build/close cleanup and partial-enable rollback')
