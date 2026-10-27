# 80 实机验证打通 + 莲座几何根因（2026-09-23 晚，继承 docs/79 的第一批工作）

> 本文件只写**实测过 / 源码里读到**的东西；推断一律显式标注「推断」。
> 上一轮（docs/79）的三次「验证通过」全是假的，本文件的方法部分就是为了不再重犯。

## 0. 接手 30 秒版

1. **docs/79 §6.1 的悬案结案** —— `FarmlandBlock.canSurvive` 只看**上方**，与下方无关（§1）。
   上一轮「耕地变泥土」**不是 ID 错**（`tfc:farmland/alfisol` 真实存在），也不是下方缺土。
2. **本项目第一次真正有效的实机验证已跑通**（§2）：耕地 + 4 株作物，全部用
   **已核实的 ID + 绝对坐标 + 延时后 probe 断言**，日志与画面双向可核对。
3. **实测暴露的新问题**：莲座（cardoon / agave）在游戏里是**深色扁平碎片**，不是植物形态。
   这是**几何**问题，不是贴图问题（§4；贴图平均亮度 43~64，比 TFC block 作物基准还亮）。
4. 工具修复：`ingame-verify.ps1` 改为**按 PID 锁定本实例窗口**（用户同时开着别的 MC 实例，
   按窗口标题取第一个有误注入到用户游戏里的风险）。

## 1. §6.1 结案：耕地为什么退回泥土

源码：`moddev/src-ref/TFC-decompiled/net/dries007/tfc/common/blocks/soil/FarmlandBlock.java`

```java
// 243-246 行
protected boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
    BlockState stateAbove = level.getBlockState(pos.above());
    return !stateAbove.isSolid() || stateAbove.getBlock() instanceof FenceGateBlock
        || stateAbove.getBlock() instanceof MovingPistonBlock;
}
// 256-259 行：tick() 里 canSurvive 不成立 → turnToDirt（退回 getDirt()，即 tfc:dirt/<土纲>）
```

作物侧（`.../blocks/crop/CropBlock.java:136-137`）：

```java
public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
    return Helpers.isBlock(level.getBlockState(pos.below()), TFCTags.Blocks.FARMLANDS);
}
```

| 方块 | 存活判据 | 与本轮实测 |
|---|---|---|
| TFC 耕地 | **上方**必须非实心（`!stateAbove.isSolid()`），**不看下方** | 在空气格铺耕地 → 延时 15 秒后 probe 仍是 `tfc:farmland/alfisol` ✅ |
| TFC / 本模组作物 | **下方**在 `#tfc:farmlands` 标签里 | 耕地上方 `y+1` 放作物 → 存活 ✅ |

⇒ 上一轮之所以看到「普通泥土」，最可能是**放置坐标压在地表里 / 上方有实心方块**，
使 `updateShape(UP)` 排了 1 tick 的 `scheduleTick` → `tick()` → `turnToDirt`。
**排查这类问题的正确姿势**：先 `/tfcfarmingplus probe <pos>` 看那一格到底是什么方块，
不要靠猜 ID。

## 2. 有效实机验证的配方（可复用，本轮实测跑通两次）

### 2.1 三条硬规则

1. **坐标一律用绝对坐标。** 玩家位置会漂移（实测两次注入之间位移了 3 格，
   疑与同时安装的 `autowalk` 有关）—— 相对坐标 `~ ~-1 ~2` 在第二批注入时已指向**别的位置**，
   上一轮就是这样「验了个寂寞」。
2. **判据必须落进日志。** `/tfcfarmingplus probe <pos>` 的 `say()` 同时写模组 LOGGER
   （前缀 `[TFCDBG]`），所以回执被聊天栏挤掉也不影响核对 —— 直接
   `Select-String 'co\.ex\.tf.TFCFarmingPlus.*TFCDBG'`。
   vanilla 的 `/setblock`、`/fill` 成功回执**只进聊天栏、不进日志**，所以要靠 probe 兜底。
3. **整段链路放同一个后台 job。** 后台 pwsh job 结束时其子进程会被连带终止：
   本轮第一次尝试把 `launch-client.ps1` 单独放一个 job，脚本一结束游戏就被杀
   （日志特征：`Saving and pausing game...` → `APlayerInMC退出了游戏` → `Stopping server`）。
   正确做法：**启动 + 等待 open world + 注入 + 截图 + `stop-own-client.ps1` 全在同一 job 内**。

