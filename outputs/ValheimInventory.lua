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
form.Caption = 'Valheim Solo Toolkit | Enemy form v6 | DBZ Powers v2 | Building v2'
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
local edit = createButton(form)
edit.Caption = 'Edit quantity'
edit.Left = 185; edit.Top = 12; edit.Width = 160
local freeze = createButton(form)
freeze.Caption = 'Freeze selected'
freeze.Left = 358; freeze.Top = 12; freeze.Width = 160
local unfreeze = createButton(form)
unfreeze.Caption = 'Unfreeze all'
unfreeze.Left = 531; unfreeze.Top = 12; unfreeze.Width = 160
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
godButton.Caption = 'God mode: OFF'
godButton.Left = 12; godButton.Top = 590; godButton.Width = 200
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
keepFlagsButton.Caption='Clear all flags: OFF'
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
local beamButton=createButton(form)
beamButton.Caption='DBZ Powers: OFF'
local kayokenCheck=createCheckBox(form)
kayokenCheck.Caption='Kayoken';kayokenCheck.Checked=false;kayokenCheck.Enabled=false
local carryButton=createButton(form)
carryButton.Caption='Unlimited carry: OFF'
local deleteButton=createButton(form)
deleteButton.Caption='Inventory delete: OFF'
local minerButton=createButton(form)
minerButton.Caption='Rapid miner: OFF'
local hoeButton=createButton(form)
hoeButton.Caption='Rapid hoe: OFF'
local enemyButton=createButton(form)
enemyButton.Caption='Enemy form: OFF'
local dragButton=createButton(form)
dragButton.Caption='Building tools...'
-- Hover hints and a reusable, scrollable help window.
local function hint(control,text)
  control.Hint=text; control.ShowHint=true; control.ParentShowHint=false
end
local helpText=[[
BUILDING
Open Building tools for Auto rows and furnished blueprints. Stand inside the building at floor level. Capture asks for a save name and box width/height/depth, then snapshots a fixed box around your character, starting 1m below your feet. Return to the game once with a hammer to capture it. The count and highlight stay fixed. Click Save captured blueprint in the Building window for a verified file path; no capture hotkeys are required. F7 remains an optional save shortcut. Duplicate names get a numbered suffix. Load previews a saved blueprint at the hammer ghost (or aimed surface). Q/E rotate, Page Up/Down adjust height, F6 locks, F7 builds. Escape cancels. Maximum 512 loaded player-built pieces, including furniture and signs. Terrain, loose items, contents, bed claims, portal links and display equipment are not copied. Free Crafting removes blueprint costs; otherwise total materials are checked before starting and each placed piece pays costs. Support still applies. Undo removes only objects from the last paste, without material refunds; empty pasted containers and display stands first. Disabling Building, changing modes or leaving the world clears Undo. Files persist under LocalAppData/ValheimSoloToolkit/Blueprints.


INVENTORY - SELECTED ITEM
Select a row first. Edit quantity accepts positive whole numbers, including values above the normal stack limit. Clone copies the selected item into your inventory; leave an empty slot available.
Freeze selected is a toggle: click once to hold that item's quantity, again to release it. X in the first column means frozen. Splitting/reordering does not freeze newly created stacks automatically. Removing an entire stack ends its freeze.

INVENTORY - ALL STACKS
Refresh reads your current inventory. Max all stacks sets each existing stack to its normal maximum; it also reduces overstacks to that maximum. Freeze entire inventory captures the quantities of currently carried stacks; new stacks start unfrozen. The inventory freeze button becomes Unfreeze inventory while any stack is frozen; clicking it releases all locks.
Auto refill: enable it, open a chest, then Ctrl+left-click a stack to deposit. A copy transfers and the original stays in its inventory slot. This is separate from freezing quantities.

ITEM FLAGS AND GOD MODE
Valheim can flag items as cheated when you kill monsters with them while God mode is enabled. The item flag controls are provided to manage that flag.
Flag Y means marked, - means clear, and ? means unreadable. Clear all flags is one inventory-wide toggle: enabling clears all carried flags immediately and keeps newly crafted/upgraded items clear; disabling stops future clearing. After clearing the affected item flag, drop the item from your inventory and pick it up again. Use the normal drop action, not Inventory delete. These controls change item flags, not every record of cheat use.

DELETE ITEMS IN GAME
Inventory delete creates a menu at the BOTTOM LEFT of the game when your inventory is open. Drag a full stack from your own inventory and use Destroy, then confirm. Quest items, equipped items, chest items and partial-stack drags are blocked. Split off a smaller stack first to delete only part of a stack. Deletion is permanent.

TELEPORT - MAP MARKERS AND PINGS
Open Valheim's map and create a named marker at your destination. Open Teleport tools, click Refresh locations, select its Map pin row, then Teleport selected.
You can also use the game's map ping action. Refresh locations while the ping is visible, then select its Ping row and teleport. The list captures coordinates when refreshed; it does not track a moving ping. If missing, ping again and refresh promptly.
Save current position creates a named bookmark in Cheat Engine for this world. Stand still before saving. These bookmarks persist locally and do not create in-game map markers. Create visible map markers in Valheim's map itself.
Enter coordinates accepts X Y Z; Y is height. Return to the game and unpause after queuing. Terrain loading may take time. Cancel queued cancels a waiting request; it does not undo an accepted teleport.
To teleport to a player, they must enable Visible to other players on their map. Refresh players, select their row, then teleport. Their latest shared position is read when clicked, with a 3m sideways offset. It does not follow them afterward.
Delete saved location removes a local bookmark only. Edit or remove game map markers using the game map.

SKILLS AND MOVEMENT
Max skills sets existing skill entries to 100, including entries at zero. Custom skill level opens a skill picker: check the skills to change, or Select all, enter the desired level, then Apply. Levels above 100 are allowed; game behavior can still apply its own caps. Movement speed and jump force are multipliers. Reset restores their original values.
Flight: Space rises, Left Ctrl descends, Shift moves faster. This is flight, not collision-free noclip.

RAPID MINER
Enable Rapid miner, equip a pickaxe and hold attack to mine. Pickaxe attack animations run at 10x speed. Stamina and the equipped pickaxe durability refill while equipped. Switching tools stops the effect; disabling restores animation speed. Refilled stamina/durability remain. Normal hit detection, mining range and pickaxe tier requirements still apply.

RAPID HOE
Enable Rapid hoe, equip the hoe, select a terrain action and hold the use button (mouse attack or controller place). Repeats up to 20 times per second with stamina and hoe durability refill. Normal material costs and terrain restrictions apply. Switching tools, disabling or closing restores the original placement cooldown. Refilled stamina and durability remain.

ENEMY FORM
Choose from 26 creature forms, including Fulings, Cultist, Abomination, Seeker Soldier and Asksvin. The tool controls a real enemy body with its native weapons, animation and movement; your original player is hidden and suspended. Move/run/jump using your normal bindings. The body faces movement while moving, or camera aim while idle/attacking, using native turn speed. For Sea Serpent, transform in deep water; normal movement steers native surface swimming. Returning restores your player at that position, including in water. Attack uses the current native weapon; Block uses its secondary attack if available, otherwise primary. Use cycles available native weapons. F8 or the toggle returns to your player at the enemy body position. Its death also returns you. Your inventory, skills and original health stay with your original player; the normal HUD does not show enemy health, so check toolkit status.
Enemy form hides your player nameplate, local map/minimap arrows and shared map position. Your original display name and map-sharing preference are restored on return. This does not guarantee a full enemy disguise on other players' clients. The body joins the player faction. This is intended for solo play. Closing the toolkit queues restoration; return to Valheim and unpause for cleanup to finish.

KAYOKEN
Enable a DBZ power and equip your bow, then check Kayoken beside DBZ Powers. Red aura; 32x DBZ damage and 2x size. Beam range 120m; Death Beam 16000 generic damage every 0.1s plus chopping/pickaxe damage, excluding you. Kameha stays hostile-only. Spirit Bomb: 160000 damage / 80m radius. Supernova: 640000 / 240m radius. Native protections apply; only loaded terrain/objects are affected. Bomb power is fixed at launch. Uncheck to restore normal beams/future bombs and remove aura. Disabling DBZ Powers resets Kayoken. Visuals are local.

PLAYER TOGGLES
God mode blocks local player damage. See the item-flag notice above. Unlimited stamina replenishes stamina while active. Free crafting bypasses crafting/building material requirements; it does not supply fuel for machines.
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
  {dragButton,'Open the Building section for drag rows, furnished blueprint capture/load, and Undo. Hammer: Ctrl + left-drag previews a snapped straight row (up to 24). Release left click while holding Ctrl to build. Right click cancels. Auto-builds the preview without range, line-of-sight or hammer cooldown checks. Free Crafting also skips row stamina and wear; otherwise normal costs apply. Rapid hoe and Drag build are mutually exclusive.'},
  {enemyButton,'Choose from 26 creature forms with native movement and attacks. Attack = primary, Block = secondary/fallback, Use = cycle weapons. F8 or this toggle returns to your player.'},
  {hoeButton,'Hold use with the hoe for up to 20 terrain actions per second, stamina refill and full hoe durability. Normal material costs apply; other tools are unaffected.'},
  {minerButton,'10x pickaxe swing animation speed with stamina and equipped pickaxe durability refill. Hold attack to mine; other weapons are unaffected.'},
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
  {godButton,'Block local player damage. DISCLAIMER: killing monsters with an item while God mode is active can flag that item as cheated. Use Item flags controls to clear or keep that flag off.'},
  {staminaButton,'Continuously replenish stamina while enabled.'},
  {craftingButton,'Bypass crafting and building material requirements. Does not refill machine fuel. Crafted/upgraded items may receive a cheated flag.'},
  {carryButton,'Prevent encumbrance regardless of carried weight. The displayed weight and normal limit are unchanged.'},
  {maxSkills,'Set all existing skill entries to level 100, including level-zero entries.'},
  {customSkills,'Open the skill editor: check individual skills or Select all, enter a level, then Apply. Levels above 100 are allowed; game effects may still be capped.'},
  {speedButton,'Set a movement-speed multiplier relative to your original walk/run/crouch/swim speeds.'},
  {jumpButton,'Set a jump-force multiplier relative to the original value. Higher values increase jump height.'},
  {resetMovementButton,'Restore the original movement speeds and jump force.'},
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
subtitle.Caption = 'Inventory loads automatically when your world is ready. Green Refresh reloads it anytime.'; subtitle.Left=22; subtitle.Top=44
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
-- Persistent notices stay separate from transient player action/status messages.
local godWarning=createLabel(playerGroup)
godWarning.Caption='GOD MODE: Monster kills can flag the used item as cheated.'
local craftingWarning=createLabel(playerGroup)
craftingWarning.Caption='FREE CRAFTING: Crafted/upgraded items can be flagged as cheated.'
local flagWarningHelp=createLabel(playerGroup)
flagWarningHelp.Caption='Clear it using Item flags, then drop the item and pick it up again.'
for _,label in ipairs({godWarning,craftingWarning,flagWarningHelp}) do
  label.AutoSize=false;label.WordWrap=true
  label.Font.Color=0x75BDFF
end
flagWarningHelp.Font.Color=0x8DCCE8
hint(godWarning,godButton.Hint)
hint(craftingWarning,craftingButton.Hint)
hint(flagWarningHelp,'Enable Inventory > Clear all flags to clear all carried-item flags. Then drop it from your inventory and pick it up again. Keep item flags off clears carried-item flags continuously. Use the normal drop action, not Inventory delete. Click for the full guide.')
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
    local lowerH=26+12+4*(buttonH+6)+line*2+8+warningH*3+8
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
    local groups={{edit,cloneButton,freeze,refresh},
      {maxStacksButton,freezeAll,depositButton,keepFlagsButton},
      {dragButton}}
    for row,controls in ipairs(groups) do
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
    local skillsH=26+12+4*(buttonH+6)+line*3+10
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
        pair(godButton,staminaButton,1)
        pair(craftingButton,teleportButton,2)
        pair(flightButton,beamButton,3)
        beamButton.Width=math.max(100,beamButton.Width-88)
        place(kayokenCheck,group,beamButton.Left+beamButton.Width+6,beamButton.Top,82,buttonH)
        pair(carryButton,deleteButton,4)
        local y=10+4*(buttonH+6)
        place(playerStatus,group,12,y,cw-24,line*2)
        y=y+line*2+6
        place(godWarning,group,12,y,cw-24,warningH)
        place(craftingWarning,group,12,y+warningH,cw-24,warningH)
        place(flagWarningHelp,group,12,y+warningH*2,cw-24,warningH)
      else
        pair(maxSkills,customSkills,1)
        pair(speedButton,jumpButton,2)
        pair(resetMovementButton,enemyButton,3)
        pair(minerButton,hoeButton,4)
        place(skillStatus,group,12,10+4*(buttonH+6),cw-24,line*3)
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
  local player = pointer(readPointer(storage), 'Local player')
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
  keepFlagsButton.Caption='Clear all flags: OFF'
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
    keepFlagsButton.Caption='Clear all flags: ON'
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
local movementState
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
local window, destinations, teleportStatus, locationLabel, poll
local entries, saved, worldKey = {}, {}, nil
local hook, pending, settings
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
  local s=context()
  local loaded=loadSaved(s.world)
  local pins=readPins(s)
  local playersOK,players,hidden=pcall(readPlayers,s)
  local playerError=not playersOK and tostring(players) or nil
  if not playersOK then players={} end
  assert(context().world==s.world and playerIdentity(s),'World changed while reading destinations.')
  worldKey=s.world; saved=loaded; entries={}
  destinations.Items.clear(); destinations.ItemIndex=-1
  for _,group in ipairs({saved,pins,players}) do
    for _,p in ipairs(group) do
      entries[#entries+1]=p
      destinations.Items.add(string.format('%-7s | %-28s | X %.1f  Y %.1f  Z %.1f',p.source,p.name,p.x,p.y,p.z))
    end
  end
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
local function installHook(s)
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
]],entry,original,entry,s.storage,target,table.concat(replay,'\n'),entry+size,entry,
    size>14 and string.format('nop %X',size-14) or '',entry,original)
  local ok,info=autoAssemble(script,false)
  assert(ok,'Teleport hook installation failed: '..tostring(info))
  hook={pid=s.pid,script=script,info=info}
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
      if hook.data then writeQword(hook.data+8,0) end
      local ok,err=autoAssemble(hook.script,false,hook.info)
      assert(ok,'Could not remove teleport hook: '..tostring(err))
    end
    hook=nil
  end
  pending=nil
  if window then window.hide() end
end
ValheimTeleportStop=stopTeleport
local oldClose,oldDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopTeleport();return oldClose() end
form.OnDestroy=function() stopTeleport();if window then window.destroy();window=nil end;oldDestroy() end
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
  teleportStatus.Caption='Teleport queued. Return to the game and unpause; distant areas may take 15+ seconds to load.'
