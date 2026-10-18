"""Check release helper classes, embedded DLLs, and declared method signatures."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent.parent
lua = (root / 'outputs/ValheimBeta.lua').read_text(encoding='utf-8')
assert ET.parse(root / 'Valheim 2026 CT.CT').findtext('LuaScript') == lua
helpers = [
    ('recoveryHelperHex', 'RecoverySpawnBetaV31', 'ValheimRecoverySpawnBetaV31.dll', 'ValheimRecoverySpawnBeta.cs'),
    ('helperHex', 'BowBeamV13', 'ValheimBowBeamV13.dll', 'ValheimBowBeam.cs'),
    ('deleteHelperHex', 'InventoryDeleteV1', 'ValheimInventoryDelete.dll', 'ValheimInventoryDelete.cs'),
    ('minerHelperHex', 'RapidMinerV2', 'ValheimRapidMinerV2.dll', 'ValheimRapidMiner.cs'),
    ('hoeHelperHex', 'RapidHoeV2', 'ValheimRapidHoeV2.dll', 'ValheimRapidHoe.cs'),
    ('dragHelperHex', 'DragBuildV6', 'ValheimDragBuildV6.dll', 'ValheimDragBuild.cs'),
    ('enemyHelperHex', 'EnemyFormV11', 'ValheimEnemyFormV11.dll', 'ValheimEnemyForm.cs'),
]
referenced = set(re.findall(r"mono_(?:findClass|image_findClass)\([^\n]*?'ValheimSoloToolkit','([^']+)'", lua))
assert referenced == {item[1] for item in helpers}, referenced
codes = {'void': 1, 'bool': 2, 'int': 8, 'float': 12, 'string': 14}
total = 0
for variable, classname, dllname, filename in helpers:
    match = re.search(r"local " + variable + r"='([0-9a-f]+)'", lua)
    assert match, f'Missing embedded {variable}'
    binary = bytes.fromhex(match[1])
    assert binary == (root / 'outputs' / dllname).read_bytes(), f'DLL mismatch: {classname}'
    assert b'\0' + classname.encode() + b'\0' in binary, f'Class absent from DLL metadata: {classname}'
    source = (root / 'outputs' / filename).read_text(encoding='utf-8')
    assert re.search(r'\bclass\s+' + classname + r'\b', source)
    declarations = {}
    for returntype, name, parameters in re.findall(
            r'public\s+static\s+([\w.<>]+)\s+(\w+)\s*\(([^)]*)\)', source):
        parameters = [p.strip().split()[0] for p in parameters.split(',') if p.strip()]
        signature = ([codes.get(p, 18) for p in parameters], codes.get(returntype, 18))
        declarations.setdefault(name, []).append(signature)
    marker = "local class=mono_findClass('ValheimSoloToolkit','" + classname + "')"
    assert marker in lua
    start = lua.index(marker)
    section = lua[start:lua.index('\n  return ', lua.index('matchingMethod(class,', start))]
    if classname == 'RecoverySpawnBetaV31':
        replenish = (root / 'outputs/ValheimReplenish.lua').read_text(encoding='utf-8')
        assert "pointer(h.class,'Replenish helper')" in replenish
        section += '\n' + replenish
    calls = re.findall(r"matchingMethod\(class,'([^']+)',\{([\d, ]*)\},(\d+)\)", section)
    assert calls, f'No binding checks found: {classname}'
    for name, parameters, result in calls:
        signature = ([int(p) for p in parameters.split(',') if p.strip()], int(result))
        assert signature in declarations.get(name, []), f'{classname}.{name}: missing or mismatched {signature}'
        assert b'\0' + name.encode() + b'\0' in binary, f'Method absent from DLL metadata: {classname}.{name}'
        total += 1
    print(f'PASS: {classname}: embedded DLL matches, {len(calls)} method signatures checked')
print(f'PASS: {len(helpers)} helper classes, {total} bindings, and packaged table parity')

# UI order must stay aligned with the native form indices.
forms_source=(root / 'outputs/ValheimEnemyForm.cs').read_text(encoding='utf-8')
forms=re.findall(r'"([^"\n]+)"', re.search(r'string\[\] Forms=\{([^}]+)\}', forms_source)[1])
labels=re.findall(r"'([^'\n]+)'", re.search(r"local names=\{('Greydwarf'[^}]+)\}", lua)[1])
assert len(forms)==len(labels)==48 and len(set(forms))==48
assert 'choice<=48' in lua
print('PASS: 48 unique native forms, 48 UI labels and matching selection bounds')
