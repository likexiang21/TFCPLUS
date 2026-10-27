# check-license-compliance.ps1 -- project license / third-party notice gate
# Run from repository root:  pwsh -File tools/check-license-compliance.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$failures = New-Object 'System.Collections.Generic.List[string]'

function Require-File([string]$rel) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $rel))) { $failures.Add("missing: $rel") }
}

function Require-Text([string]$rel, [string]$needle) {
    $path = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $path)) { $failures.Add("missing: $rel"); return }
    if (-not (Select-String -LiteralPath $path -Pattern $needle -SimpleMatch -Quiet)) {
        $failures.Add("expected '$needle' in $rel")
    }
}

Require-File 'LICENSE'
Require-File 'LICENSES/EUPL-1.2.txt'
Require-File 'THIRD_PARTY_NOTICES.md'
Require-File 'docs/THIRD-PARTY-ASSETS.md'
Require-File 'docs/CODE-PROVENANCE.md'

foreach ($mod in @('tfcfarmingplus', 'tfcagricultureplus')) {
    Require-File "$mod/src/main/templates/META-INF/neoforge.mods.toml"
    Require-Text "$mod/src/main/templates/META-INF/neoforge.mods.toml" 'license = "EUPL-1.2"'
    Require-File "$mod/src/main/resources/META-INF/licenses/EUPL-1.2.txt"
    Require-File "$mod/src/main/resources/META-INF/licenses/THIRD_PARTY_NOTICES.txt"
}

Require-File 'tfcagricultureplus/src/main/resources/META-INF/licenses/tfcwoodwork-MIT.txt'
Require-File 'tfcagricultureplus/src/main/resources/META-INF/licenses/timber-notice.txt'

# The root license and packaged EUPL copy must be byte-identical.
$rootLicense = Get-FileHash -LiteralPath (Join-Path $root 'LICENSE') -Algorithm SHA256
foreach ($mod in @('tfcfarmingplus', 'tfcagricultureplus')) {
    $packaged = Get-FileHash -LiteralPath (Join-Path $root "$mod/src/main/resources/META-INF/licenses/EUPL-1.2.txt") -Algorithm SHA256
    if ($rootLicense.Hash -ne $packaged.Hash) { $failures.Add("EUPL copy differs in $mod") }
}

# No stale MIT-only declaration in mod metadata.
$stale = Select-String -Path (Join-Path $root 'tfcfarmingplus/src/main/templates/META-INF/neoforge.mods.toml'),(Join-Path $root 'tfcagricultureplus/src/main/templates/META-INF/neoforge.mods.toml') -Pattern 'license = "MIT"' -SimpleMatch
if ($stale) { $failures.Add('stale license = "MIT" in mods.toml') }

if ($failures.Count -gt 0) {
    Write-Host '[FAIL] license compliance:'
    $failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host '[OK] license/notice metadata is internally consistent (EUPL-1.2)'
exit 0
