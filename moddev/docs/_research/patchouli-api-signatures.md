# Patchouli API 签名与注册时机分析（release-1.21.1-93）

- 仓库根目录：`D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\Patchouli`
- 版本核实：`git describe --tags` → `release-1.21.1-93`；`git log -1 --oneline` → `0c2fdff Use registry access for book icons (#843)`
- 目标环境：Minecraft 1.21.1 / NeoForge 21.1.x / Java 21
- 本文所有签名均从源码逐字抄录（去掉了方法体，保留了完整泛型、注解与关键 javadoc 中的侧别说明）。

---

## 0. 稳定公开 API 与内部实现的划分（结论速览）

| 类别 | 包/类 | 第三方是否可依赖 |
| --- | --- | --- |
| **稳定公开 API** | `vazkii.patchouli.api` 包下全部类型（`PatchouliAPI`、`PatchouliAPI.IPatchouliAPI`、`PatchouliConfigAccess`、`IMultiblock`、`IStateMatcher`、`IStyleStack`、`IComponentProcessor`、`IComponentRenderContext`、`ICustomComponent`、`IVariable`、`IVariableProvider`、`IVariableSerializer`、`IVariablesAvailableCallback`、`TriPredicate`、`VariableHelper`），以及 NeoForge 模块中的同包事件 `BookDrawScreenEvent` / `BookContentsReloadEvent` | 是 |
| **仅为占位/兼容而存在** | `vazkii.patchouli.api.stub.StubPatchouliAPI`、`vazkii.patchouli.api.stub.StubMatcher`、`vazkii.patchouli.api.stub.StubMultiblock` | 不建议直接引用；它由 `PatchouliAPI` 内部在 Patchouli 缺失时返回给调用者 |
| **内部实现（不要调用）** | `vazkii.patchouli.common.*`（含 `PatchouliAPIImpl`、`PatchouliConfig`、`BookRegistry`、`MultiblockRegistry`、`ItemModBook`…）、`vazkii.patchouli.client.*`、`vazkii.patchouli.xplat.*`、`vazkii.patchouli.neoforge.*`、`vazkii.patchouli.mixin.*` | 否 |
| **跨加载器内部 SPI** | `vazkii.patchouli.xplat.IXplatAbstractions`、`IClientXplatAbstractions`、`XplatModContainer` | 否，且**不在** `api` 包内（详见第 8 节） |

`vazkii.patchouli.api` 包的 `package-info.java` 全文只有两行，带包级非空默认注解：

```java
@net.minecraft.MethodsReturnNonnullByDefault
package vazkii.patchouli.api;
```

即该包内**所有方法的返回值默认视为非空**，需要返回 null 的地方必须显式标注 `@Nullable`（源码中确实如此，例如 `getOpenBookGui()`、`getMultiblock(ResourceLocation)`、`getCurrentMultiblock()`）。

---

## 1. `Xplat/src/main/java/vazkii/patchouli/api/PatchouliAPI.java`

### 1.1 类声明与字段

```java
public class PatchouliAPI {

	// private static final，非 public
	private static final Supplier<IPatchouliAPI> LAZY_INSTANCE = Suppliers.memoize(() -> {
		try {
			return (IPatchouliAPI) Class.forName("vazkii.patchouli.common.base.PatchouliAPIImpl").newInstance();
		} catch (ReflectiveOperationException e) {
			LogManager.getLogger().warn("Unable to find PatchouliAPIImpl, using a dummy");
			return StubPatchouliAPI.INSTANCE;
		}
	});

	public static final String MOD_ID = "patchouli";
	public static final Logger LOGGER = LogManager.getLogger(MOD_ID);
```

公开静态方法：

```java
	/**
	 * Obtain the Patchouli API, either a valid implementation if Patchouli is present, else
	 * a no-op stub instance if Patchouli is absent.
	 * Note that many API functions make no sense to call before books are loaded (which is on login),
	 * please use common sense and your best judgment.
	 */
	public static IPatchouliAPI get();
```

### 1.2 嵌套接口 `IPatchouliAPI`（`public interface IPatchouliAPI`，位于 `PatchouliAPI` 类内部，因而是隐式 `public static`）

```java
	public interface IPatchouliAPI {
		/**
		 * Returns false if this is a real API class loaded by the actual mod.
		 */
		boolean isStub();

		/**
		 * @return A read-only view of Patchouli's config options
		 */
		PatchouliConfigAccess getConfig();

		/**
		 * Sets a config flag to the value passed.<br>
		 * This is safe to call during parallel mod loading.<br>
		 * IMPORTANT: DO NOT call this without your flag being prefixed with your
		 * mod id. There is no protection against that, but don't be a jerk.
		 */
		void setConfigFlag(String flag, boolean value);

		/**
		 * Gets the value of a config flag, or false if it doesn't have a value.
		 */
		boolean getConfigFlag(String flag);

		/**
		 * Sends a network message to the given player
		 * to open the given book to the last page that was open, or the landing page otherwise.
		 */
		void openBookGUI(ServerPlayer player, ResourceLocation book);

		/**
		 * Sends a network message to the given player
		 * to open the book to the given entry
		 *
		 * @param page Zero-indexed page number
		 */
		void openBookEntry(ServerPlayer player, ResourceLocation book, ResourceLocation entry, int page);

		/**
		 * Client version of {@link #openBookGUI(ServerPlayer, ResourceLocation)}.
		 */
		void openBookGUI(ResourceLocation book);

		/**
		 * Client version of {@link #openBookEntry(ServerPlayer, ResourceLocation, ResourceLocation, int)}
		 */
		void openBookEntry(ResourceLocation book, ResourceLocation entry, int page);

		/**
		 * Returns the book ID of the currently open book, if any. Only works clientside.
		 */
		@Nullable
		ResourceLocation getOpenBookGui();

		/**
		 * Works on both sides.
		 *
		 * @return                          The subtitle (edition string/what appears under the title in the landing
		 *                                  page) of the book.
		 * @throws IllegalArgumentException if the book id given cannot be found
		 */
		Component getSubtitle(ResourceLocation bookId);

		/**
		 * Returns a book item with its NBT set to the book passed in. Works on both sides.
		 */
		ItemStack getBookStack(ResourceLocation book);

		/**
		 * Register a template you made as a built in template to be used with all books
		 * as the "res" resource location. The supplier should give an input stream that
		 * reads a full json file, containing a template.
		 * Only works on client.
		 */
		void registerTemplateAsBuiltin(ResourceLocation res, Supplier<InputStream> streamProvider);

		/**
		 * Register a Patchouli command, of the type $(cmdname).
		 * A command gets an IStyleStack if it wishes to modify it (for example, $(o) italicizes),
		 * and returns the text that should replace the command (for example, $(playername) is replaced
		 * with the current player's username). Commands that only modify style should return "".
		 * This is thread safe. Only works on client.
		 */
		void registerCommand(String name, Function<IStyleStack, String> command);

		/**
		 * Register a Patchouli function, of the type $(funcname:arg).
		 * A function is like a command,
		 * except it gets an additional argument (the text after the colon),
		 * for things like conditional formatting or differing return values.
		 * For example, $(k:use) is replaced by Right Button by default.
		 * This is thread safe. Only works on client.
		 */
		void registerFunction(String name, BiFunction<String, IStyleStack, String> function);

		/**
		 * Gets a multiblock by its ID, or null if none exists for it.
		 */
		@Nullable
		IMultiblock getMultiblock(ResourceLocation id);

		/**
		 * Registers a multiblock given its resource location. This takes care of both registering it
		 * and setting its resource location to the one passed.
		 */
		IMultiblock registerMultiblock(ResourceLocation id, IMultiblock mb);

		/**
		 * @return The multiblock currently being visualized in-world or null if no multiblock is visualized. Only works
		 *         clientside.
		 */
		@Nullable
		IMultiblock getCurrentMultiblock();

		/**
		 * Sets the given multiblock as the currently visualized one. This overwrites any currently visualized
		 * multiblock.
		 * Only works clientside.
		 *
		 * @param multiblock  The multiblock to visualize
		 * @param displayName The name to show above the completion bar
		 * @param center      Where to place the multiblock's center
		 * @param rotation    Orientation to visualize
		 */
		void showMultiblock(IMultiblock multiblock, Component displayName, BlockPos center, Rotation rotation);

		/**
		 * Clears the currently visualized multiblock. Only works clientside.
		 */
		void clearMultiblock();

		/**
		 * Creates a multiblock given the pattern and targets given. ... The Object can be a Block, an
		 * BlockState, or an IStateMatcher.
		 */
		IMultiblock makeMultiblock(String[][] pattern, Object... targets);

		/**
		 * Create a sparse multiblock. ... The center of a sparse multiblock is always (0, 0, 0), and the keys
		 * of {@code positions} are relative to that space.
		 */
		IMultiblock makeSparseMultiblock(Map<BlockPos, IStateMatcher> positions);

		IStateMatcher predicateMatcher(BlockState display, Predicate<BlockState> predicate);
		IStateMatcher predicateMatcher(Block display, Predicate<BlockState> predicate);
		IStateMatcher stateMatcher(BlockState state);
		IStateMatcher propertyMatcher(BlockState state, Property<?>... properties);
		IStateMatcher looseBlockMatcher(Block block);
		IStateMatcher strictBlockMatcher(Block block);
		IStateMatcher displayOnlyMatcher(BlockState state);
		IStateMatcher displayOnlyMatcher(Block block);

		/**
		 * @return A state matcher that accepts any block in the given tag
		 */
		IStateMatcher tagMatcher(TagKey<Block> block);

		/**
		 * Creates an IStateMatcher that accepts only air blocks.
		 */
		IStateMatcher airMatcher();

		/**
		 * Creates an IStateMatcher that accepts anything.
		 */
		IStateMatcher anyMatcher();
	}
```

