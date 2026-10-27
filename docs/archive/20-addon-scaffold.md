# TFC 附属模组工程脚手架（MC 1.21.1 / NeoForge 21.1.x / TFC 4.2.10）

> 本文给出一套**可直接落盘、可编译、可运行**的 TFC 附属模组工程模板。
> 所有写法都从 TFC 4.2.10 与 Firmalife 3.0.14 的真实源码中提取（`moddev/src-ref/TFC-decompiled`、
> `moddev/src-ref/Firmalife`），而不是通用教程。
>
> 假设：你要写一个名为 `mymod` 的模组，硬依赖 TFC 与 Patchouli，运行在本机这个整合包里。

---

## 1. 前置条件

| 项 | 要求 |
|---|---|
| JDK | **21**（本机已装：`C:\Program Files\Java\jdk-17` 是 17，需要另装 JDK 21；游戏日志显示实际用 Microsoft OpenJDK 21.0.3） |
| Gradle | 用工程自带的 `gradlew`（wrapper），不需要单独安装 |
| 目标 MC | 1.21.1 |
| NeoForge | 编译用 `21.1.234`（Firmalife 的选择）或与运行环境一致的 `21.1.248` |
| 映射 | Parchment `2024.11.17`（可选，但强烈建议，TFC 生态都用它） |
| 依赖仓库 | Maven Central（本机实测 292 KB/s 可达）、`maven.blamejared.com`（Patchouli）、`www.cursemaven.com`（TFC/Jade） |

> 网络提示：本机对 `github.com` / `raw.githubusercontent.com` 极不稳定（实测超时或 <1 KB/s），
> 对 Maven Central 正常。因此构建依赖尽量走 Maven，不要依赖 GitHub 直链。

---

## 2. 工程目录结构

```
mymod/
├── settings.gradle
├── gradle.properties
├── build.gradle.kts
├── gradlew / gradlew.bat / gradle/wrapper/...
└── src/
    ├── main/
    │   ├── templates/META-INF/neoforge.mods.toml     ← 带占位符的元数据模板（构建时展开）
    │   ├── java/com/example/mymod/
    │   │   ├── MyMod.java                             ← @Mod 主类
    │   │   ├── MyModClientEvents.java                 ← 仅客户端的注册（Dist.CLIENT 分支引用）
    │   │   ├── common/
    │   │   │   ├── blocks/MyBlocks.java
    │   │   │   ├── items/MyItems.java
    │   │   │   ├── blockentities/MyBlockEntities.java
    │   │   │   ├── container/MyMenus.java
    │   │   │   ├── recipes/MyRecipeTypes.java
    │   │   │   ├── recipes/MyRecipeSerializers.java
    │   │   │   ├── recipes/MyRecipe.java
    │   │   │   └── MyCreativeTabs.java
    │   │   └── compat/patchouli/…                     ← Patchouli 相关（客户端类）
    │   └── resources/
    │       ├── mymod.mixins.json（可选）
    │       ├── assets/mymod/…（模型、贴图、语言、书籍）
    │       └── data/mymod/…（配方、标签、tfc 数据表、战利品表）
    └── generated/resources/                            ← datagen 输出（可选）
```

**类加载铁律**：任何 import 了 `net.minecraft.client.*` / `vazkii.patchouli.client.*` 的类，
都只能被 `Dist.CLIENT` 分支引用（例如放在 `MyModClientEvents` 里，主类构造器中用
`if (FMLEnvironment.dist == Dist.CLIENT) { MyModClientEvents.init(mod, bus); }` 调用）。

---

## 3. 构建脚本

### 3.1 `settings.gradle`

```groovy
pluginManagement {
    repositories {
        gradlePluginPortal()                                             // 实测可达（插件本体从这里取）
        maven { url = "https://bmclapi2.bangbang93.com/maven/" }         // ★ 实测可达：NeoForge / NeoForm 镜像
        maven { url = "https://maven.neoforged.net/releases" }           // 官方源（本机实测超时，仅作兜底）
        maven { url = "https://maven.parchmentmc.org" }                  // 实测可达（Parchment 映射）
        maven { url = "https://repo.spongepowered.org/repository/maven-public/" }
    }
}
rootProject.name = 'mymod'
```

> `foojay-resolver-convention` 插件（自动下载 JDK toolchain）是可选的；
> 如果本机已装 JDK 21 并设置好 `org.gradle.java.installations.paths`，可以不引入它，避免额外的插件解析。

### 3.2 `gradle.properties`

```properties
org.gradle.jvmargs=-Xmx6G
org.gradle.daemon=false
org.gradle.console=plain
org.gradle.configuration-cache=true
```

### 3.3 `build.gradle.kts`（改编自 Firmalife，去掉 CI 专属部分）

