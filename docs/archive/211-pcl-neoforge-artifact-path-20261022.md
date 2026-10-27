# PCL NeoForge 通用包路径修复记录（2026-10-22）

## v2 的二次问题

v2 已声明 NeoForge 通用包 URL，但没有提供 Maven artifact 的 `size` 字段。PCL 读取该字段时进入异常回退逻辑，使用默认坐标路径 `neoforge-21.1.248.jar`，导致 BMCLAPI 和 libraries 镜像均返回 404。

PCL 的库解析逻辑会在 artifact 同时提供 `url`、`path` 和 `size` 时使用自定义路径；本次修复补齐了 `size: 0`（表示不做大小校验），保留官方通用包 URL 和 `universal.jar` 路径。

## v3 修复包

- 文件：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v3.zip`
- SHA-256：`FC9AFFF97C8871F2958FE48C9ACFFD46F4D78C16354435AB8C407D65E6CE55E2`
- 版本 JSON 依赖：`net.neoforged:neoforge:21.1.248`
- artifact 路径：`net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar`
- artifact URL：`https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar`
- 首次启动时 PCL 应请求带 `-universal.jar` 的路径，不再请求普通 `neoforge-21.1.248.jar`。

## 使用

请使用 v3 压缩包导入新的空实例，保持网络连接后首次启动。若仍出现 404，应把 PCL 启动器的下载源切换为官方源后重试；此时请求路径应仍然是 `neoforge-21.1.248-universal.jar`。
