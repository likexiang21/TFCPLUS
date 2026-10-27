# ============================================================
# gen-rosette-models.ps1 -- rosette crops: shared geometry + wrappers
# ============================================================
# VERSION HISTORY (kept short on purpose; details in moddev/docs/105 & 112)
#   v1  4 horizontal flat plates (bird_nest_fern style) -> "4 boards + a hole"
#   v2  4(+4) horizontal zero-thickness plates with up/down faces
#       -> invisible from the side (docs/80 sec.4-2, docs/93 P1-1)
#   v3  vertical plates (option A, after tfc:block/plant/sword_fern)
#   v4  HISTORICAL DRAFT (2026-09-28): per-layer uv 1:1, 3 layers per mature age,
#       ONE plate per plane when the tilt is 0 (two would be coplanar).
# ============================================================
# HARD RULES ENFORCED HERE (round 48 post-mortem, docs/112 sec.2.1)
#   1. FACE TYPE MUST MATCH THE ZERO-THICKNESS AXIS:
#        from.x == to.x  -> east / west      (X-flat plate)
#        from.z == to.z  -> north / south    (Z-flat plate)
#        from.y == to.y  -> up / down        (Y-flat plate)
#      A mismatch makes the face SILENTLY DEGENERATE (nothing is drawn):
#      this is exactly how "half of the leaves never rendered" (faces=12/24) happened.
#   2. UV MUST BE 1:1 WITH THE WORLD SIZE OF THE PLATE:
#        v0 = 16 - L  so the plate bottom sits on v=16 (= the ground line).
#   3. Every age must differ from its neighbours (no two identical stages).
# ============================================================
# USAGE
#   -GeometryOnly  : rewrite the shared geometry only (9 json), never touches textures
#   -WrappersOnly  : rewrite geometry + per-species wrapper models, never touches textures
#   (bare run)     : also writes placeholder textures, BUT an already existing
#                    texture file is left alone unless -Force is given.
#                    (round 42/44/48 hand-drawn textures must never be silently overwritten)
# ============================================================
param([switch]$GeometryOnly, [switch]$WrappersOnly, [switch]$Force, [string]$Root='', [switch]$ParticleBindingsOnly, [switch]$MatureFruitModelOnly, [switch]$DeadModelsOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Legacy geometry is older than the live reviewed models. Draft output only.
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $Root
. (Join-Path $PSScriptRoot 'shared-dead-model-policy.ps1')
$safeModes=@($ParticleBindingsOnly,$MatureFruitModelOnly,$DeadModelsOnly)|Where-Object{$_}
if(@($safeModes).Count -gt 1){throw 'Select only one safe draft mode.'}
if(@($safeModes).Count -gt 0 -and ($GeometryOnly -or $WrappersOnly -or $Force)){throw 'Do not combine safe draft modes with historical generation flags.'}
if($DeadModelsOnly){Copy-ReviewedSharedDead -OutputRoot $root -ModelsOnly;exit 0}
$reviewedFruitRelative='assets/tfcfarmingplus/models/block/crop/rosette_age_5_fruiting.json'
$reviewedFruitFile=Join-Path (Split-Path $PSScriptRoot -Parent) ('src/main/resources/'+$reviewedFruitRelative)
if($MatureFruitModelOnly){
    if($ParticleBindingsOnly){throw 'Select one safe draft mode at a time.'}
    $target=Join-Path $root $reviewedFruitRelative
    [void][IO.Directory]::CreateDirectory((Split-Path $target -Parent))
    [IO.File]::WriteAllBytes($target,[IO.File]::ReadAllBytes($reviewedFruitFile))
    Write-Output '[OK] Copied one reviewed mature fruit model to scratch; no other geometry or images generated'
    exit 0
}
if($ParticleBindingsOnly){
    $selected=@('kale')
    $written=0
    foreach($name in $selected){foreach($age in 0..5){
        $suffixes=if($name -eq 'kale'){@('','_fruiting')}else{@('')}
        foreach($suffix in $suffixes){
            $path=Join-Path $root "assets/tfcfarmingplus/models/block/crop/${name}_age_${age}${suffix}.json"
            if(-not(Test-Path -LiteralPath $path)){throw "Particle-only draft requires an existing reviewed model: $path"}
            $model=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json
            $model.textures|Add-Member -NotePropertyName particle -NotePropertyValue '#0' -Force
            [IO.File]::WriteAllText($path,($model|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
            $written++
        }
    }}
    Write-Output "[OK] Draft particle bindings updated=$written; no geometry or images generated"
    exit 0
}
Write-Warning 'Legacy full draft geometry is not the current live artwork; never publish the whole output tree.'

$NS = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 12 -Compress), $utf8)
}

