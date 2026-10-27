# Patchouli API 接口逐条抄录与实现方分析（tag `release-1.21.1-93`）

## 0. 核实信息

| 项目 | 核实结果 | 核实方式 |
| --- | --- | --- |
| 仓库根 | `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\Patchouli` | 目录列举 |
| git 版本 | `release-1.21.1-93` | `git describe --tags` |
| HEAD | `0c2fdffc7e611a828007cecae7bfc3d7b312040a`（`grafted`，`tag: release-1.21.1-93`） | `git log -1` |
| 构建参数 | `mc_version=1.21.1`、`build_number=93`、`group=vazkii.patchouli` | `gradle.properties` |
| 映射 | `neoForge.parchment.mappingsVersion=2024.11.17` | `gradle.properties` |

本文所有路径均为**相对于仓库根**的路径；方法体仅在「有重要语义」时用中文说明，其余以注释占位表示省略。

`Xplat/src/main/java/vazkii/patchouli/api/` 目录下共有 17 个 `.java` 文件：

```
Xplat/src/main/java/vazkii/patchouli/api/IComponentProcessor.java
Xplat/src/main/java/vazkii/patchouli/api/IComponentRenderContext.java
Xplat/src/main/java/vazkii/patchouli/api/ICustomComponent.java
Xplat/src/main/java/vazkii/patchouli/api/IMultiblock.java
Xplat/src/main/java/vazkii/patchouli/api/IStateMatcher.java
Xplat/src/main/java/vazkii/patchouli/api/IStyleStack.java
Xplat/src/main/java/vazkii/patchouli/api/IVariable.java
Xplat/src/main/java/vazkii/patchouli/api/IVariableProvider.java
Xplat/src/main/java/vazkii/patchouli/api/IVariablesAvailableCallback.java
Xplat/src/main/java/vazkii/patchouli/api/IVariableSerializer.java
Xplat/src/main/java/vazkii/patchouli/api/package-info.java
Xplat/src/main/java/vazkii/patchouli/api/PatchouliAPI.java          （含 IPatchouliAPI，本次未逐条抄录）
Xplat/src/main/java/vazkii/patchouli/api/PatchouliConfigAccess.java （本次未逐条抄录）
Xplat/src/main/java/vazkii/patchouli/api/TriPredicate.java
Xplat/src/main/java/vazkii/patchouli/api/VariableHelper.java
Xplat/src/main/java/vazkii/patchouli/api/stub/StubMatcher.java
Xplat/src/main/java/vazkii/patchouli/api/stub/StubMultiblock.java
Xplat/src/main/java/vazkii/patchouli/api/stub/StubPatchouliAPI.java  （作为 stub 触发机制一并说明）
```

---

## 1. `api/IComponentProcessor.java`

```java
package vazkii.patchouli.api;

import net.minecraft.client.gui.screens.Screen;
import net.minecraft.world.level.Level;

/**
 * Implement this on a class designed to process a template and the variables bound
 * to the inside. This doesn't have to be registered anywhere, but any class implementing
 * this needs either no explicit constructor, or an implicit public no parameter constructor.
 * <br>
 * <br>
 * Instances of this class are created once for every usage of the template it's meant to
 * process, so you can save data on a per-template basis.
 */
public interface IComponentProcessor {

	/**
	 * Called as the template is being built with the variables passed into it. Use
	 * this to set up any data that will be used later. Any exceptions thrown here
	 * will be caught by the book loader, and graciously displayed in a user friendly
	 * way, so feel free to throw on any unrecoverable states.
	 */
	void setup(Level level, IVariableProvider variables);

	/**
	 * Processes a variable. You should return what you think the result should be, or
	 * null if you don't want to process it. If you need to pass in a serialized
	 * ItemStack, look at the ItemStack serialization methods in the main API class.
	 * <br>
	 * <br>
	 * Note that this is also called for any right-side values of the using block of
	 * any included templates. It is not called for the variables used inside said
	 * templates.
	 */
	IVariable process(Level level, String key);

	/**
	 * Called when a book GUI containing this page is showed (by guiInit).
	 */
	default void refresh(Screen parent, int left, int top) {
		// NO-OP
	}

	/**
	 * Returns whether an element is allowed to render based on its group. This method
	 * isn't called by elements with no group or with an empty group.
	 * <br>
	 * <br>
	 * In the case of included templates existing, groups are automatically assigned
	 * to them, and this will be called for every element inside them with said groups.
	 * Eg. Including another template as "sub", which has elements with no group, and with
	 * groups "group1" and "group2" will have this be called for "sub", "sub.group1", and
	 * "sub.group2".
	 */
	default boolean allowRender(String group) {
		return true;
	}
}
```

要点（中文）：

- 不需要在任何注册表登记；但实现类必须有无参构造（隐式或显式 public 无参）。
- 每使用一次该模板就创建一个新实例，因此可以按模板实例缓存数据。
- `setup` 中抛出的异常会被书加载器捕获并以对用户友好的方式展示。
- `process` 返回 `null` 表示「不处理该变量」（交由变量表回退）；它同样会对被包含模板 `using` 块的右侧值调用，但**不会**对被包含模板内部使用的变量调用。
- `refresh` 默认空实现，由书 GUI 显示时调用（实际调用点在 `BookTemplate.onDisplayed`）。
- `allowRender` 默认 `true`；只对非空 group 调用，包含模板的 group 会被自动限定为 `sub`、`sub.group1`、`sub.group2` 形式。

无成员常量、无嵌套类型。

---

## 2. `api/ICustomComponent.java`

```java
package vazkii.patchouli.api;

import net.minecraft.client.gui.GuiGraphics;

/**
 * An interface for API level custom components for templates.
 * <br>
 * <br>
 * <b>WARNING:</b> Any fields you declare in instances of this will be deserialized from
 * gson. Any fields that you don't want to be read from the json should have
 * the transient keyword.
 */
public interface ICustomComponent extends IVariablesAvailableCallback {

	/**
	 * Called when this component is built, after variables have been resolved with {@link #onVariablesAvailable}.
	 * Take the chance to parse String variables into game objects, perform error checking, and setup any local
	 * positions here.
	 */
	void build(int componentX, int componentY, int pageNum);

	/**
	 * Called every render tick. No special transformations are applied, so you're responsible
	 * for putting everything in the right place.
	 */
	void render(GuiGraphics graphics, IComponentRenderContext context, float pticks, int mouseX, int mouseY);

	/**
	 * Called when this component first enters the screen. Good time to refresh anything that
	 * can be dynamic. If you need to add buttons, you can add them here too.
	 */
	default void onDisplayed(IComponentRenderContext context) {
		// NO-OP
	}

	/**
	 * Called on mouse click. Note that the click may not be inside your component, so
	 * you need to validate the position.
	 */
	default boolean mouseClicked(IComponentRenderContext context, double mouseX, double mouseY, int mouseButton) {
		return false;
	}
}
```

要点（中文）：

- 你的实现类字段会被 Gson 从 JSON 反序列化，不希望被 JSON 读取的字段必须加 `transient`。
- `build` 在变量解析（`onVariablesAvailable`）之后调用；`render` 每渲染帧调用且不施加任何变换，坐标自负。
- `onDisplayed` 默认空实现，可用于刷新动态内容与添加按钮。
- `mouseClicked` 默认返回 `false`；点击未必落在组件内，必须自行判定位置。
- 该接口本身继承 `IVariablesAvailableCallback`，因此必须实现 `onVariablesAvailable(UnaryOperator<IVariable>, HolderLookup.Provider)`。

