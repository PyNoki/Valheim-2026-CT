$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$root = Split-Path $PSScriptRoot -Parent
$cases = @(
    @{ Name='boat-jump'; Sources=@('ValheimBoatJumpInput','ValheimBoatSupport') },
    @{ Name='boat-support'; Sources=@('ValheimBoatSupport') },
    @{ Name='replenish'; Sources=@('ValheimReplenish') },
    @{ Name='trophy-buffs'; Sources=@('ValheimTrophyBuffs') },
    @{ Name='taming'; Sources=@('ValheimTaming') },
    @{ Name='spawn-catalogue'; Sources=@('ValheimSpawnCatalogue') },
    @{ Name='item-quality'; Sources=@('ValheimItemQuality') },
    @{ Name='loot-policy'; Sources=@('ValheimLootPolicy') }
)
foreach ($case in $cases) {
    $binary = Join-Path $PSScriptRoot "test-$($case.Name).exe"
    $sources = @($case.Sources | ForEach-Object { Join-Path $root "outputs\$_.cs" })
    $sources += Join-Path $PSScriptRoot "test-$($case.Name).cs"
    & $compiler /nologo "/out:$binary" $sources
    if ($LASTEXITCODE) { throw "$($case.Name) test compilation failed" }
    & $binary
    if ($LASTEXITCODE) { throw "$($case.Name) tests failed" }
}
