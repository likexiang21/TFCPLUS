# AR4-W 五种坚果食品图标修复

2026-10-26。按用户“继续”和260号施工清单执行，预期复杂度5/5，实际5/5。五种坚果食品图标的源文件、保护检查、离线构建及部署完成；最终美术和实机未验，VisualAccepted/RuntimeVerified均为false。

## 产物定义与图像处理

重新核对五种产物的模型、食品数据和直接声明消费者，并与260号原始证据哈希核对。五者维持现有food ID、可食用坚果定义、树叶采收/掉落及盆栽产物，坚果分类和原生汤/沙拉/三明治用途不变，没有新增去壳、坚果壳、果仁注册或加工设备。

| 食品 | 原图表现 | 新候选表现 |
|---|---|---|
| 杏仁 almond | 桃形水果 | 尖长棕色杏仁，浅边和纵向纹理 |
| 榛子 hazelnut | 双樱桃 | 两颗短圆棕色坚果，浅色底痕 |
| 夏威夷果 macadamia | 柠檬 | 深褐圆壳和显露的浅色圆果仁 |
| 碧根果 pecan | 橙子 | 深褐长条壳纹及小块金色果仁 |
| 核桃 walnut | 绿苹果 | 宽圆褶皱壳和金色双瓣果仁 |

果仁、壳和多颗构图只是既有物品的图形表达，不代表新增去壳工序、一次多产物或数量收益。树上果实贴图未在本片处理，食品图标完成不等于整棵坚果树美术完成。

食品hunger4、protein1.5、saturation0.5保持；核桃/榛子/碧根果decay_modifier1，杏仁/夏威夷果1.5保持。旧“极耐储”草案不借修图重新调整平衡。原五张水果形图片全部保留原字节，不覆盖。

## 图像来源、导出和实际查看

采用内置image_gen，为五个物种分别提供提示词并生成，不使用CLI。没有从第三方示例复制业务实现或用一张球形图片换色充当五种坚果。完整提示词：

`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\nut-icons-20261026\imagegen-prompts.json`

五张正式新增图：

