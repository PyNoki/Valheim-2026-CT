param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference = 'Stop'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.ParticleSystemModule.dll','UnityEngine.InputLegacyModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:' + (Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimBowBeamV3.dll" $references "$pwd\outputs\ValheimBowBeam.cs" "$pwd\outputs\ValheimBeamDamage.cs" "$pwd\outputs\ValheimBeamTerrain.cs"
if ($LASTEXITCODE) { throw 'Game assembly compilation failed' }
& $compiler /nologo "/out:$pwd\work\test-beam-damage.exe" "$pwd\outputs\ValheimBeamDamage.cs" "$pwd\outputs\ValheimBeamTerrain.cs" "$pwd\work\test-beam-damage.cs"
if ($LASTEXITCODE) { throw 'Damage test compilation failed' }
& "$pwd\work\test-beam-damage.exe"
if ($LASTEXITCODE) { throw 'Damage tests failed' }
