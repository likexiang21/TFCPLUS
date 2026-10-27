# build-local.ps1 -- use the workspace-local Java 21 and Gradle 8.13.
param(
    [string]$ToolingRoot = '',
    [string[]]$Tasks = @('build'),
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path $PSScriptRoot -Parent
if ($ToolingRoot -eq '') {
    $ancestor = [System.IO.DirectoryInfo]::new($projectDir)
    while ($null -ne $ancestor) {
        $candidate = Join-Path $ancestor.FullName '.tooling'
        if (Test-Path (Join-Path $candidate 'gradle-8.13\bin\gradle.bat')) {
            $ToolingRoot = $candidate
            break
        }
        $ancestor = $ancestor.Parent
    }
}
if ($ToolingRoot -eq '') {
    throw 'Workspace .tooling directory not found. Supply -ToolingRoot explicitly.'
}

$jdk = Get-ChildItem (Join-Path $ToolingRoot 'jdk21') -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'bin\javac.exe') } |
    Select-Object -First 1
if ($null -eq $jdk) {
    throw 'Java 21 JDK not found under the tooling directory.'
}
$gradleBat = Join-Path $ToolingRoot 'gradle-8.13\bin\gradle.bat'
$originalJavaHome = $env:JAVA_HOME
$originalGradleUserHome = $env:GRADLE_USER_HOME
Push-Location $projectDir
try {
    & (Join-Path $PSScriptRoot 'check-boundaries.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Boundary check failed.' }
    foreach ($contractScript in @('verify-workbench-recipes.ps1', 'verify-container-contract.ps1', 'verify-silkworm-chain.ps1', 'verify-silkworm-lifecycle.ps1', 'verify-optional-woodwork-compat.ps1', 'verify-woodwork-flow.ps1', 'verify-in-world-codec.ps1', 'verify-kitchenware-ledger.ps1', 'verify-fruit-processing.ps1', 'verify-agricultural-materials.ps1', 'verify-grain-food-processing.ps1', 'verify-coverage-ledger.ps1', 'verify-vegetable-beverage-processing.ps1')) {
        & (Join-Path $PSScriptRoot $contractScript)
        if ($LASTEXITCODE -ne 0) { throw "Contract check failed: $contractScript" }
    }
    $env:JAVA_HOME = $jdk.FullName
    $env:GRADLE_USER_HOME = Join-Path $ToolingRoot 'gradle-home'
    $gradleArgs = @($Tasks) + @('--console=plain')
    # Java does not automatically use the Windows system proxy.
    foreach ($scheme in @('http', 'https')) {
        $repositoryUri = [uri]("${scheme}://maven.neoforged.net/releases/")
        $proxyUri = [System.Net.WebRequest]::DefaultWebProxy.GetProxy($repositoryUri)
        if ($proxyUri.Host -ne $repositoryUri.Host) {
            $gradleArgs += "-D${scheme}.proxyHost=$($proxyUri.Host)"
            $gradleArgs += "-D${scheme}.proxyPort=$($proxyUri.Port)"
        }
    }
    if ($Offline) { $gradleArgs += '--offline' }
    & $gradleBat @gradleArgs
    if ($LASTEXITCODE -ne 0) { throw "Gradle failed with exit code $LASTEXITCODE." }
}
finally {
    $env:JAVA_HOME = $originalJavaHome
    $env:GRADLE_USER_HOME = $originalGradleUserHome
    Pop-Location
}
