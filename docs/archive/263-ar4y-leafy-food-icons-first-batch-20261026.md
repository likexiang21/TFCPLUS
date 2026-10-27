# AR4-Y 芝麻菜、茼蒿、芥菜、紫苏食品图标

2026-10-26。按262号下一步执行，预期复杂度5/5，实际5/5。本片四图标源文件、保护检查、构建和部署完成；最终美术和实机未验，全农业未完成。

## 实际产物与采用方案

核对MyCrops注册、四份食品数据、成熟掉落、直接声明的食物用途、盆栽产物及八个中英文文字页。四者都是现有叶菜食品，food与seeds分开，成熟收获逻辑沿用；本片只处理食品图标，不是植株或种子修复。

修改前四模型同取tfcfarmingplus:item/food/kale。实际查看共享图、旧同名存图和候选后，保留共享图/原存图，新建独立图片，不把旧根形/果形存图接回。

| 对象 | 采用候选 | 食品属性保持 |
|---|---|---|
| 芝麻菜arugula | 细长绿色裂叶、浅色主脉 | vegetables1.3，decay_modifier4 |
| 茼蒿garland_chrysanthemum | 较宽的分裂叶束、浅绿叶脉 | vegetables1.6，decay_modifier4 |
| 芥菜mustard_greens | 宽叶、明显浅色主脉与叶柄 | vegetables1.5，decay_modifier1.5 |
| 紫苏perilla | 紫色宽叶、尖端及叶缘、粉色叶脉 | vegetables1.2，decay_modifier3.5 |

四者hunger4、saturation0.5及其他食品字段均保持。图中叶片数量、叶柄和色泽仅用于辨识，不新增产物、加工步骤或数量收益；没有借绘图重平衡气候、营养、生长或采收。

## 图像来源与正式保存位置

使用内置image_gen逐项生成，不使用CLI。四张原稿及导出均在本片inventory保留，原默认生成目录不删除。完整提示词：

`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\leafy-icons-first-20261026\imagegen-prompts.json`

