# ============================================================
# 补生成批次 1（10 种浆果）缺失的「食物物品模型」
# ------------------------------------------------------------
# 背景：批次 1 只生成了 blockstates / 方块物品模型 / loot / climate / food / lang，
# 漏掉了 models/item/food/<name>.json，导致 10 个浆果食物在游戏里是紫黑格，
# 日志报 "Unable to load model: 'tfcfarmingplus:item/food/<name>'"（实测 10 条）。
#
# 贴图策略与其它批次一致：直接跨命名空间借用 TFC 已有的浆果贴图作为占位，
# 将来换成自有美术时只需改 layer0 一行。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mod_rebuild\tfcfarmingplus\src\main\resources"
$tfcJar = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar"
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 浆果 → 借用的 TFC 贴图（每种都不同）
$map = [ordered]@{
    'lingonberry'  = 'cranberry'
    'bilberry'     = 'blueberry'
    'crowberry'    = 'wintergreen_berry'
    'bearberry'    = 'raspberry'
    'blackcurrant' = 'elderberry'
    'redcurrant'   = 'gooseberry'
    'haskap'       = 'blackberry'
    'goji'         = 'strawberry'
    'serviceberry' = 'bunchberry'
    'aronia'       = 'cloudberry'
    # 批次 4：茶树 / 咖啡树的产物（同样借用 TFC 贴图占位）
    'tea_leaf'     = 'dried_kelp'
    'coffee_bean'  = 'soybean'
}

# 先确认借用的贴图在 TFC 里确实存在，避免又生成一批紫黑格
$z = [System.IO.Compression.ZipFile]::OpenRead($tfcJar)
$names = New-Object System.Collections.Generic.HashSet[string]
foreach ($e in $z.Entries) { [void]$names.Add($e.FullName) }
$z.Dispose()

$missing = @()
foreach ($k in $map.Keys) {
    $p = "assets/tfc/textures/item/food/$($map[$k]).png"
    if (-not $names.Contains($p)) { $missing += $p }
}
if ($missing.Count -gt 0) {
    Write-Host "借用的 TFC 贴图不存在，已中止："
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

$count = 0
foreach ($k in $map.Keys) {
    $rel  = "assets/tfcfarmingplus/models/item/food/$k.json"
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $json = [ordered]@{
        parent   = 'item/generated'
        textures = [ordered]@{ layer0 = "tfc:item/food/$($map[$k])" }
    }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($json), $utf8)
    $count++
}
Write-Host "已生成批次 1 食物物品模型: $count 个（贴图借用 TFC 浆果占位）"
$map.Keys | ForEach-Object { Write-Host "  food/$_  ->  tfc:item/food/$($map[$_])" }
