# Launch an isolated copy of the test save using workspace-local runtime files.
param([string]$World = 'codex-validation-20261006', [switch]$Visible, [switch]$WaitForExit, [switch]$Detached)
$ErrorActionPreference = 'Stop'
$instance = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workspace = (Resolve-Path (Join-Path $instance '..\..')).Path
$runtime = Join-Path $workspace '.tooling\game'
$jdk = Get-ChildItem (Join-Path $workspace '.tooling\jdk21') -Directory | Select-Object -First 1
$java = Join-Path $jdk.FullName 'bin\java.exe'
$versionName = 'Essential TerraFirmaCraft (TFC)'
$libraries = Join-Path $runtime 'libraries'
$natives = Join-Path $instance ($versionName + '-natives')
if (-not (Test-Path (Join-Path $runtime 'ready.json'))) { throw 'Validation runtime has not been prepared.' }
$profile = Get-Content (Join-Path $instance ($versionName + '.json')) -Raw | ConvertFrom-Json

function Test-ValidationRules($rules) {
    if (-not $rules) { return $true }
    $allowed = $false
    foreach ($rule in $rules) {
        if ($rule.os.name -and $rule.os.name -ne 'windows') { continue }
        if ($rule.os.arch -eq 'x86' -or $rule.features) { continue }
        $allowed = ($rule.action -eq 'allow')
    }
    return $allowed
}

$classpath = [System.Collections.Generic.List[string]]::new()
foreach ($library in $profile.libraries) {
    if (-not (Test-ValidationRules $library.rules)) { continue }
    if ($library.downloads.artifact.path) { $relative = $library.downloads.artifact.path }
    else {
        $parts = $library.name -split ':'
        $classifier = if ($parts.Count -gt 3) { '-' + $parts[3] } else { '' }
        $relative = ($parts[0] -replace '\.', '/') + '/' + $parts[1] + '/' + $parts[2] + '/' + $parts[1] + '-' + $parts[2] + $classifier + '.jar'
    }
    $path = Join-Path $libraries $relative
    if (-not (Test-Path -LiteralPath $path)) { throw "Library missing: $relative" }
    if (-not $classpath.Contains($path)) { $classpath.Add($path) }
}
$classpath.Add((Join-Path $instance ($versionName + '.jar')))

$jvmArgs = [System.Collections.Generic.List[string]]::new()
$jvmArgs.Add('-Xmx4G')
$jvmArgs.Add('-Dtfcfarmingplus.debug=true')
$jvmArgs.Add('-Dtfcagricultureplus.debug=true')
$jvmArgs.Add('-Dtfcagricultureplus.dumpBlockIds=true')
foreach ($argument in $profile.arguments.jvm) {
    if ($argument -isnot [string]) {
        if (-not (Test-ValidationRules $argument.rules)) { continue }
        foreach ($value in @($argument.value)) { $jvmArgs.Add([string]$value) }
        continue
    }
    $value = $argument.Replace('${classpath}', ($classpath -join ';'))
    $value = $value.Replace('${natives_directory}', $natives).Replace('${library_directory}', $libraries)
    $value = $value.Replace('${classpath_separator}', ';').Replace('${version_name}', $versionName)
    $value = $value.Replace('${launcher_name}', 'LocalValidation').Replace('${launcher_version}', '1')
    $jvmArgs.Add($value)
}

$gameArgs = [System.Collections.Generic.List[string]]::new()
$replacements = @{
    '${auth_player_name}' = 'APlayerInMC'; '${version_name}' = $versionName;
    '${game_directory}' = $instance; '${assets_root}' = (Join-Path $runtime 'assets');
    '${assets_index_name}' = [string]$profile.assetIndex.id;
    '${auth_uuid}' = 'ff27958fad74420f8da26a30f0b4dd62'; '${auth_access_token}' = '0';
    '${clientid}' = '0'; '${auth_xuid}' = '0'; '${user_type}' = 'msa'; '${version_type}' = 'LocalValidation'
}
foreach ($argument in $profile.arguments.game) {
    if ($argument -isnot [string]) { continue }
    $value = $argument
    foreach ($key in $replacements.Keys) { $value = $value.Replace($key, $replacements[$key]) }
    if ($value.Contains('${')) { throw "Unresolved game argument: $value" }
    $gameArgs.Add($value)
}
foreach ($argument in @('--width', '1280', '--height', '720', '--quickPlaySingleplayer', $World)) {
    $gameArgs.Add($argument)
}

