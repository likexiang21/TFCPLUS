# AR4-U 八项食品图标修复与交付记录

日期：2026-10-26。按用户“继续”及258号下一步执行。预期复杂度5/5，实际5/5。本片八项食品图标的源文件修复、静态检查、构建和部署完成；最终美术和实机未验，VisualAccepted/RuntimeVerified均为false。

## 一、实际产物与处理结果

先核对MyCrops注册、八份食品数据、成熟掉落和十六页中英文手册，证据见本片product-semantics-evidence.json。芽甘蓝是普通作物；韭菜成熟后可空手右键采收并保留植株，破坏则拔除；木耳菜是攀爬作物，由下半株结算收获和返种，搭架返棍规则保持。五种水生作物维持现有水覆耕地播种及成熟收获规则。

| 食品 | 修改前实际图标 | 采用方案 |
|---|---|---|
| 芽甘蓝 brussels_sprouts | TFC洋葱 | 新增小叶球簇图，harvest_v1 |
| 韭菜 chive | TFC黑麦 | 接回既有chive.png，绿色细长叶，不改图片 |
| 木耳菜 malabar_spinach | TFC番茄 | 新增肥厚圆叶、紫红叶柄图，harvest_v1 |
| 菱角 water_caltrop | TFC稻穗 | 接回既有water_caltrop.png，棕色双角果，不改图片 |
| 荸荠 water_chestnut | TFC稻穗 | 新增扁圆深褐球茎图，harvest_v1 |
| 水芹 water_dropwort | TFC稻穗 | 新增浅色叶柄和分裂小叶图，harvest_v1 |
| 莼菜 water_shield | TFC稻穗 | 新增单片微卷嫩叶图，harvest_v2 |
| 空心菜 water_spinach | TFC稻穗 | 新增长叶及绿色茎图，harvest_v1 |

已实际查看当前引用图和同名存图，未把“同名”当作采用依据。六项旧存图未满足本片形态要求，继续保留原文件；韭菜、菱角既有图可作为当前候选接回。菱角原有grain0.4、vegetables0.6等全部食品属性保持，不以画面内容推导营养分类或擅自重平衡。图片切面、数量仅作识别表达，没有新增去皮、切片等配方。

## 二、六张新图的来源和尺寸

使用内置image_gen逐项生成透明背景候选，没有调用CLI或复制第三方业务代码。原稿在默认生成目录及本片imagegen-source双份保留，原图路径、哈希、尺寸、导出方式、正式路径详见imagegen-asset-manifest.json；完整六条初始提示词见imagegen-prompts.json，莼菜重做提示见imagegen-water-shield-retry-prompt.json。

正式新增文件均在以下目录，全部RGBA、16×16：

`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food`

- brussels_sprouts_harvest_v1.png
- malabar_spinach_harvest_v1.png
- water_chestnut_harvest_v1.png
- water_dropwort_harvest_v1.png
- water_shield_harvest_v2.png
- water_spinach_harvest_v1.png

技术导出采用最近邻等比缩小，居中放入透明16×16画布，保留Alpha，没有重新配色或用程序重绘。Alpha最大值254或255都允许，不强行变成255。大原稿不进入src或JAR。

莼菜首次双叶候选缩小后拥挤、辨识太弱，因此未接入正式源；其原图和16×16导出留在inventory，并在来源清单标记RejectedCandidate。第二次改单片较大的微卷嫩叶，实际查看后采用v2。空心菜的空心切口在原生尺寸和游戏中是否足够清楚仍需后续核验，不宣称已完美达到最终美术要求。

本片实际查看五张独立对照图：AR4U-before-and-stored-p1、p2、AR4U-exported-candidates、AR4U-water-shield-comparison、AR4U-current-source-icons，另查看七张生成原图。当前源图对照的长标签曾溢出，已改短文件名并重新查看；这只是检查图排版，不改游戏图片。没有把历史O～T的图算成本片重新查看。

## 三、修改边界和持续保护

源差异为九份既有JSON修改（八个食品模型及reviewed-item-icon-routes.json）、六PNG新增、零删除。模型保持item/generated和唯一layer0。所有旧PNG、Java、食品数据、种子、气候、掉落、方块生命周期、盆栽、语言、配方和B源码均不改；没有新物品ID、存档或NBT迁移。

