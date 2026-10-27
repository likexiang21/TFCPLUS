# TFC 的 Patchouli 集成与「配方展示页」复刻指南

> 本文回答一个具体问题：**TFC 在 Patchouli 里是怎么做出那些漂亮的配方展示页与三维多块预览的？我能否照抄？**
>
> 结论先行：**能，而且 TFC 的整套方案完全在附属模组可复刻的范围内**——
> 它没有任何私有 API，用的就是 Patchouli 公开的「模板 JSON + `patchouli:custom` 组件 + `registerMultiblock`」三件套。
>
> 依据：`moddev/src-ref/TFC-decompiled/net/dries007/tfc/compat/patchouli/**`（CFR 反编译，jar 4.2.10）
> 与 jar 内真实资源 `assets/tfc/patchouli_books/field_guide/en_us/templates/*.json`。
> Patchouli 自身的格式与 API 详见 `40-patchouli-api.md`。

---

## 1. TFC 书籍的目录布局（实测于 jar 4.2.10）

```
data/tfc/patchouli_books/field_guide/book.json                 ← 书籍定义（唯一一个 data 侧文件）
assets/tfc/patchouli_books/field_guide/
    en_us/categories/*.json     8 个
    en_us/entries/**/*.json    89 个
    en_us/templates/*.json     13 个            ← 自定义展示页全部在这里
    ja_jp/ ko_kr/ pt_br/ ru_ru/ tr_tr/ uk_ua/
    zh_cn/ zh_hk/ zh_tw/       每种语言各 8 categories + 89 entries
```

`book.json` 原文（4.2.10）：

```json
{"name":"tfc.field_guide.book_name",
 "landing_text":"tfc.field_guide.book_landing_text",
 "subtitle":"4.2.10",
 "dont_generate_book":false,
 "show_progress":false,
 "macros":{},
 "use_resource_pack":true}
```

要点：`use_resource_pack: true` 是**必须的**（data 侧的书籍要读取 assets 侧内容时）；`subtitle` 直接写成了版本号。

**语言规则（附属模组最容易踩的坑）**：Patchouli 只在 `en_us` 目录里「发现」文件，
其它语言目录只能**覆盖** `en_us` 中已存在的同名文件。TFC 为 10 种语言都完整复制了 89 个 entry，
正是因为这个限制。**只写 `zh_cn` 而不写 `en_us` 的条目永远不会出现在书里。**

---

## 2. 多块结构：`PatchouliIntegration` 完整剖析

### 2.1 注册入口

`net.dries007.tfc.compat.patchouli.PatchouliIntegration.registerMultiBlocks()`
（由主类 `TerraFirmaCraft.setup(FMLCommonSetupEvent)` **在 `enqueueWork` 之外**直接调用）：

```java
public static void registerMultiBlocks() {
    registerMultiblock("bloomery",         PatchouliIntegration::bloomery);
    registerMultiblock("blast_furnace",    api -> blastFurnace(api, false));
    registerMultiblock("full_blast_furnace", api -> blastFurnace(api, true));
    registerMultiblock("rock_anvil",       PatchouliIntegration::rockAnvil);
    registerMultiblock("charcoal_forge",   PatchouliIntegration::charcoalForge);
    registerMultiblock("channel_casting",  PatchouliIntegration::channelCasting);
    registerMultiblock("windmill",         PatchouliIntegration::windmill);
    registerMultiblock("water_wheel",      PatchouliIntegration::waterWheel);
    registerMultiblock("clutch_off",       api -> clutch(api, false));
    registerMultiblock("clutch_on",        api -> clutch(api, true));
    registerMultiblock("crankshaft",       PatchouliIntegration::crankshaft);
    registerMultiblock("rotating_quern",   PatchouliIntegration::rotatingQuern);
}

private static void registerMultiblock(String name, Function<PatchouliAPI.IPatchouliAPI, IMultiblock> factory) {
    PatchouliAPI.IPatchouliAPI api = PatchouliAPI.get();
    api.registerMultiblock(Helpers.identifier(name), factory.apply(api));   // → tfc:<name>
}
```

**资源位置**：注册的 id 是 `tfc:<name>`，书籍 JSON 里用 `"multiblock": "tfc:bloomery"` 引用。

### 2.2 用 `makeMultiblock` 构造（字符矩阵 + 映射表）

