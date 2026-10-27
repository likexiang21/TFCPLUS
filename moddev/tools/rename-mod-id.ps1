# ============================================================
# modId 全局改名：tfcflora → tfcfarmingplus
# ------------------------------------------------------------
# 替换顺序很重要（先长后短，避免把类名前缀改坏）：
#   1. com.example.tfcflora        → com.example.tfcfarmingplus   （包名）
#   2. com/example/tfcflora        → com/example/tfcfarmingplus   （路径字符串）
#   3. TFCFloraClient              → TFCFarmingPlusClient         （类名，长的先来）
#   4. TFCFlora                    → TFCFarmingPlus
#   5. tfcflora                    → tfcfarmingplus               （剩余 id / 路径 / lang 前缀）
# 之后重命名：Java 包目录、resources 下的 data/<id> 与 assets/<id>、工程根目录。
# ============================================================
param(
    [string]$OldId = 'tfcflora',
    [string]$NewId = 'tfcfarmingplus'
)
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Bom   = New-Object System.Text.UTF8Encoding($true)

$moddev = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev"
$projRoot = Join-Path $moddev $OldId
if (-not (Test-Path $projRoot)) { throw "找不到工程目录: $projRoot" }

$oldPkg = "com.example.$OldId"
$newPkg = "com.example.$NewId"
$oldPkgPath = "com/example/$OldId"
$newPkgPath = "com/example/$NewId"

$rules = @(
    @($oldPkg, $newPkg),
    @($oldPkgPath, $newPkgPath),
    @('TFCFloraClient', 'TFCFarmingPlusClient'),
    @('TFCFlora', 'TFCFarmingPlus'),
    @($OldId, $NewId)
)

# ---------- 1. 文本替换 ----------
$exts = @('.java', '.json', '.kts', '.gradle', '.properties', '.ps1', '.toml', '.txt')
$changed = 0; $scanned = 0
foreach ($f in (Get-ChildItem -Recurse -File -Path $projRoot)) {
    if ($exts -notcontains $f.Extension.ToLower()) { continue }
    if ($f.FullName -match '\\build\\') { continue }   # 跳过构建产物
    $scanned++
    $text = [System.IO.File]::ReadAllText($f.FullName, $utf8NoBom)
    $orig = $text
    foreach ($r in $rules) { $text = $text.Replace($r[0], $r[1]) }
    if ($text -ne $orig) {
        # .ps1 必须保持 BOM（PS 5.1 否则按 GBK 解码中文）
        $enc = if ($f.Extension -ieq '.ps1') { $utf8Bom } else { $utf8NoBom }
        [System.IO.File]::WriteAllText($f.FullName, $text, $enc)
        $changed++
    }
}
Write-Host "[1] 文本替换: 扫描 $scanned 个文件, 改写 $changed 个"

# ---------- 2. Java 包目录重命名 ----------
$oldJavaDir = Join-Path $projRoot "src\main\java\$oldPkgPath"
$newJavaDir = Join-Path $projRoot "src\main\java\$newPkgPath"
if (Test-Path $oldJavaDir) {
    Move-Item $oldJavaDir $newJavaDir
    Write-Host "[2] Java 包目录: $oldPkgPath -> $newPkgPath"
}
# 类文件重命名（类名已改，文件名要跟上）
foreach ($pair in @(@('TFCFloraClient.java','TFCFarmingPlusClient.java'), @('TFCFlora.java','TFCFarmingPlus.java'))) {
    $src = Join-Path $newJavaDir $pair[0]
    if (Test-Path $src) {
        $dst = Join-Path (Split-Path $src -Parent) $pair[1]
        Rename-Item $src $pair[1]
        Write-Host "    类文件: $($pair[0]) -> $($pair[1])"
    }
}
# client 子目录里的也处理
Get-ChildItem $newJavaDir -Recurse -Filter 'TFCFlora*.java' | ForEach-Object {
    $newName = $_.Name.Replace('TFCFloraClient', 'TFCFarmingPlusClient').Replace('TFCFlora', 'TFCFarmingPlus')
    if ($newName -ne $_.Name) { Rename-Item $_.FullName $newName; Write-Host "    类文件: $($_.Name) -> $newName" }
}

# ---------- 3. resources 命名空间目录重命名 ----------
foreach ($sub in @('data', 'assets')) {
    $oldDir = Join-Path $projRoot "src\main\resources\$sub\$OldId"
    if (Test-Path $oldDir) {
        Rename-Item $oldDir $NewId
        Write-Host "[3] 资源命名空间: $sub/$OldId -> $sub/$NewId"
    }
}

# ---------- 4. 工程根目录重命名 ----------
$newProjRoot = Join-Path $moddev $NewId
if (Test-Path $newProjRoot) { throw "目标工程目录已存在: $newProjRoot" }
Rename-Item $projRoot $NewId
Write-Host "[4] 工程目录: $OldId -> $NewId"

# ---------- 5. 验证无残留 ----------
$leftover = @()
foreach ($f in (Get-ChildItem -Recurse -File -Path $newProjRoot)) {
    if ($f.FullName -match '\\build\\') { continue }
    if ($exts -notcontains $f.Extension.ToLower()) { continue }
    $t = [System.IO.File]::ReadAllText($f.FullName, $utf8NoBom)
    if ($t.Contains($OldId) -or $t.Contains('TFCFlora')) {
        $leftover += $f.FullName.Substring($newProjRoot.Length + 1)
    }
}
if ($leftover.Count -eq 0) {
    Write-Host "[5] 验证: 无 '$OldId' / 'TFCFlora' 残留"
} else {
    Write-Host "[5] 仍有残留（请检查）:"
    $leftover | Select-Object -First 20 | ForEach-Object { Write-Host "    $_" }
    exit 1
}
Write-Host "完成。新工程路径: $newProjRoot"
