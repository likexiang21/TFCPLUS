# Verify that B-owned woodwork crafting recipes remain compatible with TFCWorkbenchContainer.
$ErrorActionPreference = 'Stop'
$project = Split-Path $env:TFC_TOOLS_ROOT -Parent
$recipeRoot = Join-Path $project 'src\main\resources\data\tfcagricultureplus\recipe\crafting\woodwork'
if (-not (Test-Path -LiteralPath $recipeRoot)) { throw "Woodwork crafting directory not found: $recipeRoot" }

$allowedTypes = @(
    'minecraft:crafting_shaped',
    'minecraft:crafting_shapeless',
    'tfc:advanced_shaped_crafting',
    'tfc:advanced_shapeless_crafting'
)
$files = @(Get-ChildItem -LiteralPath $recipeRoot -Recurse -File -Filter '*.json')
$failures = [System.Collections.Generic.List[string]]::new()
$typeCounts = @{}

foreach ($file in $files) {
    $relative = $file.FullName.Substring($recipeRoot.Length + 1).Replace('\', '/')
    $raw = Get-Content -LiteralPath $file.FullName -Raw
    if ($raw -match '(?i)tfcwoodwork:') {
        $failures.Add("${relative}: contains tfcwoodwork runtime ID")
    }
    try { $recipe = $raw | ConvertFrom-Json } catch {
        $failures.Add("${relative}: invalid JSON")
        continue
    }
    $type = [string]$recipe.type
    if (-not $typeCounts.ContainsKey($type)) { $typeCounts[$type] = 0 }
    $typeCounts[$type]++
    if ($type -notin $allowedTypes) { $failures.Add("${relative}: unsupported crafting type '$type'") }
    if (-not ($recipe.PSObject.Properties.Name -contains 'result')) {
        $failures.Add("${relative}: missing result")
    }
    if ($type -like 'tfc:advanced_*' -and
        (($recipe.PSObject.Properties.Name -contains 'category') -or ($recipe.PSObject.Properties.Name -contains 'group'))) {
        $failures.Add("${relative}: advanced TFC recipe must not define category/group")
    }
    if ($type -eq 'minecraft:crafting_shaped') {
        $pattern = @($recipe.pattern)
        if ($pattern.Count -gt 3 -or (@($pattern | ForEach-Object { $_.Length } | Where-Object { $_ -gt 3 }).Count -gt 0)) {
            $failures.Add("${relative}: shaped pattern exceeds the 3x3 workbench grid")
        }
    }
}

Write-Host ("[INFO] B woodwork crafting recipes = {0}" -f $files.Count)
$typeCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host ("[INFO] {0} = {1}" -f $_.Key, $_.Value)
}
if ($failures.Count -gt 0) {
    Write-Host '[FAIL] workbench recipe contract violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] B woodwork recipes are compatible with TFCWorkbenchContainer/CraftingMenu'
exit 0
