# Verify the B-owned silkworm post-processing chain uses TFC's pot and loom.
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$resources = Join-Path $project 'src\main\resources'
$java = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common\MyItems.java'
$tab = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common\MyCreativeTab.java'
$pot = Join-Path $resources 'data\tfcagricultureplus\recipe\pot\cocoon_to_silk_thread.json'
$spindle = Join-Path $resources 'data\tfcagricultureplus\recipe\crafting\cooked_silkworm_to_silk_thread.json'
$loom = Join-Path $resources 'data\tfcagricultureplus\recipe\loom\silk_cloth.json'
$model = Join-Path $resources 'assets\tfcagricultureplus\models\item\silk_thread.json'
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($path in @($java, $tab, $pot, $spindle, $loom, $model)) {
    if (-not (Test-Path -LiteralPath $path)) { $failures.Add("missing silkworm chain file: $path") }
}
if (Test-Path -LiteralPath $java) {
    $text = Get-Content -LiteralPath $java -Raw
    if ($text -notmatch 'SILK_THREAD') { $failures.Add('MyItems.java: SILK_THREAD is not registered') }
}
if (Test-Path -LiteralPath $tab) {
    $text = Get-Content -LiteralPath $tab -Raw
    if ($text -notmatch 'MyItems\.SILK_THREAD') { $failures.Add('MyCreativeTab.java: SILK_THREAD is not visible in the B tab') }
}
if (Test-Path -LiteralPath $pot) {
    try { $json = Get-Content -LiteralPath $pot -Raw | ConvertFrom-Json } catch { $failures.Add('pot recipe is not valid JSON'); $json = $null }
    if ($null -ne $json) {
        if ($json.type -ne 'tfc:pot') { $failures.Add('pot recipe does not use tfc:pot') }
        if ($json.item_output[0].id -ne 'tfcagricultureplus:cooked_silkworm') { $failures.Add('pot recipe output is not cooked silkworm') }
        if ($json.ingredients[0].item -ne 'tfcagricultureplus:cocoon') { $failures.Add('pot recipe input is not B cocoon') }
        if ($json.fluid_ingredient.amount -ne 100 -or $json.fluid_ingredient.fluid -ne 'minecraft:water') { $failures.Add('pot recipe must consume 100 mB water') }
        if ($json.uses_all_fluid -ne $false) { $failures.Add('pot recipe must preserve water beyond the consumed 100 mB') }
        if ($json.duration -ne 1200 -or $json.temperature -ne 300.0) { $failures.Add('pot recipe timing/temperature changed unexpectedly') }
    }
}
if (Test-Path -LiteralPath $spindle) {
    try { $json = Get-Content -LiteralPath $spindle -Raw | ConvertFrom-Json } catch { $failures.Add('spindle recipe is not valid JSON'); $json = $null }
    if ($null -ne $json) {
        if ($json.type -ne 'tfc:advanced_shapeless_crafting') { $failures.Add('spindle recipe must use TFC advanced shapeless crafting') }
        $items = @($json.ingredients | ForEach-Object { $_.item })
        if ($items -notcontains 'tfcagricultureplus:cooked_silkworm' -or $items -notcontains 'tfc:spindle') { $failures.Add('spindle recipe inputs are incomplete') }
        if ($json.primary_ingredient.item -ne 'tfc:spindle') { $failures.Add('spindle must be the primary ingredient') }
        if ($json.remainder.modifiers[0].type -ne 'tfc:damage_crafting_remainder') { $failures.Add('spindle recipe must damage the spindle remainder') }
        if ($json.result.id -ne 'tfcagricultureplus:silk_thread') { $failures.Add('spindle recipe output is not B silk thread') }
    }
}
if (Test-Path -LiteralPath $loom) {
    try { $json = Get-Content -LiteralPath $loom -Raw | ConvertFrom-Json } catch { $failures.Add('loom recipe is not valid JSON'); $json = $null }
    if ($null -ne $json) {
        if ($json.type -ne 'tfc:loom') { $failures.Add('loom recipe does not use tfc:loom') }
        if ($json.ingredient.item -ne 'tfcagricultureplus:silk_thread' -or $json.ingredient.count -ne 24) { $failures.Add('loom recipe must consume 24 B silk threads') }
        if ($json.result.id -ne 'tfc:silk_cloth' -or $json.result.count -ne 1) { $failures.Add('loom recipe must produce one TFC silk cloth') }
        if ($json.steps -ne 24) { $failures.Add('loom recipe steps must match its 24-thread input') }
    }
}
if ($failures.Count -gt 0) {
    Write-Host '[FAIL] silkworm post-processing contract violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] silkworm cocoon -> TFC pot -> silk thread -> TFC loom chain is complete'
exit 0
