# stop-own-client.ps1 —— **只**停止本工程启动的那个客户端实例。
#
# ⚠️ 两条弯路，都别再走：
#   1. `Get-Process java | Stop-Process -Force` 是**无差别杀死所有 java 进程** ——
#      用户同时开着的其它 Minecraft 实例会被一起关掉（已实际发生，用户明确反馈过）。
#   2. 按命令行匹配也不行：本机 WMI 返回的 Win32_Process.CommandLine 是**截断的**
#      （实测只剩 56 个字符的进程标题），匹配不到版本目录或 mod 名。
#
# 因此改为：launch-client.ps1 启动时把 PID 写进 %TEMP%\tfcflora-client.pid，本脚本只关这个 PID。
$ErrorActionPreference = 'Stop'
$pidFile = Join-Path $env:TEMP 'tfcflora-client.pid'

# 关闭前先把 launch-client.ps1 为无人值守验证临时改掉的 pauseOnLostFocus 还回去，
# 保证用户环境本身不被改动。
$optFile = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\options.txt'
if (Test-Path $optFile) {
    $oc = [System.IO.File]::ReadAllText($optFile)
    if ($oc -match '(?m)^pauseOnLostFocus:') {
        $oc2 = [regex]::Replace($oc, '(?m)^pauseOnLostFocus:.*$', 'pauseOnLostFocus:true')
        if ($oc2 -ne $oc) { [System.IO.File]::WriteAllText($optFile, $oc2); Write-Host '已还原 pauseOnLostFocus:true' }
    }
}

if (-not (Test-Path $pidFile)) { Write-Host '没有记录过本实例的 PID，什么都不做'; exit 0 }
$targetPid = [int](Get-Content $pidFile -Raw).Trim()
$proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
if (-not $proc) { Write-Host "PID $targetPid 已不在运行"; Remove-Item $pidFile -Force -ErrorAction SilentlyContinue; exit 0 }
if ($proc.ProcessName -ne 'java') { Write-Host "PID $targetPid 不是 java 进程（$($proc.ProcessName)），为安全起见不关"; exit 0 }
# ⚠️⚠️ 优先「优雅退出」，不要一上来就强杀 —— 用户已实际反馈：
#    强杀会让**下次进入世界时玩家位置不可控**（游戏来不及在退出流程里保存玩家数据，
#    下次会落在「上一次自动保存」的位置，而不是最后一次 tp/站位）。
#    CloseMainWindow() 等价于点窗口的关闭按钮：MC 会先保存世界 + 玩家数据再退出。
#    只有在优雅退出超时的情况下才回退到 Stop-Process。
Write-Host "请求游戏正常退出（会先保存世界与玩家位置）..."
$graceful = $false
try { $graceful = $proc.CloseMainWindow() } catch { $graceful = $false }
if ($graceful) {
    $waited = 0
    while ($waited -lt 120) {
        Start-Sleep -Seconds 3
        $waited += 3
        try { $proc.Refresh() } catch {}
        if ($proc.HasExited) { break }
    }
}
if ($proc.HasExited) {
    Write-Host ("已正常退出（等待 $waited 秒，世界与玩家位置已保存）PID $targetPid")
} else {
    Write-Host "⚠ 正常退出超时/不可用，回退为强制结束（下次进入位置可能不可控）"
    Stop-Process -Id $targetPid -Force
}
Remove-Item $pidFile -Force -ErrorAction SilentlyContinue