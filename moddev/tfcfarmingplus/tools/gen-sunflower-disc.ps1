# ============================================================
# gen-sunflower-disc.ps1 -- sunflower upper half (cross stem + big disc)
# ============================================================
# Why a separate script:
#   gen-crops.ps1 writes <n>_age_<i>_top.json as a plain cross (its generic
#   logic). The sunflower upper half needs a cross stem PLUS - once the plant
#   matures - a big vertical disc, following tfc:block/plant/sunflower_upper_0.
#   Run order: ALWAYS after gen-crops.ps1.
# ============================================================
# Technique (TFC's authoritative approach):
#   * stem  = cross planes, full 0..16 wide, yaw 45 with rescale = true
#             (so the rotated plate still spans the whole block)
#   * disc  = one big VERTICAL plate (not a cube), tilted 22.5 deg about z
#   * shade = false (a vertical plate would otherwise be shaded into a dark slab)
#   * uv span == world size of the face (1 texture pixel = 1 block unit)
# ============================================================
# DISC APPEARS ONLY AT age5 (settled 2026-09-28 by the texture/model session):
#   age3 / age4 -> 2 elements (cross stem only), age5 -> 3 elements (stem + disc).
#   This also resolves the open point recorded in docs/112 sec.2.3
#   ("all three ages carried the same 12 px disc"): every age now differs from
#   its neighbours, and the disc only shows up when the plant is actually ripe.
# ============================================================
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..\src\main\resources'
$NS = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 12 -Compress), $utf8)
}

$disc     = 'tfc:block/plant/sunflower/sunflower_front_0'
$discBack = 'tfc:block/plant/sunflower/sunflower_back_0'
$discAges = @(5)          # which upper-half ages carry the big disc

foreach ($a in 3, 4, 5) {
    $stem = $NS + ':block/crop/sunflower_age_' + $a + '_top'
    $rel  = 'assets/' + $NS + '/models/block/crop/sunflower_age_' + $a + '_top.json'
    $elements = New-Object System.Collections.ArrayList
    # stem, plane 1: z = 8, spans x 0..16
    [void]$elements.Add([ordered]@{ from = @(0, 0, 8); to = @(16, 16, 8)
        rotation = [ordered]@{ origin = @(8, 8, 8); axis = 'y'; angle = 45; rescale = $true }; shade = $false
        faces = [ordered]@{ north = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#stem' }
                            south = [ordered]@{ uv = @(16, 0, 0, 16); texture = '#stem' } } })
    # stem, plane 2: x = 8, spans z 0..16
    [void]$elements.Add([ordered]@{ from = @(8, 0, 0); to = @(8, 16, 16)
        rotation = [ordered]@{ origin = @(8, 8, 8); axis = 'y'; angle = 45; rescale = $true }; shade = $false
        faces = [ordered]@{ east = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#stem' }
                            west = [ordered]@{ uv = @(16, 0, 0, 16); texture = '#stem' } } })
    if ($discAges -contains $a) {
        # disc: vertical plate at x = 11.5, 14 wide x 12 tall, uv span 14 x 12 (1:1)
        [void]$elements.Add([ordered]@{ from = @(11.5, 2, 1); to = @(11.5, 14, 15)
            rotation = [ordered]@{ origin = @(8, 8, 8); axis = 'z'; angle = 22.5 }; shade = $false
            faces = [ordered]@{ east = [ordered]@{ uv = @(1, 4, 15, 16); texture = '#disc' }
                                west = [ordered]@{ uv = @(15, 4, 1, 16); texture = '#disc_back' } } })
    }
    Save-Json $rel ([ordered]@{
        credit           = 'TFC Farming Plus - sunflower upper half (cross stem + big disc, after tfc:block/plant/sunflower_upper_0)'
        ambientocclusion = $false
        textures         = [ordered]@{ particle = $disc; disc = $disc; disc_back = $discBack; stem = $stem }
        elements         = $elements
    })
    Write-Host ('  sunflower_age_' + $a + '_top.json  (' + $elements.Count + ' elements)')
}
Write-Host 'sunflower upper-half geometry done (disc only at age5)'
