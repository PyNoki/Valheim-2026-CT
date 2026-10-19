if ValheimUnlimitedResourcesStop then ValheimUnlimitedResourcesStop() end
if ValheimPortalItemsStop then pcall(ValheimPortalItemsStop) end
if ValheimFixedHealthStop then ValheimFixedHealthStop() end
local styleToggle
-- Every generated hook supports allocations outside the relative 2 GB range.
-- Keep this local so unrelated Cheat Engine tables retain their own assembler.
local function prepareAssembly(script)
  if type(script)=='string' then
    script=script:gsub('alloc%(([%w_]+),%s*([%x]+),%s*([%x]+)%)','alloc(%1,%2)')
    -- Inline pointer slots avoid register clobbering and additional allocations.
    -- CALL returns to EB 08, which skips its eight-byte destination pointer.
    script=script:gsub('[^\r\n]+',function(line)
      local indent,op,address=line:match('^([ \t]*)(%a+)%s+([%x]+)%s*$')
      if op=='call' then return indent..'db FF 15 02 00 00 00 EB 08\n'..indent..'dq '..address end
      if op=='jmp' then return indent..'db FF 25 00 00 00 00\n'..indent..'dq '..address end
      return line
    end)
    assert(not script:match('alloc%([^%)]+,[^%)]+,'),'Unsupported nearby allocation in hook')
  end
  return script
end
local function autoAssemble(script,...)
  return _G.autoAssemble(prepareAssembly(script),...)
end
local function autoAssembleCheck(script,enable,targetself)
  return _G.autoAssembleCheck(prepareAssembly(script),enable,targetself)
end
-- Valheim inventory editor prototype for Cheat Engine 7.6, 64-bit Mono.
-- Inventory freeze uses a validated timer; god mode adds a local-player damage hook.
-- Mono x64 array/string layouts are validated before use.
if ValheimInventoryStop then pcall(ValheimInventoryStop) end
if ValheimPlayerCheatsStop then pcall(ValheimPlayerCheatsStop) end
if ValheimAutoRefillStop then ValheimAutoRefillStop() end
if ValheimItemFlagsStop then ValheimItemFlagsStop() end
if ValheimMovementStop then ValheimMovementStop() end
if ValheimTeleportStop then ValheimTeleportStop() end
if ValheimExplosiveFistsStop then ValheimExplosiveFistsStop(); ValheimExplosiveFistsStop=nil end
if ValheimDragBuildStop then ValheimDragBuildStop() end
if ValheimBowBeamStop then ValheimBowBeamStop() end
if ValheimCarryStop then ValheimCarryStop() end
if ValheimDeleteStop then ValheimDeleteStop() end
if ValheimRapidMinerStop then ValheimRapidMinerStop() end
if ValheimRapidHoeStop then ValheimRapidHoeStop() end
if ValheimEnemyFormStop then ValheimEnemyFormStop() end
if ValheimSpawnStop then ValheimSpawnStop(); ValheimSpawnStop=nil end
if ValheimInventoryWindow then pcall(function() ValheimInventoryWindow.destroy() end) end
local form = createForm(false)
ValheimInventoryWindow = form
form.Caption = 'Valheim 2026 CT | v60 | Recovery v2 | Enemy form v12 | DBZ Powers v2 | Building v2'
form.Width = 760
form.Height = 705
form.Position = 'poScreenCenter'
-- Native Windows buttons ignore background colors; use a colored action panel.
local refresh = createPanel(form)
refresh.Caption = 'Refresh inventory'
refresh.BevelOuter='bvRaised';refresh.ParentColor=false
refresh.Color=0x32852E;refresh.Font.Color=0xFFFFFF
refresh.Cursor=-21;refresh.TabStop=true
refresh.OnKeyDown=function(sender,key)
  if (key==13 or key==32) and refresh.OnClick then refresh.OnClick() end
end
refresh.Left = 12; refresh.Top = 12; refresh.Width = 160
local maxItemQualityButton=createButton(form)
maxItemQualityButton.Caption='Set quality...'
local edit = createButton(form)
edit.Caption = 'Edit quantity'
edit.Left = 185; edit.Top = 12; edit.Width = 160
local freeze = createButton(form)
freeze.Caption = 'Freeze selected'
freeze.Left = 358; freeze.Top = 12; freeze.Width = 160
local unfreeze = createButton(form)
unfreeze.Caption = 'Unfreeze all'
unfreeze.Left = 531; unfreeze.Top = 12; unfreeze.Width = 160
local lootMagnetButton=createButton(form)
lootMagnetButton.Caption='Loot magnet...'
local freezeReplenishButton=createButton(form)
freezeReplenishButton.Caption='Freeze inventory + replenish: OFF'
local freezeAll = createButton(form)
freezeAll.Caption = 'Freeze all stacks'
freezeAll.Left = 12; freezeAll.Top = 45; freezeAll.Width = 200
local unfreezeSelected = createButton(form)
unfreezeSelected.Caption = 'Unfreeze selected'
unfreezeSelected.Left = 225; unfreezeSelected.Top = 45; unfreezeSelected.Width = 160
unfreeze.Visible=false;unfreezeSelected.Visible=false
local status = createLabel(form)
status.Left = 12; status.Top = 82
status.Caption = 'Waiting for Valheim and your loaded world. Inventory will load automatically.'
local listbox = createListBox(form)
listbox.Left = 12; listbox.Top = 125; listbox.Width = 715; listbox.Height = 350
listbox.Font.Name = 'Consolas'
local header = createLabel(form)
header.Left = 12; header.Top = 105; header.Font.Name = 'Consolas'
header.Caption = ' X  Flag  #   Item                               Quantity / Limit'
local note = createLabel(form)
note.Left = 12; note.Top = 485
note.Caption = 'X = frozen. Flag: Y = marked, - = clear, ? = unreadable. New stacks start unfrozen.'
local maxSkills = createButton(form)
maxSkills.Caption = 'Max skills to 100'
maxSkills.Left = 12; maxSkills.Top = 515; maxSkills.Width = 200
local customSkills = createButton(form)
customSkills.Caption = 'Set custom skill level'
customSkills.Left = 225; customSkills.Top = 515; customSkills.Width = 200
local skillStatus = createLabel(form)
skillStatus.Left = 12; skillStatus.Top = 555
skillStatus.Caption = 'Skills: applies to all existing skill entries, including level 0. Custom levels may exceed 100.'
local godButton = createButton(form)
godButton.Caption = '';godButton.Visible=false
godButton.Left = 12; godButton.Top = 590; godButton.Width = 200
local fixedHealthButton=createButton(form)
fixedHealthButton.Caption='Fixed HP 999: OFF'
local staminaButton = createButton(form)
staminaButton.Caption = 'Unlimited stamina: OFF'
staminaButton.Left = 225; staminaButton.Top = 590; staminaButton.Width = 220
local playerStatus = createLabel(form)
playerStatus.Left = 12; playerStatus.Top = 630
playerStatus.Caption = 'Player toggles stop when you leave the world or close this window.'
local cloneButton = createButton(form)
cloneButton.Caption = 'Clone selected item'
cloneButton.Left = 398; cloneButton.Top = 45; cloneButton.Width = 200
local maxStacksButton = createButton(form)
maxStacksButton.Caption = 'Max all stacks'
local depositButton = createButton(form)
depositButton.Caption = 'Auto refill: OFF'
local craftingButton = createButton(form)
craftingButton.Caption = 'Free crafting: OFF'
local clearFlagButton=createButton(form)
clearFlagButton.Caption='Item flags (combined)'
clearFlagButton.Visible=false
local keepFlagsButton=createButton(form)
keepFlagsButton.Caption='Remove cheated item flags: OFF'
local speedButton=createButton(form)
speedButton.Caption='Movement speed: 1x'
local jumpButton=createButton(form)
jumpButton.Caption='Jump force: 1x'
local resetMovementButton=createButton(form)
resetMovementButton.Caption='Reset speed and jump'
local teleportButton=createButton(form)
teleportButton.Caption='Teleport tools...'
local flightButton=createButton(form)
flightButton.Caption='Flight: OFF'
local clearViewButton=createButton(form)
clearViewButton.Caption='Clear weather: OFF'
local beamButton=createButton(form)
beamButton.Caption='DBZ Powers: OFF'
local kayokenCheck=createCheckBox(form)
kayokenCheck.Caption='';kayokenCheck.Checked=false;kayokenCheck.Enabled=false;kayokenCheck.Visible=false
local carryButton=createButton(form)
carryButton.Caption='Unlimited carry: OFF'
local deleteButton=createButton(form)
deleteButton.Caption='Inventory delete: OFF'
local rapidButton=createButton(form)
rapidButton.Caption='Rapid tools: OFF'
local minerButton=createButton(form)
minerButton.Caption='Fast attacks: OFF'
local hoeButton=createButton(form)
hoeButton.Caption='Rapid hoe: OFF'
local enemyButton=createButton(form)
enemyButton.Caption='Enemy form...'
local planterButton=createButton(form)
planterButton.Caption='Auto planter...'
local sortingButton=createButton(form)
sortingButton.Caption='Chest sorting: OFF'
local tamingButton=createButton(form)
tamingButton.Caption='Taming...'
local trophyButton=createButton(form)
trophyButton.Caption='Trophy buffs...'
local boatButton=createButton(form)
boatButton.Caption='Pixie boat...'
local spawnButton=createButton(form)
spawnButton.Caption='Spawn box...'
local dragButton=createButton(form)
dragButton.Caption='Building tools...'
-- Hover hints and a reusable, scrollable help window.
local function hint(control,text)
  control.Hint=text; control.ShowHint=true; control.ParentShowHint=false
end
local helpText=[[
FARMING AND LOOT
Auto harvest is in Auto planter: harvests ripe cultivator crops on cultivated ground within 20m and attracts their native drops. Growth timers are not changed. Close the farming window to stop both farming controls.
Inventory Loot magnet has separate cheated-only and all-loot toggles (one mode at a time), with a 5-500m radius. Only loaded loose drops are collected; flags stay unchanged. Full inventories, placed items, protected loot and tar-stuck drops are skipped. Close the magnet window to stop it.

BUTTON COLORS
Green means a toggle is active. Gray means it is inactive or is a one-time action. Yellow outlines identify cheated-alert risks and remain visible whether a feature is active or inactive.

YELLOW BUTTON BORDERS
Yellow means this feature has a known or reported risk of triggering Valheim's cheated alerts or marking items as cheated. It is a heads-up before you turn the feature on, not a live indication that your items are already flagged.

Free crafting: crafted or upgraded items may be flagged. Flight: cheated alerts have been reported while using it.

Set quality: choose equipment quality 1-1000, including refinement levels beyond the normal cap. This edit does not set the cheated flag and preserves any existing flag.

If an item is flagged, use the inventory item-flag controls. Clearing an item flag does not erase every record of cheat use. Turning a feature off does not automatically remove existing flags.


BUILDING
Open Building tools for Auto rows and furnished blueprints. Stand inside the building at floor level. Capture asks for a save name and box width/height/depth, then snapshots a fixed box around your character, starting 1m below your feet. Return to the game once with a hammer to capture it. The count and highlight stay fixed. Click Save captured blueprint in the Building window for a verified file path; no capture hotkeys are required. F7 remains an optional save shortcut. Duplicate names get a numbered suffix. Load previews a saved blueprint at the hammer ghost (or aimed surface). Q/E rotate, Page Up/Down adjust height, F6 locks, F7 builds. Escape cancels. Maximum 512 loaded player-built pieces, including furniture and signs. Terrain, loose items, contents, bed claims, portal links and display equipment are not copied. Free Crafting removes blueprint costs; otherwise total materials are checked before starting and each placed piece pays costs. Support still applies. Undo removes only objects from the last paste, without material refunds; empty pasted containers and display stands first. Disabling Building, changing modes or leaving the world clears Undo. Files persist under LocalAppData/ValheimSoloToolkit/Blueprints.


INVENTORY - SELECTED ITEM
Select a row first. Edit quantity accepts positive whole numbers, including values above the normal stack limit. Clone copies the selected item into your inventory; leave an empty slot available.
Freeze selected is a toggle: click once to hold that item's quantity, again to release it. X in the first column means frozen. Splitting/reordering does not freeze newly created stacks automatically. Removing an entire stack ends its freeze.

INVENTORY - ALL STACKS
Refresh reads your current inventory. Max all stacks sets each existing stack to its normal maximum; it also reduces overstacks to that maximum. Freeze entire inventory captures the quantities of currently carried stacks; new stacks start unfrozen. The inventory freeze button becomes Unfreeze inventory while any stack is frozen; clicking it releases all locks.
Auto refill: enable it, open a chest, then Ctrl+left-click a stack to deposit. A copy transfers and the original stays in its inventory slot. This is separate from freezing quantities.

ITEM FLAGS
Flag Y means marked, - means clear, and ? means unreadable. Remove cheated item flags is one inventory-wide toggle: enabling clears all carried flags immediately and keeps newly crafted/upgraded items clear; disabling stops future clearing. After clearing the affected item flag, drop the item from your inventory and pick it up again. Use the normal drop action, not Inventory delete. These controls change item flags, not every record of cheat use.

DELETE ITEMS IN GAME
Inventory delete creates a menu at the BOTTOM LEFT of the game when your inventory is open. Drag a full stack from your own inventory and use Destroy, then confirm. Quest items, equipped items, chest items and partial-stack drags are blocked. Split off a smaller stack first to delete only part of a stack. Deletion is permanent.

TELEPORT - MAP MARKERS AND PINGS
Open Valheim's map and create a named marker at your destination. Open Teleport tools, click Refresh locations, select its Map pin row, then Teleport selected.
You can also use the game's map ping action. Refresh locations while the ping is visible, then select its Ping row and teleport. The list captures coordinates when refreshed; it does not track a moving ping. If missing, ping again and refresh promptly.
Save current position creates a named bookmark in Cheat Engine for this world. Stand still before saving. These bookmarks persist locally and do not create in-game map markers. Create visible map markers in Valheim's map itself.
Enter coordinates accepts X Y Z; Y is height. Return to the game and unpause after queuing. Terrain loading may take time. Cancel queued cancels a waiting request; it does not undo an accepted teleport.
To teleport to a player, they must enable Visible to other players on their map. Refresh players, select their row, then teleport. Their latest shared position is read when clicked, with a 3m sideways offset. It does not follow them afterward.

Death recovery: Last death uses your recorded death location in this world. Teleport to tombstone targets your latest remaining tombstone. Bring tombstone to me moves that same tombstone with its contents intact to a clear spot beside you. Stand on open solid ground and close any open tombstone. The original death location stays unchanged. Remote clients may not know distant tombstones; use Last death instead. Return to the game and unpause to run the search.
Delete saved location removes a local bookmark only. Edit or remove game map markers using the game map.

SKILLS AND MOVEMENT
Max skills sets existing skill entries to 100, including entries at zero. Custom skill level opens a skill picker: check the skills to change, or Select all, enter the desired level, then Apply. Levels above 100 are allowed; game behavior can still apply its own caps. Movement speed and jump force are multipliers for your player and transformed creature. Each form scales its own native values; changes and Reset also apply while transformed.
Flight: Space rises, Left Ctrl descends, Shift moves faster. This is flight, not collision-free noclip.

RAPID MINER
Enable Fast attacks for 10x melee attack animations, bow/spell charge progress and shorter projectile-spell burst intervals. Reload-based magic staves rearm quickly while attack is held, paying their remaining native eitr reload cost. Crossbows use instant rearming and 30x firing animations: HOLD attack for continuous automatic fire; release to stop. Supports swords, knives, clubs, polearms, spears, axes, bows, crossbows, fist weapons, magic weapons and pickaxes. Use normal attack controls; bows still fire on release and ammunition/eitr costs remain. Stamina and equipped weapon durability refill. Disabling restores animation speed; refilled resources remain. Native hit detection and weapon tier requirements apply.

RAPID HOE
Enable Rapid hoe, equip the hoe, select a terrain action and hold the use button (mouse attack or controller place). Repeats up to 20 times per second with stamina and hoe durability refill. Normal material costs and terrain restrictions apply. Switching tools, disabling or closing restores the original placement cooldown. Refilled stamina and durability remain.

ENEMY FORM
Choose from 48 creature forms, including Fulings, Cultist, Abomination, Seeker Soldier and Asksvin. The tool controls a real enemy body with its native weapons, animation and movement; your original player is hidden and suspended. Move/run/jump using your normal bindings. The body faces movement while moving, or camera aim while idle/attacking, using native turn speed. For Sea Serpent, transform in deep water; normal movement steers native surface swimming. Returning restores your player at that position, including in water. Attack uses the current native weapon; Block uses its secondary attack if available, otherwise primary. Use cycles available native weapons. F8 or Return to player in the popup returns to your player at the enemy body position. Its death also returns you. Your inventory, skills and original health stay with your original player; the normal HUD does not show enemy health, so check toolkit status.
Enemy form hides your player nameplate, local map/minimap arrows and shared map position. Your original display name and map-sharing preference are restored on return. This does not guarantee a full enemy disguise on other players' clients. The Enemy form popup selects green/player or red/native monster allegiance and optional friendly hits for monster duels. World loading follows the controlled body. Creature damage can hit players with PvP off; duel mode also permits allied targets. Multiplayer behavior needs an in-game check. Closing the toolkit queues restoration; return to Valheim and unpause for cleanup to finish.

PLAYER TOGGLES
Fixed HP 999 holds local health at 999/999. Food timers, stamina, eitr, armor wear and hit effects continue. Normal saved HP is preserved, capped as food expires, and restored when disabled. Character saving uses normal health values.  Unlimited resources covers stamina, eitr, adrenaline, ability health costs and summon-control limits, including Dead raiser. It works without eitr food. Normal incoming damage, ammo, materials and ability cooldowns remain. Disabling restores normal costs; refilled pools remain. Free crafting bypasses crafting/building material requirements; it does not supply fuel for machines.
Unlimited carry bypasses encumbrance; the displayed weight and normal weight limit remain. Kameha fires a cyan beam while holding the bow attack button, targeting hostile monsters only. Choose Death Beam for a crimson/purple beam that passes through terrain and damages creatures, pets, buildings, trees and rocks along its full 80m path. It excludes the caster; normal game damage rules still apply. Terrain is excavated into open trenches within native depth limits; edits persist in the world. Spirit Bomb launches a giant slow blue sphere (40m blast radius); Supernova launches a fiery sphere (120m blast radius). Click bow attack once to launch; impact or 20 seconds detonates it. One bomb at a time. Both damage creatures, pets and destructible objects, and excavate loaded terrain in batches. Turn DBZ Powers off to change modes or cancel unfinished blast work; completed damage and terrain edits remain.
Close the toolkit or leave the world to stop player toggles. Quantity edits, deleted items, skill edits and saved bookmarks are not undone by closing it.
]]
local helpWindow
local function openHelp()
  if helpWindow then helpWindow.show(); return end
  helpWindow=createForm(false);helpWindow.Caption='Valheim | Help and action guide'
  helpWindow.Width=820;helpWindow.Height=690;helpWindow.Position='poScreenCenter'
  helpWindow.BorderStyle='bsSizeable';helpWindow.Color=0x202020;helpWindow.Font.Color=0xE6E6E6
  local memo=createMemo(helpWindow)
  memo.ReadOnly=true;memo.ScrollBars='ssVertical';memo.WordWrap=true
  memo.Font.Name='Segoe UI';memo.Font.Size=11;memo.Color=0x292929;memo.Font.Color=0xE6E6E6
  memo.Lines.Text=helpText
  local function layoutHelp()
    memo.Left=16;memo.Top=16
    memo.Width=math.max(200,(helpWindow.ClientWidth or helpWindow.Width-16)-32)
    memo.Height=math.max(100,(helpWindow.ClientHeight or helpWindow.Height-40)-32)
  end
  helpWindow.OnResize=layoutHelp;helpWindow.OnClose=function() return caHide end
  layoutHelp();helpWindow.show()
end
-- Keep help owned by this script so rerunning the table never leaves stale guides.
if ValheimHelpStop then pcall(ValheimHelpStop) end
ValheimHelpStop=function() if helpWindow then helpWindow.destroy();helpWindow=nil end end
hint(kayokenCheck,'Enable a DBZ power first, then check Kayoken for a red aura, 32x DBZ damage and 2x size. Death Beam: 16000 damage per tick, 120m range, wider excavation. Bomb power is fixed at launch. Turns off with DBZ Powers.')
local hints={
  {dragButton,'Open the Building section for drag rows, furnished blueprint capture/load, and Undo. Hammer: Left-click and drag previews a snapped straight row (up to 24). Release left click to build. Right click cancels. Auto-builds the preview without range, line-of-sight or hammer cooldown checks. Free Crafting also skips row stamina and wear; otherwise normal costs apply. Rapid hoe and Drag build are mutually exclusive.'},
  {enemyButton,'Choose from 48 creature forms with native movement and attacks. Attack = primary, Block = secondary/fallback, Use = cycle weapons. Open the popup to choose allegiance, enable duels, or return. F8 also returns.'},
  {hoeButton,'Hold use with the hoe for up to 20 terrain actions per second, stamina refill and full hoe durability. Normal material costs apply; other tools are unaffected.'},
  {minerButton,'10x attacks, bow/spell charge and projectile-spell burst intervals; fast magic reloads. Crossbows: hold attack for instant rearming/30x animation. Stamina/durability refill; ammo/eitr costs remain.'},
  {refresh,'Automatically connects to Valheim. Click to reload items and quantities manually; the first load retries automatically until your world is ready.'},
  {edit,'Set the selected stack to a positive whole number. Overstacks above its normal limit are allowed.'},
  {cloneButton,'Copy the selected item into your inventory. Leave an empty inventory slot available.'},
  {freeze,'Toggle the selected item quantity lock on/off. X marks frozen rows. New split stacks are not automatically frozen.'},
  {unfreezeSelected,'Stop holding the selected item quantity. Its current quantity is kept.'},
  {freezeAll,'Toggle all inventory quantity locks: freeze current stacks when none are frozen, or release all active locks. Newly acquired or split stacks start unfrozen.'},
  {unfreeze,'Release all inventory quantity freezes; current quantities are kept.'},
  {maxStacksButton,'Set all existing stacks to their normal stack limits. This also REDUCES overstacks to their normal limits.'},
  {depositButton,'While enabled, Ctrl+left-click a stack into an open chest. A copy transfers and the original remains in its slot.'},
  {clearFlagButton,'Clear the selected carried item flag once. Flag Y = marked; - = clear; ? = unreadable.'},
  {keepFlagsButton,'Continuously clear cheated flags on carried items, including newly crafted/upgraded items. Does not erase all cheat history.'},
  {deleteButton,'Creates a menu at the BOTTOM LEFT in game while inventory is open. Drag a full stack from your inventory, click Destroy, then confirm. Permanently deletes it; equipped and quest items are blocked.'},
  {staminaButton,'Continuously replenish stamina while enabled.'},
  {craftingButton,'Bypass crafting and building material requirements. Does not refill machine fuel. Crafted/upgraded items may receive a cheated flag.'},
  {carryButton,'Prevent encumbrance regardless of carried weight. The displayed weight and normal limit are unchanged.'},
  {maxSkills,'Set all existing skill entries to level 100, including level-zero entries.'},
  {customSkills,'Open the skill editor: check individual skills or Select all, enter a level, then Apply. Levels above 100 are allowed; game effects may still be capped.'},
  {speedButton,'Set a movement-speed multiplier for your player and transformed form, relative to their own native walk/run/crouch/swim speeds.'},
  {jumpButton,'Set a jump-force multiplier for your player and transformed form, relative to their own native jump force. Higher values increase jump height.'},
  {resetMovementButton,'Restore original movement speeds and jump force for your player and current transformed form.'},
  {flightButton,'Enable flight: Space = up, Left Ctrl = down, Shift = faster. Does not disable collisions.'},
  {beamButton,'DBZ Powers: Kameha, Death Beam, Spirit Bomb and Frieza Supernova. Hold bow attack for beams; click for one bomb. Bombs damage creatures/objects and excavate terrain. Toggle off cancels unfinished blast work.'},
  {teleportButton,'Create a named marker or ping on the game map, refresh destinations, and teleport to it. Also save current-position bookmarks, enter coordinates, or visit players sharing their position. Click Help & tips for steps.'},
  {listbox,'Select an item before using Selected item or Clear selected flag. X = frozen. Flag Y = cheated; - = clear; ? = unreadable.'}
}
for _,entry in ipairs(hints) do hint(entry[1],entry[2]) end
-- Organized layout: selected-item, whole-inventory and flag actions have separate rows.
form.BorderStyle = 'bsSizeable'
form.Width = 1120; form.Height = 800
form.AutoScroll=false;form.AutoSize=false
form.Constraints.MinWidth=960;form.Constraints.MinHeight=740
local title = createLabel(form)
title.Caption = 'VALHEIM  |  Solo toolkit'; title.Left=20; title.Top=14; title.Font.Size=17
form.Color=0x202020;form.Font.Color=0xE6E6E6
local helpLink=createLabel(form)
helpLink.Caption='? Help & tips';helpLink.Font.Size=12;helpLink.Font.Color=0x8DCCE8
helpLink.Cursor=-21;helpLink.OnClick=openHelp
hint(helpLink,'Open the full action guide: inventory, deletion, item flags, map markers, pings and teleporting.')
local subtitle = createLabel(form)
subtitle.Caption = 'Green = active. Yellow outline = cheated-alert risk. Hover or open Help for details.'; subtitle.Left=22; subtitle.Top=44
local inventoryGroup = createGroupBox(form)
inventoryGroup.Caption='Inventory'; inventoryGroup.Left=16; inventoryGroup.Top=74
inventoryGroup.Width=950; inventoryGroup.Height=465
local skillsGroup = createGroupBox(form)
skillsGroup.Caption='Skills and movement'; skillsGroup.Left=16; skillsGroup.Top=552
skillsGroup.Width=465; skillsGroup.Height=160
local playerGroup = createGroupBox(form)
playerGroup.Caption='Player'; playerGroup.Left=497; playerGroup.Top=552
playerGroup.Width=469; playerGroup.Height=160
title.Font.Color=0x8DCCE8
subtitle.Font.Color=0xB8B8B8
inventoryGroup.Color=0x292929;skillsGroup.Color=0x292929;playerGroup.Color=0x292929
header.Font.Color=0x8DCCE8;note.Font.Color=0xB8B8B8
listbox.Color=0x181818;listbox.Font.Color=0xE6E6E6
for _,control in ipairs({inventoryGroup,skillsGroup,playerGroup,status,skillStatus,playerStatus}) do
  control.Font.Color=0xE6E6E6
end
-- Yellow frames remain visible regardless of ON/OFF caption changes.
local cheatWarningMarkers={}
for _,entry in ipairs({{flightButton,'Flight: cheated alerts have been observed while using this feature.'},
  {craftingButton,'Free crafting: crafted or upgraded items may be flagged as cheated.'}}) do
  local marker=createPanel(playerGroup);marker.Caption='';marker.BevelOuter='bvNone'
  marker.ParentColor=false;marker.Color=0x00D7FF
  hint(marker,'YELLOW BORDER: This feature can trigger cheated alerts or mark items as cheated. '..entry[2])
  hint(entry[1],'CHEATED ALERT RISK: '..entry[2]..' '..(entry[1].Hint or ''))
  cheatWarningMarkers[#cheatWarningMarkers+1]={button=entry[1],marker=marker}
end
-- Persistent notices stay separate from transient player action/status messages.
local godWarning=createLabel(playerGroup)
godWarning.Caption='';godWarning.Visible=false
local craftingWarning=createLabel(playerGroup)
craftingWarning.Caption='FREE CRAFTING: Crafted/upgraded items can be flagged as cheated.'
local flagWarningHelp=createLabel(playerGroup)
flagWarningHelp.Caption='Clear it using Item flags, then drop the item and pick it up again.'
for _,label in ipairs({godWarning,craftingWarning,flagWarningHelp}) do
  label.AutoSize=false;label.WordWrap=true
  label.Font.Color=0x00D7FF
end
flagWarningHelp.Font.Color=0x8DCCE8
hint(godWarning,godButton.Hint)
hint(craftingWarning,craftingButton.Hint)
hint(flagWarningHelp,'Enable Inventory > Remove cheated item flags to clear all carried-item flags. Then drop it from your inventory and pick it up again. Keep item flags off clears carried-item flags continuously. Use the normal drop action, not Inventory delete. Click for the full guide.')
flagWarningHelp.Cursor=-21;flagWarningHelp.OnClick=openHelp
local actionLabels={}
for i,text in ipairs({'Selected item','Inventory','Building'}) do
  local label=createLabel(inventoryGroup);label.Caption=text;label.Font.Color=0x8DCCE8
  label.AutoSize=false;actionLabels[i]=label
end
local function place(control,parent,x,y,w,h)
  control.Parent=parent; control.Left=x; control.Top=y
  if w then control.Width=w end
  if h then control.Height=h end
end
place(refresh,inventoryGroup,14,25,172,30)
place(edit,inventoryGroup,196,25,172,30)
place(cloneButton,inventoryGroup,378,25,172,30)
place(maxStacksButton,inventoryGroup,560,25,172,30)
place(depositButton,inventoryGroup,742,25,194,30)
place(freeze,inventoryGroup,14,65,172,30)
place(unfreezeSelected,inventoryGroup,196,65,172,30)
place(freezeAll,inventoryGroup,378,65,172,30)
place(unfreeze,inventoryGroup,560,65,172,30)
place(header,inventoryGroup,14,109)
place(listbox,inventoryGroup,14,132,922,270)
place(status,inventoryGroup,14,412,910,20)
status.AutoSize=false
place(note,inventoryGroup,14,437,910,18); note.AutoSize=false
place(maxSkills,skillsGroup,14,28,205,32)
place(customSkills,skillsGroup,231,28,218,32)
place(skillStatus,skillsGroup,14,75,435,65)
skillStatus.AutoSize=false; skillStatus.WordWrap=true
place(godButton,playerGroup,14,28,205,32)
place(staminaButton,playerGroup,231,28,218,32)
place(playerStatus,playerGroup,14,75,435,65)
playerStatus.AutoSize=false; playerStatus.WordWrap=true
local footer=createLabel(form)
footer.Font.Color=0xB8B8B8
footer.Caption='Hover any action for tips. Click Help & tips for the full guide, including map markers, pings and teleporting.'
footer.Left=20; footer.Top=730
-- Compact layout: fixed-height actions/notices; spare height belongs to the item list.
local layingOut=false
local function layoutWindow()
  if layingOut then return end
  layingOut=true
  local ok,err=pcall(function()
    local w=form.ClientWidth or (form.Width-16)
    local h=form.ClientHeight or (form.Height-40)
    local margin,gap=12,10
    local line=math.max(16,(subtitle.Font.Size or 8)*1.5+4)
    local buttonH=math.max(28,line+10)
    local half=math.floor((w-margin*2-gap)/2)
    -- Reserve two wrapped lines per warning only at narrower window widths.
    local warningLines=half<580 and 2 or 1
    local warningH=line*warningLines
    local lowerH=26+12+5*(buttonH+6)+line*2+8+warningH*2+8
    local footerH=line
    local lowerTop=h-margin-footerH-6-lowerH
    place(title,form,16,10,w-190,28)
    place(helpLink,form,w-166,14,150,24)
    place(subtitle,form,18,40,w-36,line)
    local inventoryTop=40+line+8
    place(inventoryGroup,form,margin,inventoryTop,w-margin*2,lowerTop-gap-inventoryTop)
    local iw=inventoryGroup.ClientWidth or (inventoryGroup.Width-4)
    local ih=inventoryGroup.ClientHeight or (inventoryGroup.Height-26)
    local labelW=98
    local bw=math.floor((iw-24-labelW-3*gap)/4)
    local groups={{edit,cloneButton,maxItemQualityButton,freeze,refresh},
      {maxStacksButton,freezeReplenishButton,keepFlagsButton,lootMagnetButton},
      {dragButton,spawnButton,tamingButton,planterButton,sortingButton}}
    for row,controls in ipairs(groups) do
      local bw=math.floor((iw-24-labelW-(#controls-1)*gap)/#controls)
            local y=6+(row-1)*(buttonH+5)
      place(actionLabels[row],inventoryGroup,12,y+6,labelW-6,line)
      for col,control in ipairs(controls) do
        place(control,inventoryGroup,12+labelW+(col-1)*(bw+gap),y,bw,buttonH)
      end
    end
    local headerY=6+3*(buttonH+5)
    place(header,inventoryGroup,12,headerY,iw-24,line);header.AutoSize=false
    local listY=headerY+line+3
    local noteY=ih-6-line
    local statusY=noteY-3-line*2
    place(listbox,inventoryGroup,12,listY,iw-24,math.max(24,statusY-4-listY))
    place(status,inventoryGroup,12,statusY,iw-24,line*2)
    place(note,inventoryGroup,12,noteY,iw-24,line)
    status.WordWrap=true;note.WordWrap=false
    hint(note,note.Caption)
    -- Skills no longer stretches into a large empty box to match Player.
    local skillsH=26+12+5*(buttonH+6)+line*3+10
    place(skillsGroup,form,margin,lowerTop,half,skillsH)
    place(playerGroup,form,margin+half+gap,lowerTop,w-margin*2-gap-half,lowerH)
    for _,group in ipairs({skillsGroup,playerGroup}) do
      local cw=group.ClientWidth or (group.Width-4)
      local size=math.floor((cw-24-gap)/2)
      local function pair(a,b,row)
        local y=10+(row-1)*(buttonH+6)
        place(a,group,12,y,size,buttonH)
        place(b,group,12+size+gap,y,cw-24-gap-size,buttonH)
      end
      if group==playerGroup then
        pair(fixedHealthButton,staminaButton,1)
        pair(craftingButton,teleportButton,2)
        pair(flightButton,beamButton,3)

        kayokenCheck.Visible=false
        pair(carryButton,deleteButton,4)
        for _,entry in ipairs(cheatWarningMarkers) do
          local b=entry.button
          place(entry.marker,group,b.Left,b.Top,b.Width,buttonH)
          place(b,entry.marker,1,1,entry.marker.Width-2,buttonH-2)
        end
        place(clearViewButton,group,12,10+4*(buttonH+6),cw-24,buttonH)
        local y=10+5*(buttonH+6)
        place(playerStatus,group,12,y,cw-24,line*2)
        y=y+line*2+6
        godWarning.Visible=false
        place(craftingWarning,group,12,y,cw-24,warningH)
        place(flagWarningHelp,group,12,y+warningH,cw-24,warningH)
      else
        pair(maxSkills,customSkills,1)
        pair(speedButton,jumpButton,2)
        pair(resetMovementButton,enemyButton,3)
        pair(rapidButton,boatButton,4)
        pair(minerButton,trophyButton,5)
        place(skillStatus,group,12,10+5*(buttonH+6),cw-24,line*3)
      end
    end
    footer.AutoSize=false;footer.WordWrap=false
    place(footer,form,margin,h-margin-footerH,w-margin*2,footerH)
  end)
  layingOut=false
  if not ok then print('Valheim layout: '..tostring(err)) end
end
form.OnResize=layoutWindow
form.OnShow=layoutWindow
layoutWindow()
local rows, cache, session = {}, {}, nil
local maxQuantity = 2147483647 -- Positive signed 32-bit stack field.
local playerClass, localField, inventoryOffset, itemsOffset
local frozen = {}
local drawRows

local timer = createTimer(form, false)
timer.Interval = 250
local function freezeLabels()
  local row=rows[listbox.ItemIndex+1]
  freeze.Caption=row and frozen[row.item] and 'Unfreeze selected' or 'Freeze selected'
  freezeAll.Caption=next(frozen) and 'Unfreeze inventory' or 'Freeze inventory'
end
listbox.OnClick=freezeLabels
listbox.OnKeyUp=freezeLabels
local function stopFreeze()
  timer.Enabled = false
  frozen = {}
  if drawRows then drawRows() end
end
ValheimInventoryStop = stopFreeze
form.OnClose = function() stopFreeze(); return caHide end
form.OnDestroy = function() stopFreeze() end

local function pointer(value, label)
  assert(type(value) == 'number' and value > 0, label .. ' unavailable')
  return value
end
local function fields(class)
  pointer(class, 'Class')
  if not cache[class] then
    local values = mono_class_enumFields(class, true)
    assert(values, 'Mono field query failed')
    local result = {}
    for _, f in ipairs(values) do result[f.name] = f end
    cache[class] = result
  end
  return cache[class]
end
local function field(class, name)
  local f = fields(class)[name]
  assert(f, 'Missing field: ' .. name)
  return f
end
local function objectClass(address)
  return pointer(mono_object_getClass(address), 'Object class')
end
local function offset(class, name)
  local f = field(class, name)
  assert(not f.isStatic and f.offset >= 0x10, 'Unexpected field: ' .. name)
  return f.offset
end
local function integer(address, label)
  local v = readInteger(address)
  assert(v ~= nil, 'Cannot read ' .. label)
  return v
end
local function stringValue(address)
  pointer(address, 'Name string')
  local length = integer(address + 0x10, 'string length')
  assert(length >= 0 and length <= 512, 'Unexpected Mono string layout')
  if length == 0 then return '(unnamed)' end
  return assert(readString(address + 0x14, length * 2, true), 'Cannot read name')
end
local function initialize()
  local pid = getProcessIDFromProcessName('valheim.exe')
  assert(pid and pid ~= 0, 'Start Valheim and load your world first.')
  if getOpenedProcessID() ~= pid then openProcess(pid) end
  assert(targetIs64Bit(), 'This prototype requires 64-bit Valheim.')
  local connected = LaunchMonoDataCollector()
  assert(connected and connected ~= 0, 'Mono connection failed')
  cache = {}
  playerClass = pointer(mono_findClass('', 'Player'), 'Player class')
  localField = field(playerClass, 'm_localPlayer')
  assert(localField.isStatic, 'm_localPlayer is not static')
  inventoryOffset = offset(pointer(mono_findClass('', 'Humanoid'), 'Humanoid class'), 'm_inventory')
  itemsOffset = offset(pointer(mono_findClass('', 'Inventory'), 'Inventory class'), 'm_inventory')
  session = pid
end
local function snapshot()
  assert(session and getOpenedProcessID() == session
    and getProcessIDFromProcessName('valheim.exe') == session, 'Process changed. Refresh inventory.')
  -- CE 7.6 exposes the actual storage address on enumerated static fields.
  -- Read the reference there rather than relying on the domain-0 vtable getter.
  local storage = localField.staticAddress
  if not storage or storage <= localField.offset then
    local base = mono_class_getStaticFieldAddress(playerClass)
    if base and base > 0 then storage = base + localField.offset end
  end
  pointer(storage, 'Local-player static storage')
  local playerValue = readPointer(storage)
  assert(playerValue and playerValue > 0, string.format(
    'Local player is null/unreadable at static storage %X (field +%X). Load your world, then refresh.',
    storage, localField.offset))
  local player = playerValue
  local inventory = pointer(readPointer(player + inventoryOffset), 'Player inventory')
  local collection = pointer(readPointer(inventory + itemsOffset), 'Item list')
  local class = objectClass(collection)
  local sizeOffset = offset(class, '_size')
  local versionOffset = offset(class, '_version')
  local arrayOffset = offset(class, '_items')
  local count = integer(collection + sizeOffset, 'list count')
  assert(count >= 0 and count <= 512, 'Unexpected inventory size')
  local version = integer(collection + versionOffset, 'list version')
  local array = pointer(readPointer(collection + arrayOffset), 'Item array')
  local capacity = readQword(array + 0x18)
  assert(capacity and capacity >= count and capacity <= 4096, 'Unexpected Mono array layout')
  local result = {player=player, inventory=inventory, collection=collection, version=version, items={}}
  for i=0,count-1 do
    result.items[#result.items+1] = pointer(readPointer(array + 0x20 + i*8), 'Item')
  end
  assert(integer(collection + versionOffset, 'list version') == version
    and integer(collection + sizeOffset, 'list count') == count, 'Inventory changed while reading; refresh again.')
  return result
end
local function itemInfo(item)
  local class = objectClass(item)
  local stackOffset = offset(class, 'm_stack')
  local shared = pointer(readPointer(item + offset(class, 'm_shared')), 'Shared item data')
  local sharedClass = objectClass(shared)
  local namePointer = pointer(readPointer(shared + offset(sharedClass, 'm_name')), 'Item name')
  local name = stringValue(namePointer)
  local maximum = integer(shared + offset(sharedClass, 'm_maxStackSize'), 'stack limit')
  local quantity = integer(item + stackOffset, 'quantity')
  assert(maximum >= 1 and maximum <= maxQuantity and quantity >= 1 and quantity <= maxQuantity,
    'Unexpected item quantity or stack limit')
  local flagField=fields(class).m_cheated
  local cheated
  if flagField and not flagField.isStatic and flagField.typename=='System.Boolean' then
    cheated=readBytes(item+flagField.offset,1)
  end
  return {item=item, class=class, shared=shared, namePointer=namePointer,
    name=name, maximum=maximum, quantity=quantity, address=item+stackOffset,cheated=cheated}
end
drawRows = function(selectedItem)
  local selected = rows[listbox.ItemIndex + 1]
  selectedItem = selectedItem or (selected and selected.item)
  listbox.Items.clear()
  listbox.ItemIndex = -1
  for i, row in ipairs(rows) do
    listbox.Items.add(string.format(' %s   %s   %02d   %-34s %d / %d',
      frozen[row.item] and 'X' or ' ', row.cheated==1 and 'Y' or (row.cheated==0 and '-' or '?'),
      i, row.name, row.quantity, row.maximum))
    if row.item == selectedItem then listbox.ItemIndex = i-1 end
  end
  freezeLabels()
end
local function populate(selectedItem)
  local selected = rows[listbox.ItemIndex + 1]
  selectedItem = selectedItem or (selected and selected.item)
  local snap = snapshot()
  local fresh = {}
  for _, item in ipairs(snap.items) do
    local info = itemInfo(item)
    info.player=snap.player; info.inventory=snap.inventory
    fresh[#fresh+1] = info
  end
  rows = fresh
  local present = {}
  for _, row in ipairs(rows) do
    local f = frozen[row.item]
    if f and f.snap.player == snap.player and f.snap.inventory == snap.inventory
      and f.row.shared == row.shared and f.row.namePointer == row.namePointer then present[row.item] = f end
  end
  frozen = present
  timer.Enabled = next(frozen) ~= nil
  drawRows(selectedItem)
  status.Caption = string.format('%d items loaded. Select an item, then Edit quantity.', #rows)
end
local function guarded(action)
  local ok, err = pcall(action)
  if not ok then
    stopFreeze()
    rows = {}; listbox.Items.clear()
    status.Caption = 'Stopped: see the error message. Refresh to retry.'
    print('Valheim inventory: ' .. tostring(err))
    showMessage('Valheim inventory: ' .. tostring(err))
  end
  return ok
end
local function refreshInventory()
  if session ~= getProcessIDFromProcessName('valheim.exe') then stopFreeze() end
  local selected = rows[listbox.ItemIndex + 1]
  initialize();populate(selected and selected.item)
end
refresh.OnClick=function() return guarded(refreshInventory) end
edit.OnClick = function()
  guarded(function()
    local row = rows[listbox.ItemIndex + 1]
    assert(row, 'Select an item first.')
    local answer = inputQuery('Edit quantity', row.name .. '\nNew quantity (overstack allowed; normal limit ' .. row.maximum .. '):', tostring(row.quantity))
    if answer == nil then return end
    local value = tonumber(answer)
    if not (value and value == math.floor(value) and value >= 1 and value <= maxQuantity) then
      showMessage('Enter a whole number from 1 to 2147483647. Overstack values are allowed.')
      return
    end
    local snap = snapshot()
    assert(snap.player == row.player and snap.inventory == row.inventory, 'Player inventory changed. Refresh first.')
    local found = false
    for _, item in ipairs(snap.items) do if item == row.item then found = true; break end end
    assert(found, 'This item is no longer in your inventory. Refresh first.')
    local current = itemInfo(row.item)
    assert(current.class == row.class and current.shared == row.shared
      and current.namePointer == row.namePointer and current.name == row.name
      and current.quantity == row.quantity and current.maximum == row.maximum,
      'Item changed since refresh. Refresh before editing.')
    -- Revalidate list membership/version immediately before the single write.
    local check = snapshot()
    assert(check.player == snap.player and check.inventory == snap.inventory
      and check.collection == snap.collection and check.version == snap.version,
      'Inventory changed during edit. Refresh first.')
    assert(readInteger(current.address) == current.quantity, 'Quantity changed during edit.')
    assert(writeInteger(current.address, value), 'Quantity write failed')
    assert(readInteger(current.address) == value, 'Quantity write did not persist')
    if frozen[row.item] then frozen[row.item].row.quantity = value end
    populate()
    status.Caption = 'Quantity updated. Reopen the game inventory to check the display.'
  end)
end
maxStacksButton.OnClick = function()
  guarded(function()
    if not session or session~=getProcessIDFromProcessName('valheim.exe') then initialize() end
    local snap=snapshot()
    local pending={}
    for _,item in ipairs(snap.items) do pending[#pending+1]=itemInfo(item) end
    local check=snapshot()
    assert(check.player==snap.player and check.inventory==snap.inventory
      and check.collection==snap.collection and check.version==snap.version,'Inventory changed. Try again.')
    for _,row in ipairs(pending) do
      assert(readInteger(row.address)==row.quantity,'A quantity changed. Try again.')
    end
    local written={}
    local ok,err=pcall(function()
      for _,row in ipairs(pending) do
        local current=snapshot()
        assert(current.player==snap.player and current.inventory==snap.inventory
          and current.collection==snap.collection and current.version==snap.version,'Inventory changed during update')
        written[#written+1]=row
        assert(writeInteger(row.address,row.maximum),'Stack write failed')
        assert(readInteger(row.address)==row.maximum,'Stack write verification failed')
      end
    end)
    if not ok then
      local restored=0
      for _,row in ipairs(written) do
        local rollback=pcall(function()
          local current=snapshot()
          assert(current.player==snap.player and current.inventory==snap.inventory
            and current.collection==snap.collection and current.version==snap.version,'Inventory changed')
          assert(writeInteger(row.address,row.quantity),'Restore failed')
          assert(readInteger(row.address)==row.quantity,'Restore verification failed')
        end)
        if rollback then restored=restored+1 end
      end
      error(tostring(err)..string.format(' Restored %d/%d attempted stacks.',restored,#written))
    end
    for _,row in ipairs(pending) do if frozen[row.item] then frozen[row.item].row.quantity=row.maximum end end
    populate()
    status.Caption=string.format('Set %d stacks to normal limits (overstacks reduced too).',#pending)
  end)
end
unfreeze.OnClick = function()
  stopFreeze()
  status.Caption = 'Freeze off. Click Refresh inventory to update quantities.'
end
local function makeFreeze(row, snap)
    assert(snap.player == row.player and snap.inventory == row.inventory, 'Inventory changed. Refresh first.')
    local found = false
    for _, item in ipairs(snap.items) do if item == row.item then found=true end end
    assert(found, 'Item left your inventory. Refresh first.')
    local current = itemInfo(row.item)
    assert(current.class == row.class and current.shared == row.shared
      and current.namePointer == row.namePointer and current.name == row.name,
      'Item changed. Refresh first.')
    local listClass = objectClass(snap.collection)
    local sharedClass = objectClass(current.shared)
    local storage = localField.staticAddress
    if not storage or storage <= localField.offset then
      storage = pointer(mono_class_getStaticFieldAddress(playerClass), 'Static storage') + localField.offset
    end
    return {row=current, snap=snap, storage=storage,
      sizeOffset=offset(listClass, '_size'), versionOffset=offset(listClass, '_version'),
      arrayOffset=offset(listClass, '_items'), sharedOffset=offset(current.class, 'm_shared'),
      nameOffset=offset(sharedClass, 'm_name'), maxOffset=offset(sharedClass, 'm_maxStackSize'),
      itemType=pointer(readPointer(current.item), 'Item type'),
      listType=pointer(readPointer(snap.collection), 'List type')}
end
freeze.OnClick = function()
  guarded(function()
    local row = rows[listbox.ItemIndex + 1]
    assert(row, 'Select an item first.')
    if frozen[row.item] then
      frozen[row.item]=nil;timer.Enabled=next(frozen)~=nil;drawRows();status.Caption='Selected stack unfrozen.';return
    end
    frozen[row.item] = makeFreeze(row, snapshot())
    timer.Enabled = true
    drawRows()
    status.Caption = 'Selected stack frozen. X marks every frozen stack.'
  end)
end
freezeAll.OnClick = function()
  if next(frozen) then stopFreeze();status.Caption='All inventory stacks unfrozen.';return end
  guarded(function()
    if not session then initialize() end
    populate()
    local snap = snapshot()
    local all = {}
    for _, row in ipairs(rows) do all[row.item] = makeFreeze(row, snap) end
    frozen = all
    timer.Enabled = next(frozen) ~= nil
    drawRows()
    status.Caption = string.format('Frozen %d current stacks. New stacks remain unfrozen.', #rows)
  end)
end
unfreezeSelected.OnClick = function()
  local row = rows[listbox.ItemIndex + 1]
  if not row then showMessage('Select an item first.'); return end
  frozen[row.item] = nil
  timer.Enabled = next(frozen) ~= nil
  drawRows()
  status.Caption = 'Selected stack unfrozen.'
end
timer.OnTimer = function()
  local changed = false
  for address, f in pairs(frozen) do
  local ok, err = pcall(function()
    local row, snap = f.row, f.snap
    assert(getOpenedProcessID() == session and getProcessIDFromProcessName('valheim.exe') == session,
      'Game process changed')
    assert(readPointer(f.storage) == snap.player
      and readPointer(snap.player + inventoryOffset) == snap.inventory
      and readPointer(snap.inventory + itemsOffset) == snap.collection, 'Player inventory changed')
    assert(readPointer(snap.collection) == f.listType, 'Inventory list identity changed')
    local version = integer(snap.collection + f.versionOffset, 'list version')
    local count = integer(snap.collection + f.sizeOffset, 'item count')
    assert(count >= 0 and count <= 512, 'Unexpected inventory size')
    local array = pointer(readPointer(snap.collection + f.arrayOffset), 'Item array')
    local capacity = readQword(array + 0x18)
    assert(capacity and capacity >= count and capacity <= 4096, 'Item array changed')
    local found = false
    for i=0,count-1 do if readPointer(array + 0x20 + i*8) == row.item then found=true; break end end
    -- A split can resize/reorder the list. Retry next tick if it changes mid-read.
    if readInteger(snap.collection + f.versionOffset) ~= version
      or readInteger(snap.collection + f.sizeOffset) ~= count
      or readPointer(snap.collection + f.arrayOffset) ~= array then return end
    assert(found, 'Item left your inventory')
    assert(readPointer(row.item) == f.itemType
      and readPointer(row.item + f.sharedOffset) == row.shared
      and readPointer(row.shared + f.nameOffset) == row.namePointer
      and readInteger(row.shared + f.maxOffset) == row.maximum, 'Item identity changed')
    local value = integer(row.address, 'quantity')
    assert(value >= 1 and value <= maxQuantity, 'Stack depleted or invalid quantity')
    if readInteger(snap.collection + f.versionOffset) ~= version then return end
    if value ~= row.quantity then
      assert(writeInteger(row.address, row.quantity), 'Freeze write failed')
    end
  end)
  if not ok then
    frozen[address] = nil
    changed = true
    status.Caption = 'A stack was unfrozen after it changed or left the inventory.'
    print('Valheim freeze stopped: ' .. tostring(err))
  end
  end
  timer.Enabled = next(frozen) ~= nil
  if changed then drawRows() end
end
-- Dictionary Entry is a value type: reported offsets include a 16-byte boxed
-- header. This verified layout has 24-byte inline entries in the array.
local function inspectSkills()
  if not session or session ~= getProcessIDFromProcessName('valheim.exe') then initialize() end
  local storage = localField.staticAddress
  if not storage or storage <= localField.offset then
    storage = pointer(mono_class_getStaticFieldAddress(playerClass), 'Static storage') + localField.offset
  end
  local player = pointer(readPointer(storage), 'Local player')
  local skillsOff = offset(playerClass, 'm_skills')
  local skills = pointer(readPointer(player + skillsOff), 'Skills')
  local sc = objectClass(skills)
  local dictOff = offset(sc, 'm_skillData')
  local dictionary = pointer(readPointer(skills + dictOff), 'Skill dictionary')
  local dc = objectClass(dictionary)
  local entriesOff, countOff = offset(dc, '_entries'), offset(dc, '_count')
  local versionOff = offset(dc, '_version')
  local entries = pointer(readPointer(dictionary + entriesOff), 'Skill entries')
  local count = integer(dictionary + countOff, 'skill count')
  local free = integer(dictionary + offset(dc, '_freeCount'), 'free skill entries')
  local version = integer(dictionary + versionOff, 'skill version')
  local capacity = readQword(entries + 0x18)
  assert(count >= 1 and count <= 512 and free >= 0 and free <= count
    and capacity and capacity >= count and capacity <= 4096, 'Unexpected skill dictionary size')
  local ec = pointer(mono_class_getArrayElementClass(objectClass(entries)), 'Skill entry class')
  assert(offset(ec,'hashCode') == 0x10 and offset(ec,'next') == 0x14
    and offset(ec,'key') == 0x18 and offset(ec,'value') == 0x20, 'Unsupported skill entry layout')
  local pending, keys = {}, {}
  for i=0,count-1 do
    local entry = entries + 0x20 + i*24
    local hash = integer(entry, 'skill hash')
    if hash >= 0 and hash < 2147483648 then
      local key = integer(entry + 8, 'skill key')
      assert(not keys[key], 'Duplicate skill key')
      keys[key] = true
      local skill = pointer(readPointer(entry + 16), 'Skill object')
      local c = objectClass(skill)
      local level = skill + offset(c, 'm_level')
      local accumulator = skill + offset(c, 'm_accumulator')
      local info = pointer(readPointer(skill + offset(c, 'm_info')), 'Skill definition')
      assert(integer(info + offset(objectClass(info), 'm_skill'), 'definition key') == key,
        'Skill definition does not match dictionary key')
      local old, progress = readFloat(level), readFloat(accumulator)
      assert(old and old == old and old >= 0 and old <= 1000000
        and progress and progress == progress and math.abs(progress) < 1e30, 'Invalid skill data')
      pending[#pending+1] = {key=key, entry=entry, skill=skill, level=level, accumulator=accumulator,
        old=old, progress=progress}
    end
  end
  assert(#pending == count-free and #pending > 0, 'Skill entry count mismatch')
  local function stable()
    assert(readPointer(storage) == player and readPointer(player+skillsOff) == skills
      and readPointer(skills+dictOff) == dictionary and readPointer(dictionary+entriesOff) == entries
      and readInteger(dictionary+versionOff) == version
      and readInteger(dictionary+countOff) == count, 'Skills changed. Try again.')
  end
  stable()
  -- Validate every target before writing any level.
  for _, p in ipairs(pending) do
    assert(readPointer(p.entry+16) == p.skill and readFloat(p.level) == p.old
      and readFloat(p.accumulator) == p.progress, 'Skill changed during inspection. Try again.')
  end
  return {rows=pending,stable=stable,player=player,skills=skills,pid=session}
end
local function setSkills(value,selected,expected)
  assert(value and value == value and value >= 0 and value <= 1000000,
    'Enter a finite skill level from 0 to 1000000.')
  local snapshot=inspectSkills()
  if expected then
    assert(snapshot.pid==expected.pid and snapshot.player==expected.player
      and snapshot.skills==expected.skills,'Player changed. Refresh the skill editor first.')
  end
  local pending={}
  local found={}
  for _,p in ipairs(snapshot.rows) do
    if not selected or selected[p.key] then
      if expected then
        local original
        for _,old in ipairs(expected.rows) do if old.key==p.key then original=old;break end end
        assert(original and original.skill==p.skill,'Skill changed. Refresh the skill editor first.')
      end
      pending[#pending+1]=p;found[p.key]=true
    end
  end
  if selected then
    for key in pairs(selected) do assert(found[key],'A selected skill disappeared. Refresh first.') end
  end
  assert(#pending>0,'Select at least one skill.')
  local stable=snapshot.stable
  local written = {}
  local ok, err = pcall(function()
    for _, p in ipairs(pending) do
      stable()
      assert(readPointer(p.entry+16) == p.skill, 'Skill reference changed')
      written[#written+1] = p
      assert(writeFloat(p.level, value), 'Skill level write failed')
      assert(writeFloat(p.accumulator, 0), 'Skill progress write failed')
      local actual = readFloat(p.level)
      assert(actual and math.abs(actual-value) <= math.max(0.0001, value*0.000001)
        and readFloat(p.accumulator) == 0, 'Skill write verification failed')
    end
  end)
  if not ok then
    local restored = 0
    for _, p in ipairs(written) do
      local reverted = pcall(function()
        stable()
        assert(readPointer(p.entry+16) == p.skill, 'Reference changed')
        assert(writeFloat(p.level,p.old) and writeFloat(p.accumulator,p.progress), 'Restore failed')
        assert(readFloat(p.level)==p.old and readFloat(p.accumulator)==p.progress, 'Restore verification failed')
      end)
      if reverted then restored=restored+1 end
    end
    error(tostring(err) .. string.format(' Restored %d/%d attempted entries.',restored,#written))
  end
  skillStatus.Caption = string.format('Set %d skills to %g; level progress reset. Reopen the game Skills screen.',#pending,value)
  print(skillStatus.Caption)
end
local function skillAction(value)
  local ok, err = pcall(function() setSkills(value) end)
  if not ok then
    skillStatus.Caption = 'Skill update stopped; see error message.'
    print('Valheim skills: ' .. tostring(err))
    showMessage('Valheim skills: ' .. tostring(err))
  end
end
maxSkills.OnClick = function() skillAction(100) end
do
local window,checks,all,levelInput,message,displayed
local changing=false
local function skillNames()
  local names={}
  local c=mono_findClass('','Skills+SkillType')
  if c and c~=0 then
    for _,f in ipairs(mono_class_enumFields(c,false) or {}) do
      if f.isStatic and f.isConst then
        local ok,value=pcall(mono_class_getStaticFieldValue,c,f.field)
        if ok and type(value)=='number' then
          names[value]=f.name:gsub('(%l)(%u)','%1 %2'):gsub('_',' ')
        end
      end
    end
  end
  return names
end
local function refreshSkills()
  local fresh=inspectSkills()
  local names=skillNames()
  table.sort(fresh.rows,function(a,b) return (names[a.key] or tostring(a.key))<(names[b.key] or tostring(b.key)) end)
  local selected={}
  for _,entry in ipairs(checks or {}) do
    if entry.control.Checked then selected[entry.key]=true end
    entry.control.destroy()
  end
  checks={};changing=true;all.Checked=false;changing=false
  displayed=fresh
  for i,p in ipairs(fresh.rows) do
    local cb=createCheckBox(window)
    cb.Caption=string.format('%s   (current: %g)',names[p.key] or ('Skill #'..p.key),p.old)
    cb.Font.Color=0xE6E6E6;cb.Checked=selected[p.key] or false
    cb.Left=18+((i-1)%2)*300;cb.Top=92+math.floor((i-1)/2)*28
    cb.Width=290;cb.Height=24
    hint(cb,'Check to change this skill. Unchecked skills keep their level and progress.')
    cb.OnChange=function()
      if changing then return end
      local every=#checks>0
      for _,entry in ipairs(checks) do if not entry.control.Checked then every=false end end
      changing=true;all.Checked=every;changing=false
    end
    checks[#checks+1]={key=p.key,control=cb}
  end
  local every=#checks>0
  for _,entry in ipairs(checks) do if not entry.control.Checked then every=false end end
  changing=true;all.Checked=every;changing=false
  window.Height=math.max(270,92+math.ceil(#checks/2)*28+94)
  message.Top=92+math.ceil(#checks/2)*28+8
  message.Caption='Choose skills, enter a level, then Apply. Unchecked skills are unchanged.'
end
local function guarded(fn)
  local ok,err=pcall(fn)
  if not ok then message.Caption=tostring(err);showMessage('Valheim skills: '..tostring(err)) end
end
if ValheimSkillEditorStop then pcall(ValheimSkillEditorStop) end
ValheimSkillEditorStop=function() if window then window.destroy();window=nil;checks=nil end end
customSkills.OnClick=function()
  if window then window.show();guarded(refreshSkills);return end
  window=createForm(false);window.Caption='Valheim | Set skill levels'
  window.Width=640;window.Height=400;window.Position='poScreenCenter';window.BorderStyle='bsSingle'
  window.Color=0x202020;window.Font.Color=0xE6E6E6
  local intro=createLabel(window);intro.Caption='Select individual skills, or check Select all. Normal maximum: 100.'
  intro.Left=18;intro.Top=16;intro.Font.Color=0x8DCCE8
  all=createCheckBox(window);all.Caption='Select all';all.Left=18;all.Top=49;all.Width=115
  hint(all,'Check every skill currently listed. Uncheck to clear the selection.')
  all.OnChange=function()
    if changing then return end
    changing=true
    for _,entry in ipairs(checks or {}) do entry.control.Checked=all.Checked end
    changing=false
  end
  local label=createLabel(window);label.Caption='Level:';label.Left=145;label.Top=53
  levelInput=createEdit(window);levelInput.Left=188;levelInput.Top=47;levelInput.Width=100;levelInput.Text='100'
  levelInput.Color=0x292929;levelInput.Font.Color=0xE6E6E6
  hint(levelInput,'Enter 0 to 1000000, including levels above 100. Selected skills have progress toward the next level reset.')
  local apply=createButton(window);apply.Caption='Apply level';apply.Left=302;apply.Top=46;apply.Width=142;apply.Height=30
  hint(apply,'Apply the entered level only to checked skills. Their progress resets; other skills are unchanged.')
  local refreshSkillsButton=createButton(window);refreshSkillsButton.Caption='Refresh skills';refreshSkillsButton.Left=454;refreshSkillsButton.Top=46;refreshSkillsButton.Width=150;refreshSkillsButton.Height=30
  hint(refreshSkillsButton,'Reload the current player skill list and levels. Use after changing character or world.')
  message=createLabel(window);message.Left=18;message.Width=588;message.Height=48
  message.AutoSize=false;message.WordWrap=true;message.Font.Color=0x8DCCE8
  apply.OnClick=function() guarded(function()
    local selected={}
    for _,entry in ipairs(checks or {}) do if entry.control.Checked then selected[entry.key]=true end end
    setSkills(tonumber(levelInput.Text),selected,displayed)
    refreshSkills();message.Caption=skillStatus.Caption
  end) end
  refreshSkillsButton.OnClick=function() guarded(refreshSkills) end
  window.OnClose=function() return caHide end
  window.show();guarded(refreshSkills)
end
local oldClose,oldDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() if window then window.hide() end;return oldClose() end
form.OnDestroy=function() ValheimSkillEditorStop();oldDestroy() end
end
local playerTimer = createTimer(form, false)
playerTimer.Interval = 100
local godState, staminaState, craftingState, flightState
local function playerIdentity(s)
  return s and getOpenedProcessID() == s.pid
    and getProcessIDFromProcessName('valheim.exe') == s.pid
    and readPointer(s.storage) == s.player and readPointer(s.player) == s.vtable
end
local function playerLabels()
  godButton.Caption = godState and 'God mode: ON' or 'God mode: OFF'
  staminaButton.Caption = staminaState and 'Unlimited stamina: ON' or 'Unlimited stamina: OFF'
  craftingButton.Caption = craftingState and 'Free crafting: ON' or 'Free crafting: OFF'
  flightButton.Caption=flightState and 'Flight: ON' or 'Flight: OFF'
  playerTimer.Enabled = godState ~= nil or staminaState ~= nil or craftingState ~= nil or flightState~=nil
end
local function installDamageBlock(s)
  local class = pointer(mono_findClass('', 'Character'), 'Character class')
  local method = pointer(mono_class_findMethod(class, 'ApplyDamage'), 'Character.ApplyDamage')
  local signature = mono_method_get_parameters(method)
  assert(signature and signature.returntype == 1, 'ApplyDamage must return void')
  local entry = pointer(mono_compile_method(method), 'Compiled ApplyDamage')
  local size, replay = 0, {}
  while size < 14 do
    local n = getInstructionSize(entry+size)
    assert(n and n > 0 and n <= 15, 'Cannot decode damage method prologue')
    replay[#replay+1] = string.format('reassemble(%X)',entry+size)
    size = size+n
  end
  local bytes = readBytes(entry,size,true)
  assert(bytes and #bytes == size, 'Cannot read damage method')
  local hex = {}
  for _, b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
  local original = table.concat(hex,' ')
  -- Windows x64 Mono: the instance (this) is in RCX. Preserve flags/RAX.
  -- Also compare the current static player so an old player object is never targeted.
  local script = string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhDamageGuard,1024,%X)
label(vhDamagePass)
vhDamageGuard:
pushfq
push rax
mov rax,%X
cmp rcx,rax
jne vhDamagePass
mov rax,%X
cmp [rax],rcx
jne vhDamagePass
pop rax
popfq
ret
vhDamagePass:
pop rax
popfq
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhDamageGuard
%s
[DISABLE]
%X:
db %s
dealloc(vhDamageGuard)
]],entry,original,entry,s.player,s.storage,table.concat(replay,'\n'),entry+size,
    entry,size>14 and string.format('nop %X',size-14) or '',entry,original)
  local ok, info = autoAssemble(script, false)
  assert(ok, 'Damage block installation failed: ' .. tostring(info))
  s.hookScript, s.hookInfo = script, info
end
local function installCraftingBlock(s)
  local class = pointer(mono_findClass('', 'Player'), 'Player class')
  local method = pointer(mono_class_findMethod(class, 'ConsumeResources'), 'Player.ConsumeResources')
  local signature = mono_method_get_parameters(method)
  assert(signature and signature.returntype == 1, 'ConsumeResources must return void')
  local entry = pointer(mono_compile_method(method), 'Compiled ConsumeResources')
  local size, replay = 0, {}
  while size < 14 do
    local n = getInstructionSize(entry+size)
    assert(n and n > 0 and n <= 15, 'Cannot decode resource consumption method prologue')
    replay[#replay+1] = string.format('reassemble(%X)',entry+size)
    size = size+n
  end
  local bytes = readBytes(entry,size,true)
  assert(bytes and #bytes == size, 'Cannot read resource consumption method')
  local hex = {}
  for _, b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
  local original = table.concat(hex,' ')
  -- Windows x64 Mono: the instance (this) is in RCX. Preserve flags/RAX.
  -- Also compare the current static player so an old player object is never targeted.
  local script = string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhCraftCostGuard,1024,%X)
label(vhCraftCostPass)
vhCraftCostGuard:
pushfq
push rax
mov rax,%X
cmp rcx,rax
jne vhCraftCostPass
mov rax,%X
cmp [rax],rcx
jne vhCraftCostPass
mov rax,%X
cmp byte ptr [rax],1
jne vhCraftCostPass
pop rax
popfq
ret
vhCraftCostPass:
pop rax
popfq
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhCraftCostGuard
%s
[DISABLE]
%X:
db %s
// Keep allocation alive for any in-flight original call.
]],entry,original,entry,s.player,s.storage,s.address,table.concat(replay,'\n'),entry+size,
    entry,size>14 and string.format('nop %X',size-14) or '',entry,original)
  local ok, info = autoAssemble(script, false)
  assert(ok, 'Free-crafting resource guard installation failed: ' .. tostring(info))
  s.hookScript, s.hookInfo = script, info
end
local function stopGod()
  local s = godState
  if s and s.hookInfo and getOpenedProcessID() == s.pid
    and getProcessIDFromProcessName('valheim.exe') == s.pid then
    local ok, err = autoAssemble(s.hookScript,false,s.hookInfo)
    assert(ok, 'Could not remove damage block: ' .. tostring(err))
    s.hookInfo = nil
  end
  godState = nil
  if playerIdentity(s) and readBytes(s.address,1) == 1 then
    assert(writeBytes(s.address,s.original), 'Could not restore original god-mode flag')
    assert(readBytes(s.address,1) == s.original, 'God-mode restore verification failed')
  end
end
local function stopCrafting()
  local s=craftingState
  if s and s.hookInfo and getOpenedProcessID()==s.pid
    and getProcessIDFromProcessName('valheim.exe')==s.pid then
    local ok,err=autoAssemble(s.hookScript,false,s.hookInfo)
    assert(ok,'Could not remove free-crafting resource guard: '..tostring(err))
    s.hookInfo=nil
  end
  craftingState=nil
  if playerIdentity(s) and readBytes(s.address,1)==1 then
    assert(writeBytes(s.address,s.original),'Could not restore no-cost crafting flag')
    assert(readBytes(s.address,1)==s.original,'No-cost crafting restore verification failed')
  end
end
local function stopFlight()
  local s=flightState
  if playerIdentity(s) then
    assert(writeBytes(s.address,s.original),'Could not restore original flight setting')
    assert(readBytes(s.address,1)==s.original,'Flight restore verification failed')
  end
  flightState=nil
end
local function stopPlayerCheats()
  playerTimer.Enabled = false
  staminaState = nil
  local ok, err = pcall(stopGod)
  local craftingOK, craftingError = pcall(stopCrafting)
  local flightOK,flightError=pcall(stopFlight)
  playerLabels()
  if not ok then print('Valheim player toggle restore: ' .. tostring(err)) end
  if not craftingOK then print('Valheim crafting restore: '..tostring(craftingError)) end
  if not flightOK then print('Valheim flight restore: '..tostring(flightError)) end
end
ValheimPlayerCheatsStop = stopPlayerCheats
form.OnClose = function() stopPlayerCheats(); stopFreeze(); return caHide end
form.OnDestroy = function() stopPlayerCheats(); stopFreeze() end
local function playerContext()
  if not session or session ~= getProcessIDFromProcessName('valheim.exe') then initialize() end
  local storage = localField.staticAddress
  if not storage or storage <= localField.offset then
    storage = pointer(mono_class_getStaticFieldAddress(playerClass), 'Static storage') + localField.offset
  end
  local player = readPointer(storage)
  assert(type(player)=='number' and player>0,
    'No active local player. Finish respawning or loading your world, wait until you can move, then Refresh inventory and try again.')
  return {pid=session, storage=storage, player=player, vtable=pointer(readPointer(player),'Player type')}
end
local function typedPlayerOffset(name, typename)
  local f = field(playerClass,name)
  assert(f.typename == typename and not f.isStatic,
    'Unexpected type for ' .. name .. ': ' .. tostring(f.typename))
  return offset(playerClass,name)
end
local function playerAction(action)
  local ok, err = pcall(action)
  playerLabels()
  if not ok then
    playerStatus.Caption = 'Toggle failed; see error message.'
    print('Valheim player toggles: ' .. tostring(err))
    showMessage('Valheim player toggles: ' .. tostring(err))
  end
end
godButton.OnClick = function()
  playerAction(function()
    if godState then stopGod(); playerStatus.Caption='God mode restored to its previous setting.'; return end
    local s = playerContext()
    s.address = s.player + typedPlayerOffset('m_godMode','System.Boolean')
    s.original = readBytes(s.address,1)
    assert(s.original == 0 or s.original == 1, 'Invalid god-mode flag')
    assert(playerIdentity(s), 'Player changed')
    godState = s
    local ok, err = pcall(function()
      installDamageBlock(s)
      assert(writeBytes(s.address,1), 'God-mode write failed')
      assert(readBytes(s.address,1) == 1, 'God-mode verification failed')
    end)
    if not ok then pcall(stopGod); error(err) end
    playerStatus.Caption='God mode enabled: local-player damage blocked.'
  end)
end
staminaButton.OnClick = function()
  playerAction(function()
    if staminaState then staminaState=nil; playerStatus.Caption='Stamina refill stopped.'; return end
    local s = playerContext()
    s.address = s.player + typedPlayerOffset('m_stamina','System.Single')
    s.maximum = s.player + typedPlayerOffset('m_maxStamina','System.Single')
    local maximum, current = readFloat(s.maximum), readFloat(s.address)
    assert(maximum and maximum == maximum and maximum > 0 and maximum <= 1000000
      and current and current == current and math.abs(current) <= 1000000, 'Invalid stamina values')
    assert(playerIdentity(s), 'Player changed')
    assert(writeFloat(s.address,maximum), 'Stamina write failed')
    staminaState=s
    playerStatus.Caption='Stamina refills to the current maximum every 100 ms.'
  end)
end
craftingButton.OnClick=function()
  playerAction(function()
    if craftingState then
      stopCrafting()
      playerStatus.Caption='Free crafting restored to its previous setting. Reopen the crafting menu.'
      return
    end
    local s=playerContext()
    s.address=s.player+typedPlayerOffset('m_noPlacementCost','System.Boolean')
    s.original=readBytes(s.address,1)
    assert(s.original==0 or s.original==1,'Invalid no-cost crafting flag')
    assert(playerIdentity(s),'Player changed')
    craftingState=s
    local ok,err=pcall(function()
      installCraftingBlock(s)
      assert(writeBytes(s.address,1),'No-cost crafting write failed')
      assert(readBytes(s.address,1)==1,'No-cost crafting verification failed')
    end)
    if not ok then pcall(stopCrafting);error(err) end
    playerStatus.Caption='Free crafting enabled. Reopen crafting/build menus to refresh requirements.'
  end)
end
flightButton.OnClick=function()
  playerAction(function()
    if flightState then
      stopFlight()
      playerStatus.Caption='Previous flight setting restored. Land before turning flight off.'
      return
    end
    local s=playerContext()
    s.address=s.player+typedPlayerOffset('m_debugFly','System.Boolean')
    s.original=readBytes(s.address,1)
    assert(s.original==0 or s.original==1,'Invalid flight flag')
    assert(playerIdentity(s),'Player changed')
    flightState=s
    local ok,err=pcall(function()
      assert(writeBytes(s.address,1),'Flight write failed')
      assert(readBytes(s.address,1)==1,'Flight verification failed')
    end)
    if not ok then pcall(stopFlight);error(err) end
    playerStatus.Caption='Flight: movement keys; Jump/Space rises, Left Ctrl descends, Run/Shift speeds up. Land before disabling. Collision bypass is not enabled.'
  end)
end
playerTimer.OnTimer = function()
  if flightState then
    local ok,err=pcall(function()
      assert(playerIdentity(flightState),'Player changed or world unloaded')
      local value=readBytes(flightState.address,1)
      assert(value==0 or value==1,'Invalid flight flag')
      if value==0 then
        assert(writeBytes(flightState.address,1),'Flight write failed')
        assert(readBytes(flightState.address,1)==1,'Flight verification failed')
      end
    end)
    if not ok then
      pcall(stopFlight)
      playerStatus.Caption='Flight stopped: player changed or memory unavailable.'
      print('Valheim flight stopped: '..tostring(err))
    end
  end
  if godState then
    local ok, err = pcall(function()
      assert(playerIdentity(godState), 'Player changed or world unloaded')
      local v = readBytes(godState.address,1)
      assert(v == 0 or v == 1, 'Invalid god-mode flag')
      if v == 0 then assert(writeBytes(godState.address,1), 'God-mode write failed') end
    end)
    if not ok then
      pcall(stopGod)
      playerStatus.Caption='God mode stopped: player changed or memory unavailable.'
      print('Valheim god mode stopped: ' .. tostring(err))
    end
  end
  if staminaState then
    local ok, err = pcall(function()
      local s=staminaState
      assert(playerIdentity(s), 'Player changed or world unloaded')
      local maximum=readFloat(s.maximum)
      assert(maximum and maximum == maximum and maximum > 0 and maximum <= 1000000, 'Invalid maximum stamina')
      assert(writeFloat(s.address,maximum), 'Stamina refill failed')
    end)
    if not ok then
      staminaState=nil
      playerStatus.Caption='Stamina refill stopped: player changed or memory unavailable.'
      print('Valheim stamina stopped: ' .. tostring(err))
    end
  end
  if craftingState then
    local ok,err=pcall(function()
      assert(playerIdentity(craftingState),'Player changed or world unloaded')
      local value=readBytes(craftingState.address,1)
      assert(value==0 or value==1,'Invalid no-cost flag')
      if value==0 then assert(writeBytes(craftingState.address,1),'No-cost write failed') end
    end)
    if not ok then
      pcall(stopCrafting)
      playerStatus.Caption='Free crafting stopped: player changed or memory unavailable.'
      print('Valheim free crafting stopped: '..tostring(err))
    end
  end
  playerLabels()
end
local function matchingMethod(class,name,types,returnType)
  local found
  for _, m in ipairs(mono_class_enumMethods(class) or {}) do
    if m.name == name then
      local p=mono_method_get_parameters(m.method)
      if p and p.parameters and #p.parameters == #types and p.returntype == returnType then
        local matches=true
        for i,t in ipairs(types) do if p.parameters[i].type ~= t then matches=false end end
        if matches then assert(not found,'Ambiguous method: '..name); found=m.method end
      end
    end
  end
  return pointer(found,'Compatible '..name..' method')
end
local function invoke(method,object,args)
  local result,err=mono_invoke_method(0,method,object,args)
  assert(not err or err=='','Game method failed: '..tostring(err))
  return result
end
cloneButton.OnClick = function()
  guarded(function()
    local row=rows[listbox.ItemIndex+1]
    assert(row,'Select an item first.')
    local snap=snapshot()
    assert(snap.player==row.player and snap.inventory==row.inventory,'Player changed. Refresh first.')
    local ic=objectClass(snap.inventory)
    local width=integer(snap.inventory+offset(ic,'m_width'),'inventory width')
    local height=integer(snap.inventory+offset(ic,'m_height'),'inventory height')
    assert(width>0 and height>0 and width*height<=512,'Unexpected inventory dimensions')
    local occupied, found={},false
    for _,item in ipairs(snap.items) do
      if item==row.item then found=true end
      local grid=item+offset(objectClass(item),'m_gridPos')
      local x,y=integer(grid,'slot x'),integer(grid+4,'slot y')
      assert(x>=0 and x<width and y>=0 and y<height,'Item outside inventory grid')
      occupied[y*width+x]=true
    end
    assert(found,'Selected item left your inventory. Refresh first.')
    local targetX,targetY
    for y=0,height-1 do
      for x=0,width-1 do
        if not occupied[y*width+x] then targetX,targetY=x,y; break end
      end
      if targetX then break end
    end
    if not targetX then status.Caption='Inventory full: free a slot before cloning.'; return end
    local current=itemInfo(row.item)
    assert(current.shared==row.shared and current.class==row.class and current.namePointer==row.namePointer,
      'Selected item changed. Refresh first.')
    -- Match the verified overload: AddItem(ItemData, int amount, int x, int y, bool).
    local cloneMethod=matchingMethod(current.class,'Clone',{},18)
    local addMethod=matchingMethod(ic,'AddItem',{18,8,8,8,2},2)
    local check=snapshot()
    assert(check.inventory==snap.inventory and check.player==snap.player
      and check.collection==snap.collection and check.version==snap.version,'Inventory changed. Try again.')
    local copy=pointer(invoke(cloneMethod,current.item,{}),'Cloned item')
    assert(copy~=current.item,'Clone returned the source item')
    local copyInfo=itemInfo(copy)
    assert(copyInfo.class==current.class and copyInfo.shared==current.shared
      and copyInfo.quantity==current.quantity,'Clone did not match source')
    -- Equipment copies belong in the bag, not in an equipped state.
    local equipped=fields(copyInfo.class).m_equipped
    if equipped then
      assert(equipped.typename=='System.Boolean' and not equipped.isStatic,'Unexpected equipped flag')
      assert(writeBytes(copy+equipped.offset,0),'Could not clear clone equipped flag')
    end
    check=snapshot()
    assert(check.inventory==snap.inventory and check.player==snap.player
      and check.collection==snap.collection and check.version==snap.version,'Inventory changed before placement; clone not added.')
    local added=invoke(addMethod,snap.inventory,{copy,current.quantity,targetX,targetY,0})
    assert(added==true or added==1,'Game rejected clone placement. Refresh inventory before retrying.')
    local after=snapshot()
    assert(after.inventory==snap.inventory and after.player==snap.player,'Player changed after clone; inspect inventory.')
    local old={}
    for _,item in ipairs(snap.items) do old[item]=true end
    local newItem
    for _,item in ipairs(after.items) do
      if not old[item] then
        local grid=item+offset(objectClass(item),'m_gridPos')
        if readInteger(grid)==targetX and readInteger(grid+4)==targetY then newItem=item end
      end
    end
    assert(newItem,'Clone call completed, but placement could not be verified. Refresh before retrying.')
    local result=itemInfo(newItem)
    assert(result.shared==current.shared and result.quantity==current.quantity,
      'Clone was added with unexpected contents. Refresh before retrying.')
    populate(newItem)
    status.Caption=string.format('Cloned %s x%d into slot (%d, %d). Copy is unfrozen.',current.name,current.quantity,targetX+1,targetY+1)
  end)
end
-- Ctrl-click uses Inventory.MoveItemToThis(Inventory, ItemData). Pass a clone
-- to that method on the game thread, so the source item never leaves its slot.
local refillState
local function stopRefill()
  if refillState then
    local s=refillState
    if getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
      local ok,err=autoAssemble(s.script,false,s.info)
      assert(ok,'Could not disable auto refill: '..tostring(err))
    end
    refillState=nil
  end
  depositButton.Caption='Auto refill: OFF'
end
ValheimAutoRefillStop=stopRefill
local previousClose,previousDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopRefill(); return previousClose() end
form.OnDestroy=function() stopRefill(); previousDestroy() end
depositButton.OnClick=function()
  local ok,err=pcall(function()
    if refillState then stopRefill(); status.Caption='Auto refill off. Ctrl+click moves stacks normally.'; return end
    if not session or session~=getProcessIDFromProcessName('valheim.exe') then initialize() end
    local snap=snapshot()
    local pc=playerClass
    local playerStorage=localField.staticAddress
    if not playerStorage or playerStorage<=localField.offset then
      playerStorage=pointer(mono_class_getStaticFieldAddress(pc),'Player storage')+localField.offset
    end
    local gc=pointer(mono_findClass('','InventoryGui'),'InventoryGui class')
    local gf=field(gc,'m_instance')
    assert(gf.isStatic,'Unexpected GUI instance field')
    local guiStorage=gf.staticAddress
    if not guiStorage or guiStorage<=gf.offset then
      guiStorage=pointer(mono_class_getStaticFieldAddress(gc),'GUI storage')+gf.offset
    end
    local containerOff=offset(gc,'m_currentContainer')
    local cc=pointer(mono_findClass('','Container'),'Container class')
    local chestInvOff=offset(cc,'m_inventory')
    local ic=pointer(mono_findClass('','Inventory'),'Inventory class')
    local itemClass=pointer(mono_findClass('','ItemDrop+ItemData'),'ItemData class')
    local clone=pointer(mono_compile_method(matchingMethod(itemClass,'Clone',{},18)),'Clone code')
    local method=matchingMethod(ic,'MoveItemToThis',{18,18},1)
    local entry=pointer(mono_compile_method(method),'Quick transfer code')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode transfer prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size)
      size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read transfer prologue')
    local hex={}
    for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    local script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhRefill,2048,%X)
label(vhRefillPass)
label(vhRefillReplay)
label(vhRefillNoCopy)
vhRefill:
pushfq
push rax
mov rax,%X
mov rax,[rax]
test rax,rax
je vhRefillPass
mov rax,[rax+%X]
cmp rdx,rax
jne vhRefillPass
cmp rcx,rdx
je vhRefillPass
test r8,r8
je vhRefillPass
mov rax,%X
mov rax,[rax]
test rax,rax
je vhRefillPass
mov rax,[rax+%X]
test rax,rax
je vhRefillPass
mov rax,[rax+%X]
cmp rcx,rax
jne vhRefillPass
pop rax
popfq
sub rsp,48
mov [rsp+20],rcx
mov [rsp+28],rdx
mov [rsp+30],r8
mov [rsp+38],r9
mov rcx,r8
call %X
mov rcx,[rsp+20]
mov rdx,[rsp+28]
mov r9,[rsp+38]
add rsp,48
test rax,rax
je vhRefillNoCopy
mov r8,rax
jmp vhRefillReplay
vhRefillPass:
pop rax
popfq
vhRefillReplay:
%s
jmp %X
vhRefillNoCopy:
ret
%X:
db FF 25 00 00 00 00
dq vhRefill
%s
[DISABLE]
%X:
db %s
dealloc(vhRefill)
]],entry,original,entry,playerStorage,inventoryOffset,guiStorage,containerOff,chestInvOff,
      clone,table.concat(replay,'\n'),entry+size,entry,size>14 and string.format('nop %X',size-14) or '',entry,original)
    local installed,info=autoAssemble(script,false)
    assert(installed,'Auto refill installation failed: '..tostring(info))
    refillState={pid=session,script=script,info=info}
    depositButton.Caption='Auto refill: ON'
    status.Caption='Auto refill ON: Ctrl+click into an open chest. The original stack stays in its slot.'
  end)
  if not ok then
    print('Valheim auto refill: '..tostring(err))
    showMessage('Valheim auto refill: '..tostring(err))
  end
end

local flagTimer=createTimer(form,false)
flagTimer.Interval=500
local flagTypes={}
local flagSession
local function stopItemFlags()
  flagTimer.Enabled=false
  flagSession=nil
  keepFlagsButton.Caption='Remove cheated item flags: OFF'
end
ValheimItemFlagsStop=stopItemFlags
local flagClose,flagDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopItemFlags(); return flagClose() end
form.OnDestroy=function() stopItemFlags(); flagDestroy() end
local function clearItemFlags()
  local snap=snapshot()
  if flagSession then
    assert(flagSession.pid==session and flagSession.player==snap.player
      and flagSession.inventory==snap.inventory,'Player changed; enable the item flag toggle again.')
  end
  local lc=objectClass(snap.collection)
  local versionAddress=snap.collection+offset(lc,'_version')
  local storage=localField.staticAddress
  if not storage or storage<=localField.offset then
    storage=pointer(mono_class_getStaticFieldAddress(playerClass),'Player storage')+localField.offset
  end
  local function unchanged()
    return getOpenedProcessID()==session and readPointer(storage)==snap.player
      and readPointer(snap.player+inventoryOffset)==snap.inventory
      and readPointer(snap.inventory+itemsOffset)==snap.collection
      and readInteger(versionAddress)==snap.version
  end
  local cleared=0
  local flags={}
  for _,item in ipairs(snap.items) do
      if not unchanged() then return cleared,false,snap end
      local vtable=pointer(readPointer(item),'Item type')
      local off=flagTypes[vtable]
      if not off then
        local c=objectClass(item)
        local f=field(c,'m_cheated')
        assert(not f.isStatic and f.typename=='System.Boolean','Unexpected m_cheated field type')
        off=offset(c,'m_cheated'); flagTypes[vtable]=off
      end
      local value=readBytes(item+off,1)
      assert(value==0 or value==1,'Invalid item flag value')
      if not unchanged() or readPointer(item)~=vtable then return cleared,false,snap end
      if value==1 then
        assert(writeBytes(item+off,0),'Could not clear item flag')
        assert(readBytes(item+off,1)==0,'Item flag clear verification failed')
        cleared=cleared+1
      end
      flags[item]=0
  end
  for _,row in ipairs(rows) do if flags[row.item]~=nil then row.cheated=flags[row.item] end end
  drawRows()
  return cleared,true,snap
end
keepFlagsButton.OnClick=function()
  if flagTimer.Enabled then
    stopItemFlags(); status.Caption='Automatic item flag clearing stopped. Already-cleared flags stay cleared.'; return
  end
  local ok,err=pcall(function()
    if not session or session~=getProcessIDFromProcessName('valheim.exe') then initialize() end
    flagTypes={}
    local snap=snapshot()
    flagSession={pid=session,player=snap.player,inventory=snap.inventory,version=snap.version}
    clearItemFlags()
    populate()
    flagTimer.Enabled=true
    keepFlagsButton.Caption='Remove cheated item flags: ON'
    status.Caption='Clearing flags in your inventory every 0.5 seconds, including newly crafted/upgraded items.'
  end)
  if not ok then stopItemFlags(); showMessage('Valheim item flags: '..tostring(err)) end
end
clearFlagButton.OnClick=keepFlagsButton.OnClick -- legacy hidden control uses the same inventory-wide toggle
flagTimer.OnTimer=function()
  local ok,err=pcall(function()
    assert(flagSession and getProcessIDFromProcessName('valheim.exe')==flagSession.pid,'Game process changed')
    local _,complete,snap=clearItemFlags()
    if complete and snap.version~=flagSession.version then
      populate(); flagSession.version=snap.version
    end
  end)
  if not ok then
    stopItemFlags()
    status.Caption='Automatic item flag clearing stopped: player changed or memory unavailable.'
    print('Valheim item flags: '..tostring(err))
  end
end
local movementState,enemyMovementChanged
local function movementLabels()
  speedButton.Caption=string.format('Movement speed: %gx',movementState and movementState.speed or 1)
  jumpButton.Caption=string.format('Jump force: %gx',movementState and movementState.jump or 1)
end
local function resetMovement()
  local s=movementState
  if s and playerIdentity(s) then
    for _,p in pairs(s.values) do
      assert(playerIdentity(s),'Player changed while restoring movement')
      assert(writeFloat(p.address,p.original),'Could not restore '..p.name)
      assert(readFloat(p.address)==p.original,'Restore verification failed: '..p.name)
    end
  end
  if enemyMovementChanged then enemyMovementChanged(1,1) end
  movementState=nil
  movementLabels()
end
ValheimMovementStop=resetMovement
local movementClose,movementDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() resetMovement(); return movementClose() end
form.OnDestroy=function() resetMovement(); movementDestroy() end
local function setMovement(kind,multiplier)
  local limit=kind=='speed' and 20 or 10
  assert(multiplier and multiplier==multiplier and multiplier>=0.1 and multiplier<=limit,
    'Enter a multiplier from 0.1 to '..limit..'.')
  if movementState and not playerIdentity(movementState) then movementState=nil end
  if not movementState then
    local s=playerContext()
    s.values={}; s.speed=1; s.jump=1
    movementState=s
  end
  local s=movementState
  local names=kind=='speed' and {'m_speed','m_walkSpeed','m_runSpeed','m_crouchSpeed','m_swimSpeed'}
    or {'m_jumpForce'}
  local pending={}
  for _,name in ipairs(names) do
    local p=s.values[name]
    if not p then
      local address=s.player+typedPlayerOffset(name,'System.Single')
      local original=readFloat(address)
      assert(original and original==original and original>0 and original<=10000,'Invalid normal value for '..name)
      p={name=name,address=address,original=original}; s.values[name]=p
    end
    local prior=readFloat(p.address)
    assert(prior and prior==prior and prior>0 and prior<=1000000,'Invalid current movement value')
    pending[#pending+1]={field=p,prior=prior,value=p.original*multiplier}
  end
  assert(playerIdentity(s),'Player changed; try again.')
  local changed={}
  local ok,err=pcall(function()
    for _,p in ipairs(pending) do
      assert(playerIdentity(s),'Player changed during movement update')
      changed[#changed+1]=p
      assert(writeFloat(p.field.address,p.value),'Write failed: '..p.field.name)
      local actual=readFloat(p.field.address)
      assert(actual and math.abs(actual-p.value)<=math.max(0.0001,math.abs(p.value)*0.000001),
        'Movement verification failed: '..p.field.name)
    end
    if enemyMovementChanged then enemyMovementChanged(kind=='speed' and multiplier or s.speed,kind=='jump' and multiplier or s.jump) end
  end)
  if not ok then
    local restored=0
    for _,p in ipairs(changed) do
      if playerIdentity(s) and writeFloat(p.field.address,p.prior) and readFloat(p.field.address)==p.prior then restored=restored+1 end
    end
    error(tostring(err)..string.format(' Restored %d/%d attempted fields.',restored,#changed))
  end
  s[kind]=multiplier
  movementLabels()
  skillStatus.Caption=kind=='speed' and 'Speed multiplier applied to walking, running, crouching and swimming.'
    or 'Jump-force multiplier applied. Jump height does not scale linearly with force.'
end
local function movementAction(kind)
  local current=movementState and movementState[kind] or 1
  local maximum=kind=='speed' and 20 or 10
  local answer=inputQuery(kind=='speed' and 'Movement speed' or 'Jump force',
    'Multiplier (0.1-'..maximum..'). 1 = normal; try 2 first:',tostring(current))
  if answer==nil then return end
  local ok,err=pcall(function() setMovement(kind,tonumber(answer)) end)
  if not ok then showMessage('Valheim movement: '..tostring(err)) end
end
speedButton.OnClick=function() movementAction('speed') end
jumpButton.OnClick=function() movementAction('jump') end
resetMovementButton.OnClick=function()
  local ok,err=pcall(resetMovement)
  if ok then skillStatus.Caption='Original movement speed and jump force restored.'
  else showMessage('Valheim movement: '..tostring(err)) end
end
-- Teleport requests run on the game's thread through Player.UpdateTeleport.
do
local window, destinations, teleportStatus, locationLabel, poll, spawnWindow, spawnStatus, trophyStatus, tamingWindow, tamingStatus
local entries, saved, worldKey = {}, {}, nil
local favorites, favoriteButton = {}, nil
local hook, pending, settings
local recoveryHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300d48ed66a0000000000000000e00002210b010b000074010000060000000000001e9201000020000000a001000000001000200000000200000400000000000000040000000000000000e001000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000d09101004b00000000a00100f00200000000000000000000000000000000000000c001000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000024720100002000000074010000020000000000000000000000000000200000602e72737263000000f002000000a001000004000000760100000000000000000000000000400000402e72656c6f6300000c00000000c0010000020000007a0100000000000000000000000000400000420000000000000000000000000000000000920100000000004800000002000500fccc0000d4c4000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b3002002d0000000100001100160a7e01000004250c1200280300000a007e060000040bde100616fe010d092d0708280400000a00dc00072a0000000110000002000300171a0010000000001b3002002d0000000200001100160a7e01000004250c1200280300000a007e090000040bde100616fe010d092d0708280400000a00dc00072a0000000110000002000300171a0010000000001b300200450000000300001100160a7e01000004250b1200280300000a00001680060000041480020000041480110000047e140000046f0500000a0000de100616fe010c082d0707280400000a00dc002a0000000110000002000300303300100000000022002847000006002a2600022848000006002a00133001000c00000004000011000228490000060a2b00062a1b300300770000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a032c060317fe012b0117000c082d0b7237000070730700000a7a021c0428230000060003800800000400de100616fe010c082d0707280400000a00dc002a0001100000020003006265001000000000133001000b00000005000011007e2d0000040a2b00062a00133001000b000000050000110028350000060a2b00062a00133001000b000000050000110028360000060a2b00062a22002837000006002a133001000b00000006000011007e9b0000040a2b00062a00133001000b00000005000011007e9c0000040a2b00062a220028b5000006002a133001000b00000006000011007e700000040a2b00062a22002880000006002a133001000b00000005000011007e560000040a2b00062a00133001000b00000005000011007e570000040a2b00062a00133001000b000000060000110028700000060a2b00062a22002871000006002a22002872000006002a22002873000006002a00001b300300890000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a031f243216031f263011041b320d0420f4010000fe0216fe012b0116000c082d0b7261000070730700000a7a02030528230000060004801000000400de100616fe010c082d0707280400000a00dc002a00000001100000020003007477001000000000133001000b000000050000110028660000060a2b00062a00133001000b00000005000011007e490000040a2b00062a22002868000006002a1b3003005e0000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a021f230428230000060003800d00000400de100616fe010c082d0707280400000a00dc002a00000110000002000300494c001000000000133001000b0000000500001100285e0000060a2b00062a001b300300b30000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a041632090419fe0216fe012b0116000c082d0b729f000070730700000a7a0516321505183011042c0a04192e060516fe012b0117002b0116000c082d0b72cf000070730700000a7a021f210e0428230000060003800d00000404800e00000405800f00000400de100616fe010c082d0707280400000a00dc002a0001100000020003009ea10010000000001b300300860000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a0417320d0420e8030000fe0216fe012b0116000c082d0b7225010070730700000a7a021f220528230000060003801100000404801200000400de100616fe010c082d0707280400000a00dc002a0000011000000200030071740010000000001b3003005e0000000300001100160a7e01000004250b1200280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000c082d0b7201000070730600000a7a021f1c0428230000060003800c00000400de100616fe010c082d0707280400000a00dc002a00000110000002000300494c001000000000133003000e0000000700001100020304285b0000060a2b00062a0000133001000b0000000800001100285c0000060a2b00062a00133004000f000000060000110002030405285d0000060a2b00062a001b300500df0000000900001100160c7e01000004250d1202280300000a000003173218031f283013031b2e0f042c0c046f0800000a1f10fe012b011600130411042d0b7253010070730700000a7a1e8d3a0000010a160b2b1806070407185a186f0900000a1f10280a00000a9c0717580b071efe04130411042dde0616280b00000a8003000004028002000004038005000004031cfe0116fe01130411042d06178008000004166a800400000416800700000414800a0000047e140000046f0500000a007283010070800900000417800600000400de120816fe01130411042d0709280400000a00dc002a000110000002000300c8cb0012000000001b300300a40000000a00001100160b7e01000004250c1201280300000a00007e06000004172e0d7e0600000418fe0116fe012b0116000d092d0b72d1010070730600000a7a032c0c036f0800000a1f0cfe012b0116000d092d0b7209020070730700000a7a160a2b140306186f0900000a1f10280a00000a260618580a061f0cfe040d092de302170428230000060003800b0000041b800500000400de100716fe010d092d0708280400000a00dc002a01100000020003008f9200100000000013300400760000000b000011007e1300000414280c00000a16fe010b072d0b723b020070730d00000a7a7e13000004028c0e0000016f0e00000aa53e000001280f00000a281000000a728b020070728f0200706f1100000a0f00281200000a281300000a281000000a728b020070728f0200706f1100000a281400000a0a2b00062a00001b300700700100000c00001100281500000a14fe0116fe01130411042d0b7291020070730600000a7a00281600000a6f1700000a6f1800000a1305380d0100001205281900000a0a0012007b1a00000a28250000067e0b0000041b281b00000a130411042d0538e200000012007b1a00000a281600000a6f1c00000a281d00000a16fe01130411042d0b72cd020070730600000a7a02282b0000060b281e00000a12007b1a00000a6f1f00000a0c082d1212007b1a00000a13061206282000000a2b06086f2100000a000d09166afe0116fe01130411042d0b72fb020070730600000a7a281500000a0912007b1a00000a7279030070198d010000011307110716078c0a000001a2110717026f2200000a6f2300000a8c45000001a2110718178c46000001a211076f2400000a00729703007012007b2500000a72c7030070282600000a17282700000600de2d1205282700000a130411043ae3feffffde0f1205fe160300001b6f2800000a00dc00726c040070730600000a7a002a411c0000020000002f00000024010000530100000f00000000000000b200028009000004032d031a2b01190080060000047e140000046f0500000a001480020000041480110000042a000000133002007000000004000011000f007b2900000a282a00000a2d5a0f007b2b00000a282a00000a2d4c0f007b2c00000a282a00000a2d3e0f007b2900000a282d00000a2200409c46352b0f007b2b00000a282d00000a2200401c4635180f007b2c00000a282d00000a2200409c46fe0316fe012b0116000a2b00062a133004004f00000004000011000328280000060a062d0b72f5040070730600000a7a0380150000040203026f2200000a6f2300000a176f2e00000a0a062d0b725d050070730600000a7a18800600000472c905007080090000042a001b3005000c0900000d0000110016130e7e0100000425130f120e280300000a00007e06000004172e0a7e0600000418fe012b011700131011102d05ddd608000000027e02000004282f00000a131011102d0b7221060070730600000a7a02283000000a2c10027e3100000a283200000a16fe012b011600131011102d0b72ce060070730600000a7a281600000a283000000a2c13281600000a6f3300000a7e03000004fe012b011600131011102d0b7265070070730600000a7a026f3400000a16fe01131011102d0b72c7070070730600000a7a7e0600000418fe0116fe01131011102d4200026f3500000a131011102d30026f2200000a6f3600000a7e15000004283700000a2200002041320772780800702b0572d80800700017282700000600ddef070000026f3500000a16fe01131011102d0b721a090070730600000a7a7e050000041bfe0116fe01131011102d0d0002282600000600ddb70700007e050000041cfe0116fe01131011102d24007e0800000428480000060002284a000006007e2d00000417282700000600dd820700007e050000041f1bfe0116fe01131011102d190002283a00000600726009007017282700000600dd570700007e050000041f1cfe0116fe01131011102d1e00027e0c00000402282b000006284100000617282700000600dd270700007e050000041f1dfe0116fe01131011102d130002284200000617282700000600dd020700007e050000041f1efe0116fe01131011102d180028370000060072d409007017282700000600ddd80600007e050000041f1ffe0116fe01131011102d130002283800000617282700000600ddb30600007e050000041f20fe0116fe01131011102d1200286100000617282700000600dd8f0600007e050000041f21fe0116fe01131011102d3e00027e0d0000047e0e0000047e0e000004182e0802282b0000062b0b026f2200000a6f3600000a007e0f000004286200000617282700000600dd3f0600007e050000041f28fe0116fe01131011102d13000228b400000617282700000600dd1a0600007e050000041f27fe0116fe01131011102d130002288100000617282700000600ddf50500007e050000041f24320b7e050000041f26fe022b011700131011102d1d00027e050000047e10000004287400000617282700000600ddbc0500007e050000041f23fe0116fe01131011102d1800027e0d000004286700000617282700000600dd920500007e050000041f22fe0116fe01131011102d2b0000027e110000047e1200000428640000061728270000060000de090014801100000400dc00dd550500007e050000041f0a320b7e050000041f13fe022b011700131011102d1b00027e050000041f0a59282e00000617282700000600dd1e0500007e050000041d320b7e050000041f09fe022b011700131011103acf00000000198d390000011311111116720a0a0070a211111772180a0070a211111872260a0070a211117e050000041d599a0a283800000a283000000a131011102d0b72380a0070730600000a7a283800000a066f3900000a0b07283000000a2c0d076f0100002b283000000a2b011600131011102d1172720a007006281400000a730600000a7a0702282b000006026f2200000a6f2300000a280200002b0c08283000000a131011102d0b72c40a0070730600000a7a72080b007006721a0b0070282600000a17282700000600dd310400007e050000041a2e187e050000041f14320b7e050000041f1afe022b0117002b011600131011103a5c01000000283800000a283000000a131011102d0b72380a0070730600000a7a1e8d39000001131111111672a10b0070a211111772bd0b0070a211111872d90b0070a211111972f70b0070a211111a72170c0070a211111b72270c0070a211111c723b0c0070a211111d72490c0070a211110d7e050000041a2e0a7e050000041f13592b01160013040911049a1305283800000a11056f3900000a13061106283000000a2c2111041b300e11066f0300002b283000000a2c0e11066f0100002b283000000a2b011600131011102d12726b0c00701105281400000a730600000a7a026f2200000a6f3600000a130711072828000006131011102d0b72d70c0070730600000a7a11061107283c00000a280200002b0c08283000000a131011102d0b720f0d0070730600000a7a72080b00701105724d0d007011041a2e0c11041b2e07728f0200702b05726b0d007000283d00000a17282700000600ddaa020000283e00000a6f3f00000a13087e0500000417fe0116fe01131011102d360011086f4000000a131011102d0b72a70d0070730600000a7a0211086f4100000a284200000a284300000a282900000600dd570200007e0a00000414fe0116fe01131011102d640011086f4400000a80040000047e1600000414280c00000a2d127e16000004026f0e00000a751a0000012b0114000b07283000000a2c0e7e04000004166afe0116fe012b011600131011102d0b72210e0070730600000a7a076f4500000a800a0000040011086f4400000a7e04000004fe01131011102d0b72890e0070730600000a7a72d70e00708009000004281e00000a7e0a0000047e140000047f070000046f4600000a131011102d05dd95010000141309210000000000000080130a007e140000046f4700000a13122b591212284800000a130b00110b7e4900000a166a6f4a00000a7e04000004fe01131011102d022b32110b7e4b00000a166a6f4a00000a130c11092c0b110c110afe0216fe012b011600131011102d0a00110b1309110c130a00001212284c00000a131011102d9ade0f1212fe160400001b6f2800000a00dc00110914fe0116fe01131011102d1f281600000a6f4d00000a2d0772250f00702b0572e20f007000730600000a7a281e00000a11097b4e00000a6f1f00000a1109282f00000a2c1711097e4900000a166a6f4a00000a7e04000004fe012b011600131011102d0b7244100070730600000a7a7e0500000418fe0116fe01131011102d2f000211096f4f00000a284200000a284300000a285000000a2200000040285100000a284300000a282900000600de4f021109282c0000060072941000701728270000060000de1e130d00727f110070110d6f5200000a281400000a1628270000060000de000000de14110e16fe01131011102d08110f280400000a00dc00002a41640000020000008b0300001b000000a6030000090000000000000002000000900700006a000000fa0700000f0000000000000000000000340000009f080000d30800001e000000520000010200000004000000f1080000f50800001400000000000000133006004c0100000e000011001b8d39000001130611061672a5110070a211061772b5110070a211061872c1110070a211061972d1110070a211061a72eb110070a21106285300000a0a160b38ec000000002200000000071f2d5a6b2200000000285400000a026f2200000a6f5500000a285600000a2200004040285100000a0c026f2200000a6f3600000a08284300000a284200000a2200000040285100000a284300000a285700000a1203220000c0400617285800000a2c181203285900000a7b2b00000a223333333ffe0416fe012b011600130711072d022b5c1203285a00000a284200000a229a99193f285100000a284300000a13041104284200000a22cdcccc3e285100000a284300000a220000003f0617285b00000a2d0c1104282800000616fe012b011700130711072d06110413052b1d000717580b071efe04130711073a07ffffff7207120070730600000a7a11052a133003001d0100000f00001100283800000a037b4e00000a6f5c00000a0a06283000000a2d03142b06066f0400002b000b07283000000a2c0b076f5d00000a16fe012b011700130511052d0b7292120070730600000a7a02282b0000060c03285e00000a6f5f00000a00037e6000000a086f6100000a0003086f6200000a00037e6300000a286400000a6f6100000a00037e6500000a286400000a6f6100000a00037e6600000a286400000a6f6100000a0006283000000a16fe01130511052d6700066f6700000a086f6800000a00066f0500002b0d09283000000a16fe01130511052d220009086f6900000a0009286400000a6f6a00000a0009286400000a6f6b00000a0000066f0600002b13041104283000000a16fe01130511052d0811046f6c00000a00002a000000033003005b00000000000000736d00000a800100000417800800000472f41200708009000004d00e000001286e00000a72fe1200701f246f6f00000a8013000004737000000a8014000004d004000001286e00000a72301300701f346f6f00000a80160000042a001b300600a10300001000001100026f7100000a0a0614fe0116fe01130d110d2d0b7248130070730600000a7a031f09fe0116fe01130d110d2d4200007e17000004130e16130f2b1a110e110f9a0b0607287200000a176f7300000a26110f1758130f110f110e8e69fe04130d110d2dd87296130070130c382e03000003163209031efe0216fe012b011600130d110d2d0b720a140070730700000a7a287400000a283000000a130d110d2d0b7236140070730600000a7a737500000a0c160d2b6e00031e2e060309fe012b011700130d110d2d022b55287400000a7e17000004099a287200000a6f7600000a13041104283000000a16fe01130d110d2d0b0811046f7700000a002b21031efe01130d110d2d1772801400707e17000004099a281400000a730600000a7a000917580d097e170000048e69fe04130d110d2d82086f7800000a16fe0116fe01130d110d2d0b72ec140070730600000a7a022831000006130516130600086f7900000a13102b371210287a00000a13040611046f4500000a287200000a17162200000000156f7b00000a283000000a16fe01130d110d2d061106175813061210287c00000a130d110d2dbcde0f1210fe160600001b6f2800000a00dc001106086f7800000afe01130d110d2d4a1b8d0100000113111111167242150070a211111711068c5e000001a21111187254150070a2111119086f7800000a8c5e000001a211111a7258150070a21111287d00000a730600000a7a737e00000a1307026f2200000a6f3600000a22000020411107287f00000a00738000000a13081613090011076f8100000a131238a90000001212288200000a130a00110a283000000a2c15110a02288300000a2d0b1108110a6f8400000a2b011600130d110d2d022b77110a6f7100000a130b110b14fe0116fe01130d110d2d022b5e00086f7900000a13102b251210287a00000a1304110b11046f4500000a287200000a17162200000000156f7b00000a261210287c00000a130d110d2dcede0f1210fe160600001b6f2800000a00dc00110a283200000600110917581309001212288500000a130d110d3a47ffffffde0f1212fe160900001b6f2800000a00dc001f098d01000001131111111672ac150070a211111711068c5e000001a211111872c2150070a21111191106172e0772dc1500702b0572f415007000a211111a72f8150070a211111b110522000070425b6c17288600000a8c5f000001a211111c7256160070a211111d11098c5e000001a211111e72a2160070a21111287d00000a130c2b00110c2a000000012800000200640148ac010f000000000200a20236d8020f0000000002004902c009030f00000000133003004e000000110000111e8d390000010a0616722d170070a206177243170070a20618725b170070a206197273170070a2061a7285170070a2061b729b170070a2061c72ad170070a2061d72c5170070a20680170000042a00001b300400640100001200001100738700000a0a288800000a738900000a0b00026f8a00000a1308389300000011086f8b00000a0c0012027b1b00000416fe02130911092d022b7812027b1a0000042c03142b0107000d0914fe01130911092d30000912027b1900000412046f8c00000a260912027b19000004110412027b1b000004288d00000a6f8e00000a00002b2e000612027b1a00000412046f8f00000a260612027b1a000004110412027b1b000004288d00000a6f9000000a00000011086f9100000a130911093a5dffffffde14110814fe01130911092d0811086f2800000a00dc0018130500066f9200000a6f9300000a130a2b10120a289400000a130611051106581305120a289500000a130911092de3de0f120afe160f00001b6f2800000a00dc0000076f9600000a6f9700000a130b2b10120b289800000a130611051106581305120b289900000a130911092de3de0f120bfe161100001b6f2800000a00dc00110513072b0011072a0128000002001b00aac50014000000000200eb00210c010f0000000002002a01214b010f000000001b3006004702000013000011007e1800000414280c00000a16fe01130c110c2d0b72df170070730d00000a7a287400000a283000000a130c110c2d0b7219180070730600000a7a287400000a7267180070287200000a6f7600000a75660000010a06283000000a130c110c2d0b7275180070730600000a7a739a00000a0b288800000a739b00000a0c00287400000a7b9c00000a6f9d00000a130d38ef000000120d289e00000a0d0009283000000a2d03142b06096f0700002b0013041104283000000a2d03142b1111047b9f00000a7ba000000a7ba100000a0013051105283000000a130c110c2d0538a00000000011057ba200000a6f9d00000a130e2b6f120e289e00000a1306001106283000000a2d03142b0711066f0800002b0013071107283000000a2c1c11077ba300000a1631120811066f4500000a6fa400000a16fe012b011700130c110c2d210711077ba500000a11077ba600000a11077ba300000a73340000066fa700000a0000120e28a800000a130c110c2d84de0f120efe161500001b6f2800000a00dc0000120d28a800000a130c110c3a01ffffffde0f120dfe161500001b6f2800000a00dc00076fa900000a16fe0116fe01130c110c2d0b72bf180070730600000a7a067baa00000a07283000000617596b067bab00000a5a581308026f7100000a066f4500000a287200000a17162200000000156f7b00000a13091109283000000a130c110c2d0b7207190070730600000a7a7e1800000411096f0e00000aa548000001130a110911097bac00000a110a11085828ad00000a7dac00000a1108130b2b00110b2a004134000002000000f200000080000000720100000f00000000000000020000008f00000006010000950100000f000000000000008200026f7100000a7267180070287200000a17162200000000156f7b00000a262a72d05d000001286e00000a723b1900701f346f6f00000a80180000042a5e0002037d1900000402047d1a00000402057d1b0000042a0000133001000b00000005000011007e270000040a2b00062a00133001000b00000005000011007e280000040a2b00062a220016801d0000042a13300200930000000b000011007e1e000004283000000a2c247e1f00000402282f00000a2c137e20000004281600000a6f3300000afe012b0116002b0117000b072d0b7249190070730600000a7a02801f000004281600000a6f3300000a802000000417801d0000047e1e000004283000000a0b072d1472c519007073af00000a280900002b801e00000472ed19007080280000047e280000040a2b00062a001b300600ca00000014000011007e1d0000042c787e1f000004283000000a2c6c7e1f0000047e3100000a283200000a2d5b7e1f0000046f3400000a2d4f28b100000a2c487e1f0000046f3500000a2d3c28b200000a2d3528b300000a2d2e28b400000a2d2728b500000a2d2028b600000a283000000a2c0c28b600000a6fb700000a2d081828b800000a2b0116000c082d022b41007e1f00000428420000060a00de1b0b0072c81a0070076fb900000a6f5200000a281400000a0a00de00000680280000047e1f00000417061614166fba00000a002a000001100000000088000f97001b52000001133003003401000015000011007e1e000004283000000a2c247e1f00000402282f00000a2c137e20000004281600000a6f3300000afe012b0116002b0117000c082d0b7249190070730600000a7ad043000001286e00000a72da1a00701f346f6f00000a0a0614280c00000a16fe010c082d0b72f61a0070730d00000a7a06281e00000a6f0e00000a75250000010b0714fe0116fe010c082d0b72381b0070730600000a7a076fbb00000a8d090000018021000004076fbc00000a7e21000004166fbd00000a001680220000047e230000046fbe00000a00728f020070802700000402801f000004281600000a6f3300000a802000000417801d0000047e1e000004283000000a0c082d1472c519007073af00000a280900002b801e00000472841b00707e210000048e698c5e00000172981b007028bf00000a80280000042a133003002b000000050000110002252d0626728f0200701f7c1f206fc000000a1f0a1f206fc000000a1f0d1f206fc000000a0a2b00062a0013300300560000001600001100027ec100000a728f0200706fc200000a0a0628c300000a0d092d0906283b0000060c2b2f283800000a026fc400000a6fc500000a0b07283000000a2d0772021c00702b06076f4500000a00283b0000060c2b00082a000013300300310000000400001100022c26281e00000a027b4e00000a6f1f00000a02282f00000a2c0e027ec600000a166fc700000a2b0116000a2b00062a0000001b3002007d00000017000011007e25000004283000000a2c147e2500000428c800000a288300000a16fe012b0117000b072d44007e240000046fc900000a6fca00000a0c2b14120228cb00000a0a7e25000004066fcc00000a00120228cd00000a0b072de1de0f1202fe161900001b6f2800000a00dc007e240000046fce00000a001480250000042a0000000110000002003800235b000f000000001b300800ce020000180000110028c800000a283000000a130911092d0538b70200007e2500000428c800000a283200000a16fe01130911092d17007e240000046fce00000a0028c800000a80250000040073cf00000a0a73d000000a0b007e230000046fd100000a130a3853010000120a28d200000a0c00120228d300000a0d09283d000006130911092d05383101000007120228d400000a6fa400000a26096f4f00000a130409283c00000613057e24000004120228d400000a12066fd500000a130911092d41007e2500000411041972301c00701105281400000a1616166a120bfe1578000001110b6fd600000a13067e24000004120228d400000a11066fd700000a00002b1e00110611047dd800000a110672301c00701105281400000a7dd900000a00061f098d39000001130c110c16120228d400000aa2110c1772401c0070a2110c181105a2110c1972401c0070a2110c1a12047c2900000a72441c007028da00000a28db00000aa2110c1b72401c0070a2110c1c12047c2b00000a72441c007028da00000a28db00000aa2110c1d72401c0070a2110c1e12047c2c00000a72441c007028da00000a28db00000aa2110c28dc00000a6fdd00000a0000120a28de00000a130911093a9dfeffffde0f120afe161b00001b6f2800000a00dc0073cf00000a1307007e240000046fdf00000a6fe000000a130d2b21120d28e100000a13080711086fe200000a130911092d0a110711086fdd00000a00120d28e300000a130911092dd2de0f120dfe161e00001b6f2800000a00dc000011076fe400000a130e2b2f120e28e500000a1308007e250000047e2400000411086fe600000a6fcc00000a007e2400000411086fe700000a2600120e28e800000a130911092dc4de0f120efe161f00001b6f2800000a00dc000628e900000a6fea00000a00724a1c0070066feb00000a28ec00000a8027000004724e1c0070066fed00000a8c5e00000172601c007028bf00000a80280000042a0000414c0000020000005e0000006a010000c80100000f0000000000000002000000f101000032000000230200000f00000000000000020000003d020000400000007d0200000f00000000000000133004001302000019000011007e1d0000042c3c7e1f000004283000000a2c307e1f0000047e3100000a283200000a2d1f281600000a283000000a2c13281600000a6f3300000a7e20000004fe012b0116000d092d4e00283e000006007e230000046fbe00000a00148021000004728f020070802700000416801d0000047e1e000004283000000a16fe010d092d107e1e0000046fee00000a28ef00000a00387a0100007e2100000414fe010d093a38010000007e210000048e697e2200000420000400005828f000000a0a2b7d007e210000047e2200000425175880220000049a0b07283d0000060d092d022b5c283800000a076fc400000a6fc500000a0c08283000000a2c1d086f0a00002b283000000a2c10086f0b00002b283000000a16fe012b0116000d092d022b1e7e23000004077c4e00000afe160e0000016ff100000a076ff200000a00007e2200000406fe040d093a74ffffff1d8d01000001130411041672351d0070a21104177e220000048c5e000001a21104187254150070a21104197e210000048e698c5e000001a211041a72751d0070a211041b7e230000046ff300000a8c5e000001a211041c727b1d0070a21104287d00000a80280000047e220000047e210000048e69fe0116fe010d092d12001480210000042200000000802600000400007e210000042d0e28f400000a7e26000004fe052b0117000d092d1800283f0000060028f400000a220000803f588026000004002a0013300300a20200001a00001100027e1f000004282f00000a2c1f281600000a283000000a2c137e20000004281600000a6f3300000afe012b011600130a110a2d0b72ab1d0070730600000a7a032c177e230000040312006ff500000a2c0806283d0000062b011600130a110a2d0b72f51d0070730600000a7a283800000a067b4e00000a6f5c00000a0b07283000000a2d03142b06076f0a00002b000c08283000000a2c0b086f3400000a16fe012b011700130a110a2d0b72821e0070730600000a7a07283000000a2d03142b06076f0100002b000d09283000000a16fe01130a110a2d2e00096ff600000a130a110a2d07096ff700000a00096ff600000a130a110a2d0b72b41e0070730600000a7a002b0c06285e00000a6f5f00000a0006283c0000061304067e6000000a046f6100000a0006046f6200000a00067e6300000a286400000a6f6100000a00067e6500000a286400000a6f6100000a00067e6600000a286400000a6f6100000a0007283000000a16fe01130a110a3afa00000000076f6700000a046f6800000a00076f0500002b13051105283000000a16fe01130a110a2d25001105046f6900000a001105286400000a6f6a00000a001105286400000a6f6b00000a0000076f0c00002b13061106283000000a16fe01130a110a2d7600d080000001286e00000a72181f00701f346f6f00000a130711071428f800000a2c1b11076ff900000ad00a000001286e00000a28fa00000a16fe012b011700130a110a2d1011071106048c0a0000016ffb00000a00d080000001286e00000a72321f00701f3428fc00000a1106146ffd00000a2600076f0600002b13081108283000000a16fe01130a110a2d0811086f6c00000a0000281e00000a067b4e00000a6ffe00000a002200000000802600000472541f0070110472621f0070282600000a13092b0011092a000013300500ee0100001b00001100026fff00000a0a06283000000a130711073aa000000000026f0001000a0b22000020410c000702076f0101000a22000020411517280201000a13081613092b67110811098f5500000171550000010d001203280301000a283000000a2c231203280301000a6f0d00002b02288300000a2d0f1203280501000a08fe0216fe012b011600130711072d022b161203280501000a0c1203280301000a6f0d00002b0a00110917581309110911088e69fe04130711072d8b0006283000000a2c380602288300000a2d2f066f3400000a2d27066f2200000a6f3600000a026f2200000a6f3600000a280601000a2200002041fe0216fe012b011600130711072d0b7237200070730600000a7a066f0e00002b1304066f0f00002b13051104283000000a2c1f066f1000002b283000000a2c121105283000000a2c0911056f0801000a2b011600130711072d0b72ce200070730600000a7a11046f0901000a16fe01130711072d09722621007013062b7d11056ff600000a130711072d0811056ff700000a0011056ff600000a130711072d0b7266210070730600000a7ad083000001286e00000a72ce2100701f3428fc00000a1104146ffd00000a2611046f0901000a130711072d0b72d8210070730600000a7a7258220070066f0a01000a7266220070282600000a13062b0011062aa6730b01000a8023000004730c01000a8024000004728f020070802700000472d622007080280000042a1b3002002f0000001c000011000028400000060028390000060000de1c0a00725b23007006280d01000a280e01000a0028370000060000de00002a0001100000000001001011001c52000001133002001a00000004000011007e1e00000402288300000a16fe010a062d0614801e0000042a1e02280f01000a2a52001680290000047e2b0000041758802b0000042a0013300200250000000400001100022c060217fe012b0117000a062d0b7279230070730700000a7a0217fe01802a0000042a000000133002002f00000004000011007e290000042c207e2a0000042c197e2c000004283000000a2c0d7e2c000004026f4f0000062b0116000a2b00062a00133003009a0000001d000011007e2900000416fe010b072d130028470000060072b1230070802d0000042b797e2c000004283000000a16fe010b072d0d007203240070802d0000042b5b728c24007073af00000a281100002b0a06802c00000406027d2e00000406281600000a6f3300000a7d2f00000406281600000a7d35000004067e2b000004175825802b0000047d3000000417802900000472ba240070802d0000042a4617802a0000047273250070802d0000042a13300200830000000400001100027b2e000004283000000a2c6e027b2e0000047e3100000a288300000a2c5c027b2e0000046f3400000a2d4f027b2e0000046f3500000a2d4228b100000a2c3b28b200000a2d3428b300000a2d2d28b400000a2d2628b500000a2d1f28b600000a283000000a2c0f28b600000a6fb700000a16fe012b0117002b0116000a2b00062a0003300300500000000000000000027b360000042032010000281001000a7e290000042c2f02284c0000062c27027b31000004283000000a2c1a027b33000004283000000a2c0d027b330000046ff600000a2b0116006f55000006002a13300400a90000001e00001100027b31000004283000000a2c0b027b3c00000414fe012b0117000b072d4a160a2b38d014000001286e00000a7e3b000004069a7e3a0000046f6f00000a027b31000004027b3c00000406988c480000016ffb00000a000617580a067e3b0000048e69fe040b072dba02147d3100000402147d3200000402147d3300000402147d3400000402147d3c000004027b360000046f5700000600020216250c7d38000004087d370000042a00000013300200c60000000400001100027b2e000004283000000a39ae000000027b2e0000047e3100000a288300000a3999000000027b2e0000046f1101000a3989000000027b2e0000046f3400000a2d7c027b2e0000046f3500000a2d6f027b35000004283000000a2c62027b35000004281600000a288300000a2c50027b350000046f3300000a027b2f000004333d03283000000a2c3503027b34000004288300000a2c27027b33000004283000000a2c1a027b330000046f0801000a2c0d027b330000046ff600000a2b0116000a2b00062a000013300500640100001f000011007e3b0000048e698d070000010a7e3b0000048e698d480000010b160c2b7b000608d014000001286e00000a7e3b000004089a7e3a0000046f6f00000aa206089a14280c00000a2d1c06089a6ff900000ad048000001286e00000a281201000a16fe012b011600130411042d1772932500707e3b000004089a281400000a730d00000a7a070806089a036f0e00000aa548000001a0000817580c087e3b0000048e69fe04130411043a72ffffff036f1200002b0d09283000000a130411042d0b72c1250070730600000a7a02036f1300002b7d3200000402036f0f00002b7d33000004027b32000004283000000a2c1a027b33000004283000000a2c0d027b330000046f0801000a2b011600130411042d0b720f260070730600000a7a02037d3100000402077d3c00000402097d34000004160c2b1d06089a027b3100000422000000008c480000016ffb00000a000817580c087e3b0000048e69fe04130411042dd32a1b3007001d0700002000001100007e290000043985000000027b300000047e2b0000043378027b2e000004283000000a2c6b027b2e0000047e3100000a283200000a2d59027b2e0000046f1101000a2c4c027b2e0000046f3400000a2d3f027b2e0000046f3500000a2d32027b35000004281600000a283200000a2d20281600000a283000000a2c14281600000a6f3300000a027b2f000004fe012b011600131211122d4100027b300000047e2b000004fe0116fe01131211122d12002847000006007273250070802d0000040002284e000006000228ee00000a28ef00000a00dd41060000027b2e0000046f1301000a0a06283000000a131211122d06281401000a0a06283000000a2c08066f1501000a2b011700131211122d170002284e00000600725d260070802d000004ddf405000006027b31000004283200000a16fe01131211122d200002284e0000060006283000000a16fe01131211122d08020628500000060000027b31000004283000000a131211122d100072e0260070802d000004dd9e050000027b330000046ff600000a131211122d1c00027b360000046f5700000600725d260070802d000004dd71050000d014000001286e00000a7e3b0000041c9a7e3a0000046f6f00000a027b310000047e2a0000042d0a027b3c0000041c982b052200000000008c480000016ffb00000a00d014000001286e00000a7e3b0000041d9a7e3a0000046f6f00000a027b310000047e2a0000042d0a027b3c0000041d982b052200000000008c480000016ffb00000a0002284c0000062c1b027b2e0000046f1301000a027b31000004283200000a16fe012b011600131211122d3500027b360000046f570000060072302700707e2a0000042d0772922700702b0572b627007000281400000a802d000004dd8b040000281601000a0b027b310000046f1701000a8c880000016ff100000a0c0872dc270070281801000a2d460872e6270070281801000a2d310872f0270070281801000a2d1c0872fa270070281801000a2d0722000000002b05220000803f002b05226666263f002b05223333b33e002b05223333b3be000d2030010000281001000a2d13202f010000281001000a2d07220000c8412b052200002042001304027b310000046f2200000a6f5500000a284200000a281901000a13131213281a01000a1305027b320000046f1b01000a1306027b320000046f1c01000a027c39000004281d01000a1307027b370000042c1012067b2b00000a2200000000fe032b011700131211122d0702177d38000004027b370000042c30027b380000042c28027b320000046f1c01000a7b2b00000a1107027b310000047b1e01000a58220000003f58fe032b011700131211122d120202162513147d3800000411147d3700000412067b2900000a220000000012067b2c00000a731f01000a110509285100000a1104285100000a2200004041075a282001000a1308027b3200000412087b2900000a12067b2b00000a12087b2c00000a731f01000a6f6a00000a001f64281001000a2d0722000000002b05220000803f001f61281001000a2d0722000000002b05220000803f00591309110922000082425a075a284200000a282101000a1105285600000a130a027b32000004027b320000046f2201000a110a284200000a282301000a220000c842075a282401000a6f2501000a00027b320000046f2601000a284200000a2200008040285100000a284300000a285700000a120b2200002041178d39000001131511151672a5110070a21115285300000a17285800000a16fe01131211123a2001000000027b310000047b2701000a130c110c283000000a2d07220000c03f2b26027b320000046f2601000a7b2b00000a110c6f2801000a13161216282901000a7b2b00000a5900130d120b285a00000a7b2b00000a110d58229a99193f58027b320000046f2601000a7b2b00000a59130e120b285a00000a7b2b00000a11072859000006130f110f2c31027b370000042c29027b380000042c21110e22cdcc4cbe361812067b2b00000a282a01000a2200000040fe0416fe012b011700131211122d120202162513147d3800000411147d37000004027b37000004120b285a00000a7b2b00000a1107110e12067b2b00000a285a000006131011102200000000fe01131211122d19027b32000004284200000a1110285100000a1b6f2b01000a0000027b360000046f5600000616fe01131211122d3700027b320000046f1b01000a13061206220000b0417d2b00000a027b3200000411066f6a00000a0002177d3700000402167d38000004001c8d0100000113171117167204280070a211171708a21117187228280070a211171911048c48000001a211171a7230280070a211171b7e2a0000042d0772922700702b0572b627007000a21117287d00000a802d00000400de3a131100284700000600729428007011116fb900000a6f5200000a281400000a802d00000402284e000006000228ee00000a28ef00000a0000de0000002a000000411c00000000000001000000df060000e00600003a000000520000011330020021000000040000110002284e000006007e2c00000402288300000a16fe010a062d0614802c0000042a0000001330030055000000110000111f34803a0000041e8d390000010a061672be280070a2061772e2280070a206187204290070a206197226290070a2061a7240290070a2061b726c290070a2061c728c290070a2061d72b4290070a206803b0000042a4e0273580000067d3600000402280f01000a002a00000013300300440000000400001100040a062d0902167d3e0000042b2d032c16027b3d0000042d0e027b3e0000041efe0416fe012b0117000a062d0e02257b3e00000417587d3e00000402037d3d0000042a13300300290000002100001100027b3e00000416fe0116fe010b072d04160a2b1202257b3e00000417597d3e000004170a2b00062a260002167d3e0000042a1e02286d00000a2a001330030024000000040000110002282a00000a2d1403282a00000a2d0c0203220000803e58fe022b0116000a2b00062a13300500540000002200001100022d13030428590000062c0a0522000000bffe032b0116000b072d0822000000000a2b2d22000070c1220000a0410522000090415a0e0422000008415a5922c3f51c4158282c01000a28ad00000a0a2b00062a1330040080000000230000110014803f0000047e3100000a0a06283000000a2c1903066f2e01000a331002032e0c042c0903046f2f01000a2b011600130411042d04140d2b44046f3001000a0b07167d3101000a071616733201000a7d3301000a72d4290070141717733401000a0c08076f3501000a130411042d04140d2b0a07803f000004080d2b00092a133001001300000024000011007e3f0000040a14803f000004060b2b00072a001b3004005201000025000011007e3100000a0a06283000000a2c1b0206283200000a2d12032c0b03066f2e01000afe012b0117002b011600130611062d081513053814010000042c21066f2e01000a046f2f01000a2c13047ba000000a7b3601000a2d060516fe022b011600130611062d0815130538e000000000046f3001000a0b07167d3101000a0705047b3701000a28f000000a066f2200000a6f3600000a066f2200000a6f5500000a284300000a284200000a284300000a066f2200000a6f2300000a283801000a0c08283000000a130611062d05161305de7d086f3901000a00086f1300002b0d09283000000a16fe01130611062d3c09066f2200000a6f5500000a284200000a284300000a04156f3a01000a22000048433207220000003f2b05220000a04000285100000a6f6a00000a00171305de1f13040072fa29007011046f5200000a281400000a280e01000a00161305de000011052a00000110000000006e00c12f011f52000001133001000b00000005000011007e410000040a2b00062a00133002002f000000040000110002720a0a0070281801000a2d1a0272180a0070281801000a2d0d0272260a0070281801000a2b0117000a2b00062a001b300300020100002600001100026f0700002b0a06283000000a2c1b067b9f00000a2c13067b9f00000a7ba000000a14fe0116fe012b011600130511052d0d026f4500000a130438be000000067b9f00000a7ba000000a7b3b01000a0b0728c300000a16fe01130511052d0d026f4500000a1304389100000000283c01000a0c082c0908076f3d01000a2b0107000d0928c300000a2d1d09722a2a00706f3e01000a2d1009722e2a00706f3e01000a16fe012b011600130511052d0a026f4500000a1304de44091f7c1f206fc000000a1f0d1f206fc000000a1f0a1f206fc000000a6f3f01000a0d096f0800000a2c03092b06026f4500000a001304de0c2600026f4500000a1304de000011042a00000110000000006d0085f2000c010000011e02286d00000a2a133004004e0000002700001100027be10000040312006f4001000a26027be10000040412016f4001000a2628e900000a06252d02260307252d0226046f4101000a0c082d0e28e900000a03046f4101000a2b0108000d2b00092a00007c000d000a0000001b3006004a0400002800001114130c73e2000006130d00283800000a283000000a130f110f2d0b72322a0070730600000a7ad04d000001286e00000a72602a00701f346f6f00000a0a0614280c00000a2d1206283800000a6f0e00000a75250000012b0114000b0714fe0116fe01130f110f2d0b727e2a0070730600000a7a1a8d1300001b131011101673d000000aa211101773d000000aa211101873d000000aa211101973d000000aa211100c110d734201000a7de100000400076fbc00000a6f4301000a1311389e01000011116f4401000a741a0000010d0009283000000a2c0d096f0100002b283000000a2b011600130f110f2d05386e010000096f4500000a1304110428c300000a2d1d1104198d9200000125d0e2000004284601000a6f4701000a16fe042b011600130f110f2d0538330100001104285f00000616fe01130f110f2d110008179a11046fa400000a263812010000096f0a00002b13051105283000000a16fe01130f110f2d4900096f0b00002b283000000a16fe01130f110f2d0538e000000008169a11046fa400000a26096f1400002b283000000a16fe01130f110f2d0b08199a11046fa400000a2638b1000000096f0300002b283000000a2d3c096f1500002b283000000a2d2f096f1600002b283000000a2d22096f1700002b283000000a2d15110472d62a00701b6f4801000a16fe0416fe012b0117001306096f0700002b13071107283000000a2c1a11077b9f00000a2c1111077b9f00000a7ba000000a14fe012b011700130f110f2d1a00171306110d7be100000411040928600000066f4901000a0000110616fe01130f110f2d0b08189a11046fa400000a260011116f9100000a130f110f3a52feffffde1d111175470000011312111214fe01130f110f2d0811126f2800000a00dc0073cf00000a130816130938ce000000000811099a734a01000a130a110a110c2d11110dfe06e3000006734b01000a130c2b00110c6f4c01000a0000110a6fe400000a13132b71121328e500000a13040011081a8d01000001131411141611098c5e000001a211141772401c0070a21114181104a2111419110d7be10000041104120b6f4001000a2c0b110b1104284d01000a2d07728f0200702b0c72401c0070110b281400000a00a21114287d00000a6fdd00000a0000121328e800000a130f110f2d82de0f1213fe161f00001b6f2800000a00dc00001109175813091109088e69fe04130f110f3a22ffffff11086fed00000a16fe0116fe01130f110f2d0b72e02a0070730600000a7a724a1c007011086feb00000a28ec00000a8041000004088040000004110d7be100000480420000041f098d01000001131411141672d72b0070a211141708169a6f4e01000a8c5e000001a211141872e72b0070a211141908179a6f4e01000a8c5e000001a211141a72012c0070a211141b08189a6f4e01000a8c5e000001a211141c721b2c0070a211141d08199a6f4e01000a8c5e000001a211141e72472c0070a21114287d00000a130e2b00110e2a00004134000002000000bc000000b5010000710200001d0000000000000002000000d302000082000000550300000f0000000000000013300500d701000029000011000e041632170e04183012042c0b04192e070e0416fe012b0117002b011600130511052d0b72cf000070730600000a7a0416321604193012032c0f7e40000004049a036fe200000a2b011600130511052d0b727f2c0070730600000a7a283800000a036f3900000a0a06283000000a2c0d066f0100002b283000000a2b011600130511052d0b721e2d0070730600000a7a042c0404193321066f0a00002b283000000a2c10066f0b00002b283000000a16fe012b0116002b011700130511052d0b726e2d0070730600000a7a0419330d066f1400002b283000000a2b011700130511052d0b72c02d0070730600000a7a0605026f2200000a6f2300000a280200002b0b07283000000a130511052d0b72262e0070730600000a7a042c090419fe0116fe012b011600130511052d10076f0a00002b0e0417586f4f01000a007e420000040312026f4001000a2c090803284d01000a2d03032b110872782e007003727e2e0070283d00000a000d1b8d39000001130611061672080b0070a211061709a2110618042c0b04192e07728f0200702b1672822e00700e048c5e00000172882e007028bf00000a00a211061972f4150070a211061a04192e07728f0200702b0572982e007000a2110628dc00000a13042b0011042a0013300300420000002a0000111a8d1300001b0a061673d000000aa2061773d000000aa2061873d000000aa2061973d000000aa2068040000004728f0200708041000004734201000a80420000042a00001b300600030200002b000011000417320d0420e8030000fe0216fe012b011600130511052d0b7225010070730700000a7a032c16037ba000000a2c0e026f2e01000a036f2f01000a2b011600130511052d0b72252f0070730600000a7a036f5001000a2d10037ba000000a7b5101000a17fe022b011700130511052d0b72a52f0070730600000a7a037b5201000a04fe0116fe01130511052d1c72ff2f0070048c5e00000172f415007028bf00000a13043856010000037b5201000a0a037b5301000a0b036f5401000a0c0003047d5201000a036f5401000a0d09282a00000a2d1509285501000a2d0d092200000000fe0416fe012b011600130511052d0b7243300070730600000a7a03082200000000300722000000002b19092200000000220000803f07085b282c01000a28ad00000a5a007d5301000ad00c000001286e00000a72973000701f3428fc00000a026f2e01000a188d010000011306110616168c46000001a2110617168c46000001a211066ffd00000a26d00d000001286e00000a72a73000701f3428fc00000a02146ffd00000a2600de12260003067d5201000a03077d5301000afe1a001d8d01000001130611061672e1300070a2110617068c5e000001a21106187229310070a2110619048c5e000001a211061a7233310070a211061b037ba000000a7b5101000a8c5e000001a211061c72f4150070a21106287d00000a13042b0011042a00011000000000bf00cf8e011201000001133003002b0000000800001100d00d000001286e00000a729f3100707e4400000428fc00000a02146ffd00000a74060000010a2b00062a001b300200ca0000002c00001100283800000a72b93100706f3900000a6f0700002b0a73cf00000a0b00067b9f00000a7ba000000a7ba100000a7ba200000a6f9d00000a13042b4f1204289e00000a0c08283000000a2c2a086f1500002b283000000a2c1d086f0800002b283000000a2c10086f0800002b7b5601000a16fe012b011700130511052d0d07086f4500000a6fdd00000a00120428a800000a130511052da4de0f1204fe161500001b6f2800000a00dc0007288800000a6fea00000a00724a1c0070076feb00000a28ec00000a0d2b00092a000001100000020039006099000f000000001b300200900100002d000011002868000006000328c300000a16fe01130611062d0c7e490000041305386b0100000228650000060a062c1a067ba000000a7b3b01000a72cf310070284d01000a16fe012b011600130611062d0b72f1310070730600000a7a140b00067ba000000a7ba100000a7ba200000a6f9d00000a13072b451207289e00000a0c08283000000a2c2b086f4500000a03281801000a2c1d086f1500002b283000000a2c10086f0800002b7b5601000a16fe012b011700130611062d02080b120728a800000a130611062daede0f1207fe161500001b6f2800000a00dc0007283000000a130611062d0b722b320070730600000a7a026f2200000a6f3600000a0d09285701000a13041104283000000a2c0a1104096f5801000a2b011600130611062d0b7261320070730600000a7a72a532007073af00000a281800002b80480000047e48000004027d4b0000047e48000004077d4c0000047e48000004097d4d0000047e48000004281600000a6f3300000a7d4e0000047e480000046f6c0000060072d532007025804900000413052b0011052a011000000200730056c9000f00000000133002003000000004000011007e48000004283000000a16fe010a062d13007e48000004177d4a00000414804800000400728a33007080490000042a133005002b0000002e000011007e4700000402188d010000010b071603a20717168c9b000001a2076ffd00000aa5460000010a2b00062a0013300500840000002f000011007e45000004021b8d010000010a061603a20617048c0a000001a20618283c00000a8c45000001a20619168c46000001a2061a168c46000001a2066ffd00000a26026f5901000a0b072d387e46000004021a8d010000010a0616037b5a01000aa20617168c5e000001a20618158c5e000001a20619178c5e000001a2066ffd00000a262a1330070090000000300000111f348044000004d004000001286e00000a72b63300707e4400000428fc00000a8045000004d004000001286e00000a72cc3300707e4400000428fc00000a8046000004d004000001286e00000a72ee3300707e4400000414188d580000010a0616d01c000001286e00000aa20617d09b000001286e00000aa20614285b01000a804700000472f412007080490000042a9200027b4f000004285c01000a6f5d01000a00027b50000004285c01000a6f5e01000a262a0000001b30060078050000310000110000027b4a00000416fe01130f110f2d12000228ee00000a28ef00000a00dd53050000027b4b000004283000000a2c71027b4b0000047e3100000a283200000a2d5f027b4b0000046f3400000a2d52027b4b0000046f3500000a2d45281600000a283000000a2c39281600000a6f3300000a027b4e0000043327027b4b0000046f2200000a6f3600000a027b4d000004280601000a220000c841fe0216fe012b011600130f110f2d1200027210340070286e00000600ddbb040000027b4b00000428650000060a062c1a067ba000000a7b3b01000a72cf310070284d01000a16fe012b011600130f110f2d1200027258340070286e00000600dd7804000028f400000a027b54000004fe0416fe01130f110f2d05dd5d0400000228f400000a22cdcc4c3d587d54000004027b4c0000046f1500002b0b027b4c0000046f0800002b0c220000c03f077b5f01000a22000000405a220000803e5828ad00000a0d16130438a403000000027b4f0000046f6001000a130502257b5300000417587d53000004027b4d0000041205286101000a6b22000000001205286201000a6b731f01000a284300000a13061205286301000a2090010000fe0216fe01130f110f2d05383f0300001106285701000a13071107283000000a2c16110711066f5801000a2c0b11061208286401000a2b011600130f110f2d05380a030000120611087d2b00000a001a8d1e00000113101110168f1e000001286501000a811e0000011110178f1e000001286601000a811e0000011110188f1e000001286701000a811e0000011110198f1e000001286801000a811e000001111013111613122b59111111128f1e000001711e00000113090011051109286901000a130a120a286301000a20900100003012027b50000004110a6f5e01000a16fe012b011700130f110f2d0e027b4f000004110a6f5d01000a0000111217581312111211118e69fe04130f110f2d99077b6a01000a11071106220ad7a33c166f6b01000a5f16fe0116fe01130f110f2d05381902000016130b00027b510000046f6c01000a13132b241213286d01000a130c110c1106283700000a09fe0416fe01130f110f2d060017130b2b0d1213286e01000a130f110f2dcfde0f1213fe162500001b6f2800000a00dc00110b16fe01130f110f2d0538b3010000001106284200000a220000003f285100000a284300000a09286f01000a1314161312388a000000111411129a130d00110d6f7001000a2d1f110d6f1900002b283000000a2d11110d6f1a00002b283000000a16fe012b011600130f110f2d022b4a110d6f1b00002b283000000a2d2d110d6f1c00002b283000000a2d1f110d6f1d00002b283000000a2d11110d6f1e00002b283000000a16fe012b011600130f110f2d060017130b2b1800111217581312111211148e69fe04130f110f3a65ffffff110b2d4f1106284200000a22cdcc4c3e285100000a284300000a284200000a220000c842178d39000001131511151672b5110070a21115285300000a287101000a2d10110622000000001616287201000a2b011600130f110f2d053891000000027b4b000004082869000006130f110f2d1200027286340070286e00000600ddde000000027b4b000004081106286a00000600027b5100000411066f7301000a0002257b5200000417587d5200000472fa340070027b520000048c5e000001720c35007028bf00000a8049000004027b520000042000010000fe04130f110f2d0f0002724c350070286e00000600de720011041758130411041f102f10027b4f0000046f7401000a16fe022b011600130f110f3a3bfcffff027b4f0000046f7401000a16fe0116fe01130f110f2d0c02727e350070286e0000060000de23130e000272ee350070110e6fb900000a6f5200000a281400000a286e0000060000de0000002a4134000002000000fd02000035000000320300000f00000000000000000000000100000051050000520500002300000052000001133003004200000032000011001a8d010000010a061603a206177202360070a20618027b520000048c5e000001a2061972f4150070a206287d00000a80490000040228ee00000a28ef00000a002aa602737501000a7d4f00000402737601000a7d5000000402737701000a7d5100000402280f01000a002a133003003900000006000011007e5500000414288300000a2d247e55000004fe137b5b0000042d03162b0117007e55000004fe137b5c0000041762602b0116000a2b00062a000000133002003d00000004000011007e5500000414283200000a16fe010a062d15007e5500000417fe137d5a0000041480550000040072163600708056000004724436007080570000042a000000133002002b00000004000011007e5500000414283200000a16fe010a062d0d7e5500000416fe137d5b000004721636007080560000042a00133002002b00000004000011007e5500000414283200000a16fe010a062d0d7e5500000416fe137d5c000004724436007080570000042a0013300400af0100003300001100041b320d0420f4010000fe0216fe012b0116000c082d0b7270360070730700000a7a7e55000004283000000a2c2a7e550000047b5800000402283200000a2d187e550000047b59000004281600000a6f3300000afe012b0116000c082d460028710000060072bc36007073af00000a281f00002b80550000047e55000004027d580000047e55000004281600000a6f3300000a7d590000047e550000046f760000060000031f24fe0116fe010c082d43007e550000047e55000004fe137b5b00000416fe01fe137d5b0000047e55000004fe137b5b0000042d0772163600702b0572e4360070002580560000040b38b9000000031f252e0a031f26fe0116fe012b0116000c083a9600000000031f24590a7e550000047e55000004fe137b5c000004062e03062b011600fe137d5c0000047e55000004046b7d5d0000047e55000004fe137b5c0000042c471a8d010000010d09167e55000004fe137b5c000004172e07729d3700702b0572bd37007000a2091772e5370070a20918048c5e000001a209197205380070a209287d00000a2b057244360070002580570000040b2b0b7233380070730700000a7a072a5672163600708056000004724436007080570000042a0000001b300200300100003400001100283800000a72b93100706f3900000a6f0700002b0a00067b9f00000a7ba000000a7ba100000a7ba200000a6f9d00000a1305388a0000001205289e00000a0b0007283000000a2d03142b06076f1500002b000c08283000000a130611062d022b6000087b7801000a13071613082b43110711089a0d09283000000a2c10096f0300002b283000000a16fe012b011700130611062d17027b60000004096f4500000a287200000a6f7901000a26110817581308110811078e69fe04130611062daf00120528a800000a130611063a66ffffffde0f1205fe161500001b6f2800000a00dc0000287700000613091613082b30110911089a13041104283000000a16fe01130611062d13027b6100000411046f7a01000a6f7901000a26110817581308110811098e69fe04130611062dc22a0110000002003300a1d4000f00000000133002002900000035000011007e5f000004146f0e00000a752700001b0a062c08066f7b01000a2b06168d05000001000b2b00072a0000001b300600f904000036000011000002fe137b5a00000416fe01130e110e2d12000228ee00000a28ef00000a00ddd2040000027b58000004283000000a2c4c027b580000047e3100000a283200000a2d3a027b580000046f3400000a2d2d027b580000046f3500000a2d20281600000a283000000a2c14281600000a6f3300000a027b59000004fe012b011600130e110e2d18002871000006000228ee00000a28ef00000a00dd5904000002fe137b5b000004130e110e2d1a00027b630000046f7c01000a00027b620000046f7d01000a000002fe137b5b0000042d1002fe137b5c00000416fe0116fe012b011700130e110e2d05dd0a04000028f400000a027b65000004fe05130e110e2d3d000228f400000a220000003f587d650000040228770000067d6900000402fe137b5b00000416fe01130e110e2d070228790000060002287a00000600001f40027b690000048e6928f000000a0a160b38b402000000027b69000004027b680000040758027b690000048e695d9a0c08283000000a130e110e2d053885020000086f0f00002b0d09283000000a2c08096f0801000a2b011600130e110e2d053861020000086f7e01000a00087b9f00000a1304110414fe0116fe01130e110e2d05383f020000027b580000046f2e01000a110411047b3701000a6f7f01000a1305027b62000004086f8001000a1306086f2200000a6f3600000a027b580000046f2200000a6f3600000a288101000a130f120f288201000a130711062d2602fe137b5c00000411047b8301000a086f8401000a11051107027b5d000004287f0000062b011700130e110e2d0538b4010000086f8401000a2d2511052c21086f8501000a2d19086f2200000a6f3600000a22000000001616287201000a2b011600130e110e2d05387a010000096ff600000a130e110e2d5700086f7a01000a1309027b64000004110912086f8601000a2c1428f400000a1108592200000040fe0216fe012b011600130e110e2d1c00086f8701000a00027b64000004110928f400000a6f8801000a00003817010000027b580000046f2200000a6f3600000a284200000a22cdcc4c3f285100000a284300000a130a086f2200000a6f3600000a110a220000f042288901000a5a282001000a130b086f1300002b130c110c283000000a16fe01130e110e2d1900110c286400000a6f6a00000a00110c110b6f6900000a0000086f2200000a110b6f6800000a00096f8a01000a110b6f6200000a00110b110a288101000a130f120f288201000a2200000040340c08166f8b01000a16fe012b011700130e110e2d5700027b58000004086fee00000a16166f8c01000a16fe01130e110e2d1d0002257b6700000417587d67000004027b62000004086f8d01000a260008283000000a16fe01130e110e2d0d7e5e00000408146ffd00000a2600000717580b0706fe04130e110e3a3ffdffff027b690000048e6916fe0216fe01130e110e2d1702027b680000040658027b690000048e695d7d6800000402fe137b5c00000416fe01130e110e2d691c8d01000001131011101602fe137b5c000004172e07729d3700702b0572bd37007000a2111017725d380070a2111018027b5d0000048c48000001a21110197263380070a211101a027b670000048c5e000001a211101b727f380070a21110287d00000a805700000400de39130d0028710000060072ee350070110d6fb900000a6f5200000a281400000a25805600000480570000040228ee00000a28ef00000a0000de0000002a000000411c00000000000001000000bc040000bd0400003900000052000001133004002a0200003700001100160a0016282000002b130816130938e5010000110811099a0b00061f10fe04130a110a2d0538df01000007283000000a2c10077b8f01000a2c08076f9001000a2b011600130a110a2d0538a3010000076f0f00002b0c08283000000a2c20086f0801000a2c18027b60000004086f8a01000a6fc400000a6f9101000a2b011600130a110a2d053867010000076f2200000a6f3600000a0d09027b580000046f2200000a6f3600000a288101000a130b120b288201000a220000c843300f0922000000001616287201000a2b011600130a110a2d05381901000009285701000a13041104283000000a2c3b1104096f5801000a2c31077b9201000a283000000a2c24027b580000046f2e01000a077b9201000a17077b9301000a288d00000a6f9401000a2b011600130a110a2d0538c0000000076f7a01000a1305027b64000004110512066f8601000a2c1428f400000a110659220000a040fe0416fe012b011700130a110a2d053886000000027b64000004110528f400000a6f8801000a00027b630000041207fe15130000021207097d6c0000041207077b9201000a6f0700002b7b9f00000a7ba000000a7b3b01000a7d6d000004120728f400000a2200002041587d6e00000411076f9501000a0007027b5800000416166f9601000a260617580a02257b6600000417587d6600000400110917581309110911088e69fe04130a110a3a0afeffff720a390070027b660000048c5e000001724239007028bf00000a80560000042a000013300200130000000400001128f400000a0f007b6e000004fe020a2b00062a00133002000e0000000400001102283000000a16fe010a2b00062a00001b300300c901000038000011000228770000067d69000004027b630000047e6a0000042d1314fe067c000006739701000a806a0000042b007e6a0000046f9801000a26027b620000047e6b0000042d1314fe067d000006739901000a806b0000042b007e6b0000046f9a01000a2600027b690000040c160d38de00000008099a0a0006283000000a2c29027b61000004066f7a01000a6f7901000a2c16066f8401000a2d0e067b9f00000a14fe0116fe012b011600130411042d05389700000000027b630000046f9b01000a13052b671205289c01000a0b067b9f00000a7ba000000a7b3b01000a12017b6d000004281801000a2c29066f2200000a6f3600000a12017b6c000004288101000a13061206288201000a2200001042fe032b011700130411042d1000027b62000004066f9d01000a002b0d1205289e01000a130411042d8cde0f1205fe162c00001b6f2800000a00dc00000917580d09088e69fe04130411043a13ffffff027b610000046f9f01000a2050c30000fe0216fe01130411042d4f00027b610000046fa001000a0000027b690000040c160d2b2908099a0a06283000000a16fe01130411042d12027b61000004066f7a01000a6f7901000a260917580d09088e69fe04130411042dcb002a000000011000000200c200783a010f00000000ded005000001286e00000a72a83900701f3428fc00000a805e000004d005000001286e00000a72b23900701f386f6f00000a805f0000042a03300200560000000000000002220000c8427d5d0000040273a101000a7d600000040273a101000a7d610000040273a201000a7d620000040273a301000a7d630000040273a401000a7d6400000402168d050000017d6900000402280f01000a002a0000133003002a000000040000110002172e040218331a042d17052c140e040e050e055a350b02182e03032b0117002b0116000a2b00062a0000133002002700000004000011001680700000047e6f00000414283200000a16fe010a062d0d7e6f00000417fe137d740000042a001b300200cf0000000b000011007e7000000417fe0116fe010b072d180028800000060072ca3900702580710000040a38a50000007e6f000004283000000a16fe010b072d23007e6f0000046f87000006007e6f0000046fee00000a28ef00000a0014806f0000040072283a007073af00000a282100002b806f0000047e6f000004027d720000047e6f000004281600000a6f3300000a7d73000004007e6f0000046f830000060000de1a26007e6f0000046fee00000a28ef00000a0014806f000004fe1a00178070000004724c3a00702580710000040a2b00062a000110000000008f000f9e001a010000012e72be3a007080710000042a13300600ff00000039000011000228a501000a7d790000040228a601000a7d7a0000040228a701000a7d7500000402027b750000047ba801000a7d7600000402d020000001286e00000a72ee3a00701f3428fc00000a027b75000004178d010000010a061672fc3a0070a2066ffd00000a74210000017d77000004027b7700000414fe0116fe010b072d0b72083b0070730600000a7a02027b750000047ba801000a7d76000004021a8d480000010c0816027b770000047ba901000aa00817027b770000047baa01000aa00818027b770000047bab01000aa00819027b770000047bac01000aa0087d780000040228a501000a7d790000040228a601000a7d7a000004022884000006002a0013300600580000003a00001100027b77000004027b77000004027b77000004027b770000042200000000250a7dac01000a06250a7dab01000a06250a7daa01000a067da901000a027b7500000472fc3a00707da801000a027b750000046fad01000a002a1b300300ef0100003b000011000002fe137b740000042d4c027b72000004283000000a2c3f027b720000047e3100000a283200000a2d2d027b720000046f3400000a2d20281600000a283000000a2c14281600000a6f3300000a027b73000004fe012b011600130411042d1900022888000006000228ee00000a28ef00000a00dd74010000027b7500000428a701000a283200000a16fe01130411042d1900022888000006000228ee00000a28ef00000a00dd42010000027b7500000472fc3a00707da801000a1628ae01000a00220000000028af01000a0028f400000a027b7b000004fe05130411042d7d000228f400000a220000803f587d7b0000040016282200002b13051613062b19110511069a0a020672463b0070288600000600110617581306110611058e69fe04130411042dd90016282300002b13071613062b19110711069a0b020772503b0070288600000600110617581306110611078e69fe04130411042dd90000027b7c0000046fb001000a13082b2b120828b101000a0c120228b201000a283000000a16fe01130411042d0e120228b201000a166fb301000a00120828b401000a130411042dc8de0f1208fe162e00001b6f2800000a00dc0000de320d000228880000060072643b0070096fb900000a6f5200000a281400000a80710000040228ee00000a28ef00000a0000de0000002a0041340000020000006b0100003c000000a70100000f000000000000000000000001000000b9010000ba0100003200000052000001133003007b0000003c00001100036fb501000a041f346f6f00000a036f0e00000a75a80000010a06283000000a0c082d022b530006176f2400002b0d1613042b3a0911049a0b07283000000a2c0e027b7c000004076fb701000a2b0117000c082d13027b7c00000407076fb801000a6fb901000a001104175813041104098e69fe040c082dbb2a2600022888000006002a0000001b300300580100003d00001100027b7d00000416fe010b072d05384401000002177d7d000004027b770000042c0b027b7800000414fe012b0117000b072d4e00027b77000004027b7800000416987da901000a027b77000004027b7800000417987daa01000a027b77000004027b7800000418987dab01000a027b77000004027b7800000419987dac01000a00027b75000004283000000a2c15027b7500000428a701000a288300000a16fe012b0117000b072d1f00027b75000004027b760000047da801000a027b750000046fad01000a0000027b7900000428ae01000a00027b7a00000428af01000a0000027b7c0000046fb001000a0c2b2f120228b101000a0a120028b201000a283000000a16fe010b072d14120028b201000a120028ba01000a6fb301000a00120228b401000a0b072dc6de0f1202fe162e00001b6f2800000a00dc00027b7c0000046fbb01000a0016807000000472943b007080710000042a011000000200ed003e2b010f000000002600022888000006002a4e0273bc01000a7d7c00000402280f01000a002a000013300200530000003e0000110002283000000a2c2d027e3100000a288300000a2c2028bd01000a283000000a2c1428b300000a2c0d7e850000041428f800000a2d03142b147e8500000428bd01000a6f0e00000a7524000001000a2b00062a00133003005d000000040000110002283000000a2c4d026f4500000a72fc3b00701b6fbe01000a2d13026f4500000a72143c00701b6fbe01000a2c27026f2500002b283000000a2c1a02288d000006283000000a2c0d02288d0000066f0801000a2b0116000a2b00062a00000013300100180000003f0000110002283000000a2d03142b06026f0f00002b000a2b00062a133003002c000000050000110002288c0000062d07728f0200702b1602288d0000066f8a01000a03728f0200706fbf01000a000a2b00062a133002001100000005000011000272323c0070288e0000060a2b00062a000000133002001100000005000011000272643c0070288e0000060a2b00062a000000133004001f0000004000001100022890000006178d920000010b07161f0a9d07176fc001000a0a2b00062a00133003003d0000004100001100000228910000060c160d2b1d08099a0a06031a281b00000a16fe01130411042d04170bde140917580d09088e69fe04130411042dd7160b2b0000072a000000133002001100000005000011000272963c0070288e0000060a2b00062a0000001330010031000000050000110002288c0000062d07728f0200702b1b02288d0000066f8a01000a7c4e00000afe160e0000016ff100000a000a2b00062a00000013300100290000000500001100022c0d027bc101000a283000000a2d07728f0200702b0b027bc101000a6f4500000a000a2b00062a00000013300500660000002e0000110002288c0000062c5603283000000a2c4e7e830000041428c201000a2c417e8300000402178d010000010b0716036fc301000a8caa000001a2076ffd00000aa5460000012c19026f2200000a6f3600000a22000000001616287201000a2b0116000a2b00062a00001330030040000000040000110003288b00000602283200000a2c2a026f5d00000a2d1e02288d0000066f8a01000a7ec401000a166fc501000a16fe0116fe012b0117002b0116000a2b00062a13300300a20000002100001100020328960000060b072d0b72ce3c0070730600000a7a03288b00000602288300000a0a0203289700000616fe010b072d0b72143d0070730600000a7a02288d0000066ff600000a0b072d0b72743d0070730600000a7a7e840000041428c601000a16fe010b072d0b72ea3d007073c701000a7a060b072d0d7e8400000402146ffd00000a26026fc801000a14fe0116fe010b072d0b72283e0070730600000a7a2a000013300300490000004200001100020328980000060002288d0000066f8a01000a0a0672643c0070728f0200706fc901000a000672963c007072643e00706fc901000a000672323c007072903e00706fc901000a002a00000013300600170000001100001100020304178d390000010a061605a206289b000006002a2e00020405289c000006002a001b300400150200004300001100020328980000060002288f00000672903e0070281801000a16fe01130711072d0b729e3e0070730600000a7a288800000a739b00000a0a02288f00000672e83e0070281801000a16fe01130711072d300002289100000613081613092b14110811099a0b06076fa400000a26110917581309110911088e69fe04130711072dde00026fc801000a6fca01000a6fcb01000a130a2b32120a28cc01000a0c087ba000000a7b3601000a2d08087b3101000a2b011700130711072d0d060828950000066fa400000a26120a28cd01000a130711072dc1de0f120afe163100001b6f2800000a00dc00288800000a739b00000a0d0414fe0116fe01130711072d0b72003f0070730600000a7a00046fce01000a130b2b5a110b6fcf01000a130400110428c300000a2d2a1104188d92000001130c110c161f0a9d110c171f0d9d110c6f4701000a162f0a0611046fe200000a2b011600130711072d0b72343f0070730600000a7a0911046fa400000a2600110b6f9100000a130711072d99de14110b14fe01130711072d08110b6f2800000a00dc00096f4e01000a16fe0116fe01130711072d0b729e3f0070730600000a7a09734a01000a13051105288800000a6fea00000a0002288d0000066f8a01000a1306110672643c0070724a1c007011056feb00000a28ec00000a6fc901000a00110672963c007072643e00706fc901000a00110672323c007072e83e00706fc901000a002a000000011c00000200940043d7000f00000000020013016b7e0114000000001b3004007e0100004400001100020328980000060002288f00000672903e0070281801000a16fe01130611062d0b7212400070730600000a7a288800000a739b00000a0a00026fc801000a6fca01000a6fcb01000a13072b7f120728cc01000a0b00072c18077ba000000a7b3601000a2d0b077b3101000a16fe012b011600130611062d022b510728950000060c0828c300000a16fe01130611062d022b3908188d9200000113081108161f0a9d1108171f0d9d11086f4701000a16fe04130611062d0b7292400070730600000a7a06086fa400000a2600120728cd01000a130611063a71ffffffde0f1207fe163100001b6f2800000a00dc0006734a01000a0d09288800000a6fea00000a0002288d0000066f8a01000a1304110472643c0070724a1c0070096feb00000a28ec00000a6fc901000a00110472963c0070096fed00000a163007728f0200702b0572643e0070006fc901000a00110472323c0070096fed00000a163007728f0200702b0572e83e0070006fc901000a00096fed00000a13052b0011052a00000110000002004b0093de000f0000000013300300490000004200001100020328980000060002288d0000066f8a01000a0a0672323c0070728f0200706fc901000a000672643c0070728f0200706fc901000a000672963c0070728f0200706fc901000a002a000000133002003d00000004000011000203283200000a2c2c03288c0000062c2403288f00000672903e0070281801000a2c1202288f00000672e83e0070281801000a2b0116000a2b00062a1e02286d00000a2a000000133003006c0000004500001100036f2200000a6f3600000a027be30000046f2200000a6f3600000a280601000a0c1202046f2200000a6f3600000a027be30000046f2200000a6f3600000a280601000a28d001000a0a062d18288800000a0328940000060428940000066f4101000a2b0106000b2b00072a1b3005003e0400004600001173e4000006130f110f027de300000400110f7be300000403289800000600110f7be3000004288f00000672903e0070284d01000a16fe01131111112d0b7200410070730600000a7a288800000a739b00000a0a00110f7be30000046fc801000a6fca01000a6fcb01000a13122b32121228cc01000a0b077ba000000a7b3601000a2d08077b3101000a2b011700131111112d0d060728950000066fa400000a26121228cd01000a131111112dc1de0f1212fe163100001b6f2800000a00dc0073d101000a0c73d000000a0d16130416130516130600046fd201000a131338da00000011136fd301000a1307001107110f7be3000004289f0000062c0f09110728940000066fa400000a2b011600131111112d0538a4000000161308001107289100000613141613152b24111411159a13090611096fe200000a16fe01131111112d06001713082b14111517581315111511148e69fe04131111112dce1108131111112d022b561107032896000006131111112d09001105175813052b3f110703289700000616fe01131111112d09001104175813042b251107288d0000066ff600000a131111112d09001106175813062b0a0811076fd401000a000011136f9100000a131111113a16ffffffde14111314fe01131111112d0811136f2800000a00dc0008110ffe06e500000673d501000a6fd601000a00110f7be30000046fc801000a130a16130b00110a6fca01000a73d701000a28cb01000a13123803010000121228cc01000a0b00072c25077ba000000a7b3601000a2d18077b3101000a2d1007289500000628c300000a16fe012b011600131111112d0538c500000000086fd801000a13163894000000121628d901000a130c00110a076f2f01000a131111112d053887000000110c0728950000062892000006131111112d022b62110f7be300000403289800000600110c03289800000600110a076f2f01000a131111112d022b4b077b3701000a130d110c6fc801000a110a076fda01000a00110b16110d110a076f2f01000a2d03162b06077b3701000a0059288d00000a58130b00121628db01000a131111113a5cffffffde0f1216fe163800001b6f2800000a00dc0000121228cd01000a131111113aedfeffffde0f1212fe163100001b6f2800000a00dc0016130e00110a6fca01000a6fcb01000a13122b13121228cc01000a0b110e077b3701000a58130e121228cd01000a131111112de0de0f1212fe163100001b6f2800000a00dc001c8d01000001131711171672541f0070a2111717110b8c5e000001a21117187238410070a2111719110e8c5e000001a211171a724a410070a211171b1104110558110658163007728f0200702b541d8d01000001131811181672cd410070a211181711048c5e000001a211181872e3410070a211181911058c5e000001a211181a72f3410070a211181b11068c5e000001a211181c720d420070a21118287d00000a00a21117287d00000a13102b0011102a0000417c0000020000006c00000043000000af0000000f0000000000000002000000dd000000f1000000ce01000014000000000000000200000068020000ab000000130300000f00000000000000020000001c0200001a010000360300000f000000000000000200000058030000240000007c0300000f000000000000001330070079000000300000111f348082000004d024000001286e00000a72414200707e8200000414178d580000010a0616d0aa000001286e00000aa20614285b01000a8083000004d024000001286e00000a72594200707e8200000428fc00000a8084000004d02f000001286e00000a72634200707e820000046f6f00000a80850000042a000000133001000b00000004000011027b8d0000040a2b00062a2202037d8d0000042a133001000b00000005000011027b8e0000040a2b00062a2202037d8e0000042a1b30030012020000470000110273d101000a7d8a0000040273dc01000a7d8b00000402286d00000a0000030428980000060003288f00000672903e0070284d01000a16fe01130611062d0b7200410070730600000a7a02037d8600000402047d8700000402281600000a7d8800000402027b880000046f3300000a7d890000040228dd01000a2200002041587d8c000004288800000a739b00000a0a00036fc801000a6fca01000a6fcb01000a13072b32120728cc01000a0b077b3101000a2d0d077ba000000a7b3601000a2b011700130611062d0d060728950000066fa400000a26120728cd01000a130611062dc1de0f1207fe163100001b6f2800000a00dc0073d000000a0c0000056fd201000a130838c800000011086fd301000a0d000903289f0000062c0e080928940000066fa400000a2b011600130611062d05389b000000027b8a000004096fd401000a00090428960000062c19090428970000062d1009288d0000066ff600000a16fe012b011600130611062d022b6216130400092891000006130916130a2b241109110a9a13050611056fe200000a16fe01130611062d06001713042b14110a1758130a110a11098e69fe04130611062dce110416fe01130611062d13027b8b000004090428aa0000066fde01000a000011086f9100000a130611063a28ffffffde14110814fe01130611062d0811086f2800000a00dc000228a80000060000de0b26000228a900000600fe1a00002a0000414c000002000000a300000043000000e60000000f000000000000000200000006010000df000000e5010000140000000000000000000000fc00000008010000040200000b0000000100000113300200820000000400001100027b87000004283000000a2c6d027b870000047e3100000a288300000a2c5b027b870000046f1101000a2c4e027b870000046f3400000a2d41027b870000046f3500000a2d34027b88000004283000000a2c27027b88000004281600000a288300000a2c15027b880000046f3300000a027b89000004fe012b0116000a2b00062a00001b3004000402000048000011000228a200000616fe01130511052d0538ee0100000228a7000006130511052d0d000228a90000060038d5010000160a00027b8b0000046fdf01000a13062b1b120628e001000a0b076fae00000616fe01130511052d040617580a120628e101000a130511052dd8de0f1206fe163a00001b6f2800000a00dc000616311228dd01000a027b8c000004fe0416fe012b011700130511052d2200027289420070068c5e00000172bd42007028bf00000a28a500000600384901000000027b8a00000473e201000a0c160d16130400027b8b0000046fdf01000a13062b3e120628e001000a0b076fad000006130511052d2a0008076fab0000066fe301000a26076fac00000616fe01130511052d060917580d2b0611041758130400120628e101000a130511052db5de0f1206fe163a00001b6f2800000a00dc0002027b86000004027b870000040828a000000628a5000006000911045816fe0216fe01130511052d54022528a400000613071c8d0100000113081108161107a21108177244430070a2110818098c5e000001a21108197268430070a211081a11048c5e000001a211081b727c430070a21108287d00000a28a50000060000de4900021728a30000060000027b8b0000046fdf01000a13062b0f120628e001000a0b076fb200000600120628e101000a130511052de4de0f1206fe163a00001b6f2800000a00dc0000dc002a0134000002003e002c6a000f000000000200da004f29010f000000000200d00120f0010f000000000200ba00ffb90149000000001b3002006000000049000011000228a200000616fe010b072d022b4f021728a3000006000272ec43007028a50000060000027b8b0000046fdf01000a0c2b0f120228e001000a0a066fb200000600120228e101000a0b072de6de0f1202fe163a00001b6f2800000a00dc002a01100000020031001e4f000f000000001b300300b90000004a00001100007e8f0000046fe401000a73e501000a28e601000a13052b2c120528e701000a0a06283000000a2c08066f0801000a2b011600130611062d0c7e8f000004066fe801000a26120528e901000a130611062dc7de0f1205fe163d00001b6f2800000a00dc0002288d0000060b7e8f0000040712026fea01000a2c08087b990000042b011700130611062d050813042b26020373af0000060d097b99000004130611062d0d7e8f00000407096feb01000a000913042b0011042a00000001100000020018003d55000f00000000133001000c0000003e00001100027b920000040a2b00062a133002001b0000000400001100027b990000042c0b027b9a00000416fe012b0116000a2b00062a00133001004c0000000400001100027b990000042c3c027b9a0000042c34027b92000004283000000a2c27027b93000004283000000a2c1a027b930000046f0801000a2c0d027b930000046ff600000a2b0116000a2b00062a13300200570000000400001100027b92000004283000000a2c42027b93000004283000000a2c35027b930000046f0801000a2c28027b990000042c1c027b9a0000042c10027b930000046ff600000a16fe012b0116002b0117002b0116000a2b00062a001b300500810100002e00001102286d00000a000002037d920000040203288d0000067d9300000402027b930000046f8a01000a6f2100000a7d94000004027b94000004166afe0116fe010a062d0d0002177d990000043831010000027e900000041428f800000a2d03142b157e90000004027b930000046f0e00000a7525000001007d95000004027e91000004287200000a7d96000004027b950000042c18027b95000004027b960000048c5e0000016fec01000a2b0116000a062d0b723c440070730600000a7a02027b95000004027b960000048c5e0000016fed01000a7d97000004027b930000047e910000046fee01000a0000027b930000047e9100000402fe06b000000673ef01000a6f2600002b0002027b95000004027b960000048c5e0000016fed01000a7d9800000400de212600027b95000004027b960000048c5e000001027b970000046ff101000a00fe1a0000027b9300000472c7440070178d010000010b0716046fc301000a8caa000001a2076ff201000a0000de0b26000228b100000600fe1a00002a000000011c00000000e9003d26012101000001000048012b73010b01000001133003005d0000004b0000110003027b94000004fe010b072d022b4c02177d9900000402047d9a0000047e8f000004027b9300000412006fea01000a2c0c0602282f00000a16fe012b0117000b072d117e8f000004027b930000046fe801000a260228b1000006002a000000133003005b0000000400001100027b950000042c2e027b980000042c26027b95000004027b960000048c5e0000016fed01000a027b98000004282f00000a16fe012b0117000a062d1d027b95000004027b960000048c5e000001027b970000046ff101000a002a0013300200160000000400001100027b9900000416fe010a062d070228b1000006002ac273f301000a808f000004d016000001286e00000a72e74400701f346f6f00000a809000000472ff44007080910000042a0013300200e50000000b0000110002283000000a2c15027e3100000a283200000a2d08026f1101000a2b0116000b072d0b7221450070730600000a7a7e9d000004283000000a16fe010b072d5c007e9d0000047ba000000402283200000a2d187e9d0000047ba1000004281600000a6f3300000afe012b0116000b072d0b725b450070730600000a7a17809b0000047e9d000004176ff401000a0072c745007025809c0000040a2b47725846007073af00000a282700002b809d0000047e9d000004027da00000047e9d000004281600000a6f3300000a7da100000417809b00000472c745007025809c0000040a2b00062a220016809b0000042a0000133002002c00000004000011007e9d00000402288300000a16fe010a062d180014809d00000416809b000004728a460070809c000004002a2e72f0460070809c0000042a133002007600000004000011007e9b000004173366027ba0000004283000000a2c59027ba00000047e3100000a288300000a2c47027ba00000046f1101000a2c3a027ba00000046f3400000a2d2d027ba00000046f3500000a2d20281600000a283000000a2c14281600000a6f3300000a027ba1000004fe012b0116000a2b00062a00001330010040000000040000110028b200000a2d3128b300000a2d2a28b400000a2d2328b500000a2d1c28b600000a283000000a2c0c28b600000a6fb700000a2b0116002b0117000a2b00062a1b300300450000004c0000110000027ba0000004288b0000060a06283000000a16fe010c082d0902061728bd0000060000de1c0b000228c100000600076fb900000a6f5200000a809c00000400de00002a00000001100000000001002627001c520000011b300600a60300004d00001114130500000228b8000006130611062d19000228c1000006000228ee00000a28ef00000a00dd7a03000028b100000a130611062d14000228c10000060002147da3000004dd5b030000027ba0000004288b0000060a027ba700000416fe01130611063a2c01000000027ba80000042d0728b90000062b4106027ba2000004283200000a2d3128b200000a2d2a28b400000a2d2328b500000a2d1c28b600000a283000000a2c0c28b600000a6fb700000a2b0116002b011700000b027bae00000428f501000a283200000a2d3b027ba2000004283000000a2c2e027ba2000004027ba000000428960000062c1b072d181f1b28f601000a2d0f202201000028f601000a16fe012b011600130611062d0d000228c100000600dd88020000027ba400000414fe01130611062d4500027ba40000046fa80000060002027ba40000046fa40000067db7000004027bb7000004809c000004027ba40000046fa200000616fe01130611062d0702147da400000400027ba0000004286400000a6ff701000a00027ba0000004166ff801000a00dd1102000006283000000a2c0b06288c00000616fe012b011700130611063aad00000000027ba90000046fd70000062d0f28dd01000a027bb9000004fe052b011600130611062d670000027ba900000411052d1002fe06d000000673f901000a13052b0011056fd800000600027ba90000046fda0000060000de320c00027ba90000046fdd000006000228dd01000a2200000040587db9000004086fb900000a6f5200000a809c00000400de000000202201000028f601000a16fe01130611062d0902061728bd00000600dd46010000027ba90000046fdd0000060028b900000616fe01130611062d0d0002147da3000004dd1f01000028dd01000a027bb80000042f0f202201000028f601000a16fe012b011600130611063a84000000000228dd01000a229a99193e587db8000004027ba00000046ffa01000a0d0209283000000a2d03142b06096f2800002b007da3000004027ba3000004288c0000062c31027ba00000046f2200000a6f3600000a027ba30000046f2200000a6f3600000a280601000a220000a040fe0216fe012b011600130611062d0702147da300000400202201000028f601000a2c10027ba3000004283000000a16fe012b011700130611062d0e02027ba30000041628bd0000060000de3d1304000228c10000060072f846007011046fb900000a6f5200000a281400000a809c000004027ba0000004177e9c0000041614166fba00000a0000de000000002a00004134000000000000d701000032000000090200003200000052000001000000000400000061030000650300003d00000052000001133003004e0000000400001100027bae000004283000000a2c15027bae00000428f501000a288300000a16fe012b0117000a062d177eaf000004027bae000004168c460000016ffb00000a001628fc01000a0028fd01000a002a000013300200160000000400001100027ba700000416fe010a062d070228bb000006002a00001330020047000000040000110028d600000616fe010a062d0b720c470070730600000a7a03027ba000000428980000060002037da20000040228be00000600020428bf000006000272584700707db70000042a00133003001c000000060000110028fe01000a0228c00000060328c00000066f4101000a0a2b00062a133004001e000000060000110028fe01000a020328ce000006020428ce0000066f4101000a0a2b00062a00001b300500ce0200004e00001100027ba20000040a027bb60000046fff01000a00027bb50000046f0002000a00027bb30000046f0102000a0002280202000a7db0000004027bb40000046f0002000a0006288f00000672903e0070281801000a16fe01130511053ade000000000016282900002b130616130738a9000000110611079a0b0706289f00000616fe01130511053a8a0000000007289100000613081613092b6e110811099a0c027bb40000041a8d01000001130a110a16020828ce000006a2110a17720f480070a2110a18076f2200000a6f3600000a066f2200000a6f3600000a280601000a6c280302000a8c5f000001a2110a197217480070a2110a287d00000a6fdd00000a00110917581309110911088e69fe04130511052d84110717581307110711068e69fe04130511053a46ffffff027bb400000428fe01000a6fea00000a000073d000000a0d00066fc801000a6fca01000a6fcb01000a130b2b59120b28cc01000a130400110428950000060c08728f020070284d01000a2c2311047ba000000a7b3601000a2d1511047b3101000a2d0c09086fa400000a16fe012b011700130511052d0e027bb300000411046f0402000a0000120b28cd01000a130511052d9ade0f120bfe163100001b6f2800000a00dc00027bb30000047ec90000042d1314fe06d1000006730502000a80c90000042b007ec90000046f0602000a0000027bb30000046fcb01000a130b2b1c120b28cc01000a1304027bb5000004110428950000066fdd00000a00120b28cd01000a130511052dd7de0f120bfe163100001b6f2800000a00dc0006288f00000672e83e0070281801000a16fe01130511052d560006289100000613081613072b3a110811079a0c00027bb6000004086fa400000a26027bb5000004086f0702000a130511052d0d027bb5000004086fdd00000a0000110717581307110711088e69fe04130511052db8027bb500000402fe06d2000006734b01000a6f4c01000a002a0000011c0000020056016ac0010f00000000020009022d36020f000000001330050062010000040000110002027ba00000046f2a00002b7da5000004027ba5000004283000000a0a062d0b721d480070730600000a7a7eaf00000414280c00000a2d277eaf0000046ff900000ad046000001286e00000a281201000a2d0c28f501000a283000000a2b0116000a062d0b7257480070730600000a7a0228f501000a7dae000004027eaf000004027bae0000046f0e00000aa5460000017dad00000402027ba50000046f1101000a7da600000402280802000a7daa00000402280902000a7dab00000402280a02000a7dac000004027ba0000004286400000a6ff701000a00027ba0000004166ff801000a00027ba5000004166ff401000a0002177da700000402037da8000004027ba800000416fe010a062d0c027ba90000046fdb000006000228bb00000600021f0a280b02000a200802000059185b288d00000a6b1f0a280c02000a204a02000059185b288d00000a6b22000002442200801244730d02000a7dba0000042a0000133002001b0000000500001100283c01000a027ba000000a7b3b01000a6f3d01000a0a2b00062a0013300300320100000400001100027ba400000414fe010a062d1500027ba40000046fa90000060002147da400000400027ba70000040a062d0538ff00000002167da7000004027ba90000046fdc0000060002167da8000004027ba5000004283000000a2c2f027ba0000004283000000a2c22027ba00000047e3100000a288300000a2c10027ba00000046f1101000a16fe012b0117000a062d12027ba5000004027ba60000046ff401000a00027bae000004283000000a2c15027bae00000428f501000a288300000a16fe012b0117000a062d1c7eaf000004027bae000004027bad0000048c460000016ffb00000a0002147dae000004027bac00000416fe010a062d0828fd01000a002b06280e02000a00027bab00000428fc01000a00027baa000004280f02000a0002147da2000004027bb30000046f0102000a002a56000228c100000600027ba90000046fdd000006002a1b300200700000004f000011000228c100000600027ba90000046fdd0000060000027bbb0000046f1002000a0b2b1c1201281102000a0a06283000000a16fe010c082d070628ef00000a001201281202000a0c082dd9de0f1201fe164100001b6f2800000a00dc00027bbb0000046f1302000a000228b6000006002a01100000020021002b4c000f000000001b3002003a0000001c0000110000036f1402000a00027bb7000004809c00000400de210a0002066fb900000a6f5200000a7db7000004027bb7000004809c00000400de00002a000001100000000001001617002152000001133004003600000050000011001717731502000a0a061f3d6f1602000a00061616036f1702000a00066f1802000a00027bbb000004066f1902000a00060b2b00072a000013300500630000005100001100281a02000a6f1b02000a731c02000a0a06036f1d02000a0006052d03162b0117006f1e02000a0006176f1f02000a0006166f2002000a0006166f2102000a000616161616732202000a6f2302000a00066f2402000a046f2502000a00060b2b00072a0013300500790100005200001100281a02000a6f2602000a731c02000a0a061f126f1d02000a0006176f1e02000a0006176f1f02000a0006166f2002000a00061a6f2102000a00061f0e1f0e1e1e732202000a6f2302000a000616161616732202000a6f2702000a000622000000006f2802000a000622000000006f2902000a0000188db60000010d0916066f2402000aa20917066f2a02000aa20913041613052b1f110411059a0b0007036f2b02000a00070e046f2502000a0000110517581305110511048e69fe04130611062dd3001a8db60000010d0916066f2c02000aa20917066f2d02000aa20918066f2e02000aa20919066f2f02000aa20913041613052b1f110411059a0b0007046f2b02000a00070e046f2502000a0000110517581305110511048e69fe04130611062dd300188db60000010d0916066f3002000aa20917066f3102000aa20913041613052b1f110411059a0b0007056f2b02000a00070e046f2502000a0000110517581305110511048e69fe04130611062dd3060c2b00082a000000133009000e0300005300001100027bbc00000414fe01130511052d0538f80200001200223333733f228fc2753f2248e17a3f220000803f283202000a00120122ec51383f2214ae473f22f6285c3f220000803f283202000a00120222c3f5683f2248e13a3f22f628dc3e220000803f283202000a0002733302000a7dbc0000040222b81e853d227b14ae3d228fc2f53d220000803f733202000a28c50000060d001e8db60000011306110616027bbc0000046f2402000aa2110617027bbc0000046f2a02000aa2110618027bbc0000046f2c02000aa2110619027bbc0000046f2d02000aa211061a027bbc0000046f3002000aa211061b027bbc0000046f3102000aa211061c027bbc0000046f2e02000aa211061d027bbc0000046f2f02000aa2110613071613082b16110711089a13041104096f2b02000a00110817581308110811078e69fe04130511052ddc0202223d0ad73d22295c0f3e225c8f423e220000803f733202000a28c50000067dc60000040202221f856b3e22e17a943e22a470bd3e220000803f733202000a28c50000067dc70000040202220000000022000000002200000000229a99193f733202000a28c50000067dc800000402021f1c061728c60000067dbd00000402021f12061628c60000067dbe00000402021f10071628c60000067dbf00000402021f0e081728c60000067dc000000402021f12061628c60000067dc100000402021f11061628c60000067dc400000402021f0d081728c60000067dc5000004020202225c8f423e220000803e22c3f5a83e220000803f733202000a28c50000060222b81e853e227b14ae3e22ae47e13e220000803f733202000a28c50000060222b81e053e22ec51383e220000803e220000803f733202000a28c50000060628c70000067dc200000402020222f6285c3f22c3f5283f227b14ae3e220000803f733202000a28c500000602228fc2753f22b81e453f226666e63e220000803f733202000a28c50000060222ec51383f22b81e053f220000803e220000803f733202000a28c5000006229a99993d22ec51b83d228fc2f53d220000803f733202000a28c70000067dc30000042a00001b3006003702000054000011000228b80000062c0728b100000a2b011600130711072d053819020000027ba700000416fe01130711073a93010000000228bb000006000228c800000600283402000a0a283502000a0b283602000a0c283702000a0d283802000a130400283902000a283a02000a00283902000a283b02000a00283902000a283c02000a001f9c283d02000a00283e02000a283f02000a0022000000002200000000280b02000a6b280c02000a6b730d02000a027bc8000004284002000a0022cdcccc3d223333933f280b02000a6b22000000425922000025445b280c02000a6b22000000425922000030445b282c01000a282c01000a28ad00000a1305286400000a283c00000a11051105220000803f731f01000a284102000a283f02000a0002280b02000a6b11055b22000025445922000000405b280c02000a6b11055b22000030445922000000405b22000025442200003044730d02000a7dba0000040202287a01000a027bba00000402fe06cd000006734202000a728f020070027bbc000004284302000a7dba00000402287a01000a284402000a0000de270006283a02000a0007283b02000a0008283c02000a0009283f02000a001104283d02000a0000dc00002b74027ba3000004283000000a2c0728b90000062b011700130711072d5800027ba3000004288f00000672903e0070281801000a2d0772dc4800702b05720e490070001306280b02000a185b20b4000000596b280c02000a185b1f50586b220000b4432200001042730d02000a1106284502000a00002a00411c0000020000005d0000003a0100009701000027000000000000003e0003027bc6000004284002000a002a03300400730000000000000000220000c041220000b04122000007442200001842730d02000a03027bbd000004284602000a00220000c04122000080422200001944220000c041730d02000a04027bbf000004284602000a00220000c041220000c0422200001944220000803f730d02000a027bc7000004284002000a002a001330070056010000220000110002220000c04122000004442200001944220000c042730d02000a28ca00000600220000204222000007442200001144220000a041730d02000a723e490070027bc0000004284602000a00027bb7000004027bb2000004284d01000a16fe010b072d190002280202000a7db100000402027bb70000047db2000004002200005042027bc4000004027bb7000004734702000a2200000b446f4802000a28ad00000a0a0222000020422200400d4422000011442200005042730d02000a027bb1000004220000000022000000002200000b4406730d02000a284902000a7db1000004220000000022000000002200000b4406730d02000a027bb7000004027bc4000004284602000a00284a02000a00220000c041220000214422000019442200002042730d02000a027ba80000042d07724c4900702b05726e49007000027bc2000004284b02000a16fe010b072d070228c1000006002a1e02286d00000a2a00001330040049000000040000110002027ba2000004027ba000000416282900002b73a60000067da400000402027ba40000046fa40000067db7000004027ba40000046fa200000616fe010a062d0702147da40000042a00000013300400420000000600001100027ba2000004027ba0000004289d0000060a0228be000006000206163007728a4900702b1572134a0070068c5e00000172574a007028bf00000a007db70000042a000013300200790000000400001100027be400000416fe010a062d3000027be50000047ba2000004027be50000047ba0000004289e00000600027be500000472a14a00707db7000004002b2e00027be50000047ba2000004027be50000047ba0000004289900000600027be500000472f74a00707db700000400027be500000428be000006002a0000001b300800030500005500001114130814130973e6000006130a110a027de500000400110a027ba2000004288f00000672903e0070281801000a7de40000040272824b0070110a7be40000042d07729e4b00702b0572084c00700028cb0000060002220000c041220000e04222000019442200005042730d02000a28ca00000600027ba200000428910000068e690a2200002042220000fe422200001144220000e041730d02000a110a7be40000042d22062c17726a4c0070068c5e00000172984c007028bf00000a2b0572bc4c0070002b0572104d007000027bbe000004284602000a00220000c04122000036432200001944220000b041730d02000a110a7be40000042d07724e4d00702b1a728e4d0070027bb40000046fed00000a8c5e000001280d01000a00027bc0000004284602000a0002220000c041220000564322000019442200002e43730d02000a28ca0000060022000000000b110a7be40000042d08027bb50000042b06027bb4000004000c00086fe400000a130b2b56120b28e500000a0d072200002042027bc1000004110a7be40000042d09020928ce0000062b010900734702000a110a7be40000042d0720c80100002b052030020000006b6f4802000a22000040415828ad00000a580b120b28e800000a130c110c2d9dde0f120bfe161f00001b6f2800000a00dc000222000000422200005e4322000015442200001e43730d02000a027bb0000004220000000022000000002200800e442200001e430728ad00000a730d02000a284902000a7db00000042200000000130400086fe400000a130b38ff000000120b28e500000a0d00110a7be40000042d09020928ce0000062b01090013052200002042027bc10000041105734702000a110a7be40000042d0720c80100002b052030020000006b6f4802000a22000040415828ad00000a1306110a7be4000004130c110c2d4622000000411104220000004158220000b8421106220000004159730d02000a027bb6000004096fe200000a2d0772c04d00702b0572d24d007000027bc5000004284602000a00110a7be40000042d041f6c2b011e006b1104220000c04058110a7be40000042d0720c60100002b052028020000006b1106220000c04059730d02000a1105027bc1000004284602000a001104110658130400120b28e800000a130c110c3af1feffffde0f120bfe161f00001b6f2800000a00dc00086fed00000a16fe0116fe01130c110c2d3b220000004122000040412200800944220000c042730d02000a110a7be40000042d0772de4d00702b0572794e007000027bbf000004284602000a00284a02000a00284c02000a130711072c0b027ba400000414fe012b011600284d02000a00110a7be400000416fe01130c110c2d6300220000c041220000ca4322000019442200004042730d02000a027ba40000042c0772224f00702b0572584f007000027bc3000004284b02000a16fe01130c110c2d1d0211082d1002fe06d300000673f901000a13082b00110828c400000600002b5100220000c041220000ca4322000019442200004042730d02000a726e4f0070027bc3000004284b02000a16fe01130c110c2d1d0211092d1002fe06d400000673f901000a13092b00110928c40000060000220000c041220000ea4322000019442200002842730d02000a110a7be40000042d0772a24f00702b0572d64f007000027bc2000004284b02000a16fe01130c110c2d1402110afe06e700000673f901000a28c4000006001107284d02000a000228cc00000600002a0041340000020000007001000067000000d70100000f00000000000000020000004002000016010000560300000f000000000000001b30020092000000560000110000027bb30000046fcb01000a13042b26120428cc01000a0a06289500000603281801000a16fe01130511052d090628c00000060dde58120428cd01000a130511052dcdde0f1204fe163100001b6f2800000a00dc00283800000a036f3900000a0b07283000000a2d03142b06076f0700002b000c08283000000a2d03032b0b087b9f00000a28c0000006000d2b0000092a00000110000002000f003746000f0000000072d028000001286e00000a72fe4f00701f346f6f00000a80af0000042a000000033002005a000000000000000273de0000067da900000402734e02000a7db30000040273cf00000a7db40000040273cf00000a7db500000402288800000a739b00000a7db600000402728f0200707db700000402734f02000a7dbb00000402280f01000a002a00001330020038000000040000110028bd01000a283000000a2c247ece0000041428f800000a2c177ece00000428bd01000a6f0e00000a14fe0116fe012b0116000a2b00062a13300100110000000400001100027bd0000004283000000a0a2b00062a1e02286d00000a2a3a00027be60000046f1402000a002a13300600ea0300005700001173e8000006130b110b037de600000400027bd0000004283000000a2c15027bcf00000428bd01000a288300000a16fe012b011700130c110c2d0538aa0300000228dd000006000228bd01000a7dcf000004027bcf000004283000000a2c0d7ecb0000041428f800000a2d03142b157ecb000004027bcf0000046f0e00000a7530000001000a027bcf000004283000000a2c0d7ecc0000041428f800000a2d03142b157ecc000004027bcf0000046f0e00000a7530000001000b06283000000a2c0807283000000a2b011600130c110c2d0b721c500070730600000a7a066f2b00002b0c076f2b00002b0d08283000000a2c2b09283000000a2c23086f5002000a096f5002000a283200000a2d10086f5002000a753200000114fe032b011600130c110c2d0b725a500070730600000a7a02087dd200000402097dd300000402027bd200000473e00000067dd400000402027bd300000473e00000067dd5000004027bd20000046f5102000a7b2900000a027bd20000046f5202000a7b5302000a027bd20000046f5402000a130d120d285502000a5a59027bd30000046f5102000a7b2900000a027bd30000046f5202000a7b5302000a027bd30000046f5402000a130d120d285502000a5a59282c01000a1304027bd20000046f5102000a7b2900000a220000803f027bd20000046f5202000a7b5302000a59027bd20000046f5402000a130d120d285502000a5a58027bd30000046f5102000a7b2900000a220000803f027bd30000046f5202000a7b5302000a59027bd30000046f5402000a130d120d285502000a5a5828ad00000a1305110511045922000040415922000040405b1306027bd20000046f5402000a130d120d285602000a027bd30000046f5402000a130d120d285602000a282c01000a130711062200008242320e11072200007041fe0416fe012b011600130c110c2d0b72ce500070730600000a7a066fee00000a027bd20000046f5002000a282c00002b1308110872385100706f5802000a000211086f2d00002b7dd0000004027bd0000004735902000a6f5a02000a00027bd00000046f5b02000a110bfe06e9000006735c02000a6f5d02000a00021108176f2e00002b7dd1000004027bd20000046f5002000a74320000011309027bd20000046f5102000a7b2b00000a220000003f027bd20000046f5202000a7b5f02000a59027bd20000046f5402000a130d120d285602000a5a58130a027bd200000411091104110a1106110728d900000600027bd300000411091104110658220000c04058110a1106110728d90000060011086f2f00002b1109110422000000401106220000c040585a58110a1106110728d9000006001108176f6002000a000228da00000600002a00000330030050000000000000000002036f5202000a6f6102000a0002036f5202000a6f6202000a00022200000000220000003f736302000a6f6402000a00020e040e05736302000a6f6502000a00020405736302000a6f6602000a002a133003006a0000000400001100027bd0000004283000000a0a062d022b57027bd000000428d600000616fe016f6702000a00027bd1000004283000000a16fe010a062d3100027bd100000472824b00706f6802000a00027bd1000004176f6902000a00027bd100000422000020416f6a02000a00002a000013300200ec0000005800001100027bd800000416fe010c082d0538d8000000027bcf000004283000000a2d0728bd01000a2b06027bcf000004000a06283000000a2c0d7ecd0000041428f800000a2d03142b107ecd000004066f0e00000a7544000001000b07283000000a0c082d0b7276510070730600000a7a02076f3000002b7dd6000004027bd6000004283000000a0c082d1f0002076fee00000a6f3100002b7dd600000402027bd60000047dd70000040002027bd60000046f6b02000a7dd900000402027bd60000046f6c02000a7dda000004027bd6000004166f6d02000a00027bd6000004166f6e02000a0002177dd80000042a13300200540000000400001100027bd80000040a062d022b4602167dd8000004027bd6000004283000000a16fe010a062d2600027bd6000004027bd90000046f6d02000a00027bd6000004027bda0000046f6e02000a000002147dd60000042a13300200ab00000004000011000228dc00000600027bd7000004283000000a16fe010a062d0c027bd700000428ef00000a0002147dd7000004027cd4000004027bd200000428e100000600027cd5000004027bd300000428e100000600027bd0000004283000000a16fe010a062d2400027bd00000046f5b02000a6f6f02000a00027bd00000046fee00000a28ef00000a000002147dd000000402147dd100000402147dcf00000402147dd200000402147dd30000042a000330030080000000000000001f3480ca000004d02f000001286e00000a72ba5100707eca0000046f6f00000a80cb000004d02f000001286e00000a72da5100707eca0000046f6f00000a80cc000004d02f000001286e00000a72fc5100707eca0000046f6f00000a80cd000004d02f000001286e00000a721c5200707eca0000046f6f00000a80ce0000042a1e02286d00000a2a033002004a000000000000000002036f7002000a7ddb00000402036f7102000a7ddc00000402036f5202000a7ddd00000402036f7202000a7dde00000402036f7302000a7ddf00000402036f5102000a7de00000042a0000133002004f000000040000110003283000000a0a062d022b4103027bdb0000046f6102000a0003027bdc0000046f6202000a0003027bdd0000046f6402000a0003027bde0000046f6502000a0003027bdf0000046f6602000a002a0042534a4201000100000000000c00000076342e302e33303331390000000005006c00000044310000237e0000b0310000782b000023537472696e677300000000285d000034520000235553005caf00001000000023475549440000006caf00006815000023426c6f620000000000000002000001579da229090a000000fa25330016000001000000bf00000023000000e6000000e9000000d0000000730200000a00000018000000010000005800000003000000070000000900000041000000010000000100000010000000090000003100000000000a000100000000000600d601cf010600dd01cf010a000a02fe010e002e0200000e00bf0200001700c80200000600fd02eb0206002a030f030e00310300000a003c03fe010e008d0300000e00d50400000e00fc0400000e002705000006007d050f030600b705eb020600e5050f030e00fa0500004b00020600000e00cb0600001200ef06fe010e00fe0600000e00110700000e003b0700001600e1070f030a000208fe0106002708eb020e00520800001a0083080f030a008b08fe010600fb08db080e00c30900000e00df0900000a00040afe010a00220afe010e00890a00000600e90bd60b0e00aa0c00000a00010dfe010e00390d00000a005f0dfe010a00dc0dfe0106002a0ecf010a00350efe011e00650efe010a00060ffe010e00760f00002200960f870f2600bc0fb60f0a00cb0ffe012a000e10fe0106003412db0806005412db0806009f128e120600b212cf010600cc12cf010600de12cf010600f012cf010600ff12cf0106000e13cf0106002f13cf0106004e13cf010e007d1300005f00951300002300ae1300000600e113cf010e00141400000a003614fe010a004e14fe0106006614cf0106008e14cf0106009a14cf010600a914cf010e00b21400000a00d601fe012e003c1500000e004d1500000e007a1500000e00901500000e00951500000e001716000006006e16cf010a008416fe011200b116fe011200b916fe011200c416fe010e00ad1700000600cb17cf010600d017cf010e00fd1700002e000c1800000e00481800000e005118000006008c18cf010600aa18cf010600b118cf010600cc180f030600e0180f0306000719d60b4700131900009301ae1300000e002e1900001b004b1900000e005f19000073008b1900000600eb19cc190600011acc190a00191afe010e00331a00000e00421a00000e00511a000032007d1afe010e00a71a0000c701b21a00000a00be1afe010600cd1ad60b0600d91acf014700ae1300000600241b0f0336004f1b451b4b005e1b00000600881b731b0600a91bcf014700b91b0000f301ae1300000600ff1b0f030a00331cfe010e00581c00000600801ceb021200d11cfe010e00121d00000e001b1d00000a00421dfe010a00531dfe010a00621dfe015300aa1d00000e00071e000012006f1efe010a008b1efe010a00a51efe011200ab1efe010600be1ecf012e00ff1e00003a00601f00000600bf1fd60b0600cb1fcf0106001520db0806006020db0806006f20cf010e009d2000000e00a32000000e00ac2000000600be20cf010e002a21000013004f21000073006b21000006008321eb0206008a21eb026b02e92100000e001c2200000e00292200000e00322200000a00c322fe0106003c23cf010a00ba23fe010e006a2400000e00772400003e00b824fe010600eb24cf0106001125cf0106002625cf0106009c25cf012e00f12500000a004f26fe010a008026fe010a00a826fe011e00c926fe011e00cd26fe0142001527fe0142004727fe010a006027fe011e007727fe010a005b28fe010a00c828fe01c702e02800001e001329fe01c300cb2900000a00092af6290a00152af6292200962a870f0a00172bf6290000000001000000000001000100810110002a003f000500010001008101100052003f00050017002e008101100060003f000500180030000a0110006f0000000900190034008101100077003f0005001c0035000101100080003f000d0029004400810110008f003f000500290047000101100099003f000d002e004c0001011000a9003f0005003d00550081011000b7003f0005003f00590081011000c3003f0005003f005b0081011000cf003f00050040005e0081011000e0003f0005004300640081011000ee003f0005004400650001011000fc003f000d004a006c00810110000e013f00050055007000010110001c013f000d00580076000b0110002e01000009006c007f008101100035013f0005006f007f008101100040013f0005006f008000010110004c013f000d0072008300810110005c013f0005007e008b00010110006d013f0005008600a200050110007a01000005008f00aa008101100082013f0005009b00b4000101100091013f000d009e00b80001011000a6013f000500ca00d6000b011000bf0100000900db00e00003011000861f00000500e100e20000000000d01f00000500e200e40013010000302000000900e300e40003011000492500000500e300e40003011000472900000500e400e60003011000492500000500e600e800310018020a00110035020d0011003b02110011004102110011004b02140011005202140011005802140011005e02140011006b02170011007202170011007902170011008602170011009302170011009f0214001100a90214001100b40214001100d1021a001100dd021400310007031e00310035032200110044032a00310050031e0031006605bc00310073051e000600a00517000600a50514000600ab0514005180c405de001300ca05e7001300d205ea00110035020d0011003b0211001100d905ee001100de0514003100f205f30031000a06fc0011000f06050111001606090111002106170011006b0217001300ca05e70013009006e7001300990614001300d20530011600350617000600bf060d000600c50611000600990614000100d00634010100f9063801010007073c0101000c07400103001607440121002107480101002707e70001003007e700010047074c013100c405de0031005507bc0001005b07500101008907e70001008e0714001100ba071a001100eb0779011100210617001100f20781015180c405de003100c405de0031003208af0131009d07af0131003808af0111004508b30116003506170006006b08e7000600bf060d0006007508d00106007c082a000600c50611002100d905d40121009608dc0121009e08e4010100a60814000100ac0814000100ba08090111004508f10116001e04170016002c0417000600bf060d000600c506110006006b08fd0106000609fd0106000e09020206001309090131001a09af01310023091e0021002909070221003509070221003f090e02210048091602210050091e0201005709090101006009140001006a0914000100de05140001007409260211004823c80f11008923d70f0600a9092a000600af0917000600b4090901110045083b021600ca0514001600350617000600bf060d000600c506110006006b08fd010100ca093f020100d60917000100e80944020100ee0950010100f809e7000100fc0909010100d905090121000d0a49020100390ae7005680420a170051804e0a17005180560a17005180610a17003100c405de0031006c0aaf013100730aaf013100780a1e002100230bbc0321002a0b0d002100310b440121003b0211002100350bc10321003c0bca032100450b090101007e0be7000100940b17003100b10bf3033100bd0b1e003100c70b17002100d00bbc03210007073c012100350211002100f50b07042100ff0b14002100030c0a0001000c0c0a000100180ce7000100210ce7001600ca05140016003506170011004508270451807c0c09015180870c09010600bf060d000600c50611000100930cbc0301009c0cbc030100a20c3b040100bb0c3f040100c60ce7000100d80ce7000100de0ce7002100ec0c44040100f30ce7000100100d480401001b0de70001002b0de7000100440d4d043100520d1e000100670d520401006e0d520401007b0d170021008d0d57042100950d5f042100a20d5f042100aa0d66040100b80d17000100c00d09010100ca0d09010100e10d6d0421003f0e850401006e0e8e040100790e8e040100840e8e0401008e0e8e040100990e8e040100a60e8e040100af0e8e040100bb0e8e040100c80e8e040100d40e8e040100df0e93040100eb0e93040100f90e930411008923ee123100c405de003100610f1e003100660f1e0031006c0f1e003100710f1e000100830fd50401009d0fda040100c50fdf040100d90fe4040100de0fe4040100e40fe9040100ee0fe90401001a10ed0401002010ed0401002b10e70001003310e70001004010e70006009910520406009d1052040600a11052040600a71052040600ac1052040600b5102a000600991f810113014c20380d0600230bbc030600230be70006005a29270406001212b91450200000000096005b032e0001009c20000000009600640332000100e8200000000096006e03360001004c2100000000960075033600010055210000000096007e033a000100602100000000960097033f0002007821000000009600a503450003000c22000000009600af03320006002422000000009600ba03320006003c22000000009600ca03320006005322000000009600d703360006005c22000000009600e2032e0006007422000000009600ef03320006008b22000000009600fd0336000600942200000000960009042e000600ab22000000009600140436000600b4220000000096001e0432000600cc220000000096002c0432000600e42200000000960039042e000600fb2200000000960043043600060004230000000096004c04360006000d23000000009600580436000600182300000000960063044d000600c0230000000096006d0432000a00d8230000000096007c0432000a00ef23000000009600880436000a00f823000000009600920456000a0074240000000096009d0432000d008c24000000009600ac045e000d005c25000000009600b804680012000026000000009600c904560016007c26000000009600df04720019009826000000009600ef047d001c00b026000000009600050582001c00cc26000000009600150545002000c8270000000096001b055600230088280000000091002d058d0026000c29000000009100360593002700a42a0000000091003d0599002800d42a00000000910044059f002a00502b0000000091004a05a5002b00ac2b000000009600530593002d0028350000000091005805ad002e0080360000000091006005b4002f00ac37000000009118c4173600310014380000000096006d05c0003100ec3b000000009118c41736003300483c0000000096008b05c7003300e03d0000000096006d05d100340068400000000096009a05930035008940000000009118c41736003600a640000000008618b105d7003600c0400000000096002b0632003900d840000000009600350632003900ef400000000096003c0636003900f84000000000960041060c01390098410000000093004e0636003a008042000000009600550693003a00c0430000000091005d0612013b00f843000000009100a00517013c005c4400000000910044051d013d009c44000000009100630636003e0038450000000091006d0636003e006048000000009300530536003e00804a000000009600600523013e00304d00000000960075060c0141002a4f000000009118c41736004200544f0000000081007f062c014200a04f00000000810086062c014200c64f000000008618b1052c014200ce4f0000000096003c0636004200e44f000000009600a4063a0042001850000000009600af063f0043005450000000009600b80693004400fa50000000009118c417360045000c510000000081006507540145009c510000000081007f062c014500f8510000000081006e072c014500b052000000008300af0658014500845300000000810076075e014600f4540000000081007d072c0147003c5c00000000810086062c014700cd5c000000008618b1052c0147006c5c000000009118c41736004700e45c000000008600960764014700345d0000000086009d0754014900695d000000008600a5072c014900735d000000008618b1052c0149007c5d000000009600ab076a014900ac5d000000009600b50770014b000c5e000000009600c30772005000985e000000009600cb077d005300b85e000000009600d0078200530028600000000096002b06320057004060000000009100f907890157007c600000000091000d088e015800086200000000960055063200590094660000000096001708940159007868000000009118c41736005e00c8680000000096001d089f015e00e86a0000000093002108a8016100206b0000000096002b0632006200086c0000000096004c08b7016200b46d0000000096003c0636006400f06d0000000093005808be016400286e0000000093006308c6016600b86e000000009118c41736006900546f000000008600c3072c0169007c6f0000000081007f062c0169003475000000008100bf08ec0169008275000000008618b1052c016a00ac75000000009600c3082e006a00f475000000009600c90836006a0040760000000096004c0436006a007876000000009600580436006a00b076000000009600d108f5016a006b78000000009118c41736006d008478000000008600c3072c016d00d0790000000091007d092b026d00087a0000000081007f062c016d002c7f0000000081008a092c016d00a08100000000810097092c016d00c083000000008618b1052c016d0064810000000091002223c20f6d0084810000000091006f23d10f6e008883000000009118c41736006f002484000000009600ba0931026f005c840000000096003c06360075009084000000009600b8060c0175007c85000000009118c417360076008885000000008600c3072c01760094860000000081006d052c017600f886000000008100170a2c01760028890000000081002c0a53027600af89000000008600310a2c017800bc890000000081006e072c017800308b00000000810086062c0178003a8b000000008618b1052c017800508b000000009600930a1f037800b08b0000000096009d0a270379001c8c000000009300a50a2e037a00408c000000009100aa0a36037b00788c000000009600af0a3e037d00988c000000009600af093e037e00b88c000000009600b40a45037f00e48c000000009600ba0a4d038000308d000000009600c20a3e038200508d0000000096002d053e038300908d000000009600ca0a55038400c88d000000009600d20a5b0385003c8e000000009600dd0a5b038700888e000000009600e20a64038900388f000000009600e80a64038b00908f000000009600f30a6d038d00b38f000000009600fa0a7a039100c08f000000009600fa0a8b0395000092000000009600060b990398009c93000000009600a50764039a00f493000000009600170ba2039c00c0940000000096001e0bac039e008899000000009118c4173600a100109a0000000086084e0b5401a100279a000000008108570bd203a100309a000000008608600bd703a200479a0000000081086b0bec01a200509a000000008618b105db03a300bc9c000000008100760b5401a6004c9d00000000860053052c01a600909f0000000086006e032c01a6000ca00000000096004c08fd03a600e4a0000000008608290c0c04a800fca0000000008608330c5401a80024a10000000086083e0c5401a8007ca1000000008608480c5401a800e0a1000000008618b1051204a8008ca3000000008100540c1b04aa00f8a30000000081006e072c01ac0060a40000000086003d052c01ac0082a4000000009118c4173600ac00b4a40000000096004c080c01ac00a5a50000000096003c063600ad00b0a5000000009300740c2b04ad00e8a5000000009118c4173600ae00f4a5000000008100760b5401ae0078a6000000009100e80d7204ae0028a70000000081007f062c01ae0010ab000000008100f10d2c01ae006cab000000008100170a2c01ae0090ab000000008100fe0d7604ae0038ac000000008100030e2c01b00030af000000008100100ed203b000a0b0000000009100a0055503b100c8b00000000081001a0e2c01b20006b2000000008100200e2c01b2001cb200000000810086062c01b200a8b2000000008100310e7e04b20000b30000000081000c0f9804b30044b3000000008100120fa104b400b4b3000000008100170fac04b7003cb5000000008100230f2c01bb0058b80000000081002f0f2c01bb00b8ba000000008100350fbe04bb00c8ba0000000081003a0fc504bc0048bb000000008100420f2c01be00e4bd000000008100500fcb04be0028c3000000008100550fd004bf00f8c3000000008618b1052c01c000c4a6000000008100b8252c01c000e4ab0000000091000c26e612c0000cac0000000081001f261a0dc200b4bc0000000081006f292c01c4000cbd0000000081007a292c01c400d8c3000000009118c4173600c40060c400000000960049107204c400a4c400000000860852105401c400d8c400000000860060107e04c400d0c80000000091003208f204c5002cc900000000860055062c01cb00a4c900000000860067102c01cb009cca00000000860076102c01cb00fcca00000000860087102c01cb0040cc000000008618b1052c01cb00b4cb000000009118c4173600cb0048cc000000008618b1050005cb00a0cc0000000086006e070005cc009c61000000008618b1052c01cd00a461000000008600a51f1a0dcd003d94000000008618b1052c01cf0048940000000086005c257011cf00aabc000000008618b1052c01d1005cbd00000000860064292c01d100c1c4000000008618b1052c01d100c9c400000000860085292c01d10000000100bb10000001000c07000001002a0b00000200bb1000000300c410000001002a0b00000200cd1000000300d21000000400c410000001002a0b00000200d91000000300c410000001002a0b00000200d91000000300de1000000400e31000000500c410000001002a0b00000200e91000000300ee1000000400c410000001002a0b00000200f61000000300c41000000100f61000000200230b00000300e91000000100fd1000000200230b00000300e910000004000311000001002a0b00000200cd1000000300c410000001002a0b000002000a1100000300c410000001001411000001001711000001001d11000002002211000001002a11000001002a11000002002c11000001002a11000001002a11000001002a11000002003211000001002a11000002003811000001003f11000001002a0b000001002a0b00000100d910000002001a10000003004611000001002a0b000001002a0b000001001d11000001004c11000001004c11000001002a0b00000200ff0b000003002c11000001002a0b00000100bb10000001000c07000001002a1100000100f61000000100f610000001005011000002005511000001005d11000002006411000001002707000002005d11000003006411000004006a1100000500701100000100f61000000200230b00000300e91000000100fd1000000200230b00000300e91000000400031100000100d910000001007202000001002a0b00000200d91000000300de10000004002c1100000500e310000001002a0b00000200e91000000300ee10000001002a11000001002a1100000200d910000001002a11000002007e11000001002a11000002007e11000003008411000001008811000001002a1100000200cd1000000300d210000001003a2300000100872300000100cd10000002008f11000003009711000004009e1100000500a61100000600d210000001002a1100000100b61100000200bb11000001002a0b00000100d00b00000100d00b00000100d00b00000200ff0b00000100d00b00000100d00b00000100d00b00000100d00b00000200e91000000100d00b00000100d00b00000100e91000000100d00b000002002a0b00000100d00b000002002a0b00000100d00b000002002a0b00000100d00b000002002a0b00000100d00b00000200230b000003002a0b00000400e91000000100d00b00000200230b000003002a0b00000400c11100000100d00b000002002a0b00000300c11100000100d00b000002002a0b00000100d00b000002002a0b00000100d00b00000200230b00000100230b000002002a0b00000300350b00000100461100000100461100000100230b000002002a0b00000300350b00000100d00b000002002a0b00000100d00b000002002a0b00000100c71100000200551100000100350200000100ce1100000100d00b10100200d71100000100d71100000100e910000001004b0200000100e11100000100a71000000200e11110100300e71100000100ec11000002009c0c00000300f31100000400fa1100000100fe1100000100031200000200091200000100141100000100ff0b00000100b31f00000200b51f00000100b31f00000200b51f000001001212000001001a12000002001c12000003002312000004002512000005002712000006002d12000001001a12000001001a1200000100b31f00000200b51f00000100b31f00000200b51fa101b105cb04a901b1052c01b101a7120905b101ad1210050c00a5072c01b901b105ec01c101b105ec01c901e5124605c901f5124a05d90107135005e1011b135605390023136d05e901b105ec01390045137505e10155137a05e1015e138005c9016713860571006f138c05e10155139005c90176139605f9018813a105b9008813a705b900a013ac051400b913be051c00c713d1050102d313d605c901f213da05b900f913e30571002313e80519028813f00519021b14f60571002214fd0549002d14fd05190140140106210259140706f9016e140d0601027e141700c901761317061c0085145401390287102c015100231209014102a11436065100251209015100a71409014902ae143b065102bc1440060900c7144a065902d71450062100e3140d005902f1145706b900ff14fd0551020b155401510212155401210220156106610242156606690288136e06690257157406d10061157a0659026e158506290283159d06c9017613a30679028813ab067902a315b1068102b41554018102c31561065100d115b7065100d815bc068102e415fd055902f015d7031902f915c5060c00b913be052400c713d10589021f16140049002716da0689022f161400240085145401b9003d16540149004616d60549004c16610651005816b70651006216e00691027816d70399028e16100729029616160721029c166106290262161f075100a816b706a102dc162907a902e4166106a902ef166106a102f9163a0769020517560721011217540119021a17630749002717670789023017140049001d086c0749003d17730789024917140051005717b70689026017140089026f171400d10040140106210279177307a90079177307a90086177307a90099177307b902bc172c010900b1052c01c102e2179407c102f4179d070c00b1052c0151020318a507d9022318ab07d1023518b007e1028813b6072c00b1052c01e1025e18c4072c006e18cb072c00721846052c00b913be053400c713d105d1027c18da07340085145401c9017613e5073c00b1052c0121009218f2074400b1052c013c00b913be054c00c713d10559022313570644006e180e084c00851454014902a41814085400b1052c010103c01862085c00b1056f086400b91381086c00c713d1055c00ee1893084902fa189c085c00fe18a2085400ee1893085400fe18a20819038514540154002319aa087400b913be087c00c713d2087c00851454015c002319aa088400b913be088c00c713d2088c00851454019400b1052c019c00b1056f08e10238192509a400b913be05ac00c713d105290040191a0031005619410939036a194609410378192509e100811914009c006e180e08e1007e141700e1009819500994006e18cb07ac00851454019400721846053103a71909013103b1190901e902c61909014902fa1855095103b1058c09d100b105ec01d1000c1a7a066103251a72046903381a72047901381a72047103381a720491004a1a72047903881398097903561a54018103831a9e099102961aa3095102c51aa909a1037218460529012319be09a103df1ac409b400a5072c01c9017613d409c9016713e4098902e61a14004900f21aea09c901fc1a890149005715460569025715f00989020a1b14004900121bb00791008813fe09bc002319aa08c400b913be08cc00c713d20891001a1b1d0acc0085145401bc00a5072c01d400b1052c019c00b1052c01b400b913370adc00c7134c0ae400331bd208e4003d1bd105bc00ee1893089100661b610abc00fe18a20899006d1b2a0099007e141700d103941b720a41025e13780ac9017613800ad4006e18cb07dc0085145401bc00c71b860aec00b9139b0af400c713d1059c00d01b0e08f40085145401d400b913be05fc00c713d105bc00d91bb70abc00e21b0e08fc00851454010103e91b6208d4001e0bbe0ad4000b1cc90ac901131ccf0ad400721846051901181c140b5902271c190b49022f1c9c0809005e13d703b400fe18a208b40072184605f903381c2b0bb400ee189308b100411c5401b100491c2c013900f1146d0539005f1c400bc1022313460b39006d1c500bc102761c560b09048b1c5e0b1902921c650b21009f1c840b5102b01c61066900bc1c8a0ba102c61c910ba902da1ca10b1901e71c7a06a902fc1ca70b5100091d6606190161157a06b100251d540119042d1d54015102351dd703b400b1052c01bc00b1052c01c9017613cf0b2904481d10051900b1052c0181035b1de60b39046c1d5401c102f114460b2100781d040ca1008a1d090ca100411c5401f903971d2b0ba100b01d0e0cc9012313140c5100c01dbc065100cf1d6106a900de1d6106a900f11d61064904101e1a0ca1001e1e09015100b105230c5100311e2a0c29023d1e340ca900591407062902471e3d0c2902541e470ca900621e540ca90020156106a1007b1e5b0c1104921e600c59049d1e61066104ae143b06a900b51e660c49022f1c55097104b1052c016900d41ea90c6100e11eae0c3100ee1eb40c3100f41ee7007904b105b90c3100081fbf0c6100b105c40c6100121fae0c39031a1fe7003100261f140029002e1fe10c2900371f2c013100441fee0c39037e14170081048813030d81046d1fd004c901761f090dc901811fd7030401ee1893080103b71f1a0d0401b1052c018904b9132e0d1903c713340d9904b1052c01a10482203d0dc9019220470dc901b6205f0d0401fe18a208d400b105670d0c01b105780dd4001e0b7e0dc901f114140c9c00721846055102cb20cb043100d42054013903e02014003100ed2014003100f720090131000421a70b410215213606e1002021e700d1043421000ed1044221080e21005f215401e1007721300ec102761c3c0ef1005717560e14019c21cb071c016e180e08b104a42109011401b121d105f100b9214605f100bf214605f100c5214605d104d621690ef100d115560ef100a816560ef100e021560ef1005816560ef100d815710eb104ef217a0ed104f7217f0e2401b913be052c01c713d1052c0185145401a1020022980e11040e225401a102dc16b40e11053e22be0e24016e18cb071401721846051401b1052c011c01b1052c012401b1052c01b1044a220f0f34016e180e085902592246053c010b1cc90a4401a5072c013c01a5072c012900730a2c0161006722510f3c01d01b0e0851007222bc065100c521a70b31008122e70029008b2254012900932254014c01ee189308290099222c014c01fe18a208f903a4222b0bb1001b145f0f2900b222640f6900bc22690f3c01e21b0e085902d7228f0f7102e922e7007102f72254013401d01b0e0871020323d00171021023140061006722990f44016e18cb0771021923a00f5401b105780d4401b023e80f5c01b105780d3c01b023e80f4401b913be056401c713d1053c016e18cb076401851454013401721846053401a5072c013401b1052c013c01b1052c014401b1052c014c01b1052c012905c92372042905d1232b0b010188131d100101e02317000901eb2309010901fd230901090111240901090121240901010135242c01290553242f1029055b2434106c01b913370a7401c7134c0a7c013d1bd10511018324d20374018514540109008f24400b1901c7248a106c01df240e0811016c1d54016c016e18a2087c01331bd2086c01a5072c016c01b1052c0179018813bd10c901761fc9104900f21a8605c901fe24d61031000425d001d900f114f0102100e415fd0589021725140049001f25f810d9002313f0105905b105ec012101d41ea90c49001d08c50461003d2503118401b913be058c01c713d1058c01851454019401b91381089c01c713d105410267257a11a401b1052c01ac01b9138108b401c713d105a4016e18cb07bc01b105780da4011e0b7e0d8401b105670da401b913be05c401c713d10561007125b011c40185145401cc01b1052c01f90380252b0bcc016e18cb07cc01b913be05d401c713d105d40185145401a401b105670da401e21b0e08dc01c71b860ae401b105670de401b913be05ec01c713d105dc01e21b0e08ec0185145401dc01ee189308dc01fe18a2082901d01b8b122901d91b7505b1009125ec01f401b105780db100a52598122901fe18500bb100ae25aa12dc01b1052c0139048324d20341018813c6128103c525e60b5102d02573075102db25d2035901b105780d6900e225140bd100e71c7a066905f925df126905072636000103322662089c00a5072c01d400a5072c018401a5072c0149015717f7124902a418fd1284016e18cb07fc01b105780d84011e0b7e0dd400d01b0e08710556267204710562263313690570267204790587262e00790591262e005101b105391369052c0a360071059c262f100402b913be050c02c713d1050c02851454010402a5072c0159018b1c2c016101b105b90c5902b22661136101c026681361016d052c0104026e18cb078905d5267a139105de2680136901b10586136901e826cb0469011f278d1369012d27d20369013a27d203690152279413a905b1059b1369016b27a3136901e416aa13b1058527b01391059327801369019e27a3136901a927c0136901b827c0136901c827aa13b105d527c5136901e427aa136901ee27aa136901fa27aa1369010628aa1369011428aa1369011f28aa137101b10539136901b1052c0189052c28fe1389053628fe1389054a28fe13890565280414890570282e0071017a28fe13890584280a1489058e280a148905a2280a148905b3283a00b905831504148905bd2811148905d0281814b905dc282214c905b105780d8905ef282f148905f6283a0089050929401489050d295b14d105b105ec0169011e296614890529296e148905392936008905960f7d1489056c1d7204890583242f108401b1052c010402b1052c0121029229010621029d2961069101af29c4144901231209019101b929ca1451018726a70b51019126a70b59026e15d0145902c229ec01d905b1052c018101de29e1148101ea29e814e105b105780de905202aee14d1002c2af514490125120901d100432ad20391014d2a221591015b2a22154901b10529159101692a22159101732a22159101812a2215f105a12ad2038901b22aec018901bb2ad2038901d02ac0139901e02a54019901f12a54019901a12ad2039901042bd203f905262b2c019101392bc4149101472bc4149101552bc4149101632bc41408007000e20008000c01e2000e00f8015b020e00fc0186020e000002b7020e000402e8020c00780231040c007c0236040200bd0207050200d90207052e000b003f152e0013004815c3032b0aa40ce3032b0aa40c23042b0aa40c43042b0aa40c63042b0aa40ce1076b09a40c410d2b0aa40c610d2b0aa40c800f2b0aa40ca00f2b0aa40ca1112b0aa40cc1112b0aa40c40142b0aa40c60142b0aa40c80142b0aa40ca0142b0aa40c21192b0aa40c001a2b0aa40c201a2b0aa40c401a2b0aa40c601a2b0aa40c801a2b0aa40c010006000000200015051c052a053005340538053c0541055d0566059c051e06e806450784071a085608e7085b09b609db09f609230ad60a2f0b6b0bb70bd50be00bed0bf80b6f0c9a0c9f0cce0cda0cf30c0e0d270d890dca0dd70de00deb0d130e2a0e360e4f0ec70efd0e070f1a0f3e0f710fa80f031023102b1062109810a710c310d110e010e710fe10281153117f11b8110812371251127612b112bc12cc120a1352137113b713cc13e21348148814a7140215351518000100190003001c0007000000ac0beb0300003506ef0300005f0c21040000650ceb030000e20aeb0300006c0ceb0300008f10eb030200a20003000100a30003000200a40005000100a50005000200ab0007000200ac0009000200ad000b000200ae000d000200d7000f002305b605c805d206bc07d107eb07ff0706085b0868087a088b08b608ca08d708df0818091f092d093409cc09030a0b0a140a310a430a580a920aa70ab00a200d710d5b0e620e890e900e140f370f4a0f580fe00ff30ffb0f45104e1058100c1113111b11211185118d1195119e11a71101122f125e1267126e12901202134113491300620000e200048000000000000000000000000000000000721200000400000000000000000000000100c601000000000000000000000000000000000000e7010000000000000000000000000000000000001d02000000000000000000000000000000000000d506000000000400000000000000000000000100d507000000000400000000000000000000000100cf010000000000000000000000000000000000004d0e000000000100000000000000000000000000870f000000000000000000000000000000000000a40f000000000000000000000000000000000000f90f0000000000000000000000000000000000002d150000000000000000000000000000000000005f1a000000000000000000000000000000000000451b0000000000000000000000000000000000004e1f0000000000000000000000000000000000009724000000000000000000000000000000000000f526000000000500040013001200190018001d001c001e000d0020001f002100170022001b0023001c0075008006770092067500970675005d077500790775007e0775003c0975004b09610193097500200b7500260b75003a0b0902200b0f02ab0b0f0280060f02b10b6101db0b0f02f30b0f0279077500ab0b75004d0d7500530d7500590d61010e0e0902a20e0902260b09024d0d09024b090902a80e0902ae0e6101020f1d039706610118101d0339101d033f106d0392100f024b09e103a6126101b712f7035d071d035d070f022d130f02be14af0492067500db14bd04fc147500be140f022f1561012f1500000000003c4d6f64756c653e0056616c6865696d5265636f76657279537061776e426574615634322e646c6c005265636f76657279537061776e426574615634320056616c6865696d536f6c6f546f6f6c6b69740054726f706879427566667356310054726f706879526573746564563100436f6d666f72740054616d696e6756310054616d696e67447269766572563100426f617446756e563500426f617446756e447269766572563500426f61744a756d70496e70757400426f6174537570706f7274005265706c656e697368563100537061776e436174616c6f6775655631004974656d5175616c6974795631004175746f506c616e7465725631004175746f506c616e74657244726976657200486172766573744c6f6f74563100486172766573744c6f6f74447269766572005469636b6574004c6f6f74506f6c69637900436c65617256696577563100436c65617256696577447269766572004368657374536f727453746f72616765004368657374536f72744a6f620052657175657374004368657374536f7274696e675631004368657374536f7274696e674472697665725631004368657374536f7274496e76656e746f7279427574746f6e004c61796f7574006d73636f726c69620053797374656d004f626a6563740056616c75655479706500556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f7572004761746500617373656d626c795f76616c6865696d00506c61796572006f776e657200776f726c640063686172616374657200616374696f6e00737461746500696e64657800626f61744e6f44616d61676500737461747573007072656661620073756d6d6f6e54617267657400616e696d616c54617267657400737061776e54617267657400737061776e4b696e6400737061776e5374617273006c6f6f74526164697573004974656d44726f70004974656d44617461007175616c6974794974656d0063686f73656e5175616c6974790053797374656d2e5265666c656374696f6e004669656c64496e666f00557365724b65790053797374656d2e436f6c6c656374696f6e732e47656e65726963004c6973746031005a444f0073746f6e657300566563746f72330064657374696e6174696f6e00546f6d62507265666162004765745374617465004765745374617475730043616e63656c0053746f70426f617400536574426f61744f7074696f6e7300576561724e5465617200426f617450726f746563746564005175657565426f617400426f61745374617475730054616d696e67436174616c6f6775650054616d696e675374617475730053746f7054616d696e6700536f7274696e67537461746500536f7274696e675374617475730053746f70536f7274696e6700436c65617253746174650053746f70436c6561720048617276657374537461747573004d61676e6574537461747573004c6f6f7453746174650053746f704c6f6f740053746f70486172766573740053746f704d61676e65740051756575654c6f6f7400506c616e74436174616c6f67756500506c616e745374617475730053746f70506c616e74005175657565506c616e7400537061776e436174616c6f6775650051756575655072656661620051756575654974656d5175616c697479005175657565416e696d616c00496e76656e746f727900507265706172655472616e73666572005072657061726564436f70790048756d616e6f69640044726f705265706c656e697368656400517565756500517565756553756d6d6f6e005a444f4944004964656e746974790053756d6d6f6e0046696e6973680056616c69640054656c65706f7274005469636b004c616e64696e67004272696e6700506f77657273004170706c790054696d654669656c640049456e756d657261626c656031004d6178696d756d436f6d666f7274005368617265004e616d650047726f75700056616c7565002e63746f720042696e64696e67466c61677300466c61677300456e61626c656400447269766572007363616e00637572736f720044696374696f6e617279603200616e696d616c73004d696e696d61700050696e446174610070696e730070696e4d6170006e65787455706461746500636174616c6f67756500436174616c6f677565005374617475730053746f7000456e61626c65486f746b657900486f746b6579005265667265736800436c65616e00436c65617250696e73005075626c6973680054616d6541696d656400557064617465004f6e44657374726f79004e6f44616d6167650047656e65726174696f6e005365744f7074696f6e730050726f746563747300546f67676c65004f776e657200576f726c640053686970007368697000556e697479456e67696e652e506879736963734d6f64756c65005269676964626f647900626f6479005a4e65745669657700766965770077656172005a4e65740053657373696f6e4e6574006a756d707300616972626f726e650064657363656e64696e67005761746572566f6c756d650070726576696f75735761746572004e616d6573006f726967696e616c7300436f6e74726f6c7300526573746f7265004174746163680046697865645570646174650068656c640070656e64696e670053616d706c6500436f6e73756d6500436c6561720044727947726f756e64004c696674007072657061726564005072657061726500436f70790044726f700053797374656d2e436f7265004861736853657460310067726f757073006c6162656c73004d65726368616e740047616d654f626a656374004974656d4c6162656c00537061776e00536574005269676874004d6574686f64496e666f00506c61636500526571756972656d656e747300647269766572005374617274005069656365004166666f726461626c6500506c616e7441740043616e63656c6c656400507265666162004f726967696e005175657565603100566563746f7232496e74007669736974656400706c616e74656400636f756e7400636865636b6564506f696e7473006e65787400456e640053746174650053746f70416c6c00436f6e6669677572650053797374656d2e52756e74696d652e436f6d70696c65725365727669636573004973566f6c6174696c650048617276657374004d6f646500526164697573005361766544726f700044726f70730063726f7050726566616273007365656e44726f70730063726f704c6f6f74007469636b657473007069636b6564007363616e54696d650068617276657374656400636f6c6c656374656400736e617073686f740043757272656e7444726f7073004861727665737443726f707300547261636b4861727665737444726f707300506f696e74004974656d00556e74696c00456c696769626c6500456e764d616e00656e7669726f6e6d656e740070726576696f757300456e76536574757000636c6561720064656e73697469657300666f670064656e736974790052656e64657265720072656e646572657273004c61746555706461746500436f6d706f6e656e7400486964650052656c6561736500726573746f72656400536861726564526f75746500526f6c654b6579004974656d5461674b6579004e6574776f726b4b657900416363657373004c6f61640043757272656e74436f6e7461696e657200436f6e7461696e6572004f70656e436865737400497343686573740056696577005265616400526f6c65004974656d730041636365707473004e6574776f726b004974656d4b65790041636365737369626c650042757379005265616479004d616b65536f757263650041737369676e0041737369676e4974656d7300526561737369676e436f6e74656e7473004c696e6b656400536f727400736f7572636500706c61796572006e6574006c6f6164656400726571756573747300646561646c696e65006765745f446f6e65007365745f446f6e65006765745f537461747573007365745f5374617475730053657373696f6e003c446f6e653e6b5f5f4261636b696e674669656c64003c5374617475733e6b5f5f4261636b696e674669656c6400446f6e65006f75747374616e64696e670046756e6374696f6e7300526573706f6e73650063686573740053797374656d2e436f6c6c656374696f6e73004944696374696f6e6172790066756e6374696f6e73006b6579006f726967696e616c007265706c6163656d656e7400616e737765726564006772616e746564006765745f4368657374006765745f44656e696564006765745f5265616479006765745f57616974696e67004f6e526573706f6e73650043686573740044656e6965640057616974696e6700526574697265640050616e656c57696474680050616e656c4865696768740073656c656374656400686f76657200736f72744a6f6200506c61796572436f6e74726f6c6c657200636f6e74726f6c6c657200636f6e74726f6c6c6572456e61626c65640070616e656c0066726f6d496e76656e746f7279006e617469766500637572736f7256697369626c6500437572736f724c6f636b4d6f646500637572736f724c6f636b00637572736f725265717565737465640063616d657261436170747572650047616d6543616d657261006361707475726543616d657261004d6f7573654361707475726500566563746f7232007363726f6c6c007374617475735363726f6c6c006c6173745374617475734d6573736167650073616d706c65730064657374696e6174696f6e730063686f696365730073656c65637465644974656d73006d657373616765006e657874486f766572006e6578744e6174697665417474656d707400526563740077696e646f770047616d654d656e750052656c656173654d6f757365004f70656e005265667265736843686573740053686f7750616e656c00436c6f7365004f6e44697361626c6500416374696f6e0041637400546578747572653244007468656d65546578747572657300556e697479456e67696e652e494d4755494d6f64756c65004755495374796c650070616e656c5374796c65007469746c655374796c6500626f64795374796c65006d757465645374796c650073656374696f6e5374796c6500726f775374796c6500627574746f6e5374796c65007072696d6172795374796c65007374617475735374796c650062616467655374796c6500636172645465787475726500626f72646572546578747572650073686164655465787475726500436f6c6f7200536f6c6964005465787400427574746f6e5374796c6500456e737572655468656d65004f6e47554900436172640048656164696e6700537461747573416e644261636b004472617700446973706c61794974656d0054616b6500537461636b00526f6f74004472616700496e76656e746f72794775690067756900556e697479456e67696e652e554900427574746f6e00627574746f6e00556e6974792e546578744d65736850726f00544d50726f00544d505f54657874006c6162656c00526563745472616e73666f726d0074616b6500737461636b00736176656454616b65007361766564537461636b00556e697479456e67696e652e55494d6f64756c650043616e76617347726f75700067726f7570006f776e656447726f757000626c6f636b656400696e74657261637461626c65007261796361737473004472616767696e67006765745f417661696c61626c6500456e7375726500426c6f636b496e76656e746f727900556e626c6f636b496e76656e746f727900446973706f736500417661696c61626c65006d696e006d6178007069766f740073697a6500706f736974696f6e006c6f63616c006e6f44616d61676500776f726c64486578006d6f646500726164697573006e616d65006b696e64007374617273006974656d007175616c69747900746172676574006163746f7200616d6f756e74007461726765744865780069640061646d696e00746578740073756363657373007000706f696e740073746f6e650063686f696365007069656365730076616c7565007a646f00646f776e00616c6c6f7765640067726f756e64007761746572006572726f7200766572746963616c537065656400706965636500706f7300726561736f6e006368656174656400706c6163656400686173526f6f6d0064697374616e636553717561726564006d697374006669656c64006974656d730073656e646572007265746972696e6700696e76656e746f727900636f6c6f7200626f6c64006e6f726d616c0061637469766500696e6b0072656374007469746c65007375627469746c6500636c69636b6564007200706172656e74007800790077696474680068656967687400436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d5265636f76657279537061776e426574615634320053797374656d2e546872656164696e67004d6f6e69746f7200456e746572004578697400496e76616c69644f7065726174696f6e457863657074696f6e00417267756d656e74457863657074696f6e00537472696e67006765745f4c656e677468004279746500537562737472696e6700436f6e7665727400546f4279746500426974436f6e76657274657200546f496e743634006f705f457175616c697479004d697373696e674669656c64457863657074696f6e0047657456616c75650055496e74313600476574427974657300546f537472696e67005265706c616365006765745f494400436f6e636174005a526f75746564527063006765745f696e7374616e636500506c61796572496e666f00476574506c617965724c69737400456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e74006d5f636861726163746572494400537472696e67436f6d70617269736f6e00457175616c73006765745f4c6f63616c506c617965724368617261637465724944005a444f4d616e004765745a444f006765745f557365724944004765744f776e6572005472616e73666f726d006765745f7472616e73666f726d005175617465726e696f6e006765745f726f746174696f6e00426f6f6c65616e00496e766f6b65526f75746564525043006d5f6e616d65004d6f76654e6578740049446973706f7361626c650053696e676c650049734e614e007a004d61746800416273004368617261637465720054656c65706f7274546f005265666572656e6365457175616c73006f705f496d706c69636974006d5f6c6f63616c506c61796572006f705f496e657175616c69747900476574576f726c645549440049734465616400497354656c65706f7274696e67006765745f706f736974696f6e00617373656d626c795f7574696c73005574696c730044697374616e6365585a005a4e65745363656e650047657450726566616200476574436f6d706f6e656e7400496e7374616e7469617465005069636b61626c65006765745f6964656e746974790047616d6500506c6179657250726f66696c6500476574506c6179657250726f66696c6500486176654465617468506f696e74004765744465617468506f696e74006765745f7570006f705f4164646974696f6e00476574506c617965724944006765745f6e616d6500476574416c6c5a444f7357697468507265666162497465726174697665005a444f5661727300735f6f776e6572004765744c6f6e6700735f74696d654f664465617468004973536572766572006d5f75696400476574506f736974696f6e006765745f7269676874006f705f4d756c7469706c7900457863657074696f6e006765745f4d657373616765004c617965724d61736b004765744d61736b0045756c6572006765745f666f7277617264006765745f646f776e0050687973696373005261796361737448697400517565727954726967676572496e746572616374696f6e0052617963617374006765745f6e6f726d616c006765745f706f696e7400436865636b5370686572650046696e64496e7374616e6365004973496e5573650047657453657373696f6e4944005365744f776e657200735f737061776e506f696e7400536574506f736974696f6e00735f626f647956656c48617368006765745f7a65726f00735f626f64794156656c4861736800735f76656c48617368007365745f706f736974696f6e007365745f6c696e65617256656c6f63697479007365745f616e67756c617256656c6f63697479005a53796e635472616e73666f726d0053796e634e6f77002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744669656c640053454d616e0047657453454d616e00537472696e67457874656e73696f6e4d6574686f647300476574537461626c6548617368436f64650052656d6f7665537461747573456666656374004f626a6563744442005374617475734566666563740047657453746174757345666665637400416464006765745f436f756e740041646453746174757345666665637400496e74333200476574506c6179657273496e52616e676500526f756e6400446f75626c6500537472696e67436f6d7061726572006765745f4f7264696e616c0049457175616c697479436f6d706172657260310049456e756d657261746f7260310054727947657456616c7565004d6178007365745f4974656d0049456e756d657261746f720056616c7565436f6c6c656374696f6e006765745f56616c7565730053455f526573746564006d5f6974656d73006d5f6974656d446174610053686172656444617461006d5f7368617265640050696563655461626c65006d5f6275696c64506965636573006d5f706965636573006d5f636f6d666f727400436f6d666f727447726f7570006d5f636f6d666f727447726f7570006d5f6261736554544c006d5f54544c506572436f6d666f72744c6576656c006d5f74746c0053797374656d2e52756e74696d652e496e7465726f705365727669636573005374727563744c61796f7574417474726962757465004c61796f75744b696e6400416464436f6d706f6e656e74004170706c69636174696f6e006765745f6973466f6375736564004d656e7500497356697369626c6500436f6e736f6c650049734f70656e004368617400486173466f63757300556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e446f776e0047657442617365457863657074696f6e004d657373616765487564004d6573736167655479706500537072697465004d6573736167650049436f6c6c656374696f6e00417272617900436f7079546f00735f74616d65644e616d6500476574537472696e670049734e756c6c4f72456d70747900735f74616d656400476574426f6f6c0052656d6f766550696e004b657956616c7565506169726032006765745f56616c7565006765745f4b65790053706c6174666f726d00506c6174666f726d5573657249440050696e547970650041646450696e006d5f706f730053797374656d2e476c6f62616c697a6174696f6e0043756c74757265496e666f006765745f496e76617269616e7443756c747572650049466f726d617450726f7669646572004b6579436f6c6c656374696f6e006765745f4b65797300436f6e7461696e73006765745f4974656d0052656d6f7665006765745f4f7264696e616c49676e6f7265436173650049436f6d7061726572603100546f4172726179004a6f696e006765745f67616d654f626a6563740044657374726f79004d696e0054696d65006765745f74696d650049734f776e657200436c61696d4f776e65727368697000426173654149006765745f4669656c64547970650053657456616c7565004765744d6574686f64004d6574686f644261736500496e766f6b6500466f72636553656e645a444f00476574486f766572437265617475726500476574457965506f696e740047657441696d4469720052617963617374416c6c00436f6c6c69646572006765745f636f6c6c6964657200476574436f6d706f6e656e74496e506172656e74006765745f64697374616e63650044697374616e63650054616d6561626c65004d6f6e73746572414900497356616c696400497354616d656400476574486f7665724e616d65004465627567004c6f675761726e696e67004b6579436f6465004765744b6579004265686176696f7572006765745f656e61626c656400476574436f6e74726f6c6c656453686970004765744c6f63616c53686970006765745f666978656444656c746154696d6500537065656400476574537065656453657474696e670050726f6a6563744f6e506c616e65006765745f6e6f726d616c697a6564006765745f6c696e65617256656c6f63697479006765745f776f726c6443656e7465724f664d61737300466c6f6174696e670047657457617465724c6576656c006d5f77617465724c6576656c4f6666736574004d6f7665546f776172647300416e676c6541786973004c6f6f6b526f746174696f6e00526f74617465546f7761726473004d6f7665526f746174696f6e00426f78436f6c6c69646572006d5f666c6f6174436f6c6c6964657200426f756e6473006765745f626f756e6473006765745f6d696e004d6174686600466f7263654d6f646500416464466f7263650054687265616453746174696341747472696275746500476574496e76656e746f727900436f6e7461696e734974656d00436c6f6e65006d5f657175697070656400566563746f723269006d5f67726964506f73004164644974656d006d5f71756573744974656d006d5f737461636b0044726f704974656d004f6e506c6179657244726f700047657457656967687400617373656d626c795f6775697574696c73004c6f63616c697a6174696f6e004c6f63616c697a650053746172747357697468005472696d003c3e635f5f446973706c6179436c617373320066726573684c6162656c73003c526566726573683e625f5f300061006200436f6d706172650049456e756d657261626c650043686172003c50726976617465496d706c656d656e746174696f6e44657461696c733e7b37453831313034312d313841432d344446312d383533352d3942453542433938453645387d00436f6d70696c657247656e657261746564417474726962757465005f5f5374617469634172726179496e69745479706553697a653d360024246d6574686f643078363030303035622d310052756e74696d6548656c706572730052756e74696d654669656c6448616e646c6500496e697469616c697a65417272617900496e6465784f66416e7900506c616e74004d696e65526f636b004d696e65526f636b3500496e6465784f6600436f6d70617269736f6e6031005365744c6576656c004973457175697061626c65006d5f6d61785175616c697479006d5f7175616c697479006d5f6475726162696c697479004765744d61784475726162696c697479004973496e66696e697479006d5f656e61626c6564004865696768746d61700046696e644865696768746d617000497343756c7469766174656400526571756972656d656e744d6f6465004e6f436f7374436865617400526571756972656d656e74006d5f7265736f75726365730042696e64657200506172616d657465724d6f64696669657200456e7175657565006d5f67726f775261646975730044657175657565006765745f78006765745f79006765745f7371724d61676e697475646500476574486569676874006765745f6c6566740042696f6d65006d5f62696f6d650047657442696f6d65004f7665726c6170537068657265006765745f69735472696767657200446573747275637469626c6500547265654261736500507269766174654172656100436865636b416363657373006d5f67726f776e5072656661627300476574496e7374616e636549440043616e4164644974656d006f705f5375627472616374696f6e006d5f63686561746564004973506965636500496e54617200526571756573744f776e006765745f64656c746154696d650043616e5069636b7570005069636b75700046696e644f626a65637473536f72744d6f64650046696e644f626a65637473427954797065006d5f6861727665737461626c650043616e42655069636b6564006d5f6974656d507265666162006d5f616d6f756e7400496e746572616374003c547261636b4861727665737444726f70733e625f5f310074005072656469636174656031004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c656761746533003c547261636b4861727665737444726f70733e625f5f320064004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c6567617465340052656d6f7665416c6c0052656e64657253657474696e6773006765745f666f67006765745f666f6744656e73697479006d5f6465627567456e76006d5f666f6744656e736974794e69676874006d5f666f6744656e736974794d6f726e696e67006d5f666f6744656e73697479446179006d5f666f6744656e736974794576656e696e6700466f726365496e7374616e74456e7669726f6e6d656e74537769746368007365745f666f67007365745f666f6744656e73697479005061727469636c654d697374004d697374456d6974746572007365745f656e61626c6564004765745479706500556e697479456e67696e652e5061727469636c6553797374656d4d6f64756c65005061727469636c6553797374656d00476574436f6d706f6e656e7473496e4368696c6472656e00436f6e7461696e734b657900537472696e6753706c69744f7074696f6e730053706c6974006d5f64726f7050726566616200496e74363400735f696e55736500476574496e74004d697373696e674d6574686f64457863657074696f6e00476574416c6c4974656d73003c3e635f5f446973706c6179436c61737331003c536f72743e625f5f3000436f6d70617265546f004d6f76654974656d546f54686973006765745f756e7363616c656454696d6500556e726567697374657200416374696f6e603200526567697374657200496e766f6b65525043003c5570646174653e625f5f30004765744b6579446f776e005365744d6f76654469720053657452756e00476574486f7665724f626a656374005a437572736f72007365745f4c6f636b53746174650053686f77003c5265667265736843686573743e625f5f32003c5265667265736843686573743e625f5f33006765745f43757272656e7443756c7475726549676e6f72654361736500437572736f72006765745f76697369626c65006765745f6c6f636b5374617465006765745f49735265717565737465640053637265656e006765745f7769647468006765745f686569676874007365745f76697369626c650048696465466c616773007365745f68696465466c61677300536574506978656c0047554900475549536b696e006765745f736b696e006765745f6c6162656c007365745f666f6e7453697a6500556e697479456e67696e652e5465787452656e646572696e674d6f64756c6500466f6e745374796c65007365745f666f6e745374796c65007365745f776f726457726170007365745f72696368546578740054657874416e63686f72007365745f616c69676e6d656e7400526563744f6666736574007365745f70616464696e67004755495374796c655374617465007365745f74657874436f6c6f72006765745f627574746f6e007365745f626f72646572007365745f66697865645769647468007365745f6669786564486569676874006765745f6f6e4e6f726d616c007365745f6261636b67726f756e64006765745f686f766572006765745f6f6e486f766572006765745f666f6375736564006765745f6f6e466f6375736564006765745f616374697665006765745f6f6e416374697665006765745f636f6c6f72006765745f6261636b67726f756e64436f6c6f72006765745f636f6e74656e74436f6c6f72004d6174726978347834006765745f6d6174726978006765745f6465707468006765745f7768697465007365745f636f6c6f72007365745f6261636b67726f756e64436f6c6f72007365745f636f6e74656e74436f6c6f72007365745f6465707468007365745f6d61747269780054657874757265004472617754657874757265005452530057696e646f7746756e6374696f6e0057696e646f77004272696e6757696e646f77546f46726f6e7400426f78004c6162656c00475549436f6e74656e740043616c6348656967687400426567696e5363726f6c6c5669657700456e645363726f6c6c56696577003c3e635f5f446973706c6179436c61737361003c3e345f5f74686973003c447261773e625f5f37003c447261773e625f5f35003c447261773e625f5f36003c456e737572653e625f5f30006765745f706172656e74006765745f6c6f63616c506f736974696f6e006765745f7069766f74006765745f72656374007365745f6e616d6500427574746f6e436c69636b65644576656e74007365745f6f6e436c69636b006765745f6f6e436c69636b00556e697479456e67696e652e4576656e747300556e697479416374696f6e00556e6974794576656e74004164644c697374656e657200476574436f6d706f6e656e74496e4368696c6472656e00536574416374697665007365745f616e63686f724d696e007365745f616e63686f724d6178007365745f7069766f74007365745f73697a6544656c7461007365745f616e63686f726564506f736974696f6e0053656c65637461626c65007365745f696e74657261637461626c65007365745f74657874007365745f656e61626c654175746f53697a696e67007365745f666f6e7453697a654d696e006765745f696e74657261637461626c65006765745f626c6f636b735261796361737473007365745f626c6f636b73526179636173747300556e6974794576656e74426173650052656d6f7665416c6c4c697374656e657273006765745f616e63686f724d696e006765745f616e63686f724d6178006765745f73697a6544656c7461006765745f616e63686f726564506f736974696f6e00003541006e006f007400680065007200200061006300740069006f006e002000690073002000700065006e00640069006e0067002e00002949006e00760061006c0069006400200062006f006100740020006f007000740069006f006e002e00003d49006e00760061006c006900640020006c006f006f007400200061006300740069006f006e0020006f00720020007200610064006900750073002e00002f49006e00760061006c0069006400200073007000610077006e002000630061007400650067006f00720079002e000055430068006f006f0073006500200030002c002000310020006f00720020003200200073007400610072007300200066006f007200200063007200650061007400750072006500730020006f006e006c0079002e00002d430068006f006f007300650020007100750061006c00690074007900200031002d0031003000300030002e00012f49006e00760061006c0069006400200074006f006f006c006b006900740020007200650071007500650073007400004d5100750065007500650064003a002000720065007400750072006e00200074006f002000560061006c006800650069006d00200061006e006400200075006e00700061007500730065002e00003741006e006f007400680065007200200072006500710075006500730074002000690073002000700065006e00640069006e0067002e00003149006e00760061006c0069006400200070006c00610079006500720020006900640065006e0074006900740079002e00004f50006c00610079006500720020006e006500740077006f0072006b0020006900640065006e00740069007400790020006c00610079006f007500740020006300680061006e006700650064002e0000032d000101003b4e006500740077006f0072006b00200072006f007500740069006e00670020006900730020006e006f0074002000720065006100640079002e00002d530065006c00650063007400200061006e006f007400680065007200200070006c0061007900650072002e00007d540061007200670065007400200070006c006100790065007200200068006100730020006e006f0020006e006500740077006f0072006b0020006f0077006e00650072002e0020005200650066007200650073006800200070006c0061007900650072007300200061006e0064002000720065007400720079002e00001d5200500043005f00540065006c00650070006f007200740054006f00002f530075006d006d006f006e00200072006500710075006500730074002000730065006e007400200074006f0020000080a32e002000410073006b0020007400680065006d00200074006f00200063006f006e006600690072006d0020006100720072006900760061006c003b002000740065006c00650070006f0072007400200063006f006f006c0064006f0077006e002f006c006f006100640069006e0067002000630061006e002000640065006c006100790020006f00720020006400650063006c0069006e0065002000690074002e00008087530065006c0065006300740065006400200070006c006100790065007200200064006900730063006f006e006e006500630074006500640020006f00720020006300680061006e0067006500640020006300680061007200610063007400650072002e0020005200650066007200650073006800200070006c00610079006500720073002e000067440065007300740069006e006100740069006f006e0020006900730020006f00750074007300690064006500200073007500700070006f007200740065006400200077006f0072006c006400200063006f006f007200640069006e0061007400650073002e00006b470061006d00650020006400650063006c0069006e00650064002000740065006c00650070006f00720074002e002000570061006900740020006100200066006500770020007300650063006f006e0064007300200061006e0064002000720065007400720079002e000057540065006c00650070006f007200740069006e0067003a0020006c006f006100640069006e0067002000640065007300740069006e006100740069006f006e0020007400650072007200610069006e002e002e002e000080ab50006c00610079006500720020007200650066006500720065006e006300650020006300680061006e006700650064002000610066007400650072002000710075006500750069006e0067002e002000460069006e0069007300680020007200650073007000610077006e0069006e0067002c0020007400680065006e00200063006c00690063006b0020007200650063006f007600650072007900200061006700610069006e002e000080954c006f00630061006c00200070006c006100790065007200200069007300200075006e0061007600610069006c00610062006c0065002e002000460069006e0069007300680020007200650073007000610077006e0069006e0067002c0020007400680065006e00200063006c00690063006b0020007200650063006f007600650072007900200061006700610069006e002e00006157006f0072006c00640020006300680061006e006700650064002000610066007400650072002000710075006500750069006e0067003b0020007200650063006f0076006500720079002000630061006e00630065006c006c00650064002e000080af50006c0061007900650072002000640069006500640020006f00720020006900730020007300740069006c006c0020007200650073007000610077006e0069006e0067002e0020005700610069007400200075006e00740069006c00200079006f0075002000630061006e0020006d006f00760065002c0020007400680065006e00200063006c00690063006b0020007200650063006f007600650072007900200061006700610069006e002e00005f540065006c00650070006f0072007400200065006e006400650064003b0020006100720072006900760061006c00200063006f0075006c00640020006e006f007400200062006500200063006f006e006600690072006d00650064002e000041410072007200690076006500640020006100740020007200650063006f0076006500720079002000640065007300740069006e006100740069006f006e002e000045460069006e0069007300680020007400680065002000630075007200720065006e0074002000740065006c00650070006f00720074002000660069007200730074002e000073540061006d0069006e00670020007300630061006e00200073007400610072007400650064002e00200052006500730075006c00740073002000610070007000650061007200200069006e0020007400680065002000540061006d0069006e0067002000770069006e0064006f0077002e000035540061006d0069006e00670020006d006100700020006d00610072006b006500720073002000680069006400640065006e002e00000d480061006c0064006f007200000d480069006c00640069007200001142006f00670057006900740063006800003957006f0072006c00640020007000720065006600610062007300200061007200650020006e006f0074002000720065006100640079002e000051520065006700690073007400650072006500640020006d00650072006300680061006e0074002000700072006500660061006200200075006e0061007600610069006c00610062006c0065003a0020000043470061006d006500200064006900640020006e006f0074002000630072006500610074006500200074006800650020006d00650072006300680061006e0074002e00001153007000610077006e006500640020000080852000620065007300690064006500200079006f0075002e0020004e006f0072006d0061006c002000730068006f007000200061006e006400200077006f0072006c0064002d00700072006f006700720065007300730069006f006e00200072006500710075006900720065006d0065006e007400730020006100700070006c0079002e00011b42006c0075006500620065007200720079004200750073006800001b5200610073007000620065007200720079004200750073006800001d43006c006f0075006400620065007200720079004200750073006800001f4c0069006e0067006f006e00620065007200720079004200750073006800000f560069006e0065004100730068000013560069006e00650047007200650065006e00000d42007500730068003000310000214200750073006800300031005f0064006500650070006e006f00720074006800006b5200650067006900730074006500720065006400200070006c0061006e0074002000700072006500660061006200200075006e0061007600610069006c00610062006c00650020006f007200200069006e0063006f006d00700061007400690062006c0065003a002000003750006c006100790065007200200070006f0073006900740069006f006e00200069007300200069006e00760061006c00690064002e00003d470061006d006500200064006900640020006e006f00740020006300720065006100740065002000740068006500200070006c0061006e0074002e00001d200061007400200079006f0075007200200066006500650074002e00003b2000560069006e006500730020006e0065006500640020007300750069007400610062006c006500200073007500700070006f00720074002e0000794e006f0020006400650061007400680020006c006f0063006100740069006f006e0020007200650063006f007200640065006400200066006f007200200074006800690073002000630068006100720061006300740065007200200069006e0020007400680069007300200077006f0072006c0064002e000067430061006e006e006f00740020006900640065006e007400690066007900200079006f0075007200200074006f006d006200730074006f006e006500200070007200650066006100620020006f00720020006300680061007200610063007400650072002e00004d43006800610072006100630074006500720020006300680061006e006700650064003b0020007200650063006f0076006500720079002000630061006e00630065006c006c00650064002e00004d53006500610072006300680069006e006700200066006f007200200079006f007500720020006c0061007400650073007400200074006f006d006200730074006f006e0065002e002e002e000080bb4e006f0020006b006e006f0077006e00200074006f006d006200730074006f006e006500200066006f0075006e0064002e002000520065006d006f0074006500200063006c00690065006e007400730020006d006100790020006e006f007400200068006100760065002000640069007300740061006e007400200074006f006d006200730074006f006e006500200064006100740061003b00200074007200790020004c006100730074002000640065006100740068002e0000614e006f002000720065006d00610069006e0069006e006700200074006f006d006200730074006f006e006500200066006f0075006e006400200066006f007200200079006f007500720020006300680061007200610063007400650072002e00004f54006f006d006200730074006f006e00650020006300680061006e00670065006400200064007500720069006e00670020007300650061007200630068002e002000520065007400720079002e000080e959006f007500720020006c0061007400650073007400200074006f006d006200730074006f006e0065002000690073002000620065007300690064006500200079006f0075002c00200077006900740068002000690074007300200069006e00760065006e0074006f007200790020007000720065007300650072007600650064002e0020004c0061007300740020006400650061007400680020007300740069006c006c00200070006f0069006e0074007300200074006f00200074006800650020006f0072006900670069006e0061006c0020006c006f0063006100740069006f006e002e0000255200650063006f0076006500720079002000730074006f0070007000650064003a002000000f7400650072007200610069006e00000b70006900650063006500000f440065006600610075006c00740000197300740061007400690063005f0073006f006c0069006400001b440065006600610075006c0074005f0073006d0061006c006c000080894e006f00200063006c0065006100720020006c0061006e00640069006e0067002000730070006f00740020006e00650061007200620079002e0020005300740061006e00640020006f006e0020006f00700065006e002c00200073006f006c00690064002000670072006f0075006e006400200061006e0064002000720065007400720079002e00006154006f006d006200730074006f006e0065002000690073002000630075007200720065006e0074006c00790020006f00700065006e002e00200043006c006f0073006500200069007400200061006e0064002000720065007400720079002e000009490064006c00650000313c0055007300650072004b00650079003e006b005f005f004200610063006b0069006e0067004600690065006c00640000176d005f0074006f006d006200730074006f006e006500004d50006c0061007900650072002000730074006100740075007300200065006600660065006300740073002000610072006500200075006e0061007600610069006c00610062006c0065002e000073540072006f007000680079002000620075006600660073002000720065006d006f007600650064002e0020004f0074006800650072002000730074006100740075007300200065006600660065006300740073002000610072006500200075006e006300680061006e006700650064002e00002b49006e00760061006c00690064002000740072006f00700068007900200070006f007700650072002e000049530074006100740075007300200065006600660065006300740020006400610074006100620061007300650020006900730020006e006f0074002000720065006100640079002e00006b54006800690073002000740072006f00700068007900200070006f00770065007200200069007300200075006e0061007600610069006c00610062006c006500200069006e00200074006800650020006c006f0061006400650064002000670061006d0065003a00200000554e006f002000740072006f00700068007900200070006f007700650072007300200066006f0075006e006400200069006e00200074006800650020006c006f0061006400650064002000670061006d0065002e0000114100700070006c00690065006400200000032f000053200070006f0077006500720073003b0020007400680065002000670061006d00650020006400650063006c0069006e006500640020007400680065002000720065006d00610069006e006400650072002e000015410063007400690076006100740065006400200000192000740072006f007000680079002000620075006600660000177300200074006f006700650074006800650072002e0000032e00005d20005200650073007400650064002000720065006600720065007300680065006400200074006f0020006d006100780020006200750069006c0064002d0070006900650063006500200063006f006d0066006f007200740020002800014b20006d0069006e0029002e002000530068006100720065006400200070006f007700650072007300200061006e006400200052006500730074006500640020007700690074006800200000808920006e0065006100720062007900200070006c0061007900650072002800730029002000770069007400680069006e002000310030006d003b00200061006c006c00690065007300200075007300650020007400680065006900720020006f0077006e00200063006f006d0066006f007200740020006400750072006100740069006f006e002e000015470050005f00450069006b0074006800790072000017470050005f0054006800650045006c006400650072000017470050005f0042006f006e0065006d006100730073000011470050005f004d006f006400650072000015470050005f005900610067006c007500740068000011470050005f0051007500650065006e000017470050005f004100730068006c0061006e00640073000019470050005f0044006500650070004e006f0072007400680000395200650073007400650064002000740069006d0065007200200069007300200075006e0061007600610069006c00610062006c0065002e00004d5300740061007400750073002000650066006600650063007400200064006100740061006200610073006500200069007300200075006e0061007600610069006c00610062006c0065002e00000d52006500730074006500640000494e006100740069007600650020005200650073007400650064002000650066006600650063007400200069007300200075006e0061007600610069006c00610062006c0065002e00004743006f006d0066006f007200740020006200750069006c0064002000700069006500630065007300200061007200650020006e006f0074002000720065006100640079002e0000335400680065002000670061006d00650020006400650063006c0069006e006500640020005200650073007400650064002e00000d6d005f00740069006d006500007b570061006900740020006f006e0065002000670061006d00650020006600720061006d006500200066006f00720020007400680065002000700072006500760069006f00750073002000740061006d0069006e0067002000730065007300730069006f006e00200074006f00200063006c006f00730065002e000027410064006d0069006e0054006f006f006c006b00690074005f00540061006d0069006e0067000080d96d006900640064006c00650020006d006f007500730065002000740061006d0069006e006700200065006e00610062006c00650064002e002000410069006d002000610074002000610020006e00610074006900760065002000740061006d006500610062006c0065002000630072006500610074007500720065002000770069007400680069006e002000310030006d00200061006e00640020007000720065007300730020006d006900640064006c00650020006d006f00750073006500200069006e002000560061006c006800650069006d002e000011540061006d0069006e0067003a002000001b6d005f006f0062006a0065006300740073004200790049004400004157006f0072006c00640020006f0062006a006500630074002000640069006300740069006f006e0061007200790020006300680061006e006700650064002e00004b57006f0072006c00640020006f0062006a0065006300740020007200650063006f007200640073002000610072006500200075006e0061007600610069006c00610062006c0065002e0000135300630061006e006e0069006e0067002000006920006b006e006f0077006e00200077006f0072006c00640020006f0062006a0065006300740073002e002000520065007400750072006e00200074006f002000560061006c006800650069006d00200061006e006400200075006e00700061007500730065002e00002d55006e006e0061006d00650064002000740061006d0065006400200063007200650061007400750072006500000f540061006d00650064003a00200000037c0000054600310000030a0000114c006f006300610074006500640020000080d320006b006e006f0077006e002000740061006d0065006400200061006e0069006d0061006c0073002e002000540065006d0070006f00720061007200790020006d00610070002000700069006e00730020006100720065002000760069007300690062006c0065003b002000720065006d006f0074006500200063006c00690065006e007400730020006d006100790020006e006f00740020006b006e006f007700200075006e007300650065006e002000640069007300740061006e007400200061006e0069006d0061006c0073002e00003f5300630061006e006e0069006e00670020006b006e006f0077006e00200061006e0069006d0061006c0020007200650063006f007200640073003a00200000053b002000002f2000740061006d00650064002000630072006500610074007500720065007300200066006f0075006e0064002e0000495200650066007200650073006800200061006e0069006d0061006c007300200069006e0020007400680069007300200077006f0072006c0064002000660069007200730074002e0000808b530065006c0065006300740065006400200061006e0069006d0061006c0020006300680061006e006700650064002c002000640069006500640020006f00720020006900730020006e006f0020006c006f006e006700650072002000740061006d00650064002e0020005200650066007200650073006800200061006e0069006d0061006c0073002e000031530065006c0065006300740065006400200061006e0069006d0061006c00200069007300200064006500610064002e00006341006e0069006d0061006c0020006f0077006e0065007200730068006900700020006900730020006e006f0074002000720065006100640079002e002000540072007900200061006700610069006e002000730068006f00720074006c0079002e0000196d005f0073007000610077006e0050006f0069006e00740000215200650073006500740050006100740072006f006c0050006f0069006e007400000d4d006f0076006500640020000080d32000620065007300690064006500200079006f00750020007500730069006e006700200069007400730020006500780069007300740069006e00670020006e006500740077006f0072006b0020006f0062006a006500630074002e00200043006f006e006600690072006d0020006100720072006900760061006c003b0020007300650072007600650072002000730079006e006300680072006f006e0069007a006100740069006f006e0020006d00610079002000740061006b0065002000610020006d006f006d0065006e0074002e00008095410069006d002000610074002000610020006c006900760065002000740061006d006500610062006c0065002000630072006500610074007500720065002000770069007400680069006e002000310030006d00200061006e00640020007000720065007300730020006d006900640064006c00650020006d006f00750073006500200069006e002000670061006d0065002e0000575400680069007300200063007200650061007400750072006500200068006100730020006e006f0020006e00610074006900760065002000740061006d0069006e006700200073007500700070006f00720074002e00003f5400680069007300200063007200650061007400750072006500200069007300200061006c00720065006100640079002000740061006d00650064002e0000674300720065006100740075007200650020006f0077006e0065007200730068006900700020006900730020006e006f0074002000720065006100640079002e002000540072007900200061006700610069006e002000730068006f00720074006c0079002e000009540061006d006500007f470061006d006500200064006900640020006e006f007400200063006f006e006600690072006d002000740061006d0069006e0067002e002000540072007900200061006700610069006e0020006100660074006500720020006f0077006e00650072007300680069007000200073006500740074006c00650073002e00000d540061006d00650064002000006f2e00200052006500660072006500730068002000740061006d0065006400200061006e0069006d0061006c007300200074006f0020006c00690073007400200069007400200061006e0064002000610064006400200069007400730020006d00610070002000700069006e002e00008083520065006100640079002e00200052006500660072006500730068002000740061006d0065006400200061006e0069006d0061006c0073002c0020007400680065006e002000720065007400750072006e00200074006f002000560061006c006800650069006d00200061006e006400200075006e00700061007500730065002e00001d540061006d0069006e006700200074006f006f006c0073003a002000003742006f006100740020006f007000740069006f006e0020006d007500730074002000620065002000300020006f007200200031002e00005150006900780069006500200062006f00610074003a0020004f00460046003b00200072006500730074006f00720069006e006700200062006f0061007400200070006800790073006900630073002e0000808750006900780069006500200062006f00610074003a002000770061006900740020006f006e0065002000670061006d00650020006600720061006d006500200066006f007200200072006500730074006f0072006100740069006f006e002c0020007400680065006e00200065006e00610062006c006500200061006700610069006e002e00002d410064006d0069006e0054006f006f006c006b00690074005f005000690078006900650042006f00610074000080b750006900780069006500200062006f00610074003a0020004f004e002e002000540061006b00650020007400680065002000680065006c006d003b00200057002f00530020007400680072006f00740074006c0065002c00200041002f0044002000730074006500650072002c00200054006100700020004c0065006600740020004300740072006c00200074006f0020006a0075006d0070003b0020006e006f00200063006f006f006c0064006f0077006e002e00001f50006900780069006500200062006f00610074003a0020004f0046004600002d42006f00610074002000700068007900730069006300730020006300680061006e006700650064003a002000004d42006f006100740020006400750072006100620069006c00690074007900200063006f006d0070006f006e0065006e007400200075006e0061007600610069006c00610062006c0065002e00004d42006f0061007400200062006f006400790020006f00720020006e006500740077006f0072006b0020007600690065007700200075006e0061007600610069006c00610062006c0065002e0000808150006900780069006500200062006f00610074003a002000770061006900740069006e006700200066006f00720020006e006f0072006d0061006c00200062006f006100740020006f0077006e006500720073006800690070002e002000530074006100790020006100740020007400680065002000680065006c006d002e00004f50006900780069006500200062006f00610074003a0020004f004e002e002000540061006b00650020007400680065002000680065006c006d00200074006f002000640072006900760065002e00006150006900780069006500200062006f00610074003a0020004f004e0020007c00200042006f006100720064002f00740061006b00650020007400680065002000680065006c006d00200074006f0020006400720069007600650020007c00200000234e006f0072006d0061006c0020006400750072006100620069006c0069007400790000254e006f0020006400750072006100620069006c0069007400790020006c006f007300730000094200610063006b00000953006c006f0077000009480061006c0066000009460075006c006c00002350006900780069006500200062006f00610074003a0020004f004e0020007c002000000720007c002000006320006d002f00730020006d006100780020007c0020004c0065006600740020004300740072006c003a002000680069006700680020006a0075006d00700020007c002000530068006900660074003a00200062006f006f007300740020007c002000002950006900780069006500200062006f00610074002000730074006f0070007000650064003a00200000236d005f007300610069006c0046006f0072006300650046006100630074006f00720000216d005f00640061006d00700069006e006700530069006400650077006100790000216d005f00640061006d00700069006e00670046006f007200770061007200640000196d005f007300740065006100720046006f00720063006500002b6d005f0073007400650061007200560065006c0046006f0072006300650046006100630074006f007200001f6d005f006200610063006b00770061007200640046006f0072006300650000276d005f007700610074006500720049006d007000610063007400440061006d00610067006500001f6d005f0075007000730069006400650044006f0077006e0044006d00670000255200650070006c0065006e0069007300680020007400720061006e007300660065007200002f5200650070006c0065006e006900730068002000640072006f00700020006600610069006c00650064003a0020000003240000035b00002d4c006f0061006400200079006f0075007200200077006f0072006c0064002000660069007200730074002e00001d6d005f006e0061006d00650064005000720065006600610062007300005752006500670069007300740065007200650064002000700072006500660061006200200063006100740061006c006f00670075006500200069007300200075006e0061007600610069006c00610062006c0065002e00000942007500730068000080f557006f0072006c00640020007000720065006600610062007300200061007200650020006e006f0074002000720065006100640079002e002000520065007400750072006e00200074006f002000560061006c006800650069006d002c002000700072006500730073002000450073006300200074006f00200063006c006f0073006500200074006800650020007000610075007300650020006d0065006e0075002c0020007400680065006e00200072006500660072006500730068002000740068006500200073007000610077006e00200063006100740061006c006f00670075006500200061006700610069006e002e00000f4c006f0061006400650064002000001920006300720065006100740075007200650073002c002000001920006d00650072006300680061006e00740073002c002000002b20006900740065006d0073002f007200650073006f0075007200630065007300200061006e0064002000003720006e00610074006900760065002000740061006d006500610062006c00650020006300720065006100740075007200650073002e0000809d530065006c00650063007400200061002000720065006700690073007400650072006500640020007000720065006600610062002000660072006f006d0020007400680065002000630075007200720065006e007400200063006100740061006c006f006700750065003b0020007200650066007200650073006800200074006800650020006c006900730074002000660069007200730074002e00004f530065006c0065006300740065006400200070007200650066006100620020006900730020006e006f0020006c006f006e00670065007200200061007600610069006c00610062006c0065002e0000515400680069007300200070007200650066006100620020006900730020006e006f00740020006100200073007000610077006e00610062006c0065002000630072006500610074007500720065002e000065540068006900730020006300720065006100740075007200650020006e006f0020006c006f006e00670065007200200068006100730020006e00610074006900760065002000740061006d0069006e006700200073007500700070006f00720074002e000051470061006d006500200064006900640020006e006f007400200063007200650061007400650020007400680065002000730065006c006500630074006500640020007000720065006600610062002e00000520005b0000035d00000520002800000f200073007400610072007300290000808b20004e00610074006900760065002000640065006600610075006c0074002000740061006d00650020007300740061007400650020006100700070006c006900650073003b002000750073006500200077006800650065006c002d0063006c00690063006b002000740061006d0069006e00670020006900660020006e00650065006400650064002e00017f530065006c006500630074006500640020006900740065006d0020006c00650066007400200079006f0075007200200069006e00760065006e0074006f00720079002e0020005200650066007200650073006800200061006e0064002000730065006c00650063007400200069007400200061006700610069006e002e000059540068006900730020006900740065006d00200068006100730020006e006f002000650071007500690070006d0065006e00740020007100750061006c006900740079002000750070006700720061006400650073002e000043530065006c006500630074006500640020006900740065006d00200069007300200061006c007200650061006400790020007100750061006c0069007400790020000053540068006900730020007100750061006c006900740079002000700072006f0064007500630065006400200069006e00760061006c006900640020006400750072006100620069006c006900740079002e00000f4300680061006e006700650064000039550070006400610074006500450071007500690070006d0065006e00740053007400610074007500730045006600660065006300740073000047530065006c006500630074006500640020006900740065006d0020007100750061006c0069007400790020006300680061006e006700650064002000660072006f006d0020000009200074006f002000006b2e0020004500780069007300740069006e00670020006300680065006100740065006400200066006c0061006700200075006e006300680061006e006700650064003b0020006e006f0072006d0061006c0020006d006100780069006d0075006d0020006900730020000019470065007400520069006700680074004900740065006d000015430075006c00740069007600610074006f007200002124006900740065006d005f00630075006c00740069007600610074006f007200003945007100750069007000200079006f00750072002000630075006c00740069007600610074006f0072002000660069007200730074002e000035530065006c00650063007400200061002000630075006c00740069007600610074006f007200200070006c0061006e0074002e0000435300740061006e00640020006f006e002000630075006c0074006900760061007400650064002000670072006f0075006e0064002000660069007200730074002e00002f54006f006f006c006b00690074005f004100750074006f0050006c0061006e0074006500720042006500740061000080b34100750074006f00200070006c0061006e00740065007200200073007400610072007400650064002e002000460069006c006c0069006e006700200063006f006e006e00650063007400650064002000630075006c0074006900760061007400650064002000670072006f0075006e0064002000770069007400680069006e002000320030006d003b0020006d006100780069006d0075006d002000320035003600200070006c0061006e00740073002e00002b4100750074006f00200070006c0061006e007400650072002000730074006f0070007000650064002e00001550006c0061006300650050006900650063006500002143006f006e00730075006d0065005200650073006f00750072006300650073000021480061007600650052006500710075006900720065006d0065006e0074007300004750006c00610079006500720020006d006f007600650064002000610077006100790020006f007200200077006f0072006c00640020006300680061006e006700650064002e00002d430075006c00740069007600610074006f007200200075006e00650071007500690070007000650064002e0000734e006f00200070006c0061006e00740069006e00670020006d006100740065007200690061006c00730020006f0072002000720065006300690070006500200072006500710075006900720065006d0065006e0074007300200075006e0061007600610069006c00610062006c0065002e00001150006c0061006e007400650064002000003f3b0020007300630061006e006e0069006e0067002000630075006c0074006900760061007400650064002000670072006f0075006e0064002e002e002e000031520065006100630068006500640020003200350036002d0070006c0061006e00740020006c0069006d00690074002e00016f43006f006e006e00650063007400650064002000630075006c007400690076006100740065006400200070006100740063006800200063006f006d0070006c0065007400650020002800320030006d00200073006500610072006300680020006c0069006d006900740029002e000013530074006f0070007000650064003a0020000013200050006c0061006e007400650064002000002d4100750074006f00200068006100720076006500730074002000640069007300610062006c00650064002e00002b4c006f006f00740020006d00610067006e00650074002000640069007300610062006c00650064002e00004b430068006f006f00730065002000610020007200610064006900750073002000660072006f006d0020003500200074006f00200035003000300020006d00650074007200650073002e00002754006f006f006c006b00690074005f0048006100720076006500730074004c006f006f0074000080b74100750074006f002000680061007200760065007300740020006100630074006900760065003a00200072006900700065002000630075006c00740069007600610074006f0072002000630072006f00700073002000770069007400680069006e002000320030006d002e00200048006100720076006500730074002000640072006f0070007300200066006c007900200074006f00200079006f0075007200200069006e00760065006e0074006f00720079002e00001f41006c006c002d006c006f006f00740020006d00610067006e0065007400012743006800650061007400650064002d006900740065006d0020006d00610067006e0065007400011f20006100630074006900760065002000770069007400680069006e002000002d6d00200028006c006f0061006400650064002000640072006f007000730020006f006e006c00790029002e00002949006e00760061006c006900640020006c006f006f007400200061006300740069006f006e002e0000053a002000001b6d003b00200063006f006c006c006500630074006500640020000080892e002000460075006c006c00200069006e00760065006e0074006f00720079002c002000700072006f00740065006300740065006400200061006e006400200075006e0061007600610069006c00610062006c0065002000640072006f007000730020007300740061007900200069006e002000740068006500200077006f0072006c0064002e0000374100750074006f0020006800610072007600650073007400200061006300740069007600650020002800320030006d0029003a0020000065200068006100720076006500730074002000720065007100750065007300740073003b0020006e00610074006900760065002000670072006f007700740068002000740069006d00650072007300200075006e006300680061006e006700650064002e0000095300610076006500001773005f0069006e007300740061006e00630065007300005d43006c00650061007200200077006500610074006800650072002000640069007300610062006c00650064003b00200072006500730074006f00720069006e006700200065006e007600690072006f006e006d0065006e0074002e00002354006f006f006c006b00690074005f0043006c006500610072005600690065007700007143006c006500610072002000770065006100740068006500720020006100630074006900760065003a0020007200610069006e002c00200066006f006700200061006e00640020006d006900730074002000680069006400640065006e0020006c006f00630061006c006c0079002e00002f43006c00650061007200200077006500610074006800650072002000640069007300610062006c00650064002e00000d47006500740045006e007600000b43006c00650061007200003d43006c00650061007200200065006e007600690072006f006e006d0065006e007400200075006e0061007600610069006c00610062006c0065002e0000096d005f007000730000136d005f007000730079007300740065006d00002f43006c00650061007200200077006500610074006800650072002000730074006f0070007000650064003a002000006743006c00650061007200200077006500610074006800650072002000640069007300610062006c00650064003b0020006e006f0072006d0061006c0020007600690073006900620069006c00690074007900200072006500730074006f007200650064002e000017700069006500630065005f0063006800650073007400001d700069006500630065005f00770061007200640072006f0062006500003153006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e0052006f006c0065002e0076003100003153006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e004900740065006d002e0076003100003753006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e004e006500740077006f0072006b002e0076003100004543006800650073007400200069007300200075006e0061007600610069006c00610062006c00650020006f0072002000700072006f007400650063007400650064002e00005f53006f006d0065006f006e00650020006900730020007500730069006e006700200074006800690073002000630068006500730074002e002000540072007900200061006e006f0074006800650072002000630068006500730074002e0000754f00700065006e00200061006e006400200063006c006f00730065002000740068006900730020006300680065007300740020007700690074006800200045002000660069007200730074002c0020007400680065006e002000740072007900200046003900200061006700610069006e002e00003d43006f006e007400610069006e00650072002e004c006f0061006400200069007300200075006e0061007600610069006c00610062006c0065002e00003b43006800650073007400200069006e00760065006e0074006f007200790020006900730020006e006f0074002000720065006100640079002e00002b7300680061007200650064002d0077006f0072006c0064002d0072006f007500740065002d0076003100010d73006f0075007200630065000049430068006f006f0073006500200061002000730065007000610072006100740065002000640065007300740069006e006100740069006f006e002000630068006500730074002e000017640065007300740069006e006100740069006f006e000033530065006c0065006300740020006100740020006c00650061007300740020006f006e00650020006900740065006d002e00006950007500740020006f006e0065002000730061006d0070006c00650020006f0066002000650061006300680020006e006500770020006900740065006d00200069006e00200074006800690073002000630068006500730074002000660069007200730074002e000073530065006c0065006300740020006100740020006c00650061007300740020006f006e00650020006900740065006d002c0020006f0072002000720065006d006f007600650020007400680065002000630068006500730074002000610073007300690067006e006d0065006e0074002e00007f520065006d006f00760065002000740068006500200073006f007200740069006e006700200072006f006c00650020006200650066006f007200650020006d0061006b0069006e00670020007400680069007300200061002000640065007300740069006e006100740069006f006e002000630068006500730074002e00006d49006e00760061006c006900640020006900740065006d00200074007900700065002e0020004500780069007300740069006e0067002000610073007300690067006e006d0065006e00740073002000610072006500200075006e006300680061006e006700650064002e0000374d00610072006b0020006100200073006f007200740069006e0067002000630068006500730074002000660069007200730074002e00001120006900740065006d0073002e0020000080812000720065006d00610069006e002000280075006e006d006100740063006800650064002c00200075006e0061007600610069006c00610062006c00650020006f00720020006e006f00200072006f006f006d0029002e0020004c006f006100640065006400200063006800650073007400730020006f006e006c0079002e000015200053006b00690070007000650064003a002000000f200062007500730079002c00200000192000700072006f007400650063007400650064002c002000003320006100770061006900740069006e00670020006e006500740077006f0072006b0020006100630063006500730073002e00001743006800650063006b0041006300630065007300730000094c006f006100640000256d005f00630075007200720065006e00740043006f006e007400610069006e00650072000033520065007100750065007300740069006e00670020006300680065007300740020006100630063006500730073003a0020000080852000720065006d00610069006e0069006e0067002e0020004900740065006d00730020007300740061007900200069006e002000740068006500200073006f007200740069006e006700200063006800650073007400200075006e00740069006c0020006100630063006500730073002000690073002000720065006100640079002e00002320004e006500740077006f0072006b0020006100630063006500730073003a00200000132000640065006e006900650064002c002000006f2000740069006d006500640020006f00750074002e0020004f00700065006e00200075006e0061007600610069006c00610062006c006500200063006800650073007400730020007700690074006800200045002c0020007400680065006e002000720065007400720079002e00004f53006f00720074002000630061006e00630065006c006c00650064002e0020004e006f002000660075007200740068006500720020006900740065006d00730020006d006f007600650064002e000080894300680065007300740020006e006500740077006f0072006b00200072006500730070006f006e0073006500200069007300200075006e0061007600610069006c00610062006c0065002e0020004f00700065006e002000740068006900730020006300680065007300740020007700690074006800200045002000660069007200730074002e00001f5200500043005f0052006500710075006500730074004f00700065006e0000176d005f00660075006e006300740069006f006e00730000215200500043005f004f00700065006e0052006500730070006f006e00730065000039520065007400750072006e00200074006f00200079006f0075007200200070006c0061007900650072002000660069007200730074002e00006b570061006900740020006f006e0065002000670061006d0065002000750070006400610074006500200066006f00720020007400680065002000700072006500760069006f0075007300200077006f0072006c006400200074006f00200063006c006f00730065002e0000808f43006800650073007400200073006f007200740069006e006700200065006e00610062006c00650064002e0020004f00700065006e00200061006e00790020006300680065007300740020007700690074006800200045002c0020007400680065006e00200063006c00690063006b00200043006800650073007400200073006f007200740069006e0067002e00003153006f006c006f0054006f006f006c006b00690074005f004300680065007300740053006f007200740069006e006700006543006800650073007400200073006f007200740069006e00670020006f00660066002e002000530061007600650064002000630068006500730074002000610073007300690067006e006d0065006e00740073002000720065006d00610069006e002e0000074f0066006600001353006f007200740069006e0067003a002000004b460069006e0069007300680020006d006f00760069006e00670020007400680065002000640072006100670067006500640020006900740065006d002000660069007200730074002e000080b543006c00690063006b00200052006500610073007300690067006e00200061006c006c0020006900740065006d00730020002b0020007300610076006500200074006f0020007200650070006c0061006300650020006f006c0064002000660069006c0074006500720073002000770069007400680020007400680069007300200063006800650073007400270073002000630075007200720065006e007400200063006f006e00740065006e00740073002e00010720002000280000056d002900003950006c006100790065007200200063006f006e00740072006f006c007300200075006e0061007600610069006c00610062006c0065002e00008083470061006d00650020006d006f0075007300650020006300610070007400750072006500200069007300200075006e0061007600610069006c00610062006c0065002e00200043006c006f007300650020007400680065002000700061006e0065006c00200061006e0064002000740072007900200061006700610069006e002e0000315b00460039005d00200043006800650073007400200073006f007200740069006e006700200073006500740075007000002f5b00460039005d0020004f00700065006e00200073006f007200740069006e006700200063006800650073007400000d530054004100540055005300002143006c006f0073006500200028004600390020002f0020004500730063002900001b4200610063006b00200074006f0020006300680065007300740000808753006100760065006400210020004e006f002000610073007300690067006e00610062006c00650020006900740065006d007300200069006e00200074006800690073002000630068006500730074003b0020006f006c00640020006900740065006d002000660069006c0074006500720073002000720065006d006f007600650064002e00004353006100760065006400210020005200650070006c00610063006500640020006f006c0064002000660069006c007400650072007300200077006900740068002000004920006900740065006d002000740079007000650073002000630075007200720065006e0074006c007900200069006e00200074006800690073002000630068006500730074002e00005553006f007200740069006e006700200072006f006c0065002000720065006d006f007600650064002e0020004900740065006d0073002000610072006500200075006e006300680061006e006700650064002e0000808953006f007200740069006e0067002000630068006500730074002000720065006100640079002e00200041006c006c00200073006f007200740069006e006700200063006800650073007400730020007300680061007200650020007400680065002000730061006d0065002000640065007300740069006e006100740069006f006e0073002e00001b43006800650073007400200073006f007200740069006e0067000069430068006f006f007300650020007700680061007400200074006800690073002000630068006500730074002000720065006300650069007600650073002000660072006f006d00200073006f007200740069006e00670020006300680065007300740073002e00006153006f007200740020006d00690078006500640020006900740065006d007300200069006e0074006f00200079006f007500720020007300680061007200650064002000730074006f007200610067006500200072006f007500740065002e00002d440065007300740069006e006100740069006f006e00200063006800650073007400200020002f0020002000002320007300610076006500640020006900740065006d002000740079007000650073000053440065007300740069006e006100740069006f006e00200063006800650073007400200020002f00200020006e006f0020007300610076006500640020006900740065006d00200074007900700065007300003d53006f007200740069006e006700200063006800650073007400200020002f0020002000730068006100720065006400200072006f00750074006500003f4900540045004d002000460049004c005400450052005300200026002000430055005200520045004e005400200043004f004e00540045004e005400530000314c004f0041004400450044002000440045005300540049004e004100540049004f004e005300200020002f0020002000001149004e00200043004800450053005400000b530041005600450044000080994e006f0020006900740065006d0020007400790070006500730020007900650074002e0020005000750074002000730061006d0070006c00650020006900740065006d007300200069006e0020007400680065002000630068006500730074002c0020007400680065006e0020007500730065002000740068006500200062007500740074006f006e002000620065006c006f0077002e000080a74e006f0020006c006f0061006400650064002000640065007300740069006e006100740069006f006e00730020007900650074002e002000530065007400200075007000200061006e006f007400680065007200200063006800650073007400200074006f002000720065006300650069007600650020006900740073002000630075007200720065006e00740020006900740065006d002000740079007000650073002e000035520045005100550045005300540049004e00470020004300480045005300540020004100430043004500530053002e002e002e00001553004f005200540020004900540045004d005300003352006500610073007300690067006e00200061006c006c0020006900740065006d00730020002b002000730061007600650000334d0061006b0065002000740068006900730020006100200073006f007200740069006e0067002000630068006500730074000027520065006d006f0076006500200073006f007200740069006e006700200072006f006c006500001d6d005f006d006f007500730065004300610070007400750072006500003d43006800650073007400200062007500740074006f006e0073002000610072006500200075006e0061007600610069006c00610062006c0065002e00007343006800650073007400200062007500740074006f006e0020006c00610079006f0075007400200069007300200075006e0061007600610069006c00610062006c0065002e002000460039002000720065006d00610069006e007300200061007600610069006c00610062006c0065002e00006943006800650073007400200062007500740074006f006e00200072006f007700200069007300200074006f006f00200073006d0061006c006c002e002000460039002000720065006d00610069006e007300200061007600610069006c00610062006c0065002e00003d53006f006c006f0054006f006f006c006b00690074005f004300680065007300740053006f007200740069006e00670042007500740074006f006e00004349006e00760065006e0074006f0072007900200069006e00700075007400200072006f006f007400200075006e0061007600610069006c00610062006c0065002e00001f6d005f00740061006b00650041006c006c0042007500740074006f006e0000216d005f0073007400610063006b0041006c006c0042007500740074006f006e00001f6d005f0069006e00760065006e0074006f007200790052006f006f00740000156d005f0064007200610067004900740065006d000000004110817eac18f14d85359be5bc98e6e80008b77a5c561934e08902061c0306121102060a02060802060e030612190306121d070615122101122503061129030000080300000e03000001040001010805000102122d070003011211080e08000401121108080e0700030112110e0e0900050112110e08080e0900040112111219080e0a0003123112311231121904000012190a000408123512311219080500010e1139050001011211050002010e02050001021129070002011211112906000111291211070002011211122503061d0e0600020e1211080900010815123d0111140500010c1211062003010e08080306114104340000000206020306121c04061d12250806151245020e12250806151245020e124d0306124902060c0500010e12110400010e0e0500010e12250500010212250800030e12110e112903200001030612240306125103061255030612590306122d0306125d030612280306126103061d0c0320000205200102122d052001011251052002010202050002020c0c0800050c020c0c0c0c07061d151265010e0706151245020e0e040001020e0500010e12690a00050e12110e081129080800030e1211121908060001121912110306126d030612400600020e12110e07000202121112710900030112111271112903061269070615127501117907061512650111790706151221011129042001010e030612480700030e1211080804061f7d0204061f7d08060615126501080706151221011215070615122101114c070615124502080c04061d12150500001d121509000602080202020c0c0306125804061280810406128085090615124502128089020720020112808d0e2a7300680061007200650064002d0077006f0072006c0064002d0072006f007500740065002d00760031003053006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e0052006f006c0065002e00760031003053006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e004900740065006d002e00760031003653006f006c006f0054006f006f006c006b00690074002e0053006f00720074002e004e006500740077006f0072006b002e007600310007000112809112110600010212809107000112591280910700020e1280910e0600010e1280910700011d0e128091070002021280910e0500010e12190800020212809112110800020112809112110c00040112809112809112110e10000401128091128091121115123d010e0d000301128091121115123d010e080002081280911211090002021280911280910f00030e128091121115123d011280910406128091080615122101128091070615122101126404200101020320000e0f200301128091121115123d01128091032800020328000e09061512450212591264090002126412809112110406128095052000128091082002011280911211052002010a020528001280910306126c05000101126c0400002544040000304403061260040612809903061270040611809d04061280a104061180a507061512210112190606151221010e0606151265010e04061180a9030000020720020112809102062001011280ad0806151221011280b104061280b504061280b10820011280b11180b90a20031280b5081180b9021120041280b51280b11280b11280b11180b9062001011180a9052002010e0e04200101080420010e0e04061280bd04061280c104061280c504061280c90306117404061280cd0d0006011280c91280c90c0c0c0c062001011280c90100060002011c1002040001011c06070402081c02060704020e1c0206151221011225050703021c02030701020307010e0307010804070112310407011219032000080520020e0808050002050e080600020a1d05080807051d0508021c0206070408021c0207000202121d121d0420011c1c0500011d05070500010e1d050520020e0e0e032000090500011d05090500020e0e0e0407020e020500001280fd040000125d09200015122101118101071512210111810109200015118105011300081511810501118101042000130003061139080003020e0e1181090420001139070002021139113905000012810d062001122511390320000a052000128111052000118115092004010a11390e1d1c0600030e0e0e0e170708118101112912250a02151181050111810111391d1c040001020c0400010c0c09200302112911811502050002021c1c0600010212812d0900020212812d12812d04200011290700020c1129112905000012813505200112690e053001001e00040a0112590c1001031e001e001129118115040a011269050a011281390500001181150700040e0e0e0e0e05000012813d05200012814104000011290800021129112911290c2003020e151221011225100807151181050112250520020a080a070002112911290c2707130e126912691d0e080e1269112912814112250a12250a128149021c021d0e15118105011225050001081d0e0800031181150c0c0c090002112911811511291000060211291129101181550c081181590a00040211290c0811815910070808081129118155112911291d0e0206200112691139050a011280910300000a042001010a06200201081129052001011129040a011255050a0112815d0f070612691280911129125512815d02080001128161118165072002121d0e1141052000128169040001080e0520020208020500001281710715122101128175062001128175080520010113000815118105011281750a20051281750802080c060500010e1d1c061512210112110c00030111290c1512210112110615126501121107151181050112110520010213000500020d0d083b07131281690e15122101128175081281750c081512210112111512650112110812111281690e021d0e0815118105011281751d1c151181050112110407011d0e0615124502080805000012818106151245020e080a200101151281850113000615123d01111409200015128189011300071512818901111408200202130010130105000208080807200201130013010b200015128191021300130107151281910208080b2000151181950213001301071511819502080804200013010715128191020e080715118195020e0830070c151245020808151245020e081114151245020e080808080815128189011114021511819502080815118195020e080615122101111405151265010e0706151221011269061512210112690715118105011269040a011215040612819d04061281a1040a01127104061181a50500020c0c0c30070f128199151221011114151265010e126912151281a1126912710c1281750c0c021511810501126915118105011269062001011181ad040a01121c0500001281bd04000102080520001281490c2005011181c90e081281cd020707030e128149020520001281d1072002011281d50807151245020e12250600030e1c1c1c080703121d128095020520020e03030520020e080e0520011269080707040e12690e02040000124907151245020e124d0815128191020e124d0815118195020e124d05200101124d0d0703124d0215118195020e124d05151221010e0b2000151181d9021300130108151181d9020e12250b2000151181dd021300130108151181dd020e1225102007124d11291181e50e02020a1181e10500001281e90720020e0e1281ed0500010e1d0e0b2000151281f1021300130108151281f1020e124d0b2000151181f5021300130108151181f5020e124d0615118105010e062001130113000a200101151281f90113000520001d13000600020e0e1d0e3d070f151221010e151265010e151181dd020e1225122511290e124d151221010e0e02151181d9020e12251181e11d0e151181f5020e124d15118105010e04200012690600010112812d050a01128129040a0112110300000c0a07050812251269021d1c050a0112820105200012816109000202128161128161052002011c1c072002126d0e11410620021c1c1d1c05200101113918070b1225126912812912590e1255128201121d12815d0e02052000128129062001112911290f00051d118155112911290c081181590520001282090320000c050a0112820d050a0112821117070a12812911290c11815512820d12590e021d118155080500020e1c1c050701128149040a01122405070212240206000102118219050703080202040a01122d0b07051d121d1d0c08122d0204200012510400001251052000118221050002020e0e0800020c1129101261062003010c0c0c0900031129112911290c0800021181150c1129090002118115112911290c00031181151181151181150c06200101118115040612822905200011822d0820020111291182352a071812510c0e0c0c112911290c11290c11291181551282290c0c020c128149021129021d0e11822d1d1c04070202020407020c02040100000004200012310520010212190420001219052002010808040611823d092004010e1281cd08080b0705121112191231123102060702121912190c0004121512190811291181150420010c080f070712111219121512551281490802050000128241042001020e0b070612150e1282410e0e02052002080e0e06151245020e0e0607040e0e080805200012818d0320001c0406118080090002011281d5118255052001081d03050a01128259050a0112825d050a01128261072002080e1181090920010115123d0113000615128265010e052002011c180a20010115128265011300400715121d1280951d151265010e12690e128129021215151221010e08151221010e0e15128265010e12780e021d151265010e12818d12811d15118105010e1d1c0c0707126912690e0e0e021d0e0807011d151265010e0a0707080c0c0c0e021d1c1407061215151221010e12690e15118105011269020700011282691129052001021129040a01124016070812191269126911291282690e0215118105011269050702021d1c05061d1282710507021d1c02122005126d0e11411282751d1281611d1182790607011d12816104000011790615127501117906151265011179070002021129100c080002117911791179040611827d09200311827d11290c020615122101112907151181050111290900021d12820911290c050a01128269050a01128281050a0112828509000402112911290c080800040211290c0202350716121912825912710c08117911291282690c11791179021129128209128149021d11791d117908151181050111291d1282091d0e0407011d1c040a011248070704080e021d1c04061d12690515126501081c070a121512691282591269121515118105011269021d1269081d1215061512210112150b07021512210112151d12150615122101114c062002021219080615124502080c0420001225042001020207200302126902021d0711080812151259121902020c0c081129112912551281490211291d1c091001011d1e0011828d06200202126908072003021235020219070c0812813912591129128269080c114c1d1281390802112905000102114c08061512829101114c050001021215080615128291011215071512829101114c0a200108151282910113000715128291011215071511810501114c1407071215114c1d121508021511810501114c1129040a0112580500001280810707031d1c021d0c0307010c0400010102040001010c050a01128299050a0112829d08151245021280890209151181d9021280890209151181dd021280890227070912829912829d151181dd0212808902128149021d128299081d12829d151181d90212808902073001011d1e0002050a011280890e07051282a1128089021d12808908150703151181dd021280890202151181d902128089020500001280bd050701128091072002020e11810904070112590920021d0e1d031182a50607021d0e1d030807050e021d0e080207000202126d126d05200208080804070112250820001512210112190615122101121907151181050112190515123d010e0615128189010e2a070d151265010e0e1219151265010e0e151221010e1225021d0e081511810501121915128189010e1d031c0709151265010e12190e151221010e12250802151181050112191d0309200208128091128091042001080c05070308080c07151221011280910715123d011280910815128189011280910815128265011280910815118105011280910720020112311219480719151265010e121915122101128091151265010e080808128091020e12310812809108081280840e021511810501121915128189011280911d0e0815118105011280911d1c1d1c0615122101126426070b151265010e1219151265010e128091020e021511810501121915128189011280911d0e08071511810501126419070908126415122101128091080802151181050112641c1d1c0c070312640215118105011264081512450212591264061512210112590715118105011259140707125912591264126412641511810501125902042001021c07151282b1020a020d300102010e151282b1020a1e00030a0102062002010e1d1c050702126402040a01126c090703128091128149020500001280a11207071280910212814912691281491280ad020600010111809d07000208121912190806151282650112190500001180a50400010d0d071512826501121922070c1280911280910e151265010e1219021d128091081d0e081d1c15118105011219050a0112809905000011809d072004010c0c0c0c07151221011280b10815118105011280b10e07031280b115118105011280b102062001011182c10820030108081180b90807021280b11280b10500001282c90520001280b5062001011280b5062001011182cd062001011182d10720040108080808062001011282d50520001282d9062001011180b90807021280b51280b5042001010c062001011280b11507071280b51282d91280b51d1282d91d1282d908021b07091180b91180b91180b91280b11282d9021d1282d91d1282d9080500001180b90500001182dd060001011180b9060001011182dd090002011180a91282e10c00031182dd112911811511291000051180a9081180a91282e50e1280b5070002011180a90e1207081180b91180b91180b91182dd080c0e020a0003011180a90e1280b50720020c1282e90c0e00031180a51180a91180a51180a90a0003021180a90e1280b51e070d080c151221010e0e0c0e0c021280ad1280ad12808815118105010e021107061219126912150e151181050112190204061280ad050a011280c90520001180a50520001180a90a1001021e001e00128111050a011280c1062001011282ed0520001282ed062001011282f1063001011e0002050a011280c51f070e1280c11280c11280c91280c90c0c0c0c12691280c90c12808c021180a9062001011180a5052002010c0c050a011280cd0907031280bd128111020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f77730100f891010000000000000000000e920100002000000000000000000000000000000000000000000000009201000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058a00100940200000000000000000000940234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004f4010000010053007400720069006e006700460069006c00650049006e0066006f000000d001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000060002000010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d005200650063006f00760065007200790053007000610077006e0042006500740061005600340032002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000006800200001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d005200650063006f00760065007200790053007000610077006e0042006500740061005600340032002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009001000c000000203200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local recoveryHelper
local function loadRecovery()
  if recoveryHelper and recoveryHelper.pid==session then return recoveryHelper end
  local class=mono_findClass('ValheimSoloToolkit','RecoverySpawnBetaV42')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_RecoverySpawnBetaV42_'..session..'_'..os.time()..'.dll'
    local file=assert(io.open(path,'wb'),'Cannot write death recovery helper')
    local binary=recoveryHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write death recovery helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path);os.remove(path)
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(pointer(assembly,'Death recovery assembly')),'ValheimSoloToolkit','RecoverySpawnBetaV42'),'Death recovery class')
  end
  recoveryHelper={pid=session,class=class,queue=matchingMethod(class,'Queue',{18,8,14},1),summon=matchingMethod(class,'QueueSummon',{18,14,14},1),
    tick=matchingMethod(class,'Tick',{18},1),cancel=matchingMethod(class,'Cancel',{},1),
    sortState=matchingMethod(class,'SortingState',{},8),sortStop=matchingMethod(class,'StopSorting',{},1),sortStatus=matchingMethod(class,'SortingStatus',{},14),clearState=matchingMethod(class,'ClearState',{},8),clearStop=matchingMethod(class,'StopClear',{},1),loot=matchingMethod(class,'QueueLoot',{18,8,8,14},1),lootState=matchingMethod(class,'LootState',{},8),lootStop=matchingMethod(class,'StopLoot',{},1),harvestStop=matchingMethod(class,'StopHarvest',{},1),magnetStop=matchingMethod(class,'StopMagnet',{},1),harvestStatus=matchingMethod(class,'HarvestStatus',{},14),magnetStatus=matchingMethod(class,'MagnetStatus',{},14),plant=matchingMethod(class,'QueuePlant',{18,14,14},1),plantCatalogue=matchingMethod(class,'PlantCatalogue',{},14),plantStatus=matchingMethod(class,'PlantStatus',{},14),plantStop=matchingMethod(class,'StopPlant',{},1),quality=matchingMethod(class,'QueueItemQuality',{18,18,8,14},1),prefab=matchingMethod(class,'QueuePrefab',{18,14,8,8,14},1),spawnCatalogue=matchingMethod(class,'SpawnCatalogue',{},14),animal=matchingMethod(class,'QueueAnimal',{18,14,14},1),tameCatalogue=matchingMethod(class,'TamingCatalogue',{},14),tameStatus=matchingMethod(class,'TamingStatus',{},14),tameStop=matchingMethod(class,'StopTaming',{},1),boatQueue=matchingMethod(class,'QueueBoat',{18,8,14},1),boatOptions=matchingMethod(class,'SetBoatOptions',{8},1),boatProtected=matchingMethod(class,'BoatProtected',{18},2),boatStop=matchingMethod(class,'StopBoat',{},1),boatStatus=matchingMethod(class,'BoatStatus',{},14),state=matchingMethod(class,'GetState',{},8),status=matchingMethod(class,'GetStatus',{},14)}
  return recoveryHelper
end
local function finite(v,limit) return type(v)=='number' and v==v and math.abs(v)<=limit end
local function validPosition(p)
  return p and finite(p.x,20000) and finite(p.y,10000) and finite(p.z,20000)
end
local function vector(address)
  local p={x=readFloat(address),y=readFloat(address+4),z=readFloat(address+8)}
  assert(validPosition(p),'Position is unreadable or outside supported world coordinates.')
  return p
end
local function typedOffset(class,name,typename)
  local f=field(class,name)
  assert(f.typename==typename,'Unexpected field type for '..name)
  return offset(class,name)
end
local function singleton(class,name)
  local f=field(class,name)
  assert(f.isStatic,'Expected static field '..name)
  local storage=f.staticAddress
  if not storage or storage<=f.offset then storage=pointer(mono_class_getStaticFieldAddress(class),'Static storage')+f.offset end
  return pointer(readPointer(storage),name)
end
local function context()
  local s=playerContext()
  assert(playerIdentity(s),'Player changed; refresh again.')
  local zc=pointer(mono_findClass('','ZNet'),'ZNet class')
  local wf=field(zc,'m_world')
  local world
  if wf.isStatic then world=singleton(zc,'m_world')
  else world=pointer(readPointer(singleton(zc,'m_instance')+offset(zc,'m_world')),'World') end
  local wc=objectClass(world)
  local uid=readBytes(world+typedOffset(wc,'m_uid','System.Int64'),8,true)
  assert(uid and #uid==8,'World ID unavailable; load a solo world first.')
  local hex={}; for _,b in ipairs(uid) do hex[#hex+1]=string.format('%02X',b) end
  s.world=table.concat(hex)
  return s
end
local function currentPosition(s)
  local nv=pointer(readPointer(s.player+offset(playerClass,'m_nview')),'Player network view')
  local zdo=pointer(readPointer(nv+offset(objectClass(nv),'m_zdo')),'Player world object')
  local p=vector(zdo+typedOffset(objectClass(zdo),'m_position','UnityEngine.Vector3'))
  assert(playerIdentity(s),'Player changed while reading position.')
  return p
end
local function encodeName(name)
  return (name:gsub('.',function(c) return string.format('%02X',string.byte(c)) end))
end
local function decodeName(hex)
  assert(#hex<=320 and #hex%2==0 and not hex:find('[^%x]'),'Invalid saved location name')
  return (hex:gsub('%x%x',function(n) return string.char(tonumber(n,16)) end))
end
local function loadSaved(key)
  settings=settings or getSettings('ValheimSoloToolkit.Teleports.v1')
  local raw=settings['world_'..key] or ''
  assert(#raw<=131072,'Saved-location data is too large.')
  local result={}
  for line in raw:gmatch('[^\r\n]+') do
    local x,y,z,name=line:match('^([^|]+)|([^|]+)|([^|]+)|(%x+)$')
    local p={x=tonumber(x),y=tonumber(y),z=tonumber(z)}
    assert(name and validPosition(p),'Saved-location data is invalid; no locations were overwritten.')
    p.name=decodeName(name); p.source='Saved'; p.world=key
    result[#result+1]=p
  end
  assert(#result<=256,'Too many saved locations.')
  return result
end
local function persist()
  local lines={}
  for _,p in ipairs(saved) do
    lines[#lines+1]=string.format('%.9g|%.9g|%.9g|%s',p.x,p.y,p.z,encodeName(p.name))
  end
  local raw=table.concat(lines,'\n')
  settings['world_'..worldKey]=raw
  assert(settings['world_'..worldKey]==raw,'Could not save locations in Cheat Engine settings.')
end
local function favoriteKey(p)
  if p.source=='Player' then return 'player|'..encodeName(p.name) end
  return string.format('location|%s|%s|%.9g|%.9g|%.9g',p.source,encodeName(p.name),p.x,p.y,p.z)
end
local function loadFavorites(key)
  local raw=settings['favorites_'..key] or ''
  assert(#raw<=131072,'Favorite data is too large; nothing was overwritten.')
  local result,count={},0
  for line in raw:gmatch('[^\r\n]+') do
    assert(#line<=1024 and (line:match('^player|%x+$') or line:match('^location|')),
      'Favorite data is invalid; nothing was overwritten.')
    if not result[line] then count=count+1;result[line]=true end
  end
  assert(count<=2048,'Too many favorite destinations.')
  return result
end
local function persistFavorites()
  local keys={};for key,value in pairs(favorites) do if value then keys[#keys+1]=key end end
  assert(#keys<=2048,'Maximum of 2048 favorite destinations per world.')
  table.sort(keys)
  local raw=table.concat(keys,'\n')
  assert(#raw<=131072,'Favorite data is too large.')
  settings['favorites_'..worldKey]=raw
  assert(settings['favorites_'..worldKey]==raw,'Could not save favorite destinations.')
end
local function updateFavoriteButton()
  if not favoriteButton then return end
  local p=entries[destinations.ItemIndex+1]
  favoriteButton.Enabled=p~=nil
  favoriteButton.Caption=p and p.favorite and 'Unfavorite' or 'Favorite'
end
local function renderDestinations(selectedKey)
  table.sort(entries,function(a,b)
    if a.favorite~=b.favorite then return a.favorite end
    return a.displayOrder<b.displayOrder
  end)
  destinations.Items.clear();destinations.ItemIndex=-1
  for i,p in ipairs(entries) do
    local item=destinations.Items.add()
    item.Caption=string.format('%s%-7s | %-28s | X %.1f  Y %.1f  Z %.1f',
      p.favorite and '* ' or '  ',p.source,p.name,p.x,p.y,p.z)
    if selectedKey and favoriteKey(p)==selectedKey then destinations.ItemIndex=i-1 end
  end
  updateFavoriteButton()
end
local function readPins(s)
  local mc=pointer(mono_findClass('','Minimap'),'Minimap class')
  local map=singleton(mc,'s_instance')
  local list=pointer(readPointer(map+offset(mc,'m_pins')),'Map pins')
  local lc=objectClass(list)
  local count=integer(list+offset(lc,'_size'),'pin count')
  local version=integer(list+offset(lc,'_version'),'pin version')
  assert(count>=0 and count<=10000,'Unexpected pin count.')
  local result={}
  if count>0 then
    local array=pointer(readPointer(list+offset(lc,'_items')),'Pin array')
    local capacity=readQword(array+0x18)
    assert(capacity and capacity>=count and capacity<=16384,'Unexpected pin-array layout.')
    for i=0,count-1 do
      local pin=pointer(readPointer(array+0x20+i*8),'Map pin')
      local pc=objectClass(pin)
      local p=vector(pin+typedOffset(pc,'m_pos','UnityEngine.Vector3'))
      local name=readPointer(pin+offset(pc,'m_name'))
      p.name=name and name~=0 and stringValue(name) or '(unnamed pin)'
      p.name=p.name:gsub('[\r\n\t]',' ')
      p.source='Map pin'; p.world=s.world
      -- Player markers also live in m_pins; use the refreshed roster for those.
      local kind=fields(pc).m_type
      local pinType=kind and readInteger(pin+kind.offset)
      -- This build's Minimap.UpdatePingPins creates type 12 through AddPin.
      if pinType==12 then p.source='Ping' end
      if pinType~=10 then result[#result+1]=p end
    end
  end
  assert(integer(list+offset(lc,'_version'),'pin version')==version
    and integer(list+offset(lc,'_size'),'pin count')==count,'Map pins changed; refresh again.')
  return result
end
local function readPlayers(s)
  local zc=pointer(mono_findClass('','ZNet'),'ZNet class')
  local net=singleton(zc,'m_instance')
  local list=pointer(readPointer(net+offset(zc,'m_players')),'Player roster')
  local lc=objectClass(list)
  local count=integer(list+offset(lc,'_size'),'player count')
  local version=integer(list+offset(lc,'_version'),'player-list version')
  assert(count>=0 and count<=256,'Unexpected player count.')
  if count==0 then return {},0 end
  local array=pointer(readPointer(list+offset(lc,'_items')),'Player array')
  local capacity=readQword(array+0x18)
  assert(capacity and capacity>=count and capacity<=1024,'Unexpected player-array layout.')
  local ac=objectClass(array)
  local pc=pointer(mono_class_getArrayElementClass(ac),'PlayerInfo class')
  assert(mono_class_isValueType(pc),'Expected inline PlayerInfo values.')
  local stride=mono_array_element_size(ac)
  assert(stride and stride>=32 and stride<=1024,'Unexpected PlayerInfo size.')
  local function inline(name,typename,size)
    local f=field(pc,name)
    assert(not f.isStatic and f.typename==typename and f.offset>=16
      and f.offset-16+size<=stride,'Unexpected PlayerInfo field: '..name)
    return f.offset-16
  end
  local nameOff=inline('m_name','System.String',8)
  local publicOff=inline('m_publicPosition','System.Boolean',1)
  local posOff=inline('m_position','UnityEngine.Vector3',12)
  local idOff=inline('m_characterID','ZDOID',8)
  local idClass=pointer(mono_findClass('','ZDOID'),'ZDOID class')
  local keyOff=typedOffset(idClass,'<UserKey>k__BackingField','System.UInt16')-16
  local valueOff=typedOffset(idClass,'<ID>k__BackingField','System.UInt32')-16
  assert(keyOff>=0 and keyOff+2<=8 and valueOff>=0 and valueOff+4<=8,'Unexpected ZDOID layout.')
  local function identity(address)
    local b=readBytes(address+keyOff,2,true)
    local id=readBytes(address+valueOff,4,true)
    assert(b and #b==2 and id and #id==4,'Unreadable player identity.')
    local parts={b[1],b[2],id[1],id[2],id[3],id[4]}
    local hex={};for _,v in ipairs(parts) do hex[#hex+1]=string.format('%02X',v) end
    return table.concat(hex)
  end
  local own=identity(net+typedOffset(zc,'m_characterID','ZDOID'))
  local result,hidden,seen={},0,{}
  for i=0,count-1 do
    local entry=array+0x20+i*stride
    local id=identity(entry+idOff)
    if id~=own and id~='000000000000' then
      local public=readBytes(entry+publicOff,1)
      assert(public==0 or public==1,'Unreadable position-sharing flag.')
      if public==1 then
        assert(not seen[id],'Player roster changed; refresh again.')
        seen[id]=true
        local p=vector(entry+posOff)
        p.name=stringValue(pointer(readPointer(entry+nameOff),'Player name')):gsub('[%c]',' ')
        p.source='Player';p.world=s.world;p.playerID=id
        result[#result+1]=p
      else hidden=hidden+1 end
    end
  end
  assert(readPointer(net+offset(zc,'m_players'))==list
    and integer(list+offset(lc,'_size'),'player count')==count
    and integer(list+offset(lc,'_version'),'player-list version')==version
    and readPointer(list+offset(lc,'_items'))==array
    and playerIdentity(s) and context().world==s.world,'Player roster/world changed; refresh again.')
  return result,hidden
end
local function refreshLocations()
  local selected=entries[destinations.ItemIndex+1]
  local selectedKey=selected and favoriteKey(selected)
  local s=context()
  local loaded=loadSaved(s.world)
  local pins=readPins(s)
  local playersOK,players,hidden=pcall(readPlayers,s)
  local playerError=not playersOK and tostring(players) or nil
  if not playersOK then players={} end
  assert(context().world==s.world and playerIdentity(s),'World changed while reading destinations.')
  local loadedFavorites=loadFavorites(s.world)
  worldKey=s.world; saved=loaded; favorites=loadedFavorites; entries={}
  for _,group in ipairs({saved,pins,players}) do
    for _,p in ipairs(group) do
      entries[#entries+1]=p
      p.favorite=favorites[favoriteKey(p)]==true;p.displayOrder=#entries
    end
  end
  renderDestinations(selected and selected.world==s.world and selectedKey or nil)
  local p=currentPosition(s)
  locationLabel.Caption=string.format('Current position: X %.2f   Y %.2f   Z %.2f   (Y = height)',p.x,p.y,p.z)
  teleportStatus.Caption=string.format('%d saved locations, %d map pins/pings. Select a destination, then Teleport selected.',#saved,#pins)
    ..(playerError and (' Players unavailable: '..playerError)
      or string.format(' %d shared players; %d not sharing position.',#players,hidden))
end
local function action(fn)
  local ok,err=pcall(fn)
  if not ok then
    if teleportStatus then teleportStatus.Caption=tostring(err) end
    showMessage('Valheim teleport: '..tostring(err))
  end
end
local function installHook(s,recovery)
  if hook and recovery and not hook.recovery then ValheimTeleportStop() end
  if hook then
    assert(hook.pid==s.pid and getOpenedProcessID()==s.pid,'Game process changed. Close and reopen Teleport tools.')
    return
  end
  local method=matchingMethod(playerClass,'UpdateTeleport',{12},1)
  local teleport=matchingMethod(playerClass,'TeleportTo',{17,17,2},2)
  local entry=pointer(mono_compile_method(method),'UpdateTeleport code')
  local target=pointer(mono_compile_method(teleport),'TeleportTo code')
  local size,replay=0,{}
  while size<14 do
    local n=getInstructionSize(entry+size)
    assert(n and n>0 and n<=15,'Cannot decode teleport prologue')
    replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
  end
  local bytes=readBytes(entry,size,true)
  assert(bytes and #bytes==size,'Cannot read teleport prologue')
  local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
  local original=table.concat(hex,' ')
  -- Windows x64: Vector3 and Quaternion arguments are passed by address.
  -- Preserve UpdateTeleport's dt (XMM1) and all volatile registers around the call.
  local script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhTeleportCode,4096,%X)
label(vhTeleportData)
label(vhTeleportRestore)
label(vhTeleportResult)
registersymbol(vhTeleportData)
vhTeleportCode:
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
%s
mov r11,vhTeleportData
cmp dword ptr [r11],1
jne vhTeleportRestore
cmp [r11+8],rcx
jne vhTeleportRestore
mov rax,%X
cmp [rax],rcx
jne vhTeleportRestore
mov dword ptr [r11],2
lea rdx,[r11+20]
lea r8,[r11+30]
mov r9d,1
call %X
test al,al
mov eax,4
je vhTeleportResult
mov eax,3
vhTeleportResult:
mov r11,vhTeleportData
mov [r11],eax
vhTeleportRestore:
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
%s
jmp %X
align 10 CC
vhTeleportData:
dq 0 0 0 0 0 0 0 0
%X:
db FF 25 00 00 00 00
dq vhTeleportCode
%s
[DISABLE]
%X:
db %s
unregistersymbol(vhTeleportData)
// Keep the retired 4 KB allocation until game exit: an in-flight call may still return here.
]],entry,original,entry,recovery and string.format('mov rax,%X\ncmp [rax],rcx\njne vhTeleportRestore\ncall %X\nmov rcx,[rsp+28]',s.storage,pointer(mono_compile_method(recovery.tick),'Recovery tick')) or '',s.storage,target,table.concat(replay,'\n'),entry+size,entry,
    size>14 and string.format('nop %X',size-14) or '',entry,original)
  local ok,info=autoAssemble(script,false)
  assert(ok,'Teleport hook installation failed: '..tostring(info))
  hook={pid=s.pid,script=script,info=info,recovery=recovery}
  hook.data=pointer(getAddressSafe('vhTeleportData'),'Teleport request buffer')
end
local stopTeleport
local function cancelQueued()
  if not hook or not hook.data or getOpenedProcessID()~=hook.pid
    or getProcessIDFromProcessName('valheim.exe')~=hook.pid then pending=nil;return end
  local state=readInteger(hook.data)
  if state==2 or state==3 then
    teleportStatus.Caption='Teleport is already running; let the game finish loading the destination.'
    return
  end
  -- Retire the entire buffer on cancellation. Never reuse a possibly claimed packet.
  stopTeleport();window.show()
  teleportStatus.Caption='Queue cancelled. If the game already claimed the request, that teleport may finish.'
end
stopTeleport=function()
  if poll then poll.Enabled=false end
  if hook then
    if getOpenedProcessID()==hook.pid and getProcessIDFromProcessName('valheim.exe')==hook.pid then
      if hook.recovery then invoke(hook.recovery.cancel,0,{}) end
      if hook.data then writeQword(hook.data+8,0) end
      local ok,err=autoAssemble(hook.script,false,hook.info)
      assert(ok,'Could not remove teleport hook: '..tostring(err))
    end
    hook=nil
  end
  pending=nil
  if window then window.hide() end
  if spawnWindow then spawnWindow.hide() end
end
ValheimTeleportStop=stopTeleport
local oldClose,oldDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopTeleport();return oldClose() end
form.OnDestroy=function() stopTeleport();if spawnWindow then spawnWindow.destroy();spawnWindow=nil end;if window then window.destroy();window=nil end;oldDestroy() end
local function queueDestination(p)
  assert(validPosition(p),'Invalid coordinates. X/Z must be within +/-20000 and Y within +/-10000.')
  local s=context()
  assert(p.world==s.world,'This destination belongs to a different world. Refresh destinations.')
  if p.source=='Player' then
    local target
    for _,v in ipairs(readPlayers(s)) do if v.playerID==p.playerID then target=v;break end end
    assert(target,'Player disconnected, changed character, or stopped sharing position. Refresh players.')
    -- Aim slightly beside the latest received position, rather than inside the player.
    p={x=target.x+3,y=target.y+1,z=target.z,name=target.name,world=s.world}
    assert(validPosition(p),'Player destination is outside supported coordinates.')
  end
  assert(not pending,'A teleport is already queued or running.')
  assert(readBytes(s.player+typedPlayerOffset('m_teleporting','System.Boolean'),1)==0,'Player is already teleporting.')
  local cooldown=readFloat(s.player+typedPlayerOffset('m_teleportCooldown','System.Single'))
  assert(cooldown and cooldown>=2,'Wait a few seconds after loading or teleporting, then try again.')
  installHook(s)
  assert(readInteger(hook.data)~=2,'Previous teleport call is still running.')
  assert(writeInteger(hook.data,0),'Cannot prepare teleport request')
  assert(writeQword(hook.data+8,s.player),'Cannot set teleport player')
  for i,v in ipairs({p.x,p.y,p.z,0,0,0,0,1}) do
    assert(writeFloat(hook.data+0x20+(i-1)*4,v),'Cannot write teleport destination')
  end
  assert(playerIdentity(s) and context().world==s.world,'Player or world changed before teleport.')
  assert(writeInteger(hook.data,1),'Cannot publish teleport request')
  pending={session=s,name=p.name or 'Coordinates',ticks=0,target={x=p.x,y=p.y,z=p.z}}
  poll.Enabled=true
  teleportStatus.Caption='Teleport queued; carried-item restrictions are bypassed. Return to Valheim and unpause; distant areas may take 15+ seconds to load.'
end
local function pollTeleport()
  if not pending then return end
  local s=pending.session
  assert(playerIdentity(s) and context().world==s.world,'World/player changed; queued teleport cancelled.')
  if pending.recovery then
    local h=pending.recovery
    local state=invoke(h.state,0,{})
    local text=invoke(h.status,0,{})
    teleportStatus.Caption=type(text)=='string' and text or stringValue(pointer(text,'Recovery status'))
    if pending.itemQuality then status.Caption=teleportStatus.Caption elseif pending.taming and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif pending.trophy and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif pending.spawn and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end
    if state==0 or state==3 or state==4 then pending=nil end
    return
  end
  local state=readInteger(hook.data)
  pending.ticks=pending.ticks+1
  if state==4 then
    pending=nil;teleportStatus.Caption='Game declined the teleport. Wait a few seconds and try again.'
  elseif state==3 then
    pending.accepted=true
    if readBytes(s.player+typedPlayerOffset('m_teleporting','System.Boolean'),1)==0 then
      local p=currentPosition(s)
      local target=pending.target
      local distance=math.sqrt((p.x-target.x)^2+(p.z-target.z)^2)
      teleportStatus.Caption=distance<10 and ('Arrived: '..pending.name)
        or 'Teleport ended; arrival could not be confirmed. Refresh position before trying again.'
      pending=nil
      locationLabel.Caption=string.format('Current position: X %.2f   Y %.2f   Z %.2f',p.x,p.y,p.z)
    else teleportStatus.Caption='Teleporting: loading destination terrain...' end
  elseif state==1 and pending.ticks>=40 then
    teleportStatus.Caption='Still queued: return to Valheim and unpause, or click Cancel queued.'
  end
end
local function queueRecovery(mode)
  assert(not pending,'A teleport or recovery is already queued. Finish it or click Cancel queued.')
  local s=context()
  assert(readBytes(s.player+typedPlayerOffset('m_teleporting','System.Boolean'),1)==0,'Finish the current teleport first.')
  if hook then stopTeleport();if mode<=3 then window.show() end end
  local h=loadRecovery()
  installHook(s,h)
  assert(playerIdentity(s) and context().world==s.world,'World/player changed before recovery.')
  invoke(h.queue,0,{{type=vtPointer,value=s.player},{type=vtDword,value=mode},{type=vtString,value=s.world}})
  pending={session=s,recovery=h};poll.Enabled=true
  teleportStatus.Caption='Recovery queued. Return to Valheim and unpause.'
end
local function openTeleportWindow()
  if window then window.show();action(refreshLocations);return end
  window=createForm(false);window.Caption='Valheim | Teleport tools | Recovery v2'
  window.Width=960;window.Height=550;window.Position='poScreenCenter';window.BorderStyle='bsSizeable'
  local help=createLabel(window);help.AutoSize=false;help.WordWrap=true
  help.Caption='Map: create a named marker or ping in Valheim, then Refresh locations and Teleport selected. Refresh while pings are visible. Saved positions are local bookmarks, not map markers. Players must share their position. Click Help & tips for the full guide.'
  window.Color=0x202020;window.Font.Color=0xE6E6E6;help.Font.Color=0x8DCCE8
  locationLabel=createLabel(window);locationLabel.AutoSize=false
  locationLabel.Caption='Current position: click Refresh locations. Position uses the player world-object snapshot; stand still when saving.'
  destinations=createListView(window);destinations.Font.Name='Consolas'
  destinations.ViewStyle='vsReport';destinations.RowSelect=true
  destinations.ReadOnly=true;destinations.HideSelection=false;destinations.MultiSelect=false
  local column=destinations.Columns.add();column.Caption='Destinations - favorites first';column.Width=1100
  destinations.Color=0x181818;destinations.Font.Color=0xE6E6E6
  destinations.OnCustomDrawItem=function(sender,item)
    local p=entries[item.Index+1]
    sender.Canvas.Font.Color=p and p.favorite and 0x00D7FF or 0xE6E6E6
    return true
  end
  destinations.OnSelectItem=function() updateFavoriteButton() end
  teleportStatus=createLabel(window);teleportStatus.AutoSize=false;teleportStatus.WordWrap=true
  local controls={}
  local teleportHints={
    ['Refresh locations']='Reload saved bookmarks, map markers, visible pings and shared players. Create markers/pings in the game map first. Refresh before a ping expires.',
    ['Save current position']='Save a named local bookmark for this world. Stand still first. Persists in Cheat Engine settings; does not create a map marker.',
    ['Teleport selected']='Teleport to the selected marker, ping, bookmark or shared player. Return to the game and unpause. Player positions are re-read when clicked, with a 3m sideways offset.',
    ['Enter coordinates']='Enter X Y Z separated by spaces. Y is height. Queues a teleport to these world coordinates.',
    ['Delete saved location']='Remove a selected local bookmark only. Remove game map markers in the game map.',
    ['Cancel queued']='Cancel a waiting teleport request. Does not undo a teleport already accepted by the game.',
    ['Refresh players']='Reload shared player positions. Players must enable Visible to other players on their map. Also refreshes markers and bookmarks.',
    ['Favorite']='Toggle the selected location or shared player as a favorite. Favorites are gold and stay at the top. Saved per world; player favorites follow their names as they move.',
    ['Last death']='Teleport to your last recorded death in this world, even after the tombstone is emptied or moved.',
    ['Teleport to tombstone']='Teleport beside your latest remaining tombstone. Remote clients may not know distant tombstones; use Last death instead.',
    ['Bring tombstone to me']='Solo/host: move your latest tombstone beside you with all contents intact. Stand on open solid ground. Never targets another character.'
  }
  local function button(caption,fn)
    local b=createButton(window);b.Caption=caption;b.OnClick=function() action(fn) end
    if styleToggle then styleToggle(b) end
    hint(b,teleportHints[caption] or 'Open the full toolkit guide.')
    controls[#controls+1]=b
    return b
  end
  button('Refresh locations',refreshLocations)
  button('Save current position',function()
    local s=context();assert(s.world==worldKey,'Refresh locations for this world first.')
    local p=currentPosition(s)
    local name=inputQuery('Save teleport location','Name this position:', '')
    if name==nil then return end
    name=name:match('^%s*(.-)%s*$')
    assert(#name>0 and #name<=160 and not name:find('[%c]'),'Use a name of 1-160 bytes without control characters.')
    assert(playerIdentity(s) and context().world==s.world,'World changed while naming the location.')
    assert(#saved<256,'Maximum of 256 saved locations per world.')
    p.name=name;p.source='Saved';p.world=s.world
    saved[#saved+1]=p;persist();refreshLocations()
    teleportStatus.Caption='Saved '..name..'. Locations persist in local Cheat Engine settings.'
  end)
  button('Teleport selected',function()
    local p=entries[destinations.ItemIndex+1];assert(p,'Select a bookmark, map pin, ping or shared player first.')
    queueDestination(p)
  end)
  button('Enter coordinates',function()
    local s=context();local p=currentPosition(s)
    local raw=inputQuery('Teleport coordinates','Enter X Y Z separated by spaces (Y is height):',string.format('%.2f %.2f %.2f',p.x,p.y,p.z))
    if raw==nil then return end
    local x,y,z=raw:match('^%s*(%S+)%s+(%S+)%s+(%S+)%s*$')
    queueDestination({x=tonumber(x),y=tonumber(y),z=tonumber(z),name='Coordinates',world=s.world})
  end)
  button('Delete saved location',function()
    local p=entries[destinations.ItemIndex+1]
    assert(p and p.source=='Saved','Select one of your saved locations. Map pins are edited in the game.')
    assert(context().world==worldKey,'World changed. Refresh locations first.')
    local key=favoriteKey(p)
    if favorites[key] then favorites[key]=nil;persistFavorites() end
    for i,v in ipairs(saved) do if v==p then table.remove(saved,i);break end end
    persist();refreshLocations()
  end)
  button('Cancel queued',cancelQueued)
  button('Refresh players',refreshLocations)
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
  end)
  button('Last death',function() queueRecovery(1) end)
  button('Teleport to tombstone',function() queueRecovery(2) end)
  button('Bring tombstone to me',function() queueRecovery(3) end)
  favoriteButton=button('Favorite',function()
    local p=entries[destinations.ItemIndex+1]
    assert(p,'Select a location or shared player first.')
    assert(context().world==worldKey,'World changed. Refresh locations first.')
    local key=favoriteKey(p);local previous=favorites[key]
    favorites[key]=not previous or nil
    local ok,err=pcall(persistFavorites)
    if not ok then favorites[key]=previous;error(err) end
    for _,entry in ipairs(entries) do entry.favorite=favorites[favoriteKey(entry)]==true end
    renderDestinations(key)
    teleportStatus.Caption=(favorites[key] and 'Favorited ' or 'Unfavorited ')..p.name..'.'
  end)
  updateFavoriteButton()
  local guide=createLabel(window);guide.Caption='? Help & tips';guide.Font.Color=0x8DCCE8
  guide.Cursor=-21;guide.OnClick=openHelp
  hint(guide,'Read step-by-step map marker, ping, bookmark and player teleport instructions.')
  hint(destinations,'Select a destination, then Teleport selected. Ping and Map pin rows use coordinates captured at refresh.')
  local resizing=false
  local function layout()
    if resizing then return end;resizing=true
    local w=window.ClientWidth or window.Width-16
    local h=window.ClientHeight or window.Height-40
    if w<760 then window.Width=window.Width+760-w;w=760 end
    if h<470 then window.Height=window.Height+470-h;h=470 end
    place(help,window,16,12,w-32,54)
    place(locationLabel,window,16,72,w-32,40);locationLabel.WordWrap=true
    local bw=math.floor((w-56)/3)
    for i,b in ipairs(controls) do place(b,window,16+((i-1)%3)*(bw+12),118+math.floor((i-1)/3)*42,bw,34) end
    local guideTop=118+math.ceil(#controls/3)*42+2
    place(guide,window,16,guideTop,w-32,24)
    local listTop=guideTop+30
    place(destinations,window,16,listTop,w-32,h-listTop-76)
    place(teleportStatus,window,16,h-64,w-32,52)
    resizing=false
  end
  window.OnResize=layout;window.OnShow=layout
  window.OnClose=function() stopTeleport();return caHide end
  poll=createTimer(window,false);poll.Interval=250
  poll.OnTimer=function()
    local ok,err=pcall(pollTeleport)
    if not ok then
      local stopped,stopError=pcall(stopTeleport)
      local trophyRequest=pending and pending.trophy;local spawnRequest=pending and pending.spawn;local boatRequest=pending and pending.boat;local tamingRequest=pending and pending.taming;local qualityRequest=pending and pending.itemQuality;pending=nil;poll.Enabled=false;if tamingRequest and tamingWindow then tamingWindow.show() elseif spawnRequest and spawnWindow then spawnWindow.show() elseif not trophyRequest and not boatRequest and not qualityRequest then window.show() end
      teleportStatus.Caption='Teleport stopped: '..tostring(err)
        ..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))
      if qualityRequest then status.Caption=teleportStatus.Caption elseif tamingRequest and tamingStatus then tamingStatus.Caption=teleportStatus.Caption elseif trophyRequest and trophyStatus then trophyStatus.Caption=teleportStatus.Caption elseif spawnRequest and spawnStatus then spawnStatus.Caption=teleportStatus.Caption end
    end
    if not pending then poll.Enabled=false end
  end
  layout();window.show();action(refreshLocations)
end
teleportButton.OnClick=function() action(openTeleportWindow) end
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


;(function()
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
  local class=pointer(h.class,'Replenish helper')
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

end)()
;(function()
local spawnNames,spawnLabels={{},{},{},{}},{{},{},{},{}}
local lastSpawnCatalogue
local function readCatalogueString(value,label)
  if type(value)=='string' then return value end
  local address=pointer(value,label)
  local length=integer(address+0x10,label..' length')
  assert(length>=0 and length<=1048576,'Invalid or oversized '..label)
  if length==0 then return '' end
  return assert(readString(address+0x14,length*2,true),'Cannot read '..label)
end
local function readSpawnNames(h)
  local value=invoke(h.spawnCatalogue,0,{})
  local text=readCatalogueString(value,'Spawn catalogue')
  -- An uninitialized helper must not erase a previously loaded catalogue.
  if text=='' then return false end
  if text==lastSpawnCatalogue then return false end
  spawnNames,spawnLabels={{},{},{},{}},{{},{},{},{}}
  for row in text:gmatch('[^\r\n]+') do
    local kind,name,label=row:match('^(%d+)|([^|]+)|?(.*)$');kind=tonumber(kind)
    if kind and kind>=0 and kind<=3 then
      local names,labels=spawnNames[kind+1],spawnLabels[kind+1]
      names[#names+1]=name;labels[#labels+1]=(label and label~='' and label~=name) and (label..' ['..name..']') or name
    end
  end
  lastSpawnCatalogue=text;return true
end
local function fillSpawnDropdown(combo,kind)
  local previous=(combo.spawnNames and combo.spawnNames[combo.ItemIndex+1]) or combo.Text;combo.Items.clear()
  local names=spawnNames[kind+1]
  for i,name in ipairs(names) do combo.Items.add(spawnLabels[kind+1][i] or name) end
  combo.ItemIndex=#names>0 and 0 or -1
  for i,name in ipairs(names) do if name==previous or (spawnLabels[kind+1][i] or name)==previous then combo.ItemIndex=i-1;break end end
  combo.spawnNames=names
end
local function createSpawnStars(parent,left,top,width)
  local combo=createComboBox(parent);combo.Left=left;combo.Top=top;combo.Width=width;combo.Style='csDropDownList'
  for _,label in ipairs({'0 stars (normal)','1 star','2 stars'}) do combo.Items.add(label) end
  combo.ItemIndex=0
  return combo
end
local function queueSpawnAction(kind,name,route,stars)
  assert(not pending,'Another toolkit action is pending. Finish it first.')
  local s=context();if hook then stopTeleport() end
  local h=loadRecovery();installHook(s,h)
  if name then invoke(h.prefab,0,{{type=vtPointer,value=s.player},{type=vtString,value=name},{type=vtDword,value=kind},{type=vtDword,value=stars or 0},{type=vtString,value=s.world}})
  else invoke(h.queue,0,{{type=vtPointer,value=s.player},{type=vtDword,value=32},{type=vtString,value=s.world}}) end
  pending={session=s,recovery=h};pending[route]=true;poll.Enabled=true
  return h
end
do
local helper,timer,combos,renderedCatalogue
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() if timer then timer.Enabled=false end;return close() end
form.OnDestroy=function() if timer then timer.Enabled=false end;destroy() end
spawnButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if spawnWindow then spawnWindow.show();return end
  spawnWindow=createForm(false);spawnWindow.Caption='Valheim | Spawn';spawnWindow.Width=800;spawnWindow.Height=435;spawnWindow.Position='poScreenCenter'
  spawnWindow.Color=0x202020;spawnWindow.Font.Color=0xE6E6E6
  local guide=createLabel(spawnWindow);guide.Left=16;guide.Top=16;guide.Width=745;guide.Height=52;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Lists come from your loaded game. Refresh, tab back into Valheim and press Esc if needed to close the pause menu; let the game run once. Creatures and merchants spawn beside you; items/resources spawn at your feet. Items show in-game names with prefab names in brackets.'
  local starLabel=createLabel(spawnWindow);starLabel.Left=16;starLabel.Top=80;starLabel.Caption='Creature stars'
  local stars=createSpawnStars(spawnWindow,170,76,190)
  combos={}
  for kind,title in ipairs({'Monsters / creatures','Merchants','Items / resources'}) do
    local label=createLabel(spawnWindow);label.Left=16;label.Top=120+(kind-1)*54;label.Caption=title
    local combo=createComboBox(spawnWindow);combo.Left=170;combo.Top=116+(kind-1)*54;combo.Width=390;combo.Style='csDropDownList';combos[kind]=combo
    local button=createButton(spawnWindow);button.Left=574;button.Top=116+(kind-1)*54;button.Width=185;button.Height=30;button.Caption='Spawn selected'
    local category=kind-1
    button.OnClick=function()
      local ok,err=pcall(function()
        local name=spawnNames[category+1][combo.ItemIndex+1];assert(name,'Refresh the catalogue and select a prefab first.')
        helper=queueSpawnAction(category,name,'spawn',category==0 and stars.ItemIndex or 0);timer.Enabled=true;spawnWindow.show()
      end)
      spawnStatus.Caption=ok and 'Spawn queued. Return to Valheim and unpause.' or tostring(err)
    end
    if styleToggle then styleToggle(button,false) end
  end
  spawnStatus=createLabel(spawnWindow);spawnStatus.Left=16;spawnStatus.Top=315;spawnStatus.Width=745;spawnStatus.Height=68;spawnStatus.AutoSize=false;spawnStatus.WordWrap=true;spawnStatus.Caption='Refresh catalogue to populate the dropdowns.'
  local refresh=createButton(spawnWindow);refresh.Left=16;refresh.Top=280;refresh.Width=230;refresh.Height=30;refresh.Caption='Refresh spawn catalogue'
  refresh.OnClick=function()
    local ok,err=pcall(function() helper=queueSpawnAction(0,nil,'spawn');timer.Enabled=true;spawnWindow.show() end)
    spawnStatus.Caption=ok and 'Catalogue queued. Return to Valheim and unpause once.' or tostring(err)
  end
  local cancel=createButton(spawnWindow);cancel.Left=260;cancel.Top=280;cancel.Width=230;cancel.Height=30;cancel.Caption='Cancel queued spawn'
  cancel.OnClick=function()
    local ok,err=pcall(function()
      if pending and pending.spawn then stopTeleport() end;spawnWindow.show()
    end)
    spawnStatus.Caption=ok and 'Unsent spawn request cancelled. A completed spawn remains in the world.' or tostring(err)
  end
  if styleToggle then styleToggle(refresh,false);styleToggle(cancel,false) end
  timer=createTimer(spawnWindow,false);timer.Interval=500
  timer.OnTimer=function()
    if not helper or getOpenedProcessID()~=helper.pid or getProcessIDFromProcessName('valheim.exe')~=helper.pid then timer.Enabled=false;return end
    local ok,err=pcall(function()
      readSpawnNames(helper)
      -- Taming can update the shared data before this window polls it.
      if lastSpawnCatalogue and renderedCatalogue~=lastSpawnCatalogue then
        for i,combo in ipairs(combos) do fillSpawnDropdown(combo,i-1) end
        renderedCatalogue=lastSpawnCatalogue
      end
    end)
    if not ok then timer.Enabled=false;spawnStatus.Caption=tostring(err) end
  end
  spawnWindow.OnClose=function() if pending and pending.spawn then stopTeleport() end;return caHide end
  for i,combo in ipairs(combos) do fillSpawnDropdown(combo,i-1) end
  renderedCatalogue=lastSpawnCatalogue
  spawnWindow.show();refresh.OnClick()
end) end
end

do
local helper,timer,list,entries,lastCatalogue,scanStatus,spawnChoice,spawnCatalogueText
entries={}
local function stopTamingUI()
  if timer then timer.Enabled=false end
  if helper and getOpenedProcessID()==helper.pid and getProcessIDFromProcessName('valheim.exe')==helper.pid then
    if pending and pending.taming then pcall(function() invoke(helper.cancel,0,{}) end);pending=nil;poll.Enabled=false end
    pcall(function() invoke(helper.tameStop,0,{}) end)
  end
  if tamingWindow then tamingWindow.hide() end
end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopTamingUI();return close() end
form.OnDestroy=function() stopTamingUI();if tamingWindow then tamingWindow.destroy();tamingWindow=nil;tamingStatus=nil end;destroy() end
local function queue(mode,key)
  local ok,err=pcall(function()
    if key then
      assert(not pending,'Another toolkit action is pending. Finish it first.')
      local s=context();if hook then stopTeleport() end
      local h=loadRecovery();installHook(s,h)
      invoke(h.animal,0,{{type=vtPointer,value=s.player},{type=vtString,value=key},{type=vtString,value=s.world}})
      pending={session=s,recovery=h,taming=true};poll.Enabled=true
    else queueRecovery(mode);pending.taming=true end
    helper=hook.recovery;timer.Enabled=true;tamingWindow.show()
  end)
  tamingStatus.Caption=ok and 'Queued: return to Valheim and unpause. When enabled, aim at a creature and click the mouse wheel in game.' or tostring(err)
end
local function readString(value,label)return readCatalogueString(value,label) end
local function refreshList(text)
  if text==lastCatalogue then return end
  local selected=entries[list.ItemIndex+1];local key=selected and selected.key
  entries={};list.Items.clear()
  for line in text:gmatch('[^\r\n]+') do
    local id,name,x,y,z=line:match('^([^|]+)|([^|]*)|([^|]+)|([^|]+)|([^|]+)$')
    if id then entries[#entries+1]={key=id,name=name,x=x,y=y,z=z} end
  end
  table.sort(entries,function(a,b) if a.name==b.name then return a.key<b.key end;return a.name<b.name end)
  for i,entry in ipairs(entries) do
    list.Items.add(entry.name..'   [X '..entry.x..', Y '..entry.y..', Z '..entry.z..']')
    if entry.key==key then list.ItemIndex=i-1 end
  end
  lastCatalogue=text
end
tamingButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if tamingWindow then tamingWindow.show();return end
  tamingWindow=createForm(false);tamingWindow.Caption='Valheim | Taming';tamingWindow.Width=820;tamingWindow.Height=645;tamingWindow.Position='poScreenCenter'
  tamingWindow.Color=0x202020;tamingWindow.Font.Color=0xE6E6E6
  local guide=createLabel(tamingWindow);guide.Left=16;guide.Top=16;guide.Width=770;guide.Height=66;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Refresh lists known tamed creatures and adds map markers. Select one to bring it beside you. Enable wheel taming, return to Valheim and unpause, then aim at a creature within 10m and click the mouse wheel. Native taming support is required. Closing this window keeps wheel-click taming active.'
  local function button(caption,x,fn)
    local b=createButton(tamingWindow);b.Caption=caption;b.Left=x;b.Top=95;b.Width=180;b.Height=34;b.OnClick=fn
    if styleToggle then styleToggle(b,false) end;return b
  end
  button('Refresh + show on map',16,function() queue(27) end)
  button('Bring selected to me',210,function()
    local entry=entries[list.ItemIndex+1]
    if not entry then tamingStatus.Caption='Select a named tamed animal first.';return end
    queue(28,entry.key)
  end)
  button('Enable wheel taming',404,function() queue(31) end)
  button('Stop / hide markers',598,function() queue(30) end)
  local spawnLabel=createLabel(tamingWindow);spawnLabel.Left=16;spawnLabel.Top=145;spawnLabel.Caption='Spawn a native tameable creature (wheel-click to tame if needed)'
  spawnChoice=createComboBox(tamingWindow);spawnChoice.Left=16;spawnChoice.Top=168;spawnChoice.Width=325;spawnChoice.Style='csDropDownList'
  local stars=createSpawnStars(tamingWindow,355,168,135)
  local spawn=createButton(tamingWindow);spawn.Left=505;spawn.Top=168;spawn.Width=272;spawn.Height=30;spawn.Caption='Spawn selected tameable'
  spawn.OnClick=function()
    local ok,err=pcall(function()
      local name=spawnNames[4][spawnChoice.ItemIndex+1];assert(name,'Refresh the spawn list, unpause Valheim, then select a creature.')
      helper=queueSpawnAction(3,name,'taming',stars.ItemIndex);timer.Enabled=true;tamingWindow.show()
    end)
    tamingStatus.Caption=ok and 'Creature spawn queued. Return to Valheim and unpause.' or tostring(err)
  end
  local refreshSpawn=createButton(tamingWindow);refreshSpawn.Left=16;refreshSpawn.Top=205;refreshSpawn.Width=230;refreshSpawn.Height=30;refreshSpawn.Caption='Refresh tameable spawn list'
  refreshSpawn.OnClick=function()
    local ok,err=pcall(function() helper=queueSpawnAction(0,nil,'taming');timer.Enabled=true;tamingWindow.show() end)
    tamingStatus.Caption=ok and 'Spawn catalogue queued. Return to Valheim and unpause once.' or tostring(err)
  end
  if styleToggle then styleToggle(spawn,false);styleToggle(refreshSpawn,false) end
  list=createListBox(tamingWindow);list.Left=16;list.Top=248;list.Width=762;list.Height=245;list.Color=0x181818;list.Font.Color=0xE6E6E6
  scanStatus=createLabel(tamingWindow);scanStatus.Left=16;scanStatus.Top=505;scanStatus.Width=762;scanStatus.Height=40;scanStatus.AutoSize=false;scanStatus.WordWrap=true
  scanStatus.Caption='Only world records synchronized to your client can be listed; distant unseen animals may be missing.'
  tamingStatus=createLabel(tamingWindow);tamingStatus.Left=16;tamingStatus.Top=552;tamingStatus.Width=762;tamingStatus.Height=55;tamingStatus.AutoSize=false;tamingStatus.WordWrap=true;tamingStatus.Caption='Refresh animals or the spawn list, then unpause Valheim to scan.'
  timer=createTimer(tamingWindow,false);timer.Interval=500
  timer.OnTimer=function()
    if not helper or getOpenedProcessID()~=helper.pid or getProcessIDFromProcessName('valheim.exe')~=helper.pid then timer.Enabled=false;scanStatus.Caption='Game changed. Reload the toolkit.';return end
    local ok,err=pcall(function()
      scanStatus.Caption=readString(invoke(helper.tameStatus,0,{}),'Taming scan status')
      refreshList(readString(invoke(helper.tameCatalogue,0,{}),'Tamed animal list'))
      local catalogue=readString(invoke(helper.spawnCatalogue,0,{}),'Spawn catalogue')
      if catalogue~=spawnCatalogueText then readSpawnNames(helper);fillSpawnDropdown(spawnChoice,3);spawnCatalogueText=catalogue end
    end)
    if not ok then timer.Enabled=false;scanStatus.Caption=tostring(err) end
  end
  tamingWindow.OnClose=function() return caHide end
  tamingWindow.show();refreshSpawn.OnClick()
end) end
hint(tamingButton,'Locate named tamed animals, show map pins, bring selected animals to you, and enable middle mouse to tame aimed creatures in game.')
end

do
maxItemQualityButton.OnClick=function()
  local ok,err=pcall(function()
    assert(not pending,'Another toolkit action is pending. Finish it first.')
    local row=rows[listbox.ItemIndex+1];assert(row,'Select an item first.')
    local current=itemInfo(row.item);local snap=snapshot()
    assert(snap.player==row.player and snap.inventory==row.inventory,'Inventory changed. Refresh first.')
    local found=false;for _,item in ipairs(snap.items) do if item==row.item then found=true;break end end
    assert(found and current.shared==row.shared and current.namePointer==row.namePointer,'Selected item changed. Refresh first.')
    local quality=integer(row.item+offset(current.class,'m_quality'),'item quality')
    local maximum=integer(current.shared+offset(objectClass(current.shared),'m_maxQuality'),'normal quality cap')
    local answer=inputQuery('Set selected item quality','Choose quality 1-1000. Current: '..quality..'; normal maximum: '..maximum..'. Refinement levels can exceed the normal cap.',tostring(quality))
    if answer==nil then return end
    local target=tonumber(answer);assert(target and target==math.floor(target) and target>=1 and target<=1000,'Enter a whole quality level from 1 to 1000.')
    local after=snapshot();assert(after.player==snap.player and after.inventory==snap.inventory and after.collection==snap.collection and after.version==snap.version,'Inventory changed while entering quality. Refresh and retry.')
    if not window then openTeleportWindow();window.hide() end
    local s=context();if hook then stopTeleport() end
    local h=loadRecovery();installHook(s,h)
    invoke(h.quality,0,{{type=vtPointer,value=s.player},{type=vtPointer,value=row.item},{type=vtDword,value=target},{type=vtString,value=s.world}})
    pending={session=s,recovery=h,itemQuality=true};poll.Enabled=true
    status.Caption='Quality change queued. Return to Valheim and unpause.'
  end)
  if not ok then status.Caption=tostring(err) end
end
hint(maxItemQualityButton,'Choose the selected equipment quality, including levels beyond its normal upgrade cap. Changes apply in-game. Existing cheated flags stay unchanged.')
end

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

do
local planterWindow,helper,timer,combo,message,names,harvestButton,harvestMessage
local function refreshPlants()
  helper=loadRecovery()
  names={};combo.Items.clear()
  local text=readCatalogueString(invoke(helper.plantCatalogue,0,{}),'Plant catalogue')
  for name in text:gmatch('[^\r\n]+') do names[#names+1]=name;combo.Items.add(name) end
  combo.ItemIndex=#names>0 and 0 or -1
end
planterButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if planterWindow then planterWindow.show();refreshPlants();timer.Enabled=true;return end
  planterWindow=createForm(false);planterWindow.Caption='Valheim | Auto planter';planterWindow.Width=610;planterWindow.Height=355;planterWindow.Position='poScreenCenter';planterWindow.Color=0x202020;planterWindow.Font.Color=0xE6E6E6
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
  harvestButton=createButton(planterWindow);harvestButton.Left=16;harvestButton.Top=238;harvestButton.Width=565;harvestButton.Height=30;harvestButton.Caption='Auto harvest ready crops: OFF'
  harvestButton.OnClick=function()
    local ok,err=pcall(function() helper=queueLootAction(36,20);timer.Enabled=true end)
    harvestMessage.Caption=ok and 'Queued. Return to Valheim and unpause.' or tostring(err)
  end
  harvestMessage=createLabel(planterWindow);harvestMessage.Left=16;harvestMessage.Top=280;harvestMessage.Width=565;harvestMessage.Height=52;harvestMessage.AutoSize=false;harvestMessage.WordWrap=true;harvestMessage.Caption='Harvests ripe cultivator crops on cultivated ground within 20m. Harvest drops fly to inventory. Growth timers stay normal.'
  timer=createTimer(planterWindow,false);timer.Interval=500;timer.OnTimer=function()
    if not helper or getOpenedProcessID()~=helper.pid then timer.Enabled=false;return end
    local ok,err=pcall(function() message.Caption=readCatalogueString(invoke(helper.plantStatus,0,{}),'Auto planter status');local bits=invoke(helper.lootState,0,{});harvestButton.Caption='Auto harvest ready crops: '..(bits%2==1 and 'ON' or 'OFF');if not pending then harvestMessage.Caption=readCatalogueString(invoke(helper.harvestStatus,0,{}),'Harvest status') end end)
    if not ok then timer.Enabled=false;message.Caption=tostring(err) end
  end
  if styleToggle then styleToggle(start,false);styleToggle(stop,false);styleToggle(refresh,false);styleToggle(harvestButton,true) end
  planterWindow.OnClose=function() stop.OnClick();if helper then pcall(invoke,helper.harvestStop,0,{}) end;timer.Enabled=false;return caHide end
  refreshPlants();planterWindow.show()
end) end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() if helper then pcall(invoke,helper.plantStop,0,{});pcall(invoke,helper.harvestStop,0,{}) end;if timer then timer.Enabled=false end;if planterWindow then planterWindow.hide() end;return close() end
form.OnDestroy=function() if helper then pcall(invoke,helper.plantStop,0,{});pcall(invoke,helper.harvestStop,0,{}) end;if planterWindow then planterWindow.destroy() end;destroy() end
end

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
hint(sortingButton,'Enable once. All sorting chests share the same destinations. Open a chest with E, click Chest sorting, click Reassign all items + save to replace old filters with its current contents. Multiple matching chests provide overflow. F9 opens sorting setup when aiming at a nearby chest.')
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() local ok,err=pcall(stopSorting);if not ok then status.Caption=tostring(err) end;return close() end
form.OnDestroy=function() pcall(stopSorting);destroy() end
end

end)()

end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local helperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c0103008adfcb6a0000000000000000e00002210b010b000078000000060000000000003e9700000020000000a000000000001000200000000200000400000000000000040000000000000000e000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000f09600004b00000000a00000c80200000000000000000000000000000000000000c000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000044770000002000000078000000020000000000000000000000000000200000602e72737263000000c802000000a0000000040000007a0000000000000000000000000000400000402e72656c6f6300000c00000000c0000000020000007e0000000000000000000000000000400000420000000000000000000000000000000020970000000000004800000002000500c05d00003039000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001330060042050000010000110002037d010000047201000070280400000a252d0b267245000070280400000a0a06280500000a131411142d0b7265000070730600000a7a021f201f201a16730700000a7d0300000420000400008d120000010b160c2b7e160d2b6b00096b22000078415922000078415b1304086b22000078415922000078415b1305220000803f110411045a59110511055a59280800000a130607081f205a09588f12000001220000803f220000803f220000803f110611065a11065a730900000a8112000001000917580d091f20fe04131411142d8a0817580c081f20fe04131411143a74ffffff027b03000004076f0a00000a00027b030000046f0b00000a00027b03000004176f0c00000a000206730d00000a7d02000004027b02000004027b030000046f0e00000a00027b0200000472a70000701b6f0f00000a00027b0200000472bb000070176f0f00000a00027b0200000472cf000070166f0f00000a0012072200008040228fc2753c22cdcccc3c22cdcc4c3e280900000a00027b0200000411076f1000000a00027b0200000472df0000706f1100000a16fe01131411142d13027b0200000472df00007011076f1200000a00027b0200000420b80b00006f1300000a0016130838840000000016281400000a1309110972f50000706f1500000a0011096f1600000a02281700000a166f1800000a0011096f0100002b130a110a166f1a00000a00110a281b00000a0011096f0200002b130b110b027b020000046f1c00000a00110b166f1d00000a00110b166f1e00000a00027b04000004110811096f1600000aa2001108175813081108027b040000048e69fe04131411143a67ffffff722b010070731f00000a130c110c6f1600000a02281700000a166f1800000a0002110c6f0300002b7d05000004027b0500000417166f2100000a00027b050000046f2200000a130d120d17282300000a00120d202c010000282400000a00120d223333333f282500000a282600000a00120d2200000000282500000a282700000a00120d226666263f282500000a282800000a00120d220000a040220ad7a33c220ad7233d22cdcc4c3f730900000a282900000a282a00000a00120d17282b00000a00027b050000046f2c00000a130e120e2200003443282500000a282d00000a00027b050000046f2e00000a130f120f16282f00000a00120f229a99593f283000000a00027b050000046f3100000a1310121017283200000a00121017283300000a0012102200008040282500000a283400000a00027b050000046f3500000a1311121117283600000a00121122cdcc4c3f282500000a283700000a0012112200000040283800000a0012112200008040282500000a283900000a00027b050000046f3a00000a1312121217283b00000a00733c00000a13131113188d3700000113151115168f37000001283d00000a2200000000733e00000a81370000011115178f37000001283f00000a220000803f733e00000a81370000011115198d3800000113161116168f3800000122000000002200000000734000000a81380000011116178f38000001220000803f22cdcccc3d734000000a81380000011116188f380000012200000000220000803f734000000a813800000111166f4100000a0012121113284200000a284300000a00027b050000046f0400002b027b020000046f1c00000a00027b050000046f4500000a000202284600000a6f0500002b7d06000004027b06000004220000803f220ad7233c220ad7a33c734700000a6f4800000a00027b0600000422000040416f4900000a00027b06000004220000c0406f4a00000a00027b06000004166f4b00000a00022802000006002a000013300600c9000000020000110002281700000a027b010000046f1700000a6f4c00000a284d00000a284e00000a6f4f00000a00220000803f22b81e053e285000000a22000098415a285100000a5a58228fc2753d285000000a2200002c425a285100000a5a580a160b2b47027b04000004079a220000a03f076b229a99993e5a5822cdcc0c40076b229a99993e5a58220000a03f076b229a99993e5a58735200000a06285300000a6f5400000a000717580b07027b040000048e69fe040c082daa027b06000004220000c040065a6f4a00000a002a00000013300200500000000300001100027b01000004281f0000062c257e2400000417331d027b010000046f5500000a2d10027b010000046f5600000a16fe012b0116000a062d0f0002284600000a281b00000a002b07022802000006002a133002003e0000000300001100027b02000004280500000a16fe010a062d0c027b02000004281b00000a00027b03000004280500000a16fe010a062d0c027b03000004281b00000a002a5202198d080000017d0400000402285700000a002a0013300100160000000400001100022d07220000803f2b052200000040000a2b00062a000013300100160000000400001100022d07220000a0422b05220000f042000a2b00062a0000133001000b0000000400001100220000fa440a2b00062a0013300200410000000500001100022c1f02172e1302182e072200409c462b052200409c45002b05220000fa43002b05220000c842000a06032d07220000803f2b052200000042005a0b2b00072a000000133002001d0000000400001100027b080000042816000006027b0d00000428060000065a0a2b00062a00000013300400e80000000600001100027b0a00000416fe010a062d0538d400000002177d0a000004027b0b0000042d10027b0c0000042d0802280c0000062b0116000a062d0538aa000000027e2400000417fe017d0d00000402027b07000004027b070000046f5800000a6f5900000a0b1201285a00000a7d1200000402027b070000046f5800000a027b120000042200002041285300000a284e00000a284d00000a2200008040285300000a284e00000a7d1100000402285000000a7d0e00000402177d0b00000402280e00000600027b08000004192e0772570100702b05726f010070007283010070285b00000a80270000042a133002008b0000000300001100027b07000004280500000a2c76027b070000046f5c00000a2c69027b070000046f5500000a2d5c027b070000046f5600000a2d4f285d00000a2c48027b07000004281c0000062c3b285e00000a2d34285f00000a2d2d286000000a2d26286100000a2d1f286200000a280500000a2c0f286200000a6f6300000a16fe012b0117002b0116000a2b00062a00133003008400000007000011007201000070280400000a252d0b267245000070280400000a0a06280500000a0d092d0b7203020070730600000a7a06730d00000a0b07036f1000000a000772a70000701b6f0f00000a000772bb000070176f0f00000a000772cf000070166f0f00000a000720b80b00006f1300000a00027b15000004076f6400000a00070c2b00082a1330050096020000080000110002027b08000004192e0772570100702b05726f01007000731f00000a7d14000004027b140000046f1600000a027b110000046f4f00000a00027b08000004192e1b220000c03f2200004040220000a04022cdcc0c3f730900000a2b192200004040223333333f228fc2753d22cdcc0c3f730900000a000a027b08000004192e1b22cdcccc3d22cdcc4c3f220000404022ec51383e730900000a2b19220000004022cdcc4c3d22cdcccc3e22ec51383e730900000a000b160c38920000000016281400000a0d096f1600000a027b140000046f1600000a166f1800000a00096f0100002b13041104166f1a00000a001104281b00000a00096f1600000a286500000a220000803f086b229a99993e5a58285300000a6f5400000a00096f0200002b1305110502082c03072b010600280d0000066f1c00000a001105166f1d00000a001105166f1e00000a00000817580c0819fe04130811083a61ffffff160c38a4000000007241020070088c46000001286600000a731f00000a130611066f1600000a027b140000046f1600000a166f1800000a0011066f0600002b13071107176f6700000a0011071f416f6800000a0011070208185d2c03072b010600280d0000066f1c00000a001107229a99193e6f6900000a001107229a99193e6f6a00000a001107166f1d00000a001107166f1e00000a00027b1600000411076f6b00000a00000817580c081dfe04130811083a4fffffff02027b140000046f0500002b7d17000004027b17000004027b08000004192e1622cdcc4c3e226666263f220000803f734700000a2b14220000803f22cdcc4c3e220ad7a33c734700000a006f4800000a00027b1700000422000080406f4a00000a00027b1700000422000034426f4900000a00027b17000004166f4b00000a002a0000133007006b0200000900001100027b14000004280500000a130711072d053853020000027b08000004192e0722000040412b05220000904100027b0d00000428060000065a0a027b0c00000416fe01130711072d2c0602280a00000622000000405a285000000a027b0f0000045922000040405b280800000a286c00000a0a2b1f06220000803f220ad7233d285000000a220000e0405a285100000a5a585a0a027b140000046f1600000a027b110000046f4f00000a00027b140000046f1600000a286500000a06285300000a6f5400000a00027b0c0000042d07220000803f2b1d220000803f285000000a027b0f00000459220000c0405b59280800000a000b160c2b4400027b15000004086f6d00000a6f6e00000a0d1203082c0722ec51383e2b0522cdcc0c3f00075a7d6f00000a027b15000004086f6d00000a096f1000000a00000817580c08027b150000046f7000000afe04130711072da816130438c9000000160c38ae00000000086b22db0f49405a22000000405a22000080425b285000000a1104185d2c0722000080bf2b05220000803f005a5813051105287100000a22000000001105285100000a735200000a06226666263f11046b22cdcccc3c5a585a285300000a1306027b1600000411046f7200000a08027b1100000411046b220000d8415a285000000a22000040415a11046b220000f8415a287300000a1106287400000a284e00000a6f7500000a00000817580c081f41fe04130711073a44ffffff1104175813041104027b160000046f7600000afe04130711073a1fffffff027b170000042200008040075a6f4a00000a00027b17000004220000c8420622000040405a287700000a6f4900000a002a00033005006b000000000000000002167d0b00000402177d0c00000402285000000a7d0f00000402027b110000047d1300000402027b1300000402280a0000061517287800000a7d180000040202280a00000628180000067d1b00000402167d1900000402167d1a000004027b1c0000046f7900000a002a0013300600a40200000a00001100285000000a027b10000004fe0416fe01130411042d05388702000002285000000a22cdcc4c3d587d10000004160a2b4d027b07000004027b18000004027b190000049a027b13000004284d00000a027b08000004027b0d0000042809000006027b1c000004283d000006000617580a02257b1900000417587d19000004061f302f12027b19000004027b180000048e69fe042b011600130411042d94160a38c400000000027b1b000004027b1a0000046f7a00000a0b027b1300000412017b20000004220000000012017b21000004735200000a284e00000a0c081203287b00000a130411042d022b6b09027c130000047b7c00000a5909027c130000047b7c00000a595a12017b2000000412017b200000045a5812017b2100000412017b210000045a5802280a00000602280a0000065afe0216fe01130411042d022b161202097d7c00000a027b0700000408283f00000600000617580a02257b1a00000417587d1a000004061c2f15027b1a000004027b1b0000046f7d00000afe042b011600130411043a18ffffff1f0a8d020000011305110516027b08000004192e0772570100702b05726f01007000a2110517725d020070a2110518027b190000048c46000001a2110519727f020070a211051a027b180000048e698c46000001a211051b7283020070a211051c027b1a0000048c46000001a211051d727f020070a211051e027b1b0000046f7d00000a8c46000001a211051f097299020070a21105287e00000a8027000004027b19000004027b180000048e69322b027b1a000004027b1b0000046f7d00000a3218285000000a027b0f00000459220000c040fe0216fe012b011700130411042d340002167d0c0000040228130000060002147d1800000402147d1b000004027b1c0000046f7900000a0072e30200708027000004002a1b300600560200000b0000110000027b07000004281f0000062c447e23000004027b0800000433377e2b000004027b09000004332a027b07000004280500000a2c1d027b070000046f5500000a2d10027b070000046f5600000a16fe012b011600130611062d120002284600000a281b00000a00dde701000016287f00000a130611062d0702167d0a00000402280c000006130611062d05ddc3010000027b0b00000416fe01130611063a7601000000027b080000042817000006288000000a22cdcccc3d287700000a5a0a060b160c00027b110000042200000040027b0d00000428060000065a027b12000004061517288100000a13071613082b67110711088f4b000001714b0000010d001203288200000a280500000a2c1c1203288200000a6f0700002b027b07000004288400000a16fe012b011600130611062d022b1d1203288500000a07fe03130611062d0c001203288500000a0b170c0000110817581308110811078e69fe04130611062d8b02257b11000004027b1200000407285300000a284e00000a7d1100000400027b110000042200000040027b0d00000428060000065a1517287800000a13091613082b3a110911089a13041104280500000a2c1711046f0700002b027b07000004288600000a16fe012b011700130611062d0500170c2b14110817581308110811098e69fe04130611062db8082d15285000000a027b0e00000459220000a041fe052b011600130611062d070228100000060000027b0c00000416fe01130611062d070228110000060002280f0000060000de1a130500110528210000060002284600000a281b00000a0000de0000002a0000411c0000000000000100000038020000390200001a000000170000011b300200870000000c00001100027b14000004280500000a16fe010b072d0c027b14000004281b00000a0002147d14000004027b160000046f8700000a0000027b150000046f8800000a0c2b1c1202288900000a0a06280500000a16fe010b072d0706281b00000a001202288a00000a0b072dd9de0f1202fe160500001b6f8b00000a00dc00027b150000046f8c00000a002a000110000002003f002b6a000f000000008e000228130000060002147d1800000402147d1b000004027b1c0000046f7900000a002aa602738d00000a7d1500000402738e00000a7d1600000402738f00000a7d1c00000402285700000a002a00001330020017000000040000110002192e0722000020422b05220000f042000a2b00062a001330020017000000040000110002192e0722000010412b05220000c040000a2b00062a00133004004c0000000d000011000f007b200000040f007b200000045a0f007b210000040f007b210000045a580b12010f017b200000040f017b200000045a0f017b210000040f017b210000045a58289100000a0a2b00062a13300400b80000000e00001100739200000a0a0222000040405b6c289300000a690b07650c2b6207650d2b4c08085a6b22000040405a22000040405a09095a6b22000040405a22000040405a5802025afe03130511052d1c06086b22000040405a096b22000040405a731a0000066f9400000a000917580d0907fe0216fe01130511052da70817580c0807fe0216fe01130511052d91067e1f0000042d1314fe0619000006739500000a801f0000042b007e1f0000046f9600000a000613042b0011042a420002037d2000000402047d210000042a3e00022d03162b01170080240000042a000000133003002800000003000011007e2d00000414289800000a2c137e2d00000402146f9900000aa5550000012b0116000a2b00062a13300200500000000300001100031632090319fe0216fe012b0116000a062d0b725f030070739a00000a7a7e2b0000041758802b0000041680240000040380230000040280280000041480260000041480270000041780220000042a52001680220000041680240000041480280000042a000000133002003200000003000011007e2200000417332202280500000a2c1a027e28000004288400000a2c0d027e9b00000a288400000a2b0116000a2b00062a0000133002001b0000000300001100022c10027b9c00000a7b9d00000a1afe012b0116000a2b00062a0013300300550000000300001100168022000004026f9e00000a6f9f00000a7283030070026fa000000a28a100000a80260000047e260000046fa200000a2090010000fe0216fe010a062d157e260000041620900100006fa300000a80260000042a0000001b3003006b0200000f0000110002281f0000060d092d07160c3856020000007e24000004173335026f5500000a2d2d026f5600000a2d257e25000004280500000a2c157e250000047b0100000402288600000a16fe012b0116002b0117000d092d43007e25000004280500000a16fe010d092d107e250000046f4600000a281b00000a007289030070731f00000a280800002b80250000047e25000004026f0100000600000328200000060d092d07160cddbe0100007e2c0000041428a400000a16fe010d092d0b72b103007073a500000a7a7e2c0000040222000080bf8c500000016fa600000a007e2300000418fe040d093ac8000000007e2a000004280500000a2c367e2a0000047b0700000402288600000a2d247e2a0000047b080000047e2300000433137e2a0000047b090000047e2b000004fe012b0116000d092d60007e2a000004280500000a16fe010d092d107e2a0000046f4600000a281b00000a0072e5030070731f00000a280900002b802a0000047e2a000004027d070000047e2a0000047e230000047d080000047e2a0000047e2b0000047d090000040016287f00000a16fe010d092d0b7e2a0000046f0b00000600170cddb40000007e29000004280500000a2c217e290000047b2e00000402288600000a2d0f7e290000046f2400000616fe012b0116000d092d45007e29000004280500000a16fe010d092d107e290000046f4600000a281b00000a00720d040070731f00000a0a066f0a00002b80290000047e29000004026f2900000600007e29000004036f2f0000060000de280b00072821000006007e29000004280500000a16fe010d092d0b7e290000046f2c0000060000de0000170c2b0000082a00411c00000000000012000000290200003b0200002800000017000001ded03d00000128a700000a72410400701f346fa800000a802c000004d00500000128a700000a72630400701f3428a900000a802d0000042a133003002a0000000300001100027b360000047e230000043315027b370000047e2400000417fe01fe0116fe012b0117000a2b00062a000013300400400000001000001100027b36000004172e03032b2d0f017baa00000a0f017bab00000a228fc2f53d5a0f017bac00000a220000803e5a0f017b6f00000a730900000a000a2b00062a13300200280000000400001100027b36000004172e0d027b3700000428070000062b0b027b370000042808000006000a2b00062a1330020017000000040000110022cdcccc3f027b3700000428060000065a0a2b00062a001330020012000000040000110016027b3700000428090000060a2b00062a000013300900da080000110000110002037d2e000004027e230000047d36000004027e2400000417fe017d3700000402036f0b00002b7d430000047201000070280400000a252d19267277040070280400000a252d0b267245000070280400000a0a06280500000a131411142d0b72a9040070730600000a7a0206730d00000a7d30000004027b3000000472a70000701b6f0f00000a00027b3000000472bb000070176f0f00000a00027b3000000472cf000070166f0f00000a00027b3000000420b80b00006f1300000a000272e9040070731f00000a7d2f000004027b2f0000046f1600000a02281700000a166f1800000a0002027201050070229a99194022cdcc4c3d226666e63e2200004040228fc2f53d730900000a1f41282a0000067d3800000402027223050070226666863f22cdcc4c3e2200004040220000a04022cdcc0c3f730900000a1f41282a0000067d390000040202723b050070227b14ae3e2200008040220000a040220000c040220000803f730900000a1f41282a0000067d3a0000040202725905007022ec51b83d229a99993e2200004040220000a04022cdcc4c3f730900000a1f60282a0000067d3b00000402027277050070228fc2753d2200004040220000a040220000c040220000403f730900000a1f60282a0000067d3c0000040202729505007022cdcccc3d22cdcccc3d2200004040220000a040229a99593f730900000a1f41282a0000067d3d000004020272b505007022cdcc4c3d2200004040220000a040220000c040226666663f730900000a1f41282a0000067d3e000004020272d5050070220ad7233e22cdcc4c3e2200008040220000c04022cdcc4c3f730900000a1f41282a0000067d3f00000400198d0e0000011315111516027b3d000004a2111517027b3e000004a2111518027b3f000004a21115131616131738a3000000111611179a0b00076fad00000a0c071a8d5d00000113181118168f5d0000012200000000220000000073ae00000a815d0000011118178f5d00000122cdcc4c3e220000803f73ae00000a815d0000011118188f5d000001223333333f223333333f73ae00000a815d0000011118198f5d000001220000803f220000000073ae00000a815d000001111873af00000a6fb000000a0007086fb100000a0000111717581317111711168e69fe04131411143a4cffffff160d38de00000000027b33000004090272ed050070098c46000001286600000a220ad7233d09195d6b22cdcccc3c5a58220000803e22cdcc4c3f229a99993f22295c8f3e730900000a1f18282a000006a2027b33000004099a198d5d00000113181118168f5d0000012200000000220000000073ae00000a815d0000011118178f5d000001223333b33e220000803f73ae00000a815d0000011118188f5d000001220000803f220000000073ae00000a815d000001111873af00000a6fb000000a00027b33000004099a220ad7233d09195d6b22cdcccc3c5a586fb100000a00000917580d09027b330000048e69fe04131411143a0effffff021f201f201a16730700000a7d3200000420000400008d12000001130416130538890000001613062b720011066b22000078415922000078415b130711056b22000078415922000078415b1308220000803f110711075a59110811085a59280800000a1309110411051f205a1106588f12000001220000803f220000803f220000803f110911095a11095a730900000a81120000010011061758130611061f20fe04131411142d8211051758130511051f20fe04131411143a68ffffff027b3200000411046f0a00000a00027b320000046f0b00000a00027b32000004176f0c00000a000206730d00000a7d31000004027b31000004027b320000046f0e00000a00027b3100000472a70000701b6f0f00000a00027b3100000472bb000070176f0f00000a00027b3100000472cf000070166f0f00000a007215060070731f00000a130a110a6f1600000a027b2f0000046f1600000a166f1800000a0002110a6f0300002b7d34000004027b3400000417166f2100000a00027b340000046f2200000a130b120b17282300000a00120b2068010000282400000a00120b226666263f282500000a282600000a00120b2200000000282500000a282700000a00120b22ec51383e282500000a282800000a00120b17282b00000a00027b340000046f2c00000a130c120c2200000000282500000a282d00000a00027b340000046f3500000a130d120d17283600000a00120d229a99993f282500000a283700000a00120d22cdcc8c3f283800000a00120d2200004040282500000a283900000a00027b340000046f3a00000a130e120e17283b00000a00733c00000a130f110f188d3700000113191119168f37000001283d00000a2200000000733e00000a81370000011119178f37000001283d00000a220000803f733e00000a81370000011119198d38000001131a111a168f3800000122000000002200000000734000000a8138000001111a178f38000001220000803f228fc2f53d734000000a8138000001111a188f380000012200000000220000803f734000000a8138000001111a6f4100000a00120e110f284200000a284300000a00027b340000046f0400002b027b310000046f1c00000a00724d060070731f00000a131011106f1600000a027b2f0000046f1600000a166f1800000a000211106f0300002b7d40000004027b4000000417166f2100000a00027b400000046f2200000a1311121117282300000a00121122cdcccc3e282500000a282600000a0012112200004041282500000a282700000a00121122cdcc4c3e282500000a282800000a0012110222cdcccc3e2200004040220000a040220000803f730900000a2825000006282900000a282a00000a00121120a0000000282400000a00121117282b00000a00027b400000046f2c00000a131212122200005c43282500000a282d00000a00027b400000046f2e00000a1313121316282f00000a001213223333b33e283000000a00027b400000046f0400002b027b310000046f1c00000a0002027269060070220000c040282b0000067d41000004020272830600702200001041282b0000067d42000004027b2f000004166fb200000a002a0000133003009d000000120000110003731f00000a0a066f1600000a027b2f0000046f1600000a166f1800000a00066f0600002b0b07027b300000046f1c00000a0007176f6700000a00070e046f6800000a0007046f6900000a00070422cdcc4c3f5a6f6a00000a0007020528250000066fb300000a0007020528250000066fb400000a00071c6fb500000a0007166fb600000a0007166f1d00000a0007166f1e00000a00070c2b00082a000000133005006a000000130000110003731f00000a0a066f1600000a027b2f0000046f1600000a166f1800000a00066f0500002b0b070222cdcccc3d226666263f220000803f734700000a28250000066f4800000a0007046f4900000a000722000040406f4a00000a0007166f4b00000a00070c2b00082a000013300300630000000300001100027b2f000004280500000a16fe010a062d0d027b2f000004166fb200000a00027b480000042c1a027b43000004280500000a2c0d027b4400000428b700000a2b0117000a062d13027b43000004027b44000004166fb800000a0002167d480000042a0013300200840000000300001100027b2e000004281f0000062c0b02282400000616fe012b0116000a062d160002282c0000060002284600000a281b00000a002b4e285000000a027b4500000459228fc2f53d302e285d00000a2c2716287f00000a2c1f027b2e000004281c0000062c12027b2e0000046fb900000a28200000062b0116000a062d0702282c000006002a1330020063000000030000110002282c00000600027b30000004280500000a16fe010a062d0c027b30000004281b00000a00027b31000004280500000a16fe010a062d0c027b31000004281b00000a00027b32000004280500000a16fe010a062d0c027b32000004281b00000a002a0013300700e3090000140000110002285000000a7d45000004285d00000a2c3216287f00000a2c2a027b2e000004281c0000062c1d027b2e0000046f5500000a2d10027b2e0000046f5600000a16fe012b011600131811182d0d0002282c000006003888090000027b48000004131811182d4f0002177d4800000402285000000a7d4600000402285000000a7d4700000402285000000a7d35000004027b2f000004176fb200000a00027b400000046f4500000a00027b340000046f4500000a000002037b9c00000a7bba00000a7bbb00000a7d44000004027b43000004280500000a2c0d027b4400000428b700000a2b011700131811182d2b00027b43000004027b44000004176fb800000a00027b43000004729d060070220000803f6fbc00000a0000027b2e0000046f5800000a284d00000a226666e63e285300000a28bd00000a0a027b2e000004066f5900000a13191219285a00000a0b0607226666263f285300000a284e00000a0c0228260000060d1c8d3e000001131a111a1672b5060070a2111a1772c5060070a2111a1872df060070a2111a1972fb060070a2111a1a7207070070a2111a1b7217070070a2111a28be00000a1304027b3600000416fe0116fe01131811183aa6000000000607022826000006226666263f5811041728bf00000a131b16131c2b77111b111c8f4b000001714b0000011305001205288200000a280500000a2c161205288200000a6f0700002b280500000a16fe012b011600131811182d022b321205288500000a226666263f5909fe0416fe01131811182d1822000000001205288500000a226666263f5928c000000a0d00111c1758131c111c111b8e69fe04131811183a78ffffff092200000000fe03131811182d0d0002282c00000600385e070000080709285300000a284e00000a130607284d00000a28c100000a13191219285a00000a1307120728c200000a220ad7233cfe0416fe01131811182d0728c300000a130711070728c100000a13191219285a00000a130822cdcc4c3e220000803f285000000a027b460000045922cdcc4c3e5b280800000a286c00000a027b3700000428060000065a1309220000803f220ad7233e285000000a220000e8415a285100000a5a5822ec51b83d285000000a22000086425a285100000a5a58130a027b38000004229a99194011095a110a5a6f6900000a00027b38000004027b380000046fad00000a22cdcc4c3f5a6f6a00000a00027b39000004226666863f11095a6f6900000a00027b39000004027b390000046fad00000a22cdcc4c3f5a6f6a00000a00027b3a000004227b14ae3e11095a6f6900000a00027b3a000004027b3a0000046fad00000a22cdcc4c3f5a6f6a00000a0016130b38e400000000110b6b22000080425b130c1107110b6b22a470dd3f5a285000000a22000004425a59285100000a285300000a1108110b6b2248e10a405a285000000a22000024425a58285100000a285300000a284e00000a110c22db0f49405a285100000a285300000a1109285300000a130d081106110c28c400000a130e027b38000004110b110e110d229a99993e285300000a284e00000a6f7500000a00027b39000004110b110e110d228fc2f53d285300000a284e00000a6f7500000a00027b3a000004110b110e110d22295c0f3d285300000a284e00000a6f7500000a0000110b1758130b110b1f41fe04131811183a0dffffff16130b38ed00000000110b6b220000be425b130c110c095a220000c03f5a285000000a22000098415a5922cdcccc3e110b6b223333f33f5a285000000a220000c0415a58285100000a5a58130f1107110f287100000a285300000a1108110f285100000a285300000a284e00000a223333333f228fc2753e110b6b22000020405a285000000a220000f8415a59285100000a5a58285300000a1109285300000a110c22db0f49405a285100000a285300000a1310081106110c28c400000a130e027b3b000004110b110e1110284e00000a6f7500000a00027b3c000004110b110e111028bd00000a6f7500000a0000110b1758130b110b1f60fe04131811183a04ffffff027b3d0000040811071108229a99193f11095a283000000600027b3e000004080722cdcc4c3e285300000a284e00000a11071108220000803f11095a283000000600027b3f000004110611071108223333b33f11095a110a5a283000000600161311382201000000285000000a226666263f11116b2296438b3c5a585a11116b22ba490c3e5a58220000803f5d131216130b38dc00000000110b6b220000b8415b130c11116b229a9919405a285000000a220000e04011116b22cdcc4c3e5a585a59110c22cdcc2c405a58130f2200002040223333b33f11125a59229a99593f229a99193e110f22000040405a11116b58285100000a5a585a027b3700000428060000065a131309111222000010415a110c220000c03f5a58287700000a1314027b3300000411119a110b08071114285300000a284e00000a1107110f287100000a285300000a1108110f285100000a285300000a284e00000a1113285300000a284e00000a6f7500000a0000110b1758130b110b1f18fe04131811183a15ffffff001111175813111111027b330000048e69fe04131811183ac9feffff285000000a027b35000004fe05131811183a800100000002285000000a220ad7a33c587d3500000416130b385701000000220000000022db0fc94028c500000a130f22cdcc4c3f22cdcc2c4028c500000a13131107110f287100000a285300000a1108110f285100000a285300000a284e00000a13151108110f287100000a285300000a1107110f285100000a285300000a28bd00000a13161217fe156300000112170811151113285300000a284e00000a07220000000009220000c040287700000a28c500000a285300000a284e00000a28c600000a0012171116220000c040220000404128c500000a285300000a11152200000040285300000a28bd00000a072200000041220000904128c500000a285300000a284e00000a28c700000a00121722cdcc0c3f28c800000a001217228fc2753d228fc2753e28c500000a28c900000a00121702229a99993e226666a63f2200000040226666263f730900000a282500000628ca00000a28cb00000a00027b340000041117176fcc00000a0000110b1758130b110b1efe04131811183a9bfeffff00027b410000042200004040110a5a6f4a00000a00027b420000042200008040110a5a6f4a00000a00027b400000046f1700000a11066f4f00000a00027b410000046f1700000a086f4f00000a00027b420000046f1700000a11066f4f00000a00285000000a027b47000004fe05131811182d630002285000000a22cdcccc3d587d47000004027b3600000417fe0116fe01131811182d3400027b2e00000408070902282700000617027b370000042809000006283c00000600080709022827000006283400000600002b0a02080709283100000600002a0013300600c60000001500001100160a38af00000000066b22000080425b0b07229a9979405a285000000a220000e0400e0422000000405a585a580e04220000a0405a580c0e04220000803f22ec51383e066b229a99d93f5a285000000a2200000c425a58285100000a5a5822ec51b83d066b22cdcc4c405a285000000a22000054425a59285100000a5a585a0d0206030408287100000a285300000a0508285100000a285300000a284e00000a09285300000a284e00000a6f7500000a00000617580a061f41fe04130411043a43ffffff2a0000133003002b01000016000011000028cd00000a6fce00000a13041613053803010000110411059a0a0006280500000a2c33066fcf00000a2d2b066f5500000a2d23066fd000000a2d1b066fd100000a75660000012c0e027b2e0000040628d200000a2b011600130611062d0538ae000000066fd300000a0328bd00000a0b070428d400000a0c082200000000322e0805302a070408285300000a28bd00000a1307120728c200000a0228270000060228270000065afe0216fe012b011600130611062d022b5973d500000a0d097cd600000a0228280000067dd700000a09066fd300000a7dd800000a09047dd900000a0922000040407dda00000a09177ddb00000a09167ddc00000a09027b2e0000046fdd00000a0006096fde00000a0000110517581305110511048e69fe04130611063aecfeffff2a56021f0c8d0e0000017d3300000402285700000a002a00000013300300310000001700001100026fdf00000a031f346fa800000a0a061428a400000a16fe010c082d070373a500000a7a06026fe000000a0b2b00072a0000001b300c00e30400001800001100020304285300000a284e00000a0a0f007be100000a12007be100000a287700000a05590b0f007be100000a12007be100000a28c000000a05580c0f007be200000a12007be200000a287700000a05590d0f007be200000a12007be200000a28c000000a055813040028e300000a6fe400000a131a3845040000121a28e500000a130500001105280500000a2c0c11056fe600000a16fe012b011600131b111b2d05dd1804000011057be700000a130611057be800000a130711056f1700000a6f4c00000a130811076b11065a220000003f5a130912087be100000a11095807322d12087be100000a11095908302012087be200000a11095809321312087be200000a1109591104fe0216fe012b011600131b111b2d05dda3030000110572270700702833000006740a00001b130a110a2c17110a6fe900000a11071758110717585afe0416fe012b011600131b111b2d05dd68030000d01a00000128a700000a723b0700701f3428a900000a1105146f9900000a746b000001130b110b280500000a131b111b2d05dd31030000110b72730700702833000006a555000001131b111b2d05dd15030000110b6f0c00002b130c110c280500000a2c09110c6fea00000a2b011600131b111b2d05dded020000110c6feb00000a131b111b2d08110c6fec00000a00110c6feb00000a131b111b2d05ddc6020000110b728f0700702833000006740b00001b130d110b72a90700702833000006740b00001b130e110b72c50700702833000006740c00001b130f110d2c0e110e2c0a110f14fe0116fe012b011600131b111b2d05dd6e020000110d8e6911071758110717585a3316110e8e69110d8e69330c110f8e69110d8e69fe012b011600131b111b2d0b72e7070070730600000a7a161310161311383001000016131238100100000012087be100000a11126b11076b220000003f5a5911065a58131312087be200000a11116b11076b220000003f5a5911065a58131412087b7c00000a1105111211116fed00000a5813150f007be100000a0f007b7c00000a0f007be200000a0f017be100000a0f017b7c00000a0f017be200000a04051113111411151216283b000006131b111b2d022b7f7e4a0000041105111311151114735200000a12176f3700000616fe01131b111b2d111116111722000000415928c000000a131611161115220ad7a33c59fe05131b111b2d022b381111110717585a1112581318110d1118110d111898110e11189811151116283a000006a0110e11182200000000a0110f1118179c1713100011121758131211121107fe0216fe01131b111b3adefeffff11111758131111111107fe0216fe01131b111b3abefeffff1110131b111b2d05dddc000000d06b00000128a700000a72290800701f346fa800000a110b110b72290800702833000006a54600000117588c460000016fa600000a00d06b00000128a700000a72430800701f346fa800000a110b068c0b0000016fa600000a00d06b00000128a700000a725f0800701f346fa800000a110b058c500000016fa600000a00d06b00000128a700000a727d0800701f3428a900000a110b178d02000001131c111c16168c55000001a2111c6f9900000a26110516166fee00000a0000de1d131900728708007011196fef00000a286600000a28f000000a0000de00000000121a28f100000a131b111b3aaafbffffde0f121afe160900001b6f8b00000a00dc002a004134000000000000840000001c040000a00400001d0000001700000102000000750000005d040000d20400000f00000000000000c2d00a00000228a700000ad01a00000128a700000a72cb0800701f3428a900000a28f200000a740a000002804a0000042a00000013300400170000000400001100020358220000000005045928f300000a580a2b00062a0013300500d900000019000011000e0b0e0a5605055a0e040e045a580e050e055a580a062217b7d138fe0416fe01130711072d0816130638a700000022000000000e060e080259055a0e0a03590e045a580e0904590e055a58065b28f300000a28f400000a0b0205075a580c040e05075a580d0e0808590e0808595a0e0909590e0909595a581304030e04075a58130511040e0a1105590e0a1105595a580e070e075afe0216fe01130711072d051613062b300e0b110522000000000e070e075a11045928f400000a6c28f500000a6b59560e0b4e0e0a220ad7a33c59fe0413062b0011062a00000013300600480000001a00001100738f00000a0a0003030405285300000a284e00000a0e04151728f600000a0c160d2b1708099a0b00020703040e0506283d00000600000917580d09088e69fe04130411042ddd2a13300300b00000001b0000110003280500000a2c11036f0700002b02288400000a16fe012b0116000c082d05388a000000036f0d00002b0a062c0a0e05066ff700000a2b0116000c082d022b6e73d500000a0b077cd600000a0e047df800000a077cd600000a0e047df900000a077cd600000a0e047dfa00000a071f647dfb00000a07037dfc00000a0703046ffd00000a7dd800000a07057dd900000a07177ddb00000a07167ddc00000a07026fdd00000a0006076ffe00000a002a133005003b0100001c000011000522000000405b28ff00000a17580a0e0422000000403003172b0119000b0f027be100000a0f027be100000a5a0f027be200000a0f027be200000a5a586c28f500000a6b0c08226f12833a3016220000803f22000000002200000000735200000a2b1d0f027be200000a65085b22000000000f027be100000a085b735200000a000d16130438a1000000000e054a06075a5d13050e051105175806075a5d540304051105075b6b22000000405a287700000a285300000a284e00000a13060717fe0216fe01130811082d1f1106091105075d17596b0e045a226666263f5a285300000a284e00000a130611061207287b00000a2c1312067b7c00000a0e04591107fe0216fe012b011600130811082d022b13120611077d7c00000a021106283f000006000011041758130411041cfe04130811083a51ffffff2a00133007007f0000001d00001100280001000a72f10800706f0101000a0a06280500000a2d03142b06066f0e00002b000b07280500000a2d03142b06077b0201000a000c082d03142b06087b9c00000a000d092d03142b06097b0301000a0013041104280500000a130511052d0b7209090070730600000a7a031104022200000000081416280401000a262a0042534a4201000100000000000c00000076342e302e33303331390000000005006c000000e4120000237e0000501300005814000023537472696e677300000000a82700006c0900002355530014310000100000002347554944000000243100000c08000023426c6f620000000000000002000001571da209090a000000fa253300160000010000006f0000000d0000004a0000003f0000005f0000000401000004000000040000001d0000000200000005000000050000000c0000000100000007000000020000000e00000000000a000100000000000600e500d9000a000301fc000a000a01fc000a001401fc000e003701000006004401d90006005601d90006006801d90012009a01d9000600b001d90006004302d90006006502d9000a008f0274020600a002d9001600cd02d9001a000c0374020e001603000006004503d9000a00130401040a00260401040e005b0400005700640400000a007304fc000e003d0500000a00ea0501040e001a0600000a002b06fc000a003806fc000a00240705070a00aa078a070a00ca078a070600fa07d90006000301d9000a001208fc0006002c08d90006003a08d90006005808d90006006008d9000600c308d9000600f808d90006002d09d90006005f0949091200a709d9002700c70900002700f50900002700300a000012004e0ad9002700800a00002700ad0a00001200c30ad9002700f40a00002700380b00002700790b00000600a70bd9000600b00bd9000600d30bd9001200ec0bd90006002f0cd9000600750cd9000e00a20c00000e00cd0c00000a00ef0cfc000600fd0cd9000600130dd9000e002d0d00000e00440d00000e00490d00000e00510d00000e00600d00000a00870dfc000600f50dd9001600160ed90016001e0ed9001e00740ed9001600970ed9003700f90e00000a00270ffc000a004a0ffc000a007e0f8a070a00990ffc000a00aa0ffc000a00bc0f05070a00d20f05070a00dd0f01040a00e80ffc000a00f00ffc005b00101000005b00241000000a003810fc000a00451001040a007a10fc000a00a010fc000600ea10d9000600f310d90006004f11d9000e00921100000600cf11d90006001112d90027001812000006003012d9000e00671200000e00781200000e009d1200009f01a51200000e00e9120000a701f01200000e00491300000e005513000006009313d9000a00a413fc000e001114000000000000010000000000010001000101100020002e000500010001008001100041002e00090007000600010110004a002e00050007000a008001100054002e0009001d0016000d0110005d0000000d0020001a008101100063002e00090022001b00010110006e002e0005002e002400800110007e002e00090049003300030100008f00000011004b003600800110009e002e0009004b003a0080011000ab002e0009004b003c0080011000b6002e0009004b003e0006003e010a0001004d010e000100600112002100720116000100a9011b000100b6011f0006003e010a000600fd01380006000202380001000d023b00010012023b00010019023b00010023023b0001002b023e00010030023e0001003a023e0001004b02410001005402410001005e0241000100700245002100960249002100ad0251000100b6011f000100d60259000100de0238000100eb0238000100f9025e0021002403660053809203380053809f0338001100570faf040300ba033e000300bc033e001600be0338001600fd0138001600c60338001100ce03a0001600de03a9001600e803a9001100ef030a001100f503ac001100fc03b00013000202380033001d04b40031003104b80006003e010a0001009f04450001004d010e000100a7040e000100b80412002100c404e2000100ca041b000100d1043e000100df043800010023023b000100e904ee000100ee04ee000100f504ee000100fa04ee0001000005ee0001000605ee0001000e05ee0001001605ee00010021051b00010028051f00010034051f0001004c05f20001005605a900010064053e0001006d053e00010075053e00010080053b005180f70527013100fd0530015020000000008300bb0123000100a025000000008100c101290002007826000000008100c80129000200d426000000008100cf01290002001e27000000008618d901290002003427000000009300df012d0002005827000000009300e5012d0003007c27000000009300eb012d0004009427000000009300f60132000500e42700000000810828036e000700102800000000860033032900070004290000000081003803720007009c290000000081004b03760007002c2a000000008100580329000800d02c000000008100640329000800482f0000000081006c0329000800c02f0000000081007503290008007032000000008100c80129000800f0340000000081007f03290008009435000000008100cf0129000800b835000000008618d90129000800e4350000000093008b038b0008000836000000009300ad038b0009008436000000009300b30390000a002c360000000091003b0fa7040b004837000000008318d9019a000d005937000000009600d303a4000f006c370000000093003b04bc001000a0370000000096004404c2001100fc370000000096004e04c900130014380000000093005604bc00130054380000000093006d04cd0014007c380000000093007d04d3001500e0380000000096008304d9001600743b0000000091189910c9001900ac3b0000000086088f0472001900e43b000000008100e404e7001900303c00000000810887056e001a00643c00000000810828036e001a00883c00000000810891056e001a00a83c000000008600bb0123001a009045000000008100a305f6001b003c46000000008100a80500011f00b446000000008600b205290021002447000000008100c80129002100b447000000008100cf01290021002448000000008600b705070121001452000000009100bc050d012200e852000000008100c1051a0127001f54000000008618d90129002a0038540000000091000b0634012a00785400000000930011063a012c009c590000000091189910c90030000000000003008618d90144013000000000000300c60124064a013200000000000300c601460654013500000000000300c601520662013a00d0590000000093005c066a013c00f459000000009300670672014000dc5a0000000093006e0683014c00305b000000009300740690015200ec5b0000000093001106a3015800345d0000000093007806b1015e00000001007c0600000100830600000100830600000100830600000100df04000002008306000001008b0600000100df0400000100df0400000100910600000100e50d00000200480f000001009806000002009a06000001009c06000001007c06000001007c0600000200df04000001007c0600000100a40600000100ab06000001007c0600000200a40600000300ad0600000100b006000001007c0600000100b20600000200b706000003008b0600000400bd0600000100b20600000200c30600000100a40600000100c906000002005e0200000300ce0600000400d30600000500910600000100d60600000200540200000300dd0600000100e40600000200b20600000100d60600000200540200000300dd0600000400910600000100e60600000200ed0600000100f40600000200f80602000300fe0600000100f40600000200f80602000300fe0600000400310700000500e60602000100fe06000002003a0700000100410700000200470700000300fe06000004004e07000001005507000002005807000003005b07000004005e0700000500610700000600640700000700dd0600000800910600000900980600000a009a0600000b00fe0602000c00670700000100ef0300000200d60600000300540200000400dd06000005009106101006006e0700000100ef0300000200750700000300d606000004005402000005006e07000006007e0700000100ef0300000200d60600000300540200000400dd0600000500910600000600830700000100ef0300000200f806e900d9012900f100d901be01f900d901290001010108c30109010608ca011101d901d1013900d901d60121014008e0019100d901e50139004808ed0139005208290029017008f4013100d901fb0131007d08020231008d080902310094080f0231009e0815023100aa081a023100b308be016100d10821020901e108d1016100ea0829024101ea082902410002092e0261000c0935027900190940020901250945024901360952024901710958024901870940026100d901d10161009a0935024900c20964024900d2096c026101db0940026101e409be016901060872026101010a79026101130a79026101220a790271010608800261013f0a880261016c0a8f0249008f0a960281019c0a79024900b90a9c028901db0aa2028901e90aa90249000f0bae029901190940029901280b8f029901320b79024900440bb402a10119094002a1014e0b7902a1015b0ba902a101690b79024900910bba02a90119094002b101d90129009100c10bc002b901d901c5029100cb0bc002c101d9019a00b101e40bcc0271010608d802a9019408880241010c0935024900030c29004101080ce7029100d901f102510094080f025100170ca9025100210ca90251003c0cf8024100480c37035900550c3c0359005c0c41034100680c4a03d9017a0c50032101830ce0015900d901f1025900870c54034100930c4a03e101ac0c7200e101b30c72000900d9012900e101c10c3703e901d60c6f035900e00c3703f101f60c7603f901070d720001021f0d820309023a0d820311023a0d820319023a0d82032102590d82032902650d86032902720d72000c007b0d930359007f0d3c03f101f60ca40371008d0d400271009f0dbe017100b10da9027100c00da90214007b0d93032101cd0dca030c00d20dd1033100db0dd7039100e50d3e000c00e70ddc032101f10de0011400d20dd1033902000ee0033902870ce9037100060ef3031400e70ddc032101120efa034102360e0d041c00440e29002400d20dd103d1004a0e28045900540e3e002400e70ddc03f101f60c300451027a0e4204d901890e50034102a20e47045902b00e58044101bd0e35020901d20e63045902de0e6e000901eb0e63041400440e29000c00040f83042c00120f95042c001e0f72006902330f29000c00440e29000c00d90129001400d90129001c00d90129007902d90129008102a00fbd042400d90129008902af0fc70424007b0d93033400d90144012400b70fd4049102d901f204a100eb0ef904a10224060105b102d901d101290002100a00b1001b100805b9022d100d05b9003d101205d10250101805b90059101805f101f60c1c05f1016510dc03f101701023059900d20e2e05d902d901d101990090103605c902b2104f05c902c4105805c902cd1060059100480f3e009100d7103e009100d9103e007100db106e00e902d9019a00f102d9017205710002117a0571001111a90261002511400271003f0a0f0271002f110f0271003c11be0171005d11c305f1016b11dc05c1007911e105e9018111e705b9029911ec050103a211a900c100b711f1055900c01141030903d911f7054102e111fd052101ec11fa035900f01141035900f6116e00590007123c035900cd0d0d061103e501fa031903680c4a03190323124a031903010aa9021903220aa90221030608170619033f0a1f06490038122606e1013d126a063c004e127c06e10156127200e1015f127200e1016e128206290382128806e1018a1237035900991292063903d90129003903b1129a064103ba123e003903c61241003903ce1241003903d4123e003903e0123b003903fa129f0639030213a406e101f601ab0611003d10120599000e13c606590098063e0059009a063e00d1001713d2064400040f83044c00120f9504d10028137200d10039133e00d100411338005400e70ddc0361035e13720061036613720061036e132900d1004a0efc06d1007d130207b90082130807690399130d074c001e0f72007103ad1348078902120efa038902ec11fa038902bc13c7044102c1135e071c007b0d82074103b1123e004103d0133e004103d7133e003903e11388073903ec138b077900fa136f038900f601ab062101071498077903650dab0779031b14b107a9002514bc07b9023014450001034414c007080074008100080078008600080024012b010c004501b9012e001b00ea072e001300e10720038304b804e1038304b804ff025c03620366036a037c039903b603000436046d049a04c204df04460568058105ca05d3052e066206b206cb06120753076d078f079d07d207040001000800020000008b037d000000d00523010000e5017d0000008b037d000000dc057d0002000a000300020024000500020026000700020027000900020028000b008c03af031a0421048d04cc047406db06e206ea06f606f906048000000000000000000000000000000000e80700000000000000000000000000000000c200000000000400000000000000000000000100f30000000000000000000000000000000000000026010000000000000000000000000000000000007901000000000000000000000000000000000000b3020000000004000000000000000000000001000003000000000000000000000000000000000000560e00000000060005000a00090033003b0233004c0241005f028900e1024100ec024100aa0307015d044100290541003c054100410589006d058900f00607017d073300b7070000003c4d6f64756c653e0056616c6865696d426f774265616d5631332e646c6c004b61796f6b656e4175726156310056616c6865696d536f6c6f546f6f6c6b69740044627a506f7765720044627a426f6d62563200426f6d62506c616e00506f696e7400426f774265616d56313300426f774265616d56697375616c56360044656174684265616d5465727261696e0052656164426173654865696768740044656174684265616d437574004265616d44616d616765004265616d5465727261696e00556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f7572006d73636f726c69620053797374656d004f626a6563740056616c756554797065004d756c74696361737444656c656761746500617373656d626c795f76616c6865696d00506c61796572004f776e6572004d6174657269616c006d6174657269616c005465787475726532440074657874757265005472616e73666f726d007368656c6c7300556e697479456e67696e652e5061727469636c6553797374656d4d6f64756c65005061727469636c6553797374656d00666c616d6573004c6967687400676c6f7700536574757000466f6c6c6f7700557064617465004f6e44657374726f79002e63746f72005363616c650052616e676500446561746852616e67650044616d616765004d6f64650047656e65726174696f6e0068656c6400666c79696e67006578706c6f64696e6700626f6f7374656400626f726e006465746f6e61746564006e657874576f726b00566563746f723300706f736974696f6e00646972656374696f6e0063656e7465720047616d654f626a656374006f72620053797374656d2e436f6c6c656374696f6e732e47656e65726963004c6973746031006d6174657269616c73004c696e6552656e64657265720072696e677300556e697479456e67696e652e506879736963734d6f64756c6500436f6c6c69646572007461726765747300746172676574437572736f72007465727261696e437572736f72006372617465720053797374656d2e436f7265004861736853657460310049446573747275637469626c6500686974006765745f526164697573004669726500496e707574416c6c6f77656400436f6c6f72004d616b654d6174657269616c004275696c6456697375616c00416e696d617465004465746f6e61746500576f726b426c61737400436c65617256697375616c005261646975730044616d616765427564676574005465727261696e427564676574005370656564004372617465720058005a00456e61626c6564004b61796f6b656e0061757261005365744b61796f6b656e004c6173744572726f7200537461747573006f776e65720076697375616c00626f6d620053797374656d2e5265666c656374696f6e004669656c64496e666f004472617754696d65004d6574686f64496e666f0054616b65496e7075740043616e496e70757400436f6e6669677572650044697361626c65004f776e73004974656d44726f70004974656d44617461004973426f7700457863657074696f6e004661756c74004f6e426f77557064617465006765745f4d6f64654368616e6765640065666665637473007061727469636c654d6174657269616c00736f66745465787475726500677573747300766f72746578006e6578745061727469636c6573006d6f64650054696e740068616c6f0073686561746800636f726500636f696c4100636f696c42006d757a7a6c6541006d757a7a6c654200696d7061637452696e6700737061726b73006d757a7a6c654c6967687400656e644c69676874005a53796e63416e696d6174696f6e00616e696d6174696f6e0064726177416e696d6174696f6e006c617374537465700073746172746564006e65787444616d61676500666972696e67006765745f52616e6765006765745f44616d6167655065725469636b004c696e65004d616b654c69676874004869646500537465700052696e670044616d6167654d6f6e7374657273004d6f64654368616e6765640044616d6167655065725469636b0042696e64696e67466c61677300466c6167730047657442617365486569676874004669656c64004578636176617465004865696768746d617000496e766f6b6500494173796e63526573756c74004173796e6343616c6c6261636b00426567696e496e766f6b6500456e64496e766f6b65004c6f77657244656c746100426f74746f6d004465617468004869740044696700706c61796572006b61796f6b656e00636f6c6f72007261646975730078007a00656e61626c656400776561706f6e00650064740063006e616d6500776964746800636f756e740072616e6765006c696e650073696465007570006f726967696e006c656e677468006f006f626a656374006d6574686f64006d617000706f696e74006865696768740053797374656d2e52756e74696d652e496e7465726f705365727669636573004f75744174747269627574650063616c6c6261636b00726573756c74006c6576656c00736d6f6f746800746172676574006f78006f79006f7a00647800647900647a00626f74746f6d0064616d61676500636f6c6c69646572007365656e00637572736f720053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d426f774265616d563133005368616465720046696e64006f705f496d706c6963697400496e76616c69644f7065726174696f6e457863657074696f6e0054657874757265466f726d6174004d6174686600436c616d70303100536574506978656c73004170706c7900546578747572650054657874757265577261704d6f6465007365745f777261704d6f6465007365745f6d61696e5465787475726500536574496e74007365745f636f6c6f720048617350726f706572747900536574436f6c6f72007365745f72656e6465725175657565005072696d697469766554797065004372656174655072696d6974697665007365745f6e616d65006765745f7472616e73666f726d00436f6d706f6e656e7400536574506172656e7400476574436f6d706f6e656e74007365745f656e61626c65640044657374726f790052656e6465726572007365745f7368617265644d6174657269616c00556e697479456e67696e652e52656e646572696e6700536861646f7743617374696e674d6f6465007365745f736861646f7743617374696e674d6f6465007365745f72656365697665536861646f777300416464436f6d706f6e656e74005061727469636c6553797374656d53746f704265686176696f720053746f70004d61696e4d6f64756c65006765745f6d61696e007365745f6c6f6f70007365745f6d61785061727469636c6573004d696e4d61784375727665007365745f73746172744c69666574696d65007365745f73746172745370656564007365745f737461727453697a65004d696e4d61784772616469656e74007365745f7374617274436f6c6f72005061727469636c6553797374656d53696d756c6174696f6e5370616365007365745f73696d756c6174696f6e537061636500456d697373696f6e4d6f64756c65006765745f656d697373696f6e007365745f726174654f76657254696d650053686170654d6f64756c65006765745f7368617065005061727469636c6553797374656d536861706554797065007365745f736861706554797065007365745f7261646975730056656c6f636974794f7665724c69666574696d654d6f64756c65006765745f76656c6f636974794f7665724c69666574696d65007365745f7370616365007365745f79004e6f6973654d6f64756c65006765745f6e6f697365007365745f737472656e677468007365745f6672657175656e6379007365745f7363726f6c6c537065656400436f6c6f724f7665724c69666574696d654d6f64756c65006765745f636f6c6f724f7665724c69666574696d65004772616469656e74004772616469656e74436f6c6f724b6579006765745f7768697465006765745f726564004772616469656e74416c7068614b6579005365744b657973005061727469636c6553797374656d52656e646572657200506c6179006765745f67616d654f626a656374007365745f72616e6765007365745f696e74656e73697479004c69676874536861646f7773007365745f736861646f7773006765745f706f736974696f6e006765745f7570006f705f4164646974696f6e007365745f706f736974696f6e0054696d65006765745f74696d650053696e006f705f4d756c7469706c79007365745f6c6f63616c5363616c65004368617261637465720049734465616400497354656c65706f7274696e6700476574457965506f696e740048756d616e6f69640047657441696d446972006765745f6e6f726d616c697a656400537472696e6700436f6e636174004265686176696f7572006765745f656e61626c6564004170706c69636174696f6e006765745f6973466f637573656400496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c65004d696e696d61700049734f70656e0043686174006765745f696e7374616e636500486173466f63757300416464006765745f6f6e6500496e743332007365745f757365576f726c645370616365007365745f706f736974696f6e436f756e74007365745f73746172745769647468007365745f656e645769647468004c657270006765745f4974656d006765745f636f6c6f720061006765745f436f756e7400436f73005175617465726e696f6e0045756c657200536574506f736974696f6e004d696e005068797369637300517565727954726967676572496e746572616374696f6e004f7665726c617053706865726500436c65617200476574486569676874007900556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e006765745f64656c746154696d6500526179636173744869740053706865726543617374416c6c006765745f636f6c6c6964657200476574436f6d706f6e656e74496e506172656e74006f705f457175616c697479006765745f64697374616e6365006f705f496e657175616c69747900456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e74004d6f76654e6578740049446973706f7361626c6500446973706f7365003c4372617465723e625f5f30006200436f6d70617269736f6e6031004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c65676174653100436f6d70696c657247656e6572617465644174747269627574650053696e676c6500436f6d70617265546f004d617468004365696c696e6700536f7274005374727563744c61796f7574417474726962757465004c61796f75744b696e64004d6574686f644261736500426f6f6c65616e00417267756d656e74457863657074696f6e006d5f6c6f63616c506c617965720053686172656444617461006d5f736861726564004974656d54797065006d5f6974656d5479706500547970650047657454797065004d656d626572496e666f006765745f4e616d65006765745f4d657373616765006765745f4c656e67746800537562737472696e67004d697373696e674669656c64457863657074696f6e0053657456616c7565002e6363746f720052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744669656c64004765744d6574686f6400720067006765745f73746172745769647468004b65796672616d6500416e696d6174696f6e4375727665007365745f77696474684375727665007365745f77696474684d756c7469706c69657200536574416374697665007365745f656e64436f6c6f72007365745f6e756d4361705665727469636573004c696e65416c69676e6d656e74007365745f616c69676e6d656e740049734e756c6c4f72456d70747900536574426f6f6c0047657443757272656e74576561706f6e0041747461636b006d5f61747461636b006d5f64726177416e696d6174696f6e537461746500536574466c6f6174006f705f5375627472616374696f6e004c617965724d61736b004765744d61736b0052617963617374416c6c004d61780043726f7373006765745f7371724d61676e6974756465006765745f72696768740052616e646f6d00456d6974506172616d73007365745f76656c6f6369747900436f6c6f72333200456d697400476574416c6c4368617261637465727300546f4172726179004973506c6179657200497354616d65640042617365414900476574426173654149004d6f6e737465724149004973456e656d790047657443656e746572506f696e7400446f7400486974446174610044616d6167655479706573006d5f64616d616765006d5f6c696768746e696e67006d5f706f696e74006d5f646972006d5f70757368466f726365006d5f72616e67656400536b696c6c7300536b696c6c54797065006d5f736b696c6c0053657441747461636b65720047657456616c756500476574416c6c4865696768746d617073006765745f497344697374616e744c6f64006d5f7363616c65006d5f7769647468005465727261696e436f6d70005a4e65745669657700497356616c69640049734f776e657200436c61696d4f776e65727368697000506f6b650047657442617365457863657074696f6e004465627567004c6f675761726e696e670044656c65676174650043726561746544656c65676174650053717274004f7665726c617043617073756c65006d5f63686f70006d5f7069636b617865006d5f746f6f6c54696572006d5f686974436f6c6c6964657200436c6f73657374506f696e74004365696c546f496e74005a4e65745363656e6500476574507265666162006d5f6974656d44617461006d5f737061776e4f6e4869745465727261696e00537061776e4f6e4869745465727261696e00000000434c0065006700610063007900200053006800610064006500720073002f005000610072007400690063006c00650073002f0041006400640069007400690076006500001f53007000720069007400650073002f00440065006600610075006c00740000414b00610079006f006b0065006e00200061007500720061002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e0000135f0053007200630042006c0065006e00640000135f0044007300740042006c0065006e006400000f5f005a005700720069007400650000155f00540069006e00740043006f006c006f00720000354b00610079006f006b0065006e00200072006500640020007000720065007300730075007200650020007300680065006c006c00002b4b00610079006f006b0065006e00200072006900730069006e006700200066006c0061006d00650073000017530070006900720069007400200042006f006d0062000013530075007000650072006e006f0076006100007f200069006e00200066006c0069006700680074002e00200049006d00700061006300740020006f00720020003200300020007300650063006f006e006400730020006400650074006f006e0061007400650073003b00200074006f00670067006c00650020004f00460046002000630061006e00630065006c0073002e00003d440042005a0020007300700068006500720065002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e00001b45006e00650072006700790020006f00720062006900740020000021200062006c006100730074003a0020006f0062006a006500630074007300200000032f0000152c0020007400650072007200610069006e00200000492e00200054006f00670067006c00650020004f00460046002000630061006e00630065006c0073002000720065006d00610069006e0069006e006700200077006f0072006b002e00007b42006c00610073007400200063006f006d0070006c006500740065002e002000520065006c006500610073006500200061006e006400200063006c00690063006b00200062006f0077002000610074007400610063006b00200074006f0020006c00610075006e0063006800200061006700610069006e002e00002349006e00760061006c00690064002000440042005a00200070006f0077006500720000053a002000002753006f006c006f0054006f006f006c006b00690074005f004b00610079006f006b0065006e000033480075006d0061006e006f00690064002e006d005f00610074007400610063006b004400720061007700540069006d006500002753006f006c006f0054006f006f006c006b00690074005f00440042005a0042006f006d006200003353006f006c006f0054006f006f006c006b00690074005f0042006f0077004200650061006d0044007200690076006500720000216d005f00610074007400610063006b004400720061007700540069006d0065000013540061006b00650049006e0070007500740000315000610072007400690063006c00650073002f005300740061006e006400610072006400200055006e006c0069007400003f4e006f00200063006f006d00700061007400690062006c00650020006200650061006d002000730068006100640065007200200066006f0075006e00640000174200650061006d00560069007300750061006c0073000021540075007200620075006c0065006e007400200063006f0072006f006e00610000174300790061006e00200070006c00610073006d006100001d57006800690074006500200068006f007400200063006f0072006500001d45006e0065007200670079002000680065006c006900780020004100001d45006e0065007200670079002000680065006c006900780020004200001f4300680061007200670069006e0067002000720069006e00670020004100001f4300680061007200670069006e0067002000720069006e00670020004200001749006d0070006100630074002000680061006c006f00002756006f0072007400650078002000770069006e006400200072006900620062006f006e002000003753007700690072006c0069006e00670020007000720065007300730075007200650020007000610072007400690063006c0065007300001b49006d007000610063007400200073007000610072006b00730000194d0075007a007a006c00650020006c006900670068007400001949006d00700061006300740020006c00690067006800740000176400720061007700700065007200630065006e007400000f440065006600610075006c00740000197300740061007400690063005f0073006f006c0069006400001b440065006600610075006c0074005f0073006d0061006c006c00000b70006900650063006500000f7400650072007200610069006e00000f760065006800690063006c00650000136d005f006800650069006700680074007300003747006500740041006e0064004300720065006100740065005400650072007200610069006e0043006f006d00700069006c0065007200001b6d005f0069006e0069007400690061006c0069007a006500640000196d005f006c006500760065006c00440065006c0074006100001b6d005f0073006d006f006f0074006800440065006c007400610000216d005f006d006f0064006900660069006500640048006500690067006800740000415400650072007200610069006e00200063006f006d00700069006c006500720020006c00610079006f007500740020006300680061006e006700650064002e0000196d005f006f007000650072006100740069006f006e007300001b6d005f006c006100730074004f00700050006f0069006e007400001d6d005f006c006100730074004f0070005200610064006900750073000009530061007600650000434400650061007400680020004200650061006d0020007400650072007200610069006e002000740069006c006500200073006b00690070007000650064003a002000002547006500740057006f0072006c006400420061007300650048006500690067006800740000175000690063006b00610078006500490072006f006e00005f490072006f006e0020007000690063006b0061007800650020007400650072007200610069006e00200069006d0070006100630074002000700072006500660061006200200075006e0061007600610069006c00610062006c0065002e000000000080f070a526b1124082008321bc0d284d0008b77a5c561934e08903061215030612190306121d04061d12210306122503061229052001011215032000010400010c020500020c080202060802060202060c0306112d030612310706151235011219070615123501123904061d123d070615123501111807061512410112450320000c03200002062001121911490328000c043000000004060000000400010c080900011512350111180c052002010c0c03061208040001010202060e03061220030612100306124d03061251050001021215060002011215080300000105000102125905000101125d08000302121512590c04061d123906200111491149030612390306126109200412390e0c11490806200212290e0c0520010112590c0005011239112d112d112d0c08200301112d112d0c03280002030611650434000000030612280500021c1c0e09000401112d112d0c0c052002011c18092003021269112d100c0d2005126d1269112d100c12711c07200202100c126d0700040c0c0c0c0c10000c020c0c0c0c0c0c0c0c0c0c0c100c0c0006011215112d112d0c0c0c120006011215123d112d112d0c1512410112450d0006011215112d112d0c0c1008070002011215112d040000fa4304200101080600011280810e06000102128085042001010e09200401080811808d020400010c0c072004010c0c0c0c062001011d1149062001011180990620010112808106200101128095052002010e08052001011149042001020e062002010e1149070001123111809d042000122106200201122102053001001e00040a01123d042001010206000101128085050a011280a5052001011219062001011180a9040a01122507200201021180ad0520001180b10600011180b50c062001011180b50700011180b91149062001011180b9062001011180bd0520001180c10520001180c5062001011180c9042001010c0520001180cd0520001180d10520001180d504000011490620020111490c0b2002011d1180dd1d1180e10800011180b91280d9050a011280e50420001231040a011229062003010c0c0c062001011180e93707171280811d114908080c0c0c1149081231123d1280a512311180b11180c11180c51180cd1180d11180d51280d9021d1180dd1d1180e1042000112d040000112d080002112d112d112d05200101112d0300000c070002112d112d0c0507030c0802030701020307010c0407020c0c062001112d112d0500020e0e0e05070202112d03000002050000128115061512350112190520010113000a070412808112191219020500020e1c1c040a0112390615123501123913070911491149081231123d1280a512311239020600030c0c0c0c05200113000804200011490320000808000311811d0c0c0c090002112d11811d112d0620020108112d0500020c0c0c0c07080c0c081149080c112d020c00041d123d112d0c08118125061512410112450615123501111807000202112d100c0500010e1d1c0b0706081118112d0c021d1c04000102081000061d11812d112d0c112d0c08118125042000123d050a011280f10900020212808512808515070a0c0c0211812d123d125d021d11812d081d123d09200015118131011300071511813101121904200013000c07031219021511813101121907000208111811180806151281390111180401000000042001080c040702080c0400010d0d07151281390111180a20010115128139011300120706151235011118080808151235011118020620010111814d07000202125112510620021c1c1d1c040612815d04061181610520001281650320000e0600030e0e0e0e0520020e0808040a01120807000202124d124d052002011c1c040a011210040a0112200807041231125d0202080001128165118171072002124d0e116507200212510e11650407011149040a011261072001011d1181750620010112817941071b12808112390c081d114908080c0c0c12311180b11180c11180d11180d51280d912311180b11180c11180c5021d12391d1239081d1181751d1180dd1d1180e10620010111817d080703123112391239080703123112291229040001020e052002010e0204200012590406128181052002010e0c050001081d0e0f00051d11812d112d112d0c08118125090003112d112d112d0c0700011181911149062001011181910720020111818d0833071d112d112d112d0c0811812d112d112d112d0c0c080c112d112d0c112d080c0c0c112d112d11818d02112d1d0e1d11812d08070705080c0c0c02090000151235011280f107151235011280f10520001d1300052000128195090002021280f11280f10700020c112d112d04061181a104061181a9062001011280f10620010112819d1307081280f1112d0c12819d1d1280f10802112d0420011c1c060703124d1c0208000015123501126906151235011269071511813101126905151235010c050a011281b1021d0c021d020520020c0808052002010802042000125d040001011c35071d112d0c0c0c0c12690c08112d0c151235010c1281ad1281b11d0c1d0c1d020208080c0c0c0c0c08125d15118131011269021d1c0a00021281b912816512510a07080c0c0c0c0c0c02020e00051d123d112d112d0c081181250f0705151241011245123d1d123d0802040a0112450520010213000206060306123d080703124512819d02040001080c0d070908080c112d0808112d0c020500001281bd05200112310e040a011255030612591100071231112d12311280f10c12591259020e070612311255125912815d1231020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773010000001897000000000000000000002e970000002000000000000000000000000000000000000000000000209700000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058a000006c02000000000000000000006c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004cc010000010053007400720069006e006700460069006c00650049006e0066006f000000a801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000004c001600010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d005600310033002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005400160001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d005600310033002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000c000000403700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper
local updatingKayoken=false
local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','BowBeamV13')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_BowBeamV13_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=helperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write bow-beam helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Explosive-fists helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','BowBeamV13'),'Explosive-fists helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18,8},1),
    kayoken=matchingMethod(class,'SetKayoken',{2},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'OnBowUpdate',{18,18,12},2)}
  return helper
end
local function stopBeam()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove bow-beam hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Explosive-fists helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  beamButton.Caption='DBZ Powers: OFF'
  updatingKayoken=true;kayokenCheck.Checked=false;kayokenCheck.Enabled=false;updatingKayoken=false
end
kayokenCheck.OnChange=function()
  if updatingKayoken then return end
  if not state then updatingKayoken=true;kayokenCheck.Checked=false;updatingKayoken=false;return end
  local ok,err=pcall(function()
    assert(playerIdentity(state),'Player changed or world unloaded')
    invoke(state.helper.kayoken,0,{{type=vtByte,value=kayokenCheck.Checked and 1 or 0}})
    playerStatus.Caption=kayokenCheck.Checked and 'Kayoken ON: red aura, 32x DBZ damage, 2x size. Death Beam 16000/tick, 2000m. Bombs snapshot power on launch.' or 'Kayoken OFF: normal power restored for beams and future bombs. In-flight bombs keep their launch power.'
  end)
  if not ok then pcall(stopBeam);showMessage('Kayoken stopped: '..tostring(err)) end
end
ValheimBowBeamStop=stopBeam
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopBeam();return close() end
form.OnDestroy=function() stopBeam();destroy() end
beamButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopBeam();playerStatus.Caption='Beam disabled.';return end
    local s=playerContext()
    local raw=inputQuery('DBZ Powers','1 Kameha - cyan beam, hostile monsters only\n2 Death Beam - excavates terrain and destroys objects\n3 Spirit Bomb - massive blue sphere, 40m blast radius\n4 Supernova (Frieza) - fiery sphere, 120m blast radius\nBow required. Hold for beams; click for bombs. One bomb at a time.\nBombs damage objects/pets and excavate terrain. Toggle OFF cancels pending work.','1')
    if raw==nil then return end
    local mode=tonumber(raw);assert(mode and mode%1==0 and mode>=1 and mode<=4,'Choose a DBZ power from 1 to 4.')
    s.mode=mode-1
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','Player'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'UpdateAttackBowDraw',{18,12},1)),'Bow draw code')
    local target=pointer(mono_compile_method(s.helper.hit),'Explosive-fists callback')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode damage prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read damage prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhBowBeam,4096,%X)
label(vhBowBeamRestore)
label(vhBowBeamReturn)
vhBowBeam:
sub rsp,D8
mov byte ptr [rsp+C0],0
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
jne vhBowBeamRestore
// Preserve Player, weapon and XMM2 dt; the helper reports whether it consumed bow input.
call %X
mov [rsp+C0],al
vhBowBeamRestore:
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
cmp byte ptr [rsp+C0],0
lea rsp,[rsp+D8]
jne vhBowBeamReturn
%s
jmp %X
vhBowBeamReturn:
ret
%X:
db FF 25 00 00 00 00
dq vhBowBeam
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling bow beam')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Explosive-fists hook installation failed: '..tostring(info))
    s.info=info
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player},{type=vtDword,value=s.mode}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Explosive-fists helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          if state.mode>=2 then
            local sf=fields(state.helper.class).Status
            if sf and sf.isStatic then
              local address=sf.staticAddress
              if not address or address<=sf.offset then address=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+sf.offset end
              local value=readPointer(address)
              if value and value~=0 then playerStatus.Caption=stringValue(value) end
            end
          end
          if readInteger(state.enabled)~=1 then
            local message='Game callback stopped after an error'
            local ef=fields(state.helper.class).LastError
            if ef and ef.isStatic then
              local storage=ef.staticAddress
              if not storage or storage<=ef.offset then storage=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+ef.offset end
              local text=readPointer(storage)
              if text and text~=0 then message=stringValue(text) end
            end
            error(message)
          end
        end)
        if not active then
          local stopped,stopError=pcall(stopBeam)
          playerStatus.Caption='Beam stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    kayokenCheck.Enabled=true
    watch.Enabled=true;beamButton.Caption=({'Kameha','Death beam','Spirit Bomb','Supernova'})[s.mode+1]..': ON'
    playerStatus.Caption=s.mode>=2 and 'Bow equipped: click to launch one slow bomb. Spirit Bomb 40m / Supernova 120m radius. Detonates on impact or after 20s. Blast work continues in batches; toggle OFF cancels it. Visuals are local.' or s.mode==1 and 'Death Beam: hold bow attack. 2000m surface-contact terrain excavation; damages creatures and destructible objects every 0.1s. Release to stop. Visuals are local.' or 'Kameha: hold bow attack. Cyan beam, 80m reach, hostile monsters only. Release to stop. Visuals are local.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopBeam)
    showMessage('Valheim beam: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

do
local carryState,carryWatch
local function stopCarry()
  if carryWatch then carryWatch.Enabled=false end
  local s=carryState
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    local ok,err=autoAssemble(s.script,false,s.info)
    assert(ok,'Could not restore carry limit: '..tostring(err))
  end
  carryState=nil;carryButton.Caption='Unlimited carry: OFF'
end
ValheimCarryStop=stopCarry
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopCarry();return close() end
form.OnDestroy=function() stopCarry();destroy() end
carryButton.OnClick=function()
  local ok,err=pcall(function()
    if carryState then stopCarry();playerStatus.Caption='Normal carry limit restored.';return end
    local s=playerContext()
    local method=matchingMethod(playerClass,'IsEncumbered',{},2)
    local entry=pointer(mono_compile_method(method),'Carry-limit code')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode carry-limit prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read carry-limit code')
    local hex={};for _,v in ipairs(bytes) do hex[#hex+1]=string.format('%02X',v) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhCarryLimit,1024,%X)
label(vhCarryPass)
vhCarryLimit:
pushfq
push rax
mov rax,%X
cmp rcx,rax
jne vhCarryPass
mov rax,%X
cmp [rax],rcx
jne vhCarryPass
pop rax
popfq
xor eax,eax
ret
vhCarryPass:
pop rax
popfq
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhCarryLimit
%s
[DISABLE]
%X:
db %s
// Retain the small trampoline until game exit for in-flight calls.
]],entry,original,entry,s.player,s.storage,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling unlimited carry')
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Carry-limit hook failed: '..tostring(info))
    s.info=info;carryState=s
    if not carryWatch then
      carryWatch=createTimer(form,false);carryWatch.Interval=250
      carryWatch.OnTimer=function()
        if not playerIdentity(carryState) then
          local stopped,failure=pcall(stopCarry)
          playerStatus.Caption=stopped and 'Unlimited carry stopped: player changed or world unloaded.'
            or ('Carry cleanup failed: '..tostring(failure))
        end
      end
    end
    carryWatch.Enabled=true;carryButton.Caption='Unlimited carry: ON'
    playerStatus.Caption='Weight encumbrance disabled for your current player. The game still displays actual weight and the normal limit.'
  end)
  if not ok then showMessage('Valheim carry weight: '..tostring(err)) end
end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local deleteHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300afdec66a0000000000000000e00002210b010b000022000000060000000000004e40000000200000006000000000001000200000000200000400000000000000040000000000000000a000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000f83f00005300000000600000e002000000000000000000000000000000000000008000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000054200000002000000022000000020000000000000000000000000000200000602e72737263000000e0020000006000000004000000240000000000000000000000000000400000402e72656c6f6300000c000000008000000002000000280000000000000000000000000000400000420000000000000000000000000000000030400000000000004800000002000500b42a00004415000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e0280030000041480020000041780010000042a361680010000041480030000042aae7e0100000417332102280400000a2c19027e03000004280500000a2c0c027e0600000a280500000a2a162a0000033003004d00000000000000168001000004026f0700000a6f0800000a7201000070026f0900000a280a00000a80020000047e020000046f0b00000a209001000031157e020000041620900100006f0c00000a80020000042a0000001b30030096000000010000117e0300000428030000062c0802280400000a2d012a7e04000004280400000a2c287e040000047b050000047e03000004280d00000a2d127e040000047b0600000402280d00000a2c417e04000004280400000a2c0f7e040000046f0e00000a280f00000a7207000070731000000a0a066f0100002b80040000047e04000004027e030000046f09000006de090b072804000006de002a00000110000000001500778c000904000001133003004e00000002000011026f0200002b0a0603166f1300000a06281400000a6f1500000a06281400000a6f1600000a06281400000a6f1700000a060405731800000a6f1900000a060e040e05731800000a6f1a00000a062a000013300600640000000300001103178d150000010c0816d00e000001281b00000aa208731c00000a0a0604050e040e050e06280600000626066f0300002b0b070e076f1d00000a0722000080416f1e00000a07281f00000a6f2000000a0720011000006f2100000a07166f2200000a072a13300900d600000004000011031a8d150000010d0916d00e000001281b00000aa20917d01f000001281b00000aa20918d020000001281b00000aa20919d008000001281b00000aa209731c00000a0a06027b070000046f2300000a042200002041052200000042280600000626066f0400002b0b0722cdcccc3e22b81e053e22cdcccc3d220000803f732400000a6f2000000a066f0500002b0c08076f2500000a0e050203724b000070282600000a066f2300000a220000004122000000000522000080415922000000420e042807000006510e055020020200006f2100000a082a000013300900060200000500001102037d0600000402047d050000047e1100000414282700000a2d277e1200000414282700000a2d1a7e1300000414282700000a2d0d7e1400000414282800000a2c0b7259000070732900000a7a036f0600002b0a06280400000a2d0b728d000070732b00000a7a066f2c00000a6f2d00000a0b03176f0700002b0c08280400000a2d07282f00000a2b06086f3000000a0d0272c7000070198d150000011306110616d00e000001281b00000aa2110617d01f000001281b00000aa2110618d020000001281b00000aa21106731c00000a7d07000004027b070000040722000000002200000000220000dc43220000b04228060000061304110422cdcccc3c228fc2f53d731800000a6f1500000a110411046f3100000a6f1600000a027b070000046f0400002b22295c8f3d220ad7a33d22ec51b83d228fc2753f732400000a6f2000000a020272f9000070027b070000046f2300000a22000040412200004042220000d04322000008420928070000067d080000040202721701007022000040412200008f4309027c0900000428080000067d0a000004020272330100702200009b43220000ec4209120528080000067d0b000004110572330100706f3200000a027b0a0000046f3300000a02fe060f000006733400000a6f3500000a027b0b0000046f3300000a02fe060e000006733400000a6f3500000a027b07000004166f3600000a2a0000133002007200000006000011027b0500000428030000062c14027b06000004280400000a2c07283700000a2d02142a7e12000004027b060000046f3800000a75290000010a7e11000004027b060000046f3800000a750a0000010b06027b050000046f3900000a3311072c0e066f3a00000a076f3b00000a2d02142a072a96022c20027b3c00000a163117027b3d00000a2d0f027b3e00000a7b3f00000a16fe012a162a8e032c1e7e13000004027b060000046f3800000aa52d000001037b3c00000afe012a162a133003003600000007000011284000000a027b3e00000a7b4100000a6f4200000a0a066f0b00000a1f303002062a06161f306f0c00000a7241010070282600000a2a3e02147d0c00000402167d0d0000042a00001b300500320100000800001102280a0000060a06280b0000062c090206280c0000062d0b02280e000006dd0e010000027b0c00000406330e027b0d000004067b3c00000a2e1802067d0c00000402067b3c00000a7d0d000004dddf000000027b050000046f3900000a0b02280a000006027b0c0000043313076f3a00000a027b0c0000046f3b00000a2d0b02280e000006dda700000006280d0000060c067b3c00000a0d7e14000004027b06000004198d010000011305110518168c2d000001a211056f4300000a2607066f4400000a2d0b7249010070732b00000a7a02280e000006021a8d0100000113061106167275010070a2110617098c2d000001a2110618728b010070a211061908a21106284500000a7d0e00000402284600000a2200004040587d0f000004de11130402280e00000611042804000006de002a0000411c00000000000000000000200100002001000011000000040000011b300400ed01000009000011027b0500000428030000062c0d027b06000004280400000a2d29027b07000004280400000a2c0c027b07000004166f3600000a02280e00000a280f00000adda9010000027b07000004280400000a2d05dd97010000283700000a0a027b07000004066f3600000a062d0b02280e000006dd7701000002280a0000060b027b0c00000407331a072c1d027b0d000004077b3c00000a33090207280c0000062d0602280e000006027b0a00000407280b0000062c090207280c0000062b01166f4700000a027b0b000004027b0c00000414fe0116fe016f4700000a027b09000004027b0c0000042c1c7293010070027b0d0000048c2d00000172b5010070284800000a2b0572c30100706f3200000a072d2a027b08000004284600000a027b0f000004320772ed0100702b06027b0e0000046f3200000a388300000007280b0000062d12027b08000004723f0200706f3200000a2b690207280c0000062d12027b08000004729b0200706f3200000a2b4e027b080000041a8d010000010d091607280d000006a20917728b010070a20918077b3c00000a8c2d000001a20919027b0c0000042d0772280300702b05724a030070a209284500000a6f3200000ade2d0c082804000006027b07000004280400000a2c0c027b07000004166f3600000a02280e00000a280f00000ade002a000000411c00000000000000000000bf010000bf0100002d0000000400000166027b07000004280400000a2c0b027b07000004280f00000a2a00000330030080000000000000001f348010000004d005000001281b00000a72780300707e100000046f4900000a8011000004d005000001281b00000a728e0300707e100000046f4900000a8012000004d005000001281b00000a72ae0300707e100000046f4900000a8013000004d005000001281b00000a72c80300707e10000004284a00000a80140000042a1e02284b00000a2a42534a4201000100000000000c00000076342e302e33303331390000000005006c00000068060000237e0000d4060000ec07000023537472696e677300000000c00e0000e403000023555300a4120000100000002347554944000000b41200009002000023426c6f620000000000000002000001571502080908000000fa25330016000001000000300000000300000014000000130000001b0000004b00000002000000090000000100000001000000070000000700000000000a0001000000000006006f0068000a0099008d000e00ca0000000600f40068000e00040100000a0020018d001200480142011600720163010e009401000027009d0100000600dc01ca010600ef01ca0106001b02ca010a0030028d000a003e028d0012004d02420106000303e4020600350315030600550315030a006f008d000600b00368000600bd03ca010600dd0368000a000e048d000a0053048d000600ad0468001200d10442010a00f7048d001600070563011200190542011a0063058d001600720563011600860563010600a30568001a00cf058d000600d60568001200160642012300580600000a008a0677060a00960677060e00ca0600000e00d406000006000507ea062b00340700000600540768001e006c07000006009607ca010a00b3078d0000000000010000000000010001008101100025003700050001000100010110004a0037000900050006001600a7000a001600af000d001100d10010001100d700140006001601100006001c01340001002b013800010051013c00010057013c000100790140000100870140000100a60144000100ac010a000100b7010d000100be0148003100e9014b003100f9014f00310002024f00310010024f003100260253005020000000009600dd00180001006420000000009600e7001e0002007220000000009300ef0022000200a020000000009300fe0028000300fc2000000000960011012e000400b0210000000091004802570005000c220000000081005b0264000b007c22000000008100720172001200602300000000860060027f0017007425000000008100660287001900f22500000000910070028c0019001826000000008100780292001a003c26000000009100830298001b007e2600000000810088029e001c0090260000000081008f029e001c00ec270000000081009c029e001c00042a000000008100a3029e001c00ac2a000000008618ad029e001c00202a000000009118d2071e001c0000000100b30200000100b30200000100ba0200000100bc0200000100c00200000200c30200000300ca0200000400cc0200000500ce0200000600d00200000100d20200000200c30200000300ca0200000400cc0200000500ce0200000600d00200000700d70200000100d20200000200ca0200000300ce0200000400d70202000500dc0200000100bc0200000200b3020000010010030000010010030000010010038900ad029e009100ad02a2009900ad029e00a1008a03a700a1009603ad001900a20310002100b503b500b100c803ba002100d103ba00b900e403be00b900eb03c500b900f603c900a1000004ad00c1001804cf00a1002704d4003100ad02da0031002f04df0031003c04df0079004904f600c9005b04fd00710064040201710072040201710080040201c900ad02080171008a04020171009f040201a900bf0413013100ad021a013900e10427013900ea042d01e100fd043201e9000f05370139002e053d01e9003c054301310078055201e100ad025d01090191056a01b900e4037001610096038301690096038b011101ad02da00c100ba05df002101ad02da001901f0059901c10078055201c100ff059f0129012306ab0139003806b00171004106b50139004f06da0041006b06ba013901ad02c0014101a106c6013100ad0643012900b706e0016100c106e4015101dd06e90149010c07ef010c0018070102510021070a00510029070f0251003f071202610148070f02710179071702610186070d0071018d071d027901a10726024901a8079200b900e4032d028101b80733020901c1074301b900e4034702a900d9075802a900e20760021100ad029e002e00130068022e001b007102ea000e0148017601cd010702220237024e02f9010480000000000000000000000000000000007303000004000000000000000000000001005f000000000000000000000000000000000000007600000000000000000000000000000000000000b900000000000000000000000000000000000000300100000000010000000000000000000000000063010000000000000000000000000000000000004e050000000000000000000000000000000000005a07000000002300e5002500f100230022012500570125006501550093015d00a60100000000003c4d6f64756c653e0056616c6865696d496e76656e746f727944656c6574652e646c6c00496e76656e746f727944656c65746556310056616c6865696d536f6c6f546f6f6c6b697400496e76656e746f727944656c65746550616e656c006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e65720070616e656c00436f6e6669677572650044697361626c65004f776e7300457863657074696f6e004661756c7400496e76656e746f7279477569005469636b004f776e6572004775690047616d654f626a65637400726f6f7400556e6974792e546578744d65736850726f00544d50726f00544d505f54657874006c6162656c00627574746f6e4c6162656c00556e697479456e67696e652e554900427574746f6e0064657374726f79427574746f6e0063616e63656c427574746f6e004974656d44726f70004974656d446174610061726d65640061726d6564436f756e7400726573756c7400726573756c74556e74696c0053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c616773004669656c64496e666f00447261674974656d0044726167496e76656e746f72790044726167416d6f756e74004d6574686f64496e666f00436c6561724472616700526563745472616e73666f726d005472616e73666f726d005265637400544d505f466f6e74417373657400546578740053657475700043616e64696461746500416c6c6f7765640057686f6c65537461636b004e616d650043616e63656c00436c69636b44657374726f7900557064617465004f6e44657374726f79002e63746f7200706c6179657200650067756900676f00706172656e740078007900770068006e616d6500666f6e740063617074696f6e0053797374656d2e52756e74696d652e496e7465726f705365727669636573004f7574417474726962757465006974656d0053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d496e76656e746f727944656c657465006f705f496d706c69636974006f705f457175616c697479006d5f6c6f63616c506c6179657200547970650047657454797065004d656d626572496e666f006765745f4e616d65006765745f4d65737361676500537472696e6700436f6e636174006765745f4c656e67746800537562737472696e67006f705f496e657175616c69747900436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e7400476574436f6d706f6e656e7400536574506172656e7400566563746f7232006765745f7a65726f007365745f616e63686f724d696e007365745f616e63686f724d6178007365745f7069766f74007365745f616e63686f726564506f736974696f6e007365745f73697a6544656c74610052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c6500546578744d65736850726f55475549007365745f666f6e74007365745f666f6e7453697a6500436f6c6f72006765745f77686974650047726170686963007365745f636f6c6f720054657874416c69676e6d656e744f7074696f6e73007365745f616c69676e6d656e74007365745f7261796361737454617267657400556e697479456e67696e652e55494d6f64756c650043616e76617352656e646572657200496d616765006765745f7472616e73666f726d0053656c65637461626c65007365745f74617267657447726170686963004d697373696e674d656d626572457863657074696f6e00476574436f6d706f6e656e74496e506172656e740043616e76617300496e76616c69644f7065726174696f6e457863657074696f6e006765745f726f6f7443616e76617300476574436f6d706f6e656e74496e4368696c6472656e00544d505f53657474696e6773006765745f64656661756c74466f6e744173736574006765745f666f6e74006765745f616e63686f724d696e007365745f7465787400427574746f6e436c69636b65644576656e74006765745f6f6e436c69636b00556e697479456e67696e652e4576656e747300556e697479416374696f6e00556e6974794576656e74004164644c697374656e65720053657441637469766500497356697369626c650047657456616c756500496e76656e746f72790048756d616e6f696400476574496e76656e746f72790053797374656d2e436f6c6c656374696f6e732e47656e65726963004c697374603100476574416c6c4974656d7300436f6e7461696e73006d5f737461636b006d5f65717569707065640053686172656444617461006d5f736861726564006d5f71756573744974656d00496e74333200617373656d626c795f6775697574696c73004c6f63616c697a6174696f6e006765745f696e7374616e6365006d5f6e616d65004c6f63616c697a65004d6574686f644261736500496e766f6b650052656d6f76654974656d0054696d65006765745f74696d65007365745f696e74657261637461626c65002e6363746f72004765744669656c64004765744d6574686f640000053a002000004353006f006c006f0054006f006f006c006b00690074005f0049006e00760065006e0074006f0072007900440065006c00650074006500440072006900760065007200000d20006c006100620065006c00003349006e00760065006e0074006f00720079002000640072006100670020005500490020006300680061006e00670065006400003949006e00760065006e0074006f00720079002000630061006e00760061007300200075006e0061007600610069006c00610062006c006500003153006f006c006f0054006f006f006c006b00690074005f00440065007300740072006f00790053007400610063006b00001d530065006c0065006300740065006400200073007400610063006b00001b440065007300740072006f007900200073007400610063006b00000d430061006e00630065006c0000072e002e002e00002b53007400610063006b00200077006100730020006e006f0074002000720065006d006f007600650064000015440065007300740072006f0079006500640020000007200078002000002143006f006e006600690072006d002000640065007300740072006f0079002000000d20006900740065006d0073000029440065007300740072006f007900200065006e007400690072006500200073007400610063006b0000515000690063006b0020007500700020006100200073007400610063006b002000660072006f006d00200079006f007500720020006f0077006e00200069006e00760065006e0074006f00720079002e00005b45007100750069007000700065006400200061006e00640020007100750065007300740020006900740065006d0073002000630061006e006e006f0074002000620065002000640065007300740072006f007900650064002e0000808b530070006c0069007400200064007200610067003a00200070006c00610063006500200069007400200069006e00200061006e00200065006d00700074007900200073006c006f0074002000660069007200730074002c0020007400680065006e0020007000690063006b0020007500700020007400680061007400200073007400610063006b002e00002120001420200065006e007400690072006500200073007400610063006b002e00012d2000142020007000650072006d0061006e0065006e0074006c0079002000640065006c006500740065003f0001156d005f0064007200610067004900740065006d00001f6d005f00640072006100670049006e00760065006e0074006f007200790000196d005f00640072006100670041006d006f0075006e007400001b5300650074007500700044007200610067004900740065006d00003c83c391fb1a2840af79d9c41b2e401d0008b77a5c561934e08902060802060e0306120d0306120c05000101120d0300000105000102120d05000101121105000101121503061215030612190306121d030612210306122902060c0306112d03061231030612350c000612391219123d0c0c0c0c0d2007121d0e123d0c0c0c0c12410c200512210e0c0c124110121d072002011215120d04200012290500010212290520010212290500010e1229032000010420010108050001021251070002021251125104200012550320000e0600030e0e0e0e032000080520020e08080420001219050001011251042001010e053001001e00040a01120c06070212191211040a01123906200201123d020400001165052001011165052002010c0c040701123906000112551169072002010e1d1255040a01126d052001011241042001010c040000117105200101117105200101117904200101020907031219121d1d1255042000123d050a01128081072004010c0c0c0c040a0112210520010112750500020e0e0e0c0704121912808112211d125507000202123112310700020212351235050a0112808d05200012808d063001011e0002040a01121d040000124104200012410420001165052000128099052002011c180620010112809d12070712808d123d121d12411239121d1d1255030000020420011c1c0520001280a5092000151280ad01122907151280ad0112290520010213000707021280a5122902060204061280b10500001280b90420010e0e0307010e0620021c1c1d1c0500010e1d1c0300000c0f070712291280a50e0812111d1c1d1c0600030e1c1c1c09070402122912111d1c07200212310e112d07200212350e112d0801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773012040000000000000000000003e4000000020000000000000000000000000000000000000000000003040000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058600000840200000000000000000000840234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004e4010000010053007400720069006e006700460069006c00650049006e0066006f000000c001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000058001b00010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0049006e00760065006e0074006f0072007900440065006c006500740065002e0064006c006c00000000002800020001004c006500670061006c0043006f00700079007200690067006800740000002000000060001b0001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0049006e00760065006e0074006f0072007900440065006c006500740065002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000c000000503000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper
local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','InventoryDeleteV1')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_Delete_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=deleteHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write inventory-delete helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Explosive-fists helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','InventoryDeleteV1'),'Explosive-fists helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18},1)}
  return helper
end
local function stopDelete()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove inventory-delete hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Explosive-fists helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  deleteButton.Caption='Inventory delete: OFF'
end
ValheimDeleteStop=stopDelete
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopDelete();return close() end
form.OnDestroy=function() stopDelete();destroy() end
deleteButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopDelete();playerStatus.Caption='Inventory delete disabled.';return end
    local s=playerContext()
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','InventoryGui'),'Inventory GUI class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'Update',{},1)),'Inventory GUI update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Explosive-fists callback')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode damage prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read damage prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhDelete,4096,%X)
label(vhDeleteRestore)
vhDelete:
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
jne vhDeleteRestore
// InventoryGui instance in RCX is the sole argument to static Tick.
call %X
vhDeleteRestore:
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
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhDelete
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling inventory deletion')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Explosive-fists hook installation failed: '..tostring(info))
    s.info=info
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Explosive-fists helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          assert(readInteger(state.enabled)==1,'Game callback stopped after an error')
        end)
        if not active then
          local stopped,stopError=pcall(stopDelete)
          playerStatus.Caption='Inventory delete stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;deleteButton.Caption='Inventory delete: ON'
    playerStatus.Caption='Open inventory, pick up a full stack, then Destroy entire stack and confirm in the game panel. Equipped, quest and container items are blocked.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopDelete)
    showMessage('Valheim inventory deletion: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local minerHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300b296d56a0000000000000000e00002210b010b000022000000060000000000009e41000000200000006000000000001000200000000200000400000000000000040000000000000000a0000000020000000000000300408500001000001000000000100000100000000000001000000000000000000000004c4100004f00000000600000d002000000000000000000000000000000000000008000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000a4210000002000000022000000020000000000000000000000000000200000602e72737263000000d0020000006000000004000000240000000000000000000000000000400000402e72656c6f6300000c000000008000000002000000280000000000000000000000000000400000420000000000000000000000000000000080410000000000004800000002000500d82e0000741200000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133003003a00000001000011002b260002031f366f0300000a0a0614280400000a16fe010c082d04060b2b18026f0500000a1000000214280600000a0c082dcf140b2b00072a0000133002002701000002000011007e0500000414280700000a16fe010a062d0b7201000070730800000a7a7e0600000414280700000a3ad50000007e0700000414280700000a3ac50000007e0800000414280700000a3ab50000007e0900000414280900000a3aa50000007e0a00000414280900000a3a950000007e0b00000414280900000a3a850000007e0c00000414280700000a2d787e0d00000414280700000a2d6b7e0e00000414280700000a2d5e7e0f00000414280700000a2d517e1000000414280700000a2d447e1200000414280700000a2d377e1300000414280700000a2d2a7e1400000414280700000a2d1d7e1500000414280700000a2d107e1600000414280700000a16fe012b0116000a062d0b7223000070730800000a7a0280030000041480020000041780010000042a3a001680010000041480030000042a0000133002003200000002000011007e0100000417332202280a00000a2c1a027e03000004280b00000a2c0d027e0c00000a280b00000a2b0116000a2b00062a4e00026f0d00000a80020000042803000006002a00001b300200b100000003000011000228040000060b072d0538a0000000007e04000004280a00000a2c157e040000047b1700000402280e00000a16fe012b0117000b072d23007e040000046f14000006007e040000046f0f00000a281000000a00148004000004007e04000004280a00000a0b072d2100729d000070731100000a280100002b80040000047e04000004027d17000004007e040000046f10000006007e040000046f110000060000de0c0a000628050000060000de00002a000000011000000000100093a3000c07000001033003000d02000000000000d003000001281300000a72cb0000701f346f0300000a8005000004d014000001281300000a72df0000701f346f0300000a8006000004d003000001281300000a72010100701f346f0300000a8007000004d003000001281300000a721f01007028010000068008000004d003000001281300000a72390100701f34281400000a8009000004d003000001281300000a72590100701f34281400000a800a000004d003000001281300000a727f0100701f34281400000a800b000004d014000001281300000a72930100702801000006800c000004d00b000001281300000a72b30100702801000006800d000004d00b000001281300000a72cb0100702801000006800e000004d00b000001281300000a72dd0100702801000006800f000004d003000001281300000a720902007028010000068010000004d003000001281300000a72250200701f306f1500000a80110000047e1100000414281600000a2d117e11000004724502007028010000062b01140080120000047e1100000414281600000a2d117e11000004725302007028010000062b01140080130000047e1100000414281600000a2d117e11000004726102007028010000062b01140080140000047e1100000414281600000a2d117e11000004726f02007028010000062b01140080150000047e1100000414281600000a2d117e11000004728502007028010000062b01140080160000042a00000013300200370000000200001100022c2c027b1700000a2c24027b1700000a7b1800000a1f092e11027b1700000a7b1800000a1f0afe012b0117002b0116000a2b00062a00133004007e0000000400001100027b1c0000042c0b027b1e00000416fe012b0117000b072d5500027b1c000004027b1d0000047d1900000a7e0f000004027b1c0000046f1a00000aa5180000010a062200000000fe0216fe010b072d1d7e0f000004027b1c0000040622000020415a8c180000016f1b00000a000002147d1c00000402167d1e0000042a0000133004007701000005000011000328080000062c1f281c00000a2c187e0b000004027b17000004146f1d00000aa51b0000012b0116000c082d0d0002280900000600383b0100007e0c000004027b170000046f1a00000a750b0000010a062c5d067b1e00000a1833547e0d000004066f1a00000a027b17000004281f00000a2c3c7e0e000004066f1a00000a03281f00000a2c2906037b1700000a7b2000000a281f00000a2d1606037b1700000a7b2100000a281f00000a16fe012b0116000c082d0d000228090000060038b200000006027b1c000004281f00000a16fe010c082d05389a0000000228090000060002067d1c00000402067b1900000a7d1d000004027b1d0000042200000000361a027b1d000004282200000a2d0d027b1d000004282300000a2b0117000c082d530002177d1e00000406027b1d00000422000020415b7d1900000a7e0f000004066f1a00000aa5180000010b072200000000fe0216fe010c082d187e0f000004060722000020415b8c180000016f1b00000a00002a0013300300770000000200001100032c6c037b1700000a7b1800000a1f0e2e270328080000062c55037b1700000a7b2000000a2c48037b1700000a7b2000000a7b2400000a2c36281c00000a2c2f7e0b000004027b17000004146f1d00000aa51b0000012c177e08000004027b170000046f1a00000aa51b0000012b0116000a2b00062a00133003005d0000000600001100027b1b0000042c2d027b17000004280a00000a2c207e07000004027b170000046f1a00000a027b1b000004281f00000a16fe012b0117000a062d197e09000004027b17000004178d010000010b076f1d00000a2602147d1b0000042a0000001b3004007e0100000700001100036f2500000a0a037b1700000a7b2000000a7b2600000a0b7e10000004027b170000046f1a00000a751d0000010c0814fe01130611063abf00000000086f2700000a1307388100000011076f2800000a0d007e12000004096f1a00000a6f2900000a729d020070282a00000a2d137e13000004096f1a00000a03281f00000a2b011600130611062d022b3f22000000007e15000004096f1a00000aa5180000017e14000004096f1a00000aa51800000159282b00000a0a7e16000004096f1a00000aa5180000010b2b1011076f2c00000a130611063a6fffffffde1d110775220000011308110814fe01130611062d0811086f2d00000a00dc00220000000006282b00000a220000000007282b00000a5a13041104282200000a2d0c1104282300000a16fe012b011600130611062d0b72ab020070732e00000a7a11042200000000fe0216fe01130611062d2800027b1700000411046f2f00000a130611062d051613052b14027b1700000411046f3000000a00001713052b0011052a0000011000000200450098dd001d0000000013300500af00000008000011000203280b0000060b072d0d0002280c000006003895000000027b1b0000042c0e027b1b00000403281f00000a2b0117000b072d0702280c000006007e07000004027b170000046f1a00000a03281f00000a0b072d58000328080000060a062c090203280d0000062b0117000b072d022b3c7e0a000004027b17000004146f1d00000a267e09000004027b17000004178d010000010c081603a2086f1d00000a26060b072d0702037d1b000004002a0013300200b40000000900001100027b1700000428040000062c1d027b170000046f3100000a2d10027b170000046f3200000a16fe012b0116000c082d04140b2b7d027b170000046f3300000a0a062c0e067b1700000a14fe0116fe012b0116000c082d04140b2b56067b1700000a7b1800000a0d091759450e00000002000000020000000200000002000000020000000600000002000000020000000200000002000000020000000200000006000000020000002b04060b2b04140b2b00072a13300300430000000a0000110002280f0000060a0614fe0116fe010b072d022b2d7e05000004027b17000004027b170000046f3400000a8c180000016f1b00000a0006066f3500000a7d3600000a2a0013300200250000000a0000110002280f0000060a0614fe0116fe010b072d09022809000006002b080206280a000006002a0000001b300400e50000000b000011000002280f0000060a0614fe0116fe01130411042d140002280c0000060002280900000600ddb90000000206280e000006000206280a000006002200001041283700000a5a0b067b1700000a7b1800000a1e2e2e0628080000062c22067b1700000a7b2000000a2c15067b1700000a7b2000000a7b3800000a16fe012b0117002b011600130411042d42007e06000004027b170000046f1a00000aa5180000010c082200000000fe0216fe01130411042d197e06000004027b170000040807588c180000016f1b00000a000000de130d00092805000006000228140000060000de0000002a0000000110000000000100cecf00130700000113300200390000000200001100027b190000042c10027b18000004280a00000a16fe012b0117000a062d12027b18000004027b1a0000046f3900000a0002167d190000042a5e000228130000060002280c00000600022809000006002a0000001b3001004d0000000300001100027b1700000428040000060b072d16000228140000060002280f00000a281000000a002b2600022810000006000228110000060000de130a00062805000006000228140000060000de00002a000000011000000000260012380013070000011b300400d90000000c000011000002280f0000060a062c0d027b170000046f3a00000a2b0116000c082d0d0002281300000600ddab000000027b18000004280a00000a0c082d1102027b170000046f0200002b7d18000004027b18000004280a00000a0c082d0b72df020070732e00000a7a027b190000040c082d1a0002027b180000046f3c00000a7d1a00000402177d1900000400027b18000004027b1a000004067b1700000a7b1800000a1f0e2e0722000020412b05220000f041005a6f3900000a000228100000060000de130b00072805000006000228140000060000de0000002a0000000110000000000100c2c30013070000012600022814000006002a1e02283d00000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c000000a4050000237e0000100600007c07000023537472696e6773000000008c0d00001803000023555300a4100000100000002347554944000000b4100000c001000023426c6f620000000000000002000001571502000908000000fa2533001600000100000025000000030000001e000000180000000b0000003d000000020000000c00000001000000040000000200000000000a00010000000000060065005e000a008f0083000e00c00000000600e600d40006001901d400060082015e000600ef015e001200260283000e005202000027005b0200000e00790200000600af038f030600cf038f0306000104d40006003e045e000a00650083000a007a0483000a00840483000600ba045e000e00de0400002b00ff0400000e00130500005b001a050000060049055e000a005905830006007305d400060085055e002f008d05000006002c06190606003206190606003e06190606006d065e00060074065e00060086065e0006009a065e000e00b40600000a002307830000000000010000000000010001008101100022002f000500010001000101100042002f0009001700080016009d000a001600a5000d001100c70010001100cd0014003300f00018003300f800180033000101180033000e011800330024011c0033002e011c0033003b011c0033004501180033005301180033005f01180033006c01180033007601180033008701200033009301180033009e0118003300a90118003300b40118003300c301180006000402100001002f024200010038024600010044024900010064024c0001008002500001008602490001009c0246005020000000009100ce01240001009820000000009600d8012c000300cb21000000009600e20132000400dc21000000009300ea01360004001a22000000009300f9013c0005003022000000009600ff012c0006000023000000009118b304320007001c25000000009100a902540007006025000000008100b1025a000800ec25000000008100be025e0008007027000000008100ce0264000900f427000000008100e0025a000a006028000000008100f40264000a00fc2900000000810003035e000b00b82a00000000810017036a000c00782b00000000860021035a000c00c82b00000000860029035a000c00fc2b00000000810035035a000c00002d00000000810041035a000c00452d00000000860049035a000c00602d00000000810051035a000c00cc2d00000000810058035a000c00c42e00000000810063035a000c00ce2e0000000086186d035a000c00000001007303000002007803000001007d03000001007d03000001008403000001007d03000001008a03000001008a03000001008a03000001008a03000001008a0361006d036f0069006d035a0031000e047400210017047c00310025048400310017048900210032047c0079006d039900290032049e0081005404aa0081003204b00019006004100039006e04b80081001704b00089008f04bc0081009e04c10091006d0399009100a604c7003100cc04d8003100e704df003100f104e70031003204890051000a05ef00a9002405f30059003005490021004005f70021005005fc00c90065050701d1007e050b015900980512010900a5051601a900b5055000a900be055000c100d0051c01c100d6051c015900e10546005100f2052e01590007064900f1004a063201f9005806370109006406b800010117043b01090179064101f9007d064701110192065a0019016d0399002101be064b012101c90650012101d10647012101d8064701a100e6066a002101f7062e01510005072e01510016074900290128077c0159003b07460041004507500121014f07470189005807c70041006f072e0111006d035a002e000b0097012e001300a0019100a600d200020121012801550165016c01760180018f01048000000000000000000000000000000000ed030000040000000000000000000000010055000000000000000000000000000000000000006c00000000000000000000000000000000000000af000000000000000000000000000000000000000a02000000002500cd0077008a0100000000003c4d6f64756c653e0056616c6865696d52617069644d696e657256352e646c6c0052617069644d696e657256350056616c6865696d536f6c6f546f6f6c6b69740052617069644d696e65724472697665725635006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e6572006472697665720053797374656d2e5265666c656374696f6e004669656c64496e666f005374616d696e61004472617754696d65004c6f61646564576561706f6e0041747461636b486f6c64004d6574686f64496e666f005365744c6f616465640043616e63656c52656c6f61640054616b65496e7075740043757272656e7441747461636b0041747461636b4f776e65720041747461636b576561706f6e004669726554696d657200416374696f6e51756575650054797065004d696e6f72416374696f6e00416374696f6e4b696e6400416374696f6e4974656d00416374696f6e54696d6500416374696f6e4475726174696f6e00416374696f6e456974720046696e644669656c6400436f6e6669677572650044697361626c65004f776e7300457863657074696f6e004661756c74005469636b004f776e657200556e697479456e67696e652e416e696d6174696f6e4d6f64756c6500416e696d61746f7200616e696d61746f7200616363656c657261746564006f726967696e616c5370656564004974656d44726f70004974656d4461746100707265706172656452656c6f6164576561706f6e0041747461636b007370656c6c006f726967696e616c4275727374496e74657276616c007363616c65644275727374730049734d6167696300526573746f72655370656c6c00416363656c65726174655370656c6c0052656c6f6164576561706f6e496e7075740052656c6561736552656c6f6164576561706f6e005061794d6167696352656c6f6164005072657061726552656c6f6164576561706f6e005261706964546f6f6c0050726f74656374005570646174655370656c6c00466978656455706461746500526573746f72650052656c6561736500557064617465004c617465557064617465004f6e44657374726f79002e63746f720074797065006e616d6500706c61796572006572726f72006974656d0053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d52617069644d696e657256350042696e64696e67466c616773004765744669656c64006f705f496e657175616c697479006765745f4261736554797065006f705f457175616c697479004d697373696e674669656c64457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006765745f4d65737361676500436f6d706f6e656e740047616d654f626a656374006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f720052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650048756d616e6f6964004765744d6574686f64004765744e6573746564547970650053686172656444617461006d5f73686172656400536b696c6c7300536b696c6c54797065006d5f736b696c6c54797065006d5f6275727374496e74657276616c0047657456616c75650053696e676c650053657456616c7565004170706c69636174696f6e006765745f6973466f6375736564004d6574686f644261736500496e766f6b6500426f6f6c65616e0041747461636b54797065006d5f61747461636b54797065005265666572656e6365457175616c73006d5f61747461636b006d5f7365636f6e6461727941747461636b0049734e614e004973496e66696e697479006d5f726571756972657352656c6f616400476574576561706f6e4c6f6164696e6754696d65006d5f72656c6f616445697472447261696e0053797374656d2e436f6c6c656374696f6e7300494c6973740049456e756d657261626c650049456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e7400546f537472696e6700537472696e67004d617468004d6178004d6f76654e6578740049446973706f7361626c6500446973706f736500496e76616c69644f7065726174696f6e457863657074696f6e00436861726163746572005472795573654569747200557365456974720049734465616400497354656c65706f7274696e670047657443757272656e74576561706f6e004765744d61785374616d696e61004765744d61784475726162696c697479006d5f6475726162696c6974790054696d65006765745f666978656444656c746154696d65006d5f626f7744726177007365745f737065656400496e41747461636b00476574436f6d706f6e656e74496e4368696c6472656e006765745f737065656400000000002150006c0061007900650072002e006d005f007300740061006d0069006e006100007946006100730074002000610074007400610063006b0073003a00200077006500610070006f006e0020006c006f006100640069006e0067002f007300700065006c006c002000740069006d0069006e00670020006600690065006c0064007300200075006e0061007600610069006c00610062006c006500002d53006f006c006f0054006f006f006c006b00690074005f00520061007000690064004d0069006e006500720000136d005f007300740061006d0069006e00610000216d005f00610074007400610063006b004400720061007700540069006d006500001d6d005f0077006500610070006f006e004c006f00610064006500640000196d005f00610074007400610063006b0048006f006c006400001f53006500740057006500610070006f006e004c006f0061006400650064000025430061006e00630065006c00520065006c006f006100640041006300740069006f006e000013540061006b00650049006e00700075007400001f6d005f00630075007200720065006e007400410074007400610063006b0000176d005f0063006800610072006100630074006500720000116d005f0077006500610070006f006e00002b6d005f00700072006f006a0065006300740069006c0065004600690072006500540069006d0065007200001b6d005f0061006300740069006f006e0051007500650075006500001f4d0069006e006f00720041006300740069006f006e004400610074006100000d6d005f007400790070006500000d6d005f006900740065006d00000d6d005f00740069006d00650000156d005f006400750072006100740069006f006e0000176d005f00650069007400720044007200610069006e00000d520065006c006f0061006400003349006e00760061006c006900640020007300700065006c006c002000720065006c006f0061006400200063006f0073007400003750006c006100790065007200200061006e0069006d00610074006f007200200075006e0061007600610069006c00610062006c006500000094fe36e1b4078e46bdb862d4039e06330008b77a5c561934e08902060802060e0306120d0306120c030612110306121503061219070002121112190e05000101120d0300000105000102120d05000101121d0306122102060202060c030612290306122d050001021229032000010520010112290520010212290420001229042001010807200212110e11390700020212111211042000121907000202121912190707031211121102042001010e07000202121512150307010205000102124107000202124112410320000e0420001249050001011241053001001e00040a01120c050702121d020600011219114d07200212150e113907200212190e1139030612550306115d0420011c1c052002011c1c0407020c02030000020620021c1c1d1c03061171050002021c1c040001020c060703122d0c02050702021d1c0320000c042000127d0320001c050002020e0e0500020c0c0c03200002042001020c042001010c0f07090c0c12751c0c0202127d12808906070302021d1c0907041229122902115d0507021229020300000c09070512290c0c121d02040a0112210707031229121d020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f777301007441000000000000000000008e41000000200000000000000000000000000000000000000000000080410000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058600000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001800010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d00520061007000690064004d0069006e0065007200560035002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800180001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d00520061007000690064004d0069006e0065007200560035002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000c000000a03100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','RapidMinerV5')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_RapidMinerV5_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=minerHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write rapid-miner helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Rapid-miner helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','RapidMinerV5'),'Rapid-miner helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18},1)}
  return helper
end
local function stopMiner()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove rapid-miner hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Rapid-miner helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  minerButton.Caption='Fast attacks: OFF'
end
ValheimRapidMinerStop=stopMiner
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopMiner();return close() end
form.OnDestroy=function() stopMiner();destroy() end
minerButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopMiner();playerStatus.Caption='Fast attacks disabled.';return end
    local s=playerContext()
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','Player'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'Update',{},1)),'Player update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Rapid-miner callback')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode damage prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read damage prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhRapidMiner,4096,%X)
label(vhRapidMinerRestore)
vhRapidMiner:
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
jne vhRapidMinerRestore
// Player instance in RCX is the sole argument to static Tick; helper checks local ownership.
call %X
vhRapidMinerRestore:
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
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhRapidMiner
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling rapid mining')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Rapid-miner hook installation failed: '..tostring(info))
    s.info=info
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Rapid-miner helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          assert(readInteger(state.enabled)==1,'Game callback stopped after an error')
        end)
        if not active then
          local stopped,stopError=pcall(stopMiner)
          playerStatus.Caption='Fast attacks stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;minerButton.Caption='Fast attacks: ON'
    playerStatus.Caption='Fast attacks: spells get 10x charge/burst timing and fast reloads; use normal spell controls. Crossbow = hold attack, instant rearming/30x animation. Stamina/durability refill; ammo/eitr costs remain.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopMiner)
    showMessage('Valheim rapid mining: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local hoeHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c0103005d25cc6a0000000000000000e00002210b010b000012000000060000000000002e300000002000000040000000000010002000000002000004000000000000000400000000000000008000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000d82f00005300000000400000c802000000000000000000000000000000000000006000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000034100000002000000012000000020000000000000000000000000000200000602e72737263000000c8020000004000000004000000140000000000000000000000000000400000402e72656c6f6300000c000000006000000002000000180000000000000000000000000000400000420000000000000000000000000000000010300000000000004800000002000500fc240000dc0a0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013300300540000000100001100d003000001280300000a021f346f0400000a0a0614280500000a2d1a066f0600000ad00e000001280300000a280700000a16fe012b0116000c082d11720100007002280800000a730900000a7a060b2b00072a52000280030000041480020000041780010000042a3a001680010000041480030000042a133002003200000002000011007e0100000417332202280a00000a2c1a027e03000004280b00000a2c0d027e0c00000a280b00000a2b0116000a2b00062a4e00026f0d00000a80020000042803000006002a00001b300200c300000003000011000228040000060b072d0538b2000000007e04000004280a00000a2c157e040000047b0b00000402280e00000a16fe012b0117000b072d23007e040000046f09000006007e040000046f0f00000a281000000a00148004000004007e04000004280a00000a0b072d21007211000070731100000a280100002b80040000047e04000004027d0b000004007e04000004036f0a0000060000de280a00062805000006007e04000004280a00000a16fe010b072d0b7e040000046f090000060000de00002a0001100000000010008999002806000001033003005800000000000000723b00007028010000068005000004724f00007028010000068006000004726900007028010000068007000004728f00007028010000068008000004d014000001280300000a72b30000701f34281300000a80090000042a133003007a0000000400001100027b0b00000428040000062c10027b0b0000046f1400000a16fe012b0116000c082d04140b2b507e09000004027b0b000004146f1500000a74080000010a062c2e067b1600000a7b1700000a72cd000070281800000a2d1a067b1600000a7b1700000a72e1000070281800000a2d03142b0106000b2b00072a000013300300430000000200001100027b0c0000042c10027b0b000004280a00000a16fe012b0117000a062d1c7e06000004027b0b000004027b0d0000048c0e0000016f1900000a0002167d0c0000042a00133004002d01000005000011000228080000060a062c21027b0b0000046f1a00000a2c14032c11281b00000a2d0a281c00000a16fe012b0116000b072d0d000228090000060038ed000000027b0c0000040b072d2400027e06000004027b0b0000046f1d00000aa50e0000017d0d00000402177d0c000004007e06000004027b0b000004027b0d00000422cdcc4c3d281e00000a8c0e0000016f1900000a007e05000004027b0b000004027b0b0000046f1f00000a8c0e0000016f1900000a0006066f2000000a7d2100000a7203010070282200000a2d3f7219010070282200000a2d0c7227010070282200000a2c27282300000a7e08000004027b0b0000046f1d00000aa50e0000015922cdcc4c3dfe0216fe012b0117000b072d1b7e07000004027b0b000004282300000a8c0e0000016f1900000a002a0000001b3002004c00000003000011000002280800000614fe0116fe010b072d0702280900000600027b0b00000428040000060b072d0c02280f00000a281000000a0000de130a00062805000006000228090000060000de00002a011000000000010036370013060000012600022809000006002a1e02282400000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c000000b8030000237e0000240400002c04000023537472696e677300000000500800003c010000235553008c0900001000000023475549440000009c0900004001000023426c6f620000000000000002000001571d02000908000000fa253300160000010000001b000000030000000d0000000d000000080000002400000001000000020000000500000001000000040000000100000000000a0001000000000006005f0058000a0089007d000e00ba0000000600e000ce0006000e01ce0006003a0158000e00740100001f007d0100000600ed01cd0106000d02cd0106003d02580006004202580006006602ce000600960258000600ab0258000600b90258000a005f007d000a00f5027d000a00ff027d000e00350300000e004803000006005903ce0023006b0300000e009b0300000600c903580012000d0400000a001e047d0000000000010000000000010001008101100020002b00050001000100010110003e002b0009000a000800160097000a0016009f000d001100c10010001100c70014003300f0001e003300f8001e003300fe001e00330006011e0033001901220051804f01440006005801100001005e014c000100660144005020000000009300ea0018000100b020000000009600230126000200c5200000000096002d012c000300d420000000009300350130000300122100000000930044013600040028210000000096004a013c00050008220000000091182e032c0008006c2200000000810086014f000800f4220000000086008a015400080044230000000086009201580008008024000000008100970154000900e8240000000081009e0154000900f224000000008618a8015400090000000100ae0100000100b30100000100b30100000100ba0100000100b30100000200c00100000300ca0100000100c0014900a8015d005100a801540059005402620059007302690021007c02710021008802790059009d027e007900b20286008100a8018c008900cf02990089007c029f001900db0210003100e902ab0089009d029f0091000a03af0089001903b4009900a8018c0099002103ba0059003e03cb00a9005203d300b1006403d70041007603de00b9007f030d0079007c02e20021008603f000a9008f03d300c1009f03f600c100b703f6002100c003fa00c900ce03ff00a900d20305014100e00305014100f1034400d10014040901d90023040e011100a80154000c00280047002e000b0018012e00130021019100a700c500e80012010480000000000000000000000000000000002b02000004000000000000000000000001004f000000000000000000000000000000000000006600000000000000000000000000000000000000a900000000000000000000000000000000000000fe03000000002500c00000000000003c4d6f64756c653e0056616c6865696d5261706964486f6556322e646c6c005261706964486f6556320056616c6865696d536f6c6f546f6f6c6b6974005261706964486f654472697665725632006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e6572006472697665720053797374656d2e5265666c656374696f6e004669656c64496e666f004669656c64005374616d696e610044656c61790050726573736564004c617374557365004d6574686f64496e666f0052696768744974656d00436f6e6669677572650044697361626c65004f776e7300457863657074696f6e004661756c74005469636b00496e74657276616c004f776e6572006368616e676564006f726967696e616c44656c6179004974656d44726f70004974656d4461746100486f650052656c65617365005374657000557064617465004f6e44657374726f79002e63746f72006e616d6500706c61796572006572726f720074616b65496e7075740064740053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d5261706964486f65563200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650042696e64696e67466c616773004765744669656c64006f705f457175616c697479006765745f4669656c64547970650053696e676c65006f705f496e657175616c69747900537472696e6700436f6e636174004d697373696e674669656c64457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006765745f4d65737361676500436f6d706f6e656e740047616d654f626a656374006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f720048756d616e6f6964004765744d6574686f640043686172616374657200497344656164004d6574686f644261736500496e766f6b650053686172656444617461006d5f736861726564006d5f6e616d650053657456616c756500496e506c6163654d6f646500487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c0047657456616c7565004d617468004d696e004765744d61785374616d696e61004765744d61784475726162696c697479006d5f6475726162696c69747900617373656d626c795f7574696c73005a496e70757400476574427574746f6e0054696d65006765745f74696d6500000f50006c0061007900650072002e00002953006f006c006f0054006f006f006c006b00690074005f005200610070006900640048006f00650000136d005f007300740061006d0069006e00610000196d005f0070006c00610063006500440065006c006100790000256d005f0070006c006100630065005000720065007300730065006400540069006d00650000236d005f006c0061007300740054006f006f006c00550073006500540069006d0065000019470065007400520069006700680074004900740065006d00001324006900740065006d005f0068006f006500002124006900740065006d005f00630075006c00740069007600610074006f00720000154a006f00790041006c0074004b00650079007300000d410074007400610063006b0000114a006f00790050006c0061006300650000000000d0d1eef316d2fc448b888f9e4d69b9a50008b77a5c561934e08902060802060e0306120d0306120c05000112110e030612110306121505000101120d0300000105000102120d05000101121907000301120d020c02060c04cdcc4c3d02060204200012210320000104200101020420010108060001122d113107200212110e11350700020212111211042000122d07000202122d122d0500020e0e0e042001010e07070312111211020500010212450700020212451245030701020320000e042000124d050001011245053001001e00040a01120c05070212190207200212150e1135032000020620021c1c1d1c0306125d050002020e0e0707031221122102052002011c1c030000020420011c1c0500020c0c0c0320000c040001020e0300000c0507021221020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773010030000000000000000000001e3000000020000000000000000000000000000000000000000000001030000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff250020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001000000018000080000000000000000000000000000001000100000030000080000000000000000000000000000001000000000048000000584000006c02000000000000000000006c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004cc010000010053007400720069006e006700460069006c00650049006e0066006f000000a801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000004c001600010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d005200610070006900640048006f006500560032002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005400160001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d005200610070006900640048006f006500560032002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000c000000303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','RapidHoeV2')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_RapidHoeV2_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=hoeHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write rapid-hoe helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Rapid-hoe helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','RapidHoeV2'),'Rapid-hoe helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18,2,12},1)}
  return helper
end
local function stopHoe()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove rapid-hoe hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Rapid-hoe helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  hoeButton.Caption='Rapid hoe: OFF'
end
ValheimRapidHoeStop=stopHoe
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopHoe();return close() end
form.OnDestroy=function() stopHoe();destroy() end
hoeButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopHoe();playerStatus.Caption='Rapid hoe disabled.';return end
    local s=playerContext()
    if ValheimDragBuildStop then ValheimDragBuildStop() end
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','Player'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'UpdatePlacement',{2,12},1)),'Player update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Rapid-hoe callback')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode damage prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read damage prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhRapidHoe,4096,%X)
label(vhRapidHoeRestore)
vhRapidHoe:
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
jne vhRapidHoeRestore
// Player, takeInput and dt are passed unchanged to Tick and the original placement method.
call %X
vhRapidHoeRestore:
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
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhRapidHoe
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling rapid hoe')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Rapid-hoe hook installation failed: '..tostring(info))
    s.info=info
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Rapid-hoe helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          assert(readInteger(state.enabled)==1,'Game callback stopped after an error')
        end)
        if not active then
          local stopped,stopError=pcall(stopHoe)
          playerStatus.Caption='Rapid hoe stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;hoeButton.Caption='Rapid hoe: ON'
    playerStatus.Caption='Equip the hoe, select a terrain action and hold use: up to 20 actions/second, stamina refill and full hoe durability. Normal material costs apply.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopHoe)
    showMessage('Valheim rapid hoe: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

do
local dragHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c01030016a9c96a0000000000000000e00002210b010b000088000000060000000000001ea600000020000000c0000000000010002000000002000004000000000000000400000000000000000001000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000cca500004f00000000c00000d00200000000000000000000000000000000000000e000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000024860000002000000088000000020000000000000000000000000000200000602e72737263000000d002000000c0000000040000008a0000000000000000000000000000400000402e72656c6f6300000c00000000e0000000020000008e0000000000000000000000000000400000420000000000000000000000000000000000a60000000000004800000002000500a45a0000284b000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b300300870000000100001100160b7e04000004250c1201280400000a00007e040000046f0500000a1efe040d092d0b7201000070730600000a7a02172e090218fe0116fe012b0116000d092d062818000006007e04000004730b0000060a06027d1300000406037d14000004066f0700000a00724d000070800500000400de100716fe010d092d0708280800000a00dc002a00011000000200030072750010000000001b300200430000000200001100160a7e04000004250c1200280400000a00007e040000046f0500000a2c0c7e040000046f0900000a2b0114000bde100616fe010d092d0708280800000a00dc00072a0001100000020003002d30001000000000133002004500000003000011007e0200000417330a7e0300000417fe012b0116000c082d0b720e010070730600000a7a2822000006281a0000060a727801007006280a00000a8005000004060b2b00072a000000133001000b000000040000110028230000060a2b00062a660002280600000600178003000004729c01007080050000042a0000001b300200f700000005000011007e0900000414280b00000a2d787e0a00000414280b00000a2d6b7e0b00000414280b00000a2d5e7e0c00000414280b00000a2d517e0d00000414280c00000a2d447e0e00000414280c00000a2d377e0f00000414280c00000a2d2a7e1000000414280c00000a2d1d7e1100000414280c00000a2d107e1200000414280c00000a16fe012b0116000b072d0b7277020070730d00000a7a2818000006007e0700000417588007000004028006000004178002000004168003000004160a7e04000004250c1200280400000a00007e040000046f0e00000a0000de100616fe010b072d0708280800000a00dc0072cd02007080050000042a00011000000200bd001edb0010000000001b300200450000000600001100281800000600168002000004148006000004160a7e04000004250b1200280400000a00007e040000046f0e00000a0000de100616fe010c082d0707280800000a00dc002a00000001100000020015001e33001000000000133002003200000007000011007e0200000417332202280f00000a2c1a027e06000004281000000a2c0d027e1100000a281000000a2b0116000a2b00062a00001b3003000301000008000011000228080000060c082d07160b38ee000000007e08000004280f00000a2c297e080000047b1500000402281200000a2d137e080000047b160000047e07000004fe012b0116002b0117000c082d23007e080000046f0c000006007e080000046f1300000a281400000a00148008000004007e08000004280f00000a0c082d3000728a030070731500000a280100002b80080000047e08000004027d150000047e080000047e070000047d16000004007e0800000403046f120000060bde420a0072b6030070066f1700000a6f1800000a280a00000a80050000047e08000004280f00000a16fe010c082d0b7e080000046f0c00000600280700000600170bde0000072a000110000000001200acbe00421a000001133007006401000009000011731900000a8004000004d005000001281a00000a72e00300701f346f1b00000a8009000004d005000001281a00000a72020400701f346f1b00000a800a000004d005000001281a00000a72260400701f346f1b00000a800b000004d005000001281a00000a724c0400701f346f1b00000a800c000004d005000001281a00000a72700400701f34141b8d1b0000010a0616d008000001281a00000aa20617d009000001281a00000aa20618d00a000001281a00000aa20619d01d000001281a00000aa2061ad01d000001281a00000aa20614281c00000a800d000004d005000001281a00000a72860400701f34281d00000a800e000004d005000001281a00000a72a60400701f34281d00000a800f000004d005000001281a00000a72cc0400701f34281d00000a8010000004d005000001281a00000a72f60400701f34281d00000a8011000004d020000001281a00000a72180500701f34281d00000a80120000042a1e02281e00000a2a1b300300bd0000000a0000110002167d1700000402167d1800000402147d1b000004027b15000004280f00000a16fe010b072d1b7e0b000004027b1500000422003c1cc68c210000016f1f00000a0000027b210000046f2000000a0c2b1c1202282100000a0a06280f00000a16fe010b072d0706281400000a001202282200000a0b072dd9de0f1202fe160300001b6f2300000a00dc00027b210000046f2400000a00027b22000004280f00000a16fe010b072d0c027b22000004281400000a0002147d220000042a00000001100000020050002b7b000f0000000013300300c90000000b000011007e12000004027b15000004146f2500000a74260000010a0339a4000000282600000a399a000000027b150000046f2700000a398a000000027b150000046f2800000a2d7d027b150000046f2900000a2d70027b150000046f2a00000a2c63062c60067b2b00000a7b2c00000a7232050070282d00000a2c49282e00000a2d42282f00000a2d3b283000000a2d34283100000a2d2d283200000a2d26283300000a2d1f283400000a280f00000a2c0f283400000a6f3500000a16fe012b0117002b0116000b2b00072a0000001b300500540200000c000011007e10000004027b15000004178d010000011305110516168c1d000001a211056f2500000a267e09000004027b150000046f3600000a750c0000010a027e11000004027b15000004146f2500000a75080000017d1b00000406280f00000a2c27027b1b000004280f00000a2c1a7e0a000004027b150000046f3600000a283700000a16fe012b011600130611062d0816130438ba010000027b1b0000046f1300000a6f3800000a6f3900000a0b07724c0500706f3a00000a2d1a0772580500706f3a00000a2d0d0772620500706f3a00000a2c2a07726c0500706f3a00000a2d1d0772760500706f3a00000a2d1007727c0500706f3a00000a16fe012b011600130611062d08161304384301000002066f3b00000a6f3c00000a7d1c00000402066f3b00000a6f3d00000a7d1e000004733e00000a0c066f0200002b086f4000000a00027b230000046f4100000a0000086f4200000a13072b251207284300000a0d027b23000004066f3b00000a096f3c00000a6f4400000a6f4500000a001207284600000a130611062dcede0f1207fe160600001b6f2300000a00dc0002027b230000041728170000067d2400000402027b230000041628170000067d25000004027b24000004220000003f3412027b25000004220000003ffe0416fe012b011700130611062d051613042b6302027b1e000004027b24000004220000003f2f12284700000a027b25000004284800000a2b10284900000a027b24000004284800000a00284a00000a7d1d00000402177d1f00000402167d2000000402177d170000040206280f000006001713042b0011042a0110000002005801368e010f00000000133005007e0200000d00001100027b22000004280f00000a130811082d55007282050070284b00000a0a06280f00000a130811082d0b72a2050070730600000a7a0206734c00000a7d22000004027b2200000422cdcc4c3e229a99593f220000803f229a99993e734d00000a6f4e00000a000038500100000072da050070731500000a0b0003176f0300002b130916130a38130100001109110a9a0c00086f5000000a280f00000a130811082d0538f000000072f2050070731500000a0d096f3b00000a076f3b00000a166f5100000a00096f3b00000a036f3b00000a086f5200000a6f3c00000a6f4400000a6f5300000a00096f3b00000a036f3b00000a6f3d00000a285400000a086f5200000a6f3d00000a285500000a6f5600000a00096f3b00000a086f5200000a6f5700000a6f5800000a00096f0400002b086f5000000a6f5900000a00096f0500002b1304086f5000000a6f5a00000a8d0d00000113051613062b1111051106027b22000004a2110617581306110611058e69fe04130811082de1110411056f5b00000a001104166f5c00000a001104166f5d00000a0000110a1758130a110a11098e69fe04130811083adcfeffff027b21000004076f5e00000a0000027b210000046f5f00000a027b1f000004fe04130811083a94feffff161307388500000000027b2100000411076f6000000a1107027b1f0000042f0f1107027b20000004fe0416fe012b0116006f6100000a00027b2100000411076f6000000a6f3b00000a027b1c000004027b1d00000411076b284800000a286200000a6f6300000a00027b2100000411076f6000000a6f3b00000a027b1e0000046f6400000a00001107175813071107027b210000046f5f00000afe04130811083a63ffffff2a000013300800ca0200000e00001100160a38aa020000007e12000004027b15000004146f2500000a74260000010b027b150000046f6500000a0c082d17286600000a027b1b0000046f6700000a6f6800000a2b0117000d08130511053a9500000000027b15000004027b1b000004166f6900000a130511052d120002720c060070281100000600384b020000027b15000004077b2b00000a7b6a00000a7b6b00000a6f6c00000a130511052d12000272580600702811000006003818020000077b2b00000a7b6d00000a2c0f077b6e00000a2200000000fe032b011700130511052d12000272d606007028110000060038e201000000286f00000a16fe0113047e0d000004027b150000041b8d010000011306110616027b1b000004a2110617027b1c000004027b1d000004027b200000046b284800000a286200000a8c09000001a2110618027b1e0000048c0a000001a2110619168c1d000001a211061a11048c1d000001a211066f2500000a2602257b2000000417587d20000004027b21000004027b2000000417596f6000000a166f6100000a0009130511052d1a027b15000004027b1b0000047b7000000a1615176f7100000a0008130511052d7900027b150000047e0e000004027b15000004146f2500000aa5210000016f7200000a00077b2b00000a7b6d00000a16fe01130511052d41072200000000077b6e00000a7e0f000004027b15000004178d01000001130611061607a211066f2500000aa5210000017e7300000a5a59287400000a7d6e00000a007e0c000004027b15000004287500000a8c210000016f1f00000a001b8d01000001130611061672fe060070a2110617027b200000048c43000001a21106187216070070a2110619027b1f0000048c43000001a211061a721a070070a21106287600000a8005000004027b20000004027b1f000004fe04130511052d0702280c00000600000617580a061a2f08027b180000042b011600130511053a3ffdffff2a0000133003005b0000000f000011001d8d010000010a0616722c070070a20617027b200000048c43000001a206187216070070a20619027b1f0000048c43000001a2061a7252070070a2061b03a2061c7266070070a206287600000a800500000402280c000006002a00133005003c03000010000011007e0300000417fe0116fe01130911092d1f027b1a000004027b150000040203280d0000066f330000061308380803000016287700000a0a027b170000042d08027b180000042b0117000b0203280d000006130911092d2d000716fe01130911092d1a0002280c0000060002067d19000004726a07007080050000040007130838b4020000027b1900000416fe01130911092d100002067d190000041713083895020000072c3b7e11000004027b15000004146f2500000a7408000001027b1b000004281200000a2d1417287800000a2d0c1f1b287900000a16fe012b0116002b011700130911092d210002280c0000060002067d1900000472bc0700708005000004171308382e020000027b1800000416fe01130911092d100002281000000600171308380f020000027b17000004130911092d470016287800000a130911092d0816130838ee01000002177d1900000402280e000006130911092d170002280c0000060002167d1900000416130838c401000002167d190000040006130911092d1e0002167d1700000402177d1800000402167d2000000417130838970100001202287a00000a6f5200000a6f3c00000a287a00000a6f5200000a6f7b00000a287c00000a00287d00000a027b1c000004737e00000a130a120a081203287f00000a2c0d09220000c842fe0416fe012b011700130911093afc00000000027b1e000004285400000a120209288000000a027b1c000004288100000a284a00000a1304027b24000004220000003f3730027b25000004220000003f321f12047b8200000a288300000a12047b8400000a288300000afe0516fe012b0117002b011600130511052d08027b250000042b06027b2400000400130611052d0912047b8400000a2b0712047b8200000a00130702027b1e00000411052d07284700000a2b05284900000a001106284800000a110722000000003203172b0115006b284800000a284a00000a7d1d000004021107110628160000067d1f000004027e09000004027b150000046f3600000a740c000001280f00000600007e0b000004027b1500000422003c1cc68c210000016f1f00000a007216080070027b1f0000048c43000001722a080070288500000a80050000041713082b0011082a13300200390000000700001100027b1500000428080000062c0f027b160000047e07000004fe012b0116000a062d150002280c0000060002281300000a281400000a00002a560002280c00000600027b1a0000046f29000006002ac20273340000067d1a00000402177d1f00000402738600000a7d2100000402738700000a7d2300000402288800000a002a133004002a0000001100001100171f1802288900000a035b220000003f586c288a00000a691758288b00000a288c00000a0a2b00062a00001b30030009010000120000110022000000000a00026f8d00000a130438cc0000001204288e00000a0b00026f8d00000a130538940000001205288e00000a0c0012017b8f00000a12027b8f00000a59288900000a220ad7a33c3035032d1112017b8200000a12027b8200000a592b0f12017b8400000a12027b8400000a5900288900000a220ad7a33cfe0216fe012b011600130611062d022b3106032d1112017b8400000a12027b8400000a592b0f12017b8200000a12027b8200000a5900288900000a289000000a0a001205289100000a130611063a5cffffffde0f1205fe160700001b6f2300000a00dc001204289100000a130611063a24ffffffde0f1204fe160700001b6f2300000a00dc00060d2b00092a000000011c000002002600abd1000f0000000002001000e3f3000f000000001b300200340000001300001100160a7e26000004250b1200280400000a000014802700000414802800000400de100616fe010c082d0707280800000a00dc002a01100000020003001f220010000000001b30020064000000140000110002281d0000061000739200000a0a000603282000000600160b7e26000004250c1201280400000a0000028028000004066f9300000a802700000400de100716fe010d092d0708280800000a00dc0000de100614fe010d092d07066f2300000a00dc002a011c000002001a00243e00100000000002000f0043520010000000001b3006007401000015000011001613057e260000042513071205280400000a00007e2700000414fe0116fe01130811082d0b7235090070730600000a7a02289400000a2602289500000a1309120972140a0070289600000a72180a0070280a00000a289700000a0a00067e27000004289800000a0006289900000a0b07282100000626de120714fe01130811082d07076f2300000a00dc00160c389400000000082c1772220a0070088c4300000172280a0070288500000a2b05722c0a0070000d027e28000004167e280000046f9a00000a1f30096f9a00000a59288b00000a6f9b00000a09722e0a0070289c00000a289700000a13041104289d00000a16fe01130811082d022b2600061104289e00000a0011041306de6326001104289d00000a130811082d02fe1a00de0000000817580c082010270000fe04130811083a5bffffff72380a0070739f00000a7a0006289d00000a16fe01130811082d070628a000000a0000dc110516fe01130811082d081107280800000a00dc0011062a4164000002000000700000000900000079000000120000000000000000000000fd000000100000000d0100001400000051000001020000005c000000e70000004301000019000000000000000200000004000000580100005c01000014000000000000002e731e00000a80260000042a4e02722c0a00707d2a00000402281e00000a002a133002008d00000016000011000228a100000a2d0f026f9a00000a1f30fe0216fe012b0116000c082d0b72b20a007073a200000a7a00020d1613042b430911046fa300000a0a0628a400000a2d1b061f202e16061f2d2e11061f5f2e0c061f282e07061f29fe012b0117000c082d0b726b0b007073a200000a7a1104175813041104096f9a00000afe040c082daf026fa500000a0b2b00072a000000133002001b00000007000011000228a600000a2d0b0228a700000a16fe012b0116000a2b00062a001b300300e40100001700001100026fa800000a173212026fa800000a2000020000fe0216fe012b0116000d092d0b72c70b007073a200000a7a00026fa900000a13043888010000120428aa00000a0a00067b2900000428ab00000a2d31067b290000046f9a00000a2080000000301f067b2a0000042c17067b2a0000046f9a00000a2000040000fe0216fe012b0116000d092d0b72110c007073a200000a7a001d8d210000011305110516067b2b000004a0110517067b2c000004a0110518067b2d000004a0110519067b2e000004a011051a067b2f000004a011051b067b30000004a011051c067b31000004a0110513061613072b2211061107986b0b07281e0000060d092d0b72410c007073a200000a7a110717581307110711068e69fe040d092dd2067b2b000004288900000a220000c8423029067b2c000004288900000a220000c8423017067b2d000004288900000a220000c842fe0216fe012b0116000d092d0b727f0c007073a200000a7a067b2e000004067b2e0000045a067b2f000004067b2f0000045a58067b30000004067b300000045a58067b31000004067b310000045a580c08220000803f59288900000a220ad7233cfe0216fe010d092d0b72bd0c007073a200000a7a00120428ac00000a0d093a6afeffffde0f1204fe160900001b6f2300000a00dc002a411c000002000000360000009d010000d30100000f000000000000001b30030014010000180000110003281f000006000228ad00000a1773ae00000a0a000672f50c00706faf00000a0006036fa800000a6fb000000a0000036fa900000a0d389f000000120328aa00000a0b0006077b290000046faf00000a0006077b2a0000046faf00000a00001d8d210000011304110416077b2b000004a0110417077b2c000004a0110418077b2d000004a0110419077b2e000004a011041a077b2f000004a011041b077b30000004a011041c077b31000004a0110413051613062b1511051106986b0c06086fb100000a00110617581306110611058e69fe04130711072ddd00120328ac00000a130711073a51ffffffde0f1203fe160900001b6f2300000a00dc0000de120614fe01130711072d07066f2300000a00dc002a011c000002003700b6ed000f0000000002001500eb000112000000001b300300670100001900001100026fb200000a20000020006afe0216fe01130611062d0b72010d007073a200000a7a73b300000a0a0228ad00000a1773b400000a0b00076fb500000a72f50c007028b600000a16fe01130611062d0b72350d007073a200000a7a076fb700000a0c0817320d082000020000fe0216fe012b011600130611062d0b72710d007073a200000a7a160d388900000006731c00000613041104076fb500000a7d290000041104076fb500000a7d2a0000041104076fb800000a7d2b0000041104076fb800000a7d2c0000041104076fb800000a7d2d0000041104076fb800000a7d2e0000041104076fb800000a7d2f0000041104076fb800000a7d300000041104076fb800000a7d3100000411046fb900000a000917580d0908fe04130611063a6affffff026fba00000a026fb200000afe01130611062d0b729b0d007073a200000a7a00de120714fe01130611062d07076f2300000a00dc0006281f000006000613052b0011052a00411c000002000000360000000f010000450100001200000000000000133003001c00000004000011001f1c28bb00000a72d10d007072f70d007028bc00000a0a2b00062a13300400440000000400001100282200000628bd00000a2d07720d0e00702b2a723d0e0070282200000672430e007028be00000a14fe06bf00000a73c000000a280600002b28c200000a000a2b00062a133003001d0000001a00001100027b2b000004027b2c000004027b2d00000473c300000a0a2b00062a00000013300400230000001b00001100027b2e000004027b2f000004027b30000004027b3100000473c400000a0a2b00062a00133006003e0000001c000011007e050000040328b600000a0a038005000004062c10027b33000004280f00000a16fe012b0117000b072d11027b3300000417031614166fc500000a002a00001b3002007b0000001d0000110000027b420000046f2000000a0b2b1c1201282100000a0a06280f00000a16fe010c082d0706281400000a001201282200000a0c082dd9de0f1201fe160300001b6f2300000a00dc00027b420000046f2400000a00027b45000004280f00000a16fe010c082d0c027b45000004281400000a0002147d450000042a000110000002000e002b39000f00000000133008003d000000070000110002020202020216250a7d3e00000406250a7d3d00000406250a7d3c00000406250a7d3b00000406250a7d3a000004067d39000004022827000006002a0000001330020033000000070000110002282800000600027b430000046fc600000a00027b44000004280f00000a16fe010a062d0c027b44000004281400000a002a0013300500bd0100001e00001100027b44000004280f00000a130811082d55007282050070284b00000a0a06280f00000a130811082d0b724f0e0070730600000a7a0206734c00000a7d44000004027b44000004229a99193e226666663f220000803f229a99993e734d00000a6f4e00000a000072850e0070731500000a0b027b42000004076f5e00000a000003176f0300002b130916130a38130100001109110a9a0c00086f5000000a280f00000a130811082d0538f000000072a90e0070731500000a0d096f3b00000a076f3b00000a166f5100000a00096f3b00000a036f3b00000a086f5200000a6f3c00000a6f4400000a6f5300000a00096f3b00000a036f3b00000a6f3d00000a285400000a086f5200000a6f3d00000a285500000a6f5600000a00096f3b00000a086f5200000a6f5700000a6f5800000a00096f0400002b086f5000000a6f5900000a00096f0500002b1304086f5000000a6f5a00000a8d0d00000113051613062b1111051106027b44000004a2110617581306110611058e69fe04130811082de1110411056f5b00000a001104166f5c00000a001104166f5d00000a0000110a1758130a110a11098e69fe04130811083adcfeffff0713072b0011072a00000013300600c70000001f000011000328c700000a81090000010416fe01130411042d6e007e10000004027b33000004178d010000011305110516168c1d000001a211056f2500000a267e09000004027b330000046f3600000a750c0000010a06280f00000a2c0b066fc800000a16fe012b011700130411042d160003066f3b00000a6f3c00000a8109000001170d2b4200287a00000a6f5200000a0c086f3c00000a086f7b00000a1201220000c8421ffb1728c900000a130411042d04160d2b1103120128ca00000a8109000001170d2b00092a0000000000000000000100000002000000030000000000000004000000050000000100000005000000060000000200000006000000070000000300000007000000040000001b300500720400002000001100027b400000046fcb00000a000228270000060073cc00000a0a027b35000004287d00000a027c360000047b8f00000a284800000a220000003f284800000a286200000a027c3600000428cd00000a0628ce00000a001201027b35000004287d00000a027c360000047b8f00000a220000003f5a22cdcccc3d59284800000a286200000a027b36000004287d00000a22cdcc4c3e284800000a286200000a28cf00000a0000066fd000000a130e3812010000120e28d100000a0c0008280f00000a2c1c086fd200000a2c141201086f5200000a6f3c00000a28d300000a2b011600130f110f2d0538d8000000086f0700002b0d09280f00000a2c0e096fd500000a14fe0116fe012b011600130f110f2d0538ae000000086f1300000a28d600000a130428d700000a11046fd800000a13051105280f00000a2c0e11056f0200002b280f00000a2b011600130f110f2d022b72027b40000004086fd900000a00027b400000046fda00000a2000020000fe0216fe01130f110f2d0b72c70e0070730600000a7a02086f1300000a282a000006130611066f3b00000a086f5200000a6f3c00000a6f6300000a0011066f3b00000a086f5200000a6f3d00000a6f6400000a0000120e28db00000a130f110f3adefeffffde0f120efe160d00001b6f2300000a00dc00027b44000004280f00000a130f110f2d2c007282050070284b00000a1307021107734c00000a7d44000004027b4400000428dc00000a6f4e00000a00000272390f0070731500000a7d45000004027b450000046f0800002b13081108027b440000046fdd00000a0011081108228fc2753d2513106fde00000a0011106fdf00000a001108176fe000000a00120128e100000a1309120128e200000a130a1e8d0900000113111111168f0900000112097b8200000a12097b8f00000a12097b8400000a73c300000a81090000011111178f09000001120a7b8200000a12097b8f00000a12097b8400000a73c300000a81090000011111188f09000001120a7b8200000a12097b8f00000a120a7b8400000a73c300000a81090000011111198f0900000112097b8200000a12097b8f00000a120a7b8400000a73c300000a810900000111111a8f0900000112097b8200000a120a7b8f00000a12097b8400000a73c300000a810900000111111b8f09000001120a7b8200000a120a7b8f00000a12097b8400000a73c300000a810900000111111c8f09000001120a7b8200000a120a7b8f00000a120a7b8400000a73c300000a810900000111111d8f0900000112097b8200000a120a7b8f00000a120a7b8400000a73c300000a81090000011111130b1f108d4300000125d04a00000428e400000a130c1108110c8e696fe500000a0016130d2b211108110d110b110c110d948f0900000171090000016fe600000a00110d1758130d110d110c8e69fe04130f110f2dd102282d00000600021b8d010000011312111216726f0f0070a2111217027b400000046fda00000a8c43000001a211121872830f0070a2111219027b34000004a211121a729d0f0070a21112287600000a2826000006002a0000411c000002000000ad00000029010000d60100000f00000000000000133002001600000011000011027c2c000004037b2c00000428e700000a0a2b00062a00001b300300880100002100001100027b400000046fda00000a16fe0116fe01130611062d0b7246100070730600000a7a73b300000a0a00027b400000046fd000000a130738ef000000120728d100000a0b0007280f00000a130611062d0b7205110070730600000a7a076f5200000a6f3c00000a027b35000004288100000a0c076f5200000a6f3d00000a0d076f0900002b130406731c00000613051105076f1300000a28d600000a7d29000004110512027b8200000a7d2b000004110512027b8f00000a7d2c000004110512027b8400000a7d2d000004110512037be800000a7d2e000004110512037be900000a7d2f000004110512037bea00000a7d30000004110512037beb00000a7d3100000411051104280f00000a2d07722c0a00702b0711046fec00000a007d2a00000411056fb900000a0000120728db00000a130611063a01ffffffde0f1207fe160d00001b6f2300000a00dc00067e460000042d1314fe063500000673ed00000a80460000042b007e460000046fee00000a0006281f00000600027b34000004062819000006002a411c00000200000037000000060100003d0100000f00000000000000133003001a000000040000110028030000060a02725f11007006280a00000a2826000006002a00001b30040064010000220000110073b300000a0a282200000603281d000006722e0a0070280a00000a289700000a289900000a0b0728210000060ade120714fe01130511052d07076f2300000a00dc0000066fa900000a13062b4e120628aa00000a0c0028d700000a087b290000046fd800000a0d09280f00000a2c0d096f0200002b280f00000a2b011600130511052d167293110070087b29000004280a00000a730600000a7a00120628ac00000a130511052da5de0f1206fe160900001b6f2300000a00dc000228280000060002037d3400000402067d41000004020222000000002513077d3800000411077d3700000402177d3a00000400027b410000046fa900000a13062b2b120628aa00000a0c000228d700000a087b290000046fd800000a282a00000613041104166f6100000a0000120628ac00000a130511052dc8de0f1206fe160900001b6f2300000a00dc000272c1110070027b3400000472d3110070289c00000a2826000006002a0128000002002700093000120000000002004c005fab000f000000000200fb003c37010f000000001b3005007a0200002300001100027b3b0000042c08027b3e0000042b011600130811082d0b72a8120070730600000a7a73ef00000a0a00027b410000046fa900000a13093831010000120928aa00000a0b0028d700000a077b290000046fd800000a0c08280f00000a130811082d167210130070077b29000004280a00000a730600000a7a086f0200002b0d027b330000046f6500000a16fe01130811082d0538d5000000027b3300000409166f6900000a130811082d1b7232130070077b290000047270130070289c00000a730600000a7a286600000a096f6700000a6f6800000a16fe01130811082d05388900000000097b7000000a130a16130b2b6c110a110b9a130411047bf000000a280f00000a2c101104166ff100000a16fe0216fe012b011700130811082d390011047bf000000a7bf200000a7b2b00000a7b2c00000a130506110512066ff300000a2606110511061104166ff100000ad66ff400000a0000110b1758130b110b110a8e69fe04130811082d8600120928ac00000a130811083abffeffffde0f1209fe160900001b6f2300000a00dc0000066ff500000a130c2b7f120c28f600000a1307027b330000046ff700000a120728f800000a15176ff900000a120728fa00000afe0416fe01130811082d4b1b8d01000001130d110d1672ce130070a2110d17120728fa00000a8c43000001a2110d1872fc130070a2110d19120728f800000aa2110d1a7200140070a2110d287600000a730600000a7a120c28fb00000a130811083a71ffffffde0f120cfe161000001b6f2300000a00dc00027b430000046fc600000a0002177d3c00000402167d3a00000402167d3f000004027224140070027b340000047238140070289c00000a2826000006002a000041340000020000003800000048010000800100000f000000000000000200000099010000930000002c0200000f000000000000001b300800850400002400001100160a386504000000027b41000004027b3f0000046ffc00000a0b28d700000a077b290000046fd800000a6f0200002b0c7e12000004027b33000004146f2500000a74260000010d027b330000046f6500000a130411042d50027b3300000408166f6900000a2c3d027b33000004097b2b00000a7b6a00000a7b6b00000a6f6c00000a2c20097b2b00000a7b6d00000a2c0f097b6e00000a2200000000fe032b0117002b0116002b011700130e110e2d2e0002282800000600027240140070027b3f0000048c430000017272140070288500000a28260000060038a50300002200000000027b37000004220000000028fd00000a1305027b35000004287d00000a027b38000004284800000a286200000a1105072824000006284a00000a286200000a130673cc00000a1307110622cdcccc3d110728ce00000a00141308007e0d000004027b330000041b8d01000001130f110f1608a2110f1711068c09000001a2110f181105072825000006285500000a8c0a000001a2110f19168c1d000001a2110f1a286f00000a16fe018c1d000001a2110f6f2500000a2600ddf80000000073cc00000a1309110622cdcccc3d110928ce00000a000011096fd000000a131038ae000000121028d100000a130a110a280f00000a2c271107110a6ffe00000a2d1c110a6f1300000a28d600000a077b29000004282d00000a16fe012b011700130e110e2d6d00110a6f0700002b130b110b280f00000a2c0c110b6fd500000a14fe012b011700130e110e2d4500027b430000047336000006130c110c110a7d47000004110c110b6fd500000a7d48000004110c110b6fd500000a7bff00000a7d49000004110c6f0001000a00110a13080000121028db00000a130e110e3a42ffffffde0f1210fe160d00001b6f2300000a00dc0000dc001108280f00000a130e110e2d0b7223150070730600000a7a02257b3f00000417587d3f000004027b42000004027b3f00000417596f6000000a166f6100000a0011042d12286600000a086f6700000a6f6800000a2b011700130e110e2d15027b33000004087b7000000a1615176f7100000a001104130e110e2d7900027b330000047e0e000004027b33000004146f2500000aa5210000016f7200000a00097b2b00000a7b6d00000a16fe01130e110e2d41092200000000097b6e00000a7e0f000004027b33000004178d01000001130f110f1609a2110f6f2500000aa5210000017e7300000a5a59287400000a7d6e00000a0011086f0900002b130d110d280f00000a2c0d077b2a00000428ab00000a2b011700130e110e2d0e110d077b2a0000046f0101000a007e0c000004027b33000004287500000a8c210000016f1f00000a00021d8d01000001130f110f16729b150070a2110f17027b3f0000048c43000001a2110f187216070070a2110f19027b410000046fa800000a8c43000001a2110f1a72a9150070a2110f1b027b34000004a2110f1c72c5150070a2110f287600000a282600000600027b3f000004027b410000046fa800000afe0116fe01130e110e2d0702282800000600000617580a061a2f08027b3c0000042b011600130e110e3a84fbffff2a000000011c00000200c201c587020f0000000002003e0163a101f80000000013300400360200002500001100160a38ca01000000027b43000004027b430000046f0201000a17596f0301000a0b077b47000004280f00000a16fe01130711073a5701000000077b470000046f0700002b0c08280f00000a2c29086fd500000a077b48000004331b086fd500000a7bff00000a077b49000004280401000a16fe012b011600130711072d0b7205160070730600000a7a077b470000046f0a00002b0d09280f00000a2c18096f0501000a6f0601000a6f0701000a16fe0216fe012b011700130711072d0b7273160070730600000a7a077b470000046f0b00002b13041104280f00000a2c0c11046f0801000a16fe012b011700130711072d0b72fc160070730600000a7a077b470000046f0c00002b13051105280f00000a16fe01130711072d3e1613062b23110511066f0901000a16fe01130711072d0b7270170070730600000a7a110617581306110611057b0a01000a6f0b01000afe04130711072dc7086f0c01000a00086f0d01000a130711072d0b72e4170070730600000a7a28d700000a077b470000046f1300000a6f0e01000a00002b24280f01000a077b490000046f1001000a14fe01130711072d0b7250180070730600000a7a027b43000004027b430000046f0201000a17596f1101000a00000617580a061e2f10027b430000046f0201000a16fe022b011600130711073a17feffff027205190070027b430000046f0201000a8c430000017213190070288500000a282600000600027b430000046f0201000a16fe0116fe01130711072d0702167d3d0000042a00001b3005001f050000260000110002037d3300000404130811082d3900027b3c0000042d0b027b3d00000416fe012b011600130811082d1500022828000006000272a21900702826000006000017130738d30400000028020000060a0614fe01130811083a8f01000000067b1300000417fe0116fe01130811083a0c01000000067b14000004178d5300000113091109161f7c9d11096f1201000a0b078e691afe01130811082d0b727b1a007073a200000a7a0207169a281d0000067d34000004198d210000010c160d2b57070917589a20a7000000281301000a08098f21000001281401000a2c2308099828a600000a2d190809982200000040320f080998220000a042fe0216fe012b011600130811082d0b72db1a007073a200000a7a0917580d0919fe04130811082d9f022828000006000208169808179808189873c300000a7d3600000402177d3900000402027b330000046f5200000a6f3c00000a287d00000a288100000a7d3500000402021725130a7d3e000004110a7d3b00000402282c00000600002b6c067b1300000418fe0116fe01130811082d0f02067b14000004282f000006002b4b067b1300000419fe0116fe01130811082d1700022828000006000272231b0070282600000600002b22067b130000041afe0116fe01130811082d10000228280000060002177d3d00000400001f1b287900000a16fe01130811082d1c000228280000060002729f1b0070282600000600171307dd04030000027b3c00000416fe01130811082d100002283100000600171307dde5020000027b3d00000416fe01130811082d100002283200000600171307ddc6020000027b390000042d08027b3a0000042b011700130811082d08171307dda6020000027b3a0000042c08027b3b0000042b011700130811082d2d0002021204027b3a000004282b0000067d3e000004027b3e00000416fe01130811082d080211047d3500000400027b3a0000042c17201f010000287900000a2c0b027b3e00000416fe012b011700130811082d2d0002027b3b00000416fe017d3b00000402027b3b0000042d0772dd1b00702b0572271c00700028260000060000027b3900000416fe01130811082d4b002020010000287900000a16fe01130811082d31000002282e0000060000de231305000272ae1c007011056f1700000a6f1800000a280a00000a28260000060000de00000000387b010000001f71287900000a16fe01130811082d1202257b370000042200007041597d370000041f65287900000a16fe01130811082d1202257b370000042200007041587d370000042018010000287900000a16fe01130811082d1202257b38000004220000003f587d380000042019010000287900000a16fe01130811082d1202257b38000004220000003f597d380000042200000000027b37000004220000000028fd00000a1306160d389c00000000027b42000004096f6000000a027b3e0000046f6100000a00027b42000004096f6000000a6f3b00000a027b35000004287d00000a027b38000004284800000a286200000a1106027b41000004096ffc00000a2824000006284a00000a286200000a6f6300000a00027b42000004096f6000000a6f3b00000a1106027b41000004096ffc00000a2825000006285500000a6f6400000a00000917580d09027b410000046fa800000afe04130811083a4dffffff2020010000287900000a16fe01130811082d07022830000006000000de2f130500022828000006000272ca1c007011056f1700000a6f1800000a72f21c0070289c00000a28260000060000de00001713072b000011072a004134000000000000320300000b0000003d030000230000001a00000100000000480000009e040000e60400002f0000001a000001033004004e0000000000000002220000a0412200004041220000a04173c300000a7d360000040273cc00000a7d400000040273b300000a7d4100000402738600000a7d4200000402731501000a7d4300000402281e00000a002a1e02281e00000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c0000008c110000237e0000f81100004413000023537472696e6773000000003c250000601d0000235553009c420000100000002347554944000000ac4200007c08000023426c6f620000000000000002000001579da229090a000000fa25330016000001000000770000000c0000004a0000003600000025000000150100000200000005000000010000002600000001000000010000000100000013000000010000000100000007000000030000000c00000000000a000100000000000600c100ba000a00eb00df0006000b01f9000e0046012b011200940100000600cd01f9000600fd01f9001200a10200000a00b002df000a00c402df000600e4022b010a00eb02df000a00ff02df000600ec03e2031200f90400001200010500000600920573050600d905b9050600f905b90506003b062a0606005306ba0006008206ba0006009c06ba000a00c100df000a00db06df0006000907ba0006003707ba0006003c07ba0006006907ba0006007107f90006007807f90012009407000006009d07ba002f00ad0700000600db07ba000600e707f9001200f90700009700020800000a000b08df000a002508df0012003b0800009b006608000012008108000012009808000012009d0800001200a50800001200b40800001200d90800000600fd08ba000a003009df000a00b909df000a00c509df000a00ed09df000a00b904df000a006a0adf000a00880adf000a00bb0aa50a12003b0b00001200460b000017006b0b000012008c0b00001200d50b00002300fb0b000012002f0c00000a00450cdf000a004f0cdf0006005d0cba001600810cdf000a00a90cdf001200bc0c00000a00c70cdf000a00d20cdf000600fe0cba0006000f0de2030600240de20306002e0de20306004c0dba000600620de20306006f0de2030600820de2030600b70de2030e00dd0de2030600fc0dba000600410e350e0600530ee2030600600ee20306009a0eba005f01a60e00000600e70eba000600f30eba001200090f00006f01140f00000a00200fdf001a00610fdf001a00690fdf001a00740fdf000a00b90fdf001200d10f00001e00f00f00001200041000000a002110df000600c410b9050600df10ba0006001a11b90506002911ba0006008411ba001200ac0300000600d1112b01b301ad070000060012122b0112002112000012006912000012007f120000120098120000cb01a31200001200d11200000600fc12e71206001d13e71206002a13ba0000000000010000000000010001008101100021002d000500010001000501100040000000050013000b00010110004c002d00090015000c00800110005e002d00050026001600800110006a002d00050026001800010110007b002d00050029001c00810110008a002d00050032001d000001100098002d0005003300220003011000aa000000050047003600000000007f10000005004a00370013010000e91000009d014b003700538018010a0016001e01130013002601130031004e0116001600ae0133001300b50136001300bb0113001100c6013a003300d7013e003300dd013e003300ed013e003300f5013e0033000802420033000e02420033001b02420033002b02420033003702420033004002420003006602130003006b0233000600b50136000300bb011300010076025c0001007f025c0001008a025c00210097025f000100a70263000100b80267000100bf0267000100cf026b000100d80213000100de0213002100f6026f00010008037700010018037b0001002303830001002903830031008303b10011008803b4001100910333000600a50333000600ac0333000600b10383000600b30383000600b50383000600b70383000600ba0383000600bd0383000600c00383005680c30313000100fe03360001009103330001000404670001000b04670001001004830001001404830001001b045c00010025045c00010030045c00010037045c00010040045c00010048045c000100de02130021005004f30001005a04fb00210062046f0021006904030101006e047700010077040b01110091118f060300a10263000300fd043701030007053b01130106113e06502000000000960057011e000100f4200000000093005f012400030054210000000096006b0129000300a821000000009600780129000300bf210000000096009b012d000300dc210000000096004a022d000400f02200000000960054024600050054230000000093005c024a0005009423000000009600610250000600b42400000000911830074600090024260000000086187002580009002c260000000086002f03580009000827000000008100360386000900e0270000000081003e038b000a00502a00000000810044038f000a00dc2c000000008100500358000b00b42f0000000081005a0395000b001c3000000000860062039a000c006433000000008100670358000e00a9330000000081006e0358000e00bf33000000008618700258000e00f0330000000093007803a0000e0028340000000093007e03a60010005c35000000009300960346001200ac350000000093009c03b80012003836000000009300a003c30014001c3800000000911830074600150028380000000086187002580015003c38000000009600c903c3001500d838000000009100d203cd0016000039000000009600d903d20017000c3b000000009600f303dc001800483c000000009600f903e8001a00d83d0000000093087f0429001b00003e0000000093008a0429001b00503e00000000910092040f011b007c3e0000000091009b0416011c00ac3e000000008100ae0195001d00f83e000000008100a40458001e00903f0000000083002f0358001e00dc3f000000008300b10458001e001c40000000008100b9041d011e00e841000000008100be0424011f000043000000008100c20458002100c047000000008100c704580021007049000000008100a003580021009849000000008100d70495002100304b000000008100dc0458002200ec4d000000008100e704580022009c52000000008100ed0458002200e05400000000830062032c012200405a0000000086187002580024009c470000000091006a11870624009a5a000000008618700258002600000001000a05000002000f05000001001405000001001405000001001405000001001405000002001605000003001c05000001001605000001001f05000001002505000001001605000002001c05000001002c05000002003505000001003d05000002004405000001004605000002005a04000001005205000001009103000001005905000001005a04000001005b05000002005a04000001005b05000001006205000001006205000001006405000001006605020001006d05000002009f0500000100a40500000100aa0500000200b105000001008011000002008211890070025800910070023f01990070025800a100430644010c0049065201a900700295000c006d065601a10075065c010c007a066e01b10089068001310090069001390090069801b900700295000c0096035800c100b306b601c1009006bc012900bf063600c100cd06bc01c900e506c801c100f406cd016100700295006100fc06d301d1001307de01d1002407e3010c0070025800d9004e07ee01d9006007f501d9008a07fd01d9008a070d020900700258003100a4071b021400b80728021c00c6076e011c00d2078b001901b10458001400960358002101f2074702390117084e0241012f088b00490145088b0049014c088b0049015a088b0031017108520251017a083300b1009006570259018e084e0261018e084e0269018e084e027101ad084e027901b8084e027901d0084e028101de085d028101eb088b003100f4086a02890105096f02c1000d09e301b1001609e301b1002709740261003a097902910148097f0291015509840224007002580061006209d30141006f0996022c00960358002400b80728023400c6076e0191017d09b1022c00930956013400d2078b0049009709b8024900a309bd024900af09b8025100a309c5029901c009ea0269007002f102a1017002f8026900cb0900036100d5090703a901f80915039101070a1b03c9003a0979029101110a23035100230a29035100a309300391012b0a390391013d0a7f0291014c0a2303a9015b0a3f03b101770a5201c101910a4c03c101cd0a5303c101e30a5a031400930956011400490652011400f60a5f036100ff0a5a034900090b65039101150b23039101220b390329002f0b8b00d101de0889034100510b8f03d1015e0b950329007b0b9c035101930ba503e9019c0b83004901ac0baa035101b80b5c003101c80b8300f101e30b4e024100070caf032900130cb5034901240cc0030102340c830009024b0cc5031102540ccb03b1008906cf032102870ce7032102960ce7032102b10cec033102de08f303910197097f0239027002f9034900cb0cb80241027002f9034102d80c01043902e00c0a044900e90c65034900440583000902f80c10044900fc0c8300b100890615041400700258002c00700258001100700258004902f80c10044902030d2f044902090d340449024b0c34042c00b80728023c00c6076e0149000d0d830049024b0cc5033c00d2078b0051027002580051021c0d640459023c0d72046902510d79046902590d7f047102670d80017902740d840479028d0d8b04b100960d5201b100a10d9204b100890698047902ab0d9f047902b20da4048902700295007902c30daa04b100ca0d9f04910270029500b100f20dc0049902010ec504b100110ee3010901160ecd0009011c0ecd004400490652014400b80728024c00c6076e01b100270e9f044c00d2078b00a1024a0ef504a9027002fb04a902f3039500a902f3033f01a902f303c0037100960d1b05440070025800b1027002fb04b1026d0ee301b100cd065702b102780e5201b102820e1f0544009309560171008d0e1b05b902b40e3a057102670d98045902ab0d9f045902c20e41057102cb0ec300540070025005d102f90e5605b100040f6e0549007002750551007002f8024901270f86055c009603580049002f0fb8026100380f8b00f102d80cc805f9028c0f7f026400960358006400700258004900960f1f054100a40fef0509037002f9036400b80728026c00c6076e014100c00f8b00090327090406c9006209d3011103da0f10061903f60f15062103de081b0621030e1021066400930956016400490652016c00d2078b00a10118102706c1012e10330629034110c00329034e10c00329035d105a0309036f107f02090377107f0231037002580041033c11420629034c113f0129035e114c060901b811980651004405830051000d0d83005100fc0c83005100c21183005903c411e3017400700250054400cc11ab067c0070025800f901de11f506f901e811fa062901f211ff067c00fd1104077c0009120d077c00b80715078400c607290701012b1235078c0038126e017903401243078c004b124a078400d2078b004400f60a5f0351005512810764002709890779005b123b015c00930956015903611295005c00490652015c00f60a5f038100cd06c10781032b12350779037312cf07940049065201890389128b0091038912ed079103b212f2079c00490652011103ba1258001103c9128b002103f4068f00a103de080308a103da0f09085c00d8123f01b100e1122408a90308132b0809013a1331085c0070025800080004000e000800c800c8002e00130053082e001b005c0863011b073906a0061b073906c1081b0739060100400000000c006101730186018c01a001ab01c401e70115023a026302ce026e03d503e2031c043a0446045e046904af04ca04e104050523057c05810593059805ac05d9055306b606d2064f078f0710083e08090001000000f20433010200220003004b01210232028902a102a8023e04d204d9044805a505e805fc05a306ed0621073b07d907fb07c04200004a00048000000000000000000000000000000000170600000400000000000000000000000100b100000000000000000000000000000000000000c800000000000400000000000000000000000100ba000000000000000000000000000000000000008301000000000000000000000000000000000000630c000000000000000000000000000000000000470f000000000000000000000000000000000000e10f00000000030002000a0009000c000b002d00d9017f0091029f000f032d000f032d00460383016905a9010a062d002d06a9019d06a901c907a901e107a901e70700000000003c4d6f64756c653e0056616c6865696d447261674275696c6456362e646c6c00447261674275696c6456360056616c6865696d536f6c6f546f6f6c6b697400526571756573744461746100447261674275696c6444726976657256360044726167526f77506c616e00426c75657072696e744361707475726500426c75657072696e74456e74727900426c75657072696e744461746100426c75657072696e74576f726b73686f7000506c61636564006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f75720053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c61677300456e61626c6564004d6f64650053797374656d2e436f6c6c656374696f6e732e47656e65726963005175657565603100726571756573747300526571756573740054616b6552657175657374005361766543617074757265640053617665644e616d657300617373656d626c795f76616c6865696d00506c6179657200436f6e666967757265426c75657072696e7400537461747573004f776e65720047656e65726174696f6e00647269766572004669656c64496e666f0047686f737400506c6163656d656e745374617475730050726573736564004c617374557365004d6574686f64496e666f00506c616365004275696c645374616d696e61004275696c644475726162696c6974790055706461746547686f73740053656c65637465640052696768744974656d00436f6e6669677572650044697361626c65004f776e73005469636b00436f64650054657874002e63746f72006472616767696e6700636f6d6d697474696e670072656c65617365477561726400626c75657072696e740050696563650073656c656374656400566563746f723300616e63686f720073746570005175617465726e696f6e00726f746174696f6e00636f756e7400696e646578004c69737460310047616d654f626a656374007072657669657773004d6174657269616c00707265766965774d6174657269616c00736e6170506f696e7473007370616e58007370616e5a0043616e63656c00416c6c6f77656400426567696e0053686f775072657669657700506c6163654e6578740053746f70526f77005374657000557064617465004f6e44657374726f7900436f756e74005370616e006761746500736e617073686f74006e616d6500436c65617200536574005361766500507265666162005369676e00580059005a00515800515900515a005157004c696d697400536166654e616d650046696e6974650056616c69646174650053797374656d2e494f0053747265616d0057726974650052656164006f776e6572006f726967696e0073697a6500796177006865696768740073656c656374696e670070726576696577696e67006c6f636b6564006275696c64696e6700756e646f696e67006861766541696d0073656c656374696f6e00656e7472696573006d657368657300756e646f006d6174657269616c006f75746c696e65006765745f466f6c64657200436174616c6f6700506f736974696f6e00526f746174696f6e00436c6561725072657669657700446973706f7365004d6573680041696d005363616e0043617074757265536e617073686f74004c6f616400426567696e4275696c64004275696c6400556e646f00466f6c646572005a444f005a646f005a444f494400496400636f64650074657874007000696e7075740064740067686f737400726561736f6e0064697374616e63650073706163696e6700706f696e7473007800636170747572654e616d6500666f6c64657200660073747265616d0065007300736f7572636500706f696e740053797374656d2e52756e74696d652e496e7465726f705365727669636573004f757441747472696275746500736e61700076616c756500706c6179657200616c6c6f7765640053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d447261674275696c6456360053797374656d2e546872656164696e67004d6f6e69746f7200456e746572006765745f436f756e7400496e76616c69644f7065726174696f6e457863657074696f6e00456e71756575650045786974004465717565756500537472696e6700436f6e636174006f705f457175616c697479004d697373696e674d656d626572457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006f705f496e657175616c69747900436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e7400457863657074696f6e0047657442617365457863657074696f6e006765745f4d657373616765002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744669656c6400426f6f6c65616e0042696e64657200506172616d657465724d6f646966696572004765744d6574686f640048756d616e6f69640053696e676c650053657456616c756500456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e74004d6f76654e6578740049446973706f7361626c65004d6574686f644261736500496e766f6b65004974656d44726f70004974656d44617461004170706c69636174696f6e006765745f6973466f6375736564004265686176696f7572006765745f656e61626c6564004368617261637465720049734465616400497354656c65706f7274696e6700496e506c6163654d6f64650053686172656444617461006d5f736861726564006d5f6e616d6500496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c65004d696e696d61700049734f70656e00487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c0043686174006765745f696e7374616e636500486173466f6375730047657456616c756500436f6e7665727400546f496e743332006765745f6e616d6500546f4c6f776572496e76617269616e7400436f6e7461696e73005472616e73666f726d006765745f7472616e73666f726d006765745f706f736974696f6e006765745f726f746174696f6e00476574436f6d706f6e656e7400476574536e6170506f696e747300496e76657273655472616e73666f726d506f696e7400416464006765745f666f7277617264006f705f4d756c7469706c79006765745f7269676874005368616465720046696e6400436f6c6f72007365745f636f6c6f7200476574436f6d706f6e656e7473496e4368696c6472656e004d65736846696c746572006765745f7368617265644d65736800536574506172656e74007365745f6c6f63616c506f736974696f6e00496e7665727365007365745f6c6f63616c526f746174696f6e006765745f6c6f7373795363616c65007365745f6c6f63616c5363616c65007365745f7368617265644d657368004d65736852656e6465726572006765745f7375624d657368436f756e740052656e6465726572007365745f7368617265644d6174657269616c7300556e697479456e67696e652e52656e646572696e6700536861646f7743617374696e674d6f6465007365745f736861646f7743617374696e674d6f6465007365745f72656365697665536861646f7773006765745f4974656d00536574416374697665006f705f4164646974696f6e007365745f706f736974696f6e007365745f726f746174696f6e004e6f436f73744368656174005a6f6e6553797374656d00476c6f62616c4b65797300467265654275696c644b657900476574476c6f62616c4b657900526571756972656d656e744d6f64650048617665526571756972656d656e74730041747461636b006d5f61747461636b006d5f61747461636b5374616d696e6100486176655374616d696e61006d5f7573654475726162696c697479006d5f6475726162696c69747900506c6179657250726f66696c65006765745f735f6279706173734368656174436865636b7300526571756972656d656e74006d5f7265736f757263657300436f6e73756d655265736f7572636573005573655374616d696e610047616d65006d5f6475726162696c69747952617465004d61746866004d61780054696d65006765745f74696d6500496e74333200556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e004765744d6f757365427574746f6e446f776e004b6579436f6465004765744b6579446f776e0047616d6543616d65726100526179006765745f757000506c616e65005261796361737400476574506f696e74006f705f5375627472616374696f6e00416273007a004d61746800466c6f6f72004d696e0079004d656d6f727953747265616d00546f4172726179004469726563746f7279004469726563746f7279496e666f004372656174654469726563746f72790047756964004e65774775696400546f537472696e67005061746800436f6d62696e650046696c65005772697465416c6c42797465730046696c6553747265616d004f70656e52656164006765745f4c656e67746800537562737472696e6700457869737473004d6f766500494f457863657074696f6e0044656c6574650049734e756c6c4f725768697465537061636500496e76616c696444617461457863657074696f6e006765745f436861727300436861720049734c65747465724f724469676974005472696d0049734e614e004973496e66696e6974790049734e756c6c4f72456d7074790053797374656d2e5465787400456e636f64696e67006765745f555446380042696e6172795772697465720042696e6172795265616465720052656164537472696e670052656164496e743332005265616453696e676c65006765745f506f736974696f6e00456e7669726f6e6d656e74005370656369616c466f6c64657200476574466f6c646572506174680047657446696c65730047657446696c654e616d65576974686f7574457874656e73696f6e00436f6e766572746572603200417272617900436f6e76657274416c6c004a6f696e004d657373616765487564004d6573736167655479706500537072697465004d657373616765006765745f7a65726f006765745f61637469766553656c6600556e697479456e67696e652e506879736963734d6f64756c650050687973696373005261796361737448697400517565727954726967676572496e746572616374696f6e006765745f706f696e74006765745f6d61676e697475646500476574416c6c506965636573496e52616469757300426f756e6473004973506c616365644279506c61796572005a4e657456696577004765745a444f00617373656d626c795f7574696c73005574696c73004765745072656661624e616d65005a4e65745363656e6500476574507265666162006765745f6379616e004c696e6552656e6465726572007365745f7368617265644d6174657269616c007365745f656e645769647468007365745f73746172745769647468007365745f757365576f726c645370616365006765745f6d696e006765745f6d6178003c50726976617465496d706c656d656e746174696f6e44657461696c733e7b34324245333843432d384331332d343630342d424643312d3630443343413846333138437d00436f6d70696c657247656e6572617465644174747269627574650056616c756554797065005f5f5374617469634172726179496e69745479706553697a653d36340024246d6574686f643078363030303032612d310052756e74696d6548656c706572730052756e74696d654669656c6448616e646c6500496e697469616c697a654172726179007365745f706f736974696f6e436f756e7400536574506f736974696f6e003c43617074757265536e617073686f743e625f5f310061006200436f6d70617269736f6e6031004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c65676174653200436f6d70617265546f0077004765745465787400536f72740044696374696f6e6172796032006d5f7265734974656d00476574416d6f756e74006d5f6974656d446174610054727947657456616c7565007365745f4974656d004b657956616c756550616972603200496e76656e746f727900476574496e76656e746f7279006765745f4b657900436f756e744974656d73006765745f56616c75650045756c6572006d5f756964005365745465787400436f6e7461696e657200476574416c6c4974656d73004974656d5374616e6400486176654174746163686d656e740041726d6f725374616e640041726d6f725374616e64536c6f74006d5f736c6f747300436c61696d4f776e6572736869700049734f776e6572005a444f4d616e0052656d6f766541740053706c69740053797374656d2e476c6f62616c697a6174696f6e0043756c74757265496e666f006765745f496e76617269616e7443756c74757265004e756d6265725374796c65730049466f726d617450726f76696465720054727950617273650000004b5700610069007400200066006f0072002000740068006500200071007500650075006500640020006200750069006c00640069006e006700200063006f006d006d0061006e0064002e000080bf4200750069006c00640069006e006700200063006f006d006d0061006e00640020007100750065007500650064002e002000520065007400750072006e00200074006f002000560061006c006800650069006d0020007700690074006800200079006f00750072002000680061006d006d0065007200200061006e006400200063006c006f00730065002000670061006d00650020006d0065006e0075007300200074006f002000700072006f0063006500730073002000690074002e00006945006e00610062006c006500200042006c00750065007000720069006e00740020006d006f0064006500200061006e00640020006300610070007400750072006500200061002000730065006c0065006300740069006f006e002000660069007200730074002e00002353006100760065006400200062006c00750065007000720069006e0074003a0020000080d942006c00750065007000720069006e007400200074006f006f006c0073002000720065006100640079002e0020005500730065002000430061007000740075007200650020006f00720020004c006f0061006400200069006e00200074006800650020004200750069006c00640069006e0067002000770069006e0064006f0077002c0020007400680065006e002000720065007400750072006e00200074006f0020007400680065002000670061006d00650020007700690074006800200079006f00750072002000680061006d006d00650072002e00005544007200610067002d006200750069006c006400200070006c006100630065006d0065006e00740020006d006500740061006400610074006100200075006e0061007600610069006c00610062006c0065002e000180bb480061006d006d00650072003a0020004c006500660074002d0063006c00690063006b00200061006e0064002000640072006100670020007000720065007600690065007700730020006100200072006f0077003b002000720065006c00650061007300650020006c00650066007400200063006c00690063006b00200074006f0020006200750069006c0064002e00200052006900670068007400200063006c00690063006b002000630061006e00630065006c0073002e00012b53006f006c006f0054006f006f006c006b00690074005f0044007200610067004200750069006c0064000029440072006100670020006200750069006c0064002000730074006f0070007000650064003a00200000216d005f0070006c006100630065006d0065006e007400470068006f007300740000236d005f0070006c006100630065006d0065006e00740053007400610074007500730000256d005f0070006c006100630065005000720065007300730065006400540069006d00650000236d005f006c0061007300740054006f006f006c00550073006500540069006d006500001550006c0061006300650050006900650063006500001f4700650074004200750069006c0064005300740061006d0069006e006100002547006500740050006c006100630065004400750072006100620069006c00690074007900002955007000640061007400650050006c006100630065006d0065006e007400470068006f00730074000021470065007400530065006c0065006300740065006400500069006500630065000019470065007400520069006700680074004900740065006d00001924006900740065006d005f00680061006d006d0065007200000b66006c006f006f0072000009770061006c006c0000096200650061006d00000972006f006f006600000532003600000534003500001f53007000720069007400650073002f00440065006600610075006c007400003750007200650076006900650077002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e00001752006f007700200070007200650076006900650077000019500072006500760069006500770020006d00650073006800004b6d0069007300730069006e00670020006d006100740065007200690061006c00730020006f00720020006300720061006600740069006e0067002000730074006100740069006f006e00007d6e006f007400200065006e006f0075006700680020007300740061006d0069006e0061002000280065006e00610062006c006500200055006e006c0069006d00690074006500640020007300740061006d0069006e00610020006f0072002000460072006500650020004300720061006600740069006e00670029000027680061006d006d006500720020006e006500650064007300200072006500700061006900720000174100750074006f002d006200750069006c007400200001032f00001120007000690065006300650073002e00002552006f0077002000730074006f0070007000650064002000610066007400650072002000001320007000690065006300650073003a00200000032e00005152006f0077002000630061006e00630065006c006c00650064003a00200063006f006e00740072006f006c00730020006f007200200074006f006f006c0020006300680061006e006700650064002e00005952006f0077002000630061006e00630065006c006c00650064002e00200041006c0072006500610064007900200070006c00610063006500640020007000690065006300650073002000720065006d00610069006e002e00001350007200650076006900650077003a00200000810920007000690065006300650073002e002000520065006c00650061007300650020006c00650066007400200063006c00690063006b00200074006f00200070006c006100630065003b00200072006900670068007400200063006c00690063006b002000630061006e00630065006c0073002e0020004100750074006f002d006200750069006c0064007300200061007400200074006800650020007000720065007600690065007700200070006f0073006900740069006f006e0073003b0020006e006f002000630068006100730069006e00670020006f00720020006c0069006e00650020006f00660020007300690067006800740020006e00650065006400650064002e000180dd4e006f002000630061007000740075007200650064002000730065006c0065006300740069006f006e002000690073002000720065006100640079002e00200043006c00690063006b00200043006100700074007500720065002c002000720065007400750072006e00200074006f0020007400680065002000670061006d00650020006f006e00630065002c00200061006e00640020007700610069007400200066006f0072002000740068006500200063006100700074007500720065006400200070006900650063006500200063006f0075006e0074002e0000034e0000092e0074006d00700000052000280000032900000100092e00760062007000007954006f006f0020006d0061006e007900200062006c00750065007000720069006e0074007300200077006900740068002000740068006900730020006e0061006d0065002e0020004300610070007400750072006500200077006900740068002000610020006e006500770020006e0061006d0065002e000080b755007300650020006100200062006c00750065007000720069006e00740020006e0061006d00650020006f006600200031002d003400380020006c006500740074006500720073002c0020006e0075006d0062006500720073002c0020007300700061006300650073002c002000680079007000680065006e0073002c00200075006e00640065007200730063006f0072006500730020006f007200200070006100720065006e007400680065007300650073002e00015b42006c00750065007000720069006e00740020006e0061006d006500200063006f006e007400610069006e007300200061006e00200069006e00760061006c006900640020006300680061007200610063007400650072002e00004942006c00750065007000720069006e00740020006d00750073007400200063006f006e007400610069006e00200031002d0035003100320020007000690065006300650073002e00012f49006e00760061006c0069006400200062006c00750065007000720069006e007400200074006500780074002e00003d49006e00760061006c0069006400200062006c00750065007000720069006e007400200063006f006f007200640069006e0061007400650073002e00003d42006c00750065007000720069006e0074002000650078006300650065006400730020003100300030006d00200062006f0075006e00640073002e00003749006e00760061006c0069006400200062006c00750065007000720069006e007400200072006f0074006100740069006f006e002e00000b53005400420050003100003342006c00750065007000720069006e0074002000660069006c006500200074006f006f0020006c0061007200670065002e00003b55006e0073007500700070006f007200740065006400200062006c00750065007000720069006e007400200066006f0072006d00610074002e00002949006e00760061006c0069006400200070006900650063006500200063006f0075006e0074002e00003555006e0065007800700065006300740065006400200062006c00750065007000720069006e007400200064006100740061002e000025560061006c006800650069006d0053006f006c006f0054006f006f006c006b0069007400001542006c00750065007000720069006e0074007300002f4e006f00200073006100760065006400200062006c00750065007000720069006e0074007300200079006500740000052c002000000b2a002e00760062007000003550007200650076006900650077002000730068006100640065007200200075006e0061007600610069006c00610062006c006500002342006c00750065007000720069006e00740020007000720065007600690065007700001d42006c00750065007000720069006e00740020006d006500730068000071530065006c0065006300740069006f006e0020006500780063006500650064007300200035003100320020007000690065006300650073002e0020005200650064007500630065002000740068006500200062006f0078002000640069006d0065006e00730069006f006e0073002e00003542006c00750065007000720069006e0074002000730065006c0065006300740069006f006e00200062006f0075006e0064007300001343006100700074007500720065006400200000192000700069006500630065007300200066006f00720020000080a72e002000530065006c0065006300740069006f006e002000690073002000660069007800650064002e00200043006c00690063006b0020005300610076006500200063006100700074007500720065006400200062006c00750065007000720069006e007400200069006e0020004200750069006c00640069006e006700200074006f006f006c0073002c0020006f0072002000700072006500730073002000460037002e000080bd4e006f00200070006c0061007900650072002d006200750069006c0074002000700069006500630065007300200069006e002000740068006500200062006f0078002e0020005300740061006e006400200069006e007300690064006500200074006800650020006200750069006c00640069006e006700200061007400200066006c006f006f00720020006c006500760065006c00200061006e00640020004300610070007400750072006500200061006700610069006e002e00015941002000730065006c00650063007400650064002000700069006500630065002000640069007300610070007000650061007200650064003b0020006300610070007400750072006500200061006700610069006e002e000033460069006c00650020007300610076006500640020007300750063006300650073007300660075006c006c0079003a002000002d4d0069007300730069006e00670020006200750069006c00640020007000720065006600610062003a0020000011500072006500760069006500770020000080d33a002000610069006d00200074006f00200070006f0073006900740069006f006e003b00200051002f004500200072006f007400610074006500200031003500200064006500670072006500650073003b00200050006100670065002000550070002f0044006f0077006e002000610064006a0075007300740020006800650069006700680074003b0020004600360020006c006f0063006b0073003b0020004600370020006200750069006c006400730020006c006f0063006b0065006400200070007200650076006900650077002e0000674c006f0063006b002000740068006500200070006c006100630065006d0065006e007400200070007200650076006900650077002000770069007400680020004600360020006200650066006f007200650020006200750069006c00640069006e0067002e0000214d0069007300730069006e00670020007000720065006600610062003a002000003d4d0069007300730069006e00670020006d006100740065007200690061006c0073002f00730074006100740069006f006e00200066006f0072002000005d2e00200045006e00610062006c0065002000460072006500650020004300720061006600740069006e00670020006f007200200073007500700070006c007900200072006500710075006900720065006d0065006e00740073002e00002d570068006f006c006500200062006c00750065007000720069006e00740020006e00650065006400730020000003200000232e0020004e006f007400680069006e006700200070006c0061006300650064002e0000134200750069006c00640069006e006700200000072e002e002e00003142006c00750065007000720069006e0074002000730074006f00700070006500640020006100660074006500720020000080af20007000690065006300650073003a0020006d006100740065007200690061006c0073002c002000730074006100740069006f006e002c0020007300740061006d0069006e00610020006f0072002000680061006d006d006500720020006400650070006c0065007400650064002e00200055006e0064006f002000630061006e002000720065006d006f0076006500200070006c00610063006500640020007000690065006300650073002e0000774e006100740069007600650020007000690065006300650020006300720065006100740069006f006e00200063006f0075006c00640020006e006f0074002000620065002000760065007200690066006900650064003b002000700061007300740065002000730074006f0070007000650064002e00000d4200750069006c0074002000001b20007000690065006300650073002000660072006f006d002000003f2e00200055006e0064006f002000610066006600650063007400730020006f006e006c007900200074006800690073002000700061007300740065002e00006d55006e0064006f0020006900640065006e00740069007400790020006300680061006e006700650064003b0020007200650066007500730069006e006700200074006f002000720065006d006f00760065002000740068006100740020006f0062006a006500630074002e0000808745006d0070007400790020007400680065002000700061007300740065006400200063006f006e007400610069006e006500720020006200650066006f0072006500200075006e0064006f0069006e0067002000690074002e00200052006500740072007900200055006e0064006f0020006100660074006500720077006100720064002e000073520065006d006f0076006500200064006900730070006c00610079006500640020006900740065006d0073002000660072006f006d002000740068006500200070006100730074006500640020007300740061006e00640020006200650066006f0072006500200055006e0064006f002e000073520065006d006f00760065002000650071007500690070006d0065006e0074002000660072006f006d00200074006800650020007000610073007400650064002000610072006d006f00720020007300740061006e00640020006200650066006f0072006500200055006e0064006f002e00006b43006f0075006c00640020006e006f00740020006f0077006e002000700061007300740065006400200070006900650063006500200066006f007200200055006e0064006f002e0020005200650074007200790020006100660074006500720077006100720064002e000080b34100200070006100730074006500640020007000690065006300650020006900730020006f00750074007300690064006500200074006800650020006c006f006100640065006400200061007200650061002e002000520065007400750072006e00200074006f00200074006800650020007000610073007400650064002000730074007200750063007400750072006500200061006e006400200072006500740072007900200055006e0064006f002e00000d55006e0064006f003a00200000808d200070006100730074006500640020007000690065006300650073002000720065006d00610069006e0069006e0067002e002000520065006d006f007600650064002000700069006500630065007300200064006f0020006e006f0074002000640072006f0070002f0072006500660075006e00640020006d006100740065007200690061006c0073002e000080d74200750069006c00640069006e00670020007000610075007300650064002f00630061006e00630065006c006c00650064003a00200063006f006e00740072006f006c00730020006f0072002000680061006d006d0065007200200075006e0061007600610069006c00610062006c0065002e00200041006c0072006500610064007900200070006c00610063006500640020007000690065006300650073002000720065006d00610069006e003b00200055006e0064006f00200069007300200061007600610069006c00610062006c0065002e00005f430061007000740075007200650020007200650071007500690072006500730020006e0061006d006500200061006e0064002000770069006400740068002c0020006800650069006700680074002c002000640065007000740068002e00004742006f0078002000640069006d0065006e00730069006f006e00730020006d00750073007400200062006500200032002d003800300020006d00650074007200650073002e00017b50007200650076006900650077002000630061006e00630065006c006c00650064002e00200053006100760065006400200062006c00750065007000720069006e0074007300200061006e006400200070006100730074006500640020007000690065006300650073002000720065006d00610069006e002e00003d42006c00750065007000720069006e00740020006f007000650072006100740069006f006e002000630061006e00630065006c006c00650064002e0000495000720065007600690065007700200075006e006c006f0063006b00650064003b002000610069006d00200074006f0020007200650070006f0073006900740069006f006e002e00008085500072006500760069006500770020006c006f0063006b00650064002e002000460037002000730061007600650073002000730065006c0065006300740069006f006e0020002f0020006200750069006c0064007300200062006c00750065007000720069006e0074003b00200046003600200075006e006c006f0063006b0073002e00001b530061007600650020006600610069006c00650064003a002000002742006c00750065007000720069006e0074002000730074006f0070007000650064003a002000006b20004500780069007300740069006e00670020007000690065006300650073002000720065006d00610069006e003b00200055006e0064006f002000720065007400610069006e007300200074006800650020006c006100730074002000700061007300740065002e00000000cc38be42138c0446bfc160d3ca8f318c0008b77a5c561934e0890306110d0434000000020608070615121101120c05000201080e040000120c0300000e05000101121502060e0306121503061210030612190306121d03000001050001021215070003021215020c0320000102060203061224030612210306112503061129070615122d01123103061235070615122d01112502060c042001020203200002052001011231042001010e05200202020c050002080c0c0a00020c15122d0111250202061c03061d050a0002010e15122d01121c0400010e0e0400020000040001020c0900010115122d01121c0b000201123915122d01121c0a000115122d01121c1239070615122d011221070615122d01121c070615122d011228030612310600011125121c0600011129121c062001123112310720020210112502062002021215020308000e0306123d030611410420010108060002011c10020615121101120c03200008052001011300040001011c0c0704120c0215121101120c0204200013000c070402120c15121101120c020500020e0e0e0507030e0e020307010e070002021219121907000202121d121d0a0703020215121101120c0a07030215121101120c020500010212610700020212611261030701020420001231050001011261053001001e00040a01121004200012690320000e06070312690202060001126d117107200212190e110d0f2005121d0e110d12791d126d1d117d072002121d0e110d0507011d126d052002011c1c0615122d0112310920001511808901130007151180890112310c0703123102151180890112310620021c1c1d1c0300000204061280a9050002020e0e0500001280c1060702128099020420011c1c040001081c042001020e0520001280c9042000112504200011290715122d011280c9040a0112210a20010115122d011280c90615122d0111250815118089011280c9062001112511250400001125070002112511250c0800021125112911251b070812310e15122d011280c91280c9021d1c0215118089011280c90600011280cd0e062001011280cd072004010c0c0c0c062001011180d1073001011d1e0002050a011280d50520001280d9072002011280c90205200101112506000111291129080002112911291129052001011129062001011280d9050a011280dd062001011d1235062001011180e504200101020520011300080800021125112511251a070b1280cd12311280d512311280dd1d12350808021d1280d5080500001280e90520001180ed062001021180ed0820020212211180f104061280f5042001020c05061d1280fd0a2004011d1280fd080808042001010c0500020c0c0c0300000c0500010e1d1c0c070708128099020202021d1c0407011d1c04000102080600010211811505000012811907200201112511250820020211811d100c05200111250c0400010c0c0600030e1c1c1c12070b020211811d0c1125020c0c02021181210400010d0d0500020808080307010807151180890111251707070c112511250c151180890111251511808901112502050703021c020420001d05080704128129021c020600011281310e0500001181350420010e0e060002010e1d050600011281410e0520020e08080600030e0e0e0e040001020e050002010e0e040001010e10070a0e128141080e0e020e1c0211813504200103080400010203070705030e020e080615122d01121c071511808901121c130708121c0c0c021511808901121c1d0c1d0c0805000012815109200301123912815102150708128155121c0c1511808901121c1d0c1d0c08020320000a0320000c16070715122d01121c1281590808121c15122d01121c020600010e1181610600021d0e0e0e0715128165020e0e052002011c18121002021d1e011d1e0015128165021e001e01040a020e0e0600020e0e1d0e062003010c0c0c040701112504070111290c2005011181710e081281750204070202020c0703123115118089011231020615122d0112281b070b1280cd12311280d512311280dd1d1235081231021d1280d50810000602112511251011817d0c081181810e0706123111817d1280c902021d1c0615122d0112210c00030111250c15122d0112210715118089011221052001021125050a01128189042000123d0500010e123105000012819105200112310e0500001180d1050a01128195052001011235040100000003061130090002011281691181a50620020108112533071315122d01122111818512211281890e123112311280cd128195112511251d11251d080815118089011221020c1d11251d1c07000208121c121c0806151281a901121c042001080c050a011281ad07151281a901121c0a200101151281a90113001b070815122d01121c1221112511291281ad121c02151180890112211a070815122d01121c128141121c12311231021511808901121c0c07151281b1020e0804061280950420010808040612809908200202130010130107200201130013010b2000151181b5021300130107151181b5020e080b2000151181b902130013010520001281bd07151181b9020e08062003080e0802042000130131070e151281b1020e08121c123112211280fd0e08151181b9020e08021511808901121c1d1280fd08151181b5020e081d1c07000311290c0c0c05200102130031071108121c1221128099021129112515122d011221122115122d011221122112818912281281ad021d1c151180890112210700020211411141050a011281c109200015122d011280990715122d01128099050a011281c5050a011281c90420010208080615122d011281cd0715122d011281cd0500001281d1062001123d11411307080812281281891281c11281c51281c908020620011d0e1d030500001281d50c0004020e1181d91281dd100c14070b120c1d0e1d0c0811251269112902021d03020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f77730100f4a5000000000000000000000ea6000000200000000000000000000000000000000000000000000000a60000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058c00000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001700010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0044007200610067004200750069006c006400560036002e0064006c006c00000000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800170001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0044007200610067004200750069006c006400560036002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000c000000203600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper,window,rowControl,buildingStatus

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','DragBuildV6')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_DragBuildV6_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=dragHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write drag-build helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Drag-build helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','DragBuildV6'),'Drag-build helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18},1),
    blueprint=matchingMethod(class,'ConfigureBlueprint',{18},1),
    request=matchingMethod(class,'Request',{8,14},1),
    names=matchingMethod(class,'SavedNames',{},14),
    save=matchingMethod(class,'SaveCaptured',{},14),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18,2,12},2)}
  return helper
end
local function stopDrag()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove drag-build hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Drag-build helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  dragButton.Caption='Building tools...'
  if rowControl then rowControl.Caption='Auto rows: OFF' end
end
ValheimDragBuildStop=stopDrag
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopDrag();if window then window.hide() end;return close() end
form.OnDestroy=function() stopDrag();if window then window.destroy();window=nil end;destroy() end
local function activate(mode,toggle)
  local ok,err=pcall(function()
    if state then
      if state.mode==mode and not toggle then return end
      local same=state.mode==mode;stopDrag()
      if same and toggle then playerStatus.Caption='Building mode disabled.';return end
    end
    local s=playerContext()
    if ValheimRapidHoeStop then ValheimRapidHoeStop() end
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','Player'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'UpdatePlacement',{2,12},1)),'Player update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Drag-build callback')
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode damage prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read damage prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    s.script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhDragBuild,4096,%X)
label(vhDragBuildRestore)
label(vhDragBuildOriginal)
vhDragBuild:
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
mov byte ptr [rsp+C0],0
mov rax,%X
mov r11,%X
cmp [rax],r11
jne vhDragBuildRestore
// Player, takeInput and dt are passed unchanged to Tick and the original placement method.
call %X
mov [rsp+C0],al
vhDragBuildRestore:
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
cmp byte ptr [rsp+C0],0
lea rsp,[rsp+D8]
je vhDragBuildOriginal
ret
vhDragBuildOriginal:
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhDragBuild
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling drag build')
    s.mode=mode;state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Drag-build hook installation failed: '..tostring(info))
    s.info=info
    invoke(mode==1 and s.helper.blueprint or s.helper.configure,0,{{type=vtPointer,value=s.player}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Drag-build helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          if not closed then
            local sf=field(state.helper.class,'Status');local address=sf.staticAddress
            if not address or address<=sf.offset then address=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+sf.offset end
            local p=readPointer(address)
            if p and p~=0 then playerStatus.Caption=stringValue(p);hint(playerStatus,playerStatus.Caption);if enemyStatus then enemyStatus.Caption=playerStatus.Caption end end
          end
          if state.stopping or readInteger(state.enabled)~=1 then stopEnemy() end
        end)
        if not active then
          local stopped,stopError=pcall(stopDrag)
          playerStatus.Caption='Drag build stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;dragButton.Caption='Building tools...'
    if rowControl then rowControl.Caption=mode==0 and 'Auto rows: ON' or 'Auto rows: OFF' end
    playerStatus.Caption=mode==0 and 'Auto rows: Left-click and drag, then release to build.' or 'Blueprint mode ready. Return to Valheim, equip your hammer and follow the Building instructions.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopDrag)
    showMessage('Valheim drag build: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
local function request(code,text)
  activate(1,false)
  if not state or state.mode~=1 then return end
  local ok,err=pcall(function() invoke(state.helper.request,0,{{type=vtDword,value=code},{type=vtString,value=text or ''}}) end)
  if not ok then showMessage('Building: '..tostring(err))
  elseif buildingStatus then buildingStatus.Caption='Command queued. Return to Valheim with your hammer and close game menus to process it.' end
end
dragButton.OnClick=function()
  if window then window.show();return end
  window=createForm(false);window.Caption='Valheim | Building';window.Width=680;window.Height=500;window.Position='poScreenCenter'
  window.Color=0x202020;window.Font.Color=0xE6E6E6
  local instructions=createLabel(window);instructions.Left=18;instructions.Top=16;instructions.Width=630;instructions.Height=145;instructions.AutoSize=false;instructions.WordWrap=true
  instructions.Caption='CAPTURE: Stand inside the building at floor level. Click Capture and enter dimensions; the box starts 1m below your feet. Return to Valheim once with your hammer. When Captured N pieces appears, click Save captured blueprint here. The selection stays fixed, and Save shows the full file path. No capture hotkeys needed. LOAD: Aim to preview, Q/E rotate, Page Up/Down adjust height, F6 locks, F7 builds. Free Crafting removes costs. Escape cancels. Undo affects the last paste only; empty its containers and stands first. See Help for details.'
  local function button(caption,x,y,fn)
    local b=createButton(window);b.Caption=caption;b.Left=x;b.Top=y;b.Width=306;b.Height=34;b.OnClick=fn;if styleToggle then styleToggle(b) end;return b
  end
  rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)
  if styleToggle then styleToggle(rowControl) end
  button('Capture furnished blueprint...',340,169,function()
    local name=inputQuery('Capture blueprint','Save name (duplicates get a numbered suffix):','My house');if not name then return end
    local box=inputQuery('Capture bounds','Width height depth (each 2-80m). Stand inside at floor level. Box starts 1m below your feet.','20 12 20');if not box then return end
    local w,h,d=box:match('^%s*(%S+)%s+(%S+)%s+(%S+)%s*$');if not w then showMessage('Enter width height depth, for example 20 12 20');return end
    request(1,name..'|'..w..'|'..h..'|'..d)
  end)
  button('Load blueprint / preview...',18,213,function()
    activate(1,false);if not state then return end
    local ok,names=pcall(function() local v=invoke(state.helper.names,0,{});return type(v)=='string' and v or (v and stringValue(v) or '') end)
    local name=inputQuery('Load blueprint','Saved: '..(ok and names or '(library unavailable)')..'\nEnter the saved name:','My house');if name then request(2,name) end
  end)
  button('Undo last blueprint paste',340,213,function() request(4,'') end)
  button('Cancel preview / queued building',18,257,function() request(3,'') end)
  button('Disable building tools',340,257,stopDrag)
  local saveButton=button('Save captured blueprint',18,301,function()
    local ok,result=pcall(function()
      assert(state and state.mode==1,'Capture a blueprint first.')
      assert(playerIdentity(state),'Player changed. Capture again in the current world.')
      local v=invoke(state.helper.save,0,{})
      return type(v)=='string' and v or stringValue(pointer(v,'Saved blueprint path'))
    end)
    if ok then
      buildingStatus.Caption='Saved: '..result
      showMessage('Blueprint saved successfully:\n'..result)
    else
      buildingStatus.Caption='Save failed: '..tostring(result)
      showMessage(buildingStatus.Caption)
    end
  end)
  saveButton.Width=628
  buildingStatus=createLabel(window);buildingStatus.Left=18;buildingStatus.Top=352;buildingStatus.Width=630;buildingStatus.Height=100;buildingStatus.AutoSize=false;buildingStatus.WordWrap=true
  buildingStatus.Caption='Saved under LocalAppData / ValheimSoloToolkit / Blueprints. Maximum 512 pieces. Rows and blueprints share one active mode.'
  window.OnClose=function() return caHide end
  window.show()
end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
;(function()
local enemyHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300221dd46a0000000000000000e00002210b010b00006c000000060000000000005e8a00000020000000a000000000001000200000000200000400000000000000040000000000000000e000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000108a00004b00000000a00000d00200000000000000000000000000000000000000c000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000646a000000200000006c000000020000000000000000000000000000200000602e72737263000000d002000000a0000000040000006e0000000000000000000000000000400000402e72656c6f6300000c00000000c0000000020000007200000000000000000000000000004000004200000000000000000000000000000000408a0000000000004800000002000500dc4e0000343b0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013300200ef00000001000011000316320c037e180000048e69fe042b0116000a062d0b7201000070730400000a7a041632090418fe0216fe012b0116000a062d0b723f000070730400000a7a7e11000004280500000a2c0f7e110000047b3d00000416fe012b0117000a062d0b726f000070730600000a7a7e1200000414280700000a2d2a7e1300000414280700000a2d1d7e1400000414280700000a2d107e1500000414280800000a16fe012b0116000a062d0b721c010070730900000a7a0280050000040380070000040480080000047e0600000417588006000004168009000004148004000004178002000004726c01007080030000042a0013300200390000000100001100022c040217330d032c060317fe012b0117002b0116000a062d0b72d6010070730400000a7a0217fe01800a0000040317fe01800b0000042a00000013300200490000000100001100022c0402173314032c040317330d042c060417fe012b0117002b0116000a062d0b7206020070730400000a7a0217fe01800c0000040317fe01800d0000040417fe01800e0000042a000000133001002300000002000011007e11000004280500000a2c0c7e110000047b3d0000042d03162b0117000a2b00062a00133002002100000001000011007e11000004280500000a2c0d7e11000004026f110000062b0116000a2b00062a000000133003005700000003000011000228050000060b072d04160a2b46026f0a00000a2200000000fe030b072d3102027e05000004280b00000a2d12220000803f026f0c00000a280d00000a2b0a7e110000046f0f000006006f0e00000a00170a2b00062a001330020054000000010000110002280f00000a2d2d0222cdcccc3d322502220000a041301d03280f00000a2d150322cdcccc3d320d032200002041fe0216fe012b0116000a062d0b7244020070730400000a7a02800f0000040380100000042a620016800200000416800900000472a002007080030000042a000000133002001700000001000011007e0200000417fe0116fe010a062d061780090000042a001b3002004d0000000400001100007e11000004280500000a2c1c7e05000004280b0000062c107e11000004036f1f00000616fe012b0117000b072d0c7e11000004026f200000060000de0c0a0006280c0000060000de00002a00000001100000000001003e3f000c09000001133002003200000001000011007e0200000417332202280500000a2c1a027e05000004280b00000a2c0d027e1000000a280b00000a2b0116000a2b00062ab200026f1100000a6f1200000a800400000416800200000472fa0200707e04000004281300000a80030000042a001b3003002b01000004000011007e0200000417fe010b072d053817010000007e05000004280b0000060b072d0c00280800000600ddfc0000007e11000004280500000a2c2d7e110000047b160000047e05000004281400000a2d137e110000047b170000047e06000004fe012b0116002b0117000b072d23007e110000046f24000006007e110000046f1500000a281600000a00148011000004007e11000004280500000a0b072d49007224030070731700000a280100002b80110000047e110000047e050000047d160000047e110000047e060000047d170000047e110000047e070000047e080000046f1900000600007e110000046f23000006007e11000004026f140000060000de280a0006280c000006007e11000004280500000a16fe010b072d0b7e110000046f240000060000de0000002a000110000000001200ee0001280900000103300300870000000000000017800d000004220000803f800f000004220000803f8010000004d00d000001281900000a72500300701f34281a00000a8012000004d004000001281900000a72660300701f34281a00000a8013000004d004000001281900000a728a0300701f34281a00000a8014000004d007000001281900000a729e0300701f346f1b00000a80150000042a0013300300260000000500001100220000803f027b37000004027b160000046f0c00000a281c00000a280d00000a0a2b00062a0000133002005b0000000100001100027b16000004280500000a2c46027b160000047e1000000a280b00000a2c34027b35000004280500000a2c27027b35000004281d00000a280b00000a2c15027b350000046f1e00000a027b36000004fe012b0116000a2b00062a00133002006b0000000300001100027b3d0000042c080228100000062b0116000b072d04160a2b4e03027b16000004280b00000a2d3b027b2b0000042d2f027b16000004280b0000062c227e0c0000042c1b027b1a000004280500000a2c0e03027b1a000004280b00000a2b0116002b0117000a2b00062a00033003005a00000000000000007e3e000004027b16000004027b160000046f1f00000a6f2000000a7b2100000a8c260000016f2200000a007e3f000004027b1600000422000000008c260000016f2200000a007e40000004027b16000004146f2300000a262a0000133003003300000006000011001a8d270000010b071672bc030070a2071772cc030070a2071872e6030070a2071972f6030070a207282400000a0a2b00062a0013300500690100000700001100027b480000042c28027b2a0000042c20027b2b0000042d1803280500000a2c10027b4a000004280500000a16fe012b0116000c082d05382c010000160a388f00000000027b4c00000406d00a000001281900000a7e4b000004069a1f346f1b00000aa2027b4c000004069a14280800000a2d21027b4c000004069a6f2500000ad026000001281900000a282600000a16fe012b0116000c082d1772020400707e4b000004069a281300000a732700000a7a027b4d00000406027b4c000004069a036f2800000aa526000001a0000617580a067e4b0000048e69fe040c083a60ffffff02037d4a000004027b450000041f1b2e0722000020412b05220000c041000b027b4c000004169a0307027b4d0000041698280d00000a8c260000016f2200000a00027b4c000004189a0307027b4d0000041898280d00000a8c260000016f2200000a00027b4c000004199a0307027b4d0000041998280d00000a8c260000016f2200000a002a00000013300600320000000100001100027b1a0000046f1f00000a6f2000000a282900000a282a00000a282b00000a0403281300000617282c00000a0a2b00062a00001330030064000000080000110003280500000a0b072d022b56036f0200002b0a06280500000a0b072d1600036f0300002b0a027b4f000004066f2e00000a0000027b4e000004066f2f00000a0b072d13027b4e00000406066f3000000a6f3100000a000622000000006f3200000a002a13300400c80200000900001100027b52000004130711073af2000000007e5600000414280800000a2d107e5700000414280800000a16fe012b011600130711072d0b721a040070732700000a7a02281d00000a7d50000004027b50000004280500000a130711072d0b726c040070730600000a7a027e56000004027b500000046f2800000aa5310000017d5100000402027b160000046f0400002b7d53000004027b53000004280500000a2c1a027b530000046f3400000a2c0d027b530000046f3500000a2b011600130711072d0b72a2040070730600000a7a02027b530000046f3600000a7d5400000402027b540000047e3700000a72f60400706f3800000a7d5500000402177d5200000400027b50000004280500000a2c15027b50000004281d00000a280b00000a16fe012b011700130711072d0d027b50000004166f3900000a00027b53000004280500000a2c32027b530000046f3400000a2c25027b530000046f3500000a2c18027b530000046f3600000a027b54000004fe0116fe012b011700130711072d16027b540000047e3700000a72f60400706f3a00000a00283b00000a0a06280500000a16fe01130711073a86000000007e5800000413081613092b6b110811099a0b00d033000001281900000a071f346f1b00000a0c0814280800000a16fe01130711072d1172f804007007281300000a732700000a7a08066f2800000a75280000010d09280500000a16fe01130711072d0d02096f1500000a28160000060000110917581309110911088e69fe04130711072d87283c00000a13041104280500000a16fe01130711072d7c007e5700000411046f2800000a7535000001130511052c121105027b160000046f3d00000a16fe012b011700130711072d49001105027b160000046f3e00000a130611066f3f00000a720a0500701f346f1b00000a0c0814284000000a16fe01130711072d14020811066f2800000a750b00000128160000060000002a1b3003006d0100000a0000110000027b4e0000046f4100000a0c2b2f1202284200000a0a1200284300000a280500000a16fe010d092d141200284300000a1200284400000a6f3200000a001202284500000a0d092dc6de0f1202fe160300001b6f4600000a00dc0000027b4f0000046f4700000a13042b1c1204284800000a0b07280500000a16fe010d092d0707281600000a001204284900000a0d092dd9de0f1204fe160500001b6f4600000a00dc00027b4e0000046f4a00000a00027b4f0000046f4b00000a00027b5200000416fe010d093a9f00000000027b50000004280500000a2c15027b50000004281d00000a280b00000a16fe012b0117000d092d12027b50000004027b510000046f3900000a00027b53000004280500000a2c32027b530000046f3400000a2c25027b530000046f3500000a2c18027b530000046f3600000a027b54000004fe0116fe012b0117000d092d17027b540000047e3700000a027b550000046f3a00000a0002167d52000004002a000000011c000002000e003e4c000f0000000002006a002b95000f0000000013300500160300000b000011007e3e00000414280800000a2d537e3e0000046f2500000ad026000001281900000a282600000a2d387e3f00000414280800000a2d2b7e3f0000046f2500000ad026000001281900000a282600000a2d107e4000000414280700000a16fe012b0116000d092d0b7216050070730900000a7a02281d00000a7d35000004027b35000004280500000a0d092d0b7266050070730600000a7a02027b350000046f1e00000a7d36000004027b160000046f4c00000a0d092d0b7292050070730600000a7a027b160000046f4d00000a2d2a027b160000046f4e00000a2d1d027b160000046f4f00000a2d10027b160000046f5000000a16fe012b0116000d092d0b7229060070730600000a7a285100000a7e18000004039a6f5200000a0a06280500000a2c1a066f0500002b280500000a2c0d066f0600002b280500000a2b0116000d092d1772ac0600707e18000004039a281300000a730600000a7a02027b160000046f0700002b7d1b00000402027b160000046f0800002b7d1c000004027b1b000004280500000a2c1f027b1c000004280500000a2c12027b160000047b5300000a280500000a2b0116000d092d0b72de060070730600000a7a02027b160000046f1f00000a6f2000000a7d3100000402027b310000047d3200000402027b160000046f1f00000a6f5400000a7d3400000402027b310000047d4900000402031f1a2e07031f1bfe012b0117007d480000040206027b31000004282900000a22cdcc4c3e285500000a282a00000a027b160000046f1f00000a6f5400000a280900002b7d1900000402027b190000046f0500002b7d1a000004027b190000046f0a00002b0b07280500000a2c10076f3400000a2c08076f3500000a2b0116000d092d0b724a070070730600000a7a027b1a0000040417586f5700000a0000027b190000046f0b00002b13041613052b14110411059a0c08166f5900000a00110517581305110511048e69fe040d092de002285a00000a7d4400000402285b00000a2200004040587d4700000402037d4500000402047d4600000472a00700707e18000004039a72ba070070285c00000a80030000042a00001b300500090500000c00001100285a00000a027b44000004fe02130611062d0816130538ea040000027b1f0000046f5d00000a0000027b1a0000046f5e00000a6f5f00000a6f6000000a13072b431207286100000a0a066f6200000a2c1e027b480000042c12067b6300000a7b6400000a7b6500000a2b0116002b011700130611062d0d027b1f000004066f6600000a001207286700000a130611062db0de0f1207fe160700001b6f4600000a00dc00027b1a0000046f6800000a0b027b1f0000046f6900000a2d29072c26076f6200000a2c1e027b480000042c12077b6300000a7b6400000a7b6500000a2b0116002b011700130611062d0d027b1f000004076f6600000a00027b1f0000046f6900000a16fe0116fe01130611062d3b00285b00000a027b47000004fe0416fe01130611062d0816130538d50300007e18000004027b450000049a72fc070070281300000a730600000a7a027b160000046f4e00000a2d1d027b160000046f4f00000a2d10027b160000046f5000000a16fe012b011600130611062d0b72af080070730600000a7a02027b1a0000047b6a00000a7d23000004160c389600000000027b2500000408d007000001281900000a7e24000004089a1f346f1b00000aa2027b25000004089a14280800000a2d21027b25000004089a6f2500000ad026000001281900000a282600000a16fe012b011600130611062d1772400900707e24000004089a281300000a732700000a7a027b2600000408027b25000004089a027b1a0000046f2800000aa526000001a0000817580c087e240000048e69fe04130611063a57ffffff02281e00000600027b450000041f1a330d027b1a0000046f6b00000a2b011700130611062d0c027b1a0000046f6c00000a0000027b1f0000046f6000000a130738b20000001207286100000a0d007e29000004097b6300000a146f2300000a7440000001130411047b6400000a14fe01130611062d3400110411047b6400000a6f6d00000a7d6400000a027b2000000411047b6400000a11047b6400000a7b6e00000a6f6f00000a000011047b7000000a14fe01130611062d3400110411047b7000000a6f6d00000a7d7000000a027b2000000411047b7000000a11047b7000000a7b6e00000a6f6f00000a00000911047d6300000a001207286700000a130611063a3effffffde0f1207fe160700001b6f4600000a00dc0002281d0000060002027b1f000004027b1a0000046f6800000a6f7100000a7d41000004027b4100000416fe0416fe01130611062d320002167d41000004027b1a000004027b1f000004166f7200000a166f7300000a130611062d0b7256090070730600000a7a0002027b160000046f4c00000a7d2c00000402027b1b0000046f4c00000a7d2d00000402027b1c0000046f7400000a7d2e000004027e15000004027b160000046f2800000aa5310000017d2f00000402027b160000047b5300000a6f7500000a7d3000000402177d2a00000402027b160000046f0a00000a7d3700000402177d3d000004027b1b000004166f5900000a00027b16000004166f5900000a007e15000004027b16000004178c310000016f2200000a00027b1c000004287600000a6f7700000a00027b1c000004287600000a6f7800000a00027b1c000004176f7900000a0002281b00000600022817000006001a8d0100000113081108167e18000004027b450000049aa211081772ac090070a2110818027b460000048c41000001a211081972b2090070a21108287a00000a80030000041713052b0011052a000000011c0000020040005494000f0000000002008b02c954030f0000000013300300af0000000d0000110000027b16000004176f0c00002b0c160d2b3708099a0a00027b1d000004066f7c00000a130411042d13027b1d00000406066f7d00000a6f7e00000a0006176f7f00000a00000917580d09088e69fe04130411042dbd00027b16000004176f0d00002b1305160d2b381105099a0b00027b1e000004076f8000000a130411042d13027b1e00000407076f8100000a6f8200000a0007166f8300000a00000917580d0911058e69fe04130411042dbb2a0013300300700000000100001100288400000a2c617e14000004027b16000004146f2300000aa5310000012c49288500000a2d42288600000a2d3b288700000a2d34288800000a2d2d288900000a2d26288a00000a2d1f288b00000a280500000a2c0f288b00000a6f8c00000a16fe012b0117002b0116000a2b00062a1b3003007e0100000e00001100027b1a0000047e0a0000042d03162b06027b23000004007d6a00000a7e15000004027b1a0000047e0a0000048c310000016f2200000a0000027b200000046f8d00000a0d2b261203288e00000a0a1200288f00000a7e0b0000042d091200289000000a2b0117007d6e00000a1203289100000a130411042dcdde0f1203fe160b00001b6f4600000a00dc00027b220000046f9200000a0000027b210000046f9300000a13052b721205289400000a0b001201289500000a280500000a130411042d1600027b220000041201289500000a6f9600000a002b411201289500000a7e0b0000042d0b1201289700000a16902b0117007d9800000a1201289500000a7e0b0000042d0b1201289700000a17902b0116007d9900000a001205289a00000a130411042d81de0f1205fe160f00001b6f4600000a00dc0000027b220000046f9b00000a13062b151206289c00000a0c027b21000004086f9d00000a261206289e00000a130411042ddede0f1206fe161100001b6f4600000a00dc002a00000128000002004500377c000f000000000200a6008329010f0000000002004701266d010f0000000013300600860000000f000011007e0f0000040a7e100000040b06027b27000004330e07027b28000004fe0116fe012b0117000d092d022b59160c2b38027b25000004089a027b1a000004027b26000004089808027b250000048e6917592e03062b0107005a8c260000016f2200000a000817580c08027b250000048e69fe040d092db902067d2700000402077d280000042a000013300200230000000100001100027b1a000004280500000a2c0e03027b1a000004280b00000a2b0116000a2b00062a001330050070000000100000110003280500000a2c0b027b2b00000416fe012b0116000a062d022b53027b21000004036f9f00000a0a062d27027b2100000403188d310000010b0716037b9800000a9c0717037b9900000a9c076fa000000a007e0b00000416fe010a062d100003177d9800000a03167d9900000a002a13300400f5000000110000110002027b1a0000046f1f00000a6f2000000a7d31000004027b160000046f1f00000a027b310000046fa100000a00027b1c000004280500000a16fe010b072d12027b1c000004027b310000046fa200000a007e3e000004027b16000004027c310000047b2100000a8c260000016f2200000a007e3f000004027b1600000422000000008c260000016f2200000a00027b4800000416fe010b072d3700022200401c461200281500000616fe010b072d2102120028a300000a282900000a220000c03f285500000a282a00000a7d4900000400281d00000a280500000a16fe010b072d11281d00000a027b310000046fa400000a002a00000013300300d70000001200001100032d08027b410000042b14027b410000041758027b1f0000046f6900000a5d000a160b388f00000000060758027b1f0000046f6900000a5d0c027b1f000004086f7200000a0d027b480000042c28027b1a0000046f6b00000a2d0d097b6300000a7ba500000a2b0b097b6300000a7ba600000a002b011700130511052d022b33027b1a0000046f6800000a092e0f027b1a00000409166f7300000a2b011700130511052d022b0c02087d410000041713042b200717580b07027b1f0000046f6900000afe04130511053a5affffff1613042b0011042a0013300500070700001300001100027b2b00000416fe01130d110d2d0538f1060000027b16000004280b0000062c0f027b170000047e06000004fe012b011600130d110d2d0d000228240000060038c0060000027b1a000004280500000a2c1d027b1a0000046f4d00000a2d10027b160000046f4d00000a16fe012b011600130d110d2d350002027b1a000004280500000a2c0d027b1a0000046f4d00000a2b0117007d3b000004280800000600022824000006003859060000202101000028a700000a16fe01130d110d2d1300280800000600022824000006003833060000027b2a0000042d0802281a0000062b011700130d110d2d0538160600000228210000060002281e0000060002281d00000600027b160000047b5300000a027b1a0000046fa800000a6fa100000a0002281b000006000228170000060002281c0000060a0616fe01130d110d3a0b040000007e12000004027b1b000004146f2300000a267e13000004027b16000004146f2300000a26027b160000047b5300000a6fa900000a0b120122000000007d2100000a120128aa00000a00282900000a0728ab00000a0c28ac00000a0d72970a007028ad00000a2d03162b01170072a30a007028ad00000a2d03162b011700596b12037bae00000a58130472ad0a007028ad00000a2d03162b01170072bd0a007028ad00000a2d03162b011700596b12037baf00000a581305071105285500000a081104285500000a282a00000a220000803f28b000000a130672cf0a007028ad00000a2d0c72d90a007028ad00000a2b011700130772cf0a007028b100000a2d0c72d90a007028b100000a2b0117001308027b4800000416fe01130d110d3ae500000000027b1a0000046f6b00000a2d1111082c0d027b1a0000046f4e00000a2b011700130d110d2d0c027b1a0000046f6c00000a00027b1a0000046f6b00000a16fe01130d110d3a9a00000000120611072d0722000000002b05220000803f00203201000028b200000a2d0722000000002b05220000803f00597d2100000a1106220000803f28b000000a1306027b450000041f1b33161f6728a700000a2c0d027b1a0000046f4e00000a2b011700130d110d2d300002220000a0401209281500000616fe01130d110d2d0e027b1a0000046fb300000a002b0a72e90a0070800300000400000072570b007028ad00000a2d0c72650b007028ad00000a2b011700130a72790b007028ad00000a2d2472990b007028ad00000a2d1872bf0b007028ad00000a2d0c72cb0b007028ad00000a2b011700130b027b1a00000411066fb400000a00120628b500000a220ad7233c3615110a2d11110b2d0d027b1a0000046f4e00000a2c12027b160000047b5300000a6fa900000a2b02110600130c027b1a000004110c22000000006fb600000a00027b1a00000472dd0b007028ad00000a2d0c72e50b007028ad00000a2b0117006fb700000a00027b1a000004166fb800000a00027b480000042d07110816fe012b011700130d110d2d0d027b1a000004166fb900000a0072f30b007028b100000a2d0f72fb0b007028b100000a16fe012b011600130d110d2d061780090000047e090000042c0d027b1a0000046f4e00000a2b011700130d110d2d1000168009000004021728220000062600110a2d04110b2c1a285b00000a027b42000004370d027b1a0000046f4e00000a2b011700130d110d2d7f0002285b00000a229a99193e587d420000040216282200000616fe01130d110d2d5c027b1a00000414110a2d49027b1f000004027b410000046f7200000a6fba00000a2c31027b480000042c25027b1f000004027b410000046f7200000a7b6300000a7b7000000a7b6500000a16fe012b0117002b0116006fbb00000a2600002b2000027b1a000004287600000a6fb400000a00027b1a000004166fb700000a0000285b00000a027b43000004fe05130d110d3a820100000002285b00000a220000003f587d430000041f128d01000001130e110e167e18000004027b450000049aa2110e1772ac090070a2110e18027b460000048c41000001a2110e1972090c0070a2110e1a027b1a0000046f0a00000a28bc00000a8c41000001a2110e1b72390c0070a2110e1c027b1a0000046f0c00000a28bc00000a8c41000001a2110e1d72410c0070a2110e1e027b4100000417588c41000001a2110e1f0972550c0070a2110e1f0a027b1f0000046f6900000a8c41000001a2110e1f0b72590c0070a2110e1f0c027b1f000004027b410000046f7200000a7b6300000a7bbd00000aa2110e1f0d7e0a0000042d07725f0c00702b0572930c007000a2110e1f0e7e0b0000042d0772f30c00702b05722f0d007000a2110e1f0f7e0c0000042d0772f60400702b05729d0d007000a2110e1f10027b480000042d0772f60400702b2172cf0d0070027b450000041f1b2e0772f60400702b0572270e007000281300000a00a2110e1f1172530e0070a2110e287a00000a8003000004002a001b300400a70400001400001100027b2b00000416fe01130511052d05389104000002177d2b000004027b4a000004280500000a16fe01130511052d3a160a2b25027b4c000004069a027b4a000004027b4d00000406988c260000016f2200000a000617580a06027b4c0000048e69fe04130511052dca00027b210000046f9300000a13062b491206289400000a0b1201289500000a280500000a16fe01130511052d2c001201289500000a1201289700000a16907d9800000a1201289500000a1201289700000a17907d9900000a001206289a00000a130511052daade0f1206fe160f00001b6f4600000a00dc00027b210000046fbe00000a00000228180000060000dda903000000027b2a0000042c10027b16000004280500000a16fe012b011700130511053a40030000000228100000060c02082c2a027b3b0000042c077e0d0000042d17027b3b0000042d077e0e0000042d08027b480000042b0117002b0116007d3c00000402027b3b0000042c077e0d0000042d17027b3b0000042d077e0e0000042d08027b490000042b06027b32000004007d33000004027b160000046f1f00000a027b310000046fa100000a00027b160000047b5300000a027b300000046fbf00000a00027b1c000004280500000a16fe01130511052d12027b1c000004027b310000046fa200000a0002281200000600027b160000046f4d00000a130511052d12027b1600000402280f0000066f0e00000a00027b160000047e1000000a280b00000a2c22027b50000004280500000a2c15027b50000004281d00000a280b00000a16fe012b011700130511052d12027b50000004027b310000046fa400000a0000027b1d0000046fc000000a13072b31120728c100000a0d120328c200000a280500000a16fe01130511052d14120328c200000a120328c300000a6f7f00000a00120728c400000a130511052dc2de0f1207fe161200001b6f4600000a00dc0000027b1e0000046fc500000a13082b32120828c600000a1304120428c700000a280500000a16fe01130511052d14120428c700000a120428c800000a6f8300000a00120828c900000a130511052dc1de0f1208fe161400001b6f4600000a00dc007e15000004027b16000004027b2f0000048c310000016f2200000a00027b1c000004280500000a16fe01130511052d4400027b1c000004027b2e0000046f7900000a00027b2e000004130511052d2400027b1c000004287600000a6f7700000a00027b1c000004287600000a6f7800000a000000027b16000004287600000a6fb400000a00027b16000004166fb700000a00027b16000004027b2c0000046f5900000a00027b1b000004280500000a16fe01130511052d12027b1b000004027b2d0000046f5900000a0002285b00000a2200004040587d3800000402285b00000a2200002041587d390000040222000000007d3a00000402082c10027b160000046f4d00000a16fe012b0116007d3d000004027b3c0000042d0772930e00702b0572240f0070008003000004027b3d00000416fe01130511052d070228260000060000027b19000004280500000a2c0f285100000a280500000a16fe012b011700130511052d11285100000a027b190000046fca00000a0002147d1900000402147d1a00000400dc002a004164000002000000780000005a000000d20000000f00000000000000020000006a02000042000000ac0200000f0000000000000002000000ca020000430000000d0300000f0000000000000002000000ee0000000e000000fc000000a90300000000000013300200700000000100001100027b2b00000416fe010a062d200002282600000600027b3d0000040a062d0c02281500000a281600000a002b41027b16000004280b0000062c0f027b170000047e06000004fe012b0116000a062d1f0002282400000600027b3d0000040a062d0c02281500000a281600000a00002a13300400230100000100001100027b3d0000040a062d0538120100000228100000062c10027b160000046f4d00000a16fe012b0116000a062d140002167d3d00000402167d3c00000438e000000002281200000600027b3c0000042c0f285b00000a027b3a000004fe052b0117000a062d720002285b00000a220000003f587d3a000004027b16000004027b33000004027b34000004176fcb00000a16fe010a062d1c0002167d3c00000402285b00000a2200004040587d38000004002b24285b00000a027b39000004fe050a062d130002167d3c00000472e10f007080030000040000027b160000046f5000000a16fe010a062d140002285b00000a220000803f587d380000042b24027b3c0000042d0f285b00000a027b38000004fe052b0117000a062d0702167d3d0000042a0013300200540000000100001100027b2a0000042c34027b2b0000042d2c027b1a000004280500000a2c1f027b16000004280b0000062c12027b170000047e06000004fe0116fe012b0117000a062d10000228210000060002281e00000600002a2600022824000006002a000013300300ff020000150000111f308d270000010a0616729e100070a2061772b2100070a2061872c4100070a2061972d2100070a2061a72dc100070a2061b72e8100070a2061c72f8100070a2061d720a110070a2061e7214110070a2061f097234110070a2061f0a7256110070a2061f0b7270110070a2061f0c728c110070a2061f0d72ac110070a2061f0e72b6110070a2061f0f72ca110070a2061f1072dc110070a2061f1172ec110070a2061f12720c120070a2061f13721a120070a2061f147232120070a2061f15724c120070a2061f167254120070a2061f17726c120070a2061f187284120070a2061f19729c120070a2061f1a72ac120070a2061f1b72c0120070a2061f1c72ce120070a2061f1d72e4120070a2061f1e72f2120070a2061f1f72fc120070a2061f20720a130070a2061f21721a130070a2061f22722c130070a2061f23723c130070a2061f24725c130070a2061f25727a130070a2061f2672a0130070a2061f2772bc130070a2061f2872da130070a2061f2972f4130070a2061f2a7216140070a2061f2b7226140070a2061f2c7236140070a2061f2d7248140070a2061f2e725e140070a2061f2f7276140070a20680180000041e8d270000010a06167282140070a206177292140070a2061872aa140070a2061972c0140070a2061a72dc140070a2061b72f4140070a2061c7212150070a2061d7230150070a2068024000004d001000001281900000a72481500701f24281a00000a8029000004d007000001281900000a72681500701f346f1b00000a803e000004d007000001281900000a728a1500701f346f1b00000a803f000004d007000001281900000a72a21500701f34281a00000a80400000041a8d270000010a061672c8150070a2061772de150070a2061872fa150070a206197216160070a206804b000004d019000001281900000a72381600701f346f1b00000a8056000004d034000001281900000a726c1600701f346f1b00000a80570000041a8d270000010a0616727a160070a206177296160070a2061872b2160070a2061972d6160070a20680580000042a0003300200be000000000000000273cc00000a7d1d0000040273cd00000a7d1e0000040273ce00000a7d1f0000040273cf00000a7d200000040273d000000a7d210000040273d100000a7d22000004027e240000048e698d060000017d25000004027e240000048e698d260000017d260000040222000080bf7d270000040222000080bf7d28000004027e4b0000048e698d060000017d4c000004027e4b0000048e698d260000017d4d0000040273d200000a7d4e0000040273d300000a7d4f0000040228d400000a002a000042534a4201000100000000000c00000076342e302e33303331390000000005006c000000a80d0000237e0000140e0000a010000023537472696e677300000000b41e0000fc16000023555300b0350000100000002347554944000000c03500007405000023426c6f620000000000000002000001571da2090908000000fa253300160000010000004c00000003000000580000002a0000001b000000d40000000100000002000000150000000100000002000000020000001500000001000000070000000d00000000000a00010000000000060065005e000a008f0083000600af009d000e00ec00000006007b019d000600a6019d000e00e60100000e0026020000060045025e000e00550200000a006b0283000e00810200000e008f0200001200c50283000600f502da020a000203830012001503830006002803da020e002f0300004f00380300000e00490300001f007b0300000a00250483000a00620483000e007b0400001200f70583001600230683000e00710600000e008506000006002b080c080600690849080600890849080600bb085e000a00650083000600d9085e000600ff085e0006002d095e00060040095e00060078095e000a00940983000600c9095e000600ce095e000a00220a83000600520a9d000a00640a83000600840a5e001200bf0a83001200c70a83000600180b5e000e00370b00000e00750b00000e007d0b00000600990b860b3f00bf0b00000600d80bda0206000e0c5e004b00bf0b00000a00280c83000e00640c00000e00780c00000e00c40c00000a00d70c83000e00f40c00005300290d00000600250e5e000a006f0e83000e00890e00000e00a00e00000e00a50e00000e00b40e00000e00d90e00001a006a0f83000a00700f83001e00ba0f00000a00c10f83000a006910830000000000010000000000010001008101100022002f000500010001000101100042002f00090016000f005380bc000a001600c20013001600ca0016001600d10016001300f30019001300f900130013000401130013000b011300130011011d00130020011d00130032011d00130037011d00130040011d0013004f011d0013005c01200013006a01200013007401230033008601270033009101270033009d0127003300b0012b000600f30019000300f900130033006502720001007602760001008a027a000100a0027e000100cf02820021000b03860021001e038f0021004103980021005003a00021005c03a90021006803b30001008303bb0031009103720021009f03bf002100ae03c4000100bd0320000100ca0320003100d60327000100e1031d000100e7031d000100f0031d000100fe031d00010010041d0001001a041d0001002d04c80001003604c80001004504c80001005304c80001006d04cc0001008004d00001008b04d4000100980420000100a50420000100b10420000100bc0420000100c6041d000100cf041d000300df041d003100fd042b00310004052b0031000e05270001003705130001004305200001004e05200001005905130001006405130001006f051300010079052000010090051d0001009605c8000100a905e9003100b60572002100c205bf002100cf05c40021002f06fb0021003806040101004006d00001004c061d00010063061d0001007a060c010100890610010100930616003100a0062b003100af062b003100b40672005020000000009600bb012f0001004c21000000009600c501370004009421000000009600d0013d000600ec21000000009600da01440009001c22000000009600f001480009004c22000000009600fc0148000a00b02200000000960007024e000b001023000000009600130254000d002c230000000096001b0254000d005023000000009600310258000d00bc23000000009300400260000f00fa230000000093004f0266001000282400000000960060026c0011007025000000009118c209540012000426000000008308ec04d700120038260000000081001a05db001200a0260000000083002405df00120018270000000081002d05e50013008027000000009108dc0544001300c027000000008300eb05ed00130038290000000081000206f30014007829000000008100bf0614011600e829000000008100c606e5001700bc2c000000008100d306e5001700542e000000008600e3061a0117007831000000008100e906db001900ac36000000008100f506e500190068370000000081000007db001900e4370000000081000d07e500190098390000000081001a07e50019002c3a0000000083002807df0019005c3a000000008300310220011a00d83a0000000081002f07e5001b00dc3b0000000081003a0726011b00c03c0000000086004707e5001c00d4430000000086004c07e5001c00ec480000000081005407e5001c0068490000000081005b07e5001c00984a0000000081006807e5001c00f84a0000000081007407e5001c00104e0000000086187e07e5001c00044b000000009118c20954001c00000001009c0700000200a30700000300a80700000100ae0700000200b60700000100bb0700000200c40700000300cb0700000100d00700000100d00700000100da0700000200e00700000100e50700000200f007000001009c0700000100f60700000100f80700000100d00700000100f80700000100ff07020002000808000001003808000001003c0800000200a80700000100d00700000100e507000001004308f1007e07e500f9007e07330101017e07e50009017e0738011101cd083d0119017e0738012900f30844013100f3084c0121017e07380139001609d7001101f3085c0139002009d700290132096601390036096c0131014709760121004d09190049005b09810149006c09860139017f098a01110186095c0141019e0990011101ad09950159007e0738015900b5099c014901e009a7014901f209b0014901fc09b8012901050a6601c900090ac401c900160ac90141012c0acd0159013a0ad301b900470a20003100490ad80161015d0ade0169016e0ae5013100760af10149018609f70171017e07380131009a0a0102b900a30a0c02b900aa0a1102b900b60a0c027901df0a1a025900e70a9c010c00f40a36021400f80a4402d900040bd7001400f40a4a02d9000e0b6c014101e70a9c01e100200bdb00e100280bdb00e100300b5d0291013f0b1300e9004c0b6202c900560b6802e900710b6d029901090a7302a101090a7902a901a50b7f02a901ae0b01020900b70bf101310086094c011400ca0b9b021c00e70bb0022400f30bc5022400fb0bca021c00050cdb00c1011a0ce5000c00ca0bcf022c00e70bc5022c00050cdb001400220ce5000c00220ce500d101320cdb0039003e0cdb003900450cdb0039004e0cdb003900560cdb00d901090afe02d9016e0c04033900820c1f035901880c2403b900950c29031101a10c31033900ad0c33015900b60c4203d101cb0c6802f101dc0c4400f101eb0c4f0339017f0953033400220ce5006100fe0c7103f9010b0d77033400ca0bcf023c00e70bc502a100170ddb00a100340d880301023d0d8d03a900460d1d003400f40a36023c00050cdb006100550d91033400660d96033900700dbb0039007a0ddb003900830de500a9008b0d9a03a900910d1d004400f40a4a0201029f0d8d033400b10da7033400ae0bad036100b90db3037100c30ddb005901d30dd301b900e50d0c027100ee0dba037100010eba037100150e680239017f09c00341012b0ede034c00f80a44028100430edb004c00f40a4a028100590e68025400f80a44028900320cdb005400f40a4a028900cb0c680211027b0e0f041902960e0f042102960e0f042902960e0f049901ad0e0f043102b80e0f043102d00e0f043902090a13043902de0edb004400ca0b9b025c00e70bb0026400f30bc5026400fb0bca025c00050cdb006c00220ce5007400ca0b9b027c00e70bb0028400f30bc5026c00f40a36028400fb0bca024100910d1d004100e70e1d007c00050cdb006c00ca0bcf028c00e70bc5027400fa0e44028c00050cdb007400f80a44027400f40a4a025901010fba037100010fba03d1000e0fd301c900180fba0301022d0f1d0001023d0f1d004102780fa3043900830fd30159018f0fd301b9009b0fe500b900a50f11025102c90faa045102d90fb0045902e30f20005902470a2000b900e50f29035102f40fb00441020210a30439000910e50039000e10ba03b9001910d70039002a10b50439003510680239003c106802390044106802a1004910db0039005d10bc0461026f10c3040102791016007400220ce50059018010ba034c00ca0b9b029400e70bb0029c00f30bc5029c00fb0bca029400050cdb005400ca0b9b02a400e70bb002ac00f30bc502ac00fb0bca02a400050cdb00d901ad091401390092103e054c007e07e50054007e07e50034007e07e50044007e07e50074007e07e5006c007e07e50014007e07e5000c007e07e50011007e07e500080004000e002e0013004c052e001b0055055401580171017b01c001eb01060252028402e1025a03c6030004570486048d0493049904c8040605470503000100000084072b01000091072f0102000f0003000200130005002f023c02a702bc02d9026a0380039f03eb03f803190422042b0432043b0445044f04e204eb04f404fd04048000000000000000000000000000000000a7080000040000000000000000000000010055000000000000000000000000000000000000006c00000000000000000000000000000000000000db00000000000000000000000000000000000000ab020000000000000000000000000000000000000e060000000000000000000000000000000000004c0f000000000000000000000000000000000000ab0f000000003100a2015b002a0231002a02670058025b000a035b000f036700150367001a03ad003d035b005802b1004903f700e603f700f3030000003c4d6f64756c653e0056616c6865696d456e656d79466f726d5631322e646c6c00456e656d79466f726d5631320056616c6865696d536f6c6f546f6f6c6b697400456e656d79466f726d447269766572563132006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f75720053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c61677300456e61626c656400537461747573004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572004f776e65720047656e65726174696f6e0043686f696365005374617273004379636c65526571756573746564004d6f6e73746572416c6c656769616e6365004475656c00496d6d6f7274616c0052657475726e4f6e4465666561740052657475726e4f6e45786974004d6f76656d656e745370656564004a756d70466f72636500447269766572004d6574686f64496e666f0043616d6572614c6f6f6b00457965526f746174696f6e0043616e496e707574004669656c64496e666f00536b697054617267657400436f6e666967757265005365744f7074696f6e73005365745361666574790053616665747953746174650043686172616374657200426c6f636b44616d61676500426c6f636b4465617468005365744d6f76656d656e740044697361626c65004e657874576561706f6e0050726f6a656374696c650054756e6550726f6a656374696c65004f776e7300457863657074696f6e004661756c740047616d6543616d657261005469636b00466f726d730047616d654f626a65637400626f64794f626a6563740048756d616e6f696400626f647900506c61796572436f6e74726f6c6c657200636f6e74726f6c6c657200556e697479456e67696e652e506879736963734d6f64756c65005269676964626f647900706c61796572426f64790053797374656d2e436f6c6c656374696f6e732e47656e657269630044696374696f6e61727960320052656e64657265720072656e64657265727300436f6c6c6964657200636f6c6c6964657273004c6973746031004974656d44726f70004974656d4461746100776561706f6e730041747461636b006475656c41747461636b730070726f6a656374696c6573006578706972656450726f6a656374696c65730046616374696f6e006e617469766546616374696f6e004d6f76656d656e744e616d6573006d6f76656d656e744669656c6473006e61746976654d6f76656d656e74006170706c6965645370656564006170706c6965644a756d7000436f707953686172656400736176656400726573746f72656400706c61796572456e61626c656400636f6e74726f6c6c6572456e61626c6564006b696e656d6174696300736b697054617267657400566563746f7233006579654c6f63616c0072657475726e506f736974696f6e007374617274506f736974696f6e0074656c65706f7274546172676574005175617465726e696f6e007374617274526f746174696f6e005a4e65740073657373696f6e4e65740073657373696f6e576f726c6400706c617965724865616c746800736574746c65556e74696c007265747279556e74696c006e65787452657472790064656665617465640074656c65706f727450656e64696e6700536166657479416374697665006765745f52657475726e4865616c7468004d61784169720046616c6c54696d657200526573657447726f756e640053616d65576f726c640050726f746563747300526573657446616c6c00776561706f6e496e646578006e65787441747461636b006e65787453746174757300737061776e4672616d6500666f726d43686f69636500666f726d537461727300696e697469616c697a6174696f6e446561646c696e6500666c796572007361666552657475726e506f736974696f6e00666c6967687443616d6572610043616d6572614e616d65730063616d6572614669656c64730063616d65726156616c756573006765745f47726f756e644d61736b004170706c7943616d65726100526179636173744869740047726f756e6442656c6f7700556e697479456e67696e652e55494d6f64756c650043616e76617347726f75700068696464656e556900616464656455690064697367756973654e6574006f726967696e616c5075626c6963506f736974696f6e0064697367756973655361766564005a4e65745669657700706c6179657256696577005a444f00706c617965725a646f006f726967696e616c4e616d65005075626c6963506f736974696f6e0048756473004d61704d61726b6572730048696465556900486964654964656e7469747900526573746f72654964656e746974790053657475700046696e69736853657475700048696465506c6179657200496e707574416c6c6f776564004170706c794f7074696f6e73004170706c794d6f76656d656e74004973426f647900466f6c6c6f77426f64790053656c656374576561706f6e005374657000526573746f72650055706461746500536574746c6552657475726e004669786564557064617465004f6e44657374726f79002e63746f720052657475726e4865616c74680047726f756e644d61736b00706c6179657200666f726d007374617273006d6f6e73746572006475656c00696d6d6f7274616c00646566656174006578697400636861726163746572007370656564006a756d700070726f6a656374696c65006f776e657200650063616d6572610064697374616e6365006869740053797374656d2e52756e74696d652e496e7465726f705365727669636573004f7574417474726962757465006f626a0063686f696365006379636c650053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d456e656d79466f726d56313200417267756d656e74457863657074696f6e006f705f496d706c6963697400496e76616c69644f7065726174696f6e457863657074696f6e006f705f457175616c697479004d697373696e674d656d626572457863657074696f6e004765744865616c7468004765744d61784865616c7468004d617468004d6178005365744865616c74680053696e676c650049734e614e006d5f6c6f63616c506c617965720047657442617365457863657074696f6e006765745f4d65737361676500537472696e6700436f6e636174006f705f496e657175616c69747900436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744d6574686f64004765744669656c64004d696e006765745f696e7374616e636500476574576f726c64554944005472616e73666f726d006765745f7472616e73666f726d006765745f706f736974696f6e00790053657456616c7565004d6574686f644261736500496e766f6b65004c617965724d61736b004765744d61736b006765745f4669656c6454797065004d697373696e674669656c64457863657074696f6e0047657456616c7565006765745f7570006f705f4164646974696f6e006765745f646f776e005068797369637300517565727954726967676572496e746572616374696f6e005261796361737400476574436f6d706f6e656e740041646400436f6e7461696e734b6579006765745f616c706861007365745f616c70686100426f6f6c65616e00497356616c69640049734f776e6572004765745a444f005a444f5661727300735f706c617965724e616d6500476574537472696e67005365745075626c69635265666572656e6365506f736974696f6e00536574004d696e696d617000456e656d794875640053797374656d2e436f6c6c656374696f6e73004944696374696f6e61727900436f6e7461696e73006765745f4974656d004765745479706500456e756d657261746f7200476574456e756d657261746f72004b657956616c7565506169726032006765745f43757272656e74006765745f4b6579006765745f56616c7565004d6f76654e6578740049446973706f7361626c6500446973706f736500436c656172004265686176696f7572006765745f656e61626c65640049734465616400496e41747461636b00496e446f64676500497354656c65706f7274696e67005a4e65745363656e6500476574507265666162004d6f6e737465724149006d5f657965006765745f726f746174696f6e006f705f4d756c7469706c7900496e7374616e7469617465005365744c6576656c00476574436f6d706f6e656e747300426173654149007365745f656e61626c65640054696d65006765745f6672616d65436f756e74006765745f74696d6500496e76656e746f727900476574496e76656e746f727900476574416c6c4974656d7300486176655072696d61727941747461636b0053686172656444617461006d5f736861726564006d5f61747461636b006d5f746f67676c65466c79696e670047657443757272656e74576561706f6e006765745f436f756e74006d5f66616374696f6e004973466c79696e670054616b654f666600436c6f6e65006d5f686974467269656e646c79006d5f7365636f6e6461727941747461636b00496e6465784f660045717569704974656d006765745f69734b696e656d61746963006765745f6c6f63616c506f736974696f6e006765745f7a65726f007365745f6c696e65617256656c6f63697479007365745f616e67756c617256656c6f63697479007365745f69734b696e656d6174696300496e74333200476574436f6d706f6e656e7473496e4368696c6472656e006765745f666f72636552656e646572696e674f6666007365745f666f72636552656e646572696e674f6666004170706c69636174696f6e006765745f6973466f637573656400496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c650049734f70656e00487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c004368617400486173466f637573006d5f6e6f44616d616765467269656e646c790052656d6f7665007365745f706f736974696f6e006765745f706f696e74005365745265666572656e6365506f736974696f6e006d5f61695768656e57616c6b696e67006d5f61695768656e466c79696e6700556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004b6579436f6465004765744b6579446f776e00476574457965506f696e74006765745f666f7277617264004e6f726d616c697a650043726f737300617373656d626c795f7574696c73005a496e70757400566563746f7232004765744a6f794c656674537469636b00476574427574746f6e007800436c616d704d61676e697475646500476574427574746f6e446f776e004765744b6579004c616e64005365744d6f7665446972006765745f7371724d61676e6974756465005365744c6f6f6b4469720053657452756e0053657457616c6b004a756d7000486176655365636f6e6461727941747461636b00537461727441747461636b004d61746866004365696c546f496e74006d5f6e616d65007365745f6c6f63616c506f736974696f6e0054656c65706f7274546f00000000003d430068006f006f007300650020006100200073007500700070006f007200740065006400200065006e0065006d007900200066006f0072006d002e00002f430068006f006f0073006500200030002c002000310020006f007200200032002000730074006100720073002e000080ab500072006500760069006f00750073002000720065007400750072006e0020006900730020007300740069006c006c00200073006500740074006c0069006e0067002e00200055006e00700061007500730065002000560061006c006800650069006d00200061006e00640020007700610069007400200066006f00720020007400680065002000720065007400750072006e00200074006f002000660069006e006900730068002e00004f45006e0065006d007900200066006f0072006d00200063006f006e00740072006f006c0020006d006500740068006f0064007300200075006e0061007600610069006c00610062006c0065002e0000695100750065007500650064002e002000520065007400750072006e00200074006f0020007400680065002000670061006d006500200061006e006400200075006e0070006100750073006500200074006f0020007400720061006e00730066006f0072006d002e00002f4f007000740069006f006e00730020006d007500730074002000620065002000300020006f007200200031002e00003d53006100660065007400790020006f007000740069006f006e00730020006d007500730074002000620065002000300020006f007200200031002e00005b5300700065006500640020006d00750073007400200062006500200030002e0031002d0032003000200061006e00640020006a0075006d00700020006d00750073007400200062006500200030002e0031002d00310030002e000159520065007400750072006e0069006e006700200074006f00200070006c00610079006500720020006f006e00200074006800650020006e006500780074002000670061006d00650020007500700064006100740065002e00002945006e0065006d007900200066006f0072006d002000730074006f0070007000650064003a002000002b53006f006c006f0054006f006f006c006b00690074005f0045006e0065006d00790046006f0072006d0000154c00610074006500550070006400610074006500002355007000640061007400650045007900650052006f0074006100740069006f006e000013540061006b00650049006e00700075007400001d6d005f006100690053006b0069007000540061007200670065007400000f440065006600610075006c00740000197300740061007400690063005f0073006f006c0069006400000f7400650072007200610069006e00000b700069006500630065000017470061006d006500430061006d006500720061002e00005145006e0065006d007900200064006900730067007500690073006500200048005500440020006d006500740061006400610074006100200075006e0061007600610069006c00610062006c0065002e0000354e006500740077006f0072006b00200077006f0072006c006400200075006e0061007600610069006c00610062006c0065002e00005350006c00610079006500720020006e0061006d0065002000730074006f00720061006700650020006900730020006e006f00740020006c006f00630061006c006c00790020006f0077006e00650064002e00000100114d0069006e0069006d00610070002e00000b6d005f00670075006900004f50006c0061007900650072002000660061006c006c002d007300740061007400650020006d006500740061006400610074006100200075006e0061007600610069006c00610062006c0065002e00012b57006f0072006c006400200069007300200075006e0061007600610069006c00610062006c0065002e00008095520065007400750072006e002000660072006f006d0020007400680065002000700072006500760069006f0075007300200065006e0065006d007900200066006f0072006d00200061006e006400200075006e007000610075007300650020006200650066006f007200650020007400720061006e00730066006f0072006d0069006e006700200061006700610069006e002e00008081460069006e00690073006800200079006f0075007200200061006300740069006f006e002f00740065006c00650070006f0072007400200061006e00640020007300740061006e00640020007300740069006c006c0020006200650066006f007200650020007400720061006e00730066006f0072006d0069006e0067002e00003145006e0065006d007900200066006f0072006d00200075006e0061007600610069006c00610062006c0065003a002000006b50006c006100790065007200200063006f006e00740072006f006c006c00650072002c00200062006f006400790020006f0072002000630061006d00650072006100200061006e00630068006f007200200075006e0061007600610069006c00610062006c0065002e00005554006800650020007400720061006e00730066006f0072006d0065006400200062006f006400790020006900730020006e006f00740020006c006f00630061006c006c00790020006f0077006e00650064002e000019570061006900740069006e006700200066006f0072002000004120006e0061007400690076006500200077006500610070006f006e007300200074006f00200069006e0069007400690061006c0069007a0065002e002e002e000080b1200064006900640020006e006f007400200069006e0069007400690061006c0069007a006500200061006e00790020006e00610074006900760065002000610074007400610063006b0073002000770069007400680069006e002000330020007300650063006f006e00640073002e00200059006f0075007200200070006c006100790065007200200077006100730020006c00650066007400200075006e006300680061006e006700650064002e0000808f50006c00610079006500720020007300740061007200740065006400200061006e00200061006300740069006f006e0020007700680069006c00650020007400720061006e00730066006f0072006d0069006e0067002e0020005300740061006e00640020007300740069006c006c00200061006e0064002000740072007900200061006700610069006e002e0000154300680061007200610063007400650072002e00005543006f0075006c00640020006e006f0074002000650071007500690070002000740068006500200065006e0065006d0079002700730020006e0061007400690076006500200077006500610070006f006e002e000105200028000080e32000730074006100720073002900200066006f0072006d002e0020004d006f00760065002f00720075006e002f006a0075006d00700020006e006f0072006d0061006c006c0079003b002000410074007400610063006b0020003d0020006e00610074006900760065002000610074007400610063006b003b00200042006c006f0063006b0020003d0020007300650063006f006e0064006100720079003b00200055007300650020003d0020006300790063006c006500200077006500610070006f006e003b0020004600380020003d002000720065007400750072006e002e00000b5200690067006800740000094c00650066007400000f46006f007200770061007200640000114200610063006b00770061007200640000094a0075006d007000000f4a006f0079004a0075006d007000006d440065007300630065006e006400200063006c006f0073006500200074006f0020007400680065002000670072006f0075006e00640020006200650066006f007200650020007000720065007300730069006e00670020004700200074006f0020006c0061006e0064002e00000d410074007400610063006b0000134a006f007900410074007400610063006b00001f5300650063006f006e006400610072007900410074007400610063006b0000254a006f0079005300650063006f006e006400610072007900410074007400610063006b00000b42006c006f0063006b0000114a006f00790042006c006f0063006b000007520075006e00000d4a006f007900520075006e000007550073006500000d4a006f007900550073006500002f20007300740061007200730029002e00200045006e0065006d00790020006800650061006c00740068003a002000000720002f00200000132e00200057006500610070006f006e00200000032f0000053a00200000332e00200047007200650065006e00200070006c006100790065007200200061006c006c0065006700690061006e0063006500005f2e00200052006500640020006d006f006e007300740065007200200061006c006c0065006700690061006e0063006500200028006300720065006100740075007200650073002000690067006e006f0072006500200079006f0075002900003b2e0020004400750065006c0020004f00460046003a0020006e0061007400690076006500200074006100720067006500740069006e0067002e00006d2e0020004400750065006c0020004f004e003a002000610074007400610063006b0073002000630061006e002000680069007400200066007200690065006e0064006c00790020006300720065006100740075007200650073002f0070006c00610079006500720073002e0000312e0020004d006f006e007300740065007200200069006d006d006f007200740061006c0069007400790020004f004e0000572000530070006100630065003a002000740061006b00650020006f00660066002f0072006900730065003b0020004c0065006600740020004300740072006c003a002000640065007300630065006e0064003b002000002b47003a0020006c0061006e00640020006e006500610072002000670072006f0075006e0064003b002000003f55007300650020006300790063006c00650073002000610074007400610063006b0073003b002000460038002000720065007400750072006e0073002e0000808f50006c006100790065007200200072006500730074006f0072006500640020007700690074006800200069006e00760065006e0074006f0072007900200069006e0074006100630074002e0020004200720069006500660020006c0061006e00640069006e0067002000700072006f00740065006300740069006f006e0020006100630074006900760065002e000080bb520065007400750072006e0069006e006700200073006100660065006c007900200074006f0020007400680065002000730065006c00650063007400650064002000720065007400750072006e00200070006f0069006e0074003b002000770061006900740069006e006700200066006f00720020006e00610074006900760065002000740065006c00650070006f00720074002f007400650072007200610069006e0020006c006f006100640069006e0067002e002e002e000080bb470061006d00650020006400650063006c0069006e00650064002000720065007400750072006e002000740065006c00650070006f00720074002e00200050006c006100790065007200200072006500730074006f0072006500640020006100740020007400680065002000630075007200720065006e007400200070006f0073006900740069006f006e0020007700690074006800200069006e00760065006e0074006f0072007900200069006e0074006100630074002e000013470072006500790064007700610072006600001153006b0065006c00650074006f006e00000d440072006100750067007200000957006f006c006600000b540072006f006c006c00000f530065007200700065006e007400001147007200650079006c0069006e00670000094e00650063006b00001f4700720065007900640077006100720066005f0045006c0069007400650000214700720065007900640077006100720066005f005300680061006d0061006e0000194400720061007500670072005f0045006c00690074006500001b4400720061007500670072005f00520061006e00670065006400001f53006b0065006c00650074006f006e005f0050006f00690073006f006e00000942006c006f006200001342006c006f00620045006c00690074006500001153007500720074006c0069006e006700000f460065006e00720069006e006700001f460065006e00720069006e0067005f00430075006c007400690073007400000d47006f0062006c0069006e00001747006f0062006c0069006e0042007200750074006500001947006f0062006c0069006e005300680061006d0061006e0000074c006f00780000175300650065006b0065007200420072006f006f00640000175300650065006b0065007200420072007500740065000017410062006f006d0069006e006100740069006f006e00000f410073006b007300760069006e000013480061007400630068006c0069006e006700000d44007200610067006f006e000015530074006f006e00650047006f006c0065006d00000d5300650065006b006500720000095400690063006b00000d4d006f007200670065006e00000f42006c006f006200540061007200001142006c006f0062004c00610076006100000f4400760065007200670065007200001f44007600650072006700650072004d006100670065004600690072006500001d44007600650072006700650072004d00610067006500490063006500002544007600650072006700650072004d0061006700650053007500700070006f0072007400001b43006800610072007200650064005f004d0065006c0065006500001d43006800610072007200650064005f00410072006300680065007200001943006800610072007200650064005f004d00610067006500002143006800610072007200650064005f0054007700690074006300680065007200000f450069006b007400680079007200000f670064005f006b0069006e006700001142006f006e0065006d00610073007300001547006f0062006c0069006e004b0069006e00670000175300650065006b006500720051007500650065006e00000b46006100640065007200000f6d005f007300700065006500640000176d005f00770061006c006b005300700065006500640000156d005f00720075006e0053007000650065006400001b6d005f00630072006f007500630068005300700065006500640000176d005f007300770069006d0053007000650065006400001d6d005f0066006c00790053006c006f00770053007000650065006400001d6d005f0066006c00790046006100730074005300700065006500640000176d005f006a0075006d00700046006f00720063006500001f4d0065006d00620065007200770069007300650043006c006f006e00650000216d005f006d006100780041006900720041006c0074006900740075006400650000176d005f00660061006c006c00540069006d0065007200002552006500730065007400470072006f0075006e00640043006f006e00740061006300740000156d005f00640069007300740061006e0063006500001b6d005f006d0069006e00440069007300740061006e0063006500001b6d005f006d0061007800440069007300740061006e006300650000216d005f0066006c00790069006e006700440069007300740061006e006300650000336d005f007000750062006c00690063005200650066006500720065006e006300650050006f0073006900740069006f006e00000d6d005f006800750064007300001b6d005f0073006d0061006c006c004d00610072006b0065007200001b6d005f006c0061007200670065004d00610072006b006500720000236d005f0073006d0061006c006c0053006800690070004d00610072006b006500720000236d005f006c00610072006700650053006800690070004d00610072006b00650072000000008582f9ae3cc7ab49b74174e31585d9f30008b77a5c561934e0890306110d043400000002060802060e0306121102060202060c0306120c03061215030612190700030112110808050002010808060003010808080300000805000102121d050002010c0c03000001070002011221121d05000102121105000101122505000101122903061d0e0306122d030612310306123503061239080615123d02124102080615123d021245020706151249011251080615123d02125502090615123d0212211d0207061512490112210306115904061d121903061d0c0306115d030611610306126502060a0320000c0320000205200102121d0320000103061229052001011229072002020c101169080615123d02126d0c070615124901126d030612710306127505200101122d05200201080805200101122104200102020328000c030800080420010108042001010e06000102128089070002021215121507000202121912190307010203070108090002021280891280890500020c0c0c042001010c0407020202040001020c05070212250204200012250320000e0500020e0e0e042000122d06000101128089053001001e00040a01120c0800011280a51180a907200212150e110d07200212190e110d0307010c04000012650320000a0520001280ad042000115d052002011c1c0620021c1c1d1c050001081d0e050702081d0e0520001280a5090002021280a51280a50420011c1c050703080c02040000115d080002115d115d115d0f000602115d115d1011690c081180c1040a01126d0615124901126d0520010113000715123d02126d0c0520010213000720020113001301050702126d02040a01127104200012750520020e080e042001010205200201080e0500001280cd0500001280d1042001021c16070a1280cd0e12191280a11280d11280d51c021d0e080b2000151180d9021300130108151180d902126d0c0b2000151180dd021300130108151180dd02126d0c04200013000420001301092000151180e501130007151180e501126d1c0705151180dd02126d0c126d151180d902126d0c02151180e501126d0500001280ed052001122d0e040a011231050a011280f1040a011235040a01123904061280ad0420001161070002115d115d0c0b1001031e001e00115d1161040a01122d063001001d1e00050a011280f50300000c0600030e0e0e0e0f0706122d12711280f5021d1280f508061512490112510520001280fd08200015124901125107151180e501125104061281010306125504200012510320000804200012550715123d021255020520010813000520011300080620020212510205200101115d0500010e1d1c170709125112510812511281010202151180e50112511d1c073001011d1e0002040a0112410715123d02124102040a0112450715123d021245020e0706124112451d124108021d12450300000205000012811d08151180d90212550208151180dd02125502061512490112210815123d0212211d0209151180d90212211d0209151180dd0212211d0207151180e50112212e0707151180dd02125502151180dd0212211d021221151180d90212550202151180d90212211d02151180e50112210607040c0c0802050702021d02050702116902090706080808125102020600010211812505000011812d040001020e06200201115d0c06200202121d02040001080c19070f02115d115d11812d0c0c115d020211690202115d021d1c08151180d90212410208151180dd0212410208151180d90212450208151180dd0212450237070908151180dd0212211d0202151180dd02124102151180dd0212450202151180d90212211d02151180d902124102151180d90212450208200302115d1161020407011d0e0801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f777301388a000000000000000000004e8a0000002000000000000000000000000000000000000000000000408a00000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058a00000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001800010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0045006e0065006d00790046006f0072006d005600310032002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800180001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0045006e0065006d00790046006f0072006d005600310032002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000c000000603a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper,enemyWindow,formList,enemyStars,monsterOption,duelOption,immortalOption,defeatOption,exitOption,enemyStatus
local closed=false

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','EnemyFormV12')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_EnemyFormV12_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=enemyHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write enemy-form helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Enemy-form helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','EnemyFormV12'),'Enemy-form helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18,8,8},1),
    options=matchingMethod(class,'SetOptions',{8,8},1),
    safety=matchingMethod(class,'SetSafety',{8,8,8},1),safeState=matchingMethod(class,'SafetyState',{},8),
    damage=matchingMethod(class,'BlockDamage',{18},2),death=matchingMethod(class,'BlockDeath',{18},2),
    movement=matchingMethod(class,'SetMovement',{12,12},1),
    cycle=matchingMethod(class,'NextWeapon',{},1),
    projectile=matchingMethod(class,'TuneProjectile',{18,18},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18},1)}
  return helper
end
local function stopEnemy()
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    if not s.stopping then invoke(s.helper.disable,0,{});s.stopping=true end
    if invoke(s.helper.safeState,0,{})~=0 then
      ValheimEnemyReturnPending=s
      if watch then watch.Enabled=true end
      if not closed then enemyButton.Caption='Enemy form: returning...' end
      return
    end
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove enemy-form hook: '..tostring(err));s.info=nil
    end
  end
  if ValheimEnemyReturnPending==s then ValheimEnemyReturnPending=nil end
  state=nil
  if watch then watch.Enabled=false;if closed then watch.destroy() end end
  if not closed then enemyButton.Caption='Enemy form...' end
end
ValheimEnemyFormStop=stopEnemy
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopEnemy();if enemyWindow then enemyWindow.hide() end;return close() end
form.OnDestroy=function() closed=true;stopEnemy();if enemyWindow then enemyWindow.destroy();enemyWindow=nil end;destroy() end
enemyMovementChanged=function(speed,jump)
  if state and playerIdentity(state) then
    invoke(state.helper.movement,0,{{type=vtSingle,value=speed},{type=vtSingle,value=jump}})
  end
end
local function applyEnemyOptions(h)
  invoke(h.safety,0,{{type=vtDword,value=immortalOption.Checked and 1 or 0},{type=vtDword,value=defeatOption.Checked and 1 or 0},{type=vtDword,value=exitOption.Checked and 1 or 0}})
  invoke(h.options,0,{{type=vtDword,value=monsterOption.Checked and 1 or 0},{type=vtDword,value=duelOption.Checked and 1 or 0}})
end
local function startEnemy()
  if ValheimEnemyReturnPending and ValheimEnemyReturnPending.pid==getOpenedProcessID() then enemyStatus.Caption='Previous return is still finishing. Unpause Valheim and wait.';return end
  if state then enemyStatus.Caption='Return to your player and unpause before choosing another form.';return end
  local ok,err=pcall(function()
    local choice=formList.ItemIndex+1
    assert(choice>=1 and choice<=48,'Select an enemy form from the list.')
    local s=playerContext()
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','GameCamera'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'LateUpdate',{},1)),'Player update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Enemy-form callback')
    local hookedEntries={}
    local function makeHook(entry,target,label,skip)
    assert(not hookedEntries[entry],'Native enemy hook methods share an entry');hookedEntries[entry]=true
    -- No nearby allocation: both callback and return use local pointer slots,
    -- preserving registers even when the trampoline is more than 2 GB away.
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode enemy hook prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local bytes=readBytes(entry,size,true)
    assert(bytes and #bytes==size,'Cannot read enemy hook prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    local script=string.format([[
[ENABLE]
assert(%X,%s)
alloc(vhEnemyForm,4096)
label(vhEnemyFormRestore)
label(vhEnemyFormCallback)
label(vhEnemyFormReturn)
vhEnemyForm:
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
jne vhEnemyFormRestore
// RCX/RDX preserve the original instance/owner arguments for each callback.
call qword ptr [vhEnemyFormCallback]
vhEnemyFormRestore:
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
%s
jmp qword ptr [vhEnemyFormReturn]
vhEnemyFormCallback:
dq %X
vhEnemyFormReturn:
dq %X
%X:
db FF 25 00 00 00 00
dq vhEnemyForm
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,s.storage,s.player,table.concat(replay,'\n'),target,entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    if skip then
      local restore=assert(script:match('vhEnemyFormRestore:\n(.-)lea rsp,%[rsp%+D8%]\n'),'Guard restore block missing')
      script=script:gsub('label%(vhEnemyFormRestore%)','label(vhEnemyFormRestore)\nlabel(vhEnemyFormSkip)',1)
      script=script:gsub('sub rsp,D8\n','sub rsp,D8\nmov byte ptr [rsp+C0],0\n',1)
      script=script:gsub('call qword ptr %[vhEnemyFormCallback%]\n','call qword ptr [vhEnemyFormCallback]\nmov [rsp+C0],al\n',1)
      script=script:gsub('vhEnemyFormRestore:\n','vhEnemyFormRestore:\ncmp byte ptr [rsp+C0],0\njne vhEnemyFormSkip\n',1)
      script=script:gsub('vhEnemyFormCallback:\n','vhEnemyFormSkip:\n'..restore..'lea rsp,[rsp+D8]\nret\nvhEnemyFormCallback:\n',1)
    end
    script=script:gsub('vhEnemyForm',label)
    local enabled,disabled=script:match('%[ENABLE%](.-)%[DISABLE%](.*)')
    assert(enabled and disabled,'Enemy hook sections unavailable')
    return enabled,disabled
    end
    local cameraEnable,cameraDisable=makeHook(entry,target,'vhEnemyForm')
    local projectileClass=pointer(mono_findClass('','Projectile'),'Projectile class')
    local projectileEntry=pointer(mono_compile_method(matchingMethod(projectileClass,'Setup',{18,17,12,18,18,18},1)),'Projectile setup code')
    local projectileTarget=pointer(mono_compile_method(s.helper.projectile),'Enemy projectile callback')
    local projectileEnable,projectileDisable=makeHook(projectileEntry,projectileTarget,'vhEnemyProjectile')
    local character=pointer(mono_findClass('','Character'),'Character class')
    local damageEntry=pointer(mono_compile_method(matchingMethod(character,'ApplyDamage',{18,2,2,17},1)),'Character damage code')
    local deathEntry=pointer(mono_compile_method(matchingMethod(character,'CheckDeath',{},1)),'Character death code')
    local damageEnable,damageDisable=makeHook(damageEntry,pointer(mono_compile_method(s.helper.damage),'Damage guard callback'),'vhEnemyDamage',true)
    local deathEnable,deathDisable=makeHook(deathEntry,pointer(mono_compile_method(s.helper.death),'Death guard callback'),'vhEnemyDeath',true)
    s.script='[ENABLE]\n'..cameraEnable..projectileEnable..damageEnable..deathEnable..'[DISABLE]\n'..cameraDisable..projectileDisable..damageDisable..deathDisable
    assert(playerIdentity(s),'Player changed before enabling enemy form')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Enemy-form hook installation failed: '..tostring(info))
    s.info=info
    local movement=movementState and playerIdentity(movementState) and movementState or nil
    enemyMovementChanged(movement and movement.speed or 1,movement and movement.jump or 1)
    applyEnemyOptions(s.helper)
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player},{type=vtDword,value=choice-1},{type=vtDword,value=enemyStars.ItemIndex}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Enemy-form helper did not enable')
    if not watch then
      watch=createTimer(nil,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          local sf=field(state.helper.class,'Status');local address=sf.staticAddress
          if not address or address<=sf.offset then address=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+sf.offset end
          local p=readPointer(address)
          if not closed and p and p~=0 then playerStatus.Caption=stringValue(p);hint(playerStatus,playerStatus.Caption);if enemyStatus then enemyStatus.Caption=playerStatus.Caption end end
          if state.stopping or readInteger(state.enabled)~=1 then stopEnemy() end
        end)
        if not active then
          local stopped,stopError=pcall(stopEnemy)
          if not closed then playerStatus.Caption='Enemy form stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
          if enemyStatus then enemyStatus.Caption=playerStatus.Caption end end
        end
      end
    end
    watch.Enabled=true;enemyButton.Caption='Enemy form: ON'
    playerStatus.Caption='Return to Valheim and unpause to transform. Attack = native attack; Block = secondary; Use cycles weapons; F8 returns. Flyers: Space rises, Left Ctrl descends; Moder: G lands near ground.'
    enemyStatus.Caption=playerStatus.Caption
  end)
  if not ok then
    local stopped,stopError=pcall(stopEnemy)
    showMessage('Valheim enemy form: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
enemyButton.OnClick=function()
  if enemyWindow then enemyWindow.show();return end
  enemyWindow=createForm(false);enemyWindow.Caption='Valheim | Enemy transformation';enemyWindow.Width=720;enemyWindow.Height=760;enemyWindow.Position='poScreenCenter'
  enemyWindow.Color=0x202020;enemyWindow.Font.Color=0xE6E6E6
  local help=createLabel(enemyWindow);help.Left=18;help.Top=14;help.Width=670;help.Height=66;help.AutoSize=false;help.WordWrap=true
  help.Caption='Choose a form and stars, set allegiance and duel options, then click Transform. Return to Valheim and unpause. Sea Serpent needs deep water. Drake/Moder: Space rises, Left Ctrl descends; Moder: G lands near ground. Large creatures need open space.'
  formList=createListBox(enemyWindow);formList.Left=18;formList.Top=80;formList.Width=290;formList.Height=360
  local names={'Greydwarf','Skeleton','Draugr','Wolf','Troll','Sea Serpent','Greyling','Neck','Greydwarf Brute','Greydwarf Shaman','Draugr Elite','Draugr Archer','Rancid Remains','Blob','Oozer','Surtling','Fenring','Cultist','Fuling','Fuling Berserker','Fuling Shaman','Lox','Seeker Brood','Seeker Soldier','Abomination','Asksvin','Drake','Moder (dragon)','Stone Golem','Seeker','Tick','Morgen','Growth (tar blob)','Lava Blob','Dvergr rogue','Dvergr fire mage','Dvergr ice mage','Dvergr support mage','Charred Warrior','Charred Marksman','Charred Warlock','Charred Twitcher','Eikthyr','The Elder','Bonemass','Yagluth','The Queen','Fader'}
  for i,name in ipairs(names) do formList.Items.add(i..'  '..name) end
  formList.ItemIndex=0
  local starLabel=createLabel(enemyWindow);starLabel.Left=18;starLabel.Top=448;starLabel.Caption='Form stars (choose before transforming)'
  enemyStars=createComboBox(enemyWindow);enemyStars.Left=18;enemyStars.Top=472;enemyStars.Width=290;enemyStars.Style='csDropDownList'
  for _,label in ipairs({'0 stars (normal)','1 star','2 stars'}) do enemyStars.Items.add(label) end
  enemyStars.ItemIndex=0
  monsterOption=createCheckBox(enemyWindow);monsterOption.Left=328;monsterOption.Top=82;monsterOption.Width=365;monsterOption.Height=30;monsterOption.Caption='Red monster allegiance';monsterOption.Checked=false
  local allegianceHelp=createLabel(enemyWindow);allegianceHelp.Left=328;allegianceHelp.Top=118;allegianceHelp.Width=355;allegianceHelp.Height=75;allegianceHelp.AutoSize=false;allegianceHelp.WordWrap=true
  allegianceHelp.Caption='Unchecked: green / player faction. Checked: red / native monster faction. Local creature AI ignores you; other clients use native faction rules. Red attacks can hurt players with PvP off.'
  duelOption=createCheckBox(enemyWindow);duelOption.Left=328;duelOption.Top=204;duelOption.Width=355;duelOption.Height=30;duelOption.Caption='Monster duel / friendly hits';duelOption.Checked=false
  local duelHelp=createLabel(enemyWindow);duelHelp.Left=328;duelHelp.Top=240;duelHelp.Width=355;duelHelp.Height=95;duelHelp.AutoSize=false;duelHelp.WordWrap=true
  duelHelp.Caption='Enables hits against allies, including the same monster form. Creature attacks use native damage with PvP off. This can also hurt nearby players and pets. Both duelists transform; each enables this option. Multiplayer needs an in-game check.'
  immortalOption=createCheckBox(enemyWindow);immortalOption.Left=328;immortalOption.Top=340;immortalOption.Width=355;immortalOption.Caption='Immortal monster';immortalOption.Checked=false
  defeatOption=createCheckBox(enemyWindow);defeatOption.Left=328;defeatOption.Top=372;defeatOption.Width=355;defeatOption.Caption='Return to start on monster defeat';defeatOption.Checked=true
  exitOption=createCheckBox(enemyWindow);exitOption.Left=328;exitOption.Top=404;exitOption.Width=355;exitOption.Caption='F8 returns to transformation point';exitOption.Checked=false
  local safetyHelp=createLabel(enemyWindow);safetyHelp.Left=328;safetyHelp.Top=438;safetyHelp.Width=355;safetyHelp.Height=54;safetyHelp.AutoSize=false;safetyHelp.WordWrap=true
  safetyHelp.Caption='Your hidden player is protected. Monster defeat restores your player and inventory without a player tombstone. Origin return uses native teleport/loading.'
  local function optionsChanged()
    if not state then return end
    local ok,err=pcall(function() assert(playerIdentity(state),'Player changed or world unloaded');applyEnemyOptions(state.helper) end)
    if not ok then showMessage('Enemy form settings: '..tostring(err)) else enemyStatus.Caption='Settings queued. Return to Valheim and unpause to apply.' end
  end
  monsterOption.OnChange=optionsChanged;duelOption.OnChange=optionsChanged
  immortalOption.OnChange=optionsChanged;defeatOption.OnChange=optionsChanged;exitOption.OnChange=optionsChanged
  local function button(caption,y,fn)
    local b=createButton(enemyWindow);b.Caption=caption;b.Left=328;b.Top=y;b.Width=355;b.Height=36;b.OnClick=fn;if styleToggle then styleToggle(b) end;return b
  end
  button('Transform into selected form',500,startEnemy)
  button('Cycle native weapon',544,function()
    local ok,err=pcall(function() assert(state and playerIdentity(state),'Transform first.');invoke(state.helper.cycle,0,{}) end)
    if not ok then showMessage(tostring(err)) end
  end)
  button('Return to player (F8)',588,function()
    local ok,err=pcall(stopEnemy)
    enemyStatus.Caption=ok and 'Return queued. Unpause Valheim to restore your player before transforming again.' or tostring(err)
  end)
  enemyStatus=createLabel(enemyWindow);enemyStatus.Left=18;enemyStatus.Top=650;enemyStatus.Width=665;enemyStatus.Height=66;enemyStatus.AutoSize=false;enemyStatus.WordWrap=true
  enemyStatus.Caption='Speed applies to ground and flight. Drake/Moder: Space rises, Left Ctrl descends; Moder: G lands. F8 returns safely to ground. Settings can change while transformed. F8 returns to your player.'
  enemyWindow.OnClose=function() return caHide end
  enemyWindow.show()
end
end)()

-- Retry only the initial load, quietly; do not overwrite selections after success.
do
  if ValheimAutoLoadStop then pcall(ValheimAutoLoadStop) end
  local retry=createTimer(form,false);retry.Interval=3000
  local loaded,busy,closed=false,false,false
  local function attempt()
    if loaded or busy or closed then return end
    busy=true
    retry.Enabled=false
    local ok,err=pcall(function()
      local pid=getProcessIDFromProcessName('valheim.exe')
      assert(pid and pid~=0,'Valheim is not running yet.')
      refreshInventory()
    end)
    busy=false
    if ok then
      loaded=true
      hint(status,'Inventory loaded. Use the green Refresh button to reload it anytime.')
    else
      status.Caption='Waiting for Valheim / loaded world. Retrying every 3 seconds...'
      hint(status,'Last connection attempt: '..tostring(err))
      retry.Enabled=not closed
    end
  end
  ValheimAutoLoadStop=function() closed=true;retry.Enabled=false end
  retry.OnTimer=attempt
  local manual=refresh.OnClick
  refresh.OnClick=function()
    if busy then return end
    if manual() then loaded=true;retry.Enabled=false end
  end
  local close,destroy,show=form.OnClose,form.OnDestroy,form.OnShow
  form.OnClose=function() ValheimAutoLoadStop();return close() end
  form.OnDestroy=function() ValheimAutoLoadStop();destroy() end
  form.OnShow=function()
    closed=false
    if show then show() end
    attempt()
  end
  form.show()
  attempt()
end

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
-- Resource checks/costs are local-player-only. Ordinary damage still uses native damage paths.
do
local active
local summonHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c0103007490d56a0000000000000000e00002210b010b00001000000006000000000000ae2f00000020000000400000000000100020000000020000040000000000000004000000000000000080000000020000000000000300408500001000001000000000100000100000000000001000000000000000000000005c2f00004f00000000400000e802000000000000000000000000000000000000006000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000b40f0000002000000010000000020000000000000000000000000000200000602e72737263000000e8020000004000000004000000120000000000000000000000000000400000402e72656c6f6300000c0000000060000000020000001600000000000000000000000000004000004200000000000000000000000000000000902f0000000000004800000002000500b4240000a80a0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013300300b200000001000011007e0500000414280300000a2d2a7e0600000414280300000a2d1d7e0700000414280300000a2d107e0800000414280400000a16fe012b0116000b072d0b7201000070730500000a7a7e070000046f0600000a6f0700000a0a068e6917fe010b072d0b7245000070730800000a7a06169a72870000701f346f0900000a80090000047e0900000414280300000a16fe010b072d0b729f000070730500000a7a0280040000041480030000041780020000042a3a001680020000041480040000042a000000133002004200000002000011007e0200000417333202280a00000a2c2a7e04000004280a00000a2c1e027e04000004280b00000a2c117e040000047e0c00000a280b00000a2b0116000a2b00062a00001b30030071000000030000110002280a00000a2c080328030000062b0116000c082d022b57140a00026f0100002b0a06280a00000a0c082d0c026f0e00000a6f0200002b0a0602036f060000060000de2a0b00076f1000000a800300000428020000060006280a00000a16fe010c082d07066f070000060000de00002a0000000110000000001b002a45002a11000001033003006d00000000000000d008000001281100000a72d90000701f346f0900000a8005000004d008000001281100000a72f30000701f346f0900000a8006000004d008000001281100000a72350100701f346f0900000a8007000004d001000001281100000a72590100701f34281200000a80080000042a0000001b300300550100000400001100027b0e00000416fe01130411042d05383f01000002037d0a00000402047d0b000004027e05000004036f1300000aa5130000017d0c000004027e06000004036f1300000aa5140000017d0d000004027e07000004036f1300000a7d0f000004027b0f00000475150000010a062c12066f1400000a281500000a74150000012b0114000b0614fe01130411043a8100000000066f1600000a13052b4911056f1700000a0c000814fe0116fe01130411042d0b0007146f1800000a262b287e0800000408146f1900000a0d7e0900000409168c130000016f1a00000a0007096f1800000a260011056f1b00000a130411042daade1d1105751a0000011306110614fe01130411042d0811066f1c00000a00dc0002177d0e0000047e0500000403168c130000016f1a00000a007e0600000403168c140000016f1a00000a000714fe01130411042d0d7e0700000403076f1a00000a002a0000000110000002009a005af4001d0000000013300300780000000200001100027b0e0000040a062d022b6a027b0a000004280a00000a16fe010a062d51007e05000004027b0a000004027b0c0000048c130000016f1a00000a007e06000004027b0a000004027b0d0000048c140000016f1a00000a007e07000004027b0a000004027b0f0000046f1a00000a000002167d0e0000042a13300100210000000200001100027b0b00000428030000060a062d10000228070000060002281d00000a00002a2600022807000006002a1e02281e00000a2a0042534a4201000100000000000c00000076342e302e33303331390000000005006c00000050030000237e0000bc0300003004000023537472696e677300000000ec0700007c0100002355530068090000100000002347554944000000780900003001000023426c6f620000000000000002000001571d02000908000000fa253300160000010000001a000000030000000f0000000a000000060000001e00000001000000020000000400000001000000030000000200000000000a00010000000000060076006f000a00a00094000600c000ae000e00f600000006000301ae0006002801ae000e00580100000e006701000006000002e00106002002e001060064026f0006007a026f000600a1026f000a00760094000a00de0294000a00f502940006001c036f00060039036f00060070036f00060076036f00060091037e0306009f036f000600b8037e030600c4037e030600ee03ae00060012046f0000000000010000000000010001008101100028003b00050001000100010110004e003b0009000a0006005180cd000a001600d30013001600db0016001100fd00190033000d011d00330015011d00330021011d00330033012100130039011d0001007c013d0001008401410001008b01130001009301450001009f0145000100a701480050200000000096004601250001000e2100000000960050012b000200202100000000930062012f0002007021000000009600740135000300002200000000911832032b0005007c22000000008600ae014b000500f023000000008600b401530007007424000000008100bc0153000700a124000000008100c30153000700ab24000000008618cd015300070000000100d301000001008401000001007c0100000200840100000100da0100000200fd004900cd0157005100cd015300290058025c003100580264005900cd016c0029007f02710061008d0276006900cd016c006100bb027c007100c4028b007100580291002100d00219007900e8029d0079000003a80081000f039d0089002603ad0061004b03b90061005d03c00029006703c800090097037100b100a903cd00b900d003d300c100de03d800a900ea03dc00c900f903e10029000004e800c1000904ee00d1001e0453007100260400011100cd015300080004000e002e000b0006012e0013000f0184009900b100f2000480000000000000000000000000000000003e020000040000000000000000000000010066000000000000000000000000000000000000007d00000000000000000000000000000000000000e500000000001b00a3001f00a3000000003c4d6f64756c653e0056616c6865696d556e6c696d6974656453756d6d6f6e7356312e646c6c00556e6c696d6974656453756d6d6f6e7356310056616c6865696d536f6c6f546f6f6c6b697400556e6c696d6974656453756d6d6f6e7353746174655631006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f75720053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c61677300456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e6572004669656c64496e666f004d6178696d756d0046726f6d5175616c697479004c6576656c73004d6574686f64496e666f00436c6f6e65004c6576656c4d6178696d756d00436f6e6669677572650044697361626c6500436861726163746572004f776e7300537061776e4162696c697479004f6e5365747570006162696c69747900636173746572006d6178696d756d0066726f6d5175616c697479006170706c696564006c6576656c73004170706c790052656c6561736500557064617465004f6e44657374726f79002e63746f7200706c617965720076616c75650053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d556e6c696d6974656453756d6d6f6e735631006f705f457175616c697479004d697373696e674669656c64457863657074696f6e0054797065006765745f4669656c64547970650047657447656e65726963417267756d656e747300496e76616c69644f7065726174696f6e457863657074696f6e004765744669656c64006f705f496d706c69636974006d5f6c6f63616c506c6179657200436f6d706f6e656e7400476574436f6d706f6e656e740047616d654f626a656374006765745f67616d654f626a65637400416464436f6d706f6e656e7400457863657074696f6e006765745f4d657373616765002e6363746f720052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744d6574686f640047657456616c756500496e74333200426f6f6c65616e0053797374656d2e436f6c6c656374696f6e7300494c697374004765745479706500416374697661746f7200437265617465496e7374616e63650049456e756d657261626c650049456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e7400416464004d6574686f644261736500496e766f6b650053657456616c7565004d6f76654e6578740049446973706f7361626c6500446973706f73650044657374726f790000000043530075006d006d006f006e002d0063006f006e00740072006f006c0020006600690065006c0064007300200075006e0061007600610069006c00610062006c006500014155006e00650078007000650063007400650064002000730075006d006d006f006e0020006c006500760065006c002000730065007400740069006e006700730000176d005f006d006100780053007000610077006e0073000039530075006d006d006f006e0020006c006500760065006c002000630061007000200075006e0061007600610069006c00610062006c00650000196d005f006d006100780053007000610077006e006500640000416d005f007300650074004d006100780049006e007300740061006e00630065007300460072006f006d0057006500610070006f006e004c006500760065006c0000236d005f006c006500760065006c0055007000530065007400740069006e0067007300001f4d0065006d00620065007200770069007300650043006c006f006e00650000000000d0a8c588cc5f7d429ab624e402530cee0008b77a5c561934e0890306110d043400000002060802060e0306121103061215030612190500010112110300000105000102121d070002011221121d030612210306121d02060202061c072002011221121d03200001042001010807000202121512150700020212191219042001010e04200012310520001d123107200212150e110d0607021d123102050001021239070002021239123903070102053001001e00040a01120c04200012410320000e070703120c1245020600011231114907200212190e110d0420011c1c0500011c123104200012610320001c042001081c0620021c1c1d1c052002011c1c032000020d0707125512551c1c02126112690500010112390801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773010000842f000000000000000000009e2f0000002000000000000000000000000000000000000000000000902f0000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff250020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001000000018000080000000000000000000000000000001000100000030000080000000000000000000000000000001000000000048000000584000008c02000000000000000000008c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004ec010000010053007400720069006e006700460069006c00650049006e0066006f000000c801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000005c001e00010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0055006e006c0069006d006900740065006400530075006d006d006f006e007300560031002e0064006c006c0000002800020001004c006500670061006c0043006f00700079007200690067006800740000002000000064001e0001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0055006e006c0069006d006900740065006400530075006d006d006f006e007300560031002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000c000000b03f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local summonHelper
local function loadSummonHelper()
  if summonHelper and summonHelper.pid==session then return summonHelper end
  local class=mono_findClass('ValheimSoloToolkit','UnlimitedSummonsV1')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP');assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_UnlimitedSummonsV1_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=summonHelperHex:gsub('%x%x',function(v)return string.char(tonumber(v,16))end)
    local file=assert(io.open(path,'wb'),'Cannot write summon helper');local written,err=file:write(binary);file:close();assert(written,err)
    local assembly=mono_loadAssemblyFromFile(path);os.remove(path)
    assembly=pointer(assembly,'Summon helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','UnlimitedSummonsV1'),'Summon helper class')
  end
  summonHelper={pid=session,class=class,configure=matchingMethod(class,'Configure',{18},1),disable=matchingMethod(class,'Disable',{},1),setup=matchingMethod(class,'OnSetup',{18,18},1)}
  return summonHelper
end
local function appendSummonHook(s,enable,disable,restore,entries)
  s.summonHelper=loadSummonHelper()
  local ef=field(s.summonHelper.class,'Enabled');assert(ef.isStatic and ef.typename=='System.Int32','Unexpected summon helper state')
  s.summonEnabled=ef.staticAddress
  if not s.summonEnabled or s.summonEnabled<=ef.offset then s.summonEnabled=pointer(mono_class_getStaticFieldAddress(s.summonHelper.class),'Summon helper storage')+ef.offset end
  local class=pointer(mono_findClass('','SpawnAbility'),'Spawn ability class')
  local method=matchingMethod(class,'Setup',{18,17,12,18,18,18},1)
  local entry=pointer(mono_compile_method(method),'Summon setup code')
  local target=pointer(mono_compile_method(s.summonHelper.setup),'Summon helper callback')
  for _,e in ipairs(entries)do assert(e.entry~=entry,'Summon setup aliases another resource method')end
  local size,replay=0,{}
  while size<14 do
    local n=getInstructionSize(entry+size);assert(n and n>0 and n<=15,'Cannot decode summon setup prologue')
    replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
  end
  local jit=mono_getJitInfo(entry);assert(jit and jit.code_start==entry and jit.code_size>=size,'Summon setup method too short to patch')
  local bytes=readBytes(entry,size,true);assert(bytes and #bytes==size,'Cannot read summon setup code')
  local hex={};for _,b in ipairs(bytes)do hex[#hex+1]=string.format('%02X',b)end
  local original=table.concat(hex,' ')
  enable[#enable+1]=string.format([[
assert(%X,%s)
alloc(vhResourceSummons,4096,%X)
label(vhResourceSummonsRestore)
vhResourceSummons:
pushfq
sub rsp,D0
mov [rsp+20],rax
mov [rsp+28],rcx
mov [rsp+30],rdx
mov [rsp+38],r8
mov [rsp+40],r9
mov [rsp+48],r10
mov [rsp+50],r11
movdqu [rsp+60],xmm0
movdqu [rsp+70],xmm1
movdqu [rsp+80],xmm2
movdqu [rsp+90],xmm3
movdqu [rsp+A0],xmm4
movdqu [rsp+B0],xmm5
// RCX = this cast, RDX = caster. Leave native vector/float/reference arguments intact.
mov rax,%X
cmp rdx,rax
jne vhResourceSummonsRestore
mov rax,%X
cmp [rax],rdx
jne vhResourceSummonsRestore
call %X
vhResourceSummonsRestore:
movdqu xmm0,[rsp+60]
movdqu xmm1,[rsp+70]
movdqu xmm2,[rsp+80]
movdqu xmm3,[rsp+90]
movdqu xmm4,[rsp+A0]
movdqu xmm5,[rsp+B0]
push qword ptr [rsp+D0]
popfq
mov rax,[rsp+20]
mov rcx,[rsp+28]
mov rdx,[rsp+30]
mov r8,[rsp+38]
mov r9,[rsp+40]
mov r10,[rsp+48]
mov r11,[rsp+50]
lea rsp,[rsp+D8]
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq vhResourceSummons
%s
]],entry,original,entry,s.player,s.storage,target,table.concat(replay,'\n'),entry+size,entry,size>14 and string.format('nop %X',size-14) or '')
  disable[#disable+1]=string.format('%X:\ndb %s',entry,original)
  restore[#restore+1]=string.format('%X:\ndb %s',entry,original)
end
local watch=createTimer(form,false);watch.Interval=100
local oldLabels=playerLabels
playerLabels=function()
  oldLabels()
  staminaButton.Caption=active and 'Unlimited resources: ON' or 'Unlimited resources: OFF'
end
local function stopResources()
  if active then
    local s=active
    if getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
      local disabled,disableError=pcall(function() if s.summonHelper then invoke(s.summonHelper.disable,0,{}) end end)
      local ok,err
      if s.rollbackOnly then ok,err=autoAssemble(s.restore,false)
      else ok,err=autoAssemble(s.script,false,s.info) end
      assert(ok,'Cannot remove ability resource hooks: '..tostring(err))
      assert(disabled,'Summon helper cleanup failed: '..tostring(disableError))
    end
    active=nil
  end
  watch.Enabled=false;playerLabels()
end
ValheimUnlimitedResourcesStop=stopResources
local function alive(s)
  local value=invoke(s.isDead,s.player,{})
  assert(value==true or value==false or value==0 or value==1,'Unreadable player death state')
  return value==false or value==0
end
local function refill(s)
  assert(playerIdentity(s) and alive(s),'Player changed, died or world unloaded')
  if s.summonHelper then assert(readInteger(s.summonEnabled)==1,'Summon limit helper stopped; disable and re-enable Unlimited resources') end
  local values={}
  for i,pool in ipairs(s.pools) do
    local maximum=pool.getMax and invoke(pool.getMax,s.player,{}) or readFloat(pool.maximum)
    assert(type(maximum)=='number' and maximum==maximum and maximum>=0 and maximum<=1000000,'Invalid maximum '..pool.name)
    values[i]=maximum
  end
  -- Validate all capacities before writing; food maxima themselves are never changed.
  for i,pool in ipairs(s.pools) do
    assert(playerIdentity(s),'Player changed before resource refill')
    assert(writeFloat(pool.address,values[i]),pool.name..' refill failed')
  end
end
local function enableResources()
  local s=playerContext()
  s.isDead=matchingMethod(playerClass,'IsDead',{},2)
  assert(alive(s),'Wait until your player has finished respawning.')
  -- Keep GetAdrenaline native. Detouring a trivial getter through another native
  -- method can disturb Mono callers' register assumptions. Refill the actual pool
  -- and block negative AddAdrenaline costs instead.
  s.maxAdrenaline=matchingMethod(playerClass,'GetMaxAdrenaline',{},12)
  s.pools={}
  for _,name in ipairs({'stamina','eitr','adrenaline'}) do
    local pool={name=name,address=s.player+typedPlayerOffset('m_'..name,'System.Single')}
    if name=='adrenaline' then pool.getMax=s.maxAdrenaline
    else pool.maximum=s.player+typedPlayerOffset(name=='stamina' and 'm_maxStamina' or 'm_maxEitr','System.Single') end
    s.pools[#s.pools+1]=pool
  end
  local character=pointer(mono_findClass('','Character'),'Character class')
  -- No general health getter/setter or damage methods are patched. UseHealth is the
  -- voluntary ability-cost path; blood-magic sufficiency is checked by HaveHealth.
  local definitions={
    {playerClass,'UseStamina',1,'free'}, {playerClass,'HaveStamina',2,'yes'},
    {playerClass,'UseEitr',1,'free'}, {playerClass,'HaveEitr',2,'yes'},
    {character,'TryUseEitr',2,'yes'}, -- includes the no-eitr-food capacity gate
    {character,'UseHealth',1,'free'}, {character,'HaveHealth',2,'yes'},
    {playerClass,'AddAdrenaline',1,'adrenaline'}
  }
  local enable,disable,entries={'[ENABLE]'},{'[DISABLE]'},{}
  local restore={'[ENABLE]','// resource emergency restore'}
  for i,d in ipairs(definitions) do
    local method=matchingMethod(d[1],d[2],{12},d[3])
    local entry=pointer(mono_compile_method(method),d[2]..' code')
    for _,e in ipairs(entries) do assert(e.entry~=entry,'Resource methods share a native entry') end
    local size,replay=0,{}
    while size<14 do
      local n=getInstructionSize(entry+size)
      assert(n and n>0 and n<=15,'Cannot decode '..d[2]..' prologue')
      replay[#replay+1]=string.format('reassemble(%X)',entry+size);size=size+n
    end
    local jit=mono_getJitInfo(entry)
    assert(jit and jit.code_start==entry and jit.code_size>=size,'Resource method too short to patch: '..d[2])
    local bytes=readBytes(entry,size,true);assert(bytes and #bytes==size,'Cannot read resource prologue')
    local hex={};for _,b in ipairs(bytes) do hex[#hex+1]=string.format('%02X',b) end
    local original=table.concat(hex,' ')
    entries[i]={entry=entry}
    local name='vhAbilityResource'..i
    enable[#enable+1]=string.format('assert(%X,%s)\nalloc(%s,2048,%X)\nlabel(%sOriginal)\nlabel(%sPass)',entry,original,name,entry,name,name)
    local result=d[4]=='yes' and 'mov eax,1\nret' or 'ret'
    local extra=''
    if d[4]=='adrenaline' then
      -- Preserve natural adrenaline gains/equipment effects; skip negative spends.
      -- Register comparison has no RIP-relative data address/range limit. Save the
      -- volatile scratch register so the native positive/NaN path sees original state.
      extra=string.format('sub rsp,10\nmovdqu [rsp],xmm0\nxorps xmm0,xmm0\ncomiss xmm1,xmm0\nmovdqu xmm0,[rsp]\nlea rsp,[rsp+10]\njae %sPass\njp %sPass\n',name,name)
    end
    enable[#enable+1]=string.format([[
%s:
pushfq
push rax
mov rax,%X
cmp rcx,rax
jne %sPass
mov rax,%X
cmp [rax],rcx
jne %sPass
%s
pop rax
popfq
%s
%sPass:
pop rax
popfq
%sOriginal:
%s
jmp %X
%X:
db FF 25 00 00 00 00
dq %s
%s
]],name,s.player,name,s.storage,name,extra,result,name,name,table.concat(replay,'\n'),entry+size,entry,name,size>14 and string.format('nop %X',size-14) or '')
    disable[#disable+1]=string.format('%X:\ndb %s',entry,original)
    restore[#restore+1]=string.format('%X:\ndb %s',entry,original)
  end
  appendSummonHook(s,enable,disable,restore,entries)
  s.script=table.concat(enable,'\n')..'\n'..table.concat(disable,'\n')
  assert(playerIdentity(s) and alive(s),'Player changed while preparing resource hooks')
  -- Check the same normalized script that installation will use, before patching
  -- any game method. Keep original bytes for recovery from a runtime write failure.
  local checked,checkError=autoAssembleCheck(s.script,true,false)
  assert(checked,'Ability resource syntax check failed; no hooks installed: '..tostring(checkError))
  s.restore=table.concat(restore,'\n')..'\n[DISABLE]'
  s.rollbackOnly=true;active=s;watch.Enabled=true
  local ran,ok,info=pcall(autoAssemble,s.script,false)
  if not ran or not ok then
    local stopped,stopError=pcall(stopResources)
    error('Ability resource installation failed: '..tostring(ran and info or ok)..
      (stopped and ' Original game code restored.' or (' Recovery pending: '..tostring(stopError))))
  end
  s.info=info;s.rollbackOnly=false
  local filled,err=pcall(function()
    invoke(s.summonHelper.configure,0,{{type=vtPointer,value=s.player}})
    refill(s)
  end)
  if not filled then
    local stopped,stopError=pcall(stopResources)
    error(tostring(err)..(stopped and '' or (' Cleanup failed: '..tostring(stopError))))
  end
  watch.Enabled=true;playerLabels()
  playerStatus.Caption='Unlimited stamina, eitr and adrenaline; ability health costs and summon-control limits bypassed. Works without eitr food. Food maxima and normal incoming damage stay native.'
end
staminaButton.OnClick=function()
  local ok,err=pcall(function()
    if active then stopResources();playerStatus.Caption='Normal ability resource costs restored.' else enableResources() end
  end)
  if not ok then playerLabels();showMessage('Unlimited resources: '..tostring(err)) end
end
watch.OnTimer=function()
  if not active then return end
  if active.rollbackOnly then
    local stopped,err=pcall(stopResources)
    playerStatus.Caption=stopped and 'Failed resource installation recovered; original game code restored.' or ('Resource recovery pending: '..tostring(err))
    return
  end
  local ok,err=pcall(refill,active)
  if not ok then
    local stopped,stopError=pcall(stopResources)
    playerStatus.Caption=stopped and ('Unlimited resources stopped: '..tostring(err)) or ('Resource cleanup failed: '..tostring(stopError))
  end
end
local previousStop=ValheimPlayerCheatsStop
ValheimPlayerCheatsStop=function() stopResources();if previousStop then previousStop() end end
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopResources();return close() end
form.OnDestroy=function() stopResources();destroy() end
hint(staminaButton,'Unlimited stamina, eitr and adrenaline, plus no ability health costs or summon-control cap (Dead raiser). Bypasses resource checks even without eitr food. Normal incoming damage, ammunition, materials and cooldowns remain. Disabling restores costs; refilled pools remain at their normal food/equipment maxima.')
playerLabels()
end
-- Native Windows buttons ignore custom fills. Keep their handlers and state,
-- and present a colored panel that forwards clicks to the original control.
do
local entries={}
local function assign(object,key,value)
  if object[key]~=value then object[key]=value end
end
local function update(entry,redraw)
  local b,p,frame=entry.button,entry.panel,entry.frame
  local caption=b.Caption or ''
  local on=entry.toggle and (caption:match(': ON$')~=nil or caption:match('^Unfreeze')~=nil) or false
  if b==speedButton or b==jumpButton then
    local multiplier=tonumber(caption:match(': ([%d%.]+)x$'))
    on=multiplier~=nil and multiplier~=1
  end
  -- Reassigning Parent on every timer tick can recreate native window handles
  -- and lose child painting after a fullscreen game releases the desktop.
  assign(frame,'Parent',b.Parent)
  for _,key in ipairs({'Left','Top','Width','Height'}) do assign(frame,key,b[key]) end
  local border=entry.warning and 0 or 1
  assign(p,'Left',border);assign(p,'Top',border)
  assign(p,'Width',b.Width-border*2);assign(p,'Height',b.Height-border*2)
  assign(p,'Enabled',b.Enabled~=false)
  assign(p,'Color',on and 0x32852E or 0x373737)
  assign(p.Font,'Color',on and 0xFFFFFF or 0xE6E6E6)
  assign(p,'Caption',(caption:gsub(': ON$',''):gsub(': OFF$','')))
  assign(p,'Hint',b.Hint or '');p.ShowHint=true;p.ParentShowHint=false
  assign(b,'Visible',false);assign(frame,'Visible',true);assign(p,'Visible',true)
  if redraw then
    frame.bringToFront();frame.repaint();p.repaint()
  end
end
styleToggle=function(b,toggle)
  if not b then return end
  for _,entry in ipairs(entries) do if entry.button==b then return end end
  if toggle==nil then toggle=(b.Caption or ''):match(': O[NF]+$')~=nil end
  local warning=b==flightButton or b==craftingButton
  local frame=createPanel(b.Parent);frame.Caption='';frame.BevelOuter='bvNone';frame.ParentColor=false;frame.Color=warning and 0x00D7FF or 0x666666
  local p=createPanel(frame);p.BevelOuter='bvNone';p.ParentColor=false
  frame.DoubleBuffered=false;p.DoubleBuffered=false
  p.Cursor=-21;p.TabStop=true
  local entry={button=b,panel=p,frame=frame,toggle=toggle,warning=warning};entries[#entries+1]=entry
  p.OnClick=function() if b.OnClick then b.OnClick() end;update(entry) end
  p.OnKeyDown=function(sender,key) if key==13 or key==32 then p.OnClick() end end
  update(entry)
end
for _,b in ipairs({fixedHealthButton,clearViewButton,staminaButton,craftingButton,flightButton,beamButton,carryButton,
  deleteButton,enemyButton,keepFlagsButton,rapidButton,freezeReplenishButton,freeze,speedButton,jumpButton,boatButton,sortingButton,minerButton}) do styleToggle(b,true) end
for _,b in ipairs({edit,cloneButton,maxItemQualityButton,refresh,maxStacksButton,dragButton,spawnButton,tamingButton,planterButton,trophyButton,maxSkills,customSkills,
  lootMagnetButton,resetMovementButton,teleportButton}) do styleToggle(b,false) end
local function updateAll(redraw) for _,entry in ipairs(entries) do update(entry,redraw) end end
-- Paint the native child windows directly instead of caching a parent bitmap.
form.DoubleBuffered=false;playerGroup.DoubleBuffered=false
local resize,show=form.OnResize,form.OnShow
form.OnResize=function(...) if resize then resize(...) end;updateAll(true) end
form.OnShow=function(...) if show then show(...) end;updateAll(true) end
local foreground=false
local redrawTicks=0
local poll=createTimer(form,false);poll.Interval=150
poll.OnTimer=function()
  local focused=form.isForegroundWindow()
  if focused and not foreground then redrawTicks=2 end
  foreground=focused
  updateAll(redrawTicks>0)
  if redrawTicks>0 then redrawTicks=redrawTicks-1 end
end
poll.Enabled=true
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() local result=close();updateAll();return result end
form.OnDestroy=function() poll.Enabled=false;destroy() end
end
