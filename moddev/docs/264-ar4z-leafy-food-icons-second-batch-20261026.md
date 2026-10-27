# AR4-Z 生菜、菠菜、牛皮菜、马齿苋食品图标

2026-10-26。按263号下一步执行，预期复杂度5/5，实际5/5。四食品图标、统一保护与菠菜专用保护已完成静态检查、构建和部署；最终美术/实机均未验，全农业未完成。

## 本片结果与产物边界

四个food模型原来都取kale共享叶束。本片核对注册、食品/腐烂、成熟掉落、直接用途、盆栽和八个中英文说明页后，分别接入独立图：生菜为浅色褶叶，菠菜为深绿叶片，牛皮菜为厚叶柄和显著叶脉，马齿苋为圆厚小叶与短枝。

实际查看共享图、旧同名存图和候选，旧根/果形存图不回接、不覆盖；保留原图。图中叶片数量和牛皮菜的红色叶柄只作辨识，不增加品种、加工状态、物品或产量。

所有食品数据保持：四者hunger4；生菜saturation1/vegetables1.5/water5/decay_modifier1.5，菠菜saturation1/vegetables2/decay_modifier1.2，牛皮菜saturation1/vegetables2/water3/decay_modifier4，马齿苋saturation0.5/vegetables1.5/water4/decay_modifier4。没有增加新营养字段或重做采收。

马齿苋保留莲座/侧芽机制；其他植株、种子、盆栽及旧存档均沿用。牛皮菜现有说明“割了还会再长”和普通crop注册的交互含义值得后续手册/生命周期核对，已列文字歧义待复核；本片不据此宣布发现玩法故障或改写其状态机。

## 图像来源与保存路径

使用内置image_gen逐项制作，没有CLI、换色模板或第三方业务代码复制。原稿保留于默认生成目录和本片imagegen-source；提示词位于：

`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\leafy-icons-second-20261026\imagegen-prompts.json`