> 说明：`IPatchouliAPI` 内**没有**任何 `registerBook(...)` 方法（1.21.1 已移除旧的书籍注册 API），也没有 `registerPageType(...)`。这与源码一致：全仓库 grep `registerBook` 仅命中 `registerMultiblock`（见第 3 节说明）。

### 1.3 `@Mod` 注解与初始化时机（重要澄清）

- **`PatchouliAPI` 类上没有任何 `@Mod` 注解。** 它只是一个普通工具类，`MOD_ID` 常量（值为 `"patchouli"`）才是被别处引用的东西。
- 全仓库 grep `@Mod\(` **只有一处**命中：

```java
// NeoForge/src/main/java/vazkii/patchouli/neoforge/common/NeoForgeModInitializer.java:35
@Mod(PatchouliAPI.MOD_ID)
```

  因此 **Patchouli 在 NeoForge 上的 mod id 就是 `PatchouliAPI.MOD_ID` = `"patchouli"`**，由 `NeoForgeModInitializer` 承载。Fabric 模块中不存在 `@Mod` 注解（Fabric 使用 `ModInitializer` 机制，不在本文范围内）。
- **`PatchouliApiImpl` 的加载时机**：`LAZY_INSTANCE` 用 Guava `Suppliers.memoize(...)` 包装，**首次调用 `PatchouliAPI.get()` 时才反射加载 `vazkii.patchouli.common.base.PatchouliAPIImpl`**；反射失败（`ReflectiveOperationException`）时打印 warn 日志 `"Unable to find PatchouliAPIImpl, using a dummy"` 并退化为 `StubPatchouliAPI.INSTANCE`。这不是 mod 生命周期事件驱动的初始化，而是惰性单例。
- 注意 `Class.forName(...).newInstance()` 在 Java 21 上属于已弃用 API（`Class.newInstance()` 自 Java 9 起 deprecated），但**源码中并未标注 `@Deprecated`**，属于遗留写法。
- javadoc 明确提示：**很多 API 函数在书籍加载完成之前调用没有意义（书籍是在玩家登录时加载的）**。这直接约束了附属模组的调用时机。

---

## 2. `Xplat/src/main/java/vazkii/patchouli/api/stub/StubPatchouliAPI.java`

类声明与全部实现（`StubPatchouliAPI` 位于 `api.stub` 子包，虽在 `api` 命名空间下，但它是「Patchouli 未安装时」的降级实现）：

```java
public class StubPatchouliAPI implements IPatchouliAPI {

	public static final StubPatchouliAPI INSTANCE = new StubPatchouliAPI();

	private StubPatchouliAPI() {}   // 私有构造器：只能通过 INSTANCE 访问

	@Override public boolean isStub();                                        // return true
	@NotNull @Override public PatchouliConfigAccess getConfig();              // 返回匿名空实现（见下）
	@Override public void setConfigFlag(String flag, boolean value);           // NO-OP
	@Override public boolean getConfigFlag(String flag);                       // return false
	@Override public void openBookGUI(ServerPlayer player, ResourceLocation book);                              // NO-OP
	@Override public void openBookEntry(ServerPlayer player, ResourceLocation book, ResourceLocation entry, int page); // 空
	@Override public void openBookGUI(ResourceLocation book);                 // NO-OP
	@Override public void openBookEntry(ResourceLocation book, ResourceLocation entry, int page);               // 空
	@Override public ResourceLocation getOpenBookGui();                        // return null
	@Override public Component getSubtitle(ResourceLocation bookId);           // throw new IllegalArgumentException("Patchouli is not loaded")
	@Override public void registerCommand(String name, Function<IStyleStack, String> command);                  // NO-OP
	@Override public void registerFunction(String name, BiFunction<String, IStyleStack, String> function);      // NO-OP
	@Override public ItemStack getBookStack(ResourceLocation book);            // return ItemStack.EMPTY
	@Override public void registerTemplateAsBuiltin(ResourceLocation res, Supplier<InputStream> streamProvider); // NO-OP
	@Override public IMultiblock getMultiblock(ResourceLocation res);          // return null
	@Override public IMultiblock registerMultiblock(ResourceLocation res, IMultiblock mb);                      // return mb
	@Nullable @Override public IMultiblock getCurrentMultiblock();             // return null
	@Override public void showMultiblock(IMultiblock multiblock, Component displayName, BlockPos center, Rotation rotation); // 空
	@Override public void clearMultiblock();                                   // 空
	@Override public IMultiblock makeMultiblock(String[][] pattern, Object... targets);                          // StubMultiblock.INSTANCE
	@Override public IMultiblock makeSparseMultiblock(Map<BlockPos, IStateMatcher> positions);                   // StubMultiblock.INSTANCE
	@Override public IStateMatcher predicateMatcher(BlockState display, Predicate<BlockState> predicate);        // StubMatcher.INSTANCE
	@Override public IStateMatcher predicateMatcher(Block display, Predicate<BlockState> predicate);             // StubMatcher.INSTANCE
	@Override public IStateMatcher stateMatcher(BlockState state);                                               // StubMatcher.INSTANCE
	@Override public IStateMatcher propertyMatcher(BlockState state, Property<?>... properties);                 // StubMatcher.INSTANCE
	@Override public IStateMatcher looseBlockMatcher(Block block);                                              // StubMatcher.INSTANCE
	@Override public IStateMatcher strictBlockMatcher(Block block);                                             // StubMatcher.INSTANCE
	@Override public IStateMatcher displayOnlyMatcher(BlockState state);                                        // StubMatcher.INSTANCE
	@Override public IStateMatcher displayOnlyMatcher(Block block);                                             // StubMatcher.INSTANCE
	@Override public IStateMatcher airMatcher();                                                                // StubMatcher.INSTANCE
	@Override public IStateMatcher anyMatcher();                                                                // StubMatcher.INSTANCE
	@Override public IStateMatcher tagMatcher(TagKey<Block> block);                                             // StubMatcher.INSTANCE
}
```

其 `getConfig()` 返回的匿名 `PatchouliConfigAccess` 固定值：`disableAdvancementLocking()=false`、`noAdvancementBooks()=Collections.emptyList()`、`testingMode()=false`、`inventoryButtonBook()=""`、`useShiftForQuickLookup()=false`、`overflowMode()=TextOverflowMode.OVERFLOW`、`quickLookupTime()=Integer.MAX_VALUE`。

**注意**：stub 的 `overflowMode()` 默认是 `OVERFLOW`，而 NeoForge 真实配置的默认值是 `RESIZE`（见第 4 节），两者不一致。

---

## 3. `Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliAPIImpl.java`

### 3.1 类声明与非 public 辅助方法

```java
public class PatchouliAPIImpl implements IPatchouliAPI {

	// private static，不是 public API
	private static void assertPhysicalClient() {
		Preconditions.checkState(
				IXplatAbstractions.INSTANCE.isPhysicalClient(),
				"Not on the physical client"
		);
	}
	// 隐式 public 无参构造器（源码未显式声明），供 PatchouliAPI 的反射调用使用
}
```

`assertPhysicalClient()` 是**运行时硬检查**：在专用服务器（dedicated server）上调用任何"仅客户端"的 API 会抛出 `IllegalStateException("Not on the physical client")`，而不是静默失败。

### 3.2 全部 public 方法与关键实现细节

