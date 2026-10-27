<#
preview-model.ps1 —— 把 block model JSON 渲染成等轴测 PNG（实机前自查几何 + 贴图是否匹配）
用法： & .\preview-model.ps1 -Model 'tfcfarmingplus:block/crop/rosette_age_5' -Out out.png [-Scale 10]
说明：递归解析 parent（本地 assets + TFC jar 贴图），应用 elements.rotation，等轴测正交投影，
      逐像素反算 UV 采样贴图。**自查工具，不等于游戏内渲染**（无光照 / 无 AO / 无染色）。
#>
param(
    [Parameter(Mandatory = $true)][string]$Model,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Scale = 10,
    [double]$YawDeg = 40,
    [double]$PitchDeg = 28
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$assetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\src\main\resources\assets')).Path
$tfcJar = (Get-ChildItem (Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) 'mods') -File -Filter 'TerraFirmaCraft-*.jar' | Sort-Object Name -Descending | Select-Object -First 1).FullName
$script:zip = $null

if (-not ('ModelPreview' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
public static class ModelPreview {
    public static string Render(string outPath, int size, double[] data, string[] texPaths) {
        int n = data.Length / 14;
        int[] order = new int[n];
        double[] keys = new double[n];
        for (int i = 0; i < n; i++) { keys[i] = data[i * 14 + 13]; order[i] = i; }
        Array.Sort(keys, order);
        Bitmap[] tex = new Bitmap[texPaths.Length];
        for (int i = 0; i < texPaths.Length; i++) {
            try { tex[i] = (texPaths[i] != null && File.Exists(texPaths[i])) ? new Bitmap(texPaths[i]) : null; } catch { tex[i] = null; }
        }
        Bitmap bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        Graphics g = Graphics.FromImage(bmp);
        g.Clear(Color.FromArgb(255, 26, 26, 30));
        g.Dispose();
        int drawn = 0;
        for (int oi = 0; oi < n; oi++) {
            int i = order[oi];
            int b = i * 14;
            double x0 = data[b + 0], y0 = data[b + 1], x1 = data[b + 2], y1 = data[b + 3];
            double x2 = data[b + 4], y2 = data[b + 5], x3 = data[b + 6], y3 = data[b + 7];
            double u1 = data[b + 8], v1 = data[b + 9], u2 = data[b + 10], v2 = data[b + 11];
            int ti = (int)data[b + 12];
            Bitmap t = (ti >= 0 && ti < tex.Length) ? tex[ti] : null;
            double ax = x1 - x0, ay = y1 - y0, bx = x3 - x0, by = y3 - y0;
            double det = ax * by - bx * ay;
            if (Math.Abs(det) < 1e-9) continue;
            double minX = Math.Min(Math.Min(x0, x1), Math.Min(x2, x3));
            double maxX = Math.Max(Math.Max(x0, x1), Math.Max(x2, x3));
            double minY = Math.Min(Math.Min(y0, y1), Math.Min(y2, y3));
            double maxY = Math.Max(Math.Max(y0, y1), Math.Max(y2, y3));
            int px0 = Math.Max(0, (int)Math.Floor(minX));
            int px1 = Math.Min(size - 1, (int)Math.Ceiling(maxX));
            int py0 = Math.Max(0, (int)Math.Floor(minY));
            int py1 = Math.Min(size - 1, (int)Math.Ceiling(maxY));
            if (px1 < px0 || py1 < py0) continue;
            for (int py = py0; py <= py1; py++) {
                for (int px = px0; px <= px1; px++) {
                    double rx = px + 0.5 - x0, ry = py + 0.5 - y0;
                    double s = (rx * by - ry * bx) / det;
                    double tt = (ax * ry - ay * rx) / det;
                    if (s < 0 || s > 1 || tt < 0 || tt > 1) continue;
                    int col;
                    if (t == null) { col = unchecked((int)0xFFFF00FF); }
                    else {
                        int tw = t.Width, th = t.Height;
                        int sx = (int)((u1 + (u2 - u1) * s) * tw / 16.0);
                        int sy = (int)((v1 + (v2 - v1) * tt) * th / 16.0);
                        if (sx < 0) sx = 0;
                        if (sx >= tw) sx = tw - 1;
                        if (sy < 0) sy = 0;
                        if (sy >= th) sy = th - 1;
                        col = t.GetPixel(sx, sy).ToArgb();
                        if (((col >> 24) & 0xFF) < 8) continue;
                    }
                    bmp.SetPixel(px, py, Color.FromArgb(col));
                }
            }
            drawn++;
        }
        string dir = Path.GetDirectoryName(Path.GetFullPath(outPath));
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        bmp.Save(outPath, ImageFormat.Png);
        bmp.Dispose();
        for (int i = 0; i < tex.Length; i++) if (tex[i] != null) tex[i].Dispose();
        return "faces=" + drawn + "/" + n;
    }
}
'@
}

function Get-JsonFromRef([string]$ref) {
    if ($ref -match ':') { $ns, $p = $ref -split ':', 2 } else { $ns = 'minecraft'; $p = $ref }
    $f = Join-Path $assetRoot "$ns\models\$p.json"
    if (Test-Path $f) { return (Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json) }
    return $null
}

function Resolve-Model([string]$ref) {
    $j = Get-JsonFromRef $ref
    if ($null -eq $j) { return @{ elements = @(); textures = @{} } }
    $tex = @{}
    $elems = @()
    if ($j.parent) {
        $pr = Resolve-Model $j.parent
        $tex = $pr.textures
        $elems = $pr.elements
    }
    if ($j.textures) { foreach ($k in $j.textures.PSObject.Properties) { $tex[$k.Name] = $k.Value } }
    if ($j.elements) { $elems = @($j.elements) }
    return @{ elements = $elems; textures = $tex }
}

function Get-TexPath([string]$name) {
    if ($name -match ':') { $ns, $p = $name -split ':', 2 } else { $ns = 'minecraft'; $p = $name }
    $f = Join-Path $assetRoot "$ns\textures\$p.png"
    if (Test-Path $f) { return $f }
    if ($ns -eq 'tfc' -and (Test-Path $tfcJar)) {
        if ($null -eq $script:zip) { $script:zip = [System.IO.Compression.ZipFile]::OpenRead($tfcJar) }
        $e = $script:zip.GetEntry("assets/tfc/textures/$p.png")
        if ($e) {
            $tmp = Join-Path $env:TEMP ("tfcpreview_" + [Math]::Abs($p.GetHashCode()) + ".png")
            if (-not (Test-Path $tmp)) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $tmp, $true) }
            return $tmp
        }
    }
    return $null
}

