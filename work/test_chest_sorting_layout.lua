local file=assert(io.open('outputs/ValheimBeta.lua'));local source=file:read('*a');file:close()
-- Execute the actual packaged row layout, including the fifth Building button.
local start=assert(source:find('    local labelW=98',1,true))
local finish=assert(source:find('    local headerY=',start,true))
local layout=source:sub(start,finish-1)..'\nreturn groups'
for _,width in ipairs({800,916,1076,1456})do
 local env={iw=width,gap=10,line=16,buttonH=28,inventoryGroup={Width=width},actionLabels={{},{},{}}}
 setmetatable(env,{__index=_G})
 for _,name in ipairs({'edit','cloneButton','maxItemQualityButton','freeze','refresh','maxStacksButton','freezeReplenishButton','keepFlagsButton','lootMagnetButton','dragButton','spawnButton','tamingButton','planterButton','sortingButton'})do env[name]={}end
 env.place=function(control,parent,x,y,w,h)control.Parent=parent;control.Left=x;control.Top=y;control.Width=w;control.Height=h end
 local groups=assert(load(layout,'packaged chest sorting layout','t',env))()
 assert(#groups[3]==5 and groups[3][5]==env.sortingButton,'Chest sorting must be the fifth Building action')
 for _,row in ipairs(groups)do
  local previousRight=0
  for _,button in ipairs(row)do
   assert(button.Width>=100,'Action label too narrow')
   assert(button.Left>=previousRight and button.Left+button.Width<=width-12,'Action overlaps or is clipped outside inventory panel')
   previousRight=button.Left+button.Width
  end
 end
 assert(env.sortingButton.Parent==env.inventoryGroup,'Sorting button must be parented to inventory panel')
end
print('PASS: packaged five-button Building row stays visible, inside panel and without overlap at four window widths')
