# AR4-S 四攀爬瓜类采收物图标修复

日期：2026-10-26。按用户“继续”和256号下一步执行。预期复杂度5/5，实际5/5。四种食品图标本片修复、检查、构建和部署完成；没有实机或最终美术验收，全部VisualAccepted/RuntimeVerified=false。

## 一、需求与现状依据

已读256号及217号当前计划、现有图标检查，核AGENTS和开发规则与上一片一致。核MyCrops四食品/种子/攀爬作物注册、四食品数据、成熟掉落、蔬菜标签和八页中英文手册，保留product-semantics-evidence.json。四者是攀爬作物，成熟age7、bottom结算食品和返种，stick=true时返棍；不是冬瓜/葫芦/哈密瓜那类向旁边放独立瓜方块的蔓延作物。

现有食品为完整食用瓜果的视觉表达，不增加加工步骤或物料。丝瓜表现食用嫩瓜，未改为干纤维。四当前模型都取tfc:item/food/tomato，四同名保存图仍是红/粉/橙色番茄状，不采用。已有瓜切片文件也没有作为这些整瓜的默认替代。B数据下没有检索到这四food ID的直接引用；这不是宣称不存在通过通用标签参与的配方。

本次按四种不同形态制作候选：苦瓜梭形疙瘩表皮、佛手瓜梨形沟槽、丝瓜长筒纵棱、蛇瓜连续弯曲长体和浅色纵纹。只修食品模型和新增内部图，不改生长、掉落、加工或独立瓜方块。

## 二、采用图片与来源

四张图均由内置image_gen分别生成；没有照抄第三方模组业务代码或覆盖旧画。完整四条提示词：

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\climbing-gourd-icons-20261026\imagegen-prompts.json

正式新增路径：

bitter_melon：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\bitter_melon_fruit_v1.png

chayote：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\chayote_fruit_v1.png

loofah：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\loofah_fruit_v1.png

snake_gourd：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\snake_gourd_fruit_v1.png

四者均为RGBA 16×16。原始生成尺寸为1312×1199、1278×1230或1254×1254，只在默认生成目录和本片imagegen-source留档，未进入游戏包。最近邻等比缩小、透明16×16画布居中导出，保留Alpha，不重新配色或重绘；四导出Alpha范围均0～254。exported-candidates保留采用字节，imagegen-asset-manifest.json记录原始/导出哈希、尺寸、方法、生成路径、正式路径及提示词。

已实际查看三张对照图：AR4S-four-before-and-stored、AR4S-exported-fruit-candidates、AR4S-current-source-icons，另查看四次生成原图。16×16成图中轮廓/表皮有区别，蛇瓜主体保持连续，才接入源。没有仅凭文件名、尺寸或检查全绿决定采用，也未把这次离线判断写成用户最终美术验收。全部旧PNG和历史快照保留。

四图都是v1候选，后续仍需用户确认小尺寸下的物种辨识、表皮细节和风格。大图只作为原稿；实际交付图已经是16×16。

## 三、准确改动和保护

运行时改四份assets/tfcfarmingplus/models/item/food/{bitter_melon,chayote,loofah,snake_gourd}.json，layer0分别改为tfcfarmingplus:item/food/<物种>_fruit_v1，保留标准item/generated和唯一layer0。新增上述四PNG，不新增物品/语言/配方/注册ID。

工具只改reviewed-item-icon-routes.json到版本5：累计23模型、34保护PNG、20食品数据，增加本片图案及验收状态。沿用audit-item-icon-routes的16×16检查、B覆盖与哈希保护，gen-crops -ItemIconsOnly和verify不改代码。旧坏存图受到保护只表示不擅自改画，不表示应接回。安全输出仍只是23规范JSON，不复制图片、不构成完整包，不得整树发布历史草稿。

全部原PNG、食品/腐烂/气候、掉落/返种/返棍、种子、栽培/野生/死株、盆栽、配方、手册/语言、Java/NBT及B源不变。冬瓜等蔓延独立瓜方块和相关皮肤/模型不变。A源5891增至5895，B仍3107；此前叶菜/茎菜/豆类图标不回退。全局命名整理未提前开展。

## 四、备份与验证