无成员常量、无嵌套类型。

---

## 3. `api/IComponentRenderContext.java`

```java
package vazkii.patchouli.api;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.AbstractWidget;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.Style;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;

import java.util.List;

/**
 * A context for a custom component's methods.
 */
public interface IComponentRenderContext {

	Screen getGui();

	Style getFont();

	void renderItemStack(GuiGraphics graphics, int x, int y, int mouseX, int mouseY, ItemStack stack);

	void renderIngredient(GuiGraphics graphics, int x, int y, int mouseX, int mouseY, Ingredient ingredient);

	boolean isAreaHovered(int mouseX, int mouseY, int x, int y, int w, int h);

	boolean navigateToEntry(ResourceLocation entry, int page, boolean push);

	@Deprecated // use setHoverTooltipComponents
	void setHoverTooltip(List<String> tooltip);

	void setHoverTooltipComponents(List<Component> tooltip);

	@Deprecated(forRemoval = true) // use addWidget
	void registerButton(Button button, int pageNum, Runnable onClick);

	void addWidget(AbstractWidget button, int pageNum);

	ResourceLocation getBookTexture();

	ResourceLocation getCraftingTexture();

	int getTextColor();

	int getHeaderColor();

	int getTicksInBook();
}
```

要点（中文）：全部为抽象方法，无默认实现、无常量、无嵌套类型。两处已弃用 API 的替代关系写在注解注释里：`setHoverTooltip(List<String>)` → `setHoverTooltipComponents(List<Component>)`；`registerButton(Button, int, Runnable)` → `addWidget(AbstractWidget, int)`（后者标记 `forRemoval = true`，即计划移除）。

---

## 4. `api/IVariableProvider.java`

```java
package vazkii.patchouli.api;

import net.minecraft.core.HolderLookup;

/**
 * A provider of variables to a template. Probably a JSON.
 */
public interface IVariableProvider {

	/**
	 * Gets the value assigned to the variable passed in.
	 * May throw an exception if it doesn't exist.
	 */
	IVariable get(String key, HolderLookup.Provider registries);

	/**
	 * Returns if a variable exists or not.
	 */
	boolean has(String key);
}
```

要点（中文）：`get` 在变量不存在「可能抛异常」（实现类 `JsonVariableWrapper.get` 确实抛 `IllegalArgumentException`），因此取变量前通常应先用 `has` 判定。无默认方法、无常量、无嵌套类型。

---

## 5. `api/IVariable.java`

```java
package vazkii.patchouli.api;

import com.google.gson.JsonArray;
import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonPrimitive;

import net.minecraft.core.HolderLookup;
import net.minecraft.core.RegistryAccess;
import net.minecraft.core.registries.BuiltInRegistries;

import org.jetbrains.annotations.Nullable;

import java.lang.reflect.Type;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

/**
 * A Patchouli derivation variable, represented internally as {@link JsonElement}.
 */
public interface IVariable {

	/**
	 * Interpret the JSON of this variable as a given Object class.
	 * Will return {@code null} if this type doesn't have a serializer registered;
	 * might return {@code null} or throw if the input is malformed.
	 *
	 * @param  clazz the Class of the object you want to convert this to
	 * @return       this variable as an object of that class
	 */
	<T> T as(Class<T> clazz);

	default <T> T as(Class<T> clazz, T def) {
		return unwrap().isJsonNull() ? def : as(clazz);
	}

	/**
	 * Take a look at the underlying {@link JsonElement} for this variable.
	 *
	 * @return the underlying JSON element for this Variable
	 */
	JsonElement unwrap();

	/**
	 * Get this IVariable as a String.
	 */
	default String asString() {
		return asString("");
	}

	/**
	 * Get this IVariable as a String, with a default value.
	 */
	default String asString(String def) {
		return unwrap().isJsonNull() ? def : unwrap().getAsString();
	}

	/**
	 * Get this IVariable as a Number.
	 */
	default Number asNumber() {
		return asNumber(0);
	}

	/**
	 * Get this IVariable as a Number, with a default value.
	 */
	default Number asNumber(Number def) {
		return unwrap().isJsonNull() ? def : unwrap().getAsNumber();
	}

	/**
	 * Get this IVariable as a boolean.
	 */
	default boolean asBoolean() {
		return asBoolean(false);
	}

	/**
	 * Get this IVariable as a boolean, with a default value.
	 * For legacy reasons, the strings {@code ""} and {@code "false"} evaluate to false.
	 */
	default boolean asBoolean(boolean def) {
		return unwrap().isJsonNull() ? def : (!unwrap().getAsString().equals("false") && !unwrap().getAsString().isEmpty() && unwrap().getAsBoolean());
	}

	/**
	 * Get this IVariable as a {@code Stream<IVariable>}, assuming it's backed by a JsonArray.
	 */
	default Stream<IVariable> asStream(HolderLookup.Provider registries) {
		return StreamSupport.stream(unwrap().getAsJsonArray().spliterator(), false)
				.map((json) -> IVariable.wrap(json, registries));
	}

	/**
	 * Get this IVariable as a {@code List<IVariable>}, returning as singleton if it's not a JsonArray.
	 */
	default Stream<IVariable> asStreamOrSingleton(HolderLookup.Provider registries) {
		return unwrap().isJsonArray() ? asStream(registries) : Stream.of(this);
	}

	/**
	 * Get this IVariable as a {@code List<IVariable>}, assuming it's backed by a JsonArray.
	 */
	default List<IVariable> asList(HolderLookup.Provider registries) {
		return asStream(registries).collect(Collectors.toList());
	}

	/**
	 * Get this IVariable as a {@code List<IVariable>}, returning as singleton if it's not a JsonArray.
	 */
	default List<IVariable> asListOrSingleton(HolderLookup.Provider registries) {
		return asStreamOrSingleton(registries).collect(Collectors.toList());
	}

	/**
	 * Convenience method to create an IVariable from {@link VariableHelper#createFromObject}.
	 */
	static <T> IVariable from(@Nullable T object, HolderLookup.Provider registries) {
		return object != null ? VariableHelper.instance().createFromObject(object, registries) : empty();
	}

	/**
	 * Convenience method to create an IVariable from a JsonElement with {@link VariableHelper#createFromJson}.
	 */
	static IVariable wrap(@Nullable JsonElement elem, HolderLookup.Provider registries) {
		return elem != null ? VariableHelper.instance().createFromJson(elem, registries) : empty();
	}

	/**
	 * Convenience method to create an IVariable from a list of IVariables.
	 */
	static IVariable wrapList(Iterable<IVariable> elems, HolderLookup.Provider registries) {
		JsonArray arr = new JsonArray();
		for (IVariable v : elems) {
			arr.add(v.unwrap());
		}
		return wrap(arr, registries);
	}

	@Deprecated // Use HolderLookup.Provider version
	static IVariable wrap(@Nullable Number n) {
		return wrap(n, RegistryAccess.EMPTY);
	}

	static IVariable wrap(@Nullable Number n, HolderLookup.Provider registries) {
		return n != null ? wrap(new JsonPrimitive(n), registries) : empty();
	}

	@Deprecated // Use HolderLookup.Provider version
	static IVariable wrap(@Nullable Boolean b) {
		return wrap(b, RegistryAccess.EMPTY);
	}

	static IVariable wrap(@Nullable Boolean b, HolderLookup.Provider registries) {
		return b != null ? wrap(new JsonPrimitive(b), registries) : empty();
	}

	@Deprecated // Use HolderLookup.Provider version
	static IVariable wrap(@Nullable String s) {
		return wrap(s, RegistryAccess.EMPTY);
	}

	static IVariable wrap(@Nullable String s, HolderLookup.Provider registries) {
		return s != null ? wrap(new JsonPrimitive(s), registries) : empty();
	}

	static IVariable empty() {
		return wrap(JsonNull.INSTANCE, RegistryAccess.EMPTY);
	}

	class Serializer implements JsonDeserializer<IVariable> {

		private HolderLookup.Provider registryCache;

		@Override
		public IVariable deserialize(JsonElement elem, Type t, JsonDeserializationContext c) {
			if (registryCache == null || registryCache.listRegistries().findFirst().isEmpty()) {
				registryCache = RegistryAccess.fromRegistryOfRegistries(BuiltInRegistries.REGISTRY);
			}
			return IVariable.wrap(elem, registryCache);
		}

		public void setRegistries(HolderLookup.Provider registries) {
			this.registryCache = registries;
		}
	}
}
```

