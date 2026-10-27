# AR4-Q 六种叶菜/茎菜采收物图标修复

日期：2026-10-26。用户要求继续217/254号下一片。预期复杂度5/5，实际5/5。本片六种食品图标已修复根菜/葱头错配、构建并部署；四种叶菜仍为共享替代，芹菜/莴笋新增v1候选。全部实机及最终美术未验，VisualAccepted/RuntimeVerified=false。

## 一、判断依据与采用范围

已读254号、217号最新安排和既有图标合同，核AGENTS/开发规则哈希未变。核MyCrops的食品、种子、作物注册和六份食品/成熟破坏掉落：生菜、芹菜、莴笋、茼蒿、紫苏为普通作物，马齿苋为莲座作物，后者成熟掉落另要求fruiting=true。六者收获物均为各自tfcfarmingplus:food/<物种>；没有改这些行为或数量。

已实看六对实际图/保存图：前三者当前为TFC洋葱、后三者为TFC甜菜，自己的同名保存图也仍是不同颜色的葱头/根形，全部不采用。另查看既有kale、白菜、韭菜、芦笋、水生叶菜、茶叶、TFC卷心菜及Firmalife果树叶候选。不能以同名图存在就判断能用，也不能把茎菜直接改成普通叶球或芦笋。

生菜、茼蒿、紫苏、马齿苋改为tfcfarmingplus:item/food/kale现有叶束图。这只是消除根菜误导的临时共享方案，四者的叶缘、紫苏颜色及马齿苋肉质小叶等物种特征尚未完成，不能记为独立美术验收。

芹菜应突出成束叶柄及叶尖，莴笋应突出粗嫩茎及顶部少量叶片。现有候选无法合适表达，因此用内置image_gen各生成一个独立候选，实际查看生成原图及16×16导出图后采用为v1。没有用参数化脚本批量重画原图，也没有覆盖原存图。

本片实际查看四张对照图：AR4Q-six-before-and-stored、AR4Q-existing-leaf-stem-candidates、AR4Q-exported-stem-candidates、AR4Q-current-source-icons，另直接查看工具输出的两张生成原图。旧O/P整套图未重复查看，不能宣称本片再次完整美术验收229项。

## 二、新图片、来源和提示词

采用内置image_gen，非CLI/API后备方式。提示词分别要求芹菜的叶柄束、莴笋的粗茎/小叶冠、透明背景、低分辨率像素风、避免根菜葱头与芦笋误形；完整两条原文保存在：

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\leaf-stem-icons-20261026\imagegen-prompts.json

生成原文件实际为1312×1199 RGBA，完整副本在本片imagegen-source，默认生成目录原文件也保留。没有把这些大图直接装进游戏。采用最近邻等比缩小、在透明16×16画布居中的资产导出，不重新配色或重绘；保留原Alpha。再实看小图主体/叶柄/粗茎区分。芹菜导出Alpha范围0～254，莴笋0～255，未为满足检查修改透明度；边缘和实际游戏显示仍待验。

正式新增两张图（不替换celery.png/celtuce.png）：

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\celery_stalks_v1.png

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\celtuce_stem_v1.png

imagegen-asset-manifest.json保留生成路径、原图/导出哈希、导出方法、正式源路径和提示词路径。exported-candidates保留最终采用字节。新图是已经接入的v1候选，来源可追溯不等于用户最终接受画法。所有原PNG与历史快照完整保留。

## 三、具体文件与兼容性

运行时修改六份assets/tfcfarmingplus/models/item/food/<物种>.json：

- lettuce、garland_chrysanthemum、perilla、purslane → tfcfarmingplus:item/food/kale。
- celery → tfcfarmingplus:item/food/celery_stalks_v1。
- celtuce → tfcfarmingplus:item/food/celtuce_stem_v1。

均保留标准item/generated、唯一layer0，不新增物品或注册ID。另新增上述两张16×16 PNG。A源文件5885增至5887，B仍3107。种子、气候、营养/腐烂、配方、产量、掉落、语言、手册、作物/野生/死株、盆栽、Java/NBT均未改；既有辣椒/葫芦巴/菠菜及前两批图标不回退。

工具仅修改reviewed-item-icon-routes.json版本3：增加六路径、原六坏存图及新两图的哈希、六食品数据哈希，补美术状态说明。现共15模型、18保护PNG、12食品数据及原生散粒图保护。旧坏图受到保护只表示不擅自改动，不表示应被采用。

沿用项目独立编写的audit-item-icon-routes、gen-crops -ItemIconsOnly及verify，无工具业务代码修改。未照抄第三方业务代码；Minecraft标准JSON格式及已存在TFC接口只用来核对框架约定/当前机制。

