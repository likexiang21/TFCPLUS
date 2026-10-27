# 75 新对话交接（本轮会话的完整记忆快照）

> **给接手的新对话**：先读 `AGENTS.md`（自动加载，行为约束 + 硬约束 18 条），再读本文。
> 本文只覆盖**最近一轮**（2026-09-22 上午）的改动、验证结论与遗留项。
> 更早的历史看 `74-handoff-and-inventory.md`；逐轮施工细节看 `71-flora-implementation-log.md` §5.57。

---

## 0. 一句话现状

树干果实**已从「自创 AGE 方块」重写为 TFC 原生 `SeasonalPlantBlock` 子类**（物候/气候/采收冷却全部走 TFC）；
莲座台座与贴图的三处确凿错误已修；实机验证通过；顺手抓出并修掉一个**生长计时器从未播种**的真 bug。
**当前 `mods\` 里的 jar 是最终形态**（1 944 905 字节，07:50），`fastgrow` 已按要求还原为关闭，游戏已停。

---

## 1. 环境与最常用命令

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
# 工作目录 = $v ；DSH checkout 在 D:\dsh-runtime\ （与本项目无关）

# 构建（在 $v\moddev\tfcfarmingplus 下）
gradle build --console=plain          # 删过 src/main/resources 里的文件时必须 gradle clean build
# ⚠️ 构建产物在 moddev\tfcfarmingplus\build\libs\，要手动复制到 $v\mods\

# 资源交叉引用校验（秒级）
& "$v\moddev\tfcfarmingplus\tools\verify.ps1"

# 实机（脚本默认直接进存档 tfctest；会自动改 options.txt）
& "$v\moddev\tools\launch-client.ps1"
& "$v\moddev\tools\stop-own-client.ps1"      # 收尾必跑，否则 pauseOnLostFocus 停在 false
# 日志：$env:TEMP\tfcflora-launch-out.log   ⚠️ 该文件是 GBK 编码，搜中文会乱码，用 ASCII 关键字搜
```

生成器重跑链（顺序有依赖，改动资源后按需跑）：

```
gen-batch2 → gen-crops → gen-fruit-trees → gen-tags → gen-wild-injection → 手册
→ localize-textures → localize-fruit-tree-models → localize-all-models
→ gen-trunk-fruits → gen-rosette-models → verify → verify-book
```

---

## 2. 本轮改了什么（12 个文件）

### 2.1 树干果实：重写为 TFC 原生机制

| 文件 | 改动 |
|---|---|
| `common/blocks/TrunkFruitBlock.java` | **整体重写**：`extends SeasonalPlantBlock`（原来 extends `HorizontalDirectionalBlock`）。只覆写附着族（`canSurvive`/`updateShape`/`getStateForPlacement`/`getShape`）+ `setPlacedBy` + `randomTick`；新增 `FACING` 四向 |
| `common/MyTrunkFruits.java` | 新增 12 月 `LIFECYCLES` 表（6 物种，**含 FRUITING**）、复用 `MyFruitTrees.CLIMATES`、`trunkFruitProps()` 加 `.blockEntity(BERRY_BUSH)`、新增 `trunkBlocks()` |
| `common/MyBlockEntities.java` | `BERRY_BUSH` 的 `validBlocks` 增加 `MyTrunkFruits.trunkBlocks()`（写在 **lambda 内**以破解循环引用）；`concat` 改为可变参数 |
| `tools/gen-trunk-fruits.ps1` | blockstate `12 → 48` 变体（4 向 × 3 阶段 × 4 物候）；6 个阶段模型（`{unripe,ripe}_stage0..2`）；每物种 2 张贴图；掉落表条件改 `stage=2 AND lifecycle=fruiting`；新增旧资源清理段 |

**为什么必须继承 `SeasonalPlantBlock`**（反汇编依据，`javap` TFC 4.2.10）：