要点（中文，说明默认实现的语义）：

- `as(clazz, def)`：底层 JSON 为 `JsonNull` 时返回 `def`，否则调用 `as(clazz)`（注意 `as(clazz)` 在文档上「未注册序列化器时返回 null」，但实际实现类 `Variable` 是**抛 `IllegalArgumentException`**，见第 2 节）。
- `asString()` 等价于 `asString("")`；`asString(def)` 对 `JsonNull` 返回 `def`。
- `asNumber()` 等价于 `asNumber(0)`。
- `asBoolean()` 等价于 `asBoolean(false)`；`asBoolean(def)` 出于历史兼容，把字符串 `"false"` 和空串都判为 `false`（表达式：`!getAsString().equals("false") && !getAsString().isEmpty() && getAsBoolean()`）。
- `asStream` 假定底层是 `JsonArray`（否则抛异常）；`asStreamOrSingleton` / `asListOrSingleton` 在非数组时退化为单元素。
- 静态工厂：`from` / `wrap(JsonElement)` 对 `null` 输入返回 `empty()`（`JsonNull`）；`wrap(Number/Boolean/String)` 有三个已弃用的无注册表重载（内部用 `RegistryAccess.EMPTY`）；`empty()` 返回 `JsonNull` 包装。
- 嵌套类 `Serializer implements JsonDeserializer<IVariable>`：缓存一个 `HolderLookup.Provider`；`deserialize` 时若缓存为 null 或其注册表集合为空，则退化为 `RegistryAccess.fromRegistryOfRegistries(BuiltInRegistries.REGISTRY)`；可通过 `setRegistries` 注入真实注册表。

---

## 6. `api/IVariableSerializer.java`

```java
package vazkii.patchouli.api;

import com.google.gson.JsonElement;

import net.minecraft.core.HolderLookup;

/**
 * An instance of a class implementing this interface
 * provides conversions for the given type to/from {@link JsonElement}.
 *
 * @param <T> the type that gets converted to/from JSON
 */
public interface IVariableSerializer<T> {
	/**
	 * Deserialize an object of type T from JSON.
	 */
	T fromJson(JsonElement json, HolderLookup.Provider registries);

	/**
	 * Serialize an object of type T to JSON.
	 */
	JsonElement toJson(T object, HolderLookup.Provider registries);
}
```

要点（中文）：仅两个抽象方法，无默认方法、无常量、无嵌套类型；泛型参数 `T` 为「被转换的类型」。

---

## 7. `api/IVariablesAvailableCallback.java`

```java
package vazkii.patchouli.api;

import net.minecraft.core.HolderLookup;

import java.util.function.UnaryOperator;

public interface IVariablesAvailableCallback {
	/**
	 * Called when variables are available, before the template component is built
	 *
	 * @param lookup     Call with arbitrary text, and it will be expanded:
	 *                   first expanding all inline variables,
	 *                   then attempting to apply "->" derivations if possible, otherwise looking up the string as a
	 *                   plain variable from the template environment<br />
	 *                   Gracefully handles nulls given as input, but will never return null itself.
	 * @param registries Provider for accessing registries in IVariable#wrap operations.
	 */
	void onVariablesAvailable(UnaryOperator<IVariable> lookup, HolderLookup.Provider registries);
}
```

要点（中文）：`lookup` 的语义是——传入任意文本即可被展开：先展开全部内联变量（`#var#` 形式），再尝试套用 `->` 派生函数，否则把该字符串当作模板环境中的普通变量查找；`lookup` 对 `null` 输入能优雅处理，但自身永不返回 `null`。无默认方法、无常量、无嵌套类型。

---

## 8. `api/VariableHelper.java`

```java
package vazkii.patchouli.api;

import com.google.common.base.Suppliers;
import com.google.gson.JsonElement;

import net.minecraft.core.HolderLookup;

import org.jetbrains.annotations.Nullable;

import java.util.function.Supplier;

/**
 * API endpoint for serializing/deserializing arbitrary objects to/from JsonElements.
 */
public interface VariableHelper {

	Supplier<VariableHelper> INSTANCE = Suppliers.memoize(() -> {
		try {
			return (VariableHelper) Class.forName("vazkii.patchouli.client.book.template.variable.VariableHelperImpl").newInstance();
		} catch (ReflectiveOperationException e) {
			return new VariableHelper() {};
		}
	});

	/**
	 * Get the singleton instance of this VariableHelper.
	 */
	static VariableHelper instance() {
		return INSTANCE.get();
	}

	/**
	 * Create an {@link IVariable} from a given object.
	 */
	default <T> IVariable createFromObject(T object, HolderLookup.Provider registries) {
		return null;
	}

	/**
	 * Create an {@link IVariable} backed by the given {@link JsonElement}.
	 */
	default IVariable createFromJson(JsonElement elem, HolderLookup.Provider registries) {
		return null;
	}

	/**
	 * Get an {@link IVariableSerializer} for the given class.
	 * If we don't know how to deserialize this class, return {@code null}.
	 */
	@Nullable
	default <T> IVariableSerializer<T> serializerForClass(Class<T> clazz) {
		return null;
	}

	/**
	 * Register an {@link IVariableSerializer} that can deserialize an object of the given class.
	 * Note that a sane serializer should probably cope with subclasses gracefully.
	 */
	default <T> VariableHelper registerSerializer(IVariableSerializer<T> serializer, Class<T> clazz) {
		return instance();
	}
}
```

要点（中文，默认实现的语义很重要）：

- 唯一常量是 `Supplier<VariableHelper> INSTANCE`，用 `Suppliers.memoize` 懒加载：反射 `vazkii.patchouli.client.book.template.variable.VariableHelperImpl` 并实例化；反射失败（例如 Patchouli 不在场）时返回一个**匿名空实现** `new VariableHelper() {}`，其所有方法都走下面的默认实现（即全部返回 `null`，形成静默降级）。
- `instance()` 静态方法返回单例。
- 两个 `create*` 默认实现都返回 `null`；`serializerForClass` 默认返回 `null`（表示「不知道怎么反序列化这个类」）。
- `registerSerializer` 默认实现**忽略传入的 serializer 与 class，直接返回 `instance()`**，也就是说只有真正的实现类才会真正登记（这是空实现下的无操作降级）。

---

## 9. `api/IMultiblock.java`