安全生成模式现复制15份规范JSON，不输出图片，新增PNG由正式源保存。草稿不是完整资源包，不能整树发布；本片没有运行历史全量生成器，也未放宽Root/符号链接/模式互斥限制。

## 四、备份、过程问题与验证

正式改动前全量备份9127条目：moddev/backups/ar4q-leaf-stem-icons-20261026，含全A/B源、工具、构建包、两个安装目录、根规则及README/217/218/253/254、覆盖台账；逐文件核复制哈希，备份不覆盖。work-plan.txt在修改前写明范围、格式、来源和完成条件。

导入预检两次停止：先是校验误要求主体必须出现Alpha255，而芹菜实际最高254；再是Pillow.verify调用顺序错误。两次都在正式源写入之前停止。改为完整PNG验证与像素读取各自打开、检查透明背景和接近不透明主体，保留原Alpha后才接入。首次预检失败后的测试因同次调用未及时短路而运行，形成缺少新目标的不完整fixtures，不计成功；保留并在import-check-notes.txt记录。正式依据为fixtures-v2完整重跑，不能用旧不完整副本代替。

正式20项检查符合预期：19副本中正确版通过，18个负例分别为六旧供体回退、六误接同名坏存图、两新图缺失、新图字节变化、B覆盖新图、莴笋食品ID串洋葱、前片芦笋回退大麦，均被拦下；另15份安全输出路径与合同完全一致、逐字节等源，不生成PNG。Windows PowerShell 5.1隔离驱动使用子进程原生模块路径；完整verify/healthcheck用现有PowerShell 7，未声称5.1全流程兼容。

源差异恰七份既有JSON（六模型+一合同）修改、两PNG新增、零删除；没有任何原PNG、Java、B或其他玩法文件变化。229条现有食品/种子模型全部重新核源哈希，20项分诊仍列“当前显示需修复；保存图另审”，不是20个独立崩溃。当前TFC/A纹理来源计数148/81，种子未改仍85条取TFC；74种栽培只取TFC纹理的统计也未变。

完整资源、作物/树/灌木/土壤、叶菜/莲座/叶球、前批显示和15图标合同检查通过；418外部命名空间覆盖台账匹配。综合静态健康检查通过，原历史闲置空图仍受保护，未清理lab-assets/lab-old/lab-new。

## 五、构建、部署与回滚

A assemble --offline成功，日志27秒，Java编译up-to-date。与备份旧JAR逐条ZIP比对，恰六模型修改、两PNG新增，零删除；全部八项与正式源字节相同，无原图覆盖或多余类/数据。四旧安装包先核与备份一致，再仅部署A到工作区mods及D:/TFC农业重置/PCL_TFC/mods；B未构建/部署。

A SHA-256：4A9F8D9EC464D691C10D8F718E8A206782A9CD74DD5727FC3277B62D7B2B15C1

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

A/B各自build/libs、工作区mods、PCL_TFC/mods三份一致。没有启动游戏、改存档、修改其他用户实例或重打PCL ZIP；以后打包仍先读215号。证据在本片inventory目录，包括差异、fixture、完整检查、构建、JAR差异、交付、健康及最终状态清单。

回滚先保存当前工作，再恢复备份六模型与合同，撤回两张新增内部PNG。撤回源文件后应clean build，防止旧图片残留在包中；或者直接恢复备份A（5687D75C1C46F3ADBE7223B3020EE4D9981AAA9D2D42FF2B0BC5185037C29281）到两个目录。B和存档无需迁移；不要用旧全量生成器回滚，不清理原PNG/生成原图/备份。

## 六、验收与后续安排

人工待验：背包、创造列表、JEI显示与名称一致，四叶菜不再显示根/葱头，芹菜/莴笋两图可区分且无背景方块；普通五作物成熟收获与马齿苋结果态收获保持自己的食品/种子和食品信息；保存重进、资源重载及用户资源包优先级另核。离线查看和静态检查不能替代实机。四共享叶菜独立图、前批共享图及菠菜盆栽末期共图等仍在美术待办。

AR4-R：豆类采收物图标核对与修复，预期5/5，优先菜豆、豇豆、豌豆、四棱豆。先按真实食品/采收/加工定义区分鲜荚和豆粒，再看实际/保存图及已有豆荚候选；不把番茄样保存图接回，不把鲜荚和干豆粒混作一类。需要新美术时沿本片留原图、候选实看、独立版本文件和来源记录流程，合格后小批次接入保护合同。开始前报告复杂度。

其后继续瓜类/块根、种子辨识和其余农业生命周期/加工及AR5。农业完整TXT总结在整个农业阶段完成后交付；233号全局命名/文件结构/代码可读性整理仍等全部既定工作收尾。用户延期实机测试和封窑完整操作不擅自恢复。