```java
	public boolean isStub();
	// → return false

	@NotNull @Override
	public PatchouliConfigAccess getConfig();
	// → return PatchouliConfig.get();（内部静态配置持有者；set 之前为 null）

	@Override
	public void setConfigFlag(String flag, boolean value);
	// → PatchouliConfig.setFlag(flag, value);（写入 ConcurrentHashMap，key 会 trim + toLowerCase）

	@Override
	public boolean getConfigFlag(String flag);
	// → PatchouliConfig.getConfigFlag(flag);
	//   支持 "!"（取反）、"&"/"|" 前缀的组合查询、以及 "mod:<modid>" 内置 flag；
	//   未知名会打 warn 日志并返回 false

	@Override
	public void openBookGUI(ServerPlayer player, ResourceLocation book);
	// → BookOpenTrigger.INSTANCE.trigger(player, book);              // 触发 advancement criterion
	// → IXplatAbstractions.INSTANCE.sendOpenBookGui(player, book, null, 0);

	@Override
	public void openBookEntry(ServerPlayer player, ResourceLocation book, ResourceLocation entry, int page);
	// → BookOpenTrigger.INSTANCE.trigger(player, book, entry, page);
	// → IXplatAbstractions.INSTANCE.sendOpenBookGui(player, book, entry, page);

	@Override
	public void openBookGUI(ResourceLocation book);
	// → assertPhysicalClient();
	// → ClientBookRegistry.INSTANCE.displayBookGui(book, null, 0);

	@Override
	public void openBookEntry(ResourceLocation book, ResourceLocation entry, int page);
	// → assertPhysicalClient();
	// → ClientBookRegistry.INSTANCE.displayBookGui(book, entry, page);

	@Override
	public ResourceLocation getOpenBookGui();
	// → assertPhysicalClient();
	// → Minecraft.getInstance().screen instanceof GuiBook ? ((GuiBook) gui).book.id : null
	//   （源码使用传统的 `gui instanceof GuiBook` + 强制转换写法，此处等价描述）

	@NotNull @Override
	public Component getSubtitle(@NotNull ResourceLocation bookId);
	// → BookRegistry.INSTANCE.books.get(bookId)；为 null 时 throw new IllegalArgumentException("Book not found: " + bookId)
	// → 否则 return book.getSubtitle();

	@Override
	public void registerCommand(String name, Function<IStyleStack, String> command);
	// → assertPhysicalClient();
	// → BookTextParser.register(command::apply, name);

	@Override
	public void registerFunction(String name, BiFunction<String, IStyleStack, String> function);
	// → assertPhysicalClient();
	// → BookTextParser.register(function::apply, name);

	@Override
	public ItemStack getBookStack(ResourceLocation book);
	// → return ItemModBook.forBook(book);

	@Override
	public void registerTemplateAsBuiltin(ResourceLocation res, Supplier<InputStream> streamProvider);
	// → assertPhysicalClient();
	// → 先 streamProvider.get() 做 null 检查（null 则 throw new NullPointerException("Stream provider can't return a null stream")）并 IOUtils.closeQuietly 关闭测试流；
	// → Supplier<BookTemplate> prev = BookContents.addonTemplates.put(res, () -> { InputStreamReader + ClientBookRegistry.INSTANCE.gson.fromJson(reader, BookTemplate.class) });
	// → 若 prev != null 则 throw new IllegalArgumentException("Template " + res + " is already registered")
	//   注意：是先 put 再判重，因此重复注册时 map 中已有的旧值已被新值覆盖

	@Override
	public IMultiblock getMultiblock(ResourceLocation res);
	// → return MultiblockRegistry.MULTIBLOCKS.get(res);

	@Override
	public IMultiblock registerMultiblock(ResourceLocation res, IMultiblock mb);
	// → return MultiblockRegistry.registerMultiblock(res, mb);

	@Override
	public IMultiblock getCurrentMultiblock();
	// → assertPhysicalClient();
	// → MultiblockVisualizationHandler.hasMultiblock ? MultiblockVisualizationHandler.getMultiblock() : null

	@Override
	public void showMultiblock(@NotNull IMultiblock multiblock, @NotNull Component displayName, @NotNull BlockPos center, @NotNull Rotation rotation);
	// → assertPhysicalClient();
	// → MultiblockVisualizationHandler.setMultiblock(multiblock, displayName, null, false);
	// → MultiblockVisualizationHandler.anchorTo(center, rotation);

	@Override
	public void clearMultiblock();
	// → assertPhysicalClient();
	// → MultiblockVisualizationHandler.setMultiblock(null, null, null, false);

	@Override
	public IMultiblock makeMultiblock(String[][] pattern, Object... targets);
	// → new DenseMultiblock(pattern, targets)

	@Override
	public IMultiblock makeSparseMultiblock(Map<BlockPos, IStateMatcher> positions);
	// → new SparseMultiblock(positions)

	@Override
	public IStateMatcher predicateMatcher(BlockState display, Predicate<BlockState> predicate);
	// → StateMatcher.fromPredicate(display, predicate)

	@Override
	public IStateMatcher predicateMatcher(Block display, Predicate<BlockState> predicate);
	// → StateMatcher.fromPredicate(display, predicate)

	@Override
	public IStateMatcher stateMatcher(BlockState state);
	// → StateMatcher.fromState(state)

	@Override
	public IStateMatcher propertyMatcher(BlockState state, Property<?>... properties);
	// → StateMatcher.fromStateWithFilter(state, Arrays.asList(properties)::contains)

	@Override
	public IStateMatcher looseBlockMatcher(Block block);
	// → StateMatcher.fromBlockLoose(block)

	@Override
	public IStateMatcher strictBlockMatcher(Block block);
	// → StateMatcher.fromBlockStrict(block)

	@Override
	public IStateMatcher displayOnlyMatcher(BlockState state);
	// → StateMatcher.displayOnly(state)

	@Override
	public IStateMatcher displayOnlyMatcher(Block block);
	// → StateMatcher.displayOnly(block)

	@NotNull @Override
	public IStateMatcher tagMatcher(@NotNull TagKey<Block> tag);
	// → 返回匿名 IStateMatcher：
	//    getDisplayedState(long ticks)：BuiltInRegistries.BLOCK.getTag(tag) 存在时按 (ticks/20) % n.size() 轮换显示该 tag 中第 idx 个方块的 defaultBlockState()，否则显示 Blocks.BEDROCK.defaultBlockState()
	//    getStatePredicate()：返回 (w, p, s) -> s.is(tag)
	//   源码内 TODO 注释：本实现允许不存在的 tag，而 StringStateMatcher 版本会校验 tag 存在

	@Override
	public IStateMatcher airMatcher();
	// → StateMatcher.AIR

	@Override
	public IStateMatcher anyMatcher();
	// → StateMatcher.ANY
```

### 3.3 `registerMultiblock` 具体做了什么（`MultiblockRegistry`）

`Xplat/src/main/java/vazkii/patchouli/common/multiblock/MultiblockRegistry.java`（**内部类，非 API**）：

```java
public class MultiblockRegistry {
	public static final Map<ResourceLocation, IMultiblock> MULTIBLOCKS = new ConcurrentHashMap<>();

	public static IMultiblock registerMultiblock(ResourceLocation location, IMultiblock multiblock) {
		IMultiblock prev = MULTIBLOCKS.put(location, multiblock);
		if (prev != null) {
			throw new IllegalArgumentException("Multiblock " + location + " already registered");
		} else {
			return multiblock.setId(location);
		}
	}
}
```

要点：
1. 使用 `ConcurrentHashMap`，因此线程安全；
2. **重复注册同一个 `ResourceLocation` 会抛 `IllegalArgumentException`**（但旧值已被 `put` 覆盖）；
3. 返回的是 `multiblock.setId(location)` 的结果（即把 id 写回 multiblock 对象），这正是 `PatchouliAPI` javadoc 所说"注册并同时设置其 resource location"；
4. 该注册表**不参与数据包重载**，属于运行期内存注册表。

### 3.4 `getBookStack` 如何构造物品（`ItemModBook.forBook`）

`Xplat/src/main/java/vazkii/patchouli/common/item/ItemModBook.java`（**内部类，非 API**）：

```java
	public static ItemStack forBook(Book book) {
		return forBook(book.id);
	}

	public static ItemStack forBook(ResourceLocation book) {
		ItemStack stack = new ItemStack(PatchouliItems.BOOK);

		stack.set(PatchouliDataComponents.BOOK, book);

		return stack;
	}
```

要点：
- 返回的是 **Patchouli 自己的 `patchouli:guide_book` 物品**（`PatchouliItems.BOOK`），不是附属模组自定义物品；
- 书籍 id 通过 **数据组件**（1.21.1 的数据组件 API，`PatchouliDataComponents.BOOK`）写入，**不是 NBT**（`IPatchouliAPI#getBookStack` 的 javadoc 仍写"with its NBT set"，属于陈旧措辞）；
- 读取端 `getBook(ItemStack)` → `stack.get(PatchouliDataComponents.BOOK)` → `BookRegistry.INSTANCE.books.get(res)`；
- 因此**用 `getBookStack` 生成的物品只有在客户端/服务端书籍注册表已加载该书时才会正常显示与打开**。

### 3.5 `openBook` 的侧别与网络消息链路

- 服务端重载 `openBookGUI(ServerPlayer, ResourceLocation)` / `openBookEntry(ServerPlayer, ResourceLocation, ResourceLocation, int)`：
  1. `BookOpenTrigger.INSTANCE.trigger(...)` 触发 advancement criterion（`vazkii.patchouli.common.advancement.BookOpenTrigger`）；
  2. `IXplatAbstractions.INSTANCE.sendOpenBookGui(player, book, entry, page)`。
- NeoForge 侧实现在 `NeoForge/src/main/java/vazkii/patchouli/neoforge/xplat/NeoForgeXplatImpl.java`：