function Get-Rotated($v, $rot) {
    $vx = [double]$v[0]; $vy = [double]$v[1]; $vz = [double]$v[2]
    if ($null -eq $rot) { return @($vx, $vy, $vz) }
    $rad = [double]$rot.angle * [Math]::PI / 180.0
    $ox = [double]$rot.origin[0]; $oy = [double]$rot.origin[1]; $oz = [double]$rot.origin[2]
    $c = [Math]::Cos($rad); $s = [Math]::Sin($rad)
    $x = $vx - $ox; $y = $vy - $oy; $z = $vz - $oz
    $ax = [string]$rot.axis
    if ($ax -eq 'x') { $ny = $y * $c - $z * $s; $z = $y * $s + $z * $c; $y = $ny }
    elseif ($ax -eq 'y') { $nx = $x * $c + $z * $s; $z = -$x * $s + $z * $c; $x = $nx }
    else { $nx = $x * $c - $y * $s; $y = $x * $s + $y * $c; $x = $nx }
    return @(($x + $ox), ($y + $oy), ($z + $oz))
}

$resolved = Resolve-Model $Model
$yaw = $YawDeg * [Math]::PI / 180.0
$pitch = $PitchDeg * [Math]::PI / 180.0
$size = 16 * $Scale * 2

function Project($v) {
    $x = [double]$v[0] - 8.0
    $y = [double]$v[1] - 8.0
    $z = [double]$v[2] - 8.0
    $xr = $x * [Math]::Cos($yaw) + $z * [Math]::Sin($yaw)
    $zr = -$x * [Math]::Sin($yaw) + $z * [Math]::Cos($yaw)
    $yr = $y * [Math]::Cos($pitch) - $zr * [Math]::Sin($pitch)
    $zd = $y * [Math]::Sin($pitch) + $zr * [Math]::Cos($pitch)
    return @(($size / 2.0 + $xr * $Scale), ($size / 2.0 - $yr * $Scale), $zd)
}

