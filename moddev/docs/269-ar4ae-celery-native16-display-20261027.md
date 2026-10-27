# AR4-AE 芹菜完整显示与原生16格贴图

2026-10-27，接268号。任务预期复杂度5/5，实际5/5。本片完成显示资源、保护检查、离线构建和部署；最终美术满意度及玩家实机仍待确认。没有启动游戏或修改存档，也没有生成PCL压缩包。

## 原有状态与依据

当前六龄模型均借用TFC洋葱0～5龄，成熟野生借用onion_wild，幼年野生直接引用dead_crop/onion_young；两枯株和Firmalife六龄盆栽也沿用洋葱。实际旧模型p28预览中能看到数根分开的洋葱叶和亮黄基部，幼年野生是褐色枯苗，和芹菜身份不一致。

逐张查看原保存图：六龄前期为小芽和细竖茎，中后期变成三团贴近地面的浅绿叶堆、褐色基部；野生与枯株为三根宽浅色柱；旧食品像圆洋葱，旧种子像红根菜。因此未把同名旧图直接接回。既有食用模型继续用celery_stalks_v1，播种继续借用TFC onion种子；未把食用图当种子，也未误用旧根菜图。

从已安装TFC JAR导出并查看onion0～5、carrot0～4、soybean0～5及原版野生草模型/贴图，记录资源路径与SHA256，并保留逐像素结构转录。参考稀疏幼苗、叶片深浅和逐龄器官延续；没有复制第三方业务代码，也未把原版图片换色充当新图。