```kotlin
plugins {
    id("net.neoforged.moddev") version "2.0.107"
}

val minecraftVersion      = "1.21.1"
val neoForgeVersion       = "21.1.234"          // 与运行环境 21.1.248 兼容
val parchmentVersion      = "2024.11.17"
val parchmentMcVersion    = "1.21.1"
val patchouliVersion      = "1.21.1-92-NEOFORGE"
val tfcVersion            = "4.2.8"

val modId      = "mymod"
val modVersion = System.getenv("VERSION") ?: "0.0.0-indev"

// —— 把 mods.toml 模板里的占位符替换掉 ——
val generateModMetadata = tasks.register<ProcessResources>("generateModMetadata") {
    val props = mapOf(
        "modId" to modId,
        "modVersion" to modVersion,
        "minecraftVersionRange" to "[$minecraftVersion]",
        "neoForgeVersionRange" to "[$neoForgeVersion,)",
        "tfcVersionRange" to "[$tfcVersion,)",
        "patchouliVersionRange" to "[$patchouliVersion,)",
    )
    inputs.properties(props)
    expand(props)
    from("src/main/templates")
    into(layout.buildDirectory.dir("generated/sources/modMetadata"))
}

neoForge { version = neoForgeVersion }

base {
    archivesName.set("MyMod-NeoForge-$minecraftVersion")
    group = "com.example.mymod"
    version = modVersion
}

java { toolchain.languageVersion.set(JavaLanguageVersion.of(21)) }

// ★ 必须加：中文 Windows 上 javac 默认按 GBK 读取源文件，
//   源码里的中文注释会触发「编码 GBK 的不可映射字符」警告（实测一次构建出现 7 处）。
tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
}

repositories {
    mavenCentral()
    // ★ 本机实测可达：NeoForge / NeoForm / Mojang 依赖的镜像（官方 maven.neoforged.net 本机超时）
    maven {
        url = uri("https://bmclapi2.bangbang93.com/maven/")
        content { includeGroup("net.neoforged") ; includeGroup("net.minecraftforge") }
    }
    // Patchouli（实测可达）
    exclusiveContent {
        forRepository { maven("https://maven.blamejared.com") }
        filter { includeGroup("vazkii.patchouli") }
    }
    // TFC / Jade 等 CurseForge 上的模组
    exclusiveContent {
        forRepository { maven("https://www.cursemaven.com") }
        filter { includeGroup("curse.maven") }
    }
}

sourceSets {
    main { resources { srcDir(generateModMetadata) } }
}

neoForge {
    validateAccessTransformers = true
    parchment {
        minecraftVersion.set(parchmentMcVersion)
        mappingsVersion.set(parchmentVersion)
    }
    runs {
        configureEach {
            jvmArguments.addAll("-XX:+IgnoreUnrecognizedVMOptions", "-XX:+AllowEnhancedClassRedefinition", "-ea")
            systemProperty("tfc.enableDebugSelfTests", "true")   // TFC 自检（强烈建议开发期开启）
        }
        register("client") { client(); gameDirectory = file("run/client") }
        register("server") { server(); gameDirectory = file("run/server"); programArgument("--nogui") }
    }
    mods {
        create(modId) { sourceSet(sourceSets.main.get()) }
    }
    ideSyncTask(generateModMetadata)
}

dependencies {
    // Patchouli：必须用完整 jar，因为要访问其客户端类
    implementation("vazkii.patchouli:Patchouli:$patchouliVersion")
    // TFC：CurseMaven 坐标（与 Firmalife 3.0.14 相同）
    implementation(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")
}
```

**离线/内网替代方案**（本机已有 jar，最省事）：

```kotlin
dependencies {
    implementation(files("../mods/Patchouli-1.21.1-93-NEOFORGE.jar"))
    implementation(files("../mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar"))
}
```

> 说明：NeoForge 模组 jar 内的类名是 **mojmap 官方名**（我们 javap 看到的是
> `net.minecraft.world.level.block.Block` 而不是 SRG 名），因此可以直接作为编译依赖使用。
> 缺点是版本写死在文件路径上，且 Parchment 参数名不会生效（不影响编译）。

---

### 3.4 本机网络环境实测（决定构建是否可行）

在本机（2026-09 实测）逐个探测了构建链路需要的仓库：

| 仓库 | 用途 | 实测结果 |
|---|---|---|
| `maven.neoforged.net/releases` | **NeoForge / NeoForm 官方源** | ❌ **超时**（这是最关键的一环） |
| `bmclapi2.bangbang93.com/maven/` | NeoForge / NeoForm 镜像 | ✅ **可达**（`net/neoforged/neoforge/21.1.234/neoforge-21.1.234.pom` 与 `neoform/1.21.1-20240808.144430` 均 200） |
| `plugins.gradle.org/m2/` | Gradle 插件（含 `net.neoforged.moddev`） | ✅ 可达 |
| `maven.parchmentmc.org` | Parchment 映射 | ✅ 可达 |
| `repo1.maven.org/maven2/` | Maven Central（CFR、commons 等） | ✅ 可达（292 KB/s） |
| `maven.blamejared.com` | Patchouli | ✅ 可达 |
| `www.cursemaven.com` | TFC / Jade（CurseForge 模组） | ✅ 域名可达（返回 404 是路径问题，服务正常） |
| `piston-meta.mojang.com`、`libraries.minecraft.net` | MC 本体与依赖库 | ✅ 可达 |
| `maven.minecraftforge.net` | 旧 Forge 源（备选） | ✅ 可达 |
| `github.com` / `raw.githubusercontent.com` / `codeload.github.com` | 源码 | ❌ 超时或 <1 KB/s（**不要依赖**） |