# Keep whole numbers whole: ConvertTo-Json renders [double]4 as 4.0, but the
# on-disk truth (and Minecraft's own json) writes 4. Only true halves stay double.
function Norm-Num([double]$v) {
    if ($v -eq [Math]::Floor($v)) { return [int]$v }
    return $v
}

# ---------- placeholder texture writers ----------
# Geometry and wrappers are the contract; these textures are only the original
# programmatic placeholders. An existing file is NEVER overwritten without -Force.
function New-LeafAtlas([string]$out, [int]$cr, [int]$cg, [int]$cb, [double]$seed) {
    if ($WrappersOnly) { return }
    if ((Test-Path $out) -and (-not $Force)) { return }
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    for ($s = 0; $s -lt 4; $s++) {
        $tone = 1.0 + 0.07 * [Math]::Sin($seed + $s * 2.3)
        for ($y = 0; $y -lt 16; $y++) {
            $t = $y / 15.0
            $half = (0.30 + 1.80 * [Math]::Pow($t, 0.72)) * (1.0 - 0.08 * [Math]::Sin($seed + $s))
            $cxx = $s * 4 + 1.5 + 0.80 * [Math]::Sin($seed * 1.1 + $t * 2.4)
            for ($x = 0; $x -lt 4; $x++) {
                $px = $s * 4 + $x + 0.5
                $adx = [Math]::Abs($px - $cxx)
                if ($adx -gt $half) { continue }
                if ($adx -gt ($half - 0.60) -and (($y + $s) % 3 -eq 0)) { continue }
                $rel = $adx / [Math]::Max($half, 0.01)
                $shade = 1.02 - 0.46 * $rel * $rel
                if ($adx -lt 0.55) { $shade = 1.26 }
                elseif ($adx -lt 1.15) { $shade = 1.06 }
                if (($y % 3 -eq 1) -and $adx -gt 0.55 -and $adx -lt ($half - 0.25)) { $shade = $shade * 1.08 }
                $shade = $shade * (1.0 - 0.12 * (1.0 - $t))
                $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $tone * $shade)))
                $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $tone * $shade)))
                $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $tone * $shade)))
                $bmp.SetPixel($s * 4 + $x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
            }
        }
    }
    $dir = Split-Path $out -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function New-FruitTexture([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    if ($WrappersOnly) { return }
    if ((Test-Path $out) -and (-not $Force)) { return }
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $cx = 7.5; $cy = 7.5; $rad = 7.0
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x - $cx); $dy = ($y - $cy)
            $d = [Math]::Sqrt($dx * $dx + $dy * $dy)
            if ($d -gt $rad) { continue }
            $nz = [Math]::Sqrt([Math]::Max(0.0, 1.0 - ($d / $rad) * ($d / $rad)))
            $nl = [Math]::Max(0.0, ($dx / $rad) * -0.45 + ($dy / $rad) * -0.55 + $nz * 0.70)
            $lam = 0.42 + 0.75 * $nl
            $spec = [Math]::Pow([Math]::Max(0.0, $nl), 16) * 0.55
            $r = [Math]::Min(255, [int]($cr * $lam + 255 * $spec))
            $g = [Math]::Min(255, [int]($cg * $lam + 255 * $spec))
            $b = [Math]::Min(255, [int]($cb * $lam + 255 * $spec))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
        }
    }
    $dir = Split-Path $out -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ---------- stage tables ----------
# "angle:length" per layer, layers separated by ';'.
# Layer order MUST be 45 -> 22.5 -> 0 to match the element order of the truth json.
# angle is limited to 0 / 22.5 / 45 (Minecraft hard limit for rotation.angle).
$stageSpec = @(
    '45:6',                    # age0
    '45:7',                    # age1
    '45:5;22.5:7;0:8',         # age2
    '45:6;22.5:8;0:9',         # age3
    '45:6;22.5:8;0:10',        # age4
    '45:8;22.5:10;0:12'        # age5
)
# age5 + fruit: the 0 deg layer drops 12 -> 10 so the fruit cube can sit on top.
# Mature fruit geometry is read from the reviewed source model below.
# fruit cube of rosette_age_5_fruiting (4 x 5 x 4, user ruling): side faces 4x5, top 4x4
$fruitCubeSide = @(6, 5, 10, 10)
$fruitCubeTop  = @(6, 6, 10, 10)

