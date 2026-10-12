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
  spawnChoice=createComboBox(tamingWindow);spawnChoice.Left=16;spawnChoice.Top=168;spawnChoice.Width=470;spawnChoice.Style='csDropDownList'
  local spawn=createButton(tamingWindow);spawn.Left=505;spawn.Top=168;spawn.Width=272;spawn.Height=30;spawn.Caption='Spawn selected tameable'
  spawn.OnClick=function()
    local ok,err=pcall(function()
      local name=spawnNames[4][spawnChoice.ItemIndex+1];assert(name,'Refresh the spawn list, unpause Valheim, then select a creature.')
      helper=queueSpawnAction(3,name,'taming');timer.Enabled=true;tamingWindow.show()
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
