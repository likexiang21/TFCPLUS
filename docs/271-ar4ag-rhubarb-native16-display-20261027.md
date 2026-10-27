# AR4-AG 大黄完整显示与原生16格贴图

2026-10-27，接270号。任务预期复杂度5/5，实际5/5。完成资源、静态检查、构建和两处部署；玩家实机及最终美术仍未验。未启动游戏、改存档或制作PCL压缩包。

## 实际玩法与显示问题

MyCrops注册大黄为pickable，调用MyPickableCropBlock（TFC PickableCropBlock公开父类），不是普通整株收获后必须重播的作物。属性为age0～5；采摘后保留植株并退回成长状态。核对本项目注册/类与原版父类行为，未把此前普通单格切片的采收说明直接套到大黄。此片没有修改Java、成熟判定、采摘产物/数量或再生行为。

栽培六龄、野生、死株及Firmalife六龄盆栽实际借用大豆；幼野生直接引用dead_crop/soybean_young。离线真实模型中能看到豆株枝条、花点与偏黄成熟叶，幼野生则是褐色死苗。

逐张查看保存图：幼苗绿芽/红基部，中龄为窄红柱配几片横叶，成熟是三根红柄顶小叶，野生为伞状大叶冠配三条粗红脚，死株同为伞形轮廓。不直接接回这些旧图。既有食品模型继续使用rhubarb_harvest_v2（红叶柄收获物），种子继续借用TFC soybean，旧PNG全部保留。

## 参考与16格绘制

从已安装TFC JAR导出onion0～5、carrot0～4、soybean0～5及原版野生草模型/图，记录路径/SHA256，查看逐像素转录、二维接触表及真实模型。参考植株的色阶、幼苗和器官延续；没有复制第三方业务代码、没有把原版换色冒充新绘。