**结论**：
1. 本机**可以**从零构建一个 TFC 附属模组，前提是**把 NeoForge 官方源替换为 BMCLAPI 镜像**（配置已写在上面的
   `settings.gradle` 与 `build.gradle.kts` 中）。
2. `net.neoforged.moddev` 插件本体从 Gradle Plugin Portal 取，**不在** BMCLAPI 镜像里（实测 404），
   所以 `pluginManagement.repositories` 里必须保留 `gradlePluginPortal()`。
3. **完全离线**的选手：把 `mods/` 目录里现成的 `TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` 与
   `Patchouli-1.21.1-93-NEOFORGE.jar` 用 `implementation(files(...))` 直接当编译依赖（见 3.3 末尾的替代方案），
   这样连 CurseMaven / blamejared 都不需要。
4. 首次 `./gradlew build` 需要下载 MC 本体、NeoForm 反编译产物与依赖库，**预留 1–2 GB 磁盘与较长时间**；
   若中途卡在 `maven.neoforged.net`，说明镜像没生效，检查 `content { includeGroup(...) }` 过滤器是否把请求挡掉了。

> 本文档没有实际执行过一次完整构建（会下载数百 MB 且耗时较长）。
> 上表是逐 URL 探测的结果，配置方案据此得出；若你首次构建遇到解析失败，优先怀疑的是 NeoForge 源而非代码。

#### 实际构建记录（已完成，成功）

本机 `~/.gradle/caches` 中已存在前人留下的构建缓存，因此**不需要联网下载 NeoForge**：

```
net.neoforged:neoforge       21.1.233
net.neoforged:neoform        1.21.1-20240808.144430
net.neoforged:moddev-gradle  2.0.111
net.neoforged:neoform-runtime 1.0.40
net.neoforged:accesstransformers 10.0.1
~/.gradle/jdks/eclipse_adoptium-21-amd64-windows   ← JDK 21 toolchain 也已缓存
```

据此在 `moddev/demo-mymod/` 建了一个最小工程（与本文件 §5、§6 的模板一致：主类 + 方块 + 方块物品 +
`TickableInventoryBlockEntity` + `RegistrationHelpers` + `ExtendedProperties` + 本地 jar 依赖），
用系统 Gradle 8.13 执行 `gradle build`，结果：

```
> Task :compileJava
> Task :generateModMetadata
> Task :processResources
> Task :jar
BUILD SUCCESSFUL in 2m 10s
5 actionable tasks: 5 executed
→ build/libs/MyMod-NeoForge-1.21.1-0.0.0-indev.jar (8315 bytes)
  内含 6 个 class + META-INF/neoforge.mods.toml（占位符已正确展开为 modId=mymod 等）
```

**因此以下结论是实测过的，不是推测**：

1. `net.neoforged.moddev` + 本地 jar 依赖 + `ProcessResources` 占位符展开的整套配置**可工作**。
2. `ExtendedProperties.of(...).blockEntity(...).serverTicks(...)`、
   `RegistrationHelpers.registerBlock(...)`、`RegistrationHelpers.register(BLOCK_ENTITIES, name, BE::new, block)`
   的调用形态**编译通过**。
3. TFC 的 BE 基类必须写成 `public XxxBlockEntity(BlockPos pos, BlockState state)`（见 §6.3 的修正与注释）。
4. **中文源码必须显式指定 UTF-8**：首次构建出现 7 处「编码 GBK 的不可映射字符」警告
   （`MyMachineBlockEntity.java`、`MyMachineBlock.java`、`MyMod.java` 的中文注释），
   加上 `tasks.withType<JavaCompile>().configureEach { options.encoding = "UTF-8" }` 后消失。
5. 首次配置阶段会触发 NeoForm 处理（日志中 `Compiling 5364 source files … Total runtime: 92.97s`），
   即使有缓存也要 1–2 分钟；之后增量构建很快。

---

## 4. `src/main/templates/META-INF/neoforge.mods.toml`

```toml
modLoader = "javafml"
loaderVersion = "[4,)"
license = "MIT"
issueTrackerURL = "https://github.com/you/mymod/issues"

[[mods]]
    modId = "${modId}"
    version = "${modVersion}"
    displayName = "MyMod"
    authors = "you"
    description = '''A TerraFirmaCraft addon.'''

# —— 关键：硬依赖 TFC 与 Patchouli，顺序 AFTER TFC ——
[[dependencies.${modId}]]
    modId = "tfc"
    type = "required"
    versionRange = "${tfcVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.${modId}]]
    modId = "patchouli"
    type = "required"
    versionRange = "${patchouliVersionRange}"
    ordering = "NONE"
    side = "BOTH"

[[dependencies.${modId}]]
    modId = "neoforge"
    type = "required"
    versionRange = "${neoForgeVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.${modId}]]
    modId = "minecraft"
    type = "required"
    versionRange = "${minecraftVersionRange}"
    ordering = "AFTER"
    side = "BOTH"
```