$species = @(
    [ordered]@{ n = 'cardoon';  r = 82;  g = 116; b = 50; fr = 96;  fg = 108; fb = 62 },
    [ordered]@{ n = 'agave';    r = 114; g = 148; b = 64; fr = 150; fg = 160; fb = 70 },
    [ordered]@{ n = 'purslane'; r = 126; g = 112; b = 54; fr = 170; fg = 150; fb = 80 },
    [ordered]@{ n = 'kale';     r = 54;  g = 90;  b = 56; fr = 70;  fg = 110; fb = 72 },
    [ordered]@{ n = 'sisal';    r = 118; g = 138; b = 78; fr = 150; fg = 150; fb = 96 }
)

# ---------- geometry ----------
# One layer = up to 4 vertical plates. A plate lies in a vertical plane
# (zero thickness along x or z) so its faces are north/south or east/west only.
#   N : plate at z=8, spans x 4..12, rotates about x by -angle
#   S : same plane, rotates about x by +angle        (skipped when angle = 0)
#   E : plate at x=8, spans z 4..12, rotates about z by -angle
#   W : same plane, rotates about z by +angle        (skipped when angle = 0)
# When angle = 0 the N and S plates would be coplanar (and E/W likewise):
# emitting both wastes two elements and causes z-fighting, so only one is emitted.
function New-LeafPlates([string]$spec) {
    $list = New-Object System.Collections.ArrayList
    foreach ($layer in ($spec -split ';')) {
        $pair = $layer -split ':'
        $ang = [double]$pair[0]
        $len = [int]$pair[1]
        $v0 = 16 - $len
        $flat = ($ang -eq 0.0)
        # Z-flat plate -> north/south faces; uv left half (8 wide = plate width)
        $facesNS = [ordered]@{
            north = [ordered]@{ uv = @(0, $v0, 8, 16);  texture = '#0' }
            south = [ordered]@{ uv = @(8, $v0, 0, 16);  texture = '#0' }
        }
        # X-flat plate -> east/west faces
        $facesEW = [ordered]@{
            east = [ordered]@{ uv = @(8, $v0, 16, 16);  texture = '#0' }
            west = [ordered]@{ uv = @(16, $v0, 8, 16);  texture = '#0' }
        }
        $posAng = Norm-Num $ang
        $negAng = Norm-Num (-$ang)
        [void]$list.Add([ordered]@{
            from = @(4, 0, 8); to = @(12, $len, 8)
            rotation = [ordered]@{ angle = $negAng; axis = 'x'; origin = @(8, 0, 8) }
            shade = $false; faces = $facesNS })
        if (-not $flat) {
            [void]$list.Add([ordered]@{
                from = @(4, 0, 8); to = @(12, $len, 8)
                rotation = [ordered]@{ angle = $posAng; axis = 'x'; origin = @(8, 0, 8) }
                shade = $false; faces = $facesNS })
        }
        [void]$list.Add([ordered]@{
            from = @(8, 0, 4); to = @(8, $len, 12)
            rotation = [ordered]@{ angle = $negAng; axis = 'z'; origin = @(8, 0, 8) }
            shade = $false; faces = $facesEW })
        if (-not $flat) {
            [void]$list.Add([ordered]@{
                from = @(8, 0, 4); to = @(8, $len, 12)
                rotation = [ordered]@{ angle = $posAng; axis = 'z'; origin = @(8, 0, 8) }
                shade = $false; faces = $facesEW })
        }
    }
    return ,$list
}

function New-Rosette([string]$spec, [bool]$fruiting) {
    $list = New-LeafPlates $spec
    if ($fruiting) {
        # Fruit cube: separate texture slots (#1 = top, #2 = side) - user ruling:
        # the centre must not use one single texture on all six faces.
        $side   = [ordered]@{ uv = $fruitCubeSide; texture = '#2' }
        $top    = [ordered]@{ uv = $fruitCubeTop;  texture = '#1' }
        $bottom = [ordered]@{ uv = $fruitCubeTop;  texture = '#2' }
        [void]$list.Add([ordered]@{
            from = @(6, 10, 6); to = @(10, 15, 10)
            shade = $false
            faces = [ordered]@{
                north = $side; south = $side; east = $side; west = $side
                up = $top; down = $bottom
            } })
    }
    return ,$list
}