- 杏仁：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\almond_harvest_v1.png`
- 榛子：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\hazelnut_harvest_v1.png`
- 夏威夷果：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\macadamia_harvest_v1.png`
- 碧根果：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\pecan_harvest_v1.png`
- 核桃：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\walnut_harvest_v1.png`

1254×1254原稿保留在默认生成目录及本片imagegen-source；正式图均为RGBA16×16，以最近邻等比缩小，置于透明画布居中，保留Alpha，不程序重画或重新配色。Alpha最大值254或255都有效。原图/导出哈希、完整路径、尺寸和导出方法在imagegen-asset-manifest.json中登记；大原稿不放进src或JAR。

实际查看五张生成原图，以及四张独立检查页：AR4W-before-and-candidates-p1/p2、AR4W-exported-nut-candidates、AR4W-current-source-icons。前后页包含原生16×16及放大图；最后一页从实际修改后的模型反查图片。五者已可通过轮廓和大色块区分后才采用本片候选，没有把自动检查或文件名当成视觉依据。没有重看全部农业美术，不宣称已获用户最终风格验收。

## 修改范围和持续保护

源差异恰六份既有JSON修改：五个models/item/food模型及tools/reviewed-item-icon-routes.json；新增五PNG、零删除。模型保持item/generated和唯一layer0，指向本物种harvest_v1。

合同升为版本8，累计40模型、66保护PNG、37食品数据；新增五种的旧/新图和食品哈希保护。沿用现有audit-item-icon-routes、16×16目录检查、verify和gen-crops -ItemIconsOnly，工具程序未改。安全模式只复制40份规范JSON，不复制图片，不发布整树历史草稿。

A源文件5910、B3107，工具A101/B19。全部原PNG、Java/B、食品属性、气候、季节、树体、掉落/采收、盆栽产物、语言、配方、ID/NBT及存档均保持。没有提前执行233号全局改名或结构整理。

229食品/种子模型按当前源哈希重新对账，TFC/A纹理来源仍128/101，85条TFC来源种子保持。因为五者原本就引用项目图，本片不会改变命名空间计数，不能用该计数衡量本次图像修复。260号八项确认错配中，五坚果已静态处理，其余agave/rhubarb/sunflower三项仍待修；八共享叶菜、其他专用美术、74种栽培及生命周期待办继续保留。

## 备份与检查

施工前全量备份9153条目至moddev/backups/ar4w-nut-icons-20261026，包括A/B源、工具、构建包、四旧安装包、根文档与规则、217/218/253～260和覆盖台账。复制后逐文件核哈希；接入前再次核备份与当前文件，确认无外部修改。work-plan.txt先记录具体输入输出与完成条件。

26项检查符合预期：25个隔离案例中正确版通过，五接回旧水果形存图、五接原生水果供体、五坚果之间串图、五缺新图、B覆盖、杏仁蛋白值改变、前片莼菜回稻穗及未保护32×32图片共24个负例被拦下。尺寸负例由尺寸检查单独拦下。另40份安全输出JSON路径及字节等于正式源，无额外图片/数据。

隔离案例沿用Windows PowerShell5.1及子进程原生模块路径，完整verify/healthcheck在PowerShell7执行，不声明5.1完整流程兼容。图标保护40/66/37零发现；资源交叉引用、前片辣椒/葫芦巴/菠菜显示保护及418项外部命名空间台账通过，综合静态健康检查通过。历史闲置空图仍按既有有哈希保护的范围保留。

当前item/food与item/seeds共252张源PNG均16×16，构建包内252张也核尺寸。GUI、方块和动画图集不套用此物品图标规则。

## 构建、部署与回滚

A离线assemble成功，27秒，Java编译up-to-date。与施工前备份JAR逐条比较，恰五食品模型修改、五PNG新增、零删除；十项内容等于正式源，所有旧坚果PNG与旧包一致，没有大原稿或业务类变化。

四旧安装包先核备份哈希，再仅把新A同步到工作区mods和D:/TFC农业重置/PCL_TFC/mods。B未构建或部署。A/B各自build/libs、工作区mods、PCL_TFC/mods三处一致：

A SHA-256：8853AAA79B608F8A2B0395183BC556536CA3022AB41CF39E8364DEA1149FAF9B

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

没有启动游戏、改存档、操作其他用户实例或重打PCL压缩包。以后打包仍先读215号成功流程。本片inventory保留提示词/来源、语义、四查看页、源/JAR差异、229条当前分诊、尺寸、fixture/安全复制、verify/ledger/build/health、交付与最终状态。

回滚前保存当前工作，再恢复备份五模型和图标合同，撤回五新增PNG；源删除后要clean build防止残留。也可直接把备份旧A（41540A6E8505BE4A4626F9D29715D5B6DFEE56A355332ACD87777DB2A3F66F16）恢复到两个mods目录，B及存档不迁移。不用旧生成器回滚，不清理原图、原稿或受保护快照。

## 人工待验与下一步

用户后续在背包、创造列表和JEI核五食品名称/图标、透明边缘及相互辨识；五种树正常采收、盆栽收获和原生食品用途按既有清单验证，食品/腐烂信息应保持。保存重进和外部资源包优先级另核。继续遵守用户延期实机、封窑完整操作交用户的安排。

下一片 **AR4-X：大黄、向日葵、龙舌兰食品图标及准确说明，预期5/5**。以260号已核语义为输入：大黄表现叶柄，向日葵食品表现可食籽并保留播种种子独立ID，龙舌兰表现中心收获物。核实际手册和生成模板，把尚无配方的榨油等愿景与当前可执行用途说清，不因改图增加物种、去壳/榨汁设备或新ID，不改现有食品和采收。候选逐项16×16查看、保留旧图、扩合同和负例，构建后核精确差异再交付；具体文件和文案在施工前重新盘点，开始前报告复杂度。

八共享叶菜、向日葵两格完整生命周期、菠菜盆栽成熟显示及其余农业/AR5继续按260号队列。全农业完成后才交最终自然语言TXT总结，233号命名和结构整理仍在全部既定工作完成之后。
