# 审查证据与专项报告

本目录是 2026-10-28 全量内容审查与清理的执行入口。

| 文件 | 内容 |
|---|---|
| [../276-full-content-audit-20261028.md](../276-full-content-audit-20261028.md) | 全量内容审查支撑报告 |
| [../277-plan-implementation-and-license-compliance-20261028.md](../277-plan-implementation-and-license-compliance-20261028.md) | 计划实现与开源协议履行专项报告（重点） |
| [../278-cleanup-inventory-20261028.md](../278-cleanup-inventory-20261028.md) | 工作区无用内容归类、清理批次与执行结果 |
| [D1-docs-and-plans.md](D1-docs-and-plans.md) | 文档/计划与实现偏差专项 |
| [D2-resources-and-protocols.md](D2-resources-and-protocols.md) | 资源/数据协议、死资源、占位与旧 JAR 回归专项 |
| [D3-java-tools-contracts.md](D3-java-tools-contracts.md) | Java/工具/合同/构建专项 |

## 清理执行记录

- `cleanup-candidates.csv`：清理前的候选分类；
- `cleanup-execution-20261028.csv`：第一批删除清单（50,448 文件 / 992.18 MB）；
- `cleanup-execution-20261028-additional.csv`：第二批删除清单（7,567 文件 / 8.82 MB）；
- `cleanup_execute_20261028.ps1`：执行脚本（含路径保护/绝对路径校验）。

**说明**：D1/D2/D3 引用的原始 CSV、脚本、日志（`d2-*`、`D3-*`、`lead-*`）已在清理中删除；D1/D2/D3 报告与关键摘要保留。审查/清理未修改 Java、资源或构建配置；仅修复了 4 处审查工具断链（见 276 §1.4）并删除明确无引用的工具数据。