```java
package vazkii.patchouli.api;

import com.mojang.datafixers.util.Pair;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Vec3i;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Rotation;

import org.jetbrains.annotations.Nullable;

import java.util.Collection;

/**
 * An instance of a multiblock.
 * <br>
 * <br>
 * WARNING: This interface is provided only for usage with the API. For creating
 * an IMultiblock instance use the methods provided in the API main class. Please
 * do not create your own implementation of this, as it'll not be compatible with
 * all the features in the mod.
 */
public interface IMultiblock {

	// ================================================================================================
	// Builder methods
	// ================================================================================================

	/**
	 * Offsets the position of the multiblock by the amount specified.
	 * Works for both placement, validation, and rendering.
	 */
	IMultiblock offset(int x, int y, int z);

	/**
	 * Offsets the view of the multiblock by the amount specified.
	 * Matters only for where the multiblock renders.
	 */
	IMultiblock offsetView(int x, int y, int z);

	/**
	 * Sets the multiblock's symmetrical value. Symmetrical multiblocks
	 * check only in one rotation, not all 4. If your multiblock is symmetrical
	 * around the center axis, set this to true to prevent needless cycles.
	 */
	IMultiblock setSymmetrical(boolean symmetrical);

	/**
	 * Sets the multiblock's ID. Not something you need to
	 * call yourself as the register method in the main API class does it for you.
	 */
	IMultiblock setId(ResourceLocation res);

	// ================================================================================================
	// Getters
	// ================================================================================================

	/**
	 * Gets if this multiblock is symmetrical.
	 *
	 * @see IMultiblock#setSymmetrical
	 */
	boolean isSymmetrical();

	ResourceLocation getID();

	// ================================================================================================
	// Actual functionality
	// Note: DO NOT USE THESE METHODS IF YOUR MOD DOESN'T HAVE
	// A HARD DEPENDENCY ON PATCHOULI
	//
	// The stub API will return an empty multiblock that doesn't
	// do any of these things!
	// ================================================================================================

	/**
	 * Places the multiblock at the given position with the given rotation.
	 */
	void place(Level world, BlockPos pos, Rotation rotation);

	/**
	 * If this multiblock were anchored at world position {@code anchor} with rotation {@code rotation}, then
	 * return a pair whose first element is the final center position (after rotation and {@link #offset}),
	 * and whose second element describes each position of the multiblock.
	 * This is intended to be highly general, most of the other methods below are implemented in terms of this one.
	 * See the main Patchouli code to see what can be done with this.
	 */
	Pair<BlockPos, Collection<SimulateResult>> simulate(Level world, BlockPos anchor, Rotation rotation, boolean forView);

	/**
	 * Validates if the multiblock exists at the given position. Will check all 4
	 * rotations if the multiblock is not symmetrical.
	 *
	 * @return The rotation that worked, null if no match
	 */
	@Nullable
	Rotation validate(Level world, BlockPos pos);

	/**
	 * Validates the multiblock for a specific rotation
	 */
	boolean validate(Level world, BlockPos pos, Rotation rotation);

	/**
	 * Fine-grained check for whether any one given block of the multiblock exists at the given position
	 * with the given rotation.
	 *
	 * @param start The anchor position. The multiblock's {@link #offset} is not applied to this.
	 */
	boolean test(Level world, BlockPos start, int x, int y, int z, Rotation rotation);

	/**
	 * Gets the size of this multiblock
	 *
	 * @return The size of the multiblock
	 */
	Vec3i getSize();

	interface SimulateResult {
		/**
		 * Final world position this block will be matched or placed at
		 */
		BlockPos getWorldPosition();

		/**
		 * The matcher used at this position
		 */
		IStateMatcher getStateMatcher();

		/**
		 * The character used to express the state matcher, if this is a dense multiblock.
		 */
		@Nullable
		Character getCharacter();

		/**
		 * @return Whether the multiblock is fulfilled at this position
		 */
		boolean test(Level world, Rotation rotation);
	}
}
```

要点（中文）：

- 源码明确警告「**不要自己实现这个接口**」，创建实例请用 `PatchouliAPI.get()` 上的 `makeMultiblock` / `makeSparseMultiblock` 等工厂方法，否则无法与模组全部功能兼容。
- 注释明确区分「构造器方法 / 取值器 / 真正的功能方法」三组，并特别提醒：**如果你的模组没有对 Patchouli 的硬依赖，不要使用功能方法**，因为 stub API 会返回一个什么都不做的空多方块。
- 嵌套类型仅一个：`interface SimulateResult`（含 4 个抽象方法，其中 `getCharacter()` 带 `@Nullable` 且只在 dense 多方块下有值）。
- 无常量（无 `static final` 字段）。

---

## 10. `api/IStateMatcher.java`

```java
package vazkii.patchouli.api;

import net.minecraft.core.BlockPos;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.block.state.BlockState;

/**
 * A composite element of a rendering block state, and a predicate
 * to validate if the real state in the world is valid or not. Used
 * as the core building block for multiblocks.
 */
public interface IStateMatcher {

	/**
	 * Gets the state displayed by this state matcher for rendering
	 * the multiblock page type and the in-world preview.
	 *
	 * @param ticks World ticks, to allow cycling the state shown.
	 */
	BlockState getDisplayedState(long ticks);

	/**
	 * Returns a predicate that validates whether the given state is
	 * acceptable. This should check the passed in blockstate instead of requerying it from the world,
	 * for both performance and correctness reasons -- the state may be rotated for multiblock matching.
	 */
	TriPredicate<BlockGetter, BlockPos, BlockState> getStatePredicate();
}
```

要点（中文）：它是多方块的核心构件；`getStatePredicate` 返回的断言必须校验**传入的** `BlockState`，而不要再去世界里查询（性能与正确性原因，状态可能已被旋转）。无默认方法、无常量、无嵌套类型。

---

## 11. `api/IStyleStack.java`

```java
package vazkii.patchouli.api;

import net.minecraft.network.chat.Style;

import java.util.function.UnaryOperator;

/**
 * Represents a stack of styles when rendering book text.
 */
public interface IStyleStack {
	/** Modify the style at the top of the stack. */
	void modifyStyle(UnaryOperator<Style> f);

	/** Push a new style onto the style stack. */
	void pushStyle(Style style);

	/** Pop the last style off the stack. Throws if called more times than pushStyle() was called. */
	Style popStyle();

	/** Peek at the current style on the stack. */
	Style peekStyle();

	/** Reset global style state. */
	void reset();
}
```

要点（中文）：全部为抽象方法。约定：`popStyle()` 调用次数多于 `pushStyle()` 时抛异常（唯一实现 `SpanState` 抛 `IllegalStateException("Underflow in style stack")`）。该接口是 `PatchouliAPI.IPatchouliAPI#registerCommand/registerFunction` 的参数类型（即 `$(cmd)` 与 `$(func:arg)` 文本命令可以修改样式栈）。无默认方法、无常量、无嵌套类型。

---

## 12. `api/TriPredicate.java`

```java
package vazkii.patchouli.api;

@FunctionalInterface
public interface TriPredicate<A, B, C> {
	boolean test(A a, B b, C c);
}
```

要点（中文）：三元断言式函数接口（对标 `java.util.function.Predicate`，只是接收三个参数），用于 `IStateMatcher#getStatePredicate` 返回「世界 + 位置 + 状态」的判定。唯一注解：`@FunctionalInterface`。无常量、无嵌套类型。

---

## 13. `api/package-info.java`

```java
@net.minecraft.MethodsReturnNonnullByDefault
package vazkii.patchouli.api;
```