合同升到版本7，累计保护35模型、56PNG、32食品数据。继续沿用现有audit-item-icon-routes、verify和16×16目录检查，工具程序没有改写。原PNG受哈希保护只表示不得意外覆盖，并不表示外观已被用户接受。gen-crops -ItemIconsOnly只安全复制35份规范JSON，不复制PNG或数据；历史完整生成器仍不可整树发布。

A源文件数5905，B源3107；工具文件数A101、B19。229食品/种子模型已按当前源哈希重新对账，TFC/A纹理来源128/101；85条TFC来源种子不变。既有“当前显示需修复；保存图另审”的明确错配子组已经清空，但96项专用美术复核、五坚果和三项产物定义、共享图标、74种栽培显示等待办仍在。来源是TFC不自动等于错误，本片完成不等于全农业通过。

## 四、备份、检查和构建

施工前全量备份9145条目至moddev/backups/ar4u-remaining-food-icons-20261026，含A/B源、工具、构建包、四旧安装包、根文档/规则、217/218/253～258及覆盖台账；复制后逐文件核哈希。work-plan.txt在源修改前保存，莼菜重做原因随后补记。保护快照、原图、旧备份和未采用候选均未清理。

28项检查符合预期：27个隔离案例（正确版通过；八旧供体回退、六错误存图路线、八缺图、B覆盖莼菜、菱角营养值改变、前片莲藕回退及未保护32×32图片共26负例被拦截），另核35份安全复制JSON路径和字节完全等于正式源，无多余图片/数据。尺寸负例独立被目录尺寸检查拦下。

隔离案例在Windows PowerShell5.1执行，子进程仅配置原生模块路径；完整verify和healthcheck沿用PowerShell7，不声明5.1完整流程兼容。35/56/32图标合同零发现，418项外部命名空间台账匹配，完整资源交叉引用及静态健康检查通过。历史闲置空图继续按既有审阅范围保留，不能据此宣称所有游戏外观已验。

A食品/种子目录全部247张PNG为16×16；构建包内这247张也逐项核尺寸。该规则针对item/food及item/seeds，未把GUI、方块或动画图集强改成16×16。

A离线assemble成功，日志26秒，Java编译up-to-date。与备份旧JAR逐条比较：恰八模型修改、六PNG新增、零删除，与正式源字节一致；两个复用图在包内也与旧包一致，没有大原稿混入。

## 五、交付和回滚

四个旧安装包先核对备份哈希，再仅部署A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。B未重新构建或部署。

A SHA-256：41540A6E8505BE4A4626F9D29715D5B6DFEE56A355332ACD87777DB2A3F66F16

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、PCL_TFC/mods三处一致。本片没有启动游戏、操作其他用户实例、改存档或重打PCL压缩包；以后打包仍先读215号成功流程。

回滚前保存当前工作，恢复本片备份的八模型与图标合同，撤回六新增PNG；源删除后需要clean build防止旧导出残留。也可直接将备份旧A（8194A6D2D88A8B5DB05D25999426658694C0EEE1BD43AC7AD2C5DC20FD17F893）恢复到两个mods目录。B与存档无需迁移，不使用旧生成器回滚。

本片证据目录：

`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\remaining-food-icons-20261026`

包括语义证据、图片/提示词/来源、源/JAR差异、当前229条分诊及尺寸清单、fixture和安全复制、verify/ledger/build/health、交付与最终状态。

## 六、待验内容与下一片

用户之后可在背包、创造列表和JEI核八项名称、图标、透明边缘与相互辨识，尤其莼菜嫩叶及空心菜茎部细节；再核韭菜保留植株采收、木耳菜搭架收获、水生作物播种和收获、食品属性及保存重进。资源包覆盖和实际游戏效果均未确认。继续遵循用户延期实机安排，不自动恢复封窑完整操作测试。

下一步AR4-V：剩余视觉待办与农业阶段状态统一复核，预期复杂度4/5。先读217/218/249及当前分诊并回查源，集中核五种坚果almond/hazelnut/macadamia/pecan/walnut和agave/sunflower/rhubarb的产物定义及候选范围，重排共享叶菜图标、菠菜盆栽后期共图、74种栽培和野生/死株等生命周期的优先级。区分“已修复待实机”“待专用美术”“实际接线或逻辑错误”，输出可直接执行的下一批清单；只读盘点不额外重建JAR，不因旧供体来源而盲目换图。进入下一片前在窗口报告复杂度。

全农业完成后再交付完整自然语言TXT总结。233号变量、文件命名、结构和可读性整理继续放在全部既定工作完成之后，AR5及其他农业缺口继续保留，不把本片图标分组清空当作全阶段验收。
