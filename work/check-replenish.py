import ctypes
from pathlib import Path
import xml.etree.ElementTree as ET

lua = ctypes.CDLL(r'C:\Program Files\Cheat Engine\lua53-64.dll')
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
                         ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]

for filename, execute in [('outputs/ValheimBeta.lua', False),
                          ('work/test_replenish_lua.lua', True)]:
    state = lua.luaL_newstate()
    try:
        lua.luaL_openlibs(state)
        result = lua.luaL_loadfilex(state, filename.encode(), None)
        if result == 0 and execute:
            result = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if result:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)

release = Path('outputs/ValheimBeta.lua').read_text(encoding='utf-8')
embedded = ET.parse('Valheim 2026 CT.CT').findtext('LuaScript')
assert embedded == release, 'Table differs from the tested release'
assert 'local class=pointer(h.class,\'Replenish helper\')' in embedded
assert 'recoveryHelper={pid=session,class=class,' in embedded
assert "mono_findClass('ValheimSoloToolkit','RecoverySpawnBetaV20')" not in embedded
print('PASS: packaged Lua 5.3 syntax, embedded table parity, dynamic helper binding')