### 2.2 本轮实际用到的命令序列

```text
/fill    -997 74 13512 -984 74 13512 tfc:farmland/alfisol
/setblock -995 75 13512 tfcfarmingplus:crop/lettuce[age=5]
/setblock -992 75 13512 tfcfarmingplus:crop/cardoon[age=5,fruiting=true]
/setblock -989 75 13512 tfcfarmingplus:crop/quinoa[age=7,part=bottom]
/setblock -989 76 13512 tfcfarmingplus:crop/quinoa[age=7,part=top]
/setblock -986 75 13512 tfcfarmingplus:crop/agave[age=5,fruiting=true]
/tp @s -991 75 13508 0 20
/tfcfarmingplus probe <每个位置>      ← 延时 ~15 秒后再 probe 一次，才是「存活」判据
```

ID 与属性全部来自 `MyCrops.java` 的注册调用，并经 `assets/tfcfarmingplus/blockstates/crop/*.json`
的变体键复核（例：`cardoon` 有 `age 0..5 × fruiting false/true`；`quinoa` 双格有 `part=bottom|top`）。

### 2.3 本轮实测记录（可复核）

```
[21:24:44] [TFCDBG] probe -992 74 13512 block=Block{tfc:farmland/alfisol}          ← /fill 的耕地，延时后仍在
[21:24:46] [TFCDBG] probe -995 75 13512 block=Block{tfcfarmingplus:crop/lettuce}[age=5]
[21:24:48] [TFCDBG] probe -989 76 13512 block=Block{tfcfarmingplus:crop/quinoa}[age=7,part=top]
[21:24:51] [TFCDBG] probe -986 75 13512 block=Block{tfcfarmingplus:crop/agave}[age=5,fruiting=true]
[21:23:30] [渲染层自检] 已注册方块 413 个，全部有归属（cutout 270 / cutoutMipped 59 / 无需登记 84）
本模组归属的 Unable to load model / Missing textures：0 条
```

截图（`screenshots/`）与放大件（`.probe/ingame-verify-20260923/`）：

| 截图 | 内容 | 结论 |
|---|---|---|
| `2026-09-23_21.20.30.png` | 双格 quinoa + 准星指向耕地（tooltip「淋溶土耕地」+ 温湿度/氮磷钾） | 耕地与作物都真实存在 ✅ |
| `2026-09-23_21.24.55.png` | 一排 4 株（lettuce / cardoon / quinoa / agave）+ 耕地 | 见 §3 |
| `C1-quinoa.png` | 放大 2× 的双格 quinoa | 茎 + 叶 + 穗三段结构成立，形态可辨认 |
| `C2-rosette.png` | 放大 2.5× 的莲座 | **深色扁平碎片，完全不像植物** ❌ |

## 3. 实测画面看到的东西（不粉饰）

- **双格作物（quinoa）**：下层宽叶丛 + 上层多根竖直茎 + 顶部棕褐穗，**能看出是植物**；
  但整体比 TFC 稀疏，且在树荫/低光处偏暗。
- **莲座（cardoon / agave）**：一坨**深色扁平碎片**，像「炸开的黑纸片」，
  中心只有一个小方块（`rosette_age_5_fruiting` 的果实体块）。
  同一画面里它的亮度明显低于旁边的草地与 quinoa。
- **耕地/作物放置链路**：完全正常，不再是问题。

## 4. 几何根因：我方莲座 vs TFC 原版

我方 `models/block/crop/rosette_age_5.json`（8 个 element，全部如此）：

```json
{"from":[6,0,8], "to":[10,0,20], "rotation":{"axis":"x","angle":-22.5,"origin":[8,0,8]}}
```

- **`y` 从 0 到 0：水平零厚度面片**；`faces` 只有 `up` / `down`
- 8 片长度 7~12，**末端伸出方块边界**（z=20 / x=20，方块边界是 16）
- 结果：从正常平视/略俯视角看，每片叶的投影趋于一条线 —— 这就是「碎黑片」

TFC 原版（实测自 `TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`）：

