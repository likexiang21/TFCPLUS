# 作物系统实施计划（TFC 附属模组）

> 本文是**唯一权威的作物清单与施工图**，整合了此前所有轮次的调研、审查与修正。
> 环境：Minecraft 1.21.1 / NeoForge 21.1.248 / TFC 4.2.10 / Firmalife 3.0.14
> 生成依据：TFC 4.2.10 反编译源码（`moddev/src-ref/TFC-decompiled`）+ jar 数据实测 + Firmalife 源码

---

## 0. 范围与原则

| 项目 | 内容 |
|---|---|
| **目标** | 新增约 132 种作物/植物内容，全部对接 TFC 现有的养分、气候、日历、食物、堆肥体系 |
| **新方块类** | **6 个**（见 §2） |
| **新机制** | **2 个**（莲座式生长、非枝头结果的位置） |
| **不新增** | 存档结构、新的养分/气候体系、新的食物营养维度 |
| **产物原则** | 先 100% 对齐 TFC 原版模板，差异化留待后续指令 |

---

## 1. 核心机制约束（设计与数值的前提）

这一节是此前多轮调研的结论，**所有数值设计都必须遵守**。

### 1.1 生长速率是全局统一的 ⚠️

```java
// CropHelpers.growthTickStep —— 源码原文
public static final float GROWTH_FACTOR = 1.7361111E-6f;
totalGrowthDelta = 1.0f / growthModifier * Helpers.uniform(random, 0.9f, 1.1f)
                 * tickDelta * 1.7361111E-6f              // ← 与阶段数无关
                 + nutrientsConsumed / nutrientsForGrowth * 0.5f;   // 养分加成，最多 +0.5
```

| 结论 | 说明 |
|---|---|
| 长满 `1.0` 需 **576,000 ticks = 24 天** | 一年 180 天，故**一年理论 7.5 茬** |
| 养分充足时最快 | 1.5 倍 → **约 16 天** |
| **`maxAge`（阶段数）不影响生长时间** | 它只决定"视觉上有几段"，不决定快慢 |
| 想改变速率 | 只有覆写 `ICropBlock.growthTick`（**不做**，工作量大） |

**因此**：
- 不要用「现实 DTM（天数）」表达生长速度 —— 数据包做不到
- 作物强弱由「**温度区间跨度**」决定：宽温作物一年能种 7 茬，窄温作物只能 1 茬
- **阶段数按视觉节奏定**：24 天 ÷ 阶段数 = 每阶段时长；**最少 6 阶段**（4 阶段太长，玩家以为没在长），建议 6~8

### 1.2 养分经济：NPK 数值 = 需要的施肥量

```java
// 农田侧
value = Mth.clamp(value, 0.0f, 1.0f);                       // 养分范围 0.0~1.0
// 作物侧
maxNToConsume = nForGrowth - crop.getNAbsorbed();           // 全株累计吸收 ≤ N 值本身
```

| N 值 | 全株消耗 | 等效施肥 |
|---|---|---|
| 0.4（叶菜） | 0.4 | 2 次堆肥（N 0.2/次） |
| 0.7（蔬菜） | 0.7 | 3.5 次 |
| **1.0（谷物）** | **1.0** | **5 次** |
| -0.8（豆科） | 反向**补充** 0.8 | 无需施肥 |

**负值上限 -1.0**（农田容量就是 1.0，超出会溢出浪费）。

### 1.3 历法换算

| 单位 | Ticks | 游戏天 |
|---|---|---|
| 1 天 | 24,000 | 1 |
| **1 月** | **360,000** | **15** |
| **1 年** | **4,320,000** | **180** |

参考值：作物成熟 1.6 月 ｜ 野生作物成熟窗口 = 6~10 月（`wildCropMaturityStartMonth/EndMonth`）｜ 果树采摘冷却 0.8 月（288,000 ticks）

### 1.4 其他硬约束

| 约束 | 值 |
|---|---|
| 光照要求 | `getRawBrightness(pos, 0) >= 12` |
| 死亡条件 | `expiry >= 2.0 × expiryModifier / growthModifier` 或气候连 wiggle 都不满足 |
| 产量系数 | 受养分满足度影响，最低 **0.2 倍**（`YIELD_MIN`） |
| 生长更新间隔 | 48,000 ticks（2 天）一次结算 |
| 腐烂上限 | `decay_modifier` 实测范围 0.1（花生）~ 5.0（果酱） |

### 1.5 堆肥：走 TFC 的 tag 自动推导，**不自定义**

```json
// tfc:tags/item/compost_greens/high 的真实内容
{"values": ["#c:foods/vegetable", "#c:foods/fruit", "tfc:pumpkin", "tfc:melon"]}
```

> **只要新食物加对 `#c:foods/vegetable` 或 `#c:foods/fruit` 标签，就自动成为最高效的堆肥绿料** —— 零额外代码。
>
> 其他档位：纤维产物 → `#tfc:compost_browns/high`（照 `tfc:jute_fiber`）；绿肥作物（不可食）→ `#tfc:compost_greens/medium`；有毒植物 → `#tfc:compost_poisons`（**会让堆肥腐烂**）。
>
> ⚠️ **不要**自己写 `Fertilizer` 数据去"右键施肥"——TFC 的堆肥桶机制已完整，玩家手持任何注册为肥料的物品右键农田即可（`CropHelpers.useFertilizer`）。

### 1.6 灌木只能用于**矮灌木** ⚠️

```java
// StationaryBerryBushBlock 的形状
private static final VoxelShape HALF_PLANT = box(2, 0, 2, 14, 8, 14);  // 半格高
public VoxelShape getShape(...) { return state.getValue(STAGE) == 2 ? Shapes.block() : HALF_PLANT; }
```

**TFC 的浆果丛最多 1 格高**。所以：
- ✅ 只能用**匍匐矮灌木/小灌木**（现实高度 ≤2m）
- ❌ **不要**把乔木、小乔木（山楂、沙棘、桑）做成灌木 —— 它们走果树形态

