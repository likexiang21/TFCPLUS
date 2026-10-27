param([string]$SourceInstance='', [string]$ReportDirectory='')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'audit-reviewed-crop-display.ps1') -Species 'spinach' -SourceInstance $SourceInstance -ReportDirectory $ReportDirectory
exit $LASTEXITCODE
