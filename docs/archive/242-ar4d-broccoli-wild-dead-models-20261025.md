# 242 · AR4-D 西兰花野生与枯死形态修复交接

日期：2026-10-25。任务预期复杂度5/5，实际复杂度5/5。本片实现、离线查看、静态检查、构建及指定目录部署完成；未进行实机或最终美术验收。

## 一、依据、范围与问题

接续241号的下一片安排，复读README、AGENTS、开发规则、217/218及120号叶球后续裁决。保留立方体花球、完整宽叶、低位居中和不批量生成位图的要求。240号已证明不能直接把七份历史专用PNG接回旧四板模型；本片仅处理西兰花四种野生/枯死状态。

修复前野生成株继承TFC原生wild_crop/crop并使用cabbage_wild；高草板遮挡主要植株。未成熟野生和枯死幼株使用cabbage_young，呈同样叶环；枯死成株使用cabbage_dead，呈亮黄叶环。这是资源借用和模型错配，并非气候、成熟或掉落逻辑故障。

现有野生broccoli.png有荧光色长茎及扁平头，dead_crop/broccoli_young.png仅有稀疏点，均不直接套用。没有删除历史PNG，也没有给它们重新上色。

## 二、采用的独立方案

| 状态 | 新方案 |
|---|---|
| 野生成熟 | 自有独立几何，复用本项目broccoli_leafball_3及花球侧/顶纹理。六片完整叶板围绕较小的4×3×4花球，中心x/z=8、底y=5，不继承原生高草层。相较栽培第三龄减少外围叶片，花球更小，保留疏松形态 |
| 野生未成熟 | 新增内部模型broccoli_young，继承本项目broccoli_age_1；绿色幼叶，无花球。仅将野生blockstate的mature=false指向它 |
| 枯死成熟 | 四片向外的完整干枯分枝轮廓，加细茎与4×3×4残留花球。沿用现有dead_crop/broccoli褐色图，花球取其不透明区域，六面完整；粒子亦来自该图 |
| 枯死未成熟 | 两片中央相交的短小干枯分枝，使用同一褐色图的茎叶区域，不保留花球；避免使用原稀疏散点贴图 |

游戏运行时改4份既有资源，新增1份模型：

- assets/tfcfarmingplus/blockstates/wild_crop/broccoli.json
- assets/tfcfarmingplus/models/block/wild_crop/broccoli.json
- assets/tfcfarmingplus/models/block/wild_crop/broccoli_young.json（新增）
- assets/tfcfarmingplus/models/block/dead_crop/broccoli.json
- assets/tfcfarmingplus/models/block/dead_crop/broccoli_young.json

这些路径均位于moddev/tfcfarmingplus/src/main/resources。新模型名只是资源标识，没有新增方块、物品、注册ID或NBT。原六龄栽培模型、野生物品的既有父引用、掉落表、气候、生长、自然生成、食品、配方、语言及全部Java不变。新增源码文件后A为5878份，B仍3107份。没有新增跨命名空间覆盖，台账仍418项。

复用的是本项目既有几何/纹理，依据公开Minecraft模型JSON协议独立组合。依赖中的MC/TFC资源只用于解析、渲染现状作对照；没有复制第三方模组业务代码或新增第三方图像到发布源码。

## 三、离线查看与具体观察

证据目录：moddev/inventory/broccoli-wild-dead-20261025。

已实际查看AR4D-textures二维图和修改前/候选各p28、p5、p70共六张三维图。四格固定顺序为：野生成熟、野生未成熟、枯死成熟、枯死未成熟，yaw40。清单与渲染调用脚本、隔离前后模型、逐资源哈希和visual-observations均保留。

前图可见草墙遮住卷心菜式植株、黄色环状死株；候选图中绿色小花球顶面和侧面能露出，完整叶片向外张开，幼株为叶丛；死株为褐色茎叶及残留方块花球，幼死株明显更小且无花球。正式五份资源与已查看候选逐字节一致。

褐色花球仍沿用已有调色，表面细节较平，当前仅解决辨识、借用和几何错配。离线软件预览没有真实地面、光影或外部资源包效果，不能据此声称美术验收通过。所有矩阵VisualAccepted和RuntimeVerified仍为false，正常种植验收也未运行。

## 四、防回退维护