```java
	@Override
	public void sendOpenBookGui(ServerPlayer player, ResourceLocation book, @Nullable ResourceLocation entry, int page) {
		NeoForgeNetworkHandler.sendOpenBook(player, book, entry, page);
	}
```

- 而 `NeoForge/src/main/java/vazkii/patchouli/neoforge/network/NeoForgeNetworkHandler.java`（**内部类**）：

```java
	public static void setupPackets(final RegisterPayloadHandlersEvent event) {
		final PayloadRegistrar registrar = event.registrar(PatchouliAPI.MOD_ID);
		registrar.playToClient(MessageOpenBookGui.TYPE, MessageOpenBookGui.CODEC, NeoForgeClientPayloadHandler.getInstance()::handleData);
		registrar.playToClient(MessageReloadBookContents.TYPE, MessageReloadBookContents.CODEC, NeoForgeClientPayloadHandler.getInstance()::handleData);
	}

	public static void sendOpenBook(ServerPlayer player, ResourceLocation book, @Nullable ResourceLocation entry, int page) {
		player.connection.send(new MessageOpenBookGui(book, entry, page));
	}

	public static void sendReloadBookContents(MinecraftServer server) {
		PacketDistributor.sendToAllPlayers(new MessageReloadBookContents());
	}
```

结论：**打开书籍在服务端只是"发一条 playToClient 自定义载荷"**（`MessageOpenBookGui`，含 `book`、可空 `entry`、`page`），实际开屏发生在客户端；`openBookGUI(ResourceLocation)` 这个客户端重载在**专用服务端会直接抛异常**（`assertPhysicalClient()`）。

### 3.6 「registerBook 做了什么」——未能核实（方法不存在）

对 `moddev\src-ref\Patchouli` 全仓库 grep `registerBook|registerMultiblock`，命中结果只有：
- `StubPatchouliAPI.java:151`、`PatchouliAPI.java:171`、`PatchouliAPIImpl.java:169`（均属 `registerMultiblock`）；
- `MultiblockRegistry.java:14`（`registerMultiblock` 定义）。

**1.21.1 版本的 Patchouli 中不存在 `registerBook` 方法**，也没有 `BookRegistry.registerBook` 之类的公开入口。书籍的"注册"方式是**数据驱动**的：`BookRegistry.init()`（由 `FMLCommonSetupEvent` 调用）扫描每个 mod 的 `data/<modid>/patchouli_books/<bookname>/book.json`：

```java
	public void init() {
		Collection<XplatModContainer> mods = IXplatAbstractions.INSTANCE.getAllMods();
		...
		// 对每个 mod 查找 data/<id>/patchouli_books 下深度 2 以内的 book.json
		// ResourceLocation bookId = ResourceLocation.fromNamespaceAndPath(id, bookName);
		...
		BookFolderLoader.findBooks();
		IXplatAbstractions.INSTANCE.signalBooksLoaded();
	}

	public void loadBook(XplatModContainer mod, ResourceLocation res, InputStream stream, boolean external) {
		Reader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8));
		var tree = GSON.fromJson(reader, JsonObject.class);
		books.put(res, new Book(tree, mod, res, external));
	}
```

因此附属模组"注册书籍"= 在资源目录放 `book.json`（以及可选的 `BookFolderLoader` 外部目录），而不是调用 Java API。

---

## 4. `Xplat/src/main/java/vazkii/patchouli/api/PatchouliConfigAccess.java`

**重要澄清：该类型不是 `record`，而是一个普通 `interface`；文件中没有任何嵌套 `record`/`class`，唯一的嵌套类型是 `enum TextOverflowMode`。** 文件全文（25 行）如下：

```java
package vazkii.patchouli.api;

import java.util.List;

public interface PatchouliConfigAccess {
	boolean disableAdvancementLocking();

	List<String> noAdvancementBooks();

	boolean testingMode();

	String inventoryButtonBook();

	boolean useShiftForQuickLookup();

	TextOverflowMode overflowMode();

	int quickLookupTime();

	enum TextOverflowMode {
		OVERFLOW,
		TRUNCATE,
		RESIZE
	}
}
```

即：7 个抽象方法 + 1 个嵌套枚举（3 个常量，无字段）。它是**只读视图**，`PatchouliAPI.get().getConfig()` 返回它。

### 4.1 两个已知实现（字段清单）

**(a) NeoForge 实现**：`NeoForge/src/main/java/vazkii/patchouli/neoforge/common/NeoForgePatchouliConfig.java`（**内部类，非 API**）。它不是 `record`，而是持有一组 `public static final ModConfigSpec.ConfigValue<...>` 字段，并在 `setup(ModContainer)` 时用一个匿名 `PatchouliConfigAccess` 把它们暴露出去：

```java
public class NeoForgePatchouliConfig {
	public static final ModConfigSpec.ConfigValue<Boolean> disableAdvancementLocking;
	public static final ModConfigSpec.ConfigValue<List<? extends String>> noAdvancementBooks;
	public static final ModConfigSpec.ConfigValue<Boolean> testingMode;
	public static final ModConfigSpec.ConfigValue<String> inventoryButtonBook;
	public static final ModConfigSpec.ConfigValue<Boolean> useShiftForQuickLookup;
	public static final ModConfigSpec.EnumValue<PatchouliConfigAccess.TextOverflowMode> overflowMode;
	public static final ModConfigSpec.ConfigValue<Integer> quickLookupTime;

	private static final ModConfigSpec SPEC;

	public static void setup(ModContainer container);   // container.registerConfig(ModConfig.Type.CLIENT, SPEC) + PatchouliConfig.set(匿名实现)
}
```

对应的配置键、默认值与注释（`ModConfig.Type.CLIENT`，即**纯客户端配置**）：

| 字段 | 配置键 | 默认值 | 注释摘要（源码原文要点） |
| --- | --- | --- | --- |
| `disableAdvancementLocking` | `disableAdvancementLocking` | `false` | 关闭所有书籍的进度锁定；Config Flag: `advancements_disabled` |
| `noAdvancementBooks` | `noAdvancementBooks` | 空列表 | 逐书关闭进度锁定，如 `[ "botania:lexicon" ]`；Config Flags: `advancements_disabled_<bookid>`；元素必须能被 `ResourceLocation.tryParse` 解析 |
| `testingMode` | `testingMode` | `false` | 默认不做任何事，仅供书籍内 config flag 使用；Config Flag: `testing_mode` |
| `inventoryButtonBook` | `inventoryButtonBook` | `""` | 指定某本书出现在玩家物品栏位置（替换配方书） |
| `useShiftForQuickLookup` | `useShiftForQuickLookup` | `false` | 用 Shift 取代 Ctrl 触发物品栏快速查阅 |
| `overflowMode` | `textOverflowMode`（注意键名与字段名不同） | `PatchouliConfigAccess.TextOverflowMode.RESIZE` | 文本溢出处理：溢出/截断/缩放；提示"修改后需重登" |
| `quickLookupTime` | `quickLookupTime` | `10` | 快速查阅键需要按住的 tick 数 |

**(b) Stub 实现**：`StubPatchouliAPI#getConfig()` 返回的匿名实现（返回值见第 2 节）。

### 4.2 内部配置持有者（供理解 `getConfigFlag` 语义）

`Xplat/src/main/java/vazkii/patchouli/common/base/PatchouliConfig.java`（**内部类**）关键成员：

```java
	private static final Map<String, Boolean> CONFIG_FLAGS = new ConcurrentHashMap<>();
	private static PatchouliConfigAccess access = null;

	public static PatchouliConfigAccess get();
	public static void set(PatchouliConfigAccess a);   // 重复 set 抛 IllegalStateException("ConfigAccess already set")
	public static void reloadBuiltinFlags();           // 写入 mod:<id>=true、debug、advancements_disabled*、testing_mode
	public static boolean getConfigFlag(String name);  // 支持 "!" 取反、"&"/"|" 组合
	public static boolean getConfigFlagAND(String[] tokens);
	public static boolean getConfigFlagOR(String[] tokens);
	public static void setFlag(String flag, boolean value);
```

`setConfigFlag(String, boolean)` 的 javadoc 要求 flag 必须带自己的 mod id 前缀（无强制校验，但 `mod:` 前缀的未知名不会打 warn 日志）。

---

## 5. `NeoForge/src/main/java/vazkii/patchouli/api/BookContentsReloadEvent.java`

文件全文（16 行）：

```java
package vazkii.patchouli.api;

import net.minecraft.resources.ResourceLocation;
import net.neoforged.bus.api.Event;

public class BookContentsReloadEvent extends Event {
	private final ResourceLocation book;

	public BookContentsReloadEvent(ResourceLocation book) {
		this.book = book;
	}

	public ResourceLocation getBook() {
		return book;
	}
}
```

- 位于 `vazkii.patchouli.api` 包（**NeoForge 模块的源集**），继承 NeoForge 的 `net.neoforged.bus.api.Event`，属于**稳定公开 API**。
- 只有 1 个字段 `book` 和 1 个 getter；**javadoc 中没有侧别说明**（源码确实没有注释）。
- **触发位置（grep 结果）**：全仓库唯一 `post` 点：

