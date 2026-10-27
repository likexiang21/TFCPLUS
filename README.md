# TFCPLUS：农业与生活系统开发工作区

这是当前项目的源码、资源、开发记录及构建产物快照。2026年10月27日，用户要求暂停功能开发，先整理并上传GitHub。当前完成至 **AR4-AG 大黄显示链**，下一片芦笋仍在计划中，等待用户明确恢复。

## 从哪里阅读

- [当前状态与本项目构建产物](CURRENT_DELIVERY.json)
- [最新交接：大黄显示链与待验限制](moddev/docs/271-ar4ag-rhubarb-native16-display-20261027.md)
- [暂停开发与此次上传范围](moddev/docs/272-github-snapshot-and-development-pause-20261027.md)
- [农业总体计划](moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md)与[农业审计台账](moddev/docs/218-agriculture-audit-baseline-20261023.md)
- [工作区原始总入口及历史记录](WORKSPACE_README.md)
- [开发规则](DEVELOPMENT_RULES.md)

## 当前包含的内容

`moddev/tfcfarmingplus`是A模块的源码与资源，负责农业植物、食物及相关种植/采收内容。`moddev/tfcagricultureplus`是B模块，包含木工、养蚕和厨具等扩展系统，依赖A。

`moddev/docs`保留开发计划、实机反馈、修复记录与交接；`moddev/inventory`保留结构化检查证据、复现脚本和近期16格可编辑像素稿。已有第三方来源说明和木工许可随源码保留。

近期农业新图均从16×16实际网格绘制；64×64仅供本机预览，不作为游戏资源。近期显示链已构建并通过静态检查，但最终美术与游戏操作验收仍待用户完成。大黄正侧视叶柄叠影等限制详见271号，不能把静态检查当作实机验收。

## 构建

使用Java 21与Gradle 8.13，Minecraft目标版本为1.21.1。把编译依赖放在仓库根目录的`mods/`：A需要TerraFirmaCraft、Patchouli；B还需要Firmalife、ArborFirmaCraft和JEI，并读取A的构建产物。[依赖锁定清单](DEPENDENCY_LOCK.json)记录本机当前版本文件名和校验值，第三方JAR需另行取得。

先在`moddev/tfcfarmingplus`运行`gradle assemble`，再在`moddev/tfcagricultureplus`运行同一命令。首次构建需要下载Gradle插件及其依赖；`--offline`只适用于已有缓存的环境。仓库副本未进行全新机器构建验收，现有本机产物与验证记录已保留。

两份本项目当前构建产物位于`deliverables/2026-10-27/`，配套现有游戏环境使用，其SHA256见CURRENT_DELIVERY.json。原有PCL打包规则见215号文档，后续打包时必须先读，不应直接压缩整个开发工作区。

## 版本保存约定

原客户端、第三方模组、游戏运行库、存档、缓存、日志、反编译参考、历史备份及视觉验证临时目录留在本机。原始文件没有因此次整理被删除或迁移。SOURCE_MANIFEST.json记录本次纳入的原始文件及SHA256。

部分保护工具按文件字节校验，所以`.gitattributes`关闭自动换行转换，保留原始换行和PowerShell脚本BOM。全局命名、目录结构与代码风格整理仍在233号后置计划中，此次没有提前开展。
