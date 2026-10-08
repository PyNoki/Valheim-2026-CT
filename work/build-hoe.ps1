param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference = 'Stop'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.AnimationModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:' + (Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimRapidHoeV1.dll" $references "$pwd\outputs\ValheimRapidHoe.cs"
if ($LASTEXITCODE) { throw 'Game assembly compilation failed' }
& $compiler /nologo "/out:$pwd\work\test-hoe.exe" "$pwd\outputs\ValheimRapidHoe.cs" "$pwd\work\test-hoe.cs"
if ($LASTEXITCODE) { throw 'Mock test compilation failed' }
& "$pwd\work\test-hoe.exe"
if ($LASTEXITCODE) { throw 'Mock tests failed' }