```java
private static IMultiblock bloomery(PatchouliAPI.IPatchouliAPI api) {
    IStateMatcher bloomeryInsulation = api.predicateMatcher(
        TFCBlocks.ROCK_BLOCKS.get(Rock.GRANITE).get(Rock.BlockType.BRICKS).get(),
        BloomeryBlock::isBloomeryInsulationBlock);

    return api.makeMultiblock(
        new String[][]{
            {" S ", "SAS", " S "},
            {"SBS", "SAS", " S "},
            {" S ", " 0 ", "   "}
        },
        new Object[]{
            '0', bloomeryInsulation,                        // 结构原点（决定 preview 的旋转中心）
            'A', api.airMatcher(),
            'S', bloomeryInsulation,
            'B', api.predicateMatcher(
                    TFCBlocks.BLOOMERY.get().defaultBlockState()
                        .setValue(BloomeryBlock.FACING, Direction.NORTH),
                    state -> Helpers.isBlock(state, TFCBlocks.BLOOMERY.get())),
            ' ', api.anyMatcher()
        });
}
```

**Matcher 清单（`PatchouliAPI.IPatchouliAPI` 提供，全部可用）**：

| 方法 | 语义 |
|---|---|
| `api.anyMatcher()` | 任意方块（通常映射空格） |
| `api.airMatcher()` | 必须为空气 |
| `api.strictBlockMatcher(Block)` | 严格匹配方块（含状态默认值） |
| `api.looseBlockMatcher(Block)` | 只匹配方块种类，忽略状态 |
| `api.stateMatcher(BlockState)` | 匹配完整方块状态 |
| `api.predicateMatcher(Block, Predicate<BlockState>)` | 自定义谓词（TFC 用它表达「任意保温砖」） |
| `api.predicateMatcher(BlockState, Predicate<BlockState>)` | 带基准状态的谓词匹配 |

### 2.3 让预览「有内容」：`sneakIntoMultiblock`

TFC 的一个巧妙技巧：**Patchouli 的 `IMultiblock` 实现同时是 `BlockGetter`**。
于是 TFC 直接把多块当成一个世界读取器，访问其中的方块实体并**手动设置运行状态**，
让书中的预览显示「正在运转的机器」（转动的水车、带锭子的砧、装满面粉的石磨……）：

```java
private static Optional<BlockGetter> sneakIntoMultiblock(IMultiblock multiblock) {
    if (multiblock instanceof BlockGetter access) return Optional.of(access);
    LOGGER.warn("Multiblock ... is not a BlockGetter, multiblock will be disfigured!");
    return Optional.empty();
}

// 例：给石磨预览装上磨盘与上方传动轴
sneakIntoMultiblock(multiblock).ifPresent(access -> {
    access.getBlockEntity(new BlockPos(0, 1, 0), TFCBlockEntities.QUERN.get()).ifPresent(quern -> {
        quern.getRotationNode().setRotationFromOutsideWorld();
        quern.setHandstoneFromOutsideWorld();
        quern.setAxleAboveFromOutsideWorld(TFCBlocks.WOODS.get(Wood.OAK).get(Wood.BlockType.AXLE).get());
    });
    access.getBlockEntity(new BlockPos(0, 2, 0), TFCBlockEntities.AXLE.get())
          .ifPresent(axle -> axle.getRotationNode().setRotationFromOutsideWorld());
});
```

> 注意 `setRotationFromOutsideWorld()`、`setHandstoneFromOutsideWorld()` 这类方法名——
> **它们就是 TFC 为了让 Patchouli 预览能操纵方块实体而特意提供的公开入口**（`XxxFromOutsideWorld` 命名约定）。
> 如果你做附属模组且希望自己的多块预览也可被操纵，照这个命名约定加方法即可。

### 2.4 其它公开入口

```java
public static final ResourceLocation BOOK_ID = Helpers.identifier("field_guide");
public static final ResourceLocation TEXTURE = Helpers.identifier("textures/gui/book/icons.png");

public static ItemStack getFieldGuide(boolean useHotReloadedBook);
public static void ifEnabled(Runnable action);                       // 受 config 开关控制
public static void openGui(ServerPlayer player);                     // 打开书
public static void openGui(ServerPlayer player, ResourceLocation entry, int page);  // 打开指定条目页
```

`openGui` 内部就是 `PatchouliAPI.get().openBookGUI(player, BOOK_ID)` 与
`openBookEntry(player, BOOK_ID, entry, page)`。附属模组可以用同样方式给自己的物品绑定「打开某本书的某一页」。

