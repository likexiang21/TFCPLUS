# Stop only the process created by launch-validation-client.ps1 and restore options.
$ErrorActionPreference = 'Stop'
$instance = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workspace = (Resolve-Path (Join-Path $instance '..\..')).Path
$runtime = Join-Path $workspace '.tooling\game'
$recordFile = Join-Path $runtime 'client-process.json'
try {
    if (Test-Path $recordFile) {
        $record = Get-Content $recordFile -Raw | ConvertFrom-Json
        $ownedProcess = Get-Process -Id $record.pid -ErrorAction SilentlyContinue
        if ($ownedProcess) {
            if ($ownedProcess.StartTime.ToUniversalTime().ToString('o') -ne $record.started) {
                throw 'PID no longer belongs to the recorded validation client; no process was stopped.'
            }
            if ($ownedProcess.Path -ne $record.executable) {
                throw 'Process executable does not match the validation client; no process was stopped.'
            }
            Stop-Process -Id $ownedProcess.Id
            $ownedProcess.WaitForExit(10000) | Out-Null
            Write-Output 'Stopped the owned validation client.'
        }
    }
}
finally {
    $originalOptions = Join-Path $runtime 'options.original'
    if (Test-Path $originalOptions) {
        Copy-Item -LiteralPath $originalOptions -Destination (Join-Path $instance 'options.txt') -Force
        Write-Output 'Restored original game options.'
    }
}