$save = Join-Path $instance ('saves\' + $World)
if (-not (Test-Path -LiteralPath $save)) {
    Copy-Item -LiteralPath (Join-Path $instance 'saves\tfctest') -Destination $save -Recurse
}
$options = Join-Path $instance 'options.txt'
Copy-Item -LiteralPath $options -Destination (Join-Path $runtime 'options.original') -Force
$text = [System.IO.File]::ReadAllText($options)
foreach ($setting in @('fullscreen', 'pauseOnLostFocus')) {
    $text = [regex]::Replace($text, "(?m)^${setting}:.*$", "${setting}:false")
}
$text = [regex]::Replace($text, '(?m)^key_key\.use:.*$', 'key_key.use:key.keyboard.f13')
$text = [regex]::Replace($text, '(?m)^toggleCrouch:.*$', 'toggleCrouch:true')
[System.IO.File]::WriteAllText($options, $text, [System.Text.UTF8Encoding]::new($false))

$arguments = @($jvmArgs) + @($profile.mainClass) + @($gameArgs)
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $java
$startInfo.WorkingDirectory = $instance
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = -not $Visible
foreach ($argument in $arguments) { [void]$startInfo.ArgumentList.Add([string]$argument) }

# Keep the Java arguments separate. Start-Process -ArgumentList joins them into one
# string, which can split a classpath containing spaces or Chinese path segments.
if ($WaitForExit) {
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
}
if ($Detached) {
    function Quote-WindowsArgument([string]$value) {
        $result = [System.Text.StringBuilder]::new('"')
        $slashes = 0
        foreach ($character in $value.ToCharArray()) {
            if ($character -eq '\') { $slashes++; continue }
            if ($character -eq '"') {
                [void]$result.Append(('\' * ($slashes * 2 + 1)) + '"')
            } else {
                [void]$result.Append(('\' * $slashes) + $character)
            }
            $slashes = 0
        }
        [void]$result.Append(('\' * ($slashes * 2)) + '"')
        return $result.ToString()
    }
    $commandLine = (@($arguments) | ForEach-Object { Quote-WindowsArgument ([string]$_) }) -join ' '
    if ($commandLine.Length -gt 32000) { throw 'Validation command line exceeds the Windows limit.' }
    $windowStyle = if ($Visible) { 'Normal' } else { 'Hidden' }
    $process = Start-Process -FilePath $java -ArgumentList $commandLine -WorkingDirectory $instance `
        -RedirectStandardOutput (Join-Path $runtime 'validation-client.log') `
        -RedirectStandardError (Join-Path $runtime 'validation-client-error.log') -PassThru -WindowStyle $windowStyle
} else {
    $process = [System.Diagnostics.Process]::Start($startInfo)
}
if (-not $process) { throw 'Java process could not be started.' }
if ($WaitForExit) {
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    [System.IO.File]::WriteAllText((Join-Path $runtime 'validation-client.log'), $stdout.Result)
    [System.IO.File]::WriteAllText((Join-Path $runtime 'validation-client-error.log'), $stderr.Result)
    if ($process.ExitCode -ne 0) { throw "Validation client exited with code $($process.ExitCode); inspect validation-client-error.log" }
} else {
    Start-Sleep -Seconds 3
    if ($process.HasExited) { throw "Validation client exited immediately with code $($process.ExitCode); run with -WaitForExit for console diagnostics" }
}
@{pid=$process.Id; started=$process.StartTime.ToUniversalTime().ToString('o'); executable=$java; instance=$instance} |
    ConvertTo-Json | Set-Content (Join-Path $runtime 'client-process.json') -Encoding UTF8
Write-Output ("Validation client PID: " + $process.Id + "; save: " + $World)
