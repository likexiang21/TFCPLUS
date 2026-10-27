# AR1-A：草莓灌木手册收口与草莓种植说明（2026-10-23）

## 本轮结果

本轮完成 AR1-A 的资源施工、工具修正、静态检查、离线构建和工作区测试目录部署。**尚未启动 Minecraft，手册最终画面与实际物品跳转仍待用户实机确认。**

任务预期复杂度为高（约 4/5）。实际工作量与该估计相符：除十种语言的资源覆盖，还发现旧覆盖的日历/页码遗漏、AR0 审计误判，以及校验工具旧路径问题。

## 原问题与审计更正

218 号初版写过“A/B 没有覆盖原版野生水果手册”，这一判断不准确。此次直接读取修改前的源码、覆盖台账与旧部署 JAR，确认 A 已有中英文 `entries/the_world/wild_fruits.json`，两份文件均为 58 页，已经移除草莓灌木介绍的两页。

旧覆盖尚有三个缺口：

1. 小型浆果灌木日历仍含草莓行，共 104 个单元格。
2. 冬青莓与蔓越莓物品映射仍指向原始 54、56 页；删除两页后应指向 52、54 页。原映射会把冬青莓带到蔓越莓介绍，蔓越莓带到日历。
3. TFC 的其余八种语言没有覆盖，因此仍显示原版草莓灌木介绍。

另核实项目普通/野生草莓已注册、掉落为 `tfc:food/strawberry`，但现有农业手册没有草莓种植条目，缺少正确的果实与种子跳转目标。本次补充独立说明。

原中英文文件已从备份的旧部署 JAR 提取并保存，哈希分别为：

- en_us：`DBE1C955A1F2A1021E52EF0FC8BACADE387F9C203C85CCFCEDE445B22F375C2D`
- zh_cn：`24E57CAF8E455ECD1E22983C09A3FE246ED0FC49FEE8640DC614561565A7F332`

它们与修改前源码快照完全匹配，故可以作为可靠的回滚副本。218 号的正文与缺口表已更正，保留了更正说明。

## 修改范围与独立设计

### 手册资源

修改 A 主资源目录中的十份文件：

```text
assets/tfc/patchouli_books/field_guide/<语言>/entries/the_world/wild_fruits.json
```

语言覆盖 en_us、zh_cn、tr_tr、ja_jp、uk_ua、ru_ru、zh_hk、ko_kr、pt_br、zh_tw。前两份为修正旧覆盖，后八份为新增覆盖。每种语言均以本地安装的 TFC 4.2.11 对应语言资源为依据，只作以下变化：

- 删除 `anchor=strawberry` 的介绍页与紧随的灌木多块展示页。
- 删除结果日历中的草莓整行，保留表头和其他六种小型浆果。日历由 104 格变为 91 格。
- 移除草莓灌木和草莓果实指向该旧页面的映射；删除后续页码统一减二，保留其他物品的正确跳转目标。

条目 ID、分类、标题、图标、排序、其他页与其他浆果锚点均保留。源文件 60 页变为 58 页，多块展示与双页表格的左右页排列保持正确。

新增两份独立编写的项目条目：

```text
assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/strawberry.json
assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/strawberry.json
```

条目说明项目草莓在 TFC 耕地上种植、成熟破坏采收、野生草莓获取种子及统一原版草莓果实。生长范围从当前 `crop/strawberry` 气候数据核对为 5～28°C、水合度 35～85%。原版果实、项目种子和野生草莓物品均指向此作物条目；其他语言按 Patchouli 规则回退英文。

### 工具与覆盖边界

- `tools/strawberry-guide-policy.json`：登记 TFC 4.2.11 来源文件、SHA-256、十种语言、允许覆盖的条目及交接入口。
- `tools/sync-strawberry-guide.ps1`：本项目独立实现的资源改写工具。先校验 TFC 指纹、语言全集、目标页对、日历结构和映射，再准备十份结果；支持 `-DryRun` 和只读 `-Check`。上游版本或布局变化时停止，要求人工复核；不批量运行旧手册/贴图生成器。
- `tools/verify-book.ps1`：修正旧电脑绝对路径与旧序列化依赖，按自身目录寻找项目；校验类别、物品、条目发现基准、全部语言的跳转范围和跨页布局。只允许 policy 明确列出的十个 TFC 同名覆盖，并核对其内容确为当前审核过的转换；其余同名覆盖仍报错。
- B 的 `OVERRIDE-REGISTRY.md`：补登十个新增文件，更新实际统计为 A 210、B 13、合计 223。原摘要中的 B 9 个已过时，本次同时更正。

