# Compatibility wrapper; the maintained script lives under scripts/.
$env:TFC_TOOLS_ROOT = $PSScriptRoot
& (Join-Path $PSScriptRoot 'scripts/generate/gen-patchouli-book.ps1') @args
exit $LASTEXITCODE
