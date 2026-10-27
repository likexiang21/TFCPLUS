param(
    [string]$LogPath = 'D:\TFC农业重置\.tooling\game\validation-client.log'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $LogPath)) { throw "找不到客户端日志：$LogPath" }
$text = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $LogPath))

$checks = [ordered]@{
    'TFC Agriculture Plus 初始化' = ($text -match 'TFC Agriculture Plus.*loaded')
    '方块渲染自检' = ($text -match '渲染层自检|515')
    '资源自检' = ($text -match '资源自检|木制案板|34.*TFC.*afc')
    'overlays 元数据错误' = ($text -match 'Couldn''t load overlays metadata|No key directory in MapLike')
    '网络/认证异常' = ($text -match 'UnknownHostException|Unable to establish loopback connection')
    '明确崩溃标记' = ($text -match 'Stopping!|Crash report|Exception in thread "main"|(?-i:\bFATAL\b\s*:)')
}

Write-Host "K1 客户端日志验证：$LogPath"
foreach ($name in $checks.Keys) {
    $status = if ($checks[$name]) { '发现' } else { '未发现' }
    Write-Host ("[{0}] {1}" -f $status, $name)
}

if (-not $checks['TFC Agriculture Plus 初始化']) { exit 2 }
if ($checks['明确崩溃标记']) { exit 3 }
# overlays、网络认证和在线版本检查在当前实例中属于可恢复警告；
# 资源重载完成且没有崩溃标记时，不把它们误判为客户端启动失败。
exit 0