现实株形仅参考[RHS大黄资料](https://www.rhs.org.uk/fruit/rhubarb/grow-your-own)的宽叶与红色叶柄，以及[俄勒冈州立大学资料](https://extension.oregonstate.edu/catalog/ec-797-grow-your-own-rhubarb)的地面株丛特征。未据现实资料另造季节休眠、强制促成、毒性或食品规则。大黄的红色用于叶柄下部，绿叶不套牛皮菜的红叶脉形状。

八张图逐格编写16行×16列可编辑像素稿：六龄与两枯株。不是高分辨率图缩小，也未调用AI画图或用参数批量生成植物形状。pixel-source-16为绘制依据，native-grid-png为16×16原图，preview-64是精确四倍最近邻预览；64、像素稿及草稿均只留工作区。

本轮视觉迭代并非一次接入：初稿红柄在两面交叉后聚成红色块根状，第二版把叶柄分开，但低角度仍显粗；试过±45度竖面，侧向又像折扇，未采用。导出原版minecraft:block/cross仅作几何参考，未将试验模型写进正式源。最终收细叶柄，保留两侧红柄及中间空隙，恢复两个居中正交竖面。draft-v1/v2及各轮预览全部保留，没有覆盖原项目旧图。

正式八图如下；本片《贴图文件路径.txt》同时列出正式PNG、64预览和16格可编辑稿绝对路径：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_0_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_1_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_2_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_3_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_4_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\rhubarb_age_5_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\rhubarb_petioles_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\rhubarb_young_petioles_v1.png`

## 显示接线与观察限制

六龄及两枯株采用两个居中竖面，整图UV、面轴、坐标及合法旋转已核。野生两态复用第5/1龄，幼野生回正常绿苗；继承TFC野生父模型，保留四片原生外围草、tintindex和槽1，不覆盖原版草资源，也不在B遮盖A。

Firmalife保留quad、stages5、六入口、养分、种子及产物，六龄改用对应新图。原版UV[2,0,14,16]保留，新图主体在可见列内；没有将农田的可采摘再生行为擅自写进盆栽系统。

实际查看16格原图与正式src重新解析的p28/p5/p70，16格包括六龄、两野生、两枯株及六盆栽。可见上部宽绿叶、下部分开细红柄，成熟高于中龄，枯株为褐色。正侧视两面叠加仍会形成环状/框状叶柄轮廓，俯视竖面变窄；野生幼苗被外围草部分遮挡，盆栽预览不含盆体。这些是本片的已知视觉限制，未声称最终美术合格，需用户实机审美确认。

## 保护、检查与交付

施工前完整备份9224条目至moddev/backups/ar4ag-rhubarb-display-20261027，逐项核SHA256，接入前再核A/B源与工具无外部修改。全部旧PNG、食品/种子/野生物品模型、栽培/死株blockstate、Java、ID、NBT、气候/掉落/食品/世界生成/手册和B保持。

新增rhubarb-display-contract/files及audit-rhubarb-display，保护17显示JSON、20旧/新PNG、13玩法/Java输入（增加MyPickableCropBlock），覆盖10状态、原版野生父资源及16格尺寸。verify接入新保护，gen-crops增加RhubarbDisplayOnly，复制前完整预检；全量旧草稿末尾恢复正式大黄显示，未发布整份草稿。

26项检查通过：17隔离fixture（正确版及16拒绝例，含旧大豆图回退、缺图/64替原图、额外64误进源、旧图变更、幼野生回死株、父级/草槽变更、B覆盖、掉落/盆栽变更、可采摘年龄和MyPickable属性改变、空几何/退化面）；7种安全复制（17大黄/17莴笋/17芹菜/17牛皮菜/21向日葵/17菠菜/44物品图标JSON），路径和字节等于正式源；八份16格稿/64预览对应；历史textures.zip不入包且既有构建排除规则保持。

完整verify与418覆盖台账通过；44图标/81PNG/41食品保护通过。索引模型16458/贴图7191；A资源blockstate481/模型2087/掉落481/configured246/placed246/物品435，交叉引用均有效。当前482参考blockstate/2839模型应用均解析成功，49树/196叶状态仍整块；A源1817张PNG均16×16，B的18×18GUI槽保持自身规格。

A离线assemble成功（28s），Java up-to-date。精确JAR差异11份既有JSON修改、1幼野生模型及8张PNG新增，零删除；新图16×16且字节等于源，原包全部PNG保持，64预览/草稿/像素稿未入包。A/B源码与工具恰13修改、12新增，其余保持。源/工具实际数量：{'tfcfarmingplus/src': 5961, 'tfcfarmingplus/tools': 116, 'tfcagricultureplus/src': 3107, 'tfcagricultureplus/tools': 19}。

A部署至工作区mods及D:/TFC农业重置/PCL_TFC/mods，与build/libs三份SHA256为F16EA3810174E3D529B604014DE19C8EC338240E2305CBC3BA473A2BE4FB65F6。B三份仍为EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3。静态健康检查通过。保留269号textures.zip排除规则，本轮未改构建配置，源码历史ZIP仍在。

## 实机待验与回滚

后续实际播种观察六龄；分别核可采摘阶段与成熟阶段采摘、产物仍为既有红叶柄、植株保留/退回生长/继续生长，区别于直接打掉植株；查看野生两态、两枯株及六龄盆栽，重进存档核对。农田可采摘和Firmalife原生盆栽按各自行为验收，不互相代替。最终美术需单独确认，VisualAccepted/RuntimeVerified均false。封窑测试仍由用户负责。

回滚前保存现状，恢复备份11份既有显示JSON和gen-crops/verify，先另存后撤回9新增源资源及3保护工具，删除资源后clean build防残留；或把旧A（D2CBDD1E3AF217E62EC6738A2A09D05D6F557282D518555BABFC0D98CBC51F6B）恢复到两mods。原图/像素稿和既有构建排除规则保留，B与存档无需迁移。

## 下一步

下一步AR4-AH：芦笋（asparagus）完整显示链审查与必要修复，预期复杂度5/5。当前成熟模型仍借用barley_5；先核当前可采摘机制、保存图与已安装TFC同族参考，再审六龄/野生/枯株/盆栽及嫩茎食品图，按实际物种辨识需要修复。保护既有采摘与气候规则，新图16格起稿、64仅工作区预览。

仅使用TFC可见纹理的栽培来源统计由70降69，属于来源统计，不是69个确定故障。其余种子、向日葵盆栽、树/灌木、加工及AR5维持队列。完整农业自然语言TXT总结与233号全局命名/结构整理仍在全部既定工作结束后开展。
