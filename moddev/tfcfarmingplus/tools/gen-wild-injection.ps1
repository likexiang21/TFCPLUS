# gen-wild-injection.ps1
# 把全部野生作物与浆果灌木的随机patch注入到 TFC 的世界生成标签里。
# 机制：TFC 通过 placed_feature 标签 feature/crops.json 与 feature/berry_bushes.json
#       收集野生植物，再由 biome modifier 在对应生物群系中生成。
#       因此方块/贴图/feature 文件齐全并不代表能在世界中生成，必须进标签。
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$proj = Split-Path -Parent $PSScriptRoot
$res = Resolve-LegacyGeneratorOutput $OutputRoot
$NS   = 'tfcfarmingplus'

function Save-Json([string]$rel, $obj) {
    $p = Join-Path $res $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
    $json = $obj | ConvertTo-Json -Depth 10 -Compress
    [System.IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  写出 $rel"
}

# ---- 1. 野生作物：以实际存在的 placed_feature 文件为准 ----
$pfDir = Join-Path $res "data\$NS\worldgen\placed_feature\plant\wild_crop"
$crops = Get-ChildItem $pfDir -Filter '*_patch.json' |
    ForEach-Object { $_.BaseName -replace '_patch$', '' } | Sort-Object
$cropRefs = $crops | ForEach-Object { "$NS`:plant/wild_crop/${_}_patch" }
Save-Json 'data/tfc/tags/worldgen/placed_feature/feature/crops.json' ([ordered]@{
    replace = $false
    values  = @($cropRefs)
})
Write-Host "[1] 野生作物注入: $($crops.Count) 项"

# ---- 2. 浆果灌木 ----
$bDir = Join-Path $res "data\$NS\worldgen\placed_feature\plant"
$bushes = Get-ChildItem $bDir -Filter '*_bush_patch.json' |
    ForEach-Object { $_.Name -replace '_patch\.json$', '' } | Sort-Object
$bushRefs = $bushes | ForEach-Object { "$NS`:plant/${_}_patch" }
Save-Json 'data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json' ([ordered]@{
    replace = $false
    values  = @($bushRefs)
    remove = @('tfc:plant/strawberry_bush_patch')
})
Write-Host "[2] 浆果灌木注入: $($bushes.Count) 项"

# ---- 2b. 果树 ----
# TFC 的果树走的是另一个标签：worldgen/placed_feature/feature/fruit_trees.json
# （值形如 tfc:plant/cherry，**没有** _patch 后缀 —— 与野生作物/灌木不同）。
$tDir = Join-Path $res "data\$NS\worldgen\placed_feature\plant"
$trees = Get-ChildItem $tDir -Filter '*_tree.json' -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Name -replace '_tree\.json$', '' } | Where-Object { $_ -ne (Read-CocoaPolicy).legacy_tree } | Sort-Object
$treeRefs = $trees | ForEach-Object { "$NS`:plant/${_}_tree" }
Save-Json 'data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json' ([ordered]@{
    replace = $false
    values  = @($treeRefs)
})
Write-Host "[2b] 果树注入: $($trees.Count) 项"

# ---- 3. 自检：标签引用的特征文件必须真实存在 ----
$bad = @()
foreach ($ref in ($cropRefs + $bushRefs + $treeRefs)) {
    $rel = ($ref -replace "^$NS`:", '') + '.json'
    $f = Join-Path (Join-Path $res "data\$NS\worldgen\placed_feature") $rel
    if (-not (Test-Path $f)) { $bad += $ref }
}
if ($bad.Count -gt 0) {
    Write-Host "!! 标签引用了不存在的特征: $($bad -join ', ')" -ForegroundColor Red
    throw "野生注入自检失败"
}
Write-Host "[3] 自检通过：$($cropRefs.Count + $bushRefs.Count + $treeRefs.Count) 个引用全部存在" -ForegroundColor Green