```java
// NeoForge/src/main/java/vazkii/patchouli/neoforge/xplat/NeoForgeXplatImpl.java:34-36
	@Override
	public void fireBookReload(ResourceLocation book) {
		NeoForge.EVENT_BUS.post(new BookContentsReloadEvent(book));
	}
```

- **重要发现：在 release-1.21.1-93 中，找不到任何调用 `IXplatAbstractions#fireBookReload(...)` 的代码。** 对 `fireBookReload` 做全仓库 grep，只命中 3 处：接口声明（`IXplatAbstractions.java:24`）、NeoForge 实现（`NeoForgeXplatImpl.java:34`）、Fabric 实现（`FabricXplatImpl.java:33`）。因此该事件**事实上永远不会被 post**（NeoForge 侧的 `BookContentsReloadEvent` 与 Fabric 侧的 `BookContentsReloadCallback` 都一样）。
  相关内容重载走的是另一条路：`ServerStartedEvent` → `ReloadContentsHandler.dataReloaded(MinecraftServer)` → `sendReloadContentsMessage(server)` → 广播 `MessageReloadBookContents` 数据包，由客户端处理（`NeoForgeClientPayloadHandler`）——**不发事件**。
  （`ReloadContentsHandler` 全文字段/方法：`public static void dataReloaded(MinecraftServer server)`，内部只做 `LOGGER.info("Sending reload packet to clients")` 与 `IXplatAbstractions.INSTANCE.sendReloadContentsMessage(server)`。）
- **侧别判断**：事件类本身不含客户端类型，理论上是"双端可用"的通用事件；但因为只在客户端书籍内容重载语境下才有意义，而当前又无触发点，**它既不是可靠的客户端钩子，也不是服务端钩子**——不要依赖它。
- **监听注册方式（同第 6 节）**：通过 `NeoForge.EVENT_BUS`（game bus）post，所以监听必须注册在 **game bus** 上：`NeoForge.EVENT_BUS.addListener(e -> ...)`，或用 `@EventBusSubscriber(modid = "patchouli", bus = EventBusSubscriber.Bus.GAME)`（`Bus.GAME` 是默认值）。注册到 mod 事件总线（`IEventBus` 构造器参数）**不会**收到此事件。

### 5.1 Fabric 侧对应物（仅作对照）

`Fabric/src/main/java/vazkii/patchouli/fabric/xplat/FabricXplatImpl.java`：

```java
	@Override
	public void fireDrawBookScreen(ResourceLocation book, Screen gui, int mouseX, int mouseY, float partialTicks, GuiGraphics graphics) {
		BookDrawScreenCallback.EVENT.invoker().trigger(book, gui, mouseX, mouseY, partialTicks, graphics);
	}

	@Override
	public void fireBookReload(ResourceLocation book) {
		BookContentsReloadCallback.EVENT.invoker().trigger(book);
	}
```

即两个平台各有一套事件：NeoForge 用 `Event` 子类 + `NeoForge.EVENT_BUS.post`，Fabric 用 callback 接口（`BookDrawScreenCallback` / `BookContentsReloadCallback`）。附属模组代码若需跨加载器，必须分别处理。

---

## 6. `NeoForge/src/main/java/vazkii/patchouli/api/BookDrawScreenEvent.java`

文件全文（55 行）：

```java
package vazkii.patchouli.api;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.resources.ResourceLocation;
import net.neoforged.bus.api.Event;

/**
 * This event is fired after any
 * book gui draws the content of a book with
 * the book gui scale still applied to the transformation state. This is useful if additional
 * custom components should be drawn independently of what page a book
 * is currently on.
 */
public class BookDrawScreenEvent extends Event {
	private final ResourceLocation book;
	private final Screen screen;
	private final int mouseX;
	private final int mouseY;
	private final float partialTicks;
	private final GuiGraphics graphics;

	public BookDrawScreenEvent(ResourceLocation book, Screen screen, int mouseX, int mouseY, float partialTicks, GuiGraphics graphics);

	public ResourceLocation getBook();
	public Screen getScreen();
	public int getMouseX();
	public int getMouseY();
	public float getPartialTicks();
	public GuiGraphics getGraphics();
}
```

（构造器与 6 个 getter 均在源码中逐字如上；6 个字段均为 `private final`。）

- 位于 `vazkii.patchouli.api` 包（NeoForge 源集）→ **稳定公开 API**。
- **这是纯客户端事件**：所有成员都引用客户端类型（`GuiGraphics`、`Screen`），在专用服务器上不可能被触发（若监听器类在专用服务器上被类加载并含这些类型，会因缺少客户端类而崩溃，因此监听类**必须**用 `Dist.CLIENT` 限定）。
- **触发位置（grep 结果）**：全仓库唯一的 `post` 点在 `NeoForgeXplatImpl`，唯一的上游调用点在 `GuiBook`：

```java
// NeoForge/src/main/java/vazkii/patchouli/neoforge/xplat/NeoForgeXplatImpl.java:28-31
	@Override
	public void fireDrawBookScreen(ResourceLocation book, Screen gui, int mouseX, int mouseY, float partialTicks, GuiGraphics graphics) {
		NeoForge.EVENT_BUS.post(new BookDrawScreenEvent(book, gui, mouseX, mouseY, partialTicks, graphics));
	}
```

```java
// Xplat/src/main/java/vazkii/patchouli/client/book/gui/GuiBook.java:135-150
	private void drawScreenAfterScale(GuiGraphics graphics, int mouseX, int mouseY, float partialTicks) {
		resetTooltip();

		graphics.pose().pushPose();
		graphics.pose().translate(bookLeft, bookTop, 0);
		graphics.setColor(1F, 1F, 1F, 1F);
		drawBackgroundElements(graphics, mouseX, mouseY, partialTicks);
		drawForegroundElements(graphics, mouseX, mouseY, partialTicks);
		graphics.pose().popPose();

		super.render(graphics, mouseX, mouseY, partialTicks);

		IXplatAbstractions.INSTANCE.fireDrawBookScreen(this.book.id, this, mouseX, mouseY, partialTicks, graphics);   // ← 第 147 行

		drawTooltip(graphics, mouseX, mouseY);
	}
```

即：**每帧渲染书籍 GUI 时触发一次**，位置在 `drawScreenAfterScale` 内（`pushPose`/`translate` 已 `popPose` 之后、`drawTooltip` 之前），`mouseX/mouseY` 是**已经按 `scaleFactor` 整除过的 GUI 缩放坐标**（见 `render(...)` 中的 `mouseX /= scaleFactor`）。

- 与 javadoc 的关系：javadoc 说"book gui scale 仍作用于变换状态时触发"，与源码中 `render()` 里 `graphics.pose().scale(scaleFactor, ...)` 尚未 `popPose()`（`drawScreenAfterScale` 在其中被调用）一致——**事件回调期间，PoseStack 上仍带有 scaleFactor 缩放**，而 `bookLeft/bookTop` 的平移已被弹出。
- **监听注册方式**：`NeoForge.EVENT_BUS`（game bus）post，因此：

```java
// 方式一：game bus 监听
NeoForge.EVENT_BUS.addListener((BookDrawScreenEvent e) -> { ... });

// 方式二：注解订阅（GAME 总线 + 仅客户端）
@EventBusSubscriber(modid = "your_modid", bus = EventBusSubscriber.Bus.GAME, value = Dist.CLIENT)
public class MyBookOverlayHandler {
	@SubscribeEvent
	public static void onDraw(BookDrawScreenEvent e) { ... }
}
```

- **注意事项**：
  1. 一定要用 `Dist.CLIENT`（`@EventBusSubscriber` 的 `value = Dist.CLIENT`），否则专用服务器加载时因客户端类缺失而崩溃；
  2. 事件**每帧**触发，回调内不要做重活；绘制请使用 `e.getGraphics()`，不要自行 `Minecraft.getInstance().renderBuffers()`；
  3. 该事件**不携带页面信息**（只有 book、screen、鼠标坐标、partialTicks、graphics），若需按页渲染需自行读取 `screen`（可 cast 到 `vazkii.patchouli.client.book.gui.GuiBook`——但那是**内部类**，属于不稳定依赖）；
  4. 事件没有 `@Cancelable`，无法取消。

---

## 7. NeoForge 初始化器

### 7.1 `NeoForge/src/main/java/vazkii/patchouli/neoforge/common/NeoForgeModInitializer.java`

类声明（两处注解都很关键）：

```java
@EventBusSubscriber(modid = PatchouliAPI.MOD_ID, bus = EventBusSubscriber.Bus.MOD)
@Mod(PatchouliAPI.MOD_ID)
public class NeoForgeModInitializer {
	public NeoForgeModInitializer(IEventBus eventBus, Dist dist, ModContainer container);

	@SubscribeEvent public static void register(RegisterEvent evt);
	@SubscribeEvent public static void processCreativeTabs(BuildCreativeModeTabContentsEvent evt);
	@SubscribeEvent public static void onInitialize(FMLCommonSetupEvent evt);
}
```

