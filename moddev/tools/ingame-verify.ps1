# ingame-verify.ps1 —— 无人值守实机验证：激活游戏窗口 -> 注入聊天命令 -> F2 截图
param([string[]]$Commands, [switch]$Maximize)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
if (-not ('Win32Focus' -as [type])) {
    $code = @'
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    // ⚠️⚠️ 绝不要用「鼠标点击」来激活窗口 —— 用户已实际反馈副作用。
    //   原因：launch-client.ps1 会把窗口最大化，此时窗口矩形是 (-7,-7)-(2055,1239)，
    //   标题栏被推到屏幕外，而旧代码点的是 (窗口中心, Top+8) = 屏幕 y≈1 的位置 ——
    //   那**落在游戏画面里**。MC 一旦拿到焦点就锁定鼠标，于是这一点变成：
    //   左键 = 挖掘/攻击（把刚放下的方块挖掉、把作物打掉），右键 = 使用/放置。
    //   改用 AttachThreadInput + BringWindowToTop + SetForegroundWindow；
    //   仍抢不到焦点时按一下 Alt（系统键，Windows 会当作激活手势，MC 内无绑定），
    //   全程不产生任何鼠标事件。
    public static bool Activate(IntPtr hWnd) {
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
        uint myThread = GetCurrentThreadId();
        AttachThreadInput(myThread, fgThread, true);
        BringWindowToTop(hWnd);
        SetForegroundWindow(hWnd);
        AttachThreadInput(myThread, fgThread, false);
        System.Threading.Thread.Sleep(300);
        if (GetForegroundWindow() == hWnd) return true;
        const byte VK_MENU = 0x12;
        const uint KEYEVENTF_KEYUP = 0x0002;
        keybd_event(VK_MENU, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(60);
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        System.Threading.Thread.Sleep(320);
        return GetForegroundWindow() == hWnd;
    }
}
'@
    Add-Type -TypeDefinition $code
}
# ⚠️ 必须优先按 launch-client.ps1 落盘的 PID 锁定「本工程启动的那个」客户端窗口。
#    用户可能同时开着别的 Minecraft 实例（本机实测有一个 1.20.1 的），
#    只按窗口标题 Select -First 1 有可能把聊天命令注入到**用户的游戏**里 —— 那是不可接受的。
$pidFile = Join-Path $env:TEMP 'tfcflora-client.pid'
$proc = $null
if (Test-Path $pidFile) {
    $ownPid = 0
    $raw = (Get-Content $pidFile -Raw).Trim()
    if ([int]::TryParse($raw, [ref]$ownPid)) {
        $proc = Get-Process -Id $ownPid -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -eq 0) { $proc = $null }   # 窗口还没建好
    }
}
if (-not $proc) {
    Write-Output '⚠ 本实例 PID 未命中，退回按窗口标题匹配（有误注入他人实例的风险）'
    $proc = Get-Process | Where-Object { $_.MainWindowTitle -like '*Minecraft*' } | Select-Object -First 1
}
if (-not $proc) { Write-Output 'FAIL: no Minecraft window'; exit 1 }
Write-Output ('window: ' + $proc.ProcessName + ' :: ' + $proc.MainWindowTitle)
if ($Maximize) { [void][Win32Focus]::ShowWindow($proc.MainWindowHandle, 3); Start-Sleep -Milliseconds 1000 }
$ok = [Win32Focus]::Activate($proc.MainWindowHandle)
if (-not $ok) { Start-Sleep -Milliseconds 700; $ok = [Win32Focus]::Activate($proc.MainWindowHandle) }
if (-not $ok) { Write-Output 'FAIL: cannot focus game window'; exit 1 }
Write-Output 'foreground OK'
Start-Sleep -Milliseconds 600
foreach ($cmd in $Commands) {
    Set-Clipboard -Value ($cmd.TrimStart('/') -replace '^/', '')   # 聊天框自己会带 /，粘贴内容必须去掉开头的斜杠
    Start-Sleep -Milliseconds 250
    [System.Windows.Forms.SendKeys]::SendWait('/')
    Start-Sleep -Milliseconds 350
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 350
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    Start-Sleep -Milliseconds 1000
    Write-Output ('sent: ' + $cmd)
}
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait('{F2}')
Start-Sleep -Milliseconds 1500
Write-Output 'screenshot key sent'