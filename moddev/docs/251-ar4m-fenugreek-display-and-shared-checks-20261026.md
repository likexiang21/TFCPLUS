# 251 · AR4-M 葫芦巴显示链与共用检查

日期：2026-10-26。预期复杂度4/5，实际复杂度4/5。葫芦巴显示接线修复、离线查看、检查、A构建及两个指定目录部署完成。没有启动游戏，所有VisualAccepted/RuntimeVerified仍为false，农业整体尚未收尾。

## 一、问题、采用方案与未采用方案

接续250号，复核工作区规则、INBOX和249号视觉清单。当前葫芦巴六龄取TFC兵豆图，野生成熟、枯死两态、种子、食品及盆栽也取兵豆；野生幼株甚至直接指向枯死兵豆。项目自身六龄与各类原图已存在，不能把文件存在当成已显示。

先准备了完整自有图候选，并实际查看二维页和三个角度。首版野生成熟模型使用保存的wild_crop/fenugreek.png，图中是紧凑绿团，与栽培成熟株的分枝和浅色细长部分差异明显。因此未采用这份接线，改为野生成熟继承fenugreek_age_5，幼态继承age1，再查看三个角度。最终成熟野生与栽培形态一致，幼态是绿色细苗；成熟死株为褐黄细枝和浅色部分，幼死株是小型褐枝。

原野生PNG保留原字节，不因没采用而删除或重画。六龄中仍有疏密变化，沿用用户已有手绘，没有为指标改图或宣称株型及龄间过渡已获最终美术验收。种子页为散落棕色颗粒，食品原图为浅棕小簇，实际查看后接回对应物品模型。

业务检查和资源组织复用本项目自己的前片实现，按本片需求扩展；没有复制第三方示例/反编译业务代码，没有新增第三方图像。公开Minecraft资源格式和实际客户端父模型继续沿用。

## 二、十四份运行时JSON

位于moddev/tfcfarmingplus/src/main/resources，完整清单见inventory/fenugreek-display-20261026/runtime-files.json：

- 六份models/block/crop/fenugreek_age_0..5.json保留原生crop几何，分别取同龄自身图；粒子由父模型的#crop跟随本物种。
- blockstates/wild_crop/fenugreek.json只改幼态指向；models/block/wild_crop/fenugreek.json改为继承自身age5；新增内部fenugreek_young.json继承自身age1。
- 两份models/block/dead_crop/fenugreek{,_young}.json保留原生crop父模型，接自身枯死图。
- seeds/food两个物品模型接自身PNG，仍为generated模型。wild物品模型原已继承野生块模型，字节不改而随新模型显示。
- data/firmalife/firmalife/plantable/fenugreek.json只改六纹理数组，quad类型、stages=5、原料/产物/种子编号与数量、N/P/K及specials逐值保持。

共十三份既有文件修改，一份内部幼株模型新增。crop/dead状态定义及wild物品模型不改，但加入后续复制保护。所有PNG、Java、其他玩法数据、B和辣椒运行时资源保持原哈希。A源码5884份，B3107份，跨命名空间覆盖仍418项。没有新增注册ID、配方、NBT或存档迁移。

## 三、实际查看的范围

目录：moddev/inventory/fenugreek-display-20261026。实际查看十张图：十一原PNG的二维汇总页一张；before、candidate初版、final采用版各p28/p5/p70三张。每张三维上排age0..4，下排age5、野生成熟/幼年、枯死成熟/幼年。初版备份图和assets-candidate-v1保留，副本不另算查看次数。

源图按16倍最近邻放大；模型父链和纹理来自当前源码及实际Minecraft/TFC JAR，隔离导出后渲染。十份状态模型在九份三维日志中均生成，无render failed。十四份正式JSON与最终候选逐字节一致，十一PNG保持。野生存图仅在初版出现，最终模型不再引用它；预览目录中保留的旧副本不能当作当前采用证据。

这些是离线观察，未验证正常种植、采收、地面、盆栽、粒子、物品手持/掉落、光影和外部资源包。未把静态通过、哈希或像素统计当美术/实机验收。

## 四、共用检查与兼容性

将辣椒已有检查中的共用逻辑提取到audit-reviewed-crop-display.ps1，仅支持已施工的chili和fenugreek。保留audit-chili-display.ps1原参数入口，新增audit-fenugreek-display.ps1入口。两者分别读自己的display-contract/files配置；葫芦巴明确记录野生成熟继承age5，辣椒仍使用前片的自身野生图，两物种策略没有混用。

检查包含十个状态的路由/父模型、可见与粒子纹理、两图标、wild物品继承、盆栽六纹理及非显示字段、十一原图哈希/尺寸/非空和B覆盖。新的葫芦巴检查接入verify。此项共用用于当前两个物种的实际维护，不开展233号全局命名整理。