# ---------- 1) shared geometry ----------
$creditLeaf = 'TFC Farming Plus - rosette v4: 4-direction vertical leaf plates, per-layer uv 1:1'
for ($i = 0; $i -lt $stageSpec.Count; $i++) {
    $tex = "$($NS):block/crop/rosette_$i"
    Save-Json "assets/$NS/models/block/crop/rosette_age_$i.json" ([ordered]@{
        credit           = $creditLeaf
        ambientocclusion = $false
        textures         = [ordered]@{ '0' = $tex; particle = $tex }
        elements         = (New-Rosette -spec $stageSpec[$i] -fruiting $false)
    })
}
# The hand-reviewed mature model is canonical; do not rebuild its old high cube.
$reviewedFruit=[IO.File]::ReadAllText($reviewedFruitFile,[Text.Encoding]::UTF8)|ConvertFrom-Json
Save-Json "assets/$NS/models/block/crop/rosette_age_5_fruiting.json" $reviewedFruit
# Shared dead geometry is copied from the reviewed source bundle below.
Write-Host 'rosette geometry: 6 stages + 1 fruiting + 2 dead'

# ---------- 2) per-species textures + wrapper models ----------
$texRoot = Join-Path $root "assets/$NS/textures/block/crop"
if ($GeometryOnly) {
    Write-Host '(-GeometryOnly) skipped species textures and wrapper models'
} else {
    foreach ($sp in $species) {
        $n = $sp['n']
        for ($i = 0; $i -lt $stageSpec.Count; $i++) {
            New-LeafAtlas (Join-Path $texRoot "$($n)_rosette_$i.png") ([int]$sp['r']) ([int]$sp['g']) ([int]$sp['b']) ($i * 1.7)
            $leafTextures=[ordered]@{ '0' = "$($NS):block/crop/$($n)_rosette_$i" }
            if($n -eq 'kale'){$leafTextures['particle']='#0'}
            Save-Json "assets/$NS/models/block/crop/$($n)_age_$i.json" ([ordered]@{
                parent   = "$($NS):block/crop/rosette_age_$i"
                textures = $leafTextures
            })
            $isLast = ($i -eq $stageSpec.Count - 1)
            $parent = if ($isLast) { "$($NS):block/crop/rosette_age_$($i)_fruiting" } else { "$($NS):block/crop/rosette_age_$i" }
            $texMap = [ordered]@{ '0' = if ($isLast) { "$($NS):block/crop/$($n)_rosette_$($i)_fruiting" } else { "$($NS):block/crop/$($n)_rosette_$i" } }
            if ($isLast) {
                # three slots: 0 = leaves, 1 = fruit top, 2 = fruit side
                $texMap['1'] = "$($NS):block/crop/$($n)_rosette_fruit_top"
                $texMap['2'] = "$($NS):block/crop/$($n)_rosette_fruit"
            }
            if($n -eq 'kale'){$texMap['particle']='#0'}
            Save-Json "assets/$NS/models/block/crop/$($n)_age_${i}_fruiting.json" ([ordered]@{
                parent   = $parent
                textures = $texMap
            })
        }
        New-LeafAtlas (Join-Path $texRoot "$($n)_rosette_5_fruiting.png") ([int]$sp['r']) ([int]$sp['g']) ([int]$sp['b']) 9.1
        New-FruitTexture (Join-Path $texRoot "$($n)_rosette_fruit.png") ([int]$sp['fr']) ([int]$sp['fg']) ([int]$sp['fb'])
        Write-Host "  $n wrappers (12 combinations) ready"
    }
    for ($i = 0; $i -lt $stageSpec.Count; $i++) { New-LeafAtlas (Join-Path $texRoot "rosette_$i.png") 110 140 80 ($i * 1.7) }
    New-LeafAtlas (Join-Path $texRoot 'rosette_5_fruiting.png') 110 140 80 9.1
    New-FruitTexture (Join-Path $texRoot 'rosette_fruit.png') 130 140 70
}

# ---------- 3) reviewed shared dead resources, including unchanged PNGs ----------
Copy-ReviewedSharedDead -OutputRoot $root -ModelsOnly
Write-Host 'rosette generator done (v4 geometry: vertical plates, per-layer uv 1:1)'
