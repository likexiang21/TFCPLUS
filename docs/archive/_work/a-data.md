# Firmalife 数据驱动内容格式调查报告（中间材料）

- 源码根目录：`moddev/src-ref/Firmalife`
- 数据生成器源码：`Firmalife/src/data/java/com/eerussianguy/firmalife/`（`DataEntryPoint.java`、`providers/`、`recipes/`）
- 本文所有 JSON 均从仓库文件原文复制，未做任何改写或补全；路径均为相对 Firmalife 仓库根目录的相对路径。
- 本文中「已验证」指直接读取了文件原文；「未能核实」指仓库内不存在该文件或该文件无法读取，并已注明检查位置。

---

## 0. 结论速览

1. Firmalife 的数据共分布在 **5 个命名空间**：`firmalife`、`tfc`、`c`、`minecraft`、`neoforge`。
2. Firmalife 自定义数据驱动注册表（DataManager）只有 **2 个**：`firmalife:greenhouse`（GreenhouseType）与 `firmalife:plantable`（Plantable），它们通过 `FLDataManagers.init()` 注册进 TFC 的 `DataManagers.MANAGERS` 注册表。
3. Firmalife 向 TFC 的 DataManager 体系注入数据，写入 `data/firmalife/tfc/<manager>/...`，共 8 个 TFC DataManager 目录被补充。
4. Firmalife 自定义配方类型共 **10 个**（`drying`、`smoking`、`stomping`、`mixing_bowl`、`oven`、`stinky_soup`、`bowl_pot`、`vat`、`press`、`centrifuge`）；其中 `press` 在 datagen 中**没有任何 JSON 实例**。
5. Firmalife 通过 `BuiltinRecipes.remove(...)` 用 `{"neoforge:conditions":[{"type":"neoforge:false"}]}` 这种「空配方」占位文件来**删除 TFC 原版配方**，这是最容易被忽略的机制。

---

## 1. 命名空间与目录总清单

### 1.1 `src/generated/resources/data` 下的命名空间

```
data/
├── c/            （NeoForge/通用惯例标签命名空间）
├── firmalife/    （本模组）
├── minecraft/    （原版）
├── neoforge/     （NeoForge）
└── tfc/          （TerraFirmaCraft，被 Firmalife 覆盖/补充）
```

### 1.2 `data/firmalife/**` 目录清单（generated）

| 目录 | 归属 | Java 端 Codec/管理器类 | 生成者 |
|---|---|---|---|
| `data/firmalife/advancement/story/*` | 原版 registry（advancement） | 原版 `Advancement` | **手工文件**（位于 `src/main/resources`，非 datagen，见 1.4） |
| `data/firmalife/damage_type/*` | 原版 registry（`minecraft:damage_type`） | 原版 `DamageType` | `BuiltinDamageTypes`（经 `DatapackBuiltinEntriesProvider`） |
| `data/firmalife/firmalife/greenhouse/*` | **Firmalife 自定义 DataManager** `firmalife:greenhouse` | `com.eerussianguy.firmalife.common.util.GreenhouseType` | `DataEntryPoint` 内匿名 `DataManagerProvider<GreenhouseType>` |
| `data/firmalife/firmalife/plantable/*` | **Firmalife 自定义 DataManager** `firmalife:plantable` | `common.util.Plantable` | `BuiltinPlantables` |
| `data/firmalife/loot_modifiers/*` | NeoForge 全局战利品修改器 | `neoforge:add_table` / `firmalife:add_item` | `BuiltinLootModifiers` |
| `data/firmalife/loot_table/blocks/*` | 原版 registry（loot_table） | 原版 `LootTable` | `BuiltinBlockLootTables` + `BuiltinBlockLootTables.PartialProvider` |
| `data/firmalife/recipe/**` | 原版配方 registry（`minecraft:recipe`） | 见第 4 章 | `BuiltinRecipes` |
| `data/firmalife/tags/{block,entity_type,fluid,item}/**` | 原版 tag registry | `TagsProvider<Block/EntityType/Fluid/Item>` | `BuiltinBlockTags`、`BuiltinEntityTypeTags`、`BuiltinFluidTags`、`BuiltinItemTags` |
| `data/firmalife/tags/tfc/food_trait/*` | **TFC 自定义 registry** `tfc:food_trait` 的标签 | `net.dries007.tfc.common.component.food.FoodTraits.KEY` | `DataEntryPoint` 内匿名 `TagsProvider<FoodTrait>` |
| `data/firmalife/tfc/climate_range/**` | **TFC DataManager** `tfc:climate_range` | `net.dries007.tfc.util.climate.ClimateRange` | `BuiltinClimateRanges` |
| `data/firmalife/tfc/drinkable/*` | **TFC DataManager** `tfc:drinkable` | `net.dries007.tfc.util.data.Drinkable` | `DataEntryPoint` 内匿名 `DataManagerProvider<Drinkable>` |
| `data/firmalife/tfc/fluid_heat/*` | **TFC DataManager** `tfc:fluid_heat` | `net.dries007.tfc.util.data.FluidHeat` | `BuiltinFluidHeats` |
| `data/firmalife/tfc/food/**` | **TFC DataManager** `tfc:food` | `net.dries007.tfc.common.component.food.FoodDefinition`（`FoodCapability.MANAGER`） | `BuiltinFoods` |
| `data/firmalife/tfc/item_heat/**` | **TFC DataManager** `tfc:item_heat` | `net.dries007.tfc.common.component.heat.HeatDefinition`（`HeatCapability.MANAGER`） | `BuiltinItemHeat` |
| `data/firmalife/tfc/item_size/*` | **TFC DataManager** `tfc:item_size` | `net.dries007.tfc.common.component.size.ItemSizeDefinition`（`ItemSizeManager.MANAGER`） | `BuiltinItemSizes` |
| `data/firmalife/tfc/knapping_type/*` | **TFC DataManager** `tfc:knapping_type` | `net.dries007.tfc.util.data.KnappingType` | `DataEntryPoint` 内匿名 `DataManagerProvider<KnappingType>` |
| `data/firmalife/tfc/lamp_fuel/*` | **TFC DataManager** `tfc:lamp_fuel` | `net.dries007.tfc.util.data.LampFuel` | `DataEntryPoint` 内匿名 `DataManagerProvider<LampFuel>` |

> 关于「`firmalife/tfc/<name>` 这种双层命名空间」的原因：`providers/DataManagerProvider.java` 第 37 行
> `output.createPathProvider(PackOutput.Target.DATA_PACK, domain + "/" + manager.getName())`，
> 其中 `domain` 是 `TerraFirmaCraft.MOD_ID`（即 `tfc`）或 `FirmaLife.MOD_ID`（即 `firmalife`），
> 而 `manager.getName()` 是 TFC `DataManager` 的完整 id（含命名空间，如 `tfc:climate_range`）。
> 路径因此成为 `data/<domain>/tfc/<子目录>/`。当 `domain == "firmalife"` 时就是 `data/firmalife/tfc/...`。
> 同理，Firmalife 自己的 manager（`firmalife:greenhouse`、`firmalife:plantable`）配合 `domain=MOD_ID`，
> 得到 `data/firmalife/firmalife/<name>/`。

### 1.3 对照：TFC 自身 jar 内同类目录（用于确认这些是 TFC 的 DataManager）

来源：`moddev/inventory/TFC.resources.txt`（TFC jar 资源清单），TFC 内存有：

```
data/tfc/tfc/climate_range/   data/tfc/tfc/drinkable/      data/tfc/tfc/entity_damage_resistance/
data/tfc/tfc/deposit/         data/tfc/tfc/fauna/          data/tfc/tfc/fertilizer/
data/tfc/tfc/fluid_heat/      data/tfc/tfc/food/           data/tfc/tfc/fuel/
data/tfc/tfc/item_damage_resistance/  data/tfc/tfc/item_heat/  data/tfc/tfc/item_size/
data/tfc/tfc/knapping_type/   data/tfc/tfc/lamp_fuel/      data/tfc/tfc/support/
data/tfc/tfc/worldgen/
```

Firmalife 只补充了其中 8 个（climate_range、drinkable、fluid_heat、food、item_heat、item_size、knapping_type、lamp_fuel）。

### 1.4 `src/main/resources/data/**` 目录清单（手工维护，非 datagen）

| 路径 | 说明 |
|---|---|
| `src/main/resources/data/firmalife/advancement/story/*.json` | 手工进度文件（37 个，含 `root.json`） |
| `src/main/resources/data/firmalife/worldgen/configured_feature/**` | 手工体素/植被特征，子目录 `plant/`、`vein/` |
| `src/main/resources/data/firmalife/worldgen/placed_feature/**` | 手工放置特征，子目录 `plant/`、`vein/` |
| `src/main/resources/data/tfc/tags/worldgen/placed_feature/feature/*.json` | 向 TFC 世界生成标签注入 Firmalife 特征 |
| `src/main/resources/data/tfc/tags/worldgen/placed_feature/in_biome/*.json` | 同上（按生物群系类别） |

### 1.5 `data/tfc/**` 下被 Firmalife 覆盖或补充的目录

| 目录 | 归属类型 | 内容 |
|---|---|---|
| `data/tfc/recipe/barrel/*.json`、`data/tfc/recipe/barrel/food/*.json` | **原版配方 registry**，但写进 `tfc` 命名空间 | **删除占位**（见第 4.10） |
| `data/tfc/recipe/crafting/*.json` | 同上 | **删除占位** |
| `data/tfc/recipe/heating/food/*.json` | 同上 | **删除占位** |
| `data/tfc/tags/block/**`、`data/tfc/tags/fluid/**`、`data/tfc/tags/item/**` | 原版 tag registry | 向 TFC 标签追加 Firmalife 条目 |
| `data/tfc/tags/worldgen/placed_feature/**`（main） | 原版 tag registry | 向 TFC 世界生成标签追加 Firmalife 放置特征 |

> 说明：`data/tfc/recipe/...` 里**没有** Firmalife 新增的可用配方，只有「禁用」占位文件。
> Firmalife 自己新增的 TFC 配方类型（alloy/anvil/barrel_*/chisel/collapse/casting/heating/knapping/loom/welding/quern 等）
> 全部写在 `data/firmalife/recipe/<type>/...`，因为配方 id 的命名空间由生成时传入的 id 决定
> （`BuiltinRecipes.add` 用 `FLHelpers.identifier(...)`，即 `firmalife:` 命名空间）。

### 1.6 `data/c/**` 与 `data/minecraft/**`

