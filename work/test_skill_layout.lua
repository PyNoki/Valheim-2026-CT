local file=assert(io.open('outputs/ValheimBeta.lua'));local source=file:read('*a');file:close()
local pairStart=assert(source:find('      local function pair(a,b,row)',1,true))
local pairEnd=assert(source:find('\n      if group==playerGroup then',pairStart,true))
local pairCode=source:sub(pairStart,pairEnd-1)
local start=assert(source:find('        pair(maxSkills,customSkills,1)',pairEnd,true))
local finish=assert(source:find('\n      end\n    end\n    footer',start,true))
local code=pairCode..'\n'..source:sub(start,finish-1)
local height=assert(source:match('local skillsH=([^\n]+)'))
for _,width in ipairs({350,416,536,726})do
 local env={cw=width,gap=10,buttonH=28,line=16,group={}}
 env.size=math.floor((width-24-env.gap)/2)
 for _,name in ipairs({'maxSkills','customSkills','speedButton','jumpButton','resetMovementButton','enemyButton','rapidButton','boatButton','minerButton','trophyButton','skillStatus'})do env[name]={}end
 setmetatable(env,{__index=_G})
 env.place=function(c,p,x,y,w,h)c.Parent=p;c.Left=x;c.Top=y;c.Width=w;c.Height=h end
 assert(load(code,'packaged skills rows','t',env))()
 local a,b=env.minerButton,env.trophyButton
 assert(a.Top==b.Top and a.Top==10+4*(env.buttonH+6),'Fast attacks and Trophy buffs must share row five')
 assert(a.Left+a.Width+env.gap==b.Left and b.Left+b.Width<=width-12,'Fifth row must have a gap and fit the panel')
 assert(a.Width>=140 and b.Width>=140,'Shared-row labels need readable button widths')
 assert(env.skillStatus.Top>=a.Top+a.Height+6,'Status must sit below both buttons')
 local total=assert(load('return '..height,'skills height','t',env))()
 assert(env.skillStatus.Top+env.skillStatus.Height<=total-26,'Skills status must fit client height')
end
print('PASS: packaged Fast attacks/Trophy buffs share row five without overlap or clipped status at four panel widths')
