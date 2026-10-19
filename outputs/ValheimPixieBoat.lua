;(function()
local boatWindow,boatTimer,boatHelper,guard
local closed,ownRequest=false,false
local function removeGuard()
  if guard and getOpenedProcessID()==guard.pid and getProcessIDFromProcessName('valheim.exe')==guard.pid then
    local ok,err=autoAssemble(guard.script,false,guard.info)
    assert(ok,'Could not remove boat durability guard: '..tostring(err))
  end
  guard=nil
end
local function installGuard(s,h)
  if guard then assert(guard.pid==s.pid,'Game changed; reload the toolkit.');return end
  local class=pointer(mono_findClass('','WearNTear'),'Vehicle durability class')
  local entry=pointer(mono_compile_method(matchingMethod(class,'ApplyDamage',{12,18},2)),'Vehicle damage code')
  local target=pointer(mono_compile_method(h.boatProtected),'Vehicle damage guard')
  local size,replay=0,{}
  while size<14 do
    local n=getInstructionSize(entry+size);assert(n and n>0 and n<=15,'Cannot decode vehicle damage prologue')
    replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
  end
  local bytes=readBytes(entry,size,true);assert(bytes and #bytes==size,'Cannot read vehicle damage prologue')
  local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
  local original=table.concat(hex,' ')
  local restore=[[
movdqu xmm0,[rsp+60]
movdqu xmm1,[rsp+70]
movdqu xmm2,[rsp+80]
movdqu xmm3,[rsp+90]
movdqu xmm4,[rsp+A0]
movdqu xmm5,[rsp+B0]
mov rax,[rsp+58]
push rax
popfq
mov rax,[rsp+20]
mov rcx,[rsp+28]
mov rdx,[rsp+30]
mov r8,[rsp+38]
mov r9,[rsp+40]
mov r10,[rsp+48]
mov r11,[rsp+50]
lea rsp,[rsp+D8]
]]
  local script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhBoatDurability,4096)
label(vhBoatOriginal)
label(vhBoatSkip)
label(vhBoatCallback)
label(vhBoatReturn)
vhBoatDurability:
sub rsp,D8
mov [rsp+20],rax
mov [rsp+28],rcx
mov [rsp+30],rdx
mov [rsp+38],r8
mov [rsp+40],r9
mov [rsp+48],r10
mov [rsp+50],r11
pushfq
pop rax
mov [rsp+58],rax
movdqu [rsp+60],xmm0
movdqu [rsp+70],xmm1
movdqu [rsp+80],xmm2
movdqu [rsp+90],xmm3
movdqu [rsp+A0],xmm4
movdqu [rsp+B0],xmm5
mov rax,%X
mov r11,%X
cmp [rax],r11
jne vhBoatOriginal
call qword ptr [vhBoatCallback]
test al,al
jne vhBoatSkip
vhBoatOriginal:
%s%s
jmp qword ptr [vhBoatReturn]
vhBoatSkip:
%sxor eax,eax
ret
vhBoatCallback:
dq %X
vhBoatReturn:
dq %X
%X:
db FF 25 00 00 00 00
dq vhBoatDurability
%s
[DISABLE]
%X:
db %s
// Retain retired memory for callbacks that were already in flight.
]],entry,original,s.storage,s.player,restore,table.concat(replay,'\n'),restore,target,entry+size,entry,size>14 and string.format('nop %X',size-14) or '',entry,original)
  assert(playerIdentity(s),'Player changed before enabling vehicle protection')
  local ok,info=autoAssemble(script,false);assert(ok,'Boat durability guard failed: '..tostring(info))
  guard={pid=s.pid,script=script,info=info}
end
local function stopBoatUI()
  if boatHelper and getOpenedProcessID()==boatHelper.pid and getProcessIDFromProcessName('valheim.exe')==boatHelper.pid then
    if pending and pending.boat then invoke(boatHelper.cancel,0,{});pending=nil;poll.Enabled=false end
    invoke(boatHelper.boatStop,0,{})
  end
  removeGuard();if boatTimer then boatTimer.Enabled=false;if closed then boatTimer.destroy() end end
  if not closed then boatButton.Caption='Pixie boat: OFF';if boatWindow then boatWindow.hide() end end
end