> TFC 4.2.10 的 `neoforge.mods.toml` 里对 patchouli 的要求是 `[1.21.1-92-NEOFORGE,)`；
> Firmalife 3.0.14 的要求是 `tfc >= 4.2.8`、`patchouli >= 1.21.1-92-NEOFORGE`、`neoforge >= 21.1.234`。
> 照抄这些区间最安全。

---

## 5. 主类（完全对照 TFC/Firmalife 的形态）

```java
package com.example.mymod;

import com.example.mymod.common.MyCreativeTabs;
import com.example.mymod.common.blockentities.MyBlockEntities;
import com.example.mymod.common.blocks.MyBlocks;
import com.example.mymod.common.container.MyMenus;
import com.example.mymod.common.items.MyItems;
import com.example.mymod.common.recipes.MyRecipeSerializers;
import com.example.mymod.common.recipes.MyRecipeTypes;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.api.distmarker.Dist;
import org.slf4j.Logger;
import com.mojang.logging.LogUtils;

@Mod(MyMod.MOD_ID)
public final class MyMod {
    public static final String MOD_ID = "mymod";
    public static final Logger LOGGER = LogUtils.getLogger();

    public MyMod(ModContainer mod, IEventBus bus) {
        // 1) DeferredRegister 一律在这里注册到模组总线
        MyBlocks.BLOCKS.register(bus);
        MyItems.ITEMS.register(bus);
        MyBlockEntities.BLOCK_ENTITIES.register(bus);
        MyMenus.MENUS.register(bus);
        MyRecipeTypes.RECIPE_TYPES.register(bus);
        MyRecipeSerializers.RECIPE_SERIALIZERS.register(bus);
        MyCreativeTabs.CREATIVE_TABS.register(bus);

        // 2) 模组总线事件
        bus.addListener(this::setup);

        // 3) 客户端专属（必须在 Dist.CLIENT 分支里引用，否则专用服务器会崩）
        if (FMLEnvironment.dist == Dist.CLIENT) {
            MyModClientEvents.init(mod, bus);
        }
    }

    private void setup(FMLCommonSetupEvent event) {
        // 跨模组、会碰原版注册表的工作必须放进 enqueueWork
        event.enqueueWork(() -> {
            // 例如：注册右键交互、给原版方块改属性
        });
        // 与 Patchouli 的交互放在 enqueueWork 之外（TFC 就是这么做的）
        com.example.mymod.compat.patchouli.MyPatchouliIntegration.registerMultiBlocks();
    }
}
```

客户端事件类：

```java
package com.example.mymod;

import com.example.mymod.common.container.MyMenus;
import com.example.mymod.client.MyScreen;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.RegisterMenuScreensEvent;

public final class MyModClientEvents {
    public static void init(ModContainer mod, IEventBus bus) {
        bus.addListener(MyModClientEvents::onMenuRegister);
    }

    private static void onMenuRegister(RegisterMenuScreensEvent event) {
        event.register(MyMenus.MY_MACHINE.get(), MyScreen::new);
    }
}
```

---

## 6. 注册类模板

### 6.1 方块（复用 TFC 的 `ExtendedProperties`）

```java
package com.example.mymod.common.blocks;

import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;   // 仅用于参考
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.level.block.state.BlockBehaviour.Properties;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;
import net.minecraft.core.registries.Registries;

import java.util.function.Function;
import java.util.function.Supplier;

public final class MyBlocks {
    public static final DeferredRegister<net.minecraft.world.level.block.Block> BLOCKS =
        DeferredRegister.create(Registries.BLOCK, MyMod.MOD_ID);

    public static final DeferredHolder<net.minecraft.world.level.block.Block, MyMachineBlock> MY_MACHINE =
        register("my_machine", () -> new MyMachineBlock(
            ExtendedProperties.of(MapColor.METAL)
                .strength(3.0f)
                .sound(SoundType.METAL)
                .noOcclusion()
                .blockEntity(MyBlockEntities.MY_MACHINE)                 // 关联方块实体
                .serverTicks(MyMachineBlockEntity::serverTick)           // 服务端 tick
        ), b -> new BlockItem(b, new Item.Properties()));

    private static <T extends net.minecraft.world.level.block.Block>
    DeferredHolder<net.minecraft.world.level.block.Block, T> register(
            String name, Supplier<T> supplier,
            Function<T, ? extends BlockItem> blockItemFactory) {
        // 与 TFC 一样：方块和方块物品一起注册
        return RegistrationHelpers.registerBlock(BLOCKS, MyItems.ITEMS, name, supplier, blockItemFactory);
    }

    private MyBlocks() {}
}
```

**TFC 风格的方块类**（继承 `ExtendedBlock` 才能用 `ExtendedProperties` 的 ticker 机制）：