| 模型 | 叶片结构 | faces | `shade` |
|---|---|---|---|
| `tfc:block/plant/sword_fern`（剑叶蕨） | **竖直面片**：`from=[-8,0,6] to=[24,8,6]`（z 固定、y 高 8），再绕 x 轴 ±22.5°/±45° | `north` / `south` | **每片都 `"shade":false`** |
| `tfc:block/plant/lady_fern` | 水平面片（`y` 固定 0），绕轴 ±45° | `up` / `down`，**带 uv `rotation` 180/90/270** | 全部 `false` |
| `tfc:block/plant/bird_nest_fern` | 水平面片（`y` 固定 0），绕轴 ±22.5° | `up` / `down`，**带 uv `rotation`** | 全部 `false` |

⇒ 两个结论：

1. **「水平面片」本身不是原罪** —— TFC 的 `lady_fern` / `bird_nest_fern` 就是低矮叶轮，
   但它们的贴图是**整张 16×16 的叶片图案**（不切竖条），且 `up`/`down` 两面带 uv 旋转、配 `shade:false`。
2. **剑叶型（刺菜蓟 / 龙舌兰）在 TFC 里用的是竖直面片**，而我方莲座沿用了水平薄板，
   形态上从根上对不上。AGENTS.md 里「莲座第二版仿 `sword_fern`」的说法**与模型文件不符**。

我方叶球同构（`leafball_age_5.json`，11 个 element）：叶片同为 `y:0→0` 水平板
（只有 [9][10] 两片绕 y 轴 ±45° 旋转），外加 [11] 一个 `from=[4,0,4] to=[12,7,12]` 的中心体块（`#1`）。
`lettuce_age_5.json` 的 `parent` 就是它 —— **叶菜成熟态也共用这套几何**。

贴图侧对照（本轮实测统计，`textures/block/crop/`）：

| 贴图 | 不透明像素 | 色数 | 平均亮度 |
|---|---|---|---|
| `rosette_5.png` | 96 | 85 | 48.2 |
| `cardoon_rosette_5.png` | 77 | 68 | 42.9 |
| `agave_rosette_5.png` | 94 | 86 | 54.0 |
| `leafball_5.png` | 93 | 89 | 62.5 |

（TFC block 作物亮度中位约 23 ⇒ **我方贴图并不比 TFC 暗**，画面发暗主要来自几何/面朝向。）

## 5. 待用户决策（不由 agent 拍板）

1. **莲座几何要不要重做？** 选项：
   - A. 改成 TFC `sword_fern` 式**竖直面片**（形态能对上剑叶植物；外观与现在完全不同）
   - B. 保留水平叶板，但补 uv `rotation` + `shade:false`、缩短到方块内（改动小，观感仍是"叶轮"）
   - C. 不动几何，只重画贴图（**已证明收益有限**：几何决定投影，贴图再好也看不出）
2. **叶球/叶菜是否同步改？**（`lettuce` 等 6 个模型共用 `leafball_age_5`）
3. **验收标准**：什么算合格？（是否需要与 TFC 同框对比？是否允许程序化？）

## 6. 本轮改动清单

| 文件 | 改动 |
|---|---|
| `moddev/tools/ingame-verify.ps1` | 注入目标改为**按 `%TEMP%\tfcflora-client.pid` 锁定**本实例窗口；pid 未命中才退回标题匹配并打印告警。已补 UTF-8 BOM + `[Parser]::ParseFile` 通过 |
| `moddev/docs/80-ingame-verify-and-rosette-geometry.md` | 本文件 |
| `.probe/ingame-verify-20260923/*.png` | 本轮 5 张放大裁图（A/B/C1/C2/C3） |

**未改动**：任何 `src/` 下代码与资源（等 §5 决策）。`options.txt` 的
`pauseOnLostFocus` 每次收尾都已还原为 `true`（三次 `stop-own-client.ps1` 均打印「已还原」）。

---

## 7. 追加：几何方案对比 + 贴图「认不出来」的量化根因

### 7.1 四个几何方案（离线渲染，一次看完见 `COMPARE-rosette-5way.png`）

用 `preview-model.ps1`（已验证：它的输出与实机画面一致）在**完全隔离的实验室目录**
`.probe/lab-assets/` + `.probe/preview-lab.ps1` 里渲染，`src/` 一个字节没动。

