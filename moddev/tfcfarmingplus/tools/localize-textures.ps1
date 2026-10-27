# localize-textures.ps1 —— 把「跨命名空间借用 TFC 贴图」改成「引用我们自己的贴图」。
#
# 背景（docs/74 §14.15）：本工程的美术是占位方案 —— 模型直接引用 TFC 的贴图，
# 零 PNG、立即可用；代价是**新内容与原版长得一模一样**，而且**同一个 donor 被多个物种共用**
# （芜菁 / 防风 / 鸦葱 / 生姜 / 姜黄全都借 beet，五者外观完全一致）。
#
# 本脚本做三件事：
#   1. 扫描 models/block/{crop,dead_crop,wild_crop} 下的模型，找出贴图引用里的 `tfc:block/...`；
#   2. 为每处生成一个「本地贴图」任务（源 = TFC 贴图，目标 = 同类目下、以本模组物种名命名）；
#   3. 把模型里的引用改写成本地命名空间，最后调用 TintTextures 生成贴图。
#
# ⚠️ 目标贴图名的推导规则：**模型名去掉 `_age`**
#      crop/ginger_age_3.json        → 贴图 crop/ginger_3.png
#      crop/ginger_age_3_stick.json  → 贴图 crop/ginger_3_stick.png
#      crop/ginger_age_3_bottom.json → 贴图 crop/ginger_3_bottom.png
#      crop/ginger_side.json         → 贴图 crop/ginger_side.png
#      dead_crop/ginger.json         → 贴图 dead_crop/ginger.png
#      wild_crop/ginger.json         → 贴图 wild_crop/ginger.png
#    这样「模型 → 贴图」是纯字符串替换，不需要去猜哪个 donor 的哪一段是后缀。
#
# ⚠️ 只匹配 `"crop": "tfc:block/..."` 这种**贴图字段**，不碰 `"parent"` ——
#    野生作物模型的 parent 是 `tfc:block/wild_crop/crop`（十字草丛父模型），它必须保留。
#
# 幂等：第二次运行时模型里已经没有 `tfc:block/...` 贴图引用了，脚本会原样退出。

$ErrorActionPreference = 'Stop'

$root  = Join-Path $PSScriptRoot '..\src\main\resources'
$NS    = 'tfcfarmingplus'
$java  = 'C:\Users\Lenovo\.gradle\jdks\eclipse_adoptium-21-amd64-windows.2\bin\java.exe'
$tfcTexRoot = Join-Path $env:TEMP 'tfcx\assets\tfc\textures\block'
$outTexRoot = Join-Path $root "assets/$NS/textures/block"
$utf8  = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $tfcTexRoot)) {
    Write-Host "✘ 找不到 TFC 贴图缓存: $tfcTexRoot"
    Write-Host "  先解压 TFC jar 到 %TEMP%\tfcx（见 docs/74 §13.2）"
    exit 1
}

$jobs = New-Object System.Collections.ArrayList
$modelsChanged = 0

foreach ($cat in @('crop', 'dead_crop', 'wild_crop')) {
    $dir = Join-Path $root "assets/$NS/models/block/$cat"
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in Get-ChildItem $dir -Filter *.json -File) {
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        # 只认贴图字段，不碰 parent
        $m = [regex]::Match($text, '"crop"\s*:\s*"tfc:block/([a-z_]+)/([a-z0-9_]+)"')
        if (-not $m.Success) { continue }

        $texName = $f.BaseName -replace '_age_', '_'
        $srcRel  = "$($m.Groups[1].Value)/$($m.Groups[2].Value).png"
        $dstRel  = "$cat/$texName.png"
        $species = ($f.BaseName -split '_age_')[0] -replace '_young$', ''
        # 莲座作物的结果态：模型名是 <n>_age_<i>_fruiting。若与未结果态共用 seed，
        # 两张贴图色调会一模一样，游戏里「中心结果了」在视觉上完全看不出来 —— 换独立 seed。
        if ($f.BaseName -match '_fruiting$') { $species = "${species}_fruiting" }

        [void]$jobs.Add([ordered]@{ src = $srcRel; dst = $dstRel; seed = $species })

        # ⚠️ 必须写 ${NS} —— "$NS:..." 里的 `$NS:` 会被 PowerShell 当成作用域变量（docs/74 §8.2-1）
        $newText = $text.Replace($m.Value, "`"crop`": `"${NS}:block/$cat/$texName`"")
        if ($newText -ne $text) {
            [System.IO.File]::WriteAllText($f.FullName, $newText, $utf8)
            $modelsChanged++
        }
    }
}

Write-Host "  改写模型: $modelsChanged 个；待生成贴图: $($jobs.Count) 个"

if ($jobs.Count -eq 0) {
    Write-Host "  （没有需要处理的引用 —— 可能已经本地化过了）"
    exit 0
}

# 导出任务清单并调用 Java 工具
$jobFile = Join-Path $PSScriptRoot 'texture-jobs.json'
[System.IO.File]::WriteAllText($jobFile,
    (([ordered]@{ jobs = $jobs }) | ConvertTo-Json -Depth 5 -Compress), $utf8)

& $java (Join-Path $PSScriptRoot 'TintTextures.java') $tfcTexRoot $outTexRoot $jobFile
if ($LASTEXITCODE -ne 0) { Write-Host "✘ 贴图生成失败"; exit 1 }