---

## 2. 新方块类（6 个）

| # | 类名 | 基类 | 覆盖形态 | 难度 |
|---|---|---|---|---|
| 1 | `MyCropBlock` | `net.dries007.tfc.common.blocks.crop.CropBlock` | 单格作物 | ★ |
| 2 | `MyPickableCropBlock` | 同上（采摘退回逻辑） | 可采摘 / 多年生 | ★★ |
| 3 | `RosetteCropBlock` | 同上 | **莲座式（新机制①）** | ★★★★★ |
| 4 | `TrunkFruitBlock` | `SeasonalPlantBlock` | **茎干生果（新机制②）** | ★★★★ |
| 5 | `TrunkFruitingBranchBlock` | `FruitTreeBranchBlock` | 配合 4（树干侧结果） | ★★★★ |
| 6 | `CrownFruitBlock` + `CrownBranchBlock` | `SeasonalPlantBlock` / `GrowingFruitTreeBranchBlock` | 顶端结果 | ★★★★ |

**复用 TFC 直接实例化的部分**（不写新类）：双格、攀爬、水田、灌木、标准果树四件套。

### 2.1 `MyCropBlock`

```java
public class MyCropBlock extends CropBlock {
    private final IntegerProperty ageProperty;

    public MyCropBlock(ExtendedProperties properties, int maxAge, Supplier<? extends Block> dead,
                       Supplier<? extends Item> seeds, float n, float p, float k,
                       Supplier<ClimateRange> climateRange) {
        super(properties, maxAge, dead, seeds, n, p, k, climateRange);
        this.ageProperty = TFCBlockStateProperties.getAgeProperty(maxAge);
    }

    @Override public IntegerProperty getAgeProperty() { return ageProperty; }

    @Override protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop) {
        int age = crop.getGrowth() == 1.0f ? getMaxAge() : (int) (crop.getGrowth() * getMaxAge());
        level.setBlockAndUpdate(pos, state.setValue(ageProperty, age));
    }

    @Override public void die(Level level, BlockPos pos, BlockState state, boolean fullyGrown) {
        level.setBlockAndUpdate(pos, MyBlocks.DEAD_CROP.get().defaultBlockState()
            .setValue(DeadCropBlock.MATURE, fullyGrown));
    }
}
```

### 2.2 `RosetteCropBlock`（新机制①）

```java
public class RosetteCropBlock extends CropBlock {
    /** 叶片轮数 0~5（6 阶段，保证视觉节奏） */
    private static final IntegerProperty AGE = TFCBlockStateProperties.getAgeProperty(5);
    /** 中心是否已结果 —— 与 TFC 作物的唯一结构差异 */
    public static final BooleanProperty FRUITING = BooleanProperty.create("fruiting");

    public RosetteCropBlock(ExtendedProperties properties, Supplier<? extends Block> dead,
                            Supplier<? extends Item> seeds, float n, float p, float k,
                            Supplier<ClimateRange> climateRange) {
        super(properties, 5, dead, seeds, n, p, k, climateRange);
    }

    @Override public IntegerProperty getAgeProperty() { return AGE; }

    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(AGE, FRUITING);      // ★ 必须覆写：父类只注册 ageProperty
    }

    @Override protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop) {
        if (crop.getGrowth() >= 1.0f) {
            level.setBlockAndUpdate(pos, state.setValue(AGE, 5).setValue(FRUITING, true));
        } else {
            level.setBlockAndUpdate(pos, state.setValue(AGE, (int) (crop.getGrowth() * 5)));
        }
    }

    @Override public void die(Level level, BlockPos pos, BlockState state, boolean fullyGrown) {
        level.setBlockAndUpdate(pos, MyBlocks.DEAD_ROSETTE.get().defaultBlockState());
    }
}
```
**模型数**：6（AGE）× 2（FRUITING）= **12 个**。
**掉落**：破坏时按 `fruiting: true` 判条件掉果实，并**必定掉 1~2 个侧芽**（侧芽 = 该作物的"种子"）。

### 2.3 `TrunkFruitBlock`（新机制②）

```java
public class TrunkFruitBlock extends SeasonalPlantBlock {
    public static final DirectionProperty FACING = BlockStateProperties.HORIZONTAL_FACING;

    public TrunkFruitBlock(ExtendedProperties properties, Supplier<ClimateRange> climateRange,
                           Supplier<? extends Item> productItem, Lifecycle[] lifecycle) {
        super(properties, climateRange, productItem, lifecycle);   // ★ 白拿季节/气候/采摘/冷却
    }

    /** ★ 唯一的核心差异：宿主必须是果树枝干 */
    @Override protected boolean mayPlaceOn(BlockState state, BlockGetter level, BlockPos pos) {
        return Helpers.isBlock(state, TFCTags.Blocks.FRUIT_TREE_BRANCH);
    }

    @Override protected boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        Direction facing = state.getValue(FACING);
        return mayPlaceOn(level.getBlockState(pos.relative(facing)), level, pos.relative(facing));
    }
}
```

**继承 `SeasonalPlantBlock` 白拿的能力**：12 月 `Lifecycle[]` 季节曲线 · `ClimateRange` 校验 · `FRUITING` 右键采摘 · 采摘冷却 · 南北半球季节取反 · 锄头提示。

配套 `TrunkFruitingBranchBlock` 在季节正确时于树干侧面生成果实方块（同 `SpreadingCropBlock` 生成南瓜的套路）。

---

## 3. 作物总清单（132 种）

### 3.1 灌木浆果（10 种）· 零方块类

直接 `new StationaryBerryBushBlock(props, 产物, Lifecycle[12], 气候引用)`。

