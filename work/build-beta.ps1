param([string]$Managed = 'C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference='Stop'
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references=@('assembly_valheim.dll','Splatform.dll','assembly_utils.dll','SoftReferenceableAssets.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.InputLegacyModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:'+(Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimRecoverySpawnBetaV11.dll" $references "$pwd\outputs\ValheimRecoverySpawnBeta.cs" "$pwd\outputs\ValheimBoatFun.cs" "$pwd\outputs\ValheimBoatJumpInput.cs" "$pwd\outputs\ValheimBoatSupport.cs" "$pwd\outputs\ValheimReplenish.cs"
if($LASTEXITCODE){throw 'Beta compilation failed'}
& $compiler /nologo "/out:$pwd\work\test-boat-jump.exe" "$pwd\outputs\ValheimBoatJumpInput.cs" "$pwd\outputs\ValheimBoatSupport.cs" "$pwd\work\test-boat-jump.cs"
if($LASTEXITCODE){throw 'Boat jump test compilation failed'}
& "$pwd\work\test-boat-jump.exe"
if($LASTEXITCODE){throw 'Boat jump tests failed'}
& $compiler /nologo "/out:$pwd\work\test-boat-support.exe" "$pwd\outputs\ValheimBoatSupport.cs" "$pwd\work\test-boat-support.cs"
if($LASTEXITCODE){throw 'Boat support test compilation failed'}
& "$pwd\work\test-boat-support.exe"
if($LASTEXITCODE){throw 'Boat support tests failed'}
& $compiler /nologo "/out:$pwd\work\test-replenish.exe" "$pwd\outputs\ValheimReplenish.cs" "$pwd\work\test-replenish.cs"
if($LASTEXITCODE){throw 'Replenish test compilation failed'}
& "$pwd\work\test-replenish.exe"
if($LASTEXITCODE){throw 'Replenish tests failed'}
