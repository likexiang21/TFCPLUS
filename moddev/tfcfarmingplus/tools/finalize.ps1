# ============================================================
# tfcfarmingplus 收尾补丁（幂等，可重复执行）
#   1. lang 补 itemGroup.tfcfarmingplus.main（创造标签页标题）
#   2. 把 8 种野生作物方块物品追加进 TFC 的 tfc:wild_crops 物品标签
#      （该标签 TFC 自身只做数据声明，但保持与其内容一致便于后续兼容）
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

# --- 1. 创造标签页标题 ---
$titles = @{ zh_cn = 'TFC 植物扩展'; en_us = 'TFC Flora' }
foreach ($lang in $titles.Keys) {
    $rel  = "assets/tfcfarmingplus/lang/${lang}.json"
    $path = Join-Path $root $rel
    $dict = $ser.DeserializeObject([System.IO.File]::ReadAllText($path, $utf8))
    $out  = [ordered]@{}
    foreach ($k in $dict.Keys) { if ($k -ne 'itemGroup.tfcfarmingplus.main') { $out[$k] = $dict[$k] } }
    $out['itemGroup.tfcfarmingplus.main'] = $titles[$lang]
    [System.IO.File]::WriteAllText($path, $ser.Serialize($out), $utf8)
    Write-Host "[1] $lang 已补 itemGroup，共 $($out.Keys.Count) 条"
}

# --- 2. tfc:wild_crops 物品标签 ---
$wild = @()
foreach ($n in @('spinach','lettuce','celery','kale','napa_cabbage','mustard_greens','broccoli','cauliflower')) {
    $wild += "tfcfarmingplus:wild_crop/$n"
}
Save-Json 'data/tfc/tags/item/wild_crops.json' ([ordered]@{ replace = $false; values = $wild })
Write-Host "[2] data/tfc/tags/item/wild_crops.json 追加 $($wild.Count) 项"

# --- 3. 校验 ---
$bad = 0
$all = Get-ChildItem -Recurse -File -Path $root -Filter *.json
foreach ($f in $all) {
    try { $null = $ser.DeserializeObject([System.IO.File]::ReadAllText($f.FullName, $utf8)) }
    catch { $bad++; Write-Host "  非法: $($f.FullName)" }
}
Write-Host "[3] JSON 校验: 共 $($all.Count) 个, 非法 $bad 个"
if ($bad -gt 0) { exit 1 }
