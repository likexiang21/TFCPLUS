# PCL 客户端压缩包修复记录（2026-10-22）

## 问题

2026-10-22 在 PCL 中导入 `TFCAgriculturePlus-PCL-Instance-20261021.zip` 时，PCL 报告“手动安装整合包失败：文件结构不匹配”。旧压缩包只有实例运行目录（`mods`、`config` 等），没有 Minecraft 客户端版本目录，因此没有通过 PCL 的通用客户端压缩包识别。

## 修复

已重新生成：

- 文件：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022.zip`
- SHA-256：`DC56A75294DB492D88BCFA46C2EDA534C90596CCEC2CBF89B526C543131A97BC`
- 大小：约 285.76 MB（299,631,772 字节）

压缩包内部采用 PCL 可识别的客户端结构：

```text
TFCAgriculturePlus-PCL/
└─ .minecraft/
   ├─ versions/Essential TerraFirmaCraft (TFC)/
   │  ├─ Essential TerraFirmaCraft (TFC).json
   │  └─ Essential TerraFirmaCraft (TFC).jar
   ├─ mods/
   ├─ config/
   ├─ defaultconfigs/
   ├─ kubejs/
   ├─ resourcepacks/
   ├─ shaderpacks/
   ├─ assets/
   ├─ PCL/
   ├─ options.txt
   └─ saves/tfctest/
```

PCL 识别检查已通过：

- 发现 1 个匹配的 `versions/<版本>/<版本>.json` 路径。
- 共有 437 个压缩条目。
- 没有达到 240 个字符的内部路径。
- 没有非 ASCII 内部路径；已移除测试世界产生的中文 JEI 历史记录目录。
- 保留现有模组、配置、资源包、PCL 元数据和 `tfctest` 测试存档。

## 导入

在 PCL 中选择“导入整合包”或“导入已有实例”，选择新的 `TFCAgriculturePlus-PCL-Client-20261022.zip`。旧的 `TFCAgriculturePlus-PCL-Instance-20261021.zip` 不再作为 PCL 客户端导入包使用。导入完成后不要再次复制同一份农业模组 JAR，以免重复加载。

## 来源与限制

PCL 的通用压缩包导入逻辑会定位 `versions/<版本>/<版本>.json`，再把归档中的客户端目录加入实例列表。本次修复依据该识别规则调整了归档布局；未修改模组代码和运行内容。
