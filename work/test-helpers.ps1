$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$root = Split-Path $PSScriptRoot -Parent
$cases = @(
    @{ Name='unlimited-summons'; Sources=@('ValheimUnlimitedSummons') },
    @{ Name='boat-jump'; Sources=@('ValheimBoatJumpInput','ValheimBoatSupport') },
    @{ Name='boat-fun'; Sources=@('ValheimBoatFun','ValheimBoatJumpInput','ValheimBoatSupport') },
    @{ Name='boat-support'; Sources=@('ValheimBoatSupport') },
    @{ Name='replenish'; Sources=@('ValheimReplenish') },
    @{ Name='trophy-buffs'; Sources=@('ValheimTrophyBuffs','ValheimRested') },
    @{ Name='taming'; Sources=@('ValheimTaming','ValheimSpawnCatalogue') },
    @{ Name='spawn-catalogue'; Sources=@('ValheimSpawnCatalogue') },
    @{ Name='enemy-form'; Sources=@('ValheimEnemyForm') },
    @{ Name='chest-sorting'; Sources=@('ValheimChestSorting','ValheimChestSortingNetwork','ValheimChestSortingUI','ValheimChestSortingInventory') },
    @{ Name='item-quality'; Sources=@('ValheimItemQuality') },
    @{ Name='loot-policy'; Sources=@('ValheimLootPolicy') }
)
foreach ($case in $cases) {
    $binary = Join-Path $PSScriptRoot "test-$($case.Name).exe"
    $sources = @($case.Sources | ForEach-Object { Join-Path $root "outputs\$_.cs" })
    if($case.Name -in @("boat-fun")) { $sources += Join-Path $PSScriptRoot "boat-test-mocks.cs" }
    $sources += Join-Path $PSScriptRoot "test-$($case.Name).cs"
    & $compiler /nologo "/out:$binary" $sources
    if ($LASTEXITCODE) { throw "$($case.Name) test compilation failed" }
    & $binary
    if ($LASTEXITCODE) { throw "$($case.Name) tests failed" }
}
