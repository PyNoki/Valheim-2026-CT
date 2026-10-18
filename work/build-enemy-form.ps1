param([string]$Managed = 'C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference = 'Stop'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.UIModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.InputLegacyModule.dll','SoftReferenceableAssets.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:' + (Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimEnemyFormV11.dll" $references "$pwd\outputs\ValheimEnemyForm.cs"
if ($LASTEXITCODE) { throw 'Game assembly compilation failed' }
& $compiler /nologo "/out:$pwd\work\test-enemy-form.exe" "$pwd\outputs\ValheimEnemyForm.cs" "$pwd\work\test-enemy-form.cs"
if ($LASTEXITCODE) { throw 'Mock test compilation failed' }
# Run the same mocked tests in-process on systems that block new executables.
Add-Type -Path "$pwd\outputs\ValheimEnemyForm.cs","$pwd\work\test-enemy-form.cs"
[Tests]::Main()
