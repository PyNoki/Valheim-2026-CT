param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference = 'Stop'
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references = @('assembly_valheim.dll','assembly_utils.dll','UnityEngine.CoreModule.dll','UnityEngine.PhysicsModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:' + (Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimWorldToolsV1.dll" $references "$pwd\outputs\ValheimWorldTools.cs"
if ($LASTEXITCODE) { throw 'Game assembly compilation failed' }
& $compiler /nologo "/out:$pwd\work\test-world-tools.exe" "$pwd\outputs\ValheimWorldTools.cs" "$pwd\work\test-world-tools.cs"
if ($LASTEXITCODE) { throw 'World tools mock test compilation failed' }
& "$pwd\work\test-world-tools.exe"
if ($LASTEXITCODE) { throw 'World tools mock tests failed' }
