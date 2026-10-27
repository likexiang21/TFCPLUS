param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath '.').Path
$manifestPath = Join-Path $root 'mod_rebuild\docs\audit\cleanup-execution-20261028.csv'
$auditKeep = @(
    'D1-docs-and-plans.md',
    'D2-resources-and-protocols.md',
    'D3-java-tools-contracts.md',
    'README.md',
    'cleanup-candidates.csv',
    'cleanup-execution-20261028.csv',
    'cleanup_execute_20261028.ps1',
    'code_similarity.py',
    'code-similarity.txt'
)

function Add-Target {
    param([string]$RelativePath, [string]$Kind, [string]$Reason)
    $full = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $full)) { return }
    $item = Get-Item -LiteralPath $full -Force
    $files = if ($item.PSIsContainer) {
        @(Get-ChildItem -LiteralPath $full -Recurse -File -Force -ErrorAction SilentlyContinue)
    } else {
        @($item)
    }
    $bytes = ($files | Measure-Object -Property Length -Sum).Sum
    if ($null -eq $bytes) { $bytes = 0 }
    $script:targets.Add([pscustomobject]@{
        Path = $full
        RelativePath = $RelativePath
        Kind = $Kind
        Reason = $Reason
        Files = $files.Count
        Bytes = [int64]$bytes
    })
}

$targets = New-Object 'System.Collections.Generic.List[object]'

# --- 1. Generated texture previews / analysis outputs (largest, non-source) ---
Add-Target '.probe\texture-design\px' 'texture-preview' 'generated 2D/3D previews; not source or branch artifact'
Add-Target '.probe\texture-design\out' 'texture-preview' 'generated render outputs'
Add-Target '.probe\skill-review' 'review-output' 'review artifacts'
Add-Target '.probe\gen-crops-ab' 'generated-output' 'old generated output'
Add-Target '.probe\ingame-verify-20260923' 'old-evidence' 'historical in-game evidence'
Add-Target '.probe\texture-design\_w2assets-old' 'old-output' 'old generated assets'
Add-Target '.probe\texture-design\removed-dead-2026' 'old-output' 'already-removed dead resources'

# Historical small backups; preserve the two AGENTS-protected source snapshots.
Get-ChildItem -LiteralPath (Join-Path $root '.probe\texture-design') -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(backup|bak)-' } |
    Where-Object { $_.Name -notin @('bak-src-20260927', 'bak-lab-20260927') } |
    ForEach-Object { Add-Target ('.probe\texture-design\' + $_.Name) 'old-backup' 'historical texture backup' }

# --- 2. Old build/caches and unrelated demo ---
foreach ($dir in @(
    'de_moddev\tfcfarmingplus\build',
    'de_moddev\tfcfarmingplus\.gradle',
    'de_moddev\tfcagricultureplus\build',
    'de_moddev\tfcagricultureplus\.gradle',
    'de_moddev\demo-mymod',
    'de_moddev\backups',
    'de_moddev\inventory',
    'de_moddev\_archive'
)) {
    Add-Target $dir 'old-build-or-backup' 'old build/cache/demo/backup, not branch source'
}

# --- 3. Raw audit evidence; keep the D1-D3/276/277/278 reports and cleanup manifest. ---
$auditDir = Join-Path $root 'mod_rebuild\docs\audit'
if (Test-Path -LiteralPath $auditDir) {
    Get-ChildItem -LiteralPath $auditDir -File -Force |
        Where-Object { $_.Name -notin $auditKeep } |
        ForEach-Object { Add-Target ('mod_rebuild\docs\audit\' + $_.Name) 'audit-raw-evidence' 'raw CSV/JSON/scripts/logs after report finalization' }
}

# --- 4. Dead tool data / helpers / historical archive ---
Add-Target 'mod_rebuild\tfcfarmingplus\tools\_tags-baseline' 'dead-tool-data' 'zero references tree-wide'
Add-Target 'mod_rebuild\tfcfarmingplus\tools\archive' 'historical-tool' 'historical generator; not active'
foreach ($name in @(
    'texture-jobs-bushes.json',
    'texture-jobs-final.json',
    'texture-jobs-rosefix.json',
    'texture-jobs-rosette.json',
    'texture-jobs-trunk.json',
    'fruit-texture-jobs-rosette.json'
)) {
    Add-Target (Join-Path 'mod_rebuild\tfcfarmingplus\tools\data' $name) 'dead-tool-data' 'zero references (verified by grep)'
}
foreach ($name in @('TextureAverage.java', 'TextureStats.java')) {
    Add-Target (Join-Path 'mod_rebuild\tfcfarmingplus\tools\java' $name) 'dead-helper' 'zero script references'
}

# Preserve a few final reference sheets before deleting the huge preview tree.
$referenceDir = Join-Path $root '.probe\texture-design\reference-redraw'
if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $referenceDir | Out-Null
    $referenceNames = @(
        'AUTHORITATIVE-TFC-ORIGINAL-REFERENCE.png',
        'LEAD-BALL-V5-AGES.png',
        'LEADCHECK-FRUITBLOCKS-FINAL.png',
        'NEW-vs-OLD-3D.png',
        'FEN3D-CMP.png'
    )
    foreach ($name in $referenceNames) {
        $candidate = Get-ChildItem -LiteralPath (Join-Path $root '.probe\texture-design\px') -Recurse -File -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($candidate) { Copy-Item -LiteralPath $candidate.FullName -Destination (Join-Path $referenceDir $name) -Force }
    }
}

# Write pre-execution manifest.
$rows = $targets | Sort-Object Bytes -Descending
$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
Write-Output ('targets=' + $targets.Count + ' files=' + (($targets | Measure-Object Files -Sum).Sum) + ' MB=' + [math]::Round((($targets | Measure-Object Bytes -Sum).Sum / 1MB), 2))

if ($DryRun) { return }

$protected = @(
    '.probe\lab-assets', '.probe\lab-old', '.probe\lab-new',
    '.probe\ref-tfc', '.probe\tfc-crop', '.probe\texture-design\bak-src-20260927',
    '.probe\texture-design\bak-lab-20260927',
    'simplebackups', 'saves', 'mods', 'screenshots',
    'mod_rebuild\src', 'mod_rebuild\artifacts',
    'mod_rebuild\tfcfarmingplus\src', 'mod_rebuild\tfcagricultureplus\src',
    'moddev', 'de_moddev\src-ref', 'de_moddev\jar-extract'
)
foreach ($target in $targets) {
    $resolved = (Resolve-Path -LiteralPath $target.Path).Path
    if (-not $resolved.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete outside workspace: $resolved"
    }
    foreach ($blocked in $protected) {
        $blockedFull = Join-Path $root $blocked
        if ($resolved.Equals($blockedFull, [StringComparison]::OrdinalIgnoreCase) -or $resolved.StartsWith($blockedFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete protected path: $resolved"
        }
    }
}

$failed = New-Object 'System.Collections.Generic.List[string]'
foreach ($target in $targets) {
    try {
        Remove-Item -LiteralPath $target.Path -Recurse -Force -ErrorAction Stop
        Write-Output ('[OK] ' + $target.RelativePath)
    } catch {
        $failed.Add($target.RelativePath + ' :: ' + $_.Exception.Message)
        Write-Output ('[FAIL] ' + $target.RelativePath + ' :: ' + $_.Exception.Message)
    }
}
Write-Output ('deleted=' + ($targets.Count - $failed.Count) + ' failed=' + $failed.Count)
if ($failed.Count -gt 0) { $failed | ForEach-Object { Write-Output $_ }; exit 1 }
exit 0
