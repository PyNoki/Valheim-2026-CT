from pathlib import Path
import re
import xml.etree.ElementTree as ET

# Assemble the current release from the base Lua and extension sources.
s = Path('outputs/ValheimInventory.lua').read_text(encoding='utf-8')
s = s.replace('if hook then stopTeleport();window.show() end', 'if hook then stopTeleport();if mode<=3 then window.show() end end')
s = s.replace('pending=nil;poll.Enabled=false;window.show()', 'local trophyRequest=pending and pending.trophy;local spawnRequest=pending and pending.spawn;local boatRequest=pending and pending.boat;local tamingRequest=pending and pending.taming;pending=nil;poll.Enabled=false;if tamingRequest and tamingWindow then tamingWindow.show() elseif spawnRequest and spawnWindow then spawnWindow.show() elseif not trophyRequest and not boatRequest then window.show() end')
s = s.replace("..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))", "..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))\n      if tamingRequest and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif trophyRequest and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif spawnRequest and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end")
s = s.replace('BowBeamV6','BowBeamV13')
s = re.sub(r"local helperHex='[0-9a-f]+'", "local helperHex='" + Path('outputs/ValheimBowBeamV13.dll').read_bytes().hex() + "'", s)
s = 'local styleToggle\n'+s
s = s.replace('Clear all flags', 'Remove cheated item flags')
s = s.replace('Teleport queued. Return to the game and unpause; distant areas may take 15+ seconds to load.', 'Teleport queued; carried-item restrictions are bypassed. Return to Valheim and unpause; distant areas may take 15+ seconds to load.')
s = s.replace('local function installHook(s,recovery)\n  if hook then', 'local function installHook(s,recovery)\n  if hook and recovery and not hook.recovery then ValheimTeleportStop() end\n  if hook then')
s = "if ValheimPortalItemsStop then pcall(ValheimPortalItemsStop) end\n"+s
s = s.replace('b.OnClick=fn;return b', 'b.OnClick=fn;if styleToggle then styleToggle(b) end;return b')
s = s.replace('b.OnClick=function() action(fn) end', 'b.OnClick=function() action(fn) end\n    if styleToggle then styleToggle(b) end')
s = s.replace("rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)", "rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)\n  if styleToggle then styleToggle(rowControl) end")
s = s.replace('DeathRecoveryV2', 'RecoverySpawnBetaV18')
s = s.replace("form.Caption = 'Valheim Solo Toolkit |", "form.Caption = 'Valheim 2026 CT | v26 |")
s = s.replace('Death Beam 16000/tick, 120m.', 'Death Beam 16000/tick, 2000m.')
s = s.replace('Death Beam: hold bow attack. 80m terrain excavation;', 'Death Beam: hold bow attack. 2000m surface-contact terrain excavation;')
s = re.sub(r"local recoveryHelperHex='[0-9a-f]+'", "local recoveryHelperHex='" + Path('outputs/ValheimRecoverySpawnBetaV18.dll').read_bytes().hex() + "'", s)
s = s.replace("queue=matchingMethod(class,'Queue',{18,8,14},1),", "queue=matchingMethod(class,'Queue',{18,8,14},1),summon=matchingMethod(class,'QueueSummon',{18,14,14},1),")
s = s.replace("  button('Refresh players',refreshLocations)", """  button('Refresh players',refreshLocations)
  button('Summon selected player',function()
    assert(not pending,'Another teleport, spawn or summon is pending. Finish it or cancel first.')
    local target=entries[destinations.ItemIndex+1]
    assert(target and target.source=='Player','Select a Player row after Refresh players.')
    local s=context()
    assert(target.world==s.world,'World changed. Refresh players first.')
    if hook then stopTeleport();window.show() end
    local h=loadRecovery();installHook(s,h)
    assert(playerIdentity(s) and context().world==s.world,'Player or world changed before summon.')
    invoke(h.summon,0,{{type=vtPointer,value=s.player},{type=vtString,value=target.playerID},{type=vtString,value=s.world}})
    pending={session=s,recovery=h};poll.Enabled=true
    teleportStatus.Caption='Summon queued. Return to Valheim and unpause; stand on clear ground.'
  end)""")
