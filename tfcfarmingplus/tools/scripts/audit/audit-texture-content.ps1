# ============================================================
# audit-texture-content.ps1 —— 贴图「内容体检」：不透明像素数分布
# ============================================================
# 由来：第八轮发现 crop/{broccoli,kale,napa_cabbage}_0.png 被像素级变色整张清空（0 个不透明像素），
#      而它们本该是「3 个像素的小芽」—— 游戏里表现为**幼苗完全不可见**，
#      且生成器不报错、verify.ps1 也查不出来（它只查交叉引用）。
# 本脚本把「贴图里到底有没有东西」变成可测量的判据：逐张统计 alpha>=8 的像素数，
# 报出 0 像素（空图）与 <=2 像素（可疑）的清单。
# 用法： & .\audit-texture-content.ps1 [-FailOnEmpty]
# ============================================================
param([switch]$FailOnEmpty)
$ErrorActionPreference = 'Stop'
$drawingAssembly = $null
try {
    Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop
    $drawingAssembly = ([System.Drawing.Bitmap].Assembly).Location
} catch {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $drawingAssembly = ([System.Drawing.Bitmap].Assembly).Location
}
if (-not ('TexContent' -as [type])) {
    $drawingReferences = @($drawingAssembly)
    foreach ($ref in ([System.Drawing.Bitmap].Assembly.GetReferencedAssemblies())) {
        try {
            $drawingReferences += ([System.Reflection.Assembly]::Load($ref)).Location
        } catch {
            # Some framework-only references do not resolve on the current runtime.
        }
    }
    Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Collections;
using System.Drawing;
using System.IO;
using System.Text;
public static class TexContent {
    public static string[] Scan(string root) {
        var lines = new ArrayList();
        var files = Directory.GetFiles(root, "*.png", SearchOption.AllDirectories);
        Array.Sort(files);
        int empty = 0, tiny = 0;
        var empties = new ArrayList();
        var tinies = new ArrayList();
        foreach (var f in files) {
            try {
                using (var bmp = new Bitmap(f)) {
                    int op = 0;
                    for (int y = 0; y < bmp.Height; y++)
                        for (int x = 0; x < bmp.Width; x++)
                            if (bmp.GetPixel(x, y).A >= 8) op++;
                    var rel = f.Substring(root.Length).TrimStart('\\', '/');
                    if (op == 0) { empty++; empties.Add(rel); }
                    else if (op <= 2) { tiny++; tinies.Add(rel + " (" + op + ")"); }
                }
            } catch (Exception e) { lines.Add("ERROR " + f + " : " + e.Message); }
        }
        lines.Add("total png: " + files.Length);
        lines.Add("empty (0 opaque px): " + empty);
        foreach (var s in empties) lines.Add("  EMPTY: " + s);
        lines.Add("tiny (<=2 opaque px): " + tiny);
        foreach (var s in tinies) lines.Add("  TINY: " + s);
        return (string[])lines.ToArray(typeof(string));
    }
}
'@
}
$root = (Resolve-Path (Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources\assets')).Path
$result = [TexContent]::Scan($root)
$result | ForEach-Object { Write-Output $_ }
if ($FailOnEmpty) {
    $emptyLine = $result | Where-Object { $_ -like 'empty (0 opaque px): *' }
    if ($emptyLine -and ($emptyLine -replace '\D','') -ne '0') { exit 1 }
}
