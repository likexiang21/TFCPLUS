# 250 · AR4-L 辣椒自有显示链与生成器防回退

日期：2026-10-25。预期复杂度5/5，实际复杂度5/5。辣椒显示资源接回现有素材，候选二维/三角度已查看，静态检查、A构建和指定测试目录部署完成。没有启动游戏，VisualAccepted和RuntimeVerified仍为false；这是单物种修复切片，不是整个农业美术完成。

## 一、实际问题和处理依据

接续249号，复核AGENTS、DEVELOPMENT_RULES、INBOX、217/218以及辣椒98/99号历史记录。当前六龄模型取TFC水稻，野生成熟取水稻及原生野草，野生幼株直接指向枯水稻；死株两态、种子、食品图标及盆栽也取水稻。已有自有PNG存在，却没有进入这些实际引用。

本片按公开资源格式及本项目既有素材独立组织JSON与检查，没有复制示例模组业务代码，没有绘制或重编码PNG。所有现有手绘图、Java、生长/成熟/采收/掉落、食品数据和注册ID保持。实际食品图标也经核对：旧模型取tfc:item/food/rice，现有自有图是红色椒果，因此一并修显示引用，不改变食品属性。

## 二、十四份运行时资源

均位于moddev/tfcfarmingplus/src/main/resources。十三份既有JSON修改，一份内部模型新增，完整列表在inventory/chili-display-20261025/runtime-files.json。

| 文件 | 改动 |
|---|---|
| assets/tfcfarmingplus/models/block/crop/chili_age_0..5.json | 六龄继续使用minecraft:block/crop几何，crop各取自身对应龄PNG；粒子随原生父模型的#crop接到同龄图 |
| assets/tfcfarmingplus/blockstates/wild_crop/chili.json | 只把mature=false从原生枯水稻转到自有chili_young，成熟状态路由不变 |
| assets/tfcfarmingplus/models/block/wild_crop/chili.json | 采用原生crop几何及既有wild_crop/chili图，去掉TFC水稻/野草借用 |
| assets/tfcfarmingplus/models/block/wild_crop/chili_young.json | 新增，继承自有chili_age_1，绿色幼苗，不用死株图 |
| assets/tfcfarmingplus/models/block/dead_crop/chili{,_young}.json | 两态保留原生crop父模型，分别取既有自身枯死成熟/幼年图 |
| assets/tfcfarmingplus/models/item/seeds/chili.json | generated物品模型接自有种子图 |
| assets/tfcfarmingplus/models/item/food/chili.json | generated物品模型接自有食品图 |
| data/firmalife/firmalife/plantable/chili.json | 只替换六个阶段纹理为对应自有图，其余字段语义不变 |

作物/dead状态定义、野生物品模型本来路由正确，未改运行时字节，但纳入后续生成器复制保护。野生物品模型仍继承野生成熟模型，因此随本片获得自有显示。

盆栽原有quad类型、stages=5、种子/产物编号与数量、N/P/K和specials全部保持；六纹理的顺序仍0..5。不新增配方/设备/注册，不改NBT，无存档迁移。原生crop父模型及实际Minecraft客户端几何直接沿用，不把离线画面解释为真实地面衔接已验收。

A源码5883份（仅增加内部young模型），B3107份不变。跨命名空间覆盖仍418项，chili盆栽路径原已登记，没有新增覆盖路径。

## 三、实际查看的图与采用决定

证据目录：moddev/inventory/chili-display-20261025。实际查看七张图：AR4L-existing-textures.png一张二维页（六龄、野生、死株两态、种子、食品共十一张原PNG），以及before/candidate各p28、p5、p70六张三维页。每张三维页十格，上排age0..4，下排age5、野生成熟、野生幼年、枯死成熟、枯死幼年。

修改前成熟辣椒是水稻的直立叶丛，没有保存版的红椒；野生幼株是褐色枯苗。候选六龄从小苗到分枝叶丛，再到浅色花点和红色长果；低角度可见下垂长果。野生幼株为绿色幼苗，成熟野生株有红果；枯死成熟株保留褐黄枝叶与红褐果，幼年枯死态是小型褐枝。采用现有原图，不为追求数量或指标重画。

源PNG按16倍最近邻放大查看；三维父链与纹理从当前源及实际MC/TFC JAR导出到两个隔离assets树，不用旧lab资产替代现状。十四份正式资源与已查看候选逐字节一致；十一张PNG逐哈希保持。food/seed原图已查看，generated图标的游戏手持/掉落显示仍待实机，未声称其世界表现已通过。

两份模型列表、preview-sources的来源/哈希、渲染脚本、六份日志和visual-observations均保留。六份渲染日志各十格，无render failed。工具在Windows PowerShell运行，未修改共享渲染器。当前仍沿用原生crop的四片面结构，重复面带来的株丛效果没有在本片改造；盆栽、实际光照、地面、掉落物及外部资源包待验。

## 四、独立检查及反例

新增tools/audit-chili-display.ps1，配套chili-display-contract.json和chili-display-files.json，并接入verify。检查六龄和四种野生/死株状态的准确路由、父模型、可见/粒子纹理、两物品图标、野生物品继承、盆栽六纹理及全部非显示字段、十一张保护图的哈希/尺寸/非空和B同路径覆盖。

