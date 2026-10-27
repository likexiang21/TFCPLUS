param([string]$SourceInstance='', [string]$ReportDirectory='')
$ErrorActionPreference='Stop'
& (Join-Path $env:TFC_TOOLS_ROOT 'audit-reviewed-crop-display.ps1') -Species 'spinach' -SourceInstance $SourceInstance -ReportDirectory $ReportDirectory
exit $LASTEXITCODE