| 灌木 | 现实高度 | 温度℃ | 水合 | 产物 | decay | 营养 |
|---|---|---|---|---|---|---|
| 越橘 Lingonberry | 10~40cm | **-18~16** | 25~75 | `lingonberry` | 4.0 | fruit 0.8 |
| 熊果 Bearberry | 10~30cm | -20~14 | 15~60 | `bearberry` | 3.5 | fruit 0.6 |
| 岩高兰 Crowberry | 10~30cm | **-22~14** | 20~70 | `crowberry` | 3.5 | fruit 0.6 |
| 黑果越橘 Bilberry | 20~50cm | -16~18 | 30~80 | `bilberry` | 4.0 | fruit 0.9 |
| 黑加仑 Blackcurrant | 1~1.5m | -12~22 | 35~85 | `blackcurrant` | 3.5 | fruit 0.9 |
| 红加仑 Redcurrant | 1~1.5m | -10~24 | 35~85 | `redcurrant` | 3.5 | fruit 0.8 |
| 蓝靛果 Haskap | 1.5~2m | -14~22 | 35~85 | `haskap` | 4.0 | fruit 1.0 |
| 枸杞 Goji | 1~2m | -12~30 | **10~55** | `goji` | 3.0 | fruit 0.8 |
| 唐棣 Serviceberry | 1~3m | -15~22 | 30~80 | `serviceberry` | 3.5 | fruit 0.8 |
| 黑果腺肋花楸 Aronia | 1~3m | -14~24 | 30~80 | `aronia` | 3.5 | fruit 0.9 |

### 3.2 单格类作物（45 种）· `MyCropBlock`

> 说明：本节的表格按**作物用途**分组（蔬菜/谷物/豆科/油料纤维），其中少数条目是跨形态的
> （高粱=双格、豆科的攀爬与双格、向日葵/大麻=双格、剑麻=莲座式），
> 已在各行明确标注。纯单格作物合计 44 种。

#### 蔬菜（19）

| 作物 | N/P/K | 阶段 | 温度℃ | 水合 | 产物 | decay | 营养 |
|---|---|---|---|---|---|---|---|
| 菠菜 Spinach | +0.7/-0.2/-0.2 | 6 | -8~22 | 50~90 | `spinach` | **4.0** | veg 2.0, water 3 |
| 生菜 Lettuce | +0.6/-0.2/-0.2 | 6 | -5~24 | 55~95 | `lettuce` | **4.5** | veg 1.5, water 4 |
| 芹菜 Celery | +0.7/+0.3/+0.4 | 6 | 5~24 | **65~100** | `celery` | 3.0 | veg 1.8, water 4 |
| 羽衣甘蓝 Kale | +0.7/+0.2/+0.3 | 6 | **-14~22** | 35~80 | `kale` | **0.5** | veg 2.0, water 3 |
| 大白菜 Napa Cabbage | +0.7/+0.2/+0.4 | 7 | -8~24 | 50~85 | `napa_cabbage` | **0.6** | veg 2.2 |
| 芥菜 Mustard | +0.3/+0.25/+0.35 | 6 | -8~24 | 25~80 | `mustard_greens` | 4.0 | veg 1.5 |
| 西兰花 Broccoli | +0.8/+0.3/+0.4 | 6 | 5~24 | 50~85 | `broccoli` | 3.0 | veg 1.8 |
| 花椰菜 Cauliflower | +0.8/+0.3/+0.4 | 7 | 5~24 | 50~85 | `cauliflower` | 3.0 | veg 1.7 |
| 抱子甘蓝 Brussels Sprouts | +0.8/+0.3/+0.4 | 7 | -6~22 | 45~85 | `brussels_sprouts` | **0.6** | veg 2.0 |
| 瑞士甜菜 Swiss Chard | +0.6/+0.2/+0.4 | 6 | -5~26 | 40~80 | `swiss_chard` | 4.0 | veg 2.0, water 3 |
| 莴笋 Celtuce | +0.6/-0.2/-0.2 | 6 | 5~24 | 50~90 | `celtuce` | 3.5 | veg 1.5, water 4 |
| 茼蒿 Garland Chrysanthemum | +0.6/-0.2/-0.2 | 6 | 5~26 | 50~90 | `garland_chrysanthemum` | 4.0 | veg 1.6 |
| 紫苏 Perilla | +0.6/-0.2/-0.2 | 6 | 12~32 | 45~85 | `perilla` | 3.5 | veg 1.2 |
| 芝麻菜 Arugula | +0.5/-0.2/-0.2 | 6 | -5~26 | 45~85 | `arugula` | 4.0 | veg 1.3 |
| 芜菁 Turnip | +0.3/+0.3/+0.4 | 6 | **-12~20** | 20~70 | `turnip` | **0.4** | veg 1.2 |
| 欧防风 Parsnip | +0.4/+0.25/+0.5 | 6 | -10~22 | 25~75 | `parsnip` | **0.4** | veg 1.5 |
| 菊芋 Sunchoke | +0.3/+0.2/+0.6 | 6 | -12~24 | 20~70 | `sunchoke` | **0.35** | veg 1.0, grain 0.3 |
| 红葱 Shallot | +0.35/+0.3/+0.45 | 6 | 0~26 | 15~65 | `shallot` | **0.4** | veg 2.0 |
| 块根芹 Celeriac | +0.6/+0.3/+0.5 | 6 | 5~24 | 45~85 | `celeriac` | 0.5 | veg 1.3 |
| 婆罗门参 Salsify | +0.4/+0.3/+0.5 | 6 | -10~24 | 25~75 | `salsify` | **0.4** | veg 1.4 |
| 雪莲果 Yacón | +0.35/+0.3/+0.5 | 6 | 8~28 | 30~75 | `yacon` | 0.5 | veg 1.2 |
| 菊苣根 Chicory Root | +0.4/+0.2/+0.5 | 6 | -8~26 | 30~75 | `chicory_root` | **0.4** | veg 1.1 |

> 注：蔬菜/块根合计 22 项（上表含 8 种块根类，与 §3.2 的 45 项统计一致）。

