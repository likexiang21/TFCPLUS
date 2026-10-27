# Verify the cross-namespace file ledger against the checked-in resource trees.
param([string]$SourceInstance='')
$ErrorActionPreference = 'Stop'
$instance = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
if($SourceInstance){$instance=(Resolve-Path -LiteralPath $SourceInstance).Path}
$ledger = Join-Path $instance 'moddev\tfcagricultureplus\OVERRIDE-REGISTRY.md'
$rows = Get-Content -LiteralPath $ledger -Encoding UTF8 |
    Where-Object { $_ -match '^\|\s*\d+\s*\|\s*([AB])\s*\|\s*`([^`]+)`\s*\|' } |
    ForEach-Object {
        $m = [regex]::Match($_, '^\|\s*\d+\s*\|\s*([AB])\s*\|\s*`([^`]+)`\s*\|')
        [pscustomobject]@{ Owner = $m.Groups[1].Value; Path = $m.Groups[2].Value }
    }
if ($rows.Count -eq 0) { throw 'No ledger rows found.' }
$actual = @()
$roots = @{
    A = @{ Root = Join-Path $instance 'moddev/tfcfarmingplus/src/main/resources'; Namespace = 'tfcfarmingplus' }
    B = @{ Root = Join-Path $instance 'moddev/tfcagricultureplus/src/main/resources'; Namespace = 'tfcagricultureplus' }
}
foreach ($owner in 'A','B') {
    $r = $roots[$owner]
    $resourceRoot = (Resolve-Path -LiteralPath $r.Root).Path
    Get-ChildItem -LiteralPath $resourceRoot -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($resourceRoot.Length + 1).Replace('\','/')
        if ($rel -match '^(assets|data)/([^/]+)/' -and $Matches[2] -cne $r.Namespace) {
            $actual += [pscustomobject]@{ Owner = $owner; Path = $rel }
        }
    }
}
$ledgerKeys = @($rows | ForEach-Object { "$($_.Owner)|$($_.Path)" } | Sort-Object -Unique)
$actualKeys = @($actual | ForEach-Object { "$($_.Owner)|$($_.Path)" } | Sort-Object -Unique)
$missing = Compare-Object -ReferenceObject $actualKeys -DifferenceObject $ledgerKeys -PassThru | Where-Object { $_ -in $actualKeys }
$extra = Compare-Object -ReferenceObject $actualKeys -DifferenceObject $ledgerKeys -PassThru | Where-Object { $_ -in $ledgerKeys }
$tagFiles = Get-ChildItem (Join-Path $instance 'moddev\tfcagricultureplus\src\main\resources\data') -Recurse -File |
    Where-Object { $_.FullName -match '\\tags\\' }
$badReplace = @($tagFiles | Where-Object { (Get-Content $_.FullName -Raw) -match '"replace"\s*:\s*true' })
Write-Host ("[INFO] ledger rows = {0}; scanned external files = {1}" -f $ledgerKeys.Count, $actualKeys.Count)
if ($ledgerKeys.Count -ne $rows.Count) { Write-Host '[FAIL] duplicate ledger paths'; exit 1 }
if ($missing.Count -or $extra.Count) {
    if ($missing.Count) { Write-Host '[FAIL] files missing from ledger:'; $missing | ForEach-Object { Write-Host "       $_" } }
    if ($extra.Count) { Write-Host '[FAIL] ledger rows absent from resources:'; $extra | ForEach-Object { Write-Host "       $_" } }
    exit 1
}
if ($badReplace.Count) {
    Write-Host '[FAIL] B neighbour tag uses replace:true:'
    $badReplace | ForEach-Object { Write-Host "       $($_.FullName)" }
    exit 1
}
Write-Host '[OK] coverage ledger matches resource tree; neighbour tags use additive semantics'
exit 0