---

## 3. 自定义展示页：模板 JSON + `patchouli:custom`

### 3.1 TFC 的 13 个模板

`assets/tfc/patchouli_books/field_guide/en_us/templates/`：

| 模板文件 | 条目中 `type` 写法 | 对应组件类（`net.dries007.tfc.compat.patchouli.component.`） |
|---|---|---|
| `heat_recipe.json` | `tfc:heat_recipe` | `HeatingComponent` |
| `anvil_recipe.json` | `tfc:anvil_recipe` | `AnvilComponent` |
| `welding_recipe.json` | `tfc:welding_recipe` | `WeldingComponent` |
| `quern_recipe.json` | `tfc:quern_recipe` | `QuernComponent` |
| `knapping_recipe.json` | `tfc:knapping_recipe` | `KnappingComponent` |
| `rock_knapping_recipe.json` | `tfc:rock_knapping_recipe` | `RockKnappingComponent` |
| `loom_recipe.json` | `tfc:loom_recipe` | `LoomComponent` |
| `glassworking_recipe.json` | `tfc:glassworking_recipe` | `GlassworkingComponent` |
| `sealed_barrel_recipe.json` | `tfc:sealed_barrel_recipe` | `SealedBarrelComponent` |
| `instant_barrel_recipe.json` | `tfc:instant_barrel_recipe` | `InstantBarrelComponent` |
| `multimultiblock.json` | `tfc:multimultiblock` | `MultiMultiBlockComponent` |
| `table.json` | `tfc:table` | `TableComponent` |
| `table_small.json` | `tfc:table_small` | `TableComponent` |

（组件包内还有 `BarrelComponent`、`RecipeComponent`、`InputOutputComponent`、`SimpleItemRecipeComponent`、
`ScrapingComponent`、`CustomComponent$MultiblockRenderer` 等基类/辅助类，共 21 个 class 文件。）

以 `heat_recipe.json` 为例，**模板的全部内容**就是：

```json
{"components":[
  {"type":"patchouli:custom","x":0,"y":0,
   "class":"net.dries007.tfc.compat.patchouli.component.HeatingComponent",
   "recipe":"#recipe"},
  {"type":"patchouli:text","x":0,"y":45,"text":"#text"}]}
```

在具体条目里：

```json
{
  "type": "tfc:heat_recipe",
  "recipe": "tfc:heating/copper_ingot",
  "text": "把铜矿石加热到 $(l:mechanics/…)…"
}
```

**机制拆解**：
1. Patchouli 读 `entry.pages[i].type`，发现不是内置类型，于是去 `templates/<name>.json` 找同名模板；
2. 模板里的 `#recipe`、`#text` 是**变量占位符**，由条目中同名字段提供（这就是为什么模板里写 `"#recipe"`）；
3. `patchouli:custom` 组件用 `"class"` 指向的**完整类名反射实例化**（`Class.forName(...).newInstance()`，须有无参构造器）；
4. 该组件实现 `vazkii.patchouli.api.ICustomComponent`，在 `onVariablesAvailable` 里接收变量、在 `build(x, y, pageNum)` 里解析、在 `render(...)` 里绘制。

### 3.2 组件基类 `CustomComponent`

```java
public abstract class CustomComponent implements ICustomComponent {
    protected transient int x;                                  // 组件坐标（build 时注入）
    protected transient int y;
    protected transient HolderLookup.Provider provider;

    @Override public void onVariablesAvailable(UnaryOperator<IVariable> lookup, HolderLookup.Provider provider);
    @Override public void build(int componentX, int componentY, int pageNum);

    protected void renderSetup(GuiGraphics g);                   // push 矩阵 + 绑定 tfc 的 icons.png
    protected void renderItemStacks(IComponentRenderContext, GuiGraphics, int x, int y, int mx, int my, List<ItemStack>);
    protected void renderFluidStacks(IComponentRenderContext, GuiGraphics, int x, int y, int mx, int my, List<FluidStack>);
    protected void renderFluidStack(IComponentRenderContext, GuiGraphics, int x, int y, int mx, int my, FluidStack);
    protected List<ItemStack>  unpackItemStackIngredient(SizedIngredient);
    protected List<FluidStack> unpackFluidStackIngredient(SizedFluidIngredient);
    protected <V, T> Optional<T> asJson(V value, Function<V, T> parse);
    protected Optional<Component> asTextComponent(JsonElement json);
    protected <T extends Recipe<?>> Optional<T> asRecipe(String variable, RecipeType<T> type);
    protected Optional<ResourceLocation> asResourceLocation(String variable);
    protected Optional<Supplier<IMultiblock>> asMultiblock(IVariable variable);
    protected Optional<MultiblockRenderer> asMultiblockRenderer(Supplier<IMultiblock>);

    public static class MultiblockRenderer extends PageMultiblock { ... }   // 借 PageMultiblock 渲染多块
}
```