#### 谷物（14）

| 作物 | N/P/K | 阶段 | 温度℃ | 水合 | 面包 grain |
|---|---|---|---|---|---|
| 黍 Millet | +0.7/-0.25/-0.3 | 6 | 8~32 | **5~55** | 1.2 |
| 谷子 Foxtail Millet | +0.7/-0.25/-0.25 | 6 | 5~30 | 10~55 | 1.2 |
| 荞麦 Buckwheat | +0.4/-0.4/-0.4 | 6 | -2~22 | 25~70 | 1.0 |
| 福尼奥米 Fonio | +0.4/-0.4/-0.4 | 6 | 20~38 | **5~40** | 1.0 |
| 斯佩耳特小麦 Spelt | +0.85/-0.35/-0.35 | 7 | **-12~22** | 20~75 | **1.5** |
| 二粒小麦 Emmer | +0.9/-0.3/-0.3 | 7 | -8~24 | 15~65 | **1.5** |
| 单粒小麦 Einkorn | +0.8/-0.3/-0.3 | 7 | -10~24 | 15~70 | **1.5** |
| 珍珠粟 Pearl Millet | +0.8/-0.3/-0.3 | 6 | **22~40** | **5~35** | 1.1 |
| 苋菜 Amaranth | +0.6/-0.2/-0.2 | 6 | 8~32 | 20~75 | 1.1 |
| 藜麦 Quinoa | +0.5/**0**/-0.3 | 7 | **-5~20** | 15~55 | 1.2 |
| 穇子 Finger Millet | +0.6/-0.35/-0.35 | 6 | 15~32 | 20~60 | 1.1 |
| 薏苡 Job's Tears | +0.7/-0.3/-0.3 | 6 | 12~32 | 40~85 | 1.1 |
| 高粱 Sorghum | +1.0/-0.3/-0.3 | 双格 3+3 | 12~34 | 10~60 | 1.2 |

#### 豆科（10）

| 作物 | 形态 | N/P/K | 阶段 | 温度℃ | 水合 | 营养 |
|---|---|---|---|---|---|---|
| 鹰嘴豆 Chickpea | 单 | **-0.85**/+0.3/+0.3 | 6 | 2~28 | 15~55 | protein 1.2, veg 0.5 |
| 蚕豆 Faba Bean | 单 | **-0.9**/+0.4/+0.4 | 6 | -8~22 | 30~85 | protein 1.3, veg 0.5 |
| 羽扇豆 Lupin | 单 | **-1.0**/+0.3/+0.3 | 6 | -5~22 | 25~75 | protein 1.4 |
| 红小豆 Adzuki | 单 | -0.75/+0.35/+0.35 | 6 | 8~28 | 30~85 | protein 1.1, veg 0.6 |
| 班巴拉豆 Bambara Nut | 单 | -0.9/+0.3/+0.4 | 6 | 20~38 | 20~65 | protein 1.3 |
| 胡卢巴 Fenugreek | 单 | -0.7/+0.3/+0.3 | 6 | 5~30 | 30~75 | protein 0.8, veg 0.6 |
| 豌豆 Pea | 攀爬 | -0.7/+0.3/+0.3 | 6+6 | -8~20 | 25~80 | protein 1.0, veg 0.8 |
| 豇豆 Cowpea | 攀爬 | -0.8/+0.4/+0.3 | 6+6 | 12~35 | 15~60 | protein 1.2, veg 0.5 |
| 菜豆 Common Bean | 攀爬 | -0.8/+0.4/+0.4 | 6+6 | 10~30 | 30~80 | protein 1.2, veg 0.6 |
| 四棱豆 Winged Bean | 攀爬 | **-1.0**/+0.3/+0.4 | 6+6 | 18~36 | 40~90 | protein 1.3, veg 0.7 |
| 木豆 Pigeon Pea | 双格 | -0.9/+0.4/+0.4 | 6+6 | 15~38 | 20~65 | protein 1.3 |

> 豆类统一模板：`decay 1.0（生）/ 2.5（熟）`，`sat 2.0`，熟制走 `tfc:heating`。

#### 油料 / 纤维（7）

| 作物 | N/P/K | 形态 | 阶段 | 温度℃ | 水合 | 产物 |
|---|---|---|---|---|---|---|
| 亚麻 Flax | +0.5/-0.2/-0.2 | 单 | 6 | -5~22 | 20~70 | `flax_fiber` + `flax_seed` |
| 芝麻 Sesame | +0.45/+0.3/-0.35 | 单 | 6 | 15~38 | 15~60 | `sesame` |
| 红花 Safflower | +0.4/-0.3/-0.5 | 单 | 6 | 8~32 | **5~40** | `safflower` |
| 苎麻 Ramie | +0.65/+0.2/-0.3 | 单 | 6 | 12~32 | 35~85 | `ramie_fiber` |
| 向日葵 Sunflower | +0.8/-0.3/-0.4 | 双格 3+3 | 6+6 | 5~30 | 20~70 | `sunflower_seed` |
| 大麻 Hemp | +0.7/-0.3/-0.3 | 双格 | 6+6 | 2~28 | 25~80 | `hemp_fiber` |
| 剑麻 Sisal | +0.4/-0.4/-0.4 | **莲座式** | 6 | 18~40 | **5~45** | `sisal_fiber` |

### 3.3 可采摘 / 多年生（9 种）· `MyPickableCropBlock`