保护图哈希来自施工前素材，仅用于防止未经核对覆盖本片手绘；不把哈希、像素数量或静态接线当美术验收。父模型约束配合本片实际导出的客户端几何与三维查看，未声称新增通用几何质量判定。

原始未改源码有29条不满足，其中含缺少自有幼株模型及逐状态重复判断，不是29个独立玩法故障。修改后十状态、十一张保护图0条不满足；PowerShell 7和Windows PowerShell均通过。

五个隔离副本验证：正确版通过；换成TFC水稻纹理拦下2条，删除一张副本PNG拦下2条，盆栽产量改成2拦下1条，B覆写一份显示模型拦下3条。反例只改隔离目录，不改游戏源、实际PNG或B内容。没有以错误日志为空冒充实机。

## 五、生成器保护与范围

现有gen-crops增加-ChiliDisplayOnly，与五个既有安全模式互斥，仍仅允许输出到moddev/.probe/generator-output子目录。新helper先检查所有输入JSON和十一张保护图的存在/哈希，再复制十七份规范源JSON；不生成PNG。十七份包括十四份本片运行时资源及未改的crop/dead状态定义、wild物品模型。

历史全量草稿末尾也补该helper，覆盖其旧水稻/种子/盆栽模板输出。全量旧模板的其他内容依然过时，**本片没有运行全量生成器，不能整树发布其草稿**。

安全输出十七份与正式源逐字节一致；既有BroccoliFormsOnly五份输出兼容保持。七项拒绝检查通过：无Root、正式资源Root以及ChiliDisplayOnly与五个旧模式分别混用。拒绝输出目录未产生可交付文件。

新增/修改工具共五份：三个新增文件audit-chili-display.ps1、chili-display-contract.json、chili-display-files.json；两个既有文件gen-crops.ps1、verify.ps1。JSON无BOM、PowerShell UTF-8 BOM及三脚本语法检查通过。

## 六、备份、构建与部署

修改前完整备份9110条目：moddev/backups/ar4l-chili-display-20261025。包含A/B源码、工具、构建包、两个安装目录及规则/计划/覆盖台账。全量差异为十四份运行时JSON及五份工具；没有PNG、Java、其他玩法数据或B变化。唯一非显示目录变动是既有Firmalife盆栽文件的textures数组，其余字段逐值对照保持。

verify全资源及作物/树/灌木/土壤、原叶菜/莲座/叶球、新辣椒检查通过；418项覆盖台账通过。A assemble --offline成功，耗时72.8秒，Java编译up-to-date。新旧JAR差异恰为十三份修改及一份新增内部模型，无额外类、PNG或数据条目变化。

核对工作区和PCL_TFC四份原安装包均与本片备份一致后，仅部署A。部署后综合静态健康检查通过，原1748张PNG原始体检及两历史空图归类保持。没有通过删图或重画绕过检查。

A SHA-256：62E97A6070E4022248AA7FAAF1D7528D337CB67CA7DB21CD32B92A6DCFABAAF2

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods及D:/TFC农业重置/PCL_TFC/mods三份一致。B未重建或部署，没有替换用户另行导入的其他实例，也没有生成PCL ZIP或启动客户端。

主要证据为review-manifest、parser、before-contracts、audit-after/winps-audit、五副本结果、draft-chili、兼容模式/七guard、verify-a、ledger、build-a-result、jar-entry-diff、delivery-manifest及healthcheck。阶段最终状态另记final-state-manifest。

## 七、实机待验和回滚

在存档副本中核对包哈希，正常播种辣椒并观察六龄、成熟右键采收和再生阶段；检查正常获得的野生两态、死株两态、粒子、野生物品、种子/椒果图标以及Firmalife盆栽各阶段。确认产量/种子仍符合原规则，保存重进、资源重载及光影/外部包没有异常。正常玩法未测，所有VisualAccepted/RuntimeVerified仍为false；封窑完整玩家操作继续交给用户。

回滚先保留本次工作，再恢复备份十三份既有运行时文件及gen-crops/verify，撤回新增内部young模型和三份工具配置/检查。若从源撤掉模型后重新构建，须clean build，不能让旧内部模型残留。直接包回滚可将备份A（A7B52A27FCCE57C75D2C54A86A3F39BACD86835D79C9EB97F5B110576892D8DB）复制回两个安装目录；B不变，无存档迁移。不用旧全量生成器回滚，不清理保护美术快照。

## 八、后续入口

249号是施工前历史快照，保留其77种/87种子TFC引用统计。本片只接回辣椒，其他物种未改，因此供体组剩76种，种子模型剩86个仍取TFC图片；不能把本片推广为其余物种已通过。

下一片AR4-M：葫芦巴自有显示链核对与修复，预期复杂度4/5。逐项核其六龄、野生/死株、粒子、物品和盆栽当前引用；保持已认可手绘PNG，以实际模型做二维/三角度候选后再选用，必要时记录不适配而不盲目回接。沿用受限草稿、独立检查及构建部署规则，保护辣椒本片接线，不批量修改其余75种。

双段整株、向日葵、果树/灌木、种子和其他视觉长尾按249号清单保留；完整农业加工长链、AR5实机/交付仍未完成。农业整体收尾后再生成完整TXT总结，232号是历史总结；233号变量/文件命名、结构和可读性整理仍放在全部既定工作完成后。
