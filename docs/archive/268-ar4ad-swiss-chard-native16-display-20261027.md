# AR4-AD 牛皮菜完整显示与原生16格贴图

2026-10-27。接267号，预期复杂度5/5、实际5/5。用户中途要求：所有本轮贴图以16为绘制基础，64只是预览，并发送文件路径。已按此要求完成八张原图、可编辑像素稿和逐张路径清单；源码/静态检查/构建/部署完成，最终美术和实机仍未验。

## 原有问题与参考

实际栽培六龄、野生、枯株和盆栽均显示TFC甜菜，成熟会出现红色块根。保存的同名图也不适合盲接：age0/1几乎相同，中龄浅色茎像根，成熟像几根浅色长柱。播种旧图像褐色块根，未采用；食用图沿用先前swiss_chard_harvest_v1，种子图仍为TFC lentil，不把食用图当播种图。

从已安装TFC JAR提取beet0～5、野生/枯株、cabbage5、soybean5、lentil5，实际查看二维和当前真实模型；native-reference-manifest记资源及哈希。第一次离线导出猜了原版模型名beet_0而不存在，随后读取真实blockstate，改用beet_age_0等；另修复预览临时名称碰撞，避免把野生和死株都画成死株。这些是离线证据导出问题，未据此修改游戏逻辑。