| 作物 | N/P/K | 阶段 | 温度℃ | 水合 | 产物 | decay | 营养 |
|---|---|---|---|---|---|---|---|
| 辣椒 Chili | +0.3/+0.4/+0.5 | 6 | 12~36 | 25~80 | `chili` | 2.5 | veg 1.5 |
| 茄子 Eggplant | +0.35/+0.4/+0.5 | 7 | 14~36 | 30~85 | `eggplant` | 3.0 | veg 1.8 |
| 秋葵 Okra | +0.4/+0.35/+0.5 | 6 | 16~38 | 25~70 | `okra` | 3.5 | veg 1.6, water 3 |
| 棉花 Cotton | +0.6/+0.3/-0.3 | 6 | 15~38 | 30~80 | `cotton_boll` | 0.3 | 纤维 |
| 芦笋 Asparagus | +0.6/+0.3/+0.4 | 8 | -8~28 | 40~80 | `asparagus` | 4.0 | veg 1.5 |
| 韭菜 Chive | +0.6/-0.2/-0.2 | 6 | -10~26 | 40~80 | `chive` | **4.5** | veg 1.6 |
| 大黄 Rhubarb | +0.5/+0.2/+0.3 | 6 | -12~24 | 45~85 | `rhubarb` | 4.0 | veg 1.0 |
| 洋蓟 Artichoke | +0.7/+0.3/+0.5 | 7 | 5~26 | 40~80 | `artichoke` | 3.5 | veg 1.4 |
| 茶 Tea | +0.5/-0.3/-0.3 | 8 | 12~32 | 50~95 | `tea_leaf` | 0.8 | 饮品 |
| 咖啡 Coffee | +0.5/+0.3/-0.4 | 8 | 16~34 | 40~85 | `coffee_bean` | 0.6 | 饮品 |

> "多年生"由**采摘退回状态**实现（芦笋/韭菜/大黄/洋蓟/茶/咖啡），不需要专门方块类。

### 3.4 水田（10 种）· TFC `FloodedCropBlock` 直接实例化

| 作物 | N/P/K | 阶段 | 温度℃ | 水合 | 产物 | 营养 |
|---|---|---|---|---|---|---|
| 芋头 Taro | +0.45/+0.35/+0.6 | 7 | 16~38 | 45~100 | `taro` | grain 0.5 |
| 荸荠 Water Chestnut | +0.4/+0.3/+0.6 | 6 | 14~34 | 60~100 | `water_chestnut` | veg 1.2 |
| 菱角 Water Caltrop | +0.35/+0.3/+0.55 | 6 | 15~35 | 70~100 | `water_caltrop` | grain 0.4, veg 0.6 |
| 茭白 Wild Rice Stem | +0.5/+0.3/+0.5 | 6 | 12~32 | 65~100 | `wild_rice_stem` | veg 1.5, water 3 |
| 莲藕 Lotus | +0.45/+0.35/+0.6 | 8 | 16~38 | 70~100 | `lotus_root` + `lotus_seed` | veg 1.3 / grain 0.6 |
| 水芹 Water Dropwort | +0.5/+0.3/+0.4 | 6 | **5~25** | 70~100 | `water_dropwort` | veg 1.8, water 4 |
| 空心菜 Water Spinach | +0.8/-0.2/-0.2 | 6 | 18~38 | 65~100 | `water_spinach` | veg 2.0, water 4 |
| 慈菇 Arrowhead | +0.45/+0.35/+0.55 | 6 | 14~34 | 60~100 | `arrowhead` | grain 0.4, veg 0.8 |
| 芡实 Gorgon Nut | +0.4/+0.3/+0.55 | 6 | 16~36 | 70~100 | `gorgon_nut` | grain 0.7 |
| 莼菜 Water Shield | +0.4/+0.2/+0.3 | 6 | 10~30 | 80~100 | `water_shield` | veg 1.0, water 5 |

### 3.5 瓜类（4 种）· `SpreadingCropBlock` + 新结果方块

| 瓜 | N/P/K | 阶段 | 温度℃ | 水合 | 整瓜 decay | 切片 decay |
|---|---|---|---|---|---|---|
| 哈密瓜 Cantaloupe | +0.4/+0.35/+0.55 | 6 | 18~38 | 30~80 | 0.5 | 2.5 |
| 冬瓜 Winter Melon | +0.5/+0.35/+0.55 | 7 | 15~35 | 40~90 | **0.3** | 2.5 |
| 瓠瓜 Bottle Gourd | +0.4/+0.3/+0.5 | 6 | 15~36 | 35~85 | 0.5 | 2.5 |
| 佛手瓜 Chayote | +0.4/+0.35/+0.5 | 攀爬 6+6 | 15~34 | 40~90 | 0.6 | 2.5 |

> 每种需注册**结果方块 + 腐烂变体**（照 TFC 的 `PUMPKIN`/`ROTTEN_PUMPKIN`，用 `DecayingBlockEntity`）。
> ⚠️ **西瓜不新增** —— TFC 的 `melon` 贴图就是西瓜。

### 3.6 攀爬 / 双格（补全）

| 作物 | 形态 | N/P/K | 阶段 | 温度℃ | 产物 |
|---|---|---|---|---|---|
| 啤酒花 Hops | 攀爬 | +0.9/+0.2/-0.3 | 6+6 | 6~24 | `hops` |
| 丝瓜 Loofah | 攀爬 | +0.45/+0.3/+0.5 | 6+6 | 15~36 | `loofah` + `loofah_fiber` |
| 苦瓜 Bitter Melon | 攀爬 | +0.4/+0.35/+0.5 | 6+6 | 16~38 | `bitter_melon` |
| 蛇瓜 Snake Gourd | 攀爬 | +0.4/+0.35/+0.5 | 6+6 | 18~38 | `snake_gourd` |
| 山药 Yam | 攀爬 | +0.5/+0.3/+0.6 | 6+6 | 15~36 | `yam` |
| 木耳菜 Malabar Spinach | 攀爬 | +0.7/-0.2/-0.2 | 6+6 | 18~38 | `malabar_spinach` |

### 3.7 标准果树（28 种）· TFC 果树四件套

