# Patchouli `release-1.21.1-93` 技术文档（面向 MC 1.21.1 / NeoForge 21.1.x 附属模组开发）

> 本文档基于**本地已克隆源码**静态分析产出，供后续（不带上下文的）AI 代理在编写 Minecraft 模组、编写/生成 Patchouli 书籍内容、为 TFC 附属模组添加手册时直接当字典查阅。
> 所有关键结论均标注来源（相对 Patchouli 仓库根的路径）。
> 凡标注「**未能核实**」的条目，均在文中说明已检查过的位置；凡与网上旧文档/旧版本 API 冲突之处，一律以本仓库源码为准并显式标出。

---

## 0. 环境事实、核实方式与「与常见前提不符」的预登记

### 0.1 环境事实

| 项目 | 值 | 来源 |
| --- | --- | --- |
| 源码根目录 | `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\Patchouli` | 环境提供 |
| Git tag | `release-1.21.1-93`（commit `0c2fdff`） | 子代理执行 `git describe --tags` / `git log -1` |
| 本地 jar | `mods\Patchouli-1.21.1-93-NEOFORGE.jar`（632 KB） | 目录列举 |
| MC 版本 | `1.21.1` | `gradle.properties` 的 `mc_version` |
| 构建号 | `93` | `gradle.properties` 的 `build_number` |
| Java | `21`（`compatibilityLevel: "JAVA_21"`） | `Xplat/src/main/resources/patchouli_xplat.mixins.json` |
| mod id | `patchouli`（`PatchouliAPI.MOD_ID`） | `Xplat/src/main/java/vazkii/patchouli/api/PatchouliAPI.java` |
| NeoForge 依赖 | `[21.0.31-beta,)`（REQUIRED） | `NeoForge/src/main/resources/META-INF/neoforge.mods.toml` |
| MC 依赖 | `[1.21.1,1.21.2)`（REQUIRED） | 同上 |
| 许可证 | `CC BY-NC-SA 3.0` | 同上 |
| TFC 版本 | `4.2.10`，把 Patchouli 作为 **required 硬依赖** | `mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` 内 `META-INF/neoforge.mods.toml` |

TFC 的依赖声明原文（从 jar 内读取 `META-INF/neoforge.mods.toml`）：

```toml
[[dependencies.tfc]]
    modId = "patchouli"
    type = "required"
    versionRange = "[1.21.1-92-NEOFORGE,)"
    ordering = "NONE"
    side = "BOTH"
```

### 0.2 本文的核实手段

1. **源码直读**：`read` / `grep` / `glob` 读取 `Xplat`、`NeoForge` 两个源集。
2. **jar 签名核验**：用本机 `javap`（JDK 17 可正常读取 Java 21 class 文件）直接反编译本地 jar
   ```
   javap -p -cp "mods\Patchouli-1.21.1-93-NEOFORGE.jar" "vazkii.patchouli.api.PatchouliAPI`$IPatchouliAPI"
   ```
   结果与源码**逐条一致**，因此本节的 API 签名是「源码 + 二进制」双重核实。
3. **TFC 侧交叉验证**：`moddev\inventory\TFC.classes.txt`（类清单）+ 直接读取 TFC jar 内的 `book.json`、`templates/*.json`、`entries/*.json` + 从 class 常量池提取字符串。TFC 源码目录 `moddev\src-ref\TerraFirmaCraft` **不存在**（`Test-Path` 返回 `False`），因此 TFC 侧一律以 jar 内容为准。
4. **官方文档交叉参考**：仓库自带 Docusaurus 文档位于 `web/docs/`（`web\docs\reference\book-json.md` 等）。这些文档**部分滞后于本 tag 的源码**，凡冲突处本文以源码为准并显式标注。

### 0.3 预登记：常见前提与源码不符之处（务必先读）

以下 8 条是旧版本资料或口头流传中常被当作事实、但在 `release-1.21.1-93` 源码中**并不存在**的东西。写代码/写书前请先确认，否则会照抄出无法编译或静默失效的内容。

| 常见说法 | 本版本事实 | 核实位置 |
| --- | --- | --- |
| 有 `PageRegistry.register(...)` / `registerPageType(...)` 方法 | **不存在**。全仓库无 `PageRegistry`、`registerPageType`。page 类型表是内部类 `ClientBookRegistry` 的 `public final Map<ResourceLocation, Class<? extends BookPage>> pageTypes` | `Xplat/.../client/book/ClientBookRegistry.java` L27、L43-60；`grep -r "registerPageType\|PageRegistry"` 零命中 |
| 有 `PageSerializer`、`IPage`、`Page`、`PageDouble` 类型 | **不存在**。本版本基类是 `BookPage`（≈旧 `IPage`）、`PageWithText`、`PageDoubleRecipe`、`PageSimpleProcessingRecipe` | `Xplat/.../client/book/BookPage.java`、`client/book/page/abstr/` |
| 有 `patchouli:macros` / `patchouli:flags` 这类 **Processor 类型**，或 `ProcessorMacros`/`ProcessorFlags` 类 | **不存在**。模板处理器的机制是**类名反射**：`"processor": "完整类名"` | `Xplat/.../client/book/template/BookTemplate.java` L46、L164-177；`grep "ProcessorMacros\|ProcessorFlags"` 零命中 |
| `patchouli:multiblock` 支持 `displayed_multiblock` 字段 | **不存在**（也不存在 `displayed_state`）。可核实字段只有 `pattern`、`sparse_pattern`、`mapping`、`symmetrical`、`offset` | `Xplat/.../common/multiblock/SerializedMultiblock.java`；`grep "displayed_multiblock\|displayed_state"` 零命中 |
| 多块 JSON 支持 `view_offset` | **不存在该字段**。源码只有 `offset`（3 元素 int 数组）。示例书里出现的 `"view_offset"` 会被 Gson 静默忽略 | `SerializedMultiblock.java`；反例见 `Xplat/src/main/resources/assets/patchouli/patchouli_books/testbook1/en_us/entries/test/testy.json` L31 |
| `book.json` 可用 `extend` 扩展、`allow_extensions` 关闭扩展 | **两者都已移除，且写了 `extend` 会直接抛异常**导致书籍加载失败 | `Xplat/.../common/book/Book.java` L151-158 |
| 有 `patchouli:shaped_book_recipe` / `patchouli:shapeless_book_recipe` 配方类型 | **本 tag 源码中不存在**（只在 `web/docs` 旧文档里残留）。1.21.1 的做法是原版配方 + `result.components."patchouli:book"` | `grep -r "book_recipe\|BookRecipe"` 仅命中 `web/docs/**`；正向范例见 `Xplat/src/main/resources/data/patchouli/recipes/test_recipe.json` |
| 书籍物品 id 是 `patchouli:book` | **是 `patchouli:guide_book`**（旧文档偶见 `patchouli:book`）。书籍 id 存于**数据组件** `patchouli:book`，不是 NBT | `Xplat/.../common/item/PatchouliItems.java` L12；`PatchouliDataComponents.java` L12 |
| `PatchouliAPI` 类上有 `@Mod` 注解 | **没有**。全仓库唯一 `@Mod` 在 `NeoForgeModInitializer`，值为 `PatchouliAPI.MOD_ID`（`"patchouli"`） | `NeoForge/.../neoforge/common/NeoForgeModInitializer.java` |
| `PatchouliConfigAccess` 是 record | 它是 25 行的 `interface`（7 个方法 + 嵌套 `enum TextOverflowMode`） | `Xplat/.../api/PatchouliConfigAccess.java` |

---

## 1. 运行模型：内容在哪一侧、何时加载、语言如何回退

理解这一章是理解后面所有「哪些文件放 data、哪些放 assets」的前提。

### 1.1 三层分工

Patchouli 的书籍由三类东西组成，它们位于**不同的一侧**、在**不同时间**加载：

| 组成 | 位置 | 加载侧 | 加载时机 | 源码依据 |
| --- | --- | --- | --- | --- |
| `book.json`（书籍声明） | `data/<modid>/patchouli_books/<bookname>/book.json` | **双端**（服务端也会读） | 游戏启动早期、`FMLCommonSetupEvent` | `Xplat/.../common/book/BookRegistry.java` L41-84 |
| 分类 / 条目 / 模板 JSON | `assets/<namespace>/patchouli_books/<bookname>/<lang>/{categories,entries,templates}/**.json` | **仅客户端** | 客户端资源重载 + 收到第一个 advancement 包后 | `Xplat/.../client/book/BookContentResourceListenerLoader.java` L26-39；`ClientAdvancements.onClientPacket()` |
| 图片 / 音效 / 字体等杂项资源 | 常规 `assets/<namespace>/...` | 仅客户端 | 常规资源加载 | `Book.java` 默认纹理常量（L40-42） |

> **结论**：`book.json` **必须**放在 `data/`；`categories`、`entries`、`templates` 三大目录**必须**放在 `assets/`（1.20 起强制，见 1.4）。书籍内容纯客户端，`book.json` 双端都要能读到。

### 1.2 加载时序（服务端 + 客户端）

```
[服务端/双端启动]
  FMLCommonSetupEvent (NeoForgeModInitializer.onInitialize)
    └─ BookRegistry.INSTANCE.init()
         ├─ 遍历所有已加载 mod，对每个 mod 扫描
         │    <modRoot>/data/<modid>/patchouli_books/**/book.json   （Files.walk 深度=2）
         │    → loadBook(mod, ResourceLocation(modid, bookName), stream, external=false)
         │    → new Book(json, owner, id, false)
         ├─ BookFolderLoader.findBooks()   // 扫描工作目录 .minecraft/patchouli_books/<name>/book.json
         │    → 这些书的 namespace 固定为 patchouli，external=true
         └─ IXplatAbstractions.INSTANCE.signalBooksLoaded()   // 唤醒等待书籍模型的客户端逻辑

[客户端启动]
  FMLClientSetupEvent (NeoForgeClientInitializer.onInitializeClient)
    ├─ ClientBookRegistry.INSTANCE.init()   // 注册 16 个内置 page 类型
    └─ PersistentData.setup()               // 读/建 patchouli_data.json
  RegisterClientReloadListenersEvent
    └─ 注册 BookContentResourceListenerLoader.INSTANCE （SimpleJsonResourceReloadListener，directory="patchouli_books"）

[客户端进入世界、收到第一个 advancement 包]
  ClientAdvancements.onClientPacket()
    └─ ClientBookRegistry.INSTANCE.reload()
         ├─ currentLang = Minecraft.getInstance().getLanguageManager().getSelected()
         └─ BookRegistry.INSTANCE.reloadContents(level)
              └─ 每本书 Book.reloadContents(level,false)
                   └─ BookContentsBuilder.loadAndBuildFor(level, book, false)
                        ├─ SerializationUtil.VARIABLE_SERIALIZER.setRegistries(level.registryAccess())
                        ├─ load("categories", ...) / load("entries", ...) / load("templates", ...)
                        └─ build(level)  // 解析 parent/category、构建页面、生成配方映射
```

来源：`BookRegistry.java` L41-102、`ReloadContentsHandler.java`、`NeoForgeClientInitializer`（子代理抄录于 `docs/_research/patchouli-api-signatures.md`）、`BookContentsBuilder.java` L72-136、`ClientAdvancements.java` L30-37。

> **实践含义**：改了 `book.json` 要重启；改了 `categories/entries/templates` 只需在游戏里点书内的「铅笔（编辑器）」按钮热重载，或重载资源包。

### 1.3 语言目录规则（**最容易被写错的一处**）

`BookContentsBuilder` 的常量与语言替换逻辑：

```java
// Xplat/src/main/java/vazkii/patchouli/client/book/BookContentsBuilder.java L30
public static final String DEFAULT_LANG = "en_us";

// L126-131：文件的「发现」永远只从 en_us 目录进行
String filePath = String.format("%s/%s/%s/%s/%s.json",
        BookRegistry.BOOKS_LOCATION, book.id.getPath(), DEFAULT_LANG, thing, id.getPath());
// thing ∈ {"categories","entries","templates"}

// L186-199：加载时把路径中的 "en_us" 替换成当前语言，失败则回退 en_us
ResourceLocation localizedFile = ResourceLocation.fromNamespaceAndPath(file.getNamespace(),
        file.getPath().replaceAll(DEFAULT_LANG, ClientBookRegistry.INSTANCE.currentLang));
BookContentLoader.LoadResult input = loader.loadJson(book, localizedFile);
if (input == null) {
    input = loader.loadJson(book, file);          // 回退英文
    if (input == null) throw new IllegalArgumentException(file + " does not exist.");
}
```

而 `BookContentResourceListenerLoader.findFiles` 也只挑 `lang == "en_us"` 的条目（L76-79）：

```java
if (dir.equals(matcher.group("folder"))
        && BookContentsBuilder.DEFAULT_LANG.equals(matcher.group("lang"))) {
    list.add(ResourceLocation.fromNamespaceAndPath(id.getNamespace(), matcher.group("entryId")));
}
```

**由此推出三条硬规则：**

1. `assets/<ns>/patchouli_books/<book>/en_us/` 是**唯一的发现基准**。`en_us` 目录里**必须**存在每一个分类/条目/模板文件，否则其它语言里的同名文件**永远不会被加载**。
2. 其它语言（`zh_cn`、`ja_jp`、`zh_tw`…）是**纯覆盖**：只放你要翻译的文件即可，缺失的条目自动回退到 `en_us`。
3. 语言代码必须是**完整文件路径中的目录段**，且 `en_us` 字样不能被其它文本包含（源码用的是无锚点的 `String.replaceAll("en_us", lang)`，虽然实务上几乎不会踩到，但目录名里含 `en_us` 的字符串会被一并替换，属于已知的实现瑕疵）。

TFC 的真实用法印证了这一点：`assets/tfc/patchouli_books/field_guide/` 下有 10 个语言目录（`en_us`、`zh_cn`、`zh_tw`、`zh_hk`、`ja_jp`、`ko_kr`、`pt_br`、`ru_ru`、`tr_tr`、`uk_ua`），而 `zh_cn/entries/getting_started/firepit.json` 只是 `en_us` 同名文件的译文覆盖。

### 1.4 `use_resource_pack` 的含义与强制

`Book` 构造器中有一段硬校验（`Xplat/.../common/book/Book.java` L142-149）：

```java
boolean useResourcePack = GsonHelper.getAsBoolean(root, "use_resource_pack", false);
if (!this.isExternal && !useResourcePack) {
    String message = "Book %s has use_resource_pack set to false. "
            + "This behaviour was removed in 1.20. "
            + "The book author should enable this flag and move all book contents clientside to /assets/, "
            + "leaving the book.json in /data/. See https://vazkiimods.github.io/Patchouli/docs/upgrading/upgrade-guide-120 for details.";
    throw new IllegalArgumentException(message);
}
```

- `use_resource_pack: true` ⇒ 内容经**资源包系统**加载（`assets/`），支持资源包覆盖与热重载。
- 只有 `external` 书（即放在工作目录 `.minecraft/patchouli_books/` 下的书）允许不写或写 `false`；此时内容与 `book.json` 同目录。
- **`data/` 里声明的书若不写 `use_resource_pack: true`，加载时直接抛异常并且这本书被跳过**（`BookRegistry.init` 的 `catch (Exception e)` 只记 error 日志）。

### 1.5 外部书（modpack 与「不改 mod 就加内容」的路径）

`BookFolderLoader`（`Xplat/.../common/book/BookFolderLoader.java`）：

- 目录固定为工作目录下的 `patchouli_books/`（`new File(BookRegistry.BOOKS_LOCATION)`，`BOOKS_LOCATION = "patchouli_books"`）。
- 该目录下**每个子目录**被视为一本书，读其 `book.json`，`external = true`，**namespace 固定为 `patchouli`**。
- 因此 modpack 书的 id 形如 `patchouli:mybook`，条目 id 形如 `patchouli:my_category`。

### 1.6 「只加内容、不建新书」——附属模组最推荐的落地方式

由于内容全部经资源包系统加载，**一个附属模组可以只往 `assets/<被扩展mod的namespace>/patchouli_books/<那本书>/en_us/...` 里补文件，就为已有书增加条目/分类/模板**，无需 Java 代码、无需 `book.json`。

- 依据：`BookContentResourceListenerLoader` 按 `DataPack`/`ResourcePack` 合并后的资源清单工作，多个 mod 的资源会被 `SimpleJsonResourceReloadListener` 合并；`BookContentResourceDirectLoader.computeAddedByText` 还专门处理了「来自其它资源包」的标记（`Xplat/.../client/book/BookContentResourceDirectLoader.java` L74-90）。
- 官方文档同样确认此路径：`web/docs/upgrading/upgrade-guide-120.md` L52-55，`web/docs/patchouli-basics/getting-started.md` L257-275。

---

## 2. `book.json` 字段全解

**反序列化位置**：`Xplat/src/main/java/vazkii/patchouli/common/book/Book.java` 的构造函数（L108-182）。全部读取都用 `GsonHelper.*`（缺失即用默认值，除非该方法无默认重载 ⇒ 必填）。

### 2.1 完整字段表

| JSON 字段 | Java 字段 | 类型 | 必填 | 默认值 | 说明 / 备注 |
| --- | --- | --- | --- | --- | --- |
| `name` | `name` | String | **是** | —（缺失抛异常） | 书名。**始终被当作翻译键**：物品名走 `Component.translatable(book.name)`，落地页标题同理（`ItemModBook.getName`、`GuiBookLanding` L39） |
| `landing_text` | `landingText` | String | 否 | `"patchouli.gui.lexicon.landing_info"` | 落地页正文。**始终走 `Component.translatable`**（`GuiBookLanding` L46），可写纯文本或翻译键 |
| `book_texture` | `bookTexture` | ResourceLocation | 否 | `patchouli:textures/gui/book_brown.png` | 书 GUI 背景纹理 |
| `filler_texture` | `fillerTexture` | ResourceLocation | 否 | `patchouli:textures/gui/page_filler.png` | 奇数页时的填充纹理 |
| `crafting_texture` | `craftingTexture` | ResourceLocation | 否 | `patchouli:textures/gui/crafting.png` | 合成/加工页面底图 |
| `model` | `model` | ResourceLocation | 否 | `patchouli:book_brown` | **物品模型 id，源码会追加 `item/` 前缀**（L114 `withPrefix("item/")`）⇒ 写 `patchouli:book_green` 即指向 `assets/patchouli/models/item/book_green.json`。Patchouli 会自动把模型注册进模型管理器，并提供一个物品属性谓词 `patchouli:completion`（值 = 书籍完成度，`ItemModBook.getCompletion(stack)`），可在自建模型里做「读得越多长得越不同」的效果 |
| `use_blocky_font` | `useBlockyFont` | boolean | 否 | `false` | true=原版粗体像素字体；false=MC 的 `UNIFORM_FONT`（平滑字体） |
| `text_color` | `textColor` | String(hex) | 否 | `"000000"` | 正文颜色，`Integer.parseInt(...,16)` 后或上 `0xFF000000`，**不带 `#`** |
| `header_color` | `headerColor` | String(hex) | 否 | `"333333"` | 标题颜色 |
| `nameplate_color` | `nameplateColor` | String(hex) | 否 | `"FFDD00"` | 落地页名牌颜色 |
| `link_color` | `linkColor` | String(hex) | 否 | `"0000EE"` | 链接颜色 |
| `link_hover_color` | `linkHoverColor` | String(hex) | 否 | `"8800EE"` | 链接悬停颜色 |
| `progress_bar_color` | `progressBarColor` | String(hex) | 否 | `"FFFF55"` | 进度条前景色 |
| `progress_bar_background` | `progressBarBackground` | String(hex) | 否 | `"DDDDDD"` | 进度条背景色 |
| `open_sound` | `openSound` | ResourceLocation | 否 | `patchouli:book_open` | 打开音效 |
| `flip_sound` | `flipSound` | ResourceLocation | 否 | `patchouli:book_flip` | 翻页音效 |
| `show_progress` | `showProgress` | boolean | 否 | `true` | 是否显示进度条（即使启用了 advancement 锁定也强制关闭） |
| `index_icon` | `indexIconRaw` | String | 否 | `""` | 索引图标。空 ⇒ 用书籍物品自身；以 `.png` 结尾 ⇒ 当纹理；否则按 ItemStack 字符串（`BookIcon.from`，L31-43） |
| `version` | `version` | String | 否 | `"0"` | 「版本号/版次」。数字且非 0 ⇒ 显示 `Nth Edition`；非数字 ⇒ 显示 dev edition；`"0"` ⇒ 显示 `subtitle` |
| `subtitle` | `subtitle` | String | 否 | `""` | 副标题，tooltip 与落地页 |
| `creative_tab` | `creativeTab` | ResourceLocation | 否 | `null` | 书籍物品出现在哪个创造标签页（如 `minecraft:tools_and_utilities`） |
| `advancements_tab` | `advancementsTab` | ResourceLocation | 否 | `null` | 关联的 advancement 页签，设置后落地页出现「进度」按钮 |
| `dont_generate_book` | `noBook` | boolean | 否 | `false` | true ⇒ 不自动生成书籍物品，改用 `custom_book_item` |
| `custom_book_item` | —（局部变量） | ItemStack 字符串 | 否 | `""` | 自定义书籍物品。**仅当 `dont_generate_book: true` 时被解析**，且是**惰性解析**（`Suppliers.memoize`），因为可能依赖后加载的 mod |
| `show_toasts` | `showToasts` | boolean | 否 | `true` | 新条目解锁时是否弹 toast |
| `pause_game` | `pauseGame` | boolean | 否 | `false` | 打开书 GUI 时是否暂停游戏（单人） |
| `pamphlet` | `isPamphlet` | boolean | 否 | `false` | 小册子模式：全书必须**恰好一个分类**，否则抛异常（`BookContentsBuilder` L106-112） |
| `i18n` | `i18n` | boolean | 否 | `false` | true ⇒ 分类名、条目名、页内标题按 `Component.translatable` 处理；false ⇒ 按字面量 |
| `text_overflow_mode` | `overflowMode` | enum `TextOverflowMode` | 否 | `null`（跟随全局配置，NeoForge 默认 `RESIZE`） | 取值 `overflow` / `truncate` / `resize`（源码用 `toUpperCase` + `Enum.valueOf`，**大小写不敏感**） |
| `use_resource_pack` | —（局部变量） | boolean | 条件必填 | `false` | `data/` 下的书**必须为 true**，否则抛异常（见 1.4） |
| `macros` | `macros`（`Map<String,String>`） | Object | 否 | `{}`（叠加在 5 个内置宏之上） | 文本宏，见 §8.3 |

