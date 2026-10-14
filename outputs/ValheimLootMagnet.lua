local function queueLootAction(mode,radius)
  assert(not pending,'Finish the pending toolkit action first.')
  if not window then openTeleportWindow();window.hide() end
  local s=context();if hook then stopTeleport() end
  local h=loadRecovery();installHook(s,h)
  invoke(h.loot,0,{{type=vtPointer,value=s.player},{type=vtDword,value=mode},{type=vtDword,value=radius},{type=vtString,value=s.world}})
  pending={session=s,recovery=h,itemQuality=true,lootMode=mode};poll.Enabled=true
  return h
end
do
local magnetWindow,helper,timer,cheated,all,radius,message
lootMagnetButton.OnClick=function() action(function()
  if magnetWindow then magnetWindow.show();timer.Enabled=true;return end
  magnetWindow=createForm(false);magnetWindow.Caption='Valheim | Loot magnet';magnetWindow.Width=620;magnetWindow.Height=315;magnetWindow.Position='poScreenCenter';magnetWindow.Color=0x202020;magnetWindow.Font.Color=0xE6E6E6
  local guide=createLabel(magnetWindow);guide.Left=16;guide.Top=16;guide.Width=580;guide.Height=64;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Attract loose loot drops into your inventory. Choose cheated items only or all drops; only one mode runs at a time. Only loaded world items are available. Placed items, protected drops and drops that cannot fit stay in the world.'
  local label=createLabel(magnetWindow);label.Left=16;label.Top=92;label.Caption='Radius (5-500 metres):'
  radius=createEdit(magnetWindow);radius.Left=210;radius.Top=86;radius.Width=100;radius.Text='100'
  cheated=createButton(magnetWindow);cheated.Left=16;cheated.Top=128;cheated.Width=280;cheated.Height=32;cheated.Caption='Cheated items only: OFF'
  all=createButton(magnetWindow);all.Left=310;all.Top=128;all.Width=280;all.Height=32;all.Caption='All loot drops: OFF'
  local function toggle(mode)
    local ok,err=pcall(function()
      local metres=tonumber(radius.Text);assert(metres and metres==math.floor(metres) and metres>=5 and metres<=500,'Enter a whole radius from 5 to 500 metres.')
      helper=queueLootAction(mode,metres);timer.Enabled=true
    end)
    message.Caption=ok and 'Queued. Return to Valheim and unpause.' or tostring(err)
  end
  cheated.OnClick=function() toggle(37) end;all.OnClick=function() toggle(38) end
  local stop=createButton(magnetWindow);stop.Left=16;stop.Top=172;stop.Width=574;stop.Height=30;stop.Caption='Stop loot magnet'
  stop.OnClick=function() if pending and (pending.lootMode==37 or pending.lootMode==38) then stopTeleport() end;if helper then pcall(invoke,helper.magnetStop,0,{}) end;cheated.Caption='Cheated items only: OFF';all.Caption='All loot drops: OFF';message.Caption='Loot magnet stopped.' end
  message=createLabel(magnetWindow);message.Left=16;message.Top=216;message.Width=574;message.Height=65;message.AutoSize=false;message.WordWrap=true;message.Caption='Select a collection mode.'
  timer=createTimer(magnetWindow,false);timer.Interval=300;timer.OnTimer=function()
    if not helper then return end
    if getOpenedProcessID()~=helper.pid or getProcessIDFromProcessName('valheim.exe')~=helper.pid then timer.Enabled=false;cheated.Caption='Cheated items only: OFF';all.Caption='All loot drops: OFF';return end
    local ok,err=pcall(function()
      local bits=invoke(helper.lootState,0,{});local mode=math.floor(bits/2)
      cheated.Caption='Cheated items only: '..(mode==1 and 'ON' or 'OFF');all.Caption='All loot drops: '..(mode==2 and 'ON' or 'OFF')
      if not pending then message.Caption=readCatalogueString(invoke(helper.magnetStatus,0,{}),'Magnet status') end
    end)
    if not ok then timer.Enabled=false;message.Caption=tostring(err) end
  end
  if styleToggle then styleToggle(cheated,true);styleToggle(all,true);styleToggle(stop,false) end
  magnetWindow.OnClose=function() stop.OnClick();timer.Enabled=false;return caHide end
  magnetWindow.show()
end) end
local close,destroy=form.OnClose,form.OnDestroy
local function cleanup() if helper then pcall(invoke,helper.lootStop,0,{}) end;if timer then timer.Enabled=false end end
form.OnClose=function() cleanup();if magnetWindow then magnetWindow.hide() end;return close() end
form.OnDestroy=function() cleanup();if magnetWindow then magnetWindow.destroy() end;destroy() end
end
