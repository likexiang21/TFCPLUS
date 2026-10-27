# check-boundaries.ps1 -- B (tfcagricultureplus) boundary + license gate
# 126 plan section 1.7 (six dependency red lines) + section 19.4 (license compliance)
# ASCII-only comments: this file is executed by Windows PowerShell 5.1 (GBK console).

$ErrorActionPreference = 'Stop'
$B = Split-Path $PSScriptRoot -Parent
$A = Join-Path (Split-Path $B -Parent) 'tfcfarmingplus'
$fail = 0

Write-Host "=== B boundary gate ==="
Write-Host "B = $B"
Write-Host "A = $A"
Write-Host ""

# ---- Red line 1: A must not import B/C/D packages ----
$hit = Select-String -Path (Join-Path $A 'src\main\java\com\example\tfcfarmingplus\*\*.java') `
                     -Pattern 'expansion|husbandry' -ErrorAction SilentlyContinue
if ($hit) {
    $fail++
    Write-Host "[FAIL] red line 1: A references B:"
    $hit | ForEach-Object { Write-Host ("       " + $_.Path + ":" + $_.LineNumber) }
}

# ---- Red line 2: B must not write into A's namespace ----
$resRoot = Join-Path $B 'src\main\resources'
if (Test-Path $resRoot) {
    $hit = Get-ChildItem $resRoot -Recurse -File |
           Where-Object { $_.FullName -match '\\assets\\tfcfarmingplus\\' -or $_.FullName -match '\\data\\tfcfarmingplus\\' }
    if ($hit) {
        $fail++
        Write-Host "[FAIL] red line 2: B writes into A namespace:"
        $hit | ForEach-Object { Write-Host ("       " + $_.FullName) }
    }
}

# ---- Red line 3: B mixins must not target A classes (match TARGET class name, NOT package name) ----
$mixins = Get-ChildItem $B -Recurse -Filter '*.mixins.json' -ErrorAction SilentlyContinue
foreach ($m in $mixins) {
    $txt = Get-Content $m.FullName -Raw
    if ($txt -match 'tfcfarmingplus\.(common|client|expansion)\.') {
        # note: B's own package also contains this substring, so only flag real targets
        Write-Host ("[INFO] mixin config " + $m.Name + " mentions the A/B package prefix -- verify by TARGET class, not package")
    }
    if ($txt -match '(?i)MyWildCrops|MyCrops|MyBushes|MyBlocks|MyItems') {
        $fail++
        Write-Host ("[FAIL] red line 3: mixin targets an A class: " + $m.Name)
    }
}

# ---- Red line 7: tags written into neighbour namespaces must be replace=false ----
$dataRoot = Join-Path $B 'src\main\resources\data'
if (Test-Path $dataRoot) {
    $tags = Get-ChildItem $dataRoot -Recurse -File |
            Where-Object { $_.FullName -match '\\tags\\' -and $_.FullName -notmatch '\\tfcagricultureplus\\' }
    foreach ($t in $tags) {
        if ((Get-Content $t.FullName -Raw) -match '"replace"\s*:\s*true') {
            $fail++
            Write-Host ("[FAIL] red line 7 (catastrophic): replace:true in " + $t.FullName)
        }
    }
}

# ---- Section 19.4: license compliance ----
$restricted = 'extradelight|extradelighttfc|dragn|aquaculture|cuisine|untamedwilds|survivorsdelight|firmalifeenhance|butchery'

# (1) restricted namespaces must not appear in our resources
if (Test-Path $resRoot) {
    $hit = Get-ChildItem $resRoot -Recurse -File |
           Where-Object { $_.FullName -match "\\(assets|data)\\($restricted)\\" }
    if ($hit) {
        $fail++
        Write-Host "[FAIL] license: restricted mod namespace found in resources:"
        $hit | ForEach-Object { Write-Host ("       " + $_.FullName) }
    }
}

# (2) mods.toml must not depend on restricted mods
$toml = Join-Path $B 'src\main\templates\META-INF\neoforge.mods.toml'
if (Test-Path $toml) {
    $txt = Get-Content $toml -Raw
    foreach ($m in [regex]::Matches($txt, 'modId\s*=\s*"([^"]+)"')) {
        $id = $m.Groups[1].Value
        if ($id -match "^($restricted)$") {
            $fail++
            Write-Host ("[FAIL] license: mods.toml depends on restricted mod: " + $id)
        }
    }
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "[OK] all boundary + license checks passed"
    exit 0
} else {
    Write-Host ("[FAIL] " + $fail + " violation(s) -- fix before building")
    exit 1
}
