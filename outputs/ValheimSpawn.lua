local spawnNames={{},{},{},{}}
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
  if text==lastSpawnCatalogue then return false end
  spawnNames={{},{},{},{}}
  for row in text:gmatch('[^\r\n]+') do
    local kind,name=row:match('^(%d+)|(.+)$');kind=tonumber(kind)
    if kind and kind>=0 and kind<=3 then local names=spawnNames[kind+1];names[#names+1]=name end
  end
  lastSpawnCatalogue=text;return true
end
local function fillSpawnDropdown(combo,kind)
  local previous=combo.Text;combo.Items.clear()
  local names=spawnNames[kind+1]
  for _,name in ipairs(names) do combo.Items.add(name) end
  combo.ItemIndex=#names>0 and 0 or -1
  for i,name in ipairs(names) do if name==previous then combo.ItemIndex=i-1;break end end
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
local helper,timer,combos
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() if timer then timer.Enabled=false end;return close() end
form.OnDestroy=function() if timer then timer.Enabled=false end;destroy() end
spawnButton.OnClick=function() action(function()
  if not window then openTeleportWindow();window.hide() end
  if spawnWindow then spawnWindow.show();return end
  spawnWindow=createForm(false);spawnWindow.Caption='Valheim | Spawn';spawnWindow.Width=800;spawnWindow.Height=435;spawnWindow.Position='poScreenCenter'
  spawnWindow.Color=0x202020;spawnWindow.Font.Color=0xE6E6E6
  local guide=createLabel(spawnWindow);guide.Left=16;guide.Top=16;guide.Width=745;guide.Height=52;guide.AutoSize=false;guide.WordWrap=true
  guide.Caption='Lists come from registered prefabs in your loaded game. Refresh the catalogue, then return to Valheim and unpause once to populate them. Creatures and merchants spawn beside you; resources spawn at your feet.'
  local starLabel=createLabel(spawnWindow);starLabel.Left=16;starLabel.Top=80;starLabel.Caption='Creature stars'
  local stars=createSpawnStars(spawnWindow,170,76,190)
  combos={}
  for kind,title in ipairs({'Monsters / creatures','Merchants','Resources / plants'}) do
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
    local ok,err=pcall(function() if readSpawnNames(helper) then for i,combo in ipairs(combos) do fillSpawnDropdown(combo,i-1) end end end)
    if not ok then timer.Enabled=false;spawnStatus.Caption=tostring(err) end
  end
  spawnWindow.OnClose=function() if pending and pending.spawn then stopTeleport() end;return caHide end
  spawnWindow.show();refresh.OnClick()
end) end
end