end
local function pollTeleport()
  if not pending then return end
  local s=pending.session
  assert(playerIdentity(s) and context().world==s.world,'World/player changed; queued teleport cancelled.')
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
local function openTeleportWindow()
  if window then window.show();action(refreshLocations);return end
  window=createForm(false);window.Caption='Valheim | Teleport tools'
  window.Width=960;window.Height=550;window.Position='poScreenCenter';window.BorderStyle='bsSizeable'
  local help=createLabel(window);help.AutoSize=false;help.WordWrap=true
  help.Caption='Map: create a named marker or ping in Valheim, then Refresh locations and Teleport selected. Refresh while pings are visible. Saved positions are local bookmarks, not map markers. Players must share their position. Click Help & tips for the full guide.'
  window.Color=0x202020;window.Font.Color=0xE6E6E6;help.Font.Color=0x8DCCE8
  locationLabel=createLabel(window);locationLabel.AutoSize=false
  locationLabel.Caption='Current position: click Refresh locations. Position uses the player world-object snapshot; stand still when saving.'
  destinations=createListBox(window);destinations.Font.Name='Consolas'
  destinations.Color=0x181818;destinations.Font.Color=0xE6E6E6
  teleportStatus=createLabel(window);teleportStatus.AutoSize=false;teleportStatus.WordWrap=true
  local controls={}
  local teleportHints={
    ['Refresh locations']='Reload saved bookmarks, map markers, visible pings and shared players. Create markers/pings in the game map first. Refresh before a ping expires.',
    ['Save current position']='Save a named local bookmark for this world. Stand still first. Persists in Cheat Engine settings; does not create a map marker.',
    ['Teleport selected']='Teleport to the selected marker, ping, bookmark or shared player. Return to the game and unpause. Player positions are re-read when clicked, with a 3m sideways offset.',
    ['Enter coordinates']='Enter X Y Z separated by spaces. Y is height. Queues a teleport to these world coordinates.',
    ['Delete saved location']='Remove a selected local bookmark only. Remove game map markers in the game map.',
    ['Cancel queued']='Cancel a waiting teleport request. Does not undo a teleport already accepted by the game.',
    ['Refresh players']='Reload shared player positions. Players must enable Visible to other players on their map. Also refreshes markers and bookmarks.'
  }
  local function button(caption,fn)
    local b=createButton(window);b.Caption=caption;b.OnClick=function() action(fn) end
    hint(b,teleportHints[caption] or 'Open the full toolkit guide.')
    controls[#controls+1]=b
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
    for i,v in ipairs(saved) do if v==p then table.remove(saved,i);break end end
    persist();refreshLocations()
  end)
  button('Cancel queued',cancelQueued)
  button('Refresh players',refreshLocations)
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
    if h<400 then window.Height=window.Height+400-h;h=400 end
    place(help,window,16,12,w-32,54)
    place(locationLabel,window,16,72,w-32,40);locationLabel.WordWrap=true
    local bw=math.floor((w-56)/3)
    for i,b in ipairs(controls) do place(b,window,16+((i-1)%3)*(bw+12),118+math.floor((i-1)/3)*42,bw,34) end
    place(guide,window,16+bw+12,118+2*42+8,bw,24)
    local listTop=126+math.ceil(#controls/3)*42
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
      pending=nil;poll.Enabled=false;window.show()
      teleportStatus.Caption='Teleport stopped: '..tostring(err)
        ..(stopped and '' or (' Cleanup failed: '..tostring(stopError)))
    end
    if not pending then poll.Enabled=false end
  end
  layout();window.show();action(refreshLocations)
end
teleportButton.OnClick=function() action(openTeleportWindow) end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local helperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c0103002128c76a0000000000000000e00002210b010b00006a00000006000000000000ae8900000020000000a000000000001000200000000200000400000000000000040000000000000000e000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000548900005700000000a00000c80200000000000000000000000000000000000000c000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000b469000000200000006a000000020000000000000000000000000000200000602e72737263000000c802000000a0000000040000006c0000000000000000000000000000400000402e72656c6f6300000c00000000c000000002000000700000000000000000000000000000400000420000000000000000000000000000000090890000000000004800000002000500fc5600005832000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001330060042050000010000110002037d010000047201000070280300000a252d0b267245000070280300000a0a06280400000a131411142d0b7265000070730500000a7a021f201f201a16730600000a7d0300000420000400008d110000010b160c2b7e160d2b6b00096b22000078415922000078415b1304086b22000078415922000078415b1305220000803f110411045a59110511055a59280700000a130607081f205a09588f11000001220000803f220000803f220000803f110611065a11065a730800000a8111000001000917580d091f20fe04131411142d8a0817580c081f20fe04131411143a74ffffff027b03000004076f0900000a00027b030000046f0a00000a00027b03000004176f0b00000a000206730c00000a7d02000004027b02000004027b030000046f0d00000a00027b0200000472a70000701b6f0e00000a00027b0200000472bb000070176f0e00000a00027b0200000472cf000070166f0e00000a0012072200008040228fc2753c22cdcccc3c22cdcc4c3e280800000a00027b0200000411076f0f00000a00027b0200000472df0000706f1000000a16fe01131411142d13027b0200000472df00007011076f1100000a00027b0200000420b80b00006f1200000a0016130838840000000016281300000a1309110972f50000706f1400000a0011096f1500000a02281600000a166f1700000a0011096f0100002b130a110a166f1900000a00110a281a00000a0011096f0200002b130b110b027b020000046f1b00000a00110b166f1c00000a00110b166f1d00000a00027b04000004110811096f1500000aa2001108175813081108027b040000048e69fe04131411143a67ffffff722b010070731e00000a130c110c6f1500000a02281600000a166f1700000a0002110c6f0300002b7d05000004027b0500000417166f2000000a00027b050000046f2100000a130d120d17282200000a00120d202c010000282300000a00120d223333333f282400000a282500000a00120d2200000000282400000a282600000a00120d226666263f282400000a282700000a00120d220000a040220ad7a33c220ad7233d22cdcc4c3f730800000a282800000a282900000a00120d17282a00000a00027b050000046f2b00000a130e120e2200003443282400000a282c00000a00027b050000046f2d00000a130f120f16282e00000a00120f229a99593f282f00000a00027b050000046f3000000a1310121017283100000a00121017283200000a0012102200008040282400000a283300000a00027b050000046f3400000a1311121117283500000a00121122cdcc4c3f282400000a283600000a0012112200000040283700000a0012112200008040282400000a283800000a00027b050000046f3900000a1312121217283a00000a00733b00000a13131113188d3100000113151115168f31000001283c00000a2200000000733d00000a81310000011115178f31000001283e00000a220000803f733d00000a81310000011115198d3200000113161116168f3200000122000000002200000000733f00000a81320000011116178f32000001220000803f22cdcccc3d733f00000a81320000011116188f320000012200000000220000803f733f00000a813200000111166f4000000a0012121113284100000a284200000a00027b050000046f0400002b027b020000046f1b00000a00027b050000046f4400000a000202284500000a6f0500002b7d06000004027b06000004220000803f220ad7233c220ad7a33c734600000a6f4700000a00027b0600000422000040416f4800000a00027b06000004220000c0406f4900000a00027b06000004166f4a00000a00022802000006002a000013300600c9000000020000110002281600000a027b010000046f1600000a6f4b00000a284c00000a284d00000a6f4e00000a00220000803f22b81e053e284f00000a22000098415a285000000a5a58228fc2753d284f00000a2200002c425a285000000a5a580a160b2b47027b04000004079a220000a03f076b229a99993e5a5822cdcc0c40076b229a99993e5a58220000a03f076b229a99993e5a58735100000a06285200000a6f5300000a000717580b07027b040000048e69fe040c082daa027b06000004220000c040065a6f4900000a002a00000013300200500000000300001100027b01000004281e0000062c257e2400000417331d027b010000046f5400000a2d10027b010000046f5500000a16fe012b0116000a062d0f0002284500000a281a00000a002b07022802000006002a133002003e0000000300001100027b02000004280400000a16fe010a062d0c027b02000004281a00000a00027b03000004280400000a16fe010a062d0c027b03000004281a00000a002a5202198d070000017d0400000402285600000a002a0013300100160000000400001100022d07220000803f2b052200000040000a2b00062a000013300100160000000400001100022d07220000a0422b05220000f042000a2b00062a000013300200410000000500001100022c1f02172e1302182e072200409c462b052200409c45002b05220000fa43002b05220000c842000a06032d07220000803f2b052200000042005a0b2b00072a000000133002001d0000000400001100027b080000042815000006027b0d00000428060000065a0a2b00062a00000013300400e80000000600001100027b0a00000416fe010a062d0538d400000002177d0a000004027b0b0000042d10027b0c0000042d0802280b0000062b0116000a062d0538aa000000027e2400000417fe017d0d00000402027b07000004027b070000046f5700000a6f5800000a0b1201285900000a7d1200000402027b070000046f5700000a027b120000042200002041285200000a284d00000a284c00000a2200008040285200000a284d00000a7d1100000402284f00000a7d0e00000402177d0b00000402280d00000600027b08000004192e0772570100702b05726f010070007283010070285a00000a80270000042a133002008b0000000300001100027b07000004280400000a2c76027b070000046f5b00000a2c69027b070000046f5400000a2d5c027b070000046f5500000a2d4f285c00000a2c48027b07000004281b0000062c3b285d00000a2d34285e00000a2d2d285f00000a2d26286000000a2d1f286100000a280400000a2c0f286100000a6f6200000a16fe012b0117002b0116000a2b00062a00133003008400000007000011007201000070280300000a252d0b267245000070280300000a0a06280400000a0d092d0b7203020070730500000a7a06730c00000a0b07036f0f00000a000772a70000701b6f0e00000a000772bb000070176f0e00000a000772cf000070166f0e00000a000720b80b00006f1200000a00027b15000004076f6300000a00070c2b00082a1330050096020000080000110002027b08000004192e0772570100702b05726f01007000731e00000a7d14000004027b140000046f1500000a027b110000046f4e00000a00027b08000004192e1b220000c03f2200004040220000a04022cdcc0c3f730800000a2b192200004040223333333f228fc2753d22cdcc0c3f730800000a000a027b08000004192e1b22cdcccc3d22cdcc4c3f220000404022ec51383e730800000a2b19220000004022cdcc4c3d22cdcccc3e22ec51383e730800000a000b160c38920000000016281300000a0d096f1500000a027b140000046f1500000a166f1700000a00096f0100002b13041104166f1900000a001104281a00000a00096f1500000a286400000a220000803f086b229a99993e5a58285200000a6f5300000a00096f0200002b1305110502082c03072b010600280c0000066f1b00000a001105166f1c00000a001105166f1d00000a00000817580c0819fe04130811083a61ffffff160c38a4000000007241020070088c40000001286500000a731e00000a130611066f1500000a027b140000046f1500000a166f1700000a0011066f0600002b13071107176f6600000a0011071f416f6700000a0011070208185d2c03072b010600280c0000066f1b00000a001107229a99193e6f6800000a001107229a99193e6f6900000a001107166f1c00000a001107166f1d00000a00027b1600000411076f6a00000a00000817580c081dfe04130811083a4fffffff02027b140000046f0500002b7d17000004027b17000004027b08000004192e1622cdcc4c3e226666263f220000803f734600000a2b14220000803f22cdcc4c3e220ad7a33c734600000a006f4700000a00027b1700000422000080406f4900000a00027b1700000422000034426f4800000a00027b17000004166f4a00000a002a0000133007006b0200000900001100027b14000004280400000a130711072d053853020000027b08000004192e0722000040412b05220000904100027b0d00000428060000065a0a027b0c00000416fe01130711072d2c0602280900000622000000405a284f00000a027b0f0000045922000040405b280700000a286b00000a0a2b1f06220000803f220ad7233d284f00000a220000e0405a285000000a5a585a0a027b140000046f1500000a027b110000046f4e00000a00027b140000046f1500000a286400000a06285200000a6f5300000a00027b0c0000042d07220000803f2b1d220000803f284f00000a027b0f00000459220000c0405b59280700000a000b160c2b4400027b15000004086f6c00000a6f6d00000a0d1203082c0722ec51383e2b0522cdcc0c3f00075a7d6e00000a027b15000004086f6c00000a096f0f00000a00000817580c08027b150000046f6f00000afe04130711072da816130438c9000000160c38ae00000000086b22db0f49405a22000000405a22000080425b284f00000a1104185d2c0722000080bf2b05220000803f005a5813051105287000000a22000000001105285000000a735100000a06226666263f11046b22cdcccc3c5a585a285200000a1306027b1600000411046f7100000a08027b1100000411046b220000d8415a284f00000a22000040415a11046b220000f8415a287200000a1106287300000a284d00000a6f7400000a00000817580c081f41fe04130711073a44ffffff1104175813041104027b160000046f7500000afe04130711073a1fffffff027b170000042200008040075a6f4900000a00027b17000004220000c8420622000040405a287600000a6f4800000a002a00033005006b000000000000000002167d0b00000402177d0c00000402284f00000a7d0f00000402027b110000047d1300000402027b130000040228090000061517287700000a7d180000040202280900000628170000067d1b00000402167d1900000402167d1a000004027b1c0000046f7800000a002a0013300600a40200000a00001100284f00000a027b10000004fe0416fe01130411042d05388702000002284f00000a22cdcc4c3d587d10000004160a2b4d027b07000004027b18000004027b190000049a027b13000004284c00000a027b08000004027b0d0000042808000006027b1c0000042833000006000617580a02257b1900000417587d19000004061f302f12027b19000004027b180000048e69fe042b011600130411042d94160a38c400000000027b1b000004027b1a0000046f7900000a0b027b1300000412017b20000004220000000012017b21000004735100000a284d00000a0c081203287a00000a130411042d022b6b09027c130000047b7b00000a5909027c130000047b7b00000a595a12017b2000000412017b200000045a5812017b2100000412017b210000045a580228090000060228090000065afe0216fe01130411042d022b161202097d7b00000a027b0700000408283500000600000617580a02257b1a00000417587d1a000004061c2f15027b1a000004027b1b0000046f7c00000afe042b011600130411043a18ffffff1f0a8d020000011305110516027b08000004192e0772570100702b05726f01007000a2110517725d020070a2110518027b190000048c40000001a2110519727f020070a211051a027b180000048e698c40000001a211051b7283020070a211051c027b1a0000048c40000001a211051d727f020070a211051e027b1b0000046f7c00000a8c40000001a211051f097299020070a21105287d00000a8027000004027b19000004027b180000048e69322b027b1a000004027b1b0000046f7c00000a3218284f00000a027b0f00000459220000c040fe0216fe012b011700130411042d340002167d0c0000040228120000060002147d1800000402147d1b000004027b1c0000046f7800000a0072e30200708027000004002a1b300600560200000b0000110000027b07000004281e0000062c447e23000004027b0800000433377e2b000004027b09000004332a027b07000004280400000a2c1d027b070000046f5400000a2d10027b070000046f5500000a16fe012b011600130611062d120002284500000a281a00000a00dde701000016287e00000a130611062d0702167d0a00000402280b000006130611062d05ddc3010000027b0b00000416fe01130611063a7601000000027b080000042816000006287f00000a22cdcccc3d287600000a5a0a060b160c00027b110000042200000040027b0d00000428060000065a027b12000004061517288000000a13071613082b67110711088f4600000171460000010d001203288100000a280400000a2c1c1203288100000a6f0700002b027b07000004288300000a16fe012b011600130611062d022b1d1203288400000a07fe03130611062d0c001203288400000a0b170c0000110817581308110811078e69fe04130611062d8b02257b11000004027b1200000407285200000a284d00000a7d1100000400027b110000042200000040027b0d00000428060000065a1517287700000a13091613082b3a110911089a13041104280400000a2c1711046f0700002b027b07000004288500000a16fe012b011700130611062d0500170c2b14110817581308110811098e69fe04130611062db8082d15284f00000a027b0e00000459220000a041fe052b011600130611062d0702280f0000060000027b0c00000416fe01130611062d070228100000060002280e0000060000de1a130500110528200000060002284500000a281a00000a0000de0000002a0000411c0000000000000100000038020000390200001a000000160000011b300200870000000c00001100027b14000004280400000a16fe010b072d0c027b14000004281a00000a0002147d14000004027b160000046f8600000a0000027b150000046f8700000a0c2b1c1202288800000a0a06280400000a16fe010b072d0706281a00000a001202288900000a0b072dd9de0f1202fe160500001b6f8a00000a00dc00027b150000046f8b00000a002a000110000002003f002b6a000f000000008e000228120000060002147d1800000402147d1b000004027b1c0000046f7800000a002aa602738c00000a7d1500000402738d00000a7d1600000402738e00000a7d1c00000402285600000a002a00001330020017000000040000110002192e0722000020422b05220000f042000a2b00062a001330020017000000040000110002192e0722000010412b05220000c040000a2b00062a00133004004c0000000d000011000f007b200000040f007b200000045a0f007b210000040f007b210000045a580b12010f017b200000040f017b200000045a0f017b210000040f017b210000045a58289000000a0a2b00062a13300400b80000000e00001100739100000a0a0222000040405b6c289200000a690b07650c2b6207650d2b4c08085a6b22000040405a22000040405a09095a6b22000040405a22000040405a5802025afe03130511052d1c06086b22000040405a096b22000040405a73190000066f9300000a000917580d0907fe0216fe01130511052da70817580c0807fe0216fe01130511052d91067e1f0000042d1314fe0618000006739400000a801f0000042b007e1f0000046f9500000a000613042b0011042a420002037d2000000402047d210000042a3e00022d03162b01170080240000042a000000133003002800000003000011007e2d00000414289700000a2c137e2d00000402146f9800000aa5500000012b0116000a2b00062a13300200500000000300001100031632090319fe0216fe012b0116000a062d0b725f030070739900000a7a7e2b0000041758802b0000041680240000040380230000040280280000041480260000041480270000041780220000042a52001680220000041680240000041480280000042a000000133002003200000003000011007e2200000417332202280400000a2c1a027e28000004288300000a2c0d027e9a00000a288300000a2b0116000a2b00062a0000133002001b0000000300001100022c10027b9b00000a7b9c00000a1afe012b0116000a2b00062a0013300300550000000300001100168022000004026f9d00000a6f9e00000a7283030070026f9f00000a28a000000a80260000047e260000046fa100000a2090010000fe0216fe010a062d157e260000041620900100006fa200000a80260000042a0000001b3003006b0200000f0000110002281e0000060d092d07160c3856020000007e24000004173335026f5400000a2d2d026f5500000a2d257e25000004280400000a2c157e250000047b0100000402288500000a16fe012b0116002b0117000d092d43007e25000004280400000a16fe010d092d107e250000046f4500000a281a00000a007289030070731e00000a280800002b80250000047e25000004026f01000006000003281f0000060d092d07160cddbe0100007e2c0000041428a300000a16fe010d092d0b72b103007073a400000a7a7e2c0000040222000080bf8c4b0000016fa500000a007e2300000418fe040d093ac8000000007e2a000004280400000a2c367e2a0000047b0700000402288500000a2d247e2a0000047b080000047e2300000433137e2a0000047b090000047e2b000004fe012b0116000d092d60007e2a000004280400000a16fe010d092d107e2a0000046f4500000a281a00000a0072e5030070731e00000a280900002b802a0000047e2a000004027d070000047e2a0000047e230000047d080000047e2a0000047e2b0000047d090000040016287e00000a16fe010d092d0b7e2a0000046f0a00000600170cddb40000007e29000004280400000a2c217e290000047b2e00000402288500000a2d0f7e290000046f2300000616fe012b0116000d092d45007e29000004280400000a16fe010d092d107e290000046f4500000a281a00000a00720d040070731e00000a0a066f0a00002b80290000047e29000004026f2800000600007e29000004036f2e0000060000de280b00072820000006007e29000004280400000a16fe010d092d0b7e290000046f2b0000060000de0000170c2b0000082a00411c00000000000012000000290200003b0200002800000016000001ded03700000128a600000a72410400701f346fa700000a802c000004d00400000128a600000a72630400701f3428a800000a802d0000042a133003002a0000000300001100027b360000047e230000043315027b380000047e2400000417fe01fe0116fe012b0117000a2b00062a000013300400400000001000001100027b36000004172e03032b2d0f017ba900000a0f017baa00000a228fc2f53d5a0f017bab00000a220000803e5a0f017b6e00000a730800000a000a2b00062a13300100110000000400001100027b3800000428070000060a2b00062a0000001330020017000000040000110022cdcccc3f027b3800000428060000065a0a2b00062a001330020012000000040000110016027b3800000428080000060a2b00062a000013300900da080000110000110002037d2e000004027e230000047d36000004027e2400000417fe017d3800000402036f0b00002b7d440000047201000070280300000a252d19267277040070280300000a252d0b267245000070280300000a0a06280400000a131411142d0b72a9040070730500000a7a0206730c00000a7d30000004027b3000000472a70000701b6f0e00000a00027b3000000472bb000070176f0e00000a00027b3000000472cf000070166f0e00000a00027b3000000420b80b00006f1200000a000272e9040070731e00000a7d2f000004027b2f0000046f1500000a02281600000a166f1700000a0002027201050070229a99194022cdcc4c3d226666e63e2200004040228fc2f53d730800000a1f4128290000067d3900000402027223050070226666863f22cdcc4c3e2200004040220000a04022cdcc0c3f730800000a1f4128290000067d3a0000040202723b050070227b14ae3e2200008040220000a040220000c040220000803f730800000a1f4128290000067d3b0000040202725905007022ec51b83d229a99993e2200004040220000a04022cdcc4c3f730800000a1f6028290000067d3c00000402027277050070228fc2753d2200004040220000a040220000c040220000403f730800000a1f6028290000067d3d0000040202729505007022cdcccc3d22cdcccc3d2200004040220000a040229a99593f730800000a1f4128290000067d3e000004020272b505007022cdcc4c3d2200004040220000a040220000c040226666663f730800000a1f4128290000067d3f000004020272d5050070220ad7233e22cdcc4c3e2200008040220000c04022cdcc4c3f730800000a1f4128290000067d4000000400198d0d0000011315111516027b3e000004a2111517027b3f000004a2111518027b40000004a21115131616131738a3000000111611179a0b00076fac00000a0c071a8d5900000113181118168f590000012200000000220000000073ad00000a81590000011118178f5900000122cdcc4c3e220000803f73ad00000a81590000011118188f59000001223333333f223333333f73ad00000a81590000011118198f59000001220000803f220000000073ad00000a8159000001111873ae00000a6faf00000a0007086fb000000a0000111717581317111711168e69fe04131411143a4cffffff160d38de00000000027b33000004090272ed050070098c40000001286500000a220ad7233d09195d6b22cdcccc3c5a58220000803e22cdcc4c3f229a99993f22295c8f3e730800000a1f182829000006a2027b33000004099a198d5900000113181118168f590000012200000000220000000073ad00000a81590000011118178f59000001223333b33e220000803f73ad00000a81590000011118188f59000001220000803f220000000073ad00000a8159000001111873ae00000a6faf00000a00027b33000004099a220ad7233d09195d6b22cdcccc3c5a586fb000000a00000917580d09027b330000048e69fe04131411143a0effffff021f201f201a16730600000a7d3200000420000400008d11000001130416130538890000001613062b720011066b22000078415922000078415b130711056b22000078415922000078415b1308220000803f110711075a59110811085a59280700000a1309110411051f205a1106588f11000001220000803f220000803f220000803f110911095a11095a730800000a81110000010011061758130611061f20fe04131411142d8211051758130511051f20fe04131411143a68ffffff027b3200000411046f0900000a00027b320000046f0a00000a00027b32000004176f0b00000a000206730c00000a7d31000004027b31000004027b320000046f0d00000a00027b3100000472a70000701b6f0e00000a00027b3100000472bb000070176f0e00000a00027b3100000472cf000070166f0e00000a007215060070731e00000a130a110a6f1500000a027b2f0000046f1500000a166f1700000a0002110a6f0300002b7d34000004027b3400000417166f2000000a00027b340000046f2100000a130b120b17282200000a00120b2068010000282300000a00120b226666263f282400000a282500000a00120b2200000000282400000a282600000a00120b22ec51383e282400000a282700000a00120b17282a00000a00027b340000046f2b00000a130c120c2200000000282400000a282c00000a00027b340000046f3400000a130d120d17283500000a00120d229a99993f282400000a283600000a00120d22cdcc8c3f283700000a00120d2200004040282400000a283800000a00027b340000046f3900000a130e120e17283a00000a00733b00000a130f110f188d3100000113191119168f31000001283c00000a2200000000733d00000a81310000011119178f31000001283c00000a220000803f733d00000a81310000011119198d32000001131a111a168f3200000122000000002200000000733f00000a8132000001111a178f32000001220000803f228fc2f53d733f00000a8132000001111a188f320000012200000000220000803f733f00000a8132000001111a6f4000000a00120e110f284100000a284200000a00027b340000046f0400002b027b310000046f1b00000a00724d060070731e00000a131011106f1500000a027b2f0000046f1500000a166f1700000a000211106f0300002b7d41000004027b4100000417166f2000000a00027b410000046f2100000a1311121117282200000a00121122cdcccc3e282400000a282500000a0012112200004041282400000a282600000a00121122cdcc4c3e282400000a282700000a0012110222cdcccc3e2200004040220000a040220000803f730800000a2824000006282800000a282900000a00121120a0000000282300000a00121117282a00000a00027b410000046f2b00000a131212122200005c43282400000a282c00000a00027b410000046f2d00000a1313121316282e00000a001213223333b33e282f00000a00027b410000046f0400002b027b310000046f1b00000a0002027269060070220000c040282a0000067d42000004020272830600702200001041282a0000067d43000004027b2f000004166fb100000a002a0000133003009d000000120000110003731e00000a0a066f1500000a027b2f0000046f1500000a166f1700000a00066f0600002b0b07027b300000046f1b00000a0007176f6600000a00070e046f6700000a0007046f6800000a00070422cdcc4c3f5a6f6900000a0007020528240000066fb200000a0007020528240000066fb300000a00071c6fb400000a0007166fb500000a0007166f1c00000a0007166f1d00000a00070c2b00082a000000133005006a000000130000110003731e00000a0a066f1500000a027b2f0000046f1500000a166f1700000a00066f0500002b0b070222cdcccc3d226666263f220000803f734600000a28240000066f4700000a0007046f4800000a000722000040406f4900000a0007166f4a00000a00070c2b00082a000013300300630000000300001100027b2f000004280400000a16fe010a062d0d027b2f000004166fb100000a00027b490000042c1a027b44000004280400000a2c0d027b4500000428b600000a2b0117000a062d13027b44000004027b45000004166fb700000a0002167d490000042a0013300200840000000300001100027b2e000004281e0000062c0b02282300000616fe012b0116000a062d160002282b0000060002284500000a281a00000a002b4e284f00000a027b4600000459228fc2f53d302e285c00000a2c2716287e00000a2c1f027b2e000004281b0000062c12027b2e0000046fb800000a281f0000062b0116000a062d0702282b000006002a1330020063000000030000110002282b00000600027b30000004280400000a16fe010a062d0c027b30000004281a00000a00027b31000004280400000a16fe010a062d0c027b31000004281a00000a00027b32000004280400000a16fe010a062d0c027b32000004281a00000a002a0013300700ef090000140000110002284f00000a7d46000004285c00000a2c3216287e00000a2c2a027b2e000004281b0000062c1d027b2e0000046f5400000a2d10027b2e0000046f5500000a16fe012b011600131811182d0d0002282b000006003894090000027b49000004131811182d4f0002177d4900000402284f00000a7d4700000402284f00000a7d4800000402284f00000a7d35000004027b2f000004176fb100000a00027b410000046f4400000a00027b340000046f4400000a000002037b9b00000a7bb900000a7bba00000a7d45000004027b44000004280400000a2c0d027b4500000428b600000a2b011700131811182d2b00027b44000004027b45000004176fb700000a00027b44000004729d060070220000803f6fbb00000a0000027b2e0000046f5700000a284c00000a226666e63e285200000a28bc00000a0a027b2e000004066f5800000a13191219285900000a0b0607226666263f285200000a284d00000a0c0228250000060d1c8d38000001131a111a1672b5060070a2111a1772c5060070a2111a1872df060070a2111a1972fb060070a2111a1a7207070070a2111a1b7217070070a2111a28bd00000a1304027b3600000416fe0116fe01131811183aa6000000000607022825000006226666263f5811041728be00000a131b16131c2b77111b111c8f4600000171460000011305001205288100000a280400000a2c161205288100000a6f0700002b280400000a16fe012b011600131811182d022b321205288400000a226666263f5909fe0416fe01131811182d1822000000001205288400000a226666263f5928bf00000a0d00111c1758131c111c111b8e69fe04131811183a78ffffff092200000000fe03131811182d0d0002282b00000600386a070000080709285200000a284d00000a130607284c00000a28c000000a13191219285900000a1307120728c100000a220ad7233cfe0416fe01131811182d0728c200000a130711070728c000000a13191219285900000a130822cdcc4c3e220000803f284f00000a027b470000045922cdcc4c3e5b280700000a286b00000a027b3800000428060000065a1309220000803f220ad7233e284f00000a220000e8415a285000000a5a5822ec51b83d284f00000a22000086425a285000000a5a58130a027b39000004229a99194011095a110a5a6f6800000a00027b39000004027b390000046fac00000a22cdcc4c3f5a6f6900000a00027b3a000004226666863f11095a6f6800000a00027b3a000004027b3a0000046fac00000a22cdcc4c3f5a6f6900000a00027b3b000004227b14ae3e11095a6f6800000a00027b3b000004027b3b0000046fac00000a22cdcc4c3f5a6f6900000a0016130b38e400000000110b6b22000080425b130c1107110b6b22a470dd3f5a284f00000a22000004425a59285000000a285200000a1108110b6b2248e10a405a284f00000a22000024425a58285000000a285200000a284d00000a110c22db0f49405a285000000a285200000a1109285200000a130d081106110c28c300000a130e027b39000004110b110e110d229a99993e285200000a284d00000a6f7400000a00027b3a000004110b110e110d228fc2f53d285200000a284d00000a6f7400000a00027b3b000004110b110e110d22295c0f3d285200000a284d00000a6f7400000a0000110b1758130b110b1f41fe04131811183a0dffffff16130b38ed00000000110b6b220000be425b130c110c095a220000c03f5a284f00000a22000098415a5922cdcccc3e110b6b223333f33f5a284f00000a220000c0415a58285000000a5a58130f1107110f287000000a285200000a1108110f285000000a285200000a284d00000a223333333f228fc2753e110b6b22000020405a284f00000a220000f8415a59285000000a5a58285200000a1109285200000a110c22db0f49405a285000000a285200000a1310081106110c28c300000a130e027b3c000004110b110e1110284d00000a6f7400000a00027b3d000004110b110e111028bc00000a6f7400000a0000110b1758130b110b1f60fe04131811183a04ffffff027b3e0000040811071108229a99193f11095a282f00000600027b3f000004080722cdcc4c3e285200000a284d00000a11071108220000803f11095a282f00000600027b40000004110611071108223333b33f11095a110a5a282f00000600161311382201000000284f00000a226666263f11116b2296438b3c5a585a11116b22ba490c3e5a58220000803f5d131216130b38dc00000000110b6b220000b8415b130c11116b229a9919405a284f00000a220000e04011116b22cdcc4c3e5a585a59110c22cdcc2c405a58130f2200002040223333b33f11125a59229a99593f229a99193e110f22000040405a11116b58285000000a5a585a027b3800000428060000065a131309111222000010415a110c220000c03f5a58287600000a1314027b3300000411119a110b08071114285200000a284d00000a1107110f287000000a285200000a1108110f285000000a285200000a284d00000a1113285200000a284d00000a6f7400000a0000110b1758130b110b1f18fe04131811183a15ffffff001111175813111111027b330000048e69fe04131811183ac9feffff284f00000a027b35000004fe05131811183a800100000002284f00000a220ad7a33c587d3500000416130b385701000000220000000022db0fc94028c400000a130f22cdcc4c3f22cdcc2c4028c400000a13131107110f287000000a285200000a1108110f285000000a285200000a284d00000a13151108110f287000000a285200000a1107110f285000000a285200000a28bc00000a13161217fe155f00000112170811151113285200000a284d00000a07220000000009220000c040287600000a28c400000a285200000a284d00000a28c500000a0012171116220000c040220000404128c400000a285200000a11152200000040285200000a28bc00000a072200000041220000904128c400000a285200000a284d00000a28c600000a00121722cdcc0c3f28c700000a001217228fc2753d228fc2753e28c400000a28c800000a00121702229a99993e226666a63f2200000040226666263f730800000a282400000628c900000a28ca00000a00027b340000041117176fcb00000a0000110b1758130b110b1efe04131811183a9bfeffff00027b420000042200004040110a5a6f4900000a00027b430000042200008040110a5a6f4900000a00027b410000046f1600000a11066f4e00000a00027b420000046f1600000a086f4e00000a00027b430000046f1600000a11066f4e00000a00284f00000a027b48000004fe05131811182d6f0002284f00000a22cdcccc3d587d48000004027b3600000417fe0116fe01131811182d4000027b2e00000408070902282600000617027b380000042808000006283200000600027b2e000004080709022826000006027c37000004283400000600002b0a02080709283000000600002a0013300600c60000001500001100160a38af00000000066b22000080425b0b07229a9979405a284f00000a220000e0400e0422000000405a585a580e04220000a0405a580c0e04220000803f22ec51383e066b229a99d93f5a284f00000a2200000c425a58285000000a5a5822ec51b83d066b22cdcc4c405a284f00000a22000054425a59285000000a5a585a0d0206030408287000000a285200000a0508285000000a285200000a284d00000a09285200000a284d00000a6f7400000a00000617580a061f41fe04130411043a43ffffff2a0000133003002b01000016000011000028cc00000a6fcd00000a13041613053803010000110411059a0a0006280400000a2c33066fce00000a2d2b066f5400000a2d23066fcf00000a2d1b066fd000000a75620000012c0e027b2e0000040628d100000a2b011600130611062d0538ae000000066fd200000a0328bc00000a0b070428d300000a0c082200000000322e0805302a070408285200000a28bc00000a1307120728c100000a0228260000060228260000065afe0216fe012b011600130611062d022b5973d400000a0d097cd500000a0228270000067dd600000a09066fd200000a7dd700000a09047dd800000a0922000040407dd900000a09177dda00000a09167ddb00000a09027b2e0000046fdc00000a0006096fdd00000a0000110517581305110511048e69fe04130611063aecfeffff2a56021f0c8d0d0000017d3300000402285600000a002a00000013300600480000001700001100738e00000a0a0003030405285200000a284d00000a0e04151728de00000a0c160d2b1708099a0b00020703040e0506283300000600000917580d09088e69fe04130411042ddd2a13300300b0000000180000110003280400000a2c11036f0700002b02288300000a16fe012b0116000c082d05388a000000036f0c00002b0a062c0a0e05066fdf00000a2b0116000c082d022b6e73d400000a0b077cd500000a0e047de000000a077cd500000a0e047de100000a077cd500000a0e047de200000a071f647de300000a07037de400000a0703046fe500000a7dd700000a07057dd800000a07177dda00000a07167ddb00000a07026fdc00000a0006076fe600000a002a133005003b01000019000011000522000000405b28e700000a17580a0e0422000000403003172b0119000b0f027be800000a0f027be800000a5a0f027be900000a0f027be900000a5a586c28ea00000a6b0c08226f12833a3016220000803f22000000002200000000735100000a2b1d0f027be900000a65085b22000000000f027be800000a085b735100000a000d16130438a1000000000e054a06075a5d13050e051105175806075a5d540304051105075b6b22000000405a287600000a285200000a284d00000a13060717fe0216fe01130811082d1f1106091105075d17596b0e045a226666263f5a285200000a284d00000a130611061207287a00000a2c1312067b7b00000a0e04591107fe0216fe012b011600130811082d022b13120611077d7b00000a0211062835000006000011041758130411041cfe04130811083a51ffffff2a00133007007f0000001a0000110028eb00000a72270700706fec00000a0a06280400000a2d03142b06066f0d00002b000b07280400000a2d03142b06077bed00000a000c082d03142b06087b9b00000a000d092d03142b06097bee00000a0013041104280400000a130511052d0b723f070070730500000a7a03110402220000000008141628ef00000a262a0042534a4201000100000000000c00000076342e302e33303331390000000005006c0000008c100000237e0000f81000009c12000023537472696e67730000000094230000a007000023555300342b0000100000002347554944000000442b00001407000023426c6f620000000000000002000001571da209090a000000fa25330016000001000000670000000a00000049000000350000003c000000ef00000003000000040000001a000000020000000500000005000000070000000100000007000000010000000d00000000000a000100000000000600b600aa000a00d400cd000a00db00cd000e00f600000006000301aa0006001501aa0006002701aa0012005901aa0006006f01aa000600f701aa0006001902aa000a004302280206005402aa0016008102aa001a00c00228020e00ca0200000600f902aa000a00c703b5030a00da03b5030e000f0400005300180400000a002704cd000e00f10400000a005f063f060a007f063f060600ae06aa000600d400aa000a00c606cd000600e006aa000600ee06aa0006000c07aa0006001407aa0006007707aa000600ac07aa000600e107aa0006001308fd0712005b08aa0023007b0800002300a90800002300e408000012000209aa0023003409000023006109000012007709aa002300a80900002300ec09000023002d0a000006005b0aaa000600640aaa000600870aaa001200a00aaa000600e30aaa000600290baa000e00560b00000e00810b00000a00a30bcd000600b10baa000600c70baa000e00e10b00000e00f80b00000e00fd0b00000e00050c00000e00140c00000a003b0ccd000600a90caa001600ca0caa001600d20caa000e00fe0c00001e00320daa001600550daa003300b70d00000a00e50dcd000a00080ecd000a003c0e3f060a00570ecd000a00680ecd000a00990e7a0e0a00af0e7a0e0a00ba0eb5030a00cc0ecd000a00d40ecd005700f40e00005700080f00000a001c0fcd000a00290fb5030a005e0fcd000a00840fcd000a00a80fb5030600db0faa000600e40faa0006004010aa000e00831000000600c010aa0006000211aa0023000911000006002111aa000e00581100000e00691100000e008e1100008f01961100000e00da1100009701e11100000e00541200000000000001000000000001000100010110001f002d000500010001008001100040002d000900070006000101100049002d000500070009008001100053002d0009001d0015000d0110005c0000000d00200019008101100062002d00090022001a00010110006c002d0005002e002300800110007c002d0009004a0032008001100087002d0009004a0034000600fd000a0001000c010e0001001f011200210031011600010068011b00010075011f000600fd000a000600b10138000600b60138000100c1013b000100c6013b000100cd013b000100d7013b000100df013e000100e4013e000100ee013e000100ff01410001000802410001001202410001002402450021004a024900210061025100010075011f0001008a02590001009202380001009f0238000100ad025e002100d80266005380460338005380530338001100150e490403006e033e00030070033e001600720338001600b101380016007a03380011008203a00016009203a90016009c03a9001100a3030a001100a903ac001100b003b0001300b60138003300d103b4003100e503b8000600fd000a0001005304450001000c010e0001005b040e0001006c04120021007804e20001007e041b00010085043e0001009304380001009f0238000100d7013b0001009d04ee000100a204ee000100a904ee000100ae04ee000100b404ee000100ba04ee000100c204ee000100ca04ee000100d5041b000100dc041f000100e8041f0001000005f20001000a05a900010018053e00010021053e00010029053e00010034053b0050200000000083007a0123000100a0250000000081008001290002007826000000008100870129000200d4260000000081008e01290002001e2700000000861898012900020034270000000093009e012d0002005827000000009300a4012d0003007c27000000009300aa0132000400cc27000000008108dc026e000600f827000000008600e70229000600ec28000000008100ec02720006008429000000008100ff0276000600142a0000000081000c0329000700b82c000000008100180329000700302f000000008100200329000700a82f0000000081002903290007005832000000008100870129000700d8340000000081003303290007007c350000000081008e0129000700a035000000008618980129000700cc350000000093003f038b000700f03500000000930061038b0008006c360000000093006703900009001436000000009100f90d41040a00303700000000831898019a000c0041370000000096008703a4000e005437000000009300ef03bc000f008837000000009600f803c2001000e4370000000096000204c9001200fc370000000093000a04bc0012003c380000000093002104cd00130064380000000093003104d3001400c8380000000096003704d90015005c3b0000000091187d0fc9001800943b000000008608430472001800cc3b0000000081009804e7001800183c0000000081083b056e001900383c000000008108dc026e0019005c3c00000000810845056e0019007c3c0000000086007a012300190064450000000081005705f6001a0010460000000081005c0500011e008846000000008600660529002000f84600000000810087012900200088470000000081008e0129002000f8470000000086006b0507012000f45100000000910070050d012100c85200000000810075051a012600ff5300000000861898012900290018540000000093009e05270129006c54000000009300a40534012f002855000000009300a805470135007056000000009300b10555013b0000000100b50500000100bc0500000100bc0500000100930400000200bc0500000100c40500000100930400000100930400000100ca0500000100990c00000200060e00000100d10500000200d30500000100d50500000100b50500000100b50500000200930400000100b50500000100dd0500000100e40500000100b50500000200dd0500000300e60500000100e90500000100b50500000100eb0500000200f00500000300c40500000400f60500000100eb0500000200fc0500000100dd05000001000206000002001202000003000706000004000c0600000500ca05000001000f0600000200080200000300160600000100a303000002000f0600000300080200000400160600000500ca05101006001d0600000100a303000002002406000003000f06000004000802000005001d06000006002d0600000100a303000002000f0600000300080200000400160600000500ca0500000600320600000100a303000002003906c10098016201c90098012900d100b5066701d900ba066d01e10098017301310098017801f100f40681018900980186013100fc068e01310006072900f90024079501290098019c0129003107a20129004107a80129004807ae0129005207b40129005e07b90129006707620159008507c001d9009507730159009e07c80111019e07c8013900b607cd015900c007d4017100cd07df01d900d907e4011901ea07f00119012508f60119013b08df0159009801730159004e08d401410076080202410086080a0231018f08df013101980862013901ba0610023101b50817023101c70817023101d60817024101ba061e023101f3082602310120092d0241004309340251015009170241006d093a0259018f09400259019d0947024100c3094c026901cd07df016901dc092d026901e60917024100f80952027101cd07df017101020a170271010f0a470271011d0a17024100450a58027901cd07df018101980129008900750a5e0289019801630289007f0a5e02910198019a008101980a6a024101ba0676027901480726021101c007d4014100b70a29001101bc0a8502890098018f0249004807ae014900cb0a47024900d50a47024900f00a96023900fc0ad4025100090bd9025100100bde0239001c0be702a9012e0bed02f100370b8101510098018f0251003b0bf1023900470be702b101600b7200b101670b7200090098012900b101750bd402b9018a0b0c035100940bd402c101aa0b1303c901bb0b7200d101d30b1f03d901ee0b1f03e101ee0b1f03e901ee0b1f03f1010d0c1f03f901190c2303f901260c72000c002f0c30035100330cd902c101aa0b40036900410cdf016900530c62016900650c47026900740c470214002f0c3003f100810c66030c00860c6d0329008f0c73038900990c3e000c009b0c7803f100a50c81011400860c6d030902b40c7c0309023b0b85036900ba0c8f0314009b0c7803f100c60c96031102ea0ca9031c00f80c29002400860c6d032102080dc4035100120d3e0024009b0c7803c101aa0bcc032902380dde03a901470ded021102600de30331026e0df40311017b0dd401d900900dff0331029c0d6e00d900a90dff031400f80c29000c00c20d1d042c00d00d2f042c00dc0d72004102f10d29000c00f80c29000c00980129001400980129001c009801290051029801290059025e0e570424009801290061026d0e610424002f0c3003340098016e042400750e74046902980192049900a90d99047902c50ea1048902980173012100e60e0a00a900ff0ea8049102110fad04b100210fb204a902340fb804b1003d0fb804c101aa0bbc04c101490f7803c101540fc3049100900dce04b102980173019100740fd604a102960fef04a102b50ff804a102be0f01058900060e3e008900c80f3e008900ca0f3e006900cc0f6e00c90298019a00d102980114056900f30f1c0569000210470259001610df016900f308ae0169002010ae0169002d10620169004e106405c1015c107d05b9006a108205b9017210880591028a108d05e1029310a900b900a81092055100b110de02e902ca1098051102d2109e05f100dd1096035100e110de025100e7106e005100f810d9025100810cae05f102a4019603f9021c0be702f9021411e702f902b5084702f902d60847020103ba06b805f902f308c00541002911c705b1012e110b063c003f111d06b10147117200b10150117200b1015f112306090373112906b1017b11d40251008a1133061903980129001903a2113b062103ab113e001903b71141001903bf1141001903c5113e001903d1113b001903eb1140061903f3114506b101aa014c061102ff1167061c002f0c8b062103a2113e0021030e123e00210315123e0019031f12910619032a129406710038120c038100aa014c06f1004512a1065100d1053e005100d3053e0061024f1261043903190cb40639035e12ba06a1006812c506910273124500e1028712c9060800740081000800780086000c00b9005d012e001300f3062e000b00ea0600037b045204e1037b0452049d02f902ff02030307031903360352039c03d203070434045c047f04e6040a0523056b057405cf050306530676069806a606db06040001000800020000003f037d000000840523010000a4017d0000003f037d00000090057d00020009000300020023000500020025000700020026000900020027000b0029034b03b603bd032704660415060480000000000000000000000000000000009d06000000000000000000000000000000009300000000000400000000000000000000000100c400000000000000000000000000000000000000e50000000000000000000000000000000000000038010000000000000000000000000000000000006702000000000400000000000000000000000100b402000000000000000000000000000000000000140d00000000060005003100da013100ea013f00fd0187007f023f008a023f0046030501f9033f00c9043f00dc043f00e10487000f05050186063100c00600000000003c4d6f64756c653e0056616c6865696d426f774265616d56362e646c6c004b61796f6b656e4175726156310056616c6865696d536f6c6f546f6f6c6b69740044627a506f7765720044627a426f6d62563200426f6d62506c616e00506f696e7400426f774265616d563600426f774265616d56697375616c5636004265616d44616d616765004265616d5465727261696e00556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f7572006d73636f726c69620053797374656d004f626a6563740056616c75655479706500617373656d626c795f76616c6865696d00506c61796572004f776e6572004d6174657269616c006d6174657269616c005465787475726532440074657874757265005472616e73666f726d007368656c6c7300556e697479456e67696e652e5061727469636c6553797374656d4d6f64756c65005061727469636c6553797374656d00666c616d6573004c6967687400676c6f7700536574757000466f6c6c6f7700557064617465004f6e44657374726f79002e63746f72005363616c650052616e67650044616d616765004d6f64650047656e65726174696f6e0068656c6400666c79696e67006578706c6f64696e6700626f6f7374656400626f726e006465746f6e61746564006e657874576f726b00566563746f723300706f736974696f6e00646972656374696f6e0063656e7465720047616d654f626a656374006f72620053797374656d2e436f6c6c656374696f6e732e47656e65726963004c6973746031006d6174657269616c73004c696e6552656e64657265720072696e677300556e697479456e67696e652e506879736963734d6f64756c6500436f6c6c69646572007461726765747300746172676574437572736f72007465727261696e437572736f72006372617465720053797374656d2e436f7265004861736853657460310049446573747275637469626c6500686974006765745f526164697573004669726500496e707574416c6c6f77656400436f6c6f72004d616b654d6174657269616c004275696c6456697375616c00416e696d617465004465746f6e61746500576f726b426c61737400436c65617256697375616c005261646975730044616d616765427564676574005465727261696e427564676574005370656564004372617465720058005a00456e61626c6564004b61796f6b656e0061757261005365744b61796f6b656e004c6173744572726f7200537461747573006f776e65720076697375616c00626f6d620053797374656d2e5265666c656374696f6e004669656c64496e666f004472617754696d65004d6574686f64496e666f0054616b65496e7075740043616e496e70757400436f6e6669677572650044697361626c65004f776e73004974656d44726f70004974656d44617461004973426f7700457863657074696f6e004661756c74004f6e426f77557064617465006765745f4d6f64654368616e6765640065666665637473007061727469636c654d6174657269616c00736f66745465787475726500677573747300766f72746578006e6578745061727469636c6573006d6f64650054696e740068616c6f0073686561746800636f726500636f696c4100636f696c42006d757a7a6c6541006d757a7a6c654200696d7061637452696e6700737061726b73006d757a7a6c654c6967687400656e644c69676874005a53796e63416e696d6174696f6e00616e696d6174696f6e0064726177416e696d6174696f6e006c617374537465700073746172746564006e65787444616d61676500666972696e67006765745f52616e6765006765745f44616d6167655065725469636b004c696e65004d616b654c69676874004869646500537465700052696e670044616d6167654d6f6e7374657273004d6f64654368616e6765640044616d6167655065725469636b004465617468004869740045786361766174650044696700706c61796572006b61796f6b656e00636f6c6f72007261646975730078007a00656e61626c656400776561706f6e00650064740063006e616d6500776964746800636f756e740072616e6765006c696e650073696465007570006f726967696e006c656e6774680064616d61676500636f6c6c69646572007365656e00637572736f7200706f696e740053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d426f774265616d5636005368616465720046696e64006f705f496d706c6963697400496e76616c69644f7065726174696f6e457863657074696f6e0054657874757265466f726d6174004d6174686600436c616d70303100536574506978656c73004170706c7900546578747572650054657874757265577261704d6f6465007365745f777261704d6f6465007365745f6d61696e5465787475726500536574496e74007365745f636f6c6f720048617350726f706572747900536574436f6c6f72007365745f72656e6465725175657565005072696d697469766554797065004372656174655072696d6974697665007365745f6e616d65006765745f7472616e73666f726d00436f6d706f6e656e7400536574506172656e7400476574436f6d706f6e656e74007365745f656e61626c65640044657374726f790052656e6465726572007365745f7368617265644d6174657269616c00556e697479456e67696e652e52656e646572696e6700536861646f7743617374696e674d6f6465007365745f736861646f7743617374696e674d6f6465007365745f72656365697665536861646f777300416464436f6d706f6e656e74005061727469636c6553797374656d53746f704265686176696f720053746f70004d61696e4d6f64756c65006765745f6d61696e007365745f6c6f6f70007365745f6d61785061727469636c6573004d696e4d61784375727665007365745f73746172744c69666574696d65007365745f73746172745370656564007365745f737461727453697a65004d696e4d61784772616469656e74007365745f7374617274436f6c6f72005061727469636c6553797374656d53696d756c6174696f6e5370616365007365745f73696d756c6174696f6e537061636500456d697373696f6e4d6f64756c65006765745f656d697373696f6e007365745f726174654f76657254696d650053686170654d6f64756c65006765745f7368617065005061727469636c6553797374656d536861706554797065007365745f736861706554797065007365745f7261646975730056656c6f636974794f7665724c69666574696d654d6f64756c65006765745f76656c6f636974794f7665724c69666574696d65007365745f7370616365007365745f79004e6f6973654d6f64756c65006765745f6e6f697365007365745f737472656e677468007365745f6672657175656e6379007365745f7363726f6c6c537065656400436f6c6f724f7665724c69666574696d654d6f64756c65006765745f636f6c6f724f7665724c69666574696d65004772616469656e74004772616469656e74436f6c6f724b6579006765745f7768697465006765745f726564004772616469656e74416c7068614b6579005365744b657973005061727469636c6553797374656d52656e646572657200506c6179006765745f67616d654f626a656374007365745f72616e6765007365745f696e74656e73697479004c69676874536861646f7773007365745f736861646f7773006765745f706f736974696f6e006765745f7570006f705f4164646974696f6e007365745f706f736974696f6e0054696d65006765745f74696d650053696e006f705f4d756c7469706c79007365745f6c6f63616c5363616c65004368617261637465720049734465616400497354656c65706f7274696e6700476574457965506f696e740048756d616e6f69640047657441696d446972006765745f6e6f726d616c697a656400537472696e6700436f6e636174004265686176696f7572006765745f656e61626c6564004170706c69636174696f6e006765745f6973466f637573656400496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c65004d696e696d61700049734f70656e0043686174006765745f696e7374616e636500486173466f63757300416464006765745f6f6e6500496e743332007365745f757365576f726c645370616365007365745f706f736974696f6e436f756e74007365745f73746172745769647468007365745f656e645769647468004c657270006765745f4974656d006765745f636f6c6f720061006765745f436f756e7400436f73005175617465726e696f6e0045756c657200536574506f736974696f6e004d696e005068797369637300517565727954726967676572496e746572616374696f6e004f7665726c617053706865726500436c656172004865696768746d617000476574486569676874007900556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e006765745f64656c746154696d6500526179636173744869740053706865726543617374416c6c006765745f636f6c6c6964657200476574436f6d706f6e656e74496e506172656e74006f705f457175616c697479006765745f64697374616e6365006f705f496e657175616c69747900456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e74004d6f76654e6578740049446973706f7361626c6500446973706f7365003c4372617465723e625f5f30006200436f6d70617269736f6e6031004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c65676174653100436f6d70696c657247656e6572617465644174747269627574650053696e676c6500436f6d70617265546f004d617468004365696c696e6700536f72740053797374656d2e52756e74696d652e496e7465726f705365727669636573005374727563744c61796f7574417474726962757465004c61796f75744b696e64004d6574686f644261736500496e766f6b6500426f6f6c65616e00417267756d656e74457863657074696f6e006d5f6c6f63616c506c617965720053686172656444617461006d5f736861726564004974656d54797065006d5f6974656d5479706500547970650047657454797065004d656d626572496e666f006765745f4e616d65006765745f4d657373616765006765745f4c656e67746800537562737472696e67004d697373696e674669656c64457863657074696f6e0053657456616c7565002e6363746f720052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650042696e64696e67466c616773004765744669656c64004765744d6574686f6400720067006765745f73746172745769647468004b65796672616d6500416e696d6174696f6e4375727665007365745f77696474684375727665007365745f77696474684d756c7469706c69657200536574416374697665007365745f656e64436f6c6f72007365745f6e756d4361705665727469636573004c696e65416c69676e6d656e74007365745f616c69676e6d656e740049734e756c6c4f72456d70747900536574426f6f6c0047657443757272656e74576561706f6e0041747461636b006d5f61747461636b006d5f64726177416e696d6174696f6e537461746500536574466c6f6174006f705f5375627472616374696f6e004c617965724d61736b004765744d61736b0052617963617374416c6c004d61780043726f7373006765745f7371724d61676e6974756465006765745f72696768740052616e646f6d00456d6974506172616d73007365745f76656c6f6369747900436f6c6f72333200456d697400476574416c6c4368617261637465727300546f4172726179004973506c6179657200497354616d65640042617365414900476574426173654149004d6f6e737465724149004973456e656d790047657443656e746572506f696e7400446f7400486974446174610044616d6167655479706573006d5f64616d616765006d5f6c696768746e696e67006d5f706f696e74006d5f646972006d5f70757368466f726365006d5f72616e67656400536b696c6c7300536b696c6c54797065006d5f736b696c6c0053657441747461636b6572004f7665726c617043617073756c65006d5f63686f70006d5f7069636b617865006d5f746f6f6c54696572006d5f686974436f6c6c6964657200436c6f73657374506f696e74004365696c546f496e740053717274005a4e65745363656e6500476574507265666162006d5f6974656d44617461006d5f737061776e4f6e4869745465727261696e00537061776e4f6e4869745465727261696e0000000000434c0065006700610063007900200053006800610064006500720073002f005000610072007400690063006c00650073002f0041006400640069007400690076006500001f53007000720069007400650073002f00440065006600610075006c00740000414b00610079006f006b0065006e00200061007500720061002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e0000135f0053007200630042006c0065006e00640000135f0044007300740042006c0065006e006400000f5f005a005700720069007400650000155f00540069006e00740043006f006c006f00720000354b00610079006f006b0065006e00200072006500640020007000720065007300730075007200650020007300680065006c006c00002b4b00610079006f006b0065006e00200072006900730069006e006700200066006c0061006d00650073000017530070006900720069007400200042006f006d0062000013530075007000650072006e006f0076006100007f200069006e00200066006c0069006700680074002e00200049006d00700061006300740020006f00720020003200300020007300650063006f006e006400730020006400650074006f006e0061007400650073003b00200074006f00670067006c00650020004f00460046002000630061006e00630065006c0073002e00003d440042005a0020007300700068006500720065002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e00001b45006e00650072006700790020006f00720062006900740020000021200062006c006100730074003a0020006f0062006a006500630074007300200000032f0000152c0020007400650072007200610069006e00200000492e00200054006f00670067006c00650020004f00460046002000630061006e00630065006c0073002000720065006d00610069006e0069006e006700200077006f0072006b002e00007b42006c00610073007400200063006f006d0070006c006500740065002e002000520065006c006500610073006500200061006e006400200063006c00690063006b00200062006f0077002000610074007400610063006b00200074006f0020006c00610075006e0063006800200061006700610069006e002e00002349006e00760061006c00690064002000440042005a00200070006f0077006500720000053a002000002753006f006c006f0054006f006f006c006b00690074005f004b00610079006f006b0065006e000033480075006d0061006e006f00690064002e006d005f00610074007400610063006b004400720061007700540069006d006500002753006f006c006f0054006f006f006c006b00690074005f00440042005a0042006f006d006200003353006f006c006f0054006f006f006c006b00690074005f0042006f0077004200650061006d0044007200690076006500720000216d005f00610074007400610063006b004400720061007700540069006d0065000013540061006b00650049006e0070007500740000315000610072007400690063006c00650073002f005300740061006e006400610072006400200055006e006c0069007400003f4e006f00200063006f006d00700061007400690062006c00650020006200650061006d002000730068006100640065007200200066006f0075006e00640000174200650061006d00560069007300750061006c0073000021540075007200620075006c0065006e007400200063006f0072006f006e00610000174300790061006e00200070006c00610073006d006100001d57006800690074006500200068006f007400200063006f0072006500001d45006e0065007200670079002000680065006c006900780020004100001d45006e0065007200670079002000680065006c006900780020004200001f4300680061007200670069006e0067002000720069006e00670020004100001f4300680061007200670069006e0067002000720069006e00670020004200001749006d0070006100630074002000680061006c006f00002756006f0072007400650078002000770069006e006400200072006900620062006f006e002000003753007700690072006c0069006e00670020007000720065007300730075007200650020007000610072007400690063006c0065007300001b49006d007000610063007400200073007000610072006b00730000194d0075007a007a006c00650020006c006900670068007400001949006d00700061006300740020006c00690067006800740000176400720061007700700065007200630065006e007400000f440065006600610075006c00740000197300740061007400690063005f0073006f006c0069006400001b440065006600610075006c0074005f0073006d0061006c006c00000b70006900650063006500000f7400650072007200610069006e00000f760065006800690063006c00650000175000690063006b00610078006500490072006f006e00005f490072006f006e0020007000690063006b0061007800650020007400650072007200610069006e00200069006d0070006100630074002000700072006500660061006200200075006e0061007600610069006c00610062006c0065002e0000003ad4192fb2c3674eb9e6977169c7f0810008b77a5c561934e08903061211030612150306121904061d121d0306122103061225052001011211032000010400010c020500020c080202060802060202060c030611290306122d0706151231011215070615123101123504061d12390706151231011118070615123d0112410320000c03200002062001121511450328000c043000000004060000000400010c080900011512310111180c052002010c0c03061208040001010202060e0306122003061210030612490306124d050001021211060002011211080300000105000102125505000101125908000302121112550c04061d123506200111451145030612350306125d09200412350e0c11450806200212250e0c0520010112550c00050112351129112911290c08200301112911290c032800020c0006011211112911290c0c0c1200060112111239112911290c15123d0112410d0006011211112911290c0c10080700020112111129040000fa43042001010805000112690e05000102126d042001010e0820040108081175020400010c0c072004010c0c0c0c062001011d11450620010111808105200101126905200101127d052002010e08052001011145042001020e062002010e1145070001122d118085042000121d06200201121d02053001001e00040a011239042001010205000101126d050a0112808d05200101121506200101118091040a011221072002010211809505200011809906000111809d0c0620010111809d0700011180a11145062001011180a1062001011180a50520001180a90520001180ad062001011180b1042001010c0520001180b50520001180b90520001180bd04000011450620020111450c0b2002011d1180c51d1180c90800011180a11280c1050a011280cd042000122d040a011225062003010c0c0c062001011180d136071712691d114508080c0c0c114508122d123912808d122d1180991180a91180ad1180b51180b91180bd1280c1021d1180c51d1180c9042000112904000011290800021129112911290520010111290300000c070002112911290c0507030c0802030701020307010c0407020c0c062001112911290500020e0e0e050702021129030000020500001280fd06151231011215052001011300090704126912151215020500020e1c1c040a011235061512310112351307091145114508122d123912808d122d1235020600030c0c0c0c0520011300080420001145032000080800031181050c0c0c09000211291181051129062002010811290500020c0c0c0c07080c0c081145080c1129020c00041d123911290c0811810d0615123d01124106151231011118070002021129100c0500010e1d1c0b070608111811290c021d1c04000102081000061d11811911290c11290c0811810d0420001239050a011280d907000202126d126d15070a0c0c0211811912391259021d118119081d12390920001511811d011300071511811d01121504200013000c07031215021511811d01121507000208111811180806151281250111180401000000042001080c040702080c0400010d0d0715128125011118052002011c180a20010115128125011300120706151231011118080808151231011118020620010111813907000202124d124d0620021c1c1d1c0406128149040611814d0520001281510320000e0600030e0e0e0e0520020e0808040a0112080700020212491249052002011c1c040a011210040a011220080704122d1259020208000112815111815d08200212490e118161082002124d0e1181610407011145040a01125d072001011d1181650620010112816940071b126912350c081d114508080c0c0c122d1180991180a91180b91180bd1280c1122d1180991180a91180ad021d12351d1235081d1181651d1180c51d1180c90620010111816d080703122d12351235080703122d12251225040001020e052002010e0204200012550406128171052002010e0c050001081d0e0f00051d118119112911290c0811810d0900031129112911290c0700011181811145062001011181810720020111817d0833071d1129112911290c081181191129112911290c0c080c112911290c1129080c0c0c1129112911817d0211291d0e1d11811908070705080c0c0c02090000151231011280d907151231011280d90520001d1300052000128185090002021280d91280d90700020c1129112904061181910406118199062001011280d90620010112818d1307081280d911290c12818d1d1280d9080211290e00051d1239112911290c0811810d0f070515123d01124112391d12390802040a01124105200102130002060603061239080703124112818d02040001080c0d070908080c1129080811290c0205000012819d052001122d0e040a01125103061255110007122d1129122d1280d90c12551255020e0706122d12511255128149122d020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f77730100007c89000000000000000000009e890000002000000000000000000000000000000000000000000000908900000000000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058a000006c02000000000000000000006c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004cc010000010053007400720069006e006700460069006c00650049006e0066006f000000a801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000004c001500010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d00560036002e0064006c006c00000000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005400150001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d00560036002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000c000000b03900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper
local updatingKayoken=false
local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','BowBeamV6')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_BowBeamV6_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=helperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write bow-beam helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Explosive-fists helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','BowBeamV6'),'Explosive-fists helper class')
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
    playerStatus.Caption=kayokenCheck.Checked and 'Kayoken ON: red aura, 32x DBZ damage, 2x size. Death Beam 16000/tick, 120m. Bombs snapshot power on launch.' or 'Kayoken OFF: normal power restored for beams and future bombs. In-flight bombs keep their launch power.'
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
      watch=createTimer(form,false);watch.Interval=250
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
    playerStatus.Caption=s.mode>=2 and 'Bow equipped: click to launch one slow bomb. Spirit Bomb 40m / Supernova 120m radius. Detonates on impact or after 20s. Blast work continues in batches; toggle OFF cancels it. Visuals are local.' or s.mode==1 and 'Death Beam: hold bow attack. 80m terrain excavation; damages creatures and destructible objects every 0.1s. Release to stop. Visuals are local.' or 'Kameha: hold bow attack. Cyan beam, 80m reach, hostile monsters only. Release to stop. Visuals are local.'
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
      watch=createTimer(form,false);watch.Interval=250
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
local minerHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c01030076f2c66a0000000000000000e00002210b010b00000e00000006000000000000ce2d00000020000000400000000000100020000000020000040000000000000004000000000000000080000000020000000000000300408500001000001000000000100000100000000000001000000000000000000000007c2d00004f00000000400000d002000000000000000000000000000000000000006000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000d40d000000200000000e000000020000000000000000000000000000200000602e72737263000000d0020000004000000004000000100000000000000000000000000000400000402e72656c6f6300000c0000000060000000020000001400000000000000000000000000004000004200000000000000000000000000000000b02d0000000000004800000002000500202400005c0900000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133002003100000001000011007e0500000414280300000a16fe010a062d0b7201000070730400000a7a0280030000041480020000041780010000042a3a001680010000041480030000042a133002003200000001000011007e0100000417332202280500000a2c1a027e03000004280600000a2c0d027e0700000a280600000a2b0116000a2b00062a4e00026f0800000a80020000042802000006002a00001b300200a600000002000011000228030000060b072d053895000000007e04000004280500000a2c157e040000047b0600000402280900000a16fe012b0117000b072d23007e040000046f0a000006007e040000046f0a00000a280b00000a00148004000004007e04000004280500000a0b072d21007223000070730c00000a280100002b80040000047e04000004027d06000004007e040000046f080000060000de0c0a000628040000060000de00002a000001100000000010008898000c0500000172d003000001280e00000a72510000701f346f0f00000a80050000042a00000013300200500000000300001100027b0600000428030000062c10027b060000046f1000000a16fe012b0116000c082d04140b2b26027b060000046f1100000a0a062c0f067b1200000a7b1300000a1f0c2e03142b0106000b2b00072a133003004300000004000011000228070000060a0614fe0116fe010b072d022b2d7e05000004027b06000004027b060000046f1400000a8c170000016f1500000a0006066f1600000a7d1700000a2a0013300200390000000100001100027b080000042c10027b07000004280500000a16fe012b0117000a062d12027b07000004027b090000046f1800000a0002167d080000042a2600022809000006002a001b300100460000000200001100027b0600000428030000060b072d16000228090000060002280a00000a280b00000a002b1f000228080000060000de130a00062804000006000228090000060000de00002a000001100000000026000b310013050000011b300200b90000000200001100000228070000062c0d027b060000046f1900000a2b0116000b072d0d0002280900000600dd8d000000027b07000004280500000a0b072d1102027b060000046f0200002b7d07000004027b07000004280500000a0b072d0b7265000070731b00000a7a027b080000040b072d1a0002027b070000046f1c00000a7d0900000402177d0800000400027b0700000422000020416f1800000a000228080000060000de130a00062804000006000228090000060000de0000002a0000000110000000000100a2a30013050000012600022809000006002a1e02281d00000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c00000050030000237e0000bc0300000004000023537472696e677300000000bc070000a0000000235553005c0800001000000023475549440000006c080000f000000023426c6f620000000000000002000001571502000908000000fa253300160000010000001800000003000000090000000e000000040000001d000000020000000400000001000000040000000200000000000a00010000000000060065005e000a008f0083000e00c00000000600e600d40006000f015e001200460183000e00720100001f007b0100000600f301d30106001302d301060051025e000a00650083000a009b0283000a00a50283000600db025e000600e0025e0006000403d4000e001a0300000e002b0300002300450300000e0059030000570060030000060084035e000600dc035e0000000000010000000000010001008101100022002f000500010001000101100042002f0009000600070016009d000a001600a5000d001100c70010001100cd0014003300f000180006002401100001004f0132000100580136000100640139005020000000009600f8001c0001008d200000000096000201220002009c200000000093000a0126000200da2000000000930019012c000300f0200000000096001f011c000400b421000000009118d40222000500d42100000000810084013c00050030220000000086008c01410005008022000000008100940141000500c5220000000086009c0141000500d022000000008100a401410005003423000000008100ab01410005000c24000000008100b601410005001624000000008618c0014100050000000100c60100000100c60100000100cd0100000100c6014900c00145005100c0014100210045024a005900c0015200610067025b0061004502610019007302100029008102690061008d0261006900b0026d006100bf0272007100c00152007100c70278007900f2028900790011039000910024039800990034033c00410050039c00a1006a03a00091007603ac0021008b03b00041009403ac004100a50339003100b203bc009100bc0398006900c5037800c100c00152003100f603ac001100c00141002e000b00c6002e001300cf0057008300a400b60004800000000000000000000000000000000031020000040000000000000000000000010055000000000000000000000000000000000000006c00000000000000000000000000000000000000af000000000000000000000000000000000000002a01000000001b007e003500c1000000003c4d6f64756c653e0056616c6865696d52617069644d696e657256312e646c6c0052617069644d696e657256310056616c6865696d536f6c6f546f6f6c6b69740052617069644d696e65724472697665725631006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e6572006472697665720053797374656d2e5265666c656374696f6e004669656c64496e666f005374616d696e6100436f6e6669677572650044697361626c65004f776e7300457863657074696f6e004661756c74005469636b004f776e657200556e697479456e67696e652e416e696d6174696f6e4d6f64756c6500416e696d61746f7200616e696d61746f7200616363656c657261746564006f726967696e616c5370656564004974656d44726f70004974656d44617461005069636b6178650050726f7465637400526573746f72650052656c6561736500557064617465004c617465557064617465004f6e44657374726f79002e63746f7200706c61796572006572726f720053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d52617069644d696e65725631006f705f457175616c697479004d697373696e674669656c64457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006765745f4d657373616765006f705f496e657175616c69747900436f6d706f6e656e740047616d654f626a656374006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650042696e64696e67466c616773004765744669656c6400436861726163746572004973446561640048756d616e6f69640047657443757272656e74576561706f6e0053686172656444617461006d5f73686172656400536b696c6c7300536b696c6c54797065006d5f736b696c6c54797065004765744d61785374616d696e610053696e676c650053657456616c7565004765744d61784475726162696c697479006d5f6475726162696c697479007365745f737065656400496e41747461636b00476574436f6d706f6e656e74496e4368696c6472656e00496e76616c69644f7065726174696f6e457863657074696f6e006765745f737065656400002150006c0061007900650072002e006d005f007300740061006d0069006e006100002d53006f006c006f0054006f006f006c006b00690074005f00520061007000690064004d0069006e006500720000136d005f007300740061006d0069006e006100003750006c006100790065007200200061006e0069006d00610074006f007200200075006e0061007600610069006c00610062006c00650000000000084d4cd67adb8e49bbe6832c0aa2c0cf0008b77a5c561934e08902060802060e0306120d0306120c0306121105000101120d0300000105000102120d0500010112150306121902060202060c04200012210320000104200101080700020212111211042001010e0307010205000102123107000202123112310320000e0420001239050001011231053001001e00040a01120c050702121502060001123d114107200212110e114503200002030612510306115907070312211221020320000c052002011c1c050702122102042001010c040a0112190801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773010000a42d00000000000000000000be2d0000002000000000000000000000000000000000000000000000b02d0000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001800010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d00520061007000690064004d0069006e0065007200560031002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800180001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d00520061007000690064004d0069006e0065007200560031002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000c000000d03d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','RapidMinerV1')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_RapidMinerV1_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=minerHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write rapid-miner helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Rapid-miner helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','RapidMinerV1'),'Rapid-miner helper class')
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
  minerButton.Caption='Rapid miner: OFF'