未改源码在新检查下有29条不满足，含逐状态重复条款，不是29个独立玩法故障。采用后两物种各十状态、各十一保护图均0条不满足，PowerShell 7和Windows PowerShell均通过。

葫芦巴六个隔离副本：正确版通过；借用兵豆图拦下2条、缺副本PNG拦下2条、盆栽产量改变拦下1条、B覆盖拦下3条、回到未采用的野生成熟接线拦下3条。另用前片辣椒正确/借用副本检查共用逻辑，保持通过/拒绝行为。所有反例只改隔离副本，不改源PNG、B或玩家包。

## 五、生成器防回退

gen-crops新增-FenugreekDisplayOnly，与六个既有安全模式互斥。将两物种实际需要的复制逻辑共用为Copy-ReviewedCropDisplay，原-ChiliDisplayOnly入口保留。输入JSON及保护图存在/哈希预检后，仅复制十七份规范源JSON至受限草稿，不生成PNG。

葫芦巴、辣椒两个安全模式各输出十七份，与各自源逐字节一致。八拒绝项通过：无Root、正式资源Root、与六个旧模式分别混用。历史全量草稿末尾同时恢复两物种规范文件；全量其他模板仍过时，本片没有运行全量生成，也不能整树发布旧草稿。

工具共改七份：修改gen-crops、verify及原辣椒入口三份；新增共用检查、葫芦巴入口、葫芦巴contract/files配置四份。五份PowerShell的UTF-8 BOM和语法、JSON无BOM/可解析性通过。未改变辣椒源资源及其配置。

## 六、备份、构建与部署

完整备份9114条目：moddev/backups/ar4m-fenugreek-display-20261026，包含A/B src/tools/build/libs、工作区/PCL_TFC原包以及根规则、README/217/218和覆盖台账。review-manifest证明差异只有十四运行时JSON及七工具；所有PNG、Java、B、辣椒运行时保持。

全部资源引用、作物/树/灌木/土壤、原叶菜/莲座/叶球和两物种新检查通过；覆盖台账418项匹配。A assemble --offline成功，记录52.43秒，Java编译up-to-date。新旧JAR恰为十三修改、一新增内部幼株模型，没有额外类、PNG或玩法数据变化。

先核工作区/PCL_TFC四份原包与备份一致，再仅部署A。综合静态健康检查通过，原PNG原始体检及历史空图保护保持。没有构建/部署B，没有启动客户端、替换用户其他实例或制作PCL ZIP。

A SHA-256：4748DF9EBA7C6AB1A8111C1EA628EA3FF5539280F418D823317F8AB5232B30A2

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods及D:/TFC农业重置/PCL_TFC/mods三份一致。证据包括before-contracts、两物种audit/WinPS、隔离副本/兼容结果、两个draft/八guard、parser、review-manifest、verify-a、ledger、build-a-result、jar-entry-diff、delivery-manifest、healthcheck和最终状态清单。

## 七、实机待验与回滚

之后在存档副本中核实际包哈希，正常播种葫芦巴并检查六龄、成熟采收与返种、野生两态/死株两态、破坏粒子、种子/食品/野生物品、Firmalife盆栽显示和产出。检查保存重进、资源重载及光影/资源包，兼顾辣椒前片显示回归。全部VisualAccepted/RuntimeVerified继续false。封窑完整玩家操作仍交用户。

回滚前先保留当前工作，恢复十三既有资源和三既有工具，撤回新内部模型及四新工具/配置；源里删除模型后要clean build。直接回滚安装包可恢复备份A（62E97A6070E4022248AA7FAAF1D7528D337CB67CA7DB21CD32B92A6DCFABAAF2）至两个目录。B不变，无存档迁移；不运行全量旧生成器，不清理保护快照。

## 八、下一片

250号和249号保留历史统计。本片只接回葫芦巴，供体栽培组从76降至75种，取TFC图片的种子模型从86降至85个；这不是剩余物种已核对或全部图片已验收。

下一片AR4-N：菠菜显示链核对与修复，预期复杂度4/5。核六龄、野生/死株、图标/粒子、盆栽实际引用与已有素材，先做二维和三角度候选；不适配的存图像本片一样另选既有可用模型，不盲目回接、不批量重画。保护辣椒/葫芦巴及此前资源，按受限草稿、检查、构建部署和哈希规则完成单物种切片。

249号其余视觉、双段整株/向日葵、果树/灌木、完整加工与AR5仍保留。农业整体完成后再生成完整TXT总结；233号变量/文件命名、结构和可读性整理继续放在全部既定工作收尾之后。