| 目录 | 归属 | 说明 |
|---|---|---|
| `data/c/tags/block/ores/*`、`data/c/tags/block/ores/chromite.json` | 通用标签 | 铬矿石 |
| `data/c/tags/fluid/molten_chromium.json`、`molten_stainless_steel.json` | 通用标签 | 熔融金属 |
| `data/c/tags/item/{ingots,double_ingots,sheets,double_sheets,rods}/{chromium,stainless_steel}.json` | 通用标签 | 金属件 |
| `data/c/tags/item/foods/{fruit,dairy,dough,raw_meat,cooked_meat}.json`、`item/leathers.json`、`item/strings.json` | 通用标签 | 食物与材料 |
| `data/minecraft/tags/block/**`（climbable/doors/leaves/replaceable/slabs/stairs/stone_bricks/trapdoors/walls/flower_pots/mineable/*） | 原版标签 | |
| `data/minecraft/tags/item/doors.json` | 原版标签 | |
| `data/minecraft/tags/damage_type/bypasses_armor.json`、`bypasses_effects.json` | 原版标签 | 由 `DataEntryPoint` 中针对 `Registries.DAMAGE_TYPE` 的匿名 `TagsProvider` 生成 |
| `data/neoforge/loot_modifiers/global_loot_modifiers.json` | NeoForge | 全局战利品修改器索引 |

> 观察结论（推导，非文件原文）：vanilla registry 的标签被写入 `data/minecraft/tags/...`，
> 而 TFC 自定义 registry（`tfc:food_trait`）的标签被写入 `data/firmalife/tags/tfc/food_trait/...`。
> 两个 provider 都是在 `DataEntryPoint` 里用同一个 `tags(...)` 辅助方法创建的，唯一区别是 registry key。

---

## 2. Firmalife 自定义 DataManager 详解

### 2.1 注册入口

`src/main/java/com/eerussianguy/firmalife/common/util/FLDataManagers.java`：

```java
public class FLDataManagers
{
    public static void init()
    {
        register(GreenhouseType.MANAGER);
        register(Plantable.MANAGER);
    }

    private static void register(DataManager<?> manager)
    {
        DataManagers.MANAGERS.register(manager.getName(), () -> manager);
    }
}
```

`DataManagers` 与 `DataManager` 均来自 TFC（`net.dries007.tfc.util.data`）。
据 `moddev/inventory/api-dump/TFC-public-api.txt` 第 365–385 行，`DataManager<T>` 的公共 API 为：

```
public class net.dries007.tfc.util.data.DataManager<T> extends net.minecraft.server.packs.resources.SimpleJsonResourceReloadListener {
  public DataManager(ResourceLocation, Codec<T>);
  public DataManager(ResourceLocation, Codec<T>, StreamCodec<RegistryFriendlyByteBuf, T>);
  public T get(ResourceLocation);
  public Map<ResourceLocation, T> getElements();
  public final String getName();
  ...
}
```

即：**DataManager 就是「资源路径 + Codec」的一层封装，本质是 `SimpleJsonResourceReloadListener`**。

### 2.2 `firmalife/greenhouse/*` —— GreenhouseType

Java 定义：`src/main/java/com/eerussianguy/firmalife/common/util/GreenhouseType.java`

```java
public record GreenhouseType(BlockIngredient ingredient, int tier, Component translationKey)
{
    public static final Codec<GreenhouseType> CODEC = RecordCodecBuilder.create(instance -> instance.group(
        BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        Codecs.POSITIVE_INT.fieldOf("tier").forGetter(c -> c.tier),
        ComponentSerialization.CODEC.fieldOf("translation_key").forGetter(c -> c.translationKey)
    ).apply(instance, GreenhouseType::new));

    public static final DataManager<GreenhouseType> MANAGER = new DataManager<>(FLHelpers.identifier("greenhouse"), CODEC, STREAM_CODEC);
    public static final IndirectHashCollection<Block, GreenhouseType> CACHE = IndirectHashCollection.create(s -> s.ingredient.blocks(), MANAGER::getValues);
}
```

生成位置：`src/data/java/com/eerussianguy/firmalife/DataEntryPoint.java` 第 118–128 行，匿名 `DataManagerProvider<GreenhouseType>`，`domain = MOD_ID`（`firmalife`）。

**真实示例** —— `src/generated/resources/data/firmalife/firmalife/greenhouse/iron.json` 全文：

```json
{
  "ingredient": "#firmalife:all_iron_greenhouse",
  "tier": 15,
  "translation_key": {
    "translate": "greenhouse.firmalife.iron"
  }
}
```

**真实示例** —— `src/generated/resources/data/firmalife/firmalife/greenhouse/copper.json` 全文：

```json
{
  "ingredient": "#firmalife:all_copper_greenhouse",
  "tier": 10,
  "translation_key": {
    "translate": "greenhouse.firmalife.copper"
  }
}
```

**字段解释**

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredient` | `BlockIngredient`（字符串=`#tag` 或 block id，或 TFC 块成分对象） | 是（`fieldOf`） | 无 | 构成该温室等级的方块集合。代码用 `IndirectHashCollection<Block, GreenhouseType>` 做快速反查 |
| `tier` | 正整数（`Codecs.POSITIVE_INT`） | 是（`fieldOf`） | 无 | 温室等级数值。`DataEntryPoint` 中：treated_wood=5、copper=10、iron=15、stainless_steel=20 |
| `translation_key` | `Component`（`ComponentSerialization.CODEC`） | 是（`fieldOf`） | 无 | 显示名，JSON 里写作 `{"translate": "..."}`；也可用 `{"text": "..."}` 等其它 Component 形式 |

**同目录全部文件（4 个）**：`treated_wood.json`、`copper.json`、`iron.json`、`stainless_steel.json`。

### 2.3 `firmalife/plantable/*` —— Plantable

Java 定义：`src/main/java/com/eerussianguy/firmalife/common/util/Plantable.java`

```java
public record Plantable(Ingredient ingredient, PlanterType planter, int tier, int stages, float extraSeedChance, ItemStack seed, ItemStack crop, NutrientList nutrient, List<ResourceLocation> textures, List<ResourceLocation> specials)
{
    public static final Codec<Plantable> CODEC = RecordCodecBuilder.create(i -> i.group(
        Ingredient.CODEC_NONEMPTY.fieldOf("ingredient").forGetter(c -> c.ingredient),
        PlanterType.CODEC.fieldOf("planter").forGetter(c -> c.planter),
        Codecs.POSITIVE_INT.optionalFieldOf("tier", 0).forGetter(c -> c.tier),
        Codecs.POSITIVE_INT.optionalFieldOf("stages", 0).forGetter(c -> c.stages),
        Codecs.POSITIVE_FLOAT.optionalFieldOf("extra_seed_chance", 0.5f).forGetter(c -> c.extraSeedChance),
        ItemStack.CODEC.fieldOf("seed").forGetter(c -> c.seed),
        ItemStack.CODEC.fieldOf("crop").forGetter(c -> c.crop),
        NUTRIENT_LIST_CODEC.fieldOf("nutrient").forGetter(c -> c.nutrient),
        ResourceLocation.CODEC.listOf().fieldOf("textures").forGetter(c -> c.textures),
        ResourceLocation.CODEC.listOf().fieldOf("specials").forGetter(c -> c.specials)
    ).apply(i, Plantable::new));
}
```

生成位置：`providers/BuiltinPlantables.java`（`super(Plantable.MANAGER, output, lookup, FirmaLife.MOD_ID)`）。

**真实示例** —— `src/generated/resources/data/firmalife/firmalife/plantable/wheat.json` 全文：

```json
{
  "crop": {
    "count": 1,
    "id": "tfc:food/wheat"
  },
  "ingredient": {
    "item": "tfc:seeds/wheat"
  },
  "nutrient": {
    "nitrogen": 1.0,
    "phosphorous": -0.3,
    "potassium": -0.3
  },
  "planter": "large",
  "seed": {
    "count": 1,
    "id": "tfc:seeds/wheat"
  },
  "specials": [],
  "stages": 7,
  "textures": [
    "tfc:block/crop/wheat_0",
    "tfc:block/crop/wheat_1",
    "tfc:block/crop/wheat_2",
    "tfc:block/crop/wheat_3",
    "tfc:block/crop/wheat_4",
    "tfc:block/crop/wheat_5",
    "tfc:block/crop/wheat_6",
    "tfc:block/crop/wheat_7"
  ],
  "tier": 10
}
```

**真实示例（含可选字段与 specials）** —— `src/generated/resources/data/firmalife/firmalife/plantable/banana.json` 全文：

```json
{
  "crop": {
    "count": 1,
    "id": "tfc:food/banana"
  },
  "extra_seed_chance": 0.08,
  "ingredient": {
    "item": "tfc:plant/banana_sapling"
  },
  "nutrient": {
    "nitrogen": 0.25,
    "phosphorous": 0.3,
    "potassium": 0.3
  },
  "planter": "hanging",
  "seed": {
    "count": 1,
    "id": "tfc:plant/banana_sapling"
  },
  "specials": [
    "firmalife:block/crop/banana_fruit"
  ],
  "stages": 4,
  "textures": [
    "firmalife:block/crop/banana_0",
    "firmalife:block/crop/banana_1",
    "firmalife:block/crop/banana_2",
    "firmalife:block/crop/banana_3",
    "firmalife:block/crop/banana_4"
  ],
  "tier": 15
}
```

**字段解释**

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredient` | `Ingredient`（`CODEC_NONEMPTY`，不可为空） | 是 | 无 | 可种入的物品（种子） |
| `planter` | `PlanterType` 枚举（JSON 为字符串） | 是 | 无 | 允许的种植盆类型。示例值：`large`、`hanging`（代码中还有 `quad`、`trellis`、`bonsai`、`hydroponic` 等，取决于 `PlanterType` 枚举） |
| `tier` | 正整数 | 否 | `0` | 等级门槛 |
| `stages` | 正整数 | 否 | `0` | 生长阶段数；`getTexture(float growth)` 用它把生长度映射到纹理索引 |
| `extra_seed_chance` | 正浮点 | 否 | `0.5` | 额外获得种子的概率 |
| `seed` | `ItemStack` | 是 | 无 | 收获时返还的种子 |
| `crop` | `ItemStack` | 是 | 无 | 收获产物；代码里 `getCrop()` 会调用 `FoodCapability.setCreatedNow(...)` 使其「刚制作」 |
| `nutrient` | 对象，三个 float 字段 `nitrogen`/`phosphorous`/`potassium` | 是 | 无 | 营养消耗/恢复值。负值表示恢复（见 `formatNutrientAmount`），正值表示消耗 |
| `textures` | `ResourceLocation` 数组 | 是 | 无 | 生长纹理列表。若长度为 2，用「未成熟/成熟」两段式；否则按 `growth * stages` 索引 |
| `specials` | `ResourceLocation` 数组 | 是（可为空数组） | 无 | 特殊纹理（如挂果贴图），用 `getSpecialTexture(id)` 取 |

**同目录文件**：63 个作物文件（alfalfa、banana、barley、basil、bay_laurel、beet、blackberry、blueberry、bunchberry、cabbage、canola、cardamom、carrot、cassava、cherry、cilantro、cloudberry、cocoa、cranberry、cumin、elderberry、fig、garlic、gooseberry、green_apple、green_bean、jute、lemon、lentil、maize、melon、nightshade、oat、olive、onion、orange、oregano、papyrus、peach、peanut、pimento、pineapple、plum、potato、pumpkin、radish、raspberry、red_apple、red_bell_pepper、red_grapes、rice、rye、snowberry、soybean、squash、strawberry、sugarcane、tomato、vanilla、wheat、white_grapes、wintergreen_berry、yellow_bell_pepper）。

---

## 3. Firmalife 自定义配方类型（`common/recipes/`）

### 3.0 类型、序列化器一览

`src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeSerializers.java`：

```java
public static final Id<DryingRecipe>     DRYING      = register("drying",      DryingRecipe.CODEC,     DryingRecipe.STREAM_CODEC);
public static final Id<SmokingRecipe>    SMOKING     = register("smoking",     SmokingRecipe.CODEC,    SmokingRecipe.STREAM_CODEC);
public static final Id<StompingRecipe>   STOMPING    = register("stomping",    StompingRecipe.CODEC,   StompingRecipe.STREAM_CODEC);
public static final Id<MixingBowlRecipe> MIXING_BOWL = register("mixing_bowl", MixingBowlRecipe.CODEC, MixingBowlRecipe.STREAM_CODEC);
public static final Id<OvenRecipe>       OVEN        = register("oven",        OvenRecipe.CODEC,       OvenRecipe.STREAM_CODEC);
public static final Id<StinkySoupRecipe> STINKY_SOUP = register("stinky_soup", StinkySoupRecipe.CODEC, StinkySoupRecipe.STREAM_CODEC);
public static final Id<BowlPotRecipe>    BOWL_POT    = register("bowl_pot",    BowlPotRecipe.CODEC,    BowlPotRecipe.STREAM_CODEC);
public static final Id<VatRecipe>        VAT         = register("vat",         VatRecipe.CODEC,        VatRecipe.STREAM_CODEC);
public static final Id<PressRecipe>      PRESS       = register("press",       PressRecipe.P_CODEC,    PressRecipe.P_STREAM_CODEC);
public static final Id<CentrifugeRecipe> CENTRIFUGE  = register("centrifuge",  CentrifugeRecipe.CODEC, CentrifugeRecipe.STREAM_CODEC);
```

因此 JSON 中 `"type"` 的合法取值是：`firmalife:drying`、`firmalife:smoking`、`firmalife:stomping`、
`firmalife:mixing_bowl`、`firmalife:oven`、`firmalife:stinky_soup`、`firmalife:bowl_pot`、
`firmalife:vat`、`firmalife:press`、`firmalife:centrifuge`。

### 3.1 `drying`（`firmalife/recipe/drying/**`）

`DryingRecipe` 继承 TFC 的 `ItemRecipe`，字段仅两个：

```java
public static final MapCodec<DryingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, DryingRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/drying/dry_fruits.json` 全文：

```json
{
  "type": "firmalife:drying",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      {
        "tag": "c:foods/fruit"
      },
      {
        "type": "tfc:not_rotten"
      },
      {
        "type": "tfc:lacks_trait",
        "trait": "firmalife:dried"
      }
    ]
  },
  "result": {
    "modifiers": [
      {
        "type": "tfc:copy_input"
      },
      {
        "type": "tfc:add_trait",
        "trait": "firmalife:dried"
      }
    ]
  }
}
```

**真实示例（简单形态）** —— `src/generated/resources/data/firmalife/recipe/drying/spice/vanilla.json` 全文：

```json
{
  "type": "firmalife:drying",
  "ingredient": {
    "item": "firmalife:plant/vanilla"
  },
  "result": {
    "count": 1,
    "id": "firmalife:spice/vanilla"
  }
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `type` | 字符串 | 是 | 无 | 固定 `firmalife:drying` |
| `ingredient` | TFC `Ingredient`（支持 `tfc:and`、`tfc:not_rotten`、`tfc:lacks_trait`、`tfc:has_trait` 等自定义成分类型） | 是 | 无 | 输入物品 |
| `result` | `ItemStackProvider`（`{id,count}` 或 `{stack:{...}, modifiers:[...]}`） | 是 | 无 | 输出。`modifiers` 可取 `tfc:copy_input`、`tfc:add_trait`、`tfc:copy_food`、`firmalife:copy_dynamic_food`、`firmalife:empty_pan`、`firmalife:add_pie_pan`、`firmalife:copy_bowl` 等 |

**目录文件（16 个）**：`drying/dry_fruits.json`、`drying/pineapple_fiber.json`、`drying/dirt/{alfisol,andisol,aridisol,entisol,fluvisol,mollisol,oxisol,podzol}.json`、`drying/food/{dark_chocolate,dehydrated_soybeans,milk_chocolate,tofu,white_chocolate}.json`、`drying/spice/vanilla.json`。

### 3.2 `smoking`（`firmalife/recipe/smoking/**`）

`SmokingRecipe` 同样继承 `ItemRecipe`，字段与 `drying` 完全一致（`ingredient` + `result`）。

**真实示例** —— `src/generated/resources/data/firmalife/recipe/smoking/smoke_meats.json` 全文：

```json
{
  "type": "firmalife:smoking",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      {
        "type": "tfc:and",
        "children": [
          {
            "tag": "c:foods/raw_meat"
          },
          {
            "type": "tfc:lacks_trait",
            "trait": "firmalife:smoked"
          }
        ]
      },
      {
        "type": "tfc:not_rotten"
      },
      {
        "type": "tfc:has_trait",
        "trait": "tfc:brined"
      }
    ]
  },
  "result": {
    "modifiers": [
      {
        "type": "tfc:copy_input"
      },
      {
        "type": "tfc:add_trait",
        "trait": "firmalife:smoked"
      }
    ]
  }
}
```

字段含义与 3.1 完全相同，仅 `type` 变化。**目录仅 2 个文件**：`smoking/smoke_cheeses.json`、`smoking/smoke_meats.json`。

### 3.3 `mixing_bowl`（`firmalife/recipe/mixing_bowl/**`）

```java
public static final MapCodec<MixingBowlRecipe> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
    Ingredient.CODEC.listOf().fieldOf("item_ingredients").forGetter(c -> c.itemIngredients),
    SizedFluidIngredient.FLAT_CODEC.optionalFieldOf("fluid_ingredients").forGetter(c -> c.fluidIngredient),
    ItemStack.CODEC.optionalFieldOf("result_item", ItemStack.EMPTY).forGetter(c -> c.resultItem),
    FluidStack.CODEC.optionalFieldOf("result_fluid", FluidStack.EMPTY).forGetter(c -> c.resultFluid)
).apply(instance, MixingBowlRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/mixing_bowl/food/butter.json` 全文：

```json
{
  "type": "firmalife:mixing_bowl",
  "fluid_ingredients": {
    "amount": 1000,
    "fluid": "firmalife:cream"
  },
  "item_ingredients": [
    {
      "item": "tfc:powder/salt"
    }
  ],
  "result_item": {
    "count": 1,
    "id": "firmalife:food/butter"
  }
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `item_ingredients` | `Ingredient` 数组 | 是 | 无 | 物品原料列表；匹配用 `Helpers.perfectMatchExists`，要求与搅拌碗内物品**完全对应** |
| `fluid_ingredients` | `SizedFluidIngredient`（`{amount, fluid}` 或 `{amount, tag}`） | 否（`optionalFieldOf`） | 空 `Optional` | 所需流体；JSON 里写作单数形式（`FLAT_CODEC` 的扁平形态），代码注释提示使用 `FluidIngredient.empty()` 的形态无法序列化 |
| `result_item` | `ItemStack` | 否 | `ItemStack.EMPTY` | 产物物品。构造时调用 `FoodCapability.setNonDecaying(resultItem)` 使其不腐烂 |
| `result_fluid` | `FluidStack` | 否 | `FluidStack.EMPTY` | 产物流体 |

**目录文件（15 个）**：均在 `mixing_bowl/food/` 下（butter、chocolate_chip_cookie_dough、chocolate_ice_cream、cookie_dough、dark_chocolate_blend、hardtack_dough、milk_chocolate_blend、pie_dough、pizza_dough、pumpkin_pie_dough、raw_egg_noodles、raw_rice_noodles、strawberry_ice_cream、vanilla_ice_cream、white_chocolate_blend）。

### 3.4 `oven`（`firmalife/recipe/oven/**`）

```java
public static final MapCodec<OvenRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.outputItem),
    Codec.FLOAT.fieldOf("temperature").forGetter(c -> c.temperature),
    Codecs.POSITIVE_INT.fieldOf("duration").forGetter(c -> c.duration)
).apply(i, OvenRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/oven/food/wheat_bread.json` 全文：

```json
{
  "type": "firmalife:oven",
  "duration": 1000,
  "ingredient": {
    "type": "tfc:and",
    "children": [
      {
        "item": "firmalife:food/wheat_dough"
      },
      {
        "type": "tfc:not_rotten"
      }
    ]
  },
  "result": {
    "count": 1,
    "id": "tfc:food/wheat_bread"
  },
  "temperature": 200.0
}
```

**真实示例（带 modifier）** —— `src/generated/resources/data/firmalife/recipe/oven/cook_pie.json` 全文：

```json
{
  "type": "firmalife:oven",
  "duration": 1000,
  "ingredient": {
    "type": "tfc:and",
    "children": [
      {
        "item": "firmalife:food/filled_pie"
      },
      {
        "type": "tfc:not_rotten"
      }
    ]
  },
  "result": {
    "modifiers": [
      {
        "type": "firmalife:copy_dynamic_food"
      }
    ],
    "stack": {
      "count": 1,
      "id": "firmalife:food/cooked_pie"
    }
  },
  "temperature": 400.0
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredient` | `Ingredient` | 是 | 无 | 输入 |
| `result` | `ItemStackProvider` | 是 | 无 | 输出；注意当使用 `modifiers` 时，物品写在 **`stack`** 子字段而不是直接写 `id` |
| `temperature` | float | 是 | 无 | 所需最低温度（`isValidTemperature` 为 `t >= 该值`）。输出物会继承输入的当前温度 |
| `duration` | 正整数 | 是 | 无 | 烘烤耗时（tick）。代码 `WrappedHeatingRecipe.of(OvenRecipe)` 用它作为时长；TFC 加热配方在无 oven 时固定 `20*50 = 1000` tick |

**目录文件（15 个）**：`oven/cook_pie.json`、`oven/cook_pizza.json`、`oven/cook_pumpkin_pie.json`、`oven/food/{barley_bread,chocolate_chip_cookie,cooked_lasagna,hardtack,maize_bread,oat_bread,rice_bread,roasted_cocoa_beans,rye_bread,sugar_cookie,taco_shell,wheat_bread}.json`。

### 3.5 `vat`（`firmalife/recipe/vat/**`）

```java
public static final MapCodec<VatRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedIngredient.FLAT_CODEC.fieldOf("input_item").forGetter(c -> c.inputItem),
    SizedFluidIngredient.FLAT_CODEC.fieldOf("input_fluid").forGetter(c -> c.inputFluid),
    ItemStackProvider.CODEC.optionalFieldOf("output_item").forGetter(c -> c.outputItem),
    FluidStack.OPTIONAL_CODEC.optionalFieldOf("output_fluid").forGetter(c -> c.outputFluid),
    Codecs.POSITIVE_INT.fieldOf("length").forGetter(c -> c.length),
    Codec.FLOAT.fieldOf("temperature").forGetter(c -> c.temperature),
    ItemStack.OPTIONAL_CODEC.optionalFieldOf("jar_output").forGetter(c -> c.jarOutput),
    ResourceLocation.CODEC.optionalFieldOf("output_texture").forGetter(c -> c.outputTexture)
).apply(i, VatRecipe::new));
```

**真实示例（最简，仅流体输出）** —— `src/generated/resources/data/firmalife/recipe/vat/lye.json` 全文：

```json
{
  "type": "firmalife:vat",
  "input_fluid": {
    "amount": 200,
    "fluid": "minecraft:water"
  },
  "input_item": {
    "count": 1,
    "item": "tfc:powder/wood_ash"
  },
  "length": 600,
  "output_fluid": {
    "amount": 200,
    "id": "tfc:lye"
  },
  "temperature": 300.0
}
```

**真实示例（带 `jar_output` 与 `output_texture`）** —— `src/generated/resources/data/firmalife/recipe/vat/jar/banana.json` 全文：

```json
{
  "type": "firmalife:vat",
  "input_fluid": {
    "amount": 500,
    "fluid": "firmalife:sugar_water"
  },
  "input_item": {
    "type": "tfc:and",
    "children": [
      {
        "item": "tfc:food/banana"
      },
      {
        "type": "tfc:lacks_trait",
        "trait": "firmalife:dried"
      },
      {
        "type": "tfc:not_rotten"
      }
    ],
    "count": 1
  },
  "jar_output": {
    "count": 1,
    "id": "tfc:jar/banana"
  },
  "length": 600,
  "output_texture": "tfc:block/jar/banana",
  "temperature": 300.0
}
```

**真实示例（物品输出）** —— `src/generated/resources/data/firmalife/recipe/vat/food/cooked_rice.json` 全文：

```json
{
  "type": "firmalife:vat",
  "input_fluid": {
    "amount": 200,
    "fluid": "minecraft:water"
  },
  "input_item": {
    "type": "tfc:and",
    "children": [
      {
        "item": "tfc:food/rice_grain"
      },
      {
        "type": "tfc:not_rotten"
      }
    ],
    "count": 1
  },
  "length": 600,
  "output_item": {
    "count": 1,
    "id": "tfc:food/cooked_rice"
  },
  "temperature": 300.0
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `input_item` | `SizedIngredient`（`{item\|tag, count}`） | 是 | 无 | 输入物品及数量；`count == 0` 表示只按流体匹配 |
| `input_fluid` | `SizedFluidIngredient`（`{fluid\|tag, amount}`） | 是 | 无 | 输入流体及数量；`amount == 0` 表示只按物品匹配 |
| `output_item` | `ItemStackProvider` | 否 | 空 `Optional`（代码注释说明是因为 `ItemStackProvider.empty()` 无法编码） | 输出物品 |
| `output_fluid` | `FluidStack`（`{id, amount}`） | 否 | 空 `Optional` | 输出流体。若无输出流体，多余输入会被保留而不是销毁 |
| `length` | 正整数 | 是 | 无 | 处理时长（tick） |
| `temperature` | float | 是 | 无 | 所需最低温度 |
| `jar_output` | `ItemStack` | 否 | 空 | 玻璃罐产物，会被 `vat.setOutput(...)` 记录 |
| `output_texture` | `ResourceLocation` | 否 | 空 | 罐内流体/内容物的显示纹理 |

**目录文件（52 个）**：根下 21 个染料与材料（black_dye…yellow_dye、lye、olive_oil_water、sugar、sugar_water、tallow）、`vat/food/` 5 个（boiled_egg、cooked_rice、cured_maize、soy_mixture、tomato_sauce）、`vat/jar/` 26 个水果罐。

### 3.6 `stomping`（`firmalife/recipe/stomping/**`）

```java
public static final MapCodec<StompingRecipe> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    ResourceLocation.CODEC.fieldOf("input_texture").forGetter(c -> c.inputTexture),
    ResourceLocation.CODEC.fieldOf("output_texture").forGetter(c -> c.outputTexture),
    BuiltInRegistries.SOUND_EVENT.byNameCodec().fieldOf("sound").forGetter(c -> c.sound)
).apply(instance, StompingRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/stomping/food/smashed_red_grapes.json` 全文：

```json
{
  "type": "firmalife:stomping",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      {
        "item": "firmalife:food/red_grapes"
      },
      {
        "type": "tfc:not_rotten"
      },
      {
        "type": "tfc:lacks_trait",
        "trait": "firmalife:dried"
      }
    ]
  },
  "input_texture": "firmalife:block/red_unsmashed_grapes",
  "output_texture": "firmalife:block/red_smashed_grapes",
  "result": {
    "count": 1,
    "id": "firmalife:food/smashed_red_grapes"
  },
  "sound": "minecraft:entity.slime.squish"
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredient` | `Ingredient` | 是 | 无 | 输入 |
| `result` | `ItemStackProvider` | 是 | 无 | 输出 |
| `input_texture` | `ResourceLocation` | 是 | 无 | 踩踏前桶内显示纹理 |
| `output_texture` | `ResourceLocation` | 是 | 无 | 踩踏后桶内显示纹理 |
| `sound` | 音效 id（`BuiltInRegistries.SOUND_EVENT`） | 是 | 无 | 踩踏音效 |

**目录文件（4 个）**：`stomping/food/smashed_red_grapes.json`、`stomping/food/smashed_white_grapes.json`、`stomping/food/soybean_paste.json`、`stomping/powder/charcoal.json`。

### 3.7 `press` —— **未生成任何 JSON**

- Java 端已注册类型与序列化器：`FLRecipeSerializers.PRESS = register("press", PressRecipe.P_CODEC, PressRecipe.P_STREAM_CODEC)`，`FLRecipeTypes.PRESS = register("press")`。
- `PressRecipe extends StompingRecipe`，其 `P_CODEC` 的字段与 `stomping` **完全一致**（`ingredient`、`result`、`input_texture`、`output_texture`、`sound`），仅 `getType()` 返回 `firmalife:press`。
- **但 datagen 没有生成任何 `firmalife:press` 配方**：
  - `src/data/java/com/eerussianguy/firmalife/recipes/` 下**不存在** `PressRecipes.java`；
  - `BuiltinRecipes.java` 的 `implements` 列表与 `buildRecipes()` 调用列表中**没有**任何 press 相关方法；
  - `src/generated/resources/data/firmalife/recipe/press/` 目录**不存在**；
  - 对 `src/generated/resources/data/firmalife/recipe/**` 全文搜索 `"type": "firmalife:press` **无任何匹配**；
  - 对 `src/**` 搜索 `PressRecipe`，仅出现在 `PressRecipe.java`、`FLRecipeTypes.java`、`FLRecipeSerializers.java`、`FLJEIPlugin.java`、`PressCategory.java`（JEI 类别）。
- 结论：`press` 配方格式可从 Java codec 推断（与 `stomping` 相同），但**仓库内不存在真实 JSON 示例，无法给出原文**；本项标记为 **未能核实（无实例）**。检查位置如上列 5 处。

### 3.8 `centrifuge`（`firmalife/recipe/centrifuge/**`）

```java
public static final MapCodec<CentrifugeRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, CentrifugeRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/centrifuge/sugar.json` 全文：

```json
{
  "type": "firmalife:centrifuge",
  "ingredient": {
    "item": "firmalife:sugared_beehive_frame"
  },
  "result": {
    "count": 1,
    "id": "minecraft:sugar"
  }
}
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/centrifuge/food/raw_honey.json` 全文：

```json
{
  "type": "firmalife:centrifuge",
  "ingredient": {
    "item": "firmalife:scraped_beehive_frame"
  },
  "result": {
    "count": 1,
    "id": "firmalife:food/raw_honey"
  }
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredient` | `Ingredient` | 是 | 无 | 输入（蜂框类物品） |
| `result` | `ItemStackProvider` | 是 | 无 | 输出 |

### 3.9 `stinky_soup`（锅输出，`firmalife/recipe/pot/stinky_*.json`）

```java
public static final MapCodec<StinkySoupRecipe> CODEC = PotRecipe.CODEC.xmap(StinkySoupRecipe::new, Function.identity());
```

即 `stinky_soup` **没有自己的额外字段**，完全复用 TFC `PotRecipe.CODEC`（字段：`ingredients`、`fluid_ingredient`、`duration`、`temperature`）。
输出物由 Java 端动态计算：把锅内前若干个食物原料合成一份「臭汤」，份数为 `ingredientCount / 2 + 1`，营养按 `1 - 0.05 * ingredientCount` 衰减。

**真实示例** —— `src/generated/resources/data/firmalife/recipe/pot/stinky_3.json` 全文：

```json
{
  "type": "firmalife:stinky_soup",
  "duration": 1000,
  "fluid_ingredient": {
    "amount": 100,
    "fluid": "minecraft:water"
  },
  "ingredients": [
    {
      "type": "tfc:and",
      "children": [
        {
          "tag": "tfc:usable_in_soup"
        },
        {
          "type": "tfc:not_rotten"
        }
      ]
    },
    {
      "type": "tfc:and",
      "children": [
        {
          "tag": "tfc:usable_in_soup"
        },
        {
          "type": "tfc:not_rotten"
        }
      ]
    },
    {
      "type": "tfc:and",
      "children": [
        {
          "tag": "tfc:usable_in_soup"
        },
        {
          "type": "tfc:not_rotten"
        }
      ]
    },
    {
      "item": "firmalife:food/nightshade_berry"
    }
  ],
  "temperature": 300.0
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `ingredients` | `Ingredient` 数组 | 是 | 无 | 锅内原料；最后一个固定为夜影浆果（`stinky_3` 为 3 份 `tfc:usable_in_soup` + 1 个浆果） |
| `fluid_ingredient` | `SizedFluidIngredient` | 是 | 无 | 所需流体 |
| `duration` | 整数 | 是 | 无 | 时长。`PotRecipes.java` 中为 `550 + 150 * i`，即 i=3 → 1000，i=4 → 1150 |
| `temperature` | float | 是 | 无 | 所需温度，示例 300.0 |

**目录文件（2 个）**：`pot/stinky_3.json`、`pot/stinky_4.json`。

### 3.10 `bowl_pot`（锅输出，`firmalife/recipe/pot/food/*`）

```java
public static final MapCodec<BowlPotRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    PotRecipe.CODEC.forGetter(c -> c),
    ItemStack.CODEC.fieldOf("item_output").forGetter(c -> c.itemOutput),
    FoodData.CODEC.fieldOf("food").forGetter(c -> c.food)
).apply(i, BowlPotRecipe::new));
```

**真实示例** —— `src/generated/resources/data/firmalife/recipe/pot/food/cooked_pasta_1.json` 全文：

```json
{
  "type": "firmalife:bowl_pot",
  "duration": 2000,
  "fluid_ingredient": {
    "amount": 100,
    "fluid": "minecraft:water"
  },
  "food": {
    "decay_modifier": 3.0,
    "grain": 1.5,
    "hunger": 4,
    "saturation": 2.0
  },
  "ingredients": [
    {
      "type": "tfc:and",
      "children": [
        {
          "item": "firmalife:food/raw_egg_noodles"
        },
        {
          "type": "tfc:not_rotten"
        }
      ]
    }
  ],
  "item_output": {
    "count": 1,
    "id": "firmalife:food/cooked_pasta"
  },
  "temperature": 300.0
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| （TFC `PotRecipe` 全部字段内联）`ingredients` / `fluid_ingredient` / `duration` / `temperature` | 同上 | 是 | 无 | 由于 `PotRecipe.CODEC.forGetter(c -> c)` 是**平铺**嵌套，这些字段与 `item_output`、`food` 处于**同一层**，不是子对象 |
| `item_output` | `ItemStack` | 是 | 无 | 碗装产物；构造时 `FoodCapability.setNonDecaying(itemOutput)` |
| `food` | `FoodData`（`hunger`、`saturation`、`water`、`decay_modifier`、各营养字段） | 是 | 无 | 动态食物数据，`FoodCapability.setFoodForDynamicItemOnCreate(item, food)` 注入 |

**目录文件（17 个）**：`pot/food/{cooked_pasta_1..4, cooked_rice_noodles_1..4, cured_maize_1..4, flavorful_cooked_rice_1..3, soy_mixture_2, tomato_sauce_5}.json`。

> 注意：同一目录下还有其它**不是** firmalife 自定义类型、而是 TFC 类型的文件，用于注入 TFC 锅配方体系，例如
> `pot/sugar_2.json`、`pot/jam_*_canning_*.json` 使用 `"type": "tfc:pot"`（由 `SimplePotRecipe` 生成，见 `PotRecipes.java`）。
> 示例：`src/generated/resources/data/firmalife/recipe/pot/jam_fig_canning_2.json` 的 `"type"` 为 `tfc:pot`，
> `item_output` 数组元素仅含 `modifiers`（`tfc:copy_input` + `tfc:add_trait` / `trait: tfc:canned`），靠复制输入产生「装罐」产物。

---

## 4. Firmalife 使用的 TFC 数据目录

以下示例均为 `data/firmalife/tfc/**`（即 Firmalife 向 TFC DataManager 注入），并附 TFC 端 Codec 类。

### 4.1 `tfc/climate_range/plant/*`

Codec 类：`net.dries007.tfc.util.climate.ClimateRange`（`api-dump/TFC-public-api.txt` 第 1040–1053 行，含 `CODEC`、`MANAGER`、`NOOP`）。
Firmalife 端引用：`common/util/FLClimateRanges.java`，注册名形如 `plant/<tree>_tree`、`plant/<bush>_bush`、`plant/grapes`。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/climate_range/plant/fig_tree.json` 全文：

```json
{
  "max_hydration": 43,
  "max_temperature": 35.0,
  "min_hydration": 25,
  "min_temperature": 20.0
}
```

**真实示例（全部字段可省略）** —— `src/generated/resources/data/firmalife/tfc/climate_range/plant/grapes.json` 全文：

```json
{
  "max_temperature": 50.0,
  "min_temperature": 0.0
}
```

| 字段 | 类型 | 必需 | 默认值（TFC `ClimateRange.NOOP` 语义） | 含义 |
|---|---|---|---|---|
| `min_temperature` | int | 否 | 不限制 | 最低适生温度 |
| `max_temperature` | int | 否 | 不限制 | 最高适生温度 |
| `min_hydration` | int | 否 | 不限制 | 最低适生湿度 |
| `max_hydration` | int | 否 | 不限制 | 最高适生湿度 |

> 默认值的准确数值未能核实：TFC 源码工作区未 checkout（`moddev/src-ref/TerraFirmaCraft` 下只有 `.git`，且 `git --git-dir=... log` 报 `fatal: your current branch appears to be broken`），`api-dump` 只输出签名不输出常量值。

**目录文件（5 个）**：`cocoa_tree.json`、`fig_tree.json`、`grapes.json`、`nightshade_bush.json`、`pineapple_bush.json`。

### 4.2 `tfc/food/*`

Codec 类：`net.dries007.tfc.common.component.food.FoodDefinition`（`FoodCapability.MANAGER`）。
生成者：`providers/BuiltinFoods.java`，`super(FoodCapability.MANAGER, output, lookup, TerraFirmaCraft.MOD_ID)`。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/food/butter.json` 全文：

```json
{
  "decay_modifier": 3.0,
  "hunger": 4,
  "ingredient": {
    "item": "firmalife:food/butter"
  }
}
```

**真实示例（标签 + 营养）** —— `src/generated/resources/data/firmalife/tfc/food/aged_cheeses.json` 全文：

```json
{
  "dairy": 3.0,
  "decay_modifier": 2.0,
  "hunger": 4,
  "ingredient": {
    "tag": "firmalife:foods/aged_cheeses"
  },
  "saturation": 0.3
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `ingredient` | `Ingredient`（示例中有 `item` 与 `tag` 两种形态） | 是 | 目标物品 |
| `hunger` | int | 是 | 饥饿回复 |
| `saturation` | float | 否 | 饱和度 |
| `water` | float | 否 | 水分 |
| `decay_modifier` | float | 否 | 腐烂速度倍率 |
| `grain` / `fruit` / `vegetables` / `protein` / `dairy` | float | 否 | 五类营养 |

（生成源 `BuiltinFoods.java` 使用 `FoodData.of(...)`、`ofFood(...)` 及 `.grain()/.fruit()/.dairy()` 等链式方法，例如
`add(FLFood.BACON, ofFood(2f, 0f, 0f).protein(0.5f))`、`add(FLTags.Items.AGED_CHEESES, ofFood(0.3f, 0f, 2f).dairy(3f), true)`，
其中第三个参数 `edible` 会写入 `FoodDefinition` 的第 3 个字段。）

**目录文件（88 个）**：涵盖 aged_cheeses、bacon、banana_split、bread_slices、butter、chocolate、dough 系列、ice cream 系列、jam/酱料系列、tofu、yak_curd 等。

### 4.3 `tfc/drinkable/*`

Codec 类：`net.dries007.tfc.util.data.Drinkable`（`api-dump/TFC-public-api.txt` 第 450–466 行）。
生成者：`DataEntryPoint.java` 第 110–117 行匿名 provider。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/drinkable/chocolate.json` 全文：

```json
{
  "ingredient": {
    "fluid": "firmalife:chocolate"
  },
  "water": 10.0
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `ingredient` | `FluidIngredient`（示例为 `{fluid: ...}`，也支持 tag） | 是 | 可饮流体 |
| `water` | float（`FoodData` 的水分） | 是 | 补水值 |
| `consume_chance` | float | 否 | 消耗概率（构造参数第 2 位，源码中传 0） |
| `may_drink_when_full` | boolean | 否 | 饱食时是否可饮（源码中传 `false`） |
| 营养字段 / `effects` | 对象/数组 | 否 | 源码中传 `List.of()`，无效果 |

### 4.4 `tfc/fluid_heat/*`

Codec 类：`net.dries007.tfc.util.data.FluidHeat`（第 564–575 行）。
生成者：`providers/BuiltinFluidHeats.java`，`super(FluidHeat.MANAGER, output, lookup, TerraFirmaCraft.MOD_ID)`。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/fluid_heat/stainless_steel.json` 全文：

```json
{
  "fluid": "firmalife:metal/stainless_steel",
  "melt_temperature": 1540.0,
  "specific_heat_capacity": 0.008571429
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `fluid` | 流体 id | 是 | 目标流体 |
| `melt_temperature` | float | 是 | 熔化温度。`Accessors.temperatureOf(...)` 通过 `FluidHeat.MANAGER.getOrThrow(...).meltTemperature()` 取用 |
| `specific_heat_capacity` | float | 是 | 比热容 |

**目录文件（2 个）**：`chromium.json`、`stainless_steel.json`。

### 4.5 `tfc/item_heat/**`

Codec 类：`net.dries007.tfc.common.component.heat.HeatDefinition`（`HeatCapability.MANAGER`）。
生成者：`providers/BuiltinItemHeat.java`，`super(HeatCapability.MANAGER, output, lookup, TerraFirmaCraft.MOD_ID)`。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/item_heat/stainless_steel/ingot.json` 全文：

```json
{
  "forging_temperature": 924.00006,
  "heat_capacity": 2.857143,
  "ingredient": {
    "item": "firmalife:metal/ingot/stainless_steel"
  },
  "welding_temperature": 1232.0
}
```

**真实示例（只有热容，无锻造/焊接温度）** —— `src/generated/resources/data/firmalife/tfc/item_heat/food/bacon.json` 全文：

```json
{
  "heat_capacity": 1.0,
  "ingredient": {
    "item": "firmalife:food/bacon"
  }
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `ingredient` | `Ingredient` | 是 | 目标物品 |
| `heat_capacity` | float | 是 | 热容（`BuiltinItemHeat` 里由金属 units 计算；食物统一为 `1`） |
| `forging_temperature` | float | 否 | 可锻造温度（金属件专属） |
| `welding_temperature` | float | 否 | 可焊接温度（金属件专属） |

**目录结构**：根下 3 个（copper_pipe、oxidized_copper_pipe、stainless_steel_jar_lid），
`chromium/` 与 `stainless_steel/` 各 8 个（block、block_slab、block_stairs、double_ingot、double_sheet、ingot、rod、sheet），
`food/` 16 个，`ore/` 4 个（normal/poor/rich/small_chromite）。

### 4.6 `tfc/item_size/*`

Codec 类：`net.dries007.tfc.common.component.size.ItemSizeDefinition`（`ItemSizeManager.MANAGER`）。
生成者：`providers/BuiltinItemSizes.java`。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/item_size/empty_jar.json` 全文：

```json
{
  "ingredient": {
    "item": "firmalife:empty_jar_with_stainless_steel_lid"
  },
  "size": "tiny",
  "weight": "medium"
}
```

**真实示例（标签形态）** —— `src/generated/resources/data/firmalife/tfc/item_size/dynamic_foods.json` 全文：

```json
{
  "ingredient": {
    "tag": "firmalife:foods/dynamic_foods"
  },
  "size": "very_small",
  "weight": "very_heavy"
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `ingredient` | `Ingredient` | 是 | 目标物品 |
| `size` | 枚举字符串（`Size`） | 是 | 尺寸。示例：`tiny`、`very_small`、`normal`、`very_large`（枚举定义自 `net.dries007.tfc.common.component.size.Size`） |
| `weight` | 枚举字符串（`Weight`） | 是 | 重量。示例：`medium`、`heavy`、`very_heavy` |

**目录文件（8 个）**：beehive_frame、cheese_wheels、dynamic_foods、empty_jar、empty_wine、kegs、peel、wine。

### 4.7 `tfc/knapping_type/*`

Codec 类：`net.dries007.tfc.util.data.KnappingType`（第 428–449 行）。
生成者：`DataEntryPoint.java` 第 129–139 行匿名 provider。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/knapping_type/pumpkin.json` 全文：

```json
{
  "click_sound": "tfc:item.knapping.leather",
  "consume_after_complete": false,
  "has_off_texture": false,
  "icon": {
    "count": 1,
    "id": "tfc:pumpkin"
  },
  "input": {
    "type": "tfc:and",
    "children": [
      {
        "tag": "firmalife:pumpkin_knapping"
      },
      {
        "type": "tfc:not_rotten"
      }
    ],
    "count": 1
  },
  "spawns_particles": false
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `input` | `SizedIngredient` | 是 | 敲击输入（示例中为 `tfc:and` 组合 + `count`） |
| `click_sound` | 音效 id | 是 | 敲击音效 |
| `consume_after_complete` | boolean | 是 | 完成后是否消耗输入 |
| `has_off_texture` | boolean | 是 | 是否有「未选中」贴图 |
| `spawns_particles` | boolean | 是 | 是否生成粒子 |
| `icon` | `ItemStack` | 是 | JEI/界面图标 |
| `amount_to_consume` | int | 否 | 消耗数量（TFC 构造器有 `Optional<Integer>` 重载） |

### 4.8 `tfc/lamp_fuel/*`

Codec 类：`net.dries007.tfc.util.data.LampFuel`（第 548–556 行）。
生成者：`DataEntryPoint.java` 第 101–109 行匿名 provider。

**真实示例** —— `src/generated/resources/data/firmalife/tfc/lamp_fuel/soybean_oil.json` 全文：

```json
{
  "burn_rate": 7000,
  "fluid": {
    "fluid": "firmalife:soybean_oil"
  },
  "lamps": "#tfc:lamps"
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `fluid` | `FluidIngredient` | 是 | 燃料流体 |
| `lamps` | `BlockIngredient`（示例为 `#tfc:lamps`） | 是 | 可用灯具方块 |
| `burn_rate` | int | 是 | 燃烧速率/时长（源码传 7000） |

### 4.9 `firmalife/tags/tfc/food_trait/*`（TFC 自定义 registry 的标签，注意不在 `data/firmalife/tfc/` 下）

生成者：`DataEntryPoint.java` 第 92–94 行：

```java
tags(event, FoodTraits.KEY, lookup, (provider, tags) -> {
    tags.tag(FLTags.Traits.WINE).add(FLFoodTraits.BEE_POLLINATED.getKey(), FLFoodTraits.GRAVEL_GROWN.getKey(), FLFoodTraits.DIRT_GROWN.getKey(), FLFoodTraits.SLOPE_GROWN.getKey());
});
```

**真实示例** —— `src/generated/resources/data/firmalife/tags/tfc/food_trait/wine.json` 全文：

```json
{
  "values": [
    "firmalife:bee_pollinated",
    "firmalife:gravel_grown",
    "firmalife:dirt_grown",
    "firmalife:slope_grown"
  ]
}
```

注意：这是**标签**（tag），不是 DataManager 数据；TFC 的 `FoodTrait` 本身是 registry 注册项（`FLFoodTraits.java` 用独立的 `DeferredRegister<FoodTrait>` 注册，以取得正确的 `firmalife:` 命名空间）。

### 4.10 `data/tfc/recipe/**` —— 配方「删除占位」

`BuiltinRecipes.java`：

```java
final Codec<Unit> emptyRecipeCodec = Codec.STRING.fieldOf("type")
    .codec()
    .listOf()
    .fieldOf("neoforge:conditions")
    .xmap(l -> Unit.INSTANCE, r -> List.of("neoforge:false"))
    .codec();
...
CompletableFuture.allOf(removedRecipes.stream()
    .map(id -> DataProvider.saveStable(output, lookup, emptyRecipeCodec, Unit.INSTANCE, recipePathProvider.json(id)))
    .toArray(CompletableFuture[]::new))
```

调用点：
- `recipes/BarrelRecipes.java` 第 25–27 行：`remove("barrel/curdled_milk", "barrel/food/cheese", "barrel/milk_vinegar");`
- `recipes/CraftingRecipes.java` 第 52 行：`remove("crafting/pumpkin_pie");`
- `recipes/HeatingRecipes.java` 第 35–40 行：`remove("heating/food/wheat_bread")` 等 6 个面包配方

`recipes/Recipes.java` 接口的 `add` 实现（`BuiltinRecipes.add`）用 `output.accept(FLHelpers.identifier((prefix + "/" + name).toLowerCase(Locale.ROOT)), recipe, null)`，
而 `remove` 收的是**带命名空间的完整 id**（`Helpers.identifier(name)`），因此删除目标落在 `tfc` 命名空间。

**真实示例** —— `src/generated/resources/data/tfc/recipe/heating/food/wheat_bread.json` 全文：

```json
{
  "neoforge:conditions": [
    {
      "type": "neoforge:false"
    }
  ]
}
```

**真实示例** —— `src/generated/resources/data/tfc/recipe/barrel/curdled_milk.json` 全文：

```json
{
  "neoforge:conditions": [
    {
      "type": "neoforge:false"
    }
  ]
}
```

**真实示例** —— `src/generated/resources/data/tfc/recipe/crafting/pumpkin_pie.json` 全文：

```json
{
  "neoforge:conditions": [
    {
      "type": "neoforge:false"
    }
  ]
}
```

**`data/tfc/recipe/**` 全部文件（10 个）**：
`barrel/curdled_milk.json`、`barrel/milk_vinegar.json`、`barrel/food/cheese.json`、
`crafting/pumpkin_pie.json`、`heating/food/{barley_bread,maize_bread,oat_bread,rice_bread,rye_bread,wheat_bread}.json`。

> 机制说明：`neoforge:false` 条件恒为假，配方加载时被 NeoForge 丢弃，等效于「删除」；
> 由于 datapack 是覆盖式的，Firmalife 用同 id 的空配方覆盖掉 TFC 的同名配方。

---

## 5. `loot_modifiers`

### 5.1 `data/firmalife/loot_modifiers/*.json`

生成者：`providers/BuiltinLootModifiers.java`（`extends GlobalLootModifierProvider`，`super(output, lookup, FirmaLife.MOD_ID)`）。

**真实示例（`firmalife:add_item`，自定义修改器）** —— `src/generated/resources/data/firmalife/loot_modifiers/rennet.json` 全文：

```json
{
  "type": "firmalife:add_item",
  "conditions": [
    {
      "condition": "minecraft:entity_properties",
      "entity": "this",
      "predicate": {
        "type": "#firmalife:drops_rennet"
      }
    }
  ],
  "item": {
    "count": 4,
    "id": "firmalife:rennet"
  }
}
```

**真实示例（`neoforge:add_table`）** —— `src/generated/resources/data/firmalife/loot_modifiers/ice_shavings.json` 全文：

```json
{
  "type": "neoforge:add_table",
  "conditions": [
    {
      "condition": "neoforge:loot_table_id",
      "loot_table_id": "minecraft:blocks/ice"
    }
  ],
  "table": "firmalife:blocks/ice_shavings"
}
```

**真实示例（树叶附加战利品表）** —— `src/generated/resources/data/firmalife/loot_modifiers/cherry_leaves.json` 全文：

```json
{
  "type": "neoforge:add_table",
  "conditions": [
    {
      "condition": "neoforge:loot_table_id",
      "loot_table_id": "tfc:blocks/plant/cherry_leaves"
    }
  ],
  "table": "firmalife:blocks/fruit_leaves"
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `type` | 字符串 | 是 | `neoforge:add_table`（追加整张战利品表）或 `firmalife:add_item`（自定义，见 `common/misc/AddItemModifier`） |
| `conditions` | 数组 | 是 | 触发条件。`neoforge:loot_table_id` 匹配原表 id；`minecraft:entity_properties` 匹配实体类型标签 |
| `table` | 战利品表 id | `add_table` 时必需 | 追加的表 |
| `item` | `ItemStack` | `add_item` 时必需 | 追加的物品 |
| `chance` | float | 否 | 概率（源码 `dropEntity(..., 1f)` 传 1f） |

**目录文件（11 个）**：`cherry_leaves`、`green_apple_leaves`、`ice_shavings`、`lemon_leaves`、`more_rennet`、`olive_leaves`、`orange_leaves`、`peach_leaves`、`plum_leaves`、`red_apple_leaves`、`rennet`。

### 5.2 `data/neoforge/loot_modifiers/global_loot_modifiers.json`

**全文** —— `src/generated/resources/data/neoforge/loot_modifiers/global_loot_modifiers.json`：

```json
{
  "entries": [
    "firmalife:cherry_leaves",
    "firmalife:green_apple_leaves",
    "firmalife:lemon_leaves",
    "firmalife:olive_leaves",
    "firmalife:orange_leaves",
    "firmalife:peach_leaves",
    "firmalife:plum_leaves",
    "firmalife:red_apple_leaves",
    "firmalife:ice_shavings",
    "firmalife:rennet",
    "firmalife:more_rennet"
  ],
  "replace": false
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `entries` | 字符串数组 | 是 | 要启用的修改器 id 列表（指向上面的 `firmalife/loot_modifiers/*`） |
| `replace` | boolean | 是 | 是否替换而非追加（`false` 表示与其它模组共存） |

---

## 6. `damage_type`

生成者：`providers/BuiltinDamageTypes.java`，经 `DataEntryPoint` 中的 `DatapackBuiltinEntriesProvider` 与 `RegistrySetBuilder().add(Registries.DAMAGE_TYPE, BuiltinDamageTypes::new)`，命名空间集合为 `Set.of(MOD_ID, TerraFirmaCraft.MOD_ID, "minecraft")`。

```java
register(FLDamageTypes.OVEN, 0.1f, DamageEffects.BURNING);
register(FLDamageTypes.SWARM, 0.1f, DamageEffects.HURT);
...
context.register(type, new DamageType(type.location().getNamespace() + "." + type.location().getPath(),
    DamageScaling.WHEN_CAUSED_BY_LIVING_NON_PLAYER, exhaustion, effects, DeathMessageType.DEFAULT));
```

**真实示例** —— `src/generated/resources/data/firmalife/damage_type/oven.json` 全文：

```json
{
  "effects": "burning",
  "exhaustion": 0.1,
  "message_id": "firmalife.oven",
  "scaling": "when_caused_by_living_non_player"
}
```

**真实示例（无 effects 字段）** —— `src/generated/resources/data/firmalife/damage_type/swarm.json` 全文：

```json
{
  "exhaustion": 0.1,
  "message_id": "firmalife.swarm",
  "scaling": "when_caused_by_living_non_player"
}
```

| 字段 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|
| `message_id` | 字符串 | 是 | 无 | 死亡消息翻译键前缀 |
| `scaling` | 枚举 | 是 | 无 | 伤害缩放方式；本模组固定 `when_caused_by_living_non_player`（对应 `DamageScaling.WHEN_CAUSED_BY_LIVING_NON_PLAYER`） |
| `exhaustion` | float | 是 | 无 | 造成的饥饿消耗；本模组均为 `0.1` |
| `effects` | 枚举 | 否 | `hurt`（原版默认） | 伤害效果；`oven` 为 `burning`，`swarm` 未写（即默认 `hurt`，对应源码 `DamageEffects.HURT`） |
| `death_message_type` | 枚举 | 否 | `default` | 源码固定 `DeathMessageType.DEFAULT`，未写入 JSON |

相关标签示例 —— `src/generated/resources/data/minecraft/tags/damage_type/bypasses_armor.json` 全文：

```json
{
  "values": [
    "firmalife:oven",
    "firmalife:swarm"
  ]
}
```

---

## 7. `worldgen`（configured_feature / placed_feature）

这些文件位于 `src/main/resources`（**手工维护**，文件内带 `"__comment__": "This file was automatically created by mcresources"`，
说明最初由 mcresources 工具生成后手工调整），命名空间为 `firmalife`。

### 7.1 configured_feature

**真实示例（植被，`minecraft:simple_block`）** —— `src/main/resources/data/firmalife/worldgen/configured_feature/plant/vanilla.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "type": "minecraft:simple_block",
  "config": {
    "to_place": {
      "type": "minecraft:simple_state_provider",
      "state": {
        "Name": "firmalife:plant/vanilla"
      }
    }
  }
}
```

**真实示例（TFC 自定义类型 `firmalife:fruit_trees`）** —— `src/main/resources/data/firmalife/worldgen/configured_feature/plant/cocoa.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "type": "firmalife:fruit_trees",
  "config": {
    "state": "firmalife:plant/cocoa_growing_branch"
  }
}
```

**真实示例（矿脉 `tfc:cluster_vein`，节选不改写）** —— `src/main/resources/data/firmalife/worldgen/configured_feature/vein/normal_chromite.json` 前 30 行：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "type": "tfc:cluster_vein",
  "config": {
    "rarity": 50,
    "density": 0.25,
    "min_y": 40,
    "max_y": 130,
    "size": 8,
    "random_name": "normal_chromite",
    "blocks": [
      {
        "replace": [
          "tfc:rock/raw/rhyolite"
        ],
        "with": [
          {
            "weight": 70,
            "block": "firmalife:ore/poor_chromite/rhyolite"
          },
          {
            "weight": 25,
            "block": "firmalife:ore/normal_chromite/rhyolite"
          },
          {
            "weight": 5,
            "block": "firmalife:ore/rich_chromite/rhyolite"
          }
        ]
      }
    ],
    "indicator": {
      "rarity": 14,
      "depth": 35,
      "underground_rarity": 1,
      "underground_count": 0,
      "blocks": [
        {
          "block": "firmalife:ore/small_chromite"
        }
      ]
    }
  }
}
```

（该文件实际共 215 行，`blocks` 数组包含 rhyolite、basalt、andesite、dacite、quartzite、slate、phyllite、schist、gneiss、marble 共 10 种母岩，每种的 poor/normal/rich 权重固定为 70/25/5。上例为原样节选，未改动任何字段。）

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `type` | 字符串 | 是 | 特征类型：`minecraft:simple_block`、`firmalife:fruit_trees`、`tfc:cluster_vein` 等 |
| `config` | 对象 | 是 | 与该类型匹配的配置对象 |
| `__comment__` | 字符串 | 否 | mcresources 工具留下的注释，游戏忽略 |

`tfc:cluster_vein` 的 `config` 子字段：`rarity`（稀有度）、`density`（密度）、`min_y`/`max_y`（高度范围）、`size`（尺寸）、`random_name`（随机名）、`blocks[]`（`{replace:[...], with:[{weight, block}]}`）、`indicator`（地面指示物，含 `rarity`/`depth`/`underground_rarity`/`underground_count`/`blocks[]`）。

### 7.2 placed_feature

**真实示例（植被）** —— `src/main/resources/data/firmalife/worldgen/placed_feature/plant/vanilla.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "feature": "firmalife:plant/vanilla",
  "placement": [
    {
      "type": "minecraft:heightmap",
      "heightmap": "WORLD_SURFACE_WG"
    },
    {
      "type": "block_predicate_filter",
      "predicate": {
        "type": "tfc:replaceable"
      }
    },
    {
      "type": "block_predicate_filter",
      "predicate": {
        "type": "would_survive",
        "state": {
          "Name": "firmalife:plant/vanilla"
        }
      }
    }
  ]
}
```

**真实示例（矿脉，`placement` 为空）** —— `src/main/resources/data/firmalife/worldgen/placed_feature/vein/normal_chromite.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "feature": "firmalife:vein/normal_chromite",
  "placement": []
}
```

| 字段 | 类型 | 必需 | 含义 |
|---|---|---|---|
| `feature` | 特征 id | 是 | 指向 configured_feature |
| `placement` | 修饰器数组 | 是（可为空数组） | 放置修饰器，如 `minecraft:heightmap`、`block_predicate_filter`（可用 TFC 谓词 `tfc:replaceable`、`would_survive`） |

**目录内容**：`configured_feature/` 与 `placed_feature/` 各含根下 7 个（beehive、hollow_shell、hollow_shell_patch、wild_red_grapes、wild_red_grapes_patch、wild_white_grapes、wild_white_grapes_patch）、
`plant/` 下 22 个（含 `_patch` 变体）、`vein/` 下 2 个（`deep_chromite`、`normal_chromite`）。

### 7.3 注入 TFC 世界生成标签

**真实示例** —— `src/main/resources/data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "replace": false,
  "values": [
    "firmalife:plant/cocoa",
    "firmalife:plant/fig"
  ]
}
```

**真实示例** —— `src/main/resources/data/tfc/tags/worldgen/placed_feature/in_biome/veins.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "replace": false,
  "values": [
    "firmalife:vein/normal_chromite",
    "firmalife:vein/deep_chromite"
  ]
}
```

`replace: false` 表示**追加**到 TFC 原有列表（而不是替换）。

---

## 8. 标签（tag）命名规律与示例

### 8.1 命名规律

| 命名空间/前缀 | 规律 | 例子 |
|---|---|---|
| `firmalife:...`（方块标签） | 机器/结构功能分类，多为复数名词 | `firmalife:greenhouse`、`firmalife:planters`、`firmalife:kegs`、`firmalife:oven_blocks`、`firmalife:food_shelves` |
| `firmalife:all_<material>_greenhouse` | 温室等级聚合标签，由多个 `firmalife:<material>_greenhouse` 组合 | `all_iron_greenhouse` = `iron_greenhouse` + `rusted_iron_greenhouse` |
| `firmalife:foods/...` | 食物子类 | `firmalife:foods/dynamic_foods`、`firmalife:foods/cheeses`、`firmalife:foods/flatbreads` |
| `firmalife:usable_in_...` | 「可用于某机器」的能力标签 | `firmalife:usable_in_vat`、`firmalife:usable_in_mixing_bowl`、`firmalife:usable_in_wine_glass`、`firmalife:usable_on_oven`、`firmalife:usable_in_stovetop_soup` |
| `firmalife:ores/<ore>/<grade>` | 矿石分级 | `firmalife:ores/chromite/normal` |
| `firmalife:metal_item/<metal>` | 金属件总标签 | `firmalife:metal_item/stainless_steel` |
| `tfc:...`（Firmalife 追加） | 沿用 TFC 命名的能力/分类标签 | `tfc:foods/sweeteners`、`tfc:fruit_tree_leaves`、`tfc:can_collapse`、`tfc:mineable/glass_saw` |
| `c:...` | NeoForge 通用标签（`<类型复数>/<材料>`） | `c:ingots/stainless_steel`、`c:double_sheets/chromium`、`c:foods/fruit`、`c:ores/chromite` |
| `minecraft:...` | 原版标签 | `minecraft:mineable/pickaxe`、`minecraft:leaves`、`minecraft:damage_type/bypasses_armor` |

### 8.2 每类一个真实示例

**firmalife 方块标签（聚合引用）** —— `src/generated/resources/data/firmalife/tags/block/all_iron_greenhouse.json`：

```json
{
  "values": [
    "#firmalife:iron_greenhouse",
    "#firmalife:rusted_iron_greenhouse"
  ]
}
```

**firmalife 物品标签（用于敲击类型）** —— `src/generated/resources/data/firmalife/tags/item/pumpkin_knapping.json`：

```json
{
  "values": [
    "tfc:pumpkin"
  ]
}
```

**firmalife 流体标签** —— `src/generated/resources/data/firmalife/tags/fluid/usable_in_vat.json`：

```json
{
  "values": [
    "#tfc:usable_in_pot"
  ]
}
```

**firmalife 实体类型标签** —— `src/generated/resources/data/firmalife/tags/entity_type/drops_rennet.json`：

```json
{
  "values": [
    "tfc:goat",
    "tfc:yak"
  ]
}
```

**firmalife 矿石分级标签（多条目形态）** —— `src/generated/resources/data/firmalife/tags/block/ores/chromite/normal.json`：

```json
{
  "values": [
    "firmalife:ore/normal_chromite/granite",
    "firmalife:ore/normal_chromite/diorite",
    "firmalife:ore/normal_chromite/gabbro",
    "firmalife:ore/normal_chromite/shale",
    "firmalife:ore/normal_chromite/claystone",
    "firmalife:ore/normal_chromite/limestone",
    "firmalife:ore/normal_chromite/conglomerate",
    "firmalife:ore/normal_chromite/dolomite",
    "firmalife:ore/normal_chromite/chert",
    "firmalife:ore/normal_chromite/chalk",
    "firmalife:ore/normal_chromite/tuff",
    "firmalife:ore/normal_chromite/rhyolite",
    "firmalife:ore/normal_chromite/basalt",
    "firmalife:ore/normal_chromite/andesite",
    "firmalife:ore/normal_chromite/dacite",
    "firmalife:ore/normal_chromite/quartzite",
    "firmalife:ore/normal_chromite/slate",
    "firmalife:ore/normal_chromite/phyllite",
    "firmalife:ore/normal_chromite/schist",
    "firmalife:ore/normal_chromite/gneiss",
    "firmalife:ore/normal_chromite/marble"
  ]
}
```

**TFC 标签（Firmalife 追加条目）** —— `src/generated/resources/data/tfc/tags/item/foods/sweeteners.json`：

```json
{
  "values": [
    "firmalife:food/raw_honey"
  ]
}
```

**通用标签 `c:`** —— `src/generated/resources/data/c/tags/item/ingots/stainless_steel.json`：

```json
{
  "values": [
    "firmalife:metal/ingot/stainless_steel"
  ]
}
```

**通用流体标签** —— `src/generated/resources/data/c/tags/fluid/molten_chromium.json`：

```json
{
  "values": [
    "firmalife:metal/chromium"
  ]
}
```

**原版方块标签** —— `src/generated/resources/data/minecraft/tags/block/mineable/pickaxe.json`（存在该文件，内容为字符串数组形态）。
**原版伤害类型标签** —— `src/generated/resources/data/minecraft/tags/damage_type/bypasses_armor.json`：

```json
{
  "values": [
    "firmalife:oven",
    "firmalife:swarm"
  ]
}
```

> 标签文件的通用字段：`values`（字符串数组；`#` 前缀表示引用其它标签）、`replace`（boolean，可选，默认 `false`）。
> Firmalife 的 datagen 输出（`BuiltinBlockTags`/`BuiltinItemTags`/`BuiltinFluidTags`/`BuiltinEntityTypeTags`）**不写 `replace`**，
> 只有 `src/main/resources` 下的手工世界生成标签文件写了 `"replace": false`。

---

## 9. datagen Provider 清单

`src/data/java/com/eerussianguy/firmalife/providers/`（14 个文件）：

| Provider 类 | 实现的接口 / 基类 | 生成的目录 |
|---|---|---|
| `DataManagerProvider<T>` | `net.minecraft.data.DataProvider`（抽象基类） | 由构造参数决定：`domain + "/" + manager.getName()` |
| `BuiltinBlockLootTables` | `BlockLootSubProvider`、`Accessors`；内部类 `PartialProvider implements LootTableSubProvider` | `data/firmalife/loot_table/blocks/**` |
| `BuiltinBlockTags` | `TagsProvider<Block>`、`Accessors` | `data/firmalife/tags/block/**` |
| `BuiltinClimateRanges` | `DataManagerProvider<ClimateRange>` | `data/firmalife/tfc/climate_range/**` |
| `BuiltinDamageTypes` | 普通类（由 `RegistrySetBuilder::add` 调用） | `data/firmalife/damage_type/*`（经 `DatapackBuiltinEntriesProvider`） |
| `BuiltinEntityTypeTags` | `TagsProvider<EntityType<?>>`、`Accessors` | `data/firmalife/tags/entity_type/**` |
| `BuiltinFluidHeats` | `DataManagerProvider<FluidHeat>`、`Accessors` | `data/firmalife/tfc/fluid_heat/*` |
| `BuiltinFluidTags` | `TagsProvider<Fluid>`、`Accessors` | `data/firmalife/tags/fluid/**` |
| `BuiltinFoods` | `DataManagerProvider<FoodDefinition>`、`Accessors` | `data/firmalife/tfc/food/**` |
| `BuiltinItemHeat` | `DataManagerProvider<HeatDefinition>`、`Accessors` | `data/firmalife/tfc/item_heat/**`，并向 `BuiltinRecipes` 暴露 `meltingRecipes` |
| `BuiltinItemSizes` | `DataManagerProvider<ItemSizeDefinition>` | `data/firmalife/tfc/item_size/*` |
| `BuiltinItemTags` | `TagsProvider<Item>`、`Accessors` | `data/firmalife/tags/item/**`（在 `data/tfc`、`data/c`、`data/minecraft` 命名空间下也有输出，因为标签可以被压入其它命名空间） |
| `BuiltinLootModifiers` | `GlobalLootModifierProvider` | `data/firmalife/loot_modifiers/*` + `data/neoforge/loot_modifiers/global_loot_modifiers.json` |
| `BuiltinPlantables` | `DataManagerProvider<Plantable>` | `data/firmalife/firmalife/plantable/*` |
| `BuiltinRecipes` | `RecipeProvider` + `Recipes` + 21 个配方接口 | `data/firmalife/recipe/**` + `data/tfc/recipe/**`（删除占位） |

### 9.1 `BuiltinRecipes` 的接口组合（关键）

```java
public class BuiltinRecipes extends RecipeProvider implements Recipes,
    AlloyRecipes, AnvilRecipes, BarrelRecipes, CastingRecipes, CentrifugeRecipes, ChiselRecipes,
    CollapseRecipes, CraftingRecipes, DryingRecipes, GlassworkingRecipes, HeatingRecipes,
    KnappingRecipes, LoomRecipes, MixingBowlRecipes, OvenRecipes, PotRecipes, QuernRecipes,
    SmokingRecipes, StompingRecipes, VatRecipes, WeldingRecipes
```

### 9.2 TFC 配方目录由哪个 provider 生成（重点）

在 `BuiltinRecipes.buildRecipes(RecipeOutput)` 中按顺序调用：

| TFC 配方目录 | 生成方法 | 定义在 `recipes/` 包中的接口 | 输出目录 | 作用 |
|---|---|---|---|---|
| `tfc:alloy` | `alloyRecipes()` | `AlloyRecipes` | `data/firmalife/recipe/alloy/*` | 把不锈钢注册为合金 |
| `tfc:anvil` | `anvilRecipes()` | `AnvilRecipes` | `data/firmalife/recipe/anvil/**` | 把 Chromium/不锈钢锻打成棒、板等 |
| `tfc:barrel_instant` | `barrelRecipes()` | `BarrelRecipes` | `data/firmalife/recipe/barrel_instant/*` | 洗食物、倒瓶等即时桶配方 |
| `tfc:barrel_instant_fluid` | 同上 | `BarrelRecipes` | `data/firmalife/recipe/barrel_instant_fluid/*` | 奶 → 奶醋 |
| `tfc:barrel_sealed` | 同上 | `BarrelRecipes` | `data/firmalife/recipe/barrel_sealed/**` | 凝乳、奶酪轮、发酵等密封桶配方 |
| `tfc:casting` | `castingRecipes()` | `CastingRecipes` | `data/firmalife/recipe/casting/ceramic/{ingot_mold_metal,fire_ingot_mold_metal}/*` | 熔融金属铸锭 |
| `tfc:chisel` | `chiselRecipes()` | `ChiselRecipes` | `data/firmalife/recipe/chisel/*` | 凿刻与「清洁」风化方块 |
| `tfc:collapse` | `collapseRecipes()` | `CollapseRecipes` | `data/firmalife/recipe/collapse/rock/cobble/*` | 矿石塌落为碎石 |
| `tfc:crafting` | `craftingRecipes()` | `CraftingRecipes` | `data/firmalife/recipe/crafting/**` | 736 个工作台配方 |
| `tfc:glassworking` | `glassworkingRecipes()` | `GlassworkingRecipes` | `data/firmalife/recipe/glassworking/*` | 酒杯与酒瓶 |
| `tfc:heating` | `heatingRecipes()` | `HeatingRecipes` | `data/firmalife/recipe/heating/**` | 加热配方（含面团→面包、金属熔化） |
| `tfc:knapping` | `knappingRecipes()` | `KnappingRecipes` | `data/firmalife/recipe/knapping/**` | 打制石窑、南瓜雕刻 |
| `tfc:loom` | `loomRecipes()` | `LoomRecipes` | `data/firmalife/recipe/loom/*` | 菠萝纤维织皮 |
| `tfc:welding` | `weldingRecipes()` | `WeldingRecipes` | `data/firmalife/recipe/welding/metal/{double_ingot,double_sheet}/*` | 焊接双锭/双板 |
| `tfc:quern` | `quernRecipes()` | `QuernRecipes` | `data/firmalife/recipe/quern/**` | 手磨 |
| `tfc:pot`（TFC 锅） | `potRecipes()` 的一部分 | `PotRecipes` | `data/firmalife/recipe/pot/**` 中的 `tfc:pot` 文件 | 装罐、糖等 |
| — | `centrifugeRecipes()` | `CentrifugeRecipes` | `data/firmalife/recipe/centrifuge/**` | Firmalife 自有类型 |

此外 `BuiltinRecipes.buildRecipes` 末尾把 `BuiltinItemHeat.meltingRecipes` 转成 TFC `HeatingRecipe`：

```java
for (BuiltinItemHeat.MeltingRecipe melt : meltingRecipes)
{
    add(nameOf(melt.item()), new HeatingRecipe(
        Ingredient.of(melt.item()), ItemStackProvider.empty(),
        new FluidStack(fluidOf(melt.metal()), melt.units()), temperatureOf(melt.metal()), false));
}
```

即：**「物品热学定义（item_heat）+ 熔融温度（fluid_heat）」自动推导出 TFC 加热熔化配方**。

### 9.3 生成顺序与依赖

`DataEntryPoint.gatherData` 的顺序（有显式依赖）：

```
DatapackBuiltinEntriesProvider(damage_type)
  → BuiltinBlockTags → BuiltinItemTags（依赖 blockTags 内容）
  → BuiltinEntityTypeTags、BuiltinFluidTags
  → 匿名 TagsProvider(damage_type)、匿名 TagsProvider(food_trait)
  → BuiltinLootModifiers、BuiltinClimateRanges、BuiltinPlantables、BuiltinFoods、BuiltinItemSizes
  → 匿名 LampFuel、Drinkable、GreenhouseType、KnappingType provider
  → BuiltinFluidHeats → BuiltinItemHeat（依赖 fluidHeat）
  → BuiltinRecipes（依赖 fluidHeat + itemHeat 的 contentDone）
  → LootTableProvider(BuiltinBlockLootTables, BuiltinBlockLootTables.PartialProvider)
```

`BuiltinItemHeat` 的 `beforeRun()` 会等待 `BuiltinFluidHeats`，`BuiltinRecipes` 的构造器又等待 `BuiltinItemHeat.output()`，
因此**必须先有 fluid_heat 才能算 item_heat，进而才能生成熔化加热配方**。

---

## 10. `build.gradle.kts` 中的 data run 参数

`build.gradle.kts` 第 117–121 行：

```kotlin
register("data") {
    data()
    sourceSet = sourceSets["data"]
    programArguments.addAll("--all", "--mod", modId, "--output", file(modDataOutput).absolutePath, "--existing",  file("src/main/resources").absolutePath, "--existing-mod", "tfc")
}
```

| 参数 | 值 | 含义 |
|---|---|---|
| `--all` | — | 生成**所有** provider（不按名字过滤），即执行 `DataEntryPoint.gatherData` 中注册的全部 provider |
| `--mod` | `firmalife` | 只运行该 modid 的 datagen 事件订阅者（`@EventBusSubscriber(modid = MOD_ID)` 的 `DataEntryPoint`） |
| `--output` | `src/generated/resources`（`modDataOutput`） | 生成结果输出目录；该目录同时被 `sourceSets.main.resources.srcDir(modDataOutput)` 加入主资源集，从而打进 jar |
| `--existing` | `src/main/resources` | **已有资源目录**：让 datagen 能读到手工维护的 JSON（`advancement/story/*`、`worldgen/**`），并允许 `ExistingFileHelper` 校验引用是否存在 |
| `--existing-mod` | `tfc` | **把 `tfc` 这个 mod 当作「已存在资源」的来源一并加载**。其意义是：<br>1. 让 Firmalife 的 `TagsProvider`/`ExistingFileHelper` 能引用并校验 TFC 的方块/物品/标签/注册项（例如 `#tfc:lamps`、`tfc:ceramic/ingot_mold`）；<br>2. 让 datagen 可以生成**写入 `tfc` 命名空间**的文件（`data/tfc/recipe/**` 的删除占位、`data/tfc/tags/**` 的追加条目）；<br>3. 让 Firmalife 能读取 TFC 的 DataManager 数据（如 `FluidHeat.MANAGER`）参与计算——`BuiltinItemHeat` 中甚至会先用 `FLHelpers.fakeDataManager(FluidHeat.MANAGER, Map.of("copper", ...))` 预置一份铜的假数据，以便在没有完整 TFC 数据时也能算出 `temperatureOf(Metal.COPPER)`。 |
| `sourceSet = sourceSets["data"]` | — | datagen 使用独立的 `data` 源集（`create("data")`），其依赖里有 `"dataImplementation"(sourceSets["main"].output)` 与独立的 TFC/Patchouli 依赖 |

其它相关配置：
- `modDataOutput = "src/generated/resources"`（第 25 行）
- `sourceSets.main.resources.srcDir(modDataOutput)`（第 86 行）
- 发布时若有 `VERSION` 环境变量（非 `-indev`），会执行 `minifyJson` 压缩 `build/resources/main` 下的 JSON，并删除 `"__comment__":"This file was automatically created by mcresources"`（第 171–216 行）

---

## 11. 其它数据目录（补充）

| 目录 | 生成者 | 示例 |
|---|---|---|
| `data/firmalife/loot_table/blocks/*` | `BuiltinBlockLootTables`（`BlockLootSubProvider`）+ `PartialProvider` | 见下 |
| `data/firmalife/advancement/story/*` | 手工（`src/main/resources`） | 见下 |

**真实示例（战利品表）** —— `src/generated/resources/data/firmalife/loot_table/blocks/beehive.json` 全文：

```json
{
  "type": "minecraft:block",
  "pools": [
    {
      "bonus_rolls": 0.0,
      "conditions": [
        {
          "condition": "minecraft:survives_explosion"
        }
      ],
      "entries": [
        {
          "type": "minecraft:item",
          "name": "firmalife:beehive"
        }
      ],
      "rolls": 1.0
    }
  ],
  "random_sequence": "firmalife:blocks/beehive"
}
```

**真实示例（进度）** —— `src/main/resources/data/firmalife/advancement/story/root.json` 全文：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "criteria": {
    "in_game_condition": {
      "trigger": "minecraft:tick"
    }
  },
  "display": {
    "icon": {
      "id": "tfc:empty_jar_with_lid"
    },
    "title": {
      "translate": "firmalife.advancements.story.root.title"
    },
    "description": {
      "translate": "firmalife.advancements.story.root.description"
    },
    "frame": "task",
    "show_toast": true,
    "announce_to_chat": false,
    "hidden": false,
    "background": "firmalife:textures/block/sealed_bricks.png"
  },
  "requirements": [
    [
      "in_game_condition"
    ]
  ]
}
```

---

## 12. `data/firmalife/recipe/**` 目录与文件数总表

| 目录 | 文件数 | 对应配方 type |
|---|---|---|
| `alloy` | 1 | `tfc:alloy` |
| `anvil` | 8 | `tfc:anvil` |
| `barrel_instant` | 5 | `tfc:barrel_instant` |
| `barrel_instant_fluid` | 1 | `tfc:barrel_instant_fluid` |
| `barrel_sealed` | 22 | `tfc:barrel_sealed` |
| `casting` | 4 | `tfc:casting` |
| `centrifuge` | 3 | `firmalife:centrifuge` |
| `chisel` | 46 | `tfc:chisel` |
| `collapse` | 21 | `tfc:collapse` |
| `crafting` | 736 | `minecraft:crafting_shaped` / `crafting_shapeless` 等 |
| `drying` | 16 | `firmalife:drying` |
| `glassworking` | 5 | `tfc:glassworking` |
| `heating` | 38 | `tfc:heating` |
| `knapping` | 13 | `tfc:knapping` |
| `loom` | 1 | `tfc:loom` |
| `mixing_bowl` | 15 | `firmalife:mixing_bowl` |
| `oven` | 15 | `firmalife:oven` |
| `pot` | 50 | `firmalife:stinky_soup`、`firmalife:bowl_pot`、`tfc:pot` |
| `quern` | 7 | `tfc:quern` |
| `smoking` | 2 | `firmalife:smoking` |
| `stomping` | 4 | `firmalife:stomping` |
| `vat` | 52 | `firmalife:vat` |
| `welding` | 4 | `tfc:welding` |
| （`press`） | **0（目录不存在）** | `firmalife:press` —— 无实例 |

> 上表文件数为**递归计数**（含子目录），与第 3 章各节列出的分组一致。

---

## 13. 未能核实项

1. **TFC 侧 Java 源码**：`moddev/src-ref/TerraFirmaCraft` 下只有 `.git` 目录（工作区未 checkout），
   且 `git --git-dir=... log` 返回 `fatal: your current branch appears to be broken`，
   故**无法读取 TFC 的 Codec 字段默认值原文**。本报告中 TFC 类名、字段名与 API 均来自：
   - Firmalife 源码中的 `import` 与调用点；
   - `moddev/inventory/api-dump/TFC-public-api.txt`、`tfc-core-api.txt`、`tfc-recipes-registry.txt`（javap 风格的公共 API 转储，只有签名没有常量值）；
   - `moddev/inventory/TFC.resources.txt`（TFC jar 资源路径清单）。
   因此 `ClimateRange`、`FoodDefinition`、`Drinkable`、`HeatDefinition`、`FluidHeat`、`ItemSizeDefinition`、
   `KnappingType`、`LampFuel` 的「可选字段默认值」**未能核实**。
2. **`PressRecipe` 的真实 JSON**：如第 3.7 节所述，仓库内不存在任何 `firmalife:press` 配方文件，
   其 JSON 结构只能从 codec 推断，**无原文示例**。
3. **`PlanterType` 枚举的完整取值**：`Plantable.planter` 的类型定义在
   `common/blocks/greenhouse/PlanterType.java`（本次未逐个读取其枚举常量），
   报告中仅给出例子中出现的 `large`、`hanging`；`firmalife:planters` 等标签名暗示还有其它取值，**未能核实全部**。
4. **`c:`/`minecraft:` 标签的精确命名规范**由 `Accessors.commonTagOf(...)`（`ResourceLocation.fromNamespaceAndPath("c", name)`）
   与 `BuiltinItemTags` 的字符串常量决定；本报告只按实际生成结果归纳，未逐一读取全部生成代码，**个别标签的构造位置未能逐一核实**。
5. 报告中「目录 → provider」的映射基于 `DataEntryPoint.java` + 各 provider 构造函数的 `domain` 参数 + 实际生成目录的对照，
   未通过运行 `runData` 实测（运行 datagen 需要 Gradle + 依赖下载，本次未执行）。