`Book` 上还有几个**非 JSON** 字段：`owner`（所属 mod 容器）、`id`、`isExternal`、`contents`（客户端内容容器）。

### 2.2 内置宏（写 `macros` 时是「叠加」而非「替换」）

`Book.DEFAULT_MACROS`（L44-53）：

```java
ret.put("$(list", "$(li");   // 注意：故意缺少右括号，以便 $(list2) 之类也能生效
ret.put("/$", "$()");
ret.put("<br>", "$(br)");
ret.put("$(item)", "$(#b0b)");
ret.put("$(thing)", "$(#490)");
```

自定义 `macros` 里的同名键会**覆盖**默认值（`macros.putAll(DEFAULT_MACROS)` 先执行，之后才是自定义项写入，L178-181）。

### 2.3 已移除 / 会抛异常的字段

| 字段 | 行为 |
| --- | --- |
| `extend` | 若存在（非 null）⇒ **抛 `IllegalArgumentException`**，提示该行为在 1.20 已移除，应改用资源包覆盖（`Book.java` L151-158） |
| `allow_extensions` | 源码中**没有任何读取**（grep 零命中），写了等于没写。旧文档仍描述它，属滞后内容 |

### 2.4 真实示例

官方测试书 `data/patchouli/patchouli_books/comprehensive_test_book/book.json`（全文）：

```json
{
  "name": "item.patchouli.comprehensive_test_book.name",
  "landing_text": "item.patchouli.comprehensive_test_book.landing",
  "model": "minecraft:nether_star",
  "version": "50",
  "subtitle": "Comprehensive Test Book Subtitle",
  "creative_tab": "minecraft:tools_and_utilities",
  "use_resource_pack": true,
  "text_overflow_mode": "resize",
  "pause_game": true
}
```

注意 `"model": "minecraft:nether_star"` ⇒ 实际模型 id 是 `minecraft:item/nether_star`，即直接复用了原版物品模型。

TFC 的真实 `data/tfc/patchouli_books/field_guide/book.json`（全文，单行）：

```json
{"name":"tfc.field_guide.book_name","landing_text":"tfc.field_guide.book_landing_text",
 "subtitle":"4.2.10","dont_generate_book":false,"show_progress":false,"macros":{},"use_resource_pack":true}
```

彩色书示例 `data/patchouli/patchouli_books/testbook2/book.json`：

```json
{
	"name": "item.patchouli:test_book_2.name",
	"landing_text": "item.patchouli:test_book_2.landing",
	"subtitle": "Cool book!",
	"text_color": "bf1111",
	"header_color": "114fbf",
	"nameplate_color": "d52eff",
	"progress_bar_background": "8892c9",
	"progress_bar_color": "da3423",
	"macros": { "$(potato)": "(POTATO MACRO)" },
	"model": "patchouli:book_green",
	"creative_tab": "minecraft:natural_blocks",
	"advancements_tab": "patchouli",
	"i18n": true,
	"use_resource_pack": true
}
```

小册子示例 `data/patchouli/patchouli_books/pamphlet/book.json` 把 `"pamphlet": true` 与其它字段并用。

### 2.5 最小可用 `book.json`（模组附属手册推荐起点）

```json
{
  "name": "item.mymod.my_guide.name",
  "landing_text": "item.mymod.my_guide.landing",
  "subtitle": "附属手册",
  "creative_tab": "minecraft:tools_and_utilities",
  "use_resource_pack": true
}
```

---

## 3. 分类（category）JSON 字段全解

**反序列化位置**：`Xplat/src/main/java/vazkii/patchouli/client/book/BookCategory.java` 构造函数（L43-53）。

### 3.1 字段表

| JSON 字段 | Java 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `name` | `name` | String | **是** | —（缺失抛异常） | 分类名。`book.i18n == true` 时按翻译键处理，否则按字面量（L55-57） |
| `description` | `description` | String | **是** | — | 分类描述，显示在分类页顶部，可含格式化代码（`getDescription()` 直接返回原始字符串） |
| `icon` | `icon`（`BookIcon`） | String | **是** | — | 图标。`.png` 结尾 ⇒ 纹理；否则按 ItemStack 字符串解析（`BookIcon.from`） |
| `parent` | `parent` | String | 否 | `null` | 父分类 id，**必须是 `domain:name` 全限定形式**。不含 `:` 会抛 `IllegalArgumentException("`parent` must be fully qualified (domain:name)")`（L167-170） |
| `flag` | `flag` | String | 否 | `""` | 配置 flag 表达式；为假时该分类**整条被丢弃**（`loadCategory` 中 `canAdd()` 返回 false ⇒ 不注册） |
| `sortnum` | `sortnum` | int | 否 | `0` | 排序号，越小越靠前 |
| `secret` | `secret` | boolean | 否 | `false` | 隐藏分类：未解锁时**完全不显示**（而不是显示锁头） |

### 3.2 运行时行为要点（影响写书策略）

- **分类 id**＝相对 `<lang>/categories/` 的路径（去掉 `.json`）。例如 `assets/mymod/patchouli_books/my_guide/en_us/categories/getting_started.json` ⇒ `mymod:getting_started`；子目录 `categories/sub/deep.json` ⇒ `mymod:sub/deep`。
- **空分类默认解锁**：`updateLockStatus` 里 `locked = !children.isEmpty() || !entries.isEmpty()`，即没有任何子分类和条目的分类**永远解锁**（L94）。测试书 `empty_subcategory*.json` 系列就是用来验证这点的。
- 排序规则（`compareTo`，L139-150）：先按「是否锁定」（解锁的在前），再 `sortnum`，最后按名称字符串比较。
- 子分类通过 `parent` 挂载；`build()` 会做存在性校验，找不到父分类会抛 `RuntimeException("Category %s specifies parent %s, but it could not be found")`（L157-171）。

### 3.3 真实示例

无子分类、最简：

```json
{
  "name": "Getting Started",
  "description": "An introduction to surviving in the world of TerraFirmaCraft.",
  "icon": "tfc:stone/axe/sedimentary",
  "sortnum": 0
}
```

（来源：TFC jar 内 `assets/tfc/patchouli_books/field_guide/en_us/categories/getting_started.json`）

带 flag 门控的分类：

```json
{
  "name": "Config Flags",
  "description": "Tests for config flag gating.",
  "icon": "minecraft:lever",
  "flag": "mod:gardenofglass",
  "sortnum": 90
}
```

（模式来源：`Xplat/src/main/resources/assets/patchouli/patchouli_books/comprehensive_test_book/en_us/categories/config_flags.json`；flag 用法与 `entries/config_flags/appears_gog_missing.json` 一致）

---

## 4. 条目（entry）JSON 字段全解

**反序列化位置**：`Xplat/src/main/java/vazkii/patchouli/client/book/BookEntry.java` 构造函数（L66-103）。

### 4.1 字段表

| JSON 字段 | Java 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `name` | `name` | String | **是** | —（缺失抛异常） | 条目名。`book.i18n` 决定翻译键还是字面量（L105-107） |
| `category` | `categoryId` | String | **是** | — | 所属分类 id。**必须是全限定 `domain:name`**，否则抛 `IllegalArgumentException("`category` must be fully qualified (domain:name)")`（L71-77） |
| `icon` | `icon`（`BookIcon`） | String | **是** | — | 条目图标，同分类图标的两种写法 |
| `pages` | `pages`（`BookPage[]`） | Array | **是** | — | 页面数组；元素可为对象或**字符串**（字符串会被当作 `patchouli:text` 简写，见 §5.6）。用 `GsonHelper.getAsJsonArray(root,"pages")` 读取，**缺失即抛异常** |
| `advancement` | `advancement` | ResourceLocation | 否 | `null` | 该条目锁定到指定 advancement；未完成时显示为锁定态（`updateLockStatus`，L151-168） |
| `turnin` | `turnin` | ResourceLocation | 否 | `null` | 「待办」标记：未完成该 advancement 时条目显示 `PENDING` 状态（`(?)` 图标） |
| `flag` | `flag` | String | 否 | `""` | 配置 flag 表达式；为假时整条丢弃（`loadEntry` 的 `canAdd()`） |
| `priority` | `priority` | boolean | 否 | `false` | 优先条目：斜体显示并**始终排在最前**（`compareTo` L224-226） |
| `secret` | `secret` | boolean | 否 | `false` | 隐藏条目：未解锁时不显示，且**不计入完成度统计**（`ItemModBook.getCompletion` 跳过 secret） |
| `read_by_default` | `readByDefault` | boolean | 否 | `false` | true ⇒ 不显示「未读」标记（`computeReadState`，L298-315） |
| `sortnum` | `sortnum` | int | 否 | `0` | 排序号 |
| `entry_color` | `entryColor` | String(hex) | 否 | 继承 `book.textColor` | 分类页中该条目链接文字的颜色 |
| `extra_recipe_mappings` | `extraRecipeMappings` | Object(String→int) | 否 | `{}` | 额外的「物品→页码」映射，键为 ItemStack 字符串（支持 `tag:` 前缀），值为 **0 基页号**。用于世界内右键查看与快速查阅（`build()` L250-269） |

### 4.2 真实示例（最小条目）

```json
{
  "name": "Test Entry",
  "icon": "minecraft:writable_book",
  "category": "mymod:test_category",
  "pages": [
    { "type": "patchouli:text", "text": "This is a test entry, but it should show up!" }
  ]
}
```

### 4.3 真实示例（含 priority / 字符串页简写 / 多格式）

`Xplat/src/main/resources/assets/patchouli/patchouli_books/testbook1/en_us/entries/intro/preface.json`（节选）：

```json
{
	"name": "A Preface",
	"icon": "minecraft:writable_book",
	"category": "patchouli:intro",
	"priority": true,
	"read_by_default": false,
	"pages": [
		"$(bold)\"$()$(italic)Humankind cannot gain anything...",
		"You may have assembled this tome yourself...$(br2)Regardless..."
	]
}
```

### 4.4 真实示例（`extra_recipe_mappings` + 标签键）

`.../comprehensive_test_book/en_us/entries/recipe_mapping/extra.json`：

```json
{
  "name": "Extra Recipe Mapping",
  "category": "patchouli:recipe_mapping",
  "icon": "minecraft:stone",
  "pages": [
    { "type": "patchouli:text", "text": {"translate":"patchouli.gui.lexicon.reloaded","with":[69]} },
    { "type": "patchouli:empty" },
    { "type": "patchouli:text", "text": "Logs should be mapped here" }
  ],
  "extra_recipe_mappings": {
    "minecraft:grass_block": 0,
    "tag:minecraft:logs": 2
  }
}
```

### 4.5 真实示例（flag 门控 + advancement 锁定）

```json
{
  "name": "Appears if GoG is missing",
  "category": "patchouli:config_flags",
  "flag": "!mod:gardenofglass",
  "icon": "minecraft:oak_sapling",
  "pages": [ { "type": "patchouli:text", "text": "If this page doesn't appear, Botania will be sad..." } ]
}
```

```json
{
	"name": "Test Entry",
	"icon": "minecraft:textures/item/clock_06.png",
	"category": "patchouli:test",
	"priority": true,
	"read_by_default": false,
	"advancement": "patchouli:test_invis",
	"pages": [ ... ]
}
```

注意 `icon` 也可以是**纹理路径**（`.png` 结尾），如上例。

### 4.6 排序与状态机（写书时的可见后果）

`BookEntry.compareTo`（L211-231）的排序键依次为：

1. 锁定状态（未锁定的在前）；
2. `EntryDisplayState` 枚举序（`UNREAD` < `PENDING` < `NEUTRAL` < `COMPLETED`，见 `EntryDisplayState.java`）；
3. `priority`（true 在前）；
4. `sortnum`；
5. 名称字符串。

`EntryDisplayState` 的四个取值与用途（`Xplat/src/main/java/vazkii/patchouli/client/book/EntryDisplayState.java`）：

| 枚举 | 触发条件 | 语义 |
| --- | --- | --- |
| `UNREAD` | 未读且非 `read_by_default` 且未锁定 | 条目名后显示未读标记 |
| `PENDING` | `turnin` 未完成 | 待办标记 |
| `NEUTRAL` | 默认 | 无标记 |
| `COMPLETED` | 条目内含 `patchouli:quest` 页且已完成 | 完成勾选 |

---

## 5. 全部内置 page 类型清单

### 5.1 注册位置（**唯一真相**）

`Xplat/src/main/java/vazkii/patchouli/client/book/ClientBookRegistry.java`：

```java
public final Map<ResourceLocation, Class<? extends BookPage>> pageTypes = new HashMap<>();   // L27

public void init() { addPageTypes(); }        // L39-41，由 FMLClientSetupEvent 调用

private void addPageTypes() {                 // L43-60，private
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "text"),        PageText.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "crafting"),    PageCrafting.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "smelting"),    PageSmelting.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "blasting"),    PageBlasting.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "smoking"),     PageSmoking.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "campfire"),    PageCampfireCooking.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "smithing"),    PageSmithing.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "stonecutting"),PageStonecutting.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "image"),       PageImage.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "spotlight"),   PageSpotlight.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "empty"),       PageEmpty.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "multiblock"),  PageMultiblock.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "link"),        PageLink.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "relations"),   PageRelations.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "entity"),      PageEntity.class);
    pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "quest"),       PageQuest.class);
}
```

**一共 16 个内置类型**，全部在 `patchouli` 命名空间下。没有 `patchouli:template` 类型的显式注册 —— 它由**未知类型的 fallback** 隐式承担（见 §5.5）。

### 5.2 反序列化机制（决定了字段如何写）

`ClientBookRegistry.LexiconPageAdapter.deserialize`（L97-125）：

```java
if (json instanceof JsonPrimitive prim && prim.isString()) {
    // 字符串简写 → 直接变成 text 页
    var out = new PageText();
    out.setText(prim.getAsString());
    return out;
}
JsonObject obj = json.getAsJsonObject();
String string = GsonHelper.getAsString(obj, "type");
if (string.indexOf(':') < 0) string = PatchouliAPI.MOD_ID + ":" + string;   // 无命名空间 ⇒ 自动补 patchouli:
ResourceLocation type = ResourceLocation.tryParse(string);
Class<? extends BookPage> clazz = ClientBookRegistry.INSTANCE.pageTypes.get(type);
if (clazz == null) clazz = PageTemplate.class;                              // 未知类型 ⇒ 当模板处理
BookPage page = SerializationUtil.RAW_GSON.fromJson(json, clazz);
page.sourceObject = obj;
```

要点：

- **字段名 = Java 字段名**（除标注了 `@SerializedName` 的用注解值），Gson 通过反射直接写私有字段；**不需要 getter/setter**。
- 未在类中声明的 JSON 字段会被**静默忽略**（Gson 默认行为），因此拼错的字段名**不会报错，只会静默失效**。这是最常见的踩坑点。
- `type` 可以省略命名空间（`"text"` 会变成 `patchouli:text`）。
- `BookPage` 里所有 `transient` 字段不会被反序列化（它们是运行时状态）。

### 5.3 公共字段（所有 page 类型共有）

来自 `Xplat/src/main/java/vazkii/patchouli/client/book/BookPage.java` L21-84：

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `type` | String | — | 类型 id，**必填** |
| `flag` | String | `null`（空视为通过） | 配置 flag 表达式；为假时该页被**跳过**（不入 `realPages`，`canAdd` L73-75） |
| `advancement` | String | `null` | advancement 解锁门控；未完成时该页**不显示**（`isPageUnlocked` L52-54） |
| `anchor` | String | `null` | 锚点名，供 `$(l:entry#anchor)` 跳转（`BookEntry.getPageFromAnchor`） |

`BookPage` 的渲染生命周期方法（第三方自定义页面需实现）：

```java
public void build(Level level, BookEntry entry, BookContentsBuilder builder, int pageNum)   // 内容装配（只在加载时一次）
public void onDisplayed(GuiBookEntry parent, int left, int top)                              // 每次显示时（可注册按钮）
public void render(GuiGraphics graphics, int mouseX, int mouseY, float pticks)               // 每帧
public boolean mouseClicked(double mouseX, double mouseY, int mouseButton)                    // 点击，返回是否消费
public boolean canAdd(Book book)                                                              // flag 门控
```

### 5.4 内置 page 类型总表

