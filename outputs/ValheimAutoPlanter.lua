do
local planterWindow,helper,timer,combo,message,names
local function refreshPlants()
  helper=loadRecovery()
  names={};combo.Items.clear()
  local text=readCatalogueString(invoke(helper.plantCatalogue,0,{}),'Plant catalogue')
  for name in text:gmatch('[^\r\n]+') do names[#names+1]=name;combo.Items.add(name) end
  combo.ItemIndex=#names>0 and 0 or -1
end
planterButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if planterWindow then planterWindow.show();refreshPlants();return end
  planterWindow=createForm(false);planterWindow.Caption='Valheim | Auto planter';planterWindow.Width=610;planterWindow.Height=260;planterWindow.Position='poScreenCenter';planterWindow.Color=0x202020;planterWindow.Font.Color=0xE6E6E6
  local guide=createLabel(planterWindow);guide.Left=16;guide.Top=16;guide.Width=565;guide.Height=70;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Equip a cultivator and stand on cultivated soil. Select a plant, then Start. Fills connected cultivated ground within 20m of where you start, up to 256 plants. Uses inventory materials (unless free crafting is active) and skips occupied spots. Stay nearby with your cultivator equipped.'
  combo=createComboBox(planterWindow);combo.Left=16;combo.Top=92;combo.Width=565;combo.Style='csDropDownList'
  local start=createButton(planterWindow);start.Left=16;start.Top=132;start.Width=180;start.Height=30;start.Caption='Start planting'
  start.OnClick=function()
    local ok,err=pcall(function()
      assert(not pending,'Finish the pending toolkit action first.')
      local name=names[combo.ItemIndex+1];assert(name,'Choose a plant.')
      local s=context();if hook then stopTeleport() end;helper=loadRecovery();installHook(s,helper)
      invoke(helper.plant,0,{{type=vtPointer,value=s.player},{type=vtString,value=name},{type=vtString,value=s.world}})
      pending={session=s,recovery=helper,itemQuality=true};poll.Enabled=true;timer.Enabled=true
    end)
    message.Caption=ok and 'Queued. Return to Valheim and unpause.' or tostring(err)
  end
  local stop=createButton(planterWindow);stop.Left=208;stop.Top=132;stop.Width=180;stop.Height=30;stop.Caption='Stop planting'
  stop.OnClick=function() local ok,err=pcall(function() if pending and pending.itemQuality then stopTeleport() end;if helper then invoke(helper.plantStop,0,{}) end end);message.Caption=ok and 'Stop requested; planted crops remain.' or tostring(err) end
  local refresh=createButton(planterWindow);refresh.Left=400;refresh.Top=132;refresh.Width=180;refresh.Height=30;refresh.Caption='Refresh plants';refresh.OnClick=function() action(refreshPlants) end
  message=createLabel(planterWindow);message.Left=16;message.Top=178;message.Width=565;message.Height=54;message.AutoSize=false;message.WordWrap=true
  timer=createTimer(planterWindow,false);timer.Interval=500;timer.OnTimer=function()
    if not helper or getOpenedProcessID()~=helper.pid then timer.Enabled=false;return end
    local ok,err=pcall(function() message.Caption=readCatalogueString(invoke(helper.plantStatus,0,{}),'Auto planter status') end)
    if not ok then timer.Enabled=false;message.Caption=tostring(err) end
  end
  if styleToggle then styleToggle(start,false);styleToggle(stop,false);styleToggle(refresh,false) end
  planterWindow.OnClose=function() stop.OnClick();timer.Enabled=false;return caHide end
  refreshPlants();planterWindow.show()
end) end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() if helper then pcall(invoke,helper.plantStop,0,{}) end;if timer then timer.Enabled=false end;if planterWindow then planterWindow.hide() end;return close() end
form.OnDestroy=function() if helper then pcall(invoke,helper.plantStop,0,{}) end;if planterWindow then planterWindow.destroy() end;destroy() end
end
