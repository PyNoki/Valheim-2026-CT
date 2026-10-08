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
if ValheimBowBeamStop then ValheimBowBeamStop() end
if ValheimCarryStop then ValheimCarryStop() end
if ValheimDeleteStop then ValheimDeleteStop() end
if ValheimRapidMinerStop then ValheimRapidMinerStop() end
if ValheimRapidHoeStop then ValheimRapidHoeStop() end
if ValheimSpawnStop then ValheimSpawnStop(); ValheimSpawnStop=nil end
if ValheimInventoryWindow then pcall(function() ValheimInventoryWindow.destroy() end) end
local form = createForm(false)
ValheimInventoryWindow = form
form.Caption = 'Valheim inventory and skills'
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
clearFlagButton.Caption='Clear selected flag'
local keepFlagsButton=createButton(form)
keepFlagsButton.Caption='Keep item flags off: OFF'
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
beamButton.Caption='Bow beam: OFF'
local carryButton=createButton(form)
carryButton.Caption='Unlimited carry: OFF'
local deleteButton=createButton(form)
deleteButton.Caption='Inventory delete: OFF'
local minerButton=createButton(form)
minerButton.Caption='Rapid miner: OFF'
local hoeButton=createButton(form)
hoeButton.Caption='Rapid hoe: OFF'
-- Hover hints and a reusable, scrollable help window.
local function hint(control,text)
  control.Hint=text; control.ShowHint=true; control.ParentShowHint=false
