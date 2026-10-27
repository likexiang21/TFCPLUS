# Verify the shared eight-item drying-rack batch contract.
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$source = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common\blockentities\DryingRackBlockEntity.java'
$interactions = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common\DryingRackInteractions.java'
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($path in @($source, $interactions)) {
    if (-not (Test-Path -LiteralPath $path)) { $failures.Add("missing source: $path") }
}
if (Test-Path -LiteralPath $source) {
    $text = Get-Content -LiteralPath $source -Raw -Encoding UTF8
    if ($text -notmatch 'MAX_BATCH\s*=\s*8') { $failures.Add('MAX_BATCH must remain eight') }
    if ($text -notmatch 'getSlotStackLimit\s*\(int slot\).*?MAX_BATCH') { $failures.Add('inventory slot limit is not tied to MAX_BATCH') }
    if ($text -notmatch 'ItemStack\.isSameItemSameComponents\s*\(') { $failures.Add('mixed item/component rejection is missing') }
    if ($text -notmatch 'DryingRecipe\.getRecipe\s*\(') { $failures.Add('Firmalife drying recipe lookup is missing') }
    if ($text -notmatch 'recipe\.assemble\s*\(input\)') { $failures.Add('batch output is not assembled from the full input stack') }
    if ($text -notmatch 'FLConfig\.SERVER\.dryingTicks\.get\(\)') { $failures.Add('configured drying duration is missing') }
    if ($text -notmatch 'insertCount\(ItemStack stack\)[\s\S]*?if \(!canAccept\(stack\)\)') { $failures.Add('direct insertion does not share canAccept') }
    if ($text -notmatch 'RackItemHandler[\s\S]*?canAccept\(stack\)') { $failures.Add('automation insertion does not share canAccept') }
}
if (Test-Path -LiteralPath $interactions) {
    $text = Get-Content -LiteralPath $interactions -Raw -Encoding UTF8
    if ($text -notmatch 'rack\.insertCount\(held\)') { $failures.Add('mouse insertion is not routed through insertCount') }
    if ($text -notmatch 'rack\.isFinished\(\)') { $failures.Add('mouse extraction does not require completion') }
}
if ($failures.Count -gt 0) {
    Write-Host '[FAIL] drying-rack batch contract violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] drying rack keeps one shared eight-item batch contract for mouse and automation paths'
exit 0