| # | `type` id | 实现类（相对 `Xplat/src/main/java/`） | 专属字段 | 备注 |
| --- | --- | --- | --- | --- |
| 1 | `patchouli:text` | `vazkii/patchouli/client/book/page/PageText.java` | `title`、`text` | 字符串简写页的落点；`text` 是 `IVariable`，可写文本组件 JSON |
| 2 | `patchouli:crafting` | `.../page/PageCrafting.java` | `recipe`、`recipe2`、`link_recipe`、`link_recipe2`、`title`、`text` | 3×3 合成，双配方 |
| 3 | `patchouli:smelting` | `.../page/PageSmelting.java` | 同上（公共模板） | 单格→单格 |
| 4 | `patchouli:blasting` | `.../page/PageBlasting.java` | 同上 | 高炉 |
| 5 | `patchouli:smoking` | `.../page/PageSmoking.java` | 同上 | 烟熏炉 |
| 6 | `patchouli:campfire` | `.../page/PageCampfireCooking.java` | 同上 | 营火（**注意 id 是 `campfire` 而非 `campfire_cooking`**） |
| 7 | `patchouli:smithing` | `.../page/PageSmithing.java` | 同上 | 1.21 锻造台（模板+基座+添加物） |
| 8 | `patchouli:stonecutting` | `.../page/PageStonecutting.java` | 同上 | 切石机 |
| 9 | `patchouli:image` | `.../page/PageImage.java` | `images`（String[]）、`title`、`border`、`text` | 支持多图切换（左右箭头） |
| 10 | `patchouli:spotlight` | `.../page/PageSpotlight.java` | `item`（`IVariable`）、`title`、`link_recipe`、`text` | 展示单个/一组物品并轮播 |
| 11 | `patchouli:empty` | `.../page/PageEmpty.java` | `draw_filler`（boolean，默认 `true`） | 空白页 |
| 12 | `patchouli:multiblock` | `.../page/PageMultiblock.java` | `name`、`multiblock_id`、`multiblock`、`enable_visualize`、`text` | 见 §10 |
| 13 | `patchouli:link` | `.../page/PageLink.java` | `url`、`link_text`，**并继承 PageText 的全部字段** | 底部一个打开网址的按钮 |
| 14 | `patchouli:relations` | `.../page/PageRelations.java` | `entries`（String[]）、`title`、`text` | 相关条目按钮列表 |
| 15 | `patchouli:entity` | `.../page/PageEntity.java` | `entity`、`scale`、`offset`、`name`、`rotate`、`default_rotation`、`text` | 3D 渲染实体 |
| 16 | `patchouli:quest` | `.../page/PageQuest.java` | `trigger`、`title`、`text` | 任务页；无 `trigger` ⇒ 手动完成按钮 |

### 5.5 未知 `type` 的行为（模板机制的核心）

`LexiconPageAdapter` 在 `pageTypes` 中查不到时回退到 `PageTemplate`。`PageTemplate.build`（`PageTemplate.java` L18-31）：

```java
if (!resolved) {
    template = BookTemplate.createTemplate(book, builder, type, null);   // 用 type 作为模板 id 去找模板
    resolved = true;
}
JsonVariableWrapper wrapper = new JsonVariableWrapper(sourceObject);
template.compile(level, builder, wrapper);
template.build(builder, this, entry, pageNum);
```

`BookTemplate.createTemplate`（`BookTemplate.java` L60-78）：`type` 含 `:` 时直接用，否则拼上**书籍的命名空间**（不是 `patchouli`），然后从 `builder.getTemplate(key)` 取模板；取不到就抛 `IllegalArgumentException("Template " + key + " does not exist")`。

**所以：「自定义 page 类型」的标准做法是「写一个模板 + 在条目里用同名 `type` 引用」，而不是注册 Java 类。** TFC 正是这么做的：

- 条目里写 `"type": "tfc:heat_recipe"`（见 TFC `assets/tfc/patchouli_books/field_guide/en_us/entries/getting_started/firepit.json`）
- 对应模板文件 `assets/tfc/patchouli_books/field_guide/en_us/templates/heat_recipe.json`（全文）：
  ```json
  {"components":[
    {"type":"patchouli:custom","x":0,"y":0,
     "class":"net.dries007.tfc.compat.patchouli.component.HeatingComponent","recipe":"#recipe"},
    {"type":"patchouli:text","x":0,"y":45,"text":"#text"}]}
  ```
- 进一步核实：在 TFC jar 的全部 class 中搜索字符串 `heat_recipe`，**零命中**，证明 `tfc:heat_recipe` 不是注册的 page 类型，而是模板 id。

### 5.6 字符串简写

`pages` 数组中的字符串元素等价于一个 `patchouli:text` 页：

```json
"pages": [
    "These two pages are equivalent",
    { "type": "patchouli:text", "text": "These two pages are equivalent" }
]
```

（实现：`LexiconPageAdapter` 中 `if (json instanceof JsonPrimitive prim && prim.isString())`，`PageText.setText`。）

### 5.7 逐类型字段细表

**`patchouli:text`**（`PageText` 继承 `PageWithText`）

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `text` | `IVariable`（String 或 文本组件 JSON） | 无（null ⇒ 视为空串） | 正文，可含格式化代码 |
| `title` | String | `null` | 页面标题；**第 0 页（首页）会改为显示条目名 + 分隔线**，此处 `title` 无效（`PageText.render` L36-58） |

**`patchouli:image`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `images` | String[]（ResourceLocation） | 无 | 图片资源 id 数组；多张时出现左右切换箭头（`onDisplayed` L26-30） |
| `title` | String | `null` | 顶部标题 |
| `border` | boolean | `false` | 是否画 106×106 的边框纹理 |
| `text` | String | — | 图片下方文字（`getTextHeight() = 120`） |

图片按 **0.5 倍缩放**绘制（`graphics.pose().scale(0.5F,0.5F,0.5F)`，`blit` 区域 200×200），官方建议图片做成 256×256、内容只占左上 200×200。

**`patchouli:spotlight`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `item` | `IVariable`（字符串或列表） | 无 | 展示的物品。字符串形式支持逗号分隔多个、支持 `tag:` 前缀（如 `"tag:minecraft:wool,minecraft:bone"`） |
| `title` | String | `null` | 空则用第一个物品的名字 |
| `link_recipe` | boolean | `false` | true ⇒ 把本页登记为该物品的「配方页」（`build` 中 `entry.addRelevantStack`） |
| `text` | String | — | 下方文字 |

物品按 `(ticksInBook / 20) % stacks.length` 轮播（每 20 tick 换一个）。

**`patchouli:entity`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `entity` | String（`@SerializedName("entity")`，Java 字段 `entityId`） | 无 | 实体 id，可用 `{...}` 附加 NBT，如 `minecraft:creeper{powered:1}`、`minecraft:slime{Size:2}` |
| `scale` | float | `1.0` | 缩放；负值会上下翻转 |
| `offset` | float（`@SerializedName("offset")`，Java 字段 `extraOffset`） | `0.0` | 垂直偏移 |
| `name` | String | `null` | 空则用实体自身名称 |
| `rotate` | boolean | `true` | 是否持续旋转 |
| `default_rotation` | float | `-45` | `rotate=false` 时使用的固定角度 |
| `text` | String | — | 下方文字 |

**`patchouli:quest`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `trigger` | ResourceLocation | `null` | 完成该 advancement 即视为完成；**缺省即手动模式**（页面上出现「标记完成/未完成」按钮，记录在 `patchouli_data.json`） |
| `title` | String | `null` | 空则显示 `patchouli.gui.lexicon.objective` |
| `text` | String | — | 正文 |

注意：`trigger` 字段类型是 `ResourceLocation`，Gson 由 `SerializationUtil.RAW_GSON` 中注册的 `ResourceLocation.Serializer` 处理；写错格式会抛解析异常。

**`patchouli:relations`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `entries` | String[]（→ `List<String>`） | 无（null 会在 `build` 里 NPE） | 目标条目 id 列表；**找不到会抛 `IllegalArgumentException("Could not find entry ...")`**，因此必须写全限定 id |
| `title` | String | `null` | 空则显示 `patchouli.gui.lexicon.relations` |
| `text` | String | — | 正文（列表项之下） |

**`patchouli:link`**（继承 `PageText`）

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `url` | String | 无 | 点击打开的网址 |
| `link_text` | `IVariable`（`@SerializedName("link_text")`，Java 字段 `linkText`） | 无 | 按钮文字 |
| （继承）`text`、`title` | | | 与 text 页一致 |

**`patchouli:empty`**

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `draw_filler` | boolean（`@SerializedName("draw_filler")`，Java 字段 `filler`） | `true` | 是否绘制页脚填充图形 |

**配方类页面（1-8）的公共字段**

来自 `Xplat/src/main/java/vazkii/patchouli/client/book/page/abstr/PageDoubleRecipe.java` L17-24：

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `recipe` | ResourceLocation | 无 | 第一个配方 id |
| `recipe2` | ResourceLocation | 无 | 第二个配方 id（可省略） |
| `link_recipe` | boolean | `true` | 是否把配方产物登记为「本页教学」（`@SerializedName("link_recipe")`） |
| `link_recipe2` | boolean | `true` | 同上，针对第二个配方 |
| `title` | String | `null` | 自定义标题；设置后不再显示产物名 |
| `text` | String | — | 配方下方文字（**当有两个产物不同的配方且未设 `title` 时，`shouldRenderText()` 为 false，文字不显示**） |

各类型使用的 `RecipeType`（构造器）与高度：

| type | RecipeType | 单页高度 |
| --- | --- | --- |
| `crafting` | `RecipeType.CRAFTING` | 78 |
| `smelting` | `RecipeType.SMELTING` | 45 |
| `blasting` | `RecipeType.BLASTING` | 45 |
| `smoking` | `RecipeType.SMOKING` | 45 |
| `campfire` | `RecipeType.CAMPFIRE_COOKING` | 45 |
| `stonecutting` | `RecipeType.STONECUTTING` | 45 |
| `smithing` | `RecipeType.SMITHING` | 60 |

配方查找逻辑（`PageDoubleRecipeRegistry.loadRecipe`，L31-50）：先按给定 id 查 `RecipeManager.byKey` 并要求 `recipe.getType() == recipeType`；**查不到时再尝试 `crafttweaker:<path>`** 作为兼容 hack；仍失败只记 warn 日志（不抛异常，页面显示为空）。另外 `recipe1 == null && recipe2 != null` 时会把第二个提上来当第一个（L33-36），所以只写 `recipe2` 也能显示。

---

## 6. 模板系统（template / include / using / processor / 组件 / 变量）

模板系统是 Patchouli 的**通用扩展点**：它同时承担「自定义页面类型」、「自定义组件」、「代码派生数据」三种角色。**对本仓库（TFC 附属）而言，这是最重要的一章** —— TFC 的全部自定义展示都建立在此之上。

### 6.1 模板文件位置与 id

- 路径：`assets/<namespace>/patchouli_books/<book>/<lang>/templates/**.json`（可放子目录）。
- 模板 id＝相对 `templates/` 的路径（去 `.json`）+ 命名空间，例如 `templates/heat_recipe.json` ⇒ `tfc:heat_recipe`；`templates/include/namenumber.json` ⇒ `patchouli:include/namenumber`。
- 加载与缓存：`BookContentsBuilder.loadTemplate`（L172-184）**先实例化一次做校验**，之后以 `Supplier` 形式缓存（每次使用模板都会重新反序列化一份新实例，这是为了避免模板间状态串味）。

> **注意**：模板 id 的命名空间来自**文件所在 assets 的命名空间**，而不是书所属的 mod。附属模组往别人的书里加模板时，id 会带上附属模组自己的命名空间。
> 而 `BookTemplate.createTemplate` 在没有 `:` 时补的是**书的命名空间**（`book.id.getNamespace()`）。

### 6.2 `BookTemplate` 字段全表

`Xplat/src/main/java/vazkii/patchouli/client/book/template/BookTemplate.java` L43-58：

| JSON 字段 | Java 字段 | 类型 | 必填 | 默认 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `components` | `components` | `List<TemplateComponent>` | 否（实践中必写） | 空列表 | 组件数组，**按顺序绘制**（后面的覆盖前面的） |
| `include` | `inclusions`（`@SerializedName("include")`） | `List<TemplateInclusion>` | 否 | 空列表 | 引入其它模板，见 §6.5 |
| `processor` | `processorClass`（`@SerializedName("processor")`） | String | 否 | `null` | **组件的完整 Java 类名**（不是 type id！），见 §6.6 |

反序列化用的 Gson 实例是 `ClientBookRegistry.INSTANCE.gson`，它为 `TemplateComponent` 注册了 `TemplateComponentAdapter`（按 `type` 选类）。

### 6.3 组件（component）的公共字段

`Xplat/src/main/java/vazkii/patchouli/client/book/template/TemplateComponent.java` L25-41：

| JSON 字段 | Java 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `type` | —（由 adapter 读取） | String | — | 组件类型 id，**必填** |
| `x` | `x` | int | `0` | 组件在页面内的 X 坐标（被 include 时再加上父级偏移） |
| `y` | `y` | int | `0` | Y 坐标 |
| `group` | `group` | String | `""` | 组名，配合 `IComponentProcessor.allowRender(group)` 由代码控制显隐 |
| `flag` | `flag` | String | `""` | 配置 flag 表达式，为假则不显示 |
| `advancement` | `advancement` | String | `""` | advancement 门控 |
| `negate_advancement` | `negateAdvancement`（`@SerializedName("negate_advancement")`） | boolean | `false` | true ⇒ 未完成该 advancement 时才显示 |
| `guard` | `guard` | String | `null` | 变量函数表达式；解析结果为 `false` 或空串则**不显示**（`getVisibleStatus` L57-75） |

四条可见性判定的**短路顺序**（`getVisibleStatus`）：

```java
if (processor != null && group 非空 && !processor.allowRender(group)) return false;
if (!guardPass) return false;                 // guard 解析结果
if (!flag.isEmpty() && !PatchouliConfig.getConfigFlag(flag)) return false;
if (!advancement.isEmpty()) return ClientAdvancements.hasDone(advancement) != negateAdvancement;
return true;
```

> `guardPass` 初始为 `false`，只在 `onVariablesAvailable` 中根据 `guard` 变量求值后更新，因此**未解析变量前组件一律不可见**（这是设计使然）。

### 6.4 内置组件类型全表（**9 种**）

注册位置：`BookTemplate` 静态块（L31-41），注册表是 `public static final HashMap<ResourceLocation, Class<? extends TemplateComponent>> componentTypes`（L29）。

| # | `type` id | 实现类（`client/book/template/component/`） | 专属字段（类型 / 默认值） |
| --- | --- | --- | --- |
| 1 | `patchouli:text` | `ComponentText.java` | `text`（IVariable）、`color`（IVariable，键名 `color`，Java 字段 `colorStr`）、`max_width`（int，默认 `GuiBook.PAGE_WIDTH`=116）、`line_height`（int，默认 `GuiBook.TEXT_LINE_HEIGHT`=9） |
| 2 | `patchouli:item` | `ComponentItemStack.java` | `item`（IVariable，支持多物品数组轮播）、`framed`（boolean，默认 false）、`link_recipe`（boolean，默认 false） |
| 3 | `patchouli:image` | `ComponentImage.java` | `image`（String）、`u`、`v`、`width`、`height`（int，默认 0）、`texture_width`（int，默认 256）、`texture_height`（int，默认 256）、`scale`（float，默认 1） |
| 4 | `patchouli:header` | `ComponentHeader.java` | `text`（IVariable）、`color`（IVariable）、`centered`（boolean，默认 true）、`scale`（float，默认 1）。**`x == -1` 时自动居中，`y == -1` 时自动对齐标题位**（`build` L38-43） |
| 5 | `patchouli:separator` | `ComponentSeparator.java` | 无专属字段。`x == -1 ⇒ 0`，`y == -1 ⇒ 12` |
| 6 | `patchouli:frame` | `ComponentFrame.java` | 无专属字段。`x == -1 ⇒ PAGE_WIDTH/2-53`，`y == -1 ⇒ 7` |
| 7 | `patchouli:entity` | `ComponentEntity.java` | `entity`（IVariable，键名 `entity`）、`render_size`（float，默认 `100`）、`rotate`（boolean，默认 true）、`default_rotation`（float，默认 -45） |
| 8 | `patchouli:tooltip` | `ComponentTooltip.java` | `tooltip`（IVariable[]，键名 `tooltip`，Java 字段 `tooltipRaw`）、`width`（int）、`height`（int） |
| 9 | `patchouli:custom` | `ComponentCustom.java` | `class`（String，**完整类名**）+ 该自定义类自身的所有非 transient 字段 |

`patchouli:custom` 的工作方式（`ComponentCustom.java` L19-56）：

```java
@SerializedName("class") String clazz;
private transient ICustomComponent callbacks;

@Override
public void onVariablesAvailable(UnaryOperator<IVariable> lookup, HolderLookup.Provider registries) {
    super.onVariablesAvailable(lookup, registries);
    Class<?> classObj = Class.forName(clazz);
    callbacks = (ICustomComponent) SerializationUtil.RAW_GSON.fromJson(sourceObject, classObj);
    callbacks.onVariablesAvailable(lookup, registries);
}
```

即：**用整页 JSON 对象（`sourceObject`）反序列化出你的 `ICustomComponent` 实例**，因此你的自定义组件类可以直接声明与 JSON 同名的字段（TFC 的 `HeatingComponent` 就声明了 `recipe` 字段，并由模板里的 `"recipe":"#recipe"` 传入）。

真实模板示例（TFC）：见 §5.5 与 §15。

官方测试模板 `assets/patchouli/patchouli_books/testbook2/en_us/templates/test_template.json`：

```json
{
	"components": [
		{ "type": "patchouli:text", "text": "#text", "x": 20, "y": 30 },
		{ "type": "patchouli:text", "text": "#text2", "x": 6, "y": 55,
		  "max_width": 40, "line_height": 12, "color": "007700" },
		{ "type": "patchouli:item", "item": "#item", "x": 60, "y": 50, "framed": true, "link_recipe": true },
		{ "type": "patchouli:item", "item": "minecraft:gold_ingot", "x": 60, "y": 80 },
		{ "type": "patchouli:image", "image": "minecraft:textures/painting/paintings_kristoffer_zetterstrand.png",
		  "x": 50, "y": 100, "u": 160, "v": 128, "width": 32, "height": 32 },
		{ "group": "header", "type": "patchouli:header", "text": "Template Test", "x": -1 },
		{ "group": "header", "type": "patchouli:separator", "y": 12 }
	]
}
```

### 6.5 include / using（模板嵌套与变量绑定）

`Xplat/src/main/java/vazkii/patchouli/client/book/template/TemplateInclusion.java`：

| JSON 字段 | Java 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| `template` | `template` | String | **是** | 被引入的模板 id |
| `as` | `as` | String | **是** | 该引入的命名前缀（用于限定变量名）。**必须在同一模板内唯一** |
| `using` | `localBindings`（`@SerializedName("using")`） | JsonObject | 否 | 变量绑定：`{"子模板变量名": "值或 #上层变量"}` |
| `x` / `y` | `x` / `y` | int | 否（0） | 被引入模板内所有组件的坐标偏移（会累加父级偏移） |

硬校验（`BookTemplate.compile` L101-105）：

```java
if (include.template == null || include.template.isEmpty() || include.as == null || include.as.isEmpty()) {
    throw new IllegalArgumentException("Template inclusion must define both \"template\" and \"as\" fields.");
}
```

- **循环引入会被检测并抛异常**：`TemplateInclusion.upperMerge` 中 `"Breaking when include template %s, circular dependencies aren't allowed"`（L48-50），检查位置在 L106 调用。
- 变量解析顺序（`wrapProvider` L119-132 与 `VariableAssigner.resolveStringVar` L111-143）：先在 `using` 本地绑定里找 → 再找父级限定名（`as.变量名`）→ 再问 processor → 最后回落 `variables.get(key)`。
- `using` 值以 `#` 开头 ⇒ 表示「指向上层模板的变量」，在 `upperMerge` 中会被向上提升/解析（L58-67、L70-86）。

真实示例 `assets/patchouli/patchouli_books/testbook2/en_us/templates/include/recipetest.json`（节选）：