| 方案 | 结构 | 预览表现 | 备注 |
|---|---|---|---|
| 0 当前 | 8 片 `y:0→0` 水平板 ±22.5°/45° | 扁片从中心炸开 | 实机 = 黑色碎片 |
| A vertical | 8 片**竖直**面片（仿 TFC `sword_fern`） | 两簇竖直叶、中间空、偏稀疏 | 与现有「4 条竖条」贴图匹配最好 |
| B flat-fixed | 水平板 + `shade:false` + uv rotation + 收回方块边界 | 极扁平、贴地 | 观感仍是「叶轮」 |
| C thick | 8 片带 1 格厚度的板 | 有体积，但仍「趴着」 | 侧边也要贴图内容 |
| D cross+full-tex | 十字平面 + 整张 16×16 贴图 | **一块绿色条纹板** | **必须配「整株剪影」新贴图** |

**判断（这是 §5 决策的关键前提）**：几何方案的成败取决于**它与贴图的约定**。
现贴图是「4 条 4×16 竖条」（专为叶片式几何设计），所以 A/B/C 能用它、但**只能表现「几片叶子」**；
D 之所以变成条纹板，是因为贴图不是整株图。⇒ **要「一眼认出是什么植物」，必须几何与贴图成对重做。**

### 7.2 贴图「不能让人识别」的量化根因

`tools/ascii-texture.ps1` dump `cardoon_rosette_5.png`：

```text
16x16  opaque=77  colors=68
.........D......     色值集中在 #0B0D08 / #0C0E08 / #1D2114 / #2D3520
.........S......     —— 全部 V < 35%
.....e..........
```

对照 TFC 基准（docs/78 §2）：`wheat_5` = 104 像素 / **9 色**，结构是「4~5 根 1px 麦秆 + 顶部麦穗」。

⇒ 三条可量化的缺陷：

1. **色数爆炸**（68 vs 9）：参数化生成器逐像素加微小抖动 ⇒ 视觉上就是「糊成一团的噪点」；
2. **明度太低**（V < 35%）：进游戏还要再乘方块光照系数 ⇒ 更黑；
3. **没有器官结构**：77 个像素里看不出叶片 / 茎 / 果的轮廓。

⇒ 对策与 docs/78 §7.2 一致：**结构型贴图逐像素手写，且先定 4~6 档色阶再落像素**，
把色数压回 TFC 区间（≤ 12）。这条可以当作后续验收的**可量化门槛**。

### 7.3 本轮工具改动（补充）

| 文件 | 改动 |
|---|---|
| `.probe/lab-assets/**` + `.probe/preview-lab.ps1` | 新建的**几何实验室**：改自 `preview-model.ps1`，资产根指向 `.probe/lab-assets`，可在不碰 `src/` 的前提下试几何 |
| `moddev/tools/launch-client.ps1` | 第 114 行**临时**打开 `-Dtfcfarmingplus.fastgrow=true`（茎生果验证用）—— **验证完必须还原成注释** |

---

## 8. 【真 bug】整棵树的茎生果机制此前完全失效（本轮实机验证发现）

用户指出「整棵的茎生果没有验证过」—— 一验证就发现它**根本没工作**。

### 8.1 实测数据（同一局游戏内）

```text
[TFCDBG] calendar ticks=675829 month=AUGUST ordinal=7        ← 当月 FRUITING 树种 = canistel / bael / jabuticaba
[TFCDBG] tree canistel at -991 75 13509 temperature=20.44 hydration=20 checkBoth=true -> 可以生长
[TFCDBG] plant canistel ground=73 -> sapling at -991 74 13512 = plant/canistel_sapling[saplings=1]
[TFCDBG] probe -991 74 13512 lastUpdateTick=698667 sinceUpdate=37   ← 树苗计时器已播种（不是哨兵值）
[TFCDBG] setcounter ... ticks=200000 -> sinceUpdate=200000
[TFCDBG] randomtick -991 74 13512 x3 -> block=plant/canistel_branch[down=true,fruit=none,stage=0,up=false]
[TFCDBG] probe -991 74 13512 block=plant/canistel_branch[...]  BE=<none>   ← ★ 关键异常
[TFCDBG] probe -991 75/76/77/78/79 13512 block=minecraft:air               ← 45 秒 + 40 秒后树没有长高
```

### 8.2 根因（源码级对照）

