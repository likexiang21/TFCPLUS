# Verify the independent B woodwork route for every TFC/AFC species.
$ErrorActionPreference = 'Stop'
$project = Split-Path $env:TFC_TOOLS_ROOT -Parent
$recipeRoot = Join-Path $project 'src\main\resources\data\tfcagricultureplus\recipe\in_world'
$tfcWoods = @('acacia','ash','aspen','birch','blackwood','chestnut','douglas_fir','hickory','kapok','mangrove','maple','oak','palm','pine','rosewood','sequoia','spruce','sycamore','white_cedar','willow')
$afcWoods = @('araucaria','baobab','beech','cypress','eucalyptus','fig','ginkgo','hevea','ipe','ironwood','mahoe','mahogany','teak','tualang')
$failures = [System.Collections.Generic.List[string]]::new()
$recipes = @(Get-ChildItem -LiteralPath $recipeRoot -Recurse -File -Filter '*.json')

function Get-OutputIds($recipe) {
    foreach ($entry in @($recipe.result_items)) {
        if ($null -ne $entry.item -and $null -ne $entry.item.id) { [string]$entry.item.id }
    }
}

function Has-Route([string]$inputBlock, [string]$tool, [string]$outputId) {
    foreach ($file in $recipes) {
        $recipe = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$recipe.input_state.block -ne $inputBlock -or [string]$recipe.tool -ne $tool) { continue }
        if (@(Get-OutputIds $recipe) -contains $outputId) { return $true }
    }
    return $false
}

function Has-StateRoute([string]$inputBlock, [string]$tool, [string]$resultBlock) {
    foreach ($file in $recipes) {
        $recipe = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$recipe.input_state.block -ne $inputBlock -or [string]$recipe.tool -ne $tool) { continue }
        if ([string]$recipe.result_state.Name -eq $resultBlock) { return $true }
    }
    return $false
}

foreach ($wood in $tfcWoods + $afcWoods) {
    $origin = if ($afcWoods -contains $wood) { 'afc' } else { 'tfc' }
    if (-not (Has-StateRoute "${origin}:wood/wood/$wood" 'axe' "${origin}:wood/stripped_wood/$wood")) {
        $failures.Add("${wood}: wood block -> stripped wood route missing")
    }
    if (-not (Has-StateRoute "${origin}:wood/log/$wood" 'axe' "${origin}:wood/stripped_log/$wood")) {
        $failures.Add("${wood}: log block -> stripped log route missing")
    }
    if (-not (Has-Route "${origin}:wood/stripped_wood/$wood" 'axe' "tfcagricultureplus:bast/$wood")) {
        $failures.Add("${wood}: stripped wood -> B debarked log route missing")
    }
    if (-not (Has-Route "${origin}:wood/stripped_log/$wood" 'axe' "tfcagricultureplus:bast/$wood")) {
        $failures.Add("${wood}: stripped log -> B debarked log route missing")
    }
    if (-not (Has-Route "${origin}:wood/log/$wood" 'axe' "tfcagricultureplus:bark/$wood")) {
        $failures.Add("${wood}: source log -> B bark route missing")
    }
    if (-not (Has-Route "tfcagricultureplus:debarked_log/$wood" 'axe' "tfcagricultureplus:debarked_half/$wood")) {
        $failures.Add("${wood}: debarked log -> half route missing")
    }
    if (-not (Has-Route "tfcagricultureplus:debarked_half/$wood" 'axe' "tfcagricultureplus:debarked_quarter/$wood")) {
        $failures.Add("${wood}: half -> quarter route missing")
    }
}

# A source log may produce a fence or bark, but must not directly produce the
# finished lumber/support families that require the debarked/split route.
foreach ($file in $recipes) {
    $recipe = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $input = [string]$recipe.input_state.block
    if ($input -notmatch '^(tfc|afc):wood/log/') { continue }
    foreach ($id in @(Get-OutputIds $recipe)) {
        if ($id -match ':(?:wood/)?(?:planks|lumber|support)/') {
            $failures.Add("$($file.Name): source log directly produces finished wood $id")
        }
    }
}

Write-Host ("[INFO] woodwork species routes checked = {0}" -f ($tfcWoods.Count + $afcWoods.Count))
if ($failures.Count) {
    Write-Host '[FAIL] woodwork flow violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] all species preserve the bark -> debarked -> split woodwork route'
exit 0
