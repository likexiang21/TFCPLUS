# ============================================================
# 补生成野生作物的「单株 placed_feature」
# ------------------------------------------------------------
# 背景（实测于 2026-09-19 的第二次进游戏验证）：
#   java.lang.IllegalStateException: Unbound values in registry
#     ResourceKey[minecraft:root / minecraft:worldgen/placed_feature]:
#     [tfcfarmingplus:plant/wild_crop/broccoli, tfcfarmingplus:plant/wild_crop/cauliflower, ...]
#
# 根因：minecraft:random_patch 的 config 里 `feature` 字段类型是
#   **Holder<PlacedFeature>（placed_feature）**，而不是 ConfiguredFeature。
#   TFC 因此为每个野生作物准备了两层 placed_feature：
#     placed_feature/plant/wild_crop/<name>.json        单株（heightmap + 两个 predicate）
#     placed_feature/plant/wild_crop/<name>_patch.json  成片（rarity_filter + in_square + tfc:climate）
#   其中 configured_feature/<name>_patch.json 的 random_patch.config.feature
#   指向的正是「单株 placed_feature」。
#   本模组此前只生成了 _patch 那一层，于是被引用者不存在 → 世界加载崩溃。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
}

$crops = @('spinach','lettuce','celery','kale','napa_cabbage','mustard_greens','broccoli','cauliflower')

foreach ($n in $crops) {
    # 结构照抄 TFC 的 data/tfc/worldgen/placed_feature/plant/wild_crop/cabbage.json
    Save-Json "data/tfcfarmingplus/worldgen/placed_feature/plant/wild_crop/${n}.json" ([ordered]@{
        feature   = "tfcfarmingplus:plant/wild_crop/$n"
        placement = @(
            [ordered]@{ type = 'minecraft:heightmap'; heightmap = 'WORLD_SURFACE_WG' },
            [ordered]@{ type = 'minecraft:block_predicate_filter'; predicate = [ordered]@{ type = 'tfc:replaceable' } },
            [ordered]@{ type = 'minecraft:block_predicate_filter'
                        predicate = [ordered]@{ type = 'would_survive'; state = [ordered]@{ Name = "tfcfarmingplus:wild_crop/$n" } } }
        )
    })
}

Write-Host "已生成单株 placed_feature: $($crops.Count) 个（tfcfarmingplus:plant/wild_crop/<name>）"

# 校验：random_patch 的 feature 引用必须能在 placed_feature 中找到
$bad = @()
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'data/tfcfarmingplus/worldgen/configured_feature') -Filter *.json) {
    $j = $ser.DeserializeObject([System.IO.File]::ReadAllText($f.FullName, $utf8))
    if ($j['type'] -ne 'minecraft:random_patch') { continue }
    $ref = [string]$j['config']['feature']
    $rel = $ref -replace '^tfcfarmingplus:', ''
    if (-not (Test-Path (Join-Path $root "data/tfcfarmingplus/worldgen/placed_feature/$rel.json"))) {
        $bad += "$($f.Name) -> $ref"
    }
}
if ($bad.Count -gt 0) {
    Write-Host "仍有 random_patch 引用了不存在的 placed_feature:"
    $bad | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "校验通过: 所有 random_patch 的 feature 引用都指向存在的 placed_feature"
