param([string]$Managed='C:\Program Files (x86)\Steam\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference='Stop'
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references=@('assembly_valheim.dll','UnityEngine.CoreModule.dll','UnityEngine.dll','netstandard.dll')|ForEach-Object{'/r:'+(Join-Path $Managed $_)}
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimUnlimitedSummonsV1.dll" $references "$pwd\outputs\ValheimUnlimitedSummons.cs"
if($LASTEXITCODE){throw 'Summon helper compilation failed'}
& $compiler /nologo "/out:$pwd\work\test-unlimited-summons.exe" "$pwd\outputs\ValheimUnlimitedSummons.cs" "$pwd\work\test-unlimited-summons.cs"
if($LASTEXITCODE){throw 'Summon tests compilation failed'}
& "$pwd\work\test-unlimited-summons.exe"
if($LASTEXITCODE){throw 'Summon tests failed'}
