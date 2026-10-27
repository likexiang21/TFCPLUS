# 77 本轮交接：枝干结果属性化 + 莲座/叶球重做 + 贴图重绘

> 上一轮看 `75-session-handoff.md`（最近一轮）与 `76-session-handoff-prior-rounds.md`（其 §2「后来被推翻的结论」必读）。
> 本轮由「美术与结构返工」驱动，用户提出的 5 条问题全部落地。

## 0. 一句话现状

**果实不再是独立方块**：它是果树枝干的一个 blockstate 属性（`fruit = none/unripe/ripe`）；
莲座改成了「长条叶片 + 绕轴外倾」的叶丛（仿 TFC `sword_fern` 手法），
原来那套「平铺叶轮 + 中心球」移交给了叶球类作物（含 **TFC 原版卷心菜** 的跨命名空间覆盖）；
树苗恢复 TFC 的嫁接表达；配套的方块与物品贴图按**写实风**重绘。

## 1. 枝干结果（取代批次 10 的独立果实方块）

| 项 | 内容 |
|---|---|
| 新类 | `common/blocks/MyFruitingBranchBlock extends FruitTreeBranchBlock`，属性 `FRUIT`（枚举 `FruitState`） |
| 物候表 | `common/MyBranchFruits.java`（6 物种 × 12 月，**含 FRUITING**；树叶那份刻意不含） |
| 注册 | `MyFruitTrees`：6 种树用新类（`branchFruitProps()` 带 `.blockEntity(MyBlockEntities.TICK_COUNTING_PLANT)`），其余 33 种照 TFC |
| 挂果位置 | `canBearFruit`：**成熟**（本类）+ **竖直**（`UP && DOWN`）+ **六邻无叶**（`#tfc:fruit_tree_leaves`）→ 即「下方主干挂果、上方树冠不挂果」 |
| 推进 | `randomTick`：当月物候 == FRUITING 且温度在气候区间内 → 按 `getTicksSinceUpdate() / berryBushGrowthTicks` 推进 NONE→UNRIPE→RIPE（与 TFC 浆果丛同构） |
| 采收 | `useItemOn`：RIPE 时产物进背包、果实回 NONE、计时器归零 |
| 资源 | `tools/gen-branch-fruits.ps1`：共享果实几何 `branch_fruit.json`（两颗 6³ 果分挂两侧）+ 6 物种 × 2 阶段贴图 + 枝干 blockstate **追加两层 multipart**（`when:{fruit:unripe/ripe}`） |
| 删除 | `MyTrunkFruits` / `TrunkFruitBlock` 两个类；66 个旧资源（blockstate / 模型 / 物品模型 / 掉落表 / 贴图）；lang 里 6 条方块名 |

⚠️ 两处与 TFC 的差异（都是 API 可见性所迫，已在代码注释里写明）：
1. **只判温度**不判湿度 —— `SeasonalPlantBlock.getFruitBushHydrationFromRootPos` 是 `protected static`，跨包不可调用；
2. **月份固定北半球**（`Calendars.SERVER.getHemispheralCalendarMonthOfYear(true)`）——
   TFC 用的是 `net.dries007.tfc.client.overworld.SolarCalculator`（client 包），服务端不宜依赖。

## 2. 莲座（3 种）—— 第二版几何

- 旧版：4 片**水平平板**（仿 `bird_nest_fern` 叶轮）+ 中心体块 → 渲染出来是「4 块板子 + 一个洞」，
  贴图还是整丛俯视蕨叶，**内容与几何完全错位**（用户原话：「极其不匹配」）。
- 新版 `tools/gen-rosette-models.ps1`：**4(+4) 片长条平面叶片**，根部交于中心，绕水平轴 ±22.5°/45° 向外上方张开
  （TFC `tfc:block/plant/sword_fern` 的手法）；age ≥ 2 加内层短叶让中心饱满。
- 贴图 16×16 切成 **4 条 4×16 竖条**，每条画一片叶，**每片叶元素 UV 取自己那一条** → 逐像素对应。
- 枯死台座改为压平 + 枯黄（旧版枯死贴图至今是绿的，已修）。

