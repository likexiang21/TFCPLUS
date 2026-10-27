# Compatibility wrapper; the maintained script lives under scripts/.
$env:TFC_TOOLS_ROOT = $PSScriptRoot
& (Join-Path $PSScriptRoot 'scripts/audit/audit-reviewed-crop-display.ps1') @args
exit $LASTEXITCODE
