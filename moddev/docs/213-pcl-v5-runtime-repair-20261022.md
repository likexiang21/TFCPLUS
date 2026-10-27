# PCL v5 启动包与现有实例修复（2026-10-22）

## 用户截图与根因

新截图显示 PCL 下载 `net/neoforged/neoforge/21.1.248/neoforge-21.1.248.jar`，BMCLAPI 返回 404。NeoForge 21.1.248 官方发布的是 `neoforge-21.1.248-universal.jar`。v4 使用 v2 的打包底稿，虽然补进 client JAR，但 universal 条目仍缺少 `size`，使 PCL 回退到普通 JAR 路径。这是打包回归，v4 应废弃。

## 已做的修复

1. 源版本 JSON、v5 包版本 JSON和用户当前 PCL 实例版本 JSON都登记 `net.neoforged:neoforge:21.1.248`，artifact 指向 `neoforge-21.1.248-universal.jar`，完整提供路径、大小 3,551,268 和 SHA-1 `9a97bebbd7641685052d59368bb32c56ecb9c913`。
2. 三份 JSON 都登记 `net.neoforged:neoforge:21.1.248:client`，artifact 指向 `neoforge-21.1.248-client.jar`，大小 5,675,624 和 SHA-1 `bab98816cfdbccc1e9076872771ef81f39afbcc9`。这个客户端运行库含 `net/minecraft/client/gui/screens/LoadingOverlay.class`。
3. v5 包与当前实例的 `.minecraft/libraries/net/neoforged/neoforge/21.1.248/` 内置上述 universal 与 client 文件；另放置一份内容等同 universal 的 `neoforge-21.1.248.jar`，覆盖 PCL 回退查找路径，避免再次请求错误的远端普通 JAR。
4. 用户当前实例的旧 JSON 已备份为 `D:\TFC农业重置\实机测试文件夹\新建文件夹\PCL-version-json-before-v5-20261022.json`，其存档和模组未更改。

## 交付

- 原地修补的实例：`D:\TFC农业重置\实机测试文件夹\新建文件夹\TFCAgriculturePlus-PCL`
- 可重新导入的包：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v5.zip`
- v5 SHA-256：`89453CDDFC08AF6984599B2F0B2DB2F7E5E80244DAE08F7682F9817BB037F7D6`

现在应直接在 PCL 启动现有实例。文件结构与哈希已核对；PCL 实际启动尚未由本记录宣称通过。如果出现新的启动错误，应依据这次启动生成的日志继续定位。