```json
{
    "processor": "vazkii.patchouli.client.book.template.test.RecipeTestProcessor",
    "include": [
        { "template": "patchouli:include/namenumber", "as": "nn",
          "using": { "iname": "#iname", "icount": "#icount" }, "x": 70, "y": 20 }
    ],
    "components": [
        { "type": "patchouli:item", "item": "#item1", "x": 4, "y": 10 },
        ...
    ]
}
```

### 6.6 `processor`：组件处理器（**类名反射，无 type id**）

机制（`BookTemplate.createProcessor`，L164-177）：

```java
if (processorClass != null && !processorClass.isEmpty()) {
    try {
        Class<?> clazz = Class.forName(processorClass);
        processor = (IComponentProcessor) clazz.newInstance();
    } catch (Exception e) {
        throw new RuntimeException("Failed to create component processor " + processorClass, e);
    }
}
```

- `"processor"` 的值是**完整类名**，如 `"vazkii.patchouli.client.book.template.test.RecipeTestProcessor"`。
- 用 `Class.forName` + `newInstance()` ⇒ **实现类必须有无参构造器**，且必须**存在于客户端 classpath**（否则 `RuntimeException`）。
- 调用时机（`compile` L80-119）：`createProcessor()` → （若被 include）`include.wrapProvider(variables)` → `processor.setup(level, processorVars)` → 每个 include 的 `include.process(level, processor)` → 每个组件 `compile(...)`。
- `processor.refresh(parent, left, top)` 在**每次显示时**由 `BookTemplate.onDisplayed` 调用（L127-136）。
- **不存在** `patchouli:macros` / `patchouli:flags` 这类 processor 类型，也不存在 `ProcessorMacros`/`ProcessorFlags` 类（全仓库 grep 零命中，已核实）。

### 6.7 变量（variable）系统

**语法总览**（`VariableAssigner.java`）：

| 语法 | 含义 | 实现位置 |
| --- | --- | --- |
| `"#name"` | 引用变量（整字段引用） | `resolveStringVar` L119-141 |
| `"前缀 #name 后缀"` | 字符串内联插值，可多次 | `INLINE_VAR_PATTERN = ([^#]*)(#[^#]+)#(.*)`，L28、L70-80 |
| `"#name->func"` | 派生函数（可链式 `->a->b`） | `FUNCTION_PATTERN = (.+)->(.+)`，L29、L91-104 |

**内建派生函数全表**（`VariableAssigner` 静态块 L32-46）：

| 函数 | 作用 |
| --- | --- |
| `iname` | ItemStack 变量 → 物品显示名 |
| `icount` | ItemStack 变量 → 堆叠数量 |
| `ename` | 实体 id → 实体显示名（`EntityUtil.getEntityName`） |
| `lower` / `upper` / `trim` | 字符串小写 / 大写 / 去首尾空白 |
| `capital` / `fcapital` | 首字母大写 / 每个单词首字母大写（`WordUtils`） |
| `i18n` | 把值当作翻译键取本地化文本（`I18n.get`） |
| `exists` | 值非 JsonNull ⇒ `true` |
| `iexists` | ItemStack 变量非空 ⇒ `true` |
| `inv` | 布尔取反 |
| `stacks` | Ingredient → 其物品数组（`arg.as(Ingredient.class).getItems()`） |

变量查找链（`resolveStringVar`）：若以 `#` 开头 → 先试 `encapsulation.attemptVariableLookup`（include 的 `using`）→ 再 `processor.process(level, key)` → 再 `variables.get(key)` → 都没有则 `IVariable.empty()`。

变量提供者：

| 提供者 | 作用 | 源码 |
| --- | --- | --- |
| `JsonVariableWrapper` | 把**页面 JSON 对象本身**当变量源，缺键抛 `IllegalArgumentException("Attempted to get variable " + key + " when it's not present")` | `client/book/template/JsonVariableWrapper.java` |
| `TemplateInclusion.wrapProvider(...)` | 为被 include 的模板加一层「本地绑定 + 限定名」的解析 | `TemplateInclusion.java` L119-132 |

> 因此：**页面对象里的顶层字段就是模板可用的变量**（`{"type":"tfc:heat_recipe","recipe":"...","text":"..."}` ⇒ 模板里 `#recipe`、`#text` 可用）。

### 6.8 变量序列化（可放到变量里的对象类型）

`Xplat/src/main/java/vazkii/patchouli/client/book/template/variable/VariableHelperImpl.java` 注册的序列化器（构造器中）：

| 目标类型 | 序列化器 | 行为要点 |
| --- | --- | --- |
| `ItemStack` | `ItemStackVariableSerializer` | JsonNull→`ItemStack.EMPTY`；字符串→`ItemStackUtil.loadStackFromString`；对象→按 `{"item":...,"count":...,"components":...}` 读 |
| `ItemStack[]` | `ItemStackArrayVariableSerializer` | 字符串会经 `loadStackListFromString` **展平**（一个字符串可展开多个物品，支持 `tag:`）；对象→单元素数组 |
| `Ingredient` | `IngredientVariableSerializer` | 字符串→`ItemStackUtil.loadIngredientFromString`；否则走 `Ingredient.CODEC` |
| `Component` | `TextComponentVariableSerializer` | JsonNull→空串组件；**字符串按字面量**（不走文本组件 JSON）；其它走 `Component.Serializer` |
| 任意 `T[]` | `GenericArrayVariableSerializer`（动态生成并缓存） | 由 `serializerForClass` 对数组类型递归取得元素序列化器后构造 |

`IVariable.as(Class)` 在**未注册序列化器时抛 `IllegalArgumentException("Can't deserialize object of class %s from IVariable")`**（`Variable.java` 实现；注意 `IVariable.as` 的 javadoc 说返回 null，**以实现为准**）。

第三方可通过 `VariableHelper.instance().registerSerializer(serializer, clazz)` 注册新的可序列化类型。

---

## 7. 门控：flag 与 advancement

### 7.1 配置 flag（Config Flags）

**求值实现**：`Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliConfig.java` L42-89。

| 表达式形式 | 语义 |
| --- | --- |
| `flag` | 直接取该 flag 的布尔值 |
| `!flag` | 取反 |
| `&a,b,c` | 全部为真（AND） |
| `|a,b,c` | 任一为真（OR） |

细节：flag 名会被 `trim().toLowerCase(Locale.ROOT)`；**未定义的 flag 默认 false**，并且如果不是以 `mod:` 开头会打一条 `Queried for unknown config flag: {}` 警告（L57-64）—— 写错 flag 名时日志里能直接看到。

**内置 flag**（`reloadBuiltinFlags` L27-40）：

| flag | 含义 |
| --- | --- |
| `mod:<modid>` | 该 mod 已加载（每个已加载 mod 都会置 `true`） |
| `debug` | 开发环境（`isDevEnvironment()`） |
| `advancements_disabled` | 配置项 `disableAdvancementLocking` 为真 |
| `testing_mode` | 配置项 `testingMode` 为真 |
| `advancements_disabled_<bookid>` | 该书出现在 `noAdvancementBooks` 列表中 |

**第三方自定义 flag**：`PatchouliAPI.get().setConfigFlag(String flag, boolean value)`（线程安全，建议带自己 mod id 前缀）。

**可挂 flag 的位置**（全部核实）：分类 `flag`、条目 `flag`、页面 `flag`、模板组件 `flag`。

### 7.2 advancement 锁定

| 位置 | 字段 | 行为 |
| --- | --- | --- |
| 条目 | `advancement` | 未完成 ⇒ 条目锁定（`BookEntry.isLocked`）；若同时 `secret: true`，则**完全不显示**（`shouldHide`） |
| 条目 | `turnin` | 未完成 ⇒ 显示 `PENDING`（待办）状态 |
| 页面 | `advancement` | 未完成 ⇒ 该页**从页面列表中移除**（不显示、不占页） |
| 分类 | （无 advancement 字段） | 分类的锁定状态由「是否有未锁定的子分类/条目」推导（`BookCategory.updateLockStatus` L84-113） |
| 模板组件 | `advancement` + `negate_advancement` | 见 §6.3 |

判定实现：`ClientAdvancements.hasDone(String)` 查客户端 `ClientAdvancements.getProgress()`（`Xplat/src/main/java/vazkii/patchouli/client/base/ClientAdvancements.java` L39-54）。因此**锁定的解除完全依赖客户端收到的 advancement 数据包**。

全局开关：配置项 `disableAdvancementLocking`（真 ⇒ 所有 adv 门控失效）；ServerConfig 侧的 `noAdvancementBooks` 列表可对单本书关闭。

**触发书内 advancement 的机制**：Patchouli 自带一个 criterion trigger，id 为 `patchouli:open_book`，条件字段为 `book`（必填）、`entry`（可选）、`page`（可选，`MinMaxBounds.Ints`，默认任意）。来源：`Xplat/src/main/java/vazkii/patchouli/common/advancement/BookOpenTrigger.java` L21-45。可用它做「打开某书某页」的进度：

```json
{
  "criteria": {
    "opened": {
      "trigger": "patchouli:open_book",
      "conditions": { "book": "mymod:my_guide", "entry": "mymod:getting_started/basics", "page": 2 }
    }
  }
}
```

---

## 8. 文本格式（`$(...)` 命令与宏）

**解析实现**：`Xplat/src/main/java/vazkii/patchouli/client/book/text/BookTextParser.java`。命令正则 `COMMAND_PATTERN = \$\(([^)]*)\)`（L266），未知命令会**原样保留**为 `$(cmd)` 文本。

### 8.1 命令全表（**逐条来自源码静态注册块** L51-210）

| 命令 | 含义 | 源码位置 |
| --- | --- | --- |
| `$(0)`–`$(f)` | 原版颜色代码 | `colorCodeProcessor` L319-325 |
| `$(#rrggbb)` / `$(#rgb)` | 十六进制颜色（3 位会展开为 6 位） | `colorHexProcessor` L327-343 |
| `$(li)` / `$(li2)` / `$(li3)`… | 列表项，数字决定缩进（`pad = dist*4`）与符号（奇=•，偶=◦） | `listProcessor` L345-357 |
| `$(br)` | 换行 | L57-60 |
| `$(br2)` / `$(2br)` / `$(p)` | 空一行（段落） | L61-64 |
| `$(k)` / `$(obf)` | 随机乱码 | L80-83 |
| `$(l)` / `$(bold)` | 加粗 | L84-87 |
| `$(m)` / `$(strike)` | 删除线 | L88-91 |
| `$(n)` / `$(underline)` | 下划线 | L92-95 |
| `$(o)` / `$(italic)` / `$(italics)` | 斜体 | L96-99 |
| `$()` / `$(reset)` / `$(clear)` | 重置全部样式 | L100-103 |
| `$(nocolor)` | 回到基础颜色 | L104-107 |
| `$(k:keybind)` | 显示按键名（找不到则显示 `N/A` 并带缺失提示 tooltip） | L109-118、`getKeybindKey` L375-387 |
| `$(l:目标)` | 内部链接。`目标` 为条目 id 或分类 id（同名时条目优先）；`entry#anchor` 跳到锚点页 | L119-183 |
| `$(l:https://...)` | 外部链接（`^https?:.*` 判定） | 同上 L123-132 |
| `$(/l)` | 结束链接 | L66-73 |
| `$(t:文本)` / `$(tooltip:文本)` | 悬停提示 | L184-188 |
| `$(/t)` | 结束提示 | L74-78 |
| `$(c:/命令)` / `$(command:/命令)` | 点击后为玩家发送命令（**必须带前导 `/`**） | L189-202 |
| `$(/c)` | 结束命令 | L203-209 |
| `$(playername)` | 玩家名 | L79 |

注意两处易混：`$(k)` 与 `$(k:xxx)` —— 前者来自 `CommandProcessor` 的 `"k"`，后者来自 `FunctionProcessor` 的 `"k"`；查找顺序决定了带 `:` 的走函数分支（`lookupFunctionProcessor` 在 `lookupCommandProcessor` 之前，L52-56）。

### 8.2 第三方注册文本命令 / 函数

```java
// 仅客户端；BookTextParser.register(...)
PatchouliAPI.get().registerCommand(String name, Function<IStyleStack, String> command);
PatchouliAPI.get().registerFunction(String name, BiFunction<String, IStyleStack, String> function);
```

`registerFunction` 注册的函数可用 `$(name:参数)` 语法调用。TFC 的真实用法：注册了 `cfg` 函数以支持 `$(cfg:temperature)`、`$(cfg:heat)` 等，运行期读取 TFC 自己的配置值（类 `net.dries007.tfc.compat.patchouli.ConfigTextFunction`，由 `PatchouliClientEventHandler` 在 `NeoForge.EVENT_BUS` 上注册）。其正则 `\$\(cfg:([^)]*)\)` 与 `IPatchouliAPI.registerFunction` 的调用在 class 常量池中均可核实。

### 8.3 宏（macros）

展开逻辑（`expandMacros` L238-264）：**反复**对文本做全量 `String.replace(key, value)`，直到不再变化，最多 **10 轮**；超过 10 轮会打警告 `"Expanded macros for {} iterations without reaching fixpoint"`。因此**宏的左值可以是任意字符串**（不限于 `$(...)` 形式），但要避免循环替换。

内置宏（`Book.DEFAULT_MACROS`）：`$(list`→`$(li`、`/$`→`$()`、`<br>`→`$(br)`、`$(item)`→`$(#b0b)`、`$(thing)`→`$(#490)`。

自定义宏写在 `book.json` 的 `macros` 对象里，例如：

```json
"macros": {
  "$(potato)": "$(#F00)POTATO SALAD$()",
  "<b>": "$(l)",
  "<i>": "$(o)",
  "</>": "$()"
}
```

### 8.4 文本组件（JSON 形式）也能用

`PageText.text` 与若干组件的文本字段类型是 `IVariable`，因此可以直接给一个文本组件对象。真实示例（`comprehensive_test_book/.../deserialization/test.json`）：

```json
{
  "type": "patchouli:text",
  "text": {
    "translate": "patchouli.gui.lexicon.edition_str",
    "with": ["Using the edition translation string with $(4)cool text..."]
  }
}
```

---

## 9. ItemStack 字符串与图标格式

### 9.1 解析实现

`Xplat/src/main/java/vazkii/patchouli/common/util/ItemStackUtil.java`：

```java
public static Triple<Holder<Item>, DataComponentPatch, Integer> deserializeStack(String string, HolderLookup.Provider registries) {
    StringReader reader = new StringReader(string.trim());
    ItemParser itemParser = new ItemParser(registries);          // 原版命令解析器
    ItemParser.ItemResult result = itemParser.parse(reader);
    int count = 1;
    if (reader.canRead()) { reader.expect('#'); count = reader.readInt(); }   // #数量
    return Triple.of(result.item(), result.components(), count);
}
```

- 使用的是 **1.21.1 原版 `ItemParser`**，即 `/give` 命令的语法 ⇒ 物品 id + **`[数据组件]`** + `#数量`。
- 多物品（用于 `spotlight.item`、`extra_recipe_mappings` 的键等）：`loadStackListFromString` 会按**顶层逗号**切分（`splitStacksFromSerializedIngredient` 正确处理了 `{}`/`[]`/字符串内的逗号，L141-188），并且以 `tag:` 开头的片段会展开为该标签下所有物品。
- 对象形式（`{"item":"...","count":N,"components":{...}}`）由 `loadStackFromJson` 处理（L190-204）。

**未能核实**：`web/docs/patchouli-advanced/itemstack-format.md` 仍描述 `namespace:path{nbt}` 花括号 NBT 写法。本 tag 的源码只调用了原版 `ItemParser`，**源码中没有任何 `{}` NBT 的专门处理**。该写法在 1.21.1 是否仍被原版解析器接受，本文**未能核实**（需要实际运行验证）。建议**一律使用 1.21.1 的数据组件写法**：

```
minecraft:stone                                  # 单位物品
minecraft:stone#64                               # 64 个
minecraft:diamond_sword[unbreakable={}]          # 带数据组件
minecraft:stone,minecraft:dirt#4                 # 多物品
tag:minecraft:logs                               # 标签（展开为所有成员）
```

### 9.2 图标（icon / index_icon）两种写法

`Xplat/src/main/java/vazkii/patchouli/client/book/BookIcon.java` L31-43：

```java
static BookIcon from(String str, HolderLookup.Provider registries) {
    if (str.endsWith(".png")) return new TextureIcon(ResourceLocation.tryParse(str));
    try { return new StackIcon(ItemStackUtil.loadStackFromString(str, registries)); }
    catch (Exception e) { LOGGER.warn("Invalid icon item stack: {}", e.getMessage()); return new StackIcon(ItemStack.EMPTY); }
}
```

- **以 `.png` 结尾** ⇒ 当作 16×16 的纹理资源 id（例：`minecraft:textures/item/clock_06.png`）。
- 否则 ⇒ 按 ItemStack 字符串（例：`minecraft:diamond`、`tfc:stone/axe/sedimentary`）。
- 解析失败只记 warn 并显示空图标（**不会崩溃**）。
- `book.json` 的 `index_icon` 同样走这个逻辑；空串时使用书籍物品自身。

---

## 10. 多块（multiblock）

### 10.1 `patchouli:multiblock` 页面字段

`Xplat/src/main/java/vazkii/patchouli/client/book/page/PageMultiblock.java` L54-85：

| JSON 字段 | Java 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `name` | `name` | String | `""` | 顶部标题（会经 `i18n()` 处理） |
| `multiblock_id` | `multiblockId`（`@SerializedName("multiblock_id")`） | ResourceLocation | `null` | 引用**代码注册**的多块（`PatchouliAPI.get().registerMultiblock`） |
| `multiblock` | `serializedMultiblock`（`@SerializedName("multiblock")`） | Object（`SerializedMultiblock`） | `null` | **内联定义**的多块 |
| `enable_visualize` | `showVisualizeButton`（`@SerializedName("enable_visualize")`） | boolean | `true` | 是否显示「视觉化」按钮 |
| `text` | （继承 `PageWithText`） | String | — | 下方文字 |

解析顺序与失败行为（`build` L67-85）：先按 `multiblock_id` 从 `MultiblockRegistry.MULTIBLOCKS` 查（且要求是 `AbstractMultiblock` 实例）；查不到再用内联 `multiblock`；两者都拿不到 ⇒ `IllegalArgumentException("No multiblock located for " + multiblockId)`。

### 10.2 内联多块 JSON 字段全表

`Xplat/src/main/java/vazkii/patchouli/common/multiblock/SerializedMultiblock.java`（**全部字段，就这 5 个**）：

| JSON 字段 | Java 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `pattern` | `densePattern`（`@SerializedName("pattern")`） | `String[][]` | `null` | 稠密模式：**外层按 Y（从上到下）、内层按 X（西→东）、字符串内按 Z（北→南）** |
| `sparse_pattern` | `sparsePattern`（`@SerializedName("sparse_pattern")`） | `Map<String, List<List<Integer>>>` | `null` | 稀疏模式：字符 → `[[x,y,z], ...]` 坐标列表 |
| `mapping` | `mapping` | `Map<String,String>` | `{}` | 字符 → 方块状态谓词。**键必须恰好 1 个字符**（否则抛 `IllegalArgumentException("... is an invalid mapping key, every mapping key must be 1 character long")`） |
| `symmetrical` | `symmetrical` | boolean | `false` | 声明绕竖直轴 90° 旋转不变 ⇒ 只检查一个朝向（性能优化） |
| `offset` | `offset` | `int[3]` | `[0,0,0]` | 相对中心的偏移 |

**硬校验**（`toMultiblock` L96-111）：

```java
if ((densePattern != null) == (sparsePattern != null)) {
    throw new IllegalArgumentException("One and only one of pattern and sparse_pattern should be specified");
}
```