**几个关键技巧（值得直接抄）**：

- `renderItemStacks(...)` 里用 `context.getTicksInBook() / 20 % stacks.size()` 让多个候选物品**轮流显示**
  （例如「任意一种矿石都可以」的展示）。
- `asRecipe(String, RecipeType<T>)` 通过 `ClientHelpers.getLevelOrThrow().getRecipeManager().byKey(id)` 查配方并校验类型，
  查不到会打日志（不是崩溃）。这就是「页面直接引用一个真实配方 id」的实现。
- `asMultiblock(IVariable)` 同时支持「写字符串 id（引用已注册多块）」与「内联写完整多块 JSON」。
- `MultiblockRenderer` 通过反射把 `PageMultiblock.multiblockObj` 字段塞进去，从而**复用原版多块页面的渲染器**。

### 3.3 组件字段 = 模板 JSON 键名

Gson 会把 JSON 中与字段同名的键**自动注入**（不需要 setter）。例如：

| 组件 | 可用字段（即模板/条目中的键） |
|---|---|
| `RecipeComponent<T>`（抽象基类） | `recipe`（配方 id，经 `#变量` 解析后查表得到 `T recipe`） |
| `BarrelComponent` | `inputItems`（`List<ItemStack>`）、`inputFluids`（`List<FluidStack>`），另有 `transient` 标记的内部缓存 |
| `KnappingComponent` | `inputs`（`ItemStack[]`） |
| `TableComponent` | `entries`、`columns`、`firstColumnWidth`、`columnWidth`、`rowHeight`、`leftBuffer`、`topBuffer`、`drawBackground`、`title`、`legend` |

> `transient` 修饰的字段用于「解析后的中间结果」，不会被 Gson 从 JSON 注入 ——
> 想避免玩家在 JSON 里乱填，就给字段加 `transient`。

---

## 4. 附属模组复刻清单（可执行步骤）

目标：**为我自己模组的一种配方做一个像 TFC 一样的展示页**。

### 4.1 文件清单

| 路径 | 内容 |
|---|---|
| `src/main/resources/data/mymod/patchouli_books/handbook/book.json` | 书籍定义，必须含 `"use_resource_pack": true` |
| `src/main/resources/assets/mymod/patchouli_books/handbook/en_us/categories/*.json` | 分类（**基准语言必须是 en_us**） |
| `src/main/resources/assets/mymod/patchouli_books/handbook/en_us/entries/**.json` | 条目，`"type": "mymod:my_recipe"` |
| `src/main/resources/assets/mymod/patchouli_books/handbook/en_us/templates/my_recipe.json` | 模板 |
| `src/main/java/.../compat/patchouli/MyRecipeComponent.java` | 组件实现 |
| （可选）`assets/mymod/patchouli_books/handbook/zh_cn/...` | 中文覆盖（**必须与 en_us 同名同路径**） |

### 4.2 模板 JSON

```json
{"components":[
  {"type":"patchouli:custom","x":0,"y":0,
   "class":"com.example.mymod.compat.patchouli.MyRecipeComponent",
   "recipe":"#recipe"},
  {"type":"patchouli:text","x":0,"y":60,"text":"#text"}]}
```

### 4.3 条目 JSON

```json
{
  "name": "我的机器配方",
  "category": "mymod:machines",
  "icon": "mymod:my_machine",
  "pages": [
    { "type": "mymod:my_recipe",
      "recipe": "mymod:my_recipe/example",
      "text": "把 $(item)mymod:ore$ 放进去，等 $(thing)10 秒$。" }
  ]
}
```

### 4.4 组件实现（最小可编译骨架）

