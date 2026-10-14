local errors, methodCalls, assemblies = {}, {}, {}
local helperClass = 91
session = 42
form = {OnClose=function() return 1 end, OnDestroy=function() end}
depositButton = {Caption='Auto refill: OFF'}
function initialize() session=42 end
function snapshot() end
function pointer(value, name) assert(value and value ~= 0, name..' unavailable');return value end
function loadRecovery() return {pid=session,class=helperClass} end
function mono_findClass(namespace, name)
  assert(namespace=='', 'Replenish must not search for a versioned helper')
  return name=='Inventory' and 2 or name=='Humanoid' and 3 or nil
end
function matchingMethod(class, name, parameters, result)
  if name=='PrepareTransfer' or name=='PreparedCopy' or name=='DropReplenished' then
    assert(class==helperClass, 'Wrong loaded helper class')
    methodCalls[#methodCalls+1]={class=class,name=name}
  end
  return 0x1000+#methodCalls*0x100
end
function mono_compile_method(method) return method end
function getInstructionSize() return 7 end
function readBytes(address, count, asTable)
  assert(asTable)
  local result={};for i=1,count do result[i]=0x90 end;return result
end
function autoAssemble(script, targetSelf, info)
  assemblies[#assemblies+1]={script=script,info=info}
  return true, {installed=true}
end
function getOpenedProcessID() return session end
function getProcessIDFromProcessName() return session end
function showMessage(error) errors[#errors+1]=error end
dofile('outputs/ValheimReplenish.lua')
depositButton.OnClick()
assert(#errors==0 and depositButton.Caption=='Auto refill: ON')
assert(#methodCalls==3 and #assemblies==1)
depositButton.OnClick()
assert(#errors==0 and depositButton.Caption=='Auto refill: OFF')
assert(#assemblies==2 and assemblies[2].info)
helperClass=97
depositButton.OnClick()
assert(#errors==0 and depositButton.Caption=='Auto refill: ON')
assert(#methodCalls==6 and methodCalls[4].class==97)
form.OnClose()
assert(depositButton.Caption=='Auto refill: OFF')
helperClass=nil
local before=#assemblies
depositButton.OnClick()
assert(#errors==1 and errors[1]:find('Replenish helper unavailable',1,true))
assert(#assemblies==before and depositButton.Caption=='Auto refill: OFF')
print('PASS: loaded helper class, helper upgrades, replenish enable/disable, close cleanup, missing-helper guard')
