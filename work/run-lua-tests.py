import ctypes
l=ctypes.CDLL(r'C:\Program Files\Cheat Engine\lua53-64.dll')
l.luaL_newstate.restype=ctypes.c_void_p
s=l.luaL_newstate()
l.luaL_openlibs.argtypes=[ctypes.c_void_p];l.luaL_openlibs(s)
l.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
l.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
r=l.luaL_loadfilex(s,b'work/test_inventory.lua',None)
r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_spawn_stars.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_chest_sorting.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_chest_sorting_layout.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_toggle_style.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_pixie_boat.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_fast_attacks.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_unlimited_resources.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
if r==0:
 r=l.luaL_loadfilex(s,b'work/test_skill_layout.lua',None)
 r=r or l.lua_pcallk(s,0,0,0,0,None)
l.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];l.lua_tolstring.restype=ctypes.c_char_p
print('Tests passed' if r==0 else l.lua_tolstring(s,-1,None).decode())
raise SystemExit(r)