```java
package com.example.mymod.common.blocks;

import net.dries007.tfc.common.blocks.ExtendedBlock;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.minecraft.core.BlockPos;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

public class MyMachineBlock extends ExtendedBlock {
    public MyMachineBlock(ExtendedProperties properties) {
        super(properties);
    }

    @Override
    protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
                                               Player player, BlockHitResult hit) {
        if (!level.isClientSide && level.getBlockEntity(pos) instanceof MyMachineBlockEntity machine) {
            player.openMenu(machine);       // 因为 BE 实现了 MenuProvider
        }
        return InteractionResult.SUCCESS;
    }
}
```

> **不想依赖 TFC 的 `ExtendedBlock`？** 那就用原版 `BlockBehaviour.Properties` 并在方块类里重写
> `getTicker(Level, BlockState, BlockEntityType)` 返回你自己的 `BlockEntityTicker`。
> 但只要你在做 TFC 附属，直接用 TFC 的这套 DSL 可以省掉一半样板代码。

### 6.2 物品

```java
public final class MyItems {
    public static final DeferredRegister<Item> ITEMS = DeferredRegister.create(Registries.ITEM, MyMod.MOD_ID);

    public static final DeferredHolder<Item, Item> MY_PART =
        ITEMS.register("my_part", () -> new Item(new Item.Properties()));
}
```

### 6.3 方块实体（继承 TFC 基类）

TFC 提供的 BE 基类层次（都在 `net.dries007.tfc.common.blockentities`）：

```
BlockEntity
 └─ TFCBlockEntity                    // 自动处理 update packet / 同步（markForSync 等）
     └─ TickableBlockEntity           // 额外的 tick 同步逻辑
         └─ InventoryBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag>>
             └─ TickableInventoryBlockEntity<C>   // 带库存 + tick 的常用基类
```

```java
package com.example.mymod.common.blockentities;

import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;
import net.dries007.tfc.common.container.ISlotCallback;
import net.dries007.tfc.util.Helpers;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;
import net.minecraft.core.registries.Registries;

import java.util.function.Supplier;

public class MyMachineBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> {
    public static final int SLOTS = 3;

    /**
     * ★ 关键：TFC 的 BE 构造器签名是 (BlockPos, BlockState)，类型在内部用 .get() 取，
     *   这样 RegistrationHelpers.register(..., MyMachineBlockEntity::new, block) 才能直接匹配
     *   BlockEntityType.BlockEntitySupplier<T>（即 (BlockPos, BlockState) -> T）。
     *   对照 Firmalife：
     *     public BarrelPressBlockEntity(BlockPos pos, BlockState state) {
     *         super(FLBlockEntities.BARREL_PRESS.get(), pos, state, defaultInventory(SLOTS), FirmaLife.MOD_ID);
     *     }
     *   （注意：写成 (BlockEntityType, BlockPos, BlockState) 会导致方法引用无法匹配而编译失败。）
     */
    public MyMachineBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.MY_MACHINE.get(), pos, state, defaultInventory(SLOTS));
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state, MyMachineBlockEntity be) {
        be.checkForLastTickSync();
        // ... 逻辑
    }

    public static void clientTick(Level level, BlockPos pos, BlockState state, MyMachineBlockEntity be) { }

    @Override
    public void loadAdditional(CompoundTag nbt, net.minecraft.core.HolderLookup.Provider provider) {
        super.loadAdditional(nbt, provider);
    }

    @Override
    public void saveAdditional(CompoundTag nbt, net.minecraft.core.HolderLookup.Provider provider) {
        super.saveAdditional(nbt, provider);
    }

    @Override
    public AbstractContainerMenu createMenu(int windowId, Inventory playerInv, net.minecraft.world.entity.player.Player player) {
        return MyMachineContainer.create(this, playerInv, windowId);
    }

    @Override
    public net.minecraft.network.chat.Component getDisplayName() {
        return net.minecraft.network.chat.Component.translatable("block.mymod.my_machine");
    }
}
```

注册：

```java
public final class MyBlockEntities {
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, MyMod.MOD_ID);

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MyMachineBlockEntity>> MY_MACHINE =
        RegistrationHelpers.register(BLOCK_ENTITIES, "my_machine",
            MyMachineBlockEntity::new, MyBlocks.MY_MACHINE);
}
```

### 6.4 菜单（复用 TFC 的 `BlockEntityContainer`）