end
ValheimRapidMinerStop=stopMiner
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopMiner();return close() end
form.OnDestroy=function() stopMiner();destroy() end
minerButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopMiner();playerStatus.Caption='Rapid miner disabled.';return end
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
      watch=createTimer(form,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          assert(readInteger(state.enabled)==1,'Game callback stopped after an error')
        end)
        if not active then
          local stopped,stopError=pcall(stopMiner)
          playerStatus.Caption='Rapid miner stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;minerButton.Caption='Rapid miner: ON'
    playerStatus.Caption='Equip a pickaxe and hold attack: 10x swing animations, stamina refill and full pickaxe durability. Normal mining range and tier requirements apply.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopMiner)
    showMessage('Valheim rapid mining: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

-- The helper assembly is embedded so the .CT remains a single-file deliverable.
do
local hoeHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300bef3c66a0000000000000000e00002210b010b00001000000006000000000000ee2f00000020000000400000000000100020000000020000040000000000000004000000000000000080000000020000000000000300408500001000001000000000100000100000000000001000000000000000000000009c2f00004f00000000400000c802000000000000000000000000000000000000006000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000f40f0000002000000010000000020000000000000000000000000000200000602e72737263000000c8020000004000000004000000120000000000000000000000000000400000402e72656c6f6300000c0000000060000000020000001600000000000000000000000000004000004200000000000000000000000000000000d02f0000000000004800000002000500e4240000b80a0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013300300540000000100001100d003000001280300000a021f346f0400000a0a0614280500000a2d1a066f0600000ad00e000001280300000a280700000a16fe012b0116000c082d11720100007002280800000a730900000a7a060b2b00072a52000280030000041480020000041780010000042a3a001680010000041480030000042a133002003200000002000011007e0100000417332202280a00000a2c1a027e03000004280b00000a2c0d027e0c00000a280b00000a2b0116000a2b00062a4e00026f0d00000a80020000042803000006002a00001b300200c300000003000011000228040000060b072d0538b2000000007e04000004280a00000a2c157e040000047b0b00000402280e00000a16fe012b0117000b072d23007e040000046f09000006007e040000046f0f00000a281000000a00148004000004007e04000004280a00000a0b072d21007211000070731100000a280100002b80040000047e04000004027d0b000004007e04000004036f0a0000060000de280a00062805000006007e04000004280a00000a16fe010b072d0b7e040000046f090000060000de00002a0001100000000010008999002806000001033003005800000000000000723b00007028010000068005000004724f00007028010000068006000004726900007028010000068007000004728f00007028010000068008000004d014000001280300000a72b30000701f34281300000a80090000042a13300300630000000400001100027b0b00000428040000062c10027b0b0000046f1400000a16fe012b0116000c082d04140b2b397e09000004027b0b000004146f1500000a74080000010a062c17067b1600000a7b1700000a72cd000070281800000a2d03142b0106000b2b00072a0013300300430000000200001100027b0c0000042c10027b0b000004280a00000a16fe012b0117000a062d1c7e06000004027b0b000004027b0d0000048c0e0000016f1900000a0002167d0c0000042a00133004002d01000005000011000228080000060a062c21027b0b0000046f1a00000a2c14032c11281b00000a2d0a281c00000a16fe012b0116000b072d0d000228090000060038ed000000027b0c0000040b072d2400027e06000004027b0b0000046f1d00000aa50e0000017d0d00000402177d0c000004007e06000004027b0b000004027b0d00000422cdcc4c3d281e00000a8c0e0000016f1900000a007e05000004027b0b000004027b0b0000046f1f00000a8c0e0000016f1900000a0006066f2000000a7d2100000a72e1000070282200000a2d3f72f7000070282200000a2d0c7205010070282200000a2c27282300000a7e08000004027b0b0000046f1d00000aa50e0000015922cdcc4c3dfe0216fe012b0117000b072d1b7e07000004027b0b000004282300000a8c0e0000016f1900000a002a0000001b3002004c00000003000011000002280800000614fe0116fe010b072d0702280900000600027b0b00000428040000060b072d0c02280f00000a281000000a0000de130a00062805000006000228090000060000de00002a011000000000010036370013060000012600022809000006002a1e02282400000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c000000b8030000237e0000240400002c04000023537472696e67730000000050080000180100002355530068090000100000002347554944000000780900004001000023426c6f620000000000000002000001571d02000908000000fa253300160000010000001b000000030000000d0000000d000000080000002400000001000000020000000500000001000000040000000100000000000a0001000000000006005f0058000a0089007d000e00ba0000000600e000ce0006000e01ce0006003a0158000e00740100001f007d0100000600ed01cd0106000d02cd0106003d02580006004202580006006602ce000600960258000600ab0258000600b90258000a005f007d000a00f5027d000a00ff027d000e00350300000e004803000006005903ce0023006b0300000e009b0300000600c903580012000d0400000a001e047d0000000000010000000000010001008101100020002b00050001000100010110003e002b0009000a000800160097000a0016009f000d001100c10010001100c70014003300f0001e003300f8001e003300fe001e00330006011e0033001901220051804f01440006005801100001005e014c000100660144005020000000009300ea0018000100b020000000009600230126000200c5200000000096002d012c000300d420000000009300350130000300122100000000930044013600040028210000000096004a013c00050008220000000091182e032c0008006c2200000000810086014f000800dc220000000086008a01540008002c230000000086009201580008006824000000008100970154000900d0240000000081009e0154000900da24000000008618a8015400090000000100ae0100000100b30100000100b30100000100ba0100000100b30100000200c00100000300ca0100000100c0014900a8015d005100a801540059005402620059007302690021007c02710021008802790059009d027e007900b20286008100a8018c008900cf02990089007c029f001900db0210003100e902ab0089009d029f0091000a03af0089001903b4009900a8018c0099002103ba0059003e03cb00a9005203d300b1006403d70041007603de00b9007f030d0079007c02e20021008603f000a9008f03d300c1009f03f600c100b703f6002100c003fa00c900ce03ff00a900d20305014100e00305014100f1034400d10014040901d90023040e011100a80154000c00280047002e000b0018012e00130021019100a700c500e80012010480000000000000000000000000000000002b02000004000000000000000000000001004f000000000000000000000000000000000000006600000000000000000000000000000000000000a900000000000000000000000000000000000000fe03000000002500c00000000000003c4d6f64756c653e0056616c6865696d5261706964486f6556312e646c6c005261706964486f6556310056616c6865696d536f6c6f546f6f6c6b6974005261706964486f654472697665725631006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e6572006472697665720053797374656d2e5265666c656374696f6e004669656c64496e666f004669656c64005374616d696e610044656c61790050726573736564004c617374557365004d6574686f64496e666f0052696768744974656d00436f6e6669677572650044697361626c65004f776e7300457863657074696f6e004661756c74005469636b00496e74657276616c004f776e6572006368616e676564006f726967696e616c44656c6179004974656d44726f70004974656d4461746100486f650052656c65617365005374657000557064617465004f6e44657374726f79002e63746f72006e616d6500706c61796572006572726f720074616b65496e7075740064740053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d5261706964486f65563100547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650042696e64696e67466c616773004765744669656c64006f705f457175616c697479006765745f4669656c64547970650053696e676c65006f705f496e657175616c69747900537472696e6700436f6e636174004d697373696e674669656c64457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006765745f4d65737361676500436f6d706f6e656e740047616d654f626a656374006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f720048756d616e6f6964004765744d6574686f640043686172616374657200497344656164004d6574686f644261736500496e766f6b650053686172656444617461006d5f736861726564006d5f6e616d650053657456616c756500496e506c6163654d6f646500487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c0047657456616c7565004d617468004d696e004765744d61785374616d696e61004765744d61784475726162696c697479006d5f6475726162696c69747900617373656d626c795f7574696c73005a496e70757400476574427574746f6e0054696d65006765745f74696d6500000f50006c0061007900650072002e00002953006f006c006f0054006f006f006c006b00690074005f005200610070006900640048006f00650000136d005f007300740061006d0069006e00610000196d005f0070006c00610063006500440065006c006100790000256d005f0070006c006100630065005000720065007300730065006400540069006d00650000236d005f006c0061007300740054006f006f006c00550073006500540069006d0065000019470065007400520069006700680074004900740065006d00001324006900740065006d005f0068006f00650000154a006f00790041006c0074004b00650079007300000d410074007400610063006b0000114a006f00790050006c006100630065000000fb8eec62dcdd314298bcdac24a08ac730008b77a5c561934e08902060802060e0306120d0306120c05000112110e030612110306121505000101120d0300000105000102120d05000101121907000301120d020c02060c04cdcc4c3d02060204200012210320000104200101020420010108060001122d113107200212110e11350700020212111211042000122d07000202122d122d0500020e0e0e042001010e07070312111211020500010212450700020212451245030701020320000e042000124d050001011245053001001e00040a01120c05070212190207200212150e1135032000020620021c1c1d1c0306125d050002020e0e0707031221122102052002011c1c030000020420011c1c0500020c0c0c0320000c040001020e0300000c0507021221020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f777301c42f00000000000000000000de2f0000002000000000000000000000000000000000000000000000d02f0000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000001001000000018000080000000000000000000000000000001000100000030000080000000000000000000000000000001000000000048000000584000006c02000000000000000000006c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004cc010000010053007400720069006e006700460069006c00650049006e0066006f000000a801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000004c001600010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d005200610070006900640048006f006500560031002e0064006c006c0000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005400160001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d005200610070006900640048006f006500560031002e0064006c006c000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000c000000f03f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','RapidHoeV1')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_RapidHoeV1_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=hoeHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write rapid-hoe helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Rapid-hoe helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','RapidHoeV1'),'Rapid-hoe helper class')
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
      watch=createTimer(form,false);watch.Interval=250
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
local dragHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300b124c76a0000000000000000e00002210b010b000088000000060000000000005ea700000020000000c000000000001000200000000200000400000000000000040000000000000000000100000200000000000003004085000010000010000000001000001000000000000010000000000000000000000008a700005300000000c00000d00200000000000000000000000000000000000000e000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e7465787400000064870000002000000088000000020000000000000000000000000000200000602e72737263000000d002000000c0000000040000008a0000000000000000000000000000400000402e72656c6f6300000c00000000e0000000020000008e0000000000000000000000000000400000420000000000000000000000000000000040a70000000000004800000002000500f45a0000144c000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b300300870000000100001100160b7e04000004250c1201280400000a00007e040000046f0500000a1efe040d092d0b7201000070730600000a7a02172e090218fe0116fe012b0116000d092d062818000006007e04000004730b0000060a06027d1300000406037d14000004066f0700000a00724d000070800500000400de100716fe010d092d0708280800000a00dc002a00011000000200030072750010000000001b300200430000000200001100160a7e04000004250c1200280400000a00007e040000046f0500000a2c0c7e040000046f0900000a2b0114000bde100616fe010d092d0708280800000a00dc00072a0001100000020003002d30001000000000133002004500000003000011007e0200000417330a7e0300000417fe012b0116000c082d0b720e010070730600000a7a2822000006281a0000060a727801007006280a00000a8005000004060b2b00072a000000133001000b000000040000110028230000060a2b00062a660002280600000600178003000004729c01007080050000042a0000001b300200f700000005000011007e0900000414280b00000a2d787e0a00000414280b00000a2d6b7e0b00000414280b00000a2d5e7e0c00000414280b00000a2d517e0d00000414280c00000a2d447e0e00000414280c00000a2d377e0f00000414280c00000a2d2a7e1000000414280c00000a2d1d7e1100000414280c00000a2d107e1200000414280c00000a16fe012b0116000b072d0b7277020070730d00000a7a2818000006007e0700000417588007000004028006000004178002000004168003000004160a7e04000004250c1200280400000a00007e040000046f0e00000a0000de100616fe010b072d0708280800000a00dc0072cd02007080050000042a00011000000200bd001edb0010000000001b300200450000000600001100281800000600168002000004148006000004160a7e04000004250b1200280400000a00007e040000046f0e00000a0000de100616fe010c082d0707280800000a00dc002a00000001100000020015001e33001000000000133002003200000007000011007e0200000417332202280f00000a2c1a027e06000004281000000a2c0d027e1100000a281000000a2b0116000a2b00062a00001b3003000301000008000011000228080000060c082d07160b38ee000000007e08000004280f00000a2c297e080000047b1500000402281200000a2d137e080000047b160000047e07000004fe012b0116002b0117000c082d23007e080000046f0c000006007e080000046f1300000a281400000a00148008000004007e08000004280f00000a0c082d30007284030070731500000a280100002b80080000047e08000004027d150000047e080000047e070000047d16000004007e0800000403046f120000060bde420a0072b0030070066f1700000a6f1800000a280a00000a80050000047e08000004280f00000a16fe010c082d0b7e080000046f0c00000600280700000600170bde0000072a000110000000001200acbe00421a000001133007006401000009000011731900000a8004000004d005000001281a00000a72da0300701f346f1b00000a8009000004d005000001281a00000a72fc0300701f346f1b00000a800a000004d005000001281a00000a72200400701f346f1b00000a800b000004d005000001281a00000a72460400701f346f1b00000a800c000004d005000001281a00000a726a0400701f34141b8d1b0000010a0616d008000001281a00000aa20617d009000001281a00000aa20618d00a000001281a00000aa20619d01d000001281a00000aa2061ad01d000001281a00000aa20614281c00000a800d000004d005000001281a00000a72800400701f34281d00000a800e000004d005000001281a00000a72a00400701f34281d00000a800f000004d005000001281a00000a72c60400701f34281d00000a8010000004d005000001281a00000a72f00400701f34281d00000a8011000004d020000001281a00000a72120500701f34281d00000a80120000042a1e02281e00000a2a1b300300bd0000000a0000110002167d1700000402167d1800000402147d1b000004027b15000004280f00000a16fe010b072d1b7e0b000004027b1500000422003c1cc68c210000016f1f00000a0000027b210000046f2000000a0c2b1c1202282100000a0a06280f00000a16fe010b072d0706281400000a001202282200000a0b072dd9de0f1202fe160300001b6f2300000a00dc00027b210000046f2400000a00027b22000004280f00000a16fe010b072d0c027b22000004281400000a0002147d220000042a00000001100000020050002b7b000f0000000013300300c90000000b000011007e12000004027b15000004146f2500000a74260000010a0339a4000000282600000a399a000000027b150000046f2700000a398a000000027b150000046f2800000a2d7d027b150000046f2900000a2d70027b150000046f2a00000a2c63062c60067b2b00000a7b2c00000a722c050070282d00000a2c49282e00000a2d42282f00000a2d3b283000000a2d34283100000a2d2d283200000a2d26283300000a2d1f283400000a280f00000a2c0f283400000a6f3500000a16fe012b0117002b0116000b2b00072a0000001b300500540200000c000011007e10000004027b15000004178d010000011305110516168c1d000001a211056f2500000a267e09000004027b150000046f3600000a750c0000010a027e11000004027b15000004146f2500000a75080000017d1b00000406280f00000a2c27027b1b000004280f00000a2c1a7e0a000004027b150000046f3600000a283700000a16fe012b011600130611062d0816130438ba010000027b1b0000046f1300000a6f3800000a6f3900000a0b0772460500706f3a00000a2d1a0772520500706f3a00000a2d0d07725c0500706f3a00000a2c2a0772660500706f3a00000a2d1d0772700500706f3a00000a2d100772760500706f3a00000a16fe012b011600130611062d08161304384301000002066f3b00000a6f3c00000a7d1c00000402066f3b00000a6f3d00000a7d1e000004733e00000a0c066f0200002b086f4000000a00027b230000046f4100000a0000086f4200000a13072b251207284300000a0d027b23000004066f3b00000a096f3c00000a6f4400000a6f4500000a001207284600000a130611062dcede0f1207fe160600001b6f2300000a00dc0002027b230000041728170000067d2400000402027b230000041628170000067d25000004027b24000004220000003f3412027b25000004220000003ffe0416fe012b011700130611062d051613042b6302027b1e000004027b24000004220000003f2f12284700000a027b25000004284800000a2b10284900000a027b24000004284800000a00284a00000a7d1d00000402177d1f00000402167d2000000402177d170000040206280f000006001713042b0011042a0110000002005801368e010f00000000133005007e0200000d00001100027b22000004280f00000a130811082d5500727c050070284b00000a0a06280f00000a130811082d0b729c050070730600000a7a0206734c00000a7d22000004027b2200000422cdcc4c3e229a99593f220000803f229a99993e734d00000a6f4e00000a000038500100000072d4050070731500000a0b0003176f0300002b130916130a38130100001109110a9a0c00086f5000000a280f00000a130811082d0538f000000072ec050070731500000a0d096f3b00000a076f3b00000a166f5100000a00096f3b00000a036f3b00000a086f5200000a6f3c00000a6f4400000a6f5300000a00096f3b00000a036f3b00000a6f3d00000a285400000a086f5200000a6f3d00000a285500000a6f5600000a00096f3b00000a086f5200000a6f5700000a6f5800000a00096f0400002b086f5000000a6f5900000a00096f0500002b1304086f5000000a6f5a00000a8d0d00000113051613062b1111051106027b22000004a2110617581306110611058e69fe04130811082de1110411056f5b00000a001104166f5c00000a001104166f5d00000a0000110a1758130a110a11098e69fe04130811083adcfeffff027b21000004076f5e00000a0000027b210000046f5f00000a027b1f000004fe04130811083a94feffff161307388500000000027b2100000411076f6000000a1107027b1f0000042f0f1107027b20000004fe0416fe012b0116006f6100000a00027b2100000411076f6000000a6f3b00000a027b1c000004027b1d00000411076b284800000a286200000a6f6300000a00027b2100000411076f6000000a6f3b00000a027b1e0000046f6400000a00001107175813071107027b210000046f5f00000afe04130811083a63ffffff2a000013300800ca0200000e00001100160a38aa020000007e12000004027b15000004146f2500000a74260000010b027b150000046f6500000a0c082d17286600000a027b1b0000046f6700000a6f6800000a2b0117000d08130511053a9500000000027b15000004027b1b000004166f6900000a130511052d1200027206060070281100000600384b020000027b15000004077b2b00000a7b6a00000a7b6b00000a6f6c00000a130511052d12000272520600702811000006003818020000077b2b00000a7b6d00000a2c0f077b6e00000a2200000000fe032b011700130511052d12000272d006007028110000060038e201000000286f00000a16fe0113047e0d000004027b150000041b8d010000011306110616027b1b000004a2110617027b1c000004027b1d000004027b200000046b284800000a286200000a8c09000001a2110618027b1e0000048c0a000001a2110619168c1d000001a211061a11048c1d000001a211066f2500000a2602257b2000000417587d20000004027b21000004027b2000000417596f6000000a166f6100000a0009130511052d1a027b15000004027b1b0000047b7000000a1615176f7100000a0008130511052d7900027b150000047e0e000004027b15000004146f2500000aa5210000016f7200000a00077b2b00000a7b6d00000a16fe01130511052d41072200000000077b6e00000a7e0f000004027b15000004178d01000001130611061607a211066f2500000aa5210000017e7300000a5a59287400000a7d6e00000a007e0c000004027b15000004287500000a8c210000016f1f00000a001b8d01000001130611061672f8060070a2110617027b200000048c43000001a21106187210070070a2110619027b1f0000048c43000001a211061a7214070070a21106287600000a8005000004027b20000004027b1f000004fe04130511052d0702280c00000600000617580a061a2f08027b180000042b011600130511053a3ffdffff2a0000133003005b0000000f000011001d8d010000010a06167226070070a20617027b200000048c43000001a206187210070070a20619027b1f0000048c43000001a2061a724c070070a2061b03a2061c7260070070a206287600000a800500000402280c000006002a00133005008b03000010000011007e0300000417fe0116fe01130a110a2d1f027b1a000004027b150000040203280d0000066f330000061309385703000016287700000a0a2032010000287800000a2d0c2031010000287800000a2b0117000b027b170000042d08027b180000042b0117000c0203280d000006130a110a2d2d000816fe01130a110a2d1a0002280c0000060002067d19000004726407007080050000040008130938e8020000027b1900000416fe01130a110a2d100002067d1900000417130938c9020000082c3b7e11000004027b15000004146f2500000a7408000001027b1b000004281200000a2d1417287900000a2d0c1f1b287a00000a16fe012b0116002b011700130a110a2d210002280c0000060002067d1900000472b607007080050000041713093862020000027b1800000416fe01130a110a2d1000022810000006001713093843020000027b17000004130a110a2d5100072c0816287900000a2b011600130a110a2d08161309381b02000002177d1900000402280e000006130a110a2d1a0002280c000006007210080070800500000417130938ee01000002167d190000040007130a110a2d210002280c0000060002067d1900000472a3080070800500000417130938be01000006130a110a2d1e0002167d1700000402177d1800000402167d2000000417130938990100001203287b00000a6f5200000a6f3c00000a287b00000a6f5200000a6f7c00000a287d00000a00287e00000a027b1c000004737f00000a130b120b091204288000000a2c0e1104220000c842fe0416fe012b011700130a110a3afd00000000027b1e000004285400000a12031104288100000a027b1c000004288200000a284a00000a1305027b24000004220000003f3730027b25000004220000003f321f12057b8300000a288400000a12057b8500000a288400000afe0516fe012b0117002b011600130611062d08027b250000042b06027b2400000400130711062d0912057b8500000a2b0712057b8300000a00130802027b1e00000411062d07284700000a2b05284900000a001107284800000a110822000000003203172b0115006b284800000a284a00000a7d1d000004021108110728160000067d1f000004027e09000004027b150000046f3600000a740c000001280f00000600007e0b000004027b1500000422003c1cc68c210000016f1f00000a0072df080070027b1f0000048c4300000172f3080070288600000a80050000041713092b0011092a0013300200390000000700001100027b1500000428080000062c0f027b160000047e07000004fe012b0116000a062d150002280c0000060002281300000a281400000a00002a560002280c00000600027b1a0000046f29000006002ac20273340000067d1a00000402177d1f00000402738700000a7d2100000402738800000a7d2300000402288900000a002a133004002a0000001100001100171f1802288a00000a035b220000003f586c288b00000a691758288c00000a288d00000a0a2b00062a00001b30030009010000120000110022000000000a00026f8e00000a130438cc0000001204288f00000a0b00026f8e00000a130538940000001205288f00000a0c0012017b9000000a12027b9000000a59288a00000a220ad7a33c3035032d1112017b8300000a12027b8300000a592b0f12017b8500000a12027b8500000a5900288a00000a220ad7a33cfe0216fe012b011600130611062d022b3106032d1112017b8500000a12027b8500000a592b0f12017b8300000a12027b8300000a5900288a00000a289100000a0a001205289200000a130611063a5cffffffde0f1205fe160700001b6f2300000a00dc001204289200000a130611063a24ffffffde0f1204fe160700001b6f2300000a00dc00060d2b00092a000000011c000002002600abd1000f0000000002001000e3f3000f000000001b300200340000001300001100160a7e26000004250b1200280400000a000014802700000414802800000400de100616fe010c082d0707280800000a00dc002a01100000020003001f220010000000001b30020064000000140000110002281d0000061000739300000a0a000603282000000600160b7e26000004250c1201280400000a0000028028000004066f9400000a802700000400de100716fe010d092d0708280800000a00dc0000de100614fe010d092d07066f2300000a00dc002a011c000002001a00243e00100000000002000f0043520010000000001b3006007401000015000011001613057e260000042513071205280400000a00007e2700000414fe0116fe01130811082d0b72160a0070730600000a7a02289500000a2602289600000a1309120972f50a0070289700000a72f90a0070280a00000a289800000a0a00067e27000004289900000a0006289a00000a0b07282100000626de120714fe01130811082d07076f2300000a00dc00160c389400000000082c1772030b0070088c4300000172090b0070288600000a2b05720d0b0070000d027e28000004167e280000046f9b00000a1f30096f9b00000a59288c00000a6f9c00000a09720f0b0070289d00000a289800000a13041104289e00000a16fe01130811082d022b2600061104289f00000a0011041306de6326001104289e00000a130811082d02fe1a00de0000000817580c082010270000fe04130811083a5bffffff72190b007073a000000a7a0006289e00000a16fe01130811082d070628a100000a0000dc110516fe01130811082d081107280800000a00dc0011062a4164000002000000700000000900000079000000120000000000000000000000fd000000100000000d0100001400000051000001020000005c000000e70000004301000019000000000000000200000004000000580100005c01000014000000000000002e731e00000a80260000042a4e02720d0b00707d2a00000402281e00000a002a133002008d00000016000011000228a200000a2d0f026f9b00000a1f30fe0216fe012b0116000c082d0b72930b007073a300000a7a00020d1613042b430911046fa400000a0a0628a500000a2d1b061f202e16061f2d2e11061f5f2e0c061f282e07061f29fe012b0117000c082d0b724c0c007073a300000a7a1104175813041104096f9b00000afe040c082daf026fa600000a0b2b00072a000000133002001b00000007000011000228a700000a2d0b0228a800000a16fe012b0116000a2b00062a001b300300e40100001700001100026fa900000a173212026fa900000a2000020000fe0216fe012b0116000d092d0b72a80c007073a300000a7a00026faa00000a13043888010000120428ab00000a0a00067b2900000428ac00000a2d31067b290000046f9b00000a2080000000301f067b2a0000042c17067b2a0000046f9b00000a2000040000fe0216fe012b0116000d092d0b72f20c007073a300000a7a001d8d210000011305110516067b2b000004a0110517067b2c000004a0110518067b2d000004a0110519067b2e000004a011051a067b2f000004a011051b067b30000004a011051c067b31000004a0110513061613072b2211061107986b0b07281e0000060d092d0b72220d007073a300000a7a110717581307110711068e69fe040d092dd2067b2b000004288a00000a220000c8423029067b2c000004288a00000a220000c8423017067b2d000004288a00000a220000c842fe0216fe012b0116000d092d0b72600d007073a300000a7a067b2e000004067b2e0000045a067b2f000004067b2f0000045a58067b30000004067b300000045a58067b31000004067b310000045a580c08220000803f59288a00000a220ad7233cfe0216fe010d092d0b729e0d007073a300000a7a00120428ad00000a0d093a6afeffffde0f1204fe160900001b6f2300000a00dc002a411c000002000000360000009d010000d30100000f000000000000001b30030014010000180000110003281f000006000228ae00000a1773af00000a0a000672d60d00706fb000000a0006036fa900000a6fb100000a0000036faa00000a0d389f000000120328ab00000a0b0006077b290000046fb000000a0006077b2a0000046fb000000a00001d8d210000011304110416077b2b000004a0110417077b2c000004a0110418077b2d000004a0110419077b2e000004a011041a077b2f000004a011041b077b30000004a011041c077b31000004a0110413051613062b1511051106986b0c06086fb200000a00110617581306110611058e69fe04130711072ddd00120328ad00000a130711073a51ffffffde0f1203fe160900001b6f2300000a00dc0000de120614fe01130711072d07066f2300000a00dc002a011c000002003700b6ed000f0000000002001500eb000112000000001b300300670100001900001100026fb300000a20000020006afe0216fe01130611062d0b72e20d007073a300000a7a73b400000a0a0228ae00000a1773b500000a0b00076fb600000a72d60d007028b700000a16fe01130611062d0b72160e007073a300000a7a076fb800000a0c0817320d082000020000fe0216fe012b011600130611062d0b72520e007073a300000a7a160d388900000006731c00000613041104076fb600000a7d290000041104076fb600000a7d2a0000041104076fb900000a7d2b0000041104076fb900000a7d2c0000041104076fb900000a7d2d0000041104076fb900000a7d2e0000041104076fb900000a7d2f0000041104076fb900000a7d300000041104076fb900000a7d3100000411046fba00000a000917580d0908fe04130611063a6affffff026fbb00000a026fb300000afe01130611062d0b727c0e007073a300000a7a00de120714fe01130611062d07076f2300000a00dc0006281f000006000613052b0011052a00411c000002000000360000000f010000450100001200000000000000133003001c00000004000011001f1c28bc00000a72b20e007072d80e007028bd00000a0a2b00062a13300400440000000400001100282200000628be00000a2d0772ee0e00702b2a721e0f0070282200000672240f007028bf00000a14fe06c000000a73c100000a280600002b28c300000a000a2b00062a133003001d0000001a00001100027b2b000004027b2c000004027b2d00000473c400000a0a2b00062a00000013300400230000001b00001100027b2e000004027b2f000004027b30000004027b3100000473c500000a0a2b00062a00133006003e0000001c000011007e050000040328b700000a0a038005000004062c10027b33000004280f00000a16fe012b0117000b072d11027b3300000417031614166fc600000a002a00001b3002007b0000001d0000110000027b420000046f2000000a0b2b1c1201282100000a0a06280f00000a16fe010c082d0706281400000a001201282200000a0c082dd9de0f1201fe160300001b6f2300000a00dc00027b420000046f2400000a00027b45000004280f00000a16fe010c082d0c027b45000004281400000a0002147d450000042a000110000002000e002b39000f00000000133008003d000000070000110002020202020216250a7d3e00000406250a7d3d00000406250a7d3c00000406250a7d3b00000406250a7d3a000004067d39000004022827000006002a0000001330020033000000070000110002282800000600027b430000046fc700000a00027b44000004280f00000a16fe010a062d0c027b44000004281400000a002a0013300500bd0100001e00001100027b44000004280f00000a130811082d5500727c050070284b00000a0a06280f00000a130811082d0b72300f0070730600000a7a0206734c00000a7d44000004027b44000004229a99193e226666663f220000803f229a99993e734d00000a6f4e00000a000072660f0070731500000a0b027b42000004076f5e00000a000003176f0300002b130916130a38130100001109110a9a0c00086f5000000a280f00000a130811082d0538f0000000728a0f0070731500000a0d096f3b00000a076f3b00000a166f5100000a00096f3b00000a036f3b00000a086f5200000a6f3c00000a6f4400000a6f5300000a00096f3b00000a036f3b00000a6f3d00000a285400000a086f5200000a6f3d00000a285500000a6f5600000a00096f3b00000a086f5200000a6f5700000a6f5800000a00096f0400002b086f5000000a6f5900000a00096f0500002b1304086f5000000a6f5a00000a8d0d00000113051613062b1111051106027b44000004a2110617581306110611058e69fe04130811082de1110411056f5b00000a001104166f5c00000a001104166f5d00000a0000110a1758130a110a11098e69fe04130811083adcfeffff0713072b0011072a00000013300600c70000001f000011000328c800000a81090000010416fe01130411042d6e007e10000004027b33000004178d010000011305110516168c1d000001a211056f2500000a267e09000004027b330000046f3600000a750c0000010a06280f00000a2c0b066fc900000a16fe012b011700130411042d160003066f3b00000a6f3c00000a8109000001170d2b4200287b00000a6f5200000a0c086f3c00000a086f7c00000a1201220000c8421ffb1728ca00000a130411042d04160d2b1103120128cb00000a8109000001170d2b00092a0000000000000000000100000002000000030000000000000004000000050000000100000005000000060000000200000006000000070000000300000007000000040000001b300500720400002000001100027b400000046fcc00000a000228270000060073cd00000a0a027b35000004287e00000a027c360000047b9000000a284800000a220000003f284800000a286200000a027c3600000428ce00000a0628cf00000a001201027b35000004287e00000a027c360000047b9000000a220000003f5a22cdcccc3d59284800000a286200000a027b36000004287e00000a22cdcc4c3e284800000a286200000a28d000000a0000066fd100000a130e3812010000120e28d200000a0c0008280f00000a2c1c086fd300000a2c141201086f5200000a6f3c00000a28d400000a2b011600130f110f2d0538d8000000086f0700002b0d09280f00000a2c0e096fd600000a14fe0116fe012b011600130f110f2d0538ae000000086f1300000a28d700000a130428d800000a11046fd900000a13051105280f00000a2c0e11056f0200002b280f00000a2b011600130f110f2d022b72027b40000004086fda00000a00027b400000046fdb00000a2000020000fe0216fe01130f110f2d0b72a80f0070730600000a7a02086f1300000a282a000006130611066f3b00000a086f5200000a6f3c00000a6f6300000a0011066f3b00000a086f5200000a6f3d00000a6f6400000a0000120e28dc00000a130f110f3adefeffffde0f120efe160d00001b6f2300000a00dc00027b44000004280f00000a130f110f2d2c00727c050070284b00000a1307021107734c00000a7d44000004027b4400000428dd00000a6f4e00000a000002721a100070731500000a7d45000004027b450000046f0800002b13081108027b440000046fde00000a0011081108228fc2753d2513106fdf00000a0011106fe000000a001108176fe100000a00120128e200000a1309120128e300000a130a1e8d0900000113111111168f0900000112097b8300000a12097b9000000a12097b8500000a73c400000a81090000011111178f09000001120a7b8300000a12097b9000000a12097b8500000a73c400000a81090000011111188f09000001120a7b8300000a12097b9000000a120a7b8500000a73c400000a81090000011111198f0900000112097b8300000a12097b9000000a120a7b8500000a73c400000a810900000111111a8f0900000112097b8300000a120a7b9000000a12097b8500000a73c400000a810900000111111b8f09000001120a7b8300000a120a7b9000000a12097b8500000a73c400000a810900000111111c8f09000001120a7b8300000a120a7b9000000a120a7b8500000a73c400000a810900000111111d8f0900000112097b8300000a120a7b9000000a120a7b8500000a73c400000a81090000011111130b1f108d4300000125d04a00000428e500000a130c1108110c8e696fe600000a0016130d2b211108110d110b110c110d948f0900000171090000016fe700000a00110d1758130d110d110c8e69fe04130f110f2dd102282d00000600021b8d0100000113121112167250100070a2111217027b400000046fdb00000a8c43000001a21112187264100070a2111219027b34000004a211121a727e100070a21112287600000a2826000006002a0000411c000002000000ad00000029010000d60100000f00000000000000133002001600000011000011027c2c000004037b2c00000428e800000a0a2b00062a00001b300300880100002100001100027b400000046fdb00000a16fe0116fe01130611062d0b7227110070730600000a7a73b400000a0a00027b400000046fd100000a130738ef000000120728d200000a0b0007280f00000a130611062d0b72e6110070730600000a7a076f5200000a6f3c00000a027b35000004288200000a0c076f5200000a6f3d00000a0d076f0900002b130406731c00000613051105076f1300000a28d700000a7d29000004110512027b8300000a7d2b000004110512027b9000000a7d2c000004110512027b8500000a7d2d000004110512037be900000a7d2e000004110512037bea00000a7d2f000004110512037beb00000a7d30000004110512037bec00000a7d3100000411051104280f00000a2d07720d0b00702b0711046fed00000a007d2a00000411056fba00000a0000120728dc00000a130611063a01ffffffde0f1207fe160d00001b6f2300000a00dc00067e460000042d1314fe063500000673ee00000a80460000042b007e460000046fef00000a0006281f00000600027b34000004062819000006002a411c00000200000037000000060100003d0100000f00000000000000133003001a000000040000110028030000060a02724012007006280a00000a2826000006002a00001b30040064010000220000110073b400000a0a282200000603281d000006720f0b0070280a00000a289800000a289a00000a0b0728210000060ade120714fe01130511052d07076f2300000a00dc0000066faa00000a13062b4e120628ab00000a0c0028d800000a087b290000046fd900000a0d09280f00000a2c0d096f0200002b280f00000a2b011600130511052d167274120070087b29000004280a00000a730600000a7a00120628ad00000a130511052da5de0f1206fe160900001b6f2300000a00dc000228280000060002037d3400000402067d41000004020222000000002513077d3800000411077d3700000402177d3a00000400027b410000046faa00000a13062b2b120628ab00000a0c000228d800000a087b290000046fd900000a282a00000613041104166f6100000a0000120628ad00000a130511052dc8de0f1206fe160900001b6f2300000a00dc000272a2120070027b3400000472b4120070289d00000a2826000006002a0128000002002700093000120000000002004c005fab000f000000000200fb003c37010f000000001b3005007a0200002300001100027b3b0000042c08027b3e0000042b011600130811082d0b7289130070730600000a7a73f000000a0a00027b410000046faa00000a13093831010000120928ab00000a0b0028d800000a077b290000046fd900000a0c08280f00000a130811082d1672f1130070077b29000004280a00000a730600000a7a086f0200002b0d027b330000046f6500000a16fe01130811082d0538d5000000027b3300000409166f6900000a130811082d1b7213140070077b290000047251140070289d00000a730600000a7a286600000a096f6700000a6f6800000a16fe01130811082d05388900000000097b7000000a130a16130b2b6c110a110b9a130411047bf100000a280f00000a2c101104166ff200000a16fe0216fe012b011700130811082d390011047bf100000a7bf300000a7b2b00000a7b2c00000a130506110512066ff400000a2606110511061104166ff200000ad66ff500000a0000110b1758130b110b110a8e69fe04130811082d8600120928ad00000a130811083abffeffffde0f1209fe160900001b6f2300000a00dc0000066ff600000a130c2b7f120c28f700000a1307027b330000046ff800000a120728f900000a15176ffa00000a120728fb00000afe0416fe01130811082d4b1b8d01000001130d110d1672af140070a2110d17120728fb00000a8c43000001a2110d1872dd140070a2110d19120728f900000aa2110d1a72e1140070a2110d287600000a730600000a7a120c28fc00000a130811083a71ffffffde0f120cfe161000001b6f2300000a00dc00027b430000046fc700000a0002177d3c00000402167d3a00000402167d3f000004027205150070027b340000047219150070289d00000a2826000006002a000041340000020000003800000048010000800100000f000000000000000200000099010000930000002c0200000f000000000000001b300800850400002400001100160a386504000000027b41000004027b3f0000046ffd00000a0b28d800000a077b290000046fd900000a6f0200002b0c7e12000004027b33000004146f2500000a74260000010d027b330000046f6500000a130411042d50027b3300000408166f6900000a2c3d027b33000004097b2b00000a7b6a00000a7b6b00000a6f6c00000a2c20097b2b00000a7b6d00000a2c0f097b6e00000a2200000000fe032b0117002b0116002b011700130e110e2d2e0002282800000600027221150070027b3f0000048c430000017253150070288600000a28260000060038a50300002200000000027b37000004220000000028fe00000a1305027b35000004287e00000a027b38000004284800000a286200000a1105072824000006284a00000a286200000a130673cd00000a1307110622cdcccc3d110728cf00000a00141308007e0d000004027b330000041b8d01000001130f110f1608a2110f1711068c09000001a2110f181105072825000006285500000a8c0a000001a2110f19168c1d000001a2110f1a286f00000a16fe018c1d000001a2110f6f2500000a2600ddf80000000073cd00000a1309110622cdcccc3d110928cf00000a000011096fd100000a131038ae000000121028d200000a130a110a280f00000a2c271107110a6fff00000a2d1c110a6f1300000a28d700000a077b29000004282d00000a16fe012b011700130e110e2d6d00110a6f0700002b130b110b280f00000a2c0c110b6fd600000a14fe012b011700130e110e2d4500027b430000047336000006130c110c110a7d47000004110c110b6fd600000a7d48000004110c110b6fd600000a7b0001000a7d49000004110c6f0101000a00110a13080000121028dc00000a130e110e3a42ffffffde0f1210fe160d00001b6f2300000a00dc0000dc001108280f00000a130e110e2d0b7204160070730600000a7a02257b3f00000417587d3f000004027b42000004027b3f00000417596f6000000a166f6100000a0011042d12286600000a086f6700000a6f6800000a2b011700130e110e2d15027b33000004087b7000000a1615176f7100000a001104130e110e2d7900027b330000047e0e000004027b33000004146f2500000aa5210000016f7200000a00097b2b00000a7b6d00000a16fe01130e110e2d41092200000000097b6e00000a7e0f000004027b33000004178d01000001130f110f1609a2110f6f2500000aa5210000017e7300000a5a59287400000a7d6e00000a0011086f0900002b130d110d280f00000a2c0d077b2a00000428ac00000a2b011700130e110e2d0e110d077b2a0000046f0201000a007e0c000004027b33000004287500000a8c210000016f1f00000a00021d8d01000001130f110f16727c160070a2110f17027b3f0000048c43000001a2110f187210070070a2110f19027b410000046fa900000a8c43000001a2110f1a728a160070a2110f1b027b34000004a2110f1c72a6160070a2110f287600000a282600000600027b3f000004027b410000046fa900000afe0116fe01130e110e2d0702282800000600000617580a061a2f08027b3c0000042b011600130e110e3a84fbffff2a000000011c00000200c201c587020f0000000002003e0163a101f80000000013300400360200002500001100160a38ca01000000027b43000004027b430000046f0301000a17596f0401000a0b077b47000004280f00000a16fe01130711073a5701000000077b470000046f0700002b0c08280f00000a2c29086fd600000a077b48000004331b086fd600000a7b0001000a077b49000004280501000a16fe012b011600130711072d0b72e6160070730600000a7a077b470000046f0a00002b0d09280f00000a2c18096f0601000a6f0701000a6f0801000a16fe0216fe012b011700130711072d0b7254170070730600000a7a077b470000046f0b00002b13041104280f00000a2c0c11046f0901000a16fe012b011700130711072d0b72dd170070730600000a7a077b470000046f0c00002b13051105280f00000a16fe01130711072d3e1613062b23110511066f0a01000a16fe01130711072d0b7251180070730600000a7a110617581306110611057b0b01000a6f0c01000afe04130711072dc7086f0d01000a00086f0e01000a130711072d0b72c5180070730600000a7a28d800000a077b470000046f1300000a6f0f01000a00002b24281001000a077b490000046f1101000a14fe01130711072d0b7231190070730600000a7a027b43000004027b430000046f0301000a17596f1201000a00000617580a061e2f10027b430000046f0301000a16fe022b011600130711073a17feffff0272e6190070027b430000046f0301000a8c4300000172f4190070288600000a282600000600027b430000046f0301000a16fe0116fe01130711072d0702167d3d0000042a00001b3005001f050000260000110002037d3300000404130811082d3900027b3c0000042d0b027b3d00000416fe012b011600130811082d1500022828000006000272831a00702826000006000017130738d30400000028020000060a0614fe01130811083a8f01000000067b1300000417fe0116fe01130811083a0c01000000067b14000004178d5300000113091109161f7c9d11096f1301000a0b078e691afe01130811082d0b725c1b007073a300000a7a0207169a281d0000067d34000004198d210000010c160d2b57070917589a20a7000000281401000a08098f21000001281501000a2c2308099828a700000a2d190809982200000040320f080998220000a042fe0216fe012b011600130811082d0b72bc1b007073a300000a7a0917580d0919fe04130811082d9f022828000006000208169808179808189873c400000a7d3600000402177d3900000402027b330000046f5200000a6f3c00000a287e00000a288200000a7d3500000402021725130a7d3e000004110a7d3b00000402282c00000600002b6c067b1300000418fe0116fe01130811082d0f02067b14000004282f000006002b4b067b1300000419fe0116fe01130811082d1700022828000006000272041c0070282600000600002b22067b130000041afe0116fe01130811082d10000228280000060002177d3d00000400001f1b287a00000a16fe01130811082d1c00022828000006000272801c0070282600000600171307dd04030000027b3c00000416fe01130811082d100002283100000600171307dde5020000027b3d00000416fe01130811082d100002283200000600171307ddc6020000027b390000042d08027b3a0000042b011700130811082d08171307dda6020000027b3a0000042c08027b3b0000042b011700130811082d2d0002021204027b3a000004282b0000067d3e000004027b3e00000416fe01130811082d080211047d3500000400027b3a0000042c17201f010000287a00000a2c0b027b3e00000416fe012b011700130811082d2d0002027b3b00000416fe017d3b00000402027b3b0000042d0772be1c00702b0572081d00700028260000060000027b3900000416fe01130811082d4b002020010000287a00000a16fe01130811082d31000002282e0000060000de2313050002728f1d007011056f1700000a6f1800000a280a00000a28260000060000de00000000387b010000001f71287a00000a16fe01130811082d1202257b370000042200007041597d370000041f65287a00000a16fe01130811082d1202257b370000042200007041587d370000042018010000287a00000a16fe01130811082d1202257b38000004220000003f587d380000042019010000287a00000a16fe01130811082d1202257b38000004220000003f597d380000042200000000027b37000004220000000028fe00000a1306160d389c00000000027b42000004096f6000000a027b3e0000046f6100000a00027b42000004096f6000000a6f3b00000a027b35000004287e00000a027b38000004284800000a286200000a1106027b41000004096ffd00000a2824000006284a00000a286200000a6f6300000a00027b42000004096f6000000a6f3b00000a1106027b41000004096ffd00000a2825000006285500000a6f6400000a00000917580d09027b410000046fa900000afe04130811083a4dffffff2020010000287a00000a16fe01130811082d07022830000006000000de2f130500022828000006000272ab1d007011056f1700000a6f1800000a72d31d0070289d00000a28260000060000de00001713072b000011072a004134000000000000320300000b0000003d030000230000001a00000100000000480000009e040000e60400002f0000001a000001033004004e0000000000000002220000a0412200004041220000a04173c400000a7d360000040273cd00000a7d400000040273b400000a7d4100000402738700000a7d4200000402731601000a7d4300000402281e00000a002a1e02281e00000a2a000042534a4201000100000000000c00000076342e302e33303331390000000005006c00000090110000237e0000fc1100004c13000023537472696e67730000000048250000401e00002355530088430000100000002347554944000000984300007c08000023426c6f620000000000000002000001579da229090a000000fa25330016000001000000770000000c0000004a0000003600000025000000160100000200000005000000010000002600000001000000010000000100000013000000010000000100000007000000030000000c00000000000a000100000000000600c100ba000a00eb00df0006000b01f9000e0046012b011200940100000600cd01f9000600fd01f9001200a10200000a00b002df000a00c402df000600e4022b010a00eb02df000a00ff02df000600ec03e2031200f90400001200010500000600920573050600d905b9050600f905b90506003b062a0606005306ba0006008206ba0006009c06ba000a00c100df000a00db06df0006000907ba0006003707ba0006003c07ba0006006907ba0006007107f90006007807f90012009407000006009d07ba002f00ad0700000600db07ba000600e707f9001200f90700009700020800000a000b08df000a002508df0012003b0800009b006608000012008108000012009808000012009d0800001200a50800001200b40800001200d90800000600fd08ba000a003009df000a00b909df000a00c509df000a00ed09df000a00b904df000a006a0adf000a00880adf000a00bb0aa50a12003b0b00001200460b000017006b0b000012008c0b00001200d50b00002300fb0b000012002f0c00000a00450cdf000a004f0cdf0006005d0cba001600810cdf000a00960cdf001200c30c00000a00ce0cdf000a00d90cdf000600050dba000600160de20306002b0de2030600350de2030600530dba000600690de2030600760de2030600890de2030600be0de2030e00e40de2030600030eba000600480e3c0e06005a0ee2030600670ee2030600a10eba005f01ad0e00000600ee0eba000600fa0eba001200100f00006f011b0f00000a00270fdf001a00680fdf001a00700fdf001a007b0fdf000a00c00fdf001200d80f00001e00f70f000012000b1000000a002810df000600cb10b9050600e610ba0006002111b90506003011ba0006008b11ba001200ac0300000600d8112b01b301ad070000060019122b0112002812000012007012000012008612000012009f120000cb01aa1200001200d812000006000313ee1206002413ee1206003113ba0000000000010000000000010001008101100021002d000500010001000501100040000000050013000b00010110004c002d00090015000c00800110005e002d00050026001600800110006a002d00050026001800010110007b002d00050029001c00810110008a002d00050032001d000001100098002d0005003300220003011000aa000000050047003600000000008610000005004a00370013010000f01000009d014b003700538018010a0016001e01130013002601130031004e0116001600ae0133001300b50136001300bb0113001100c6013a003300d7013e003300dd013e003300ed013e003300f5013e0033000802420033000e02420033001b02420033002b02420033003702420033004002420003006602130003006b0233000600b50136000300bb011300010076025c0001007f025c0001008a025c00210097025f000100a70263000100b80267000100bf0267000100cf026b000100d80213000100de0213002100f6026f00010008037700010018037b0001002303830001002903830031008303b10011008803b4001100910333000600a50333000600ac0333000600b10383000600b30383000600b50383000600b70383000600ba0383000600bd0383000600c00383005680c30313000100fe03360001009103330001000404670001000b04670001001004830001001404830001001b045c00010025045c00010030045c00010037045c00010040045c00010048045c000100de02130021005004f30001005a04fb00210062046f0021006904030101006e047700010077040b011100981190060300a10263000300fd043701030007053b0113010d113f06502000000000960057011e000100f4200000000093005f012400030054210000000096006b0129000300a821000000009600780129000300bf210000000096009b012d000300dc210000000096004a022d000400f02200000000960054024600050054230000000093005c024a0005009423000000009600610250000600b42400000000911830074600090024260000000086187002580009002c260000000086002f03580009000827000000008100360386000900e0270000000081003e038b000a00502a00000000810044038f000a00dc2c000000008100500358000b00b42f0000000081005a0395000b001c3000000000860062039a000c00b433000000008100670358000e00f9330000000081006e0358000e000f34000000008618700258000e0040340000000093007803a0000e0078340000000093007e03a6001000ac35000000009300960346001200fc350000000093009c03b80012008836000000009300a003c30014006c3800000000911830074600150078380000000086187002580015008c38000000009600c903c30015002839000000009100d203cd0016005039000000009600d903d20017005c3b000000009600f303dc001800983c000000009600f903e8001a00283e0000000093087f0429001b00503e0000000093008a0429001b00a03e00000000910092040f011b00cc3e0000000091009b0416011c00fc3e000000008100ae0195001d00483f000000008100a40458001e00e03f0000000083002f0358001e002c40000000008300b10458001e006c40000000008100b9041d011e003842000000008100be0424011f005043000000008100c204580021001048000000008100c70458002100c049000000008100a00358002100e849000000008100d70495002100804b000000008100dc04580022003c4e000000008100e70458002200ec52000000008100ed0458002200305500000000830062032c012200905a000000008618700258002400ec47000000009100711188062400ea5a000000008618700258002600000001000a05000002000f05000001001405000001001405000001001405000001001405000002001605000003001c05000001001605000001001f05000001002505000001001605000002001c05000001002c05000002003505000001003d05000002004405000001004605000002005a04000001005205000001009103000001005905000001005a04000001005b05000002005a04000001005b05000001006205000001006205000001006405000001006605020001006d05000002009f0500000100a40500000100aa0500000200b105000001008711000002008911890070025800910070023f01990070025800a100430644010c0049065201a900700295000c006d065601a10075065c010c007a066e01b10089068001310090069001390090069801b900700295000c0096035800c100b306b601c1009006bc012900bf063600c100cd06bc01c900e506c801c100f406cd016100700295006100fc06d301d1001307de01d1002407e3010c0070025800d9004e07ee01d9006007f501d9008a07fd01d9008a070d020900700258003100a4071b021400b80728021c00c6076e011c00d2078b001901b10458001400960358002101f2074702390117084e0241012f088b00490145088b0049014c088b0049015a088b0031017108520251017a083300b1009006570259018e084e0261018e084e0269018e084e027101ad084e027901b8084e027901d0084e028101de085d028101eb088b003100f4086a02890105096f02c1000d09e301b1001609e301b1002709740261003a097902910148097f0291015509840224007002580061006209d30141006f0996022c00960358002400b80728023400c6076e0191017d09b1022c00930956013400d2078b0049009709b8024900a309bd024900af09b8025100a309c5029901c009ea0269007002f102a1017002f8026900cb0900036100d5090703a901f80915039101070a1b03c9003a0979029101110a23035100230a29035100a309300391012b0a390391013d0a7f0291014c0a2303a9015b0a3f03b101770a5201c101910a4c03c101cd0a5303c101e30a5a031400930956011400490652011400f60a5f036100ff0a5a034900090b65039101150b23039101220b390329002f0b8b00d101de0889034100510b8f03d1015e0b950329007b0b9c035101930ba503e9019c0b83004901ac0baa035101b80b5c003101c80b8300f101e30b4e024100070caf032900130cb5034901240cc0030102340c830009024b0cc5031102540ccb03b1008906cf032102870ce70321029e0cec032102a50ce7032102b80cec033102de08f303910197097f0239027002f9034900d20cb80241027002f9034102df0c01043902e70c0a044900f00c65034900440583000902ff0c10044900030d8300b100890615041400700258002c00700258001100700258004902ff0c100449020a0d30044902100d350449024b0c35042c00b80728023c00c6076e014900140d830049024b0cc5033c00d2078b005102700258005102230d65045902430d73046902580d7a046902600d800471026e0d800179027b0d85047902940d8c04b1009d0d5201b100a80d9304b100890699047902b20da0047902b90da5048902700295007902ca0dab04b100d10da004910270029500b100f90dc1049902080ec604b100180ee30109011d0ecd000901230ecd004400490652014400b80728024c00c6076e01b1002e0ea0044c00d2078b00a102510ef604a9027002fc04a902f3039500a902f3033f01a902f303c00371009d0d1c05440070025800b1027002fc04b102740ee301b100cd065702b1027f0e5201b102890e20054400930956017100940e1c05b902bb0e3b0571026e0d99045902b20da0045902c90e42057102d20ec300540070025105d102000f5705b1000b0f6f0549007002760551007002f80249012e0f87055c00960358004900360fb80261003f0f8b00f102df0cc905f902930f7f0264009603580064007002580049009d0f20054100ab0ff00509037002f9036400b80728026c00c6076e014100c70f8b00090327090506c9006209d3011103e10f11061903fd0f16062103de081c062103151022066400930956016400490652016c00d2078b00a1011f102806c1013510340629034810c00329035510c003290364105a03090376107f0209037e107f02310370025800410343114306290353113f01290365114d060901bf1199065100440583005100140d83005100030d83005100c91183005903cb11e3017400700251054400d311ac067c0070025800f901e511f606f901ef11fb062901f91100077c00041205077c0010120e077c00b80716078400c6072a070101321236078c003f126e017903471244078c0052124b078400d2078b004400f60a5f0351005c128207640027098a07790062123b015c00930956015903681295005c00490652015c00f60a5f038100cd06c20781033212360779037a12d007940049065201890390128b0091039012ee079103b912f3079c00490652011103c11258001103d0128b002103f4068f00a103de080408a103e10f0a085c00df123f01b100e8122508a9030f132c080901411332085c0070025800080004000e000800c800c8002e00130054082e001b005d08630123073a06a00623073a06c10823073a060100400000000c006101730186018c01a001ab01c401e70115023a026302ce026e03d503e2031c043b0447045f046a04b004cb04e204060524057d05820594059905ad05da055406b706d3065007900711083f08090001000000f20433010200220003004b01210232028902a102a8023f04d304da044905a605e905fd05a406ee0622073c07da07fc07104300004a00048000000000000000000000000000000000170600000400000000000000000000000100b100000000000000000000000000000000000000c800000000000400000000000000000000000100ba000000000000000000000000000000000000008301000000000000000000000000000000000000630c0000000000000000000000000000000000004e0f000000000000000000000000000000000000e80f00000000030002000a0009000c000b002d00d9017f0091029f000f032d000f032d00460385016a05ab010b062d002e06ab019e06ab01ca07ab01e207ab01e8070000003c4d6f64756c653e0056616c6865696d447261674275696c6456352e646c6c00447261674275696c6456350056616c6865696d536f6c6f546f6f6c6b697400526571756573744461746100447261674275696c6444726976657256350044726167526f77506c616e00426c75657072696e744361707475726500426c75657072696e74456e74727900426c75657072696e744461746100426c75657072696e74576f726b73686f7000506c61636564006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f75720053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c61677300456e61626c6564004d6f64650053797374656d2e436f6c6c656374696f6e732e47656e65726963005175657565603100726571756573747300526571756573740054616b6552657175657374005361766543617074757265640053617665644e616d657300617373656d626c795f76616c6865696d00506c6179657200436f6e666967757265426c75657072696e7400537461747573004f776e65720047656e65726174696f6e00647269766572004669656c64496e666f0047686f737400506c6163656d656e745374617475730050726573736564004c617374557365004d6574686f64496e666f00506c616365004275696c645374616d696e61004275696c644475726162696c6974790055706461746547686f73740053656c65637465640052696768744974656d00436f6e6669677572650044697361626c65004f776e73005469636b00436f64650054657874002e63746f72006472616767696e6700636f6d6d697474696e670072656c65617365477561726400626c75657072696e740050696563650073656c656374656400566563746f723300616e63686f720073746570005175617465726e696f6e00726f746174696f6e00636f756e7400696e646578004c69737460310047616d654f626a656374007072657669657773004d6174657269616c00707265766965774d6174657269616c00736e6170506f696e7473007370616e58007370616e5a0043616e63656c00416c6c6f77656400426567696e0053686f775072657669657700506c6163654e6578740053746f70526f77005374657000557064617465004f6e44657374726f7900436f756e74005370616e006761746500736e617073686f74006e616d6500436c65617200536574005361766500507265666162005369676e00580059005a00515800515900515a005157004c696d697400536166654e616d650046696e6974650056616c69646174650053797374656d2e494f0053747265616d0057726974650052656164006f776e6572006f726967696e0073697a6500796177006865696768740073656c656374696e670070726576696577696e67006c6f636b6564006275696c64696e6700756e646f696e67006861766541696d0073656c656374696f6e00656e7472696573006d657368657300756e646f006d6174657269616c006f75746c696e65006765745f466f6c64657200436174616c6f6700506f736974696f6e00526f746174696f6e00436c6561725072657669657700446973706f7365004d6573680041696d005363616e0043617074757265536e617073686f74004c6f616400426567696e4275696c64004275696c6400556e646f00466f6c646572005a444f005a646f005a444f494400496400636f64650074657874007000696e7075740064740067686f737400726561736f6e0064697374616e63650073706163696e6700706f696e7473007800636170747572654e616d6500666f6c64657200660073747265616d0065007300736f7572636500706f696e740053797374656d2e52756e74696d652e496e7465726f705365727669636573004f757441747472696275746500736e61700076616c756500706c6179657200616c6c6f7765640053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d447261674275696c6456350053797374656d2e546872656164696e67004d6f6e69746f7200456e746572006765745f436f756e7400496e76616c69644f7065726174696f6e457863657074696f6e00456e71756575650045786974004465717565756500537472696e6700436f6e636174006f705f457175616c697479004d697373696e674d656d626572457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c61796572006f705f496e657175616c69747900436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e7400457863657074696f6e0047657442617365457863657074696f6e006765745f4d657373616765002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744669656c6400426f6f6c65616e0042696e64657200506172616d657465724d6f646966696572004765744d6574686f640048756d616e6f69640053696e676c650053657456616c756500456e756d657261746f7200476574456e756d657261746f72006765745f43757272656e74004d6f76654e6578740049446973706f7361626c65004d6574686f644261736500496e766f6b65004974656d44726f70004974656d44617461004170706c69636174696f6e006765745f6973466f6375736564004265686176696f7572006765745f656e61626c6564004368617261637465720049734465616400497354656c65706f7274696e6700496e506c6163654d6f64650053686172656444617461006d5f736861726564006d5f6e616d6500496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c65004d696e696d61700049734f70656e00487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c0043686174006765745f696e7374616e636500486173466f6375730047657456616c756500436f6e7665727400546f496e743332006765745f6e616d6500546f4c6f776572496e76617269616e7400436f6e7461696e73005472616e73666f726d006765745f7472616e73666f726d006765745f706f736974696f6e006765745f726f746174696f6e00476574436f6d706f6e656e7400476574536e6170506f696e747300496e76657273655472616e73666f726d506f696e7400416464006765745f666f7277617264006f705f4d756c7469706c79006765745f7269676874005368616465720046696e6400436f6c6f72007365745f636f6c6f7200476574436f6d706f6e656e7473496e4368696c6472656e004d65736846696c746572006765745f7368617265644d65736800536574506172656e74007365745f6c6f63616c506f736974696f6e00496e7665727365007365745f6c6f63616c526f746174696f6e006765745f6c6f7373795363616c65007365745f6c6f63616c5363616c65007365745f7368617265644d657368004d65736852656e6465726572006765745f7375624d657368436f756e740052656e6465726572007365745f7368617265644d6174657269616c7300556e697479456e67696e652e52656e646572696e6700536861646f7743617374696e674d6f6465007365745f736861646f7743617374696e674d6f6465007365745f72656365697665536861646f7773006765745f4974656d00536574416374697665006f705f4164646974696f6e007365745f706f736974696f6e007365745f726f746174696f6e004e6f436f73744368656174005a6f6e6553797374656d00476c6f62616c4b65797300467265654275696c644b657900476574476c6f62616c4b657900526571756972656d656e744d6f64650048617665526571756972656d656e74730041747461636b006d5f61747461636b006d5f61747461636b5374616d696e6100486176655374616d696e61006d5f7573654475726162696c697479006d5f6475726162696c69747900506c6179657250726f66696c65006765745f735f6279706173734368656174436865636b7300526571756972656d656e74006d5f7265736f757263657300436f6e73756d655265736f7572636573005573655374616d696e610047616d65006d5f6475726162696c69747952617465004d61746866004d61780054696d65006765745f74696d6500496e74333200556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e004b6579436f6465004765744b6579004765744d6f757365427574746f6e446f776e004765744b6579446f776e0047616d6543616d65726100526179006765745f757000506c616e65005261796361737400476574506f696e74006f705f5375627472616374696f6e00416273007a004d61746800466c6f6f72004d696e0079004d656d6f727953747265616d00546f4172726179004469726563746f7279004469726563746f7279496e666f004372656174654469726563746f72790047756964004e65774775696400546f537472696e67005061746800436f6d62696e650046696c65005772697465416c6c42797465730046696c6553747265616d004f70656e52656164006765745f4c656e67746800537562737472696e6700457869737473004d6f766500494f457863657074696f6e0044656c6574650049734e756c6c4f725768697465537061636500496e76616c696444617461457863657074696f6e006765745f436861727300436861720049734c65747465724f724469676974005472696d0049734e614e004973496e66696e6974790049734e756c6c4f72456d7074790053797374656d2e5465787400456e636f64696e67006765745f555446380042696e6172795772697465720042696e6172795265616465720052656164537472696e670052656164496e743332005265616453696e676c65006765745f506f736974696f6e00456e7669726f6e6d656e74005370656369616c466f6c64657200476574466f6c646572506174680047657446696c65730047657446696c654e616d65576974686f7574457874656e73696f6e00436f6e766572746572603200417272617900436f6e76657274416c6c004a6f696e004d657373616765487564004d6573736167655479706500537072697465004d657373616765006765745f7a65726f006765745f61637469766553656c6600556e697479456e67696e652e506879736963734d6f64756c650050687973696373005261796361737448697400517565727954726967676572496e746572616374696f6e006765745f706f696e74006765745f6d61676e697475646500476574416c6c506965636573496e52616469757300426f756e6473004973506c616365644279506c61796572005a4e657456696577004765745a444f00617373656d626c795f7574696c73005574696c73004765745072656661624e616d65005a4e65745363656e6500476574507265666162006765745f6379616e004c696e6552656e6465726572007365745f7368617265644d6174657269616c007365745f656e645769647468007365745f73746172745769647468007365745f757365576f726c645370616365006765745f6d696e006765745f6d6178003c50726976617465496d706c656d656e746174696f6e44657461696c733e7b38303439414445392d333036412d343145392d393643312d3039334539303343324433367d00436f6d70696c657247656e6572617465644174747269627574650056616c756554797065005f5f5374617469634172726179496e69745479706553697a653d36340024246d6574686f643078363030303032612d310052756e74696d6548656c706572730052756e74696d654669656c6448616e646c6500496e697469616c697a654172726179007365745f706f736974696f6e436f756e7400536574506f736974696f6e003c43617074757265536e617073686f743e625f5f310061006200436f6d70617269736f6e6031004353243c3e395f5f436163686564416e6f6e796d6f75734d6574686f6444656c65676174653200436f6d70617265546f0077004765745465787400536f72740044696374696f6e6172796032006d5f7265734974656d00476574416d6f756e74006d5f6974656d446174610054727947657456616c7565007365745f4974656d004b657956616c756550616972603200496e76656e746f727900476574496e76656e746f7279006765745f4b657900436f756e744974656d73006765745f56616c75650045756c6572006d5f756964005365745465787400436f6e7461696e657200476574416c6c4974656d73004974656d5374616e6400486176654174746163686d656e740041726d6f725374616e640041726d6f725374616e64536c6f74006d5f736c6f747300436c61696d4f776e6572736869700049734f776e6572005a444f4d616e0052656d6f766541740053706c69740053797374656d2e476c6f62616c697a6174696f6e0043756c74757265496e666f006765745f496e76617269616e7443756c74757265004e756d6265725374796c65730049466f726d617450726f7669646572005472795061727365000000004b5700610069007400200066006f0072002000740068006500200071007500650075006500640020006200750069006c00640069006e006700200063006f006d006d0061006e0064002e000080bf4200750069006c00640069006e006700200063006f006d006d0061006e00640020007100750065007500650064002e002000520065007400750072006e00200074006f002000560061006c006800650069006d0020007700690074006800200079006f00750072002000680061006d006d0065007200200061006e006400200063006c006f00730065002000670061006d00650020006d0065006e0075007300200074006f002000700072006f0063006500730073002000690074002e00006945006e00610062006c006500200042006c00750065007000720069006e00740020006d006f0064006500200061006e00640020006300610070007400750072006500200061002000730065006c0065006300740069006f006e002000660069007200730074002e00002353006100760065006400200062006c00750065007000720069006e0074003a0020000080d942006c00750065007000720069006e007400200074006f006f006c0073002000720065006100640079002e0020005500730065002000430061007000740075007200650020006f00720020004c006f0061006400200069006e00200074006800650020004200750069006c00640069006e0067002000770069006e0064006f0077002c0020007400680065006e002000720065007400750072006e00200074006f0020007400680065002000670061006d00650020007700690074006800200079006f00750072002000680061006d006d00650072002e00005544007200610067002d006200750069006c006400200070006c006100630065006d0065006e00740020006d006500740061006400610074006100200075006e0061007600610069006c00610062006c0065002e000180b5480061006d006d00650072003a0020004300740072006c0020002b0020006c006500660074002d00640072006100670020007000720065007600690065007700730020006100200072006f0077003b002000720065006c00650061007300650020006c00650066007400200063006c00690063006b00200074006f0020006200750069006c0064002e00200052006900670068007400200063006c00690063006b002000630061006e00630065006c0073002e00012b53006f006c006f0054006f006f006c006b00690074005f0044007200610067004200750069006c0064000029440072006100670020006200750069006c0064002000730074006f0070007000650064003a00200000216d005f0070006c006100630065006d0065006e007400470068006f007300740000236d005f0070006c006100630065006d0065006e00740053007400610074007500730000256d005f0070006c006100630065005000720065007300730065006400540069006d00650000236d005f006c0061007300740054006f006f006c00550073006500540069006d006500001550006c0061006300650050006900650063006500001f4700650074004200750069006c0064005300740061006d0069006e006100002547006500740050006c006100630065004400750072006100620069006c00690074007900002955007000640061007400650050006c006100630065006d0065006e007400470068006f00730074000021470065007400530065006c0065006300740065006400500069006500630065000019470065007400520069006700680074004900740065006d00001924006900740065006d005f00680061006d006d0065007200000b66006c006f006f0072000009770061006c006c0000096200650061006d00000972006f006f006600000532003600000534003500001f53007000720069007400650073002f00440065006600610075006c007400003750007200650076006900650077002000730068006100640065007200200075006e0061007600610069006c00610062006c0065002e00001752006f007700200070007200650076006900650077000019500072006500760069006500770020006d00650073006800004b6d0069007300730069006e00670020006d006100740065007200690061006c00730020006f00720020006300720061006600740069006e0067002000730074006100740069006f006e00007d6e006f007400200065006e006f0075006700680020007300740061006d0069006e0061002000280065006e00610062006c006500200055006e006c0069006d00690074006500640020007300740061006d0069006e00610020006f0072002000460072006500650020004300720061006600740069006e00670029000027680061006d006d006500720020006e006500650064007300200072006500700061006900720000174100750074006f002d006200750069006c007400200001032f00001120007000690065006300650073002e00002552006f0077002000730074006f0070007000650064002000610066007400650072002000001320007000690065006300650073003a00200000032e00005152006f0077002000630061006e00630065006c006c00650064003a00200063006f006e00740072006f006c00730020006f007200200074006f006f006c0020006300680061006e006700650064002e00005952006f0077002000630061006e00630065006c006c00650064002e00200041006c0072006500610064007900200070006c00610063006500640020007000690065006300650073002000720065006d00610069006e002e00008091430068006f006f0073006500200061002000760061006c0069006400200073007400720061006900670068007400200066006c006f006f0072002c002000770061006c006c0020006f007200200068006f00720069007a006f006e00740061006c0020006200650061006d0020007700690074006800200073006e0061007000200070006f0069006e00740073002e00003b52006f0077002000630061006e00630065006c006c00650064003a0020004300740072006c002000720065006c00650061007300650064002e00001350007200650076006900650077003a00200000812120007000690065006300650073002e002000520065006c00650061007300650020006c00650066007400200063006c00690063006b002000280068006f006c00640020004300740072006c002900200074006f00200070006c006100630065003b00200072006900670068007400200063006c00690063006b002000630061006e00630065006c0073002e0020004100750074006f002d006200750069006c0064007300200061007400200074006800650020007000720065007600690065007700200070006f0073006900740069006f006e0073003b0020006e006f002000630068006100730069006e00670020006f00720020006c0069006e00650020006f00660020007300690067006800740020006e00650065006400650064002e000180dd4e006f002000630061007000740075007200650064002000730065006c0065006300740069006f006e002000690073002000720065006100640079002e00200043006c00690063006b00200043006100700074007500720065002c002000720065007400750072006e00200074006f0020007400680065002000670061006d00650020006f006e00630065002c00200061006e00640020007700610069007400200066006f0072002000740068006500200063006100700074007500720065006400200070006900650063006500200063006f0075006e0074002e0000034e0000092e0074006d00700000052000280000032900000100092e00760062007000007954006f006f0020006d0061006e007900200062006c00750065007000720069006e0074007300200077006900740068002000740068006900730020006e0061006d0065002e0020004300610070007400750072006500200077006900740068002000610020006e006500770020006e0061006d0065002e000080b755007300650020006100200062006c00750065007000720069006e00740020006e0061006d00650020006f006600200031002d003400380020006c006500740074006500720073002c0020006e0075006d0062006500720073002c0020007300700061006300650073002c002000680079007000680065006e0073002c00200075006e00640065007200730063006f0072006500730020006f007200200070006100720065006e007400680065007300650073002e00015b42006c00750065007000720069006e00740020006e0061006d006500200063006f006e007400610069006e007300200061006e00200069006e00760061006c006900640020006300680061007200610063007400650072002e00004942006c00750065007000720069006e00740020006d00750073007400200063006f006e007400610069006e00200031002d0035003100320020007000690065006300650073002e00012f49006e00760061006c0069006400200062006c00750065007000720069006e007400200074006500780074002e00003d49006e00760061006c0069006400200062006c00750065007000720069006e007400200063006f006f007200640069006e0061007400650073002e00003d42006c00750065007000720069006e0074002000650078006300650065006400730020003100300030006d00200062006f0075006e00640073002e00003749006e00760061006c0069006400200062006c00750065007000720069006e007400200072006f0074006100740069006f006e002e00000b53005400420050003100003342006c00750065007000720069006e0074002000660069006c006500200074006f006f0020006c0061007200670065002e00003b55006e0073007500700070006f007200740065006400200062006c00750065007000720069006e007400200066006f0072006d00610074002e00002949006e00760061006c0069006400200070006900650063006500200063006f0075006e0074002e00003555006e0065007800700065006300740065006400200062006c00750065007000720069006e007400200064006100740061002e000025560061006c006800650069006d0053006f006c006f0054006f006f006c006b0069007400001542006c00750065007000720069006e0074007300002f4e006f00200073006100760065006400200062006c00750065007000720069006e0074007300200079006500740000052c002000000b2a002e00760062007000003550007200650076006900650077002000730068006100640065007200200075006e0061007600610069006c00610062006c006500002342006c00750065007000720069006e00740020007000720065007600690065007700001d42006c00750065007000720069006e00740020006d006500730068000071530065006c0065006300740069006f006e0020006500780063006500650064007300200035003100320020007000690065006300650073002e0020005200650064007500630065002000740068006500200062006f0078002000640069006d0065006e00730069006f006e0073002e00003542006c00750065007000720069006e0074002000730065006c0065006300740069006f006e00200062006f0075006e0064007300001343006100700074007500720065006400200000192000700069006500630065007300200066006f00720020000080a72e002000530065006c0065006300740069006f006e002000690073002000660069007800650064002e00200043006c00690063006b0020005300610076006500200063006100700074007500720065006400200062006c00750065007000720069006e007400200069006e0020004200750069006c00640069006e006700200074006f006f006c0073002c0020006f0072002000700072006500730073002000460037002e000080bd4e006f00200070006c0061007900650072002d006200750069006c0074002000700069006500630065007300200069006e002000740068006500200062006f0078002e0020005300740061006e006400200069006e007300690064006500200074006800650020006200750069006c00640069006e006700200061007400200066006c006f006f00720020006c006500760065006c00200061006e00640020004300610070007400750072006500200061006700610069006e002e00015941002000730065006c00650063007400650064002000700069006500630065002000640069007300610070007000650061007200650064003b0020006300610070007400750072006500200061006700610069006e002e000033460069006c00650020007300610076006500640020007300750063006300650073007300660075006c006c0079003a002000002d4d0069007300730069006e00670020006200750069006c00640020007000720065006600610062003a0020000011500072006500760069006500770020000080d33a002000610069006d00200074006f00200070006f0073006900740069006f006e003b00200051002f004500200072006f007400610074006500200031003500200064006500670072006500650073003b00200050006100670065002000550070002f0044006f0077006e002000610064006a0075007300740020006800650069006700680074003b0020004600360020006c006f0063006b0073003b0020004600370020006200750069006c006400730020006c006f0063006b0065006400200070007200650076006900650077002e0000674c006f0063006b002000740068006500200070006c006100630065006d0065006e007400200070007200650076006900650077002000770069007400680020004600360020006200650066006f007200650020006200750069006c00640069006e0067002e0000214d0069007300730069006e00670020007000720065006600610062003a002000003d4d0069007300730069006e00670020006d006100740065007200690061006c0073002f00730074006100740069006f006e00200066006f0072002000005d2e00200045006e00610062006c0065002000460072006500650020004300720061006600740069006e00670020006f007200200073007500700070006c007900200072006500710075006900720065006d0065006e00740073002e00002d570068006f006c006500200062006c00750065007000720069006e00740020006e00650065006400730020000003200000232e0020004e006f007400680069006e006700200070006c0061006300650064002e0000134200750069006c00640069006e006700200000072e002e002e00003142006c00750065007000720069006e0074002000730074006f00700070006500640020006100660074006500720020000080af20007000690065006300650073003a0020006d006100740065007200690061006c0073002c002000730074006100740069006f006e002c0020007300740061006d0069006e00610020006f0072002000680061006d006d006500720020006400650070006c0065007400650064002e00200055006e0064006f002000630061006e002000720065006d006f0076006500200070006c00610063006500640020007000690065006300650073002e0000774e006100740069007600650020007000690065006300650020006300720065006100740069006f006e00200063006f0075006c00640020006e006f0074002000620065002000760065007200690066006900650064003b002000700061007300740065002000730074006f0070007000650064002e00000d4200750069006c0074002000001b20007000690065006300650073002000660072006f006d002000003f2e00200055006e0064006f002000610066006600650063007400730020006f006e006c007900200074006800690073002000700061007300740065002e00006d55006e0064006f0020006900640065006e00740069007400790020006300680061006e006700650064003b0020007200650066007500730069006e006700200074006f002000720065006d006f00760065002000740068006100740020006f0062006a006500630074002e0000808745006d0070007400790020007400680065002000700061007300740065006400200063006f006e007400610069006e006500720020006200650066006f0072006500200075006e0064006f0069006e0067002000690074002e00200052006500740072007900200055006e0064006f0020006100660074006500720077006100720064002e000073520065006d006f0076006500200064006900730070006c00610079006500640020006900740065006d0073002000660072006f006d002000740068006500200070006100730074006500640020007300740061006e00640020006200650066006f0072006500200055006e0064006f002e000073520065006d006f00760065002000650071007500690070006d0065006e0074002000660072006f006d00200074006800650020007000610073007400650064002000610072006d006f00720020007300740061006e00640020006200650066006f0072006500200055006e0064006f002e00006b43006f0075006c00640020006e006f00740020006f0077006e002000700061007300740065006400200070006900650063006500200066006f007200200055006e0064006f002e0020005200650074007200790020006100660074006500720077006100720064002e000080b34100200070006100730074006500640020007000690065006300650020006900730020006f00750074007300690064006500200074006800650020006c006f006100640065006400200061007200650061002e002000520065007400750072006e00200074006f00200074006800650020007000610073007400650064002000730074007200750063007400750072006500200061006e006400200072006500740072007900200055006e0064006f002e00000d55006e0064006f003a00200000808d200070006100730074006500640020007000690065006300650073002000720065006d00610069006e0069006e0067002e002000520065006d006f007600650064002000700069006500630065007300200064006f0020006e006f0074002000640072006f0070002f0072006500660075006e00640020006d006100740065007200690061006c0073002e000080d74200750069006c00640069006e00670020007000610075007300650064002f00630061006e00630065006c006c00650064003a00200063006f006e00740072006f006c00730020006f0072002000680061006d006d0065007200200075006e0061007600610069006c00610062006c0065002e00200041006c0072006500610064007900200070006c00610063006500640020007000690065006300650073002000720065006d00610069006e003b00200055006e0064006f00200069007300200061007600610069006c00610062006c0065002e00005f430061007000740075007200650020007200650071007500690072006500730020006e0061006d006500200061006e0064002000770069006400740068002c0020006800650069006700680074002c002000640065007000740068002e00004742006f0078002000640069006d0065006e00730069006f006e00730020006d00750073007400200062006500200032002d003800300020006d00650074007200650073002e00017b50007200650076006900650077002000630061006e00630065006c006c00650064002e00200053006100760065006400200062006c00750065007000720069006e0074007300200061006e006400200070006100730074006500640020007000690065006300650073002000720065006d00610069006e002e00003d42006c00750065007000720069006e00740020006f007000650072006100740069006f006e002000630061006e00630065006c006c00650064002e0000495000720065007600690065007700200075006e006c006f0063006b00650064003b002000610069006d00200074006f0020007200650070006f0073006900740069006f006e002e00008085500072006500760069006500770020006c006f0063006b00650064002e002000460037002000730061007600650073002000730065006c0065006300740069006f006e0020002f0020006200750069006c0064007300200062006c00750065007000720069006e0074003b00200046003600200075006e006c006f0063006b0073002e00001b530061007600650020006600610069006c00650064003a002000002742006c00750065007000720069006e0074002000730074006f0070007000650064003a002000006b20004500780069007300740069006e00670020007000690065006300650073002000720065006d00610069006e003b00200055006e0064006f002000720065007400610069006e007300200074006800650020006c006100730074002000700061007300740065002e000000e9ad49806a30e94196c1093e903c2d360008b77a5c561934e0890306110d0434000000020608070615121101120c05000201080e040000120c0300000e05000101121502060e0306121503061210030612190306121d03000001050001021215070003021215020c0320000102060203061224030612210306112503061129070615122d01123103061235070615122d01112502060c042001020203200002052001011231042001010e05200202020c050002080c0c0a00020c15122d0111250202061c03061d050a0002010e15122d01121c0400010e0e0400020000040001020c0900010115122d01121c0b000201123915122d01121c0a000115122d01121c1239070615122d011221070615122d01121c070615122d011228030612310600011125121c0600011129121c062001123112310720020210112502062002021215020308000e0306123d030611410420010108060002011c10020615121101120c03200008052001011300040001011c0c0704120c0215121101120c0204200013000c070402120c15121101120c020500020e0e0e0507030e0e020307010e070002021219121907000202121d121d0a0703020215121101120c0a07030215121101120c020500010212610700020212611261030701020420001231050001011261053001001e00040a01121004200012690320000e06070312690202060001126d117107200212190e110d0f2005121d0e110d12791d126d1d117d072002121d0e110d0507011d126d052002011c1c0615122d0112310920001511808901130007151180890112310c0703123102151180890112310620021c1c1d1c0300000204061280a9050002020e0e0500001280c1060702128099020420011c1c040001081c042001020e0520001280c9042000112504200011290715122d011280c9040a0112210a20010115122d011280c90615122d0111250815118089011280c9062001112511250400001125070002112511250c0800021125112911251b070812310e15122d011280c91280c9021d1c0215118089011280c90600011280cd0e062001011280cd072004010c0c0c0c062001011180d1073001011d1e0002050a011280d50520001280d9072002011280c90205200101112506000111291129080002112911291129052001011129062001011280d9050a011280dd062001011d1235062001011180e504200101020520011300080800021125112511251a070b1280cd12311280d512311280dd1d12350808021d1280d5080500001280e90520001180ed062001021180ed0820020212211180f104061280f5042001020c05061d1280fd0a2004011d1280fd080808042001010c0500020c0c0c0300000c0500010e1d1c0c070708128099020202021d1c0407011d1c04000102080600010211811505000012811907200201112511250820020211811d100c05200111250c0400010c0c0600030e1c1c1c13070c02020211811d0c1125020c0c02021181210400010d0d0500020808080307010807151180890111251707070c112511250c151180890111251511808901112502050703021c020420001d05080704128129021c020600011281310e0500001181350420010e0e060002010e1d050600011281410e0520020e08080600030e0e0e0e040001020e050002010e0e040001010e10070a0e128141080e0e020e1c0211813504200103080400010203070705030e020e080615122d01121c071511808901121c130708121c0c0c021511808901121c1d0c1d0c0805000012815109200301123912815102150708128155121c0c1511808901121c1d0c1d0c08020320000a0320000c16070715122d01121c1281590808121c15122d01121c020600010e1181610600021d0e0e0e0715128165020e0e052002011c18121002021d1e011d1e0015128165021e001e01040a020e0e0600020e0e1d0e062003010c0c0c040701112504070111290c2005011181710e081281750204070202020c0703123115118089011231020615122d0112281b070b1280cd12311280d512311280dd1d1235081231021d1280d50810000602112511251011817d0c081181810e0706123111817d1280c902021d1c0615122d0112210c00030111250c15122d0112210715118089011221052001021125050a01128189042000123d0500010e123105000012819105200112310e0500001180d1050a01128195052001011235040100000003061130090002011281691181a50620020108112533071315122d01122111818512211281890e123112311280cd128195112511251d11251d080815118089011221020c1d11251d1c07000208121c121c0806151281a901121c042001080c050a011281ad07151281a901121c0a200101151281a90113001b070815122d01121c1221112511291281ad121c02151180890112211a070815122d01121c128141121c12311231021511808901121c0c07151281b1020e0804061280950420010808040612809908200202130010130107200201130013010b2000151181b5021300130107151181b5020e080b2000151181b902130013010520001281bd07151181b9020e08062003080e0802042000130131070e151281b1020e08121c123112211280fd0e08151181b9020e08021511808901121c1d1280fd08151181b5020e081d1c07000311290c0c0c05200102130031071108121c1221128099021129112515122d011221122115122d011221122112818912281281ad021d1c151180890112210700020211411141050a011281c109200015122d011280990715122d01128099050a011281c5050a011281c90420010208080615122d011281cd0715122d011281cd0500001281d1062001123d11411307080812281281891281c11281c51281c908020620011d0e1d030500001281d50c0004020e1181d91281dd100c14070b120c1d0e1d0c0811251269112902021d03020801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f77730130a7000000000000000000004ea7000000200000000000000000000000000000000000000000000040a7000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff250020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058c00000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001700010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0044007200610067004200750069006c006400560035002e0064006c006c00000000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800170001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0044007200610067004200750069006c006400560035002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000c000000603700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper,window,rowControl,buildingStatus

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','DragBuildV5')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_DragBuildV5_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=dragHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write drag-build helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Drag-build helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','DragBuildV5'),'Drag-build helper class')
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
      watch=createTimer(form,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          local sf=field(state.helper.class,'Status')
          local address=sf.staticAddress
          if not address or address<=sf.offset then address=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+sf.offset end
          local value=readPointer(address)
          if value and value~=0 then playerStatus.Caption=stringValue(value);hint(playerStatus,playerStatus.Caption);if buildingStatus then buildingStatus.Caption=playerStatus.Caption end end
          assert(readInteger(state.enabled)==1,playerStatus.Caption)
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
    playerStatus.Caption=mode==0 and 'Auto rows: Ctrl + left-drag, then release to build.' or 'Blueprint mode ready. Return to Valheim, equip your hammer and follow the Building instructions.'
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
    local b=createButton(window);b.Caption=caption;b.Left=x;b.Top=y;b.Width=306;b.Height=34;b.OnClick=fn;return b
  end
  rowControl=button('Auto rows: OFF',18,169,function() activate(0,true) end)
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
do
local enemyHelperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300fd06c76a0000000000000000e00002210b010b000040000000060000000000007e5e000000200000006000000000001000200000000200000400000000000000040000000000000000a000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000245e00005700000000600000d002000000000000000000000000000000000000008000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000843e0000002000000040000000020000000000000000000000000000200000602e72737263000000d0020000006000000004000000420000000000000000000000000000400000402e72656c6f6300000c0000000080000000020000004600000000000000000000000000004000004200000000000000000000000000000000605e000000000000480000000200050010380000142600000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133002009f00000001000011000316320c037e100000048e69fe042b0116000a062d0b7201000070730300000a7a7e0a00000414280400000a2d2a7e0b00000414280400000a2d1d7e0c00000414280400000a2d107e0d00000414280500000a16fe012b0116000a062d0b7247000070730600000a7a0280050000040380070000047e0600000417588006000004168008000004148004000004178002000004729700007080030000042a6200168002000004168008000004720101007080030000042a133002001700000001000011007e0200000417fe0116fe010a062d061780080000042a00133002003200000001000011007e0200000417332202280700000a2c1a027e05000004280800000a2c0d027e0900000a280800000a2b0116000a2b00062ab200026f0a00000a6f0b00000a8004000004168002000004725b0100707e04000004280c00000a80030000042a001b3002001a01000002000011007e0200000417fe010b072d053806010000007e0500000428040000060b072d0c00280200000600ddeb0000007e09000004280700000a2c2d7e090000047b0e0000047e05000004280d00000a2d137e090000047b0f0000047e06000004fe012b0116002b0117000b072d23007e090000046f10000006007e090000046f0e00000a280f00000a00148009000004007e09000004280700000a0b072d44007285010070731000000a280100002b80090000047e090000047e050000047d0e0000047e090000047e060000047d0f0000047e090000047e070000046f0b00000600007e090000046f0f0000060000de280a00062805000006007e09000004280700000a16fe010b072d0b7e090000046f100000060000de0000002a00000110000000001200ddef002807000001033003006d00000000000000d00b000001281200000a72b10100701f34281300000a800a000004d004000001281200000a72c70100701f34281300000a800b000004d004000001281200000a72eb0100701f34281300000a800c000004d021000001281200000a72ff0100701f346f1400000a800d0000042a0000001330030064000000030000110003280700000a0b072d022b56036f0200002b0a06280700000a0b072d1600036f0300002b0a027b27000004066f1600000a0000027b26000004066f1700000a0b072d13027b2600000406066f1800000a6f1900000a000622000000006f1a00000a002a13300400c80200000400001100027b2a000004130711073af2000000007e2e00000414280500000a2d107e2f00000414280500000a16fe012b011600130711072d0b721d020070731b00000a7a02281c00000a7d28000004027b28000004280700000a130711072d0b726f020070731d00000a7a027e2e000004027b280000046f1e00000aa5240000017d2900000402027b0e0000046f0400002b7d2b000004027b2b000004280700000a2c1a027b2b0000046f2000000a2c0d027b2b0000046f2100000a2b011600130711072d0b72a5020070731d00000a7a02027b2b0000046f2200000a7d2c00000402027b2c0000047e2300000a72f90200706f2400000a7d2d00000402177d2a00000400027b28000004280700000a2c15027b28000004281c00000a280800000a16fe012b011700130711072d0d027b28000004166f2500000a00027b2b000004280700000a2c32027b2b0000046f2000000a2c25027b2b0000046f2100000a2c18027b2b0000046f2200000a027b2c000004fe0116fe012b011700130711072d16027b2c0000047e2300000a72f90200706f2600000a00282700000a0a06280700000a16fe01130711073a86000000007e3000000413081613092b6b110811099a0b00d026000001281200000a071f346f1400000a0c0814280500000a16fe01130711072d1172fb02007007280c00000a731b00000a7a08066f1e00000a751e0000010d09280700000a16fe01130711072d0d02096f0e00000a28080000060000110917581309110911088e69fe04130711072d87282800000a13041104280700000a16fe01130711072d7c007e2f00000411046f1e00000a7528000001130511052c121105027b0e0000046f2900000a16fe012b011700130711072d49001105027b0e0000046f2a00000a130611066f2b00000a720d0300701f346f1400000a0c0814282c00000a16fe01130711072d14020811066f1e00000a750900000128080000060000002a1b3003006d010000050000110000027b260000046f2d00000a0c2b2f1202282e00000a0a1200282f00000a280700000a16fe010d092d141200282f00000a1200283000000a6f1a00000a001202283100000a0d092dc6de0f1202fe160300001b6f3200000a00dc0000027b270000046f3300000a13042b1c1204283400000a0b07280700000a16fe010d092d0707280f00000a001204283500000a0d092dd9de0f1204fe160500001b6f3200000a00dc00027b260000046f3600000a00027b270000046f3700000a00027b2a00000416fe010d093a9f00000000027b28000004280700000a2c15027b28000004281c00000a280800000a16fe012b0117000d092d12027b28000004027b290000046f2500000a00027b2b000004280700000a2c32027b2b0000046f2000000a2c25027b2b0000046f2100000a2c18027b2b0000046f2200000a027b2c000004fe0116fe012b0117000d092d17027b2c0000047e2300000a027b2d0000046f2600000a0002167d2a000004002a000000011c000002000e003e4c000f0000000002006a002b95000f0000000013300500230200000600001100027b0e0000046f3800000a0d092d0b7219030070731d00000a7a027b0e0000046f3900000a2d2a027b0e0000046f3a00000a2d1d027b0e0000046f3b00000a2d10027b0e0000046f3c00000a16fe012b0116000d092d0b72b0030070731d00000a7a283d00000a7e10000004039a6f3e00000a0a06280700000a2c1a066f0500002b280700000a2c0d066f0600002b280700000a2b0116000d092d1772330400707e10000004039a280c00000a731d00000a7a02027b0e0000046f0700002b7d1300000402027b0e0000046f0800002b7d14000004027b13000004280700000a2c1f027b14000004280700000a2c12027b0e0000047b3f00000a280700000a2b0116000d092d0b7265040070731d00000a7a02027b0e0000046f4000000a6f4100000a7d1f0000040206027b1f000004284200000a22cdcc4c3e284300000a284400000a027b0e0000046f4000000a6f4500000a280900002b7d1100000402027b110000046f0500002b7d12000004027b110000046f0a00002b0b07280700000a2c10076f2000000a2c08076f2100000a2b0116000d092d0b72d1040070731d00000a7a00027b110000046f0b00002b13041613052b14110411059a0c08166f4800000a00110517581305110511048e69fe040d092de0027b12000004167d4900000a02284a00000a7d2300000402284b00000a2200004040587d2500000402037d2400000472270500707e10000004039a7241050070284c00000a80030000042a001b300300960200000700001100284a00000a027b23000004fe020d092d07160c387b020000027b170000046f4d00000a0000027b120000046f4e00000a6f4f00000a6f5000000a13042b221204285100000a0a066f5200000a16fe010d092d0d027b17000004066f5300000a001204285400000a0d092dd3de0f1204fe160700001b6f3200000a00dc00027b120000046f5500000a0b027b170000046f5600000a2d0e072c0b076f5200000a16fe012b0117000d092d0d027b17000004076f5300000a00027b170000046f5600000a16fe0116fe010d092d3800284b00000a027b25000004fe0416fe010d092d07160c38ab0100007e10000004027b240000049a7283050070280c00000a731d00000a7a027b0e0000046f3a00000a2d1d027b0e0000046f3b00000a2d10027b0e0000046f3c00000a16fe012b0116000d092d0b7236060070731d00000a7a02027b17000004027b120000046f5500000a6f5700000a7d20000004027b2000000416fe0416fe010d092d300002167d20000004027b12000004027b17000004166f5800000a166f5900000a0d092d0b72c7060070731d00000a7a0002027b0e0000046f3800000a7d1a00000402027b130000046f3800000a7d1b00000402027b140000046f5a00000a7d1c000004027e0d000004027b0e0000046f1e00000aa5240000017d1d00000402027b0e0000047b3f00000a6f5b00000a7d1e00000402177d18000004027b13000004166f4800000a00027b0e000004166f4800000a007e0d000004027b0e000004178c240000016f5c00000a00027b14000004285d00000a6f5e00000a00027b14000004285d00000a6f5f00000a00027b14000004176f6000000a0002280d00000600022809000006007e10000004027b240000049a721d070070280c00000a8003000004170c2b00082a00000110000002003d00316e000f0000000013300300af000000080000110000027b0e000004176f0c00002b0c160d2b3708099a0a00027b15000004066f6200000a130411042d13027b1500000406066f6300000a6f6400000a0006176f6500000a00000917580d09088e69fe04130411042dbd00027b0e000004176f0d00002b1305160d2b381105099a0b00027b16000004076f6600000a130411042d13027b1600000407076f6700000a6f6800000a0007166f6900000a00000917580d0911058e69fe04130411042dbb2a0013300300700000000100001100286a00000a2c617e0c000004027b0e000004146f6b00000aa5240000012c49286c00000a2d42286d00000a2d3b286e00000a2d34286f00000a2d2d287000000a2d26287100000a2d1f287200000a280700000a2c0f287200000a6f7300000a16fe012b0117002b0116000a2b00062a133004002f0500000900001100027b1900000416fe01130b110b2d053819050000027b0e00000428040000062c0f027b0f0000047e06000004fe012b011600130b110b2d0d000228100000060038e8040000027b12000004280700000a2c1d027b120000046f3900000a2d10027b0e0000046f3900000a16fe012b011600130b110b2d1d002802000006000228100000060072f4070070800300000438990400002021010000287400000a16fe01130b110b2d1300280200000600022810000006003873040000027b180000042d0802280c0000062b011700130b110b2d05385604000002027b120000046f4000000a6f4100000a7d1f000004027b0e0000046f4000000a027b1f0000046f7500000a00027b0e0000047b3f00000a027b120000046f7600000a6f7500000a0002280d000006000228090000060002280e0000060a0616fe01130b110b3adf020000007e0a000004027b13000004146f6b00000a267e0b000004027b0e000004146f6b00000a26027b0e0000047b3f00000a6f7700000a0b120122000000007d7800000a1201287900000a00284200000a07287a00000a0c287b00000a0d7256080070287c00000a2d03162b0117007262080070287c00000a2d03162b011700596b12037b7d00000a581304726c080070287c00000a2d03162b011700727c080070287c00000a2d03162b011700596b12037b7e00000a581305071105284300000a081104284300000a284400000a220000803f287f00000a1306728e080070287c00000a2d0c729c080070287c00000a2b011700130772b0080070287c00000a2d2472d0080070287c00000a2d1872f6080070287c00000a2d0c7202090070287c00000a2b0117001308027b1200000411066f8000000a001206288100000a220ad7233c361511072d1111082d0d027b120000046f3a00000a2c12027b0e0000047b3f00000a6f7700000a2b021106001309027b12000004110922000000006f8200000a00027b120000047214090070287c00000a2d0c721c090070287c00000a2b0117006f8300000a00027b12000004166f8400000a00722a090070288500000a2d0f7234090070288500000a16fe012b011600130b110b2d0d027b12000004166f8600000a007244090070288500000a2d0f724c090070288500000a16fe012b011600130b110b2d061780080000047e080000042c0d027b120000046f3a00000a2b011700130b110b2d4800168008000004027b200000041758027b170000046f5600000a5d130a027b12000004027b17000004110a6f5800000a166f5900000a16fe01130b110b2d0802110a7d200000040011072d0411082c1a284b00000a027b21000004370d027b120000046f3a00000a2b011700130b110b2d3e0002284b00000a229a99193e587d21000004027b120000041411072d18027b17000004027b200000046f5800000a6f8700000a2b0116006f8800000a2600002b2000027b12000004285d00000a6f8000000a00027b12000004166f8300000a0000284b00000a027b22000004fe05130b110b3ad60000000002284b00000a220000003f587d220000041f0b8d01000001130c110c16725a090070a2110c17027b120000046f8900000a288a00000a8c42000001a2110c187278090070a2110c19027b120000046f8b00000a288a00000a8c42000001a2110c1a7280090070a2110c1b027b2000000417588c42000001a2110c1c7294090070a2110c1d027b170000046f5600000a8c42000001a2110c1e7298090070a2110c1f09027b17000004027b200000046f5800000a7b8c00000a7b8d00000aa2110c1f0a729e090070a2110c288e00000a8003000004002a001b3003003a0200000a00001100027b1900000416fe010c082d05382602000002177d190000040002280a0000060000dd1002000000027b180000042c10027b0e000004280700000a16fe012b0117000c083aab01000000027b0e0000046f4000000a027b1f0000046f7500000a00027b0e0000047b3f00000a027b1e0000046f8f00000a0000027b150000046f9000000a0d2b2f1203289100000a0a1200289200000a280700000a16fe010c082d141200289200000a1200289300000a6f6500000a001203289400000a0c082dc6de0f1203fe160a00001b6f3200000a00dc0000027b160000046f9500000a13042b2f1204289600000a0b1201289700000a280700000a16fe010c082d141201289700000a1201289800000a6f6900000a001204289900000a0c082dc6de0f1204fe160c00001b6f3200000a00dc007e0d000004027b0e000004027b1d0000048c240000016f5c00000a00027b14000004280700000a16fe010c082d4200027b14000004027b1c0000046f6000000a00027b1c0000040c082d2400027b14000004285d00000a6f5e00000a00027b14000004285d00000a6f5f00000a000000027b0e000004285d00000a6f8000000a00027b0e000004166f8300000a00027b0e000004027b1a0000046f4800000a00027b13000004280700000a16fe010c082d12027b13000004027b1b0000046f4800000a0000027b11000004280700000a2c0f283d00000a280700000a16fe012b0117000c082d11283d00000a027b110000046f9a00000a0002147d1100000402147d1200000400dc002a0000414c000002000000860000003e000000c40000000f0000000000000002000000e20000003e000000200100000f00000000000000020000001a0000000e00000028000000100200000000000013300200390000000100001100027b0e00000428040000062c0f027b0f0000047e06000004fe012b0116000a062d15000228100000060002280e00000a280f00000a00002a2600022810000006002a0013300300530100000b0000111f1a8d1d0000010a061672e2090070a2061772f6090070a2061872080a0070a2061972160a0070a2061a72200a0070a2061b722c0a0070a2061c723c0a0070a2061d724e0a0070a2061e72580a0070a2061f0972780a0070a2061f0a729a0a0070a2061f0b72b40a0070a2061f0c72d00a0070a2061f0d72f00a0070a2061f0e72fa0a0070a2061f0f720e0b0070a2061f1072200b0070a2061f1172300b0070a2061f1272500b0070a2061f13725e0b0070a2061f1472760b0070a2061f1572900b0070a2061f1672980b0070a2061f1772b00b0070a2061f1872c80b0070a2061f1972e00b0070a2068010000004d015000001281200000a72f00b00701f346f1400000a802e000004d027000001281200000a72240c00701f346f1400000a802f0000041a8d1d0000010a061672320c0070a20617724e0c0070a20618726a0c0070a20619728e0c0070a20680300000042afe02739b00000a7d1500000402739c00000a7d1600000402739d00000a7d1700000402739e00000a7d2600000402739f00000a7d270000040228a000000a002a0042534a4201000100000000000c00000076342e302e33303331390000000005006c00000054090000237e0000c0090000a80b000023537472696e67730000000068150000b40c0000235553001c2200001000000023475549440000002c220000e803000023426c6f620000000000000002000001571d02080908000000fa253300160000010000004300000003000000300000001400000007000000a000000001000000020000000b0000000d00000001000000070000000d00000000000a00010000000000060062005b000a008c0080000600ac009a000e00e900000006001e019a00060049019a00060080015b000e00900100000a00a60180000e00bc0100000e00ca0100001200000280000600300215020a003d0280001200500280000600630215020e006a0200004700730200000a00c802800016004c0380000e00690300000e009f0300000e00b303000006009f047f040600bf047f040600f0045b0006000e055b000a006200800006005c055b000a00780580000600ad055b000600b2055b000e00e0050000060024065b00060047065b0006006a065b000e00890600000e00c70600000e00cf0600000600eb06d80637001107000006002a071502060060075b004300110700000a007a0780000e00b60700000e00ca0700000a00d40780000a001e0880000e00500800008700630800000a00750880000e00920800000a00a30980000600bd099a000e00cf0900000e00e60900000e00eb0900000e00fa0900000e001f0a00001a004b0a80000a00510a80001e00aa0a00000a00b10a80000a00570b80000600670b5b004b007a0b000000000000010000000000010001008101100021002d000500010001000101100040002d0009000e0008005380b9000a001600bf0013001600c70016001600ce0016001300f00019001300f6001300130001011300130008011d001300170120003300290124003300340124003300400124003300530128000600f00019000300f60013003300a00149000100b1014d000100c50151000100db01550001000a025900210046025d0021005902660021007c026f00010084021d0001008a021d00010093021d000100a1021d000100b3021d000100bd021d000100d00277000100d90277000100e80213000100f4027b000100ff027b0001000a031300010015031300010020037b00210058037e0021006103870001006e038f0001007a031d00010091031d000100a80393000100b70397000100c10316003100ce0328003100dd0328003100e203490050200000000096005e012c000100fb20000000009600680133000300142100000000960070013300030038210000000093007b013700030076210000000093008a013d000400a4210000000096009b0143000500dc22000000009118a605330006005823000000008100ed039b000600c823000000008100f403a10007009c260000000081000104a100070034280000000086001104a5000700642a0000000081001704aa000800182d0000000081002304a1000800d42d0000000081002e04aa000800502e0000000086003b04a10008008c330000000086004004a100080020360000000081004804a100080065360000000081004f04a1000800cf370000000086185904a10008007036000000009118a60533000800000001005f04000002006604000001005f04000001006b04000001006d04000001007404000001007804c1005904a500c9005904a100d1005904ae0029000205b30031000205bb00d9005904ae00e1002505c700e1000205cd0021003105190039003f05d50039005005da00e9006305de00e1006a05cd00f1008205e400e1009105e90049005904ae0049009905ef00f900c4050001f900d6050801f900ea0510014900f305ef000c0000062401140004063201a10010063801140000063c01a1001a06440111015904ae00a9003a064f0119015904ae00310061065401f100f305ef00b1007206aa00b1007a06aa00b10082065e01290191061300b9009e066301a900a8066901b900c3066e0131013a06740139013a067a014101f706800141010007540109000907850131006a05bb0014001c07a0011c003907b50124004507ca0124004d07cf011c005707aa0059016c07a1000c001c07d4012c003907ca012c005707aa0014007407a1000c007407a10069018407aa0009019007aa0009019707aa000901a007aa000901a807aa0071013a0603027101c00709020901de072402f100e40729028101f2072f029900ff073402990006083902990012084102810129084a02e1003608500249004208620269015708690109016b086f02a1017a087402a10189087802e90063057c0234007407a10051009c089a02a901a908a00234001c07d4013c003907ca019100b508aa003400000624013c005707aa005100c708b1023400d808b6023400e208ba0234000007c0025100ea08c6026100f408aa00810104092f0231001609cd0299001f09340261002809d30261003b09d30261004f096901f1005f09e90244000406320171007709aa00440000063c0171008d0969014c000406320179008407aa004c0000063c01790057086901b101af091a03b901c8091e03c101dc091a03c901dc091a03d101dc091a033101f3091a03d901fe091a03d901160a1a03e1013a062503e101240aaa00e901590a2b038101640ad3020901710a2f0281017d0a2f029900890a7b0099008b0aa1009900950a4102f901b90a3203f901c90a38030102d30a7b000102890a7b009900d50a39020901e40ad3029900ef0a38010901000b3d0309010b0b69010901120b6901f9011a0b38030901280b690191002d0baa000901410b440309014d0b380109025d0b4c0309016d0b38019100850b510319028e0b1600e900630556038101950bd30244001c07a00154003907b5015c004507ca015c004d07cf0154005707aa004c001c07a00164003907b5016c004507ca016c004d07cf0164005707aa00710191059b0044005904a1004c005904a10034005904a10014005904a1000c005904a10011005904a100080004000e002e000b00c0032e001300c903c300fa0049018a01e6018302d9020b035c039703bb031d012a01ac01c101de019302a902f602030373037c0385038e03048000000000000000000000000000000000dd040000040000000000000000000000010052000000000000000000000000000000000000006900000000000000000000000000000000000000d800000000000000000000000000000000000000e60100000000000000000000000000000000000037030000000000000000000000000000000000002d0a0000000000000000000000000000000000009b0a000000002300f5002b001801230018013f0059012b000f022b0014023f001a023f001f028d005d022b0059018f006902c300f102c300fe0200000000003c4d6f64756c653e0056616c6865696d456e656d79466f726d56362e646c6c00456e656d79466f726d56360056616c6865696d536f6c6f546f6f6c6b697400456e656d79466f726d4472697665725636006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f75720053797374656d2e5265666c656374696f6e0042696e64696e67466c61677300466c61677300456e61626c656400537461747573004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572004f776e65720047656e65726174696f6e0043686f696365004379636c6552657175657374656400447269766572004d6574686f64496e666f0043616d6572614c6f6f6b00457965526f746174696f6e0043616e496e707574004669656c64496e666f00536b697054617267657400436f6e6669677572650044697361626c65004e657874576561706f6e004f776e7300457863657074696f6e004661756c740047616d6543616d657261005469636b00466f726d730047616d654f626a65637400626f64794f626a6563740048756d616e6f696400626f647900506c61796572436f6e74726f6c6c657200636f6e74726f6c6c657200556e697479456e67696e652e506879736963734d6f64756c65005269676964626f647900706c61796572426f64790053797374656d2e436f6c6c656374696f6e732e47656e657269630044696374696f6e61727960320052656e64657265720072656e64657265727300436f6c6c6964657200636f6c6c6964657273004c6973746031004974656d44726f70004974656d4461746100776561706f6e7300736176656400726573746f72656400706c61796572456e61626c656400636f6e74726f6c6c6572456e61626c6564006b696e656d6174696300736b697054617267657400566563746f7233006579654c6f63616c0072657475726e506f736974696f6e00776561706f6e496e646578006e65787441747461636b006e65787453746174757300737061776e4672616d6500666f726d43686f69636500696e697469616c697a6174696f6e446561646c696e6500556e697479456e67696e652e55494d6f64756c650043616e76617347726f75700068696464656e55690061646465645569005a4e65740064697367756973654e6574006f726967696e616c5075626c6963506f736974696f6e0064697367756973655361766564005a4e65745669657700706c6179657256696577005a444f00706c617965725a646f006f726967696e616c4e616d65005075626c6963506f736974696f6e0048756473004d61704d61726b6572730048696465556900486964654964656e7469747900526573746f72654964656e746974790053657475700046696e69736853657475700048696465506c6179657200496e707574416c6c6f776564005374657000526573746f726500557064617465004f6e44657374726f79002e63746f7200706c6179657200666f726d00650063616d657261006f626a0063686f6963650053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d456e656d79466f726d563600417267756d656e74457863657074696f6e006f705f457175616c697479004d697373696e674d656d626572457863657074696f6e006f705f496d706c69636974006d5f6c6f63616c506c617965720047657442617365457863657074696f6e006765745f4d65737361676500537472696e6700436f6e636174006f705f496e657175616c69747900436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f7200547970650052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c65004765744d6574686f6400436861726163746572004765744669656c6400476574436f6d706f6e656e740041646400436f6e7461696e734b6579006765745f616c706861007365745f616c706861004d697373696e674669656c64457863657074696f6e006765745f696e7374616e636500496e76616c69644f7065726174696f6e457863657074696f6e0047657456616c756500426f6f6c65616e00497356616c69640049734f776e6572004765745a444f005a444f5661727300735f706c617965724e616d6500476574537472696e67005365745075626c69635265666572656e6365506f736974696f6e00536574004d696e696d617000456e656d794875640053797374656d2e436f6c6c656374696f6e73004944696374696f6e61727900436f6e7461696e73006765745f4974656d004765745479706500456e756d657261746f7200476574456e756d657261746f72004b657956616c7565506169726032006765745f43757272656e74006765745f4b6579006765745f56616c7565004d6f76654e6578740049446973706f7361626c6500446973706f736500436c656172004265686176696f7572006765745f656e61626c65640049734465616400496e41747461636b00496e446f64676500497354656c65706f7274696e67005a4e65745363656e6500476574507265666162004d6f6e737465724149005472616e73666f726d006d5f657965006765745f7472616e73666f726d006765745f706f736974696f6e006765745f7570006f705f4d756c7469706c79006f705f4164646974696f6e005175617465726e696f6e006765745f726f746174696f6e00496e7374616e746961746500476574436f6d706f6e656e747300426173654149007365745f656e61626c65640046616374696f6e006d5f66616374696f6e0054696d65006765745f6672616d65436f756e74006765745f74696d6500496e76656e746f727900476574496e76656e746f727900476574416c6c4974656d7300486176655072696d61727941747461636b0047657443757272656e74576561706f6e006765745f436f756e7400496e6465784f660045717569704974656d006765745f69734b696e656d61746963006765745f6c6f63616c506f736974696f6e0053657456616c7565006765745f7a65726f007365745f6c696e65617256656c6f63697479007365745f616e67756c617256656c6f63697479007365745f69734b696e656d6174696300476574436f6d706f6e656e7473496e4368696c6472656e006765745f666f72636552656e646572696e674f6666007365745f666f72636552656e646572696e674f6666004170706c69636174696f6e006765745f6973466f6375736564004d6574686f644261736500496e766f6b6500496e76656e746f727947756900497356697369626c65004d656e7500436f6e736f6c650049734f70656e00487564004973506965636553656c656374696f6e56697369626c6500496e52616469616c004368617400486173466f63757300556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004b6579436f6465004765744b6579446f776e007365745f706f736974696f6e00476574457965506f696e74006765745f666f72776172640079004e6f726d616c697a650043726f737300617373656d626c795f7574696c73005a496e70757400566563746f7232004765744a6f794c656674537469636b00476574427574746f6e007800436c616d704d61676e6974756465005365744d6f7665446972006765745f7371724d61676e6974756465005365744c6f6f6b4469720053657452756e0053657457616c6b00476574427574746f6e446f776e004a756d7000486176655365636f6e6461727941747461636b00537461727441747461636b004765744865616c7468004d61746866004365696c546f496e7400496e743332004765744d61784865616c74680053686172656444617461006d5f736861726564006d5f6e616d65007365745f6c6f63616c506f736974696f6e00000045430068006f006f0073006500200061006e00200065006e0065006d007900200066006f0072006d002000660072006f006d0020003100200074006f002000320036002e00004f45006e0065006d007900200066006f0072006d00200063006f006e00740072006f006c0020006d006500740068006f0064007300200075006e0061007600610069006c00610062006c0065002e0000695100750065007500650064002e002000520065007400750072006e00200074006f0020007400680065002000670061006d006500200061006e006400200075006e0070006100750073006500200074006f0020007400720061006e00730066006f0072006d002e000059520065007400750072006e0069006e006700200074006f00200070006c00610079006500720020006f006e00200074006800650020006e006500780074002000670061006d00650020007500700064006100740065002e00002945006e0065006d007900200066006f0072006d002000730074006f0070007000650064003a002000002b53006f006c006f0054006f006f006c006b00690074005f0045006e0065006d00790046006f0072006d0000154c00610074006500550070006400610074006500002355007000640061007400650045007900650052006f0074006100740069006f006e000013540061006b00650049006e00700075007400001d6d005f006100690053006b0069007000540061007200670065007400005145006e0065006d007900200064006900730067007500690073006500200048005500440020006d006500740061006400610074006100200075006e0061007600610069006c00610062006c0065002e0000354e006500740077006f0072006b00200077006f0072006c006400200075006e0061007600610069006c00610062006c0065002e00005350006c00610079006500720020006e0061006d0065002000730074006f00720061006700650020006900730020006e006f00740020006c006f00630061006c006c00790020006f0077006e00650064002e00000100114d0069006e0069006d00610070002e00000b6d005f00670075006900008095520065007400750072006e002000660072006f006d0020007400680065002000700072006500760069006f0075007300200065006e0065006d007900200066006f0072006d00200061006e006400200075006e007000610075007300650020006200650066006f007200650020007400720061006e00730066006f0072006d0069006e006700200061006700610069006e002e00008081460069006e00690073006800200079006f0075007200200061006300740069006f006e002f00740065006c00650070006f0072007400200061006e00640020007300740061006e00640020007300740069006c006c0020006200650066006f007200650020007400720061006e00730066006f0072006d0069006e0067002e00003145006e0065006d007900200066006f0072006d00200075006e0061007600610069006c00610062006c0065003a002000006b50006c006100790065007200200063006f006e00740072006f006c006c00650072002c00200062006f006400790020006f0072002000630061006d00650072006100200061006e00630068006f007200200075006e0061007600610069006c00610062006c0065002e00005554006800650020007400720061006e00730066006f0072006d0065006400200062006f006400790020006900730020006e006f00740020006c006f00630061006c006c00790020006f0077006e00650064002e000019570061006900740069006e006700200066006f0072002000004120006e0061007400690076006500200077006500610070006f006e007300200074006f00200069006e0069007400690061006c0069007a0065002e002e002e000080b1200064006900640020006e006f007400200069006e0069007400690061006c0069007a006500200061006e00790020006e00610074006900760065002000610074007400610063006b0073002000770069007400680069006e002000330020007300650063006f006e00640073002e00200059006f0075007200200070006c006100790065007200200077006100730020006c00650066007400200075006e006300680061006e006700650064002e0000808f50006c00610079006500720020007300740061007200740065006400200061006e00200061006300740069006f006e0020007700680069006c00650020007400720061006e00730066006f0072006d0069006e0067002e0020005300740061006e00640020007300740069006c006c00200061006e0064002000740072007900200061006700610069006e002e00005543006f0075006c00640020006e006f0074002000650071007500690070002000740068006500200065006e0065006d0079002700730020006e0061007400690076006500200077006500610070006f006e002e000180d5200066006f0072006d002e0020004d006f00760065002f00720075006e002f006a0075006d00700020006e006f0072006d0061006c006c0079003b002000410074007400610063006b0020003d0020006e00610074006900760065002000610074007400610063006b003b00200042006c006f0063006b0020003d0020007300650063006f006e0064006100720079003b00200055007300650020003d0020006300790063006c006500200077006500610070006f006e003b0020004600380020003d002000720065007400750072006e002e00006145006e0065006d007900200062006f0064007900200065006e006400650064002e00200059006f0075007200200070006c006100790065007200200068006100730020006200650065006e00200072006500730074006f007200650064002e00000b5200690067006800740000094c00650066007400000f46006f007200770061007200640000114200610063006b007700610072006400000d410074007400610063006b0000134a006f007900410074007400610063006b00001f5300650063006f006e006400610072007900410074007400610063006b0000254a006f0079005300650063006f006e006400610072007900410074007400610063006b00000b42006c006f0063006b0000114a006f00790042006c006f0063006b000007520075006e00000d4a006f007900520075006e0000094a0075006d007000000f4a006f0079004a0075006d0070000007550073006500000d4a006f007900550073006500001d45006e0065006d00790020006800650061006c00740068003a002000000720002f00200000132e00200057006500610070006f006e00200000032f0000053a00200000432e00200055007300650020006300790063006c00650073002000610074007400610063006b0073003b002000460038002000720065007400750072006e0073002e000013470072006500790064007700610072006600001153006b0065006c00650074006f006e00000d440072006100750067007200000957006f006c006600000b540072006f006c006c00000f530065007200700065006e007400001147007200650079006c0069006e00670000094e00650063006b00001f4700720065007900640077006100720066005f0045006c0069007400650000214700720065007900640077006100720066005f005300680061006d0061006e0000194400720061007500670072005f0045006c00690074006500001b4400720061007500670072005f00520061006e00670065006400001f53006b0065006c00650074006f006e005f0050006f00690073006f006e00000942006c006f006200001342006c006f00620045006c00690074006500001153007500720074006c0069006e006700000f460065006e00720069006e006700001f460065006e00720069006e0067005f00430075006c007400690073007400000d47006f0062006c0069006e00001747006f0062006c0069006e0042007200750074006500001947006f0062006c0069006e005300680061006d0061006e0000074c006f00780000175300650065006b0065007200420072006f006f00640000175300650065006b0065007200420072007500740065000017410062006f006d0069006e006100740069006f006e00000f410073006b007300760069006e0000336d005f007000750062006c00690063005200650066006500720065006e006300650050006f0073006900740069006f006e00000d6d005f006800750064007300001b6d005f0073006d0061006c006c004d00610072006b0065007200001b6d005f006c0061007200670065004d00610072006b006500720000236d005f0073006d0061006c006c0053006800690070004d00610072006b006500720000236d005f006c00610072006700650053006800690070004d00610072006b00650072000000006c88fd5f12efc443b405ba77eca024830008b77a5c561934e0890306110d043400000002060802060e030612110206020306120c0306121503061219060002011211080300000105000102121105000101121d05000101122103061d0e03061225030612290306122d03061231080615123502123902080615123502123d0207061512410112490306114d02060c08061512350212510c070615124101125103061255030612590306125d05200101122503200001042001010803200002042001010e07000202121512150700020212191219030701020500010212710700020212711271042000121d0320000e0500020e0e0e0420001225050001011271053001001e00040a01120c050702121d02070001127d11808107200212150e110d07200212190e110d040a01125106151241011251052001011300071512350212510c0520010213000320000c0720020113001301042001010c05070212510204000012550420011c1c040a011259042000125d0520020e080e042001010205200201080e05000012809905000012809d042001021c042000127d15070a1280990e1219127912809d1280a11c021d0e080b2000151180a5021300130108151180a50212510c0b2000151180a9021300130108151180a90212510c04200013000420001301092000151180b101130007151180b10112511c0705151180a90212510c1251151180a50212510c02151180b10112510500001280b905200112250e040a011229050a011280bd040a01122d040a01123104061280c10520001280c1042000114d040000114d070002114d114d0c080002114d114d114d0520001180c50c1001031e001e00114d1180c5040a011225063001001d1e00050a011280c904061180cd030000080300000c0600030e0e0e0e0f0706122512591280c9021d1280c908061512410112490520001280d508200015124101124907151180b101124904200012490320000805200108130005200113000806200202124902052002011c1c05200101114d0f0705124912490202151180b1011249073001011d1e0002040a0112390715123502123902040a01123d0715123502123d020e07061239123d1d123908021d123d030000020620021c1c1d1c0500001280f1060001021180f9050000118101040001020e06200201114d0c0720020212808502040001080c040612810d0500010e1d1c16070d02114d114d1181010c0c114d0202114d08021d1c08151180a50212390208151180a90212390208151180a502123d0208151180a902123d02230705151180a902123902151180a902123d0202151180a502123902151180a502123d020407011d0e0801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773014c5e000000000000000000006e5e0000002000000000000000000000000000000000000000000000605e00000000000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058600000740200000000000000000000740234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004d4010000010053007400720069006e006700460069006c00650049006e0066006f000000b001000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e003000000050001700010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0045006e0065006d00790046006f0072006d00560036002e0064006c006c00000000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005800170001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0045006e0065006d00790046006f0072006d00560036002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000c000000803e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper

local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','EnemyFormV6')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_EnemyFormV6_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=enemyHelperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write enemy-form helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Enemy-form helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','EnemyFormV6'),'Enemy-form helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18,8},1),
    disable=matchingMethod(class,'Disable',{},1),
    hit=matchingMethod(class,'Tick',{18},1)}
  return helper