| 类 | 声明 | 有 BE？ |
|---|---|---|
| `GrowingFruitTreeBranchBlock`（TFC 生长枝） | `extends FruitTreeBranchBlock implements EntityBlockExtension` | ✅ |
| `FruitTreeBranchBlock`（TFC 成熟枝干 = 我方父类） | `extends PipePlantBlock implements HoeOverlayBlock` | ❌ **不是 `EntityBlock`** |
| `MyFruitingBranchBlock`（修复前） | `extends FruitTreeBranchBlock` | ❌ |

`EntityBlockExtension extends EntityBlock, IForgeBlockExtension`，默认 `newBlockEntity` 取
`getExtendedProperties().newBlockEntity(...)`；而 `PipePlantBlock`（第 50 行）已经
`implements IForgeBlockExtension` 并提供 `getExtendedProperties()`。
⇒ 只差 `implements EntityBlockExtension` 这一句。

**后果**（`MyFruitingBranchBlock.randomTick` 第 125-127 行）：

```java
if (!(level.getBlockEntity(pos) instanceof TickingPlantBlockEntity be)) {
    return;      // ← BE 恒为 null ⇒ 永远走这一行
}
```

⇒ `FRUIT` 永远停在 `none`；`useItemOn` 的采收分支（要求 `RIPE`）永远进不去。
**「主干结果 → 转熟 → 右键采收」整条链此前是死的，而且日志里一句报错都没有**
（BE 不是「创建失败」而是压根没尝试创建，所以连 `Invalid block entity` 都不会出现）。

### 8.3 修复

`MyFruitingBranchBlock` 加 `implements EntityBlockExtension`（+ import），并在类注释里写明原因。
BE 类型仍用 `MyBlockEntities.TICK_COUNTING_PLANT`；该类型的 `validBlocks` 已包含会结果的枝干
（`MyFruitTrees.tickingBlocks()` 第 374-378 行），所以不会触发 `validateBlockState` 失败。

### 8.4 仍未解决：树长不高（`up=false`）

这次催熟只把树苗变成了**一格高的成熟枝干**（`down=true, up=false`），上方 5 格全是空气。
`canBearFruit` 要求 `UP && DOWN` 同时为真 ⇒ 即便 BE 修好，这一格也不会结果。
**待查**：是催熟手法（`setcounter 200000` + `randomtick x3` 一次跳太远）造成的，
还是 `MyGrowingFruitTreeBranchBlock` 的生长本身有问题 —— 需换成「少量多次推进」再验一次。


---

## 9. 用户反馈的两个工具缺陷（2026-09-23 晚，均已修复）

这两条都是**我的自动化脚本在用户世界里留下的副作用**，不是游戏/模组的问题。

### 9.1 注入脚本用「鼠标点击」激活窗口 → 游戏内左键误操作

`moddev/tools/ingame-verify.ps1` 的 `Win32Focus.Activate()` 旧实现是
`SetCursorPos((Left+Right)/2, Top + 8)` 之后 `mouse_event(LEFTDOWN/LEFTUP)` —— 本意是点标题栏。

但 `launch-client.ps1` 会把窗口**最大化**（实测窗口矩形 `(-7,-7)-(2055,1239)`），
标题栏被推到屏幕外，`Top + 8` 实际落在**屏幕 y≈1 = 游戏画面内**。
MC 一拿到焦点就锁定鼠标，于是这一点变成**左键 = 挖掘/攻击**（挖掉刚放下的方块、打掉作物）。

**修复**：`Activate()` 全程不再产生任何鼠标事件 ——
`AttachThreadInput + BringWindowToTop + SetForegroundWindow`，仍抢不到焦点时按一下 **Alt**
（系统键，Windows 当作激活手势，MC 内无绑定）。

### 9.2 强杀 java → 下次进入世界时玩家位置不可控

`moddev/tools/stop-own-client.ps1` 旧实现直接 `Stop-Process -Force`。
强杀时游戏来不及走退出流程保存玩家数据，下次进入落在**上一次自动保存**的位置，
于是每次进入的基准位置都不同 —— 这也是前几轮「相对坐标 `~ ~-1 ~2` 指向别处」的来源之一。

**修复**：改为 `CloseMainWindow()`（等价于点关闭按钮 → MC 先保存世界与玩家数据再退出），
最多等 120 秒；只有超时才回退 `Stop-Process -Force`，且会打印告警。
另外下次验证起，注入的最后一批命令里加 `/save-all flush` 作为双保险。