扩展既有tools/audit-leaf-vegetable-models.ps1，继续检查三种叶菜36状态，额外约束西兰花四种野生/死株：状态模型指向自有资源、父链不含原生草层、所有使用的图来自本物种、成熟才有花球、花球居中离地、六面UV采样全不透明。它已在verify接线，未另增加重复检查入口。

当前36状态、54个展开模型通过。旧完整备份在新契约下检出51条不满足项，其中有重复面纹理判断，不代表51个独立游戏错误；证明卷心菜借用不能静默通过。Windows PowerShell与PowerShell 7均通过当前检查。

修改tools/gen-crops.ps1，新增BroccoliFormsOnly：只将当前五份已复核源码JSON复制到受限草稿目录后退出，既不生成位图，也不运行其他作物模板。完整旧草稿在末尾也用同一来源覆盖这五份，避免再次用卷心菜模板回退。缺省Root及正式源Root均在写入前拒绝。

实际运行安全模式只产生五份JSON，与正式源码逐字节一致。完整旧生成器没有运行，其他旧草稿仍不可整体发布。此处维护仅为修复防回退，不提前开展233号全工程整理。

## 五、构建、保护和交付

修改前完整备份9101份条目：moddev/backups/ar4d-broccoli-wild-dead-20261025。包含A/B源码工具及构建包、工作区/测试目录安装包、主说明和台账，详见backup-manifest。

静态引用、87作物、树类/灌木/土壤、三叶菜36状态和五莲座60状态检查通过；源码/工具差异只有上述五资源和两维护工具，所有PNG、Java及B源码未改变。两脚本语法与UTF-8 BOM、JSON无BOM核对通过。覆盖台账418项匹配。

A assemble --offline成功，耗时25秒，Java编译保持up-to-date。新旧JAR内容差异恰为五份计划资源；无额外类、配方或图像变更。先校验工作区与PCL_TFC四份原安装包仍与备份相符，再仅部署A。部署后综合静态健康检查通过，AR4-A历史闲置空图仍保留原始计数及哈希/引用证明，没有删除PNG来绕过检查。

A SHA-256：9F067D15D431527271D610B37B762237A3CDE5CE0C49C7A5C730D71F047EFB8F

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、D:/TFC农业重置/PCL_TFC/mods三份一致。B未修改、未重复构建/部署。没有更新用户另行导入的实例，也没有重新制作PCL压缩包。

主要检查证据：parser、audit-after/winps/before、draft、guard-no-root/live-root、verify-a、ledger、build-a、review-manifest、jar-entry-diff、delivery-manifest、healthcheck。中文状态矩阵leaf-vegetable-model-contracts.csv和JSON仍区分静态与实机结论。

## 六、实机待验与回滚

之后在存档副本、确认实际实例A/B哈希后验证：野生成熟/未成熟和成熟/幼年死株分别从正面、低角度、俯视观察，草丛不遮住花球；成熟花球有支撑、无破洞或明显闪烁；幼态无花球。正常播种、生长、野生季节变化与收获/死亡掉种仍须玩家验证，不以/setblock代替正常流程。检查破坏粒子、野生物品显示、重进和资源重载；外部光影/资源包另行比较，异常附状态、截图与日志。既有封窑玩家测试约定继续保留。

回滚先保留当前修改，再恢复备份中的四份既有运行时资源和两工具，撤去本片新增内部young模型及其状态引用，恢复主文档状态；也可恢复备份A包9E335AF4049562E42E78EBE2D64376ED2D2EC829E21D5AFC0F7D76570F84C162到两个安装目录。B不变，没有存档迁移。不要运行旧全量生成器回滚，不清理受保护美术快照。

## 七、下一片及保留队列

建议AR4-E：生菜野生与枯死形态，任务预期复杂度5/5。它已有洋葱等借用及专用图错配证据，继续单物种、先隔离对照再定稿。羽衣甘蓝随后单独评估，因为共享dead_rosette还影响其他物种，不能直接照搬本片死株方案。

其他视觉长尾、完整农业加工链、AR5实机验收和交付、233号最终命名/结构/可读性整理继续保留。待整个农业完善阶段收尾后再交完整TXT总结；232号依然只是截至AR3-E的历史总结，不宣称全部农业工作完成。