说明（中文）：

- 该文件**只有一行包注解，没有任何章节性文字**，因此本仓库中并不存在以注释形式写下的「API 稳定性契约 / 版本兼容承诺」文本。
- 注解 `@net.minecraft.MethodsReturnNonnullByDefault`（Mojang 自带）的语义要点：**该包内所有方法的返回值默认视为非空**；只有显式标注 `@Nullable` 的元素（例如 `VariableHelper#serializerForClass`、`IMultiblock#validate(Level, BlockPos)`、`IMultiblock.SimulateResult#getCharacter`、以及 `IVariable` 与 `PatchouliAPI` 中的若干静态/接口方法）才被允许返回 `null`。
- 为确认是否存在别处的稳定性说明，已检索整个仓库中的 `stabilit|API is stable|breaking change|backwards compat`：**无任何匹配**（即「未能核实」仓库内存在明确的稳定性承诺文字）。

---

## 14. `api/stub/StubMatcher.java`

```java
package vazkii.patchouli.api.stub;

import net.minecraft.core.BlockPos;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;

import vazkii.patchouli.api.IStateMatcher;
import vazkii.patchouli.api.TriPredicate;

public final class StubMatcher implements IStateMatcher {

	public static final StubMatcher INSTANCE = new StubMatcher();

	private final BlockState state = Blocks.AIR.defaultBlockState();

	private StubMatcher() {}

	@Override
	public BlockState getDisplayedState(long ticks) {
		return state;
	}

	@Override
	public TriPredicate<BlockGetter, BlockPos, BlockState> getStatePredicate() {
		return (w, p, s) -> false;
	}
}
```

---

## 15. `api/stub/StubMultiblock.java`

```java
package vazkii.patchouli.api.stub;

import com.mojang.datafixers.util.Pair;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Vec3i;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Rotation;

import vazkii.patchouli.api.IMultiblock;

import java.util.Collection;
import java.util.Collections;

public class StubMultiblock implements IMultiblock {

	public static final StubMultiblock INSTANCE = new StubMultiblock();

	private StubMultiblock() {}

	@Override
	public IMultiblock offset(int x, int y, int z) {
		return this;
	}

	@Override
	public IMultiblock offsetView(int x, int y, int z) {
		return this;
	}

	@Override
	public IMultiblock setSymmetrical(boolean symmetrical) {
		return this;
	}

	@Override
	public ResourceLocation getID() {
		return ResourceLocation.fromNamespaceAndPath("patchouli", "stub");
	}

	@Override
	public IMultiblock setId(ResourceLocation res) {
		return this;
	}

	@Override
	public boolean isSymmetrical() {
		return false;
	}

	@Override
	public void place(Level world, BlockPos pos, Rotation rotation) {
		// NO-OP
	}

	@Override
	public Pair<BlockPos, Collection<SimulateResult>> simulate(Level world, BlockPos anchor, Rotation rotation, boolean forView) {
		return Pair.of(BlockPos.ZERO, Collections.emptyList());
	}

	@Override
	public Rotation validate(Level world, BlockPos pos) {
		return null;
	}

	@Override
	public boolean validate(Level world, BlockPos pos, Rotation rotation) {
		return false;
	}

	@Override
	public boolean test(Level world, BlockPos start, int x, int y, int z, Rotation rotation) {
		return false;
	}

	@Override
	public Vec3i getSize() {
		return Vec3i.ZERO;
	}
}
```

---

## 16. stub 包的作用与触发时机（`StubMatcher` / `StubMultiblock` / `StubPatchouliAPI`）

- 触发时机：`api/PatchouliAPI.java` 中的
  ```java
  private static final Supplier<IPatchouliAPI> LAZY_INSTANCE = Suppliers.memoize(() -> {
      try {
          return (IPatchouliAPI) Class.forName("vazkii.patchouli.common.base.PatchouliAPIImpl").newInstance();
      } catch (ReflectiveOperationException e) {
          LogManager.getLogger().warn("Unable to find PatchouliAPIImpl, using a dummy");
          return StubPatchouliAPI.INSTANCE;
      }
  });
  ```
  也就是说：**当 Patchouli 本体不在运行时（反射不到 `vazkii.patchouli.common.base.PatchouliAPIImpl`），`PatchouliAPI.get()` 会返回 `StubPatchouliAPI.INSTANCE`（一个空实现）**，而该空实现的所有多方块/匹配器工厂方法都返回 `StubMultiblock.INSTANCE` / `StubMatcher.INSTANCE`（已核实：`StubPatchouliAPI.java` 第 173、178 行返回 `StubMultiblock.INSTANCE`，第 183–233 行共 11 处返回 `StubMatcher.INSTANCE`）。
- 因此这两个类的作用是：让**把 Patchouli 当作可选依赖**的模组在 Patchouli 缺席时仍能编译并运行——API 调用得到「永远判定为 false / 什么都不做」的对象，而不是 `NoClassDefFoundError` 或 NPE。
- `StubMatcher`：展示状态恒为空气（`Blocks.AIR.defaultBlockState()`），判定恒为 `false`（`(w, p, s) -> false`）；单例、私有构造、`final` 类。
- `StubMultiblock`：所有链式设置方法返回 `this`（便于链式调用不炸），`place` 为空操作，`simulate` 返回「中心为 `BlockPos.ZERO` + 空集合」，`validate` 返回 `null` / `false`，`test` 返回 `false`，`getSize` 返回 `Vec3i.ZERO`；`getID()` 恒为 `patchouli:stub`（`setId` 被忽略）；`isSymmetrical()` 恒为 `false`。
- 与之配套的还有 `api/stub/StubPatchouliAPI.java`（`implements IPatchouliAPI`，`isStub()` 返回 true）。**注意**：`IMultiblock` 的源码注释明确要求「不要自己实现该接口」，而 stub 包是模组自身的内部降级实现，并非给外部实现的示例。

---

## 17. 实现方清单位置（grep 结果）

### 17.1 `IComponentProcessor` 的实现类

| 实现类（相对仓库根路径） | 说明 |
| --- | --- |
| `Xplat/src/main/java/vazkii/patchouli/client/book/template/test/RecipeTestProcessor.java` | 官方示例：从 `recipe` 变量取配方，派生 `item1..itemN` / `text` / `icount` / `iname` |
| `Xplat/src/main/java/vazkii/patchouli/client/book/template/test/EntityTestProcessor.java` | 官方示例：从 `entity` 变量取实体类型并派生 `name` |

检索方式：`grep -r "implements IComponentProcessor"` 覆盖整个仓库（含 `Xplat` / `Fabric` / `NeoForge` 全部源集与 `src/test`），**只有上述两处直接实现**；除此之外的使用方是「消费方」而非实现方：

- `client/book/template/BookTemplate.java`：字段 `transient IComponentProcessor processor;`，负责反射创建与生命周期调度。
- `client/book/template/TemplateComponent.java`：`compile(...)` 形参与 `getVisibleStatus(IComponentProcessor processor)`。
- `client/book/template/VariableAssigner.java`：在变量解析时调用 `processor.process(...)`。
- `client/book/template/TemplateInclusion.java`：`process(Level, IComponentProcessor)`。

**关于「Processor 的 type id」——重要更正（并与用户提示不符）**：本 tag 中 `IComponentProcessor` **不是**按 `ResourceLocation`/type id 注册的，**不存在** `patchouli:macros`、`patchouli:flags` 这类 id。实际机制是**类名反射**：