- 构造器 `(ExtendedProperties, Supplier<ClimateRange>, Supplier<? extends Item>, Lifecycle[])`，`Lifecycle[]` **必须长度 12**（构造器断言）；
- 属性 = `STAGE`(=`STAGE_2`, 0~2) + `LIFECYCLE`(4 值)，**没有 `AGE`**；
- `onUpdate` 第一句是 `level.getBlockEntity(pos) instanceof BerryBushBlockEntity`，不满足**整段跳过**；
- 气候判据位置 = `be.getStemPos().below()` 的湿度 + `be.getStemPos()` 的温度，第三参是 **boolean**；
- `useItemOn` **仅当 `LIFECYCLE == FRUITING`** 才采收，产物走 `ItemHandlerHelper.giveItemToPlayer`（**进背包，不是掉落物**），随后 `stateAfterPicking` → `HEALTHY`；
- `getShape` 在 `STAGE == 2` 时返回 `Shapes.block()`（整块）→ **必须覆写**；
- `codec()` 已实现（`fakeBlockCodec()`），子类不用写；
- 父类**不推进 `STAGE`**，那是子类的活 → 本类在 `randomTick` 里照抄 `StationaryBerryBushBlock.tick` 的算法（`getTicksSinceUpdate()/berryBushGrowthTicks`，上限 8），去掉「向地面蔓延」；
- `randomTick` 走的是 **4 参数** `Block.randomTick(BlockState, ServerLevel, BlockPos, RandomSource)`（与 `FruitTreeLeavesBlock` 同构），不是那个 5 参数的 TFC 内部重载。

### 2.2 抓到的真 bug：生长计时器从未被播种

`SeasonalPlantBlock.setPlacedBy` 里播种计时器那句是 `BerryBushBlockEntity.reset(level,pos)` —— **按 TFC 自己的 `BlockEntityType` 查表**的静态 helper，在本模组自建 BE 上静默失效。
`TickCounterBlockEntity` 构造器只把 `lastUpdateTick` 置为哨兵值 `-2147483648L`，唯一播种方式是实例方法 `resetCounter()`。

后果：`getTicksSinceUpdate()` ≈ 2.1e9 → 生长次数被上限截到 **8** → **放下方块的第一次随机刻就直接长满 `STAGE`**，缓苗期消失。
影响树干果实 + 浆果灌木；果树树叶不受影响（它只走物候，不推进 `STAGE`）。

| 文件 | 改动 |
|---|---|
| `common/blocks/MySeasonalPlantFix.java` | 新增 `afterPlace(Level, BlockPos)`（`instanceof TickCounterBlockEntity` → `resetCounter()`）；**更正**了早期「setPlacedBy 那次失效无影响」的错误论证 |
| `TrunkFruitBlock` / `MyBerryBushBlock` / `MyFruitTreeLeavesBlock` | 三者的 `setPlacedBy` 在 `super` 之后调用 `MySeasonalPlantFix.afterPlace(...)` |

### 2.3 模型与贴图的三处确凿错误

| 问题 | 根因 | 修复 |
|---|---|---|
| 莲座 `fruiting=true` 的 **age 0~4 共 15 个模型**是原版小麦十字 | `gen-crops.ps1` 先写 `parent: block/crop` 占位，`gen-rosette-models.ps1` 只覆盖了 `age_5_fruiting` | 生成器改为**全量覆盖 12 个组合**（age 5 用结果态几何，age 0~4 退化为同阶段未结果台座） |
| `dead_rosette{,_young}` 也是小麦十字 | 同源，无人覆盖 | 新增枯死叶轮几何 `rosette_dead{,_young}`，两个共享方块模型改指向它 |
| 结果态中心果实是「一块绿方块」 | 果实体块与叶片共用贴图槽 `#0` | 体块改用**独立槽 `#1`** + `GenFruitTexture` 画的球体（`<n>_rosette_fruit.png`） |
| 树干果实贴图像六张圆贴纸 | `GenFruitTexture` 把球外留成**透明** | 改为整张不透明，立体感靠光照；球外压暗、保底 0.20 |
| 贴图左上角一块纯白 | 球外像素照算法线 → `nx` 可达 2.2 → `lambert` 溢出 → `pow(lambert,18)` 爆掉 | **只在球内取法线与高光**（先试过单纯 clamp `lambert`，白斑仍在） |

**新增/重写的工具**：`tools/gen-rosette-models.ps1`（全量覆盖 + 枯死台座 + 中心果实贴图）、`tools/GenFruitTexture.java`（整张不透明 + 球面光照）。

