from pathlib import Path
import re
import xml.etree.ElementTree as ET

source = Path('outputs/ValheimInventory.lua')
s = source.read_text(encoding='utf-8')
for name, dll in [('helperHex', 'ValheimBowBeamV4'), ('deleteHelperHex', 'ValheimInventoryDelete'), ('minerHelperHex', 'ValheimRapidMinerV1'), ('hoeHelperHex', 'ValheimRapidHoeV1'), ('enemyHelperHex', 'ValheimEnemyFormV6')]:
    s, count = re.subn(r"local " + name + "='[0-9a-f]+'", "local " + name + "='" + Path('outputs', dll + '.dll').read_bytes().hex() + "'", s)
    assert count == 1, name
source.write_text(s, encoding='utf-8')
table = Path('Valheim 2026 CT.CT')
root = ET.fromstring(table.read_bytes())
root.find('LuaScript').text = s
table.write_bytes(ET.tostring(root, encoding='utf-8', xml_declaration=True))
assert ET.fromstring(table.read_bytes()).findtext('LuaScript') == s
print('Table XML validated; Lua and all five embedded helpers synchronized.')