end
local function stopEnemy()
  if watch then watch.Enabled=false end
  local s=state
  if s and getOpenedProcessID()==s.pid and getProcessIDFromProcessName('valheim.exe')==s.pid then
    -- Disable managed work first; retain code memory for an already-running call.
    local disabled,disableError=pcall(function() invoke(s.helper.disable,0,{}) end)
    if s.info then
      local removed,err=autoAssemble(s.script,false,s.info)
      assert(removed,'Could not remove enemy-form hook: '..tostring(err))
      s.info=nil
    end
    assert(disabled,'Enemy-form helper cleanup failed: '..tostring(disableError))
  end
  state=nil
  enemyButton.Caption='Enemy form: OFF'
end
ValheimEnemyFormStop=stopEnemy
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopEnemy();return close() end
form.OnDestroy=function() stopEnemy();destroy() end
enemyButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopEnemy();playerStatus.Caption='Enemy form disabled.';return end
    local s=playerContext()
    local raw=inputQuery('Enemy transformation - 26 forms','Choose a number (1-26):\n1 Greydwarf | 2 Skeleton | 3 Draugr\n4 Wolf | 5 Troll | 6 Sea Serpent\n7 Greyling | 8 Neck | 9 Greydwarf Brute\n10 Greydwarf Shaman | 11 Draugr Elite | 12 Draugr Archer\n13 Rancid Remains | 14 Blob | 15 Oozer\n16 Surtling | 17 Fenring | 18 Cultist\n19 Fuling | 20 Fuling Berserker | 21 Fuling Shaman\n22 Lox | 23 Seeker Brood | 24 Seeker Soldier\n25 Abomination | 26 Asksvin\nSea Serpent: deep water. Large forms: open space. F8 returns.','1')
    if raw==nil then return end
    local choice=tonumber(raw);assert(choice and choice%1==0 and choice>=1 and choice<=26,'Choose a whole number from 1 to 26.')
    s.helper=loadHelper()
    local cc=pointer(mono_findClass('','GameCamera'),'Player class')
    local entry=pointer(mono_compile_method(matchingMethod(cc,'LateUpdate',{},1)),'Player update code')
    local target=pointer(mono_compile_method(s.helper.hit),'Enemy-form callback')
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
alloc(vhEnemyForm,4096,%X)
label(vhEnemyFormRestore)
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
// GameCamera instance in RCX; callback uses its configured local player.
call %X
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
jmp %X
%X:
db FF 25 00 00 00 00
dq vhEnemyForm
%s
[DISABLE]
%X:
db %s
// Retain the retired allocation until game exit for in-flight callbacks.
]],entry,original,entry,s.storage,s.player,target,table.concat(replay,'\n'),entry+size,entry,
      size>14 and string.format('nop %X',size-14) or '',entry,original)
    assert(playerIdentity(s),'Player changed before enabling enemy form')
    state=s
    local installed,info=autoAssemble(s.script,false)
    assert(installed,'Enemy-form hook installation failed: '..tostring(info))
    s.info=info
    invoke(s.helper.configure,0,{{type=vtPointer,value=s.player},{type=vtDword,value=choice-1}})
    local ef=field(s.helper.class,'Enabled')
    assert(ef.isStatic and ef.typename=='System.Int32','Unexpected helper state layout')
    s.enabled=ef.staticAddress
    if not s.enabled or s.enabled<=ef.offset then s.enabled=pointer(mono_class_getStaticFieldAddress(s.helper.class),'Helper storage')+ef.offset end
    assert(readInteger(s.enabled)==1,'Enemy-form helper did not enable')
    if not watch then
      watch=createTimer(form,false);watch.Interval=250
      watch.OnTimer=function()
        if not state then watch.Enabled=false;return end
        local active,failure=pcall(function()
          assert(playerIdentity(state),'Player changed or world unloaded')
          local sf=field(state.helper.class,'Status');local address=sf.staticAddress
          if not address or address<=sf.offset then address=pointer(mono_class_getStaticFieldAddress(state.helper.class),'Helper storage')+sf.offset end
          local p=readPointer(address)
          if p and p~=0 then playerStatus.Caption=stringValue(p);hint(playerStatus,playerStatus.Caption) end
          assert(readInteger(state.enabled)==1,playerStatus.Caption)
        end)
        if not active then
          local stopped,stopError=pcall(stopEnemy)
          playerStatus.Caption='Enemy form stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;enemyButton.Caption='Enemy form: ON'
    playerStatus.Caption='Return to Valheim to transform. Normal move/run/jump; Attack attacks, Block uses secondary, Use cycles weapons; F8 returns. Enemy health appears here.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopEnemy)
    showMessage('Valheim enemy form: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
  end
end
end

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