各阶段行为（逐条对应源码）：

| 阶段 | 位置 | 做什么 |
| --- | --- | --- |
| **mod 构造期** | 构造器 `NeoForgeModInitializer(IEventBus eventBus, Dist dist, ModContainer container)` | `NeoForgePatchouliConfig.setup(container)`（注册 **CLIENT** 类型配置并 `PatchouliConfig.set(...)`）；`eventBus.addListener(NeoForgeNetworkHandler::setupPackets)` |
| **注册期** | `@SubscribeEvent static void register(RegisterEvent evt)` | **没有使用 `DeferredRegister`**，而是在 `RegisterEvent` 里直接按注册表注册：<br>`evt.register(Registries.SOUND_EVENT, rh -> PatchouliSounds.submitRegistrations(rh::register))`<br>`evt.register(Registries.DATA_COMPONENT_TYPE, rh -> PatchouliDataComponents.submitDataComponentRegistrations(rh::register))`<br>`evt.register(Registries.ITEM, rh -> PatchouliItems.submitItemRegistrations(rh::register))`<br>`evt.register(Registries.TRIGGER_TYPE, rh -> PatchouliCriteriaTriggers.submitTriggerRegistrations(rh::register))` |
| **创造模式标签页** | `processCreativeTabs(BuildCreativeModeTabContentsEvent evt)` | 遍历 `BookRegistry.INSTANCE.books.values()`，对 `!b.noBook` 的书生成 `ItemModBook.forBook(b)`；`CreativeModeTabs.SEARCH` 标签下用 `SEARCH_TAB_ONLY` 添加（去重检查 `getSearchEntries().contains(book)`）；否则若 `b.creativeTab != null` 且 `evt.getTab() == CreativeModeTabRegistry.getTab(b.creativeTab)` 则正常添加。**即书籍入创造栏依赖书籍已加载** |
| **CommonSetup** | `onInitialize(FMLCommonSetupEvent evt)` | 在 **game bus** 上注册 `RegisterCommandsEvent` → `OpenBookCommand.register(dispatcher)`；注册 `PlayerInteractEvent.RightClickBlock` → `LecternEventHandler.rightClick(...)`（若 `result.consumesAction()` 则 `setCanceled(true)` + `setCancellationResult(result)`）；调用 **`BookRegistry.INSTANCE.init()`**（扫描并加载所有 `patchouli_books`，末尾 `signalBooksLoaded()`）；注册 `ServerStartedEvent` → `ReloadContentsHandler.dataReloaded(server)` |

网络注册细节：`setupPackets(RegisterPayloadHandlersEvent)` 是 **MOD bus** 事件，用 `event.registrar(PatchouliAPI.MOD_ID)`（协议版本即 mod id 字面量 `"patchouli"`），注册两个 `playToClient` 载荷（见 3.5）。

### 7.2 `NeoForge/src/main/java/vazkii/patchouli/neoforge/client/NeoForgeClientInitializer.java`

```java
@EventBusSubscriber(modid = PatchouliAPI.MOD_ID, bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public class NeoForgeClientInitializer {
	/**
	 * Why are these necessary?
	 * BookRegistry.init is called from CommonSetupEvent. We need the models to be known in ModelRegistryEvent.
	 * However, there is no defined ordering for those events. They all run concurrently during the initial resource
	 * reload.
	 * We need a way of waiting for the books to become known.
	 * Another critical point to note is that loading runs on a fixed-size ForkJoinPool.
	 * Blocking the thread can starve loading completely.
	 * Fortunately, the implementation of Condition.await for ReentrantLock uses ForkJoinPool.managedBlock,
	 * which is aware of potentially blocking operations and can resize the pool accordingly.
	 * If parallel mod loading didn't exist we wouldn't need any of this, but here we are :))))
	 */
	private static final Lock BOOK_LOAD_LOCK = new ReentrantLock();
	private static final Condition BOOK_LOAD_CONDITION = BOOK_LOAD_LOCK.newCondition();
	private static boolean booksLoaded = false;

	public static void signalBooksLoaded();

	private static List<ResourceLocation> getBookModels();

	@SubscribeEvent public static void modelRegistry(ModelEvent.RegisterAdditional e);
	@SubscribeEvent public static void registerReloadListeners(RegisterClientReloadListenersEvent e);
	@SubscribeEvent public static void registerOverlays(RegisterGuiLayersEvent evt);
	@SubscribeEvent public static void onInitializeClient(FMLClientSetupEvent evt);
	@SubscribeEvent public static void replaceBookModel(ModelEvent.ModifyBakingResult evt);
}
```

行为要点：

| 方法 | 阶段 | 做什么 |
| --- | --- | --- |
| `signalBooksLoaded()` | 由 `IXplatAbstractions.signalBooksLoaded()`（→ `NeoForgeXplatImpl.signalBooksLoaded()`，仅物理客户端）调用，实际来自 `BookRegistry.init()` 末尾 | 加锁置 `booksLoaded = true` 并 `signalAll()` |
| `getBookModels()` | 内部 | 阻塞等待 `booksLoaded`（`Condition.awaitUninterruptibly()`），然后返回 `BookRegistry.INSTANCE.books.values().stream().map(b -> b.model).toList()` |
| `modelRegistry(ModelEvent.RegisterAdditional e)` | MOD bus，客户端 | 把每本书的 `b.model` 以 `ModelResourceLocation::standalone` 注册为附加模型；并注册物品属性 `patchouli:completion`（`ItemPropertyFunction` → `ItemModBook.getCompletion(stack)`）到 `PatchouliItems.BOOK` |
| `registerReloadListeners(RegisterClientReloadListenersEvent e)` | MOD bus，客户端 | 注册 `BookContentResourceListenerLoader.INSTANCE`；另注册一个 `ResourceManagerReloadListener`：仅当 `Minecraft.getInstance().level != null` 时 `ClientBookRegistry.INSTANCE.reload()`（否则打 debug 日志 "Not reloading resource pack-based books as client world is missing"） |
| `registerOverlays(RegisterGuiLayersEvent evt)` | MOD bus，客户端 | `registerAbove(VanillaGuiLayers.CROSSHAIR, patchouli:book_overlay, BookRightClickHandler::onRenderHUD)`；`registerBelow(VanillaGuiLayers.BOSS_OVERLAY, patchouli:multiblock_progress, MultiblockVisualizationHandler::onRenderHUD)` |
| `onInitializeClient(FMLClientSetupEvent evt)` | MOD bus，客户端 | **`ClientBookRegistry.INSTANCE.init()`**（注册 page 类型，见下）；`PersistentData.setup()`；在 game bus 上注册 `ClientTickEvent.Post` → `ClientTicker.endClientTick`；`PlayerInteractEvent.RightClickBlock` → `BookRightClickHandler.onRightClick(...)`；另一个 `RightClickBlock` → `MultiblockVisualizationHandler.onPlayerInteract(...)`；`ClientTickEvent.Post` → `MultiblockVisualizationHandler.onClientTick`；`RenderFrameEvent.Pre` → `ClientTicker.renderTickStart(e.getPartialTick().getGameTimeDeltaPartialTick(false))`；`RenderFrameEvent.Post` → `ClientTicker.renderTickEnd()`；`ClientPlayerNetworkEvent.LoggingOut` → `ClientAdvancements.playerLogout()`；`RenderTooltipEvent.Pre` → `TooltipHandler.onTooltip(...)` |
| `replaceBookModel(ModelEvent.ModifyBakingResult evt)` | MOD bus，客户端 | 把 `ModelResourceLocation.inventory(PatchouliItems.BOOK_ID)` 对应的烘焙模型替换成 `new BookModel(oldModel, model -> Minecraft.getInstance().getModelManager().getModel(ModelResourceLocation.standalone(model)))` |

### 7.3 对附属模组的启示：何时能安全注册自己的 page 类型

事实基础（全部来自源码）：

1. **Patchouli 没有任何 `registerPageType(...)` API**。全仓库 grep `registerPageType|PageRegistry|BookPageRegistry|PageType` 只命中 `ClientBookRegistry.java:40/43`（`init()` 与其内部的 `private void addPageTypes()`）。
2. page 类型的存放处是 **`ClientBookRegistry` 的实例字段**，且是 `public`：

