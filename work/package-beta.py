from pathlib import Path
import re
import xml.etree.ElementTree as ET
import runpy

# Assemble the current release from the base Lua and extension sources.
s = Path('outputs/ValheimInventory.lua').read_text(encoding='utf-8')
s = s.replace('local edit = createButton(form)', "local maxItemQualityButton=createButton(form)\nmaxItemQualityButton.Caption='Set quality...'\nlocal edit = createButton(form)")
s = s.replace('{edit,cloneButton,freeze,refresh}', '{edit,cloneButton,maxItemQualityButton,freeze,refresh}')
s = s.replace('if hook then stopTeleport();window.show() end', 'if hook then stopTeleport();if mode<=3 then window.show() end end')
s = s.replace('pending=nil;poll.Enabled=false;window.show()', 'local trophyRequest=pending and pending.trophy;local spawnRequest=pending and pending.spawn;local boatRequest=pending and pending.boat;local tamingRequest=pending and pending.taming;local qualityRequest=pending and pending.itemQuality;pending=nil;poll.Enabled=false;if tamingRequest and tamingWindow then tamingWindow.show() elseif spawnRequest and spawnWindow then spawnWindow.show() elseif not trophyRequest and not boatRequest and not qualityRequest then window.show() end')
s = s.replace("..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))", "..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))\n      if qualityRequest then status.Caption=teleportStatus.Caption elseif tamingRequest and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif trophyRequest and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif spawnRequest and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end")
s = s.replace('BowBeamV6','BowBeamV13')
s = re.sub(r"local helperHex='[0-9a-f]+'", "local helperHex='" + Path('outputs/ValheimBowBeamV13.dll').read_bytes().hex() + "'", s)
s = 'local styleToggle\n'+s
s = 'if ValheimFixedHealthStop then ValheimFixedHealthStop() end\n'+s
s = s.replace('local staminaButton = createButton(form)', "local fixedHealthButton=createButton(form)\nfixedHealthButton.Caption='Fixed HP 999: OFF'\nlocal staminaButton = createButton(form)")
s = s.replace('God mode blocks local player damage.', 'Fixed HP 999 holds local health at 999/999 without enabling God Mode. Food timers, stamina, eitr, armor wear and hit effects continue. Normal saved HP is preserved, capped as food expires, and restored when disabled. Character saving uses normal health values. Cannot be combined with God Mode. Other cheat features and flagged items can still trigger item flags; fixed-HP item-flag behavior needs in-game verification.\n\nGod mode blocks local player damage.')
s = s.replace('Clear all flags', 'Remove cheated item flags')
s = s.replace('Teleport queued. Return to the game and unpause; distant areas may take 15+ seconds to load.', 'Teleport queued; carried-item restrictions are bypassed. Return to Valheim and unpause; distant areas may take 15+ seconds to load.')
s = s.replace('local function installHook(s,recovery)\n  if hook then', 'local function installHook(s,recovery)\n  if hook and recovery and not hook.recovery then ValheimTeleportStop() end\n  if hook then')
s = "if ValheimPortalItemsStop then pcall(ValheimPortalItemsStop) end\n"+s
s = s.replace('b.OnClick=fn;return b', 'b.OnClick=fn;if styleToggle then styleToggle(b) end;return b')
s = s.replace('b.OnClick=function() action(fn) end', 'b.OnClick=function() action(fn) end\n    if styleToggle then styleToggle(b) end')
s = s.replace("rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)", "rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)\n  if styleToggle then styleToggle(rowControl) end")
s = re.sub(r'Enemy form v[0-9]+', 'Enemy form v12', s)
s = s.replace('DeathRecoveryV2', 'RecoverySpawnBetaV42')
s = s.replace("form.Caption = 'Valheim Solo Toolkit |", "form.Caption = 'Valheim 2026 CT | v60 |")
s = s.replace('Death Beam 16000/tick, 120m.', 'Death Beam 16000/tick, 2000m.')
s = s.replace('Death Beam: hold bow attack. 80m terrain excavation;', 'Death Beam: hold bow attack. 2000m surface-contact terrain excavation;')
s = re.sub(r"local recoveryHelperHex='[0-9a-f]+'", "local recoveryHelperHex='" + Path('outputs/ValheimRecoverySpawnBetaV42.dll').read_bytes().hex() + "'", s)
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
s = s.replace('place(skillStatus,group,12,10+4*(buttonH+6),cw-24,line*3)', 'pair(minerButton,trophyButton,5)\n        place(skillStatus,group,12,10+5*(buttonH+6),cw-24,line*3)')
s = s.replace('local tamingButton=createButton(form)', "local planterButton=createButton(form)\nplanterButton.Caption='Auto planter...'\nlocal tamingButton=createButton(form)")
s = s.replace('local tamingButton=createButton(form)', "local sortingButton=createButton(form)\nsortingButton.Caption='Chest sorting: OFF'\nlocal tamingButton=createButton(form)")
s = s.replace('{dragButton}}', '{dragButton,spawnButton,tamingButton,planterButton,sortingButton}}')
s = s.replace("local spawnButton=createButton(form)", "local boatButton=createButton(form)\nboatButton.Caption='Pixie boat...'\nlocal spawnButton=createButton(form)")
s = s.replace("local minerButton=createButton(form)", "local rapidButton=createButton(form)\nrapidButton.Caption='Rapid tools: OFF'\nlocal minerButton=createButton(form)")
s = s.replace('pair(minerButton,hoeButton,4)', 'pair(rapidButton,boatButton,4)')
s = s.replace('local freezeAll = createButton(form)', "local lootMagnetButton=createButton(form)\nlootMagnetButton.Caption='Loot magnet...'\nlocal freezeReplenishButton=createButton(form)\nfreezeReplenishButton.Caption='Freeze inventory + replenish: OFF'\nlocal freezeAll = createButton(form)")
s = s.replace('{maxStacksButton,freezeAll,depositButton,keepFlagsButton}', '{maxStacksButton,freezeReplenishButton,keepFlagsButton,lootMagnetButton}')
s = s.replace('local y=6+(row-1)*(buttonH+5)', '      local y=6+(row-1)*(buttonH+5)')
s = s.replace('-- Persistent notices stay separate', '''-- Yellow frames remain visible regardless of ON/OFF caption changes.
local cheatWarningMarkers={}
for _,entry in ipairs({{flightButton,'Flight: cheated alerts have been observed while using this feature.'},
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
FARMING AND LOOT
Auto harvest is in Auto planter: harvests ripe cultivator crops on cultivated ground within 20m and attracts their native drops. Growth timers are not changed. Close the farming window to stop both farming controls.
Inventory Loot magnet has separate cheated-only and all-loot toggles (one mode at a time), with a 5-500m radius. Only loaded loose drops are collected; flags stay unchanged. Full inventories, placed items, protected loot and tar-stuck drops are skipped. Close the magnet window to stop it.

BUTTON COLORS
Green means a toggle is active. Gray means it is inactive or is a one-time action. Yellow outlines identify cheated-alert risks and remain visible whether a feature is active or inactive.

YELLOW BUTTON BORDERS
Yellow means this feature has a known or reported risk of triggering Valheim's cheated alerts or marking items as cheated. It is a heads-up before you turn the feature on, not a live indication that your items are already flagged.

God mode: killing monsters can flag the item used. Free crafting: crafted or upgraded items may be flagged. Flight: cheated alerts have been reported while using it.

Set quality: choose equipment quality 1-1000, including refinement levels beyond the normal cap. This edit does not set the cheated flag and preserves any existing flag.

If an item is flagged, use the inventory item-flag controls. Clearing an item flag does not erase every record of cheat use. Turning a feature off does not automatically remove existing flags.

''')
s = s.replace('label.Font.Color=0x75BDFF', 'label.Font.Color=0x00D7FF')
s = s.replace("state=matchingMethod(class,'GetState',{},8)", "sortState=matchingMethod(class,'SortingState',{},8),sortStop=matchingMethod(class,'StopSorting',{},1),sortStatus=matchingMethod(class,'SortingStatus',{},14),clearState=matchingMethod(class,'ClearState',{},8),clearStop=matchingMethod(class,'StopClear',{},1),loot=matchingMethod(class,'QueueLoot',{18,8,8,14},1),lootState=matchingMethod(class,'LootState',{},8),lootStop=matchingMethod(class,'StopLoot',{},1),harvestStop=matchingMethod(class,'StopHarvest',{},1),magnetStop=matchingMethod(class,'StopMagnet',{},1),harvestStatus=matchingMethod(class,'HarvestStatus',{},14),magnetStatus=matchingMethod(class,'MagnetStatus',{},14),plant=matchingMethod(class,'QueuePlant',{18,14,14},1),plantCatalogue=matchingMethod(class,'PlantCatalogue',{},14),plantStatus=matchingMethod(class,'PlantStatus',{},14),plantStop=matchingMethod(class,'StopPlant',{},1),quality=matchingMethod(class,'QueueItemQuality',{18,18,8,14},1),prefab=matchingMethod(class,'QueuePrefab',{18,14,8,8,14},1),spawnCatalogue=matchingMethod(class,'SpawnCatalogue',{},14),animal=matchingMethod(class,'QueueAnimal',{18,14,14},1),tameCatalogue=matchingMethod(class,'TamingCatalogue',{},14),tameStatus=matchingMethod(class,'TamingStatus',{},14),tameStop=matchingMethod(class,'StopTaming',{},1),boatQueue=matchingMethod(class,'QueueBoat',{18,8,14},1),boatOptions=matchingMethod(class,'SetBoatOptions',{8},1),boatProtected=matchingMethod(class,'BoatProtected',{18},2),boatStop=matchingMethod(class,'StopBoat',{},1),boatStatus=matchingMethod(class,'BoatStatus',{},14),state=matchingMethod(class,'GetState',{},8)")
s = s.replace("local window, destinations, teleportStatus, locationLabel, poll", "local window, destinations, teleportStatus, locationLabel, poll, spawnWindow, spawnStatus, trophyStatus, tamingWindow, tamingStatus")
s = s.replace("teleportStatus.Caption=type(text)=='string' and text or stringValue(pointer(text,'Recovery status'))", "teleportStatus.Caption=type(text)=='string' and text or stringValue(pointer(text,'Recovery status'))\n    if pending.itemQuality then status.Caption=teleportStatus.Caption elseif pending.taming and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif pending.trophy and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif pending.spawn and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end")
s = s.replace("if window then window.hide() end\nend\nValheimTeleportStop", "if window then window.hide() end\n  if spawnWindow then spawnWindow.hide() end\nend\nValheimTeleportStop")
s = s.replace("if window then window.destroy();window=nil end;oldDestroy()", "if spawnWindow then spawnWindow.destroy();spawnWindow=nil end;if window then window.destroy();window=nil end;oldDestroy()")
marker = "teleportButton.OnClick=function() action(openTeleportWindow) end"
s = s.replace(marker, marker+'\n;(function()\n'+Path('outputs/ValheimReplenish.lua').read_text(encoding='utf-8')+'\nend)()\n;(function()\n'+Path('outputs/ValheimSpawn.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimTaming.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimItemQuality.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimClearView.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimLootMagnet.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimAutoPlanter.lua').read_text(encoding='utf-8')+'\n'+Path('outputs/ValheimChestSorting.lua').read_text(encoding='utf-8')+'\nend)()\n')
s = s.replace(marker, marker+'\n'+Path('outputs/ValheimPixieBoat.lua').read_text(encoding='utf-8')+'\n')
s = s.replace(marker, marker + '''
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
  info.Caption='Activate trophy powers and refresh your Rested to maximum build-piece comfort duration. Shares powers and Rested within 10m. Friends use their own comfort duration; trophy powers keep native durations.'
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
  note.Caption='Friends need no toolkit. Activate all skips unavailable powers. Remove affects your trophy powers only; Rested and food remain. This applies through these activation buttons.'
  trophyStatus=createLabel(buffs);trophyStatus.Left=16;trophyStatus.Top=235;trophyStatus.Width=555;trophyStatus.Height=65;trophyStatus.AutoSize=false;trophyStatus.WordWrap=true;trophyStatus.Caption='Ready.'
  if styleToggle then styleToggle(selected,false);styleToggle(all,false);styleToggle(remove,false) end
  buffs.OnClose=function() return caHide end;buffs.show()
end) end
''')
s += '''
-- The original controls retain their helpers; one visible button coordinates both.
do
hoeButton.Visible=false
hint(rapidButton,'Toggle Fast attacks and rapid hoe/cultivator actions together. Fast attacks covers melee weapons, bows, crossbows, magic weapons and pickaxes with stamina and durability refill. Normal material costs apply. Building mode disables the hoe/cultivator helper, so Rapid tools also turns off.')
hint(boatButton,'Take the boat helm: W/S throttle, A/D steer, Shift boost, tap Left Ctrl to jump. No durability loss defaults ON. Stop restores normal boat behavior.')
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
    if enabled or hoeButton.Caption=='Rapid hoe: ON' then
      stopBoth();playerStatus.Caption='Fast attacks and rapid hoe disabled.';return
    end
    if minerButton.Caption~='Fast attacks: ON' then minerButton.OnClick() end
    assert(minerButton.Caption=='Fast attacks: ON','Fast attacks did not enable. Check the reported error.')
    hoeButton.OnClick()
    assert(hoeButton.Caption=='Rapid hoe: ON','Rapid hoe did not enable. Check the reported error.')
    enabled=true;monitor.Enabled=true;rapidButton.Caption='Rapid tools: ON'
    playerStatus.Caption='Rapid tools enabled: Fast attacks plus rapid hoe/cultivator actions. Normal planting/material costs apply.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopBoth)
    showMessage('Rapid tools: '..tostring(err)..(stopped and '' or (' '..tostring(stopError))))
  end
end
monitor.OnTimer=function()
  if enabled and (minerButton.Caption~='Fast attacks: ON' or hoeButton.Caption~='Rapid hoe: ON') then
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
s=s.replace('local beamButton=createButton(form)', "local clearViewButton=createButton(form)\nclearViewButton.Caption='Clear weather: OFF'\nlocal beamButton=createButton(form)")
s=s.replace('beamButton.Width=math.max(100,beamButton.Width-88)', '')
s=s.replace('place(kayokenCheck,group,beamButton.Left+beamButton.Width+6,beamButton.Top,82,buttonH)', 'kayokenCheck.Visible=false')
s=re.sub(r'KAYOKEN\n.*?\n\nPLAYER TOGGLES', 'PLAYER TOGGLES', s, flags=re.S)
s=s.replace("kayokenCheck.Caption='Kayoken';kayokenCheck.Checked=false;kayokenCheck.Enabled=false","kayokenCheck.Caption='';kayokenCheck.Checked=false;kayokenCheck.Enabled=false;kayokenCheck.Visible=false")
s=s.replace('pair(godButton,staminaButton,1)', 'pair(fixedHealthButton,staminaButton,1)')
s=s.replace('local y=10+4*(buttonH+6)', 'place(clearViewButton,group,12,10+4*(buttonH+6),cw-24,buttonH)\n        local y=10+5*(buttonH+6)')
s=s.replace('26+12+4*(buttonH+6)+line*2', '26+12+5*(buttonH+6)+line*2')
# Fixed health replaces the legacy God Mode control in the release UI.
s=s.replace("godButton.Caption = 'God mode: OFF'", "godButton.Caption = '';godButton.Visible=false")
s=s.replace("godWarning.Caption='GOD MODE: Monster kills can flag the used item as cheated.'", "godWarning.Caption='';godWarning.Visible=false")
s=s.replace('place(godWarning,group,12,y,cw-24,warningH)', 'godWarning.Visible=false')
s=s.replace('place(craftingWarning,group,12,y+warningH,cw-24,warningH)', 'place(craftingWarning,group,12,y,cw-24,warningH)')
s=s.replace('place(flagWarningHelp,group,12,y+warningH*2,cw-24,warningH)', 'place(flagWarningHelp,group,12,y+warningH,cw-24,warningH)')
s=s.replace('warningH*3+8', 'warningH*2+8')
s=s.replace('ITEM FLAGS AND GOD MODE\nValheim can flag items as cheated when you kill monsters with them while God mode is enabled. The item flag controls are provided to manage that flag.', 'ITEM FLAGS')
s=s.replace('God mode: killing monsters can flag the item used. ', '')
s=s.replace('without enabling God Mode. ', '')
s=s.replace('999/999 Food timers', '999/999. Food timers')
s=re.sub(r"  \{godButton,'Block local player damage\.[^\n]*\n", '', s)
s=s.replace('Cannot be combined with God Mode. Other cheat features and flagged items can still trigger item flags; fixed-HP item-flag behavior needs in-game verification.\n\nGod mode blocks local player damage. See the item-flag notice above.', '')
s += Path('outputs/ValheimFixedHealth.lua').read_text(encoding='utf-8')
s = 'if ValheimUnlimitedResourcesStop then ValheimUnlimitedResourcesStop() end\n'+s
s=s.replace('Unlimited stamina replenishes stamina while active.', 'Unlimited resources covers stamina, eitr, adrenaline, ability health costs and summon-control limits, including Dead raiser. It works without eitr food. Normal incoming damage, ammo, materials and ability cooldowns remain. Disabling restores normal costs; refilled pools remain.')
s += Path('outputs/ValheimUnlimitedResources.lua').read_text(encoding='utf-8')
s += Path('outputs/ValheimToggleStyle.lua').read_text(encoding='utf-8').replace('spawnButton,tamingButton,trophyButton','spawnButton,tamingButton,planterButton,trophyButton').replace('resetMovementButton,teleportButton','lootMagnetButton,resetMovementButton,teleportButton').replace('staminaButton,craftingButton','fixedHealthButton,clearViewButton,staminaButton,craftingButton')
s=re.sub(r'[ \t]+\n','\n',s)
Path('outputs/ValheimBeta.lua').write_text(s, encoding='utf-8')
root = ET.fromstring(Path('Valheim 2026 CT.CT').read_bytes())
root.find('LuaScript').text = s
Path('Valheim 2026 CT.CT').write_bytes(ET.tostring(root, encoding='utf-8', xml_declaration=True))
assert ET.parse('Valheim 2026 CT.CT').findtext('LuaScript') == s
runpy.run_path('work/audit-helper-bindings.py', run_name='__main__')
print('Valheim 2026 CT.CT packaged and XML verified.')