即 `pattern` 与 `sparse_pattern` **必须且只能有一个**。

**字符→谓词的解析**（`StringStateMatcher.fromString`，`common/multiblock/StringStateMatcher.java` L23-37）：

```java
if (s.equals("ANY")) return StateMatcher.ANY;
if (s.equals("AIR")) return StateMatcher.AIR;
return BlockStateParser.parseForTesting(BuiltInRegistries.BLOCK.asLookup(), s, true)
        .map(blockResult -> new ExactMatcher(blockResult.blockState(), blockResult.properties()),
             tagResult  -> new TagMatcher(tagResult.tag(), tagResult.vagueProperties()));
```

⇒ mapping 的值支持：
- 方块 id：`minecraft:gold_block`
- 带属性：`minecraft:note_block[note=4]`、`tfc:firepit[lit=true]`、`minecraft:oak_stairs[facing=north]`
- 方块标签：`#minecraft:wool`（TagMatcher 的显示状态会**每 20 tick 轮换**该标签中的一个方块，用来做「任意羊毛」这类展示）
- 两个保留字：`ANY`（任意方块）、`AIR`（空气）

**三个自动预置的 mapping**（`deserializeMapping` L46-55）：若未显式定义，则自动补
- `_` → `StateMatcher.ANY`（任意方块）
- ` `（空格）→ `StateMatcher.AIR`
- `0` → `StateMatcher.AIR`（**中心标记**）

**中心（`0`）的语义**（`DenseMultiblock.build` L112-145）：
- 稠密模式中字符 `0` 的位置被当作「中心」，即放置/验证时对齐到玩家选中的方块位置；源码据此计算 `offX/offY/offZ`。
- 每个结构**必须有且只有一个** `0`：没有 ⇒ `IllegalArgumentException("A structure can't have no center")`；两个 ⇒ `"A structure can't have two centers"`。
- 尺寸一致性也要满足：各层行数、每行长度必须一致，否则抛 `"Inconsistent array length. ..."`（L147-169）。

**未在源码中存在的字段**（写错会被静默忽略）：`view_offset`、`displayed_multiblock`、`displayed_state`。

### 10.3 真实内联多块示例

稠密 + 属性 + 标签（`.../testbook2/en_us/entries/intro/smelttest.json`，节选）：

```json
{
    "type": "patchouli:multiblock",
    "name": "Goldzebo",
    "multiblock": {
        "pattern": [
            [ " GRG ", "GGRGG", "RRNRR", "GGRGG", " GRG " ],
            [ "GG GG", "G   G", "     ", "G   G", "GG GG" ],
            [ "G   G", "     ", "     ", "     ", "G   G" ],
            [ "G   G", "     ", "  0  ", "     ", "G   G" ],
            [ "_WWW_", "WWWWW", "WWWWW", "WWWWW", "_WWW_" ]
        ],
        "mapping": {
            "G": "minecraft:gold_block",
            "W": "#minecraft:wool",
            "R": "minecraft:red_terracotta",
            "N": "minecraft:note_block[note=4]"
        }
    }
}
```

含 `symmetrical` 与 `offset`（`.../testbook1/en_us/entries/test/testy.json`，节选）：

```json
{
    "type": "patchouli:multiblock",
    "multiblock_id": "",
    "name": "Cool Crucible",
    "text": "Testing multiblocks loaded from json!",
    "multiblock": {
        "pattern": [ ["   ", " 0 ", "   "], [ "SSS", "SFS", "SSS"] ],
        "mapping": { " ": "ANY", "0": "minecraft:cauldron", "F": "minecraft:fire", "S": "minecraft:mossy_stone_bricks" },
        "symmetrical": true,
        "offset": [0, 0, 0],
        "view_offset": [0, 0, 0]
    }
}
```

> 注意最后一行 `view_offset` —— 如上文所述，**源码里没有这个字段，会被忽略**。这里特意保留作为反例。

稀疏模式（`.../comprehensive_test_book/en_us/entries/multiblocks/sparse.json`）：

```json
{
  "type": "patchouli:multiblock",
  "name": "stair end portal (sparse)",
  "multiblock": {
    "sparse_pattern": {
      "N": [ [-1,0,-2], [0,0,-2], [1,0,-2] ],
      "S": [ [-1,0,2],  [0,0,2],  [1,0,2] ],
      "W": [ [-2,0,-1], [-2,0,0], [-2,0,1] ],
      "E": [ [2,0,-1],  [2,0,0],  [2,0,1] ]
    },
    "mapping": {
      "N": "minecraft:oak_stairs[facing=north]",
      "S": "minecraft:birch_stairs[facing=south]",
      "W": "minecraft:brick_stairs[facing=west]",
      "E": "minecraft:stone_brick_stairs[facing=east]"
    }
  }
}
```

TFC 的真实极简多块（`field_guide/en_us/entries/getting_started/firepit.json`）：

```json
{
  "type": "patchouli:multiblock",
  "multiblock": { "pattern": [["X"], ["0"]], "mapping": { "X": "tfc:firepit[lit=true]" } },
  "name": "",
  "text": "If you were successful, a firepit will be created.",
  "enable_visualize": false
}
```

### 10.4 视觉化（Visualize）功能

点击眼睛按钮（`GuiButtonBookEye`）后调用 `MultiblockVisualizationHandler.setMultiblock(multiblockObj, name, bookmark, true)`（`PageMultiblock.handleButtonVisualize` L118-128），把结构「投影」到世界里，玩家按进度逐块搭建；进度保存在 `patchouli_data.json` 的 `clickedVisualize` 与 `bookmarks` 中。

---

## 11. Java API（供模组代码使用）

### 11.1 API 稳定性边界（先认清哪些能碰）

| 类别 | 类型 | 是否可依赖 |
| --- | --- | --- |
| **稳定公开 API** | `vazkii.patchouli.api` 包内全部类型：`PatchouliAPI`（含嵌套 `IPatchouliAPI`）、`PatchouliConfigAccess`、`IMultiblock`、`IStateMatcher`、`IStyleStack`、`IComponentProcessor`、`IComponentRenderContext`、`ICustomComponent`、`IVariable`、`IVariableProvider`、`IVariableSerializer`、`IVariablesAvailableCallback`、`TriPredicate`、`VariableHelper`；NeoForge 源集另提供同包事件 `BookDrawScreenEvent`、`BookContentsReloadEvent` | 可以 |
| 降级占位（不建议引用） | `api.stub.StubPatchouliAPI` / `StubMatcher` / `StubMultiblock` | 不建议 |
| **内部实现，无兼容承诺** | `vazkii.patchouli.common.*`、`client.*`、`xplat.*`、`mixin.*`、`neoforge.*` | **不要依赖**（但注意：TFC 自己就违反了这条，见 §15） |

`Xplat/src/main/java/vazkii/patchouli/api/package-info.java` 全文只有一行：

```java
@net.minecraft.MethodsReturnNonnullByDefault
package vazkii.patchouli.api;
```

⇒ API 包内**返回值默认非空**，只有显式标 `@Nullable` 的（如 `VariableHelper.serializerForClass`、`IMultiblock.validate(Level,BlockPos)`、`IVariableProvider` 相关）才可能返回 null。
**未能核实**：仓库中是否存在成文的 API 稳定性契约文本（`grep -r "stabilit|breaking change|backwards compat"` 零命中；`package-info.java` 无说明文字）。

### 11.2 `PatchouliAPI` 入口类

`Xplat/src/main/java/vazkii/patchouli/api/PatchouliAPI.java`：

```java
public class PatchouliAPI {
    public static final String MOD_ID = "patchouli";
    public static final Logger LOGGER = LogManager.getLogger(MOD_ID);

    private static final Supplier<IPatchouliAPI> LAZY_INSTANCE = Suppliers.memoize(() -> {
        try {
            return (IPatchouliAPI) Class.forName("vazkii.patchouli.common.base.PatchouliAPIImpl").newInstance();
        } catch (ReflectiveOperationException e) {
            LogManager.getLogger().warn("Unable to find PatchouliAPIImpl, using a dummy");
            return StubPatchouliAPI.INSTANCE;
        }
    });

    public static IPatchouliAPI get();      // 惰性反射加载实现；Patchouli 缺席时返回 stub
    public interface IPatchouliAPI { ... }  // 嵌套接口，全部方法见下
}
```

**要点**：
- `PatchouliAPI` 类上**没有** `@Mod` 注解；`@Mod` 只在 `NeoForgeModInitializer` 上，值为 `PatchouliAPI.MOD_ID`。
- `PatchouliAPI.get()` **首次调用时才反射加载**实现。若把 Patchouli 当可选依赖且它缺席，`get()` 返回 `StubPatchouliAPI.INSTANCE`（所有方法都是空操作/返回空值），因此**可选依赖场景下调用是安全的**（但不会有任何效果）。
- 书在**玩家登录后**才加载，因此很多 API 在此之前调用无意义（官方 javadoc 明示）。

### 11.3 `IPatchouliAPI` 全部方法签名（源码 + `javap` 双重核实）

以下签名与 `javap -p -cp Patchouli-1.21.1-93-NEOFORGE.jar "vazkii.patchouli.api.PatchouliAPI\$IPatchouliAPI"` 的输出**逐条一致**。

```java
public interface IPatchouliAPI {
    // ---- 自检与配置 ----
    boolean isStub();                                                  // true = 这是 stub（Patchouli 未加载）
    PatchouliConfigAccess getConfig();                                 // 只读配置视图
    void setConfigFlag(String flag, boolean value);                     // 线程安全；建议带自己 mod id 前缀
    boolean getConfigFlag(String flag);

    // ---- 打开书本（服务端侧，需传入 ServerPlayer）----
    void openBookGUI(ServerPlayer player, ResourceLocation book);
    void openBookEntry(ServerPlayer player, ResourceLocation book, ResourceLocation entry, int page);

    // ---- 打开书本（客户端侧，仅物理客户端可调用）----
    void openBookGUI(ResourceLocation book);
    void openBookEntry(ResourceLocation book, ResourceLocation entry, int page);
    @Nullable ResourceLocation getOpenBookGui();                       // 当前打开的书 id，否则 null（仅客户端）

    // ---- 书籍元信息与物品 ----
    Component getSubtitle(ResourceLocation bookId);                    // 双端可用；书不存在抛 IllegalArgumentException
    ItemStack getBookStack(ResourceLocation book);                     // 双端可用；返回 patchouli:guide_book + 数据组件 patchouli:book

    // ---- 文本系统扩展（仅客户端）----
    void registerTemplateAsBuiltin(ResourceLocation res, Supplier<InputStream> streamProvider);   // 注册内建模板
    void registerCommand(String name, Function<IStyleStack, String> command);                     // $(name)
    void registerFunction(String name, BiFunction<String, IStyleStack, String> function);         // $(name:参数)

    // ---- 多块 ----
    @Nullable IMultiblock getMultiblock(ResourceLocation id);
    IMultiblock registerMultiblock(ResourceLocation id, IMultiblock mb);     // 重复 id 抛 IllegalArgumentException
    @Nullable IMultiblock getCurrentMultiblock();                            // 仅客户端
    void showMultiblock(IMultiblock multiblock, Component displayName, BlockPos center, Rotation rotation);  // 仅客户端
    void clearMultiblock();                                                  // 仅客户端

    // ---- 多块 / 匹配器工厂 ----
    IMultiblock makeMultiblock(String[][] pattern, Object... targets);
    IMultiblock makeSparseMultiblock(Map<BlockPos, IStateMatcher> positions);
    IStateMatcher predicateMatcher(BlockState display, Predicate<BlockState> predicate);
    IStateMatcher predicateMatcher(Block display, Predicate<BlockState> predicate);
    IStateMatcher stateMatcher(BlockState state);
    IStateMatcher propertyMatcher(BlockState state, Property<?>... properties);
    IStateMatcher looseBlockMatcher(Block block);
    IStateMatcher strictBlockMatcher(Block block);
    IStateMatcher displayOnlyMatcher(BlockState state);
    IStateMatcher displayOnlyMatcher(Block block);
    IStateMatcher tagMatcher(TagKey<Block> block);
    IStateMatcher airMatcher();
    IStateMatcher anyMatcher();
}
```

关键实现行为（`Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliAPIImpl.java`）：

| 方法 | 实现要点 |
| --- | --- |
| 所有「仅客户端」方法 | 先执行 `Preconditions.checkState(IXplatAbstractions.INSTANCE.isPhysicalClient(), "Not on the physical client")` ⇒ **专用服务器上调用会抛 `IllegalStateException`** |
| `openBookGUI(ServerPlayer, ...)` | 先触发 advancement criterion `BookOpenTrigger`，再 `IXplatAbstractions.sendOpenBookGui(...)`（NeoForge 侧发一条 `playToClient` 自定义载荷 `MessageOpenBookGui`） |
| `getSubtitle(bookId)` | 从 `BookRegistry.INSTANCE.books` 取，取不到 ⇒ `throw new IllegalArgumentException("Book not found: " + bookId)` |
| `getBookStack(book)` | 等价于 `ItemModBook.forBook(book)`：`new ItemStack(PatchouliItems.BOOK)` 并 `stack.set(PatchouliDataComponents.BOOK, book)`。**注意是数据组件不是 NBT**（接口 javadoc 里"with its NBT set"是陈旧措辞） |
| `registerMultiblock` | 委托 `MultiblockRegistry.registerMultiblock`，用 `ConcurrentHashMap`，**重复 id 抛 `IllegalArgumentException("Multiblock ... already registered")`**；返回 `mb.setId(id)`。该表**不参与数据包重载** |
| `registerTemplateAsBuiltin` | 委托 `BookContents.addonTemplates.put(...)`；重复注册抛 `IllegalArgumentException("Template " + res + " is already registered")`；**仅客户端、且只对「内建模板」有意义** |
| `registerCommand` / `registerFunction` | 委托 `BookTextParser.register(...)`；**仅客户端** |
| `makeMultiblock(pattern, targets...)` | 委托 `new DenseMultiblock(pattern, targets)`；`targets` 是**交替的 `Character, 匹配器对象`**，匹配器可为 `Block` / `BlockState` / `String` / `IStateMatcher` |
| `makeSparseMultiblock(map)` | 委托 `new SparseMultiblock(positions)`；中心恒为 `(0,0,0)`，map 的 key 是相对该点的坐标 |
| `tagMatcher(tag)` | 返回匿名实现：显示状态按 `(ticks/20) % tag.size()` 轮换该标签中的方块；标签为空时显示 `Blocks.BEDROCK`；谓词为 `s -> s.is(tag)` |

`PatchouliAPIImpl` 上**不存在** `registerBook(...)`：书籍是纯数据驱动（`data/**/book.json`），由 `BookRegistry.init()` 在 `FMLCommonSetupEvent` 扫描。

### 11.4 `PatchouliConfigAccess`（配置只读视图）

`Xplat/src/main/java/vazkii/patchouli/api/PatchouliConfigAccess.java` **全文**：

```java
public interface PatchouliConfigAccess {
    boolean disableAdvancementLocking();
    List<String> noAdvancementBooks();
    boolean testingMode();
    String inventoryButtonBook();
    boolean useShiftForQuickLookup();
    TextOverflowMode overflowMode();
    int quickLookupTime();

    enum TextOverflowMode { OVERFLOW, TRUNCATE, RESIZE }
}
```

它是 `interface`（**不是 record**），实现是 `NeoForgePatchouliConfig` 里的匿名类（配置类型为 `ModConfig.Type.CLIENT`）。可通过 `PatchouliAPI.get().getConfig()` 读取。

| 方法 | 默认值（NeoForge 实现） | 含义 |
| --- | --- | --- |
| `disableAdvancementLocking()` | `false` | 关闭全部 advancement 门控 |
| `noAdvancementBooks()` | 空列表 | 这些书的 adv 门控关闭（也生成 flag `advancements_disabled_<bookid>`） |
| `testingMode()` | `false` | 测试模式（生成 flag `testing_mode`） |
| `inventoryButtonBook()` | `""` | 在物品栏显示按钮的书 |
| `useShiftForQuickLookup()` | `false` | 快速查阅改为按 Shift |
| `overflowMode()` | `RESIZE`（**配置键名是 `textOverflowMode`**，与字段名不同） | 文本溢出策略；可被 `book.json` 的 `text_overflow_mode` 覆盖 |
| `quickLookupTime()` | `10` | 快速查阅需按住的 tick 数 |

### 11.5 注册自定义 page 类型（真实可用的做法）

**先明确：本版本没有官方的 page 类型注册 API。** 唯一入口是内部类的 public 字段：

```java
// Xplat/src/main/java/vazkii/patchouli/client/book/ClientBookRegistry.java
public final Map<ResourceLocation, Class<? extends BookPage>> pageTypes = new HashMap<>();
public static final ClientBookRegistry INSTANCE = new ClientBookRegistry();
```

**注册时机**：`ClientBookRegistry.INSTANCE.init()` 由 `NeoForgeClientInitializer.onInitializeClient(FMLClientSetupEvent)` 调用，其内部 `addPageTypes()` 只 `put` 16 个 `patchouli:*` 键、**从不 `clear()`**。因此**任意在 `FMLClientSetupEvent` 期间（或其后、书籍内容反序列化之前）执行的 `pageTypes.put(...)` 都是安全的，且与监听器执行顺序无关**。内容反序列化发生在客户端收到第一个 advancement 包时（`ClientAdvancements.onClientPacket` → `ClientBookRegistry.reload`），远晚于客户端初始化，因此只要在 `FMLClientSetupEvent` 里注册即可稳定生效。

```java
package com.example.mymod.compat.patchouli;

import com.mojang.blaze3d.systems.RenderSystem;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.Level;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;
import vazkii.patchouli.client.book.BookContentsBuilder;
import vazkii.patchouli.client.book.BookEntry;
import vazkii.patchouli.client.book.ClientBookRegistry;
import vazkii.patchouli.client.book.gui.GuiBook;
import vazkii.patchouli.client.book.page.abstr.PageWithText;

/**
 * 自定义页面：展示本模组某台机器的配方。
 * 注意：本类及其依赖全部是 Patchouli 的内部实现类，属于「无兼容承诺」用法，
 * 必须与 Patchouli 版本一起升级（建议把 Patchouli 当硬依赖）。
 */
public class PageMyMachine extends PageWithText {

    // 字段名 = JSON 键名；Gson 直接反射写字段，无需 getter/setter
    ResourceLocation recipe;
    String title;

    @Override
    public int getTextHeight() {
        return 60;                    // 上方自定义区域高度，文本从这里往下画
    }

    @Override
    public void build(Level level, BookEntry entry, BookContentsBuilder builder, int pageNum) {
        super.build(level, entry, builder, pageNum);
        if (recipe != null) {
            var holder = level.getRecipeManager().byKey(recipe).orElse(null);
            if (holder != null) {
                // 登记「本页教这个物品的配方」：世界内 shift 右键 + 快速查阅都会用到
                entry.addRelevantStack(builder, holder.value().getResultItem(level.registryAccess()), pageNum);
            }
        }
    }

    @Override
    public void render(GuiGraphics graphics, int mouseX, int mouseY, float pticks) {
        // 页面内绘制区域：以 (0,0) 起、116x156 为一页
        parent.drawCenteredStringNoShadow(graphics,
                title == null || title.isEmpty() ? Component.literal("My Machine") : i18nText(title),
                GuiBook.PAGE_WIDTH / 2, 0, book.headerColor);
        GuiBook.drawSeparator(graphics, book, 0, 12);

        // 画背景板
        RenderSystem.enableBlend();
        graphics.blit(book.craftingTexture, 6, 20, 11, 71, 96, 24, 128, 256);

        super.render(graphics, mouseX, mouseY, pticks);   // 触发 PageWithText 的文本渲染
    }
}

/** 注册入口：必须在客户端事件总线、FMLClientSetupEvent 中执行 */
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public final class MyModPatchouliPages {

    @SubscribeEvent
    public static void onClientSetup(FMLClientSetupEvent event) {
        ClientBookRegistry.INSTANCE.pageTypes.put(
                ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_machine"),
                PageMyMachine.class);
    }
}
```