- `BookTemplate` 中 `@SerializedName("processor") String processorClass;`（模板 JSON 的 `"processor"` 字段是一个**字符串形式的完整类名**）；
- `BookTemplate.createProcessor()`：
  ```java
  Class<?> clazz = Class.forName(processorClass);
  processor = (IComponentProcessor) clazz.newInstance();   // 失败抛 RuntimeException("Failed to create component processor " + processorClass, e)
  ```
- 官方文档也如此描述：`web/docs/patchouli-advanced/component-processors.md` 第 20 行 ——「Add `"processor": "package.name.ClassName"` to your template file, referencing the class you created.」
- 仓库内实际出现的两个取值（`grep "processor"`）：
  - `Xplat/src/main/resources/assets/patchouli/patchouli_books/testbook2/en_us/templates/mob_kill_display.json` → `"vazkii.patchouli.client.book.template.test.EntityTestProcessor"`
  - `Xplat/src/main/resources/assets/patchouli/patchouli_books/testbook2/en_us/templates/include/recipetest.json` → `"vazkii.patchouli.client.book.template.test.RecipeTestProcessor"`
- 调用顺序（`BookTemplate.compile`）：先 `createProcessor()` → 若有 `encapsulation`（被作为子模板包含）则把变量源包一层 `encapsulation.wrapProvider(variables)` → `processor.setup(level, processorVars)`（异常包装为 `RuntimeException("Error setting up template processor", e)`）→ 处理每个 `include` 的 `include.process(level, processor)` → 每个组件 `c.compile(level, variables, processor, encapsulation)`；`onDisplayed` 时调用 `processor.refresh(parent, left, top)` 并把每个组件的 `isVisible` 置为 `c.getVisibleStatus(processor)`。

### 17.2 `ProcessorMacros` / `ProcessorFlags` —— 未能核实（不存在于本 tag）

- 已检查位置：
  1. `grep "ProcessorMacros|ProcessorFlags|interface Processor"` 于 `Xplat/src/main/java` → **0 匹配**；
  2. `grep "ProcessorMacros|ProcessorFlags|IMultiblockProcessor|\"processor\""` 于整个仓库根（不限文件类型）→ 仅 4 个匹配，全部是 `"processor"` 字段相关，**没有**这两个类；
  3. 完整列举 `Xplat/src/main/java/vazkii/patchouli/client/book/template/` 及其子目录（共 24 个 `.java`，含 `component/`、`test/`、`variable/` 三个子包）→ 没有 `processor/` 子包，也没有任何名字含 `Macros` / `Flags` 的类；
  4. 官方文档 `web/docs/patchouli-advanced/component-processors.md` 只描述 FQCN 反射方式。
- 结论：**`ProcessorMacros`、`ProcessorFlags` 以及 `patchouli:macros`、`patchouli:flags` 这两个 type id 在本 tag（release-1.21.1-93）中不存在，未能核实**；它们可能来自其它 Patchouli 版本/分支或第三方模组。
- 可能造成混淆的两处真实机制（已核实存在，但**都不是** `IComponentProcessor` 的 type id）：
  1. **Config Flags**：`TemplateComponent.flag` 字段 + `PatchouliConfig.getConfigFlag(flag)` + `PatchouliAPI.IPatchouliAPI#setConfigFlag/getConfigFlag`，文档见 `web/docs/patchouli-basics/config-gating.md`（这是「flags」，但属于配置开关系统，用于门控内容）；
  2. **文本宏（Macros）**：`client/book/text/BookTextParser.java` 的 `expandMacros(...)`（`$(...)` 命令/函数系统），文档见 `web/docs/patchouli-basics/text-formatting.md` 的「Default Macros / Custom Macros」（这是「macros」，但属于文本格式化，不是 processor）。

### 17.3 `ICustomComponent` 的实现类与注册表

| 项目 | 位置 | 说明 |
| --- | --- | --- |
| 唯一实现类 | `client/book/template/test/ComponentCustomTest.java` | 测试用实现：`build` 只打印调试日志并记录坐标；`render` 用 `context.getFont()` 作样式绘制文本；`mouseClicked` 打印日志并返回 `false`；`onVariablesAvailable` 把 `"First we eat #spaghet#, then we drink #pop#"` 交给 `lookup` 展开成 `text`（字段 `x`/`y`/`text` 都是 `transient`） |
| 注册/桥接类 | `client/book/template/component/ComponentCustom.java` | **注意：它继承 `TemplateComponent`，本身并不实现 `ICustomComponent`**；它是「模板组件类型 `patchouli:custom`」的载体，用 `@SerializedName("class") String clazz` 反射实例化真正的 `ICustomComponent` |
| 组件类型注册表 | `client/book/template/BookTemplate.java` | `public static final HashMap<ResourceLocation, Class<? extends TemplateComponent>> componentTypes` |

`ComponentCustom` 的关键实现（中文说明）：

```java
public class ComponentCustom extends TemplateComponent {
	@SerializedName("class") String clazz;
	private transient ICustomComponent callbacks;

	@Override
	public void onVariablesAvailable(UnaryOperator<IVariable> lookup, HolderLookup.Provider registries) {
		super.onVariablesAvailable(lookup, registries);
		try {
			Class<?> classObj = Class.forName(clazz);
			callbacks = (ICustomComponent) SerializationUtil.RAW_GSON.fromJson(sourceObject, classObj);
			callbacks.onVariablesAvailable(lookup, registries);
		} catch (Exception e) {
			throw new RuntimeException("Failed to create custom component " + clazz, e);
		}
	}

	@Override public void build(BookContentsBuilder builder, BookPage page, BookEntry entry, int pageNum) { callbacks.build(x, y, pageNum); }
	@Override public void render(GuiGraphics graphics, BookPage page, int mouseX, int mouseY, float pticks) { callbacks.render(graphics, page.parent, pticks, mouseX, mouseY); }
	@Override public void onDisplayed(BookPage page, GuiBookEntry parent, int left, int top) { callbacks.onDisplayed(parent); }
	@Override public boolean mouseClicked(BookPage page, double mouseX, double mouseY, int mouseButton) { return callbacks.mouseClicked(page.parent, mouseX, mouseY, mouseButton); }
}
```

- 实例化路径：`Class.forName(clazz)` + `SerializationUtil.RAW_GSON.fromJson(sourceObject, classObj)`（即把该组件的原始 JSON 对象反序列化成你的 `ICustomComponent` 实现类的实例，因此实现类字段必须可被 Gson 写入，敏感字段应标 `transient`）；创建失败抛 `RuntimeException("Failed to create custom component " + clazz, e)`。
- 回调转接：`build` 传组件坐标 `x, y`；`render` 与 `mouseClicked` 把 `page.parent`（即 `IComponentRenderContext`）作为上下文传入。
- `BookTemplate.componentTypes` 的静态初始化注册了 9 个模板组件类型，全部在 `patchouli` 命名空间：

```java
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "text"), ComponentText.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "item"), ComponentItemStack.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "image"), ComponentImage.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "header"), ComponentHeader.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "separator"), ComponentSeparator.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "frame"), ComponentFrame.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "entity"), ComponentEntity.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "tooltip"), ComponentTooltip.class);
registerComponent(ResourceLocation.fromNamespaceAndPath(PatchouliAPI.MOD_ID, "custom"), ComponentCustom.class);
```

  即 `patchouli:text`、`patchouli:item`、`patchouli:image`、`patchouli:header`、`patchouli:separator`、`patchouli:frame`、`patchouli:entity`、`patchouli:tooltip`、`patchouli:custom`；对外还有 `public static void registerComponent(ResourceLocation name, Class<? extends TemplateComponent> clazz)` 供其它模组注册新的模板组件类型。