| 果树 | 温度℃ | | 果树 | 温度℃ |
|---|---|---|---|---|
| 梨 Pear | -14~28 | | 荔枝 Lychee | 12~36 |
| 枇杷 Loquat | 0~26 | | 芒果 Mango | 15~40 |
| 石榴 Pomegranate | 5~34 | | 牛油果 Avocado | 12~34 |
| 柿子 Persimmon | -8~28 | | 番石榴 Guava | 12~36 |
| 杏 Apricot | -10~28 | | 枣 Jujube | 10~36 |
| 榅桲 Quince | -6~28 | | 山竹 Mangosteen | 20~38 |
| 桑 Mulberry | -12~30 | | 红毛丹 Rambutan | 20~38 |
| 无花果 Fig | 5~34 | | 龙眼 Longan | 12~36 |
| 杨梅 Waxberry | 5~30 | | 莲雾 Wax Apple | 18~38 |
| 柚 Pomelo | 8~36 | | 人心果 Sapodilla | 18~38 |
| 青柠 Lime | 12~38 | | 黄皮 Wampee | 12~34 |
| 柑橘 Mandarin | 5~34 | | 油柑 Amla | 15~40 |
| 葡萄柚 Grapefruit | 10~36 | | **沙棘** Sea Buckthorn | -15~24 |
| 金橘 Kumquat | 5~34 | | **山楂** Hawthorn | -12~26 |
| 猕猴桃 Kiwi | -5~28（攀爬） | | 百香果 Passionfruit | 15~36（攀爬） |

### 3.8 茎干生果（6 种）· `TrunkFruitBlock`（新机制②）

| 树种 | 温度℃ | 水合 | 产物 | 现实依据 |
|---|---|---|---|---|
| 可可 Cocoa | 20~34 | 60~100 | `cocoa_beans` | 干生花教科书案例 |
| 杨桃 Starfruit | 15~36 | 50~90 | `starfruit` | 干生/枝生 |
| 面包果 Breadfruit | 20~38 | 60~100 | `breadfruit` | 干生果 |
| 菠萝蜜 Jackfruit | 20~38 | 55~95 | `jackfruit` | 单果最重 |
| 榴莲 Durian | 22~38 | 60~100 | `durian` | 干生果 |
| 番荔枝 Sugar Apple | 20~36 | 45~85 | `sugar_apple` | 干生/枝生 |

### 3.9 顶端结果（2 种）· `CrownFruitBlock`

| 树种 | 温度℃ | 树形 | 产物 |
|---|---|---|---|
| 番木瓜 Papaya | 18~38 | 单干不分叉 | `papaya` |
| 椰子 Coconut | 18~40 | 单干 | `coconut`（+ `coconut_water`，water 8） |

### 3.10 坚果（5 种）· 果树形态

| 坚果 | 温度℃ | 产物 | decay | 营养 |
|---|---|---|---|---|
| 杏仁 Almond | -5~30 | `almond` | **0.2** | protein 1.2 |
| 核桃 Walnut | -14~26 | `walnut` | **0.15** | protein 1.3 |
| 榛子 Hazelnut | -12~26 | `hazelnut` | **0.2** | protein 1.2 |
| 开心果 Pistachio | 5~34 | `pistachio` | **0.15** | protein 1.3 |
| 腰果 Cashew | 18~38 | `cashew` | **0.2** | protein 1.4 |

> 坚果走"极耐储"路线（0.15~0.2，对标 TFC 花生的 0.1），是冬储玩法的重要支柱。

### 3.11 莲座式（3 种）· `RosetteCropBlock`（新机制①）

| 作物 | N/P/K | 阶段 | 温度℃ | 水合 | 产物 | 繁殖 |
|---|---|---|---|---|---|---|
| 龙舌兰 Agave | +0.2/-0.5/-0.5 | 6 | 18~38 | **5~35** | `agave_heart` | 侧芽 |
| 剑麻 Sisal | +0.4/-0.4/-0.4 | 6 | 18~40 | **5~45** | `sisal_fiber` | 侧芽 |
| 芦荟 Aloe | +0.3/-0.4/-0.3 | 6 | 15~38 | **5~40** | `aloe_leaf` | 侧芽 |

> ⚠️ **菠萝不进首批** —— Firmalife 已把菠萝做成 `StationaryBush`，避免冲突，用龙舌兰/剑麻/芦荟验证机制。

### 3.12 香料（2 种）

| 作物 | 形态 | N/P/K | 阶段 | 温度℃ | 产物 |
|---|---|---|---|---|---|
| 姜 Ginger | 单格 | +0.4/+0.3/+0.55 | 7 | 18~36 | `ginger` |
| 姜黄 Turmeric | 单格 | +0.4/+0.35/+0.55 | 7 | 18~35 | `turmeric` |
| 黑胡椒 Black Pepper | 攀爬 | +0.5/+0.3/+0.4 | 6+6 | 20~35 | `black_pepper` |

---

## 4. 产物链模板（100% 对齐 TFC）

### 4.1 谷物 7 件套

```
<grain>                     decay 2.0    无营养      ← 刀脱粒（tfc:advanced_shapeless_crafting）
                                                   条件 tfc:not_rotten，副产 1 个 tfc:straw
<grain>_grain               decay 0.25   grain 0.5~1.0, sat 0.5    ← tfc:quern
<grain>_flour               decay 0.5    无营养      ← tfc:barrel_instant（加水）
<grain>_dough               decay 3.0    无营养      ← tfc:heating
<grain>_bread               decay 1.0    grain 1.0/1.2/1.5, sat 1.0
<grain>_bread_sandwich      decay 4.5
<grain>_bread_jam_sandwich  decay 4.5
```

**品质档分配**：
- **1.5（优质）**：斯佩耳特、二粒、单粒小麦
- **1.2（中等）**：黍、谷子、高粱、藜麦
- **1.1（基础）**：荞麦、福尼奥米、珍珠粟、苋菜、穇子、薏苡

### 4.2 其他模板

