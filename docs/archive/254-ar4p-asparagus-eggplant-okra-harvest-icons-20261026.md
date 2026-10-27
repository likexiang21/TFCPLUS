# AR4-P 芦笋、茄子、秋葵采收物图标修复

日期：2026-10-26。按用户“继续”推进217/253号的下一片。预期复杂度4/5，实际4/5。本片三个采收物图标的引用修复、检查、构建和部署已完成；没有实机验收，最终美术仍待用户确认。

## 一、先核产物与真实图片

已重读253号交接、217号当前安排及开发规则。AGENTS/DEVELOPMENT_RULES哈希与上一片相同，无新增下级AGENTS。核MyCrops的食品注册food(name)、三种可采摘作物注册以及pickable辅助方法，成熟/未熟采摘供应器均为各自食物；核MyPickableCropBlock使用TFC公共接口、三份成熟破坏掉落和三食品数据。实际产物为tfcfarmingplus:food/asparagus、food/eggplant、food/okra，不是麦类或其他加工品。

实际修改前食品模型分别取tfc:item/food/barley、wheat、oat，因此显示麦穗。三张既有16×16保存图分别可辨为绿色笋茎、紫色茄果和绿色长荚。已实际查看独立候选对照图，再查看修改后沿真实layer0读取的三图对照，不是凭文件名、颜色统计或“无缺图”就采用。

本次采用既有本物种图，解决采收物显示成麦穗的问题；没有新画/替换PNG，不声称这些图已经达到最终美术标准。两张图为AR4P-three-harvest-icon-candidates.png及AR4P-current-source-icons.png，位于moddev/inventory/harvest-icons-20261026。

## 二、准确修改范围

运行时仅三份既有JSON：

- assets/tfcfarmingplus/models/item/food/asparagus.json → tfcfarmingplus:item/food/asparagus。
- assets/tfcfarmingplus/models/item/food/eggplant.json → tfcfarmingplus:item/food/eggplant。
- assets/tfcfarmingplus/models/item/food/okra.json → tfcfarmingplus:item/food/okra。

保留item/generated与唯一layer0，不增加模型几何、图层或运行时文件。种子图标、作物/野生/死株、盆栽、语言、ID、物料数量、营养与腐烂、气候、配方、Java/NBT和B源均不改。全部原PNG保留。A源5885、B源3107不变。前片六份叶菜/种子图标、辣椒/葫芦巴/菠菜等资源均未回退。三作物的完整生长外观没有因此修完。

开发工具只改tools/reviewed-item-icon-routes.json：版本2，扩展三条食品模型路径、三个PNG和三份食品数据哈希。现共9模型、10保护PNG、6食品数据及原有TFC散粒图保护。原有audit-item-icon-routes、gen-crops的-ItemIconsOnly、verify无需改代码即可遍历新增条目，避免再次复制同类脚本。

没有复制示例模组业务代码。本片仅按Minecraft标准generated模型格式接回本项目现有资源，沿用本项目独立编写的合同检查；TFC公共可采摘接口用于核实现状，没有改写其业务逻辑。

## 三、防回退与检查证据

修改前全量备份9126条目：moddev/backups/ar4p-harvest-icons-20261026，含全A/B源/工具/构建包、四旧安装包、根规则及README/217/218/253和覆盖台账，复制后逐文件校验。work-plan.txt先于正式改动写出输入/输出、格式、文件和完成条件。备份及旧O清单均未覆盖。

review-manifest.json对照备份：恰三模型加一工具合同四既有文件变化，零新增、零删除；全部PNG/Java/B及其余源保持。JSON为无BOM UTF-8；没有修改PowerShell代码或重复开展无关整理。

13个隔离副本的结果符合预期：正确版本通过；分别退回三旧麦穗、串到另两物种、缺少各自PNG的9个副本，加上B覆盖秋葵PNG、芦笋食品ID串到大麦、旧芝麻菜回退甜菜的3个副本，均被拦截。第14项为安全生成：-ItemIconsOnly输出恰9份JSON，路径集合与合同一致，逐字节等于正式源，不生成PNG或玩法数据。