- 使用示例（资源文件，已核实）：`Xplat/src/main/resources/assets/patchouli/patchouli_books/comprehensive_test_book/en_us/templates/custom_component.json`
  ```json
  {
    "components": [
      {
        "type": "patchouli:custom",
        "class": "vazkii.patchouli.client.book.template.test.ComponentCustomTest",
        "x": 10,
        "y": 40
      }
    ]
  }
  ```

### 17.4 `IVariableSerializer` 的实现类

| 实现类（相对仓库根） | 处理类型 | 是否被注册 |
| --- | --- | --- |
| `client/book/template/variable/ItemStackVariableSerializer.java` | `ItemStack` | 是（`VariableHelperImpl` 构造器） |
| `client/book/template/variable/ItemStackArrayVariableSerializer.java` | `ItemStack[]` | 是（`VariableHelperImpl` 构造器） |
| `client/book/template/variable/IngredientVariableSerializer.java` | `Ingredient` | 是（`VariableHelperImpl` 构造器） |
| `client/book/template/variable/TextComponentVariableSerializer.java` | `Component` | 是（`VariableHelperImpl` 构造器） |
| `client/book/template/variable/GenericArrayVariableSerializer.java` | 泛型 `T[]`（`implements IVariableSerializer<T[]>`） | 不直接注册，由 `VariableHelperImpl.serializerForClass` 对数组类型**动态构造并缓存** |

`client/book/template/variable/VariableHelperImpl.java` 的注册清单（构造器）：

```java
public VariableHelperImpl() {
	registerSerializer(new ItemStackVariableSerializer(), ItemStack.class);
	registerSerializer(new ItemStackArrayVariableSerializer(), ItemStack[].class);
	registerSerializer(new IngredientVariableSerializer(), Ingredient.class);
	registerSerializer(new TextComponentVariableSerializer(), Component.class);
}

public Map<Class<?>, IVariableSerializer<?>> serializers = new HashMap<>();

@Override
public <T> IVariableSerializer<T> serializerForClass(Class<T> clazz) {
	IVariableSerializer<T> serializer = (IVariableSerializer<T>) serializers.get(clazz);
	if (serializer == null && clazz.isArray()) {
		Class<?> componentType = clazz.getComponentType();
		IVariableSerializer<?> componentSerializer = serializerForClass(componentType);
		if (componentSerializer != null) {
			IVariableSerializer<T> arraySerializer = (IVariableSerializer<T>) new GenericArrayVariableSerializer(componentSerializer, componentType);
			serializers.put(clazz, arraySerializer);   // 动态生成后写回映射缓存
			return arraySerializer;
		}
	}
	return serializer;
}

@Override
public <T> IVariable createFromObject(T object, HolderLookup.Provider registries) {
	Class<?> clazz = object.getClass();
	for (Entry<Class<?>, IVariableSerializer<?>> e : serializers.entrySet()) {
		if (e.getKey().isAssignableFrom(clazz)) {
			return create(((IVariableSerializer<T>) e.getValue()).toJson(object, registries), clazz, registries);
		}
	}
	throw new IllegalArgumentException(String.format("Can't serialize object %s of type %s to IVariable", object, clazz));
}
```

各序列化器行为细节（全部为读源码所得，非推测）：

- **`GenericArrayVariableSerializer<T>`**
  - 字段：`protected final T[] empty`（由 `Array.newInstance(type, 0)` 生成的空数组模板，用于 `toArray`）、`private final IVariableSerializer<T> inner`。
  - `fromJson`：若 JSON 是数组，逐个元素交给 `inner.fromJson`，收集为 `List<T>` 后 `toArray(empty)`；**若不是数组则抛 `IllegalArgumentException("Can't create an array of objects from a non-array JSON!")`**。
  - `toJson`：输出 `JsonArray`，每个元素由 `inner.toJson` 生成。
  - 用途：为任意已注册内部序列化器的类型自动提供 `T[]` 支持（例如 `Ingredient[]`、`Component[]` 之类，无需显式注册）。

- **`ItemStackArrayVariableSerializer extends GenericArrayVariableSerializer<ItemStack>`**
  - 构造器：`super(new ItemStackVariableSerializer(), ItemStack.class)`。
  - 重写 `fromJson` 以放宽格式：若 JSON 是数组，则对每个元素调用 `fromNonArray` 并把结果**展平（flatten，`addAll`）**后合并为一个数组；若不是数组则直接 `fromNonArray`。
  - `fromNonArray(JsonElement, HolderLookup.Provider)`：
    - `JsonNull` → 返回空数组 `empty`；
    - 字符串（primitive）→ `ItemStackUtil.loadStackListFromString(json.getAsString(), registries).toArray(empty)`（即一个字符串可展开成**多个**物品堆，例如逗号分隔列表）；
    - JSON 对象 → 单元素数组 `{ ItemStackUtil.loadStackFromJson(...) }`；
    - JSON 数组 → 抛 `IllegalArgumentException("Can't make an ItemStack from an array!")`（此分支在正常流程中不可达，因为 `fromJson` 已先筛出数组）。
  - `toJson` 未重写，沿用父类（逐元素用 `ItemStackVariableSerializer.toJson`）。

- **`IngredientVariableSerializer implements IVariableSerializer<Ingredient>`**
  - `fromJson`：**字符串（primitive）** → `ItemStackUtil.loadIngredientFromString(json.getAsString(), registries)`（支持 Patchouli 的简写语法）；否则用 `Ingredient.CODEC.parse(registries.createSerializationContext(JsonOps.INSTANCE), json).result().orElseThrow()`（数据包式 JSON，失败直接抛）。
  - `toJson`：`Ingredient.CODEC.encodeStart(registries.createSerializationContext(JsonOps.INSTANCE), stack).result().orElseThrow()`。

- **`ItemStackVariableSerializer implements IVariableSerializer<ItemStack>`**
  - `fromJson`：`JsonNull` → `ItemStack.EMPTY`；**字符串** → `ItemStackUtil.loadStackFromString(...)`；**JSON 对象** → `ItemStackUtil.loadStackFromJson(...)`；**数组** → 抛 `IllegalArgumentException("Can't make an ItemStack from an array!")`。
  - `toJson`：生成 `JsonObject`，写 `"item"`（`BuiltInRegistries.ITEM.getKey(stack.getItem()).toString()`）；当 `count != 1` 时写 `"count"`；当 `!stack.getComponents().isEmpty()` 时用 `DataComponentMap.CODEC` 编码后写入 `"components"`。源码注释注明「改编自 net.minecraftforge.common.crafting.StackList::toJson」。

- **`TextComponentVariableSerializer implements IVariableSerializer<Component>`**
  - `fromJson`：`JsonNull` → `Component.literal("")`；**字符串** → `Component.literal(json.getAsString())`（注意：字符串被当作纯文本，**不会**按 JSON 文本组件解析）；其它情况 → `Component.Serializer.fromJson(json, registries)`（接受完整的文本组件 JSON）。
  - `toJson`：`ComponentSerialization.CODEC.encodeStart(...).getOrThrow(JsonParseException::new)`。

### 17.5 其余接口的实现方（一并列出，均经 grep 核实）

