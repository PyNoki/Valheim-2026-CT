param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference='Stop'
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references=@('assembly_valheim.dll','assembly_utils.dll','SoftReferenceableAssets.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:'+(Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimDeathRecoveryV2.dll" $references "$pwd\outputs\ValheimDeathRecovery.cs"
if($LASTEXITCODE){throw 'Death recovery compilation failed'}
& $compiler /nologo "/out:$pwd\work\test-death-recovery.exe" "$pwd\outputs\ValheimDeathRecovery.cs" "$pwd\work\test-death-recovery.cs"
if($LASTEXITCODE){throw 'Recovery test compilation failed'}
& "$pwd\work\test-death-recovery.exe"
if($LASTEXITCODE){throw 'Recovery tests failed'}
