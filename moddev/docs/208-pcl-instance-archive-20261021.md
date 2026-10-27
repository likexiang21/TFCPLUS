# PCL 启动器实例压缩包记录（2026-10-21）

## 压缩包

文件：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Instance-20261021.zip`

SHA-256：`8D0497BB36D3BE4EE1B52085217C86E9AD778CBFBB05350B52ABF8445FB3E4B0`

压缩包大小：约 263.63 MB。

解压后文件大小：约 335.41 MB。

## 内容

压缩包根目录可以直接作为 PCL 实例导入，包含：

- `mods`
- `config`
- `defaultconfigs`
- `kubejs`
- `resourcepacks`
- `shaderpacks`
- `assets`
- `PCL` 元数据和实例图标
- `options.txt`
- `saves/tfctest` 实机测试存档
- `PCL_IMPORT_README.txt` 导入说明

共 433 个压缩条目，最长路径没有超过 240 个字符。

## 排除内容

为了保持 PCL 导入包可迁移，已排除源码、`moddev`、构建缓存、历史备份、日志、截图和其他旧存档。测试存档只保留 `tfctest`，其他旧存档仍保留在原工作区。

## 导入方式

优先在 PCL 中选择“导入整合包”或“导入已有实例”，选择该 ZIP 文件。如果当前 PCL 版本不接受该 ZIP，先解压到短路径目录，再把解压后的目录作为实例目录导入。

不要在导入后再次复制旧版本 `TFCAgriculturePlus` JAR，避免模组重复加载。