s = s.replace("local dragButton=createButton(form)", "local spawnButton=createButton(form)\nspawnButton.Caption='Spawn box...'\nlocal dragButton=createButton(form)")
s = s.replace("local spawnButton=createButton(form)", "local tamingButton=createButton(form)\ntamingButton.Caption='Taming...'\nlocal spawnButton=createButton(form)")
s = s.replace("local spawnButton=createButton(form)", "local trophyButton=createButton(form)\ntrophyButton.Caption='Trophy buffs...'\nlocal spawnButton=createButton(form)")
s = s.replace('local skillsH=26+12+4*(buttonH+6)+line*3+10', 'local skillsH=26+12+5*(buttonH+6)+line*3+10')
s = s.replace('place(skillStatus,group,12,10+4*(buttonH+6),cw-24,line*3)', 'place(trophyButton,group,12,10+4*(buttonH+6),cw-24,buttonH)\n        place(skillStatus,group,12,10+5*(buttonH+6),cw-24,line*3)')
s = s.replace('{dragButton}}', '{dragButton,spawnButton,tamingButton}}')
s = s.replace("local spawnButton=createButton(form)", "local boatButton=createButton(form)\nboatButton.Caption='Pixie boat...'\nlocal spawnButton=createButton(form)")
s = s.replace("local minerButton=createButton(form)", "local rapidButton=createButton(form)\nrapidButton.Caption='Rapid tools: OFF'\nlocal minerButton=createButton(form)")
s = s.replace('pair(minerButton,hoeButton,4)', 'pair(rapidButton,boatButton,4)')
s = s.replace('local freezeAll = createButton(form)', "local freezeReplenishButton=createButton(form)\nfreezeReplenishButton.Caption='Freeze inventory + replenish: OFF'\nlocal freezeAll = createButton(form)")
s = s.replace('{maxStacksButton,freezeAll,depositButton,keepFlagsButton}', '{maxStacksButton,freezeReplenishButton,keepFlagsButton}')
s = s.replace('local y=6+(row-1)*(buttonH+5)', 'local bw=row==2 and math.floor((iw-24-labelW-2*gap)/3) or bw\n      local y=6+(row-1)*(buttonH+5)')
s = s.replace('-- Persistent notices stay separate', '''-- Yellow frames remain visible regardless of ON/OFF caption changes.
local cheatWarningMarkers={}
for _,entry in ipairs({{godButton,'God mode: monster kills can flag the used item as cheated.'},
  {flightButton,'Flight: cheated alerts have been observed while using this feature.'},
  {craftingButton,'Free crafting: crafted or upgraded items may be flagged as cheated.'}}) do
  local marker=createPanel(playerGroup);marker.Caption='';marker.BevelOuter='bvNone'
  marker.ParentColor=false;marker.Color=0x00D7FF
  hint(marker,'YELLOW BORDER: This feature can trigger cheated alerts or mark items as cheated. '..entry[2])
  hint(entry[1],'CHEATED ALERT RISK: '..entry[2]..' '..(entry[1].Hint or ''))
  cheatWarningMarkers[#cheatWarningMarkers+1]={button=entry[1],marker=marker}
end
-- Persistent notices stay separate''')
s = s.replace('local y=10+4*(buttonH+6)', '''for _,entry in ipairs(cheatWarningMarkers) do
          local b=entry.button
          place(entry.marker,group,b.Left,b.Top,b.Width,buttonH)
          place(b,entry.marker,1,1,entry.marker.Width-2,buttonH-2)
        end
        local y=10+4*(buttonH+6)''')