local boatClose,boatDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopBoatUI();return boatClose() end
form.OnDestroy=function() closed=true;stopBoatUI();if boatWindow then boatWindow.destroy();boatWindow=nil end;boatDestroy() end
boatButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if boatWindow then boatWindow.show();return end
  boatWindow=createForm(false);boatWindow.Caption='Valheim | Pixie boat';boatWindow.Width=640;boatWindow.Height=390;boatWindow.Position='poScreenCenter'
  local guide=createLabel(boatWindow);guide.Left=16;guide.Top=16;guide.Width=595;guide.Height=90;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Enable, return to Valheim and take the helm. W/S: throttle, A/D: steer, Shift: boost. Tap Left Ctrl for a high jump. No durability loss defaults ON and protects the active boat from damage and wear while you steer or ride it. Stop restores normal boat behavior.'
  local safe=createCheckBox(boatWindow);safe.Left=16;safe.Top=112;safe.Width=595;safe.Caption='No durability loss (active boat only)';safe.Checked=true
  local toggle=createButton(boatWindow);toggle.Left=16;toggle.Top=157;toggle.Width=285;toggle.Height=34;toggle.Caption='Toggle Pixie boat'
  local stop=createButton(boatWindow);stop.Left=315;stop.Top=157;stop.Width=295;stop.Height=34;stop.Caption='Stop / restore boat'
  local text=createLabel(boatWindow);text.Left=16;text.Top=207;text.Width=595;text.Height=140;text.AutoSize=false;text.WordWrap=true;text.Caption='No durability loss: ON by default. Your boat keeps its current health; other boats and buildings are unaffected.'
  local function optionsChanged()
    if not boatHelper then return end
    action(function()
      assert(getOpenedProcessID()==boatHelper.pid and getProcessIDFromProcessName('valheim.exe')==boatHelper.pid,'Game changed; reload the toolkit.')
      invoke(boatHelper.boatOptions,0,{{type=vtDword,value=safe.Checked and 1 or 0}})
      text.Caption='Settings updated. Return to Valheim and unpause.'
    end)
  end
  safe.OnChange=optionsChanged
  toggle.OnClick=function() action(function()
    assert(not pending,'Finish or cancel the pending toolkit action first.')
    local s=context();assert(readBytes(s.player+typedPlayerOffset('m_teleporting','System.Boolean'),1)==0,'Finish teleporting first.')
    local h=loadRecovery();if hook then stopTeleport() end;installHook(s,h)
    boatHelper=h;installGuard(s,h)
    assert(playerIdentity(s) and context().world==s.world,'World/player changed before queuing the boat.')
    invoke(h.boatQueue,0,{{type=vtPointer,value=s.player},{type=vtDword,value=safe.Checked and 1 or 0},{type=vtString,value=s.world}})
    pending={session=s,recovery=h,boat=true,itemQuality=true};ownRequest=true;poll.Enabled=true;boatTimer.Enabled=true
    text.Caption='Queued. Return to Valheim and unpause.'
  end) end
  stop.OnClick=function() action(function()
    assert(not pending or pending.boat,'Finish the other pending toolkit action first.')
    stopBoatUI();boatWindow.show();text.Caption='Stop requested. Return to Valheim and unpause to restore normal boat behavior.'
  end) end
  boatTimer=createTimer(nil,false);boatTimer.Interval=500
  boatTimer.OnTimer=function()
    if not boatHelper or getOpenedProcessID()~=boatHelper.pid or getProcessIDFromProcessName('valheim.exe')~=boatHelper.pid then boatTimer.Enabled=false;if not closed then boatButton.Caption='Pixie boat: OFF';text.Caption='Game changed; reload the toolkit.' else boatTimer.destroy() end;return end
    if ownRequest and boatHelper.state then
      local good,nativeState=pcall(function() return invoke(boatHelper.state,0,{}) end)
      if good and nativeState==4 then
        ownRequest=false;local goodText,errorText=pcall(function() return invoke(boatHelper.status,0,{}) end)
        if goodText then text.Caption=type(errorText)=='string' and errorText or stringValue(pointer(errorText,'Boat activation error')) end
        local goodStatus,nativeStatus=pcall(function() return invoke(boatHelper.boatStatus,0,{}) end)
        if goodStatus and type(nativeStatus)=='string' and nativeStatus:find('OFF',1,true) then removeGuard();boatButton.Caption='Pixie boat: OFF' end
        boatTimer.Enabled=false;return
      elseif good and nativeState==3 then ownRequest=false end
    end
    local ok,result=pcall(function() return invoke(boatHelper.boatStatus,0,{}) end)
    if not ok then text.Caption=tostring(result);return end
    text.Caption=type(result)=='string' and result or stringValue(pointer(result,'Boat status'))
    local inactive=text.Caption:find('OFF',1,true) or text.Caption:find('stopped',1,true) or text.Caption:find('wait one game frame',1,true)
    boatButton.Caption=inactive and 'Pixie boat: OFF' or 'Pixie boat: ON'
    if inactive and not (pending and pending.boat) then stopBoatUI() end
  end
  if styleToggle then styleToggle(toggle,false);styleToggle(stop,false) end
  boatWindow.OnClose=function() stopBoatUI();return caHide end
  boatWindow.show()
end) end
end)()