现实株形仅参考[RHS牛皮菜资料](https://www.rhs.org.uk/vegetables/chard/grow-your-own)中的叶片、叶柄和叶脉；没有根据现实割叶再生去改写70号既定普通单格采收。267号中英文整株采收后重播说明继续保持。

## 16为绘制基础，64仅预览

前期内置image_gen制作六龄、四张修订和两枯株共12份大稿。缩成16后，中龄红基部仍像块根；用户强调16格起稿后，这些AI大稿全部不采用，保留于imagegen-source和三个提示词文件中作失败记录。没有把“导出16”称为“从16格起稿”。

最终另建八份16行×16列可编辑像素源，逐格指定轮廓、叶片、细红叶脉、短绿叶柄、枯叶及透明格；用项目既有的像素稿格式渲染到16×16 PNG，不用公式生成植株形状。pixel-source-16为原始绘制依据，native-grid-png为原图，preview-64为精确四倍最近邻预览；所有原图和旧草稿不覆盖。64预览、大原稿、接触表及像素稿都不进入JAR。

正式八图路径：

- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_0_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_1_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_2_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_3_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_4_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\crop\swiss_chard_age_5_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\swiss_chard_leafy_v2.png`
- `D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\textures\block\dead_crop\swiss_chard_young_leafy_v2.png`

完整可复制清单：`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\inventory\swiss-display-20261027\贴图文件路径.txt`，逐张包括正式PNG、64预览和16格像素源。保存清单、源码及JAR三者已对账。

修改前扫描A全部1785张PNG均16×16；本片加入八张后共1793张，全部仍16×16。B为57张16×16，以及一张18×18的用户养蚕箱GUI槽素材，按其界面用途保留；没有为作物规则盲改界面。尺寸检查不等于逐张追认历史图的绘制基础，本片只确认这八张从16格起稿。历史高分辨率来源可在后续逐批审查，新作物单图规则已写入DEVELOPMENT_RULES。

## 显示接线与实际查看

六龄表现从小叶苗长为带红叶脉的绿叶株，基部为细绿柄，地面不再有红色块根。八张图是六龄及成熟/幼苗枯株，野生成熟/幼株复用第5/1龄，盆栽用相同六龄，减少互相不一致的整套图。

初版把新图放入旧四片分散的crop面，真实预览会围成空框，未采用。最终以两个居中竖面表现作物和死株；所有面轴正确、UV完整，无越界旋转角。野生继续继承tfc:block/wild_crop/crop，作物部分为居中面，保留原生四片wild_crop_grass、染色和槽1，不自造草底座。

盆栽保持quad、stages5和六入口，其原生UV为[2,0,14,16]；六龄新图均位于可见列内且基部到底。没有改盆类型、温室、物品库存、收获规则、食物新鲜度或产量。

实际查看旧图/原版表、未采用AI导出、最终原生16格图、候选及正式src重新解析的p28/p5/p70。每个最终检查图包含六龄、野生两态、死株两态和盆栽六阶段，共16格。可见绿叶、分开的细叶柄和少量红叶脉，成熟较幼龄高且叶面更大；枯株为褐色下垂叶，野生外围为原版深绿草，幼苗部分被草遮挡。竖直面在俯视下变窄，盆栽预览不含盆底；这些限制记录，未称为实机或最终美术验收。

## 防回退、检查与交付

施工前备份9182条目至moddev/backups/ar4ad-swiss-display-20261027，逐项核哈希，接入前再核源/工具无外部修改。原有全部PNG、Java、B、食品/掉落/气候/采收、手册、注册ID和NBT均保持。

新增swiss_chard-display-contract/files及audit-swiss-chard-display：保护17份显示JSON、20张旧/新图、12份玩法/Java输入，并核10个状态、面轴/旋转和原生草模型/贴图哈希。普通crop/wild/dead单张图片新增16×16检查；GUI与声明动画图集按独立规格，不把它们当64预览。verify接入新保护，gen-crops新增SwissChardDisplayOnly先完整检查再复制17份JSON，完整旧草稿末尾也会恢复正式显示数据。

21项检查通过：正确版及15负例（甜菜图回退、缺新图、用64替新图、额外64预览误进资源、旧图被改、幼野生回甜菜、丢草父级、自有草覆盖、B覆盖、原版父资源被覆盖、掉落变更、盆栽重复龄、Java分龄改变、空几何、退化面）；4种安全复制分别17牛皮菜/21向日葵/17菠菜/44图标，路径和字节等于源，不额外绘PNG；另核八份16格像素稿和64预览的逐像素四倍对应。

完整verify、418覆盖台账通过。A离线assemble成功，28秒，Java编译up-to-date。JAR恰11份既有JSON改、1份幼野生模型和8张PNG新增，零删除；八新图均16×16，变化与正式源相同，原包所有PNG保持，未混入64预览或大稿。A源5933/工具107，B源3107/工具19；源/工具差异为13份既有文件修改、12份新增，根规则另记录16格/64预览要求。

部署前核四旧安装包与备份一致，仅更新A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。A在build/libs及两mods三份SHA-256：78F8256355CE25DCD061E48A983382E408FC2DA8845AEB3D6B7DD0B87671600F。B三份保持EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3。部署后静态健康检查通过。

当前482个参考blockstate/2839模型应用全部解析成功，49树/196叶状态仍整块。仅用TFC可见纹理的栽培统计从73降72，仅是来源统计，不代表72个游戏故障。44图标/81PNG/41食品与八页/八模板、菠菜/向日葵保护均保持；整书176/174页差异未在本片处理，也未发布草稿。

没有启动游戏、改存档或打PCL ZIP。正常种植、成熟采收/返种重播、野生/枯株、盆栽和重进，以及美术满意度仍等用户验证；封窑完整操作继续由用户负责。VisualAccepted/RuntimeVerified均false。

回滚须先保存现状，恢复备份11份既有资源和gen-crops/verify，另存后撤回9份新增源资源及3份新保护工具，删除资源后clean build防残留；或恢复旧A（88B8DD9CDE9EF3F634FB0E74A378C0946DCB3E9936199B2659FCFB530D278921）至两mods。新用户16格/64预览要求继续保留，B和存档无需迁移，所有原稿/像素稿不删。

## 下一步

下一步AR4-AE：芹菜完整显示链审查与必要修复，预期复杂度5/5。先看已安装TFC原版同类素材、当前模型及保存图，再核六龄、野生/枯株/盆栽；新图从16×16网格起稿、64仅预览，保留已修食品图和采收规则。其余72项纹理来源统计不是故障数；种子、向日葵盆栽、树/灌木、加工与AR5继续保留。

全农业自然语言TXT总结和233号全局命名/结构整理仍在既定全部工作完成后。证据、正式路径清单、草稿/像素源、检查、构建和交付记录见本片inventory目录。
