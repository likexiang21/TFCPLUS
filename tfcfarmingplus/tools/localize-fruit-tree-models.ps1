# localize-fruit-tree-models.ps1 —— 果树的贴图本地化。
#
# 与 localize-textures.ps1（作物那一批）的区别：果树的模型**不是直接引用贴图**，
# 而是 `{"parent": "tfc:block/plant/cherry_leaves"}` 这样**继承 TFC 的模型**，
# 贴图写在 TFC 的模型里。所以不能只换字符串，要**重写模型**：
#   · 树叶：TFC 的 `<donor>_leaves` 实际是 {"parent":"block/leaves","textures":{"all":"tfc:block/fruit_tree/<donor>_leaves"}}
#           → 我们自己写 {"parent":"block/leaves","textures":{"all":"<ns>:block/fruit_tree/<n>_leaves"}}
#   · 树苗：同理，父模型是 block/cross，贴图键是 cross
#   · 枝干：几何父模型 tfc:block/plant/branch_core (side/up/down) 是**纯几何**，保留；
#           只把 textures.bark 换成我们自己的贴图。
#
# 贴图本身由 TintTextures 从 TFC 的 `tfc:block/fruit_tree/<donor>_*.png` 变换而来，
# 每种树 6 张（leaves / dry_leaves / flowering_leaves / fruiting_leaves / sapling / branch）。
#
# 幂等：重复运行只是重写同样的内容。

$ErrorActionPreference = 'Stop'

$root = Join-Path $PSScriptRoot '..\src\main\resources'
$NS   = 'tfcfarmingplus'
$java = 'C:\Users\Lenovo\.gradle\jdks\eclipse_adoptium-21-amd64-windows.2\bin\java.exe'
$tfcTexRoot = Join-Path $env:TEMP 'tfcx\assets\tfc\textures\block'
$outTexRoot = Join-Path $root "assets/$NS/textures/block"
$plantDir   = Join-Path $root "assets/$NS/models/block/plant"
$utf8 = New-Object System.Text.UTF8Encoding($false)

$manifestPath = Join-Path $PSScriptRoot 'contracts/fruit-trees-manifest.json'
if (-not (Test-Path $manifestPath)) { Write-Host "✘ 找不到 $manifestPath（先跑 gen-fruit-trees.ps1）"; exit 1 }
$trees = @((Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json).trees)

$jobs = New-Object System.Collections.ArrayList
$written = 0

foreach ($t in $trees) {
    $n     = $t.name
    $donor = $t.donor

    # ① 树叶的四个物候：父模型 block/leaves，贴图键 all
    foreach ($phase in @('leaves', 'dry_leaves', 'flowering_leaves', 'fruiting_leaves')) {
        $body = "{`"parent`":`"block/leaves`",`"textures`":{`"all`":`"${NS}:block/fruit_tree/${n}_${phase}`"}}"
        [System.IO.File]::WriteAllText((Join-Path $plantDir "${n}_${phase}.json"), $body, $utf8)
        [void]$jobs.Add([ordered]@{ src = "fruit_tree/${donor}_${phase}.png"; dst = "fruit_tree/${n}_${phase}.png"; seed = $n })
        $written++
    }

    # ② 树苗 1..4：**必须保留 TFC 的「嫁接株数」表达**
    #    变体不体现在贴图上，而体现在**父模型**：TFC 的 sapling_1 = block/cross（1 组交叉），
    #    sapling_2/3/4 = tfc:block/plant/cross_2/3/4（2/3/4 组交叉小苗，见 TFC 的
    #    assets/tfc/models/block/plant/cross_{2,3,4}.json）。
    #    ⚠️ 早期这里把 4 个变体**统一写成 block/cross**，saplings=1..4 渲染完全相同 ——
    #       树苗永远只有一株，玩家看不出「嫁接过几株」（用户报的问题）。已修。
    $saplingParents = [ordered]@{ 1 = 'block/cross'; 2 = 'tfc:block/plant/cross_2'
                                  3 = 'tfc:block/plant/cross_3'; 4 = 'tfc:block/plant/cross_4' }
    foreach ($i in 1..4) {
        $body = "{`"parent`":`"$($saplingParents[$i])`",`"textures`":{`"cross`":`"${NS}:block/fruit_tree/${n}_sapling`"}}"
        [System.IO.File]::WriteAllText((Join-Path $plantDir "${n}_sapling_${i}.json"), $body, $utf8)
        $written++
    }
    [void]$jobs.Add([ordered]@{ src = "fruit_tree/${donor}_sapling.png"; dst = "fruit_tree/${n}_sapling.png"; seed = $n })

    # ③ 枝干四件套：几何改用**我们自己的** trunk_*（不再借 TFC 的 branch_*）。
    #    这是「重新设计树的形状」的落点：截面 6×6 → 8×8，树干更粗壮、更像树干，
    #    同时为树干果实（TrunkFruitBlock）留出了可附着的侧面。
    #    ⚠️ 几何是 4 个**共享**文件（models/block/plant/trunk_{core,side,up,down}.json），
    #       33 种树只靠 textures.bark 区分 —— 与 TFC 自己的做法一致。
    #    ⚠️ 这里必须跟着改：否则跑一次本脚本就会把 parent 退回 tfc:block/plant/branch_*（§32.11.3 的顺序依赖）。
    foreach ($part in @('core', 'side', 'up', 'down')) {
        $body = "{`"parent`":`"${NS}:block/plant/trunk_${part}`",`"textures`":{`"bark`":`"${NS}:block/fruit_tree/${n}_branch`"}}"
        [System.IO.File]::WriteAllText((Join-Path $plantDir "${n}_branch_${part}.json"), $body, $utf8)
        $written++
    }
    # ⚠️ 树皮**不按各自 donor 借**：TFC 的 cherry_branch 本身就是深紫（实测 R=54 G=33 B=44），
    #    梨树等借了它，整根树干都会变紫（实测 pear_branch R=59 G=43 B=61）——
    #    而 TFC 的其它果树树皮大都是棕色（red_apple 109/85/50、lemon 122/97/61 …）。
    #    改为从 TFC 的**棕色系**树皮里按物种名轮换：保证都是木质色，又保留物种间区分度。
    $barkDonors = @('red_apple', 'lemon', 'orange', 'green_apple', 'banana')
    $barkPick = $barkDonors[[Math]::Abs($n.GetHashCode()) % $barkDonors.Count]
    [void]$jobs.Add([ordered]@{ src = "fruit_tree/${barkPick}_branch.png"; dst = "fruit_tree/${n}_branch.png"; seed = $n })
}

Write-Host "  重写果树模型: $written 个（$($trees.Count) 种树）；待生成贴图: $($jobs.Count) 个"

$jobFile = Join-Path $PSScriptRoot 'data/texture-jobs-trees.json'
[System.IO.File]::WriteAllText($jobFile,
    (([ordered]@{ jobs = $jobs }) | ConvertTo-Json -Depth 5 -Compress), $utf8)

& $java (Join-Path $PSScriptRoot 'java/TintTextures.java') $tfcTexRoot $outTexRoot $jobFile
if ($LASTEXITCODE -ne 0) { Write-Host "✘ 贴图生成失败"; exit 1 }