## 3. 叶球类（6 种，含 TFC 原版卷心菜）

- 生成器 `tools/gen-leafball-models.ps1`：外层 6 片（4 轴向 + 2 个 45° 对角）+ 中层 4 片抬起 22.5° 包裹 + 中心叶球（4³→7³）。
- 覆盖范围：`assets/tfc/models/block/crop/cabbage_age_*.json`（**跨命名空间覆盖 TFC**）+
  我们的 `lettuce` / `cauliflower` / `broccoli` / `kale` / `napa_cabbage`。
- 备选项调研：TFC 里只有 cabbage 属叶球类（其余是根菜/整瓜/蔓生）；Firmalife 无；afc 只有树木资源。

## 4. 树苗（嫁接表达）

- 根因：`localize-fruit-tree-models.ps1` 把 `saplings=1..4` 四个变体**统一写成 `block/cross`**，
  抹掉了 TFC 的多株表达。
- 已改为 `block/cross` / `tfc:block/plant/cross_2/3/4`（39 种 × 4 = 156 个模型），生成器同步修正。
- ℹ️ TFC 的**嫁接本身没有视觉表达**（只改逻辑：强制 saplings=3、stage=1、气候锚点改到宿主基部）；
  若要「看得见的嫁接痕」需自行加 `grafted` 属性，本轮**未做**。

## 5. 贴图重绘（写实风）

| 对象 | 生成器 | 手法 |
|---|---|---|
| 莲座叶片（3 种 × 7） | `gen-rosette-models.ps1` | 披针形轮廓 + 中脉高光 + 侧脉 + 叶缘锯齿 + 叶尖渐深 |
| 叶球外叶 + 叶球（6 种 × 7） | `gen-leafball-models.ps1` | 外叶同叶片画法；叶球用球面光照 + 同心包裹层 + 放射叶脉 |
| 枝干果实（6 种 × 2） | `gen-branch-fruits.ps1` | 球面光照 + 果点质感 + 蒂部 + 成熟果油亮高光 |
| 物品图标（14 张） | `gen-item-textures.ps1` | 果实＝球体+果柄+小叶；叶菜＝扇形外叶+中心球；莲座＝放射叶丛 |

物品图标此前是**从 TFC donor 变色来的**（木橘用橙子的图标），现在按物种形状与配色重画。

## 6. 新增工具：离线模型渲染器

`tools/preview-model.ps1` —— 读 block model JSON（递归 parent、应用 rotation）→ 等轴测正交投影 →
逐像素反算 UV 采样贴图 → PNG。**几秒出图**，改模型/贴图后能立刻自查（无光照/AO，不等于游戏内渲染）。
本轮所有几何与贴图都是靠它迭代出来的（对比图在 `.probe/skill-review/`）。

## 7. 验证结论

