from pathlib import Path
import re
import xml.etree.ElementTree as ET

source = Path('outputs/ValheimInventory.lua')
s = source.read_text(encoding='utf-8')
for name, dll in [('helperHex', 'ValheimBowBeamV6'), ('deleteHelperHex', 'ValheimInventoryDelete'), ('minerHelperHex', 'ValheimRapidMinerV5'), ('hoeHelperHex', 'ValheimRapidHoeV2'), ('enemyHelperHex', 'ValheimEnemyFormV12'), ('dragHelperHex', 'ValheimDragBuildV6'), ('recoveryHelperHex', 'ValheimDeathRecoveryV2')]:
    s, count = re.subn(r"local " + name + "='[0-9a-f]+'", "local " + name + "='" + Path('outputs', dll + '.dll').read_bytes().hex() + "'", s)
    assert count == 1, name
source.write_text(s, encoding='utf-8')
resources=Path('outputs/ValheimUnlimitedResources.lua')
r=resources.read_text(encoding='utf-8')
r,count=re.subn(r"local summonHelperHex='[^']+'", "local summonHelperHex='"+Path('outputs/ValheimUnlimitedSummonsV1.dll').read_bytes().hex()+"'",r)
assert count==1
resources.write_text(r,encoding='utf-8')
table = Path('Valheim 2026 CT.CT')
root = ET.fromstring(table.read_bytes())
root.find('LuaScript').text = s
table.write_bytes(ET.tostring(root, encoding='utf-8', xml_declaration=True))
assert ET.fromstring(table.read_bytes()).findtext('LuaScript') == s
print('Table XML validated; Lua and all seven embedded helpers synchronized.')
import runpy
runpy.run_path('work/package-beta.py', run_name='__main__')