s = s.replace("subtitle.Caption = 'Inventory loads automatically when your world is ready. Green Refresh reloads it anytime.'", "subtitle.Caption = 'Green = active. Yellow outline = cheated-alert risk. Hover or open Help for details.'")
s = s.replace('local helpText=[[', '''local helpText=[[
BUTTON COLORS
Green means a toggle is active. Gray means it is inactive or is a one-time action. Yellow outlines identify cheated-alert risks and remain visible whether a feature is active or inactive.

YELLOW BUTTON BORDERS
Yellow means this feature has a known or reported risk of triggering Valheim's cheated alerts or marking items as cheated. It is a heads-up before you turn the feature on, not a live indication that your items are already flagged.

God mode: killing monsters can flag the item used. Free crafting: crafted or upgraded items may be flagged. Flight: cheated alerts have been reported while using it.

If an item is flagged, use the inventory item-flag controls. Clearing an item flag does not erase every record of cheat use. Turning a feature off does not automatically remove existing flags.

''')
s = s.replace('label.Font.Color=0x75BDFF', 'label.Font.Color=0x00D7FF')
s = s.replace("state=matchingMethod(class,'GetState',{},8)", "animal=matchingMethod(class,'QueueAnimal',{18,14,14},1),tameCatalogue=matchingMethod(class,'TamingCatalogue',{},14),tameStatus=matchingMethod(class,'TamingStatus',{},14),tameStop=matchingMethod(class,'StopTaming',{},1),boatStop=matchingMethod(class,'StopBoat',{},1),boatStatus=matchingMethod(class,'BoatStatus',{},14),state=matchingMethod(class,'GetState',{},8)")
s = s.replace("local window, destinations, teleportStatus, locationLabel, poll", "local window, destinations, teleportStatus, locationLabel, poll, spawnWindow, spawnStatus, trophyStatus, tamingWindow, tamingStatus")
s = s.replace("teleportStatus.Caption=type(text)=='string' and text or stringValue(pointer(text,'Recovery status'))", "teleportStatus.Caption=type(text)=='string' and text or stringValue(pointer(text,'Recovery status'))\n    if pending.taming and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif pending.trophy and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif pending.spawn and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end")
s = s.replace("if window then window.hide() end\nend\nValheimTeleportStop", "if window then window.hide() end\n  if spawnWindow then spawnWindow.hide() end\nend\nValheimTeleportStop")
s = s.replace("if window then window.destroy();window=nil end;oldDestroy()", "if spawnWindow then spawnWindow.destroy();spawnWindow=nil end;if window then window.destroy();window=nil end;oldDestroy()")
marker = "teleportButton.OnClick=function() action(openTeleportWindow) end"
s = s.replace(marker, marker+'\n'+Path('outputs/ValheimReplenish.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimTaming.lua').read_text(encoding='utf-8'))
s = s.replace(marker, marker + '''
local boatWindow,boatTimer,boatHelper
local function stopBoatUI()
  boatButton.Caption='Pixie boat: OFF'
  if boatTimer then boatTimer.Enabled=false end
  if boatHelper and getOpenedProcessID()==boatHelper.pid and getProcessIDFromProcessName('valheim.exe')==boatHelper.pid then
    if pending and pending.boat then pcall(function() invoke(boatHelper.cancel,0,{}) end);pending=nil;poll.Enabled=false end
    pcall(function() invoke(boatHelper.boatStop,0,{}) end)
  end
  if boatWindow then boatWindow.hide() end
end
local boatClose,boatDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopBoatUI();return boatClose() end
form.OnDestroy=function() stopBoatUI();if boatWindow then boatWindow.destroy();boatWindow=nil end;boatDestroy() end
boatButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if boatWindow then boatWindow.show();return end
  boatWindow=createForm(false);boatWindow.Caption='Valheim | Pixie boat v4';boatWindow.Width=610;boatWindow.Height=300;boatWindow.Position='poScreenCenter'
  local guide=createLabel(boatWindow);guide.Left=16;guide.Top=16;guide.Width=560;guide.Height=90;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Enable, return to Valheim, unpause and take the helm. W/S: normal throttle settings. A/D: steer. Left Ctrl: one jump per tap (no cooldown; repeat taps allowed). Shift: boost. Land driving adds lift above terrain; rocks and buildings still collide. Only affects the boat you steer and own.'
  local toggle=createButton(boatWindow);toggle.Left=16;toggle.Top=115;toggle.Width=260;toggle.Caption='Toggle pixie boat'
  local stop=createButton(boatWindow);stop.Left=290;stop.Top=115;stop.Width=260;stop.Caption='Stop / restore boat'
  local text=createLabel(boatWindow);text.Left=16;text.Top=165;text.Width=560;text.Height=80;text.AutoSize=false;text.WordWrap=true;text.Caption='Pixie boat: OFF'
  toggle.OnClick=function() action(function() queueRecovery(6);pending.boat=true;boatHelper=hook.recovery;boatTimer.Enabled=true;text.Caption='Queued: return to Valheim and unpause.' end) end
  stop.OnClick=function() action(function()
    if pending and not pending.recovery then error('Finish or cancel the pending teleport first.') end
    if pending then cancelQueued() end
    if boatHelper then invoke(boatHelper.boatStop,0,{}) end
    boatButton.Caption='Pixie boat: OFF'
    text.Caption='Stopped. Return to Valheim and unpause to restore boat physics.'
  end) end
  boatTimer=createTimer(boatWindow,false);boatTimer.Interval=500
  boatTimer.OnTimer=function()
    if not boatHelper or getOpenedProcessID()~=boatHelper.pid or getProcessIDFromProcessName('valheim.exe')~=boatHelper.pid then boatTimer.Enabled=false;text.Caption='Game changed; reload the toolkit.';return end
    local ok,result=pcall(function() return invoke(boatHelper.boatStatus,0,{}) end)
    if ok then
      text.Caption=type(result)=='string' and result or stringValue(pointer(result,'Boat status'))
      local inactive=text.Caption:find('OFF',1,true) or text.Caption:find('stopped',1,true) or text.Caption:find('wait one game frame',1,true)
      boatButton.Caption=inactive and 'Pixie boat: OFF' or 'Pixie boat: ON'
    else boatTimer.Enabled=false;text.Caption=tostring(result) end
  end
  if styleToggle then styleToggle(toggle,false);styleToggle(stop,false) end
  boatWindow.OnClose=function() stopBoatUI();return caHide end
  boatWindow.show()
end) end
spawnButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if spawnWindow then spawnWindow.show();return end
  spawnWindow=createForm(false);spawnWindow.Caption='Valheim | Beta spawn box v2'
  spawnWindow.Width=540;spawnWindow.Height=260;spawnWindow.Position='poScreenCenter'
  local box=createGroupBox(spawnWindow);box.Caption='Spawn';box.Left=12;box.Top=12;box.Width=500;box.Height=180
  local item=createComboBox(box);item.Left=16;item.Top=28;item.Width=300;item.Style='csDropDownList'
  for _,name in ipairs({'Blueberry bush','Raspberry bush','Cloudberry bush','Lingonberry bush','Vineberry vine (Ashlands)','Vineberry vine (green)','Decorative bush','Decorative bush (Deep North)','Haldor','Hildir','Bog Witch'}) do item.Items.add(name) end;item.ItemIndex=0
  local info=createLabel(box);info.Left=16;info.Top=65;info.Width=460;info.Height=40
  info.AutoSize=false;info.WordWrap=true
  info.Caption='Plants spawn at your feet; vines need support. Merchants spawn beside you on clear ground. Return to Valheim and unpause. Spawns remain in the world; normal shop/progression requirements apply.'
  local button=createButton(box);button.Left=16;button.Top=110;button.Width=210;button.Caption='Spawn selected'
  local cancel=createButton(box);cancel.Left=240;cancel.Top=110;cancel.Width=210;cancel.Caption='Cancel queued spawn'
  cancel.OnClick=function() action(function() stopTeleport();spawnWindow.show();spawnStatus.Caption='Queue cancelled. A spawn already running may finish.' end) end
  spawnStatus=createLabel(spawnWindow);spawnStatus.Left=16;spawnStatus.Top=200
  spawnStatus.AutoSize=false;spawnStatus.WordWrap=true;spawnStatus.Width=490;spawnStatus.Height=40;spawnStatus.Caption='Ready.'
  button.OnClick=function()
    local ok,err=pcall(function() local mode=({4,20,21,22,23,24,25,26,7,8,9})[item.ItemIndex+1];assert(mode,'Select a spawn option.');queueRecovery(mode);pending.spawn=true;spawnWindow.show() end)
    spawnStatus.Caption=ok and 'Queued: return to Valheim and unpause.' or tostring(err)
  end
  if styleToggle then styleToggle(button,false);styleToggle(cancel,false) end
  spawnWindow.OnClose=function() stopTeleport();return caHide end
  spawnWindow.show()
end) end
local trophyWindow
local trophyClose,trophyDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() if trophyWindow then trophyWindow.hide() end;return trophyClose() end
form.OnDestroy=function() if trophyWindow then trophyWindow.destroy();trophyWindow=nil;trophyStatus=nil end;trophyDestroy() end
trophyButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if trophyWindow then trophyWindow.show();return end
  local buffs=createForm(false);buffs.Caption='Valheim | Trophy buffs';buffs.Width=600;buffs.Height=340;buffs.Position='poScreenCenter'
  trophyWindow=buffs
  local info=createLabel(buffs);info.Left=16;info.Top=16;info.Width=555;info.Height=58;info.AutoSize=false;info.WordWrap=true
  info.Caption='Activate a selected trophy power or all available powers together. Automatically shares with players within 10m, using native buff requests. Native durations apply; your selected forsaken power is unchanged.'
  local choice=createComboBox(buffs);choice.Left=16;choice.Top=85;choice.Width=555;choice.Style='csDropDownList'
  for _,name in ipairs({'Eikthyr','The Elder','Bonemass','Moder','Yagluth','The Queen','Fader / Ashlands','Deep North trophy power'}) do choice.Items.add(name) end;choice.ItemIndex=0
  local function queue(mode)
    local ok,err=pcall(function() queueRecovery(mode);pending.trophy=true end)
    trophyStatus.Caption=ok and 'Trophy buff queued. Return to Valheim and unpause.' or tostring(err)
  end
  local selected=createButton(buffs);selected.Left=16;selected.Top=132;selected.Width=175;selected.Caption='Activate selected';selected.OnClick=function() if choice.ItemIndex>=0 then queue(10+choice.ItemIndex) end end
  local all=createButton(buffs);all.Left=201;all.Top=132;all.Width=175;all.Caption='Activate all';all.OnClick=function() queue(18) end
  local remove=createButton(buffs);remove.Left=386;remove.Top=132;remove.Width=175;remove.Caption='Remove trophy buffs';remove.OnClick=function() queue(19) end
  local note=createLabel(buffs);note.Left=16;note.Top=183;note.Width=555;note.Height=45;note.AutoSize=false;note.WordWrap=true
  note.Caption='Nearby friends do not need the toolkit. Activate all skips unavailable powers. Remove affects only your own trophy buffs; food and other effects remain.'
  trophyStatus=createLabel(buffs);trophyStatus.Left=16;trophyStatus.Top=235;trophyStatus.Width=555;trophyStatus.Height=65;trophyStatus.AutoSize=false;trophyStatus.WordWrap=true;trophyStatus.Caption='Ready.'
  if styleToggle then styleToggle(selected,false);styleToggle(all,false);styleToggle(remove,false) end
  buffs.OnClose=function() return caHide end;buffs.show()
end) end
''')
s += '''
-- The original controls retain their helpers; one visible button coordinates both.
do
minerButton.Visible=false;hoeButton.Visible=false
hint(rapidButton,'Toggle rapid pickaxe, hoe and cultivator actions together. Includes cultivation and planting, stamina protection and tool durability refill. Normal material costs apply. Building mode disables the hoe/cultivator helper, so Rapid tools also turns off.')
hint(boatButton,'Open Pixie boat controls: faster travel, land driving and Left Ctrl jumps.')
local enabled=false
local monitor=createTimer(form,false);monitor.Interval=250
local function stopBoth()
  local minerOK,minerError=pcall(ValheimRapidMinerStop)
  local hoeOK,hoeError=pcall(ValheimRapidHoeStop)
  enabled=false;monitor.Enabled=false;rapidButton.Caption='Rapid tools: OFF'
  assert(minerOK and hoeOK,'Rapid tools cleanup failed: '..tostring(minerError or hoeError))
end
rapidButton.OnClick=function()
  local ok,err=pcall(function()
    if enabled or minerButton.Caption=='Rapid miner: ON' or hoeButton.Caption=='Rapid hoe: ON' then
      stopBoth();playerStatus.Caption='Rapid mining and rapid hoe disabled.';return
    end
    minerButton.OnClick()
    assert(minerButton.Caption=='Rapid miner: ON','Rapid mining did not enable. Check the reported error.')
    hoeButton.OnClick()
    assert(hoeButton.Caption=='Rapid hoe: ON','Rapid hoe did not enable. Check the reported error.')
    enabled=true;monitor.Enabled=true;rapidButton.Caption='Rapid tools: ON'
    playerStatus.Caption='Rapid tools enabled. Equip a pickaxe, hoe or cultivator. Normal planting/material costs apply.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopBoth)
    showMessage('Rapid tools: '..tostring(err)..(stopped and '' or (' '..tostring(stopError))))
  end
end
monitor.OnTimer=function()
  if enabled and (minerButton.Caption~='Rapid miner: ON' or hoeButton.Caption~='Rapid hoe: ON') then
    local ok,err=pcall(stopBoth)
    playerStatus.Caption=ok and 'Rapid tools stopped: a tool was disabled or the player changed.' or tostring(err)
  end
end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopBoth();return close() end
form.OnDestroy=function() stopBoth();destroy() end
end
'''
s += '''
do
freezeAll.Visible=false;depositButton.Visible=false
hint(freezeReplenishButton,'Freeze current inventory quantities and retain source stacks when dropping items or transferring to another inventory. Ctrl-click and drag deposits are supported. New stacks start unfrozen; click off/on to freeze them too.')
local enabled=false
local watch=createTimer(form,false);watch.Interval=250
local function stopCombined()
  local refillOK,refillError=pcall(ValheimAutoRefillStop)
  local freezeOK,freezeError=pcall(stopFreeze)
  enabled=false;watch.Enabled=false;freezeReplenishButton.Caption='Freeze inventory + replenish: OFF'
  assert(refillOK and freezeOK,'Inventory cleanup failed: '..tostring(refillError or freezeError))
end
freezeReplenishButton.OnClick=function()
  local ok,err=pcall(function()
    if enabled or depositButton.Caption=='Auto refill: ON' then stopCombined();status.Caption='Inventory freeze and replenish disabled.';return end
    stopFreeze();freezeAll.OnClick()
    assert(next(frozen),'No inventory stacks frozen. Load your inventory first.')
    depositButton.OnClick()
    assert(depositButton.Caption=='Auto refill: ON','Replenish failed to enable; quantities have been unfrozen.')
    enabled=true;watch.Enabled=true;freezeReplenishButton.Caption='Freeze inventory + replenish: ON'
    status.Caption='Inventory frozen. Ground drops and inventory deposits retain the source stack.'
  end)
  if not ok then local stopped,stopError=pcall(stopCombined);showMessage('Freeze + replenish: '..tostring(err)..(stopped and '' or (' '..tostring(stopError)))) end
end
watch.OnTimer=function()
  if enabled and (not next(frozen) or depositButton.Caption~='Auto refill: ON' or session~=getProcessIDFromProcessName('valheim.exe')) then
    local ok,err=pcall(stopCombined);if not ok then status.Caption=tostring(err) end
  end
end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopCombined();return close() end
form.OnDestroy=function() stopCombined();destroy() end
end
'''
s += Path('outputs/ValheimToggleStyle.lua').read_text(encoding='utf-8')
Path('outputs/ValheimBeta.lua').write_text(s, encoding='utf-8')
root = ET.fromstring(Path('Valheim 2026 CT.CT').read_bytes())
root.find('LuaScript').text = s
Path('Valheim 2026 CT.CT').write_bytes(ET.tostring(root, encoding='utf-8', xml_declaration=True))
assert ET.parse('Valheim 2026 CT.CT').findtext('LuaScript') == s
print('Valheim 2026 CT.CT packaged and XML verified.')
