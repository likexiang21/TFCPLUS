# Compatibility wrapper; the maintained script lives under scripts/.
$env:TFC_TOOLS_ROOT = $PSScriptRoot
& (Join-Path $PSScriptRoot 'scripts/verify/verify-optional-woodwork-compat.ps1') @args
exit $LASTEXITCODE