| 类型 | 产物链 |
|---|---|
| **蔬菜（耐储）** | decay 0.4~0.8，veg 1.2~2.5 |
| **蔬菜（易腐）** | decay 3.0~4.5，veg 1.5~2.0 **+ water 3~4** |
| **豆类** | `<bean>` decay 1.0（protein + veg）→ `<bean>_cooked` decay 2.5（`tfc:heating`） |
| **块根** | `<root>` decay 0.35~0.5 → `<root>_baked` decay 1.0（`tfc:heating`） |
| **瓜类** | 整瓜 decay 0.5 → 切片 decay 2.5 + water 5 |
| **纤维** | `<x>_fiber` decay 0.2 → `crafting`（绳/布）+ `tfc:loom` |
| **坚果** | decay 0.15~0.2，protein 1.2~1.4 |
| **水果** | decay 1.5~4.5，fruit 0.7~1.0 → 果酱（`tfc:pot_jam`） |

### 4.3 三条铁律

1. **加工配方一律带 `tfc:not_rotten`**（腐烂原料不能加工）
2. **产物一律带 `tfc:copy_food` modifier**（继承原料新鲜度，加工不刷新保质期）
3. **食物物品一律加 `#c:foods/vegetable` 或 `#c:foods/fruit`**（自动获得堆肥绿料 + 沙拉/汤可用 + 交易）

---

## 5. 实施批次（从易到难）

| 批次 | 内容 | 数量 | 新方块类 | 难度 | 关键产出 |
|---|---|---|---|---|---|
| **1** | 灌木浆果 | 10 | **0** | ★ | 最快验证数据管线（气候/食物/掉落/Lifecycle） |
| **2** | 单格蔬菜（叶菜类） | 8 | `MyCropBlock` | ★ | **验证核心方块类** |
| **3** | 单格蔬菜（根茎类）+ 香料 | 13 | 复用 | ★ | 数据铺开 |
| **4** | 单格谷物（含 7 件套） | 12 | 复用 | ★★ | **验证完整产物链** |
| **5** | 可采摘 / 多年生 | 9 | `MyPickableCropBlock` | ★★ | 采摘退回机制 |
| **6** | 豆科 | 10 | 复用 + TFC 攀爬/双格 | ★★ | 固氮循环闭环 |
| **7** | 油料 / 纤维 | 7 | 复用 + 莲座（剑麻待 13） | ★★ | — |
| **8** | 水田 | 11 | TFC `FloodedCropBlock` | ★★ | 水体逻辑 |
| **9** | 攀爬 / 双格补全 | 7 | TFC 类 | ★★ | — |
| **10** | 瓜类 | 4 | **结果方块 ×4 + 腐烂变体 ×4** | ★★★★ | 蔓延结果机制 |
| **11** | 标准果树 | 28 | TFC 四件套 + **3 个薄子类** | ★★★ | BE 适配（接管静态 helper） |
| **12** | 坚果 | 5 | 复用果树 | ★★★ | — |
| **13** | **茎干生果** | 6 | **`TrunkFruitBlock` + `TrunkFruitingBranchBlock`** | ★★★★ | **新机制②** |
| **14** | **顶端结果** | 2 | **`CrownFruitBlock` + `CrownBranchBlock`** | ★★★★ | — |
| **15** | **莲座式** | 3 | **`RosetteCropBlock`** | ★★★★★ | **新机制①** |

> **批次 2 与批次 4 是关键里程碑**：前者验证作物方块类，后者验证 7 件套产物链。
> **批次 13/14/15 是三个需要新方块的机制批次**，放最后。

---

## 6. 搁置项（记录在案，不实施）

| 项 | 原因 |
|---|---|
| **TFC 现有树改造**（栗子、碧根果、橡子、松子、椰枣、云杉芽、木棉、阿拉伯胶、柳条） | 用户要求搁置 |
| **取汁类**（枫糖浆、桦树汁） | 属其它模组内容 |
| **豆制品加工链**（豆浆/豆腐/豆腐干/腐乳） | 用户要求作物完成后再深化（用于补 dairy 维度） |
| **染料作物**（茜草、靛蓝、菘蓝、蓼蓝、皂草、油桐） | 作物可先加，染色机制后补 |
| **药用作物**（洋地黄、颠茄、甘草、人参、薄荷、艾草） | 药效系统后补 |
| **蘑菇** | 需"无光生长"新机制 |
| **竹笋** | TFC 已有竹子 |
| **菠萝** | 与 Firmalife 冲突，待定 |
| **西瓜** | TFC 的 `melon` 就是西瓜 |
| **Vat 流体化加工链**（染料液、果汁、糖水、油） | Firmalife 已提供机制，但属"深化内容" |

---

## 7. 文件清单与工作量

### 7.1 单作物文件模板

| 文件 | 数量 |
|---|---|
| `blockstates/crop/<name>.json` | 1 |
| `models/block/crop/<name>_age_0..N.json` | 6~7 |
| `textures/block/crop/<name>_age_*.png` | 6~7 |
| `models/item/seeds/<name>.json` + 贴图 | 1 |
| `models/item/food/<name>.json` + 贴图 | 1~7 |
| `lang/zh_cn.json` + `en_us.json` | 2 |
| `data/<ns>/tfc/climate_range/crop/<name>.json` | 1 |
| `data/<ns>/tfc/food/<name>.json` | 1~7 |
| `data/<ns>/loot_table/blocks/crop/<name>.json` | 1 |
| `data/<ns>/recipe/...` | 2~8 |
| `data/<ns>/tags/item/...` | 1~2 |

**单作物**：蔬菜约 25 个文件 ｜ 谷物约 55 个文件

### 7.2 全量估算

| 类别 | 数量 | × 文件/种 | 小计 |
|---|---|---|---|
| 灌木 | 10 | 8 | 80 |
| 单格作物 | 45 | 25 | 1125 |
| 谷物（含谷物链） | 12 | 55 | 660 |
| 可采摘 | 10 | 25 | 250 |
| 水田 | 11 | 25 | 275 |
| 瓜类 | 4 | 40 | 160 |
| 果树 | 28 | 20 | 560 |
| 茎干/顶端/莲座 | 11 | 30 | 330 |
| 坚果 | 5 | 20 | 100 |
| **合计** | **132** | — | **约 3540 个文件** |

