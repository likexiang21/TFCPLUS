# Compatibility wrapper; the maintained script lives under scripts/.
$env:TFC_TOOLS_ROOT = $PSScriptRoot
& (Join-Path $PSScriptRoot 'scripts/audit/audit-swiss-chard-display.ps1') @args
exit $LASTEXITCODE
