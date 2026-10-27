# ============================================================
# gen-leafball-models.ps1 -- leaf-ball crops: shared geometry + wrappers
# ============================================================
# Geometry history (details: mod_rebuild/docs/105, 110, 112, 114):
#   v1/v2  4 flat plates wheel + centre ball, on the ground (y=0)
#          -> "a box sitting on the floor with a few leaves stuck on top"
#   v5     head cube lifted above the inner leaf ring (the ball became visible)
#   v7     leaves became RADIAL (base edge on the rotation axis at [8,0,8])
#          so the rosette converges at the centre; cube bottom moved to y=8
#   v8     HISTORICAL DRAFT (2026-09-28): + 2 diagonal upright blades (yaw +-45)
#          -> 8 azimuths in top view; 1:1 uv everywhere; head cube split into
#             slot #1 (top) and slot #2 (side) - the centre must not use a single
#             texture on all six faces (user ruling).
# ============================================================
# HARD RULES ENFORCED HERE (docs/110, docs/112 sec.2.2)
#   1. Zero-thickness face type must match the flat axis:
#        from.z == to.z -> north/south      (blades in the XY plane)
#        from.x == to.x -> east/west        (blades in the ZY plane)
#      v1 wrote north/south on y-flat plates -> the faces degenerated silently.
#   2. UV span == world size of the face (1 texture pixel = 1 block unit),
#      v0 = 16 - length so the blade base sits on the ground line.
#   3. The head cube must be LIFTED (from.y = 8) - never sitting on the floor,
#      and never buried inside the leaf ring (it must stay the tallest organ).
#   4. Every age must differ from its neighbours.
# ============================================================
# USAGE
#   -WrappersOnly : rewrite geometry + wrapper models, never touches textures
#   (bare run)    : also writes placeholder textures, BUT an existing texture
#                   file is left alone unless -Force is given.
# ============================================================
param([switch]$WrappersOnly, [switch]$Force, [string]$Root='', [switch]$ParticleBindingsOnly, [switch]$SharedGeometryOnly, [ValidateSet('broccoli','lettuce','cauliflower','napa_cabbage','cabbage')][string[]]$ParticleSpecies=@('broccoli','lettuce'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Legacy geometry is older than the live reviewed models. Draft output only.
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $Root
# Current shared geometry is canonical; the old v8 formulas below are historical only.
function Copy-ReviewedLeafballGeometry([switch]$IncludeNativeCabbage) {
    $source=Join-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) 'src/main/resources'
    $selected=@(0..5|ForEach-Object{"assets/tfcfarmingplus/models/block/crop/leafball_age_$_.json"})
    if($IncludeNativeCabbage){$selected+=@(0..5|ForEach-Object{"assets/tfc/models/block/crop/cabbage_age_$_.json"})}
    foreach($relative in $selected){if(-not(Test-Path -LiteralPath (Join-Path $source $relative))){throw "Reviewed leafball resource missing: $relative"}}
    foreach($relative in $selected){
        $output=Join-Path $root $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes((Join-Path $source $relative)))
    }
    Write-Output "[OK] copied $($selected.Count) reviewed leafball JSONs; no image generation"
}
if($SharedGeometryOnly -and ($ParticleBindingsOnly -or $WrappersOnly -or $Force)){throw 'Shared geometry copy must run without other generation modes.'}
if($SharedGeometryOnly){Copy-ReviewedLeafballGeometry;exit 0}
if($ParticleBindingsOnly){
    $selected=@($ParticleSpecies|Select-Object -Unique)
    $written=0
    foreach($name in $selected){
        $modelNamespace=if($name -eq 'cabbage'){'tfc'}else{'tfcfarmingplus'}
        foreach($age in 0..5){
        $suffixes=if($name -eq 'kale'){@('','_fruiting')}else{@('')}
        foreach($suffix in $suffixes){
            $path=Join-Path $root "assets/$modelNamespace/models/block/crop/${name}_age_${age}${suffix}.json"
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

# Keep whole numbers whole: ConvertTo-Json renders [double]4 as 4.0, the truth
# json (and Minecraft's own json) writes 4. Only real halves stay double.
function Norm-Num([double]$v) {
    if ($v -eq [Math]::Floor($v)) { return [int]$v }
    return $v
}

# ---------- placeholder texture writers ----------
# An existing file is NEVER overwritten unless -Force is given: the hand-drawn
# round 44~48 leaf/head textures must survive a generator re-run.
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
                $shade = 1.14 - 0.46 * $rel * $rel
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

function New-HeadTexture([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    if ($WrappersOnly) { return }
    if ((Test-Path $out) -and (-not $Force)) { return }
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $cx = 7.5; $cy = 7.5; $rad = 7.6
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x - $cx); $dy = ($y - $cy)
            $d = [Math]::Sqrt($dx * $dx + $dy * $dy)
            if ($d -gt $rad) { continue }
            $nz = [Math]::Sqrt([Math]::Max(0.0, 1.0 - ($d / $rad) * ($d / $rad)))
            $nl = [Math]::Max(0.0, ($dx / $rad) * -0.40 + ($dy / $rad) * -0.52 + $nz * 0.75)
            $lam = 0.44 + 0.68 * $nl
            $rings = 1.0 + 0.075 * [Math]::Sin($d * 2.35)
            $ang = [Math]::Atan2($dy, $dx)
            $veins = 1.0 + 0.045 * [Math]::Sin($ang * 6.0 + $d * 0.5)
            $spec = [Math]::Pow([Math]::Max(0.0, $nl), 20) * 0.42
            $edge = 1.0 - 0.24 * [Math]::Pow($d / $rad, 3.0)
            $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $lam * $rings * $veins * $edge + 255 * $spec)))
            $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $lam * $rings * $veins * $edge + 255 * $spec)))
            $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $lam * $rings * $veins * $edge + 255 * $spec)))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
        }
    }
    $dir = Split-Path $out -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ---------- stage tables ----------
