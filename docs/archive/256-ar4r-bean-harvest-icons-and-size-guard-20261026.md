# AR4-R 四豆类采收物图标与16×16检查

日期：2026-10-26。按用户“继续”及255号下一步执行，纳入用户强调的正式物品贴图16×16要求。预期复杂度5/5，实际5/5。本片四食品图标替换番茄借用、四新图、尺寸保护、检查构建和部署完成；实机及最终美术仍未验收，所有VisualAccepted/RuntimeVerified=false。

## 一、先核鲜荚和豆粒含义

已读255号/217号当前安排和现有图标合同，AGENTS及开发规则在施工前与上一片一致。核MyCrops的四食品/种子/攀爬作物注册、四食品数据、成熟破坏掉落、蔬菜标签及中英文手册。四者是普通攀爬作物，成熟age7，收获以bottom半株结算食品和返种，stick=true时返棍；这些条件均未修改。

蔬菜标签精确包含四种food ID，食品有蔬菜和蛋白属性；手册写菜豆“荚嫩豆香”、豇豆长荚垂挂、四棱豆荚有四条棱翅，豌豆属于蔬菜攀爬豆科。当前没有为本片新增或拆分“干豆”“剥壳豆”注册。本片依据这些记录选择鲜荚/嫩豆的图形表达；豌豆用打开豆荚显示新鲜圆豆，不表示新增剥壳流程。图中成对荚或三粒豆仅为图案，不修改物品份量、产量或配方收益。

最初按文本前缀搜索时food/pea会误中pear/pearl_millet，已改为解析JSON字符串并精确匹配完整ID；不能把水果/谷物的子串命中作为四豆归类证据。精确标签和八页中英文文字证据保存在product-semantics-evidence.json。

四当前模型都取tfc:item/food/tomato；四同名保存图也为红/粉番茄形，均不采用。另查看已有五种豆类及TFC豆荚候选，多为同一成熟荚形变色，不能表现本片长荚、圆豆和四翼区别。没有把同名坏图重新接回，也没有将鲜荚/干粒强行混作新增原料。

## 二、原创新图与尺寸

内置image_gen分别生成四候选：菜豆短弯荚、豇豆成对细长荚、豌豆荚中圆豆、四棱豆翼棱。完整四条提示词与豇豆修订提示词分别在：

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\bean-icons-20261026\imagegen-prompts.json

D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\bean-icons-20261026\imagegen-cowpea-retry-prompt.json

采用图正式路径：

common_bean：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\common_bean_pod_v1.png

cowpea：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\cowpea_pod_v2.png

pea：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\pea_pod_v1.png

winged_bean：D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\item\food\winged_bean_pod_v1.png

均为RGBA 16×16。原生成图1254×1254或1312×1199，仅保留在生成默认目录和本片imagegen-source，不进入游戏。采用最近邻等比缩小、透明16×16画布居中的导出，保留Alpha，不重新配色/重绘。新图与旧同名PNG分开，旧图完整保留。imagegen-asset-manifest.json记录原始/导出哈希、方法、默认生成路径、正式路径及提示词；exported-candidates保留采用字节。

豇豆初版16×16后左侧细荚出现断点，实际查看后拒绝，未写入正式源；保留初版原图与导出。单独重做强调连续加粗荚的第二候选，再导出、查看后采用cowpea_pod_v2.png，未用旧图勉强交付。其余三者为pod_v1。版本号是内部贴图文件，不新增玩家物品ID。

本片实看五张对照图：四对修改前/保存图、既有豆荚候选、初版导出、豇豆两候选对比、最终实际模型图，另查看五次image_gen原图。没有把尺寸、颜色数或校验全绿当最终美术验收。16×16下物种形态为当前候选，尤其四棱豆翼棱和长荚的最终辨识仍待用户实机确认。

## 三、正式修改与尺寸防回退

运行时仅四份assets/tfcfarmingplus/models/item/food/{common_bean,cowpea,pea,winged_bean}.json改为各自pod纹理，保留item/generated和唯一layer0；新增上述四PNG。没有新增物品、语言或配方。全部原PNG、ID、食品/腐烂属性、掉落/返种/返棍、种子、生长/野生/死株、盆栽、Java/NBT及B源不变。A源5887增至5891，B仍3107。

工具改两份：reviewed-item-icon-routes.json扩展到19模型、26保护PNG、16食品数据；audit-item-icon-routes.ps1新增PNG签名/IHDR尺寸核对，固定要求16×16，扫描A textures/item/food和seeds目录所有PNG，包括尚未列入保护合同的图片。当前完整扫描233张，无异常。GUI、方块和动画图集不套用这条食品/种子图标检查，不盲目缩放。

检查仍保护原图/食品数据哈希、模型路线与B同路径覆盖，源坏存图被保护不代表应采用。gen-crops的-ItemIconsOnly无需改代码，现复制19份规范JSON；它不复制PNG，不是完整资源包，仍禁止整树发布历史草稿。Root/符号链接/模式互斥限制保持。