> **结论：必须先搭 datagen 管线**（参考 Firmalife 的 14 个 data provider），否则手工做不完。

---

## 8. 施工前置条件

| # | 前置项 | 说明 |
|---|---|---|
| 1 | **6 个方块类的骨架** | 见 §2 |
| 2 | **注册框架** | `MyBlocks` / `MyItems` / `MyCrops`（枚举驱动批量注册） |
| 3 | **datagen 管线** | blockstates / models / loot / recipe / tags / lang 自动生成 |
| 4 | **气候数据生成器** | 从作物枚举批量产出 `climate_range/*.json` |
| 5 | **食物数据生成器** | 批量产出 `tfc/food/*.json` |
| 6 | **贴图方案** | 132 种 × 6~7 张阶段贴图 —— 建议先用占位图，后续替换 |

---

## 9. 附录：本计划的关键修正记录

| # | 修正 | 来源 |
|---|---|---|
| 1 | 删除"西瓜" | TFC 的 `melon` 贴图即西瓜（已做像素核实） |
| 2 | 堆肥走 `#c:foods/*` tag 自动推导，不自定义 `Fertilizer` | TFC `compost_greens/high` 实测内容 |
| 3 | 删除"地下结果"机制 | 收获本来就是破坏方块 |
| 4 | 删除"多年生"专用方块类 | 采摘退回 + 气候合适即自然多年生 |
| 5 | 删除取汁类 | 属其它模组内容 |
| 6 | 搁置 TFC 现有树改造 | 用户要求 |
| 7 | 搁置豆制品加工 | 用户要求（作物后深化） |
| 8 | **灌木只用于矮灌木** | `StationaryBerryBushBlock` 形状最高 1 格 |
| 9 | 修正 Vat 定位为"大号锅" | `VatBlockEntity extends BoilingBlockEntity`，流体过滤用 `USABLE_IN_POT` |
| 10 | 生长速率全局统一 16~24 天，阶段数不影响时长 | `CropHelpers.growthTickStep` 公式 |
| 11 | NPK 数值 = 施肥量，上限 ±1.0 | 农田 `clamp(0,1)` + 全株吸收 ≤ N |
| 12 | 阶段数最少 6 | 24 天 ÷ 阶段数，4 阶段每段 6 天太长 |
| 13 | 羽扇豆 N 从 -1.2 改 -1.0 | 超农田容量会上溢 |
| 14 | 莲座式从 4 阶段改 6 阶段 | 视觉节奏 |
| 15 | 恢复"茎干生果"与"顶端结果" | 用户明确要求，之前误归入搁置 |

---

## 10. 批次 4 的三点设计修正（用户指示，务必执行）

### 10.1 新建物品，不再借用 TFC 的物品

之前亚麻/苎麻为「不扩机制」借用了 `tfc:jute_fiber`。现改为**本模组自己的纤维物品**：

| 作物 | 现在 | 改为 |
|---|---|---|
| 亚麻 flax | `tfc:jute_fiber`（借的） | **`tfcfarmingplus:fiber/flax`** 亚麻纤维 Flax Fibre |
| 苎麻 ramie | `tfc:jute_fiber`（借的） | **`tfcfarmingplus:fiber/ramie`** 苎麻纤维 Ramie Fibre |
| 棉花 cotton（批次 4） | — | **`tfcfarmingplus:cotton_boll`** 棉铃 Cotton Boll |

这些是**非食物物品**：要有物品模型和 lang，但**不生成食物数据**。

### 10.2 茶、咖啡先放占位物品

`tea_leaf`（茶叶）、`coffee_bean`（咖啡豆）先按占位物品加，等做饮品体系时再补全用途。

### 10.3 茶、咖啡是灌丛，不要与耕地作物混在一起

这两者在现实中是**常绿灌木/小乔木**，不能按 `crop/<name>` 的耕地作物做，应走**灌木形态**
（与浆果灌木同一套：`plant/<name>_bush` + `MyBerryBushBlock` / `MySpreadingBushBlock`）：

| 作物 | 形态 | 注册名 | 方块类 |
|---|---|---|---|
| 茶 tea | **灌丛** | `plant/tea_bush` | 灌木 |
| 咖啡 coffee | **灌丛** | `plant/coffee_bush` | 灌木 |
| 辣椒/茄子/秋葵/棉花/芦笋/韭菜/大黄/洋蓟 | 耕地作物 | `crop/<name>` | `MyPickableCropBlock` |

所以批次 4 实际是 **8 种可采摘耕地作物 + 2 种灌丛**。

### 10.4 gen-crops.ps1 的 prod 需要支持三种形式

```powershell
if (-not $prod) { $prod = "${NS}:food/$n" }      # ① 缺省：本模组食物物品，带食物数据
elseif ($prod -match ':') { $external = $true } # ② 含冒号：外部物品，食物数据/模型/lang 全跳过
else { $noFood = $true; $prod = "${NS}:$prod" }   # ③ 不含冒号：本模组非食物物品，要模型与 lang、无食物数据
$ownItem = (-not $external)
```

对应改四处：①食物数据 `if (-not $external -and -not $noFood)` ②产物模型 `if ($ownItem)`
③食物 lang `if ($ownItem -and -not $noFood)` ④非食物产物的 lang 用新增字段 `zhProd`/`enProd`。
`gen-tags.ps1` 的 `$noFoodCrops` 名单也要同步收录（否则报「标签引用了不存在的物品」）。

### 10.5 实施状态

* 批次 3：**已完成**（44 种，游戏内 0 错误、手册 44 株）
* 批次 4：**设计已定，尚未实施**（gen-crops.ps1 的改动因锚点匹配失败未写入，脚本保持原样）