本轮只使用 Patchouli 的资源覆盖与条目数据格式，没有新增 Java 行为，没有复制示例模组或第三方业务代码。TFC 手册内容属于已有依赖的资源覆盖，保留原语言文本、记录来源与复用范围；它不被声称为本项目原创文本。新增的草莓种植说明、资源处理和检查逻辑为独立编写。

参考的公开格式与加载机制：[Patchouli 1.20 之后的资源目录规则](https://vazkiimods.github.io/Patchouli/docs/upgrading/upgrade-guide-120/)、[扩展现有书籍](https://vazkiimods.github.io/Patchouli/docs/patchouli-basics/getting-started/)。具体版本语义还核对了本地 40 号 Patchouli 1.21.1-93 技术记录与当前安装 JAR。

## 检查与构建证据

- 两个 PowerShell 工具语法检查通过，脚本保存为 UTF-8 with BOM；游戏 JSON 保存为 UTF-8 无 BOM。
- `sync-strawberry-guide.ps1 -DryRun` 在首次生成前列出十个目标文件；生成后 `-Check` 无差异。
- `verify-book.ps1` 在 PowerShell 7 与 Windows PowerShell 中均通过：10 个审核覆盖、24 个各语言条目实例、1,368 页。
- 额外独立比较：十种语言合计 570 个无关原版页面内容不变；日历均为 91 格，冬青莓与蔓越莓跳转均指向原物种锚点。
- 施工前的 5,857 项源码/资源快照中，仅原有中英文 `wild_fruits.json` 改变；其余已有源码、模型、贴图和数据资源没有意外变化。该快照在新增两份项目草莓说明之后、生成十种语言覆盖之前采集。
- 覆盖台账校验通过：223 项与实际资源树一致。
- 首次 Gradle 在沙箱内无法连接本机构建后台进程，尚未进入编译；调整执行权限后，同一离线构建成功，无项目配置改动。日志分别为备份目录的 `build.log` 与 `build-retry.log`。
- 离线 Gradle `jar` 成功，`compileJava` 为 UP-TO-DATE。构建包中 12 份本轮手册资源的哈希逐份与源码一致；45 个编译类与旧部署包完全一致。

## 交付位置

新 A JAR：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\build\libs\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar
```

SHA-256：`205C267E73682D7C48D866BD434BE4BAF3F25A80F244DC1EAB7FC8C15FDAC5BF`

已部署并逐份比对同一哈希：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\mods\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar
D:\TFC农业重置\PCL_TFC\mods\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar
```

备份、构建日志、源码快照与交付清单：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\backups\ar1a-strawberry-guide-20261023-102125
```

该目录的 `backup-manifest.json` 记录旧文件与哈希，`original-book-from-deployed-jar` 保存原中英文手册覆盖，`protected-source-hashes.csv` 保存前述快照，`delivery-manifest.json` 记录新包与部署位置。

未重新打包 PCL 压缩包，未替换用户另行导入的启动器实例。若使用独立导入实例验收，应只替换其中 A 模组 JAR，避免保留两份 A。

## 待用户实机确认

1. 用新 A JAR 进入世界，打开 TFC 手册。中文及英文“野生水果”条目均无草莓灌木介绍和展示，末尾的小型浆果日历也无草莓行；其他浆果保持显示。
2. 从冬青莓、蔓越莓及其灌木的物品手册跳转进入，分别落到正确物种页面。
3. 从原版草莓果实、项目草莓种子或野生草莓物品跳转，进入“草莓种植 / Strawberries”作物说明。
4. 如需多语言验收，切换其他八种已覆盖语言，确认原版灌木介绍不再出现；没有项目译文的草莓作物说明回退英文。
5. 顺带回归原有创造栏/JEI 隐藏与草莓作物采收。这些逻辑本轮没有修改，不能因资源检查通过就视作本轮实机通过。

## 回滚与下一步

若回滚资源施工，恢复 `original-book-from-deployed-jar` 中两份旧覆盖，移除本轮新增八种语言覆盖与两份项目草莓说明，恢复旧 `verify-book.ps1`，并同步撤销 policy/生成工具与台账变更。回滚部署可直接恢复备份中的旧 A JAR。回滚只按清单处理本轮文件，不清理其他美术资源、存档或旧工程。

AR1-A 状态：**资源已施工、检查已通过、构建与测试目录部署已完成；实机待验证。**

下一步为 **AR1-B：可可产物统一与旧 cocoa 树兼容收口**。任务预期复杂度：**高（约 4/5）**。需核对 `cupuacu` 的 Firmalife 盆栽与自然采收、生成器的权威来源、旧 `cocoa` 及重复物品 ID 的存档兼容，并保护用户已确认正常的发酵链。开始前按用户要求报告复杂度，由用户据此配置模型后继续。
