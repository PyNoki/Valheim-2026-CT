param([string]$Managed = 'D:\SteamLibrary\steamapps\common\Valheim\valheim_Data\Managed')
$ErrorActionPreference='Stop'
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$references=@('assembly_valheim.dll','UnityEngine.CoreModule.dll','UnityEngine.dll','netstandard.dll') | ForEach-Object { '/r:'+(Join-Path $Managed $_) }
& $compiler /nologo /target:library "/out:$pwd\outputs\ValheimLearnRecipesV1.dll" $references "$pwd\outputs\ValheimLearnRecipes.cs"
if($LASTEXITCODE){throw 'Game compilation failed'}
& $compiler /nologo "/out:$pwd\work\test-recipes.exe" "$pwd\outputs\ValheimLearnRecipes.cs" "$pwd\work\test-recipes.cs"
if($LASTEXITCODE){throw 'Test compilation failed'}
& "$pwd\work\test-recipes.exe"
if($LASTEXITCODE){throw 'Recipe tests failed'}
