-- Native Windows buttons ignore custom fills. Keep their handlers and state,
-- and present a colored panel that forwards clicks to the original control.
do
local entries={}
local function update(entry)
  local b,p,frame=entry.button,entry.panel,entry.frame
  local caption=b.Caption or ''
  local on=entry.toggle and (caption:match(': ON$')~=nil or caption:match('^Unfreeze')~=nil) or false
  if b==speedButton or b==jumpButton then
    local multiplier=tonumber(caption:match(': ([%d%.]+)x$'))
    on=multiplier~=nil and multiplier~=1
  end
  frame.Parent=b.Parent;frame.Left=b.Left;frame.Top=b.Top;frame.Width=b.Width;frame.Height=b.Height
  local border=entry.warning and 0 or 1
  p.Left=border;p.Top=border;p.Width=b.Width-border*2;p.Height=b.Height-border*2
  p.Enabled=b.Enabled~=false
  p.Color=on and 0x32852E or 0x373737
  p.Font.Color=on and 0xFFFFFF or 0xE6E6E6
  p.Caption=caption:gsub(': ON$',''):gsub(': OFF$','')
  p.Hint=b.Hint or '';p.ShowHint=true;p.ParentShowHint=false
  b.Visible=false
end
styleToggle=function(b,toggle)
  if not b then return end
  for _,entry in ipairs(entries) do if entry.button==b then return end end
  if toggle==nil then toggle=(b.Caption or ''):match(': O[NF]+$')~=nil end
  local warning=b==godButton or b==flightButton or b==craftingButton
  local frame=createPanel(b.Parent);frame.Caption='';frame.BevelOuter='bvNone';frame.ParentColor=false;frame.Color=0x666666
  local p=createPanel(frame);p.BevelOuter='bvNone';p.ParentColor=false
  p.Cursor=-21;p.TabStop=true
  local entry={button=b,panel=p,frame=frame,toggle=toggle,warning=warning};entries[#entries+1]=entry
  p.OnClick=function() if b.OnClick then b.OnClick() end;update(entry) end
  p.OnKeyDown=function(sender,key) if key==13 or key==32 then p.OnClick() end end
  update(entry)
end
for _,b in ipairs({godButton,staminaButton,craftingButton,flightButton,beamButton,carryButton,
  deleteButton,enemyButton,keepFlagsButton,rapidButton,freezeReplenishButton,freeze,speedButton,jumpButton,boatButton}) do styleToggle(b,true) end
for _,b in ipairs({edit,cloneButton,refresh,maxStacksButton,dragButton,spawnButton,maxSkills,customSkills,
  resetMovementButton,teleportButton}) do styleToggle(b,false) end
local function updateAll() for _,entry in ipairs(entries) do update(entry) end end
local resize,show=form.OnResize,form.OnShow
form.OnResize=function(...) if resize then resize(...) end;updateAll() end
form.OnShow=function(...) if show then show(...) end;updateAll() end
local poll=createTimer(form,false);poll.Interval=150;poll.OnTimer=updateAll;poll.Enabled=true
local close,destroy=form.OnClose,form.OnDestroy
form.OnClose=function() local result=close();updateAll();return result end
form.OnDestroy=function() poll.Enabled=false;destroy() end
end