书籍 JSON 侧（`assets/<ns>/patchouli_books/<book>/en_us/entries/xxx/machine.json`）：

```json
{
  "name": "My Machine",
  "icon": "mymod:my_machine",
  "category": "mymod:machines",
  "pages": [
    { "type": "mymod:my_machine", "recipe": "mymod:my_machine/iron", "text": "Just build it like this." }
  ]
}
```

**可继承的页面基类**（`Xplat/src/main/java/vazkii/patchouli/client/book/`）：

| 基类 | 路径 | 用途 |
| --- | --- | --- |
| `BookPage` | `client/book/BookPage.java` | 最底层抽象（≈旧版 `IPage`）。手写全部渲染 |
| `PageWithText` | `client/book/page/abstr/PageWithText.java` | 带 `protected IVariable text` 与下方文本渲染；`getTextHeight()` 是抽象方法 |
| `PageDoubleRecipe<T>` | `client/book/page/abstr/PageDoubleRecipe.java` | 上下两个配方的页面骨架 |
| `PageDoubleRecipeRegistry<T extends Recipe<?>>` | `client/book/page/abstr/PageDoubleRecipeRegistry.java` | 按 `RecipeType` 查配方的实现 |
| `PageSimpleProcessingRecipe<T extends Recipe<?>>` | `client/book/page/abstr/PageSimpleProcessingRecipe.java` | 单输入单输出（熔炉类） |

**风险提示（务必写进注释/文档）**：
1. `ClientBookRegistry`、`BookPage`、`PageWithText`、`BookContentsBuilder`、`BookEntry` 都是内部实现，Patchouli 升级可能改签名或改名。
2. 自定义页面必须有**公开无参构造器**（Gson 反射实例化）。
3. `BookPage` 中的 `transient` 字段不会被反序列化，可安全用于运行时状态。
4. 页面类必须是**客户端类**（引用了 `GuiGraphics` 等）⇒ 注册代码与类都必须在 `Dist.CLIENT` 保护之下，否则专用服务器会因类加载失败而崩溃。

**更稳的替代方案**（推荐）：用**模板 + 自定义组件**（下一节），完全避开对 page 类型注册表的写入。

### 11.6 注册自定义模板组件类型

`BookTemplate` 暴露了 public 静态注册方法（`BookTemplate.java` L160-162）：

```java
public static void registerComponent(ResourceLocation name, Class<? extends TemplateComponent> clazz) {
    componentTypes.put(name, clazz);
}
```

用法（同样建议在 `FMLClientSetupEvent`、`Dist.CLIENT` 下执行）：

```java
BookTemplate.registerComponent(
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_gauge"),
        ComponentMyGauge.class);
```

```java
public class ComponentMyGauge extends TemplateComponent {
    public IVariable value;                       // 从 JSON / 变量系统注入
    @SerializedName("max") public int max = 100;
    @SerializedName("color") public IVariable colorStr;

    @Override
    public void onVariablesAvailable(UnaryOperator<IVariable> lookup, HolderLookup.Provider registries) {
        super.onVariablesAvailable(lookup, registries);   // 必须调用：处理 group/flag/advancement/guard
        value = lookup.apply(value);
        colorStr = lookup.apply(colorStr);
    }

    @Override
    public void render(GuiGraphics graphics, BookPage page, int mouseX, int mouseY, float pticks) {
        // 以 (x, y) 为左上角绘制
    }
}
```

### 11.7 `IComponentProcessor`（代码派生变量的标准做法）

`Xplat/src/main/java/vazkii/patchouli/api/IComponentProcessor.java`：

```java
public interface IComponentProcessor {
    void setup(Level level, IVariableProvider variables);
    @Nullable IVariable process(Level level, String key);
    default void refresh(Screen parent, int left, int top) {}      // NO-OP
    default boolean allowRender(String group) { return true; }
}
```

- **无注册机制**：模板里写 `"processor": "完整类名"`，由 `Class.forName(...).newInstance()` 创建 ⇒ **必须有公开无参构造器**。
- `process(level, key)` 返回 `null` 表示不管；返回的 `IVariable` 会替代 `#key`。
- 只在变量以 `#` 开头时被调用（`VariableAssigner.resolveStringVar` L132-134），并且**优先于** `variables.get(key)`。
- `setup` 抛出的异常会被包装成 `RuntimeException("Error setting up template processor", e)`。
- `allowRender(group)` 用于按代码条件隐藏某组组件（组件里写 `"group": "xxx"`）。
- `refresh(parent, left, top)` 每次页面显示时调用。

完整示例（官方测试用的 `RecipeTestProcessor`，`Xplat/src/main/java/vazkii/patchouli/client/book/template/test/RecipeTestProcessor.java`）：

```java
public class RecipeTestProcessor implements IComponentProcessor {
    private Recipe<?> recipe;

    @Override
    public void setup(Level level, IVariableProvider variables) {
        String recipeId = variables.get("recipe", level.registryAccess()).asString();
        recipe = level.getRecipeManager().byKey(ResourceLocation.tryParse(recipeId))
                .orElseThrow(IllegalArgumentException::new).value();
    }

    @Override
    public IVariable process(Level level, String key) {
        if (key.startsWith("item")) {                       // #item1..#item9
            int index = Integer.parseInt(key.substring(4)) - 1;
            Ingredient ingredient = recipe.getIngredients().get(index);
            ItemStack[] stacks = ingredient.getItems();
            return IVariable.from(stacks.length == 0 ? ItemStack.EMPTY : stacks[0], level.registryAccess());
        } else if (key.equals("text")) {
            ItemStack out = recipe.getResultItem(level.registryAccess());
            return IVariable.wrap(out.getCount() + "x$(br)" + out.getHoverName(), level.registryAccess());
        } else if (key.equals("icount")) {
            return IVariable.wrap(recipe.getResultItem(level.registryAccess()).getCount(), level.registryAccess());
        } else if (key.equals("iname")) {
            return IVariable.wrap(recipe.getResultItem(level.registryAccess()).getHoverName().getString(), level.registryAccess());
        }
        return null;
    }
}
```

配套模板（`.../testbook2/en_us/templates/include/recipetest.json`）里 `"processor": "vazkii.patchouli.client.book.template.test.RecipeTestProcessor"`；条目里只需给 `"recipe": "minecraft:..."`。

### 11.8 `ICustomComponent`（自定义渲染组件，**TFC 选择的路线**）

```java
// Xplat/src/main/java/vazkii/patchouli/api/ICustomComponent.java
public interface ICustomComponent extends IVariablesAvailableCallback {
    void build(int componentX, int componentY, int pageNum);
    void render(GuiGraphics graphics, IComponentRenderContext context, float pticks, int mouseX, int mouseY);
    default void onDisplayed(IComponentRenderContext context) {}                       // NO-OP
    default boolean mouseClicked(IComponentRenderContext context, double mouseX, double mouseY, int mouseButton) { return false; }
}
```

- **无需注册**：在模板里写 `{"type":"patchouli:custom","class":"你的全限定类名", ...额外字段}`
- 你的实现类会被 `SerializationUtil.RAW_GSON.fromJson(sourceObject, 你的类)` 反序列化 ⇒ **JSON 里与字段同名的键会自动注入**（TFC 就是这样把 `recipe`、`multiblocks` 传进去的）。
- **不想被注入的字段必须声明为 `transient`**。
- `IComponentRenderContext` 提供的上下文（`api/IComponentRenderContext.java`）：

```java
public interface IComponentRenderContext {
    Screen getGui();
    Style getFont();
    void renderItemStack(GuiGraphics graphics, int x, int y, int mouseX, int mouseY, ItemStack stack);
    void renderIngredient(GuiGraphics graphics, int x, int y, int mouseX, int mouseY, Ingredient ingredient);
    boolean isAreaHovered(int mouseX, int mouseY, int x, int y, int w, int h);
    boolean navigateToEntry(ResourceLocation entry, int page, boolean push);
    @Deprecated void setHoverTooltip(List<String> tooltip);                    // 改用 setHoverTooltipComponents
    void setHoverTooltipComponents(List<Component> tooltip);
    @Deprecated(forRemoval = true) void registerButton(Button button, int pageNum, Runnable onClick);   // 改用 addWidget
    void addWidget(AbstractWidget button, int pageNum);
    ResourceLocation getBookTexture();
    ResourceLocation getCraftingTexture();
    int getTextColor();
    int getHeaderColor();
    int getTicksInBook();
}
```

### 11.9 多块的 Java 侧

```java
// 1) 手工构建（推荐：显式、可读性好）
IMultiblock mb = PatchouliAPI.get().makeMultiblock(
        new String[][] {
            { "XXX", "X0X", "XXX" },      // 第 0 层（最上面），Y 从上到下
            { "   ", " 0 ", "   " }
        },
        'X', PatchouliAPI.get().looseBlockMatcher(MyBlocks.MACHINE.get()),
        'Y', PatchouliAPI.get().anyMatcher());

// 2) 注册（重复 id 会抛异常，建议用自己 mod 的 id）
PatchouliAPI.get().registerMultiblock(
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_machine"), mb);

// 3) 服务端校验（模组硬依赖 Patchouli 时可用）
if (mb.validate(level, pos, Rotation.NONE)) { ... }

// 4) 客户端世界内预览
PatchouliAPI.get().showMultiblock(mb, Component.literal("My Machine"), pos, Rotation.NONE);
PatchouliAPI.get().clearMultiblock();
```

`IMultiblock` 的完整接口（`api/IMultiblock.java`）：

```java
public interface IMultiblock {
    IMultiblock offset(int x, int y, int z);
    IMultiblock offsetView(int x, int y, int z);
    IMultiblock setSymmetrical(boolean symmetrical);
    IMultiblock setId(ResourceLocation res);
    boolean isSymmetrical();
    ResourceLocation getID();
    void place(Level world, BlockPos pos, Rotation rotation);
    Pair<BlockPos, Collection<SimulateResult>> simulate(Level world, BlockPos anchor, Rotation rotation, boolean forView);
    @Nullable Rotation validate(Level world, BlockPos pos);
    boolean validate(Level world, BlockPos pos, Rotation rotation);
    boolean test(Level world, BlockPos start, int x, int y, int z, Rotation rotation);
    Vec3i getSize();

    interface SimulateResult {
        BlockPos getWorldPosition();
        IStateMatcher getStateMatcher();
        @Nullable Character getCharacter();
        boolean test(Level world, Rotation rotation);
    }
}
```

> `IMultiblock` 的类注释明确写着：**不要自己实现这个接口**，请用 `PatchouliAPI` 的工厂方法。

`IStateMatcher`（`api/IStateMatcher.java`）：

```java
public interface IStateMatcher {
    BlockState getDisplayedState(long ticks);                                 // 渲染用的「展示状态」
    TriPredicate<BlockGetter, BlockPos, BlockState> getStatePredicate();     // 校验用的谓词
}
```

实现类：`common/multiblock/StateMatcher.java`（`ANY`、`AIR` 常量 + `fromPredicate`/`fromState`/`fromStateWithFilter`/`fromBlockLoose`/`fromBlockStrict`/`displayOnly` 工厂）、`StringStateMatcher`（字符串解析，内含 `ExactMatcher`/`TagMatcher`）。

### 11.10 事件与扩展点

| 事件 | 位置 | 侧别 | 可用性 |
| --- | --- | --- | --- |
| `vazkii.patchouli.api.BookDrawScreenEvent` | `NeoForge/src/main/java/vazkii/patchouli/api/BookDrawScreenEvent.java` | **纯客户端** | **可用**：每帧在书籍 GUI 绘制时触发 |
| `vazkii.patchouli.api.BookContentsReloadEvent` | `NeoForge/src/main/java/vazkii/patchouli/api/BookContentsReloadEvent.java` | 名义双端 | **本版本永远不触发（不要用）** |

`BookDrawScreenEvent` 的字段与 getter：`getBook()`（书 id）、`getScreen()`、`getMouseX()`、`getMouseY()`、`getPartialTicks()`、`getGraphics()`。
触发点唯一：`NeoForgeXplatImpl.fireDrawBookScreen`，由 `GuiBook.drawScreenAfterScale` 在**每帧**调用（`Xplat/.../client/book/gui/GuiBook.java` L135-150，位于 `popPose` 之后、`drawTooltip` 之前）。事件**不可取消**（无 `@Cancelable`），也**不含当前页面信息**（要拿页面需强转到内部类 `GuiBook`）。

`BookContentsReloadEvent` 的不触发结论与依据：唯一 `post` 点在 `NeoForgeXplatImpl:34-36`（`fireBookReload` 的实现），而全仓库 grep `fireBookReload` 只有 3 处命中 —— 接口声明、NeoForge 实现、Fabric 实现，**没有任何调用者**。实际的内容重载走 `ServerStartedEvent` → `ReloadContentsHandler.dataReloaded(server)` → 广播 `MessageReloadBookContents` 数据包。

监听写法（NeoForge，注意用 **game bus**）：

```java
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = EventBusSubscriber.Bus.GAME, value = Dist.CLIENT)
public final class MyBookOverlay {
    @SubscribeEvent
    public static void onDraw(BookDrawScreenEvent event) {
        if (!event.getBook().equals(MyMod.id("my_guide"))) return;
        // 用 event.getGraphics() 在已应用 GUI 缩放的坐标系里绘制
    }
}
```

（也可用 `NeoForge.EVENT_BUS.addListener((BookDrawScreenEvent e) -> { ... });`。注册到 mod bus 收不到。）

### 11.11 初始化时机速查

| 我想做的事 | 应该在哪里做 | 依据 |
| --- | --- | --- |
| 声明一本书 | 不需要代码：放 `data/<modid>/patchouli_books/<book>/book.json` | `BookRegistry.init()`（`FMLCommonSetupEvent`） |
| 注册自定义 page 类型 | `FMLClientSetupEvent`（`Dist.CLIENT`），写 `ClientBookRegistry.INSTANCE.pageTypes` | `ClientBookRegistry.init()` 在同一事件阶段，且不 `clear()` |
| 注册自定义模板组件类型 | `FMLClientSetupEvent`（`Dist.CLIENT`），调 `BookTemplate.registerComponent` | `BookTemplate` 静态注册表 |
| 注册多块 | `FMLCommonSetupEvent` 之后任意时刻（线程安全） | `MultiblockRegistry` 用 `ConcurrentHashMap` |
| 注册文本命令/函数 | 客户端初始化阶段（`FMLClientSetupEvent`） | `registerCommand`/`registerFunction` 均 `assertPhysicalClient` |
| 自己的 flag | 配置装载后任意时刻 `PatchouliAPI.get().setConfigFlag(...)` | `PatchouliConfig.setFlag` 线程安全 |
| 监听书籍 GUI 绘制 | game bus + `Dist.CLIENT` | §11.10 |
| 给玩家书 / 打开书 | 服务端逻辑（`ServerPlayer` 可用时） | `openBookGUI(ServerPlayer, ...)` |

---

## 12. 运行时给书、开书与命令

### 12.1 取得书籍物品

```java
ItemStack book = PatchouliAPI.get().getBookStack(ResourceLocation.fromNamespaceAndPath("mymod", "my_guide"));
```

实现等价于（`common/item/ItemModBook.java` L55-65）：

```java
public static ItemStack forBook(ResourceLocation book) {
    ItemStack stack = new ItemStack(PatchouliItems.BOOK);      // patchouli:guide_book
    stack.set(PatchouliDataComponents.BOOK, book);              // 数据组件 patchouli:book
    return stack;
}
```

反向查询：`ItemModBook.getBook(stack)` / `ItemStackUtil.getBookFromStack(stack)`（后者还会遍历所有书比较物品，兼容自定义书物品）。
`PatchouliAPI.get().getBookStack` 在 **stub**（Patchouli 缺席）时返回 `ItemStack.EMPTY`，因此可选依赖场景要判空。

### 12.2 用原版配方/战利品「生产」这本书

1.21.1 没有 `patchouli:*_book_recipe`，用原版配方 + 数据组件（正向范例 `Xplat/src/main/resources/data/patchouli/recipes/test_recipe.json` 全文）：

```json
{
  "type": "minecraft:crafting_shaped",
  "pattern": ["##"],
  "key": { "#": { "item": "minecraft:dirt" } },
  "result": {
    "id": "patchouli:guide_book",
    "count": 1,
    "components": { "patchouli:book": "mymod:my_guide" }
  }
}
```

给新玩家自动发书的推荐做法（原版 advancement + loot table，`patchouli:book` 组件用 `minecraft:set_components` 函数写入）：

```json
{
  "type": "minecraft:advancement_reward",
  "pools": [{
    "rolls": 1,
    "entries": [{
      "type": "item",
      "name": "patchouli:guide_book",
      "functions": [{
        "function": "minecraft:set_components",
        "components": { "patchouli:book": "mymod:my_guide" }
      }]
    }]
  }]
}
```

（官方文档同样给出这一模式：`web/docs/patchouli-basics/giving-new.md`。）

### 12.3 打开书

```java
// 服务端（会向该玩家发送客户端载荷，并在服务端触发 patchouli:open_book criterion）
PatchouliAPI.get().openBookGUI(serverPlayer, bookId);
PatchouliAPI.get().openBookEntry(serverPlayer, bookId, entryId, page);   // page 是「第几页」（非跨页索引）

// 客户端（仅物理客户端可调用）
PatchouliAPI.get().openBookGUI(bookId);
PatchouliAPI.get().openBookEntry(bookId, entryId, page);
```

注意：`openBookEntry` 的 `page` 在客户端 `ClientBookRegistry.displayBookGui` 里会 `page / 2` 转成「跨页（spread）」，因此传「页序号」即可（0 基）。

### 12.4 内置命令

`OpenBookCommand`（`common/command/OpenBookCommand.java`）注册的命令：

```
/open-patchouli-book <targets> <book> [<entry> <page>]
```

- 权限等级 2（`cs.hasPermission(2)`）。
- `<book>` 有补全（列出所有已注册书 id）。
- 实现直接调用 `openBookGUI` / `openBookEntry`。

### 12.5 右键/讲台等内置交互

| 交互 | 实现 |
| --- | --- |
| 手持书 shift 右键**方块** | 查该方块的 `getCloneItemStack` 是否命中某条目的 `extra_recipe_mappings`/配方映射，命中则跳到该页（`client/handler/BookRightClickHandler.java`） |
| 手持书右键**空气** | `ItemModBook.use` ⇒ 服务端 `openBookGUI`（`ItemModBook.java` L126-142） |
| 讲台上放书/取书/右键打开 | `common/handler/LecternEventHandler.java`（**服务端**判断，客户端只回 `SUCCESS`） |
| 物品栏按钮 | 由配置 `inventoryButtonBook` 指定书；`client/gui/GuiButtonInventoryBook.java` + `MixinInventoryScreen` |

---

## 13. `patchouli_data.json`（客户端本地状态）

**位置**：游戏工作目录根（`Paths.get("patchouli_data.json")`，与 `mods/` 同级）。本实例中的实际内容：

```json
{
  "bookGuiScale": 0,
  "clickedVisualize": false,
  "bookData": {}
}
```

**实现**：`Xplat/src/main/java/vazkii/patchouli/client/base/PersistentData.java`。