---

## 3. 实机验证结论（最终 jar，不带 fastgrow）

```
open world 48.8s
[渲染层自检] 已注册方块 419 个，全部有归属（cutout 276 / cutoutMipped 59 / 无渲染层 84）
TagLoader 错误 0        本模组归属的模型/贴图/注册问题 0        ERROR 总计 5（全为无关项）
verify.ps1 全绿：blockstate 419 / 模型 1760 / 掉落表 418 / 物品模型 381
模型审计：1760 个模型，非法 rotation.angle 0 处、越界坐标 0 处
贴图审计：1468 张，全部 PNG、全部 16×16
```

树干果实机制逐项验证（用 `/tfcfarmingplus` 调试命令）：

| 检查项 | 结果 |
|---|---|
| 方块能放置并保留（`canSurvive` 判背面枝干） | ✅ `[facing=east,lifecycle=healthy,stage=2]` |
| 三个属性齐全 + BE 已绑定 | ✅ |
| **物候推进** `setblock …[lifecycle=dormant]` → `randomtick 1` | ✅ 变成 `healthy` |
| **STAGE 推进** `setcounter 50000` → `randomtick 1` | ✅ `stage 0 → 2` |
| 气候数据加载 | ✅ `checkBoth=true`（temp 13.44 / hydration 20） |

> ⚠️ `calendar`/`tree` 命令用 `getHemispheralCalendarMonthOfYear(true)` **硬编码北半球**，而方块走 `SolarCalculator` 的实际半球判定 —— 两者不一致会让人误判「物候没推进」。玩家在 z 正方向（南半球）时 `calendar` 报 AUGUST 而方块目标是 FEBRUARY。

**本轮新增的可复用能力：按键注入跑实机验证。**
游戏窗口最大化后，用 `SetForegroundWindow` + `SendKeys`（`/` 开聊天 → `Ctrl+V` 贴命令 → `Enter`）即可无人值守执行命令；
调试命令的 `say()` **同时写日志**（`TFCFarmingPlus.LOGGER.info`），所以结果能从 `tfcflora-launch-out.log` 读回。
要点：① `SendKeys` 里 `~` `(` `)` 是特殊字符，**必须用剪贴板粘贴**；② 发送前用 `GetForegroundWindow()` 校验前台是游戏窗口，否则放弃；③ 每次 `Add-Type` 用不同的类名。
⚠️ TFC 的**土壤塌落**会把测试场地埋掉（实测三次「放下去就变泥土」），把试验台搭到 **y≈116 的空中石台上**才稳定。

---

## 4. ⚠️ 未验证 / 存疑项（接手时优先处理）

1. **`setPlacedBy` 的两条路径没在实机走过**：`/setblock` **不触发** `setPlacedBy`，所以
   ① `afterPlace()` 的计时器播种、② `stemPos` 从宿主枝干继承 —— 都只做了代码审查与同构比对（`afterUse` 是同类写法），**没有用玩家真实放置验证过**。
   验证办法：给玩家物品后模拟选中快捷栏 + 对着枝干右键，或临时加一个直接调用 `setPlacedBy` 的调试命令。
2. **树干果实的 12 月物候表是我拟的**（`MyTrunkFruits.LIFECYCLES`，6 物种各自一张，热带、DORMANT 少、结果期长）。
   这是产品决策，**未经你确认**；觉得不合理直接改那张表即可（一个物种一行）。
3. **台座/果实的实机观感没看过**。我只能 `read_image` 看贴图文件，看不到游戏画面。
   贴图文件层面三处错误已修，但「几何形态是否与应用效果匹配」「树干截面 8×8 是否合适」仍未评估。
4. **孤儿资源未清理**：`textures/block/dead_crop/dead_rosette{,_young}.png` 在改指向后已无人引用
   （`gen-crops.ps1` 可能仍在生成）。留着无害，但若要清爽需同步改生成器再 `clean build`。
5. `AGENTS.md` 进度锚点第 113 行仍写 `模型 1758`，实际已是 **1760**（改了一处忘了同步）。
6. Xaero 小地图报 `Exception when loading tfcfarmingplus:wild_crop/celtuce texture, using material colour`（INFO 级）。
   判断为**无害**（野生作物用 `parent: block/crop` 十字模型，Xaero 取不到单一贴图；只对它附近出现过的方块报一次），但**未深究**。若小地图上该野生作物颜色不对，从这里查。
