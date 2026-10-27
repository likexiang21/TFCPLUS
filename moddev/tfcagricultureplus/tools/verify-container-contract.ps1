# Verify that every B-owned item-holding block uses TFC's container base and
# keeps an explicit slot policy, validation rule, and destruction path.
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$javaRoot = Join-Path $project 'src\main\java'
$blockEntityRegistry = Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion\common\MyBlockEntities.java'
$blockSource = Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion\common\MyBlocks.java'
$dryingBlock = Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion\common\DryingRackBlock.java'
$silkwormBlock = Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion\common\SilkwormRackBlock.java'
$timberBlock = Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion\common\timber\TimberPileBlock.java'

$required = @(
    @{ File = 'common\blockentities\CuttingBoardBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('cutting_board','log_cutting_board') },
    @{ File = 'common\blockentities\KnifeBlockBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('knife_block') },
    @{ File = 'common\blockentities\MortarBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('mortar') },
    @{ File = 'common\blockentities\DryingRackBlockEntity.java'; Base = 'TickableInventoryBlockEntity'; Registry = @('drying_rack') },
    @{ File = 'common\blockentities\SilkwormRackBlockEntity.java'; Base = 'TickableInventoryBlockEntity'; Registry = @('silkworm_rack') },
    @{ File = 'common\timber\TimberPileBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('log_pile') }
)
$failures = [System.Collections.Generic.List[string]]::new()
$registryText = Get-Content -LiteralPath $blockEntityRegistry -Raw
$blockText = Get-Content -LiteralPath $blockSource -Raw

foreach ($entry in $required) {
    $path = Join-Path (Join-Path $javaRoot 'com\example\tfcfarmingplus\expansion') $entry.File
    if (-not (Test-Path -LiteralPath $path)) { $failures.Add("missing block entity source: $($entry.File)"); continue }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notmatch 'net\.dries007\.tfc\.common\.blockentities\.(InventoryBlockEntity|TickableInventoryBlockEntity)') {
        $failures.Add("$($entry.File): no TFC inventory base import")
    }
    if ($text -notmatch "extends\s+$($entry.Base)") {
        $failures.Add("$($entry.File): does not extend $($entry.Base)")
    }
    if ($text -notmatch 'getSlotStackLimit\s*\(') { $failures.Add("$($entry.File): missing slot capacity policy") }
    if ($text -notmatch 'isItemValid\s*\(') { $failures.Add("$($entry.File): missing item validation policy") }
    foreach ($name in $entry.Registry) {
        $registryPattern = 'register\([^\)]*"' + [regex]::Escape($name) + '"'
        if ($registryText -notmatch $registryPattern) {
            $failures.Add("$($entry.File): registry entry '$name' not found")
        }
    }
}

foreach ($path in @($blockSource, $dryingBlock, $silkwormBlock, $timberBlock)) {
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notmatch 'onRemove\s*\(') {
        $failures.Add("$([IO.Path]::GetFileName($path)): missing onRemove destruction hook")
    }
}

if ($failures.Count -gt 0) {
    Write-Host '[FAIL] TFC container contract violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] B item-holding blocks use TFC container bases, policies, registrations, and removal hooks'
exit 0