| 接口 | 实现类（相对仓库根） | 备注 |
| --- | --- | --- |
| `VariableHelper` | `client/book/template/variable/VariableHelperImpl.java`；另有 `VariableHelper.java` 内匿名空实现 `new VariableHelper() {}`（反射失败时的保底） | `@SuppressWarnings` 处理泛型强转 |
| `IVariable` | `client/book/template/variable/Variable.java`（**唯一**实现） | 字段 `JsonElement value`、`@Nullable Class<?> sourceClass`、`HolderLookup.Provider registries`；`as(clazz)` 经 `VariableHelper.instance().serializerForClass(clazz)`，**未注册时抛 `IllegalArgumentException("Can't deserialize object of class %s from IVariable")`**（与接口 javadoc 「return null」的措辞不一致，实际以实现为准）；另定义了 `toString()` 返回 `value.toString()` |
| `IVariableProvider` | `client/book/template/JsonVariableWrapper.java`（JSON 顶层对象）；`client/book/template/TemplateInclusion.java` 的 `wrapProvider(IVariableProvider)` 返回匿名实现（优先查本地 `using` 绑定，再按限定名回落到上层 provider） | `JsonVariableWrapper.get` 找不到键时抛 `IllegalArgumentException("Attempted to get variable " + key + " when it's not present")`；`has` 直接委托 `JsonObject.has` |
| `IVariablesAvailableCallback` | 抽象基类 `client/book/template/TemplateComponent.java`（`implements IVariablesAvailableCallback`）及其全部具体子类：`component/ComponentText`、`ComponentItemStack`、`ComponentImage`、`ComponentHeader`、`ComponentSeparator`、`ComponentFrame`、`ComponentEntity`、`ComponentTooltip`、`ComponentCustom`；以及 `test/ComponentCustomTest`（经 `ICustomComponent` 继承） | 调用入口是 `VariableAssigner.assignVariableHolders(...)` |
| `IMultiblock` | `common/multiblock/AbstractMultiblock.java`（`implements IMultiblock, BlockAndTintGetter`）→ 子类 `common/multiblock/DenseMultiblock.java`、`common/multiblock/SparseMultiblock.java`；`api/stub/StubMultiblock.java` | 工厂入口在 `PatchouliAPI.IPatchouliAPI#makeMultiblock/makeSparseMultiblock`（实现类 `common/base/PatchouliAPIImpl.java`） |
| `IMultiblock.SimulateResult` | `common/multiblock/SimulateResultImpl.java` | — |
| `IStateMatcher` | `common/multiblock/StateMatcher.java`（含常量 `ANY`、`AIR` 与一组 `fromPredicate`/`fromState`/`displayOnly`/`fromBlockLoose`/`fromBlockStrict` 工厂）；`common/multiblock/StringStateMatcher.java` 的私有静态内部类 `ExactMatcher`、`TagMatcher`；`api/stub/StubMatcher.java` | 解析字符串式多方块定义（dense 的字符映射） |
| `IStyleStack` | `client/book/text/SpanState.java`（**唯一**实现） | `popStyle()` 在 `stateStack.size() <= 1` 时抛 `IllegalStateException("Underflow in style stack")`；`pushStyle` 用 `style.applyTo(peekStyle())` 合并；对外经 `PatchouliAPIImpl.registerCommand/registerFunction` 暴露（`api/PatchouliAPI.java` 第 145、155 行） |
| `TriPredicate<A,B,C>` | 无具名实现类 | 以 lambda / 方法引用形式被 `StateMatcher`、`StringStateMatcher.ExactMatcher/TagMatcher`、`StubMatcher` 等返回，并被 `AbstractMultiblock`、`StateMatcher` 使用 |

---

## 18. 变量解析链路（有助于理解上述接口的实际语义）

`client/book/template/VariableAssigner.java`（已通读）中的关键事实：

- `INLINE_VAR_PATTERN = Pattern.compile("([^#]*)(#[^#]+)#(.*)")` —— `#var#` 内联变量；`FUNCTION_PATTERN = Pattern.compile("(.+)->(.+)")` —— `arg->func` 派生。
- 内建派生函数表 `FUNCTIONS` 共 13 个：`iname`、`icount`、`ename`、`lower`、`upper`、`trim`、`capital`、`fcapital`、`i18n`、`exists`、`iexists`、`inv`、`stacks`。
- `assignVariableHolders(Level, IVariablesAvailableCallback, IVariableProvider, IComponentProcessor, TemplateInclusion)` 构造的 `lookup`：输入 `null` → `IVariable.empty()`；输入是 JSON 字符串 → 走 `resolveString`（先反复展开 `#var#`，再走函数派生）；其它类型原样返回。
- **`processor.process(level, key)` 的调用点唯一**：`resolveStringVar` 中，当变量名以 `#` 开头时——
  1. 若在包含（include）上下文中，先 `encapsulation.attemptVariableLookup(...)`；
  2. 否则/失败时 `c.processor.process(level, originalKey)`；
  3. **仅当 processor 返回 `null` 时**才回退到 `c.variables.get(key, ...)`；
  4. 仍未取到则返回 `IVariable.empty()`。
- `Context` 内部有 `Map<String, IVariable> cachedVars` 缓存解析结果。

---

## 19. 未能核实项（明确列出检查过的位置）

1. **`ProcessorMacros` / `ProcessorFlags` / `patchouli:macros` / `patchouli:flags`**：未能核实。
   检查位置：`Xplat/src/main/java` 全量 grep（`ProcessorMacros|ProcessorFlags|interface Processor`）→ 0 匹配；仓库根全量 grep（含资源与文档）→ 仅 `"processor"` 字段相关 4 处；`client/book/template/` 全部 24 个 `.java` 逐文件列举 → 无相关类；`web/docs/patchouli-advanced/component-processors.md` → 只描述 FQCN 方式。结论：本 tag 中 `IComponentProcessor` **没有** ResourceLocation 型 type id 注册机制。
2. **本包是否存在成文的 API 稳定性契约**：未能核实。`api/package-info.java` 仅有 `@net.minecraft.MethodsReturnNonnullByDefault` 一行注解，无文字说明；全仓库 grep（`stabilit|API is stable|breaking change|backwards compat`）无匹配。
3. **TFC 侧的 Patchouli 集成实现类**（例如 `net.dries007.tfc.compat.patchouli.component.SimpleItemRecipeComponent`，被 Firmalife 的 `DryingComponent`/`SmokingComponent` 继承）：未能核实。`src-ref/TerraFirmaCraft` 目录**已检出但工作树为空**（目录内只有一个 `.git`，`git status` 报 `No commits yet`），因此无法读取 TFC 源码；`src-ref` 全量 grep 中不存在 `SimpleItemRecipeComponent` 的定义，只有 Firmalife 的两处 import 引用。
4. **Firmalife 是否直接实现本包接口**：已核实为**否**。`src-ref/Firmalife` 目录中 `grep "implements (IComponentProcessor|ICustomComponent|IStateMatcher|IMultiblock|IVariableSerializer)|registerSerializer\("` 无任何匹配；其 `compat/patchouli/` 下只有 `DryingComponent`、`SmokingComponent`、`FLPatchouliIntegration`、`package-info` 四个文件，前两者继承 TFC 的抽象基类而非直接实现本包接口。
5. **`IVariable.as(Class)` 的 javadoc 与实现不一致**：javadoc 说「未注册序列化器时返回 `null`」，而唯一实现 `Variable.as` 实际抛 `IllegalArgumentException`。此为源码事实，非推测（勿依赖 javadoc 的 null 语义）。
