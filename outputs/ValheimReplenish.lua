-- Installed only while the combined inventory toggle is active.
local replenishHooks
local function removeReplenish()
  if replenishHooks then
    local h=replenishHooks
    if getOpenedProcessID()==h.pid and getProcessIDFromProcessName('valheim.exe')==h.pid then
      local ok,err=autoAssemble(h.script,false,h.info)
      assert(ok,'Cannot remove replenish hooks: '..tostring(err))
    end
    replenishHooks=nil
  end
  depositButton.Caption='Auto refill: OFF'
end
ValheimAutoRefillStop=removeReplenish
local function installReplenish()
  assert(not replenishHooks,'Replenish already enabled.')
  if not session then initialize() end
  snapshot()
  local h=loadRecovery()
  local class=pointer(mono_findClass('ValheimSoloToolkit','RecoverySpawnBetaV14'),'Replenish helper')
  local prepare=pointer(mono_compile_method(matchingMethod(class,'PrepareTransfer',{18,18,18},18)),'Prepare transfer')
  local copy=pointer(mono_compile_method(matchingMethod(class,'PreparedCopy',{},18)),'Prepared copy')
  local drop=pointer(mono_compile_method(matchingMethod(class,'DropReplenished',{18,18,18,8},8)),'Replenished drop')
  local inventory=pointer(mono_findClass('','Inventory'),'Inventory class')
  local humanoid=pointer(mono_findClass('','Humanoid'),'Humanoid class')
  local methods={matchingMethod(inventory,'MoveItemToThis',{18,18},1),matchingMethod(inventory,'MoveItemToThis',{18,18,8,8,8},2),matchingMethod(humanoid,'DropItem',{18,18,8},2)}
  local enable,disable={'[ENABLE]'},{'[DISABLE]'}
  local save=[[
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
]]
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
  for i,method in ipairs(methods) do
    local entry=pointer(mono_compile_method(method),'Replenish entry')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size);assert(n and n>0 and n<=15,'Cannot decode replenish entry')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true);assert(bytes and #bytes==size,'Cannot read replenish entry')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    local name='vhRep'..i
    enable[#enable+1]=string.format('assert(%X,%s)\nalloc(%s,4096,%X)\nlabel(%sPass)\nlabel(%sExit)\n%s:\n%s',entry,original,name,entry,name,name,name,save)
    if i<3 then
      enable[#enable+1]=string.format([[
call %X
test rax,rax
je %sPass
mov [rsp+C0],rax
call %X
test rax,rax
je %sPass
mov [rsp+38],rax
mov rax,[rsp+C0]
mov [rsp+30],rax
jmp %sPass
]],prepare,name,copy,name,name)
    else
      enable[#enable+1]=string.format('call %X\ncmp eax,0\njl %sPass\nmov [rsp+20],rax\njmp %sExit\n',drop,name,name)
    end
    enable[#enable+1]=string.format('%sPass:\n%s\n%s\njmp %X\n%sExit:\n%s\nret\n%X:\ndb FF 25 00 00 00 00\ndq %s\n%s',name,restore,table.concat(replay,'\n'),entry+size,name,restore,entry,name,size>14 and string.format('nop %X',size-14) or '')
    -- Retain retired allocations until process exit: an in-flight game call may return.
    disable[#disable+1]=string.format('%X:\ndb %s',entry,original)
  end
  local script=table.concat(enable,'\n')..'\n'..table.concat(disable,'\n')
  local ok,info=autoAssemble(script,false);assert(ok,'Replenish installation failed: '..tostring(info))
  replenishHooks={pid=session,script=script,info=info}
  depositButton.Caption='Auto refill: ON'
end
local closeReplenish,destroyReplenish=form.OnClose,form.OnDestroy
form.OnClose=function() removeReplenish();return closeReplenish() end
form.OnDestroy=function() removeReplenish();destroyReplenish() end
depositButton.OnClick=function()
  local ok,err=pcall(function() if replenishHooks then removeReplenish() else installReplenish() end end)
  if not ok then showMessage('Replenish: '..tostring(err)) end
end
