# Verify that every B-owned item-holding block uses TFC's container base and
# keeps an explicit slot policy, validation rule, and destruction path.
$ErrorActionPreference = 'Stop'
$project = Split-Path $env:TFC_TOOLS_ROOT -Parent
$javaRoot = Join-Path $project 'src\main\java'
$blockEntityRegistry = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\registry\AgricultureBlockEntities.java'
$blockSource = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\registry\AgricultureBlocks.java'
$cuttingBoardBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\CuttingBoardBlock.java'
$logCuttingBoardBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\LogCuttingBoardBlock.java'
$knifeRackBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\KnifeRackBlock.java'
$mortarBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\MortarBlock.java'
$dryingBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\DryingRackBlock.java'
$silkwormBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\block\SilkwormRackBlock.java'
$timberBlock = Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture\common\timber\TimberPileBlock.java'

$required = @(
    @{ File = 'common\blockentity\CuttingBoardBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('cutting_board','log_cutting_board') },
    @{ File = 'common\blockentity\KnifeRackBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('knife_block') },
    @{ File = 'common\blockentity\MortarBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('mortar') },
    @{ File = 'common\blockentity\DryingRackBlockEntity.java'; Base = 'TickableInventoryBlockEntity'; Registry = @('drying_rack') },
    @{ File = 'common\blockentity\SilkwormRackBlockEntity.java'; Base = 'TickableInventoryBlockEntity'; Registry = @('silkworm_rack') },
    @{ File = 'common\timber\TimberPileBlockEntity.java'; Base = 'InventoryBlockEntity'; Registry = @('log_pile') }
)
$failures = [System.Collections.Generic.List[string]]::new()
$registryText = Get-Content -LiteralPath $blockEntityRegistry -Raw
$blockText = Get-Content -LiteralPath $blockSource -Raw

foreach ($entry in $required) {
    $path = Join-Path (Join-Path $javaRoot 'io\github\likexiang21\tfcplus\agriculture') $entry.File
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

foreach ($path in @($cuttingBoardBlock, $logCuttingBoardBlock, $knifeRackBlock, $mortarBlock, $dryingBlock, $silkwormBlock, $timberBlock)) {
    $text = Get-Content -LiteralPath $path -Raw
    $ownsOnRemove = $path -ne $logCuttingBoardBlock
    if ($ownsOnRemove -and $text -notmatch 'onRemove\s*\(') {
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
