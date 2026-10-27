# ============================================================
# 启动实例客户端（用于验证模组是否真的加载）
# ------------------------------------------------------------
# 为什么不用启动器：需要无人值守地启动一次并直接读日志验证。
# 本脚本完全按 versions/<ver>.json 的 arguments 重建命令行，
# 与 PCL 的启动方式等价（BootstrapLauncher + module path + 144 个库的 classpath）。
#
# 用法：
#   .\launch-client.ps1                          # 默认**直接进入 tfctest**（无人值守验证用）
#   .\launch-client.ps1 -QuickPlay "新的世界"     # 进入指定存档
#   .\launch-client.ps1 -QuickPlay ""            # 停在主菜单
#
# ⚠️ 为什么默认值不是空串：本脚本的唯一用途就是「启动一次并直接读日志验证」，
#    而停在主菜单的会话里**不会加载世界、不会跑数据包、不会触发随机刻** ——
#    日志照样有模组加载信息，看日志会以为验证过了，实际什么都没验。
#    曾因此连续多次误判（日志里只有启动信息，没有 "open world"）。
param(
    [string]$QuickPlay = "tfctest",
    [int]$Width = 1280,
    [int]$Height = 720,
    [switch]$Visible,
    [switch]$Wait
)
$ErrorActionPreference = 'Stop'

$verName  = "Essential TerraFirmaCraft (TFC)"
$inst     = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workspace = (Resolve-Path (Join-Path $inst '..\..')).Path
$mc       = Join-Path $workspace '.tooling\game'
$jdk      = Get-ChildItem (Join-Path $workspace '.tooling\jdk21') -Directory | Select-Object -First 1
$java     = Join-Path $jdk.FullName 'bin\java.exe'
$natives  = Join-Path $inst "$verName-natives"
$libs     = Join-Path $mc 'libraries'
$outLog   = Join-Path $mc 'validation-client.log'
$errLog   = Join-Path $mc 'validation-client-error.log'

if (-not $jdk -or -not (Test-Path $java)) { throw "找不到项目自带 Java: $java" }
if (-not (Test-Path $natives)) { throw "找不到 natives: $natives" }
if (-not (Test-Path (Join-Path $mc 'ready.json'))) { throw "本地运行时尚未准备完成: $mc" }

$json = Get-Content (Join-Path $inst "$verName.json") -Raw | ConvertFrom-Json

# 与本机匹配的库规则判定（windows / 非 osx；features 一律不启用；arch 只认 x86 之外的默认）
function Test-Rules($rules) {
    if (-not $rules) { return $true }
    $allowed = $false
    foreach ($r in $rules) {
        $match = $true
        if ($r.os) {
            if ($r.os.name -and $r.os.name -ne 'windows') { $match = $false }
            if ($r.os.arch -and $r.os.arch -eq 'x86')     { $match = $false }
        }
        if ($r.features) { $match = $false }
        if ($match) { $allowed = ($r.action -eq 'allow') }
    }
    return $allowed
}

# ---------- classpath ----------
$cp = New-Object System.Collections.Generic.List[string]
foreach ($lib in $json.libraries) {
    if (-not (Test-Rules $lib.rules)) { continue }
    $rel = $null
    if ($lib.downloads -and $lib.downloads.artifact) {
        $rel = $lib.downloads.artifact.path
    } elseif ($lib.name) {
        $p = $lib.name -split ':'
        $grp = $p[0] -replace '\.', '/'
        $art = $p[1]; $ver = $p[2]
        $cls = if ($p.Count -gt 3) { "-$($p[3])" } else { '' }
        $rel = "$grp/$art/$ver/$art-$ver$cls.jar"
    }
    # ⚠️ 必须去重：json 里存在指向同一 jar 的重复条目，
    #    BootstrapLauncher 的 UnionFileSystem 遇到重复 key 会直接抛 IllegalStateException
    if ($rel) {
        $full = Join-Path $libs $rel
        if (-not $cp.Contains($full)) { $cp.Add($full) }
    }
}
$verJar = Join-Path $inst "$verName.jar"
if (-not $cp.Contains($verJar)) { $cp.Add($verJar) }