# age0/1 (v3 layout): one 45 deg layer of four blades -> 4 elements.
# age2..5 (v8 layout): layers "0:len;22.5:len;45:len" -> 10 blades + 2 diagonals + cube.
$v3Len = @(5, 6)
$v8Spec = @(
    '0:4;22.5:11;45:7',        # age2
    '0:5;22.5:12;45:8',        # age3
    '0:6;22.5:13;45:9',        # age4
    '0:8;22.5:14;45:10'        # age5
)
# Head cube (1:1 uv): x1/y1/x2/y2 + side uv (w x h) + top uv (w x w).
# y1 = 8 always: the cube sits on top of the leaf ring, above the 0 deg blade top
# (base 4/5/6/8) and above the 22.5 deg blade top.
$headCubes = @(
    [ordered]@{ x1 = 6;   x2 = 10;   y2 = 11; side = @(6, 6, 10, 9);  top = @(6, 6, 10, 10) },
    [ordered]@{ x1 = 5.5; x2 = 10.5; y2 = 12; side = @(5, 6, 10, 10); top = @(5, 5, 10, 10) },
    [ordered]@{ x1 = 5;   x2 = 11;   y2 = 13; side = @(5, 5, 11, 10); top = @(5, 5, 11, 11) },
    [ordered]@{ x1 = 5;   x2 = 11;   y2 = 14; side = @(5, 5, 11, 11); top = @(5, 5, 11, 11) }
)
$headY1 = 8

# Species: outer leaf r/g/b + head hr/hg/hb. 'cabbage' is the vanilla/TFC crop
# that this mod overrides in the tfc namespace.
$species = @(
    [ordered]@{ n = 'cabbage';      r = 74;  g = 122; b = 54; hr = 132; hg = 174; hb = 108 },
    [ordered]@{ n = 'lettuce';      r = 102; g = 156; b = 62; hr = 154; hg = 194; hb = 104 },
    [ordered]@{ n = 'cauliflower';  r = 82;  g = 130; b = 60; hr = 204; hg = 212; hb = 186 },
    [ordered]@{ n = 'broccoli';     r = 56;  g = 102; b = 48; hr = 70;  hg = 122; hb = 58 },
    [ordered]@{ n = 'napa_cabbage'; r = 96;  g = 146; b = 70; hr = 184; hg = 202; hb = 148 }
)