正式新增路径：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\arugula_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\garland_chrysanthemum_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\mustard_greens_harvest_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\perilla_harvest_v1.png`

均为RGBA16×16，Alpha范围0～254。原稿分别1267×1241、1312×1199、1278×1230、1254×1254；最近邻等比缩小、透明画布居中，保留Alpha，不程序重画/换色。大原稿不进入src/JAR，来源、原/导出哈希、尺寸和正式路径见imagegen-asset-manifest.json。

实际查看四张生成原稿及三张独立检查页：AR4Y-current-stored-candidates、AR4Y-exported-leafy-candidates、AR4Y-current-source-icons。第一张每物种并列当前共享图、旧存图和新候选，另含原生16×16；最后一张从实际模型反查正式源。已按轮廓、主脉和颜色初步区分后采用，细小裂叶、锯齿及游戏缩放效果仍待用户判断，不把离线查看当最终美术验收。没有只凭像素数或文件名选图，没有重看全部农业资源。

## 修改边界与保护

五份既有JSON修改：四食品模型及reviewed-item-icon-routes.json；四PNG新增、零删除。全部原PNG、Java/B、食品、标签/配方、语言/手册、生长/采收、掉落、种子、植株/盆栽、ID/NBT和存档保持。无工具程序改动，A源5917/B3107，工具A101/B19。

合同版本10，43条路线中仅四目标Texture改变，其他39条路线保持；新增四PNG保护，累计76PNG、40食品数据，原六页准确说明与六行模板保护完整保留。旧四同名PNG及食品原已受保护，没有重复增加食品条目。item/generated及唯一layer0保持，原生TFC种子图集保护不变。

229食品/种子模型按当前源哈希对账，TFC/A来源仍125/104，85条TFC来源种子保持。四者原本就在项目命名空间，故本片来源计数不变。实际剩余共享kale食品只有生菜、马齿苋、菠菜、牛皮菜四项；不把共享组处理进度当全部美术完成。

## 备份、检查和构建

施工前全量备份9163条目：moddev/backups/ar4y-leafy-icons-first-20261026，含A/B源/工具/构建包、四旧安装包、根规则与文档、217/218/253～262及覆盖台账。复制后逐文件核哈希，接入前再次确认当前文件与备份相同。原图、保护快照及历史文档未清理。

24项检查通过：23个隔离案例中正确版通过，四共享kale回退、四旧同名图回退、四目标串图、四缺图、B覆盖、芝麻菜营养值改变、大黄回退、未保护32×32图片、前批说明被改、前批模板字段被改共22个负例被拦下。尺寸负例独立由尺寸检查拦下。另43份安全复制JSON的路径和字节与正式源一致，无额外图片/数据。

隔离案例和安全复制在Windows PowerShell5.1下运行，子进程采用原生模块路径；完整verify/healthcheck沿用PowerShell7，不宣称5.1全流程兼容。43模型/76PNG/40食品、六说明/六模板检查零发现，418项跨命名空间台账匹配，资源交叉引用及前片显示保护通过。原生历史闲置空图按既有范围保留。

全部259张item/food与item/seeds源PNG为16×16，包内259张也逐项核尺寸。GUI、方块和动画图集不套用本条规则。A离线assemble成功，27秒，Java编译up-to-date；JAR与备份精确比较，恰四食品模型修改、四PNG新增、零删除，八项等于正式源，旧四PNG与旧包相同。

四旧安装包先与备份核对，再仅部署A至工作区mods和D:/TFC农业重置/PCL_TFC/mods。B未构建/部署。各自build/libs、工作区mods、PCL_TFC/mods三处一致：

A SHA-256：FC6773E088FCD8162C911387D429F4ABBD2621A530A74F6EAA8903CC8ABF0096

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

综合静态健康检查通过，没有启动游戏、改存档、操作其他实例或重打PCL包。以后打包仍先读215号。没有复制第三方业务代码；本片仅使用框架标准模型格式、本项目已有保护/检查和内置图像生成。

证据目录：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\leafy-icons-first-20261026`，包含语义、原稿/来源/提示词、三查看页、当前分诊、尺寸、源/JAR差异、fixture/安全复制、verify/ledger/build/health、交付及最终状态。

回滚前保存当前工作，恢复备份四模型及合同，撤回四新增PNG；删除源文件后clean build防止残留。也可直接把备份旧A（C7A4B007D79C598DD1BDA229BDA40E2540247DA7089F9138AE5FD6D1AB941075）恢复到两mods目录。B及存档无需迁移，不用旧生成器回滚。

## 待验与下一步

用户后续核背包、创造列表、JEI四食品图标与名称、透明边缘及相互辨识；成熟采收、食品/腐烂和原生食物用途按既有清单核验，保存重进与外部资源包优先级另核。全部VisualAccepted/RuntimeVerified仍false，用户延期实机及封窑完整操作安排保持。

下一片 **AR4-Z：生菜、菠菜、牛皮菜、马齿苋独立食品图标，预期5/5**。四者目前仍共享叶束，按实际收获物逐张制作16×16候选，不直接回接旧根/果形图。尤其生菜宽叶、菠菜叶片、牛皮菜叶脉/叶柄、马齿苋肉质小叶须区分；保持食品、种子、植株和盆栽逻辑，继续保护本批与前批图标、六页说明/模板，再检查和构建交付。开始前报告复杂度。

之后继续向日葵完整两格生命周期、菠菜盆栽成熟阶段、其余作物/树/灌木视觉和完整加工、AR5。262号整书再生176/174页差异仍在VK18/AR5队列，本片没有重跑或发布整份手册草稿。全农业完成后才交最终自然语言TXT，233号命名/结构整理继续放在全部既定工作完成之后。
