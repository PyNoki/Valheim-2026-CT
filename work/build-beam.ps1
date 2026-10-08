param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference = 'Stop'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.ParticleSystemModule.dll','UnityEngine.InputLegacyModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:' + (Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimBowBeamV6.dll" $references "$pwd\outputs\ValheimKayokenAura.cs" "$pwd\outputs\ValheimDbzPower.cs" "$pwd\outputs\ValheimDbzBomb.cs" "$pwd\outputs\ValheimBombPlan.cs" "$pwd\outputs\ValheimBowBeam.cs" "$pwd\outputs\ValheimBeamDamage.cs" "$pwd\outputs\ValheimBeamTerrain.cs"
if ($LASTEXITCODE) { throw 'Game assembly compilation failed' }
& $compiler /nologo "/out:$pwd\work\test-beam-damage.exe" "$pwd\outputs\ValheimDbzPower.cs" "$pwd\outputs\ValheimBeamDamage.cs" "$pwd\outputs\ValheimBeamTerrain.cs" "$pwd\work\test-beam-damage.cs"
if ($LASTEXITCODE) { throw 'Damage test compilation failed' }
& "$pwd\work\test-beam-damage.exe"
if ($LASTEXITCODE) { throw 'Damage tests failed' }
& $compiler /nologo "/out:$pwd\work\test-bomb-plan.exe" "$pwd\outputs\ValheimDbzPower.cs" "$pwd\outputs\ValheimBombPlan.cs" "$pwd\work\test-bomb-plan.cs"
if ($LASTEXITCODE) { throw 'Bomb test compilation failed' }
& "$pwd\work\test-bomb-plan.exe"
if ($LASTEXITCODE) { throw 'Bomb tests failed' }
