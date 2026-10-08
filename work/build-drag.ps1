param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference='Stop'
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references=@('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.InputLegacyModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:'+(Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimDragBuildV3.dll" $references "$pwd\outputs\ValheimDragBuild.cs" "$pwd\outputs\ValheimDragRowPlan.cs"
if($LASTEXITCODE){throw 'Drag build compilation failed'}
& $compiler /nologo "/out:$pwd\work\test-drag-plan.exe" "$pwd\outputs\ValheimDragRowPlan.cs" "$pwd\work\test-drag-plan.cs"
if($LASTEXITCODE){throw 'Drag plan test compilation failed'}
& "$pwd\work\test-drag-plan.exe"
if($LASTEXITCODE){throw 'Drag plan tests failed'}
