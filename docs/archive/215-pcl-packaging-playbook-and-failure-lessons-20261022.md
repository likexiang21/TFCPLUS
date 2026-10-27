# PCL 客户端打包前必读：成功流程与失误复盘（2026-10-22）

> **适用范围：**今后凡是要生成、修改或交付本项目的 PCL 客户端 ZIP，动手前先通读本文，再核对 [214 号运行时重建记录](214-pcl-runtime-rebuild-20261022.md)。本文以用户已经确认能够正常运行的 **v6** 为基线。208～213 号文档是排错历史，其中的旧包、旧版 JSON 修补法和“应可启动”判断不能作为下一次打包指令。

## 一、这次真正成功的交付是什么

- 成功包：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v6.zip`。
- SHA-256：`6D7E57FDD3814104C89E4898EF9560F8C0E25E6EF72F7F2D157AAD97BBA94971`；大小 1,151,481,721 字节。这个哈希只用于识别 **本次 v6**，将来内容变化后应重算，不能复用。
- ZIP 内从 `.minecraft/` 开始，版本定义在 `.minecraft/versions/Essential TerraFirmaCraft (TFC)/Essential TerraFirmaCraft (TFC).json`，同目录有同名主 JAR 与 `PCL/Setup.ini`。根目录另有 `.minecraft/PCL.ini`。
- 包含完整 `assets/objects`、`libraries`、模组、配置、资源包、着色器与测试存档；不依赖旧实例中的手工补丁。
- 制作时完成了独立目录 Java 21 离线启动、日志与归档完整性检查。此后用户在 PCL 中实测并明确反馈“可以正常运行了”。这证明 **v6 在用户当前环境中能启动**；不等于以后改动的包自动通过，也不代表所有游戏功能已重新验收。

## 二、逐次失误及其因果

| 阶段 | 当时所做与现象 | 真正教训 |
| --- | --- | --- |
| 208 号实例包 | 只装入 `mods/config` 等实例内容，PCL “导入整合包”提示文件结构不匹配。 | 该入口需要能识别的 `versions/<版本名>/<版本名>.json`。仅有游戏目录不是 PCL 通用客户端安装包。 |
| 初版客户端包（209） | 补上版本目录，ZIP 通过结构识别，但启动报告 NeoForge、Minecraft 缺失。 | **导入成功只验证布局**，不验证启动器、版本 JSON、运行库能组成可运行客户端。 |
| v2（210） | 手工在 JSON 加入 NeoForge universal 坐标；PCL 转而请求不存在的普通 `neoforge-21.1.248.jar`，下载源均返回 404。 | 不能凭 Maven 坐标想当然推导文件名。NeoForge 安装器产物不是一般可下载依赖，PCL 对版本 JSON 的 `path/url/size` 处理也会改变下载路径。 |
| v3（211） | 补充 universal 的路径、URL 与 `size`，解决了一次 404；后续仍出现 `LoadingOverlay` 缺类。 | 修好下载路径不等于拿到了完整游戏模块。要继续读**新一轮完整错误日志**，不能沿用前一轮诊断。 |
| v4（212） | 手工把 NeoForge client JAR 加进 JSON，且误用 v2 底稿，使普通 JAR 404 回归；文档曾把 client JAR 当作完整客户端运行库。 | 手工补丁和旧底稿会带回已修过的错误。NeoForge client JAR 只有修改过的部分类；原版类在安装器生成的 SRG 客户端 JAR 中。 |
| v5（213） | 再补 universal、client、普通 JAR 别名，静态路径和哈希看似齐全；14:47 报告仍以 `NoClassDefFoundError: ... Overlay` 崩溃。 | 在错误加载层补更多 JAR 不能解决根因。把处理器产物写入 JSON `libraries`，PCL 会把它们作为独立 classpath 项，破坏 NeoForge 本来要合成的 Minecraft 模块。静态检查通过也不能宣布“可运行”。 |
| v6（214） | 从 Minecraft 1.21.1 与 NeoForge 21.1.248 安装器版本信息重建；四个处理器产物放在标准路径，**不**列入版本 JSON 的 `libraries`；随后独立启动与用户 PCL 实测成功。 | 从权威版本定义重新构造，按 NeoForge 自身的模块组装规则提供文件，再做真正的启动验收。 |

14:47 报告中的大量 `minecraft [MISSING]` 是模块未正确组装后的连带症状。关键堆栈是 `DisplayWindow.updateModuleReads` 处缺 `net/minecraft/client/gui/screens/Overlay`。当时 PCL 的 classpath 有 NeoForge universal、client 与版本主 JAR，却没有完整 SRG 客户端内容。后续受控启动进一步证明：四个产物全写进 JSON 导致重复 `neoforge` 模块；仅删除 client 声明又导致 `client` 与 `minecraft` 导出包冲突；四者只存放于正确路径而不加入 JSON 后，NeoForge 自己组装模块并完成启动。

**不要再采用**：复制 v1～v5 JSON 继续补字段；伪造普通 `neoforge-21.1.248.jar` 别名；把 `-client.jar` 当成完整 Minecraft；把下列四个安装器产物加到 JSON 的 `libraries`；仅凭 ZIP 可解压、哈希正确或 PCL 导入成功就宣布可运行。

## 三、下次打包的标准步骤

### 0. 先确认输入，不覆盖旧包

1. 阅读本文与 214 号记录，确认本次目标 Minecraft、NeoForge、Java 与 PCL 版本。若版本已变，重新检查相应安装器的输出与版本定义；下面的 `1.21.1/21.1.248` 路径不可机械套用。
2. 确定作为输入的 **实际可运行实例** `.minecraft` 路径，并盘点 `mods`、`config`、`defaultconfigs`、`kubejs`、`resourcepacks`、`shaderpacks`、`saves`、`assets`。检查模组 JAR 版本及重复文件。保留需要的用户设置和测试存档；不要把源码、Gradle 缓存、旧压缩包、错误日志、崩溃报告打入客户端。
3. 每轮使用新的短路径暂存目录和新的 ZIP 名称。`rebuild-pcl-client.ps1` 默认参数是 2026-10-22 当天的源实例和暂存路径；**下次先核对或显式传入 `-SourceMinecraft`、`-Stage`**。脚本发现 Stage 已存在会拒绝覆盖，不应为了省事直接复用可能被污染的暂存目录。

### 1. 重新建立版本定义与文件树

1. 使用 `D:\TFC农业重置\rebuild-pcl-client.ps1` 建立暂存的 `.minecraft`。脚本只建立目录，**不会生成 ZIP，也不会证明客户端可启动**。先核对脚本读入的 `D:\TFC农业重置\.tooling\game` 确实对应目标版本。
2. 版本 JSON 从原版 `versions/1.21.1/1.21.1.json` 和 NeoForge 安装器 `versions/neoforge-21.1.248/neoforge-21.1.248.json` 合并常规依赖及启动参数，去重坐标，保留 PCL 可识别的同名版本 JSON 和主 JAR。
3. 下面四个文件必须在暂存目录的 `libraries` **实际存在**，路径和版本要逐个核对：

   ```text
   net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar
   net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-extra.jar
   net/neoforged/neoforge/21.1.248/neoforge-21.1.248-client.jar
   net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar
   ```

   **这四个安装器产物不得在版本 JSON 的 `libraries` 数组中声明。**NeoForge 4.0.43 的 `ProductionClientProvider` 按 Maven 路径寻找 SRG、extra、client 并合成 Minecraft 模块；universal 由另一定位器读取。缺文件会缺类，写进 JSON 又会形成重复或冲突模块。
4. 确认 `PCL.ini` 和版本目录的 `PCL/Setup.ini` 随包带入。当前 v6 通过这些设置使用 `.minecraft` 根目录的 `mods`；若下次更改版本隔离，必须同步调整模组实际位置，不能只改 UI 设置。
5. 保留完整 `assets/objects`。v1～v5 小包没有完整资源对象，依赖启动器另行下载；v6 约 1.15 GB 是完整资源随包带来的正常结果，不能为追求小包再漏掉它们。

### 2. 生成 PCL 能识别的 ZIP

归档内部从 `.minecraft/` 开始；不要把绝对路径、外层工作区或另一层无关目录写进 ZIP。核心布局为：

```text
.minecraft/
  PCL.ini
  assets/indexes/...
  assets/objects/...
  libraries/...
  mods/...
  config/...
  versions/Essential TerraFirmaCraft (TFC)/
    Essential TerraFirmaCraft (TFC).json
    Essential TerraFirmaCraft (TFC).jar
    PCL/Setup.ini
