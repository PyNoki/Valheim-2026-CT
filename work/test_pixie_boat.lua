local controls,timers,forms,errors,calls={},{},{},{},{}
local pid=123
local h={pid=123,boatQueue=1,boatOptions=2,boatProtected=3,boatStop=4,boatStatus=5,cancel=6}
local active,boatOn=false,false
local e=setmetatable({},{__index=_G})
e.vtPointer=1;e.vtDword=2;e.vtString=3;e.caHide=0
e.boatButton={Caption='Pixie boat...'}
e.form={OnClose=function() return 0 end,OnDestroy=function() end}
e.window={hide=function() end};e.poll={Enabled=false}
local function control() local c={};controls[#controls+1]=c;return c end
e.createLabel=control;e.createButton=control;e.createCheckBox=control
e.createComboBox=function() local c=control();c.Items={};c.Items.add=function(v)table.insert(c.Items,v)end;return c end
e.createForm=function() local c={};c.show=function() c.visible=true end;c.hide=function() c.visible=false end;c.destroy=function() c.destroyed=true end;forms[#forms+1]=c;return c end
e.createTimer=function() local t={Enabled=false};t.destroy=function() t.Enabled=false;t.destroyed=true end;timers[#timers+1]=t;return t end
e.action=function(fn) local ok,err=pcall(fn);if not ok then errors[#errors+1]=err end end
e.getOpenedProcessID=function() return pid end;e.getProcessIDFromProcessName=function() return pid end
e.context=function() return {pid=123,player=0x2000,storage=0x1030,world='0100000000000000'} end
e.typedPlayerOffset=function() return 0x80 end;e.playerIdentity=function(s) return s.pid==pid end
e.pointer=function(p) assert(p and p~=0);return p end
e.readBytes=function(address,n,tableResult) if not tableResult then return 0 end;local t={};for i=1,n do t[i]=0x90 end;return t end
e.mono_findClass=function(ns,name) assert(ns=='');assert(name=='WearNTear' or name=='Player');return name=='WearNTear' and 10 or 20 end
e.matchingMethod=function(class,name,args,result) if class==20 then assert(name=='SetControls' and args[1]==17 and #args==12 and result==1);for i=2,12 do assert(args[i]==2) end;return 21 end;assert(class==10 and name=='ApplyDamage' and args[1]==12 and args[2]==18 and #args==2 and result==2);return 11 end
e.mono_compile_method=function(method) return method==11 and 0x10000 or method==21 and 0x30000 or 0x20000 end
e.getInstructionSize=function() return 1 end
e.autoAssemble=function(script,self,disable)
 assert(script:find('cmp [rax],r11',1,true),'Guard must validate local player')
 assert(script:find('call qword ptr [vhBoatCallback]',1,true),'Absolute callback missing')
 assert(not script:find('vhFurniture',1,true),'Furniture input hook remains')
 local _,enables=script:gsub('%[ENABLE%]','');local _,disables=script:gsub('%[DISABLE%]','');assert(enables==1 and disables==1,'Vehicle guards must be installed and removed together')
 assert(script:find('xor eax,eax\nret',1,true),'Skipped bool ApplyDamage must return false')
 assert(script:find('movdqu [rsp+70],xmm1',1,true) and script:find('movdqu xmm1,[rsp+70]',1,true),'Native float damage argument not preserved')
 assert(not script:find('dealloc(',1,true),'In-flight callback memory freed')
 active=not disable;return true,{}
end
e.loadRecovery=function() return h end
e.installHook=function(s,helper) e.hook={recovery=helper} end
e.stopTeleport=function() e.hook=nil end
e.invoke=function(method,object,args)
 calls[#calls+1]={method=method,args=args}
 if method==1 then assert(#args==3 and args[1].value==0x2000 and args[3].value=='0100000000000000');boatOn=true
 elseif method==4 then boatOn=false
 elseif method==5 then return boatOn and 'Pixie boat: ON' or 'Pixie boat: OFF' end
end
assert(loadfile('outputs/ValheimPixieBoat.lua','t',e))()
e.boatButton.OnClick()
local toggle,stop,safe
for _,c in ipairs(controls) do
 if c.Caption=='Toggle Pixie boat' then toggle=c end
 if c.Caption=='Stop / restore boat' then stop=c end
 if c.Caption=='No durability loss (active boat only)' then safe=c end
 assert(not tostring(c.Caption):find('longship',1,true),'Rejected boat substitution remained in menu')
 assert(not tostring(c.Caption):find('ground mode',1,true),'Furniture ground/jump mode was not removed')
end
assert(toggle and stop and safe and safe.Checked==true and not active,'Menu/default protection or deferred install failed')
toggle.OnClick();assert(#errors==0 and active and e.pending.boat and e.poll.Enabled and timers[1].Enabled,'Boat queue/guard setup failed: '..tostring(errors[#errors]))
assert(calls[#calls].method==1 and calls[#calls].args[2].value==1,'Default durability option was not queued')
local count=#calls;toggle.OnClick();assert(#calls==count and #errors==1,'Duplicate pending boat request accepted')
safe.Checked=false;safe.OnChange();assert(calls[#calls].method==2 and #calls[#calls].args==1 and calls[#calls].args[1].value==0,'Live durability option not marshalled')

e.pending=nil;timers[1].OnTimer();assert(e.boatButton.Caption=='Pixie boat: ON' and active,'Polling retired active durability hook')
stop.OnClick();assert(not active and not boatOn and not timers[1].Enabled,'Stop did not restore/remove guard')
safe.Checked=true;toggle.OnClick();e.form.OnClose();assert(not active and not e.pending and not e.poll.Enabled and not boatOn,'Close did not cancel queued activation and restore guard')
toggle.OnClick();e.pending=nil;boatOn=false;timers[1].OnTimer();assert(not active and not timers[1].Enabled,'Native stop/fault did not retire durability guard')
pid=456;safe.OnChange();assert(#errors==2,'Stale process accepted live options')
pid=123
for _,c in ipairs(controls) do assert(not c.Items,'Furniture selector remains') end
e.form.OnDestroy();assert(not active and timers[1].destroyed,'Destroy did not restore boat guard')
print('PASS: boat-only menu, original controls, default durability, scoped damage guard, live options, queue/cancel, stop/close and stale-process cleanup')