| 顶层字段 | 类型 | 含义 |
| --- | --- | --- |
| `bookGuiScale` | int | 书本 GUI 缩放档位 |
| `clickedVisualize` | boolean | 是否点过「视觉化」按钮（用于首次提示） |
| `bookData` | Object（键为书 id 字符串） | 每本书的本地状态 |

`bookData.<bookid>` 的字段（`PersistentData.BookData`）：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `viewedEntries` | String[] | 已读条目 id（决定 `UNREAD` 标记） |
| `bookmarks` | Object[]（`{entry, page}`） | 书签；**`page` 字段实际存的是 spread 索引**（源码注释：`// Serialized as page for legacy reasons`） |
| `history` | String[] | 浏览历史 |
| `completedManualQuests` | String[] | 手动完成的 `patchouli:quest` 条目 id |

**要点**：
- 该文件是**纯客户端**、**每个玩家本地**的，与存档/服务器无关。服务端不会读它。
- 载入失败或损坏时会用默认值覆盖并打警告（`setup()` L31-46）。
- 因此：**不要**把「玩家进度」设计成依赖服务端可校验的东西（服务端读不到）。要实现服务端可信的进度，请用 advancement。

---

## 14. 多语言（i18n）

### 14.1 三种语言相关机制，不要混淆

| 机制 | 触发条件 | 行为 |
| --- | --- | --- |
| **书内容按语言目录覆盖** | 总是生效 | `assets/<ns>/patchouli_books/<book>/<lang>/...` 覆盖 `en_us` 同名文件（见 §1.3） |
| **`book.name` / `book.landing_text`** | 总是按翻译键 | 总是 `Component.translatable(...)`，无论 `i18n` 字段（`ItemModBook.getName`、`GuiBookLanding` L39/L46）；`subtitle` 在 `version=="0"` 时也走 `Component.translatable` |
| **`book.json` 的 `i18n: true`** | 需显式开启 | 让**分类名、条目名、页面标题**走 `Component.translatable` 而不是字面量（`BookCategory.getName`、`BookEntry.getName`、`BookPage.i18n`/`i18nText`） |

⇒ 模组作者的最佳实践：`book.json` 里设 `"i18n": true`，`name`/`landing_text`/`subtitle` 写翻译键，并把键放进 `assets/<modid>/lang/<lang>.json`；分类/条目名也用键。

### 14.2 语言代码

使用 MC 标准的语言代码目录名：`en_us`（**必须存在**）、`zh_cn`、`zh_tw`、`zh_hk`、`ja_jp`、`ko_kr`、`pt_br`、`ru_ru`、`tr_tr`、`uk_ua`、`de_de`、`fr_fr`、`es_es`、`it_it`、`pl_pl`、`cs_cz` 等。
当前语言来自 `Minecraft.getInstance().getLanguageManager().getSelected()`（`ClientBookRegistry.reload`）。

### 14.3 翻译实践（TFC 的真实做法）

- `en_us` 全量内容；其它语言只放要覆盖的文件。
- TFC 的 `zh_cn/entries/getting_started/firepit.json` 与 `en_us` 同名同结构，只把文本换成中文（JSON 内使用 `\uXXXX` 转义，例如 `"\u751f\u706b"` = 「生火」）。**注意保持 `type`、`recipe`、`category`、`icon` 等非文本字段完全一致**，否则行为会变。
- 翻译文件里 **不要**放 `en_us` 中不存在的条目（见 §1.3 规则 1）。

---

## 15. 第三方扩展真实范例：TFC（TerraFirmaCraft 4.2.10）

> TFC 源码目录 `moddev\src-ref\TerraFirmaCraft` **不存在**；以下结论全部来自实例内实际 jar（`mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`）的内容、`moddev\inventory\TFC.classes.txt` 类清单，以及 class 常量池字符串提取。

### 15.1 TFC 的依赖声明（附属模组照抄这一条即可）

```toml
[[dependencies.mymod]]
    modId = "patchouli"
    type = "required"                 # 若只用模板/JSON，可改 "optional" 或干脆不声明
    versionRange = "[1.21.1-92-NEOFORGE,)"
    ordering = "NONE"
    side = "BOTH"
```

TFC 选的是 `type = "required"` + `side = "BOTH"`，并把 Patchouli 作为**编译期依赖**（Firmalife 的构建脚本里是 `vazkii.patchouli:Patchouli:1.21.1-92-NEOFORGE`，`implementation` 而非 `api`）。

### 15.2 TFC 的书籍结构（可直接当模板抄）

```
data/tfc/patchouli_books/field_guide/book.json                                  ← 单行 JSON，见 §2.4
assets/tfc/patchouli_books/field_guide/en_us/categories/*.json
assets/tfc/patchouli_books/field_guide/en_us/entries/<分类目录>/*.json
assets/tfc/patchouli_books/field_guide/en_us/templates/*.json
assets/tfc/patchouli_books/field_guide/<其它 9 种语言>/…
```

书籍 id = `tfc:field_guide`。**全 TFC 只有这一本书、一个 `book.json`**（已核实：jar 内所有 `*patchouli_books*book.json` 只有 1 个条目）。

### 15.3 TFC 的「自定义页面类型」= 模板 + 自定义组件

TFC 的 entries 里出现了 `tfc:heat_recipe`、`tfc:multimultiblock`、`tfc:anvil_recipe`、`tfc:knapping_recipe`、`tfc:barrel_recipe` 等 type，它们**不是注册的 page 类型**（TFC jar 中不存在含 `heat_recipe` 字符串的 class），而是 `templates/` 下的模板：

| entry 里写的 type | 对应模板文件 | 模板里使用的自定义组件类 |
| --- | --- | --- |
| `tfc:heat_recipe` | `templates/heat_recipe.json` | `net.dries007.tfc.compat.patchouli.component.HeatingComponent` |
| `tfc:multimultiblock` | `templates/multimultiblock.json` | `...component.MultiMultiBlockComponent` |
| `tfc:anvil_recipe` | `templates/anvil_recipe.json` | `...component.AnvilComponent` |
| `tfc:knapping_recipe` | `templates/knapping_recipe.json` | `...component.KnappingComponent` |
| `tfc:rock_knapping_recipe` | `templates/rock_knapping_recipe.json` | `...component.RockKnappingComponent` |
| `tfc:loom_recipe` | `templates/loom_recipe.json` | `...component.LoomComponent` |
| `tfc:glassworking_recipe` | `templates/glassworking_recipe.json` | `...component.GlassworkingComponent` |
| `tfc:quern_recipe` | `templates/quern_recipe.json` | `...component.QuernComponent` |
| `tfc:welding_recipe` | `templates/welding_recipe.json` | `...component.WeldingComponent` |
| `tfc:instant_barrel_recipe` / `tfc:sealed_barrel_recipe` | `templates/instant_barrel_recipe.json` / `sealed_barrel_recipe.json` | `...component.InstantBarrelComponent` / `SealedBarrelComponent` |
| `tfc:table` / `tfc:table_small` | `templates/table.json` / `table_small.json` | `...component.TableComponent` |

（模板文件清单来自 jar 内容；组件类名来自同一模板文件里的 `"class"` 字段与 `TFC.classes.txt`。）

组件类清单（`TFC.classes.txt` 中 `net/dries007/tfc/compat/patchouli/component/` 全部条目）：
`AnvilComponent`、`BarrelComponent`、`CustomComponent`、`CustomComponent$MultiblockRenderer`、`GlassworkingComponent`、`HeatingComponent`、`InputOutputComponent`、`InstantBarrelComponent`、`KnappingComponent`、`KnappingComponent$Entry`、`LoomComponent`、`MultiMultiBlockComponent`、`QuernComponent`、`RecipeComponent`、`RockKnappingComponent`、`RockKnappingComponent$Entry`、`ScrapingComponent`、`SealedBarrelComponent`、`SimpleItemRecipeComponent`、`TableComponent`、`TableComponent$TableEntry`、`WeldingComponent`。
其中 `CustomComponent` 是 TFC 自己的抽象基类（其余组件继承它），它是 `ICustomComponent` 的实现。

**给附属模组的启示**：如果你要给 TFC 手册加一个展示 TFC 配方的页面，最省事的路线是
**(a)** 复用 TFC 已注册的模板 id（`"type":"tfc:heat_recipe"` 等），或在
**(b)** 自己写一个 `ICustomComponent` 实现 + 一个模板文件（`"type":"patchouli:custom","class":"你的类"`）+ 一个 entry 用 `"type":"你的命名空间:你的模板名"`。

### 15.4 TFC 的文本函数（`registerFunction` 真实用法）

- 类：`net.dries007.tfc.compat.patchouli.ConfigTextFunction`，在 `net.dries007.tfc.compat.patchouli.PatchouliClientEventHandler` 中注册（后者在 `NeoForge.EVENT_BUS` 上加监听）。
- 它通过 `PatchouliAPI.get().registerFunction("cfg", (parameter, styleStack) -> ...)` 注册，使手册里可以写 `$(cfg:temperature)`、`$(cfg:heat)` 等，从 TFC 的 CLIENT/SERVER 配置里取当前值渲染（内部用正则 `\$\(cfg:([^)]*)\)` 与 `Style.withColor` 改写样式，用到 `IStyleStack.modifyStyle`）。
- 它还监听 `RenderTooltipEvent.Pre`，在物品 tooltip 上追加「按 shift 查看手册」提示，并调用 `ItemStackUtil.getBookFromStack`、`BookContents.getEntryForStack`、`ItemModBook.forBook`（**注意：这些是 Patchouli 的内部类**）。

### 15.5 TFC 的多块注册（`registerMultiblock` 真实用法）

类 `net.dries007.tfc.compat.patchouli.PatchouliIntegration`（class 常量池可核实）：
- 常量 `BOOK_ID = Helpers.resourceLocation("tfc", "field_guide")`；
- 用 `PatchouliAPI.get().getBookStack(BOOK_ID)` 拿书、`openBookGUI(ServerPlayer, ResourceLocation)` / `openBookEntry(...)` 开书；
- 用 `IPatchouliAPI.registerMultiblock(...)` 注册了 `tfc:bloomery`、`tfc:blast_furnace`、`tfc:full_blast_furnace`、`tfc:rock_anvil`、`tfc:charcoal_forge`、`tfc:channel_casting`、`tfc:windmill`、`tfc:water_wheel`、`tfc:clutch_off`、`tfc:clutch_on`、`tfc:crankshaft`、`tfc:rotating_quern` 等多块；
- 使用 `Predicate` + `predicateMatcher(...)`、`looseBlockMatcher(...)`、`strictBlockMatcher(...)`、`airMatcher()`、`anyMatcher()`、`stateMatcher(BlockState)` 等工厂，并用 `BlockState.setValue(...)` 精确指定属性；
- 有一个 `sneakIntoMultiblock(IMultiblock) -> Optional<BlockGetter>` 辅助（把多方块包成 `BlockGetter` 供 `test`/渲染用）；
- 引用纹理 `textures/gui/book/icons.png`（TFC 自己的手册图标）。

### 15.6 TFC 使用的「外部 API 之外」的东西（反面教材）

TFC 直接引用了以下**内部类**：`vazkii.patchouli.common.book.BookRegistry`、`vazkii.patchouli.client.book.BookContents`/`BookEntry`、`vazkii.patchouli.common.util.ItemStackUtil`、`vazkii.patchouli.common.base.PatchouliConfig`、`vazkii.patchouli.client.book.gui.GuiBook`（另有 mixin `net.dries007.tfc.mixin.client.compat.patchouli.GuiBookMixin`）。

⇒ 这是一种**「硬依赖 + 紧跟版本升级」**的取舍。**附属模组如非必要，不要模仿**：优先只用 `vazkii.patchouli.api` 包 + JSON 模板，能覆盖绝大多数需求。

---

## 16. 给「TFC 附属模组」的落地清单

> 目标场景：为一个依赖 TFC 的附属模组（modId 假设为 `mymod`）添加一本 Patchouli 手册，其中包含用自定义页面展示 TFC 配方的条目。

### 16.1 先做决策：你需要 Java 代码吗？

| 需求 | 是否需要 Java | 推荐路线 |
| --- | --- | --- |
| 纯文字/图片/原版配方/多块的条目 | **不需要** | 只写 JSON（`book.json` + `assets/**`） |
| 展示 TFC 独有的配方/机器界面 | 需要 | 写一个 `ICustomComponent` 实现 + 一个模板 + 条目引用该模板（**TFC 自己的做法**） |
| 完全自定义的整页渲染 | 需要 | 继承 `PageWithText` 并写入 `ClientBookRegistry.INSTANCE.pageTypes`（内部 API，风险高） |
| 从模组代码里读配置/数据渲染文本 | 需要 | `IComponentProcessor` 或 `registerFunction` |

**强烈建议先尝试「模板 + ICustomComponent」**，因为它是 Patchouli 官方支持的扩展方式（`patchouli:custom` 组件是 16 个内置 page 类型之外的官方出口），不需要触碰任何内部注册表。

### 16.2 需要创建的文件（完整路径模板）

```
src/main/resources/
├── data/
│   └── mymod/
│       └── patchouli_books/
│           └── my_guide/                                  ← 书名：仅小写字母、数字、下划线
│               └── book.json                              ← 书籍声明（必填字段见下）
│
├── assets/
│   └── mymod/
│       ├── lang/
│       │   ├── en_us.json                                 ← book.name / landing_text / 条目名的翻译键
│       │   └── zh_cn.json
│       ├── models/item/
│       │   └── my_book.json                               ← 可选：book.json 的 "model": "mymod:my_book"
│       ├── textures/
│       │   ├── item/my_book.png
│       │   └── gui/entries/my_recipe.png                  ← 条目里用到的图片
│       └── patchouli_books/
│           └── my_guide/
│               ├── en_us/                                 ← 必须有！发现基准（见 §1.3）
│               │   ├── categories/
│               │   │   ├── getting_started.json
│               │   │   └── machines.json
│               │   ├── entries/
│               │   │   ├── getting_started/
│               │   │   │   └── intro.json
│               │   │   └── machines/
│               │   │       └── my_machine.json            ← 使用自定义页面/模板
│               │   └── templates/
│               │       └── my_machine.json                ← 模板（可选，见 16.3）
│               └── zh_cn/                                 ← 可选：仅放要覆盖的文件
│                   ├── categories/
│                   │   └── getting_started.json
│                   └── entries/
│                       └── getting_started/
│                           └── intro.json
│
└── (可选) data/mymod/advancements/my_guide/root.json      ← 若要用 advancement 门控
```

**命名与 id 的对应关系（务必记牢）**

| 文件 | 对应 id |
| --- | --- |
| `data/mymod/patchouli_books/my_guide/book.json` | 书 id `mymod:my_guide` |
| `assets/mymod/patchouli_books/my_guide/en_us/categories/machines.json` | 分类 id `mymod:machines` |
| `.../categories/sub/deep.json` | 分类 id `mymod:sub/deep` |
| `.../entries/machines/my_machine.json` | 条目 id `mymod:machines/my_machine` |
| `.../templates/my_machine.json` | 模板 id `mymod:my_machine` |

> 条目 id 来自**文件路径**，与 `category` 字段无强制对应关系（但建议目录与分类同名以便维护）。
> 条目里的 `category` **必须写全限定 id**（`mymod:machines`），否则抛异常。

### 16.3 `book.json` 模板

```json
{
  "name": "item.mymod.my_guide.name",
  "landing_text": "item.mymod.my_guide.landing",
  "subtitle": "mymod 手册",
  "version": "1",
  "model": "mymod:my_book",
  "creative_tab": "minecraft:tools_and_utilities",
  "i18n": true,
  "show_progress": false,
  "use_resource_pack": true
}
```

要点：`use_resource_pack: true` **必写**；`name`/`landing_text` 建议用翻译键并配 `"i18n": true`；`model` 指向自己做的物品模型（不要复用 `patchouli:book_*`，官方文档明确要求模组自制）。

### 16.4 分类 / 条目 / 模板模板

`categories/getting_started.json`：

```json
{
  "name": "item.mymod.my_guide.category.getting_started",
  "description": "item.mymod.my_guide.category.getting_started.desc",
  "icon": "mymod:my_machine",
  "sortnum": 0
}
```

`entries/getting_started/intro.json`：

```json
{
  "name": "item.mymod.my_guide.entry.intro",
  "icon": "mymod:my_machine",
  "category": "mymod:getting_started",
  "priority": true,
  "read_by_default": false,
  "pages": [
    { "type": "patchouli:text", "text": "Welcome to $(thing)mymod$()." },
    { "type": "patchouli:crafting", "recipe": "mymod:my_machine", "text": "Craft the machine like this." },
    { "type": "patchouli:image", "images": ["mymod:textures/gui/entries/my_recipe.png"], "border": true, "text": "The GUI" },
    { "type": "patchouli:multiblock",
      "multiblock": { "pattern": [["XXX"],["X0X"],["XXX"]], "mapping": { "X": "mymod:my_machine" } },
      "name": "Structure", "enable_visualize": true, "text": "Build it like this." }
  ]
}
```

`templates/my_machine.json`（展示 TFC 配方的自定义页面）：

```json
{
  "components": [
    { "type": "patchouli:custom", "x": 0, "y": 0,
      "class": "com.example.mymod.compat.patchouli.component.MyMachineComponent",
      "recipe": "#recipe" },
    { "type": "patchouli:text", "x": 0, "y": 105, "text": "#text" }
  ]
}
```

`entries/machines/my_machine.json`（引用该模板 —— 注意 `type` 就是模板 id）：

```json
{
  "name": "item.mymod.my_guide.entry.my_machine",
  "icon": "mymod:my_machine",
  "category": "mymod:machines",
  "pages": [
    { "type": "mymod:my_machine", "recipe": "mymod:my_machine/iron", "text": "Iron processing." },
    { "type": "tfc:heat_recipe", "recipe": "tfc:heating/wrought_iron", "text": "See also TFC heating." }
  ]
}
```

> 最后一页演示了**直接复用 TFC 已注册的模板** `tfc:heat_recipe`（其模板 id 的命名空间是 `tfc`，因为文件在 TFC 的 assets 里）。这是附属模组不写一行 Java 就能展示 TFC 配方的最快路径。

### 16.5 需要注册的 Java 对象（仅在需要 Java 时）

| 要注册的东西 | 注册方式 | 时机 | 侧别 |
| --- | --- | --- | --- |
| 自定义 `ICustomComponent` 实现 | **无需注册**，靠模板里的 `"class"` 全限定名反射创建 | — | 客户端 |
| 自定义 `IComponentProcessor` 实现 | **无需注册**，靠模板里的 `"processor"` 全限定名反射创建 | — | 客户端 |
| 自定义模板组件类型 | `BookTemplate.registerComponent(id, clazz)` | `FMLClientSetupEvent` | 客户端 |
| 自定义 page 类型 | `ClientBookRegistry.INSTANCE.pageTypes.put(id, clazz)`（**内部 API**） | `FMLClientSetupEvent` | 客户端 |
| 多块 | `PatchouliAPI.get().registerMultiblock(id, mb)` | `FMLCommonSetupEvent` 之后任意时刻 | 双端 |
| 文本命令/函数 | `PatchouliAPI.get().registerCommand/registerFunction` | 客户端初始化 | 客户端 |
| 自定义 flag | `PatchouliAPI.get().setConfigFlag(name, value)` | 配置装载后 | 双端 |
| 书籍 / 分类 / 条目 / 模板 | **不放 Java，放 JSON 文件** | — | — |

`ICustomComponent` 实现的最小骨架（TFC 路线，推荐）：