# ---------- JVM 参数（照抄 json，替换占位符）----------
$jvmArgs = New-Object System.Collections.Generic.List[string]
$j = $json.arguments.jvm
for ($i = 0; $i -lt $j.Count; $i++) {
    $a = $j[$i]
    if ($a -isnot [string]) {
        if (-not (Test-Rules $a.rules)) { continue }
        $v = $a.value
        if ($v -is [array]) { foreach ($x in $v) { $jvmArgs.Add($x) } } else { $jvmArgs.Add($v) }
        continue
    }
    if ($a -eq '-cp') {
        $jvmArgs.Add('-cp'); $jvmArgs.Add(($cp -join ';')); $i++; continue
    }
    if ($a -eq '-p') {
        $mp = $j[$i + 1]
        $mp = $mp.Replace('${library_directory}', $libs).Replace('${classpath_separator}', ';')
        $jvmArgs.Add('-p'); $jvmArgs.Add($mp); $i++; continue
    }
    $s = $a.Replace('${natives_directory}', $natives)
    $s = $s.Replace('${library_directory}', $libs)
    $s = $s.Replace('${launcher_name}', 'PCL')
    $s = $s.Replace('${launcher_version}', '2.8.0')
    $s = $s.Replace('${version_name}', $verName)
    $jvmArgs.Add($s)
}

# 打开模组的开发期自检命令（/tfcfarmingplus probe|randomtick|setcounter|calendar）。
# 该命令默认不注册，只有带这个系统属性时才挂载 —— 正式包里玩家看不到它。
$jvmArgs.Add('-Dtfcfarmingplus.debug=true')

# 生长加速开关（**仅供快速检查外观**，用户要求检查完必须还原）：
#   打开时莲座作物每次生长 tick 进度放大、树干果实每次 randomTick 必进、
#   果树枝条每次额外推进大量 tick（见 common/FastGrow.java）。
#   需要临时加速时把下面这行加回来即可 —— 它只影响本次启动，
#   不动任何生长常量，也不会进正式包。
# $jvmArgs.Add('-Dtfcfarmingplus.fastgrow=true')
# ⚠️ 2026 本轮检查已结束：**已还原为不加速**（默认关闭），生长速率与正式包一致。

# ---------- 游戏参数 ----------
$gameArgs = New-Object System.Collections.Generic.List[string]
foreach ($a in @(
    '--username', 'APlayerInMC',
    '--version', $verName,
    '--gameDir', $inst,
    '--assetsDir', (Join-Path $mc 'assets'),
    '--assetIndex', $json.assetIndex.id,
    '--uuid', 'ff27958fad74420f8da26a30f0b4dd62',
    '--accessToken', '0',
    '--clientId', '0',
    '--xuid', '0',
    '--userType', 'msa',
    '--versionType', 'PCL',
    '--width', "$Width",
    '--height', "$Height",
    '--fml.neoForgeVersion', '21.1.248',
    '--fml.fmlVersion', '4.0.43',
    '--fml.mcVersion', '1.21.1',
    '--fml.neoFormVersion', '20240808.144430',
    '--launchTarget', 'forgeclient'
)) { $gameArgs.Add($a) }
if ($QuickPlay) { $gameArgs.Add('--quickPlaySingleplayer'); $gameArgs.Add($QuickPlay) }

# ---------- 组装命令行（含空格/中文的参数加引号）----------
$all = @($jvmArgs) + @($json.mainClass) + @($gameArgs)
$argStr = ($all | ForEach-Object { if ($_ -match '[\s]') { '"' + $_ + '"' } else { $_ } }) -join ' '

Write-Host "Java: $java"
Write-Host "classpath 条目数: $($cp.Count)，命令行长度: $($argStr.Length)"
Write-Host "标准输出日志: $outLog"