### 9.3 第三个缺陷：聊天注入会偶发丢字/截断（截图取证）

`screenshots/2026-09-23_21.46.34.png` 的聊天栏原文：

```text
无法放置方块
未知或不完整的命令。错误见下
/setblock -991 75 13512
tfcfarmingplus:plant/canistel_branch<--[此处]
已更改位于 -991 76 13512 的方块          ← 紧挨着的下一条（同一个 ID）却成功了
[TFCDBG] probe -991 75 13512 block=Block{minecraft:air}
```

⇒ 同一批里三条几乎相同的 `/setblock`，**中间那条被截断**（Brigadier 在命令末尾报"无法解析"），
所以「枝干放不上去」**不是 `canSurvive` 拒绝，而是注入没送进去**。

**缓解措施**（已写进本轮验证流程）：
1. **每条关键命令单独注入一次**，注入后立刻 `probe` 核对，不符就重发（最多 3 次）；
2. `probe` 结果从**模组 LOGGER** 读（不受聊天栏滚动影响）；
3. 长远可改用**数据包函数**（`saves/tfctest/datapacks/tfcdbg` 已经存在）——只需注入一次
   `/function ...`，把几十条命令的注入失败面压到一次。

### 9.4 对既有结论的影响（诚实标注）

- 前几轮反复出现的「玩家位置漂移」「相对坐标失效」，**主要是 9.2 造成的**；
- 9.1 的鼠标点击会挖掉方块，因此**凡是在两次 `ingame-verify` 调用之间保持的方块状态都不可信**；
- §8.1 里「3 条 `/setblock` 之后 probe 仍是 air」，现在可以定性为**9.3 的注入截断**，
  与 `PipePlantBlock.canSurvive` 无关（它的判据已查清：`testDown` 认 `#tfc:fruit_tree_branches`
  或 `#tfc:bush_plantable_on`，而后者 = `#minecraft:dirt` ∪ `#tfc:farmlands` ∪ `#tfc:clays`，
  而 `#minecraft:dirt` 又被 TFC 覆盖为 `#tfc:grass ∪ #tfc:dirt ∪ #tfc:coarse_dirt ∪ #tfc:mud` ——
  所以 TFC 的草方块 / 泥土 / 耕地都撑得住枝干）；
- 另外核实：模组**已经**把 39 种树的 branch / growing_branch / sapling 补进了
  `data/tfc/tags/block/fruit_tree_{branches,saplings}.json`（`replace:false`），
  所以 TFC 的 `testUp` / `testHorizontal` 对我方枝干成立 ——
  **一次排查中曾误判这里缺标签，查了定义才发现是我方已正确补齐**。

### 8.5 修复已验证（21:56，日志可复核）

```text
probe -991 75 13512 block=canistel_branch[down=true,fruit=none,stage=0,up=true]
                    BE=net.minecraft.world.level.block.entity.BlockEntityType@1d435411   ← 修复前是 <none>
                    lastUpdateTick=677833 sinceUpdate=323
                    stemPos=BlockPos{x=-991, y=75, z=13512}
setcounter 200000 + randomtick x1 -> canistel_branch[fruit=unripe, ...]
setcounter 200000 + randomtick x1 -> canistel_branch[fruit=ripe,  ...]
```

⇒「BE 创建 → 计时器播种 → 物候/气候判定 → NONE → UNRIPE → RIPE」整条链**首次**走通。
果实外观另用离线渲染确认：`canistel_branch_fruit_ripe` = **四颗金黄色椭球**
（`.probe/ingame-verify-20260923/E1-fruit-ripe.png`）。

### 8.6 仍未完成：真实种植路径下的「整棵树」

本轮验到的是**单格枝干**上的果实推进（用 `/setblock` 摆出 `up/down` 都成立的中间段）。
用户要的「整棵的茎生果」还差最后一段：**树苗 → 长成多格主干 → 主干自然结果**。
已知卡点：上次催熟（`setcounter 200000` + `randomtick x3`）只得到**一格**枝干（`up=false`），
上方 5 格仍是空气。下一步应改用**少量多次推进**（每次 `randomtick 1` 后 probe 观察），
看它是真的长不高，还是被一次性跳步的加速手法卡住。