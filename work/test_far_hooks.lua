local source=assert(io.open('outputs/ValheimInventory.lua')):read('*a')
local prefix=assert(source:match('^(.-)%-%- Valheim inventory editor'))
local received,calls,arguments
local env={};env._G=env;setmetatable(env,{__index=_G})
env.autoAssemble=function(script,...)received=script;calls=(calls or 0)+1;arguments={...};return true,'assembly-info' end
local assemble=assert(load(prefix..'return autoAssemble','far-hooks','t',env))()
local original='[ENABLE]\nalloc(test,4096,28645248FB0)\ncall 7FFF12345678\ncall 1234\njmp 28645248FBE\n[DISABLE]\n1234:\ndb 90'
local token={}
local ok,info=assemble(original,false,token)
assert(ok and info=='assembly-info' and arguments[1]==false and arguments[2]==token,'Assembler result and disable token must survive')
assert(received:find('alloc(test,4096)',1,true) and not received:find('alloc(test,4096,',1,true),'No nearby request may reach CE')
assert(received:find('db FF 15 02 00 00 00 EB 08\ndq 7FFF12345678\ndb FF 15 02 00 00 00 EB 08\ndq 1234',1,true),'Consecutive calls must both use inline absolute pointers')
assert(received:find('db FF 25 00 00 00 00\ndq 28645248FBE',1,true),'Return jump must be absolute')
assemble('call FFFFFFFFFFFF');assert(received=='db FF 15 02 00 00 00 EB 08\ndq FFFFFFFFFFFF','First/last line call')
assemble('jmp FFFFFFFFFFFF');assert(received=='db FF 25 00 00 00 00\ndq FFFFFFFFFFFF','First/last line jump')
assemble('call vhFixedHP1Original\ncall qword ptr [callback]\njne localLabel')
assert(received=='call vhFixedHP1Original\ncall qword ptr [callback]\njne localLabel','Local labels and existing indirect calls must remain intact')
local before=calls;assert(not pcall(assemble,'alloc(test,4096,unsupported+10)') and calls==before,'Unsupported nearby syntax must fail before CE')
assemble(original);local once=received;assemble(once);assert(received==once,'Transform must be stable for uninstall')
print('PASS: all-distance calls/jumps, consecutive transfers, no near requests, fail-closed allocation syntax and disable-token forwarding')
