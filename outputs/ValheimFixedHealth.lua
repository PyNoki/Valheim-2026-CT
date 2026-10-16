-- Local-player health overlay. Native food maxima and saved HP remain ordinary.
-- Windows x64 Mono: this=RCX, float argument=XMM1, float result=XMM0.
do
local active
local watch=createTimer(form,false);watch.Interval=100
local function stopHealth()
  if active then
    local s=active
    if getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
      local ok,err=autoAssemble(s.script,false,s.info)
      assert(ok,'Cannot remove fixed health hooks: '..tostring(err))
    end
    active=nil
  end
  watch.Enabled=false;fixedHealthButton.Caption='Fixed HP 999: OFF'
end
ValheimFixedHealthStop=stopHealth
local function alive(s)
  local dead=invoke(s.isDead,s.player,{})
  assert(dead==true or dead==false or dead==0 or dead==1,'Unreadable player death state')
  return dead==false or dead==0
end
local function enableHealth()
  local s=playerContext()
  assert(readBytes(s.player+typedPlayerOffset('m_godMode','System.Boolean'),1)==0,
    'Turn off God Mode before enabling fixed health.')
  s.isDead=matchingMethod(playerClass,'IsDead',{},2)
  assert(alive(s),'Wait until your player has finished respawning.')
  local deadCheck=pointer(mono_compile_method(s.isDead),'Player.IsDead')
  local class=pointer(mono_findClass('','Character'),'Character class')
  -- Player.Save serializes both getters. Return native values to that caller,
  -- so the overlay never enters the character file, even while enabled.
  local save=pointer(mono_compile_method(matchingMethod(playerClass,'Save',{18},1)),'Player.Save')
  local saveInfo=mono_getJitInfo(save)
  assert(saveInfo and saveInfo.code_start==save and saveInfo.code_size>0,'Cannot identify character save code')
  local hud=pointer(mono_findClass('','Hud'),'HUD class')
  local definitions={{'GetHealth',{},12},{'GetMaxHealth',{},12},{'SetHealth',{12},1},{'SetHealthBarSize',{12},1,hud}}
  local enable,disable={'[ENABLE]'},{'[DISABLE]'}
  local entries={}
  for i,d in ipairs(definitions) do
    local entry=pointer(mono_compile_method(matchingMethod(d[4] or class,d[1],d[2],d[3])),'Health method')
    for _,previous in ipairs(entries) do assert(previous.entry~=entry,'Health methods share a native entry') end
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode health method prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true);assert(bytes and #bytes==size,'Cannot read health method')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    entries[i]={entry=entry,size=size,replay=table.concat(replay,'\n'),original=table.concat(hex,' ')}
    local name='vhFixedHP'..i
    enable[#enable+1]=string.format('assert(%X,%s)\nalloc(%s,2048,%X)\nlabel(%sOriginal)\nlabel(%sOriginalGuard)',entry,entries[i].original,name,entry,name,name)
    if i~=4 then enable[#enable+1]=string.format('label(%sLocal)\nlabel(%sLocalGuard)',name,name) end
    disable[#disable+1]=string.format('%X:\ndb %s',entry,entries[i].original)
  end
  enable[#enable+1]='label(vhFixedHP1Return)'
  enable[#enable+1]='label(vhFixedHPHud25)\nlabel(vhFixedHPHud32)'
  for i,e in ipairs(entries) do
    local name='vhFixedHP'..i
    if i==4 then
      -- Hud.UpdateHealth sizes the bar as maxHP / 25 * 32. Keep that native
      -- calculation tied to food HP, without changing the 999 value/fill.
      enable[#enable+1]=string.format([[
%s:
pushfq
push rax
mov rax,%X
mov rax,[rax]
push rcx
mov rcx,%X
cmp rax,rcx
pop rcx
jne %sOriginalGuard
pop rax
popfq
sub rsp,38
mov [rsp+20],rcx
mov rcx,%X
call vhFixedHP2Original
divss xmm0,[vhFixedHPHud25]
mulss xmm0,[vhFixedHPHud32]
movss xmm1,xmm0
mov rcx,[rsp+20]
add rsp,38
jmp %sOriginal
%sOriginalGuard:
pop rax
popfq
jmp %sOriginal
vhFixedHPHud25:
dd (float)25
vhFixedHPHud32:
dd (float)32
]],name,s.storage,s.player,name,s.player,name,name,name)
    else
    enable[#enable+1]=string.format([[
%s:
pushfq
push rax
mov rax,%X
cmp rcx,rax
jne %sOriginalGuard
mov rax,%X
cmp [rax],rcx
jne %sOriginalGuard
// Preserve this and the health setter float across the native death check.
sub rsp,38
mov [rsp+20],rcx
movss [rsp+28],xmm1
call %X
test al,al
movss xmm1,[rsp+28]
mov rcx,[rsp+20]
lea rsp,[rsp+38]
jne %sOriginalGuard
mov rax,%X
cmp [rsp+10],rax
jb %sLocalGuard
mov rax,%X
cmp [rsp+10],rax
jb %sOriginalGuard
%sLocalGuard:
pop rax
popfq
jmp %sLocal
%sOriginalGuard:
pop rax
popfq
jmp %sOriginal
%sLocal:
]],name,s.player,name,s.storage,name,deadCheck,name,save,name,save+saveInfo.code_size,name,name,name,name,name,name)
    if i==1 then
      -- Bypass our own hooks for native storage maintenance. Only clamp excess
      -- saved HP after food expires; never persist 999 or refill normal HP.
      enable[#enable+1]=[[
sub rsp,38
mov [rsp+20],rcx
call vhFixedHP1Original
movss [rsp+28],xmm0
mov rcx,[rsp+20]
call vhFixedHP2Original
comiss xmm0,[rsp+28]
jae vhFixedHP1Return
movss xmm1,xmm0
mov rcx,[rsp+20]
call vhFixedHP3Original
vhFixedHP1Return:
add rsp,38
mov eax,4479C000
movd xmm0,eax
ret
]]
    elseif i==2 then
      enable[#enable+1]='mov eax,4479C000\nmovd xmm0,eax\nret'
    else
      enable[#enable+1]='ret'
    end
    end
    enable[#enable+1]=string.format('%sOriginal:\n%s\njmp %X\n%X:\ndb FF 25 00 00 00 00\ndq %s\n%s',
      name,e.replay,e.entry+e.size,e.entry,name,e.size>14 and string.format('nop %X',e.size-14) or '')
  end
  -- Retain retired trampolines: game calls may still be returning through them.
  local script=table.concat(enable,'\n')..'\n'..table.concat(disable,'\n')
  assert(playerIdentity(s) and alive(s),'Player changed while preparing health hooks')
  local ok,info=autoAssemble(script,false);assert(ok,'Fixed health installation failed: '..tostring(info))
  s.script=script;s.info=info;active=s
  watch.Enabled=true;fixedHealthButton.Caption='Fixed HP 999: ON'
  playerStatus.Caption='Fixed HP: 999/999. Food, stamina, eitr and hit effects continue normally.'
end
fixedHealthButton.OnClick=function()
  local ok,err=pcall(function() if active then stopHealth();playerStatus.Caption='Normal food-based health restored.' else enableHealth() end end)
  if not ok then showMessage('Fixed health: '..tostring(err)) end
end
watch.OnTimer=function()
  local ok,available=pcall(function() return active and playerIdentity(active) and alive(active) end)
  if active and (not ok or not available) then
    local ok,err=pcall(stopHealth)
    playerStatus.Caption=ok and 'Fixed health stopped: player changed or world unloaded.' or tostring(err)
  end
end
local godClick=godButton.OnClick
godButton.OnClick=function()
  local ok,err=pcall(stopHealth)
  if not ok then showMessage(tostring(err));return end
  godClick()
end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopHealth();return close() end
form.OnDestroy=function() stopHealth();destroy() end
hint(fixedHealthButton,'Hold local HP at 999/999. The health bar keeps its normal food-based size. Food timers, stamina, eitr, armor wear, stagger and hit effects continue. Normal saved HP is preserved and capped as food expires; disabling restores it.')
end