end
local helpText=[[
INVENTORY - SELECTED ITEM
Select a row first. Edit quantity accepts positive whole numbers, including values above the normal stack limit. Clone copies the selected item into your inventory; leave an empty slot available.
Freeze selected holds that item's current quantity. Unfreeze selected releases it. X in the first column means frozen. Splitting/reordering does not freeze newly created stacks automatically. Removing an entire stack ends its freeze.

INVENTORY - ALL STACKS
Refresh reads your current inventory. Max all stacks sets each existing stack to its normal maximum; it also reduces overstacks to that maximum. Freeze entire inventory captures the quantities of currently carried stacks; new stacks start unfrozen. Unfreeze all releases every quantity lock.
Auto refill: enable it, open a chest, then Ctrl+left-click a stack to deposit. A copy transfers and the original stays in its inventory slot. This is separate from freezing quantities.

ITEM FLAGS AND GOD MODE
Valheim can flag items as cheated when you kill monsters with them while God mode is enabled. The item flag controls are provided to manage that flag.
Flag Y means marked, - means clear, and ? means unreadable. Clear selected item flag clears the selected carried item's flag once. Keep item flags off repeatedly clears flags on carried items, including newly crafted or upgraded items. After clearing the affected item flag, drop the item from your inventory and pick it up again. Use the normal drop action, not Inventory delete. These controls change item flags, not every record of cheat use.

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

PLAYER TOGGLES
God mode blocks local player damage. See the item-flag notice above. Unlimited stamina replenishes stamina while active. Free crafting bypasses crafting/building material requirements; it does not supply fuel for machines.
Unlimited carry bypasses encumbrance; the displayed weight and normal weight limit remain. Bow beam fires while holding the bow attack button, damaging hostile monsters along the beam. It does not target players, pets or buildings.
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
local hints={
  {hoeButton,'Hold use with the hoe for up to 20 terrain actions per second, stamina refill and full hoe durability. Normal material costs apply; other tools are unaffected.'},
  {minerButton,'10x pickaxe swing animation speed with stamina and equipped pickaxe durability refill. Hold attack to mine; other weapons are unaffected.'},
  {refresh,'Automatically connects to Valheim. Click to reload items and quantities manually; the first load retries automatically until your world is ready.'},
  {edit,'Set the selected stack to a positive whole number. Overstacks above its normal limit are allowed.'},
  {cloneButton,'Copy the selected item into your inventory. Leave an empty inventory slot available.'},
  {freeze,'Hold the selected item at its current quantity. X marks frozen rows. New split stacks are not automatically frozen.'},
  {unfreezeSelected,'Stop holding the selected item quantity. Its current quantity is kept.'},
  {freezeAll,'Freeze the current quantities of all existing inventory stacks. Newly acquired or split stacks start unfrozen.'},
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
  {beamButton,'Hold attack with a bow to fire the energy beam at hostile monsters. Players, pets and buildings are excluded.'},
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
hint(flagWarningHelp,'Select the affected item and use Item flags > Clear selected flag. Then drop it from your inventory and pick it up again. Keep item flags off clears carried-item flags continuously. Use the normal drop action, not Inventory delete. Click for the full guide.')
flagWarningHelp.Cursor=-21;flagWarningHelp.OnClick=openHelp
local actionLabels={}
for i,text in ipairs({'Selected item','All stacks','Item flags'}) do
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
    local groups={{edit,cloneButton,freeze,unfreezeSelected},
      {maxStacksButton,freezeAll,unfreeze,depositButton},
      {clearFlagButton,keepFlagsButton,refresh}}
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
        place(resetMovementButton,group,12,10+2*(buttonH+6),cw-24,buttonH)
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
    frozen[row.item] = makeFreeze(row, snapshot())
    timer.Enabled = true
    drawRows()
    status.Caption = 'Selected stack frozen. X marks every frozen stack.'
  end)
end
freezeAll.OnClick = function()
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
    assert(writeBytes(s.address,1),'No-cost crafting write failed')
    craftingState=s
    assert(readBytes(s.address,1)==1,'No-cost crafting verification failed')
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
  keepFlagsButton.Caption='Keep item flags off: OFF'
end
ValheimItemFlagsStop=stopItemFlags
local flagClose,flagDestroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopItemFlags(); return flagClose() end
form.OnDestroy=function() stopItemFlags(); flagDestroy() end
local function clearItemFlags(onlyRow)
  local snap=snapshot()
  if flagSession then
    assert(flagSession.pid==session and flagSession.player==snap.player
      and flagSession.inventory==snap.inventory,'Player changed; enable the item flag toggle again.')
  end
  if onlyRow then
    assert(snap.player==onlyRow.player and snap.inventory==onlyRow.inventory,'Player changed. Refresh first.')
    local present=false
    for _,item in ipairs(snap.items) do if item==onlyRow.item then present=true end end
    assert(present,'Selected item left your inventory.')
    local info=itemInfo(onlyRow.item)
    assert(info.shared==onlyRow.shared and info.namePointer==onlyRow.namePointer
      and info.class==onlyRow.class,'Selected item changed. Refresh first.')
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
    if not onlyRow or item==onlyRow.item then
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
  end
  for _,row in ipairs(rows) do if flags[row.item]~=nil then row.cheated=flags[row.item] end end
  drawRows()
  return cleared,true,snap
end
clearFlagButton.OnClick=function()
  local ok,err=pcall(function()
    local row=rows[listbox.ItemIndex+1]
    assert(row,'Select an item first.')
    flagTypes={}
    local count,complete=clearItemFlags(row)
    assert(complete,'Inventory changed during the check. Refresh and retry.')
    status.Caption=count>0 and 'Selected item flag cleared. Flag column now shows -.' or 'Selected item flag was already clear.'
  end)
  if not ok then showMessage('Valheim item flags: '..tostring(err)) end
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
    keepFlagsButton.Caption='Keep item flags off: ON'
    status.Caption='Clearing flags in your inventory every 0.5 seconds, including newly crafted/upgraded items.'
  end)
  if not ok then stopItemFlags(); showMessage('Valheim item flags: '..tostring(err)) end
end
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
local helperHex='4d5a90000300000004000000ffff0000b800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000e1fba0e00b409cd21b8014ccd21546869732070726f6772616d2063616e6e6f742062652072756e20696e20444f53206d6f64652e0d0d0a2400000000000000504500004c010300c7d8c66a0000000000000000e00002210b010b00003800000006000000000000ee56000000200000006000000000001000200000000200000400000000000000040000000000000000a000000002000000000000030040850000100000100000000010000010000000000000100000000000000000000000945600005700000000600000c802000000000000000000000000000000000000008000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002e74657874000000f4360000002000000038000000020000000000000000000000000000200000602e72737263000000c80200000060000000040000003a0000000000000000000000000000400000402e72656c6f6300000c0000000080000000020000003e00000000000000000000000000004000004200000000000000000000000000000000d0560000000000004800000002000500a4370000f01e00000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867e0600000414280300000a2c127e0600000402146f0400000aa5150000012a162a4e0280030000041480020000041780010000042a361680010000041480030000042aae7e0100000417332102280500000a2c19027e03000004280600000a2c0c027e0700000a280600000a2a162a52022c0f027b0800000a7b0900000a1afe012a162a000000033003004d00000000000000168001000004026f0a00000a6f0b00000a7201000070026f0c00000a280d00000a80020000047e020000046f0e00000a209001000031157e020000041620900100006f0f00000a80020000042a0000001b300300c7000000010000110228040000062c080328050000062d02162a7e0500000414281000000a2c0b7207000070731100000a7a7e050000040222000080bf8c1d0000016f1200000a7e04000004280500000a2c127e040000047b0a00000402281300000a2c3c7e04000004280500000a2c0f7e040000046f1400000a281500000a723b000070731600000a0a066f0100002b80040000047e04000004026f090000067e04000004036f0f000006de1f0b0728060000067e04000004280500000a2c0a7e040000046f0c000006de00172a00011000000000120094a6001f08000001ded01f000001281800000a726f0000701f346f1900000a8005000004d003000001281800000a72910000701f34281a00000a80060000042a13300900680800000200001102037d0a00000402036f0200002b7d1d00000472a5000070281c00000a252d192672e9000070281c00000a252d0b26721b010070281c00000a0a06280500000a2d0b723b010070731d00000a7a0206731e00000a7d0c000004027b0c000004727b0100701b6f1f00000a027b0c000004728f010070176f1f00000a027b0c00000472a3010070166f1f00000a027b0c00000420b80b00006f2000000a0272b3010070731600000a7d0b000004027b0b0000046f2100000a02282200000a166f2300000a020272cb010070229a99194022cdcc4c3d226666e63e2200004040228fc2f53d732400000a1f41280a0000067d12000004020272ed010070226666863f22cdcc4c3e2200004040220000a04022cdcc0c3f732400000a1f41280a0000067d1300000402027205020070227b14ae3e2200008040220000a040220000c040220000803f732400000a1f41280a0000067d140000040202722302007022ec51b83d229a99993e2200004040220000a04022cdcc4c3f732400000a1f60280a0000067d1500000402027241020070228fc2753d2200004040220000a040220000c040220000403f732400000a1f60280a0000067d160000040202725f02007022cdcccc3d22cdcccc3d2200004040220000a040229a99593f732400000a1f41280a0000067d170000040202727f02007022cdcc4c3d2200004040220000a040220000c040226666663f732400000a1f41280a0000067d180000040202729f020070220ad7233e22cdcc4c3e2200008040220000c04022cdcc4c3f732400000a1f41280a0000067d19000004198d0c0000011314111416027b17000004a2111417027b18000004a2111418027b19000004a211141315161316389f000000111511169a0b076f2500000a0c071a8d2500000113171117168f2500000122000000002200000000732600000a81250000011117178f2500000122cdcc4c3e220000803f732600000a81250000011117188f25000001223333333f223333333f732600000a81250000011117198f25000001220000803f2200000000732600000a81250000011117732700000a6f2800000a07086f2900000a111617581316111611158e693f56ffffff160d38da000000027b0f000004090272b7020070098c27000001282a00000a220ad7233d09195d6b22cdcccc3c5a58220000803e22cdcc4c3f229a99993f22295c8f3e732400000a1f18280a000006a2027b0f000004099a198d2500000113181118168f2500000122000000002200000000732600000a81250000011118178f25000001223333b33e220000803f732600000a81250000011118188f25000001220000803f2200000000732600000a81250000011118732700000a6f2800000a027b0f000004099a220ad7233d09195d6b22cdcccc3c5a586f2900000a0917580d09027b0f0000048e693f18ffffff021f201f201a16732b00000a7d0e00000420000400008d10000001130416130538810000001613062b7011066b22000078415922000078415b130711056b22000078415922000078415b1308220000803f110711075a59110811085a59282c00000a1309110411051f205a1106588f10000001220000803f220000803f220000803f110911095a11095a732400000a811000000111061758130611061f20328a11051758130511051f203f76ffffff027b0e00000411046f2d00000a027b0e0000046f2e00000a027b0e000004176f2f00000a0206731e00000a7d0d000004027b0d000004027b0e0000046f3000000a027b0d000004727b0100701b6f1f00000a027b0d000004728f010070176f1f00000a027b0d00000472a3010070166f1f00000a72df020070731600000a130a110a6f2100000a027b0b0000046f2100000a166f2300000a02110a6f0300002b7d10000004027b1000000417166f3100000a027b100000046f3200000a130b120b17283300000a120b2068010000283400000a120b226666263f283500000a283600000a120b2200000000283500000a283700000a120b22ec51383e283500000a283800000a120b17283900000a027b100000046f3a00000a130c120c2200000000283500000a283b00000a027b100000046f3c00000a130d120d17283d00000a120d229a99993f283500000a283e00000a120d22cdcc8c3f283f00000a120d2200004040283500000a284000000a027b100000046f4100000a130e120e17284200000a734300000a130f110f188d3400000113191119168f34000001284400000a2200000000734500000a81340000011119178f34000001284400000a220000803f734500000a81340000011119198d35000001131a111a168f3500000122000000002200000000734600000a8135000001111a178f35000001220000803f228fc2f53d734600000a8135000001111a188f350000012200000000220000803f734600000a8135000001111a6f4700000a120e110f284800000a284900000a027b100000046f0400002b027b0d0000046f4a00000a7217030070731600000a131011106f2100000a027b0b0000046f2100000a166f2300000a0211106f0300002b7d1a000004027b1a00000417166f3100000a027b1a0000046f3200000a1311121117283300000a121122cdcccc3e283500000a283600000a12112200004041283500000a283700000a121122cdcc4c3e283500000a283800000a121122cdcccc3e2200004040220000a040220000803f732400000a284b00000a284c00000a121120a0000000283400000a121117283900000a027b1a0000046f3a00000a131212122200005c43283500000a283b00000a027b1a0000046f4d00000a1313121316284e00000a1213223333b33e284f00000a027b1a0000046f0400002b027b0d0000046f4a00000a02027233030070220000c040280b0000067d1b0000040202724d0300702200001041280b0000067d1c000004027b0b000004166f5000000a2a13300300800000000300001103731600000a0a066f2100000a027b0b0000046f2100000a166f2300000a066f0500002b0b07027b0c0000046f4a00000a07176f5100000a070e046f5200000a07046f5300000a070422cdcc4c3f5a6f5400000a07056f5500000a07056f5600000a071c6f5700000a07166f5800000a07166f5900000a07166f5a00000a072a133004005a0000000400001103731600000a0a066f2100000a027b0b0000046f2100000a166f2300000a066f0600002b0b0722cdcccc3d226666263f220000803f735b00000a6f5c00000a07046f5d00000a0722000040406f5e00000a07166f5f00000a072a0000033003005500000000000000027b0b000004280500000a2c0c027b0b000004166f5000000a027b220000042c2c027b1d000004280500000a2c1f027b1e000004286000000a2d12027b1d000004027b1e000004166f6100000a02167d220000042a000000033002006700000000000000027b0a00000428040000062d1202280c00000602281400000a281500000a2a286200000a027b1f00000459228fc2f53d302e286300000a2c2716286400000a2c1f027b0a00000428010000062c12027b0a0000046f6500000a28050000062d0602280c0000062a00033001004f0000000000000002280c000006027b0c000004280500000a2c0b027b0c000004281500000a027b0d000004280500000a2c0b027b0d000004281500000a027b0e000004280500000a2c0b027b0e000004281500000a2a0013300600b10800000500001102286200000a7d1f000004286300000a2c2f16286400000a2c27027b0a00000428010000062c1a027b0a0000046f6600000a2d0d027b0a0000046f6700000a2c0702280c0000062a027b220000042d4a02177d2200000402286200000a7d2000000402286200000a7d2100000402286200000a7d11000004027b0b000004176f5000000a027b1a0000046f6800000a027b100000046f6800000a02037b0800000a7b6900000a7b6a00000a7d1e000004027b1d000004280500000a2c34027b1e000004286000000a2d27027b1d000004027b1e000004176f6100000a027b1d0000047267030070220000803f6f6b00000a027b0a0000046f6c00000a286d00000a226666e63e286e00000a286f00000a0a027b0a000004066f7000000a13211221287100000a0b0607226666263f286e00000a287200000a0c220000a0420d1c8d1b0000011322112216727f030070a2112217728f030070a211221872a9030070a211221972c5030070a211221a72d1030070a211221b72e1030070a21122287300000a1304060722cd4ca142110417287400000a13231613242b5f112311248f45000001714500000113051205287500000a280500000a2c3b1205287500000a6f0700002b280500000a2d281205287700000a226666263f5909341822000000001205287700000a226666263f59287800000a0d112417581324112411238e693299092200000000350702280c0000062a080709286e00000a287200000a130607286d00000a287900000a13251225287100000a13071207287a00000a220ad7233c3407287b00000a1307110707287900000a13261226287100000a130822cdcc4c3e220000803f286200000a027b200000045922cdcc4c3e5b282c00000a287c00000a1309220000803f220ad7233e286200000a220000e8415a287d00000a5a5822ec51b83d286200000a22000086425a287d00000a5a58130a027b12000004229a99194011095a110a5a6f5300000a027b12000004027b120000046f2500000a22cdcc4c3f5a6f5400000a027b13000004226666863f11095a6f5300000a027b13000004027b130000046f2500000a22cdcc4c3f5a6f5400000a027b14000004227b14ae3e11095a6f5300000a027b14000004027b140000046f2500000a22cdcc4c3f5a6f5400000a16130b38df000000110b6b22000080425b130c1107110b6b22a470dd3f5a286200000a22000004425a59287d00000a286e00000a1108110b6b2248e10a405a286200000a22000024425a58287d00000a286e00000a287200000a110c22db0f49405a287d00000a286e00000a1109286e00000a130d081106110c287e00000a130e027b12000004110b110e110d229a99993e286e00000a287200000a6f7f00000a027b13000004110b110e110d228fc2f53d286e00000a287200000a6f7f00000a027b14000004110b110e110d22295c0f3d286e00000a287200000a6f7f00000a110b1758130b110b1f413f18ffffff16130f38e9000000110f6b220000be425b13101110095a220000c03f5a286200000a22000098415a5922cdcccc3e110f6b223333f33f5a286200000a220000c0415a58287d00000a5a58131111071111288000000a286e00000a11081111287d00000a286e00000a287200000a223333333f228fc2753e110f6b22000020405a286200000a220000f8415a59287d00000a5a58286e00000a1109286e00000a111022db0f49405a287d00000a286e00000a13120811061110287e00000a1313027b15000004110f11131112287200000a6f7f00000a027b16000004110f11131112286f00000a6f7f00000a110f1758130f110f1f603f0effffff027b170000040811071108229a99193f11095a2810000006027b18000004080722cdcc4c3e286e00000a287200000a11071108220000803f11095a2810000006027b19000004110611071108223333b33f11095a110a5a2810000006161314380b010000286200000a226666263f11146b2296438b3c5a585a11146b22ba490c3e5a58220000803f5d131516131638cd00000011166b220000b8415b131711146b229a9919405a286200000a220000e04011146b22cdcc4c3e5a585a59111722cdcc2c405a5813182200002040223333b33f11155a59229a99593f229a99193e111822000040405a11146b58287d00000a5a585a131909111522000010415a1117220000c03f5a58288100000a131a027b0f00000411149a11160807111a286e00000a287200000a11071118288000000a286e00000a11081118287d00000a286e00000a287200000a1119286e00000a287200000a6f7f00000a11161758131611161f183f2affffff1114175813141114027b0f0000048e693fe6feffff286200000a027b11000004446a01000002286200000a220ad7a33c587d1100000416131b3849010000220000000022db0fc940288200000a131c22cdcc4c3f22cdcc2c40288200000a131d1107111c288000000a286e00000a1108111c287d00000a286e00000a287200000a131e1108111c288000000a286e00000a1107111c287d00000a286e00000a286f00000a131f1220fe1549000001122008111e111d286e00000a287200000a07220000000009220000c040288100000a288200000a286e00000a287200000a288300000a1220111f220000c0402200004041288200000a286e00000a111e2200000040286e00000a286f00000a0722000000412200009041288200000a286e00000a287200000a288400000a122022cdcc0c3f288500000a1220228fc2753d228fc2753e288200000a288600000a1220229a99993e226666a63f2200000040226666263f732400000a288700000a288800000a027b100000041120176f8900000a111b1758131b111b1e3faffeffff027b1b0000042200004040110a5a6f5e00000a027b1c0000042200008040110a5a6f5e00000a027b1a0000046f2200000a11066f8a00000a027b1b0000046f2200000a086f8a00000a027b1c0000046f2200000a11066f8a00000a286200000a027b21000004371a02286200000a22cdcccc3d587d210000040208070928110000062a00000013300600bc00000006000011160a38ac000000066b22000080425b0b07229a9979405a286200000a220000e0400e0422000000405a585a580e04220000a0405a580c0e04220000803f22ec51383e066b229a99d93f5a286200000a2200000c425a58287d00000a5a5822ec51b83d066b22cdcc4c405a286200000a22000054425a59287d00000a5a585a0d0206030408288000000a286e00000a0508287d00000a286e00000a287200000a09286e00000a287200000a6f7f00000a0617580a061f413f4cffffff2a133003000c01000007000011288b00000a6f8c00000a130416130538ec000000110411059a0a06280500000a39d5000000066f8d00000a3aca000000066f6600000a3abf000000066f8e00000a3ab4000000066f8f00000a754d00000139a4000000027b0a00000406289000000a3993000000066f9100000a03286f00000a0b0704289200000a0c082200000000327608053072070408286e00000a286f00000a13061206287a00000a220bd723403055739300000a0d097c9400000a220000c8427d9500000a09066f9100000a7d9600000a09047d9700000a0922000040407d9800000a09177d9900000a09167d9a00000a09027b0a0000046f9b00000a06096f9c00000a110517581305110511048e693f09ffffff2a52021f0c8d0c0000017d0f00000402289d00000a2a00000042534a4201000100000000000c00000076342e302e33303331390000000005006c0000004c090000237e0000b8090000f80c000023537472696e677300000000b0160000f403000023555300a41a0000100000002347554944000000b41a00003c04000023426c6f620000000000000002000001571d02080908000000fa2533001600000100000051000000030000002200000012000000180000009d0000000300000002000000070000000100000001000000060000000700000000000a0001000000000006005c0055000a0086007a000e00b70000000600dd00cb000600f000cb000e00250100001b002e01000006003d0155000a007a017a000a008d017a000a00b0017a000a00c6017a001200fa017a000a005d027a000e00780200000a00c8027a000a00f8027a0006009d037d030600bd037d030600fa03cb0006000c0455000a005c007a001f003a0400001f004e04000006006204550006006f04cb0006008f0455000600b20455000600c80455000a00d8047a000e000d05000006001605550006003a05cb000a0067057a000600730555000a00a4057a000a00d5057a000a00de057a000600100655000a0016067a000a0024067a000a0042067a000a004a067a00120077067a003700970600003700c5060000120000077a0037003207000037005f0700003700ac0700000a00da077a000a00e3077a000a00fe077a00370017080000120030087a000a0047087a00370072080000120088087a000a0023097a000a0055093f090a00a8097a000a00d7097a000a00e5097a0016001d0a7a000e00430a00000e00670a00000a00e80a7a001a00140b7a001a001c0b7a001a00270b7a001a004a0b7a000a00c40b7a003700cb0b00000a00f00b7a000600180cfd0b0e00490c00000e005a0c00000e007f0c00003b01870c00000e00cb0c00004301d20c00000000000001000000000001000100810110001f002900050001000100010110003c002900090007000900160094000a0016009c000d001100be0010001100c40014003300e70018003100fb001c0051805901450051805f014500518066014500060074011000010085015700010096015b0001009f015b000100ba015f002100d301630001000902680001001002450001001e026c00010023026c0001002a026c0001002f026c00010035026c0001003b026c00010043026c0001004b026c0001005602680001006302700001006f027000010087027400010091020d0001009f0245000100a80245000100b00245000100bb027800502000000000930005012000010072200000000096000e0126000200862000000000960018012c0003009420000000009300200120000300c020000000009300370130000400d82000000000930047013600050034210000000096004d013c000600182200000000911806052c0009005022000000008600c2027b000900c42a000000008100ce0281000a00502b000000008100d3028b000e00b82b000000008600dd02920010001c2c000000008100e20292001000902c000000008100e90292001000ec2c000000008600f30296001000ac3500000000910000039c00110074360000000081000503a90016008c37000000008618140392001900000001001a03000001001a03000001001a03000001002103000001002803000001001a03000002002103000003002a03000001001a03000001002d03000002003203000003003803000004003e03000001002d03000002004403000001002103000001004a03000002004f03000003005603000004005b03000005005e03000001006503000002006c0300000300760391001403b2009900140392002900ec03b700a1000504bf00b1001404c600b1002004cc0019002c04100039004504d400b9005704d80041006704dc00d1007a04e10041008304e100d9009604e500d9009d04ec00d900a804f00021002004f600e1001403fe002100cf040301b100ec03cc00f100e2040901b100f1040e0149001403fe004900f9041401c90028052601c90047052e01c90050053701f1005a05140111016e05450119011403fe00510014034c0151008d05530151009405b2004900ae055901f100ae0559012101bc055f018100140367016100c6056f012901140373013101140379016100ed0581016100fc058801d90096048d0159001403930149012a069d0159003206a20159003c06920051015a06a90151006706b00169009206bc016900a206c4016901ab06ca016901b406b20071011404cf016901d106d6016901e306d6016901f206d60169011e07dd0169004107e40181014e07d60169006b07ea0189017507ca0189018107d60189018e07880189019c07d6016900c407f00191017507ca019901140392008100f407f601a1011403fb01a9011403730199010f080202b10114040e02910126081702c10150082402b10114042a0269016308170269007e083202c901a0083802c901ae0888014900b908ca016100c308ca016100d508b2006100e70888016100f608880161006308890261000309890261001009b200610031098f02c10167099602c1017d09ca0181001403a90271002608890271009009880171009a0988017100b509b002d900c109be027900cf09c302f101dc09c902f901f109cd020102230ad102f900320ad60209024d0adb020902540adb026900620a9200b9006e0adf021102770a0d0079008c0ae4020902950aea028900a10aef028900a80af4028900b40afc02f900c30a05038900cd0aea028900dc0afc021902f20a0c0321023f0b12032902530b2203f100600b14012902750b6f014901820b2e038900860bfc0289008c0b6f0189009d0bef024901a70b34034901ac0b9d018900a70b3b036100b00b45034901bc0b9d014901c00b2e03410259012e034902d60b4c034902e30b4c034902d10688014902f2068801510214045203490263085a036900f80b61032101d60b4c0309021f0cb1030c00300cc5030902380cdb020902410cdb020902500ccb036102640cd10309026c0cea0289007b0cdb037102140392007102930ce30379029c0c45007102a80ce8037102b00ce8037102b60c45007102c20c78007102dc0cec037102e40cf1030902f00cf8031100140392000c001c0048000c0020004d000c00240052002e000b0012042e0013001b041f013f029d02b7026903aa03ff03bc03048000000000000000000000000000000000db03000004000000000000000000000001004c000000000000000000000000000000000000006300000000000000000000000000000000000000a600000000000000000000000000000000000000d901000000000000000000000000000000000000ff09000000000000000000000000000000000000fa0a000000002f001a01370040012f00b70137001e022f0084022f00a402ed00280300000000003c4d6f64756c653e0056616c6865696d426f774265616d56322e646c6c00426f774265616d56320056616c6865696d536f6c6f546f6f6c6b697400426f774265616d56697375616c5632006d73636f726c69620053797374656d004f626a65637400556e697479456e67696e652e436f72654d6f64756c6500556e697479456e67696e65004d6f6e6f4265686176696f757200456e61626c6564004c6173744572726f7200617373656d626c795f76616c6865696d00506c61796572006f776e65720076697375616c0053797374656d2e5265666c656374696f6e004669656c64496e666f004472617754696d65004d6574686f64496e666f0054616b65496e7075740043616e496e70757400436f6e6669677572650044697361626c65004f776e73004974656d44726f70004974656d44617461004973426f7700457863657074696f6e004661756c74004f6e426f775570646174650052616e6765005261646975730044616d6167655065725469636b004f776e65720047616d654f626a6563740065666665637473004d6174657269616c006d6174657269616c007061727469636c654d6174657269616c0054657874757265324400736f667454657874757265004c696e6552656e646572657200677573747300556e697479456e67696e652e5061727469636c6553797374656d4d6f64756c65005061727469636c6553797374656d00766f72746578006e6578745061727469636c65730068616c6f0073686561746800636f726500636f696c4100636f696c42006d757a7a6c6541006d757a7a6c654200696d7061637452696e6700737061726b73004c69676874006d757a7a6c654c6967687400656e644c69676874005a53796e63416e696d6174696f6e00616e696d6174696f6e0064726177416e696d6174696f6e006c617374537465700073746172746564006e65787444616d61676500666972696e6700536574757000436f6c6f72004c696e65004d616b654c69676874004869646500557064617465004f6e44657374726f79005374657000566563746f72330052696e670044616d6167654d6f6e7374657273002e63746f7200706c6179657200776561706f6e0065006474006e616d6500776964746800636f6c6f7200636f756e740072616e6765006c696e650063656e746572007369646500757000726164697573006f726967696e00646972656374696f6e006c656e6774680053797374656d2e52756e74696d652e436f6d70696c6572536572766963657300436f6d70696c6174696f6e52656c61786174696f6e734174747269627574650052756e74696d65436f6d7061746962696c6974794174747269627574650056616c6865696d426f774265616d5632006f705f496e657175616c697479004d6574686f644261736500496e766f6b6500426f6f6c65616e006f705f496d706c69636974006f705f457175616c697479006d5f6c6f63616c506c617965720053686172656444617461006d5f736861726564004974656d54797065006d5f6974656d5479706500547970650047657454797065004d656d626572496e666f006765745f4e616d65006765745f4d65737361676500537472696e6700436f6e636174006765745f4c656e67746800537562737472696e67004d697373696e674669656c64457863657074696f6e0053696e676c650053657456616c756500436f6d706f6e656e74006765745f67616d654f626a6563740044657374726f7900416464436f6d706f6e656e74002e6363746f720048756d616e6f69640052756e74696d655479706548616e646c65004765745479706546726f6d48616e646c650042696e64696e67466c616773004765744669656c64004765744d6574686f6400476574436f6d706f6e656e74005368616465720046696e6400496e76616c69644f7065726174696f6e457863657074696f6e00536574496e74007365745f72656e6465725175657565005472616e73666f726d006765745f7472616e73666f726d00536574506172656e74006765745f73746172745769647468004b65796672616d6500416e696d6174696f6e4375727665007365745f77696474684375727665007365745f77696474684d756c7469706c69657200496e7433320054657874757265466f726d6174004d6174686600436c616d70303100536574506978656c73004170706c7900546578747572650054657874757265577261704d6f6465007365745f777261704d6f6465007365745f6d61696e54657874757265005061727469636c6553797374656d53746f704265686176696f720053746f70004d61696e4d6f64756c65006765745f6d61696e007365745f6c6f6f70007365745f6d61785061727469636c6573004d696e4d61784375727665007365745f73746172744c69666574696d65007365745f73746172745370656564007365745f737461727453697a65005061727469636c6553797374656d53696d756c6174696f6e5370616365007365745f73696d756c6174696f6e537061636500456d697373696f6e4d6f64756c65006765745f656d697373696f6e007365745f726174654f76657254696d65004e6f6973654d6f64756c65006765745f6e6f697365007365745f656e61626c6564007365745f737472656e677468007365745f6672657175656e6379007365745f7363726f6c6c537065656400436f6c6f724f7665724c69666574696d654d6f64756c65006765745f636f6c6f724f7665724c69666574696d65004772616469656e74004772616469656e74436f6c6f724b6579006765745f7768697465004772616469656e74416c7068614b6579005365744b657973004d696e4d61784772616469656e74007365745f636f6c6f72005061727469636c6553797374656d52656e64657265720052656e6465726572007365745f7368617265644d6174657269616c007365745f7374617274436f6c6f720053686170654d6f64756c65006765745f7368617065005061727469636c6553797374656d536861706554797065007365745f736861706554797065007365745f72616469757300536574416374697665007365745f757365576f726c645370616365007365745f706f736974696f6e436f756e74007365745f73746172745769647468007365745f656e645769647468007365745f656e64436f6c6f72007365745f6e756d4361705665727469636573004c696e65416c69676e6d656e74007365745f616c69676e6d656e7400556e697479456e67696e652e52656e646572696e6700536861646f7743617374696e674d6f6465007365745f736861646f7743617374696e674d6f6465007365745f72656365697665536861646f7773007365745f72616e6765007365745f696e74656e73697479004c69676874536861646f7773007365745f736861646f77730049734e756c6c4f72456d70747900536574426f6f6c0054696d65006765745f74696d65004170706c69636174696f6e006765745f6973466f637573656400556e697479456e67696e652e496e7075744c65676163794d6f64756c6500496e707574004765744d6f757365427574746f6e0047657443757272656e74576561706f6e004368617261637465720049734465616400497354656c65706f7274696e6700506c61790041747461636b006d5f61747461636b006d5f64726177416e696d6174696f6e537461746500536574466c6f617400476574457965506f696e74006765745f7570006f705f4d756c7469706c79006f705f5375627472616374696f6e0047657441696d446972006765745f6e6f726d616c697a6564006f705f4164646974696f6e004c617965724d61736b004765744d61736b00556e697479456e67696e652e506879736963734d6f64756c650050687973696373005261796361737448697400517565727954726967676572496e746572616374696f6e0052617963617374416c6c00436f6c6c69646572006765745f636f6c6c6964657200476574436f6d706f6e656e74496e506172656e74006765745f64697374616e6365004d61780043726f7373006765745f7371724d61676e6974756465006765745f7269676874004c6572700053696e00536574506f736974696f6e00436f73004d696e0052616e646f6d00456d6974506172616d73007365745f706f736974696f6e007365745f76656c6f6369747900436f6c6f72333200456d69740053797374656d2e436f6c6c656374696f6e732e47656e65726963004c697374603100476574416c6c4368617261637465727300546f4172726179004973506c6179657200497354616d65640042617365414900476574426173654149004d6f6e737465724149004973456e656d790047657443656e746572506f696e7400446f7400486974446174610044616d6167655479706573006d5f64616d616765006d5f6c696768746e696e67006d5f706f696e74006d5f646972006d5f70757368466f726365006d5f72616e67656400536b696c6c7300536b696c6c54797065006d5f736b696c6c0053657441747461636b65720044616d616765000000053a0020000033480075006d0061006e006f00690064002e006d005f00610074007400610063006b004400720061007700540069006d006500003353006f006c006f0054006f006f006c006b00690074005f0042006f0077004200650061006d0044007200690076006500720000216d005f00610074007400610063006b004400720061007700540069006d0065000013540061006b00650049006e0070007500740000434c0065006700610063007900200053006800610064006500720073002f005000610072007400690063006c00650073002f004100640064006900740069007600650000315000610072007400690063006c00650073002f005300740061006e006400610072006400200055006e006c0069007400001f53007000720069007400650073002f00440065006600610075006c007400003f4e006f00200063006f006d00700061007400690062006c00650020006200650061006d002000730068006100640065007200200066006f0075006e00640000135f0053007200630042006c0065006e00640000135f0044007300740042006c0065006e006400000f5f005a005700720069007400650000174200650061006d00560069007300750061006c0073000021540075007200620075006c0065006e007400200063006f0072006f006e00610000174300790061006e00200070006c00610073006d006100001d57006800690074006500200068006f007400200063006f0072006500001d45006e0065007200670079002000680065006c006900780020004100001d45006e0065007200670079002000680065006c006900780020004200001f4300680061007200670069006e0067002000720069006e00670020004100001f4300680061007200670069006e0067002000720069006e00670020004200001749006d0070006100630074002000680061006c006f00002756006f0072007400650078002000770069006e006400200072006900620062006f006e002000003753007700690072006c0069006e00670020007000720065007300730075007200650020007000610072007400690063006c0065007300001b49006d007000610063007400200073007000610072006b00730000194d0075007a007a006c00650020006c006900670068007400001949006d00700061006300740020006c00690067006800740000176400720061007700700065007200630065006e007400000f440065006600610075006c00740000197300740061007400690063005f0073006f006c0069006400001b440065006600610075006c0074005f0073006d0061006c006c00000b70006900650063006500000f7400650072007200610069006e00000f760065006800690063006c006500000000001617f1169cb48142ad9ac9c3fb0b6e280008b77a5c561934e08902060802060e0306120d0306120c030612110306121505000102120d05000101120d0300000105000102121d05000101122108000302120d121d0c02060c040000a04204cdcccc3f040000c84203061225030612290306122d04061d12310306123503061231030612390306123d02060205200101120d09200412310e0c11410806200212390e0c0320000105200101121d0c00050112311145114511450c08200301114511450c042001010807000202121512150620021c1c1d1c05000102125907000202125912590306125d0306116104200012650320000e0600030e0e0e0e032000080520020e08080700020212111211042001010e052002011c1c0420001225050001011259053001001e00040a01120c06070212251221070001126511808108200212110e11808508200212150e118085040a01123d0600011280890e06200101128089052002010e080520001280910720020112809102072004010c0c0c0c0320000c052002010c0c072001011d11809506200101128099042001010c0500020e1c1c0920040108081180a1020400010c0c062001011d1141062001011180ad062001011280a9040a01123507200201021180b10520001180b504200101020600011180b90c062001011180b9062001011180bd0520001180c10520001180c50520001180c904000011410620020111410c0b2002011d1180d11d1180d50800011180d91280cd062001011180d9050a011280dd0520010112290700011180d911410520001180e5062001011180e944071b12808912310c081d114108080c0c0c12251180b51180c11180c51180c91280cd12251180b51180c11180e51d12311d1231081d1180951d1180951d1180d11d1180d5040a011231052001011141062001011180ed062001011180f106070212251231040a011239062003010c0c0c062001011180f506070212251239040001020e052002010e020300000c030000020400010208042000121d032000020406128109052002010e0c04200011450400001145070002114511450c08000211451145114506200111451145050001081d0e0f00051d118115114511450c0811811905200012811d050a011281050500020c0c0c0600030c0c0c0c0900031145114511450c0620020108114505200101114507000111812911410620010111812907200201118125084007271145114511450c081181151145114511450c0c080c11451145080c0c11451145080c080c0c0c0c080c0c1145114511812511451d0e1d1181150811451145060704080c0c0c0a00001512812d01128105081512812d011281050520001d1300052000128131090002021281051281050700020c11451145040611813d030611450406118145062001011281050620010112813912070712810511450c1281391d1281050811450801000800000000001e01000100540216577261704e6f6e457863657074696f6e5468726f7773010000bc5600000000000000000000de560000002000000000000000000000000000000000000000000000d05600000000000000000000000000000000000000005f436f72446c6c4d61696e006d73636f7265652e646c6c0000000000ff250020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001000000018000080000000000000000000000000000001000100000030000080000000000000000000000000000001000000000048000000586000006c02000000000000000000006c0234000000560053005f00560045005200530049004f004e005f0049004e0046004f0000000000bd04effe00000100000000000000000000000000000000003f000000000000000400000002000000000000000000000000000000440000000100560061007200460069006c00650049006e0066006f00000000002400040000005400720061006e0073006c006100740069006f006e00000000000000b004cc010000010053007400720069006e006700460069006c00650049006e0066006f000000a801000001003000300030003000300034006200300000002c0002000100460069006c0065004400650073006300720069007000740069006f006e000000000020000000300008000100460069006c006500560065007200730069006f006e000000000030002e0030002e0030002e00300000004c001500010049006e007400650072006e0061006c004e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d00560032002e0064006c006c00000000002800020001004c006500670061006c0043006f0070007900720069006700680074000000200000005400150001004f0072006900670069006e0061006c00460069006c0065006e0061006d0065000000560061006c006800650069006d0042006f0077004200650061006d00560032002e0064006c006c0000000000340008000100500072006f006400750063007400560065007200730069006f006e00000030002e0030002e0030002e003000000038000800010041007300730065006d0062006c0079002000560065007200730069006f006e00000030002e0030002e0030002e003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000c000000f03600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
local state,watch,helper
local function loadHelper()
  if helper and helper.pid==session then return helper end
  local class=mono_findClass('ValheimSoloToolkit','BowBeamV2')
  if not class or class==0 then
    local folder=os.getenv('TEMP') or os.getenv('TMP')
    assert(folder and folder~='','Windows temporary directory unavailable')
    local path=folder..'\\ValheimSoloToolkit_BowBeamV2_'..tostring(session)..'_'..tostring(os.time())..'.dll'
    local binary=helperHex:gsub('%x%x',function(v) return string.char(tonumber(v,16)) end)
    local file=assert(io.open(path,'wb'),'Cannot write embedded helper to the temporary directory')
    local written,err=file:write(binary);file:close()
    assert(written,'Cannot write bow-beam helper: '..tostring(err))
    local assembly=mono_loadAssemblyFromFile(path)
    os.remove(path) -- Windows/Mono may retain the temporary file until game exit.
    assembly=pointer(assembly,'Explosive-fists helper assembly')
    class=pointer(mono_image_findClass(mono_getImageFromAssembly(assembly),'ValheimSoloToolkit','BowBeamV2'),'Explosive-fists helper class')
  end
  helper={pid=session,class=class,
    configure=matchingMethod(class,'Configure',{18},1),
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
  beamButton.Caption='Bow beam: OFF'
end
ValheimBowBeamStop=stopBeam
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() stopBeam();return close() end
form.OnDestroy=function() stopBeam();destroy() end
beamButton.OnClick=function()
  local ok,err=pcall(function()
    if state then stopBeam();playerStatus.Caption='Bow beam disabled.';return end
    local s=playerContext()
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
          playerStatus.Caption='Bow beam stopped: '..tostring(failure)
            ..(stopped and '' or ('; cleanup: '..tostring(stopError)))
        end
      end
    end
    watch.Enabled=true;beamButton.Caption='Bow beam: ON'
    playerStatus.Caption='Equip a bow and hold Mouse 1: continuous cyan beam, 80m reach, 100 lightning damage per 0.1s. Release to stop. Replaces arrows; hostile monsters only. Visuals are local.'
  end)
  if not ok then
    local stopped,stopError=pcall(stopBeam)
    showMessage('Valheim bow beam: '..tostring(err)..(stopped and '' or (' Cleanup: '..tostring(stopError))))
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
