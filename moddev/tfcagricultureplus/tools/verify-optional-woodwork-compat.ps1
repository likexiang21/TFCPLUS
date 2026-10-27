# Verify that TFC Woodworking remains optional and that B owns the interaction surface.
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$template = Join-Path $project 'src\main\templates\META-INF\neoforge.mods.toml'
$handler = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\common\recipe\inworld\InWorldRecipeHandler.java'
$jei = Join-Path $project 'src\main\java\com\example\tfcfarmingplus\expansion\compat\jei\MyJeiPlugin.java'
$failures = [System.Collections.Generic.List[string]]::new()

$metadata = Get-Content -LiteralPath $template -Raw
if ($metadata -match '(?m)modId\s*=\s*"tfcwoodwork"') {
    $failures.Add('neoforge.mods.toml declares tfcwoodwork as a dependency')
}
$handlerText = Get-Content -LiteralPath $handler -Raw
if ($handlerText -notmatch 'EventPriority\.HIGH') { $failures.Add('world handler is not high priority') }
if ($handlerText -notmatch 'setCanceled\(true\)') { $failures.Add('world handler does not reserve/cancel handled interactions') }
$jeiText = Get-Content -LiteralPath $jei -Raw
if ($jeiText -notmatch 'getNamespace\(\)\.equals\("tfcwoodwork"\)') {
    $failures.Add('JEI compatibility filter does not hide tfcwoodwork item entries')
}

$runtimeFiles = Get-ChildItem (Join-Path $project 'src\main') -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\META-INF\\licenses\\' }
$runtimeRefs = @($runtimeFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match '(?i)tfcwoodwork:' })
if ($runtimeRefs.Count -gt 0) {
    $runtimeRefs | ForEach-Object { $failures.Add("runtime tfcwoodwork ID: $($_.FullName)") }
}

if ($failures.Count -gt 0) {
    Write-Host '[FAIL] optional woodwork compatibility violations:'
    $failures | ForEach-Object { Write-Host "       $_" }
    exit 1
}
Write-Host '[OK] TFC Woodworking is optional; B owns handled interactions and JEI filtering'
exit 0
