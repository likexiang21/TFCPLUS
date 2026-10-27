# AR4-X 大黄、向日葵、龙舌兰食品图标与说明修复

2026-10-26。按261号下一步执行，预期复杂度5/5，实际5/5。三食品图标、六个中英文文字页及模板保护已完成静态施工、检查、构建和部署；实机及最终美术未验。全农业仍未完成。

## 本片结果

大黄由黄豆荚改为红色叶柄，向日葵食品由大麦穗改为黑白条纹食用籽，龙舌兰由甜菜改为浅绿乳白中心收获物。沿用food/rhubarb、food/sunflower、food/agave；播种用seeds仍独立，龙舌兰侧芽仍用于种植，没有新增去壳、榨油、榨汁或烤制流程。

重新核对260号原始证据中的模型、食品与直接声明消费者，接入前与当前源哈希一致。三者保持现有食品、腐烂和成熟采收逻辑：大黄可采摘保留植株，向日葵双格破坏只结算一次，龙舌兰完全成熟且中心结果后整株收获、侧芽另返。图中数量和切面只是表达，不新增产量收益。

中英文crops.json各仅改三文字页的text字段：

- 大黄明确食用叶柄、叶片不作食材，现有食用和原生餐食用途使用未腐烂原料。
- 向日葵明确食用籽和播种种子分开，保留双格种植/收获操作；删除“随日转动、可榨油”的现有功能承诺，说明专属榨油尚未接入。
- 龙舌兰明确收获食材为龙舌兰心、侧芽用于播种，保留原莲座六龄/结果/死亡返芽操作，说明无专属烤制或榨汁配方。

两份正式作物书均174页，页码、标题、锚点、图示和其他页面保持。新文本长度已登记，实际游戏排版、JEI和操作仍待验收，不能把字符串校验当页面视觉通过。

## 图像来源和采用情况

使用内置image_gen独立制作三种候选，没有CLI或第三方业务实现复制。首轮大黄叶柄缩小后过细、五颗葵花籽过小，未接入正式源，原稿与导出完整保留。第二轮采用较粗的双叶柄和两颗较大条纹籽；龙舌兰采用首轮中心心部图。果实数量仅图形表达。

