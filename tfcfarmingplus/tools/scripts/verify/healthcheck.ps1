# ============================================================
# healthcheck.ps1 —— 一条命令跑完整套资源健康检查
# ============================================================
# 由来：这几轮陆续加了 verify.ps1（交叉引用）、audit-texture-uniqueness.ps1（唯一率）、
#       audit-texture-content.ps1（空图），加上「jar 是否与产物一致」的判据（AGENTS.md 硬约束 3：
#       曾把后台构建的残缺 jar 拿去启动游戏，报一片 FileNotFoundException 被误判成模型 bug）。
# 本脚本把它们串成一次检查，输出单一结论，方便每轮收尾跑一遍。
# 用法： & .\healthcheck.ps1
# ============================================================
$ErrorActionPreference = 'Stop'
$proj = Split-Path $env:TFC_TOOLS_ROOT -Parent
$version = Split-Path (Split-Path $proj -Parent) -Parent
$fail = 0

Write-Output '=== [1/4] 资源交叉引用（verify.ps1） ==='
$v = & (Join-Path $env:TFC_TOOLS_ROOT 'verify.ps1') 2>&1
$v | Select-Object -Last 6 | ForEach-Object { Write-Output $_ }
if (($v | Select-String -Pattern '结果: 发现 |NOT FOUND' | Measure-Object).Count -gt 0) { $fail++; Write-Output '  ✘ 交叉引用有问题' }

Write-Output ''
Write-Output '=== [2/4] 贴图唯一率 ==='
$u = & (Join-Path $env:TFC_TOOLS_ROOT 'audit-texture-uniqueness.ps1') 2>&1
$u | ForEach-Object { Write-Output $_ }

Write-Output ''
Write-Output '=== [3/4] 贴图内容（空图体检） ==='
$c = & (Join-Path $env:TFC_TOOLS_ROOT 'audit-texture-content.ps1') 2>&1
$c | ForEach-Object { Write-Output $_ }
# Keep the raw scan above visible. Only reviewed, hash-pinned, unreferenced legacy
# files may be downgraded; any new empty texture or failed contract still blocks.
$review = & (Join-Path $env:TFC_TOOLS_ROOT 'audit-seedling-texture-contracts.ps1') -PassThru
if ($review.Findings.Count -gt 0) {
    $fail++
    $review.Findings | ForEach-Object { Write-Output "  [FAIL] $_" }
}
$rawEmpty = @($c | Where-Object { $_ -match '^\s*EMPTY: ' } | ForEach-Object { ($_ -replace '^\s*EMPTY: ','').Trim().Replace('\','/') })
$emptyLine = $c | Where-Object { $_ -like 'empty (0 opaque px): *' } | Select-Object -First 1
if (-not $emptyLine -or [int](($emptyLine -split ':')[-1].Trim()) -ne $rawEmpty.Count -or @($c|Where-Object{$_ -like 'ERROR *'}).Count -gt 0) {
    $fail++; Write-Output '  [FAIL] Raw texture scan failed or its empty-file list is incomplete'
}
$blockingEmpty = @($rawEmpty | Where-Object { $_ -notin $review.ReviewedUnusedEmptyPaths })
$historicalEmpty = @($rawEmpty | Where-Object { $_ -in $review.ReviewedUnusedEmptyPaths })
foreach ($file in $historicalEmpty) { Write-Output "  [REVIEWED LEGACY] $file (retained; no declared A/B source consumer)" }
if ($blockingEmpty.Count -gt 0) { $fail++; Write-Output "  [FAIL] Unreviewed/referenced empty textures: $($blockingEmpty.Count)" }
else { Write-Output '  [OK] No blocking empty textures in the checked source scope; appearance and external packs remain unverified' }

Write-Output ''
Write-Output '=== [4/4] jar 一致性（build/libs vs mods/） ==='
$built = Get-ChildItem (Join-Path $proj 'build\libs') -File -Filter '*.jar' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$installed = Get-ChildItem (Join-Path $version 'mods') -File -Filter 'TFCFarmingPlus*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $built) { $fail++; Write-Output '  ✘ build/libs 里没有 jar（尚未构建）' }
elseif (-not $installed) { $fail++; Write-Output ('  ✘ mods/ 里没有已安装 jar（build 产物 ' + $built.Length + ' 字节）') }
else {
    $builtHash = (Get-FileHash -LiteralPath $built.FullName -Algorithm SHA256).Hash
    $installedHash = (Get-FileHash -LiteralPath $installed.FullName -Algorithm SHA256).Hash
    $same = ($builtHash -eq $installedHash)
    Write-Output ('  built    : ' + $built.Name + '  ' + $built.Length + ' bytes  ' + $built.LastWriteTime)
    Write-Output ('  installed: ' + $installed.Name + '  ' + $installed.Length + ' bytes  ' + $installed.LastWriteTime)
    Write-Output ('  built SHA256    : ' + $builtHash)
    Write-Output ('  installed SHA256: ' + $installedHash)
    if ($same) { Write-Output '  ✔ SHA-256 一致' } else { $fail++; Write-Output '  ✘ SHA-256 不一致 —— 游戏可能读到旧/残缺 jar（AGENTS.md 硬约束 3）' }
}

Write-Output ''
if ($fail -eq 0) { Write-Output '静态资源健康检查：通过；历史闲置空图保留，外观与实机待验' } else { Write-Output ('健康检查：' + $fail + ' 项需要处理'); exit 1 }