# MC convention: for EVERY face, seen from OUTSIDE the block, u runs right and
# v runs DOWN, with model uv[0,1] at the TOP-LEFT corner of the quad.
# Indices address the 8-corner array: 0..3 = y=from ring, 4..7 = y=to ring,
# each ring ordered (x0z0, x1z0, x1z1, x0z1).
# The old table started each quad at its BOTTOM-LEFT corner, which flipped V on
# all four vertical faces (and on down) -> every plant texture previewed upside-down.
$faceDefs = [ordered]@{
    north = @(4, 5, 1, 0); south = @(6, 7, 3, 2)
    west  = @(4, 7, 3, 0); east  = @(6, 5, 1, 2)
    up    = @(4, 5, 6, 7); down  = @(3, 2, 1, 0)
}
$texNames = New-Object System.Collections.ArrayList
$texPaths = New-Object System.Collections.ArrayList
$data = New-Object System.Collections.ArrayList

foreach ($el in $resolved.elements) {
    $fx = [double]$el.from[0]; $fy = [double]$el.from[1]; $fz = [double]$el.from[2]
    $tx = [double]$el.to[0];   $ty = [double]$el.to[1];   $tz = [double]$el.to[2]
    $base = @(
        @($fx, $fy, $fz), @($tx, $fy, $fz), @($tx, $fy, $tz), @($fx, $fy, $tz),
        @($fx, $ty, $fz), @($tx, $ty, $fz), @($tx, $ty, $tz), @($fx, $ty, $tz)
    )
    $verts = @()
    foreach ($v in $base) { $verts += , (Get-Rotated $v $el.rotation) }
    foreach ($fname in $faceDefs.Keys) {
        $face = $el.faces.$fname
        if ($null -eq $face) { continue }
        $tref = [string]$face.texture
        $tname = $tref
        if ($tref.StartsWith('#')) { $tname = [string]$resolved.textures[$tref.Substring(1)] }
        if ([string]::IsNullOrWhiteSpace($tname)) { continue }
        $uv = $face.uv
        if ($null -eq $uv) { $uv = @(0, 0, 16, 16) }
        $idx = $faceDefs[$fname]
        $pts = @()
        for ($i = 0; $i -lt 4; $i++) { $pts += , (Project $verts[$idx[$i]]) }
        $depth = ([double]$pts[0][2] + [double]$pts[1][2] + [double]$pts[2][2] + [double]$pts[3][2]) / 4.0
        $ti = $texNames.IndexOf($tname)
        if ($ti -lt 0) { $ti = $texNames.Count; [void]$texNames.Add($tname); [void]$texPaths.Add((Get-TexPath $tname)) }
        foreach ($p in $pts) { [void]$data.Add([double]$p[0]); [void]$data.Add([double]$p[1]) }
        [void]$data.Add([double]$uv[0]); [void]$data.Add([double]$uv[1])
        [void]$data.Add([double]$uv[2]); [void]$data.Add([double]$uv[3])
        [void]$data.Add([double]$ti)
        [void]$data.Add($depth)
    }
}

$info = [ModelPreview]::Render($Out, $size, [double[]]$data.ToArray(), [string[]]$texPaths.ToArray())
if ($null -ne $script:zip) { $script:zip.Dispose() }
Write-Host ("preview: $Out  ($info; elements=$($resolved.elements.Count); textures=$($texNames.Count))")