```java
// Xplat/src/main/java/vazkii/patchouli/client/book/ClientBookRegistry.java
public class ClientBookRegistry {
	public final Map<ResourceLocation, Class<? extends BookPage>> pageTypes = new HashMap<>();
	public final Gson gson = new GsonBuilder()
			.registerTypeHierarchyAdapter(BookPage.class, new LexiconPageAdapter())
			.registerTypeHierarchyAdapter(TemplateComponent.class, new TemplateComponentAdapter())
			.create();
	public String currentLang;

	public static final ClientBookRegistry INSTANCE = new ClientBookRegistry();

	private ClientBookRegistry() {}

	public void init() {          // ← 在 FMLClientSetupEvent 中调用
		addPageTypes();
	}

	private void addPageTypes() { // ← private，只注册 patchouli 自带 16 种类型
		pageTypes.put(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "text"), PageText.class);
		pageTypes.put(... "crafting" → PageCrafting.class);
		pageTypes.put(... "smelting" → PageSmelting.class);
		pageTypes.put(... "blasting" → PageBlasting.class);
		pageTypes.put(... "smoking" → PageSmoking.class);
		pageTypes.put(... "campfire" → PageCampfireCooking.class);
		pageTypes.put(... "smithing" → PageSmithing.class);
		pageTypes.put(... "stonecutting" → PageStonecutting.class);
		pageTypes.put(... "image" → PageImage.class);
		pageTypes.put(... "spotlight" → PageSpotlight.class);
		pageTypes.put(... "empty" → PageEmpty.class);
		pageTypes.put(... "multiblock" → PageMultiblock.class);
		pageTypes.put(... "link" → PageLink.class);
		pageTypes.put(... "relations" → PageRelations.class);
		pageTypes.put(... "entity" → PageEntity.class);
		pageTypes.put(... "quest" → PageQuest.class);
	}

	public void reload();
	public void reloadLocks(boolean suppressToasts);
	/**
	 * @param entryId Entry to force to the top of the stack
	 * @param page    Zero-indexed page in the entry to force. Ignored if {@code entryId} is null.
	 */
	public void displayBookGui(ResourceLocation bookStr, @Nullable ResourceLocation entryId, int page);
	// 另有 2 个内部类：LexiconPageAdapter implements JsonDeserializer<BookPage>、TemplateComponentAdapter（见文件 97 行起）
}
```

3. `pageTypes` 的消费点在 `LexiconPageAdapter.deserialize(...)`：JSON 里 `"type"` 若不含 `:` 会前缀 `patchouli:`；查不到类型时**回退为 `PageTemplate.class`**：

```java
			ResourceLocation type = ResourceLocation.tryParse(string);
			Class<? extends BookPage> clazz = ClientBookRegistry.INSTANCE.pageTypes.get(type);
			if (clazz == null) {
				clazz = PageTemplate.class;
			}
```

由此得到的结论（供附属模组决策）：

- **`ClientBookRegistry`、`BookPage` 全部是内部实现类**（包 `vazkii.patchouli.client.book`），不在 `api` 包内，不存在兼容性承诺；`pageTypes` 虽然 `public`，但依赖它等于依赖内部实现。
- 如果非要注册自定义 page 类型，**唯一可行时机是 `FMLClientSetupEvent` 之后（严格说是 client 侧 `ClientBookRegistry.INSTANCE.init()` 执行之后），且必须在书籍内容被反序列化之前**；由于 `addPageTypes()` 只是 `put` 而不清空 map，在之后 `put` 自定义类型在实践上可行，但**监听器顺序无保证**（Patchouli 自己的 `onInitializeClient` 也是普通 `FMLClientSetupEvent` 监听器，同一事件内先注册者先执行，存在竞态风险）。相对安全的做法是：在自己的客户端初始化后、`Minecraft` 尚在标题界面时写入 `ClientBookRegistry.INSTANCE.pageTypes`，或使用 `enqueueWork`。
- **官方推荐的扩展路径是模板系统**：使用 `patchouli:template` 类型（`PageTemplate`）+ `registerTemplateAsBuiltin(ResourceLocation, Supplier<InputStream>)`（仅客户端、仅**内建**模板且不能与已有 id 冲突），配合 `IComponentProcessor`/`ICustomComponent`/`IComponentRenderContext`（这些**都在 `api` 包内**，属于稳定公开 API）。
- 其他安全时机清单（基于第 7.1/7.2 的实际阶段）：
  - **物品栏/创造栏**：`RegisterEvent`（注册物品、数据组件、音效、criterion）与 `BuildCreativeModeTabContentsEvent`（书籍入栏）在 `FMLCommonSetupEvent` 之前或之中执行，而 **`BookRegistry.INSTANCE.init()` 在 `FMLCommonSetupEvent` 中**，所以想把书放进创造栏，书籍的 `book.json` 必须作为**数据/资源文件**存在（扫描发生在 setup 时）。
  - **`PatchouliAPI.get().getConfig()`** 在 `NeoForgePatchouliConfig.setup(container)` 之后才非 null（构造期完成），且 `PatchouliConfig.set` 只允许一次。
  - **`registerMultiblock`/`makeMultiblock`** 是纯运行期内存注册，可在 `FMLCommonSetupEvent` 之后任意时刻调用（线程安全）；但多方块可视化相关 API（`showMultiblock`、`getCurrentMultiblock`、`clearMultiblock`）仅客户端。
  - **`registerCommand`/`registerFunction`（文本解析器）** 仅客户端，需在书籍渲染前注册；`registerTemplateAsBuiltin` 仅客户端。
  - **`openBookGUI(ServerPlayer, ...)`** 可服务端调用（发数据包）；无 `ServerPlayer` 的重载只能客户端调用。

---

## 8. `Xplat` 跨加载器抽象（内部 SPI，**不是给第三方模组用的**）

以下三个类型都位于 **`vazkii.patchouli.xplat`**，**不在 `vazkii.patchouli.api` 包内**，也没有任何 javadoc 承诺：

- `IXplatAbstractions` 的注释仅为 `/** Cross-modloader abstracted calls */`；
- `XplatModContainer` 的注释仅为 `/** Small cross-loader abstraction over mod containers */`；
- `IClientXplatAbstractions` 无类级 javadoc，只有一行内部注释 `// NB: Fluids handled at callsite in platform-independent manner`。

**它们不是公开 API，第三方不应调用。** 理由：包名在 `api` 之外；实现由 `META-INF/services` 的 `ServiceLoader` 注入（`NeoForge/src/main/resources/META-INF/services/vazkii.patchouli.xplat.IXplatAbstractions` → `vazkii.patchouli.neoforge.xplat.NeoForgeXplatImpl`；`...IClientXplatAbstractions` → `vazkii.patchouli.neoforge.client.NeoForgeClientXplatImpl`；Fabric 模块各有一份），且接口内的 `INSTANCE = find()` 在**类路径上存在不等于 1 个实现时会直接抛异常**，第三方复制/实现它们会破坏 Patchouli 自身。

### 8.1 `Xplat/src/main/java/vazkii/patchouli/xplat/IXplatAbstractions.java`

```java
/**
 * Cross-modloader abstracted calls
 */
public interface IXplatAbstractions {
	// Events
	void fireDrawBookScreen(ResourceLocation book, Screen gui, int mouseX, int mouseY, float partialTicks, GuiGraphics graphics);
	void fireBookReload(ResourceLocation book);

	// Networking
	void sendReloadContentsMessage(MinecraftServer server);
	void sendOpenBookGui(ServerPlayer player, ResourceLocation book, @Nullable ResourceLocation entry, int page);

	// FML/FabricLoader-related
	Collection<XplatModContainer> getAllMods();
	XplatModContainer getModContainer(String modId);
	boolean isModLoaded(String modId);
	boolean isDevEnvironment();

	// Misc
	boolean isPhysicalClient();

	// Needed because of Forge
	default void signalBooksLoaded() {}

	// JEI/REI compat
	boolean handleRecipeKeybind(int keyCode, int scanCode, ItemStack stack);

	IXplatAbstractions INSTANCE = find();   // 接口常量，隐式 public static final

	private static IXplatAbstractions find() { /* ServiceLoader 查找，要求恰好 1 个实现，否则 IllegalStateException */ }
}
```

NeoForge 实现要点（`NeoForgeXplatImpl`，内部类）：
- `fireDrawBookScreen` → `NeoForge.EVENT_BUS.post(new BookDrawScreenEvent(...))`；
- `fireBookReload` → `NeoForge.EVENT_BUS.post(new BookContentsReloadEvent(book))`（**无调用者**）；
- `sendReloadContentsMessage` → `NeoForgeNetworkHandler.sendReloadBookContents(server)`（`PacketDistributor.sendToAllPlayers`）；
- `sendOpenBookGui` → `NeoForgeNetworkHandler.sendOpenBook(player, book, entry, page)`（`player.connection.send(...)`）；
- `getAllMods`/`getModContainer` → 基于 `ModList.get()` 包装成 `NeoForgeXplatModContainer`；
- `isModLoaded` → `ModList.get().isLoaded(modId)`；
- `isDevEnvironment` → `!FMLEnvironment.production`；
- `isPhysicalClient` → `FMLEnvironment.dist == Dist.CLIENT`；
- `signalBooksLoaded` → 仅物理客户端时调 `NeoForgeClientInitializer.signalBooksLoaded()`；
- `handleRecipeKeybind` → `return false`（NeoForge 侧未实现 JEI/REI 键位兼容）。

### 8.2 `Xplat/src/main/java/vazkii/patchouli/xplat/IClientXplatAbstractions.java`

