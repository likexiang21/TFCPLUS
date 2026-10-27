# Verify the JSON shape consumed by B's independent InWorldRecipe codec.
$ErrorActionPreference = 'Stop'
$project = Split-Path $env:TFC_TOOLS_ROOT -Parent
$woodRoot = Join-Path $project 'src\main\resources\data\tfcagricultureplus\recipe\in_world\woodwork'
$lootRoot = Join-Path $project 'src\main\resources\data\tfcagricultureplus\loot_table\blocks'
$componentsSource = Join-Path $project 'src\main\java\io\github\likexiang21\tfcplus\agriculture\common\recipe\inworld\InWorldComponents.java'
$sawdustRecipe = Join-Path $project 'src\main\resources\data\tfcagricultureplus\recipe\crafting\woodwork\sawdust_dough.json'
$failures = [System.Collections.Generic.List[string]]::new()
$actions = @('drop_center', 'drop_cardinal', 'drop_above', 'shoot_as_block')
$tools = @('axe', 'saw', 'knife')
$recipes = @(Get-ChildItem -LiteralPath $woodRoot -Recurse -File -Filter '*.json')
$componentsText = Get-Content -LiteralPath $componentsSource -Raw

function Add-Failure([string]$file, [string]$message) {
    $failures.Add("$($file.Replace($project + '\\', '')): $message")
}

function Is-Object($value) {
    return $null -ne $value -and $value -isnot [System.Array] -and $value -isnot [string] -and $value -isnot [ValueType]
}

function Is-Array($value) {
    return $value -is [System.Array]
}

foreach ($file in $recipes) {
    try { $recipe = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { Add-Failure $file.FullName "invalid JSON: $($_.Exception.Message)"; continue }
    if ([string]$recipe.type -ne 'tfcagricultureplus:in_world') { Add-Failure $file.FullName 'type must be tfcagricultureplus:in_world' }
    if (-not (Is-Object $recipe.input_state)) { Add-Failure $file.FullName 'input_state must be an object'; continue }
    if ([string]::IsNullOrWhiteSpace([string]$recipe.input_state.block)) { Add-Failure $file.FullName 'input_state.block is required' }
    if ($null -ne $recipe.input_state.acceptableStates) {
        if (-not (Is-Array $recipe.input_state.acceptableStates)) { Add-Failure $file.FullName 'input_state.acceptableStates must be an array' }
        foreach ($state in @($recipe.input_state.acceptableStates)) {
            if (-not (Is-Object $state) -or [string]::IsNullOrWhiteSpace([string]$state.Name)) { Add-Failure $file.FullName 'acceptableStates entries need Name objects' }
        }
    }
    if ($tools -notcontains [string]$recipe.tool) { Add-Failure $file.FullName 'tool is not an allowed value' }
    if (-not (Is-Object $recipe.result_state) -or [string]::IsNullOrWhiteSpace([string]$recipe.result_state.Name)) { Add-Failure $file.FullName 'result_state must be an object with Name' }
    if ($null -eq $recipe.result_items -or -not (Is-Array $recipe.result_items)) { Add-Failure $file.FullName 'result_items must be an array' }
    foreach ($entry in @($recipe.result_items)) {
        if (-not (Is-Object $entry) -or -not (Is-Object $entry.item) -or [string]::IsNullOrWhiteSpace([string]$entry.item.id)) { Add-Failure $file.FullName 'result_items entries need item.id objects' }
        if ($actions -notcontains [string]$entry.action) { Add-Failure $file.FullName 'result_items action is not allowed' }
        if ($null -ne $entry.item.count -and [int]$entry.item.count -lt 1) { Add-Failure $file.FullName 'result item count must be positive' }
    }
    if ($null -ne $recipe.sound) {
        if (-not (Is-Object $recipe.sound) -or [string]::IsNullOrWhiteSpace([string]$recipe.sound.sound) -or $null -eq $recipe.sound.volume -or $null -eq $recipe.sound.pitch) { Add-Failure $file.FullName 'sound must contain sound, volume and pitch' }
    }
}

$lootFiles = @(Get-ChildItem -LiteralPath $lootRoot -Recurse -File -Filter '*.json' | Where-Object { $_.FullName -match '\\debarked_(log|half|quarter)\\' })
foreach ($file in $lootFiles) {
    try { $loot = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { Add-Failure $file.FullName "invalid JSON: $($_.Exception.Message)"; continue }
    if (-not (Is-Array $loot.pools)) { Add-Failure $file.FullName 'loot pools must be an array' }
    foreach ($pool in @($loot.pools)) {
        foreach ($key in @('conditions', 'entries')) {
            if ($null -ne $pool.$key -and -not (Is-Array $pool.$key)) { Add-Failure $file.FullName "loot pool $key must be an array" }
        }
        foreach ($entry in @($pool.entries)) {
            if ($null -ne $entry.functions -and -not (Is-Array $entry.functions)) { Add-Failure $file.FullName 'loot entry functions must be an array' }
        }
    }
}

Write-Host ("[INFO] woodwork in_world files checked = {0}; debarked loot tables checked = {1}" -f $recipes.Count, $lootFiles.Count)
if ($recipes.Count -ne 408) { Add-Failure 'recipe/in_world/woodwork' "expected 408 woodwork recipes, found $($recipes.Count)" }
if (-not $componentsText.Contains('ResourceLocation.CODEC.xmap(SoundEvent::createVariableRangeEvent')) {
    Add-Failure $componentsSource 'SoundSpec codec must consume the resource-location sound JSON used by the generated recipes'
}
try {
    $sawdust = Get-Content -LiteralPath $sawdustRecipe -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not (Is-Array $sawdust.result.modifiers)) { Add-Failure $sawdustRecipe 'result.modifiers must be an array' }
} catch { Add-Failure $sawdustRecipe "invalid JSON: $($_.Exception.Message)" }
if ($failures.Count) {
    Write-Host '[FAIL] in-world/loot codec contract violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] all woodwork in-world and debarked loot resources match the runtime codec shape'
exit 0