现实株形参考[UC Davis芹菜资料](https://postharvest.ucdavis.edu/produce-facts-sheets/celery)的长叶柄与顶部绿叶特征，以及[RHS种植说明](https://www.rhs.org.uk/vegetables/celery/grow-your-own)。只用于本片外观设计，不引入现实气候/再生/产量或储藏参数。玩法继续使用现有普通单格6龄及原有掉落/重播规则。

## 像素稿与显示接线

八份逐图编写的16行×16列像素稿：六龄与成熟/幼苗枯株。每格明确颜色和透明位置，保留pixel-source-16；渲染后的native-grid-png原图为16×16，preview-64是精确四倍最近邻放大，仅留工作区，不进入源码和JAR。未使用高分辨率图缩小替代原生网格，也未调用AI生成图片。

首稿离线预览后，中后龄中央显得空，追加中心叶片与叶柄旁的小叶，保留draft-v1完整稿件供对比。最终原图、可编辑稿和64预览的路径均列于本片《贴图文件路径.txt》。正式八图：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_0_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_1_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_2_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_3_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_4_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\celery_age_5_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\celery_stalks_v1.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\celery_young_stalks_v1.png`

六龄与枯株使用两片居中、相互垂直的竖面，所有面轴、坐标、UV与合法旋转经过检查。野生两态复用第5/1龄新图，幼年不再是死洋葱；继续继承TFC原版野生父模型，并保留原版四片外围草、染色与槽1。没有另造同名原版草资源或在B覆盖A。

Firmalife保留quad盆、stages5、原有养分和种子/产物，六入口对应六龄新图，UV仍为原版[2,0,14,16]；盆栽会裁去左右边缘，成熟外侧叶尖有部分裁切，中心叶柄和主体叶仍可见，此项保留为实机美术确认内容。食品、种子、野生物品模型和栽培/死株blockstate保持原文件。

实际查看16格原图及正式src解析的p28、p5、p70，共六龄/两野生/两枯株/六盆栽16格。可见从小叶苗长为浅绿叶柄、深绿叶团的较高植株，成熟有分开的侧叶；枯株为褐色。低角度部分叶柄叠成较厚亮带，野生幼苗被周边草遮挡，俯视竖直面明显变窄；盆栽预览不含盆体。以上是离线观察及限制，不是游戏验收或用户美术认可。

## 保护、检查与交付

施工前完整备份9197条目至moddev/backups/ar4ae-celery-display-20261027，逐项核哈希，接入前复核A/B源码与工具无外部改动。全部原PNG、Java、气候、养分、食品、掉落、世界生成、注册ID/NBT、手册和B源码保持。

新增celery-display-contract/files及audit-celery-display，保护17份显示JSON、20张旧/新图、12份玩法/Java输入，覆盖10状态和原版野生依赖。verify接入芹菜保护，gen-crops新增CeleryDisplayOnly，复制前先检查，完整旧草稿末尾也恢复芹菜正式显示；未发布全量草稿。

23项检查通过：正确版和15个拒绝例（洋葱图回退、缺新图、64代替新图、额外64误进资源、旧图变更、幼野生回死洋葱、丢野生父级、改草槽、B覆盖、B覆盖原版依赖、掉落/盆栽/Java年龄变更、空几何和退化面）；5种安全复制分别17芹菜/17牛皮菜/21向日葵/17菠菜/44物品图标JSON，路径和字节与正式源相等；另逐像素核八份16格稿及64预览精确对应，并核旧贴图压缩包原文件不变且不进入JAR。

完整verify和418覆盖台账通过。索引模型16456/贴图7175，A资源blockstate481/模型2085/掉落481/configured246/placed246/物品435，交叉引用有效；44图标/81PNG/41食品保护通过。当前482参考blockstate/2839模型应用均可解析，49树/196叶状态仍为整块。A源码PNG从1793增至1801，所有图仍16×16；B的18×18GUI槽维持自身规格。

A最终离线clean assemble成功，35秒，Java重新编译。精确包差异为11份旧JSON修改、1份幼野生模型及8张新PNG新增，零删除；新图均16×16，原包所有PNG保持，无64预览/像素稿/草稿混入。源与工具恰13份修改、12份新增，另修改构建配置排除源目录内旧textures.zip（原压缩包保留）：A源5943/工具110（本片开工基线5934个源文件，含旧ZIP），B源3107/工具19。

A只部署至工作区mods及D:/TFC农业重置/PCL_TFC/mods，与build/libs三份SHA256均为6D9C304D9C5431973CFC4F3DE3A57D21872AA82F8825EC113AE1DEA969A7C3F5。B三份继续为EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3。静态资源健康检查通过。

## 本轮工具执行问题

原版carrot只有0～4龄；导出时首次取carrot_5失败，改为按JAR实际条目导出，未改游戏资源。旧离线绘图工具需Windows PowerShell5.1/System.Drawing；首次用PowerShell7调用失败，改用其适用环境后出图成功。完整verify含空键JSON，需要PowerShell7；首次在5.1解析失败，保留日志，使用PowerShell7检查后通过。负例脚本初次仍指向牛皮菜检查器，正确版按预期报缺资源；更正为芹菜检查器并保留首次fixture后，23项均通过。这些是验证工具的调用/适配失误，不作为客户端故障，也未靠修改游戏数据绕过。另，首次构建的精确包差异发现多出assets/tfcfarmingplus/textures.zip；该历史压缩包在施工前已存在源码且内容未变，之前交付JAR没有它，本次processResources将它带入。检查器拒绝交付，尚未部署。追加备份build.gradle.kts，仅为processResources明确排除此路径，保留源ZIP，clean assemble消除输出残留后复核包差异通过。

## 待实机与回滚

后续由用户实际播种、观察六龄/成熟整株采收与返种重播、野生两态、两枯株和六龄盆栽，重进存档核对；最终美术需单独确认。封窑完整操作继续由用户负责。VisualAccepted与RuntimeVerified均false。

需要回滚时先保存现状，再恢复备份的11份既有显示资源及gen-crops/verify；构建配置的排除规则建议继续保留，以免旧ZIP重新打入；9份新增源资源和3份保护工具先另存再撤回，删除资源后clean build以免旧产物残留；也可用旧A（78F8256355CE25DCD061E48A983382E408FC2DA8845AEB3D6B7DD0B87671600F）恢复两mods。新稿及原PNG继续保留，B与存档无需迁移。

## 下一步

下一步AR4-AF：莴笋（celtuce）完整显示链审查与必要修复，预期复杂度5/5。当前成熟模型仍引用onion_5，而食品已为celtuce_stem_v1；先看TFC原版和保存图、实际几何，再核六龄/野生/枯株/盆栽，保护食品图和既定整株采收规则。新图16格起稿、64仅预览；其余来源统计不是故障数。

仅用TFC纹理的栽培来源统计从72降至71；这不表示71个确定故障。其余种子、向日葵盆栽、树/灌木、加工与AR5保留原队列。全农业自然语言TXT总结和233号命名/结构整理仍在全部既定工作结束后开展。