隔离检查在Windows PowerShell 5.1下运行，测试驱动沿253号经验仅给子进程使用原生模块路径；没有修改系统永久设置。通用全量verify/healthcheck使用现有PowerShell 7环境，没有声称Windows PowerShell 5.1全流程兼容。旧模式互斥/Root/符号链接限制未改，本片没有重复运行历史全量生成器。

完整资源交叉引用、作物/树/灌木/土壤、叶菜/莲座/叶球、辣椒/葫芦巴/菠菜及新增条目检查通过。418项外部命名空间覆盖台账匹配。健康检查通过，历史闲置透明图仍受原合同保护，未清理保护快照。

## 四、构建与交付

A assemble --offline构建成功，日志27秒，Java编译up-to-date。与备份旧JAR逐条ZIP内容对比，恰三个食品模型改变，零新增/删除，无额外图片或类。先核工作区及PCL_TFC四份旧安装包与备份一致，再只部署新A至两个目录。

A SHA-256：5687D75C1C46F3ADBE7223B3020EE4D9981AAA9D2D42FF2B0BC5185037C29281

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

A/B分别在build/libs、工作区mods和D:/TFC农业重置/PCL_TFC/mods三处哈希相同。B没有重构建或重新部署。没有启动游戏、访问用户其他实例、改存档或制作新PCL ZIP；以后打包仍按215号成功流程进行。

证据目录moddev/inventory/harvest-icons-20261026，含before-target-references、两张图、review-manifest、13个fixture日志、check-results、九份安全复制日志、verify-a、ledger、build-a、jar-entry-diff、delivery-manifest、healthcheck及final-state。

## 五、当前台账、实机与回滚

当前229条食品/种子模型逐条与源哈希复核，其中154条取TFC、75条取A素材；种子未改，仍有85条取TFC。三条食品由此前“需修复”移到“接回既有本物种食品图，最终美术/实机未验”；该后续分诊组现26条，并非26个独立崩溃故障。74种栽培显示仍只取TFC纹理的统计未变，本片食品图标不能算作生长显示修复。

新current-item-icon-references.json是当前引用快照。新item-icon-triage.csv/JSON保留旧诊断，将AR4OBaselineTexture/Origin/TextureSha256/ModelSha256与CurrentSourceTexture/ModelSha256明确区分；旧页码仍指O目录26张历史图，本片只重看自己的两张图，没有虚称重新看完229图或全部验收。旧O目录原文件保持原样。

实机待验：在背包、JEI和创造列表分别核名称/图标；正常采摘或成熟破坏后仍得自己的食品和种子，营养/腐烂信息不变；保存重进、资源重载后显示保持。用户资源包优先级另在实际环境检查。全部VisualAccepted/RuntimeVerified=false。

回滚先保留当前工作，再恢复备份三模型和图标合同；没有新增运行时资源，不需存档迁移。直接恢复备份A（89C9238FEF0849CD313A8E5C658D428DEEEB9C62D62DBCB679C3DD4736F39146）至两个安装目录也可，B不变。不要用旧全量生成器回滚，不清理原PNG、lab-assets/lab-old/lab-new或备份。

## 六、下一步开发安排

AR4-Q：剩余叶菜/茎菜采收物图标集中核对与修复，预期5/5。优先生菜、芹菜、莴笋、茼蒿、紫苏、马齿苋：核实际产物定义，分辨该画叶、叶柄还是嫩茎；逐个实际查看现有候选，区分可复用、临时共享与必须新美术，不把不同颜色的根/葱头图直接接回。将合格的小批次接入同一保护合同；不适用者保留原图并明确美术方案，避免为凑进度硬接错误图。开始前再次报告复杂度。

随后继续豆瓜/块根及种子辨识、新美术和其余农业生命周期/加工与AR5，按217号推进。前片共享图标、菠菜盆栽成熟共图和本片三种最终美术仍保留待验。农业全部完成后交完整TXT总结；233号全局命名/结构/可读性整理仍在全部既定工作完成后另行开展。用户搁置的实机与封窑操作测试不自动恢复。