```java
public interface IClientXplatAbstractions {
	// NB: Fluids handled at callsite in platform-independent manner
	void renderForMultiblock(BlockState state, BlockPos pos, BlockAndTintGetter multiblock, PoseStack ps, MultiBufferSource buffers, RandomSource rand);

	IClientXplatAbstractions INSTANCE = find();   // 隐式 public static final

	private static IClientXplatAbstractions find() { /* ServiceLoader，要求恰好 1 个实现 */ }
}
```

整个接口**只有 1 个方法**，纯客户端（含 `PoseStack`、`MultiBufferSource` 等客户端渲染类型）。

### 8.3 `Xplat/src/main/java/vazkii/patchouli/xplat/XplatModContainer.java`

```java
/**
 * Small cross-loader abstraction over mod containers
 */
public interface XplatModContainer {
	String getId();
	String getName();
	Path getPath(String s);
	List<Path> getRootPaths();
}
```

（4 个方法，均无默认实现；无 `@Nullable` 注解。）

### 8.4 稳定公开 API（`vazkii.patchouli.api`）完整清单（glob 结果）

`Xplat/src/main/java/vazkii/patchouli/api/` 下共 18 个文件（均为 `.java`，其中 `package-info.java` 为包声明文件）：

```
IComponentProcessor.java        IComponentRenderContext.java   ICustomComponent.java
IMultiblock.java                IStateMatcher.java             IStyleStack.java
IVariable.java                  IVariableProvider.java         IVariablesAvailableCallback.java
IVariableSerializer.java        PatchouliAPI.java              PatchouliConfigAccess.java
TriPredicate.java               VariableHelper.java            package-info.java
stub/StubMatcher.java  stub/StubMultiblock.java  stub/StubPatchouliAPI.java
```

（共 17 个公开类型声明 + `package-info.java`；`stub/` 下 3 个属于降级实现。）NeoForge 源集中额外贡献 2 个 `api` 包类型：`BookDrawScreenEvent`、`BookContentsReloadEvent`。

---

## 9. `NeoForge/src/main/resources/META-INF/neoforge.mods.toml`（全文 27 行，逐字抄录）

```toml
modLoader="javafml"
license="CC BY-NC-SA 3.0"
loaderVersion="[4,)"
issueTrackerURL="https://github.com/VazkiiMods/Patchouli"
logoFile="logo.png"

[[mods]]
modId="patchouli"
displayName="Patchouli"
version="${file.jarVersion}"
authors="Vazkii"
description='''
Accessible, Data-Driven, Dependency-Free Documentation for Minecraft Modders and Pack Makers
'''

[[dependencies.patchouli]]
modId="neoforge"
type="REQUIRED"
versionRange="[21.0.31-beta,)"

[[dependencies.patchouli]]
modId="minecraft"
type="REQUIRED"
versionRange="[1.21.1,1.21.2)"

[[mixins]]
config="patchouli_xplat.mixins.json"
```

要点：
- **mod id = `patchouli`**，`displayName = "Patchouli"`，`authors = "Vazkii"`；
- **version = `${file.jarVersion}`**（由构建时替换，源码树中**未能核实**具体版本号字符串；仓库 tag 为 `release-1.21.1-93`，对应 jar 版本按 Patchouli 惯例为 `1.21.1-93`，但本文件本身不含该数字）；
- `license = "CC BY-NC-SA 3.0"`；`modLoader = "javafml"`，`loaderVersion = "[4,)"`；
- **依赖声明只有 2 条，均为 `REQUIRED`**：`neoforge` 要求 `[21.0.31-beta,)`，`minecraft` 要求 `[1.21.1,1.21.2)`。**没有对任何其他 mod 的依赖**（也没有 `side` 字段）；
- **mixins 配置只列了一个文件**：`config="patchouli_xplat.mixins.json"`（不在本文件中声明 `patchouli_fabric.mixins.json`，那属于 Fabric 模块）。

`Xplat/src/main/resources/patchouli_xplat.mixins.json`（全文 24 行，供交叉核对）：

```json
{
  "required": true,
  "minVersion": "0.8.4",
  "package": "vazkii.patchouli.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": [
    "AccessorSmithingTransformRecipe",
    "AccessorSmithingTrimRecipe"
  ],
  "client": [
    "client.AccessorClientAdvancements",
    "client.AccessorKeyMapping",
    "client.AccessorMultiBufferSource",
    "client.AccessorScreen",
    "client.MixinClientAdvancements",
    "client.MixinInventoryScreen",
    "client.MixinLevelRenderer",
    "client.MixinSystemReport"
  ],
  "injectors": {
    "defaultRequire": 1
  },
  "refmap": "patchouli.refmap.json"
}
```

注意：`refmap` 声明为 `patchouli.refmap.json`，`package` 为 `vazkii.patchouli.mixin`（**内部包，属于不稳定实现**）。

---

## 10. 核实记录与未能核实项

核实过（工具：read / grep / glob / pwsh）：

- 所有第 1–9 节列举的文件均已用 `read` 逐行阅读，签名逐字抄录；
- 版本：`git -C <repo> describe --tags` → `release-1.21.1-93`；`git log -1 --oneline` → `0c2fdff Use registry access for book icons (#843)`；
- 事件触发点：grep `fireDrawBookScreen|BookDrawScreenEvent|fireBookReload|BookContentsReloadEvent` 覆盖整个 `src-ref\Patchouli` 树（15 处命中，全部列出）；
- `@Mod(` grep 全仓库仅 1 处；
- `registerBook|registerMultiblock` grep 全仓库仅 5 处命中，确认无 `registerBook`；
- `registerPageType|PageRegistry|PageType|BookPageRegistry` grep 全仓库仅 2 处命中（`ClientBookRegistry`），确认无公开 page 类型注册 API。

未能核实 / 存在偏差的地方（如实标注）：

1. **`PatchouliAPI` 类上没有 `@Mod` 注解**——任务描述中"该类的 `@Mod` 注解值"这一前提与源码不符。实际 `@Mod` 出现在 `NeoForgeModInitializer` 上，值为 `PatchouliAPI.MOD_ID`（即字符串 `"patchouli"`）。已检查位置：`PatchouliAPI.java` 全文（281 行）、全仓库 grep `@Mod\(`。
2. **`PatchouliConfigAccess` 不是 `record`**——它是一个 `interface`（25 行），没有嵌套 record/class，只有嵌套 `enum TextOverflowMode`。任务描述中"所有嵌套 record/class 的字段"无对应实体。已检查位置：`PatchouliConfigAccess.java` 全文；glob `**/PatchouliConfigAccess.java` 全仓库唯一命中；其两个实现（`NeoForgePatchouliConfig` 匿名类、`StubPatchouliAPI#getConfig` 匿名类）字段已列出。
3. **`registerBook` 在本版本不存在**——无法描述其"做了什么"。已检查位置：全仓库 grep `registerBook|registerMultiblock`。
4. **`BookContentsReloadEvent` 在 release-1.21.1-93 中没有任何触发点**——只有 `NeoForgeXplatImpl.fireBookReload` 里的一处 `post`，而 `fireBookReload` 无调用者。已检查位置：全仓库 grep `fireBookReload`、`BookContentsReloadEvent`、`ReloadContentsHandler.java` 全文。
5. **`neoforge.mods.toml` 中的 `version` 是占位符 `${file.jarVersion}`**，源码树中无法读出具版本号。已检查位置：该文件全文。
6. 本文未逐条抄录 `IMultiblock`、`IStateMatcher`、`IStyleStack`、`IComponentProcessor` 等其余 `api` 包接口的方法签名（任务未要求）；如需，可另外补充。

---

## 附：给附属模组（例如 TFC 集成）的可操作结论

1. **书籍不通过 Java 注册**：在 `data/<你的modid>/patchouli_books/<bookname>/book.json` 放文件即可，`BookRegistry.init()` 在 `FMLCommonSetupEvent` 阶段扫描 `data/<modid>/patchouli_books`（深度 2），`book.json` 必须在正该层级。
2. **给物品/命令用的书**：`PatchouliAPI.get().getBookStack(ResourceLocation)` 返回 `patchouli:guide_book` 且书籍 id 存于数据组件 `PatchouliDataComponents.BOOK`；服务端打开用 `openBookGUI(ServerPlayer, ResourceLocation)`。
3. **自定义渲染/覆盖层**：监听 `BookDrawScreenEvent`，务必 `Dist.CLIENT`；注意每帧触发且事件回调时 PoseStack 仍带 `scaleFactor`。
4. **不要监听 `BookContentsReloadEvent`**（本版本不会触发）；内容重载依赖 `MessageReloadBookContents` 客户端处理。
5. **自定义 page 类型属于高风险内部依赖**；优先走模板系统（`patchouli:template` + `registerTemplateAsBuiltin` + `api` 包内的 `ICustomComponent`/`IComponentProcessor`）。
6. **不要引用** `vazkii.patchouli.xplat.*`、`vazkii.patchouli.common.*`、`vazkii.patchouli.client.*`、`vazkii.patchouli.mixin.*` 中的任何类型。
