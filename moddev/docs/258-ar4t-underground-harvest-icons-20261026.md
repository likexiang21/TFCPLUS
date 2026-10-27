# AR4-T 芋头、山药、莲藕、慈菇图标修复

日期：2026-10-26。按用户“继续”与257号下一步执行。预期复杂度5/5，实际5/5。本片四食品图标修复、检查、构建与部署已完成；未进行实机或最终美术验收，全部VisualAccepted/RuntimeVerified=false。

## 一、先核实际产物

已读257号、217号当前计划及现有图标检查，核AGENTS/开发规则与上一片一致。核MyCrops注册、四食品数据与成熟掉落、蔬菜标签及八页中英文手册，证据保存在product-semantics-evidence.json。

芋头为水生作物age6成熟，莲藕age7、慈菇age5；山药为攀爬作物age7，bottom半株结算食品/返种，stick=true返棍。三种水生作物的水下播种规则和山药搭架行为均保持。B数据目录没有检索到四food ID直接引用，不据此推断通用标签配方不存在。

三当前食品图取TFC稻穗，山药取番茄。实际查看四对当前/保存图：芋头存图仍为稻穗、山药仍为番茄；莲藕/慈菇虽有通用杆状根形，但不具备藕节孔洞和带尖芽球茎特征，未直接接回。

芋头现有grain营养0.5、慈菇混合vegetables0.8/grain0.4都保留。营养类别不决定该画稻穗还是地下器官，本片不顺带重平衡食品，也不新增削皮、切片或烹饪状态。

## 二、新图与来源

内置image_gen逐物种制作候选：芋头褐色环纹球茎、山药长条褐色块茎和浅切面、莲藕藕节及可见孔洞、慈菇浅色球茎与尖芽。完整四条提示词：

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\underground-icons-20261026\imagegen-prompts.json

正式新增路径：

taro：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\taro_harvest_v1.png

yam：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\yam_harvest_v1.png

lotus：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\lotus_harvest_v1.png

arrowhead：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\arrowhead_harvest_v1.png

四图均为RGBA 16×16，Alpha范围0～254。大原稿1312×1199或1214×1295在默认生成目录及本片imagegen-source留档，未装入游戏。最近邻等比缩小、透明16×16画布居中，保留Alpha，不重新配色/重绘；exported-candidates保留采用字节。imagegen-asset-manifest.json记录原/导出哈希、尺寸、方法和正式路径。

实际查看三张对照图：AR4T-four-before-and-stored、AR4T-exported-harvest-candidates、AR4T-current-source-icons，另看四次生成原图。小图中的环纹、长条、三孔和尖芽可区分后才采用；不是凭文件名、统计指标或检查全绿直接采用。切面只是图形表达，不改变物品数量，不新增莲藕切片或山药削皮配方。四图仍是v1候选，最终风格与实机辨识等待用户确认。

## 三、修改范围与保护

仅改四个assets/tfcfarmingplus/models/item/food/{taro,yam,lotus,arrowhead}.json，layer0接到tfcfarmingplus:item/food/<物种>_harvest_v1，保留item/generated和唯一layer0；新增四PNG。全部旧PNG保持，没有新物品ID/语言/配方。

工具只扩展reviewed-item-icon-routes.json到版本6：累计27模型、42保护PNG、24食品数据。沿用现有audit-item-icon-routes、16×16目录检查、verify及gen-crops -ItemIconsOnly，未修改工具程序。安全模式只复制27份规范JSON，不复制图片，不是完整资源包，仍禁止整树发布历史草稿。

食品/腐烂、气候、掉落/返种/返棍、种子、栽培/野生/死株、盆栽、手册、配方、Java/NBT和B源均不改；原PNG受保护不代表其形态已经合格。A源5895增至5899，B仍3107。此前叶菜、茎菜、豆类、瓜类不回退，全局命名整理未提前执行。没有照抄示例业务代码；仅用标准generated格式及本项目既有独立检查，图片为内置image_gen候选。

## 四、备份与检查

正式改动前全量备份9140条目：moddev/backups/ar4t-underground-icons-20261026，含A/B源/工具/构建包、四旧安装包、根规则、README/217/218/253～257和覆盖台账，复制后逐文件核哈希。work-plan.txt先写具体输入/输出和完成条件，旧清单/备份/保护快照未清理或覆盖。