7. **批次 11（树冠果实）仍暂缓** —— 需要与「贴侧面」不同的「长在树冠顶部」附着语义。不要擅自开工。
8. `docs/74` 只更新了树干果实落地情况表（§33.4 附近）；§9.2 / 批次状态等段落可能有旧的「AGE 0~2」措辞残留，未全量核对。

---

## 5. 建议的下一步（按优先级）

1. 用**玩家真实放置**验证 `setPlacedBy` 两条路径（见 §4.1），确认 `lastUpdateTick` 不再是哨兵值、`stemPos` 等于整棵树根部。
2. 进游戏**看一眼**三种莲座作物（幼苗/成熟/结果/枯死）与 6 种树干果实的实际观感，收一轮视觉反馈。
3. 复核 6 个物种的物候表与采收手感是否合理（§4.2）。
4. 同步 `AGENTS.md` 的 verify 数字、清理孤儿贴图。
5. 之后才考虑批次 11。

---

## 6. 踩坑速查（本轮新增，已写入 `AGENTS.md` 硬约束 16/17/18）

| # | 坑 | 判据 |
|---|---|---|
| 16 | 「占位 + 事后覆盖」的生成器，覆盖必须按 **blockstate 的变体空间逐组合核对**，不能按「我生成了几种几何」 | 莲座 15 个 `_fruiting` + 2 个枯死模型长期留在小麦形态 |
| 17 | TFC 的**静态 helper 一律按 TFC 自己的 `BlockEntityType` 查表**（`reset` / `resetPickedTick` / `setStemPos`）→ 自建 BE 上静默失效，必须用实例方法 | `lastUpdateTick` 停在哨兵值 → 第一次随机刻就长满 STAGE |
| 18 | **凡「论证为无影响」的异常值，必须在实机里真的读一次再下结论** | 早期靠「那段代码是 scheduled tick、没人 schedule」论证无害，反汇编后发现 `randomTick` **直接调用** `tick(...)`，前提不成立 |
| —（补充 13） | **视觉产物的验收判据里必须有一步是「看图」** | 1468 张贴图的「格式/尺寸/MD5/平均色」四项全绿，三处错误仍一眼可见 —— 前四项测的是**文件**，问题在**图像内容** |

---

## 7. 关键源码位置速查

```
moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/
  common/blocks/TrunkFruitBlock.java         树干果实（SeasonalPlantBlock 子类）
  common/blocks/MySeasonalPlantFix.java      计时补丁（afterUse / afterPlace）
  common/blocks/MyBerryBushBlock.java        浆果灌木（覆写 getDeadState / useItemOn / setPlacedBy）
  common/blocks/MyFruitTreeLeavesBlock.java  果树树叶（开花期蜜蜂 + 同上两处）
  common/MyTrunkFruits.java                  树干果实注册 + 12 月物候表
  common/MyFruitTrees.java                   39 种果树（TREES / CLIMATES / FRUITS / tickingBlocks）
  common/MyBlockEntities.java                4 个自建 BE 类型（CROP/BERRY_BUSH/DECAYING/TICK_COUNTING_PLANT）
  common/MyDebugCommands.java                /tfcfarmingplus calendar|plant|tree|probe|randomtick|setcounter
  common/FastGrow.java                       快速检查开关（当前默认关闭）

moddev/tfcfarmingplus/tools/
  gen-trunk-fruits.ps1    树干果实资源（48 变体 / 6 模型 / 2 贴图每物种）
  gen-rosette-models.ps1  莲座台座（12 组合全覆盖 + 枯死 + 中心果实）
  GenFruitTexture.java    程序化球体果实贴图（整张不透明）
  TintTextures.java       从 TFC 贴图按路径分档（BARK/LEAF/FRUIT/OTHER）变色
  verify.ps1              资源交叉引用校验

moddev/tools/
  launch-client.ps1       默认 -QuickPlay tfctest；fastgrow 那行已被注释
  stop-own-client.ps1     收尾必跑
```
