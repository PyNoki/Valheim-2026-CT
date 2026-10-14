do
local helper
local timer=createTimer(form,false)
timer.Interval=300
clearViewButton.OnClick=function()
  local ok,err=pcall(function()
    assert(not pending,'Finish the pending toolkit action first.')
    if not window then openTeleportWindow();window.hide() end
    local s=context();if hook then stopTeleport() end
    helper=loadRecovery();installHook(s,helper)
    invoke(helper.queue,0,{{type=vtPointer,value=s.player},{type=vtDword,value=39},{type=vtString,value=s.world}})
    pending={session=s,recovery=helper,itemQuality=true};poll.Enabled=true;timer.Enabled=true
    playerStatus.Caption='Clear weather queued. Return to Valheim and unpause.'
  end)
  if not ok then playerStatus.Caption=tostring(err) end
end
hint(clearViewButton,'Toggle clear local weather and remove fog and Mistlands mist for visibility. Turn off or close the toolkit to restore the previous environment. Does not change server-wide weather.')
timer.OnTimer=function()
  if not helper or getOpenedProcessID()~=helper.pid or getProcessIDFromProcessName('valheim.exe')~=helper.pid then timer.Enabled=false;clearViewButton.Caption='Clear weather: OFF';return end
  local ok,value=pcall(invoke,helper.clearState,0,{})
  if not ok then timer.Enabled=false;return end
  clearViewButton.Caption='Clear weather: '..(value==1 and 'ON' or 'OFF')
end
local close,destroy=form.OnClose,form.OnDestroy
local function cleanup() timer.Enabled=false;if helper and getOpenedProcessID()==helper.pid then pcall(invoke,helper.clearStop,0,{}) end end
form.OnClose=function() cleanup();return close() end
form.OnDestroy=function() cleanup();destroy() end
end