修改前全量备份9135条目：moddev/backups/ar4s-climbing-gourd-icons-20261026，含A/B源/工具/构建包、四旧安装包、根规则、README/217/218/253～256及覆盖台账，复制后逐文件核哈希。work-plan.txt先列输入/输出、文件和完成条件。备份、旧清单和保护快照未清理或覆盖。

源差异恰五既有JSON（四模型+合同）修改、四PNG新增，零删除，无任何原PNG、Java、B或其他玩法文件变化。JSON无BOM；本片无PowerShell代码修改，既有检查保持。

18项检查符合预期：17副本中正确版通过；四回退番茄、四接回同名坏图、四缺新图，加上佛手瓜食品ID串番茄、B覆盖新图、前片豇豆回番茄、未受保护32×32的16个负例均被拦下。尺寸负例仅由尺寸检查即产生一个问题。另23份安全输出JSON的路径与合同一致、逐字节等源，未生成PNG或数据。本片只针对新合同和必要前片/尺寸边界检查，没有重跑历史全量生成器。

隔离检查用Windows PowerShell 5.1并只为子进程设置原生模块路径；完整verify/healthcheck用现有PowerShell 7，未声称5.1全流程兼容。资源、作物/树/灌木/土壤、叶菜/莲座/叶球、前片显示及23图标合同通过，418外部命名空间台账匹配，综合静态健康检查通过。历史闲置空图继续按原合同保留。

A食品/种子目录全部237张PNG均16×16，检查不盲目作用于GUI/方块/动画图集。229个模型按当前源哈希全量对账，TFC/A纹理来源140/89，85条TFC来源种子不变。后续“当前显示需修复；保存图另审”组还12条，是视觉分诊，不是12个崩溃；另有专用美术和生命周期待办，不能说农业全部修完。74种栽培显示只取TFC纹理的统计不变。

## 五、构建和交付

A assemble --offline成功，日志27秒，Java编译up-to-date。与备份旧JAR逐项ZIP对比，恰四模型修改、四PNG新增，零删除，八项与正式源字节一致。包内全部237食品/种子PNG也均16×16，未混入生成大原稿。

四旧安装包先与备份哈希核对，再仅部署A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。B没有构建或重新部署。

A SHA-256：D1C32093B6B93DFD639BF8A4124B243E4863AAA1744C7C3FD3F873B414F16EEE

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、PCL_TFC/mods三份一致。未启动游戏、改存档、操作用户其他实例或重打PCL ZIP；以后打PCL包仍先按215号成功流程。证据在本片inventory，含语义、提示词/来源、对照图、源/包尺寸、源/JAR差异、fixture/安全复制、verify/ledger/build、交付与健康、最终状态。

回滚前保留当前工作，恢复备份四模型与合同，撤回四新增PNG；源删除后须clean build避免图片残留。或直接恢复备份A（6A9C897D60FBCF16AA6FCB942A741C953A4D1B6B971141986AE335F4D4766004）至两目录。B和存档不需迁移，不用旧生成器回滚，不删原图/生成原稿/备份。

## 六、验收与下一步

待人工在背包、创造列表和JEI核四食品名称/图标、透明背景及物种区分；正常搭架长成后破坏任一半株，核食品/种子/返棍只结算一次，保存重进/资源重载与用户资源包优先级另核。蔓延型冬瓜等独立瓜方块可作为范围回归；本片源/JAR差异证明未改它们，仍不等于实际游戏验证。所有实机/最终美术标记保持false，前片共享叶菜和菠菜盆栽成熟共图等待办保留。

AR4-T：地下收获物图标核对与修复，预期5/5，优先芋头、山药、莲藕、慈菇。当前这些食品仍借用稻穗或番茄；先核实际收获/加工定义，分辨块茎、球茎和根茎等应表现的部分，逐图审现有候选，不能按同名文件直接回接。需新图时留原稿与旧图、实看16×16成图并纳入同一保护，再检查构建部署。开始前报告复杂度。

其后继续剩余种子/食品辨识、其他农业生命周期/加工和AR5。全农业完成后交完整TXT总结；233号全局变量/文件名称、结构与可读性整理仍在全部既定工作收尾后开展。用户延期的实机与封窑完整操作不自行恢复。
