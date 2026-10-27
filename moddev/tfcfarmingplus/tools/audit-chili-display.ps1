param([string]$SourceInstance='', [string]$ReportDirectory='')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'audit-reviewed-crop-display.ps1') -Species 'chili' -SourceInstance $SourceInstance -ReportDirectory $ReportDirectory
exit $LASTEXITCODE