# ---------- geometry ----------
# A blade lies in a vertical plane (zero thickness along x or z):
#   XY-plane blade (z fixed) -> north/south faces, spans x 4..12
#   ZY-plane blade (x fixed) -> east/west faces,  spans z 4..12
# v3 layout (no head cube): order N-, S+, E-, W+ around the centre.
function New-LeafballV3([int]$len) {
    $list = New-Object System.Collections.ArrayList
    $v0 = 16 - $len
    $facesNS = [ordered]@{
        north = [ordered]@{ uv = @(0, $v0, 8, 16); texture = '#0' }
        south = [ordered]@{ uv = @(8, $v0, 0, 16); texture = '#0' }
    }
    $facesEW = [ordered]@{
        east = [ordered]@{ uv = @(8, $v0, 16, 16); texture = '#0' }
        west = [ordered]@{ uv = @(16, $v0, 8, 16); texture = '#0' }
    }
    [void]$list.Add([ordered]@{
        from = @(4, 0, 8); to = @(12, $len, 8)
        rotation = [ordered]@{ angle = -45; axis = 'x'; origin = @(8, 0, 8) }
        shade = $false; faces = $facesNS })
    [void]$list.Add([ordered]@{
        from = @(4, 0, 8); to = @(12, $len, 8)
        rotation = [ordered]@{ angle = 45; axis = 'x'; origin = @(8, 0, 8) }
        shade = $false; faces = $facesNS })
    [void]$list.Add([ordered]@{
        from = @(8, 0, 4); to = @(8, $len, 12)
        rotation = [ordered]@{ angle = -45; axis = 'z'; origin = @(8, 0, 8) }
        shade = $false; faces = $facesEW })
    [void]$list.Add([ordered]@{
        from = @(8, 0, 4); to = @(8, $len, 12)
        rotation = [ordered]@{ angle = 45; axis = 'z'; origin = @(8, 0, 8) }
        shade = $false; faces = $facesEW })
    return ,$list
}

# v8 layout (with head cube): layers are emitted 0 -> 22.5 -> 45;
# inside a layer the order is N(-A), E(-A), N(+A), E(+A); the 0 deg layer has
# no rotation node at all and only two blades (N and E - the other two would be
# coplanar). Then 2 diagonal blades (yaw +-45) and finally the head cube.
function New-LeafballV8([string]$spec, $cube) {
    $list = New-Object System.Collections.ArrayList
    $len0 = 0
    foreach ($layer in ($spec -split ';')) {
        $pair = $layer -split ':'
        $ang = [double]$pair[0]
        $len = [int]$pair[1]
        if ($ang -eq 0.0) { $len0 = $len }
        $v0 = 16 - $len
        $facesNS = [ordered]@{
            north = [ordered]@{ uv = @(0, $v0, 8, 16); texture = '#0' }
            south = [ordered]@{ uv = @(8, $v0, 0, 16); texture = '#0' }
        }
        $facesEW = [ordered]@{
            east = [ordered]@{ uv = @(8, $v0, 16, 16); texture = '#0' }
            west = [ordered]@{ uv = @(16, $v0, 8, 16); texture = '#0' }
        }
        if ($ang -eq 0.0) {
            [void]$list.Add([ordered]@{
                from = @(4, 0, 8); to = @(12, $len, 8)
                shade = $false; faces = $facesNS })
            [void]$list.Add([ordered]@{
                from = @(8, 0, 4); to = @(8, $len, 12)
                shade = $false; faces = $facesEW })
        } else {
            $posAng = Norm-Num $ang
            $negAng = Norm-Num (-$ang)
            [void]$list.Add([ordered]@{
                from = @(4, 0, 8); to = @(12, $len, 8)
                shade = $false
                rotation = [ordered]@{ angle = $negAng; axis = 'x'; origin = @(8, 0, 8) }
                faces = $facesNS })
            [void]$list.Add([ordered]@{
                from = @(8, 0, 4); to = @(8, $len, 12)
                shade = $false
                rotation = [ordered]@{ angle = $negAng; axis = 'z'; origin = @(8, 0, 8) }
                faces = $facesEW })
            [void]$list.Add([ordered]@{
                from = @(4, 0, 8); to = @(12, $len, 8)
                shade = $false
                rotation = [ordered]@{ angle = $posAng; axis = 'x'; origin = @(8, 0, 8) }
                faces = $facesNS })
            [void]$list.Add([ordered]@{
                from = @(8, 0, 4); to = @(8, $len, 12)
                shade = $false
                rotation = [ordered]@{ angle = $posAng; axis = 'z'; origin = @(8, 0, 8) }
                faces = $facesEW })
        }
    }
    # Two diagonal upright blades: yaw the ZY blade by +-45 about y.
    # Length = the 0 deg layer length (never taller than the ring, so it cannot
    # cut into the head cube).
    $v0d = 16 - $len0
    $facesDiag = [ordered]@{
        east = [ordered]@{ uv = @(8, $v0d, 16, 16); texture = '#0' }
        west = [ordered]@{ uv = @(16, $v0d, 8, 16); texture = '#0' }
    }
    [void]$list.Add([ordered]@{
        from = @(8, 0, 4); to = @(8, $len0, 12)
        shade = $false
        rotation = [ordered]@{ angle = 45; axis = 'y'; origin = @(8, 0, 8) }
        faces = $facesDiag })
    [void]$list.Add([ordered]@{
        from = @(8, 0, 4); to = @(8, $len0, 12)
        shade = $false
        rotation = [ordered]@{ angle = -45; axis = 'y'; origin = @(8, 0, 8) }
        faces = $facesDiag })
    # Head cube: slot #1 = top texture, slot #2 = side texture (user ruling).
    $side = [ordered]@{ uv = $cube['side']; texture = '#2' }
    $top  = [ordered]@{ uv = $cube['top'];  texture = '#1' }
    $bottom = [ordered]@{ uv = $cube['top']; texture = '#2' }
    [void]$list.Add([ordered]@{
        from = @($cube['x1'], $headY1, $cube['x1'])
        to   = @($cube['x2'], $cube['y2'], $cube['x2'])
        shade = $false
        faces = [ordered]@{
            north = $side; south = $side; east = $side; west = $side
            up = $top; down = $bottom
        } })
    return ,$list
}

