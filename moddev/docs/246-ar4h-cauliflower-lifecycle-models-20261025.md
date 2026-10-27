# 246 · AR4-H 花菜全生命周期模型与粒子接线核对

日期：2026-10-25。任务预期复杂度4/5，实际复杂度4/5。本片核对及发现问题的资源修复、离线查看、静态检查、构建和指定目录部署完成。实机与最终美术验收继续暂缓。

## 一、核对依据与结论

接续245号安排，复核开发规则、AGENTS、INBOX、217/218，以及120号宽叶与叶球裁决。继续保持立方体花球、完整宽叶与独立实现；不批量生成或重新上色PNG，不提前开展233号全工程命名/目录整理。

花菜实际有六种栽培年龄、两种野生和两种枯死状态，共十种声明状态。栽培模型已使用本物种六龄叶片，age2至5有本物种浅色立方体花球；离线三角度能辨认各阶段，没有发现本片必须更改栽培几何的证据。

确认的接线问题有两类：六个栽培包装均未覆盖父模型的通用leafball_N粒子，因此破坏粒子与本物种叶片不一致；野生成株/幼株、枯死成株/幼株仍引用卷心菜及原生高草几何，表现为高草遮挡、亮黄色枯叶环等。

本片改资源接线与野生/枯死几何，不改种植、生长、采收、气候、食品、配方或存档逻辑。现有87作物静态路径检查继续通过；实际生命周期仍须玩家验证，不能把模型核对等同于完整实机验收。

## 二、运行时修复

全部位于moddev/tfcfarmingplus/src/main/resources，既有十份JSON修改，新增一份内部模型：

- assets/tfcfarmingplus/models/block/crop/cauliflower_age_0.json至age_5.json：只增加textures.particle=#0。父模型、可见面纹理和其他字段语义完全不变，花球仍按原六龄设计显示。
- assets/tfcfarmingplus/blockstates/wild_crop/cauliflower.json：mature=false转向自有幼株模型，两个成熟状态都不再借用卷心菜模型。
- assets/tfcfarmingplus/models/block/wild_crop/cauliflower.json：本项目既有宽叶几何组合配本物种灰绿叶和较小浅色花球，去掉高草父链；六片完整叶围绕居中4×3×4花球。
- assets/tfcfarmingplus/models/block/wild_crop/cauliflower_young.json：新增，继承本物种栽培第一龄，无花球。
- assets/tfcfarmingplus/models/block/dead_crop/cauliflower.json：四片向外的干枯叶片、承托茎和残留浅色立方体花球，沿用现有dead_crop/cauliflower图的褐叶、茎及不透明花球区域。
- assets/tfcfarmingplus/models/block/dead_crop/cauliflower_young.json：两片小型褐色叶面，无花球；使用同一现有枯叶图的幼叶区域，不接回原稀疏散点幼株PNG。

两成熟新模型旋转后均在方块内，叶片没有进入花球内部；花球六面所采区域全不透明。死株花球的褐色色斑来自原图，没有挖透明孔或另画新图。枯死粒子取本物种褐色图。

所有PNG、Java、其他游戏资源和B源码不变，无新增物品/方块注册ID、NBT或存档迁移。A源码5881份，B3107份；跨命名空间覆盖台账仍418项。独立组合使用本项目已有几何与素材及Minecraft公开模型格式，没有复制第三方模组业务代码或新增第三方图像。

## 三、已查看证据与实际限制

目录：moddev/inventory/cauliflower-lifecycle-20261025。

已实际查看两张二维素材页，共十七张源PNG，包括六龄本物种叶图、花球侧/顶图、历史野生/枯死图和原继承的六张通用粒子图。三张栽培六龄图，以及四种其他形态的修改前/候选各三张图，均为p28、p5、p70、yaw40；总计十一张检查图。

栽培图按上排age0/1/2、下排age3/4/5排列：前两龄为灰绿幼叶，后四龄花球逐渐增大。六包装只有粒子变化，故使用修改前可见面图作几何对照；没有把离线静态图当作真实破坏粒子的验证。

修改前野生植株被高草遮住，枯死是黄色叶环；候选中野生成株有较小浅色花球，幼态为无球叶丛，死株为褐色叶/茎和残留花球，幼死株为较小褐叶轮廓。采用的十一份资源与已查看候选逐字节一致；六龄包装另逐字段证明只有粒子变化。

这些图没有真实地面、光照、光影或外部资源包。低角度叶片遮挡程度、根部衔接、原图简化风格及实际粒子仍需玩家确认，不作为最终美术验收。所有VisualAccepted和RuntimeVerified保持false。前图来源已按修改前完整备份与当前MC/TFC依赖逐文件校验，清单、渲染脚本、资源来源/哈希、几何检查和visual-observations保留。

## 四、检查与生成器防回退

