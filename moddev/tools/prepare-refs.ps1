# prepare-refs.ps1
# 重新生成 moddev/inventory 下的参考清单文件。
# 用法（在整合包根目录运行）：
#   pwsh -File moddev\tools\prepare-refs.ps1
# 可选参数：
#   -Jar <路径>        额外分析一个 jar（会以其文件名作为清单前缀）
#   -Decompile         反编译 TFC jar（需要 %TEMP%\cfr-0.152.jar，会自动下载）
#
# 说明：本脚本只做「读 jar / 写清单」，不修改任何游戏文件。

param(
    [string[]]$Jar = @(),
    [switch]$Decompile
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 定位整合包根目录（本脚本位于 <root>/moddev/tools/）
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modsDir = Join-Path $root 'mods'
$invDir = Join-Path $root 'moddev\inventory'
New-Item -ItemType Directory -Force -Path $invDir | Out-Null

Write-Host "整合包根目录: $root"
Write-Host "清单输出目录: $invDir"

# 默认分析的目标（jar 文件名 -> 清单前缀）
$targets = [ordered]@{
    'TFC'       = 'TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar'
    'Firmalife' = 'Firmalife-NeoForge-1.21.1-3.0.14.jar'
    'Patchouli' = 'Patchouli-1.21.1-93-NEOFORGE.jar'
    'KubeJSTFC' = 'kubejs_tfc-1.21.1-2.1.0.jar'
}
foreach ($p in $Jar) {
    $targets[[System.IO.Path]::GetFileNameWithoutExtension($p)] = (Split-Path -Leaf $p)
}

# ---------- 1) 类 / 资源 / 条目清单 ----------
foreach ($prefix in $targets.Keys) {
    $jarPath = Join-Path $modsDir $targets[$prefix]
    if (-not (Test-Path $jarPath)) { Write-Warning "跳过（不存在）: $jarPath"; continue }

    Write-Host "分析 $prefix <- $(Split-Path -Leaf $jarPath)"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
    try {
        $names = $zip.Entries | ForEach-Object { $_.FullName }
        $names | Set-Content -Encoding UTF8 (Join-Path $invDir "$prefix.entries.txt")

        $classes = $names |
            Where-Object { $_ -like '*.class' -and $_ -notlike '*/package-info.class' } |
            ForEach-Object { $_ -replace '\.class$', '' -replace '/', '.' }
        $classes | Set-Content -Encoding UTF8 (Join-Path $invDir "$prefix.classes.txt")

        $res = $names | Where-Object { $_ -notlike '*.class' }
        $res | Set-Content -Encoding UTF8 (Join-Path $invDir "$prefix.resources.txt")

        Write-Host ("  条目 {0} / 类 {1} / 资源 {2}" -f $names.Count, $classes.Count, $res.Count)

        # ---------- 2) TFC 专用：方块 id 与物品 id ----------
        if ($prefix -eq 'TFC') {
            $blocks = $res |
                Where-Object { $_ -like 'assets/tfc/blockstates/*.json' } |
                ForEach-Object { 'tfc:' + (($_ -replace '^assets/tfc/blockstates/', '') -replace '\.json$', '') } |
                Sort-Object -Unique
            $items = $res |
                Where-Object { $_ -like 'assets/tfc/models/item/*.json' } |
                ForEach-Object { 'tfc:' + (($_ -replace '^assets/tfc/models/item/', '') -replace '\.json$', '') } |
                Sort-Object -Unique

            $blocks | Set-Content -Encoding UTF8 (Join-Path $invDir 'TFC-block-ids.txt')
            $items | Set-Content -Encoding UTF8 (Join-Path $invDir 'TFC-item-ids.txt')
            Write-Host ("  方块 id {0} / 物品 id {1}" -f $blocks.Count, $items.Count)
        }
    }
    finally { $zip.Dispose() }
}

# ---------- 3) 可选：下载 CFR 并反编译 TFC ----------
if ($Decompile) {
    $cfr = Join-Path $env:TEMP 'cfr-0.152.jar'
    if (-not (Test-Path $cfr)) {
        Write-Host "下载 CFR 0.152 ..."
        Invoke-WebRequest -Uri 'https://repo1.maven.org/maven2/org/benf/cfr/0.152/cfr-0.152.jar' -OutFile $cfr
    }
    $tfcJar = Join-Path $modsDir $targets['TFC']
    $outDir = Join-Path $root 'moddev\src-ref\TFC-decompiled'
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    Write-Host "反编译 TFC（可能需要数分钟）..."
    & java -Xmx3G -jar $cfr $tfcJar --outputdir $outDir --silent true
    $count = (Get-ChildItem $outDir -Recurse -Filter *.java | Measure-Object).Count
    Write-Host "反编译完成，产出 $count 个 .java -> $outDir"
}

Write-Host '完成。'
