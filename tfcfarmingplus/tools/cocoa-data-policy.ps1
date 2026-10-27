# Shared data policy. All functions are independently implemented for this project.
function Read-CocoaPolicy {
    return (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'contracts/cocoa-chain-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
}
function Set-CupuacuDiagram($page) {
    if ($page.type -ne 'tfc:multimultiblock' -or $page.multiblocks.Count -ne 4) {
        throw 'Unexpected cupuacu handbook diagram structure.'
    }
    $fruit = @('none', 'none', 'unripe', 'ripe')
    $leaf = @('healthy', 'flowering', 'healthy', 'healthy')
    for ($i = 0; $i -lt 4; $i++) {
        $mapping = $page.multiblocks[$i].mapping
        $branch = "tfcfarmingplus:plant/cupuacu_branch[down=true,up=true,fruit=$($fruit[$i])]"
        $leaves = "tfcfarmingplus:plant/cupuacu_leaves[lifecycle=$($leaf[$i])]"
        if ($mapping -is [System.Collections.IDictionary]) {
            $mapping['0'] = $branch
            $mapping['L'] = $leaves
        } else {
            $mapping.'0' = $branch
            $mapping.L = $leaves
        }
    }
}
function Resolve-LegacyGeneratorOutput([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Legacy bulk generation is restricted to a scratch tree. Pass -OutputRoot inside mod_rebuild/.probe/generator-output; never publish that tree wholesale. For live cocoa changes use sync-cocoa-data.ps1 -DryRun first.'
    }
    $module = Split-Path $PSScriptRoot -Parent
    $scratch = [IO.Path]::GetFullPath((Join-Path (Split-Path $module -Parent) '.probe/generator-output')).TrimEnd('\', '/')
    $target = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    if (-not $target.StartsWith($scratch + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'OutputRoot must be a child of mod_rebuild/.probe/generator-output; live sources and protected snapshots cannot be targets.'
    }
    $ancestor = $target
    while ($ancestor) {
        if (Test-Path -LiteralPath $ancestor) {
            $node = Get-Item -LiteralPath $ancestor -Force
            if (($node.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Generator output must not traverse a symlink or junction.'
            }
        }
        $ancestor = Split-Path $ancestor -Parent
    }
    return $target
}