扩展audit-leaf-vegetable-models，将花菜十状态加入原三种叶菜：目前四种作物46状态，其中30栽培、16野生/枯死；展开模型61个。检查本物种粒子、age2至5花球、四其他形态的自有父链/本物种图、成熟才有居中花球及六面不透明等。继续由verify调用，没有另建重复入口。

当前检查在PowerShell 7及Windows PowerShell通过。用旧完整备份运行新规则得到57条不满足，含六粒子及逐面重复的借用判断，不是57个独立游戏故障。原三种叶菜、五莲座60活株及共享死株范围/UV检查均保持通过。

gen-crops新增CauliflowerFormsOnly，只将已复核的五份野生/枯死JSON复制到受限草稿后退出；其余三种旧安全模式参数保留，四种模式互斥。完整旧草稿末尾也恢复花菜已复核形态，未执行完整旧生成器。无Root、正式源Root及与三个旧模式混用共五项拒绝检查通过；实际安全输出五份文件，与源码逐字节一致。

gen-leafball-models新增可选ParticleSpecies，用于ParticleBindingsOnly指定花菜；默认仍为西兰花、生菜两种共十二份包装，保持旧安全调用的范围。实际从旧花菜六包装隔离副本运行，只生成六份粒子修正，与正式源码JSON语义一致；默认旧模式十二份亦语义不变。历史完整包装模板同步包含花菜粒子修复，但没有运行其旧几何或位图生成逻辑，旧整树输出仍不可整体发布。

## 五、备份、构建与交付

修改前完整备份9106份条目：moddev/backups/ar4h-cauliflower-lifecycle-20261025，包含A/B源码、工具、构建产物、工作区/PCL_TFC安装包、主说明/计划和覆盖台账。

全量哈希差异只有十一份运行时资源及三份既有工具（audit-leaf-vegetable-models、gen-crops、gen-leafball-models），共十四份。所有PNG、Java和B不变；六龄父模型、共享莲座死株等其他资源保持不变，新野生/死株成熟几何已检查范围及叶片穿模。三脚本语法及UTF-8 BOM、JSON无BOM/可解析性通过。

A资源引用、87作物、树/灌木/土壤、46叶菜状态、60莲座活株和共享死株检查通过，覆盖台账418项匹配。A assemble --offline成功26秒，Java编译up-to-date。JAR内容差异恰为十一份计划JSON，无额外类、图片或游戏数据变更。

先核工作区/PCL_TFC四个原安装副本仍与备份一致，再只部署A；部署后综合静态健康检查通过。AR4-A历史闲置空图仍保留原始计数及有哈希保护的无引用说明，没有删除或重画PNG绕过检查。

A SHA-256：9728DE60A0C0720A6D848EFCB1324B1522FA2E357CE056422BEDB5BAEC61E613

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、D:/TFC农业重置/PCL_TFC/mods三份一致。B未修改、未重复构建/部署；用户另行导入的实例未自动替换，没有新打PCL压缩包。

主要证据：parser、audit-after/winps、baseline-audit、draft-forms、draft-particle-cauliflower、compat-particle-default、五guard、review-manifest、verify-a、ledger、build-a、jar-entry-diff、delivery-manifest及healthcheck。四作物中文CSV/JSON位于预览目录leaf-vegetable-model-contracts。

## 六、待实机项目与回滚

之后确认实际实例A/B哈希，在存档副本中观察花菜正常六龄生长：幼龄无球，age2起花球出现并逐渐增大，成熟采收正常。分别破坏各龄，粒子应来自对应灰绿叶图。检查野生成株/幼株、成熟/幼年死株及野生物品显示、常用视角遮挡和地面衔接。

正常成熟/幼年采收与死亡返种、保存重进、资源重载、光影及外部资源包仍待玩家验证；原掉落表未修改，不以静态引用通过代替实际产量验证。未启动游戏，不用/setblock或日志无错误替代正常种植。封窑完整玩家测试继续交用户。

回滚先保留当前工作，再恢复备份十份既有JSON及三工具，撤去新增wild_crop/cauliflower_young内部模型及其状态引用，恢复README/217/218；或恢复备份A（49A5A785096810B76F331EB1392B0EEC97F5338ECBD2001A5BAF0EE318DAC778）至两个安装目录。B不变，无存档迁移；不要用全量旧生成器回滚，不清理受保护美术快照。

## 七、下一片与保留队列

AR4-I建议：白菜（napa_cabbage）全生命周期模型与粒子核对，任务预期复杂度4/5。当前已读取其野生/死株仍借用卷心菜，栽培包装未显式覆盖本物种粒子；先逐状态解析、查看原图与三维效果，再决定最小修复。继续复用本片单物种流程，不把所有叶球植物直接批量套同一候选。

其余视觉长尾、完整农业加工链、AR5实机验收和交付，以及233号最终命名/目录/可读性整理保留。整个农业阶段收尾后再交完整TXT总结，232号仍是历史阶段总结。