```java
package com.example.mymod.compat.patchouli;

import java.util.List;
import java.util.function.UnaryOperator;
import net.dries007.tfc.compat.patchouli.component.CustomComponent;   // 直接复用 TFC 基类
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.RecipeType;
import vazkii.patchouli.api.IComponentRenderContext;
import vazkii.patchouli.api.IVariable;

/** 展示一条 mymod:my_recipe 配方：输入物品 → 输出物品。 */
public class MyRecipeComponent extends CustomComponent {
    // 字段名即 JSON 键名，由 Gson 注入
    private String recipe = "";
    private transient MyRecipe resolved;      // transient：解析结果，不参与注入

    @Override
    public void onVariablesAvailable(UnaryOperator<IVariable> lookup, net.minecraft.core.HolderLookup.Provider provider) {
        super.onVariablesAvailable(lookup, provider);
        this.recipe = lookup.apply(IVariable.wrap(this.recipe, provider)).asString();
    }

    @Override
    public void build(int componentX, int componentY, int pageNum) {
        super.build(componentX, componentY, pageNum);
        this.resolved = asRecipe(this.recipe, MyModRecipes.MY_TYPE.get()).orElse(null);
    }

    @Override
    public void render(GuiGraphics graphics, IComponentRenderContext context, float partialTicks, int mouseX, int mouseY) {
        renderSetup(graphics);
        if (resolved == null) return;
        renderItemStacks(context, graphics, 0, 0, mouseX, mouseY,
            List.of(resolved.getInput().getItems()));
        context.renderItemStack(graphics, 32, 16, mouseX, mouseY, resolved.getResult());
        graphics.pose().popPose();
    }
}
```

要点：
- **`class` 指向的类必须有无参构造器**，且**只能在客户端加载**（组件只在 GUI 里用）；
  因此这个类应放在 `compat.patchouli` 包并确保服务端不会加载它（TFC 的做法是所有 Patchouli 相关代码
  只在 `Dist.CLIENT` 分支引用）。
- 复用 TFC 的 `CustomComponent` 基类可以直接获得 `renderItemStacks`、`asRecipe` 等工具（代价是硬依赖 TFC —— 对本项目而言无所谓）。

### 4.5 注册自己的多块结构

```java
public final class MyPatchouliIntegration {
    public static void registerMultiBlocks() {
        PatchouliAPI.IPatchouliAPI api = PatchouliAPI.get();
        api.registerMultiblock(ResourceLocation.fromNamespaceAndPath("mymod", "my_machine"),
            api.makeMultiblock(
                new String[][]{ {"BBB", "B0B", "BBB"} },
                new Object[]{
                    '0', api.looseBlockMatcher(MyBlocks.MACHINE.get()),
                    'B', api.predicateMatcher(MyBlocks.CASING.get(), MyMachineBlock::isValidCasing),
                    ' ', api.anyMatcher()
                }));
    }
}
```

调用时机：与 TFC 相同，在 `FMLCommonSetupEvent` 中调用（**TFC 是在 `enqueueWork` 之外调用的**，
跟随同样的时序最安全）。

---

## 5. 排错清单

| 现象 | 原因 |
|---|---|
| 条目在书里不出现 | `en_us` 里没有同名文件（Patchouli 只从 `en_us` 发现文件） |
| 书籍加载直接失败/被跳过 | `data` 侧 `book.json` 缺 `"use_resource_pack": true` |
| `type` 显示成「未知页面」 | 模板文件名与 `type` 不同名，或模板放错目录（必须在 `<lang>/templates/`） |
| 页面空白、日志报 ClassNotFound | `"class"` 写错，或该类被服务端加载/没有无参构造器 |
| `#recipe` 变量没生效 | 条目里漏写同名字段；`onVariablesAvailable` 里没做 `lookup.apply(...)` |
| 多块预览旋转中心不对 | `'0'` 字符没映射（原点约定用 `0`） |
| `sneakIntoMultiblock` 报 "will be disfigured" | 使用的 `IMultiblock` 实现不是 `BlockGetter`（一般是自己 new 出来的假实现） |
| 配方查不到只打日志不崩溃 | `asRecipe` 的行为就是「找不到 → `Optional.empty()` + ERROR 日志」，检查日志定位 |

---

## 6. 交叉引用

- Patchouli 自身格式与 API 完整字典：`40-patchouli-api.md`
- TFC 注册体系与事件：`10-tfc-overview.md`、`13-tfc-api.md`
- TFC 配方 JSON 格式（展示页要引用的 recipe id 从哪来）：`12-tfc-data-driven.md`
- 附属模组工程骨架：`20-addon-scaffold.md`
