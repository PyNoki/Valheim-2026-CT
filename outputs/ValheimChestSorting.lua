do
local helper,timer,lastStatus
local function stopSorting()
  if pending and pending.sorting then stopTeleport() end
  if helper and getOpenedProcessID()==helper.pid and getProcessIDFromProcessName('valheim.exe')==helper.pid then invoke(helper.sortStop,0,{}) end
  if timer then timer.Enabled=false end
  sortingButton.Caption='Chest sorting: OFF'
end
sortingButton.OnClick=function()
  local ok,err=pcall(function()
    if (pending and pending.sorting) or (helper and getOpenedProcessID()==helper.pid and getProcessIDFromProcessName('valheim.exe')==helper.pid and invoke(helper.sortState,0,{})==1) then stopSorting();return end
    assert(not pending,'Finish the pending toolkit action first.')
    if not window then openTeleportWindow();window.hide() end
    local s=context();if hook then stopTeleport() end
    helper=loadRecovery();installHook(s,helper)
    invoke(helper.queue,0,{{type=vtPointer,value=s.player},{type=vtDword,value=40},{type=vtString,value=s.world}})
    pending={session=s,recovery=helper,sorting=true,itemQuality=true};poll.Enabled=true
    if not timer then
      timer=createTimer(form,false);timer.Interval=500
      timer.OnTimer=function()
        if not helper or getOpenedProcessID()~=helper.pid or getProcessIDFromProcessName('valheim.exe')~=helper.pid then timer.Enabled=false;sortingButton.Caption='Chest sorting: OFF';return end
        local good,error=pcall(function()
          local on=invoke(helper.sortState,0,{})==1
          sortingButton.Caption='Chest sorting: '..(on and 'ON' or (pending and pending.sorting and 'STARTING' or 'OFF'))
          if not pending then
            local text=readCatalogueString(invoke(helper.sortStatus,0,{}),'Chest sorting status')
            if text~=lastStatus then lastStatus=text;status.Caption=text end
          end
        end)
        if not good then status.Caption=tostring(error) end
      end
    end
    lastStatus=nil;timer.Enabled=true;sortingButton.Caption='Chest sorting: STARTING';status.Caption='Chest sorting queued. Return to Valheim and unpause. Open a chest with E, then click Chest sorting inside its interface.'
  end)
  if not ok then status.Caption=tostring(err) end
end
hint(sortingButton,'Enable once. All sorting chests share the same destinations. Open a chest with E, click Chest sorting, tick its items and Save selected items. Multiple matching chests provide overflow. F9 is also available.')
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() local ok,err=pcall(stopSorting);if not ok then status.Caption=tostring(err) end;return close() end
form.OnDestroy=function() pcall(stopSorting);destroy() end
end