正式新增图均为RGBA16×16：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\rhubarb_harvest_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\sunflower_harvest_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\agave_harvest_v1.png`

提示词保存在本片inventory的imagegen-prompts.json、imagegen-retry-prompts.json；最终采用路径、原稿/导出尺寸、哈希和两份RejectedCandidate在imagegen-asset-manifest.json。默认生成目录原图及本片imagegen-source均保留，没有大原稿进入src或JAR。技术导出只做最近邻等比缩小、透明16×16居中，保留Alpha，不用程序重绘/换色。采用原稿均1254×1254；未采用的大黄首稿1536×1024也保留。Alpha最大值254/255均允许。

实际查看五张生成原图、五张离线检查页：首轮before-and-candidates及exported-special-candidates、第二轮对应两页、实际源AR4X-current-source-icons。第二轮前后页修正了左栏文件标签，直接显示实际TFC纹理标识，不再把物种同名存图名称当作当前引用。原生16×16和放大对照已看，VisualAccepted/RuntimeVerified均false。

## 文件与保护

九份既有文件修改、三PNG新增、零删除：三食品模型、两份书、gen-crops、gen-patchouli-book、audit-item-icon-routes、reviewed-item-icon-routes。无新工具文件，A源5913/B3107，工具A101/B19。

三模型继续item/generated和唯一layer0。所有原PNG、Java/B、食品/腐烂数值、标签/配方、气候、生长/掉落、植株模型/盆栽及ID/NBT/存档保持；不是向日葵整株或花盘修复，原两格生命周期另排。

图标合同版本9，累计43模型、72保护PNG、40食品数据。现有检查增加六页准确文字及两个生成器中六行物种声明的保护；只锁本片页面，不锁整书其他页面。后续合法更新这些说明时应同时更新证据与合同，不能静默跳过保护。生成模板增加三种产物说明并在原操作文字后追加，其他作物分支不变。

gen-crops -ItemIconsOnly继续只复制43份规范模型JSON，不复制书、图片或数据，不是完整资源包。没有照抄示例业务代码；检查逻辑按本项目需要独立组织，只使用公开JSON、框架资源格式及本项目已有检查。

## 检查与一项必须保留的生成边界

33项检查通过：32个隔离案例含正确版1个，31个负例覆盖三旧存图、三原生供体、三物种串图、三缺图、B覆盖、龙舌兰食品值改变、核桃回退、未保护32×32图片、六旧说明、重复锚点、缺书、B覆盖书和六旧模板行。另核43份安全复制JSON路径和字节一致，无多余图片/数据。

三份修改的PowerShell程序语法解析通过，并在Windows PowerShell5.1下实际执行图标检查/负例、安全复制或手册草稿；完整verify/healthcheck沿用PowerShell7。PS脚本保留UTF-8 BOM，JSON无BOM。418项跨命名空间台账匹配，完整引用、43/72/40保护、六说明/六模板和前片显示保护通过。

手册生成草稿的六页目标文本及所在索引均与正式源一致。首次检查错误假定整份草稿页数也应174而停止；随后定位到历史完整生成器额外输出草莓的一对页面，草稿176页、正式源174页。该整份差异没有伪装成通过，也没有发布草稿或把草莓重复页写入源。本片只证明六页模板内容一致；整书再生仍须按现有受限流程另做合并/页码检查，作为VK18/AR5待办保留，不能整树覆盖。证据在book-draft-comparison.json、book-draft.log，草稿保留于moddev/.probe/generator-output/ar4x-book-review。

当前255张item/food和item/seeds源PNG均16×16，构建包255张也逐项核对。GUI、方块、动画图集不套用这条尺寸规则。229食品/种子模型当前源哈希对账，TFC/A来源125/104，85条TFC来源种子不变。260号八项明确食品错配子组静态处理完成，但八共享叶菜、其他专用美术和74种栽培生命周期仍未完成。

## 备份、构建和交付

施工前全量备份9159条目至moddev/backups/ar4x-special-food-icons-20261026，含A/B源、工具、构建包、四旧安装包、根文档/规则、217/218/253～261及覆盖台账；逐文件核哈希，接入前再次核当前文件无外部修改。原图、旧备份和保护快照均保留。

A离线assemble成功，31秒，Java编译up-to-date。JAR精确差异为三模型和两书共五项修改、三PNG新增、零删除，八项内容等于正式源，原三物种旧PNG保持。四旧安装包先与备份核对，再只部署A至工作区mods和D:/TFC农业重置/PCL_TFC/mods。B未构建/部署。

A SHA-256：C7A4B007D79C598DD1BDA229BDA40E2540247DA7089F9138AE5FD6D1AB941075

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods和PCL_TFC/mods三份一致，综合静态健康检查通过，历史闲置空图继续按原范围保留。没有启动游戏、操作其他实例、改存档或重打PCL ZIP；以后打包仍先读215号。

本片证据目录：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\special-food-icons-20261026`，包含提示词、来源/原稿/采用与拒绝稿、语义、查看页、书页差异、当前分诊、尺寸、源/JAR差异、检查/草稿及构建交付记录。

回滚前保存当前工作，恢复备份九份文件并撤回三新增PNG；源删除后clean build防残留。也可直接恢复旧A（8853AAA79B608F8A2B0395183BC556536CA3022AB41CF39E8364DEA1149FAF9B）到两mods目录。B、旧ID和存档无需迁移，不用旧生成器回滚。

## 待验与下一片

用户后续核背包/创造栏/JEI三食品图标、食用籽与播种种子区分，中英文三个手册页的排版与实际操作；再按既有清单验证采摘/双格收获/莲座及原生食物用途、食品属性和保存重进。本片没有恢复用户延期实机及封窑完整操作测试。

下一片 **AR4-Y：芝麻菜、茼蒿、芥菜、紫苏独立食品图标，预期5/5**。四者当前共享kale叶束，旧同名保存图是根/果形，不直接回接。按实际叶菜产物逐张制作独立16×16候选，原图/食品/玩法保持，沿用43模型及六页说明保护，检查本片和前片不回退，再构建交付。开始前报告复杂度。

之后继续生菜/菠菜/牛皮菜/马齿苋、向日葵完整两格及其他生命周期、菠菜盆栽、树/灌木视觉、完整加工与AR5。整书再生差异随生成流程复核保留；全农业完成后才生成最终自然语言TXT总结，233号命名/结构整理继续留在全部既定工作完成后。