# ---------- 1) shared geometry: copy current reviewed models, not historical v8 ----------
Copy-ReviewedLeafballGeometry

# ---------- 2) per-species textures + wrapper models ----------
$texRoot = Join-Path $root "assets/$NS/textures/block/crop"
foreach ($sp in $species) {
    $n = $sp['n']
    for ($i = 0; $i -lt 6; $i++) {
        New-LeafAtlas (Join-Path $texRoot "${n}_leafball_$i.png") ([int]$sp['r']) ([int]$sp['g']) ([int]$sp['b']) ($i * 1.3)
    }
    New-HeadTexture (Join-Path $texRoot "${n}_leafball_head.png") ([int]$sp['hr']) ([int]$sp['hg']) ([int]$sp['hb'])
    for ($i = 0; $i -lt 6; $i++) {
        $hasHead = ($i -ge 2)
        $texMap = [ordered]@{ '0' = "${NS}:block/crop/${n}_leafball_$i" }
        if ($hasHead) {
            $texMap['1'] = "${NS}:block/crop/${n}_leafball_head_top"
            $texMap['2'] = "${NS}:block/crop/${n}_leafball_head"
        }
        if($n -in @('broccoli','lettuce','cauliflower','napa_cabbage','cabbage')){$texMap['particle']='#0'}
        # (a) this mod's leaf crops
        Save-Json "assets/$NS/models/block/crop/${n}_age_$i.json" ([ordered]@{
            parent   = "${NS}:block/crop/leafball_age_$i"
            textures = $texMap
        })
        # (b) override the vanilla/TFC cabbage in the tfc namespace
        if ($n -eq 'cabbage') {
            Save-Json "assets/tfc/models/block/crop/cabbage_age_$i.json" ([ordered]@{
                parent   = "${NS}:block/crop/leafball_age_$i"
                textures = $texMap
            })
        }
    }
    Write-Host "  $n wrappers (6 ages) ready"
}
# shared fallback textures (so the shared geometry resolves standalone)
for ($i = 0; $i -lt 6; $i++) { New-LeafAtlas (Join-Path $texRoot "leafball_$i.png") 110 150 90 ($i * 1.3) }
New-HeadTexture (Join-Path $texRoot 'leafball_head.png') 180 208 150
Write-Host 'leaf-ball generator done (v8 geometry + tfc cabbage override)'

# Restore current shared JSON and the live native cabbage override after old draft templates.
Copy-ReviewedLeafballGeometry -IncludeNativeCabbage