已将农业食品/种子正式图标16×16及大原稿隔离要求写入DEVELOPMENT_RULES。没有修改示例模组业务代码，本片JSON是标准框架格式，工具沿既有项目独立实现扩展；图片为内置image_gen原创候选及保留的项目资源比较，无第三方业务代码移植。全局命名/结构整理未提前开展。

## 四、备份与检查

修改前全量备份9130条目：moddev/backups/ar4r-bean-icons-20261026，含A/B源、工具、构建包、四旧安装包、根规则及README/217/218/253/254/255和覆盖台账，逐文件核复制哈希。work-plan.txt先写输入/输出、文件、完成条件，再据实际豇豆候选问题细化到v2。保护快照、旧清单与备份未覆盖/清理。

review-manifest确认六既有文件修改（四模型、一个合同、一个检查脚本）、四PNG新增、零删除；没有原PNG/Java/B或其他玩法文件变化。PowerShell保持UTF-8 BOM并语法校验，JSON无BOM。没有更改系统永久设置。

正式20项检查符合预期：19副本中正确版通过，其余18个负例为四回退番茄、四接回同名坏图、四缺新图、错误豌豆食品ID、B覆盖新图、前片莴笋回洋葱、受保护32×32、未受保护32×32、损坏PNG头。未受保护32×32仅靠尺寸检查即产生一个问题并被拦截，证明尺寸保护不限于哈希清单。另19份安全输出JSON路径与合同一致、逐字节等源，没有额外图片或玩法数据。

隔离检查用Windows PowerShell 5.1并仅为子进程使用原生模块路径，完整verify/healthcheck使用现有PowerShell 7。没有声称5.1全流程兼容。资源、作物/树/灌木/土壤、叶菜/莲座/叶球、前片显示及19图标合同通过；418项外部命名空间台账匹配。综合静态体检通过，历史闲置空图保护保持。

229个现有食品/种子模型全部按当前源哈希重新对账，TFC/A纹理来源144/85；85条TFC来源种子未变。本轮后续“当前显示需修复；保存图另审”组还16条，是视觉分诊条目，不是16个独立崩溃。74种栽培显示只取TFC纹理的统计未变，食品图标修复不能算作生长显示修复。新分诊保留O/P/Q历史观察并更新当前引用，未虚称重看旧整套图或完成全农业。

## 五、构建与交付

A assemble --offline成功，日志31秒，Java编译up-to-date。与备份旧JAR逐条ZIP比对，恰四模型修改、四PNG新增，零删除，八项与正式源字节相同。额外核包内全部233食品/种子PNG均16×16，未把大尺寸生成原稿或失败候选装入游戏。

四旧安装包先与备份哈希核对，再只部署A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。B未构建/部署。

A SHA-256：6A9C897D60FBCF16AA6FCB942A741C953A4D1B6B971141986AE335F4D4766004

B SHA-256：EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3

两模组各自build/libs、工作区mods、PCL_TFC/mods三处一致。没有启动游戏、修改存档、操作用户其他实例或重打PCL ZIP；下次打包仍按215号成功流程。证据在本片inventory，含语义、图像/提示词/来源、尺寸清单、源/JAR差异、fixture/安全复制、verify/ledger/build、交付与健康、最终状态。

回滚前保留当前工作，恢复备份四模型和两工具，撤回四新增PNG；源删除后须clean build，避免残留。或直接恢复备份A（4A9F8D9EC464D691C10D8F718E8A206782A9CD74DD5727FC3277B62D7B2B15C1）至两个目录；B和存档无需迁移。开发规则中的用户16×16要求应继续保留，不用旧生成器回滚，不删除原PNG/生成原稿/备份。

## 六、人工验收与下一步

后续在背包、创造列表和JEI核四种食品名称/图标、透明背景和辨识；正常搭架种植并成熟破坏任意半株，核食品、种子及返棍只结算一次，保存重进/资源重载保持，食品信息/配方不串到其他作物。用户资源包优先级另核。四新图最终美术和实机都未验，前批共享叶菜/菠菜盆栽等待办继续保留。

AR4-S：攀爬瓜类采收物图标核对与修复，预期5/5，优先苦瓜、佛手瓜、丝瓜、蛇瓜。先核收获形态、食品/加工定义和现有图片，区分长短、棱沟与表皮；不接番茄样保存图，也不误改蔓延型独立瓜方块。需要新美术时逐物种候选实看并导出16×16，用本片尺寸保护防止误用原稿，合格后小批次接入、检查构建部署。开始前报告复杂度。

其后继续块根/种子辨识及其余农业生命周期、加工与AR5。农业完整TXT总结仍待整个农业阶段完成后交付；233号全局名称、文件结构和可读性整理仍在全部既定工作收尾后。用户延期的实机与封窑完整操作测试不自行恢复。
