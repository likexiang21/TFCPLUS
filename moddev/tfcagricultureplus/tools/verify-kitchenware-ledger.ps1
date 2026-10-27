# Verify the K0 kitchenware ledger and the existing TFC container baseline.
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$javaRoot = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common'
$blocks = Join-Path $javaRoot 'MyBlocks.java'
$entities = Join-Path $javaRoot 'MyBlockEntities.java'
$ledger = Join-Path (Split-Path $project -Parent) 'docs\190-kitchenware-k0-ledger-20261018.md'
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($path in @($blocks, $entities, $ledger)) {
    if (-not (Test-Path -LiteralPath $path)) { $failures.Add("missing K0 file: $path") }
}

if (Test-Path -LiteralPath $blocks) {
    $text = Get-Content -LiteralPath $blocks -Raw -Encoding UTF8
    if ($text -notmatch 'TFC_WOODS\s*=\s*List\.of\(') { $failures.Add('TFC wood list is missing') }
    if ($text -notmatch 'AFC_WOODS\s*=\s*List\.of\(') { $failures.Add('AFC wood list is missing') }
    if ($text -notmatch 'TFC_ROCKS\s*=\s*List\.of\(') { $failures.Add('TFC rock list is missing') }
    foreach ($name in @('counter_cabinet','half_cabinet','sink_cabinet','spice_rack','food_display','fruit_bowl')) {
        if ($text -notmatch [regex]::Escape($name)) { $failures.Add("K1 family is missing from MyBlocks: $name") }
    }
    if ($text -notmatch 'registerKitchenFamily') { $failures.Add('K1 family registration helper is missing') }
    if ($text -notmatch 'KitchenStorageBlock') { $failures.Add('K1 shared kitchen block is missing') }
}

if (Test-Path -LiteralPath $entities) {
    $text = Get-Content -LiteralPath $entities -Raw -Encoding UTF8
    foreach ($name in @('LOG_CUTTING_BOARD','CUTTING_BOARD','KNIFE_BLOCK','MORTAR','DRYING_RACK','SILKWORM_RACK','TIMBER_PILE','BURNING_TIMBER_PILE')) {
        if ($text -notmatch ('\b' + $name + '\b')) { $failures.Add("existing container registration missing: $name") }
    }
    if ($text -notmatch '\bKITCHEN_STORAGE\b') { $failures.Add('K1 kitchen storage BE registration missing') }
}

if (Test-Path -LiteralPath $ledger) {
    $text = Get-Content -LiteralPath $ledger -Raw -Encoding UTF8
    foreach ($name in @('counter_cabinet','half_cabinet','sink_cabinet','spice_rack','food_display','fruit_bowl','jar_display','picnic_basket','chocolate_box','fondue')) {
        if ($text -notmatch ('`' + [regex]::Escape($name) + '`')) { $failures.Add("ledger missing planned id: $name") }
    }
    foreach ($token in @('InventoryBlockEntity','TickableInventoryBlockEntity','34 木材','21 岩石','K1 厨房骨架')) {
        if ($text -notmatch [regex]::Escape($token)) { $failures.Add("ledger missing interface/material contract: $token") }
    }
}

if ($failures.Count -gt 0) {
    Write-Host '[FAIL] kitchenware K0 ledger violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] K0 kitchenware ledger, planned ids, material scope, and existing TFC container baseline are frozen'
exit 0