```java
package com.example.mymod.compat.patchouli.component;

import com.mojang.blaze3d.systems.RenderSystem;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeManager;
import vazkii.patchouli.api.IComponentRenderContext;
import vazkii.patchouli.api.ICustomComponent;
import vazkii.patchouli.api.IVariable;

/**
 * 展示一条 mymod 配方。
 * 模板里写：{"type":"patchouli:custom","class":"com.example.mymod.compat.patchouli.component.MyMachineComponent","recipe":"#recipe"}
 * 因此 JSON 的 "recipe" 键会被注入到下面的 recipeId 字段。
 */
public class MyMachineComponent implements ICustomComponent {

    private transient int x, y;                 // transient ⇒ 不会被 JSON 覆盖
    private transient boolean errored;
    private ResourceLocation recipeId;          // 由 JSON 的 "recipe": "#recipe" 注入

    private transient Recipe<?> recipe;

    @Override
    public void build(int componentX, int componentY, int pageNum) {
        this.x = componentX;
        this.y = componentY;
        var level = Minecraft.getInstance().level;
        if (level == null || recipeId == null) { errored = true; return; }
        RecipeManager manager = level.getRecipeManager();
        this.recipe = manager.byKey(recipeId).map(h -> h.value()).orElse(null);
        this.errored = this.recipe == null;
    }

    @Override
    public void render(GuiGraphics graphics, IComponentRenderContext context, float pticks, int mouseX, int mouseY) {
        if (errored) {
            graphics.drawString(Minecraft.getInstance().font, "Missing recipe: " + recipeId, x, y, 0xFF0000, false);
            return;
        }
        var level = Minecraft.getInstance().level;
        if (level == null) return;

        RenderSystem.enableBlend();
        graphics.blit(context.getCraftingTexture(), x, y, 11, 71, 96, 24, 128, 256);
        context.renderIngredient(graphics, x + 4,  y + 4, mouseX, mouseY, recipe.getIngredients().get(0));
        context.renderItemStack(graphics, x + 40, y + 4, mouseX, mouseY, recipe.getToastSymbol());
        ItemStack out = recipe.getResultItem(level.registryAccess());
        context.renderItemStack(graphics, x + 76, y + 4, mouseX, mouseY, out);
    }
}
```

（`ICustomComponent.build` 由 `ComponentCustom.build` 传入组件坐标与页码；`onDisplayed`/`mouseClicked` 有默认空实现，可按需覆写。）

### 16.6 必须注意的坑（按重要度排序）

1. **`use_resource_pack: true` 缺失 ⇒ 书籍加载抛异常并被跳过**（`Book.java` L142-149）。日志里能看到 `"has use_resource_pack set to false"`。
2. **`en_us` 目录必须存在且包含所有内容的基准文件**。只放 `zh_cn` 会导致条目根本不被发现（`findFiles` 只列 `en_us`，见 §1.3）。
3. **`category` / `parent` 必须全限定（`domain:name`）**，否则抛 `IllegalArgumentException`；而**拼错不存在的分类**会抛 `RuntimeException("Entry in file %s does not have a valid category.")`。
4. **`type` 拼错不会报「类型不存在」，而会尝试当模板加载**，报错形式是 `IllegalArgumentException("Template <ns>:<name> does not exist")`。这是最常见的「页面不显示」原因，且错误信息在日志里很清楚。
5. **字段名拼错会被 Gson 静默忽略**，页面照常渲染但没有效果（例如把 `link_recipe` 写成 `linkRecipe`、把 `enable_visualize` 写成 `visualize`、把 `draw_filler` 写成 `filler`）。写字段时**逐字对照本文第 5 节的表**。
6. **`multiblock` 与 `multiblock_id` 二选一**；`pattern` 与 `sparse_pattern` 必须且只能有一个；结构里**必须有且只有一个 `0`**。`view_offset`、`displayed_multiblock` 是无效字段。
7. **配方页的 `recipe` 必须是真实存在的配方 id，且类型匹配**（`crafting` 页只认 `RecipeType.CRAFTING`）。查不到只打 warn 日志，页面显示为空而不是报错，容易被忽略。另外源码会把找不到的 id 再试一次 `crafttweaker:<path>`。
8. **图片建议 256×256 且只占左上 200×200**（源码按 0.5 倍缩放绘制 200×200 区域）。宽度/高度不是 2 的幂会出问题（官方警告）。
9. **`icon` / `index_icon` 以 `.png` 结尾会被当纹理**；写 `minecraft:diamond` 是物品，写 `minecraft:textures/item/diamond.png` 是纹理。
10. **advancement 门控依赖客户端已收到该 advancement**。开发期测试建议用配置项 `disableAdvancementLocking` / `testingMode`（分别对应 flag `advancements_disabled` / `testing_mode`），或用 flag 门控替代；否则「页面不显示」往往只是 advancement 没解锁。注意源码中的 flag `debug` 来自 `IXplatAbstractions.isDevEnvironment()`（即 `!FMLEnvironment.production`），**不存在 `-Dpatchouli.debug` 这类系统属性开关**（`grep "debug"` 在 `PatchouliConfig.java` 中只有 L33 一处）。
11. **`book.json` 改动需重启游戏**；`categories/entries/templates` 可热重载（书内铅笔按钮 / 重载资源包）。
12. **书籍内容纯客户端**，服务端不读 entries；但 `book.json` 服务端也读（用于创造栏与物品名）。因此 `book.json` 引用的翻译键要在 `assets/<modid>/lang/` 里（客户端语言文件），创造栏在服务端的显示不影响物品名（物品名在客户端解析）。
13. **`patchouli_data.json` 是客户端本地文件**，不能作为服务端可信进度（用 advancement 代替）。
14. **客户端类加载隔离**：任何引用 `GuiGraphics`、`Minecraft`、`ClientBookRegistry`、`BookPage`、`ICustomComponent` 的类都必须在**客户端专用**类里（NeoForge 用 `@EventBusSubscriber(value = Dist.CLIENT)` 或在 `DistExecutor`/`FMLClientSetupEvent` 中加载）。否则专用服务器启动时会 `NoClassDefFoundError`。
   同时，**如果 Patchouli 是 optional 依赖**，连 `PatchouliAPI` 本身的引用都要做加载隔离（先 `ModList.get().isLoaded("patchouli")` 再触碰相关类）。**本环境（TFC 实例）Patchouli 必然存在**（TFC 硬依赖它），因此直接声明 `required` 是最省事的做法。
15. **`registerMultiblock` 重复 id 抛异常**；请使用自己的命名空间，且不要在数据包重载时重复注册（该注册表不参与重载）。
16. **`registerTemplateAsBuiltin` 重复注册抛异常**，且只对「内建模板」（代码提供的模板）有意义 —— 用文件方式写在 assets 里的模板**不要**再调它。
17. **不要监听 `BookContentsReloadEvent`**（本版本不触发）；需要「书重载后做事」请自行挂资源重载事件。
18. **硬依赖声明**（`META-INF/neoforge.mods.toml`）：

```toml
[[dependencies.mymod]]
    modId = "patchouli"
    type = "required"
    versionRange = "[1.21.1-92-NEOFORGE,)"
    ordering = "NONE"
    side = "BOTH"
```

    编译期依赖（Gradle，参照 Firmalife 的写法）：`implementation "vazkii.patchouli:Patchouli:<version>-NEOFORGE"`。
    注：**纯 JSON 方案理论上不需要声明依赖**（文件放着就行），但声明 `optional` 可以显式表达意图；只要用了任何 Java API 就必须声明。

### 16.7 最小可运行检查清单

- [ ] `data/mymod/patchouli_books/my_guide/book.json` 存在，含 `name` 与 `use_resource_pack: true`
- [ ] `assets/mymod/patchouli_books/my_guide/en_us/categories/*.json` 至少一个，含 `name`/`description`/`icon`
- [ ] `assets/mymod/patchouli_books/my_guide/en_us/entries/**/*.json` 至少一个，含 `name`/`category`（全限定）/`icon`/`pages`
- [ ] 条目 `pages[].type` 是 16 个内置类型之一，或是自己 assets 里存在的模板 id
- [ ] 用 `patchouli:custom` 时：`"class"` 是全限定类名、类有无参构造器、在客户端侧
- [ ] 若声明了 `creative_tab`：该 tab 的 id 正确（`minecraft:tools_and_utilities` 等）
- [ ] 启动后日志无 `use_resource_pack` / `does not exist` / `does not have a valid category` 错误
- [ ] 游戏内书内点铅笔按钮可热重载内容

---

## 17. 未能核实／与前提不符的条目汇总（含检查位置）

| # | 条目 | 结论 | 已检查位置 |
| --- | --- | --- | --- |
| 1 | `PageRegistry.register(...)` / `registerPageType(...)` | **本版本不存在** | `grep -r "registerPageType\|PageRegistry"` 全仓库零命中；`ClientBookRegistry.java` 全文 |
| 2 | `PageSerializer` / `IPage` / `Page` / `PageDouble` | **本版本不存在**；对应物是 `BookPage` / `PageWithText` / `PageDoubleRecipe` | `Xplat/.../client/book/**` 全文件列举；`glob "**/Page*.java"` |
| 3 | `ComponentProcessor`（作为类型名） | **本版本不存在**；接口名是 `IComponentProcessor` | `grep "Processor"` 全部命中已逐条读过 |
| 4 | `patchouli:macros` / `patchouli:flags` 处理器 type id、`ProcessorMacros` / `ProcessorFlags` 类 | **不存在**，Processor 是 FQCN 反射 | 同上；`web/docs/patchouli-advanced/component-processors.md` 只用 FQCN |
| 5 | `patchouli:multiblock` 的 `displayed_multiblock` 字段 | **不存在** | `grep "displayed_multiblock\|displayed_state"` 零命中；`SerializedMultiblock.java` 全文 |
| 6 | 多块的 `view_offset` 字段 | **不存在**（源码只有 `offset`）；示例 JSON 中出现过但被忽略 | `SerializedMultiblock.java`；`testbook1/.../testy.json` |
| 7 | `book.json` 的 `extend` / `allow_extensions` | `extend` 存在则抛异常；`allow_extensions` 无任何读取 | `Book.java` L151-158；`grep "allow_extensions"` 零命中（仅 `web/docs` 有） |
| 8 | `patchouli:shaped_book_recipe` / `shapeless_book_recipe` | **本 tag 源码中不存在**；1.21.1 用原版配方 + `result.components` | `grep -r "book_recipe\|BookRecipe\|RecipeSerializer"` 仅命中 `web/docs/**`；`data/patchouli/recipes/test_recipe.json` |
| 9 | 书籍物品 id `patchouli:book` | **实为 `patchouli:guide_book`**；`patchouli:book` 是**数据组件**名 | `PatchouliItems.java` L12；`PatchouliDataComponents.java` L12 |
| 10 | `PatchouliAPI` 上的 `@Mod` 注解 | **不存在**；`@Mod` 只在 `NeoForgeModInitializer` | `grep -r "@Mod("` 唯一命中 |
| 11 | `PatchouliConfigAccess` 是 record | **是 interface** | 该文件全文 |
| 12 | `PatchouliConfigAccess.overflowMode` 对应配置键名 | 配置键是 `textOverflowMode`，与字段名不同 | 子代理抄录 `NeoForgePatchouliConfig` |
| 13 | ItemStack 字符串的 `{nbt}` 花括号写法 | 源码只用原版 `ItemParser`，**无 `{}` 专门处理**；该写法在本版本是否仍被接受**未能核实** | `ItemStackUtil.deserializeStack`；`web/docs/patchouli-advanced/itemstack-format.md`（文档滞后） |
| 14 | `BookContentsReloadEvent` 是否可作扩展点 | **本版本无任何触发点**，不可用 | `grep "fireBookReload\|BookContentsReloadEvent"`；`ReloadContentsHandler.java` 全文 |
| 15 | API 包是否存在成文稳定性承诺 | **未能核实**（`package-info.java` 仅一行非空注解；稳定性关键词零命中） | `api/package-info.java`；全仓库 grep |
| 16 | 本仓库 `web/docs/**` 与源码的差异 | 部分文档滞后（已逐处标注：`extend`、`book_recipe`、`patchouli:book`、`{nbt}`、`landing_text` 必填性等） | 逐文件对照 |
| 17 | TFC 侧 `compat.patchouli` 的源码实现细节 | **未能核实源码**（`src-ref/TerraFirmaCraft` 不存在或工作树为空）；但已从 jar 的 JSON、类清单与 class 常量池核实行为 | `Test-Path`；`TFC.classes.txt`；jar 内 JSON 与 class 字符串 |
| 18 | `web/docs` 中 `landing_text` 标注为 mandatory | 源码默认为 `"patchouli.gui.lexicon.landing_info"`，**实际非必填** | `Book.java` L110 |

---

## 18. 速查表（Cheat Sheet）

### 18.1 目录与 id

| 内容 | 路径 | id |
| --- | --- | --- |
| 书籍声明 | `data/<modid>/patchouli_books/<book>/book.json` | `<modid>:<book>` |
| 分类 | `assets/<ns>/patchouli_books/<book>/en_us/categories/<path>.json` | `<ns>:<path>` |
| 条目 | `assets/<ns>/patchouli_books/<book>/en_us/entries/<path>.json` | `<ns>:<path>` |
| 模板 | `assets/<ns>/patchouli_books/<book>/en_us/templates/<path>.json` | `<ns>:<path>` |
| 其它语言 | 同上，把 `en_us` 换成语言代码 | 同 id（覆盖） |
| modpack 外部书 | `.minecraft/patchouli_books/<book>/{book.json,en_us/...}` | `patchouli:<book>` |

### 18.2 内置 page 类型（16 种）

```
patchouli:text          patchouli:crafting      patchouli:smelting     patchouli:blasting
patchouli:smoking       patchouli:campfire      patchouli:smithing     patchouli:stonecutting
patchouli:image         patchouli:spotlight     patchouli:empty        patchouli:multiblock
patchouli:link          patchouli:relations     patchouli:entity       patchouli:quest
（未知 type ⇒ 按模板处理，模板 id = 该 type）
```

### 18.3 内置模板组件类型（9 种）

```
patchouli:text   patchouli:item     patchouli:image    patchouli:header   patchouli:separator
patchouli:frame  patchouli:entity   patchouli:tooltip  patchouli:custom
```

### 18.4 常用文本命令

```
$()  $(br)  $(br2)  $(li)/$(li2)  $(#rrggbb)  $(0-f)
$(l)  $(o)  $(m)  $(n)  $(k)          # 加粗/斜体/删除线/下划线/乱码
$(item)  $(thing)                      # 内置宏 → 颜色
$(l:entry_id)  $(l:entry#anchor)  $(l:https://...)  $(/l)
$(t:提示)  $(/t)   $(c:/命令)  $(/c)
$(k:key.jump)                          # 按键名
```

### 18.5 常用 Java 调用

```java
ItemStack book = PatchouliAPI.get().getBookStack(id);                 // 拿书物品
PatchouliAPI.get().openBookGUI(serverPlayer, id);                     // 服务端开书
PatchouliAPI.get().openBookEntry(serverPlayer, id, entryId, page);    // 服务端开书到某页
PatchouliAPI.get().registerMultiblock(id, mb);                        // 注册多块
PatchouliAPI.get().setConfigFlag("mymod:feature", true);              // 自定义 flag
PatchouliAPI.get().registerFunction("cfg", (param, style) -> ...);    // $(cfg:xxx) 文本函数（客户端）
ClientBookRegistry.INSTANCE.pageTypes.put(id, MyPage.class);          // 自定义 page 类型（内部 API）
BookTemplate.registerComponent(id, MyComponent.class);                // 自定义模板组件
```

### 18.6 关键常量

| 常量 | 值 | 来源 |
| --- | --- | --- |
| `GuiBook.PAGE_WIDTH` / `PAGE_HEIGHT` | `116` / `156` | `client/book/gui/GuiBook.java` L53-54 |
| `GuiBook.FULL_WIDTH` / `FULL_HEIGHT` | `272` / `180` | 同上 L51-52 |
| `GuiBook.TEXT_LINE_HEIGHT` | `9` | 同上 L58 |
| `GuiBook.TOP_PADDING` | `18` | 同上 L55 |
| `GuiBook.MAX_BOOKMARKS` | `10` | 同上 L59 |
| `BookContentsBuilder.DEFAULT_LANG` | `"en_us"` | `client/book/BookContentsBuilder.java` L30 |
| `BookRegistry.BOOKS_LOCATION` | `"patchouli_books"` | `common/book/BookRegistry.java` L32 |
| 书籍物品 | `patchouli:guide_book` + 组件 `patchouli:book` | `common/item/PatchouliItems.java`、`PatchouliDataComponents.java` |
| 开书 advancement trigger | `patchouli:open_book` | `common/advancement/BookOpenTrigger.java` L21 |
| 客户端状态文件 | `patchouli_data.json`（工作目录根） | `client/base/PersistentData.java` L27 |

---

## 附：参考文件索引（相对 Patchouli 仓库根）

| 主题 | 文件 |
| --- | --- |
| 书籍字段 | `Xplat/src/main/java/vazkii/patchouli/common/book/Book.java` |
| 书籍发现/加载 | `Xplat/src/main/java/vazkii/patchouli/common/book/BookRegistry.java`、`BookFolderLoader.java` |
| 分类字段 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookCategory.java` |
| 条目字段 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookEntry.java` |
| 页面基类 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookPage.java` |
| 内置 page 注册 | `Xplat/src/main/java/vazkii/patchouli/client/book/ClientBookRegistry.java` |
| 内容装配 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookContentsBuilder.java`、`BookContents.java` |
| 内容加载器 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookContentLoader.java`、`BookContentResourceListenerLoader.java`、`BookContentResourceDirectLoader.java`、`BookContentExternalLoader.java` |
| 模板 | `Xplat/src/main/java/vazkii/patchouli/client/book/template/BookTemplate.java`、`TemplateComponent.java`、`TemplateInclusion.java`、`VariableAssigner.java`、`JsonVariableWrapper.java` |
| 内置组件 | `Xplat/src/main/java/vazkii/patchouli/client/book/template/component/*.java` |
| 文本解析 | `Xplat/src/main/java/vazkii/patchouli/client/book/text/BookTextParser.java` |
| 多块 | `Xplat/src/main/java/vazkii/patchouli/common/multiblock/*.java` |
| 配置 flag | `Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliConfig.java` |
| API 入口 | `Xplat/src/main/java/vazkii/patchouli/api/PatchouliAPI.java`、`PatchouliConfigAccess.java` |
| API 实现 | `Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliAPIImpl.java` |
| 事件 | `NeoForge/src/main/java/vazkii/patchouli/api/BookDrawScreenEvent.java`、`BookContentsReloadEvent.java` |
| 初始化 | `NeoForge/src/main/java/vazkii/patchouli/neoforge/common/NeoForgeModInitializer.java`、`.../client/NeoForgeClientInitializer.java` |
| 物品 | `Xplat/src/main/java/vazkii/patchouli/common/item/ItemModBook.java`、`PatchouliItems.java`、`PatchouliDataComponents.java` |
| itemstack 解析 | `Xplat/src/main/java/vazkii/patchouli/common/util/ItemStackUtil.java` |
| 图标 | `Xplat/src/main/java/vazkii/patchouli/client/book/BookIcon.java` |
| 本地状态 | `Xplat/src/main/java/vazkii/patchouli/client/base/PersistentData.java` |
| advancement | `Xplat/src/main/java/vazkii/patchouli/common/advancement/BookOpenTrigger.java`、`PatchouliCriteriaTriggers.java` |
| 命令 | `Xplat/src/main/java/vazkii/patchouli/common/command/OpenBookCommand.java` |
| 官方文档（部分滞后） | `web/docs/**` |
| 示例书籍（权威范例） | `Xplat/src/main/resources/data/patchouli/patchouli_books/*/book.json`、`Xplat/src/main/resources/assets/patchouli/patchouli_books/**` |