正式新增图均为RGBA16×16：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\lettuce_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\spinach_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\swiss_chard_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\purslane_harvest_v1.png`

原稿三张1254×1254，菠菜1312×1199；最近邻等比缩小并透明居中，不程序重绘/换色。Alpha范围分别0～254、0～254、0～253、0～254，保留原透明通道，不强制最大值255。大原稿不进入src/JAR。来源、尺寸、哈希和正式路径见imagegen-asset-manifest.json。

实际查看四张生成原稿、三张检查页：AR4Z-current-stored-candidates、AR4Z-exported-leafy-candidates、AR4Z-current-source-icons，包含原生16×16及放大对照，最后一页从实际模型反查源图。候选在离线对照中可区分后采用，仍需用户在背包/JEI和实际缩放下评价，不把统计或脚本通过当最终美术验收。两次检查图读取早于前置脚本完成，等待完成后实际查看成功，未将其误判为游戏缺图。

## 菠菜为何要同步两份保护

菠菜食品之前由AR4-N完整显示合同保护，尚未登记到统一食品图标合同。只改模型会与旧的ItemTextures.food=kale冲突。

本片在统一合同新增菠菜食品路线、旧图/新图及食品哈希；其他三食品只改已有路线。统一合同版本11，累计44模型、81PNG、41食品数据，六页准确说明及六行模板保护保持。

同时仅在spinach-display-contract.json修改food入口、追加新PNG保护及修订说明。原12张保护PNG均保留，现13张；种子仍为原生lentil，六龄、野生/枯死、剪裁几何和盆栽字段/纹理全部保持。菠菜盆栽末两阶段共age4仍是后续项，本片没有用旧age5白花图替换它。

源差异为六份既有JSON修改（四模型、两合同）、四PNG新增、零删除。源A5921/B3107，工具A101/B19。所有原PNG、Java/B、食品、标签/配方、气候、种子/植株/掉落/盆栽、语言/手册、生成器程序、ID/NBT/存档保持。

## 检查、备份和交付

施工前全量备份9168条目至moddev/backups/ar4z-leafy-icons-second-20261026，逐文件核哈希，接入前再次核当前文件无外部修改。包括A/B源、工具、构建包、四旧安装包、根规则与文档、217/218/253～263及覆盖台账；原图、原稿、旧备份和保护快照均保留。

29项检查通过：统一合同23个隔离案例（正确版1、共享/旧图/串图/缺图各4，另B覆盖、食品值改变、大黄回退、32×32、前批说明/模板变更共22负例），菠菜专用4案例（正确版、食品回kale、缺新图、盆栽末阶段回旧图），以及两个安全复制检查。

ItemIconsOnly输出44份模型JSON、SpinachDisplayOnly输出17份显示JSON，各自路径和字节均与正式源一致，无额外PNG/数据；两种模式里的菠菜食品模型相同。没有通过放松检查、关闭旧菠菜保护或发布整树草稿来绕过冲突。

完整资源校验、44/81/41及六说明/六模板保护、菠菜10个状态/13图保护、418项覆盖台账通过。隔离/安全复制沿用Windows PowerShell5.1及子进程原生模块路径，完整verify/healthcheck在PowerShell7执行，不声称5.1完整流程兼容。

全部263张item/food与item/seeds源PNG和包内263张均16×16；GUI、方块、动画图集不盲目套用。229食品/种子模型当前源哈希对账，TFC/A来源125/104、85条TFC种子不变。本次四模型原本都取自有kale，故来源计数不变。八种共享叶束食品组已静态接入独立候选，剩余共享kale食品列表为空（kale本身不计），不等于全部图标或生命周期验收完成。

A离线assemble成功，用时1分17秒，Java编译up-to-date。JAR精确差异恰四模型修改、四PNG新增、零删除，八项等于正式源，原四PNG保持。四旧安装包先核备份哈希，再仅部署A到工作区mods及D:/TFC农业重置/PCL_TFC/mods，B未构建/部署。

A SHA-256：9218D5B069A013C2A616AD3603EE4D7CEE75999335346BC9D7284C271CC81B39

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、PCL_TFC/mods三份一致，综合静态健康检查通过，历史闲置空图按原范围保留。未启动游戏、改存档、操作其他用户实例或重打PCL ZIP；以后打包仍先读215号。

本片证据目录：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\leafy-icons-second-20261026`，含语义、提示词/来源/原稿、三查看页、当前分诊、尺寸、源/JAR差异、通用和菠菜隔离案例/安全输出、verify/ledger/build/health及交付记录。

回滚前保存当前工作，恢复备份四模型及两合同，撤回四新增PNG，源删除后clean build防残留；也可直接恢复旧A（FC6773E088FCD8162C911387D429F4ABBD2621A530A74F6EAA8903CC8ABF0096）到两mods目录。B与存档无需迁移，不用旧生成器回滚。

## 待验及下一片

用户之后核四食品在背包、创造栏、JEI中的名字/图标/透明边缘和相互辨识，再按既有清单核正常成熟采收、食品属性、原生用途及重进。全部VisualAccepted/RuntimeVerified仍false，用户延期实机和封窑完整操作安排保持。

下一片 **AR4-AA：向日葵完整两格显示链审查与修复，预期5/5**。先重新核当前Java年龄/part、实际bottom/top模型及保存素材，按两格整株查看六龄、成熟花盘、野生/死株、种子和盆栽，保护已修食用籽图与食品/生长/掉落。候选不适配时先定位几何/UV，不盲接旧图，不虚造第三/四格；按实际差异补保护、预览及构建交付，开始前报告复杂度。

菠菜盆栽成熟显示、牛皮菜文字歧义、其余作物/树/灌木视觉、完整加工与AR5继续保留。262号整书生成176/174页差异仍在生成流程待办，不发布旧草稿。全农业完成后才交完整自然语言TXT总结；233号命名/结构整理仍放在全部既定工作完成之后。