- `gradle clean build` 成功（删过资源，必须 clean）；jar 1 987 093 字节 → `mods\`
- `verify.ps1` **全绿**：blockstate 413 / 模型 1743 / 掉落表 412 / 物品模型 375；
  索引 模型 16114 / 贴图 6896
- 实机（进 tfctest，51.97 s）：本模组归属 **无** `Unable to load model` / `Missing textures`；
  唯一 Missing textures 是 afc 自己的 `afc:wood/leaves/mahoe`

## 7.1 追加（2026-09-23 10:03）：挂果模型第二版 + 实机确认

- 果实几何重做为 **主干中下侧四颗椭球**（贴着主干、四向各一颗），且**随状态长大**：
  
`
fruit=unripe
`
 3x4x3（高 > 宽 = 椭球）、
`
fruit=ripe
`
 4x5x4；两套共享几何
  
`
models/block/plant/branch_fruit_{unripe,ripe}.json
`
，6 种树只覆盖贴图。
- **实机通过**：截图 
`
screenshots/2026-09-23_10.03.16.png
`
 —— 枝干上可见四颗椭球果实（金黄＝canistel 成熟果），
  方块提示显示 
`
block.tfcfarmingplus.plant.bael_branch
`
，证明 fruit 属性 + multipart 叠加层在游戏内正常。
- 物品图标按 TFC 画法重绘（先提取 32 张 TFC 原版食物图标学习：主体占 80% / 深色描边 / 亮斑高光 / 果柄小叶 /
  叶菜＝外叶+内叶球 / 配色明亮）。对比图 
`
.probe/skill-review/items-vs-tfc.png
`
（第 1 行 TFC 参考、第 2 行新版、第 3 行旧版）。
- 待办（已写入 
`
INBOX.md
`
）：核查种子/食物/树皮/树叶贴图的 **donor 映射**是否与物种匹配，再决定重绘范围。

- **77 张种子图标重绘**（`tools/gen-seed-textures.ps1`）：先提取 30 张 TFC 原版种子学习画法，   再按「3~6 颗分开的小颗粒 + 每颗高光/暗面/描边 + 大量留白」重画；布局按物种名确定性随机、配色取自旧图平均色。   对比 `.probe/skill-review/seeds-grid2.png`，旧图备份 `.probe/skill-review/seeds-old/`。 - ⚠️ **发现的食物图标映射问题**（待办，已写入 INBOX）：`gen-crops.ps1` 让每个物种借同 `ref` 的 TFC 图标   （生菜 ref=onion → 用洋葱图标、西兰花 ref=cabbage → 用卷心菜图标），形状与物种不符；需按类别程序化重画。  - **124 张食物图标按类别重绘**（`tools/gen-food-textures.ps1`）：7 类画法 ——   grain(15) / legume(6) / root(12) / leafy(6) / herb(19) / fruitveg(8) / berry(58)，配色取旧图平均色；   对比 `.probe/skill-review/food-grid2.png`，旧图备份 `.probe/skill-review/food-old/`。   ⚠️ 已知不足：berry 类多数仍是「球体+换色」，形状辨识度不如 TFC（樱桃双果、香蕉弯、桃带尖），已写入 INBOX 待办。  - **果实/坚果/浆果形状差异化**（第四轮）：坚果＝水滴形 + 壳纹；带刺大果（durian/jackfruit/breadfruit/soursop/cherimoya）＝放射刺球；
  浆果（goji/bilberry/blackcurrant/bearberry 等）＝3 颗一簇；其余核果/仁果＝形状与尺寸随物种名确定性变化。
  对比 
`
.probe/skill-review/fruit-grid.png
`
（22 个代表物种一行排列）。

- **第五轮：实机视觉验证（莲座 / 叶球 / 树苗 / 挂果）** —— 在 tfctest 铺 `tfc:dirt/silt` + `tfc:farmland/silt` 后放置：   cardoon(age0/3/5+fruiting)、lettuce(5)、broccoli(5)、tfc:crop/cabbage(5)、bael_sapling(saplings=4)、bael_branch(fruit=ripe)。   全部放置成功、模型渲染正常（无紫/黑块 ⇒ 无缺失贴图）。截图 `screenshots/2026-09-23_10.14.45.png`。   ⚠️ 观感问题：**叶球基色偏淡黄绿、发白**，与周围 TFC 植被的深绿相比塑料感明显 —— 已记入 INBOX 待办（提高一档饱和度）。   ℹ️ 树苗 `saplings=4`（嫁接 4 株）本次也在实机放置成功，交叉形模型正常。  - **第六轮：叶球/莲座配色加深**（修实机发现的「发白」问题）：6 种叶菜的叶色与叶球色整体下沉一档，
  绘制提亮系数同步下调；莲座 3 种基色也加深。对比 
`
.probe/skill-review/color-grid.png
`
。
  ⚠️ 莲座叶片仍偏亮（本轮只压了叶球相关），若实机仍突兀可再压一档 —— 已记 INBOX。

- **第七轮：树皮/树叶机械化核查** —— 新增 `tools/audit-texture-uniqueness.ps1`（逐目录 MD5 唯一率，支持 -FailOnDup 挂 CI）。   结论：fruit_tree 234/234、item/food 124/124、item/seeds 77/77 全部唯一 ⇒ 每个物种的贴图都不同，**无需返工**。   仅 3 组重复：crop/{broccoli,kale,napa_cabbage}_0（源素材 TFC cabbage_0 太小，变色后差异趋零 —— 幼苗期难分可接受）；   dead_berry_bush_{0,1,2}（枯死形态不随阶段变，设计使然）。树皮总览 `.probe/skill-review/bark-grid.png`。  - **第八轮：修掉一个真 bug（幼苗贴图全透明）** —— `crop/{broccoli,kale,napa_cabbage}_0.png` 曾是 0 个不透明像素（完全透明），   而 TFC 原版 `cabbage_0.png` 有 3 个 —— 即这三种作物**刚种下时游戏里完全不可见**，要等 age 1 才看得到。   已从 TFC 原版重新生成（保留 alpha + 三物种各一套色调）。修复后 `block/crop` 目录 **709/709 唯一**，只剩枯死灌木 2 组（设计使然）。   📌 教训：像素级贴图处理（变色/滤镜）必须**检查输出的不透明像素数**，否则会把「只有 2~3 像素的幼苗贴图」清空 ——   现在这条已由 `tools/audit-texture-uniqueness.ps1` 的重复检测间接兜住（同一批里有空图就会报重复）。  - **第九轮：全量贴图内容体检 + 孤儿资源清理**：新增 `tools/audit-texture-content.ps1`（逐张统计 alpha>=8 的像素数，   报出 0 像素（空图）与 <=2 像素（可疑））。1542 张里扫出 1 张空图 —— 位于**无人引用的孤儿目录**   `assets/tfcfarmingplus/textures/crop/`（18 张，早期生成器写到旧路径的残留，模型/blockstate 里 0 引用）。   已删除该目录（备份 `.probe/skill-review/orphan-textures-crop/`）并按硬约束 4 走 clean build ⇒ jar 从 2 012 734 降到 2 006 542 字节。   复查：空图 0、fruit_tree/crop/food/seeds 唯一率 100%（仅枯死灌木 2 组为设计使然）。   📌 两个体检脚本（uniqueness / content）建议**每次改完贴图都跑一遍**，它们能抓到 verify.ps1 抓不到的「图是空的」类问题。  - **第十轮：幼苗可见性修复的实机确认** —— 在 tfctest 铺 `tfc:dirt/silt` + `tfc:farmland/silt` 后放置   `crop/{broccoli,kale,napa_cabbage}[age=0]`、`broccoli[age=1]`、`lettuce[age=5]`、`agave[age=5]`。   截图 `screenshots/2026-09-23_10.26.29.png`：准星前方的耕地上**能看到 age 0 的绿色小芽** ——   修复前这三张贴图是 0 不透明像素（完全不可见），现在与 TFC 原版一致（3 像素小芽）。  - **第十一轮：统一资源健康检查** —— 新增 `tools/healthcheck.ps1`，一条命令串起：   ① verify.ps1 交叉引用 ② 贴图唯一率 ③ 贴图内容（空图） ④ build/libs 与 mods/ 的 jar 一致性（AGENTS.md 硬约束 3 的判据）。   修掉了两个**工具自身**的误判 bug：verify 的失败判据把「未发现问题」也判成失败；空图计数 `-replace '\D',''` 把两处数字粘成 「00」。   ▶ 当前结果：全部通过（空图 0；fruit_tree 234/234、crop 709/709、food 124/124、seeds 77/77 唯一；jar 2006542 字节一致）。   **以后每轮收尾建议都跑一次 healthcheck.ps1**。  - **第十二轮：文档一致性核对（只读为主）** —— 把 AGENTS.md 与仓库实际状态逐条对照，修掉 4 处会误导接手人的过期内容：
  ① 顶部指引还写「先读 75」（最新已到 77）；② §四「莲座台座几何」仍是第一版描述（bird_nest_fern 叶轮 / 已推翻）；
  ③ verify 数字停在 模型 1743 / 索引 16114·6896（实际 1745 / 16116·6898）；④ 生成器仍写 gen-trunk-fruits.ps1。
  ➕ 把**旧生成器** 
`
gen-trunk-fruits.ps1
`
 改名为 
`
.deprecated-20260923
`
 并在文件头写明「不要跑」——
  它会重新生成已删除的独立果实方块资源（资源有、方块没注册 ⇒ 不一致）；已确认无任何脚本引用它。

### 12 轮 goal 的整体产出（2026-09-23 03:40 ~ 12:50）
- 结构：果实改为枝干 blockstate 属性（四颗椭球随状态长大）+ 实机确认；
  莲座几何第二版（长条叶片 + 竖条图集）+ 叶球类覆盖 TFC 原版卷心菜；树苗恢复 TFC 嫁接表达。
- 贴图：77 张种子 + 124 张食物图标按 TFC 画法重绘、果实/坚果/浆果形状差异化、叶球配色加深、
  修掉「幼苗贴图全透明」真 bug、清理孤儿贴图目录（jar −6 KB）。
- 工具（新增 6 个）：preview-model（离线模型渲染）、gen-{seed,food,item,leafball,branch-fruits}-textures、
  audit-texture-{uniqueness,content}、healthcheck（一条命令跑完 4 项检查）。
- 实机验证 3 次（挂果 / 莲座叶球树苗 / 幼苗可见性），全部通过。

### 贴图翻新（用户 2026-09-23 判「明显低质量且问题百出」）

- **用户定的纪律**：每完成一次绘制**必须用 read_image 放大 16~20 倍观察**，看到问题立刻改、再看 —— 不许「生成成功就当完成」。
- 已完成：果皮贴图（去掉球心突兀的深色方块、柔光高光、果点纹理、轮廓暗边）；物品牌图标（果实/叶菜/浆果/坚果共 3 轮迭代）。
- **瓜类切片**（
`
bottle_gourd_slice / cantaloupe_slice / winter_melon_slice
`
）曾被画成**完整圆瓜** ——
  分类规则把 
`
_slice
`
 归进「圆果」类。已新增 
`
Draw-Slice
`
 楔形画法（皮 + 果肉 + 籽），4 轮迭代后达标。
- ⏳ 未完成（见 INBOX 待办）：作物方块贴图 
`
crop/*_0..5
`
（462 张，最大一块）、配色普遍偏暗（取自旧图平均色）、种子颗粒偏方。

## 8. ⚠️ 未验证 / 存疑（接手时优先）

1. **存档残留报错**：删掉旧方块后，旧存档里已放置的 `plant/*_trunk_fruit` 会变成
   `Unknown registry key` + 孤立 BE（`Invalid block entity tfcfarmingplus:berry_bush // ... got Block{minecraft:air}`）。
   属 `Recoverable errors`，**新存档不会有**；若要在测试世界清干净，需手动清理该区块。
2. **枝干结果的运行时行为未实机验证**：物候推进 / 采收 / `canBearFruit` 三条件都只做了代码审查与编译验证。
   验证办法：给枝干刷 `fruit=ripe` 看模型是否叠加、右键是否给果实；用 `/tfcfarmingplus` 调试命令配合。
3. **TFC 原版卷心菜的覆盖是否真的生效**未目视确认（跨命名空间覆盖依赖资源包顺序，日志不会报）。
4. 贴图写实度靠**离线渲染 + 像素级目视**判断，未在游戏内看最终效果（光照/生物群系染色会改变观感）。
5. 物品图标只重绘了本轮涉及的 14 张；作物种子、其余食物图标仍是旧的变色贴图。

## 9. 下一步建议

1. 进游戏看一眼：莲座 3 种（幼苗/成熟/结果/枯死）、叶球 6 种、枝干果实（成熟/未熟）、14 个物品图标。
2. 验证枝干结果的完整闭环：物候 → 结果 → 右键采收 → 冷却。
3. 若观感满意，把同样手法推广到其余作物/果树贴图（种子、其余食物、树皮、树叶）。