源差异恰五既有JSON（四模型+合同）修改、四PNG新增、零删除；没有原PNG、Java、B或其他玩法文件变化。JSON无BOM，既有PowerShell程序及BOM保持。

19项检查符合预期：18个副本中正确版通过，四旧稻穗/番茄回退、四接回同名错形图、四缺新图、莲藕食品ID串番茄、B覆盖新图、前片蛇瓜回番茄、芋头grain被改到1.5、未受保护32×32的17个负例均被拦下。特别验证了ID不变但营养值被改仍会失败，尺寸负例由尺寸检查独立拦下。另27份安全输出JSON的路径与合同一致、逐字节等源，无额外PNG/数据。

隔离检查在Windows PowerShell5.1下并仅给子进程原生模块路径；完整verify/healthcheck在既有PowerShell7运行，未声称5.1全流程兼容。资源、作物/树/灌木/土壤、叶菜/莲座/叶球、前片显示和27图标合同通过；418外部命名空间台账匹配，综合静态健康检查通过，历史闲置空图仍按原保护保留。

A食品/种子目录全部241张PNG为16×16，GUI/方块/动画图集不盲目套该规则。229模型按当前源哈希全量对账，TFC/A纹理来源136/93，85条TFC来源种子不变。“当前显示需修复；保存图另审”组余8条，另有专用美术/生命周期待办，不能等同全农业只剩8问题。74种栽培显示只取TFC纹理的统计未变，食品图标修复不能算作生长显示修复。

## 五、构建、交付与回滚

A assemble --offline成功，日志26秒，Java编译up-to-date。对备份旧JAR逐项ZIP比较，恰四模型修改、四PNG新增、零删除，八项与正式源字节一致。包内全部241食品/种子PNG也核为16×16，没有生成大原稿。

四旧安装包先与备份哈希核对，再仅部署A到工作区mods和D:/TFC农业重置/PCL_TFC/mods，B未构建/部署。

A SHA-256：8194A6D2D88A8B5DB05D25999426658694C0EEE1BD43AC7AD2C5DC20FD17F893

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

各自build/libs、工作区mods、PCL_TFC/mods三处一致。未启动游戏、改存档、操作其他用户实例或重打PCL ZIP；之后打PCL包仍按215号成功流程。证据在本片inventory，含语义、提示词/来源、三对照图、尺寸清单、源/JAR差异、fixture/安全复制、verify/ledger/build、交付/健康/最终状态。

回滚前保存当前工作，恢复备份四模型/合同，撤回四新增PNG；源删除后须clean build防止残留。或直接恢复备份A（D1C32093B6B93DFD639BF8A4124B243E4863AAA1744C7C3FD3F873B414F16EEE）到两个目录；B和存档无需迁移。不用旧生成器回滚，不清理原图、生成原稿和保护快照。

## 六、人工验收与下一步

之后在背包、创造列表、JEI核四食品名称/图标、孔洞/尖芽/环纹和透明背景；按三种水生作物及山药攀爬流程正常种植和成熟收获，核自己的食品/种子与山药返棍只结算一次，营养/腐烂信息保持，保存重进/资源重载及用户资源包优先级另核。离线图和源差异不能代替真实游戏，实机/最终美术均false。

AR4-U：剩余八项明确错配食品图标集中核对与修复，预期5/5。名单：芽甘蓝、韭菜、木耳菜、菱角、荸荠、水芹、莼菜、空心菜。先核食用部位和现有素材，尤其韭菜/菱角/荸荠等已有候选，按实际图像决定复用或新美术，不把同名存图自动接回、不为凑进度采用简陋错形。合格者接入同一保护、16×16检查和小批次构建部署；需另画者保留来源/候选。开始前报告复杂度。

该八项分诊处理后仍要复核其他专用美术、共享图标、74种栽培与野生/死株/盆栽等生命周期、完整加工及AR5，不把某个分组清空当全农业验收。全农业完成后交完整TXT总结；233号变量/文件命名、结构和可读性整理在全部既定工作收尾后开展。用户延期实机及封窑完整操作不自行恢复。
