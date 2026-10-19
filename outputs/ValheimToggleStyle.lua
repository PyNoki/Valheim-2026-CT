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
for _,b in ipairs({staminaButton,craftingButton,flightButton,beamButton,carryButton,
  deleteButton,enemyButton,keepFlagsButton,rapidButton,freezeReplenishButton,freeze,speedButton,jumpButton,boatButton,sortingButton,minerButton}) do styleToggle(b,true) end
for _,b in ipairs({edit,cloneButton,maxItemQualityButton,refresh,maxStacksButton,dragButton,spawnButton,tamingButton,trophyButton,maxSkills,customSkills,
  resetMovementButton,teleportButton}) do styleToggle(b,false) end
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