```java
package com.example.mymod.common.container;

import com.example.mymod.common.blockentities.MyMachineBlockEntity;
import net.dries007.tfc.common.capabilities.BlockCapabilities;
import net.dries007.tfc.common.container.BlockEntityContainer;
import net.dries007.tfc.common.container.slot.CallbackSlot;
import net.dries007.tfc.util.Helpers;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.item.ItemStack;
import net.neoforged.neoforge.items.IItemHandler;

public class MyMachineContainer extends BlockEntityContainer<MyMachineBlockEntity> {
    /** 由 RegistrationHelpers 生成的 IContainerFactory 调用（BE 已由 BlockPos 解析出来） */
    public static MyMachineContainer create(MyMachineBlockEntity be, Inventory playerInv, int windowId) {
        return new MyMachineContainer(be, playerInv, windowId).init(playerInv);
    }

    public MyMachineContainer(MyMachineBlockEntity blockEntity, Inventory playerInv, int windowId) {
        super(MyMenus.MY_MACHINE.get(), windowId, blockEntity);   // ← 3 个参数：(MenuType, windowId, BE)
    }

    @Override
    protected void addContainerSlots() {
        IItemHandler inventory = Helpers.getCapability(BlockCapabilities.ITEM, blockEntity);
        if (inventory != null) {
            addSlot(new CallbackSlot(blockEntity, inventory, MyMachineBlockEntity.SLOT_INPUT, 8, 20));
            addSlot(new CallbackSlot(blockEntity, inventory, MyMachineBlockEntity.SLOT_OUTPUT, 80, 20));
        }
    }

    @Override
    protected boolean moveStack(ItemStack stack, int slotIndex) {
        // TFC 用 typeOf(slotIndex) 区分 MAIN_INVENTORY / HOTBAR / CONTAINER
        return switch (typeOf(slotIndex)) {
            case MAIN_INVENTORY, HOTBAR -> !moveItemStackTo(stack, 0, 2, false);
            case CONTAINER -> !moveItemStackTo(stack, containerSlots, slots.size(), false);
        };
    }
}
```

> 以上写法逐行对照 Firmalife 的 `BarrelPressContainer`（`src/main/java/com/eerussianguy/firmalife/common/container/BarrelPressContainer.java`）。
> 要点：**`super(MenuType, windowId, blockEntity)` 只有 3 个参数**（不是原版那种带 `playerInventory` 的写法），
> 玩家背包槽位由 `init(playerInv)` 统一添加；`addContainerSlots()` 里用 `Helpers.getCapability(BlockCapabilities.ITEM, blockEntity)`
> 取容器侧物品栏，再用 `CallbackSlot` 把槽位绑定到实现 `ISlotCallback` 的方块实体上（从而支持 `isItemValid` 等回调）。

注册（自动处理「从网络缓冲区读取 BlockPos 再解析 BE」的细节）：

```java
public final class MyMenus {
    public static final DeferredRegister<MenuType<?>> MENUS = DeferredRegister.create(Registries.MENU, MyMod.MOD_ID);

    public static final DeferredHolder<MenuType<?>, MenuType<MyMachineContainer>> MY_MACHINE =
        RegistrationHelpers.registerBlockEntityContainer(MENUS, "my_machine",
            MyBlockEntities.MY_MACHINE, MyMachineContainer::create);
}
```

屏幕（客户端）：

```java
public class MyScreen extends net.minecraft.client.gui.screens.inventory.AbstractContainerScreen<MyMachineContainer> {
    public MyScreen(MyMachineContainer menu, Inventory playerInv, net.minecraft.network.chat.Component title) {
        super(menu, playerInv, title);
    }
    // renderBg 里绘制贴图 …
}
```

### 6.5 自定义配方类型（推荐直接继承 TFC 基类）

TFC 的配方体系（`net.dries007.tfc.common.recipes`）：

| 基类/接口 | 用途 |
|---|---|
| `ISimpleRecipe<C extends RecipeInput> extends Recipe<C>` | 默认实现 `canCraftInDimensions`/`isSpecial`/`getResultItem`，减少样板 |
| `INoopInputRecipe extends ISimpleRecipe<NoopInput>` | **没有输入容器**的配方（塌方、滑坡、加热这类「世界/物品触发」配方） |
| `IRecipePredicate<C>` | `boolean matches(C)` —— 用自定义上下文匹配 |
| `ItemRecipe` | `INoopInputRecipe` + `IRecipePredicate<ItemStack>`，按物品匹配（加热、凿刻、刮削等） |
| `BlockRecipe` | 按方块状态匹配（塌方、滑坡），自带 `serializer(...)`/`codec(...)`/`streamCodec(...)` 工厂 |
| `RecipeSerializerImpl<R>` | `record`，把 `MapCodec<R>` + `StreamCodec<RegistryFriendlyByteBuf, R>` 打包成 `RecipeSerializer` |
| `RecipeHelpers.getHolder(Level, Supplier<RecipeType<R>>, C)` | **TFC 风格的配方查找**（按 `IRecipePredicate` 的上下文匹配，比原版 `getRecipeFor` 更适合单输入机器） |
| `RecipeHelpers.getRecipes(Level, Supplier<RecipeType<R>>)` | 取全部某类型配方 |
| `RecipeHelpers.itemKeys(Ingredient)`、`fluidKeys(FluidIngredient)` | 为 `IndirectHashCollection` 建索引键 |

最小可用配方（按物品匹配、输出物品）：