# ---------- 启动前关掉独占全屏 + 关掉失焦暂停 ----------
# options.txt 里的 fullscreen:true 会让游戏启动瞬间先进独占全屏（黑一下/闪一下），
# 随后才被下面的最大化逻辑拉回窗口。所以每次启动前先确保它是 false。
#
# pauseOnLostFocus 一并关掉：单人游戏默认「窗口失焦就暂停」，而无人值守验证时窗口必然失焦 ——
# 那会让整个世界停摆（schedule、随机刻、日历都不推进），表现为「命令排了却不执行」。
# stop-own-client.ps1 会在关闭时把它改回 true，**所以用户环境本身不会被动过**。
$optFile = Join-Path $inst 'options.txt'
if (Test-Path $optFile) {
    $oc = [System.IO.File]::ReadAllText($optFile)
    if ($oc -match '(?m)^fullscreen:') { $oc = [regex]::Replace($oc, '(?m)^fullscreen:.*$', 'fullscreen:false') }
    else { $oc = $oc.TrimEnd() + "`r`nfullscreen:false`r`n" }
    if ($oc -match '(?m)^pauseOnLostFocus:') { $oc = [regex]::Replace($oc, '(?m)^pauseOnLostFocus:.*$', 'pauseOnLostFocus:false') }
    else { $oc = $oc.TrimEnd() + "`r`npauseOnLostFocus:false`r`n" }
    [System.IO.File]::WriteAllText($optFile, $oc)
    Write-Host "已关闭独占全屏 (fullscreen:false) 与失焦暂停 (pauseOnLostFocus:false)"
}
Remove-Item $outLog, $errLog -ErrorAction SilentlyContinue
# 使用 Start-Process 统一处理 Windows PowerShell 5 和 PowerShell 7：
# ProcessStartInfo.ArgumentList 仅在较新的 .NET 中可用，且 PowerShell 的
# DataReceived 事件回调在线程池线程中没有稳定的 Runspace，容易使启动脚本崩溃。
# 这里保留标准输出/错误重定向，由系统直接写入日志文件。
$proc = Start-Process -FilePath $java -WorkingDirectory $inst -ArgumentList $argStr `
    -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
if (-not $proc) { throw 'Java 进程未能启动。' }
Write-Host "已启动，PID = $($proc.Id)"
# 把 PID 落盘，供 stop-own-client.ps1 精准关闭。
# ⚠️ 不要用 Get-Process java | Stop-Process —— 那会连用户同时开着的其它 Minecraft 实例一起杀掉。
#    也不能按命令行匹配：本机 WMI 返回的 CommandLine 是截断的（只剩进程标题），匹配不上。
Set-Content -Path (Join-Path $env:TEMP 'tfcflora-client.pid') -Value $proc.Id -Encoding ASCII

# ---------- 启动后把游戏窗口「最大化」----------
# 「窗口化全屏」= 像点标题栏那个最大化按钮一样，让窗口占满**工作区**，
# 标题栏 / 拖动 / 最小化 / **还原按钮** 全部保留 —— 它就是一个最大化的普通窗口。
#
# ⚠️ 下面这两样都试过、都不对：
#   ① F11 —— 那是独占全屏，会切分辨率、alt+tab 黑屏；
#   ② SetWindowPos 把窗口硬拉成屏幕尺寸 —— 窗口不处于「最大化」状态，
#      还原按钮行为是错的，尺寸还会被 DPI 缩放算错。
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DshMax {
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    [DllImport("user32.dll")] static extern bool IsZoomed(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rt, B; }
    public static bool Maximize(IntPtr h) {
        if (IsZoomed(h)) return true;   // 已经是最大化就别再动
        ShowWindow(h, 9);               // SW_RESTORE：先复位，避免从最小化状态直接最大化失败
        return ShowWindow(h, 3);        // SW_MAXIMIZE
    }
    public static bool IsMax(IntPtr h) { return IsZoomed(h); }
}
"@ -ErrorAction SilentlyContinue

$deadline = (Get-Date).AddSeconds(150)
$game = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 4
    # ⚠️ 必须按**刚启动的那个 PID** 找窗口，不能用 Get-Process java | Select -First 1：
    #    用户同时开着别的 Minecraft 实例时，那个写法会选中**别人的窗口**（往往已经是最大化状态），
    #    于是 IsZoomed 直接返回 true、脚本原样跳过，我们新启动的窗口压根没被处理 —— 表现为「最大化失效」。
    $game = $null
    for ($try = 0; $try -lt 60; $try++) {
        $cand = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
        if ($cand -and $cand.MainWindowHandle -ne 0) { $game = $cand; break }
        Start-Sleep -Milliseconds 500
    }
    if ($game) { break }
}
if ($game) {
    Start-Sleep -Seconds 12          # 等窗口尺寸定型
    $game.Refresh()
    $r = New-Object DshMax+R
    [void][DshMax]::GetWindowRect($game.MainWindowHandle, [ref]$r)
    Write-Host ("窗口 PID=$($game.Id)  最大化前: {0}x{1} @ {2},{3}  最大化状态={4}" -f ($r.Rt-$r.L), ($r.B-$r.T), $r.L, $r.T, [DshMax]::IsMax($game.MainWindowHandle))
    [void][DshMax]::Maximize($game.MainWindowHandle)
    Start-Sleep -Seconds 3
    $game.Refresh()
    [void][DshMax]::GetWindowRect($game.MainWindowHandle, [ref]$r)
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    Write-Host ("最大化后: {0}x{1} @ {2},{3}  最大化状态={4}  (工作区 {5}x{6})" -f ($r.Rt-$r.L), ($r.B-$r.T), $r.L, $r.T, [DshMax]::IsMax($game.MainWindowHandle), $wa.Width, $wa.Height)
} else {
    Write-Host "⚠ 未检测到游戏窗口，跳过最大化"
}

if ($Wait) {
    $proc.WaitForExit()
    Write-Host "Java 进程已退出，退出码 = $($proc.ExitCode)"
}