```

PCL 的普通 ZIP 导入逻辑靠 `versions/<版本名>/<版本名>.json` 找客户端。归档应当只匹配到 **一个**预期版本路径。打包工具可以变化，但必须以**暂存 `.minecraft` 的父目录**为相对路径基准，使 ZIP 条目保持 `.minecraft/...`。本次 v6 共 4439 个条目，最长相对路径 159 字符；这是本次基线，不是将来必须相等的固定数量。

### 3. 发布前逐项检查，并真的启动

1. 静态检查 ZIP：可完整读取所有条目；只有一个目标版本 JSON；主 JAR、四个产物、`PCL.ini`、`PCL/Setup.ini`、资源对象、模组和配置都在；JSON 可解析且不声明那四个产物；每个 Windows 所需普通依赖有对应文件；内部及目标提取路径不超长。记录 ZIP 大小、条目数与**新算出的** SHA-256。
2. 用**新的空目录**导入 ZIP，不沿用旧失败实例的 libraries、JSON、缓存或手工别名。保留 Java 21，检查 PCL 选择的游戏目录和版本隔离设置，避免读取错一份 `mods`。
3. 实际启动到主菜单并加载约定测试存档，至少确认 Minecraft、NeoForge 与本项目模组加载。若本轮只做了独立离线启动而未完成 PCL GUI 启动，报告必须明确写“独立启动通过、PCL 实际启动待验证”。本次 v6 已获得用户 PCL 运行成功的反馈。
4. 任何失败都保存**本轮** PCL 日志、`latest.log`、`debug.log` 与崩溃报告，先找首个致命异常和完整堆栈，再判断下载、模块组装、模组依赖或游戏内容问题。`minecraft [MISSING]` 等汇总结果不能取代首因分析。修复后用全新版本号和空目录重走步骤 1～3。
5. 交付说明要写清实际测试范围、目标 PCL 导入方式、需要的 Java/版本、包路径和哈希；旧包应标记废弃，避免误装。

## 四、复盘中的工作纪律

- **不要用补丁堆叠代替重建。**这次 v4 误用 v2 底稿，直接使已修复的 404 回归。发现版本定义结构性错误时，回到官方 Minecraft/NeoForge 安装器产物重新构造。
- **不要把“文件存在”当成“文件加载位置正确”。**NeoForge 的生成 JAR 必须由其加载器自己定位和合并，而不是由 PCL 作为普通依赖塞进 classpath。
- **不要把单次错误当成全部原因。**v2、v3、v5 所暴露的问题不相同，每次都需要完整新日志。
- **不要过早宣告完成。**导入、静态检查、独立启动、PCL 启动和游戏内功能验收是不同层级的证据，记录时逐项写明。
- **控制文件路径长度。**归档相对路径、目标安装目录与缓存路径都要核对；优先在短路径构建及导入，避免把项目源码树或多层“新建文件夹”放入压缩包。

## 五、可追溯资料

- [214 号：14:47 报告、模块冲突实验与 v6 交付](214-pcl-runtime-rebuild-20261022.md)。
- [208～213 号](208-pcl-instance-archive-20261021.md)记录了旧包的演变；其中 212 号已明确标记 v4 废弃，213 号的 v5 后来也被 14:47 报告证实不可用。
- 本地构建入口：`D:\TFC农业重置\rebuild-pcl-client.ps1`。用户导入说明：`D:\TFC农业重置\PCL_IMPORT_README.txt`。
- [PCL 官方导入实现](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModModpack.vb)、[版本与依赖处理](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModMinecraft.vb)、[启动流程](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModLaunch.vb)。以后若 PCL 更新，应重新核对对应版本源码，不把这次源码观察当作永恒规则。