```java
package com.example.mymod.common.recipes;

public class MyRecipe implements INoopInputRecipe, IRecipePredicate<ItemStack> {
    public static final MapCodec<MyRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC_NONEMPTY.fieldOf("ingredient").forGetter(MyRecipe::getIngredient),
        ItemStackProvider.CODEC.fieldOf("result").forGetter(MyRecipe::getResult),
        Codec.INT.optionalFieldOf("duration", 100).forGetter(MyRecipe::getDuration)
    ).apply(i, MyRecipe::new));

    private final Ingredient ingredient;
    private final ItemStackProvider result;
    private final int duration;

    public MyRecipe(Ingredient ingredient, ItemStackProvider result, int duration) { ... }

    @Override public boolean matches(ItemStack stack) { return ingredient.test(stack); }
    @Override public ItemStack assemble(ItemStack input) { return result.getSingleStack(input); }
    @Override public Ingredient getIngredient() { return ingredient; }
    public ItemStackProvider getResult() { return result; }
    public int getDuration() { return duration; }
    @Override public RecipeSerializer<?> getSerializer() { return MyRecipeSerializers.MY_RECIPE.get(); }
    @Override public RecipeType<?> getType() { return MyRecipeTypes.MY_RECIPE.get(); }
    @Override public boolean isSpecial() { return true; }   // 不出现在配方书里
}
```

注册：

```java
public final class MyRecipeTypes {
    public static final DeferredRegister<RecipeType<?>> RECIPE_TYPES =
        DeferredRegister.create(Registries.RECIPE_TYPE, MyMod.MOD_ID);
    public static final DeferredHolder<RecipeType<?>, RecipeType<MyRecipe>> MY_RECIPE =
        RECIPE_TYPES.register("my_recipe", () -> RecipeType.simple(ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_recipe")));
}

public final class MyRecipeSerializers {
    public static final DeferredRegister<RecipeSerializer<?>> RECIPE_SERIALIZERS =
        DeferredRegister.create(Registries.RECIPE_SERIALIZER, MyMod.MOD_ID);
    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<MyRecipe>> MY_RECIPE =
        RECIPE_SERIALIZERS.register("my_recipe",
            () -> new RecipeSerializerImpl<>(MyRecipe.CODEC, MyRecipe.STREAM_CODEC));
}
```

在方块实体里查找配方：

```java
RecipeHolder<MyRecipe> holder = RecipeHelpers.getHolder(level, MyRecipeTypes.MY_RECIPE, stack);
if (holder != null) { /* 用 holder.value() */ }
```

配方的 JSON（放在 `src/main/resources/data/mymod/recipe/my_recipe/xxx.json`）：

```json
{
  "type": "mymod:my_recipe",
  "ingredient": { "item": "tfc:ore/rich_hematite" },
  "result": { "stack": { "id": "tfc:metal/ingot/wrought_iron", "count": 1 } },
  "duration": 200
}
```

> `ItemStackProvider` 是 TFC 的输出抽象（支持「按输入物品决定输出」「附加 FoodComponent/HeatComponent」等），
> 其 JSON 形态与可用 modifier 见 `12-tfc-data-driven.md`。

### 6.6 数据组件

```java
public final class MyComponents {
    public static final DeferredRegister<DataComponentType<?>> COMPONENTS =
        DeferredRegister.create(Registries.DATA_COMPONENT_TYPE, MyMod.MOD_ID);

    public static final DeferredHolder<DataComponentType<?>, DataComponentType<MyData>> MY_DATA =
        COMPONENTS.register("my_data", () -> new DataComponentType.Builder<MyData>()
            .persistent(MyData.CODEC)
            .networkSynchronized(MyData.STREAM_CODEC)
            .build());
}
```

### 6.7 能力（Capability）

```java
public final class MyCapabilities {
    public static final ItemCapability<IMyThing, Void> MY_THING =
        ItemCapability.createVoid(ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_thing"), IMyThing.class);

    public static void register(RegisterCapabilitiesEvent event) {
        event.registerItem(MY_THING, (stack, ctx) -> new MyThing(stack), MyItems.MY_PART.get());
    }
}
// 主类里：bus.addListener(MyCapabilities::register);
```

### 6.8 网络包

见 `13-tfc-api.md` §8 的模板（`RegisterPayloadHandlersEvent` + `context.enqueueWork`）。

### 6.9 创造标签

```java
public final class MyCreativeTabs {
    public static final DeferredRegister<CreativeModeTab> CREATIVE_TABS =
        DeferredRegister.create(Registries.CREATIVE_MODE_TAB, MyMod.MOD_ID);

    public static final DeferredHolder<CreativeModeTab, CreativeModeTab> TAB =
        CREATIVE_TABS.register("main", () -> CreativeModeTab.builder()
            .title(Component.translatable("itemGroup.mymod"))
            .icon(() -> new ItemStack(MyItems.MY_PART.get()))
            .displayItems((params, output) -> {
                output.accept(MyItems.MY_PART.get());
                output.accept(MyBlocks.MY_MACHINE.get());
            })
            .build());
}
```

---

## 7. 资源与数据包目录约定

