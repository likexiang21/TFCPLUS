# ============================================================
# audit-texture-uniqueness.ps1 —— 贴图「是否有辨识度」的机械化核查
# ============================================================
# 判据（AGENTS.md §5.56.4 的教训：自查清单若是自己列的，天然漏掉没想到的东西）：
#   「贴图能反映物种」这件事不能只靠肉眼看几张，要**逐目录统计 MD5 唯一率**：
#     唯一率 = 100%  → 每个物种的贴图都不同（合格）；
#     出现重复        → 说明生成器的 seed 没生效或参数撞车（不合格，打印具体文件名）。
# 用法： & .\audit-texture-uniqueness.ps1            # 只统计
#        & .\audit-texture-uniqueness.ps1 -FailOnDup  # 有重复就 exit 1（可挂进 CI）
# ============================================================
param([switch]$FailOnDup)
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources\assets\tfcfarmingplus\textures'
$dirs = @(
    'block/fruit_tree',
    'block/crop',
    'block/plant',
    'item/food',
    'item/seeds'
)
$dups = 0
foreach ($d in $dirs) {
    $full = Join-Path $root $d
    if (-not (Test-Path $full)) { continue }
    $files = Get-ChildItem $full -File -Filter '*.png'
    if ($files.Count -eq 0) { continue }
    $groups = $files | Group-Object { (Get-FileHash $_.FullName -Algorithm MD5).Hash }
    $uniq = $groups.Count
    $dupGroups = $groups | Where-Object { $_.Count -gt 1 }
    $flag = if ($dupGroups) { 'DUP!' } else { 'ok' }
    Write-Output ('{0,-20} {1,5} files  {2,5} unique  [{3}]' -f $d, $files.Count, $uniq, $flag)
    foreach ($g in $dupGroups) {
        $dups++
        Write-Output ('    DUP: ' + (($g.Group | ForEach-Object { $_.Name }) -join ', '))
    }
}
if ($dups -gt 0) {
    Write-Output ('重复组: ' + $dups)
    if ($FailOnDup) { exit 1 }
} else {
    Write-Output '未发现重复贴图（每个物种的贴图都不同）'
}