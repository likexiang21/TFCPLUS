
param([Parameter(Mandatory=$true)][string[]]$Path, [int]$MaxColors = 34)
Add-Type -AssemblyName System.Drawing
$letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
foreach ($p in $Path) {
  if (-not (Test-Path $p)) { Write-Output "MISSING $p"; continue }
  $bmp = New-Object System.Drawing.Bitmap((Resolve-Path $p).Path)
  $w = $bmp.Width; $h = $bmp.Height
  $counts = @{}
  $grid = @()
  for ($y = 0; $y -lt $h; $y++) {
    $row = @()
    for ($x = 0; $x -lt $w; $x++) {
      $c = $bmp.GetPixel($x, $y)
      if ($c.A -lt 16) { $row += '.' ; continue }
      $key = ('{0:X2}{1:X2}{2:X2}' -f $c.R, $c.G, $c.B)
      if (-not $counts.ContainsKey($key)) { $counts[$key] = 0 }
      $counts[$key]++
      $row += $key
    }
    $grid += ,$row
  }
  $bmp.Dispose()
  $sorted = @($counts.GetEnumerator() | Sort-Object -Property Value -Descending)
  $map = @{}
  $i = 0
  foreach ($kv in $sorted) {
    if ($i -lt $letters.Length) { $map[$kv.Key] = $letters[$i] } else { $map[$kv.Key] = '?' }
    $i++
  }
  $opaque = 0
  foreach ($v in $counts.Values) { $opaque += $v }
  Write-Output ("=== " + (Split-Path $p -Leaf) + "  " + $w + "x" + $h + "  opaque=" + $opaque + " colors=" + $counts.Count + " ===")
  for ($y = 0; $y -lt $h; $y++) {
    $line = ''
    for ($x = 0; $x -lt $w; $x++) {
      $v = $grid[$y][$x]
      if ($v -eq '.') { $line += '.' } else { $line += $map[$v] }
    }
    Write-Output $line
  }
  $i = 0
  foreach ($kv in $sorted) {
    if ($i -ge $MaxColors) { Write-Output ("  ... +" + ($sorted.Count - $MaxColors) + " more"); break }
    Write-Output ("  " + $letters[$i] + " #" + $kv.Key + " x" + $kv.Value)
    $i++
  }
  $lums = New-Object System.Collections.ArrayList
  foreach ($kv in $counts.GetEnumerator()) {
    $r = [Convert]::ToInt32($kv.Key.Substring(0,2),16); $g = [Convert]::ToInt32($kv.Key.Substring(2,2),16); $b = [Convert]::ToInt32($kv.Key.Substring(4,2),16)
    $l = 0.2126*$r + 0.7152*$g + 0.0722*$b
    for ($k = 0; $k -lt $kv.Value; $k++) { [void]$lums.Add($l) }
  }
  if ($lums.Count -gt 0) {
    $m = ($lums | Measure-Object -Average).Average
    $ss = 0.0
    foreach ($l in $lums) { $ss += ($l - $m) * ($l - $m) }
    $sd = [math]::Sqrt($ss / $lums.Count)
    Write-Output ("  LUM min=" + [math]::Round(($lums | Measure-Object -Minimum).Minimum,1) + " max=" + [math]::Round(($lums | Measure-Object -Maximum).Maximum,1) + " avg=" + [math]::Round($m,1) + " sd=" + [math]::Round($sd,1))
  }
  Write-Output ''
}

