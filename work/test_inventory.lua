local buttons, box, errors, writes = {}, nil, {}, 0
local timer
local timers={}
function createTimer() local t={Enabled=false}; timers[#timers+1]=t; timer=timer or t; return t end
function createForm() return {Font={},Constraints={},show=function() end, hide=function() end, destroy=function() end} end
function createButton() local b={}; buttons[#buttons+1]=b; return b end
local labels,helpMemo={},nil
function createLabel() local l={Font={}};labels[#labels+1]=l;return l end
function createMemo() helpMemo={Font={},Lines={}};return helpMemo end
function createGroupBox() return {Font={}} end
function createPanel() local p={Font={}};buttons[#buttons+1]=p;return p end
local checkboxes,edits={},{}
function createCheckBox() local c={Font={},Checked=false,destroy=function() end};checkboxes[#checkboxes+1]=c;return c end
function createEdit() local e={Font={}};edits[#edits+1]=e;return e end
function createListBox()
  local values={}
  local control={Font={},ItemIndex=-1}
  control.Items={clear=function() values={}; control.ItemIndex=-1 end,add=function(v) values[#values+1]=v end}
  control.values=function() return values end
  box=control
  return box
end
function showMessage(e) errors[#errors+1]=e end
local detectedPID=0
function getProcessIDFromProcessName() return detectedPID end
function getOpenedProcessID() return 42 end
function targetIs64Bit() return true end
function LaunchMonoDataCollector() return 1 end
local classes={Player=1,Humanoid=2,Inventory=3}
function mono_findClass(_,name) return classes[name] end
local function f(name,off) return {name=name,offset=off} end
local defs={
  [1]={{name='m_localPlayer',offset=0x30,isStatic=true,staticAddress=0x1030,field=77}},
  [2]={f('m_inventory',0x5a0)},[3]={f('m_inventory',0x28)},
  [4]={f('_size',0x18),f('_version',0x1c),f('_items',0x10)},
  [5]={f('m_stack',0x38),f('m_shared',0x10)},
  [6]={f('m_name',0x10),f('m_maxStackSize',0x18)}
}
function mono_class_enumFields(c) return defs[c] end
function mono_object_getClass(p) return ({[0x4000]=4,[0x6000]=5,[0x9000]=5,[0x7000]=6})[p] end
local mem={
 [0x4000]=0x4444,[0x6000]=0x6666,
 [0x1030]=0x2000,[0x25a0]=0x3000,[0x3028]=0x4000,
 [0x4018]=1,[0x401c]=3,[0x4010]=0x5000,[0x5018]=4,[0x5020]=0x6000,
 [0x6010]=0x7000,[0x6038]=23,[0x7010]=0x8000,[0x7018]=50,[0x8010]=10
}
function readPointer(p) return mem[p] end
readInteger=readPointer; readQword=readPointer
function readString() return '$item_wood' end
function writeInteger(p,v) mem[p]=v; writes=writes+1; return true end
function inputQuery() return '24' end
dofile('outputs/ValheimInventory.lua')
assert(timers[4].Enabled and #errors==0,'Missing game should retry quietly')
detectedPID=42
local savedPlayer=mem[0x1030];mem[0x1030]=0
timers[4].OnTimer()
assert(timers[4].Enabled and #errors==0,'Unloaded world should retry quietly')
mem[0x1030]=savedPlayer
timers[4].OnTimer()
assert(not timers[4].Enabled and #box.values()==1,'Automatic inventory load did not finish')
box.ItemIndex=0;timers[4].OnTimer()
assert(box.ItemIndex==0 and not timers[4].Enabled,'Successful startup must stop refreshing')
print('PASS: quiet startup retries for missing game/world, successful load and stop-after-success')
do
  for i=1,28 do assert(buttons[i].ShowHint and #buttons[i].Hint>20,'Missing action tooltip '..i) end
  for _,label in ipairs(labels) do if label.Caption=='? Help & tips' then label.OnClick();break end end
  assert(helpMemo and helpMemo.ReadOnly and helpMemo.Lines.Text:find('BOTTOM LEFT',1,true),'Help popout missing')
  assert(helpMemo.Lines.Text:find('cheated',1,true) and helpMemo.Lines.Text:find('ping',1,true),'Help content missing')
  ValheimHelpStop()
  assert(buttons[1].Color==0x32852E and buttons[1].Font.Color==0xFFFFFF,'Refresh action must stand out in green/white')
  assert(not ValheimInventoryWindow.AutoScroll,'Outer scrollbar must be disabled')
  for _,label in ipairs(labels) do assert(label.Caption~='[ Compact ]','Presets must be removed') end
  for _,size in ipairs({{960,740},{1120,800},{1500,900}}) do
    ValheimInventoryWindow.Width=size[1];ValheimInventoryWindow.Height=size[2]
    ValheimInventoryWindow.OnResize()
    assert(ValheimInventoryWindow.Width==size[1] and ValheimInventoryWindow.Height==size[2],'Resize must not force the frame larger')
    assert(box.Height>=24,'Inventory list collapsed')
    for _,label in ipairs(labels) do
      if label==nil then error('Missing label') end
      if label.Caption and label.Caption:find('GOD MODE:',1,true)==1 then
        assert(label.Top+label.Height<label.Parent.Height,'God warning clipped')
      end
    end
  end
  print('PASS: compact resize layout without presets or outer scrolling, tooltips and help')
end
buttons[1].OnClick()
assert(#errors==0 and #box.values()==1, 'Refresh failed')
box.ItemIndex=0
buttons[2].OnClick()
assert(#errors==0 and writes==1 and mem[0x6038]==24, 'Edit failed')
assert(box.ItemIndex==0, 'Editing lost selection')
function inputQuery() mem[0x6038]=25; return '26' end
buttons[2].OnClick()
assert(#errors==1 and writes==1 and mem[0x6038]==25, 'Stale quantity must block write')
mem[0x1030]=0
buttons[1].OnClick()
assert(#errors==2 and errors[2]:find('static storage 1030'), 'Null player diagnostic missing')
mem[0x1030]=0x2000
buttons[1].OnClick()
box.ItemIndex=0
buttons[3].OnClick()
assert(timer.Enabled, 'Freeze did not enable')
mem[0x6038]=20
timer.OnTimer()
assert(mem[0x6038]==25 and writes==2, 'Freeze did not restore quantity')
buttons[4].OnClick()
assert(not timer.Enabled, 'Unfreeze failed')
buttons[3].OnClick()
mem[0x401c]=4
mem[0x4018]=2; mem[0x5020]=0x9000; mem[0x5028]=0x6000; mem[0x6038]=12
timer.OnTimer()
assert(timer.Enabled and writes==3 and mem[0x6038]==25, 'Split/reordering must preserve original freeze')
mem[0x401c]=5; mem[0x4018]=1; mem[0x5020]=0x9000
timer.OnTimer()
assert(not timer.Enabled and writes==3, 'Removing original must stop freeze')
mem[0x5020]=0x6000
buttons[1].OnClick(); buttons[3].OnClick()
mem[0x6038]=0
timer.OnTimer()
assert(not timer.Enabled and writes==3, 'Depleted stack must stop freeze')
mem[0x6038]=25
buttons[1].OnClick(); buttons[3].OnClick()
ValheimInventoryWindow.OnClose()
assert(not timer.Enabled, 'Closing window must stop freeze')
print('PASS: freeze restore, unfreeze, inventory mutation, depletion, close cleanup')
buttons[1].OnClick()
function inputQuery() return '50' end
buttons[2].OnClick()
assert(mem[0x6038]==50, 'Exact normal limit rejected')
function inputQuery() return '500' end
buttons[2].OnClick()
assert(mem[0x6038]==500, 'Overstack edit rejected')
buttons[3].OnClick()
assert(timer.Enabled, 'Overstack freeze rejected')
mem[0x6038]=499; timer.OnTimer()
assert(mem[0x6038]==500, 'Overstack freeze failed')
buttons[4].OnClick()
local before=writes
function inputQuery() return '2147483648' end
buttons[2].OnClick()
assert(writes==before and mem[0x6038]==500, '32-bit overflow must be rejected')
print('PASS: exact normal limit, overstack edit/freeze, overflow rejection')
mem[0x9000]=0x6666; mem[0x9010]=0x7000; mem[0x9038]=12
mem[0x4018]=2; mem[0x5028]=0x9000; mem[0x401c]=6
buttons[5].OnClick()
assert(timer.Enabled and #box.values()==2, 'Freeze entire inventory failed')
assert(box.values()[1]:sub(2,2)=='X' and box.values()[2]:sub(2,2)=='X', 'Missing X indicators')
mem[0x6038]=400; mem[0x9038]=5; timer.OnTimer()
assert(mem[0x6038]==500 and mem[0x9038]==12, 'Both stacks must freeze')
buttons[1].OnClick()
assert(timer.Enabled and box.values()[1]:sub(2,2)=='X', 'Refresh lost freezes')
box.ItemIndex=0; buttons[6].OnClick()
assert(box.values()[1]:sub(2,2)==' ' and box.values()[2]:sub(2,2)=='X', 'Unfreeze selected indicator failed')
mem[0x6038]=400; mem[0x9038]=5; timer.OnTimer()
assert(mem[0x6038]==400 and mem[0x9038]==12, 'Unfreeze selected affected wrong stack')
box.ItemIndex=0; buttons[3].OnClick()
mem[0x4018]=1; mem[0x401c]=7; mem[0x5020]=0x9000; mem[0x9038]=5
timer.OnTimer()
assert(timer.Enabled and mem[0x9038]==12, 'Removing one stack stopped others')
assert(box.values()[1]:sub(2,2)==' ' and box.values()[2]:sub(2,2)=='X', 'Removed stack X not cleared')
buttons[4].OnClick()
assert(not timer.Enabled and box.values()[2]:sub(2,2)==' ', 'Unfreeze all failed')
print('PASS: freeze all, X indicators, refresh retention, selective unfreeze, per-item removal')
print('PASS: static player reference, inventory refresh, edit, stale-item rejection, null-player diagnostic')
defs[1][#defs[1]+1]=f('m_skills',0x758)
defs[7]={f('m_skillData',0x28)}
defs[8]={f('_entries',0x18),f('_count',0x40),f('_freeCount',0x48),f('_version',0x4c)}
defs[9]={f('hashCode',0x10),f('next',0x14),f('key',0x18),f('value',0x20)}
defs[10]={f('m_info',0x10),f('m_level',0x18),f('m_accumulator',0x1c)}
defs[11]={f('m_skill',0x20)}
local originalClass=mono_object_getClass
function mono_object_getClass(p)
  return ({[0xa000]=7,[0xb000]=8,[0xc000]=12,[0xd000]=10,[0xd100]=10,[0xe000]=11,[0xe100]=11})[p] or originalClass(p)
end
function mono_class_getArrayElementClass(c) assert(c==12); return 9 end
mem[0x2758]=0xa000; mem[0xa028]=0xb000; mem[0xb018]=0xc000
mem[0xb040]=3; mem[0xb048]=1; mem[0xb04c]=1; mem[0xc018]=4
mem[0xc020]=1; mem[0xc028]=1; mem[0xc030]=0xd000
mem[0xc038]=0xffffffff -- deleted dictionary entry
mem[0xc050]=2; mem[0xc058]=2; mem[0xc060]=0xd100
mem[0xd010]=0xe000; mem[0xd110]=0xe100; mem[0xe020]=1; mem[0xe120]=2
mem[0xd018]=14; mem[0xd01c]=0.5; mem[0xd118]=0; mem[0xd11c]=0
function readFloat(p) return mem[p] end
function writeFloat(p,v) mem[p]=v; return true end
buttons[1].OnClick() -- rebuild metadata cache
buttons[7].OnClick()
assert(mem[0xd018]==100 and mem[0xd118]==100 and mem[0xd01c]==0, 'Max skills failed, including zero skill')
classes['Skills+SkillType']=99
defs[99]={{name='Swords',isStatic=true,isConst=true,field=1},{name='Knives',isStatic=true,isConst=true,field=2}}
function mono_class_getStaticFieldValue(c,f) assert(c==99);return f end
buttons[8].OnClick()
assert(#checkboxes==3 and checkboxes[2].Caption:find('Knives',1,true),'Named skill list missing')
edits[1].Text='250'
local before=#errors;buttons[29].OnClick()
assert(#errors==before+1 and mem[0xd018]==100,'Empty selection wrote levels')
mem[0xd01c]=0.75
checkboxes[2].Checked=true -- Knives only, alphabetically first.
buttons[29].OnClick()
assert(mem[0xd018]==100 and mem[0xd01c]==0.75 and mem[0xd118]==250,'Individual selection changed unchecked skill/progress')
checkboxes[1].Checked=true;checkboxes[1].OnChange()
buttons[29].OnClick()
assert(mem[0xd018]==250 and mem[0xd118]==250,'Select all failed')
edits[1].Text='not a level';before=#errors;buttons[29].OnClick()
assert(#errors==before+1 and mem[0xd018]==250,'Invalid level accepted')
edits[1].Text='300';mem[0x1030]=0;before=#errors;buttons[29].OnClick()
assert(#errors==before+1 and mem[0xd018]==250,'Missing player accepted')
mem[0x1030]=0x3000;mem[0x3758]=0xa000;before=#errors;buttons[29].OnClick()
assert(#errors==before+1 and mem[0xd018]==250,'Stale player selection accepted')
mem[0x1030]=0x2000
print('PASS: named skill picker, selected-only writes, select all, empty/invalid input and missing-player rejection')
local fail=true
function writeFloat(p,v)
  if p==0xd118 and fail then fail=false; return false end
  mem[p]=v; return true
end
buttons[7].OnClick()
assert(mem[0xd018]==250 and mem[0xd118]==250, 'Partial skill failure must restore old values')
print('PASS: max skills including level zero, free dictionary entry, overlevel, write failure rollback')
defs[1][#defs[1]+1]={name='m_godMode',offset=0x800,typename='System.Boolean'}
defs[1][#defs[1]+1]={name='m_stamina',offset=0x804,typename='System.Single'}
defs[1][#defs[1]+1]={name='m_maxStamina',offset=0x808,typename='System.Single'}
mem[0x2000]=0x2222; mem[0x2800]=0; mem[0x2804]=20; mem[0x2808]=100
function readBytes(p,n,asTable)
  if asTable then local b={}; for i=1,n do b[i]=0x90 end; return b end
  return mem[p]
end
function writeBytes(p,v) mem[p]=v; return true end
classes.Character=13
function mono_class_findMethod(c,name) assert((c==13 and name=='ApplyDamage') or (c==1 and name=='ConsumeResources')); return 77 end
function mono_method_get_parameters() return {returntype=1} end
function mono_compile_method() return 0xf000 end
function getInstructionSize() return 1 end
local hookActive=false
function autoAssemble(script,self,disable)
  assert(script:find('cmp rcx,rax',1,true) and script:find('cmp [rax],rcx',1,true), 'Hook lacks local player guards')
  assert(script:find('db FF 25 00 00 00 00',1,true), 'Hook must use reserved 14-byte jump')
  if disable then hookActive=false; return true end
  hookActive=true; return true,{}
end
buttons[1].OnClick()
buttons[9].OnClick()
assert(mem[0x2800]==1 and buttons[9].Caption=='God mode: ON','God mode activation failed')
assert(hookActive,'Damage block was not installed')
buttons[10].OnClick()
assert(mem[0x2804]==100 and timers[2].Enabled,'Stamina activation failed')
mem[0x2804]=5; mem[0x2808]=150; timers[2].OnTimer()
assert(mem[0x2804]==150,'Stamina must follow changing maximum')
buttons[9].OnClick()
assert(mem[0x2800]==0 and timers[2].Enabled,'God disable must restore flag and preserve stamina')
assert(not hookActive,'Damage block was not removed')
buttons[10].OnClick()
assert(not timers[2].Enabled,'Player timer must stop when toggles off')
mem[0x2800]=1; buttons[9].OnClick(); buttons[9].OnClick()
assert(mem[0x2800]==1,'Preexisting god mode must be preserved')
mem[0x2800]=0; buttons[9].OnClick(); buttons[10].OnClick()
ValheimInventoryWindow.OnClose()
assert(mem[0x2800]==0 and not timers[2].Enabled,'Close must restore god flag and stop timer')
buttons[9].OnClick(); buttons[10].OnClick()
mem[0x1030]=0; mem[0x2804]=7; timers[2].OnTimer()
assert(mem[0x2804]==7 and not timers[2].Enabled,'World unload must stop writes')
print('PASS: god/stamina enable/disable, dynamic maximum, prior flag, close cleanup, world unload')
mem[0x1030]=0x2000
defs[3][#defs[3]+1]=f('m_width',0x30); defs[3][#defs[3]+1]=f('m_height',0x34)
defs[5][#defs[5]+1]=f('m_gridPos',0x58)
defs[5][#defs[5]+1]={name='m_equipped',offset=0x60,typename='System.Boolean'}
mem[0x3030]=2; mem[0x3034]=1; mem[0x9058]=0; mem[0x905c]=0; mem[0x9060]=1
mem[0x9038]=500
local savedClass=mono_object_getClass
function mono_object_getClass(p) if p==0x3000 then return 3 end; if p==0xa100 or p==0xa200 then return 5 end; return savedClass(p) end
local savedParams=mono_method_get_parameters
function mono_class_enumMethods(c)
 if c==5 then return {{name='Clone',method=88}} end
 if c==3 then return {{name='AddItem',method=89}} end
 return {}
end
function mono_method_get_parameters(m)
 if m==88 then return {parameters={},returntype=18} end
 if m==89 then return {parameters={{type=18},{type=8},{type=8},{type=8},{type=2}},returntype=2} end
 return savedParams(m)
end
local invokes=0
function mono_invoke_method(domain,m,obj,args)
 invokes=invokes+1
 if m==88 then
  assert(obj==0x9000)
  mem[0xa110]=mem[0x9010]; mem[0xa138]=mem[0x9038]; mem[0xa160]=mem[0x9060]
  return 0xa100
 end
 assert(m==89 and obj==0x3000 and args[1]==0xa100 and args[2]==500 and args[3]==1 and args[4]==0 and args[5]==0)
 assert(mem[0xa160]==0,'Clone equipped flag not cleared')
 mem[0xa210]=mem[0xa110]; mem[0xa238]=args[2]; mem[0xa258]=args[3]; mem[0xa25c]=args[4]
 mem[0x5028]=0xa200; mem[0x4018]=2; mem[0x401c]=mem[0x401c]+1
 return 1
end
buttons[1].OnClick(); box.ItemIndex=0
local cloneErrors=#errors
buttons[11].OnClick()
assert(#errors==cloneErrors and mem[0xa238]==500 and mem[0x9038]==500,'Clone must preserve full overstack and source')
assert(box.ItemIndex==1 and box.values()[2]:sub(2,2)==' ','Copy should be selected and unfrozen')
buttons[11].OnClick()
assert(invokes==2 and #errors==cloneErrors,'Full inventory must not invoke clone/add')
print('PASS: clone uses explicit empty slot, preserves source/overstack, clears equipped flag, selects unfrozen copy, full inventory')
mem[0xa200]=0x6666; buttons[12].OnClick()
assert(mem[0x9038]==50 and mem[0xa238]==50,'Max all must normalize both overstacks')
buttons[5].OnClick()
mem[0x9038]=10; mem[0xa238]=5
timers[1].OnTimer()
assert(mem[0x9038]==50 and mem[0xa238]==50,'Frozen targets must match max stack limit')
classes.InventoryGui=14; classes.Container=15; classes['ItemDrop+ItemData']=5
defs[14]={{name='m_instance',offset=0,isStatic=true,staticAddress=0xf100},f('m_currentContainer',0x20)}
defs[15]={f('m_inventory',0x28)}
local oldMethods=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==3 then return {{name='AddItem',method=89},{name='MoveItemToThis',method=90}} end
 return oldMethods(c)
end
local oldParameters=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==90 then return {parameters={{type=18},{type=18}},returntype=1} end
 return oldParameters(m)
end
function mono_compile_method(m) return m==88 and 0xf500 or 0xf000 end
local oldAssemble=autoAssemble
local refillActive=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhRefill,',1,true) then
  assert(script:find('cmp rdx,rax',1,true) and script:find('cmp rcx,rax',1,true),'Missing source/chest guard')
  assert(script:find('mov rcx,r8',1,true) and script:find('mov r8,rax',1,true),'Clone must replace transferred item')
  assert(script:find('sub rsp,48',1,true) and script:find('mov [rsp+28],rdx',1,true),'Call frame must preserve source')
  refillActive=not disable; return true,{}
 end
 return oldAssemble(script,self,disable)
end
buttons[13].OnClick()
assert(refillActive and buttons[13].Caption=='Auto refill: ON','Refill toggle did not enable')
buttons[13].OnClick()
assert(not refillActive and buttons[13].Caption=='Auto refill: OFF','Refill toggle did not disable')
buttons[13].OnClick(); ValheimInventoryWindow.OnClose()
assert(not refillActive,'Close must remove refill hook')
print('PASS: normalize stacks/freeze targets; refill hook guards, argument replacement, toggle and cleanup')
defs[1][#defs[1]+1]={name='m_noPlacementCost',offset=0x80c,typename='System.Boolean'}
local costActive,costFail=false,false
local beforeCostAssemble=autoAssemble
function autoAssemble(script,self,disable)
  if script:find('vhCraftCostGuard',1,true) then
    assert(script:find('cmp rcx,rax',1,true) and script:find('cmp [rax],rcx',1,true),'Cost guard must target current local player')
    assert(script:find('cmp byte ptr [rax],1',1,true),'Cost guard must check no-cost flag')
    assert(not script:find('dealloc(',1,true),'Do not free an in-flight cost trampoline')
    if costFail and not disable then return false,'simulated install failure' end
    costActive=not disable;return true,{}
  end
  return beforeCostAssemble(script,self,disable)
end
mem[0x280c]=0
buttons[1].OnClick()
buttons[14].OnClick()
assert(costActive and mem[0x280c]==1 and buttons[14].Caption=='Free crafting: ON','Free crafting enable failed')
mem[0x280c]=0; timers[2].OnTimer()
assert(mem[0x280c]==1,'Free crafting flag must remain on')
buttons[14].OnClick()
assert(not costActive and mem[0x280c]==0 and buttons[14].Caption=='Free crafting: OFF','Free crafting disable must restore prior value')
mem[0x280c]=1; buttons[14].OnClick(); buttons[14].OnClick()
assert(mem[0x280c]==1,'Preexisting no-cost setting must be preserved')
mem[0x280c]=0; buttons[14].OnClick(); ValheimInventoryWindow.OnClose()
assert(not costActive and mem[0x280c]==0 and not timers[2].Enabled,'Close must restore free crafting')
buttons[14].OnClick(); mem[0x1030]=0; mem[0x280c]=0; timers[2].OnTimer()
assert(not costActive and mem[0x280c]==0 and buttons[14].Caption=='Free crafting: OFF','World unload must stop no-cost writes')
mem[0x1030]=0x2000;costFail=true
buttons[14].OnClick()
assert(not costActive and mem[0x280c]==0,'Failed cost guard must leave free crafting off')
costFail=false
print('PASS: free crafting on/off, maintain flag, preserve previous setting, close cleanup and world unload')
mem[0x1030]=0x2000
defs[5][#defs[5]+1]={name='m_cheated',offset=0x64,typename='System.Boolean'}
mem[0x9064]=1; mem[0xa264]=1
buttons[1].OnClick(); box.ItemIndex=0
assert(box.values()[1]:find('Y',1,true),'Flag indicator missing')
buttons[15].OnClick()
assert(mem[0x9064]==0 and mem[0xa264]==1,'Selected clear affected wrong items')
buttons[16].OnClick()
assert(mem[0xa264]==0 and timers[3].Enabled,'Automatic flag clearing failed')
mem[0xa264]=1; timers[3].OnTimer()
assert(mem[0xa264]==0,'In-place upgrade reflag was not cleared')
local flagClass=mono_object_getClass
function mono_object_getClass(p) if p==0xa300 then return 5 end; return flagClass(p) end
mem[0xa300]=0x6666; mem[0xa310]=0x7000; mem[0xa338]=1; mem[0xa364]=1
mem[0x5030]=0xa300; mem[0x4018]=3; mem[0x401c]=mem[0x401c]+1
timers[3].OnTimer()
assert(mem[0xa364]==0 and #box.values()==3,'Newly crafted item not cleared or displayed')
buttons[16].OnClick()
assert(not timers[3].Enabled and mem[0xa364]==0,'Disabling should preserve cleared flags')
buttons[16].OnClick(); mem[0x1030]=0; mem[0xa364]=1; timers[3].OnTimer()
assert(not timers[3].Enabled and mem[0xa364]==1,'World unload must stop item flag writes')
mem[0x1030]=0x2000; buttons[16].OnClick(); ValheimInventoryWindow.OnClose()
assert(not timers[3].Enabled,'Window close must stop flag timer')
print('PASS: flag display, selected-only clearing, repeated upgrade flags, new crafted items, disable and cleanup')
local movementNames={'m_speed','m_walkSpeed','m_runSpeed','m_crouchSpeed','m_swimSpeed','m_jumpForce'}
local movementDefaults={4,2,7,2,2,10}
for i,name in ipairs(movementNames) do
 local offset=0x820+(i-1)*4
 defs[1][#defs[1]+1]={name=name,offset=offset,typename='System.Single'}
 mem[0x2000+offset]=movementDefaults[i]
end
buttons[1].OnClick()
function inputQuery() return '2' end
buttons[17].OnClick(); buttons[17].OnClick()
assert(mem[0x2820]==8 and mem[0x2828]==14,'Speed must scale original values without compounding')
function inputQuery() return '3' end
buttons[18].OnClick()
assert(mem[0x2834]==30,'Jump multiplier failed')
function inputQuery() return '1' end
buttons[17].OnClick()
assert(mem[0x2820]==4 and mem[0x2834]==30,'Speed reset must preserve jump')
buttons[19].OnClick()
for i,v in ipairs(movementDefaults) do assert(mem[0x2820+(i-1)*4]==v,'Reset failed') end
function inputQuery() return '999' end
buttons[17].OnClick(); buttons[18].OnClick()
assert(mem[0x2820]==4 and mem[0x2834]==10,'Invalid multiplier changed values')
local movementWrite=writeFloat
local movementFail=true
function writeFloat(p,v)
 if p==0x2824 and movementFail then movementFail=false; return false end
 return movementWrite(p,v)
end
function inputQuery() return '2' end
buttons[17].OnClick()
assert(mem[0x2820]==4 and mem[0x2824]==2,'Failed speed update must roll back')
buttons[17].OnClick(); buttons[18].OnClick(); ValheimInventoryWindow.OnClose()
assert(mem[0x2820]==4 and mem[0x2834]==10,'Close must restore movement')
buttons[17].OnClick(); mem[0x1030]=0; buttons[19].OnClick()
assert(mem[0x2820]==8,'Reset after world unload must not write stale player')
mem[0x1030]=0x2000
print('PASS: movement/jump multipliers, no compounding, independent changes, reset, limits, rollback, close and stale-player guard')
do
local base=0x20000
classes.ZNet=20;classes.Minimap=23
defs[20]={{name='m_world',offset=0,isStatic=true,staticAddress=base}}
defs[21]={{name='m_uid',offset=0x10,typename='System.Int64'}}
defs[22]={f('m_zdo',0x10)}
defs[23]={{name='s_instance',offset=0,isStatic=true,staticAddress=base+8},f('m_pins',0x10)}
defs[24]={{name='m_position',offset=0x10,typename='UnityEngine.Vector3'}}
defs[25]={{name='m_pos',offset=0x10,typename='UnityEngine.Vector3'},f('m_name',0x20),f('m_type',0x28)}
defs[1][#defs[1]+1]=f('m_nview',0x900)
defs[1][#defs[1]+1]={name='m_teleporting',offset=0x908,typename='System.Boolean'}
defs[1][#defs[1]+1]={name='m_teleportCooldown',offset=0x90c,typename='System.Single'}
mem[base]=0x21000;mem[base+8]=0x24000
mem[0x2900]=0x22000;mem[0x2908]=0;mem[0x290c]=5
mem[0x22010]=0x23000;mem[0x23010]=10;mem[0x23014]=20;mem[0x23018]=30
mem[0x24010]=0x25000;mem[0x25010]=0x26000;mem[0x25018]=1;mem[0x2501c]=1
mem[0x26018]=4;mem[0x26020]=0x27000
mem[0x27010]=100;mem[0x27014]=0;mem[0x27018]=300;mem[0x27020]=0x28000;mem[0x28010]=4
local oldClass=mono_object_getClass
function mono_object_getClass(p)
 return ({[0x21000]=21,[0x22000]=22,[0x23000]=24,[0x24000]=23,[0x25000]=4,[0x27000]=25})[p] or oldClass(p)
end
local bytesBefore=readBytes
local worldID=1
function readBytes(p,n,t)
 if p==0x21010 then return {worldID,0,0,0,0,0,0,0} end
 return bytesBefore(p,n,t)
end
local stringBefore=readString
function readString(p,...) if p==0x28014 then return 'Home' end;return stringBefore(p,...) end
local store={}
function getSettings() return store end
function writeQword(p,v) mem[p]=v;return true end
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==1 then return {{name='UpdateTeleport',method=101},{name='TeleportTo',method=102}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==101 then return {returntype=1,parameters={{type=12}}} end
 if m==102 then return {returntype=2,parameters={{type=17},{type=17},{type=2}}} end
 return paramsBefore(m)
end
local assembleBefore=autoAssemble
local active=false
local buffer=0x30000
function autoAssemble(script,self,disable)
 if script:find('alloc(vhTeleportCode,',1,true) then
  assert(script:find('movdqu [rsp+70],xmm1',1,true),'Must preserve dt argument')
  assert(script:find('cmp [r11+8],rcx',1,true) and script:find('cmp [rax],rcx',1,true),'Missing local-player guard')
  assert(script:find('lea rdx,[r11+20]',1,true) and script:find('lea r8,[r11+30]',1,true),'Struct argument ABI')
  assert(not script:find('dealloc(',1,true),'Retired hook must remain valid for in-flight calls')
  active=not disable
  if active then buffer=buffer+0x1000;mem[buffer]=0 end
  return true,{}
 end
 return assembleBefore(script,self,disable)
end
function getAddressSafe() return buffer end
buttons[1].OnClick()
buttons[20].OnClick()
assert(#box.values()==1 and box.values()[1]:find('Home',1,true),'Map pin missing: '..tostring(errors[#errors]))
mem[0x27028]=12;buttons[31].OnClick()
assert(box.values()[1]:find('Ping',1,true),'Ping destination not labeled')
mem[0x27028]=10;buttons[31].OnClick()
assert(#box.values()==0,'Player map pin bypassed roster filtering')
mem[0x27028]=0;buttons[31].OnClick()
for i=30,36 do assert(buttons[i].ShowHint and #buttons[i].Hint>20,'Missing teleport tooltip') end
print('PASS: ping labels, player-pin filtering and teleport hints')

function inputQuery() return 'My base' end
buttons[32].OnClick()
assert(#box.values()==2 and store.world_0100000000000000:find('10|20|30',1,true),'Current-position save failed')
buttons[31].OnClick()
assert(#box.values()==2,'Saved location did not persist across refresh')
box.ItemIndex=1;buttons[33].OnClick()
assert(active and mem[buffer]==1 and mem[buffer+8]==0x2000,'Teleport not queued: '..tostring(errors[#errors]))
assert(mem[buffer+0x20]==100 and mem[buffer+0x28]==300 and mem[buffer+0x3c]==1,'Wrong position or quaternion')
local beforeErrors=#errors
buttons[33].OnClick();assert(#errors==beforeErrors+1,'Must reject concurrent requests')
mem[buffer]=3;mem[0x2908]=1;timers[5].OnTimer()
assert(timers[5].Enabled,'Must wait for terrain loading')
mem[0x23010]=100;mem[0x23018]=300;mem[0x2908]=0;timers[5].OnTimer()
assert(not timers[5].Enabled,'Arrival did not finish request')
buttons[33].OnClick();buttons[36].OnClick()
assert(not active and not timers[5].Enabled,'Cancel must retire hook and stop polling')
buttons[33].OnClick();mem[buffer]=4;timers[5].OnTimer()
assert(not timers[5].Enabled,'Declined teleport must finish request')
function inputQuery() return 'invalid 2 3' end
local previous=mem[buffer];buttons[34].OnClick();assert(mem[buffer]==previous,'Invalid coordinates published')
function inputQuery() return '-50 35 80' end
buttons[34].OnClick();assert(mem[buffer]==1 and mem[buffer+0x20]==-50,'Coordinate request failed')
worldID=2;timers[5].OnTimer()
assert(not timers[5].Enabled and mem[buffer+8]==0,'World change must cancel pending request')
buttons[31].OnClick();assert(#box.values()==1,'Saved locations leaked between worlds')
worldID=1;buttons[31].OnClick();assert(#box.values()==2,'Original world locations missing')
box.ItemIndex=0;buttons[35].OnClick();assert(#box.values()==1 and store.world_0100000000000000=='','Delete saved location failed')
box.ItemIndex=0;buttons[33].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and not timers[5].Enabled,'Main window close must stop teleport tools')
print('PASS: pins, persistent per-world saves/deletion, coordinates, request lifecycle, duplicate guard, cancellation and world-change cleanup')
classes.ZDOID=28
defs[20][#defs[20]+1]={name='m_instance',offset=0,isStatic=true,staticAddress=0x40000}
defs[20][#defs[20]+1]=f('m_players',0x10)
defs[20][#defs[20]+1]={name='m_characterID',offset=0x18,typename='ZDOID'}
defs[27]={{name='m_name',offset=16,typename='System.String'},
 {name='m_characterID',offset=24,typename='ZDOID'},
 {name='m_publicPosition',offset=32,typename='System.Boolean'},
 {name='m_position',offset=36,typename='UnityEngine.Vector3'}}
defs[28]={{name='<UserKey>k__BackingField',offset=16,typename='System.UInt16'},
 {name='<ID>k__BackingField',offset=20,typename='System.UInt32'}}
mem[0x40000]=0x41000;mem[0x41010]=0x42000
mem[0x42010]=0x43000;mem[0x42018]=3;mem[0x4201c]=1;mem[0x43018]=4
local playerClassBefore=mono_object_getClass
function mono_object_getClass(p)
 if p==0x42000 then return 4 elseif p==0x43000 then return 26 end
 return playerClassBefore(p)
end
function mono_class_getArrayElementClass(c) assert(c==26);return 27 end
function mono_class_isValueType(c) return c==27 end
function mono_array_element_size(c) assert(c==26);return 64 end
local rosterBytesBefore=readBytes
local ids={[0x41018]=1,[0x43028]=1,[0x43068]=2,[0x430a8]=3}
function readBytes(p,n,t)
 if t then
  if ids[p] then return {1,0} end
  if ids[p-4] then return {ids[p-4],0,0,0} end
 end
 return rosterBytesBefore(p,n,t)
end
for i=0,2 do
 local e=0x43020+i*64
 mem[e]=0x28000;mem[e+16]=i<2 and 1 or 0
 mem[e+20]=500+i*100;mem[e+24]=40;mem[e+28]=700
end
buttons[1].OnClick();buttons[20].OnClick()
assert(#box.values()==2 and box.values()[2]:find('Player',1,true),'Shared player missing or self/private player included')
box.ItemIndex=1;mem[0x43074]=900
buttons[33].OnClick()
assert(mem[buffer+0x20]==903 and mem[buffer+0x24]==41,'Player teleport did not reread latest position with offset')
buttons[36].OnClick()
mem[0x43070]=0
local errorCount=#errors;buttons[33].OnClick()
assert(#errors==errorCount+1 and not active,'Hidden player must not reuse stale position')
mem[0x43070]=1;ids[0x43068]=4
errorCount=#errors;buttons[33].OnClick()
assert(#errors==errorCount+1 and not active,'Same-name replacement player must not match old character ID')
buttons[37].OnClick();assert(#box.values()==2,'Refresh players failed')
mem[0x42018]=0;buttons[37].OnClick()
assert(#box.values()==1,'Disconnected player was not removed')
print('PASS: shared players, self/private filtering, fresh position, offset, character-ID matching, hidden/disconnected rejection')
end
defs[1][#defs[1]+1]={name='m_debugFly',offset=0x910,typename='System.Boolean'}
mem[0x2910]=0
buttons[1].OnClick();buttons[21].OnClick()
assert(mem[0x2910]==1 and buttons[21].Caption=='Flight: ON' and timers[2].Enabled,'Flight did not enable')
mem[0x2910]=0;timers[2].OnTimer()
assert(mem[0x2910]==1,'Flight did not maintain its flag')
buttons[21].OnClick()
assert(mem[0x2910]==0 and buttons[21].Caption=='Flight: OFF' and not timers[2].Enabled,'Flight did not restore original setting')
mem[0x2910]=1;buttons[21].OnClick();buttons[21].OnClick()
assert(mem[0x2910]==1,'Preexisting flight setting must be preserved')
mem[0x2910]=0;buttons[21].OnClick();ValheimInventoryWindow.OnClose()
assert(mem[0x2910]==0 and not timers[2].Enabled,'Close must restore flight')
buttons[21].OnClick();mem[0x1030]=0;mem[0x2910]=0;timers[2].OnTimer()
assert(mem[0x2910]==0 and buttons[21].Caption=='Flight: OFF','World unload must stop flight without stale writes')
mem[0x1030]=0x2000
local flightWrite=writeBytes
local failFlightOnce=true
function writeBytes(p,v)
 if p==0x2910 and failFlightOnce then failFlightOnce=false;return false end
 return flightWrite(p,v)
end
buttons[21].OnClick()
assert(mem[0x2910]==0 and buttons[21].Caption=='Flight: OFF','Failed flight enable must roll back')
print('PASS: flight enable/disable, maintain flag, preserve prior setting, close cleanup, world unload and failed write')
do
classes.BowBeamV5=30;vtDword=2
local beamChoice="1"
function inputQuery() return beamChoice end
defs[30]={{name='Enabled',offset=0,isStatic=true,staticAddress=0x60000,typename='System.Int32'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==30 then return {{name='Configure',method=201},{name='Disable',method=202},{name='OnBowUpdate',method=203}} end
 if c==1 then return {{name='UpdateAttackBowDraw',method=204}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==201 then return {returntype=1,parameters={{type=18},{type=8}}} end
 if m==202 then return {returntype=1,parameters={}} end
 if m==203 then return {returntype=2,parameters={{type=18},{type=18},{type=12}}} end
 if m==204 then return {returntype=1,parameters={{type=18},{type=12}}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
function mono_invoke_method(d,m,obj,args)
 if m==201 then assert(args[1].value==0x2000,'Wrong beam owner');assert(args[2].value==tonumber(beamChoice)-1,'Wrong beam mode');mem[0x60000]=1;return nil end
 if m==202 then mem[0x60000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhBowBeam,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Missing local-player guard')
  assert(script:find('mov [rsp+30],rdx',1,true) and script:find('mov rdx,[rsp+30]',1,true),'Must preserve original hit argument')
  assert(not script:find('dealloc(',1,true),'In-flight callback memory must remain valid')
  assert(script:find('jne vhBowBeamReturn',1,true),'Must suppress original bow draw only when helper consumes input')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[22].OnClick()
local beamTimer=timers[#timers]
assert(active and mem[0x60000]==1 and buttons[22].Caption=='Kameha: ON','BowBeam toggle failed: '..tostring(errors[#errors]))
buttons[22].OnClick();assert(not active and mem[0x60000]==0 and not beamTimer.Enabled,'Toggle disable did not clean up')
for choice=3,4 do beamChoice=tostring(choice);buttons[22].OnClick();assert(active and buttons[22].Caption==(choice==3 and 'Spirit Bomb: ON' or 'Supernova: ON'),'Bomb selection failed');buttons[22].OnClick();assert(not active,'Bomb mode cleanup failed') end
beamChoice='5';buttons[22].OnClick();assert(not active,'Invalid DBZ power enabled')
beamChoice=nil;buttons[22].OnClick();assert(not active,'Cancelled DBZ power enabled')
beamChoice='2';buttons[22].OnClick();assert(buttons[22].Caption=='Death beam: ON','Death beam selection failed');mem[0x1030]=0;beamTimer.OnTimer()
assert(not active and mem[0x60000]==0,'World unload must disable callbacks and remove hook')
mem[0x1030]=0x2000;buttons[22].OnClick();mem[0x60000]=0;beamTimer.OnTimer()
assert(not active and buttons[22].Caption=='DBZ Powers: OFF','Helper fault must remove hook')
buttons[22].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and mem[0x60000]==0 and not beamTimer.Enabled,'Closing toolkit must remove beam effect')
print('PASS: beam toggle, hook guards, original argument preservation, disable, world unload, callback fault and close cleanup')
end
do
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==1 then return {{name='IsEncumbered',method=301}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==301 then return {returntype=2,parameters={}} end
 return paramsBefore(m)
end
local assembleBefore=autoAssemble
local carryActive=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhCarryLimit,',1,true) then
  assert(script:find('cmp rcx,rax',1,true) and script:find('cmp [rax],rcx',1,true),'Carry hook needs current-player guards')
  assert(script:find('xor eax,eax',1,true) and not script:find('7F800000',1,true),'Carry hook must return false without changing displayed capacity')
  carryActive=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[23].OnClick()
local carryTimer=timers[#timers]
assert(carryActive and buttons[23].Caption=='Unlimited carry: ON','Carry toggle failed: '..tostring(errors[#errors]))
buttons[23].OnClick();assert(not carryActive and not carryTimer.Enabled,'Carry toggle did not restore normal behavior')
buttons[23].OnClick();mem[0x1030]=0;carryTimer.OnTimer()
assert(not carryActive and buttons[23].Caption=='Unlimited carry: OFF','World unload must remove carry hook')
mem[0x1030]=0x2000;buttons[23].OnClick();ValheimInventoryWindow.OnClose()
assert(not carryActive and not carryTimer.Enabled,'Close must remove carry hook')
print('PASS: unlimited carry local-player guards, encumbrance bypass, toggle, world unload and cleanup')
end
do
classes.InventoryDeleteV1=40
defs[40]={{name='Enabled',offset=0,isStatic=true,staticAddress=0x70000,typename='System.Int32'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==40 then return {{name='Configure',method=401},{name='Disable',method=402},{name='Tick',method=403}} end
 if c==14 then return {{name='Update',method=404}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==401 or m==403 then return {returntype=1,parameters={{type=18}}} end
 if m==402 or m==404 then return {returntype=1,parameters={}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
function mono_invoke_method(d,m,obj,args)
 if m==401 then assert(args[1].value==0x2000);mem[0x70000]=1;return nil end
 if m==402 then mem[0x70000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhDelete,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Delete UI hook must check local player')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[24].OnClick();local deleteTimer=timers[#timers]
assert(active and buttons[24].Caption=='Inventory delete: ON','Delete UI enable failed: '..tostring(errors[#errors]))
buttons[24].OnClick();assert(not active and mem[0x70000]==0 and not deleteTimer.Enabled,'Delete UI disable failed')
buttons[24].OnClick();mem[0x1030]=0;deleteTimer.OnTimer()
assert(not active and mem[0x70000]==0,'World unload did not disable deletion UI')
mem[0x1030]=0x2000;buttons[24].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and not deleteTimer.Enabled,'Close did not stop deletion UI')
print('PASS: deletion UI toggle, local-player guard, world unload and cleanup')
end

do
classes.RapidMinerV1=40
defs[40]={{name='Enabled',offset=0,isStatic=true,staticAddress=0x70000,typename='System.Int32'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==40 then return {{name='Configure',method=401},{name='Disable',method=402},{name='Tick',method=403}} end
 if c==1 then return {{name='Update',method=404}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==401 or m==403 then return {returntype=1,parameters={{type=18}}} end
 if m==402 or m==404 then return {returntype=1,parameters={}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
function mono_invoke_method(d,m,obj,args)
 if m==401 then assert(args[1].value==0x2000);mem[0x70000]=1;return nil end
 if m==402 then mem[0x70000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhRapidMiner,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Rapid miner hook must check local player')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[25].OnClick();local deleteTimer=timers[#timers]
assert(active and buttons[25].Caption=='Rapid miner: ON','Rapid miner enable failed: '..tostring(errors[#errors]))
buttons[25].OnClick();assert(not active and mem[0x70000]==0 and not deleteTimer.Enabled,'Rapid miner disable failed')
buttons[25].OnClick();mem[0x1030]=0;deleteTimer.OnTimer()
assert(not active and mem[0x70000]==0,'World unload did not disable rapid miner')
mem[0x1030]=0x2000;buttons[25].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and not deleteTimer.Enabled,'Close did not stop rapid miner')
print('PASS: rapid miner toggle, local-player guard, world unload and cleanup')
end

do
classes.RapidHoeV1=41
defs[41]={{name='Enabled',offset=0,isStatic=true,staticAddress=0x80000,typename='System.Int32'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==41 then return {{name='Configure',method=501},{name='Disable',method=502},{name='Tick',method=503}} end
 if c==1 then local entries=methodsBefore(c);entries[#entries+1]={name='UpdatePlacement',method=504};return entries end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==503 then return {returntype=1,parameters={{type=18},{type=2},{type=12}}} end
 if m==504 then return {returntype=1,parameters={{type=2},{type=12}}} end
 if m==501 then return {returntype=1,parameters={{type=18}}} end
 if m==502 or m==504 then return {returntype=1,parameters={}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
function mono_invoke_method(d,m,obj,args)
 if m==501 then assert(args[1].value==0x2000);mem[0x80000]=1;return nil end
 if m==502 then mem[0x80000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhRapidHoe,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Rapid hoe hook must check local player')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[26].OnClick();local deleteTimer=timers[#timers]
assert(active and buttons[26].Caption=='Rapid hoe: ON','Rapid hoe enable failed: '..tostring(errors[#errors]))
buttons[26].OnClick();assert(not active and mem[0x80000]==0 and not deleteTimer.Enabled,'Rapid hoe disable failed')
buttons[26].OnClick();mem[0x1030]=0;deleteTimer.OnTimer()
assert(not active and mem[0x80000]==0,'World unload did not disable rapid hoe')
mem[0x1030]=0x2000;buttons[26].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and not deleteTimer.Enabled,'Close did not stop rapid hoe')
buttons[25].OnClick();buttons[26].OnClick()
assert(buttons[25].Caption=='Rapid miner: ON' and buttons[26].Caption=='Rapid hoe: ON','Both tool toggles must enable together')
buttons[26].OnClick()
assert(buttons[25].Caption=='Rapid miner: ON' and mem[0x70000]==1,'Disabling hoe disturbed miner')
buttons[26].OnClick();buttons[25].OnClick()
assert(buttons[26].Caption=='Rapid hoe: ON' and active and mem[0x80000]==1,'Disabling miner disturbed hoe')
ValheimInventoryWindow.OnClose()
assert(not active and mem[0x70000]==0 and mem[0x80000]==0,'Combined cleanup failed')
print('PASS: rapid hoe toggle, local-player guard, world unload, independent miner/hoe toggles and cleanup')
end

do
classes.EnemyFormV6=42;classes.GameCamera=43;vtDword=2
mem[0x90008]=0xa0000;mem[0xa0010]=10
defs[42]={{name='Enabled',offset=0,isStatic=true,staticAddress=0x90000,typename='System.Int32'},{name='Status',offset=8,isStatic=true,staticAddress=0x90008,typename='System.String'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==42 then return {{name='Configure',method=601},{name='Disable',method=602},{name='Tick',method=603}} end
 if c==43 then return {{name='LateUpdate',method=604}} end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==601 then return {returntype=1,parameters={{type=18},{type=8}}} end
 if m==603 then return {returntype=1,parameters={{type=18}}} end
 if m==602 or m==604 then return {returntype=1,parameters={}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
local selected
function mono_invoke_method(d,m,obj,args)
 if m==601 then assert(args[1].value==0x2000);selected=args[2].value;mem[0x90000]=1;return nil end
 if m==602 then mem[0x90000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhEnemyForm,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Enemy form must validate local-player storage')
  assert(script:find('mov [rsp+28],rcx',1,true) and script:find('mov rcx,[rsp+28]',1,true),'Camera instance must survive the callback')
  assert(not script:find('dealloc(',1,true),'Do not free in-flight camera hook memory')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
function inputQuery() return nil end
buttons[27].OnClick();assert(not active and not selected,'Cancel enabled transformation')
function inputQuery() return '27' end
buttons[27].OnClick();assert(not active and not selected,'Invalid form enabled transformation')
function inputQuery() return '26' end
buttons[27].OnClick();local morphTimer=timers[#timers]
assert(active and selected==25 and buttons[27].Caption=='Enemy form: ON','Enemy form toggle failed: '..tostring(errors[#errors]))
morphTimer.OnTimer();assert(active,'Status polling failed')
buttons[27].OnClick();assert(not active and mem[0x90000]==0 and not morphTimer.Enabled,'Toggle did not request restoration/remove hook')
buttons[27].OnClick();mem[0x90000]=0;morphTimer.OnTimer();assert(not active and buttons[27].Caption=='Enemy form: OFF','F8/death/fault did not retire hook')
buttons[27].OnClick();mem[0x1030]=0;morphTimer.OnTimer();assert(not active and mem[0x90000]==0,'World unload did not disable form')
mem[0x1030]=0x2000;buttons[27].OnClick();ValheimInventoryWindow.OnClose();assert(not active and mem[0x90000]==0,'Closing did not stop transformation')
print('PASS: enemy selection/cancel/bounds, camera hook guard/argument preservation, status, return/death/fault/world unload and close')
end

do
classes.DragBuildV2=44
defs[44]={{name='Enabled',offset=0,isStatic=true,staticAddress=0xb0000,typename='System.Int32'},{name='Status',offset=8,isStatic=true,staticAddress=0xb0008,typename='System.String'}}
local methodsBefore=mono_class_enumMethods
function mono_class_enumMethods(c)
 if c==44 then return {{name='Configure',method=701},{name='Disable',method=702},{name='Tick',method=703}} end
 if c==1 then local entries={};for _,m in ipairs(methodsBefore(c)) do if m.name~='UpdatePlacement' then entries[#entries+1]=m end end;entries[#entries+1]={name='UpdatePlacement',method=704};return entries end
 return methodsBefore(c)
end
local paramsBefore=mono_method_get_parameters
function mono_method_get_parameters(m)
 if m==703 then return {returntype=2,parameters={{type=18},{type=2},{type=12}}} end
 if m==704 then return {returntype=1,parameters={{type=2},{type=12}}} end
 if m==701 then return {returntype=1,parameters={{type=18}}} end
 if m==702 or m==704 then return {returntype=1,parameters={}} end
 return paramsBefore(m)
end
local invokeBefore=mono_invoke_method
function mono_invoke_method(d,m,obj,args)
 if m==701 then assert(args[1].value==0x2000);mem[0xb0000]=1;return nil end
 if m==702 then mem[0xb0000]=0;return nil end
 return invokeBefore(d,m,obj,args)
end
local assembleBefore=autoAssemble
local active=false
function autoAssemble(script,self,disable)
 if script:find('alloc(vhDragBuild,',1,true) then
  assert(script:find('cmp [rax],r11',1,true),'Drag build hook must check local player')
  assert(script:find('mov [rsp+C0],al',1,true) and script:find('je vhDragBuildOriginal',1,true),'Drag must consume native input only when callback requests it')
  active=not disable;return true,{}
 end
 return assembleBefore(script,self,disable)
end
buttons[28].OnClick();local deleteTimer=timers[#timers]
assert(active and buttons[28].Caption=='Drag build: ON','Drag build enable failed: '..tostring(errors[#errors]))
buttons[28].OnClick();assert(not active and mem[0xb0000]==0 and not deleteTimer.Enabled,'Drag build disable failed')
buttons[28].OnClick();mem[0x1030]=0;deleteTimer.OnTimer()
assert(not active and mem[0xb0000]==0,'World unload did not disable drag build')
mem[0x1030]=0x2000;buttons[28].OnClick();ValheimInventoryWindow.OnClose()
assert(not active and not deleteTimer.Enabled,'Close did not stop drag build')
buttons[25].OnClick();buttons[28].OnClick()
assert(buttons[25].Caption=='Rapid miner: ON' and buttons[28].Caption=='Drag build: ON','Both tool toggles must enable together')
buttons[28].OnClick()
assert(buttons[25].Caption=='Rapid miner: ON' and mem[0x70000]==1,'Disabling hoe disturbed miner')
buttons[28].OnClick();buttons[25].OnClick()
assert(buttons[28].Caption=='Drag build: ON' and active and mem[0xb0000]==1,'Disabling miner disturbed hoe')
ValheimInventoryWindow.OnClose()
assert(not active and mem[0x70000]==0 and mem[0xb0000]==0,'Combined cleanup failed')
buttons[26].OnClick();buttons[28].OnClick();assert(buttons[26].Caption=='Rapid hoe: OFF' and active,'Drag did not retire hoe hook')
buttons[26].OnClick();assert(not active and buttons[28].Caption=='Drag build: OFF','Hoe did not retire drag hook');ValheimInventoryWindow.OnClose()
print('PASS: drag build toggle, local-player guard, world unload, independent miner/hoe toggles and cleanup')
end
