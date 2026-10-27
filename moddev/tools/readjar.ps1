# TFC jar 资源读取辅助函数（供文档编写使用）
# 用法： . "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\tools\readjar.ps1"
#        Read-JarEntry "data/tfc/recipe/anvil/brass_mechanisms.json"
#        Find-JarEntry "data/tfc/recipe/anvil/*.json"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:TFC_ROOT = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
$script:TFC_JAR = Join-Path $script:TFC_ROOT 'mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar'

function Read-JarEntry {
    param([Parameter(Mandatory = $true)][string]$Path)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($script:TFC_JAR)
    try {
        $entry = $zip.GetEntry($Path)
        if ($null -eq $entry) { Write-Error "entry not found: $Path"; return }
        $sr = New-Object System.IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
        try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
    } finally { $zip.Dispose() }
}

function Get-JarEntryList {
    param([string]$Filter = '*')
    $zip = [System.IO.Compression.ZipFile]::OpenRead($script:TFC_JAR)
    try {
        $zip.Entries | Where-Object { $_.FullName -like $Filter -and $_.FullName -notlike '*/' } | ForEach-Object { $_.FullName }
    } finally { $zip.Dispose() }
}

function Grep-JarEntry {
    param([Parameter(Mandatory = $true)][string]$PathFilter,
          [Parameter(Mandatory = $true)][string]$Pattern,
          [int]$MaxMatches = 40)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($script:TFC_JAR)
    try {
        $count = 0
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -like '*/') { continue }
            if ($entry.FullName -notlike $PathFilter) { continue }
            $sr = New-Object System.IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
            $text = $sr.ReadToEnd(); $sr.Dispose()
            if ($text -match $Pattern) {
                Write-Output "--- $($entry.FullName)"
                $count++
                if ($count -ge $MaxMatches) { break }
            }
        }
    } finally { $zip.Dispose() }
}