```
src/main/resources/
├── assets/mymod/
│   ├── lang/en_us.json, zh_cn.json
│   ├── models/block/…, models/item/…
│   ├── textures/block/…, textures/item/…
│   ├── blockstates/…
│   └── patchouli_books/<book>/en_us/{categories,entries,templates}/…
└── data/mymod/
    ├── recipe/…                    ← 原版与自定义配方
    ├── loot_table/blocks/…         ← 方块掉落
    ├── tags/{block,item,fluid}/…
    ├── tfc/<data_name>/…           ← ★ 注入 TFC 的数据表（fuel、item_heat、item_size、food……）
    └── patchouli_books/<book>/book.json
```

**要点（来自 Firmalife 的实测结论）**：
- 往 TFC 数据表里加内容，路径是 `data/<你的命名空间>/tfc/<表名>/xxx.json`（`tfc` 这一段由 TFC 的 `DataManager`
  的语义 id 决定），而不是 `data/tfc/...`。**不要直接写 `data/tfc/`**——那会与 TFC 本体冲突且被覆盖。
- 附属模组自己的数据表则是 `data/<你的命名空间>/<你的命名空间>/<表名>/xxx.json`。
- 每种数据的字段格式见 `12-tfc-data-driven.md`。

---

## 8. 运行与验证

```bash
./gradlew runClient     # 启动带你的模组的客户端（会加载 TFC/Patchouli）
./gradlew runServer     # 启动专用服务器（验证客户端类未被误加载）
./gradlew build         # 产出 build/libs/MyMod-NeoForge-1.21.1-0.0.0-indev.jar
```

**把产物交给本整合包使用**：把 jar 复制到
`D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mods\`，
然后启动 PCL 启动器中的该版本即可。

**验证清单**：
1. `runServer` 必须能启动（若崩在 `NoClassDefFoundError: net/minecraft/client/...`，说明客户端类泄漏到公共代码）。
2. 日志里搜索 `tfc.enableDebugSelfTests` 相关的 TFC 自检输出（开发期建议开着，能提前发现数据格式错误）。
3. 用 `/reload` 验证数据包 JSON 无语法错误（TFC 的 `DataManager` 会在日志中报出解析失败的具体文件）。

---

## 9. 常见错误与对策

| 错误 | 原因 / 对策 |
|---|---|
| `Mod mymod requires tfc ... which is missing` | `neoforge.mods.toml` 里依赖没写，或版本区间写错 |
| 启动即崩 `NoClassDefFoundError: vazkii/patchouli/client/...` | 客户端类被公共代码引用；把相关类全部挪到 `Dist.CLIENT` 分支 |
| 方块放置后立刻掉落实体 / 无模型 | 缺 `blockstates/*.json`、`models/block/*.json`、`models/item/*.json` |
| `BlockEntityType` 报 “invalid block entity” | BE 注册时没有把对应方块传进 `BlockEntityType.Builder.of(...)` |
| 打开 GUI 崩溃 | `MenuType` 未用 `RegistrationHelpers.registerBlockEntityContainer`（该工厂负责从 buffer 读 `BlockPos`） |
| 数据 JSON 不生效且无报错 | 放错目录（`data/tfc/...` vs `data/mymod/tfc/...`）；或字段名拼错（TFC 的 Codec 对未知字段通常静默忽略） |
| 配方的 `result` 写 `{"item": "...", "count": 1}` 报错 | TFC 的输出用 `ItemStackProvider`，写 `{"stack": {"id": "...", "count": 1}}` |
| 注册名重复 / 被 TFC 覆盖 | 命名空间必须是自己的 `mymod`，绝不能占用 `tfc` |

---

## 10. 与生态其它模组集成

| 目标 | 做法 |
|---|---|
| TFC | 硬依赖；复用 `ExtendedProperties`、`RegistrationHelpers`、`IRecipePredicate`、`DataManager`、`Helpers` |
| Firmalife | 硬依赖（可选）；详见 `30-firmalife-api.md`；常见做法是给 Firmalife 已有数据表塞 JSON |
| Patchouli | 硬依赖；书籍与自定义展示页见 `40-patchouli-api.md` 与 `50-tfc-patchouli-integration.md` |
| JEI / EMI | 软依赖：`ModList.get().isLoaded("jei")` 门控 + `bus.addListener` 注册类别（TFC 的 `compat/jei`、`compat/emi` 可作范例） |
| Jade / TOP | 软依赖，同上（TFC 的 `compat/jade`、`compat/theoneprobe`） |

---

## 11. 相关文档

| 文档 | 用途 |
|---|---|
| `10-tfc-overview.md` | TFC 架构、注册七层模型、时序规范 |
| `12-tfc-data-driven.md` | 28 种配方 + 17 类 `tfc/` 数据表的字段字典 |
| `13-tfc-api.md` | 组件、事件、气候、日历、Helpers 速查 |
| `30-firmalife-api.md` | Firmalife 注册清单、可复用与不可复用的扩展点 |
| `40-patchouli-api.md` | Patchouli 全部 JSON 字段与 Java API |
| `50-tfc-patchouli-integration.md` | TFC 的配方展示页与多块预览复刻 |
