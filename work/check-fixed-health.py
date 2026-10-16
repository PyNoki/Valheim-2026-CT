import ctypes
from pathlib import Path
l=ctypes.CDLL(r'C:\Program Files\Cheat Engine\lua53-64.dll')
l.luaL_newstate.restype=ctypes.c_void_p
l.luaL_openlibs.argtypes=[ctypes.c_void_p]
l.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
l.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
l.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];l.lua_tolstring.restype=ctypes.c_char_p
for path,execute in [('outputs/ValheimBeta.lua',False),('work/test_fixed_health.lua',True),('work/test_far_hooks.lua',True),('work/test_toggle_style.lua',True)]:
 s=l.luaL_newstate();l.luaL_openlibs(s);r=l.luaL_loadfilex(s,path.encode(),None)
 if not r and execute:r=l.lua_pcallk(s,0,0,0,0,None)
 assert not r,l.lua_tolstring(s,-1,None).decode()
 print('PASS:',path)
