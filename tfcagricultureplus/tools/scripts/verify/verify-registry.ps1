# verify-registry.ps1 -- check that every blockstate has a Java registration
# 126 plan section 5.2. ASCII-only comments (Windows PowerShell 5.1, GBK console).
#
# WHY THIS EXISTS (2026-09-29, real crash):
#   9 wild crops had blockstates but were never registered in Java
#   -> worldgen referenced a non-existent block
#   -> "Failed to load registries" -> the save could not be opened at all.
#   tools/verify.ps1 only checks resource-to-resource references, so it could NOT catch this.
#
# USAGE: & .\tools\verify-registry.ps1
#        & .\tools\verify-registry.ps1 -ModId tfcagricultureplus   (for B)

param(
    [string]$ModId = 'tfcagricultureplus',
    # Runtime mode: read the authoritative block list from a launch log
    # (enable with -Dtfcfarmingplus.dumpBlockIds=true -> lines "[BLOCK-ID] <id>")
    [string]$FromLog = ''
)

$ErrorActionPreference = 'Stop'
$proj = Split-Path $env:TFC_TOOLS_ROOT -Parent
$bsDir = Join-Path $proj "src\main\resources\assets\$ModId\blockstates"
$javaDir = Join-Path $proj 'src\main\java'
$issues = 0

if (-not (Test-Path $bsDir)) {
    Write-Host ("[SKIP] no blockstates dir yet: " + $bsDir)
    exit 0
}

# ---- (1) resource side: every blockstate path (relative, no .json) ----
$prefixLen = $bsDir.Length + 1
$res = Get-ChildItem $bsDir -Recurse -File -Filter *.json |
       ForEach-Object { ($_.FullName.Substring($prefixLen) -replace '\.json$', '') -replace '\\', '/' } |
       Sort-Object -Unique

if ($FromLog -ne '') {
    # ================= RUNTIME MODE (authoritative) =================
    # Loop-generated variants (e.g. "cutting_board/" + wood) CANNOT be extracted statically.
    # The runtime dump is the only reliable source of truth (see 126 plan section 5.2).
    if (-not (Test-Path $FromLog)) {
        Write-Host ("[FAIL] log not found: " + $FromLog)
        exit 1
    }
    # Log lines look like:
    #   [09:15:09] [Render thread/INFO] [TFC Agriculture Plus/]: [BLOCK-ID] cutting_board/acacia
    # so anchor on the [BLOCK-ID] token itself, not on start-of-line.
    $codeNames = @(Select-String -Path $FromLog -Pattern '\[BLOCK-ID\]\s+([a-z0-9_/]+)\s*$' |
                   ForEach-Object { $_.Matches[0].Groups[1].Value } |
                   Sort-Object -Unique)
    Write-Host ("[INFO] runtime mode: read " + $codeNames.Count + " block ids from log")
} else {
    # ================= STATIC MODE (best effort) =================
    # WARNING: only handles literal register("x") and a small factory table.
    #          Anything built by a loop with string concatenation is INVISIBLE here.
    $code = (Get-ChildItem $javaDir -Recurse -File -Filter *.java |
             ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($_.FullName)) }) -join "`n"

    $byLiteral = [regex]::Matches($code, 'register\(\s*"([a-z0-9_/]+)"') |
                 ForEach-Object { $_.Groups[1].Value }

    $factories = @{
        'wild'             = 'wild_crop/{0}'
        'wildFlooded'      = 'wild_crop/{0}'
        'dead'             = 'dead_crop/{0}'
        'deadFlooded'      = 'dead_crop/{0}'
        'registerWithItem' = '{0}'
    }
    $byFactory = @()
    foreach ($fn in $factories.Keys) {
        foreach ($m in [regex]::Matches($code, ('=[\s]*' + $fn + '\(\s*"([a-z0-9_]+)"'))) {
            $byFactory += ($factories[$fn] -f $m.Groups[1].Value)
        }
    }

    $noise = @()
    foreach ($m in [regex]::Matches($code, '(?s)CREATIVE_TABS\.register\(\s*"([a-z0-9_/]+)"')) {
        $noise += $m.Groups[1].Value
    }

    # force arrays with @() -- a single-element array degrades to a scalar in PowerShell
    $codeNames = (@($byLiteral) + @($byFactory) | Where-Object { $noise -notcontains $_ }) | Sort-Object -Unique
    $codeNames = @($codeNames)
    Write-Host "[INFO] static mode: extracted $($codeNames.Count) ids -- loop-generated variants are NOT visible, prefer -FromLog"
}

# ---- (3) bidirectional diff ----
$onlyRes  = @($res       | Where-Object { $codeNames -notcontains $_ })
$onlyCode = @($codeNames | Where-Object { $res       -notcontains $_ })

if ($onlyRes.Count -gt 0) {
    $issues++
    Write-Host "[FAIL] blockstate exists but NOT registered in Java (FML will report Unknown registry key):"
    $onlyRes | ForEach-Object { Write-Host ("       " + $_) }
}
if ($onlyCode.Count -gt 0) {
    $issues++   # not necessarily an error, but must be confirmed by a human
    Write-Host "[WARN] registered but has no blockstate (confirm this is intentional):"
    $onlyCode | ForEach-Object { Write-Host ("       " + $_) }
}

Write-Host ""
if ($issues -eq 0) {
    Write-Host ("[OK] resources and registrations match (" + $res.Count + " blocks, mod=" + $ModId + ")")
    exit 0
} else {
    Write-Host ("[FAIL] " + $issues + " kind(s) of mismatch -- fix before building")
    exit 1
}
