# 126 · B 部分（`tfcagricultureplus`）实现子文档

> **定位**：本文是 [`117-agriculture-redesign-plan.md`](117-agriculture-redesign-plan.md) 的**施工子文档**，**只覆盖 B 模组**。
> 主方案回答「**做什么 / 为什么**」；本文回答「**怎么落代码**」。
>
> **上游依据**：主方案 §〇.2（拆包）· §9.0（工程前提）· §9.1~9.4（施工清单）· §12.6（mixin 策略）· §5.5（覆盖台账）· §5.1.1（A 层物种接管定则）
>
> **状态**：2026-09-29 起草。**尚未开工** —— 本文写完后按 §一 执行「阶段 -1」。
>
> 📌 **引用约定**：本文出现的 `§x.y` **除特别注明外，均指主方案 [`117-agriculture-redesign-plan.md`](117-agriculture-redesign-plan.md) 的章节**
> （本文自己的章节用 `§一`~`§十九` 的中文编号）。所以本文里 `§9.0-C` = 主方案的 9.0-C 小节，不是本文的第九节。

---

## 🧭 文档导航（🆕 2026-09-29 整理）

> ⚠️ **本文是"逐轮追加"写成的**（经历了 **9 次用户口径修正**），所以有**多处"后章推翻前章"**。
> 下表**明确标出每章的状态**，避免照旧结论开工。

### A. 按目的导航

| 你想做什么 | 直接看 | 状态 |
|---|---|---|
| **开工前必读** | §〇（红线 12 条）· **§十九（协议合规）** | ⭐ **两份都要读** |
| **建工程骨架** | §一（拆包）· §二（API 边界）· §三（基础设施） | ✅ 现行 |
| **知道要做什么（清单）** | §四（批次）· §十四（方块工序）· §十五（新品类）· §十六（可放置食物）· §十七（厨房家具） | ✅ 现行 |
| **知道为什么这么设计** | §十（改造清单）· §十一（现实加工）· §十二（逐工序）· §十三（学 extradelight） | 📖 推导过程 |
| **了解外部参照** | [`127-extradelight-full-analysis.md`](127-extradelight-full-analysis.md) | ✅ 现行 |
| **验证怎么做** | §五（三层验证 + `verify-registry.ps1`） | ✅ 现行 |
| **出问题了怎么退** | §六（回滚）· §七（风险） | ✅ 现行 |
| **合规检查** | **§十九** | 🛑 **必读** |

### B. ⚠️ 权威结论索引（**"后章推翻前章"的地方**）

| 结论 | ❌ 旧（已作废） | ✅ **权威（以这个为准）** |
|---|---|---|
| **拆包方案** | 主方案 §9.0-A 的"单仓多模块" | **§1.2「并列双项目 + jar 依赖」** |
| **调料机制** | ~~调料影响营养~~（需 mixin） | **§10.2 A3「`FoodTrait`，零 mixin」** |
| **连作 / 适播 / 授粉** | ~~§13.4 三项深化~~ | **§10.2 A6「全部作废」**（TFC 已有前两项） |
| **加工方块** | ~~§12.9 的 10 个~~（风车/玉米工位/土砻/杵臼…） | **§14.5 + §17.5**（15 个加工 + 10 个食物 + 7 个家具） |
| **搅拌碗 / 烟熏 / 干燥垫** | ~~§13.3 的"搅拌碗 · 挂晒架"~~ | **§13.7「Firmalife 已有，撤销」** + **§13.10 干燥三形态** |
| **家具材质** | ~~§17.3 的"建议 6 种木材"~~ | **§17.3 修订「全部 34 树种 + 21 岩石」** |
| **方块数量口径** | ~~"≈53 个方块"~~ | **§17.5「类 ≈20 · 单例 53 · 全材质注册项 ≈375」** |
| **美术量** | ~~主方案 §9.0-D 的"≈410 张"~~ | **主方案 §9.0-D 修订「≈620 张」**（家具仅增 20~30） |
| **配方类型** | ~~§14.6 的"9 个新建"~~ | **§14.6 扩充「12 个新建」**（+`bottle_fluid`/`dynamic_jam`/`flour_dough`） |
| **协议红线** | ~~主方案 §2.8 只有 ARR 模组~~ | **§十九「完整协议总表 + 过度挪用判据」** |

### C. 建议的**开工顺序**（与章节顺序不同）

```
① 读 §〇（红线）+ §十九（协议）        ← 5 分钟，但决定"能不能做"
② 执行 §一（阶段 -1 拆包）              ← 唯一必须先做的工程动作
③ 按 §四 的批次表推进                   ← 批次 -1 → 0 → 1 → …
④ 每个批次收口跑 §五 的三层验证
⑤ 需要设计细节时查 §十四~§十七
⑥ 需要学术语/结构时查 §十~§十三 + 127 文档
```

### D. 九次口径修正的**时间线**（便于追溯）

| 轮 | 用户口径 | 影响 |
|---|---|---|
| 1 | 调料只影响保质期，不影响营养 | A3 重写（mixin → 零 mixin） |
| 2 | 连作适播已有，授粉不做 | A6 作废 |
| 3 | 多添加方块丰富流程 | §十二 工序分析 |
| 4 | 部分机械 TFC 已有；可用合成/右键 | §12.9 去重 + 四选一判据 |
| 5 | 其他作物也要考虑；育种/酿酒/养蚕未体现 | §12.11~§12.14 |
| 6 | 除案板外方块都不适合；学 extradelight；聚焦食品 | §十三 方向修正 |
| 7 | 干燥有 Firmalife 垫；搅拌碗烟熏已有；加手持工具 + TFC 机械工具 | §13.7~§13.10 |
| 8 | 方块工序还不够多；拓展新品类 | §十四 · §十五 |
| 9 | 别忘了食物方块 / 厨房家具 / 1.20.1 版 / 全材质 | §十六 · §十七 · §十八 · §17.3 |

---

## 〇、开工前提（缺一不可）

### 0.1 必须先读的主方案章节

| 顺序 | 章节 | 为什么 |
|---|---|---|
| 1 | §〇.2 拆包 | **最高优先级**，先于一切内容工作 |
| 2 | §1.4 已实现地基 | 能用现成的类就不要新写 |
| 3 | §5.1.1 A 层物种接管定则 | **B 只加链条、不碰 A 的方块** |
| 4 | §12.6 mixin 策略 + §9.0-B Java 规范 | 编码红线 |
| 5 | §9.1~9.4 施工清单 | 做什么 |
| 6 | §5.5 / §5.5.2 覆盖台账 | 每个覆盖文件都要登记 |

### 0.2 当前环境状态（2026-09-29 实测）

| 项 | 状态 |
|---|---|
| **A 模组**（`tfcfarmingplus`） | ✅ **已实机验证通过**（本轮修复 2 个 bug 后） |
| A 的 jar | `mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` · 2.397 MB · **6460 条目** |
| A 的注册方块 | **474 个**（`[渲染层自检]` 实测） |
| A 的资源 | blockstate 475 · 模型 2052 · **贴图 2394** · 掉落表 475 |
| TFC | **4.2.11**（`mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar`） |
| Firmalife / afc | ⚠️ 需确认是否在 `mods/` 里（B 依赖它们） |
| 已禁用的第三方 | geckolib(1.20.1) · extradelight · FarmersDelight · DragN ×3 · untamedwilds · Aquaculture · fowlplay · crabbersdelight · cuisinedelight |
| Gradle | 8.13 · Java 21（toolchain） |

### 0.3 红线速查（**违反任一条即返工**）

| # | 红线 | 出处 |
|---|---|---|
| 1 | **B 不得依赖 A 以外的我们自己的模组**；A 不得 import B 的类 | §〇.2.6-1 |
| 2 | 🛑 **B 不得写 `assets/tfcfarmingplus/**` 或 `data/tfcfarmingplus/**`** | §〇.2.6-2 |
| 3 | **mixin 不得指向 A 的类**（检查**目标类名**，不是包名 —— B 的包名本身含 `tfcfarmingplus`） | §〇.2.6-3 · §2.3 |
| 4 | **A 不得为 B 预埋钩子** | §〇.2.6-4 |
| 5 | **B 检测不到 A 时硬失败**（不静默降级） | §〇.2.6-5 |
| 6 | **D 不得依赖 B**（`A ← B` · C 独立 · `C ← D`） | §〇.2.6-6 |
| 7 | 写邻居命名空间的标签**必须 `replace=false`**（`true` 是唯一的灾难性写法） | §5.5.2 |
| 8 | **mixin 配置 `"required": true`**（条件让位组例外） | §12.6.5-4 |
| 9 | **新增方块族必须接进渲染层清单 + BE 注册** | §9.0-B-1 |
| 10 | **物种必须闭环**（种子→可种→可长→可收→产物有用途） | §9.0-B-2 |
| 11 | 删 `src/main/resources` 文件后**必须 `gradle clean build`** | §9.0-B-4 |
| 12 | **资源引用的方块必须在 Java 里注册过** —— 🆕 本轮实机验证抓到的真实 bug（§五 5.2） | 本文 §5.2 |

---

## 一、阶段 -1：拆包（🛑 最高优先级）

### 1.1 现状：A 是**单项目 + 离线 jar 依赖**

```
moddev/tfcfarmingplus/
├── build.gradle.kts      # 单项目，无 subprojects
├── settings.gradle       # rootProject.name = 'tfcfarmingplus'，无 include
├── gradle.properties
├── src/main/{java,resources,templates}
└── tools/
```

依赖方式（`build.gradle.kts` 实测）：
```kotlin
val modsDir = "D:/111/最强服务器/.minecraft/versions/Essential TerraFirmaCraft (TFC)/mods"
fun latestJar(prefix: String): String { /* 取文件名最大的那个 */ }
val tfcJar = latestJar("TerraFirmaCraft-NeoForge-")
val patchouliJar = latestJar("Patchouli-")
...
dependencies {
    implementation(files(tfcJar))        // ← 离线 jar 直引
    implementation(files(patchouliJar))
}
```

### 1.2 🛑 对主方案结论的修正：**不建议改造成多模块**

主方案 §9.0-A 定的是「单仓多模块（`:core` + `:remake`）」。**拿到实际工程状态后应修正**：

| 方案 | 做法 | 优点 | 缺点 | 裁决 |
|---|---|---|---|---|
| **甲：改成 Gradle 多模块** | `settings.gradle` 加 `include ':core', ':remake'`，A 的目录下沉一层 | 依赖关系由 Gradle 表达 | 🛑 **要动 A 的 `settings.gradle` + `build.gradle.kts` + 目录结构** ⇒ **A 刚从"构建不出来"修好**，再动它有回归风险；且 A 的 6,418 个资源路径要跟着搬 | ❌ **否决** |
| **乙：并列双项目 + jar 依赖** ⭐ | B 是**独立目录**（`moddev/tfcagricultureplus/`），依赖 A 用 `files(aJar)` | ✅ **A 完全不动**；✅ 与 A 现有的 TFC 依赖方式**style 一致**；✅ B 可独立构建 / 独立发布；✅ 回滚 = 删目录 | A 改动后要先重建 A 再建 B（可脚本化） | ✅ **采用** |
| 丙：B 直接引用 A 的 `src` 目录 | `sourceSets { main { java { srcDir("../tfcfarmingplus/src/main/java") } } }` | 无需构建 A | 🛑 会让 B 把 A 的**全部源码**编进自己的 jar ⇒ **A 的类被复制两份**，运行时冲突 | ❌ **否决** |

**修正理由（一句话）**：A 已经是一个**经过实机验证的稳定交付物**；
阶段 -1 的目标是「把 B 隔离出来」，**不是「把 A 拆开」** —— 乙方案以**最低风险**达成同一目标。

### 1.3 B 的目录布局

```
moddev/
├── tfcfarmingplus/                  ← A（🛑 一个字节都不动）
│   └── ...
└── tfcagricultureplus/              ← B（全新）
    ├── build.gradle.kts
    ├── settings.gradle              # rootProject.name = 'tfcagricultureplus'
    ├── gradle.properties
    ├── src/main/
    │   ├── java/com/example/tfcfarmingplus/expansion/   ← 包名沿用主方案 §〇.2.4
    │   │   ├── TFCFarmingPlusExpansion.java             ← 入口
    │   │   ├── client/                                  ← 渲染层登记
    │   │   └── common/
    │   │       ├── MyBlocks / MyItems / MyBlockEntities / MyCreativeTab
    │   │       ├── override/        ← 覆盖台账（197 项的代码侧）
    │   │       ├── species/         ← B 层新物种
    │   │       ├── machines/        ← 新加工设备
    │   │       ├── inworld/         ← 世界内加工（§7.2.4）
    │   │       ├── system/          ← L-3：温室 / 地窖 / 灌溉
    │   │       └── food/            ← 调料 / 主次产品 / 新鲜草
    │   ├── resources/
    │   └── templates/META-INF/neoforge.mods.toml
    └── tools/                       ← 门禁脚本等
```

🛑 **`assets/` 与 `data/` 的顶层命名空间是 `tfcagricultureplus`**（mod id），**不是包名**。

### 1.4 B 的 `build.gradle.kts`（可直接复制，基于 A 的实测版改造）

```kotlin
plugins {
    id("net.neoforged.moddev") version "2.0.111"
}

val modId = "tfcagricultureplus"
val modVersion = "0.1.0"
val minecraftVersion = "1.21.1"
val neoForgeVersion = "21.1.233"

// 本机 mods 目录（与 A 同一套离线 jar 依赖方案）
val modsDir = "D:/111/最强服务器/.minecraft/versions/Essential TerraFirmaCraft (TFC)/mods"

// ASCII-only log messages: the Gradle console here is GBK (see A's script note).
fun latestJar(prefix: String): String {
    val jar = File(modsDir).listFiles { f -> f.name.startsWith(prefix) && f.name.endsWith(".jar") }
        ?.maxByOrNull { it.name }
        ?: error("[tfcagricultureplus] no jar starting with '$prefix' found in: $modsDir")
    logger.lifecycle("[tfcagricultureplus] using dependency: ${jar.name}")
    return jar.absolutePath
}

val tfcJar       = latestJar("TerraFirmaCraft-NeoForge-")
val patchouliJar = latestJar("Patchouli-")
val firmalifeJar = latestJar("Firmalife-")     // ⚠️ 若 mods 里没有会直接报错 —— 这是刻意的（B 依赖它）
val afcJar       = latestJar("afc-")           // ⚠️ 同上

// 🆕 B 依赖 A 的**构建产物**（不是源码；见 §1.2 乙方案）
val aJar = File("../tfcfarmingplus/build/libs")
    .listFiles { f -> f.name.startsWith("TFCFarmingPlus-NeoForge-") && f.name.endsWith(".jar") }
    ?.maxByOrNull { it.name }
    ?: error("[tfcagricultureplus] 找不到 A 的构建产物 —— 请先在 ../tfcfarmingplus 跑 gradle build")

val generateModMetadata = tasks.register<ProcessResources>("generateModMetadata") {
    val props = mapOf(
        "modId" to modId,
        "modVersion" to modVersion,
        "minecraftVersionRange" to "[$minecraftVersion]",
        "neoForgeVersionRange" to "[$neoForgeVersion,)",
        "tfcVersionRange" to "[4.2.8,)",
        "patchouliVersionRange" to "[1.21.1-92-NEOFORGE,)",
        "aVersionRange" to "[0.1.0,)",          // B 对 A 的版本要求
    )
    inputs.properties(props)
    expand(props)
    from("src/main/templates")
    into(layout.buildDirectory.dir("generated/sources/modMetadata"))
}

neoForge { version = neoForgeVersion }

base {
    archivesName.set("TFCAgriculturePlus-NeoForge-$minecraftVersion")
    group = "com.example.tfcfarmingplus.expansion"
    version = modVersion
}

java { toolchain.languageVersion.set(JavaLanguageVersion.of(21)) }

tasks.withType<JavaCompile>().configureEach { options.encoding = "UTF-8" }
tasks.withType<ProcessResources>().configureEach { filteringCharset = "UTF-8" }

repositories {
    mavenCentral()
    maven {
        url = uri("https://bmclapi2.bangbang93.com/maven/")
        content { includeGroup("net.neoforged"); includeGroup("net.minecraftforge") }
    }
    exclusiveContent {
        forRepository { maven("https://maven.blamejared.com") }
        filter { includeGroup("vazkii.patchouli") }
    }
}

sourceSets { main { resources { srcDir(generateModMetadata) } } }

neoForge {
    mods { create(modId) { sourceSet(sourceSets.main.get()) } }
    ideSyncTask(generateModMetadata)
}

dependencies {
    implementation(files(tfcJar))
    implementation(files(patchouliJar))
    implementation(files(firmalifeJar))
    implementation(files(afcJar))
    implementation(files(aJar))            // ← 依赖 A（仅供编译；运行期由 mods 目录里的 A 提供）
}
```

⚠️ **`aJar` 用 `implementation` 而不是 `compileOnly`**：
`implementation` 会把 A 的类带上编译期 classpath（这正是我们要的）；
**但 B 的 jar 不会打包 A**（`files()` 依赖不进 jar）⇒ 运行期由 `mods/` 里的 A 提供 ✅

### 1.5 `neoforge.mods.toml` 模板（`src/main/templates/META-INF/`）

⚠️ **必须保持纯 ASCII**（A 的构建脚本里记录了原因：`ProcessResources` 的 `filteringCharset` 一旦出错，
FML 会判定 `is not a valid mod file / MalformedInputException` 并**拒绝整个 jar**）。

```toml
modLoader = "javafml"
loaderVersion = "[4,)"
license = "MIT"

[[mods]]
modId = "${modId}"
version = "${modVersion}"
displayName = "TFC Agriculture Plus"
authors = "dsh"
description = '''TFC Agriculture Plus - the overhaul layer on top of TFC Farming Plus: crops, processing chains, seasonings and systems.'''

[[dependencies.${modId}]]
    modId = "tfcfarmingplus"
    type = "required"                 # 🛑 红线 5：检测不到 A 就硬失败
    versionRange = "${aVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.${modId}]]
    modId = "tfc"
    type = "required"
    versionRange = "${tfcVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.${modId}]]
    modId = "firmalife"
    type = "required"
    versionRange = "[3.0.0,)"
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

### 1.6 入口类骨架

```java
package com.example.tfcfarmingplus.expansion;

import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.ModList;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Mod(TFCFarmingPlusExpansion.MOD_ID)
public final class TFCFarmingPlusExpansion {

    public static final String MOD_ID = "tfcagricultureplus";
    public static final Logger LOGGER = LoggerFactory.getLogger("TFC Agriculture Plus");

    public TFCFarmingPlusExpansion(IEventBus modBus, ModContainer container) {
        // 🛑 红线 5：检测不到 A 时**硬失败**，不静默降级
        if (!ModList.get().isLoaded("tfcfarmingplus")) {
            throw new IllegalStateException(
                "[tfcagricultureplus] 需要前置模组 tfcfarmingplus（TFC Farming Plus）—— 请勿单独安装本模组。");
        }

        // 注册表：**顺序敏感**，按 A 的既有顺序（Blocks → Items → BEs → CreativeTab）
        MyBlocks.register(modBus);
        MyItems.register(modBus);
        MyBlockEntities.register(modBus);
        MyCreativeTab.register(modBus);

        modBus.addListener(this::commonSetup);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> {
            // 覆盖台帐自检（§3.6）：核对 197 项覆盖是否与磁盘一致
            // 配方类型 / in_world handler 的注册时机
        });
    }
}
```

### 1.7 六条依赖红线的**门禁脚本**（`tools/check-boundaries.ps1`）

```powershell
# 用途：每批次提交前跑一次；任一红线被触碰即退出码 1
$ErrorActionPreference = 'Stop'
$B = $PSScriptRoot + '\..'
$A = $PSScriptRoot + '\..\..\tfcfarmingplus'
$fail = 0

# 红线 1：A 不得 import B/C/D 的包
$hit = Select-String -Path "$A\src\main\java\**\*.java" -Pattern 'expansion|husbandry' -EA SilentlyContinue
if ($hit) { $fail++; Write-Host "🛑 红线1：A 引用了 B：" ; $hit | ForEach-Object { $_.Line } }

# 红线 2：B 不得写 A 的命名空间
$hit = Get-ChildItem "$B\src\main\resources" -Recurse -File -EA SilentlyContinue |
       Where-Object { $_.FullName -match '\\(assets|data)\\tfcfarmingplus\\' }
if ($hit) { $fail++; Write-Host "🛑 红线2：B 覆盖了 A 的资源：" ; $hit | ForEach-Object { $_.FullName } }

# 红线 3：B 的 mixin 不得指向 A 的类（匹配 target 类名，不是包名）
$mix = Get-ChildItem "$B\src\main\resources" -Recurse -Filter '*.mixins.json' -EA SilentlyContinue
foreach ($m in $mix) {
  $t = Get-Content $m.FullName -Raw
  if ($t -match 'tfcfarmingplus\.[a-z]+\.(common|client)\.') {
    $fail++; Write-Host "🛑 红线3：mixin 指向了 A 的类：$($m.Name)"
  }
}

# 红线 7：写邻居命名空间的标签必须 replace=false
$tags = Get-ChildItem "$B\src\main\resources\data" -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.FullName -match '\\tags\\' -and $_.FullName -notmatch '\\tfcagricultureplus\\' }
foreach ($t in $tags) {
  if ((Get-Content $t.FullName -Raw) -match '"replace"\s*:\s*true') {
    $fail++; Write-Host "🛑 红线7（灾难性）：$($t.FullName) 写了 replace:true"
  }
}

if ($fail -eq 0) { Write-Host "✅ 六条红线全过" } else { exit 1 }
```

### 1.8 批次 -1 的**验收判据**

> ✅🆕 **2026-09-29：批次 -1 已执行完毕，6 条判据全过** —— 证据与产物见 §1.9。

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | B 能独立构建 | `gradle build` 在 `moddev/tfcagricultureplus/` 成功 |
| 2 | **空 B jar 能进游戏** | 日志出现 B 的 mod 名 · 无 `Unable to load` |
| 3 | **A 的 146 物种照常** | `[渲染层自检] 已注册方块 474 个` 不变 |
| 4 | **卸载 B 后 A 仍完整** | 把 B 的 jar 移出 `mods/` 再启动一次，判据 3 仍成立 |
| 5 | 红线门禁可跑 | `check-boundaries.ps1` 退出码 0 |
| 6 | B 缺 A 时**硬失败** | 临时移除 A 的 jar ⇒ 启动应报明确错误（不是静默） |

### 1.9 ✅ 批次 -1 **执行记录**（2026-09-29，实测）

#### 交付物（**已落地**）

| 类别 | 文件 | 行/大小 |
|---|---|---|
| **Java**（6 个） | `TFCAgriculturePlus.java`（入口） | **53 行** |
| | `client/TFCAgriculturePlusClient.java`（渲染层清单） | 33 行 |
| | `common/MyBlocks.java` · `MyItems.java` · `MyBlockEntities.java` · `MyCreativeTab.java` | 59 / 45 / 30 / 36 行 |
| **Gradle** | `settings.gradle` · `gradle.properties` · `build.gradle.kts` | 243 B / 75 B / **3,773 B** |
| **模板** | `templates/META-INF/neoforge.mods.toml`（**纯 ASCII**） | 1,311 B |
| **门禁脚本** | `tools/check-boundaries.ps1`（六红线 + 协议合规） | **3,896 B** |
| | `tools/verify-registry.ps1`（资源↔注册一致性） | **3,319 B** |
| **产物** | **`TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`** | **8.9 KB**（8 条目：6 class + MANIFEST + mods.toml） |

#### 构建实测（`BUILD SUCCESSFUL in 57s`）

**5 个依赖全部自动解析**（`latestJar()` 生效）：
```
TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar
Patchouli-1.21.1-93-NEOFORGE.jar
Firmalife-NeoForge-1.21.1-3.0.15.jar
afc-2.1.3-1.21.1.jar
TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar   ← A 的构建产物 ✅
```

#### 实机验证（**判据全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | B 的 mod 被识别 | ✅ `TFC Agriculture Plus 0.1.0 (tfcagricultureplus)` |
| 2 | **B 读到 A 的版本** | ✅ `[TFC Agriculture Plus] loaded, dependency A version = 0.1.0` |
| 3 | **A 的渲染层自检不变** | ✅ `已注册方块 474 个，全部有归属（cutout 304 / cutoutMipped 68 / 无需登记 102）` |
| 4 | **真进世界** | ✅ `Starting integrated minecraft server` + `Loaded 1551 advancements` + `Time elapsed: 751 ms` |
| 5 | `Unknown registry key` | ✅ **0 处** |
| 6 | `Couldn't parse element` | ✅ **0 处** |
| 7 | `Failed to load registries` / `Mod loading has failed` | ✅ **0 处** |
| 8 | **本模组 ERROR** | ✅ **0 处** |

⚠️ 日志里唯一的 `Missing textures` 属于 **`afc:wood/leaves/mahoe`**（**afc 自己的贴图名 bug**，
路径写作 `dense_leaves/mahoet` —— 多了一个 `t`）⇒ **与本项目无关**。

#### 🆕 执行中踩到的**两个真实坑**（已修）

| # | 坑 | 现象 | 修法 |
|---|---|---|---|
| **1** | ⭐ **Kotlin 的 `?:` 与 `.also` 优先级** | `a ?: error(...).also { }` ⇒ `.also` 绑到 `error()` 的 **`Nothing`** 返回类型上 ⇒ `Unresolved reference: name` ⇒ **构建失败** | **给 elvis 结果加括号**：`(a ?: error(...)).also { }` |
| **2** | ⭐ **Windows 260 字符路径上限** | `[System.IO.File]::ReadAllBytes()` 抛 `PathTooLongException`（脚本内部再拼 `src\main\resources\...` 就超） | ① **用相对路径**（`Set-Location` 后）<br>② 或缩短中间目录名<br>⚠️ **`[Parser]::ParseFile` 用的是"进程工作目录"不是 PowerShell location** ⇒ 混用会解析到错位置 |

#### 意外收获

✅ **`check-boundaries.ps1` 首次运行即通过**（六红线 + 协议合规）——
说明**空 B 天然合规**（没有资源、没有 mixin、没有受限依赖）⇒ **门禁脚本可用作后续批次的守门人**。

✅ **日志已存档**：`moddev/backups/launch-out-B-phase-minus1-20260929.log`

---

## 二、包结构与 A ↔ B 的 API 边界

### 2.1 命名规范（与 A 对齐，降低心智负担）

| 类别 | 规范 | 例（A 的既有做法） |
|---|---|---|
| 注册表 | `My{Blocks,Items,BlockEntities,CreativeTab}` | A 同名 |
| 物种清单 | 按域分：`MySpecies*` / `MyOverrides` | A 的 `MyCrops`/`MyBushes` |
| 方块类 | `My*Block`（复用 A 的类时**不要**再包一层） | A 的 `MyCropBlock` |
| 常量 | **大写下划线** | A 的 `WILD_SPINACH` |
| 注释语言 | **中文**（javac 已设 UTF-8，见 §1.4） | A 全中文 |

### 2.2 🛑 与 A 的 API 边界（**B 只能用这 3 样，多一个都不给**）

| B 需要 | A 的现状 | 动作 |
|---|---|---|
| **1. A 的 17 个方块类 + 3 个物品类** | 已 `public` | ✅ 直接 `new`。⚠️ A 应在其类注释里写明「**这是给 B 的稳定接口**」—— 见 §2.3 批次 1 |
| **2. A 的注册表**（`MyBlocks` / `MyItems` / `MyBlockEntities`） | `public static` 字段 | ✅ **只读引用**（取 ID / 取 holder）；❌ **不得运行时写入或清空** |
| **3. A 的物种与气候只读查询** | 🛑 **A 目前没有**（`MyClimateRanges` 是数据驱动的，但无查询 API） | 🆕 **批次 1 要在 A 侧新增 1 个类**（§2.3） |
| 往 A 的创造模式页追加 | `MyCreativeTab` | ❌ **不开钩子** ⇒ B 自建创造页 |
| 覆盖 A 的贴图 / 模型 / 掉落表 | — | 🛑 **禁止**（红线 2） |

### 2.3 批次 1：A 侧唯一的新增（`MySpeciesApi`）

> 🛑 这是**整个拆包中唯一一处要改 A 的地方**。
> 它必须：① 只读 ② 不改变 A 的任何现有行为 ③ A 单独跑时完全无感。

```java
package com.example.tfcfarmingplus.common;

import java.util.List;
import java.util.Optional;
import net.dries007.tfc.util.climate.ClimateRange;

/**
 * 【给 B 的稳定只读接口】—— TFC Agriculture Plus 依赖本类。
 * <p>
 * ⚠️ 改这个类 = 改 B 的编译契约。**只增不改**：新增方法可以，改签名/删方法会让 B 编译失败。
 * <p>
 * 本类不做任何注册、不持有任何可变状态、不参与任何 tick —— A 单独运行时它的存在感为零。
 */
public final class MySpeciesApi {

    /** 全部 146 个物种名（86 作物 + 48 果树 + 12 灌木），不可变快照。 */
    public static List<String> species() { /* … */ }

    /** 某个物种的气候区间；不存在则空。 */
    public static Optional<ClimateRange> climateOf(String species) { /* … */ }

    /** 这个名字是不是 A 的物种（B 用它来避免重复注册）。 */
    public static boolean isOurSpecies(String name) { /* … */ }

    private MySpeciesApi() {}
}
```

**验收（批次 1）**：A 单独 `gradle build` 成功 · `verify.ps1` 全绿 · **A 的 jar 里不出现任何 B 的字样**。

### 2.4 ✅ 批次 0 **执行记录**（2026-09-29 / 10-05，实测）

#### 交付物

| 项 | 内容 |
|---|---|
| **新文件** | `tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MySpeciesApi.java`（**约 150 行**） |
| **公开 API（5 个）** | `species()` · `blockOf(String)` · `climateOf(String)` · `isOurSpecies(String)` · `speciesCount()` |
| **A 的改动** | 🛑 **仅此一个文件**（符合"唯一一处要改 A 的地方"的设计） |
| **A 的 mods.toml** | **未改**（依赖仍是 tfc / patchouli / neoforge / minecraft —— **没有 B**） |

#### 三条验收判据（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | A 单独 `gradle build` | ✅ **BUILD SUCCESSFUL in 1m 35s** |
| 2 | `verify.ps1` | ✅ **全部交叉引用有效，未发现问题**（blockstate 474 / 模型 2044 / 掉落表 474 / configured_feature 244 / placed_feature 244 / 物品模型 429） |
| 3 | **A 的 jar 里不出现 B 的字样** | ✅ **命中 0 处**（`tfcagricultureplus` / `expansion` 均为 0）<br>✅ `MySpeciesApi.class` 在 jar 里<br>✅ `mods.toml` 的 5 个 modId 里没有 B |
| 4 | 实机验证（A+B 共存） | ✅ `已注册方块 474 个，全部有归属` · `TFC Agriculture Plus loaded, dependency A version = 0.1.0` · 进世界无错误 |

#### 实现要点（**B 依赖此契约，改动前必读**）

| # | 要点 |
|---|---|
| **1** | ⭐ **惰性初始化**：`MyBlocks.BLOCKS.getEntries()` 在**类初始化期不完整**（注册表未绑定）⇒ 所有缓存**首次调用时**才构建，构建后不可变（返回 `Collections.unmodifiable*`） |
| **2** | **物种名从"已注册方块 ID"反推**：取 `crop/<n>` 与 `plant/<n>` 的前缀剥离结果，排除 `dead_*` 与 `*_bush_cane` |
| **3** | **气候查询复用 TFC 的 `ClimateRange.MANAGER`**：物种的方块 ID **去掉命名空间就是气候 ID**（`data/tfcfarmingplus/tfc/climate_range/<path>.json`）⇒ **零新数据结构** |
| **4** | **不抛异常**：注册表未就绪时返回空列表（方便 B 的早期调用） |

### 2.5 ⚠️ 批次 0 执行途中发现的**外部事件**（**必须记录**）

🛑 **A 的贴图从 2394 张降到 1728 张（-666）** —— **不是本项目任何操作造成的**，需要留档：

| 项 | 数据 |
|---|---|
| 发现时刻 | 2026-10-05（构建 A 时发现 jar 条目 **6460 → 5789**） |
| 丢失明细 | `textures/block/crop/` **576** · `textures/block/wild_crop/` **86** · `textures/block/dead_crop/` **4** |
| ✅ **判定：影响为零** | 丢失的全是 **`X_N.png` 形式的"死贴图"**（AGENTS.md 第 42 轮已记录过这批 658+ 张）：<br>① **模型引用的是 `X_age_N`**（抽查 `adzuki_age_0.json` → `tfcfarmingplus:block/crop/adzuki_age_0`）<br>② **活贴图齐全**：`crop/` 现 849 张（含 **742** 张 `_age_` + 107 张有意义的 `rosette`/`leafball`/`side` 变体）<br>③ `wild_crop/` **86 张齐全** · `dead_crop/` **162 张齐全**<br>④ **`verify.ps1` 全绿** |
| 处置 | ① **备份旧 jar**：`moddev/backups/TFCFarmingPlus-pre-cleanup.20261005-080835.bak.jar`<br>② 部署**含 `MySpeciesApi` 的新 A**（2.107 MB / 5888 条目）<br>③ **实机验证通过**（判据见 §2.4） |

⚠️ **教训**：**A 的 jar 条目数变化必须当场对账**（本次就是靠对账才发现的）。
🆕 **建议**：把"**jar 条目数 vs src 文件数**"的对账加进 §5.2 的 `verify-registry.ps1`（或独立脚本）——它能同时抓到**资源丢失**与**增量构建残留**两类问题。

---

## 三、基础设施（阶段 3，B 的第一批真实代码）

> 目标：把「新设备 / 新配方类型 / mixin」三件事的**共同底座**做出来，
> 之后每条链都只是「填数据 + 套模板」。

### 3.1 注册表骨架

```java
// MyBlocks.java —— 只放 B 自己的方块；A 的方块从 A 的注册表**读**
public final class MyBlocks {
    public static final DeferredRegister.Blocks BLOCKS =
        DeferredRegister.createBlocks(TFCFarmingPlusExpansion.MOD_ID);

    /** 统一方块属性：与 A 的 cropProps()/deadProps() 保持同一套观感 */
    public static BlockBehaviour.Properties cropProps() { /* … */ }

    public static void register(IEventBus bus) { BLOCKS.register(bus); }
}

// MyBlockEntities.java —— 🛑 每个 BE 必须登记 validBlocks，否则**放置即崩**（红线 9）
// MyCreativeTab.java  —— B 自建创造页（A 的创造页不开钩子）
```

🛑 **顺序**：`Blocks` → `Items` → `BlockEntities` → `CreativeTab`（与 A 一致）。
🛑 **新增方块族必须显式接进 `client/` 的渲染层清单**（红线 9）—— 自动化只覆盖已知类别。

### 3.2 配方类型基建

```java
// ModRecipeTypes / ModRecipeSerializers —— 照 TFC 的范式
// 每个配方类型需要三件套：RecipeType + RecipeSerializer(MapCodec) + StreamCodec
// ⚠️ 参考 §7.2.3 反编译出的 InWorldRecipe：record + MapCodec + StreamCodec 双编解码器
```

### 3.3 ⭐ `in_world` 的实现骨架（**按 §7.2.3 的反编译结论**）

```java
// ① 配方记录（照 tfcwoodwork 的 InWorldRecipe 结构，但 tool 改为标签驱动）
public record InWorldRecipe(
    BlockStatePredicate inputState,          // "inputState" 必填
    TagKey<Item> requiredTool,               // 🆕 用标签而非硬编码枚举（原版只有 axe/saw 两值）
    BlockState resultState,                  // "resultState" 必填
    Optional<SoundInstance> soundInstance,   // "sound" 可选
    List<Pair<ItemStack, Action>> resultItems// "resultItems" 可选
) implements Recipe<InWorldRecipeInput> { /* getIngredients / matches / getResultItem / assemble */ }

// ② 处理器 —— 挂 NeoForge 公开事件，**零 mixin**
@EventBusSubscriber(modid = TFCFarmingPlusExpansion.MOD_ID)
public final class InWorldRecipeHandler {
    @SubscribeEvent
    public static void onPlayerRightClickBlock(RightClickBlock event) {
        // 1. 只处理 MAIN_HAND
        // 2. 冷却检查（按工具标签）
        // 3. checkFiveDirections：UP + 四水平都无实心面（⚠️ 沤麻池在水里需实测）
        // 4. 组 InWorldRecipeInput(blockState, itemStack) → recipeManager.getRecipeFor(IN_WORLD, input, level)
        // 5. 命中 ⇒ 对每个 resultItems 执行 Action.accept(level, pos, stack, playerDirection)
        // 6. level.setBlockAndUpdate(pos, recipe.resultState())
        // 7. damageTool(player, itemStack) —— 概率损伤，**常数自己定**（不抄 400）
        // 8. setCooldownForItems（按 TFC LevelTier）
        // 9. sound.play + swing + setCancellationResult(sidedSuccess) + **event.setCanceled(true)**
    }
}

// ③ Action 枚举（4 种，语义照反编译）
public enum Action implements StringRepresentable {
    DROP_CENTER, DROP_ABOVE, DROP_CARDINAL, SHOOT_AS_BLOCK
}
```

🛑 **两条硬约束**（§7.2.4.2 反编译结论）：
1. **`inputState` 只能枚举完整 `BlockState`** ⇒ 载体方块**状态数 ≤ 8**
2. 🛑 **不能直接加工作物方块**（蔓延型作物 `age×fruiting×4向side` = 192 个状态）
   ⇒ 必须用**专用载体**：沤麻池 / 脱粒垫 / 晒架 / 碾磨槽 / 压榨槽（§7.2.5 的 5 个，共 20 状态 / 11 配方 / 11 贴图，**全部无需 BE**）

### 3.4 机器 BE 基类（**性能红线的落地**）

```java
public abstract class MyMachineBlockEntity extends BlockEntity {
    @Override
    public void serverTick(Level level, BlockPos pos, BlockState state) {
        if (!isActive()) return;        // 🛑 判据 1：空闲时零开销
        // 判据 2：不遍历附近方块 —— 用事件 / 邻居更新触发
        // 判据 3：一切循环有上限（BFS ≤ 4096 格）
    }
    protected abstract boolean isActive();
}
```

⚠️ **17 台设备需要 BE**（§9.2）⇒ 这个基类决定它们的性能上限。

### 3.5 mixin 基建

```jsonc
// tfcagricultureplus.mixins.json
{
  "required": true,                       // 🛑 规则 4：失败即崩，不静默失效
  "package": "com.example.tfcfarmingplus.expansion.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins":      [ /* P0：TFC 腐坏推进（FoodCapability / FoodData） */ ],
  "client":      [],
  "server":      []
}
```

🆕 **条件让位组**（§12.6.4 —— firmalifehardcore 已 mixin 同一批类）：

```jsonc
// tfcagricultureplus.conditional.mixins.json
{
  "required": false,                      // ⚠️ 让位组必须 false
  "package": "com.example.tfcfarmingplus.expansion.mixin.conditional",
  "mixins": [
    "ClimateMixin",                       // 温室气候
    "FoodShelfBlockEntityMixin",          // 保鲜容器
    "HangerBlockEntityMixin",
    "LargeVesselBlockEntityMixin",
    "PumpingStationBlockEntityMixin",     // 灌溉
    "SprinklerBlockEntityMixin",
    "AbstractSprinklerBlockMixin",
    "ThermometerMixin"
  ]
}
```

⇒ **运行时检测**：`ModList.get().isLoaded("firmalifehardcore")` 为真 ⇒ **不加载该组** + 日志提示。

### 3.6 覆盖台账机制（§5.5 的 197 项）

```markdown
<!-- OVERRIDE-REGISTRY.md 的条目格式 -->
| # | 路径 | 类型 | 用途 | 依赖 | 回滚动作 | 批次 |
|---|---|---|---|---|---|---|
| 1 | `assets/tfc/models/block/crop/cabbage_age_0.json` | A 资源覆盖 | 卷心菜几何 | A | 删文件 | -1 |
```

🛑 **必须登记的四类**（每批次更新）：
1. **资源覆盖**（`assets/tfc/**`、`assets/firmalife/**`）
2. **数据覆盖 / 追加**（`data/**`）
3. 🆕 **mixin**（**既不在 `assets/` 也不在 `data/`** ⇒ 最容易漏）
4. 🆕 **A 侧改动**（`MySpeciesApi` 是唯一一处）

**自检脚本**：对比台账行数与磁盘实际文件数 ⇒ 不一致即报错（§1.7 的门禁脚本加一段即可）。

---

## 四、实施批次（把主方案 §9.1~9.4 转成可执行批次）

### 4.1 批次总览

| 批次 | 内容 | 产出 | 依赖 |
|---|---|---|---|
| **-1** | **拆包**（§一） | 新建 `moddev/tfcagricultureplus/` + 门禁脚本 + **空 B jar 进游戏** | — |
| **0** | **A 侧批次 1**（§2.3） | `MySpeciesApi`（**唯一要改 A 的地方**） | -1 |
| **1** | B 骨架 | 注册表 ×4 + 入口 + 创造页 + `client/` 渲染层清单 | 0 || **2** | ⭐ **B 接管草莓**（最小覆盖，验证覆盖链路） | 覆盖 TFC `plant/strawberry_bush` + 普通作物形态 | 1 |
| **3** | **覆盖台账机制**（§3.6） | `OVERRIDE-REGISTRY.md` + 自检 | 2 |
| **4** | **mixin 基建 + P0 两个 mixin** | 腐坏推进（`FoodCapability`/`FoodData`）+ 温室气候 | 1 |
| **5** | **`in_world` 配方类型**（§3.3） | 配方类型 + 处理器 + 4 种 Action | 1 |
| **6** | **5 个载体方块**（§7.2.5） | 沤麻池 · 脱粒垫 · 晒架 · 碾磨槽 · 压榨槽（**零 BE**） | 5 |
| **7** | **第一台设备试点**（干燥架） | 验证「机器 BE 基类 + 数据驱动配方」范式 | 1 · 5 |
| **8** | **补链型**（§5.1.1 定则） | 茶 / 咖啡 / hops / **纤维 5 种**（沤麻链） | 5 · 6 |
| **9** | 调料 + 派（§6.5） | 香料 8 种 + **依赖批次 4 的 mixin** | 4 |
| **10** | L-1 物种覆盖 | 葡萄（棚架）· 8 香料 · TFC 29 作物 · TFC 11 灌木 | 1 · 3 |
| **11** | L-2 / L-3 | §5.3.1 的 15 条链 + 温室 / 地窖 / 灌溉 | 4 · 7 |

⚠️ **批次 0~3 是「零玩家可见内容」批次** —— 它们不产出可玩内容，但**决定后面一切能否安全落地**。
🛑 **不得跳过**（用户口径：在真正开始工作之前一定要把计划打磨足够详尽）。

🆕 **§十四 最终确定的 15 个食品加工方块**（**案板** · **刀具架** · **水槽** · **烘焙石** · **6 个模具**〔面包模 · 派盘 · 方盘 · 松饼连模 · 平烤盘 · 条模〕· **干燥架** · ⭐**酵母罐** · ⭐**醋母罐** · **糖果碗** · **熟食板**）
+ 🆕 **4 个手持工具**（石臼+杵 · 簸箕 · 筛 · 连枷 —— **物品，不是方块**）
+ 🆕 **3~5 台动力设备**（动力磨 · 动力榨油机 · 动力脱粒机 —— 基于 TFC `SinkNode`）
+ 🆕 **9 个新配方类型**（`in_world` · `feast` · `mortar` · `dough_shaping` · `melting` · `juicing` · `evaporating` · `chilling` · `starter`）
+ 🆕 **7 个厨房家具方块**（§十七：**橱柜台面 · 半高柜 · 水槽柜 · 刀具架 · 香料架 · 食品展示柜 · 果盘** —— ⚠️ **我之前把这一族当"装饰"误排除了，实测它们全都有 BE+Menu+Screen**）
+ 🆕 **3 个补充**（巧克力火锅[feast 类] · 野餐篮 · 巧克力盒）
+ 🆕 **12 个新品类 / ≈110 项产物**（§十五：糖与甜味剂 · 奶制品 · **大豆制品** · 蛋制品 · 巧克力 · 糖果 · 肉制品熟食 · 酱料 · 饮品 · 面食烘焙 · 腌渍发酵 · 藻类制品 —— ⭐ **其中大豆/腌渍/海苔是 extradelight 没有的东亚品类**）
+ 🆕 **10 个可放置食物方块**（§十六：**整派 · 整蛋糕 · 奶酪块 · 黄油块 · 糖块 · 果冻块 · 大餐锅 · 熟食拼盘 · 腌渍坛 · 挂晒串** —— ⭐ **前 8 个共用 1 个 `CuttableFoodBlock` 类**，份数存 BE 不存 blockstate）
+ 🆕 **1 项重制**（Firmalife `drying_mat` 的**资源覆盖**，保留其 16 条配方）

⇒ **B 的方块总数 ≈ 33 个**（§9.2 的 18 台 + 15 个）；⚠️ **6 个模具共用 1 个方块类** ⇒ 实际方块类 ≈ **10 个**。
⚠️ **其中约 10 个需要 BE** ⇒ §12.4 的性能红线直接适用。
🛑 **§十二 的 9 个方块与 §13.3 的 3 个方块已相继撤销**（用户口径，见 §13.1 / §13.7）。

### 4.2 每个批次的「改动文件 + 验收」

**每个批次收口时必须产出 3 样**：
1. **改动清单**（新增/修改的文件，逐个列出）
2. **覆盖台账更新**（§3.6）
3. **验收记录**（§五 的三层验证）

### 4.3 ✅ 批次 1 **执行记录**（2026-10-05，实测）

#### 交付物（**21 条目 jar / 17.8 KB**）

| 类别 | 内容 |
|---|---|
| **Java**（6 个 / 370 行） | `TFCAgriculturePlus.java` 53 · `client/TFCAgriculturePlusClient.java` **56** · `common/MyBlocks.java` **128** · `MyItems.java` **65** · `MyCreativeTab.java` 38 · `MyBlockEntities.java` 30 |
| **资源**（12 个） | blockstates ×2 · models/block ×2 · models/item ×3 · textures ×3 · lang ×2（**en_us + zh_cn**） |
| **产物** | **`TFCAgriculturePlus-...jar` 17.8 KB**（从批次 -1 的 8.9 KB 增长） |

#### 内容：2 个方块 + 1 个手持工具

| 项 | 说明 |
|---|---|
| ⭐ **案板**（`cutting_board`） | **用户明确保留的唯一方块**（126 §13.1）—— "所有食品加工的第一道工序"<br>状态 `facing × 4` ✅ |
| ⭐ **刀具架**（`knife_block`） | 与案板配套（126 §14.5 #2）<br>状态 `facing × 4` ✅ |
| ⭐ **石臼**（`stone_mortar`） | **手持工具**（126 §13.8）—— 验证"物品链"<br>⚠️ 与 TFC `quern` 的分工已写进类注释（臼=粗磨/随身，磨=细粉/固定） |

⚠️ 三者的 **`in_world` 交互**（切菜 / 放刀 / 研磨）**留到批次 5**（配方类型就绪后）。

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `check-boundaries.ps1`（六红线 + 协议） | ✅ 退出码 0 |
| 2 | `verify-registry.ps1` | ✅ **`[OK] resources and registrations match (2 blocks)`** |
| 3 | `gradle build` | ✅ **BUILD SUCCESSFUL in 15s** |
| 4 | 🎯 **B 的渲染层自检** | ✅ **`[渲染层自检] 已注册方块 2 个，全部有归属（cutout 2 / 无需登记 0）`** |
| 5 | A 不受影响 | ✅ `已注册方块 474 个，全部有归属` |
| 6 | 实机进世界 | ✅ `Starting integrated minecraft server` + `Loaded 1551 advancements` + `Time elapsed: 428 ms` |
| 7 | `Unknown registry key` / `Couldn't parse element` / `Unable to load model` / **本模组 ERROR** | ✅ **全部 0 处** |
| 8 | ⚠️ `Missing textures`（1 处） | ✅ **属于 `afc:wood/leaves/mahoe`**（afc 自己的贴图名 bug，与本项目无关） |

#### 🆕 批次 1 踩到的**三个真实坑**（已修，全部值得记住）

| # | 坑 | 现象 | 修法 |
|---|---|---|---|
| **1** | ⭐ **1.21.1 的 `Block.codec()` 是抽象的** | `HorizontalFacingBlock 不是抽象的, 并且未覆盖 HorizontalDirectionalBlock 中的抽象方法 codec()` ⇒ **编译失败** | 实现 `codec()`：`return simpleCodec(HorizontalFacingBlock::new);` |
| **2** | ⭐ **`@EventBusSubscriber(bus = ...)` 已过时** | 编译警告 `Bus 已过时, 且被标记为待删除` | 去掉 `bus = EventBusSubscriber.Bus.MOD`（1.21.1 起自动判别） |
| **3** | ⭐⭐ **`verify-registry.ps1` 的**两个误报（**脚本自身的 bug**） | ① `registerWithItem()` 是**新工厂**，脚本没登记 ⇒ 误报"blockstate 未注册"<br>② `CREATIVE_TABS.register("main")` 被当成方块 ⇒ 误报"注册了但没 blockstate"<br>③ ⚠️ **PowerShell 单元素数组退化为标量** ⇒ `$a + $b` **字符串拼接**而非并集（输出 `maincutting_board knife_block`） | ① `$factories` 加 `registerWithItem`<br>② 加 `$noise` 排除非方块注册<br>③ **所有拼接处强制 `@(...)`** |

⇒ ⭐ **坑 3 正是 `verify-registry.ps1` 的价值所在**：**它抓到了"出现了新工厂模式"** ——
但同时也说明 §5.2 里那句"**新加工厂时必须同步登记 `$factories` 表**"是**必须遵守的维护纪律**
（脚本已在注释里写死这条提醒）。

#### 与 §4.1 批次表的差异（**如实记录**）

| 项 | 计划 | 实际 |
|---|---|---|
| 批次 1 内容 | "注册表 ×4 + 入口 + 创造页 + 渲染层清单" | ⚠️ **这些在批次 -1 已建** ⇒ 批次 1 改为**做 2 个真实方块 + 1 个手持工具**，把链路**端到端跑通**（注册 → 资源 → 渲染 → 创造页 → 实机） |

⇒ 🆕 **修正**：批次 -1 交付的是**空骨架**；批次 1 交付的是**第一个可玩内容**。
两者合起来才等于原计划的"批次 1"。

### 4.4 ✅ 批次 1 **修订（rev2）**（2026-10-05，按用户口径）

> 用户口径：「**方块模型过于不可辨认，碰撞箱和实际模型不贴切，材质更多要复用 tfc（和附属模组）已有材质，
> 涉及到木材或者石材的物品记得添加等同的材质变种**，以及修复 bug」

#### 🎯 四项修正

| # | 用户指出的问题 | 修法 | 结果 |
|---|---|---|---|
| **1** | **模型过于不可辨认** | **重做几何**：<br>· 案板 = **板身（16×2×16）+ 四边挡边**（像真砧板，不再是"一张纸"）<br>· 刀架 = **背板（16×15×2）+ 底座（16×3×6）+ 两道横档**（一眼看出是插刀的架子） | ✅ 见 §4.4 的模型结构 |
| **2** | **碰撞箱与模型不贴切** | ⭐ **每个方块实现 `getShape()`**：<br>· 案板 `box(0,0,0, 1, 0.125, 1)`（**只到板身 2px**，挡边不挡人）<br>· 刀架 `box(0,0,0.375, 1, 0.9375, 0.75)`（背板+底座整体） | ✅ 与几何一致 |
| **3** | **材质没复用 TFC** | 木制 → **`tfc:block/wood/planks/<wood>` + `tfc:block/wood/log/<wood>`**<br>石制 → **`tfc:block/rock/chiseled/<rock>` + `tfc:block/rock/bricks/<rock>`**<br>🆕 **自有贴图从 3 张降到 1 张**（只剩石臼） | ✅ **家具 0 张自有贴图** |
| **4** | **缺材质变种** | 程序化注册 **89 个变种**：木制案板 **34**（TFC 20 + afc 14）· 石制案板 **21** · 刀具架 **34** | ✅ 实测自检通过 |

#### ⭐⭐ 关键技术：**共享几何 + 每树种一个薄模型**（学 Firmalife）

**实测 Firmalife 的做法**（`models/block/wood/jarbnet/oak.json`）：
```json
{"parent":"firmalife:block/jarbnet",
 "textures":{"planks":"tfc:block/wood/planks/oak","sheet":"tfc:block/wood/sheet/oak","log":"tfc:block/wood/log/oak"}}
```

⇒ 🎯 **这就是"全材质可行"的真正原因**：
- **几何只写一次**（共享父模型，用 `#planks` / `#log` 占位）
- **每个树种一个 3 行的子模型**（只换贴图引用）
- ⇒ **34 树种 × 1 个 3 行 json**，而不是 34 套几何

**我们的落地**：
| 文件 | 数量 | 内容 |
|---|---|---|
| `models/block/cutting_board.json` | 1 | **共享几何**（板身 + 四边挡边，5 个 element） |
| `models/block/knife_block.json` | 1 | **共享几何**（背板 + 底座 + 两道横档，4 个 element） |
| `models/block/cutting_board/<mat>.json` | **55** | 每个 1 行 `parent` + 2 个贴图引用 |
| `models/block/knife_block/<mat>.json` | **34** | 同上 |
| `blockstates/<...>/<mat>.json` | **89** | 4 向 `facing` |
| `models/item/<...>/<mat>.json` | **89** | 指向对应的 block 模型 |

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `check-boundaries.ps1` | ✅ 退出码 0 |
| 2 | ⭐ **`verify-registry.ps1 -FromLog`（运行时模式）** | ✅ **`[OK] resources and registrations match (89 blocks)`** |
| 3 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 4 | 🎯 **B 的渲染层自检** | ✅ **`已注册方块 89 个，全部有归属（cutout 89 / 无需登记 0）`** |
| 5 | 🆕 **材质自检** | ✅ **`木制案板 34（TFC 20 + afc 14）· 石制案板 21 · 刀具架 34`** |
| 6 | A 不受影响 | ✅ `已注册方块 474 个` |
| 7 | 实机进世界 | ✅ `Starting integrated minecraft server` + `Loaded 1551 advancements` |
| 8 | registry 类错误 | ✅ `Unknown registry key` / `Couldn't parse element` / `Failed to load registries` / `Unable to load model` **全部 0 处** |

#### 🆕 本次踩到并修好的**四个真实坑**

| # | 坑 | 现象 | 修法 |
|---|---|---|---|
| **1** | 🛑🛑 **JavaDoc 里的 `*/` 序列会提前结束注释** | 我在注释里写了 `tfc:block/rock/*/<rock>` ⇒ **`*/` 把注释截断** ⇒ 后续中文注释被当成代码 ⇒ **编译报"非法字符 '：'"与"需要 class"**（**报错行号指向注释之后，极具误导性**） | 把 `<wood>` 写成 `&lt;wood&gt;`，并**移除 `/*/` 序列**。🆕 **教训：JavaDoc 里凡出现 `*/` 的地方都要转义或改写** |
| **2** | **`verify-registry.ps1` 的静态模式对"循环生成的变种"完全失效** | 变种名是 `"cutting_board/" + wood`（**字符串拼接**）⇒ 正则提取到 **0 个 ID** ⇒ 89 个全部误报"未注册" | ⭐ **新增运行时模式**：client 侧加 `-Dtfcfarmingplus.dumpBlockIds=true` 开关，把**真实注册的 ID 打进日志**；脚本加 `-FromLog <log>` 读日志 ⇒ **`read 89 block ids`** |
| **3** | **`-D` 开关没有传入 JVM** | `launch-client.ps1` 是共享脚本（A/B 共用），**不宜擅自改** | ⭐ **用 `JAVA_TOOL_OPTIONS=-Dtfcfarmingplus.dumpBlockIds=true` 环境变量** ⇒ JVM 自动应用，**零改脚本** |
| **4** | **日志行首不是 `[BLOCK-ID]`** | 我用 `^\[BLOCK-ID\]` 锚定行首 ⇒ 提取 0 行（实际行首是时间戳） | 正则改为 **`\[BLOCK-ID\]\s+([a-z0-9_/]+)\s*$`**（锚定 token 本身） |

#### 📌 本次的方法论收获（写进 §5.2）

🆕 **`verify-registry.ps1` 现在有两种模式**：

| 模式 | 命令 | 适用 | 可靠性 |
|---|---|---|---|
| **静态**（默认） | `verify-registry.ps1` | 字面量注册 / 已知工厂 | ⚠️ **循环生成的变种看不见** |
| ⭐ **运行时** | `verify-registry.ps1 -FromLog <log>` | **全部情况** | ✅ **权威口径**（读真实注册结果） |

⇒ 🛑 **结论：只要出现了"循环生成的方块"，就必须用运行时模式** ——
这条已写进 §5.2 的脚本注释里（静态模式会主动提示 `prefer -FromLog`）。

### 4.5 ✅ 批次 1 **修订（rev3）**（2026-10-05，按用户 6 条口径）

> 用户口径：
> ①「这里的叶子游戏内显示效果就是这样，**记下该教训先不做修改**」
> ②「**案板不需要明显的外缘**，进行修改」
> ③「**几个方块的物品栏渲染存在问题**，修复」
> ④「**石臼根本不能放出**，进行修复」
> ⑤「石臼也应该存在**多种变体**，查找并**查证适合作为"石臼"的岩石种类**并且添加变体」
> ⑥「**先为后续的加工配方引入和 jei 适配做好代码基础**」

#### ① 叶子渲染教训（**只记录，未修改**）

| 项 | 内容 |
|---|---|
| **现象** | 杏树叶（A 层果树）游戏内是**一个不透明的绿色立方体 + 少量透明**，看起来像"一块绿石头"而不是树叶 |
| **截图证据** | 用户提供的游戏内截图（2026-10-05），tooltip 显示 `TFC Farming Plus` —— 说明是 **A 层的果树叶子** |
| 🛑 **处置** | **本轮不改**（用户明示）—— 只**记入文档**，等后续专门处理 |
| ⚠️ **教训** | **"资源齐全 + verify 全绿" ≠ "画面正确"** —— 叶子这类**需要 `cutout` + 透明像素**的方块，必须在**实机里看**才知道效果（AGENTS.md 第 42/48 轮的同类教训） |

#### ② 案板去掉外缘

| 项 | 内容 |
|---|---|
| **改动** | 几何从"板身 + 四边挡边（5 个 element）"改为**只剩平坦厚板**（`[0,0,0]→[16,2,16]`，1 个 element） |
| **连带** | 89 个变种子模型**去掉了 `log` 贴图引用**（只留 `planks`） |

#### ③ 物品栏渲染修复

| 项 | 内容 |
|---|---|
| **问题** | 方块在物品栏里的显示角度/大小不对（Minecraft 对"方块模型"与"物品模型"的默认变换不同） |
| **修法** | 给 **89 个 item 模型**全部加 **`display` 变换**（`gui` 30°/225° 缩放 0.625 · `ground` · `fixed` · 第三人称 · 第一人称 · `head`） |
| **依据** | 这是原版方块物品的标准做法（`minecraft:block/*` 的 `display` 段） |

#### ④⑤ 石臼：**从物品改为方块** + **15 种岩石变体**（含现实查证）

| 项 | 内容 |
|---|---|
| **原问题** | 批次 1 把石臼做成**纯物品** ⇒ **无法放置**（用户："根本不能放出"） |
| **修法** | 改为**方块**（`mortar/<rock>`，104 个方块总数中的 15 个）· 几何 = **底板 + 四壁**（中间凹）· 碰撞箱 = 整方块 |
| 🆕 **岩石选择的现实依据** | 石臼靠**研磨与撞击**工作 ⇒ 要求**硬度高、耐磨、无孔隙**：<br>✅ **火成岩 8 种**：`basalt`（**传统石臼主力**）· `andesite` · `dacite` · `rhyolite` · `granite` · `diorite` · `gabbro` · `tuff`<br>✅ **变质岩 6 种**：`gneiss` · `schist` · `phyllite` · `slate` · `marble` · `quartzite`<br>✅ **燧石 1 种**：`chert`（**硬度 7，最硬**）<br>❌ **排除 6 种软质沉积岩**：`chalk` · `claystone` · `conglomerate` · `dolomite` · `limestone` · `shale`（硬度低/有孔隙/易碎 ⇒ **研磨会掉渣，现实里也不用它们做臼**） |
| **结果** | **15 种变体**（8 火成 + 6 变质 + 1 燧石）⇒ 自检日志会打印 |

#### ⑥ 配方基建 + JEI 适配（**为后续 12 个配方类型打基础**）

| 新增 | 内容 |
|---|---|
| `common/recipe/MyRecipeTypes.java` | 配方**类型**注册表（照 TFC 的 `TFCRecipeTypes`）—— 已建 `mortar`，其余 11 个占位列出 |
| `common/recipe/MyRecipeSerializers.java` | 配方**序列化器**注册表（照 TFC 的 `TFCRecipeSerializers`） |
| `common/recipe/MortarRecipe.java` | 🆕 **第一个配方类型**（研磨）—— **`MapCodec` + `StreamCodec` 双编解码器**，照 TFC 的 record 写法 |
| `compat/jei/MyJeiPlugin.java` | 🆕 **JEI 插件**（`@JeiPlugin`）：注册 category / recipes / **catalysts**（15 种石臼都是催化剂） |
| `compat/jei/MortarRecipeCategory.java` | 🆕 JEI 展示类（后续 11 个类型的**模板**） |
| `data/.../recipe/mortar/link_test_limestone.json` | 🆕 **链路验证配方**（真实 ID，批次 5 会替换成真实加工链） |
| **依赖方式** | 🛑 **JEI 是 optional**（学 TFC 的实测写法：`type = "optional"` · `side = "CLIENT"` · gradle 用 **`compileOnly`**）⇒ **没有 JEI 也能正常加载** |

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | 🎯 **B 渲染层自检** | ✅ **`已注册方块 104 个，全部有归属（cutout 104 / 无需登记 0）`**（89 → 104，+15 石臼） |
| 3 | 材质自检 | ✅ `木制案板 34（TFC 20 + afc 14）· 石制案板 21 · 刀具架 34` |
| 4 | **配方加载** | ✅ `Loaded 9173 recipes`（比上次 9172 **多 1** ⇒ 我们的 `link_test_limestone` 被正确解析）⭐ |
| 5 | **JEI 启动** | ✅ `Starting JEI...` → `Added 9285 ingredients`（**没有 JEI 插件的报错**） |
| 6 | A 不受影响 | ✅ `已注册方块 474 个` |
| 7 | `Failed to load registries` / `Mod loading has failed` / `Unable to load model` | ✅ **全部 0 处** |

#### 🆕 rev3 的**一个新发现**：JEI 的本地缓存会引用"已删除的物品"

| 项 | 内容 |
|---|---|
| **现象** | 日志报 `Unknown registry key ... minecraft:item]: tfcagricultureplus:stone_mortar` |
| **根因** | ⚠️ **不是我们的 bug** —— 是 **JEI 的"查找历史"缓存**（`config/jei/world/local/tfctest/lookupHistory.json`）里**存了用户曾经用 JEI 收藏过的 `stone_mortar`**，而该物品在 rev3 被删掉了 ⇒ **JEI 读缓存时找不到物品** |
| **处置** | 备份并尝试清理该缓存；⚠️ 由于 JEI 在退出时会**重写**它，若下次启动仍报，需在 JEI 界面里"清除历史" |
| 🆕 **教训** | **删除一个已发布的注册项时，要考虑第三方模组的本地缓存**（JEI 的 lookupHistory / 书签）—— 这类错误**不影响游戏**，但会在日志里留下 `ERROR`，干扰验证 |

#### 🆕 rev3 踩到的**两个 JEI API 坑**（已修）

| # | 坑 | 修法 |
|---|---|---|
| **1** | **`IRecipeRegistration.addRecipes` 的参数是 `List<T>`，而 `getAllRecipesFor` 返回 `List<RecipeHolder<T>>`** | 必须 **`.stream().map(RecipeHolder::value).toList()`**（TFC 的 `JEIIntegration` 也是这么做） |
| **2** | **JEI 19.x 起 `IRecipeCategory.getBackground()` 已过时** | 去掉该方法，改用 **`getWidth()` / `getHeight()`**（背景改在 `createRecipeExtras` 里画） |

### 4.6 ✅ 批次 1 **修订（rev4）**（2026-10-05，按用户 7 条口径）

> 用户口径：
> ①「**案板添加原木材质的版本以供早期使用**」
> ②「这几个方块模型**不要挤满整个方块**」
> ③「**石臼侧壁太粗**」
> ④「**刀架的要有存储功能**（存储刀具和未来添加的调料罐），刀架的**侧面材质有缺失**，并且材质存在 **zfighting** 问题」
> ⑤「**tfc 不存在燧石岩，不要添加燧石质地的方块**」
> ⑥「石臼的"**石杵**"使用**打制工艺**从**特定的石头类型**中制作（**包括燧石和黑曜石质地**）」
> ⑦（隐含）修 bug

#### 逐条落实

| # | 口径 | 做法 |
|---|---|---|
| **①** | 原木案板 | 🆕 新增 {@code log_cutting_board/<wood>} **34 树种**（TFC 20 + afc 14），贴图用 `tfc/afc:block/wood/log/<wood>` —— **早期没锯也能做** |
| **②** | 不挤满方块 | 三条几何**全部缩小到 14/16**：<br>· 案板 = **14×1×14 台面 + 4 条腿**（真实砧板有腿）<br>· 石臼 = **14×9×14**<br>· 刀架 = **14 宽 + 靠墙（z=5..12）** |
| **③** | 石臼侧壁太粗 | 壁厚 **4px → 2px**（`from [1,x,1] to [15,x,3]` 之类） |
| **④** | 刀架存储 + 侧面缺失 + z-fighting | ① 🆕 **加 BE**：`KnifeBlockBlockEntity`，**9 格**（刀具 + 未来调料罐），**右键存取**（手持存入 / 空手取出最后一件）<br>② **补侧面贴图**：新几何的每个面都显式给 `texture`（旧几何有面漏了贴图槽）<br>③ **修 z-fighting**：各 element 的平面**不再共面**（背板 z=10..12、底座 z=5..11、两道横档 z=9..10，互不重叠） |
| **⑤** | 不要燧石质地**方块** | 石臼 **15 → 14 种**（移除 `chert`）。⚠️ **如实记录**：实测 TFC 里 `chert` 确实是一种岩石（`block.tfc.rock.raw.chert = Raw Chert`），但**遵从用户口径** |
| **⑥** | 石杵用**打制**工艺 | 🆕 **7 种石杵**（见下），全部通过 `tfc:knapping` + `knapping_type: tfc:rock` 打制 |

#### 🆕 ⑥ 石杵的实现（**含一个 TFC 的硬约束**）

**实测 TFC 的打制机制**：
- `knapping_type` 共 6 种：`leather` · **`rock`** · `clay` · `fire_clay` · `goat_horn`（+1 未列）
- `KnappingPattern.CODEC` = `Codec.STRING.listOf(1, 5).fieldOf("pattern")` + `Codec.BOOL.optionalFieldOf("default_on")`
  ⇒ ⚠️ **`pattern` 必须是 5×5**，否则报 **`default_on is required if the pattern is not 5x5`**

🛑🛑 **本轮踩到的关键硬约束**：TFC 的打制界面**要求每种材料有一张 GUI 贴图**
（`tfc:textures/gui/knapping/<材料路径>.png`）。实测 TFC 只提供：
| 有的 | 没有的 |
|---|---|
| ✅ `rock/loose/<rock>.png` × **21** | ❌ **`flint.png`** |
| ✅ `rock/mossy_loose/<rock>.png` × 21 | ❌ `groundcover/flint.png`（该方块**掉落的是 `minecraft:flint`**，见其 loot table） |
| ✅ `groundcover/obsidian_shard.png` | |

⇒ ⚠️ 我第一版用 `minecraft:flint` ⇒ 游戏报
`FileNotFoundException: tfc:textures/gui/knapping/flint.png`
⇒ 🛑 **我们不去 TFC 命名空间塞贴图**（与红线 2 同类：不覆盖邻居资源）
⇒ **改用可打制的硬质散石 + 黑曜石**：

| 石杵 | 打制材料 | 现实依据 |
|---|---|---|
| **黑曜石杵** | `tfc:groundcover/obsidian_shard` | 火山玻璃，硬度 5~6、断口锋利；TFC 已用它做刀/斧/锤 |
| **玄武岩石杵** | `tfc:rock/loose/basalt` | **传统石臼/石杵主力材质** |
| **花岗岩石杵** | `tfc:rock/loose/granite` | 硬度高、结晶致密 |
| **闪长岩石杵** | `tfc:rock/loose/diorite` | — |
| **辉长岩石杵** | `tfc:rock/loose/gabbro` | — |
| **石英岩石杵** | `tfc:rock/loose/quartzite` | 硬度接近石英 |
| **板岩石杵** | `tfc:rock/loose/slate` | 易劈成薄片，便于成型 |

⚠️ **燧石版暂缓**（`minecraft:flint` 无 GUI 贴图 + TFC 无燧石物品 + 不覆盖 TFC 资源）——
**已在 `MyItems` 的类注释里写明原因**，等后续有自建 GUI 贴图时再补。

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | 🎯 **B 渲染层自检** | ✅ **`已注册方块 137 个，全部有归属（cutout 137 / 无需登记 0）`**<br>（89 + 34 原木案板 + 14 石臼 = **137**） |
| 3 | **配方加载** | ✅ **`Loaded 9180 recipes`**（上轮 9175 ⇒ **净 +5** = 删 2 旧的 + 加 7 打制） |
| 4 | 🎯 **打制配方解析** | ✅ **`Parsing error loading recipe` 0 处** |
| 5 | 🎯 **knapping GUI 贴图** | ✅ **`Failed to load texture ... knapping` 0 处**（燧石问题已解决） |
| 6 | A 不受影响 | ✅ `已注册方块 474 个` |
| 7 | registry 类错误 | ✅ `Failed to load registries` / `Mod loading has failed` / `Unable to load model` / **`Invalid block entity`** 全部 **0 处** |
| 8 | 本模组 ERROR | ✅ **0 处** |

#### 🆕 rev4 踩到的**四个技术坑**（全部值得记住）

| # | 坑 | 现象 | 修法 |
|---|---|---|---|
| **1** | ⭐⭐ **`BlockEntityType` 不能直接 `new`** | `new BlockEntityType<>(...)` 报 **"无法推断类型参数"** / **"无法将构造器应用到给定类型"** | ⭐ **用 TFC 的 `RegistrationHelpers.register(reg, name, factory, Stream<Supplier<Block>>)`** —— 实测 **TFC 与 Firmalife 都这么做**（`import net.dries007.tfc.util.registry.RegistrationHelpers`） |
| **2** | ⭐⭐ **TFC 的 `knapping` 要求 `pattern` 是 5×5** | `default_on is required if the pattern is not 5x5` | `pattern` 用**严格 5 行 × 5 字符**，并显式写 `"default_on": false` |
| **3** | ⭐⭐ **TFC 的 `groundcover/flint` 不是物品** | `Unknown registry key ... minecraft:item]: tfc:groundcover/flint` | 实测其 loot table 掉落 **`minecraft:flint`** ⇒ 燧石应用原版 ID；⚠️ 但原版 ID 又触发 **坑 4** |
| **4** | ⭐⭐⭐ **打制界面要求材料有 GUI 贴图** | `FileNotFoundException: tfc:textures/gui/knapping/flint.png` | 只能选 TFC **已有 GUI 贴图**的材料（21 散石 + 黑曜石碎片）；**不往 TFC 命名空间塞文件** |
| **5** | ⚠️ **`Get-Content -Raw` 读写 UTF-8 会双重编码乱码** | `zh_cn.json` 被写成乱码 ⇒ JSON 非法 | 🛑 **绝不用 `Get-Content -Raw` 读写 UTF-8 文件**（AGENTS.md §8.2-3 早有记录，本轮又踩一次）⇒ 用 `ReadAllBytes` + `UTF8.GetString`，**或直接从头重建** |

#### 交付物

| 项 | 数量 |
|---|---|
| **Java** | **12 文件 / 1,197 行**（+`KnifeBlockBlockEntity` · +2 配方类 · +2 JEI 类） |
| **资源** | **439 文件**（blockstates **137** · models/block **140** · models/item **145** · textures **7** · **recipe 8**） |
| **产物** | **188.8 KB** |

### 4.7 ✅ 批次 1 **修订（rev5）**（2026-10-05，3 条口径）

> 用户口径：
> ①「**chert 在 tfc 里面是硅质岩**」
> ②「**案板模型修改，不需要下面的腿**」
> ③「**原木类型的案板应该显示为一个"木桩子"**」

#### ① chert = **硅质岩**（不是"燧石"）⇒ **加回石臼**

🛑 **这是一次译名误解的更正**：
- rev4 我按「tfc 不存在燧石岩」把 `chert` 从石臼里移除了
- 用户澄清：**TFC 的 `chert` 中文名是「硅质岩」**（SiO₂ 质沉积岩，**硬度 7**）
- ⇒ **「燧石岩」这个说法不存在，但硅质岩存在且完全够格做石臼**
- ✅ **石臼 14 → 15 种**；中文名 `硅质岩石臼`（不是"燧石石臼"）
- ⚠️ **真正的"燧石"在 TFC 里是 `minecraft:flint`**（见 `groundcover/flint` 的掉落表）——
  这与 rev4 的发现一致，两者是**不同的东西**

#### ② 案板去掉腿

| 项 | 内容 |
|---|---|
| **改动** | 几何从"14×1×14 台面 + 4 条腿"简化为**只有 14×1×14 的台面**（1 个 element） |
| **碰撞箱** | 同步改为 `box(0.0625, 0, 0.0625, 0.9375, 0.0625, 0.9375)` |

#### ③ 原木案板 = **木桩子**（独立几何）

| 项 | 内容 |
|---|---|
| **改动** | 原木案板**不再复用案板几何**，改为**竖立的一段原木（树桩）** |
| **几何** | 柱身 `[2,0,2] → [14,10,14]`（**12×10×12**） |
| **贴图** | 侧面 = **树皮** `tfc/afc:block/wood/log/<wood>`<br>顶面 = **年轮截面** `tfc/afc:block/wood/log_top/<wood>` |
| **碰撞箱** | `box(0.125, 0, 0.125, 0.875, 0.625, 0.875)` |
| **方块类** | `LogCuttingBoardBlock` 从"继承 `CuttingBoardBlock`"改为**独立继承 `HorizontalDirectionalBlock`**（几何与碰撞箱都不同） |
| **34 个变种** | 全部改成 `parent: tfcagricultureplus:block/log_cutting_board` + `side`/`top` 双贴图 |

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | 🎯 **B 渲染层自检** | ✅ **`已注册方块 138 个`**（137 + 1 硅质岩石臼） |
| 3 | **配方加载** | ✅ `Loaded 9180 recipes` |
| 4 | 🎯 **模型与贴图** | ✅ `Unable to load model` **0 处** · `Failed to load texture` **0 处** |
| 5 | A 不受影响 | ✅ `已注册方块 474 个` |
| 6 | registry 类错误 + 本模组 ERROR | ✅ **全部 0 处** |

#### 🆕 本轮教训（写进 §12.3 的自纠清单）

| # | 教训 |
|---|---|
| **1** | ⭐⭐ **外文术语的中文译名必须核实，不能凭字面猜** —— 我把 `chert` 当成"燧石"，因而**误删了一个完全合格的材质**。TFC 里 `chert` = **硅质岩**，`flint`（真正燧石）= `minecraft:flint`。<br>⇒ 🆕 **纪律**：涉及材质/物品名的判断，**先去 lang 文件确认中文译名**（`assets/tfc/lang/zh_cn.json`），再决定是否排除 |
| **2** | **用户口径与实测冲突时，先如实记录冲突再执行** —— rev4 我写了"实测 TFC 里 chert 确实是一种岩石，但遵从用户口径"，这个记录**让 rev5 的更正变得容易**（有据可查）。**这条做法要保留** |

### 4.8 ✅ 批次 1 **修订（rev6）**（2026-10-05，6 条口径 —— 含 tfcwoodworking 迁移侦察）

> 用户口径：
> ①「**石臼的实现参考搅拌碗（firmalife）**，只不过**石杵会消耗耐久**」
> ②「**原木案板的模型太高，将其压扁**」
> ③「**木板案板的模型微调，加个小的包边**」
> ④「**案板要设计耐久特性**」
> ⑤「案板的主要功能是**切割和分片食材**，其次也能**处理原木或者分解石砖块**」
> ⑥「**读取 tfcwoodworking 的代码和资源并且进行迁移融合和优化**（以及补全对 **arborcraft 木材**的支持），
>    其是 **mit 协议可以直接迁移**并且应用到本模组中」+「**案板的配方测试正好使用迁移的这部分木材加工流程**」

#### ①②③ 模型（**已完成**）

| # | 口径 | 实测数据 |
|---|---|---|
| **②** | 原木案板压扁 | 木桩高度 **10 → 5**（`[2,0,2] → [14,5,14]`）· 碰撞箱同步 `box(0.125,0,0.125,0.875,0.3125,0.875)` |
| **③** | 案板加小包边 | 几何从 1 个 element ⇒ **5 个**：**14×1 台面 + 四周 1px 高的窄包边**；<br>🆕 **89 个变种补 `trim` 贴图槽**：木制用 **`block/wood/log/<wood>`**、石制用 **`block/rock/bricks/<rock>`** |

#### ④⑤ 案板：耐久 + BE（**已完成**）

| 项 | 内容 |
|---|---|
| **新 BE** | `CuttingBoardBlockEntity` —— **只记耐久**，{@code MAX_USES = 128} |
| 🛑 **关键设计** | **耐久只存在 BE 里，不占 blockstate 属性** ⇒ 避免状态数爆炸（§7.2.4 的 ≤8 红线） |
| **接口** | `getUsesLeft()` · `wearRatio()` · `consume()`（返回"还能用吗"）· `repair()` |
| **不 tick** | `getTicker()` 返回 `null` ⇒ 空闲零开销 |
| **覆盖范围** | **55 个变体**（木案板 34 + 石案板 21）共用同一个 BE 类型；<br>⚠️ **原木案板不接 BE**（早期廉价工具，v1 不做耐久） |
| **功能规划** | 主 = 切/分片食材 · 次 = 处理原木 / 分解石砖 —— **靠 §4.8 的 `in_world` 机制承载**（见下） |

#### ① 石臼：参考 Firmalife 搅拌碗 + 石杵耐久（**已完成**）

**实测 Firmalife 的 `mixing_bowl`**：
| 组件 | 类 |
|---|---|
| 方块 | `MixingBowlBlock` |
| BE | `MixingBowlBlockEntity` |
| 配方 | `MixingBowlRecipe`（`{"type":"firmalife:mixing_bowl","fluid_ingredients":{...},"item_ingredients":[...],"result_i...}`） |
| 附加 | `MixingBowlBlockEntityRenderer` + EMI 适配 |

**我们的落地**：
| 项 | 内容 |
|---|---|
| **新 BE** | `MortarBlockEntity` —— **1 格容器**（v1 只做干磨，不接流体） |
| **对照关系** | Firmalife 是"物品+流体多输入 + GUI"；我们做成 **"1 格物品 + 右键流程"**（无 GUI，与刀架同一套思路） |
| **右键三分支** | ① 手持**石杵** ⇒ **研磨**（查 `MortarRecipe` ⇒ 产出 + 消耗内容物 + **石杵 -1 耐久**）<br>② 手持**其他** ⇒ 放入<br>③ **空手** ⇒ 取出 |
| **⭐ 石杵耐久** | 用户口径「石杵会消耗耐久」⇒ `pestleProps()` = **`durability(160)`**（7 种石杵全部改用它）<br>取 160 的依据：石臼+杵是**可长期使用**的工具，Firmalife 同类工具在 100~250 之间 |
| **辅助 API** | `MyItems.isPestle(ItemStack)`（石臼右键分流用）· `allPestles()`（创造页/JEI 用） |
| **覆盖范围** | **15 个岩石变体**共用同一个 BE 类型 |

#### ⑥ tfcwoodworking 迁移：**侦察完成，代码迁移待执行**

**协议核实**：`license="MIT"` · `authors="uTa4u"` · `modId="tfcwoodwork"` ⇒ ✅ **可以迁移**（用户已确认）

**资产规模**：**1,091 条目** · 39 个 Java 类 · 1.2.4 版

**核心结构（已反编译核实）**：
| 层 | 类 | 说明 |
|---|---|---|
| ⭐ **配方机制** | `recipes/inworld/` 6 个类 | **`InWorldRecipe`（record）** + `InWorldRecipeHandler` + `Action` + `Tool` + `BlockStatePredicate` + `SoundInstance` |
| **注册** | `ModRecipeTypes` · `ModRecipeSerializers` | `IN_WORLD = "in_world"` |
| **方块** | `AbstractDebarkedWood` 派生 3 个 | `DebarkedLog` · `DebarkedHalf` · `DebarkedQuarter` |
| **方块** | `LogPileExBlock` · `BurningLogPileExBlock` | 原木堆（可烧） |
| **BE** | `LogPileExBlockEntity` · `BurningLogPileExBlockEntity` | |
| **实体** | `LogHalfProjectile` · `LogQuarterProjectile` | 劈开的木头可投掷 |
| **mixin** | `AxeItemMixin` · `InteractionManagerMixin` · `StateHolderAccessor` | |
| **compat** | `compat/jei/InWorldRecipeCategory` · `compat/jade/JadeIntegration` | |
| **数据生成** | `datagen/recipes/InWorldRecipeBuilder` + `InWorldRecipeProvider` | |

**⭐ `InWorldRecipe` 的确切签名**（反编译所得）：
```java
public record InWorldRecipe(
   BlockStatePredicate inputState,          // 命中哪个方块的哪个状态
   Tool tool,                               // 用哪类工具
   BlockState resultState,                  // 方块变成什么
   Optional<SoundInstance> soundInstance,
   List<Pair<ItemStack, Action>> resultItems // 附属产出 + 动作
) implements Recipe<InWorldRecipeInput>
```

**资源结构**：
| 路径 | 数量 | 备注 |
|---|---|---|
| `data/tfcwoodwork/recipe/in_world/saw/*` | 20 | **每树种 1 个**（锯：原木→木材） |
| `data/tfcwoodwork/recipe/in_world/axe/*` | 20 | 斧：`chop_log` · `strip_wood` |
| `data/tfc/recipe/crafting/wood/planks` | **40** | ⚠️ **写进 TFC 命名空间**（覆盖 TFC 的木板配方） |
| `data/tfc/recipe/crafting/wood/lumber` | 40 | 同上 |
| `data/tfcwoodwork/tfc/fuel` | 100 | 燃料值（词条） |
| `assets/tfcwoodwork/models/block/debarked_{log,half,quarter}` | 21×3 | **每树种 1 套** |

**🛑 迁移时必须解决的三件事**：
| # | 问题 | 方案 |
|---|---|---|
| **1** | **只有 20 树种**（TFC 的），**缺 afc 的 14 种** | 用户明确要求「**补全对 arborcraft 木材的支持**」⇒ 迁移后**按 34 树种生成**（复用我们已建立的 `TFC_WOODS` + `AFC_WOODS` 双清单机制） |
| **2** | **40+40 个配方写在 `data/tfc/`**（覆盖 TFC 命名空间） | 🛑 红线 7：**必须 `replace: false`**（只加不删）；<br>⚠️ 迁移到 B 时**要重新评估是否需要覆盖 TFC 的既有配方**——B 的定位是"扩展"而非"替换" |
| **3** | **3 个 mixin**（`AxeItemMixin` 等） | ⚠️ 它们**碰的是 TFC 的类**（不是 A 的）⇒ 不违反红线 3，但**要在 `check-boundaries.ps1` 里放行**（脚本当前的正则只看 A 的类名） |

**迁移计划（下一轮执行）**：
1. 迁 `recipes/inworld/` 6 个类 ⇒ **B 的 `in_world` 配方类型**（同时服务**案板的三大功能**）
2. 迁 `DebarkedLog/Half/Quarter` 方块 + 模型 ⇒ **按 34 树种生成**
3. 迁 `LogPileExBlock` + 2 个 BE
4. 迁 `compat/jei/InWorldRecipeCategory` ⇒ 接进已有的 `MyJeiPlugin`
5. **案板配方用迁移来的木材加工流程测试**（用户口径 ⑤⑥ 的交汇点）

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL**（中途修掉 1 个编译错误，见下） |
| 2 | 🎯 **B 渲染层自检** | ✅ **`已注册方块 138 个，全部有归属`** |
| 3 | 🎯 **BE 注册** | ✅ **`Invalid block entity` 0 处**（3 个 BE 类型：刀架 34 + 案板 55 + 石臼 15） |
| 4 | 模型与贴图 | ✅ `Unable to load model` **0 处** · `Missing textures.*tfcagricultureplus` **0 处** |
| 5 | 配方 | ✅ `Parsing error loading recipe` **0 处** |
| 6 | A 不受影响 | ✅ `已注册方块 474 个` |
| 7 | 本模组 ERROR | ✅ **0 处** |

#### 🆕 rev6 踩到的坑

| # | 坑 | 修法 |
|---|---|---|
| **1** | ⭐ **1.21.1 的 `Block.playerWillDestroy` 返回 `BlockState`（不是 `void`）** | 我写了个 `void` 版本 ⇒ 编译报"无法覆盖" ⇒ **直接删掉该方法**（v1 不需要它） |

### 4.9 ✅ 批次 1 **修订（rev7）**（2026-10-05，3 条口径）

> 用户口径：
> ①「**刀架不渲染其上的物品**，进行修复」
> ②「**刀架可放置的物品进行限制**（**读取 tfc 已有的工具架进行理解学习**）」
> ③「**原木案板也要做耐久**」

#### 🔍 侦察：TFC 的工具架（`ToolRackBlock`）—— 本轮最重要的发现

🛑🛑 **TFC 早就有一个功能完整的工具架**，我们之前**完全没注意到**：

| 层 | 类 |
|---|---|
| 方块 | **`common/blocks/wood/ToolRackBlock`** ⭐（`extends DeviceBlock implements SimpleWaterloggedBlock`） |
| BE | **`common/blockentities/ToolRackBlockEntity`**（`extends InventoryBlockEntity<ItemStackHandler>`，**4 格**） |
| 渲染器 | **`client/render/blockentity/ToolRackBlockEntityRenderer`** ⭐ |
| ⭐ **白名单 tag** | **`tfc:usable_on_tool_rack`** = `{"values":["#c:tools","#tfc:sewing_needles","tfc:sandpaper","minecraft:spyglass"]}` |
| 变体 | `wood/tool_rack/<wood>`（**afc 也已提供 14 种**，共 34） |

**反编译得到的三个关键机制**：
| # | 机制 | 细节 |
|---|---|---|
| **1** | **物品限制** | `ToolRackBlockEntity#isItemValid(int slot, ItemStack)` ⇒ **内部查 tag `tfc:usable_on_tool_rack`**<br>⇒ 🎯 **结论：限制靠 tag（数据驱动），不是硬编码清单** |
| **2** | **槽位选择** | `ToolRackBlock#getSlotFromPos(BlockState, Vec3)` ⇒ **按玩家点击的位置**决定放进哪一格 |
| **3** | **渲染** | `ToolRackBlockEntityRenderer`：<br>· `ITEM_SCALE = 0.5F`<br>· **`ITEM_LOCATION[4 方向][4 槽][xyz]`**（静态三维位置表）<br>· `poseStack.translate(...)` + `scale(0.5F,0.5F,0.5F)` + `getItemRenderer().renderStatic(...)` |

#### 三条口径的落地

| # | 口径 | 做法 |
|---|---|---|
| **②** | **物品限制** | 🆕 新建 **`MyTags.Items.USABLE_ON_KNIFE_BLOCK`**<br>tag 文件 `data/tfcagricultureplus/tags/item/usable_on_knife_block.json`：<br>`{"values":["#c:tools","#tfc:usable_on_tool_rack","#tfc:sewing_needles","tfc:sandpaper","minecraft:spyglass"],"replace":false}`<br>⭐ **直接继承 `#tfc:usable_on_tool_rack`** ⇒ **TFC 给工具架加什么，我们就自动有**<br>✅ 用 tag 而非硬编码的三个好处：**玩家可改** · **其它模组可加入** · **不依赖具体物品 ID** |
| **①** | **渲染** | 🆕 新建 **`client/KnifeBlockBlockEntityRenderer`**（照 TFC 的数值做法）：<br>· `ITEM_SCALE = 0.5F`（与 TFC 一致）<br>· **`SLOT_LOCATION[4][xyz]`** 静态表（2×2：上排两把刀、下排两个调料罐）<br>· 先按 `FACING` 旋转（`Axis.YP.rotationDegrees(-facing.toYRot())`），再 translate + scale<br>· `ItemRenderer.renderStatic(stack, ItemDisplayContext.FIXED, ...)`<br>🆕 **注册**：`EntityRenderersEvent.RegisterRenderers#registerBlockEntityRenderer` |
| **③** | **原木案板耐久** | 🆕 新增 BE 类型 **`log_cutting_board`**（复用 `CuttingBoardBlockEntity`，34 个原木变体）<br>`LogCuttingBoardBlock` 改为 `implements EntityBlock`（+ `newBlockEntity` / `getTicker` 返回 `null`） |

#### 🆕 顺带的对齐修正

| 项 | 原 | 现 |
|---|---|---|
| 刀架格数 | 9 | **4**（与 TFC 工具架一致） |
| 提示语 | 只有"满了" | 新增 **"这个放不到刀具架上"**（区分"满"与"物品不合法"两种失败） |

#### 验收（**7 条全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | 🎯 **B 渲染层自检** | ✅ `已注册方块 138 个，全部有归属` |
| 3 | 🎯 **材质自检（新版）** | ✅ **`木制案板 34（TFC 20 + afc 14）· 石制案板 21 · 刀具架 34 · 原木案板 34 · 石臼 15`** |
| 4 | `Invalid block entity` | ✅ **0 处**（现在 **4 个 BE 类型**：knife_block / cutting_board / log_cutting_board / mortar） |
| 5 | `Exception.*tfcagricultureplus` | ✅ **0 处** |
| 6 | 模型 / 贴图 / 配方 | ✅ `Unable to load model` · `Missing textures` · `Parsing error loading recipe` **全部 0 处** |
| 7 | A 不受影响 | ✅ `已注册方块 474 个` |

#### 🛑 ⚠️ **诚实说明：BER 的视觉效果尚未用肉眼确认**

| 项 | 状态 |
|---|---|
| **能证明的** | BE 类型注册成功（`Invalid block entity` 0 处）· BER 注册代码编译通过并执行（无异常） |
| **不能证明的** | ⚠️ **BER 真的把物品画出来了** —— 这需要**进游戏放下刀架 → 放入一把刀 → 看画面** |
| 🆕 **待补** | 放进 §5.3 的实机判据：**"刀架上必须能看见挂着的物品"**（首条**画面级**判据） |
| **纪律依据** | AGENTS.md §一-20：「实机验证的判据是**画面里看到了预期的东西**，不是"日志里没有报错"」 |

#### 🆕 rev7 踩到的坑

| # | 坑 | 修法 |
|---|---|---|
| **1** | ⭐⭐ **`String.Replace` 的锚点 `/**` 在文件里出现多次** ⇒ 我的插入脚本**把同一段代码插了 3 次** ⇒ 编译报"已在类中定义了变量 LOG_CUTTING_BOARD" | 用**行号定位 + 精确删除区间**（先算出重复块的首尾行，再重建数组）—— **不要用短锚点做批量插入** |

### 4.10 ✅ 批次 1 **修订（rev8）**（2026-10-05，2 条口径）

> 用户口径：
> ①「**砧板交互也要保证物品的可见性**，而且是**直接渲染不是绘画或者建模**」
> ②「**内部存储物品的方块被破坏时要掉落内部物品**」
> ③「完成以上两点后**继续迁移**」

#### ① 案板：物品可见性 + **直接渲染**

🛑 **用户明确区分了三种"让物品显示出来"的做法**：

| 做法 | 说明 | 用不用 |
|---|---|---|
| ⭐ **直接渲染** | 把物品**本身的三维模型**画出来（`ItemRenderer.renderStatic(...)`） | ✅ **用这个** |
| 绘制（2D） | 把物品的**图标**贴上去（`GuiGraphics.blit`） | ❌ 不用 |
| 建模（自定义 block model） | 给每种可放物品写一套方块模型（TFC 的 `ToolRackBlockEntityRenderer.MODELS` 就是这种，只覆盖锅/罐等少量物品） | ❌ 不用（要穷举物品，不可扩展） |

**落地**：
| 项 | 内容 |
|---|---|
| 🆕 **案板加 1 格承载** | `CuttingBoardBlockEntity#onBoard` —— 才能"有东西可渲染" |
| 🆕 **右键两分支** | 手持 ⇒ **摊到板上** · 空手 ⇒ **取回**（板也空时提示**剩余耐久**） |
| 🆕 **BER** | `CuttingBoardBlockEntityRenderer`：`ITEM_SCALE = 0.5F` + 按 `FACING` 旋转 + `y = 0.09375`（正好在 1px 台面之上）+ `Axis.XP.rotationDegrees(90)`（平放）+ **`renderStatic`** |
| **注册** | `CUTTING_BOARD` 与 **`LOG_CUTTING_BOARD`** 两个 BE 类型都注册同一个 BER |
| ✅ **直接渲染的好处** | **任何物品都能自动显示** —— 不用为每种物品写模型，也不用管图标 |

#### ② 方块被破坏时掉落内部物品

| 项 | 内容 |
|---|---|
| 🆕 **统一辅助** | `MyBlocks.dropContentsOnBreak(Level, BlockPos)` —— 按 BE 类型分派（刀架/案板/石臼） |
| 🆕 **钩子** | 4 个方块类（`CuttingBoardBlock` · `LogCuttingBoardBlock` · `KnifeBlockBlock` · `MortarBlock`）**全部覆盖 `playerWillDestroy`** |
| 🛑 **为什么不用 `BlockEntity#preRemoveSideEffects`** | 那是 **1.21.2+** 的 API，在 1.21.1 上编译报**"无法覆盖或实现超类型的方法"**（本轮实测踩到） |
| ⚠️ **签名坑** | 1.21.1 的 `playerWillDestroy` **返回 `BlockState`**（不是 `void`）—— 我在 rev6 已经踩过一次，rev8 又踩了一次 |
| ⚠️ **覆盖范围** | **只在玩家破坏时触发**（不含爆炸/活塞）—— 对"架子/案板"够用；爆炸掉落留后续批次（可用 `setRemoved` 兜底） |

#### 验收（**8 条全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | 🎯 B 渲染层自检 | ✅ `已注册方块 138 个，全部有归属` |
| 3 | 🎯 材质自检 | ✅ `木制案板 34 · 石制案板 21 · 刀具架 34 · 原木案板 34 · 石臼 15` |
| 4 | `Invalid block entity` | ✅ **0 处**（4 个 BE 类型） |
| 5 | `Exception.*tfcagricultureplus` | ✅ **0 处** |
| 6 | 模型 / 贴图 / 配方 | ✅ 全部 **0 处** |
| 7 | registry 类错误 | ✅ 全部 **0 处** |
| 8 | A 不受影响 | ✅ `已注册方块 474 个` |

#### 🛑 ⚠️ **诚实说明（承接 rev7）**

| 项 | 状态 |
|---|---|
| **能证明的** | 3 个 BER 注册代码编译通过 · BE 类型注册成功 · 无任何运行时异常 |
| **不能证明的** | ⚠️ **BER 真的把物品画出来了** —— 仍需**进游戏**：放刀架 → 放刀 → 放案板 → 摊食材 → **看画面** |
| **纪律依据** | AGENTS.md §一-20：「实机验证的判据是**画面里看到了预期的东西**」 |

#### 🆕 rev8 踩到的坑

| # | 坑 | 修法 |
|---|---|---|
| **1** | ⭐⭐ **`BlockEntity#preRemoveSideEffects` 是 1.21.2+ 的 API** | 1.21.1 改用 **`BlockBehaviour#playerWillDestroy`**（返回 `BlockState`） |
| **2** | ⚠️ **同一个签名坑踩了第二次**（`playerWillDestroy` 返回 `BlockState`） | 已写进上方表格，**下次直接查这张表** |
| **3** | **`ItemStack` 没 import** ⇒ 一连串"找不到符号" | 加 import（编译器的报错行号会**分散在多处**，容易误判） |

### 4.11 ✅ **tfcwoodworking 迁移（第一批：`in_world` 机制）**（2026-10-05）

> 用户口径：「**读取 tfcwoodworking 的代码和资源并且进行迁移融合和优化**（以及补全对 arborcraft 木材的支持），
> 其是 **mit 协议可以直接迁移**」+「**案板的配方测试正好使用迁移的这部分木材加工流程**」

#### 已迁移的内容（**4 个新文件**）

| 文件 | 内容 | 来源 |
|---|---|---|
| `common/recipe/inworld/InWorldComponents.java` | **4 个小组件**：`Input`（配方输入）· `SoundInstance`（音效）· `BlockStatePredicate`（方块状态判定）· `Tool`（工具类别） | 逐类迁移自 `InWorldRecipeInput` / `SoundInstance` / `BlockStatePredicate` / `Tool` |
| `common/recipe/inworld/InWorldRecipe.java` | ⭐ **配方本体**（record：`input_state` + `tool` + `result_state` + `sound` + `result_items`） | 迁移自 `InWorldRecipe` |
| `common/recipe/inworld/Action.java` | **4 个产出动作**：`DROP_CENTER` · `DROP_CARDINAL` · `DROP_ABOVE` · `SHOOT_AS_BLOCK` | 迁移自 `Action` |
| `common/recipe/inworld/InWorldRecipeHandler.java` | ⭐ **执行器**（**改用 NeoForge 事件，零 mixin**） | 替代源项目的 3 个 mixin |

#### ⭐ 三项**融合优化**（不是照抄）

| # | 优化 | 说明 |
|---|---|---|
| **1** | ⭐ **零 mixin** | 源项目用 `AxeItemMixin` + `InteractionManagerMixin` + `StateHolderAccessor` **3 个 mixin**；<br>我们改用 **`PlayerInteractEvent.RightClickBlock`** ⇒ **只监听事件**，与其它模组共存更安全、可断点调试 |
| **2** | ⭐ **新增 `KNIFE` 工具类别** | 源项目只有 `AXE` / `SAW`（它只做木材加工）；<br>我们加了 **`KNIFE`**（`tfc:tools/knives` 标签）⇒ **案板的"切食材"主功能**有了落点 |
| **3** | ⭐ **`result_items` 改用对象格式** | 源项目用 `Codec.pair`（数据包必须写 **数组** `[{"id":..}, "drop_center"]`）；<br>我们改成**命名键对象** `{"item":{..},"action":".."}` ⇒ 更好写、更好读 |

#### 用户口径 ⑤ 的落点（案板三大功能）

| 功能 | 用什么工具 | 迁移后的载体 |
|---|---|---|
| **主：切割和分片食材** | `knife`（🆕 新增类别） | `in_world` 配方：`input_state` = 案板/食材，`tool` = `knife` |
| **次：处理原木** | `axe` / `saw` | 源项目已有的 20 树种配方 ⇒ 待补 afc 14 种 |
| **次：分解石砖块** | `hammer`（待加） | `in_world` 配方 |

#### 测试配方（**用户口径 ⑥：用迁移的木材加工流程**）

| 文件 | 链路 |
|---|---|
| `data/tfcagricultureplus/recipe/in_world/axe_strip_oak.json` | `tfc:wood/log/oak` --(axe)--> `tfc:wood/wood/oak` + 2× `tfc:wood/lumber/oak` |
| `data/tfcagricultureplus/recipe/in_world/saw_planks_oak.json` | `tfc:wood/wood/oak` --(saw)--> `tfc:wood/planks/oak` + 4× `tfc:wood/lumber/oak`（四向掉落） |

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | ⭐⭐ **`in_world` 配方被加载** | ✅ **`Loaded 9182 recipes`**（上一版 9180 ⇒ **+2 = 我们的 2 个测试配方**） |
| 3 | ⭐ **配方解析** | ✅ **`Parsing error loading recipe` 0 处** |
| 4 | 🎯 **BE 类型 bug 修复** | ✅ **`Invalid block entity` 0 处** |
| 5 | B 渲染层自检 | ✅ `已注册方块 138 个` |
| 6 | A 不受影响 | ✅ `已注册方块 474 个` |
| 7 | registry 类错误 + 本模组 ERROR | ✅ **全部 0 处** |

#### 🆕 迁移中踩到的**四个真实坑**（全部值得记住）

| # | 坑 | 现象 | 修法 |
|---|---|---|---|
| **1** | 🛑🛑 **BE 类型不匹配 ⇒ 放置即崩** | `IllegalStateException: Invalid block entity tfcagricultureplus:cutting_board`，堆栈直指 `BlockEntity.validateBlockState` | `LogCuttingBoardBlock.newBlockEntity` 返回了"用 `CUTTING_BOARD` 类型构造的"BE ⇒ **必须用 `LOG_CUTTING_BOARD` 类型**（照 TFC 的 `PlacedItemBlockEntity` 模式：**基类持有类型参数**） |
| **2** | 🛑 **`Codec.pair` 的数据包格式是"数组"不是"对象"** | `No key id in MapLike[{"item":{...},"action":"drop_center"}]`（**它在对象里找 `id`，报错极具误导性**） | 改用 `RecordCodecBuilder` + 命名键（`item` + `action`） |
| **3** | ⚠️ **1.21.1 没有 `BlockState.STREAM_CODEC`** | `找不到符号: 类 BlockState` | 用 **`ByteBufCodecs.idMapper(Block.BLOCK_STATE_REGISTRY)`** |
| **4** | ⚠️ **`SoundInstance` 的 `pitch` 上限是 1.0** | `Value 1.2 outside of range [0.0:1.0]` | 数据包里 `pitch ≤ 1.0`（我先写了 1.2） |
| **5** | 🛑 **Java 的"非法前向引用"** | `CODEC` 用了定义在它**之后**的 `RESULT_ITEM_CODEC` ⇒ 编译失败 | **静态编解码器必须定义在使用它们的常量之前**（本轮踩了 2 次） |
| **6** | ⚠️ **用行号做代码块搬移非常危险** | 我的搬移脚本把整个类都切了进去 ⇒ "需要 class、interface、enum 或 record" + "到达文件结尾" | 🛑 **改大段代码用 `write` 重写整个文件**，不要用脚本搬行 |

#### 📌 迁移**进度**

| 步骤 | 状态 |
|---|---|
| 1. 迁 `recipes/inworld/` 6 个类 ⇒ `in_world` 配方类型 | ✅ **完成**（融合为 4 个文件，零 mixin） |
| 2. 迁 `DebarkedLog/Half/Quarter` 方块 + 模型 ⇒ **按 34 树种生成**（补 afc） | ✅ 2026-10-06：102 个木料变体、170 条加工配方，34 木种加工链实机检查通过（docs/129） |
| 3. 迁 `LogPileExBlock` + 2 个 BE | ✅ 实现与构建完成；容量、取放、保存检查通过；**完整封窑验收按用户要求留待用户自行测试**（docs/129） |
| 4. 迁 `compat/jei/InWorldRecipeCategory` ⇒ 接进 `MyJeiPlugin` | ✅ 已接入，239 条世界中加工配方；产物来源检索与数量显示已实机核对（docs/128、129） |
| 5. 案板配方全面接入（切食材 / 分解石砖） | 🔁 案板切割、12 条现有食材配方及 JEI 已接入；更多食品与石砖分解留待后续批次（docs/129） |

---

## 五、验收与验证

### 5.1 三层验证（缺一不可）

| 层 | 工具 | 频率 | 判据 |
|---|---|---|---|
| **① 工具级** | `verify.ps1` · `check-geom.ps1` · `seam-audit.ps1` · `check-boundaries.ps1` · 🆕 **`verify-registry.ps1`** | 每次改资源后 | 全绿 |
| **② 构建级** | `gradle build`（**删过资源则 `clean build`**） | 每批次 | `BUILD SUCCESSFUL` |
| **③ 实机级** | `launch-client.ps1` → 读日志 → `stop-own-client.ps1` | **每批次收口** | 见 §5.3 |

### 5.2 🆕 `verify-registry.ps1`（**本轮实机验证暴露的工具缺口**）

> 🛑 **为什么必须有它**：2026-09-29 的实机验证发现 **9 个野生作物有 blockstate 却没注册**
> ⇒ 世界生成引用了不存在的方块 ⇒ `Failed to load registries` ⇒ **存档完全打不开**。
> 而 `tools/verify.ps1` **只校验资源之间的交叉引用**，**这类问题它一个都查不出来**。

```powershell
# tools/verify-registry.ps1 —— 核对「blockstates 里的方块」与「Java 注册」是否一致
# 用法：& .\tools\verify-registry.ps1
$ErrorActionPreference = 'Stop'
$proj = Split-Path $PSScriptRoot -Parent
$bsDir = "$proj\src\main\resources\assets\tfcfarmingplus\blockstates"
$javaDir = "$proj\src\main\java"
$issues = 0

# ① 资源侧：blockstates 下的全部方块名（相对路径，去掉 .json）
$res = Get-ChildItem $bsDir -Recurse -File -Filter *.json |
       ForEach-Object { $_.FullName.Substring($bsDir.Length + 1) -replace '\.json$', '' -replace '\\', '/' }

# ② 代码侧：把全部 .java 拼起来，扫两种注册写法
$code = (Get-ChildItem $javaDir -Recurse -File -Filter *.java |
         ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($_.FullName)) }) -join "`n"

#   写法 A：字面量  register("some/path", ...)
$byLiteral = [regex]::Matches($code, 'register\(\s*"([a-z0-9_/]+)"') |
             ForEach-Object { $_.Groups[1].Value }

#   写法 B：工厂 —— ⚠️ 本脚本的核心：**工厂方法会让静态提取漏掉大量方块**
#   （本轮就因此在统计 dead_crop / wild_crop 时连错两次）
$factories = @{
  'wild'        = 'wild_crop/{0}'
  'wildFlooded' = 'wild_crop/{0}'
  'dead'        = 'dead_crop/{0}'
  'deadFlooded' = 'dead_crop/{0}'
  # 🛑 新增工厂时**必须在这里登记**，否则脚本会误报
}
$byFactory = @()
foreach ($fn in $factories.Keys) {
  foreach ($m in [regex]::Matches($code, "=\s*$fn\(\s*""([a-z0-9_]+)""")) {
    $byFactory += ($factories[$fn] -f $m.Groups[1].Value)
  }
}
$codeNames = ($byLiteral + $byFactory) | Sort-Object -Unique

# ③ 双向差集
$onlyRes  = $res       | Where-Object { $codeNames -notcontains $_ }
$onlyCode = $codeNames | Where-Object { $res       -notcontains $_ }

if ($onlyRes) {
  $issues++
  Write-Host "🛑 有 blockstate 但没注册（会导致 FML 报 Unknown registry key）：" -ForegroundColor Red
  $onlyRes | ForEach-Object { Write-Host "     $_" }
}
if ($onlyCode) {
  $issues++   # 不一定是错误，但必须人工确认
  Write-Host "⚠️ 有注册但没有 blockstate（确认是否刻意）：" -ForegroundColor Yellow
  $onlyCode | ForEach-Object { Write-Host "     $_" }
}

Write-Host ""
if ($issues -eq 0) { Write-Host "✅ 资源与注册完全一致（$($res.Count) 个方块）" -ForegroundColor Green }
else { Write-Host "发现 $issues 类不一致 —— 修完再构建" -ForegroundColor Red; exit 1 }
```

⚠️ **本脚本的已知局限**（诚实写明）：
- 它是**静态**提取，**新加工厂方法时必须同步登记** `$factories` 表 —— 否则会误报
- **最可靠的是运行时清单** ⇒ 建议给 `[渲染层自检]` 加一个开关，让它**把全部方块 ID 打印出来**，
  与资源清单做 diff（「运行时口径」比静态提取可靠）

### 5.3 实机验证配方（**每批次收口跑**）

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'

# ① 部署前备份
Copy-Item "$v\mods\TFCAgriculturePlus-*.jar" "$v\moddev\backups\" -Force -EA SilentlyContinue
Copy-Item "$v\moddev\tfcagricultureplus\build\libs\*.jar" "$v\mods\" -Force

# ② 启动（默认直接进 tfctest —— 停在主菜单等于没验证）
& "$v\moddev\tools\launch-client.ps1"

# ③ 读日志（等 2~4 分钟）→ 判据见下表
$log = Join-Path $env:TEMP 'tfcflora-launch-out.log'

# ④ 收尾（**必跑**，还原 options.txt 的 pauseOnLostFocus）
& "$v\moddev\tools\stop-own-client.ps1"
```

**判据（缺一不可）**：

| # | 判据 | 怎么查 |
|---|---|---|
| 1 | 本模组渲染层自检 | 日志有 `[渲染层自检] 已注册方块 N 个，全部有归属`，且 **N ≥ A 的 474** |
| 2 | 🛑 **无 `Unknown registry key`** | 0 处 |
| 3 | 🛑 **无 `Couldn't parse element`** | 0 处 |
| 4 | 🛑 **无 `Failed to load registries`** / `Mod loading has failed` | 0 处 |
| 5 | **真进世界** | 日志有 `Starting integrated minecraft server` + `Loaded N advancements` + `Time elapsed` |
| 6 | **正常存盘** | 收尾时有 `All chunks are saved` |
| 7 | 🎯 **本模组 ERROR** | 过滤 `tfcfarmingplus` / `tfcagricultureplus` 的 ERROR ⇒ **0 处** |
| 8 | **画面里看到了预期的东西** | 🛑 **"日志没报错"不算验证**（`AGENTS.md` §二-20：本项目曾三次据此误报） |

⚠️ **判据 2/3/4 是 2026-09-29 用真实崩溃换来的** —— 它们对应两类 bug：
「资源引用的方块没注册」与「遗留资源自引用不存在的方块」。

---

## 六、回滚（B 专属）

| 层 | 回滚动作 | 伤存档吗 |
|---|---|---|
| **① 资源层**（覆盖 `assets/tfc/**` 等） | 删文件 | ✅ 不伤（邻居原文件从未被改动，只是加载时被盖住） |
| **② 数据层**（往邻居命名空间新增） | 删目录 | ✅ 不伤 |
| **③ 代码层**（B 自建的方块 / BE / 物品） | 卸载 jar | 🛑 **伤**（方块变空气、物品消失、BE 数据丢失） |

⇒ **排期推论**（主方案 §5.5.1）：**B 的「新方块」越晚铺开，存档风险越小**。
⇒ 所以批次顺序是 **补链型（只加物品与配方，不动世界）在前，设备在后** —— 这不是巧合，是故意的。

**一键回滚**（⏳ 待写 `tools/rollback-b.ps1`）：
```
输入：批次 ID（对应 OVERRIDE-REGISTRY.md 的一节）
动作：① 按台账列出该批次全部文件 → ② 移动到 _rollback/<批次>/（不删，保留证据）
      → ③ 复跑 verify.ps1 + verify-registry.ps1 → ④ 输出"邻居哪些文件恢复了"
判据：两个 verify 全绿 + 游戏内邻居内容恢复原貌 + A 的 474 个方块无变化
```

---

## 七、风险登记（**B 专属**，与主方案 §10.2 互补）

| # | 风险 | 触发条件 | 早期信号 | 对策 |
|---|---|---|---|---|
| 1 | 🛑 **资源引用的方块没注册** | 新增方块时漏改 Java | FML 报 `Unknown registry key` | **§5.2 的 `verify-registry.ps1`**（本轮真实 bug） |
| 2 | 🛑 **遗留资源自引用** | 物种换了形状（如普通→莲座）但旧资源没删 | `Couldn't parse element ... loot_table` | 换形状时**同时清理旧资源**（本轮 kale 的教训） |
| 3 | **A 的改动破坏 B** | A 改了 `MySpeciesApi` 或 17 个方块类的签名 | B 编译失败 | 批次 0 起把 A 的公共 API 视为**冻结契约**；改之前先搜 B 的引用 |
| 4 | **mixin 静默失效** | 邻居更新改了方法签名 | 功能无声消失、日志无报错 | `"required": true`（红线 8） |
| 5 | **mixin 与 hardcore 冲突** | 两边注入同一方法 | 行为叠加 / 偶发崩溃 | 条件让位组（§3.5） |
| 6 | **A 的 jar 未重建** | 改了 A 却直接建 B | B 编译到旧的 A API | 构建按序：先 A 后 B；或让 `aJar` 检测时间戳 |
| 7 | **覆盖了 A 的资源**（红线 2） | 手滑在 `assets/tfcfarmingplus/` 下建文件 | 门禁脚本报错 | §1.7 |
| 8 | **美术量被低估** | ≈410 张贴图 + 18 台设备 | 代码做完但没贴图 | 主方案 §9.0-D；**先做通 1 个再铺开** |

---

## 八、下一步（本文档写完后立刻能做的）

| 序 | 动作 | 产物 |
|---|---|---|
| 1 | 按 §一 建 `moddev/tfcagricultureplus/` 骨架 | 目录 + `build.gradle.kts` + `settings.gradle` + 入口类 |
| 2 | 写 `tools/check-boundaries.ps1`（§1.7）与 `verify-registry.ps1`（§5.2） | 两个门禁脚本 |
| 3 | 建 `neoforge.mods.toml` 模板（§1.5） | **纯 ASCII** |
| 4 | `gradle build` 建出**空 B jar** | 第一个交付物 |
| 5 | 部署 + 实机验证（§5.3 的 8 条判据） | 批次 -1 收口 |

⚠️ **在批次 -1 通过之前，不要写任何 B 层内容**（用户口径：**先拆包**）。

---

## 九、本子文档与主方案的关系（防脱节）

| 本文 | 主方案 | 说明 |
|---|---|---|
| §一 拆包 | §〇.2 · §9.0-A | 🆕 **本文修正了主方案的"多模块"结论**（改为并列双项目，理由见 §1.2） |
| §二 API 边界 | §〇.2.5 | 一致；本文补了 `MySpeciesApi` 的骨架 |
| §三 基础设施 | §9.0-B · §12.6 | 一致 |
| §四 批次 | §九 阶段 0~9 | 本文是**可执行版**（主方案是规划版） |
| §五 验证 | §9.0-C | 🆕 **本文补了 `verify-registry.ps1`**（主方案缺这一环） |
| §六 回滚 | §5.5.1 | 一致 |
| §七 风险 | §10.2 | 本文是 **B 专属**增量 |

🛑 **两边若冲突，以本文为准**（本文更新、更贴实际工程状态）；但**冲突处必须回写主方案**，避免两份文档说法不一。

---

## 十、改造清单（**要动的已有内容，逐项构想**）

> 用户口径：「**mixin 是必选项，因为你本来就要动大量已有内容**」+「**最终目标是完全重制**」。
> 本节回答：**到底要动哪些已有内容、每项改成什么样、怎么改、影响谁**。
>
> 📌 标记：**手段** = 数据 / 覆盖 / mixin / 自建；**影响面** = 动错了会连带坏掉什么。

### 10.1 总览（三层 × 13 项）

| # | 层 | 对象 | 手段 | 影响面 | 优先级 | 批次 |
|---|---|---|---|---|---|---|
| **A1** | TFC | **29 种作物**的几何 / 贴图 / 掉落 | 资源覆盖 | 中（TFC 作物外观全变，**方块类不变**） | P1 | 10 |
| **A2** | TFC | **11 种浆果灌木** | 资源覆盖 | 中 | P1 | 10 |
| **A3** | TFC | ⭐ **调料 → 保质期 + 味道标签** | ✅ **零 mixin**（注册 `FoodTrait` + `AddTraitModifier`） | 🟢 低（只碰我们自己的 trait） | **P0** | 9 |
| **A4** | TFC | **烹饪**（`pot` 动态食物） | 数据 + 可能的 mixin | 🔴 高（所有锅类配方） | P1 | 9 |
| **A5** | TFC | **汤 / 沙拉 / 三明治标签** | ✅ **纯数据** | 🟢 低（追加式） | P1 | 9 |
| ~~**A6**~~ | ~~TFC~~ | ❌ **作废**：连作 / 适播 **TFC 已有**，授粉**不做** | — | — | — | — |
| **B1** | Firmalife | **温室气候** | mixin（**条件让位**） | 🟠 中高 | P1 | 11 |
| **B2** | Firmalife | **灌溉**（泵 / 喷淋） | mixin（**条件让位**） | 🟠 中高 | P1 | 11 |
| **B3** | Firmalife | **保鲜容器**（架子 / 挂架 / 大罐） | mixin（**条件让位**） | 🟠 中 | P1 | 11 |
| **B4** | Firmalife | **烤箱**（5 材质 + insulated） | 资源覆盖（**不加方块**） | 🟡 中 | P1 | 11 |
| **B5** | Firmalife | **香料 8 种** + **葡萄棚架** | 物种接管（覆盖） | 🟡 中 | P1 | 10 |
| **C1** | **A** | `MySpeciesApi`（**唯一改动**） | 🆕 新增只读类 | 🟢 极低 | P0 | 0 |
| **C2** | **A** | ~~接管 A 的茶 / 咖啡 / hops / 纤维方块~~ | ❌ **不做** | — | — | — |

✅ **只有 3 项是"全局影响"的 mixin**（A3 · A6 + B 组）—— **B 的改造风险高度集中在这几处**。

---

### 10.2 逐项构想

#### A1 · TFC 29 种作物（几何 / 贴图 / 掉落）

| 项 | 内容 |
|---|---|
| **现状（实测）** | `assets/tfc/blockstates/crop/*.json` **恰好 29 个**（alfalfa · barley · beet · cabbage · canola · carrot · cassava · garlic · green_bean · jute · lentil · maize · melon · oat · onion · papyrus · peanut · potato · pumpkin · radish · red_bell_pepper · rice · rye · soybean · squash · sugarcane · tomato · wheat · yellow_bell_pepper）；它们用 `parent: block/crop`（**十字片**，非我们风格） |
| 🎯 **目标构想** | 让 TFC 的 29 种作物**看起来像我们画的**：7 种形状（普通 / 双段 / 攀爬 / 蔓延 / 水生 / 莲座 / 可摘），每物种 6 龄 + 枯死态，风格与 A 的 86 种**完全同族**。**玩家分不出哪些是"我们的"、哪些是"TFC 的"** |
| **手段** | **资源覆盖**：`assets/tfc/blockstates/crop/<n>.json` + `models/block/crop/<n>_age_*.json` + `textures/block/crop/<n>_*.png` |
| ⚠️ **影响面** | 中 —— **TFC 的方块类与 blockstate 属性不变**（仍 `age`/`fruiting`）⇒ 只换皮 ⇒ **存档安全** ✅ |
| 🛑 **关键技术点** | 覆盖 **blockstate** 时**必须覆盖它的全部变体**（`age` × `fruiting`）；A 的 `kale` 就曾因漏掉 `fruiting` 导致 6 个模型**永远不显示**（`AGENTS.md` 第 48 轮） |
| **掉落** | 覆盖 `data/tfc/loot_table/blocks/crop/<n>.json` ⇒ 接入我们的**主/次产品**（`tfc:extra_products`） |
| **验收** | ① 29 种在游戏里**都长成我们的风格** ② 原有掉落**不减少**（只是增加次产品）③ 存档里已种的 TFC 作物**不消失** |
| **风险** | 覆盖 `data/tfc/loot_table/**` ⇒ 邻居更新若改掉落，我们的覆盖会**盖住它的新内容**（需 `OVERRIDE-REGISTRY` 登记 + 对齐检查） |

#### A2 · TFC 11 种浆果灌木

| 项 | 内容 |
|---|---|
| **现状** | 13 个 `*_bush` blockstate，减 2 个枯死态 ⇒ **11 种**；`StationaryBerryBushBlock`，3 stage |
| 🎯 **目标构想** | 走**我们的灌木管线**（`MyBerryBushBlock` / `MySpreadingBushBlock`，与 A 的 12 种同族）；**草莓单独摘出**（做成普通作物，§5.2） |
| **手段** | 资源覆盖 `assets/tfc/blockstates/plant/<n>_bush.json` 等 |
| ⚠️ **影响面** | 中 —— `data/tfc/tags/block/spreading_bushes/living` 等标签**已由 A 覆盖**（197 文件之一），B 要注意**不要动 A 已写的标签**（红线 2） |
| 🛑 **冲突点** | 草莓的灌木形态**被 A 的 197 文件之一引用**（`spreading_bushes` 等）⇒ B 改草莓时必须**同时**让 A 的标签不再指向它 ⇒ **这是唯一一处 B 必须"绕过"而非"覆盖"A 的地方**（做法：B 自己覆盖 TFC 的标签，而不是改 A 的） |
| **验收** | ① 11 种灌木外观同族 ② 草莓在野外/农田**都表现为普通作物** ③ 蜂蜜仍能访问 `buzzing_leaves`（A 已接的 48 条果树叶子） |

#### A3 · ⭐ 调料 → 保质期 + 味道标签（🆕 **重新设计：零 mixin**）

> 🛑 **用户口径（2026-09-29）**：「**调料只影响保质期，不影响营养值**（食物不会因为加了调料就变多），
> **调料只会对食物添加一个"味道"的标签**」。
> ⇒ 旧稿的"调料参与营养加成"**作废** —— 那需要 mixin `FoodCapability`；**新设计完全落在 TFC 的既有扩展点上**。

| 项 | 内容 |
|---|---|
| **现状（反编译实测）** | `FoodTrait` = **`{decayModifier: Supplier<Double>, translationKey}`** —— 一个 trait 就是「**名字 + 腐坏速率乘数 + tooltip**」；`FoodTraits` 是 **`DeferredRegister<FoodTrait>`**（**可扩展**），已有 **10 个**：`salted` · `brined` · `pickled` · `preserved` · `vinegar` · `charcoal_grilled` · `wood_grilled` · `burnt_to_a_crisp` · `wild` · `canned` |
| 🎯 **目标构想** | ① 调料**只影响保质期**（`decayModifier < 1.0`）② 调料**给食物加一个"味道"标签**（就是 `FoodTrait`）③ 🛑 **不影响营养值** |
| ⭐ **手段：零 mixin** | ① **注册我们自己的 `FoodTrait`** —— `DeferredRegister.create(FoodTraits.KEY, "tfcagricultureplus")` ⇒ **标准 NeoForge 注册，不碰 TFC 的类**<br>② **配方里用 TFC 现成的 `AddTraitModifier`** 给成品加 trait ⇒ **纯数据** |
| **代码量** | 注册 N 个 trait（每种味道一个）+ N 条配方挂 modifier —— **无需 mixin、无需改 TFC 行为** |
| 🛑 **与前稿的差别** | 旧稿要 mixin `FoodCapability`/`FoodData`（🔴 **全局风险**）；**新设计把风险降到 🟢** —— 我们只**新增** trait，**不改任何已有行为的计算** |
| ⚠️ **数值必须自定** | `decayModifier` 取多少？（TFC 的值在 `TFCConfig.SERVER.trait*Modifier` 里）⇒ **我们取自己的值，不抄** |
| **验收** | ① 🎯 **加调料的食物，营养与未加时逐项一致**（用户口径的硬判据）② 加调料的食物**坏得慢** ③ tooltip 显示味道 ④ TFC 原有 10 个 trait 照常 ⑤ `RottenIngredient` 等配方条件照常 |

**味道标签的粒度 —— ✅ 已裁决（用户 2026-09-29）：采用方案 A**

| 方案 | 做法 | 裁决 |
|---|---|---|
| **A** ⭐ | **多种味道 trait**（`spicy` · `herbal` · `sweet` · `smoky` · `sour` · `umami` …），同一食物**只保留一个** | ✅ **采用** |
| B | 单一 `seasoned` trait | ❌ 否决 |

**方案 A 的落地要点（4 条）**：

| # | 要点 | 说明 |
|---|---|---|
| 1 | **味道与来源对应** | 香料 → `spicy` / `herbal` · 烟熏 → `smoky` · 糖渍 → `sweet` · 油浸 → `rich` · 醋渍 → `sour`（⚠️ TFC 已有 `vinegar` trait，**直接复用，别重复造**）· 酱 → `umami` |
| 2 | **"只保留一个"怎么实现** | ✅ **在配方层面解决**：加料配方产出**带新 trait 的成品**；若成品已有别的味道，先用 **`RemoveTraitModifier`** 移除旧味道、再用 **`AddTraitModifier`** 加新的 —— **两个修饰器 TFC 都现成** |
| 3 | **与 TFC 已有 10 个 trait 的关系** | ⚠️ **不冲突但要对齐风格**：TFC 的 trait 讲"**怎么保存的**"（`salted`/`brined`/`pickled`/`canned`），我们的讲"**什么风味**"（`spicy`/`smoky`/`sweet`）⇒ **两类可以共存**（一个食物既有 `canned` 又有 `spicy`）<br>🛑 **但"味道"类之间互斥**（只能有一个），"保存"类可叠加 |
| 4 | **数量** | 建议 **6 种味道**：`spicy` · `herbal` · `sweet` · `smoky` · `sour` · `umami` |

🆕 **顺带**：TFC 已有 **10 个 trait** 本身就构成一套"加工方式 → 保质期"的体系
（`salted` 盐渍 · `brined` 卤水 · `pickled` 醋渍 · `preserved` 保存 · `vinegar` 醋 · `charcoal_grilled` 炭烤 · `wood_grilled` 木烤 · `burnt_to_a_crisp` 烤焦 · `wild` 野生 · `canned` 罐装）
⇒ **我们的调料 trait 应与它们同一套风格命名**，并在手册里成组介绍。

#### A4 · TFC 烹饪（`pot` 动态食物）

| 项 | 内容 |
|---|---|
| **现状** | `pot` 配方 + 动态食物（营养按成分算）；`data/tfc/recipe/pot/` 有 **216 个文件**，其中 `type: tfc:pot` 的 **145 条** |
| 🎯 **目标构想** | 调料成为**可选成分**：同一锅汤，加了香料的版本是**另一个产物**（"调味汤"），且带着 A3 的营养加成标记 |
| **手段** | ⚠️ **先试纯数据**：新增 `pot` 配方变体（"汤底 + 香料 → 调味汤"）⇒ **不动 TFC 代码**<br>只有"要在**同一锅里**同时加且动态计算"时才 mixin（§12.6.2 的 #6，P1） |
| ⚠️ **影响面** | 高 —— `pot` 是最常用的加工设备 |
| **验收** | ① TFC 原有 145 条 `pot` 配方**全部照常**<br>② 新变体能在锅里做出来<br>③ 动态食物的营养**从成分正确推算** |

#### A5 · TFC 汤 / 沙拉 / 三明治标签（**纯数据，零风险**）

| 项 | 内容 |
|---|---|
| **现状** | `tfc:usable_in_{soup,salad,sandwich}` · `usable_in_jam_sandwich` · `tfc:foods/*` |
| 🎯 **目标构想** | ① A 已把 ~110 种产物接进去（§4.1）<br>② **B 再补**：调料、药草、菌类、坚果、茶/咖啡副产品 |
| **手段** | ✅ **纯数据**（追加式标签，`replace=false`） |
| **验收** | 游戏里**真的能做出一碗含我们蔬菜的汤**（不是"标签写出了"） |
| **备注** | ⭐ **这是全 B 层性价比最高的一类**：零代码、零风险、玩家立刻能感知 |

#### A6 · ❌ **作废**（连作 / 适播已有，授粉不做）

> 🛑 **用户口径（2026-09-29）**：「**连作和适播内容已有，不要重复造轮子**」·「**授粉增产无必要，不需要添加**」

| 项 | 内容 |
|---|---|
| ✅ **核实结果：用户是对的** | **连作**：TFC **已有完整机制** —— `FarmlandBlockEntity$NutrientType`（农田养分类型）· `PlantableInfo$PlantNutrients`（植物养分消耗）· 🆕 **`Fertilizer` 数据类型（10 个）**：`{nitrogen, phosphorus, potassium}`（`compost` · `saltpeter` · `wood_ash` · `bone_meal` · `guano` · `sylvite` · `pure_nitrogen/phosphorus/potassium` · `shellfish`）⇒ **作物消耗农田养分、连作必然减产**，且**已有完整的肥料补充链**<br>**适播 / 季节**：TFC 有 `Calendars` + `Month` + 果树的 `Lifecycle` **12 月物候表** + `ClimateRange{min/max_temperature, min/max_hydration}` |
| ⇒ **本项删除** | **不写 `CropBlock` mixin** · **不加 `season` / `flowering` 字段** · **不做连作计数** · **不做授粉** |
| 📌 **教训（"把邻居已有的当缺口"第 8 次）** | §1.2.4 已建了"明确不是缺口的"清单，但**连作 / 适播是漏网的**<br>⇒ 🛑 **只靠清单防不住这一类错，必须逐个实测**（前 7 次：香料 · 浆果灌木数 · 葡萄形态 · 踩踏 · 茶咖啡占位 · TFC 动物体系 · 宠物驯化） |
| **副产品（有正面价值）** | 🆕 本次核实**顺带发现 `tfc:fertilizer` 数据类型（10 个）** ⇒ 主方案 §13.4-1 的"绿肥还田"变成**纯数据**（往 `Fertilizer` 里加定义即可），**不必 mixin、不必写代码** |

#### B1~B3 · Firmalife 温室 / 灌溉 / 保鲜容器（**三项共用条件让位组**）

| 项 | 内容 |
|---|---|
| **现状（实测）** | `firmalifehardcore 0.3.4` **已装**，且已 mixin 了同一批类：`ClimateMixin` · `FoodShelfBlockEntityMixin` · `HangerBlockEntityMixin` · `LargeVesselBlockEntityMixin` · `PumpingStationBlockEntityMixin` · `SprinklerBlockEntityMixin` · `AbstractSprinklerBlockMixin` · `ThermometerMixin`（共 8 个，`"required": true`） |
| 🎯 **目标构想** | **B 自带这三套系统**（玩家不装 hardcore 也能用），且**与 hardcore 互斥**：检测到 hardcore ⇒ B 的三个模块**整体让位**（不 mixin、不注册对应方块），日志明确提示 |
| **手段** | mixin（放进 **`tfcagricultureplus.conditional.mixins.json`**，`"required": false` + 运行时开关，§3.5） |
| 🛑 **为什么必须让位** | 两个模组同时注入同一方法 ⇒ **行为叠加甚至崩溃**（§12.6.4） |
| **验收** | ① **两者都装**：日志出现"已让位"，游戏正常，无重复规则<br>② **只装 B**：温室 / 灌溉 / 保鲜**都能用**<br>③ 卸载 B 后 Firmalife 恢复原貌 |
| **附** | 地窖/温室的空间检测基建：**BFS + `SavedData` 缓存 + ≤4096 格上限 + 事件节流**（§5.6.2/5.6.5，§12.4 的最大性能风险） |

#### B4 · Firmalife 烤箱（**只覆盖资源，不加方块**）

| 项 | 内容 |
|---|---|
| **现状** | Firmalife 有 **5 材质烤箱**（含 insulated 变体）+ `oven` 配方 **16 条** |
| 🎯 **目标构想** | 外观与交互**归我们**（同族风格），但**复用它的方块类** ⇒ **不新增方块**（否则存档风险 +1） |
| **手段** | 资源覆盖 `assets/firmalife/**` + 数据 `data/firmalife/recipe/oven/**` |
| **验收** | ① 烤箱外观是我们的 ② 16 条 `oven` 配方照常 ③ **没有新增方块类**（存档风险不增） |

#### B5 · Firmalife 香料 8 种 + 葡萄棚架（**物种接管**）

| 项 | 内容 |
|---|---|
| **现状** | 香料：`plant/{basil, bay_laurel, cardamom, cilantro, cumin, oregano, pimento, vanilla}`（**8 种**，产出 7 种香料，刀切/磨/干燥三条工序）；葡萄：**棚架 + 绳子系统**（**168 文件 / 9 类 / 10 blockstate / 27 配方**） |
| 🎯 **目标构想（香料）** | 8 种香料成为**我们的作物**（`MyCropBlock` 或沿用 `plant/<name>` 形态），并接入 §6.5 的调料系统 |
| 🎯 **目标构想（葡萄）** | ⛔ **不走果树管线** —— 用 **`MyClimbingCropBlock` + 自建棚架**重制（对齐"系统级覆盖"） |
| **手段** | 覆盖 `assets/firmalife/blockstates/plant/**` 等 + B 自建棚架方块 |
| ⚠️ **影响面** | 中 —— 葡萄的 27 条配方（`stomping`/`quern`/`vat`/`barrel_sealed`）要**保留**，只换种植形态 |
| **验收** | ① 8 种香料可种可收，产出接进调料链 ② 葡萄在棚架上生长，**踩踏 / 发酵链照常**（复用 Firmalife 已有的 `stomping`） |

#### C1 · A 侧唯一改动（`MySpeciesApi`）

见 §2.3。**验收**：A 单独构建通过 · `verify.ps1` 全绿 · **A 的 jar 里不出现 B 的字样**。

#### C2 · ❌ **明确不做的**：接管 A 的茶 / 咖啡 / hops / 纤维方块

按 **§5.1.1 定则**：**A 层已存在的物种，B 一律「只加链条、不碰方块」**。
⇒ A 的 `tea_bush` / `coffee_bush` / `crop/hops` / 5 种纤维作物**保持原样**，B 只加它们的加工链。
⇒ **好处**：A 单独运行时这 4 类**完全不受影响**；B 卸载后它们也只是"回到没有加工链"的状态。

---

### 10.3 🛑 改造优先级（**按"影响面 × 必要性"排**）

| 序 | 项 | 为什么这个顺序 |
|---|---|---|
| 1 | **A5 标签接入** | 零风险零代码，先拿确定收益 |
| 2 | **A1/A2 资源覆盖** | 只换皮，存档安全；但它决定"视觉统一"这个最大卖点 |
| 3 | **B4/B5 资源覆盖 + 物种接管** | 同上 |
| 4 | ⚠️ **A3 营养/腐烂 mixin** | **风险最高** ⇒ 先"只读探测"再"只加不改" |
| 5 | **A6 生长 mixin** | 风险次高，且 **1 个 mixin 承载 3 套功能** ⇒ 必须一次做完 |
| 6 | **B1~B3 条件让位组** | 有 hardcore 兜底 ⇒ 可以先不做，但**协议上要留位** |

🛑 **一句话**：**先做"只换皮"的，再做"改行为"的；改行为的里面，先做"只加不改"的，最后才动原逻辑。**

### 10.4 改造的**共同验收判据**（每项都要过）

| # | 判据 |
|---|---|
| 1 | **未改造的部分与 TFC / Firmalife 原版逐项一致**（回归基线 —— 改造不该"顺手改坏"别的） |
| 2 | **存档安全**：改造后进老存档，已有的方块/物品**不消失、不变形** |
| 3 | **卸载可回滚**：移除 B 后邻居**恢复原貌**（§六） |
| 4 | **台账已登记**（§3.6，含 mixin 与 A 侧改动） |
| 5 | **实机 8 条判据全过**（§5.3） |

---

## 十一、灵感扩充：现实农业加工 × extradelight（🆕 用户指示）

> 用户口径：「**你要做的是从现实生活的农业加工（尤其是原始农业生产）和 extradelight 模组汲取灵感，然后体现到文档中**」
>
> 本节 = **extradelight 实测** → **现实原始农业加工的 40 项完整清单** → **我们缺什么** → **每项的具体设计**。

### 11.1 extradelight 实测（**1.21.1 版**，19 种配方类型 / 13,198 条目）

| 配方类型 | 条数 | 现实对应 | 我们的现状 |
|---|---|---|---|
| `extradelight:oven` | **518** | 🍞 烘焙 | Firmalife `oven` **16 条** ⇒ **B4 覆盖** |
| `extradelight:feast` | 120 | 🍽 大餐（多人共享） | §9.2 **#11** 大餐方块 |
| `extradelight:mixing_bowl` | 108 | 🥣 搅拌 / 混合 | Firmalife `mixing_bowl` 15 条（§5.3.1 #4） |
| **`farmersdelight:cutting`** | **106** | 🔪 **砧板切分** | 🆕 ⭐ **值得借鉴 —— 我们没有"砧板"概念** |
| `extradelight:mortar` | 35 | 🧪 研钵 | §9.2 **#10** 研钵 |
| `smoking` / `smelting` / `campfire_cooking` | 33 × 3 | 🔥 烟熏 / 熔炼 / 营火 | TFC 有火塘；🆕 **烟熏值得补** |
| `extradelight:vat` | 21 | 🛢 发酵 / 腌制 | Firmalife `vat` **53 条** |
| `extradelight:dough_shaping` | 21 | 🥟 面团成型 | §9.2 **#3** 面团成型台 |
| 🆕 **`extradelight:tool_on_block`** | **15** | ⭐ **手持物品右键方块** | ⭐ **与我们的 `in_world` 同类**（见 §11.4） |
| `extradelight:chiller` | 12 | ❄ 冷藏 | 用户口径：**只做冷饮** |
| `extradelight:juicer` | 11 | 🍹 榨汁 | §9.2 **#9**（只做油料批量） |
| `extradelight:melting_pot` | 11 | 🍫 熔化 | §9.2 **#4** 熔化锅 |
| `extradelight:drying_rack` | 10 | ☀️ 晒干 | ⭐ **与 §7.2.5 #3 的"晒架"同名同用途** |
| `extradelight:evaporator` | 1 | 💨 蒸发浓缩 | §9.2 **#2** 蒸发浓缩器 |

⇒ **结论**：extradelight 的设备清单，**我们已在 §9.2 覆盖 8/10**；
它**独有且真正值得学**的只有两条 —— **`tool_on_block`（机制）** 与 **`cutting`（砧板切分，106 条）**。

### 11.2 现实原始农业加工**完整清单**（40 项，对照我们的覆盖）

> 视角：**原始农业**（无电力，靠人力 / 畜力 / 水力 / 火 / 日晒 / 时间）。
> 这是"深化加工"的**唯一权威参照** —— 因为 TFC 的设定就是前工业时代。

**A · 谷物收获后处理（8 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 1 | **收割** | 镰刀贴地割 | TFC 有作物收获 | ✅ 已有 |
| 2 | **捆扎** | 扎成捆便于搬运 / 立起来晒 | ❌ 无 | 🆕 **可做**（"谷捆"中间物） |
| 3 | **脱粒** | 摔打 / 连枷 / **畜力踩踏** | ✅ §7.2.5 **#2 脱粒垫** | 计划内 |
| 4 | **扬场** | 借风把壳吹走 | ✅ §7.2.5 #2（两级递进） | 计划内 |
| 5 | **舂米** | 杵臼**脱壳**（≠ 磨粉） | ❌ 无 | 🆕 **可做**（§7.2.5 **#4 碾磨槽**可承载） |
| 6 | **碾磨** | 石磨磨粉 | TFC `quern` ✅ | ✅ 已有 |
| 7 | **筛分 / 筛粉** | 筛出粗细（粗粉回磨、细粉做糕点） | ❌ 无 | 🆕 **可做**（筛子 + 2~3 档粉） |
| 8 | **制麦芽** | 浸泡 → 发芽 → 烘干 | ❌ TFC 啤酒直接用面粉 | ✅ §13.3-1（计划内） |

**B · 保存（防坏，10 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 9 | **晒干** | 日晒脱水 | ✅ Firmalife `drying` + §7.2.5 #3 晒架 | 计划内 |
| 10 | **风干 / 阴干** | 通风处慢慢干（保风味） | ❌ 与晒干混为一谈 | 🆕 **可做**（同设备不同时段） |
| 11 | **烟熏** | 冷熏 / 热熏（防腐 + 风味） | ⚠️ TFC 有火塘，**无烟熏** | 🆕 ⭐ **可做**（接 `smoky` 味道 trait） |
| 12 | **盐渍** | 盐腌 | ✅ TFC `can_be_salted` + `salted` trait | ✅ 已有 |
| 13 | **醋渍 / 泡菜** | 醋 / 乳酸发酵 | ✅ TFC `pickled` + `vinegar` trait | ✅ 已有 |
| 14 | **糖渍 / 蜜饯** | 糖煮后浸渍 | ❌ 无 | 🆕 **可做**（接 `sweet` trait） |
| 15 | **油浸** | 油封隔绝空气 | ❌ 无 | 🆕 **可做**（TFC 有油 ⇒ 纯数据 + trait） |
| 16 | **窖藏** | 地窖低温高湿 | ✅ §5.6 地窖（计划内） | 计划内 |
| 17 | **罐装** | 密封罐 + 加热灭菌 | ✅ TFC 有 `jar` / `canned` trait | ✅ 已有 |
| 18 | **青贮** | 青饲料密封发酵（冬季饲料） | ❌ 无 | 🆕 ⭐ **可做**（接 §6.3 新鲜草 + D 模块饲料） |

**C · 发酵（转化，6 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 19 | **面团发酵** | 酵母 / 老面 | ✅ Firmalife `oven` / 面团 | ✅ 已有 |
| 20 | **酒精发酵** | 果实 / 谷物 → 酒 | ✅ TFC 有酒类 + Firmalife 33 条 | ✅ 已有 |
| 21 | **醋酸发酵** | 酒 → 醋 | ✅ TFC `vinegar` | ✅ 已有 |
| 22 | **乳酸发酵** | 蔬菜 → 酸菜 | ✅ TFC `pickled` | ✅ 已有 |
| 23 | **曲霉发酵**（酱 / 酱油 / 豆酱） | 豆 + 曲霉 → 酱 | ❌ 无 | 🆕 ⭐⭐ **最值得补**（**中国农业的核心加工**，三方都没有） |
| 24 | **蒸馏** | 酒 → 烈酒 | ✅ TFC 有 whiskey / vodka | ✅ 已有 |

**D · 提取与分离（6 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 25 | **榨油** | 碾磨 → 蒸炒 → 压榨 | ✅ TFC `olive_oil`/`canola_oil` + §13.3-3 | 计划内 |
| 26 | **榨汁** | 压榨取汁 | ✅ §6.1.2（TFC `BarrelRecipe` 纯数据） | 计划内 |
| 27 | **踩踏** | 脚踩破皮（葡萄 / 橄榄） | ✅ Firmalife `stomping`（4 条） | ✅ 已有 |
| 28 | **制淀粉** | 磨浆 → 沉淀 → 干燥 | ❌ TFC 无 | ✅ §13.3-2（计划内） |
| 29 | **制糖** | 甘蔗压榨 → 熬煮结晶 | ⚠️ TFC 有甜味剂标签、AFC 有糖浆链 | ⚠️ **部分已有**，按需补 |
| 30 | **熬盐** | 卤水熬煮 / 晒盐 | ✅ TFC 有 `salt_water` / 盐 | ✅ 已有 |

**E · 纤维与纺织（5 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 31 | **沤麻（retting）** | 水浸数日脱胶 | ❌ 三方都没有 | ✅ §7.2.5 **#1 沤麻池**（计划内） |
| 32 | **打麻（scutching）** | 敲打分离木质部 | ❌ | ✅ §7.2.5 #2（计划内） |
| 33 | **梳麻（heckling）** | 梳顺纤维 | ❌ | 🆕 **可做**（极简：1 条配方） |
| 34 | **纺线（spinning）** | 纺锤 / 纺车 | ⚠️ Firmalife 有 `loom`（织） | ✅ 复用 `loom` |
| 35 | **织布（weaving）** | 织机 | ✅ Firmalife `loom` | ✅ 已有 |

**F · 火与土（5 项）**

| # | 加工 | 现实做法 | 我们的现状 | 处置 |
|---|---|---|---|---|
| 36 | **制炭** | 坑窑闷烧 | ✅ TFC `charcoal_pit` | ✅ 已有 |
| 37 | **烧灰** | 草木灰（钾肥 + 碱） | ✅ TFC `powder/wood_ash` + `Fertilizer` | ✅ 已有 |
| 38 | **堆肥** | 有机质腐熟 | ✅ TFC `compost` + `compost_browns/greens` 标签 | ✅ 已有 |
| 39 | **制皮革** | 鞣制 | ✅ TFC `tannin` | ✅ 已有 |
| 40 | **搅乳（churning）** | 奶油 → 黄油 | ❌ 无 | 🆕 **可做**（但**奶在 D 模块** ⇒ 归 C/D） |

### 11.3 ⇒ 结论：**40 项里已有 22 项，计划内 8 项，真正缺 10 项**

| 类别 | 已有 | 计划内 | 🆕 **真缺** |
|---|---|---|---|
| 谷物处理 | 3 | 2 | **捆扎 · 舂米 · 筛分** |
| 保存 | 5 | 2 | **风干 · 烟熏 · 糖渍 · 油浸 · 青贮** |
| 发酵 | 5 | 0 | **曲霉发酵（酱）** |
| 提取 | 4 | 2 | — |
| 纤维 | 1 | 3 | **梳麻** |
| 火与土 | 5 | 0 | **搅乳**（归 C/D） |

**⇒ 建议新增的 7 项（B 层）**：

| # | 新增项 | 现实依据 | 设计要点 | 载体 / 设备 | 批次 |
|---|---|---|---|---|---|
| **1** | ⭐⭐ **曲霉发酵（酱 / 酱油 / 豆酱）** | **中国农业的核心加工**（豆 + 曲 → 酱，可存数年） | 豆 → 蒸煮 → 拌曲 → **制曲（控温湿）** → 下缸发酵 → **酱**；酱是**调料** ⇒ 接 §6.5 的 `umami` 味道 trait；**保质期极长** | **`vat`（Firmalife 已有）+ 曲房（1 方块）** | 9 |
| **2** | ⭐ **烟熏** | 冷熏 / 热熏，防腐 + 风味 | 接 `smoky` trait；与**晒干 / 风干**共用设备思路 | 烟熏架（1 方块）· 复用 TFC 火塘热源 | 9 |
| **3** | ⭐ **青贮（silage）** | 青饲料密封发酵（冬季饲料） | 新鲜草 + 密封 → 青贮饲料（**D 模块饲料体系**的前置） | 青贮窖（1 方块）· 复用 §5.6 地窖概念 | 11 |
| **4** | **舂米 / 杵臼** | 杵臼**脱壳**（与磨粉是两件事） | 稻 / 黍 → 舂 → **精米 + 米糠**（糠 → 饲料，接 §13.2） | 🆕 **杵臼**（**专属方块**，§12.2 / §12.9 **#6**） | 6 |
| **5** | **筛分 / 筛粉** | 粗粉回磨、细粉做糕点 | 面粉分**粗 / 细**两档 ⇒ **同一种谷物两种用途** | 🆕 **筛架**（**方块**，§12.9 **#8**） | 8 |
| **6** | **风干 / 阴干** | 通风慢干（保风味） | 与晒干**同时段、不同条件** ⇒ 产物品质不同 | **晒架**（§12.9 **#1**，**加时间 / 位置维度**） | 6 |
| **7** | **糖渍 / 油浸** | 糖煮浸渍 / 油封 | 两种保存法 ⇒ 各对应一个味道 trait（`sweet` / `rich`） | 🆕 **陶缸**（**方块**，§12.9 **#11**；糖渍走 `pot`） | 9 |

⚠️ **共同点（🆕 已按用户口径修正）**：
- 🛑 ~~7 项里 4 项零新方块~~ —— **用户口径：「多添加更多方块来丰富处理流程」** ⇒
  **每一项都要有实体方块承载**：舂米 → **杵臼** · 筛分 → **筛架** · 风干 → **晒架的时间维度** · 糖渍/油浸 → **陶缸**
- ⭐ **详见 §十三「向 extradelight 学习」** —— 那里按**食品加工**重新设计了 **7 个新方块**（案板 · 搅拌碗 · 面包模 · 派盘 · 方盘 · 挂晒架 · 糖果碗），另有 6 道工序改用**合成 / 右键**
  （🛑 §十二 原先的 9 个方块已被用户口径撤销）
- **它们的产出全部接 §6.5 的"味道 trait"** ⇒ **与 A3 的新设计天然咬合**

### 11.4 extradelight 的 `tool_on_block` —— 与我们的 `in_world` 的关系

**实测 schema（15 条，全部是给姜饼上糖霜）**：

```jsonc
{
  "type": "extradelight:tool_on_block",
  "in":         { "id": "extradelight:gingerbread_cookie_block_item" },  // 世界里的方块
  "ingredient": { "tag": "c:frosting/blue" },                            // 手持物品（标签）
  "out":        { "id": "extradelight:gingerbread_block_blue" }          // 结果方块
}
```

| 对比项 | extradelight `tool_on_block` | woodwork `in_world` | **我们的设计** |
|---|---|---|---|
| 字段数 | **3**（`in` / `ingredient` / `out`） | 5（+ `requiredTool` / `sound` / `resultItems[]`） | 取**两者之长** |
| 工具门控 | ❌ 无（用 `ingredient` 代替） | ⚠️ **硬编码 2 值**（axe / saw） | ✅ **`TagKey<Item>` 驱动** |
| 产物形式 | 只换方块 | **4 种投放动作**（含投射物） | ✅ 保留 4 种 |
| 输入匹配 | 方块**物品**形态 | **完整 BlockState 枚举**（≤8 状态） | ✅ 用 woodwork 的（更精确） |
| 规模 | 15 条 | **240 条** | — |

⇒ ⭐ **两条独立证据**（1.20.1 的 FarmersDelight 系 + 1.21.1 的 woodwork）**都证明"手持物品 + 世界方块 → 结果"这条路可行**
⇒ 我们的 `in_world` 设计**不变**（§3.3），但**可以借鉴它的简洁命名**（`in` / `ingredient` / `out` 比 `inputState` / `resultItems` 好读）

### 11.5 🆕 从现实加工反推的**两条设计原则**

| # | 原则 | 依据 |
|---|---|---|
| 1 | **"同一原料、不同处理 ⇒ 不同产物"才是深度** | 现实里同一种谷物可以做成：米饭（**舂**）· 面粉（**磨**）· 粗粉（**筛**）· 麦芽（**发芽**）· 酒（**发酵**）—— **5 条路**。§13.2 的矩阵只写了"主产品 + 次产品"，**应加上"加工路径分叉"这一维** |
| 2 | **保存方式的差别应体现在"保质期 + 味道"，而不是"能不能吃"** | 现实里盐渍 / 烟熏 / 糖渍 / 油浸 / 青贮**都能吃**，区别是**能放多久 + 什么风味** ⇒ 🆕 **这正好是 `FoodTrait` 的设计**（`decayModifier` + tooltip），**与 A3 的新设计完全一致** |

🛑 **一句话**：**用户对调料的修正（只影响保质期 + 加味道标签）与现实的保存加工逻辑是同构的** ——
现实中的盐渍 / 烟熏 / 糖渍 / 油浸，本质就是"**给食物打一个延长保质期 + 带风味的标签**"。
⇒ **B 的调料系统应当覆盖这整套现实保存法，而不只是"往汤里加香料"。**

---

## 十二、加工流程逐工序分析（🆕 用户指示：多为处理流程添加方块）

> 用户口径：「**多添加更多方块来丰富处理流程**」+「**继续分析加工流程（比如谷物脱粒，剥玉米，剥豆子等等）**」
>
> ⚠️ **本节修正 §11.3 的倾向**：那里有 4 项写了"零新方块"——
> 🆕 **改为：每条工序链都要有实体方块承载**（"在田里/院子里干活"的实感是这类模组的核心体验）。

### 12.1 分析方法：把每类作物拆成**工序链**

原始农业的通用结构（**六段**）：

```
田间收获 → ①后处理（脱粒/脱荚/剥苞）→ ②清选（扬场/筛分）→ ③干燥 → ④储存
                                                              ↓
                                     ⑤加工（脱壳/碾磨/浸泡/蒸煮/发酵/压榨）
                                                              ↓
                                     ⑥成品（食物 / 油 / 纤维 / 调料）
```

**每一段都要有工位**（方块），且**工序之间要有可搬运的中间产物**（否则玩家感受不到"流程"）。

### 12.2 谷物类（13 种）—— 🎯 **脱粒是核心工序**

**小麦 / 大麦 / 黑麦 / 燕麦（TFC 四件套）的现实链**：

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | **收割** | 镰刀割穗秆 | TFC 收获（已有） | 谷物 |
| 2 | **捆扎** | 扎成捆、立起来风干 | **谷捆**（新物品，右键地面放置成方块） | 谷捆 |
| 3 | **干燥** | 晒 3~7 天 | **晒架**（放置谷捆 → 计时 → 干谷捆） | 干谷捆 |
| 4 | 🎯 **脱粒** | **摔打 / 连枷 / 畜力踩踏** | ⭐ **脱粒板**（手持干谷捆右键，`in_world`） | **籽粒 + 糠 + 秸秆** |
| 5 | **扬场** | 簸箕抛起，风把壳吹走 | ⭐ **风车（扬场机）**（投入带壳籽粒 → 净籽粒 + 糠） | 净籽粒 |
| 6 | **筛分** | 筛掉碎石 | **筛架** | 分级籽粒 |
| 7 | **碾磨** | 石磨 | TFC `quern`（已有） | 面粉 |
| 8 | **筛粉** | 分粗细 | **筛架**（复用） | 细粉 + 粗粉 |

**🎯 玉米（`maize`）—— 用户点名的"剥玉米"，它有两条特有工序**：

| 序 | 工序 | 现实做法 | 🆕 游戏设计 |
|---|---|---|---|
| 1 | **剥苞叶（husking）** | 剥开外层苞叶 | ⭐ **玉米专职工位**：手持玉米右键 ⇒ 苞叶（→ 饲料/编织）+ 玉米棒 |
| 2 | **脱粒（shelling）** | **从棒子上把粒搓下来**（≠ 小麦的摔打） | ⭐ **同一工位第二步**：玉米棒 → **玉米粒 + 玉米芯** |
| 3 | 玉米芯 | — | **副产物三用**：燃料 · 饲料 · 磨粉（玉米芯粉） |

⚠️ **关键设计差异**：**小麦靠"摔"、玉米靠"搓"、稻靠"砻"** —— 三者**不是同一道工序**，
所以**不能只做一个通用的"脱粒机"**。见 §12.9 的工位表。

**稻（`rice` / `wild_rice_stem`）—— 三段去壳**：

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 脱粒 | 摔打 | 脱粒板 | 稻谷 |
| 2 | **砻谷** | **土砻**（上下磨盘搓开谷壳） | ⭐ **土砻**（专用方块） | **糙米 + 稻壳** |
| 3 | **碾米** | **杵臼**捣去糠层 | ⭐ **杵臼**（专用方块） | **精米 + 米糠** |

⇒ ⭐ **稻米是"三级产物"（稻谷 → 糙米 → 精米）** —— 这是**所有作物里最长的链**，
也是最能体现"加工深度"的一条。**糙米与精米应有营养差异**（糙米纤维多、精米口感好）。

**高粱 / 黍 / quinoa / amaranth / buckwheat 等**：走"脱粒板 → 风车 → 磨"标准链。

### 12.3 豆类（9 种）—— 🎯 **剥豆子（脱荚）是核心工序**

**关键区分：两类豆的链完全不同**

| 类型 | 成员 | 吃法 | 工序 |
|---|---|---|---|
| **可食荚豆** | `pea` · `cowpea`（嫩）· `green_bean`(TFC) | 连荚吃 | 采收 → **手剥**（右键）→ 直接烹饪 |
| **干豆** | `common_bean` · `faba_bean` · `chickpea` · `lentil` · `soybean` · `winged_bean` · `pigeon_pea` | 剥粒吃 | 采收 → **干燥** → **脱荚** → 扬场 → 浸泡 → 煮/磨 |

**干豆的现实链**：

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 收割 | 连根拔或割 | 已有 | 豆株 |
| 2 | **干燥** | 挂起来晒到豆荚变黄发脆 | **晒架** | 干豆荚 |
| 3 | 🎯 **脱荚（剥豆子）** | **敲打 / 脚踩 / 手剥** | ⭐ **脱粒板**（复用谷物工位） | **豆粒 + 豆荚壳** |
| 4 | **扬场** | 簸箕扬 | **风车** | 净豆粒 |
| 5 | **浸泡** | 冷水泡 8~12 小时 | ⭐ **陶缸**（豆 + 水 → 泡发豆，缩短后续时间） | 泡发豆 |
| 6 | **磨浆** | 石磨加水磨 | TFC `quern` | **豆浆**（流体或物品） |
| 7 | **点卤 + 压制** | 卤水/石膏点浆 → 压成形 | ⭐ **豆腐箱**（豆浆 + 卤 → 豆腐） | 豆腐 |
| 8 | **制酱** | 豆 → 蒸 → 拌曲 → 发酵 | ⭐ **曲房 + 陶缸**（§11.3 的 #1） | **酱 / 酱油** |

⚠️ **豆荚壳有用途**（→ 饲料 `compost_greens`），否则"剥豆子"产出一堆垃圾物。

### 12.4 油料（3 种：`canola` · `sesame` · `safflower`）—— **五段榨油**

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 脱粒 | 摔打 | **脱粒板** | 油籽 |
| 2 | **炒籽** | 炒到出香（提高出油率） | **炒锅**（§6.6 已有设计） | 炒籽 |
| 3 | **碾磨** | 磨成粗粉 | TFC `quern` | 油籽粉 |
| 4 | **蒸** | 蒸到蛋白质凝固（便于出油） | ⭐ **蒸锅** | 蒸熟的油籽粉 |
| 5 | **制饼** | 用布/模具压成饼 | ⭐ **饼模**（或并入榨油机） | 油饼 |
| 6 | 🎯 **压榨** | **楔式榨 / 杠杆榨**（人力或畜力） | ⭐ **榨油机**（§9.2 #9 扩展成全流程） | **油 + 油饼** |
| 7 | 油饼 | — | **副产物**：饲料 / 肥料（接 `tfc:fertilizer`） | — |

⚠️ **现实里"炒 → 磨 → 蒸 → 压"四步缺一不可**（少一步出油率显著下降）——
这正好是**"长链加工"的天然素材**，比"一压就出油"有深度得多。

### 12.5 纤维（5 种：`cotton` · `flax` · `hemp` · `ramie` · `sisal`）—— **五段成布**

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 收割 | 拔秆 | 已有 | 纤维秆 |
| 2 | 🎯 **沤麻（retting）** | **水浸 5~14 天**让果胶分解 | ⭐ **沤麻池**（§7.2.5 #1，方块 + 水 + 时间） | 沤好的秆 |
| 3 | **干燥** | 晒干 | **晒架** | 干秆 |
| 4 | 🎯 **打麻（scutching）** | **刀打 / 折弯**剥掉木质部 | ⭐ **打麻架**（§7.2.5 #2） | **粗纤维 + 麻屑（木质）** |
| 5 | **梳麻（heckling）** | 用梳板梳顺、分出长纤维 | ⭐ **梳麻板**（🆕） | **长纤维（纺线用）+ 短纤维（造纸/填充）** |
| 6 | **纺线（spinning）** | 纺锤 / 纺车 | ⭐ **纺车**（🆕） | 线 |
| 7 | **织布（weaving）** | 织机 | Firmalife `loom`（已有） | 布 |
| 8 | 麻屑 | — | 副产物：**引火物 / 造纸 / 填缝**（TFC 已有 `straw` 类的用途） | — |

⚠️ **`sisal`（剑麻）是叶纤维**（不是茎纤维）⇒ **不沤麻，直接刮叶取纤维** ——
同族物种**工序不同**，这类差异要保留（§11.5 的原则 1）。

### 12.6 块根块茎（16 种）—— **清洗 / 去皮 / 切片 / 去毒 / 磨粉**

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 挖掘 | 锄 / 手拔 | 已有 | 块根 |
| 2 | **清洗** | 水里搓洗去泥 | ⭐ **水槽**（方块 + 水） | 洗净块根 |
| 3 | **去皮 / 切片** | 刀削皮、切片 | ⭐ **案板**（右键 + 刀，`in_world`） | 去皮块根 / 切片 |
| 4 | 🎯 **木薯去毒** | **浸泡 / 发酵 / 加热**（氰苷） | ⭐ **陶缸浸泡**（木薯**必须**泡过才能吃 —— 现实的硬约束） | 无毒木薯 |
| 5 | **磨浆 + 沉淀** | 磨碎 → 水洗 → 沉淀出淀粉 | ⭐ **沉淀池**（磨浆 → 沉淀 → 淀粉） | 淀粉 |
| 6 | **干燥** | 晒干成粉 | **晒架** | 淀粉粉 |
| 7 | 薯渣 | — | 副产物：**饲料** | — |

⚠️ **`cassava`（木薯）的去毒是"现实的硬约束"** ⇒ 生吃会中毒（游戏里做成"吃了会中毒"是**忠于现实**的设计）。

### 12.7 果实类（48 果树 + 12 灌木 + 5 瓜）—— **去核 / 切块 / 榨汁 / 熬煮**

| 序 | 工序 | 现实做法 | 🆕 游戏设计 | 产物 |
|---|---|---|---|---|
| 1 | 采摘 | 手摘 / 摇树 | 已有 | 果实 |
| 2 | **去核 / 去籽** | 刀切开挖核 | ⭐ **案板**（`in_world`） | 果肉 + 核（→ 育苗 / 燃料） |
| 3 | **切块 / 捣泥** | 切块或捣成泥 | **案板** / **研钵** | 果块 / 果泥 |
| 4 | **榨汁** | 压榨 | **榨油机**（复用，加榨汁配方） | 果汁（→ 可发酵成酒） |
| 5 | **熬煮（制果酱）** | 加糖慢煮 | TFC `pot` | 果酱（→ 罐装保存） |
| 6 | **晒干（果干）** | 晒 / 烘干 | **晒架** | 果干（**保质期大增** ⇒ 接 `FoodTrait`） |
| 7 | **熟成** | 部分果实需后熟 | ⭐ **熟成架**（§9.2 #7） | 熟成水果 |

### 12.8 调料（8 种香料 + 药草）—— **干燥 / 研磨 / 过筛**

| 序 | 工序 | 现实做法 | 🆕 游戏设计 |
|---|---|---|---|
| 1 | 采收 | 摘叶 / 挖根 / 收籽 | 已有 |
| 2 | **干燥** | 阴干（保香）或晒干 | **晒架**（§11.3 #6 的"风干/阴干"差异在这里体现） |
| 3 | **研磨** | 研钵 / 石磨 | **研钵**（§9.2 #10） |
| 4 | **过筛** | 分出粗细粉 | **筛架** |
| 5 | **调配** | 多种香料混合 | **案板 / 研钵**（配比 ⇒ 不同味道 trait） |

#### 12.8.1 🆕 补一道**漏掉的工序：油炸**（从 [`127-extradelight-full-analysis.md`](127-extradelight-full-analysis.md) §6.2 发现）

| 项 | 内容 |
|---|---|
| **发现来源** | extradelight 有一个 **`item/frying_oil` 标签**（"可用于油炸的油"）⇒ 说明**它把油炸当成独立工序** |
| **现实依据** | 油炸是**最古老的烹饪法之一**（油炸面食 · 油炸豆腐 · 天妇罗 · 炸糕） |
| **实现方式** | ✅ **TFC `pot` + 油（流体）** ⇒ **零新方块** |
| **抽象标签** | ⭐ **照它的做法定义 `tfcagricultureplus:frying_oil`**（不绑定具体油种 ⇒ 橄榄油/菜籽油/猪油都能用） |
| **产物** | **油豆腐**（品类 3）· **炸糕** · **油条/炸面团** · **炸蔬菜** · **炸鱼** |
| **为什么值得补** | ① 它是**"油的用途"**（否则油只能榨油/点灯）② 它是**"豆腐/面团"的重要出路** ③ **零成本**（复用 `pot`） |

### 12.9 ⇒ 汇总：**工位（方块）总表** —— ⚠️ **本节结论已被 §十三 推翻**（保留为推导过程）

> 🛑 **用户口径（2026-09-29 二次）**：「你现在要添加的新方块**除了切菜用的案板其他的都不适合**」·
> 「**主要目标是深化食品加工流程并且丰富食品**」⇒ **本节的 10 个方块里 9 个被否决**。
> ✅ **最终方案见 §十三**（聚焦食品的 **7 个新方块**）。本节保留，用于记录推导与"为什么否决"。

#### 12.9.0 🛑 二次修订（用户口径：「部分机械 TFC 已经存在，不需要额外添加」）

**实测 TFC 的全部 27 种配方类型**，其中**加工类**的关键 7 个：

| TFC 配方类型 | 条数 | 能力 | ⇒ 我们**不要**再做 |
|---|---|---|---|
| `heating` | **883** | 加热 / 烘焙 / 熔炼（火塘 · 炉） | ❌ 不做烘烤炉 |
| `barrel_sealed` | **309** | **密封发酵 · 腌制 · 浸泡** | ❌ **不做"陶缸"** —— 桶已完全够用 |
| `pot` | **145** | 煮 / 熬 | ❌ 不做"蒸锅"（`heating` 也可） |
| `quern` | **89** | **手推磨** | ⚠️ 磨粉**已有** |
| `pot_jam` | **66** | **熬果酱** | ❌ 不做果酱锅 |
| `loom` | **5** | **织布** | ❌ 不做织机 —— ⚠️ **更正：织机是 TFC 自己的**（`LoomBlockEntity`），**不是 Firmalife 的**；TFC 甚至还有 **`PowerLoomBlockEntity`（动力织机）** |
| `scraping` | 7 | 刮（皮革处理） | ⚠️ 与"去皮"部分重叠 |

⇒ 🛑 **我上一版列的 15 个新方块里，5 个要撤销、1 个要降级**：

| 原方案 | 裁决 | 改法 |
|---|---|---|
| ~~陶缸~~（浸泡 / 发酵 / 去毒 / 沉淀） | ❌ **撤销** | 用 TFC **`barrel_sealed`（309 条）** + `barrel_instant`（20 条） |
| ~~蒸锅~~ | ❌ **撤销** | 用 TFC **`pot`（145 条）** 或 `heating` |
| ~~水槽~~（清洗） | ❌ **撤销** | **合成**（带泥块根 + 水桶 → 洗净）或右键水源 |
| ~~筛架~~ | ❌ **撤销** | **右键物品**（筛子 + 右键方块）—— "筛"是**手持动作**，不需要台面 |
| ~~梳麻板~~ | ❌ **撤销** | **合成配方**（粗纤维 + 梳 → 长纤维 + 短纤维） |
| **杵臼** | ✅ **保留**（但需说明差异） | ⚠️ 与 `quern` 有重叠 ⇒ **必须说明**：**舂 = 脱壳**（粒状产物）· **磨 = 磨粉**（粉状产物）；现实里也是两种器具 |

⇒ **新方块从 15 降到 10 个**。

#### 12.9.1 🆕 四种实现方式的**选择判据**（用户口径：「部分工作可以使用合成、右键使用等方式」）

| 实现方式 | **什么时候用** | 本方案里的例子 |
|---|---|---|
| **方块 + `in_world`**（零 BE） | 工序需要「**场地 / 台面 / 器械**」，且是**一次性动作** | 脱粒板 · 风车 · 玉米工位 · 舂米 · **案板** |
| **方块 + BE** | 工序需要「**时间推进 + 环境条件**」 | 晒架 · 土砻 · 沤麻池 · 曲房 · 青贮窖 · 熏房 · 纺车 · 豆腐箱 |
| **合成配方** | 工序本质是「**把几样东西组合**」，**无场地需求** | **梳麻** · 配调料 · 包种子 · 清洗 |
| **右键物品** | 工序是「**手持工具作用于物品**」，**无场地需求** | **筛粉**（筛子 + 右键）· 剥嫩豆荚 · 去核 |

🛑 **一句话判据**：**"要场地"→方块；"要时间"→BE；"只是组合"→合成；"只是手持动作"→右键。**

⇒ 这直接**削减了方块数量**（原来我倾向"每个工序一个方块"），同时**保留了实感**（关键工序仍有工位）。

#### 12.9.2 修订后的工位表

> ⚠️ 下表是 §12.9 原表的**修订版**（原表保留在上方作为推导过程）。
> 标记：🆕 = 本轮新增 · ♻️ = 复用 TFC/Firmalife · 📐 = 合成/右键（**不是方块**）

> 🛑 **用户口径：「多添加更多方块来丰富处理流程」** ⇒ 下面**不再出现"零新方块"**。

| # | 工位方块 | 承载的工序 | 输入 → 输出 | 依据 |
|---|---|---|---|---|
| **1** | 晒架 ✅已有设计 | 晒干 · 风干 · 阴干 | 谷捆/豆荚/果/香料 → 干品 | §7.2.5 #3 |
| **2** | ⭐ **脱粒板** | **谷物脱粒 · 豆类脱荚 · 油料脱粒** | 干谷捆/干豆荚 → 籽粒 + 糠/荚壳 + 秸秆 | §7.2.5 #2（**扩展为三类通用**） |
| **3** | ⭐ **风车（扬场机）** | **扬场 · 筛分** | 带壳籽粒 → 净籽粒 + 糠 | 🆕 |
| **4** | ⭐ **玉米工位**（剥苞 + 脱粒） | **剥苞叶 · 搓玉米粒** | 玉米 → 苞叶 + 玉米粒 + 玉米芯 | 🆕 **玉米专属**（工序与小麦不同） |
| **5** | ⭐ **土砻** | **砻谷**（稻脱壳） | 稻谷 → 糙米 + 稻壳 | 🆕 **稻专属** |
| **6** | ⭐ **杵臼** | **碾米 · 舂粉** | 糙米 → 精米 + 米糠 | 🆕 **稻专属** |
| **7** | TFC `quern` ✅已有 | 碾磨 | 籽粒/豆/油籽 → 粉 | TFC |
| **8** | ⭐ **筛架** | **筛粉 · 分级** | 混合粉 → 细粉 + 粗粉 | 🆕 |
| **9** | 榨油机 ✅§9.2 #9 | **制饼 · 压榨 · 榨汁** | 油籽粉/果 → 油/汁 + 饼/渣 | §9.2 #9（**扩展为三用**） |
| **10** | ⭐ **蒸锅** | **蒸籽 · 蒸浆** | 油籽粉 → 蒸熟粉 | 🆕 |
| **11** | ⭐ **陶缸** | **浸泡 · 去毒 · 沉淀淀粉 · 发酵** | 干豆/木薯/淀粉浆 → 泡发/无毒/淀粉 | 🆕 **一方块承载四类** |
| **12** | ⭐ **案板** | **去皮 · 切片 · 去核 · 切碎** | 块根/果/蔬菜 → 处理品 | 🆕 **一方块承载四类** |
| **13** | ⭐ **水槽** | **清洗** | 带泥块根 → 洗净 | 🆕 |
| **14** | ⭐ **豆腐箱** | **点卤 · 压制** | 豆浆 + 卤 → 豆腐 | 🆕 |
| **15** | 沤麻池 ✅已有设计 | **沤麻** | 纤维秆 + 水 + 时间 → 沤好的秆 | §7.2.5 #1 |
| **16** | ⭐ **打麻架 + 梳麻板** | **打麻 · 梳麻** | 干秆 → 长纤维 + 短纤维 + 麻屑 | §7.2.5 #2 扩展 |
| **17** | ⭐ **纺车** | **纺线** | 长纤维 → 线 | 🆕 |
| **18** | Firmalife `loom` ✅已有 | 织布 | 线 → 布 | Firmalife |
| **19** | ⭐ **熏房** | **烟熏** | 肉/鱼/果 → 熏制品（+ `smoky` trait） | 🆕（§11.3 #2） |
| **20** | ⭐ **曲房** | **制曲** | 蒸豆 + 曲霉 → 曲 | 🆕（§11.3 #1） |
| **21** | ⭐ **青贮窖** | **青贮** | 新鲜草 + 密封 → 青贮饲料 | 🆕（§11.3 #3） |
| **22** | ⭐ **熟成架** ✅§9.2 #7 | 熟成 | 奶酪/酒/果 → 熟成品 | §9.2 #7 |

⇒ 🆕 **本轮真正新增的方块 = 10 个**（风车 · 玉米工位 · 土砻 · 杵臼 · 案板 · 豆腐箱 · 纺车 · 熏房 · 曲房 · 青贮窖）；
另有 **6 个已在 §9.2 / §7.2.5 规划**（晒架 · 脱粒板 · 榨油机 · 沤麻池 · 打麻架 · 熟成架）+ **5 个复用邻居**（`quern` · `loom` · `pot` · `barrel` · `heating`）+ **5 个改为合成/右键**（梳麻 · 筛粉 · 清洗 · 剥豆荚 · 去核）。
叠加 §9.2 的 **18 台设备** ⇒ **B 的方块总数 ≈ 28 个**（含 3 个条件让位的温室 / 地窖 / 灌溉）。

### 12.10 🛑 复用设计（**避免"设备海"**）

用户要"多方块"，但**不能变成"每道工序一个 GUI 机器"**（那既不像原始农业，也做不完）。三条原则：

| # | 原则 | 例子 |
|---|---|---|
| 1 | **同类工序共用一个方块** | 一个**脱粒板**同时管谷物/豆类/油料的脱粒（靠**配方**区分，不靠方块） |
| 2 | **同"工位族"共用一个方块** | 一个**陶缸**同时管浸泡/去毒/沉淀/发酵 |
| 3 | ⭐ **优先"手持物品 + 右键方块"（`in_world`）而非"打开 GUI"** | 案板的去皮/切片/去核全走 `in_world`；**只有需要"时间推进"的才做 BE**（晒架/沤麻池/曲房/青贮窖） |

⇒ 这直接呼应 §7.2.4：**`in_world` 是这套设计的主承载**，
而 **BE 只用在"需要计时"的工位**上（§12.9 里带 ⏱ 的那些）。

**方块的类型分布（供排期参考）**：

| 类型 | 数量 | 说明 |
|---|---|---|
| **纯 `in_world` 工位**（零 BE） | **5** | 脱粒板 · 风车 · 玉米工位 · 舂米 · 案板 |
| **需要 BE（计时）** | **6** | 晒架 · 土砻 · 沤麻池 · 曲房 · 青贮窖 · 熏房 |
| **需要 BE + 流体** | **2** | 榨油机 · 纺车（⚠️ 纺车实为计时，归上类亦可） |
| **♻️ 复用 TFC / Firmalife** | **4** | `quern`（磨）· `loom`（**TFC 自己的**织机）· `pot`（煮/熬）· `barrel_sealed`（**发酵/腌制**）· `heating`（**烟熏可用它**） |
| **📐 改为合成 / 右键**（**不是方块**） | **4** | 梳麻（合成）· 筛粉（右键）· 清洗（合成）· 剥嫩豆荚（右键） |

---

### 12.11 其他作物的加工（🆕 用户口径：「**其他作物的内容也要考虑**」）

> ⚠️ §12.2~12.8 只覆盖了 **9 族里的 7 族**。本节补齐 **叶菜 21 · 茄果瓜类 10 · 香草香料 4 · 特用 5**。

#### 12.11.1 叶菜（**21 种**）—— 🎯 **保存加工最重要**（叶菜是最易坏的）

`artichoke` · `arugula` · `asparagus` · `broccoli` · `brussels_sprouts` · `cardoon` · `cauliflower` · `celtuce` · `celery` · `chicory_root`(叶用) · `kale` · `lettuce` · `mustard_greens` · `napa_cabbage` · `perilla` · `purslane` · `spinach` · `swiss_chard` · `water_spinach` · `malabar_spinach` · `water_dropwort`

| 序 | 工序 | 现实做法 | 实现方式 | 产物 |
|---|---|---|---|---|
| 1 | **切 / 撕** | 手撕或刀切 | ⭐ **案板**（`in_world`） | 菜段 |
| 2 | 🎯 **盐渍** | 撒盐揉搓出水 | ✅ **TFC `barrel`**（`barrel_instant`） | 盐渍菜（`salted` trait） |
| 3 | 🎯 **乳酸发酵** | 压实密封 → 酸菜 / 泡菜 | ✅ **TFC `barrel_sealed`（309 条已覆盖这类）** | 酸菜（`pickled` trait） |
| 4 | **晒干** | 挂晒成干菜 | ⭐ **晒架** | 干菜（**保质期大增**） |
| 5 | **焯水 + 冷冻**？ | — | ❌ 不做（无冷冻概念） | — |
| 6 | 结球类特有 | 白菜/甘蓝**切丝 + 盐渍** | 案板 → barrel | 酸菜 |

🛑 **设计要点**：叶菜的价值**不在"多吃"，而在"能不能过冬"** ——
⇒ 它们的**主要出路是保存加工**（腌 / 渍 / 晒），这与 §11.5 的原则 2 完全一致。
⚠️ **A3 的 `FoodTrait` 在这里是主角**：盐渍 / 发酵 / 晒干**各对应一个保质期修正**。

#### 12.11.2 茄果瓜类（**10 种**）—— **籽是油料 · 络是纤维 · 葫芦是容器**

`bitter_melon` · `bottle_gourd` · `cantaloupe` · `chayote` · **`chili`** · `eggplant` · **`loofah`** · `okra` · `snake_gourd` · `winter_melon`

| 作物 | 特有工序 | 现实做法 | 实现方式 | 产物 |
|---|---|---|---|---|
| **`chili`（辣椒）** | 🎯 **晒干 → 磨粉** | 晒干辣椒、舂成辣椒粉 | **晒架** → **研钵** | **辣椒粉（调料！接 `spicy` trait）** |
| **`loofah`（丝瓜）** | 🎯 **取络** | 老丝瓜泡水去皮去籽 → 丝瓜络 | **案板 + 水** | **丝瓜络（纤维：洗具 / 过滤）** |
| **`bottle_gourd`（葫芦）** | 🎯 **制容器** | 老葫芦掏空晾干 → 水瓢/容器 | **案板 + 晒架** | **葫芦容器** |
| **瓜类通用** | 🎯 **取籽** | 掏籽 → 洗净 → 晒干 | **案板 + 晒架** | **瓜籽（→ 炒制零食 / 榨油）** |
| **`okra`（秋葵）** | 晒干 / 腌渍 | 晒干秋葵、腌秋葵 | 晒架 / barrel | 干秋葵 |
| **`eggplant`（茄子）** | 晒干（茄干）· 腌渍 | 切片晒干 | **案板 + 晒架** | 茄干 |
| **`cantaloupe` / `winter_melon`** | 熬煮（果酱）/ 糖渍 | 加糖慢煮 | **TFC `pot_jam`（66 条）** | 瓜酱 |
| **`tomato`（TFC）** | 晒干（番茄干）· 熬酱 | 晒 / 熬 | 晒架 / `pot` | 番茄干 · 番茄酱 |

⚠️ **瓜籽是"隐藏的油料"**（南瓜子油、冬瓜子）⇒ **与 §12.4 油料链联动**（10 种瓜 ⇒ 多一个油源）。
⚠️ **`chili` 是"作物 + 调料"双重身份**（§13.2 已标"辣椒是调料"）⇒ 它同时属于 §12.8 调料链。

#### 12.11.3 香草香料（**4 种**）+ 块根里的调料

`chive`（细香葱）· `fenugreek`（葫芦巴）· `garland_chrysanthemum`（茼蒿）· `perilla`（紫苏）

| 作物 | 特有工序 | 产物 |
|---|---|---|
| **`chive` / `perilla`** | 鲜用 / 晒干 → 研粉 | 香草碎 · 香草粉（`herbal` trait） |
| **`fenugreek`（葫芦巴）** | 🎯 **种子是香料、叶是蔬菜、芽是芽菜** —— **一物三用** | 香料（咖喱味）· 叶菜 · 芽菜 |
| **`garland_chrysanthemum`（茼蒿）** | 叶菜为主（也可做香料） | 蔬菜 |

⚠️ **调料的两处"外来户"**（§13.2 已标）：
- **`ginger`（生姜）· `turmeric`（姜黄）** 在**块根块茎族**，但**实际是调料**
- ⇒ 它们的加工走 **§12.8 调料链**（干燥 → 研磨 → 过筛），**不走块根链**
- ⇒ 🛑 **族的归属 ≠ 加工链的归属** —— 这一点必须在实现时不搞混

#### 12.11.4 特用（**5 种**）—— 🎯 **五种走向五条完全不同的链**

`agave` · `bambara_nut` · `gorgon_nut` · `hops` · `jobs_tears`

| 作物 | 🎯 主链 | 现实做法 | 实现方式 | 产物 |
|---|---|---|---|---|
| **`agave`（龙舌兰）** | **纤维链**（同剑麻） | 刮叶取纤维 | **案板 + 打麻架** | 粗纤维（→ §12.5 纺线） |
| | + **糖浆链** | 烤心 → 压汁 → 熬浓 | **榨油机 + `pot`** | **龙舌兰糖浆**（甜味剂 ⇒ `sweet` trait） |
| **`bambara_nut`（班巴拉豆）** | **豆类链** | 煮 / 磨 | **`pot` / `quern`** | 豆泥 · 豆粉 |
| **`gorgon_nut`（芡实）** | **水生坚果链** | 采种 → **脱壳** → 煮/磨 | **舂米/杵臼 + `pot`** | 芡实米 · 芡实粉 |
| **`hops`（啤酒花）** | 🎯 **酿酒链专用** | 干燥 → 加入麦芽汁煮沸 | **晒架 → `pot`** | 啤酒（→ §12.13） |
| **`jobs_tears`（薏苡）** | **谷物链** | 脱壳 → 碾 | **脱粒板 + 杵臼** | 薏米（药食两用） |

⇒ ⭐ **"特用"这个名字其实很准确**：它们**不属于任何一个大宗族**，每种的加工路径都不同 ——
⇒ 🛑 **实现时不能把它们塞进某一个族批处理**，要逐个对待。

#### 12.11.5 ⇒ 全 86 种的链覆盖核对

| 族 | 数量 | 主链 | 本节/前节位置 |
|---|---|---|---|
| 谷类禾本 | 13 | 脱粒 → 扬场 → 磨 | §12.2 |
| 豆类 | 9 | 干燥 → 脱荚 → 浸泡 → 磨浆 | §12.3 |
| 块根块茎 | 16 | 清洗 → 去皮 → 切片 → 磨/沉淀 | §12.6 |
| 叶菜 | 21 | **腌 / 渍 / 晒干** | §12.11.1 |
| 茄果瓜类 | 10 | 晒干 → 磨粉 · 取籽 · 取络 | §12.11.2 |
| 纤维 | 5 | 沤 → 打 → 梳 → 纺 → 织 | §12.5 |
| 油料 | 3 | 炒 → 磨 → 蒸 → 制饼 → 压榨 | §12.4 |
| 香草香料 | 4 | 干燥 → 研磨 → 过筛 | §12.8 / §12.11.3 |
| 特用 | 5 | **五条各异的链** | §12.11.4 |
| **合计** | **86** | ✅ **全覆盖** | — |

---

### 12.12 育种 / 育秧链（🆕 补：主方案 §6.8 的六环节在加工侧未体现）

> 主方案 **§6.8「育秧到收获的全流程深化」** 把流程拆成六环节：
> ① 留种/采种 ② 育苗 ③ 移栽 ④ 生长管理 ⑤ 收获 ⑥ 循环。
> 🆕 **本节补它在"加工侧"需要的工序与工位**（原 §6.8 只讲了种植侧）。

| 序 | 工序 | 现实做法 | 实现方式 | 说明 |
|---|---|---|---|---|
| 1 | **采种** | 留最好的植株不收，等种子成熟 | 掉落表（已有） | 有性繁殖 |
| 2 | 🎯 **种子干燥** | 晒干防霉（**种子含水率高就不能存**） | **晒架** | 干种子 |
| 3 | 🎯 **选种 / 筛种** | 筛掉瘪粒、按大小分级 | ⭐ **筛架 / 右键筛子** | **大粒 / 小粒**分档 |
| 4 | 🎯 **浸种** | 温水浸泡催芽 | ✅ **TFC `barrel`**（种子 + 水 + 时间） | 浸过的种子（**发芽更快**） |
| 5 | **催芽** | 保湿保温到露白 | `barrel_sealed` 或 **晒架保温** | 催芽种子 |
| 6 | **拌种** | 拌草木灰防虫 | **合成**（种子 + 灰） | 拌种（**抗病**） |
| 7 | **扦插 / 分株**（无性） | 枝条/块茎直接繁育 | **`in_world` 扦插**（§6.8 已定） | 无性苗（**保留母株性状**） |
| 8 | **育苗** | 苗床/容器 | ✅ Firmalife 6 种容器（**155 个 plantable 已填**） | 苗 |
| 9 | **移栽** | 苗移到田里 | ✅ **`in_world`**（§7.2.4 已定） | 定植 |

🛑 **与 TFC 的关系**：TFC 只有"种子 → 作物"一条直线（§6.8 已指出）⇒
**育种链是纯增量**（§6.8 已判"六环节深化"），本节补的是**其中需要"加工动作"的 5 道**（干燥/筛选/浸种/催芽/拌种）。

⚠️ **⚠️ `浸种` / `催芽` 在游戏里的价值**：**缩短生长时间**（现实原理：提前打破休眠）。
⇒ 这是"**用加工换时间**"的设计 —— 玩家愿意做，因为**省的是真实等待**。

### 12.13 酿酒链（🆕 补：主方案 §13.3-1 的麦芽化在 §十二 未体现）

> 主方案已有：**§13.3-1 谷物麦芽化** · **§9.1 #10 hops** · **§9.1 #11 麦芽化** · **§5.3.1 #2 发酵**
> 🆕 本节把它们**串成一条完整链**（原来散在三处）。

**现实酿酒六段（以啤酒为例）**：

| 序 | 工序 | 现实做法 | TFC 已有？ | 实现方式 | 产物 |
|---|---|---|---|---|---|
| 1 | 🎯 **制麦芽（malting）** | 谷物**浸泡 → 发芽 → 烘干**（停止发芽） | ❌ **TFC 没有** | ✅ **`barrel`（浸泡）+ 晒架（烘干）** —— **零新方块**（§9.1 #11 已定） | **麦芽** |
| 2 | **磨麦芽** | 粗碎（不磨成粉） | ✅ `quern` | `quern` | 碎麦芽 |
| 3 | 🎯 **糖化（mashing）** | 碎麦芽 + **热水**（60~70°C）静置 → 淀粉变糖 | ❌ | ✅ **`pot`**（加热 + 水）或 `barrel` | **麦芽汁** |
| 4 | 🎯 **煮沸 + 加酒花（hopping）** | 麦芽汁煮沸，加 **hops** 增苦防腐 | ❌ | ✅ **`pot`（145 条）** | 加酒花的麦芽汁 |
| 5 | **发酵（fermentation）** | 冷却 + 酵母 → 发酵 | ✅ **`barrel_sealed`**（TFC 的酒就是这么做的） | `barrel_sealed` | **啤酒** |
| 6 | **熟成（conditioning）** | 静置数周 | ✅ **熟成架**（§9.2 #7） | 熟成架 | 熟成啤酒（**品质更高**） |
| 7 | 🎯 **蒸馏（烈酒）** | 蒸馏提高酒精度 | ✅ **TFC 有 whiskey / vodka**（`alcohol.json` 数据驱动） | `pot` 加热（或复用 TFC 链） | **烈酒** |

⇒ ⭐ **关键发现：整条酿酒链"零新方块"** —— 全部落在 TFC 已有的 `barrel` / `pot` / `quern` / `heating` 上。
⇒ **B 要做的只是**：① 加**麦芽 / 麦芽汁 / 啤酒**的物品与数据 ② 把 **hops** 接进第 4 步
（§9.1 #10 已定："hops → 啤酒"）③ **酒类数据**（TFC 的 `alcohol.json` 是**一个通用定义**，我们加自己的酒种）。

⚠️ **与现实对照要注意**：TFC 的 `alcohol.json` 只有 **1 个文件**（不是每种酒一个）⇒
它**按"酒"这个大类**统一处理 ⇒ 我们的**新酒种**应当**复用这个范式**，而不是自建一套酒类系统。

### 12.14 养蚕与丝（🆕 补：主方案 §6.4 的养蚕在 §十二 未体现）

> 主方案已有：**§6.4 养蚕**（用 Firmalife `fruit_leaf` 作饲料）· **§9.1 #15** · **§9.2 #18 养蚕架**
> **§5.1 A 层的 `mulberry`（桑树）**作第二饲料。🆕 本节补**完整的丝加工链**。

| 序 | 工序 | 现实做法 | 实现方式 | 产物 |
|---|---|---|---|---|
| 1 | **采叶** | 摘桑叶 / 柞树叶 | ✅ 已有（`fruit_leaf` 通用果树叶 · `mulberry` 桑树） | 桑叶 |
| 2 | **养蚕** | 喂叶 → 蚕长大（4 龄）→ 吐丝 | ✅ **养蚕架**（§9.2 #18，`stage` 0 空 / 1 养蚕中 / 2 已结茧 = **3 状态**） | **蚕茧** |
| 3 | 🎯 **缫丝（煮茧抽丝）** | **茧在热水里煮**（软化丝胶）→ 找到丝头 → **抽丝** | 🆕 **这是原方案缺的一道工序** ⇒ ✅ **TFC `pot`（煮茧）→ 案板/右键（抽丝）** | **生丝** |
| 4 | **纺丝** | 生丝 → 丝线 | ✅ **纺车**（§12.9）或合成 | **丝线** |
| 5 | **织绸** | 丝线织成绸 | ✅ **TFC `loom`（5 条）** | **丝绸** |
| 6 | 副产物 | 蚕蛹（**高蛋白饲料/食物**）· 蚕沙（**肥料**） | ✅ 接 `fertilizer` / 饲料 | 蛹 · 沙 |

🛑 **用户口径回顾**（§6.4）：养蚕是**刻意砍掉全部育种与病害的极简版** ——
只保留「**喂 → 长 → 结茧 → 收**」四步，**不做**蜂种级别的复杂性。
⇒ **本节补的"缫丝/纺丝/织绸"属于"收"之后的加工**，与"不育种"的口径**不冲突**。

⚠️ **A 层已有的资产**：`mulberry`（桑树）已进果树管线 ⇒ **直接复用**（§5.1.1 定则：B 不动它）。
⚠️ **`fruit_leaf` 是通用果树叶** ⇒ 意味着**任何果树都能养蚕**（现实里柞蚕确实吃多种树叶）——

⇒ 🆕 **这是一个"横向出口"的好例子**：不新增物种，用已有资源开新用途（§13.2 的思路）。

#### 12.14.1 🆕 三条链的**共同点**（育种 / 酿酒 / 养蚕）

| 观察 | 结论 |
|---|---|
| **三条链都主要复用 TFC 的 `barrel` / `pot` / `quern` / `loom`** | ⇒ **几乎不需要新方块**（酿酒链是"零新方块"） |
| 三条链的**价值都在"中间产物"**（麦芽 · 麦芽汁 · 生丝 · 浸种） | ⇒ 这正是 §11.5 原则 1 说的「**同一原料、多条路**」 |
| 三条链**都接 `FoodTrait`**（酒 → 熟成 · 菜 → 腌制 · 果 → 晒干） | ⇒ **A3 是所有加工链的共同出口** |

---

## 十三、🛑 方向修正：向 extradelight 学习（用户指示）

> 用户口径（2026-09-29）：
> ①「**你现在要添加的新方块除了切菜用的案板其他的都不适合**」
> ②「**请你学习 extradelight**」
> ③「**你的主要目标是深化食品加工流程并且丰富食品**」

### 13.1 被否决的 9 个方块（**保留案板**）

| ❌ 否决 | 原因 |
|---|---|
| ~~风车（扬场机）~~ · ~~玉米工位~~ · ~~土砻~~ · ~~杵臼~~ | **不是"食品加工"** —— 它们是**谷物初处理**，且 TFC 的 `quern` 已覆盖"磨"的核心 |
| ~~豆腐箱~~ · ~~曲房~~ · ~~青贮窖~~ | 单用途方块，**不成体系**；且 `barrel_sealed` 已能做发酵 |
| ~~纺车~~ | **纤维/纺织** 不属于"食品" —— 那是 TFC `loom` + Firmalife 的领域 |
| ~~熏房~~ | ⚠️ 方向对（食品保存），但 **extradelight 的做法更好**（见 §13.2 手法 4：**挂晒**） |

✅ **保留：案板**（切菜）—— 因为它是「**所有食品加工的第一道工序**」，且 extradelight 也有对应的刀具/砧板概念。

### 13.2 ⭐ 从 extradelight 学到的**四个核心手法**（实测 822 blockstate / 1441 物品）

#### 手法 1 ⭐⭐ **模具体系**（同一份原料 × 不同模具 = 不同成品）—— **"丰富食品"最高效的手法**

extradelight 有 **7 种模具/容器**：

| 模具 | 现实对应 | 产物 |
|---|---|---|
| `loaf_pan` | 长条面包模 | 面包 · 磅蛋糕 |
| `pie_dish` | 派盘 | 各种派 |
| `square_pan` | 方盘 | 布朗尼 · 方糕 |
| `muffin_tray` | 松饼连模 | 松饼 · 小蛋糕 |
| `sheet` | 平烤盘 | 饼干 · 曲奇 |
| `bar_mold` | 条模 | 巧克力条 · 糖条 |
| `tray` | 托盘 | 摆盘 · 拼盘 |

⇒ 🎯 **核心洞察**：**一份面糊倒进不同模具 = 7 种不同食物** ——
这比"为每种食物做一个新配方"**高效得多**，而且**玩家能理解**（现实里就是这样）。

#### 手法 2 ⭐ **feast 方块**（一道菜 = 一个可放置方块）—— 120 条配方

`beef_stew_block` · `lasagna_block` · `macaroni_cheese_block` · `meatloaf_block` · `potroast_block` · `pulled_pork_block` · `stirfry_block` · `salad_block` · `curry_block` · `chili_con_carne` · `hotdish_block` · `hash_block` · `cheesecake` · `pumpkin_pie` …

⇒ 🎯 **一道菜做出来后可以"放上桌"，切成多份供多人食用** —— **这是"丰富食品"的展示面**。
⚠️ 我们的 §9.2 **#11 大餐方块**已经覆盖这个概念 ✅ **直接对齐它的做法**。

#### 手法 3 ⭐ **腌渍坛**（一个方块 × 多种内容物）—— 8 种 `pickled_*_block`

`pickled_beets` · `pickled_carrots` · `pickled_eggs` · `pickled_fish` · `pickled_ginger` · `pickled_onions` · `pickled_rinds` · `pickled_sausage` · `preserved_lemons`

⇒ 🎯 **一个"腌渍坛"方块，通过内容物区分** ——
⚠️ **但 TFC 的 `barrel_sealed`（309 条）已经能做这件事** ⇒ 🛑 **我们不再做方块，改用 `barrel` + 我们的原料**。

#### 手法 4 ⭐ **挂晒**（`hanging_*`，7 种）—— **"挂起来风干"的实体化**

`hanging_chili` · `hanging_corn` · `hanging_garlic` · `hanging_onions` · `hanging_mint` · `hanging_dried_chili` · `hanging_ham`

⇒ 🎯 **比"晒架"更有画面感**：把辣椒/大蒜/玉米**串起来挂在墙上/梁上**风干。
⇒ ⭐ **这正是"熏房"的正确形态** —— 用户否决熏房是对的，**应该做成"挂晒"而不是"熏房"**。

### 13.3 ⇒ 重新设计：**聚焦食品加工的 7 个新方块** —— 🛑 **本表已被 §13.7 二次修正（净剩 5 个）**

> ⚠️ **修正结果**：本表 7 个里有 **2 个与 Firmalife 重复**（搅拌碗 · 糖果碗/巧克力模）、**1 个改变形态**（挂晒架 → **干燥架**）。
> ✅ **最终 5 个**：**案板 · 面包模 · 派盘 · 方盘 · 干燥架**（见 §13.11）。下表保留为推导过程。

> 🎯 用户口径：「**深化食品加工流程并且丰富食品**」⇒ 下面的方块**全部服务于食品**，不做纤维/育种/机械。

| # | 方块 | 手法来源 | 承载的工序 | 为什么需要它 |
|---|---|---|---|---|
| **1** | ✅ **案板** | extradelight 的刀具概念 | **切 · 剁 · 切片 · 去核 · 切丝** | 食品加工的**第一道工序**（保留） |
| **2** | ⭐ **搅拌碗** | `mixing_bowl`（**108 条**） | **和面 · 搅拌 · 混合 · 打发** | 面食/糕点/酱料的**前置**（TFC 没有） |
| **3** | ⭐⭐ **烤模 · 面包模**（`loaf_pan`） | 手法 1 | 面团 → **面包 / 磅蛋糕** | 模具体系第 1 件 |
| **4** | ⭐⭐ **烤模 · 派盘**（`pie_dish`） | 手法 1 | 面团 + 馅 → **各种派** | 模具体系第 2 件（**用户点名的"派重做"正需要它**） |
| **5** | ⭐⭐ **烤模 · 方盘**（`square_pan`） | 手法 1 | 面糊 → **布朗尼 / 方糕 / 千层** | 模具体系第 3 件 |
| **6** | ⭐ **挂晒架**（`hanging_*`） | 手法 4 | **辣椒 · 蒜 · 洋葱 · 玉米 · 香草 · 肉** 的风干 | 取代被否决的"熏房"，**更有画面感** |
| **7** | ⭐ **糖果碗 / 巧克力模** | `candy_bowl` + `bar_mold` | **巧克力 · 糖艺 · 蜜饯** | 接 §5.2 的**可可接管** |

⚠️ **7 个里 3 个是"烤模"** —— 但它们是**模具体系的载体**，
⇒ 🆕 **实现建议**：**3 个模具可以做成同一套方块类的 3 个实例**（共用 BE 与逻辑，只换形状与配方），
⇒ 这样**开发量 = 1 个方块类 + 3 个注册项**，而不是 3 套独立实现。

### 13.4 🆕 从 extradelight 学到的**食品丰富化手法**（不新增方块也能丰富）

⚠️ extradelight 有 **1441 个物品** —— 但**大部分不是靠新方块做出来的**，而是靠这 4 种"数据驱动"的手法：

| # | 手法 | 说明 | 我们的适用性 |
|---|---|---|---|
| **1** | **流体酱汁** | 它有 **30+ 个 `*_fluid_block`**（broth · gravy · ketchup · mayo · jam · caramel · chocolate_syrup · hot_cocoa · milkshake · whipped_cream…） | ⭐ **强适用** —— 我们的油/汁/酱都该做成流体（接 §6.1.2 果汁） |
| **2** | **中间产物** | `flour` · `cornmeal` · `breadcrumbs` · `stuffing` · `yeast` · `butter` · `cheese` · `dough` … | ⭐ **强适用** —— 我们已有 §13.3 的中间产物计划，**再加"面包糠/馅料/酵母"** |
| **3** | **一物多用** | 同一种原料进不同链（如 `corn` → 玉米粒/玉米面/玉米糊/爆米花） | ⭐ **强适用** —— 正是 §11.5 原则 1 |
| **4** | **摆盘/上桌** | `food_display`（11 材质）· `charcuterie_board` · `fruit_bowl` · `jar_display` | 🟡 **可选** —— 这是装饰向的，⚠️ 主方案 §2.8 已定"**不借鉴装饰体系**" ⇒ **只取"大餐方块"这一个**（§9.2 #11） |

⇒ 🎯 **结论**：**"丰富食品"主要靠"流体 + 中间产物 + 一物多用"，而不是靠堆方块**。
方块只在"**需要一个操作台面**"时才加 —— 这与 §12.9.1 的四选一判据**完全一致**。

### 13.5 🛑 修正后的**方块总账**

| 类别 | 数量 | 明细 |
|---|---|---|
| **§9.2 原有设备** | **18 台** | 干燥架 · 蒸发浓缩器 · 面团成型台 · 熔化锅 · 香料架 · 炒锅 · 熟成架 · 保冷设施 · 榨油机 · 研钵 · 大餐方块 · 漏斗/龙头 · `in_world` · 温室 · 地窖 · 灌溉 · 育秧/苗床 · 养蚕架 · 菌包 |
| 🆕 **§十三 新增（食品加工）** | **7 个** | 案板 · 搅拌碗 · 面包模 · 派盘 · 方盘 · 挂晒架 · 糖果碗/巧克力模 |
| **♻️ 复用 TFC / Firmalife** | **5 个** | `quern`（磨）· `loom`（织）· `pot`（煮/熬）· `barrel_sealed`（发酵/腌制/浸泡）· `heating`（加热/烟熏） |
| **📐 改为合成 / 右键** | **6 道** | 梳麻（合成）· 筛粉（右键）· 清洗（合成）· 剥嫩豆荚（右键）· 去核（右键）· 脱粒（？见下） |
| ❌ **撤销**（前两版） | **9 + 5** | 风车 · 玉米工位 · 土砻 · 杵臼 · 豆腐箱 · 纺车 · 熏房 · 曲房 · 青贮窖 · 陶缸 · 蒸锅 · 水槽 · 筛架 · 梳麻板 |

⇒ **B 的方块总数 ≈ 25 个**（18 + 7），其中**食品加工相关的 25 个全部在内**。

### 13.6 ⚠️ 一个遗留问题：**脱粒怎么办？**

🛑 **用户否决了"风车/玉米工位/土砻"**，但 §12.2 论证过「**小麦靠摔、玉米靠搓、稻靠砻，三者不是同一道工序**」。
⇒ 现在的选择：

| 方案 | 做法 | 评价 |
|---|---|---|
| **A** | **全部走合成/右键**（手持谷物 → 合成出籽粒 + 糠） | ✅ 最简单，符合"部分工作可以用合成"口径<br>⚠️ 失去"在场上干活"的实感 |
| **B** | **保留 `in_world` 的"脱粒"动作**，但**不新增方块** —— 直接对**已有方块**（如 `tfc:threshing_floor`？没有） | — |
| **C** | **合成 + 时间**：谷捆 → 晒架（干）→ **合成**（脱粒）→ 籽粒 + 糠 | ⭐ **推荐** —— 用了已有的晒架（§7.2.5 #3），脱粒走合成 |

⇒ 🆕 **推荐 C**：**"干燥"给晒架（有实感），"脱粒"走合成（零方块）**。
⚠️ **待用户确认**。

---

### 13.7 🛑 第二次修正：**Firmalife 已有的比我想的多得多**（用户口径）

> 用户口径：「**干燥有 firmalife 的干燥垫，可以添加额外的架子并且重新设计其干燥垫和干燥器**」
> 「**搅拌碗和烟熏存在于 firmalife 中，进行学习和使用**」

#### 实测 Firmalife 3.0.15（5,981 条目 / **29 种配方类型**）

| Firmalife 配方类型 | 条数 | 我原方案的冲突 |
|---|---|---|
| **`vat`** | **53** | 发酵主力（§5.3.1 #2 已知） |
| `tfc:heating` | 38 | — |
| `tfc:pot` | 33 | — |
| `tfc:barrel_sealed` | 22 | — |
| ⭐ **`drying`** | **16** | 🛑 **我提的"挂晒架"与它重叠** ⇒ 见 §13.9 |
| ⭐ **`oven`** | **16** | B4 已计划覆盖 |
| ⭐ **`mixing_bowl`** | **15** | 🛑 **我提的"搅拌碗"就是它** ⇒ **撤销** |
| `bowl_pot` / `tfc:pot_jam` | 8 / 8 | — |
| ⭐ **`stomping`** | **4** | 踩踏（§12.7 已识别） |
| ⭐ **`centrifuge`** | **3** | 🆕 **离心机**（我漏了） |
| ⭐ **`smoking`** | **2** | 🛑 **我提的"熏房"就是它** ⇒ **撤销** |
| `stinky_soup` | 2 | 臭汤（发酵失败品？） |

#### Firmalife 的**加工设备清单**（部分）

| 设备 | 说明 | 我们的态度 |
|---|---|---|
| ⭐ **`drying_mat`** | **干燥垫**（`drying` 16 条：菠萝纤维 · 香草 · **8 种土纲的泥→土**） | 🆕 **重制它 + 加"架子"形态**（见 §13.9） |
| ⭐ **`mixing_bowl`** | **搅拌碗**（**支持流体 + 物品混合**：米线 · 巧克力 · 冰淇淋 · 硬饼干面团） | ❌ **不新增，直接用它** |
| ⭐ **`stovetop_pot` / `stovetop_grill`** | 灶台锅 / 灶台烤架 | ❌ 已有 |
| ⭐ **`jarring_station`** | **装罐台**（4 向 `facing`） | ❌ 已有 |
| ⭐ **`wood/barrel_press`（20 树种）** | **桶压榨机** | ❌ 已有（**我提的"榨油机"要重新考虑**） |
| ⭐ **`wood/wine_shelf`（20）** | **酒架**（= 我提的"熟成架"的原型） | ⚠️ 用它的 |
| ⭐ **`wood/food_shelf`（20）** | **食品架**（= 保鲜容器，§5.6 已计划） | ⚠️ 用它的 |
| ⭐ **`wood/jarbnet` / `wood/keg` / `wood/stomping_barrel`（各 20）** | 罐柜 / 小桶 / 踩踏桶 | ❌ 已有 |
| **4 种烤箱**（brick · clay · rustic · stone · tile × insulated） | 烘焙 | B4 覆盖 |
| **6 种种植容器** | `quad` / `large` / `hanging` / `hydroponic` / `bonsai` / `trellis` | ✅ A 层已填 155 个 plantable |
| **温室 6 材质 · `sprinkler` · `floor_sprinkler` · `pumping_station`** | 温室灌溉 | §5.6 已计划 |

⇒ 🛑 **我 §13.3 的"7 个新方块"里，3 个与 Firmalife 重复**（搅拌碗 · 挂晒架 · 烟熏相关）。

#### ⭐ `smoking` 的实现方式对我们**极有参考价值**

```jsonc
{"type":"firmalife:smoking",
 "ingredient":{"type":"tfc:and","children":[
    {"tag":"c:foods/raw_meat"},
    {"type":"tfc:not_rotten"},
    {"type":"tfc:lacks_trait","trait":"firmalife:smoked"}]},   // ⭐ 用 trait 做"已熏过"判定
 "result": ...}
```

⇒ 🛑 **两个直接结论**：
1. **Firmalife 已经注册了 `firmalife:smoked` trait** ⇒ 🆕 **我们的调料 trait 命名要避开它，并复用它**（不要再造 `smoky`）
2. **`tfc:lacks_trait` 是一个现成的配方条件** ⇒ 🆕 **各味道 trait 的"只保留一个"可以用它实现**（§10.2 A3 的方案 A 落地更简单了）

### 13.8 🆕 用户第 3 条之一：**手持工具**（不做方块）

> 用户口径：「**工序添加一些手持工具（如石臼，簸箕）**」

| 工具 | 现实对应 | 用途 | 为什么做手持而不是方块 |
|---|---|---|---|
| ⭐ **石臼 + 杵** | 石臼/研钵 | **研磨**（香料 · 谷物 · 豆） | 便携、随处可用；**与 TFC `quern`（固定磨）分工**：臼=小批量/粗磨，磨=大批量/细粉 |
| ⭐ **簸箕** | 竹/藤簸箕 | **扬场**（去壳、分级） | 扬场是**手持抛洒动作**，不需要台面 |
| ⭐ **筛** | 竹筛/罗 | **筛分**（分粗细、去杂） | 同上是手持动作 |
| ⭐ **连枷** | 木连枷 | **脱粒**（打谷） | ⭐ **这解决了 §13.6 的遗留问题** —— 脱粒**不需要方块**，用**手持连枷**即可 |
| **刀** | 菜刀 | 切（配合案板 `in_world`） | ⚠️ TFC 有 `knife` ⇒ **复用** |

⇒ ⭐ **关键洞察**：**"手持工具"是"少方块"与"有实感"之间的第三条路** ——
它比"合成配方"有操作感（要拿工具、要对着目标用），又比"专用方块"轻量（不用注册方块/BE/贴图集）。

🛑 **`石臼` 与 `TFC quern` 的分工要写清楚**（否则玩家会问"为什么有两个磨"）：

| | 石臼（手持） | `quern`（TFC 方块） |
|---|---|---|
| 批量 | 小（一次 1 份） | 大（可放多份） |
| 产物 | **粗磨**（香料粉 · 碎粒） | **细粉**（面粉） |
| 场景 | 随身 · 厨房 | 固定 · 作坊 |

### 13.9 🆕 用户第 3 条之二：**基于 TFC 机械装置的动力工具**（⭐ 本方案唯一的"自动化"入口）

> 用户口径：「**基于 tfc 机械装置的工具**」+（既定口径）「**动力系统不动，仅添加部分自动化机器**」

#### 实测 TFC 的动力系统（**完整且开放**）

| 组件 | 实测 | 说明 |
|---|---|---|
| **动力源** | `wood/water_wheel/*`（**水车**）· `wood/windmill/*`（**风车**）—— **各 20 树种** | ✅ 已有，**我们不动** |
| **传动** | `wood/axle` · `wood/bladed_axle` · `wood/encased_axle` · `wood/gear_box` · `wood/clutch` · `crankshaft` | ✅ 已有 |
| **流体** | `steel_pump` · `FluidPumpBlock` · `FluidPipeBlock` | ✅ 已有 |
| ⭐ **动力消费端 API** | **`util/rotation/`：`SinkNode`（汇）· `SourceNode`（源）· `AxleNode` · `Node` · `Rotation` · `RotationAccess` · `RotationNetwork` · `RotationNetworkManager`** | 🆕 ⭐ **这就是我们的接入点** |
| 现有消费者 | **`PowerLoomBlock`（动力织机）** —— ⚠️ **TFC 唯一的动力加工设备** | ⇒ **动力加工设备是一个大空白** |

⇒ 🎯 **结论**：**TFC 提供了完整的"动力网 + 消费端 API"，但几乎没做"动力驱动的加工设备"**（只有动力织机）。
⇒ ⭐ **这就是"添加部分自动化机器"的正确落点**：**实现 `SinkNode`，让我们的加工设备被水车/风车驱动。**

#### 基于动力的加工设备（🆕 设计）

| # | 动力设备 | 对应工序 | 现实对应 | 与手持/手动版的关系 |
|---|---|---|---|---|
| **1** | ⭐⭐ **动力磨** | 碾磨 | 水磨/风磨 | **`quern` 的动力版**（同产物，效率高得多）—— 现实里水磨就是这么取代手推磨的 |
| **2** | ⭐ **动力榨油机** | 压榨 | 水碓式榨油 | 手动压榨的动力版（§9.2 #9 的升级） |
| **3** | ⭐ **动力脱粒机** | 脱粒 | 畜力/水力脱粒 | 手持连枷的动力版 |
| **4** | **动力筛分机** | 筛分 | 水力筛 | 手持筛的动力版 |
| **5** | **动力搅拌机** | 和面/搅拌 | 水力和面 | `mixing_bowl` 的动力版（Firmalife 有手动的） |

🛑 **两条硬约束**（用户既定口径）：
1. **不动 TFC 的动力系统本身** —— 不加动力源、不改传动、不改 `RotationNetwork`
2. **只做"消费端"**（`SinkNode`）⇒ **我们的设备是"用电设备"，不是"发电设备"**

⚠️ **技术风险**（必须先在批次 4 验证）：
- `SinkNode` 的接入协议（转速/扭矩要求、网络增删时机）**需要反编译确认**
- ⚠️ 若 API 不够用，**退回方案**：用"手动曲柄"（TFC 有 `crankshaft`）**临时驱动**，或**降级为手动设备**

### 13.10 🆕 用户第 1 条：**干燥体系的重制**（Firmalife 干燥垫 + 我们的架子）

> 用户口径：「**干燥有 firmalife 的干燥垫，可以添加额外的架子并且重新设计其干燥垫和干燥器**」

#### 实测：Firmalife 的干燥体系

| 项 | 实测 |
|---|---|
| 方块 | **`drying_mat`（干燥垫）** —— blockstate 只有 `variants`（**状态极简**） |
| 配方类型 | `firmalife:drying`（**16 条**），schema 极简：`{ingredient, result}` |
| 配方内容 | 菠萝 → **菠萝纤维** · `plant/vanilla` → **`spice/vanilla`** · ⭐ **8 种土纲的 `tfc:mud/*` → `tfc:dirt/*`** |

🛑 **关键约束**：那 **8 条"泥→土"配方是 TFC 基础玩法的一环**（泥浆晒干成土）⇒
**我们重制干燥垫时必须保留它们**（覆盖资源，**不覆盖配方**）。

#### 🆕 设计：**干燥三形态**（垫 / 架 / 器）

| 形态 | 来源 | 特点 | 我们的动作 |
|---|---|---|---|
| **干燥垫**（`drying_mat`） | Firmalife 已有 | 铺在地上，**占地 1×1，不能叠** | ⭐ **重制**（资源覆盖成我们的风格）· **保留它的 16 条配方** |
| ⭐ **干燥架**（新） | 用户要求"额外的架子" | **立式、可叠层**（一层放更多） | 🆕 **新增方块** —— 与垫**互补**（垫=地面大量，架=墙边省地） |
| ⭐ **干燥器**（新） | 用户要求"重新设计…干燥器" | **加速干燥**（利用火塘余热 / 温室） | 🆕 可做成**干燥架的升级形态**（同一方块类 + 不同 tier？） |

⚠️ **技术提示**：干燥架的"可叠层"要**控制状态数**（§7.2.4 的 `in_world` 约束 ≤8 状态）；
建议做成 **`tier`(0/1/2) × `slot`(是否有物)** 的**极简状态**，而不是每层一个方块。

🛑 **与 `drying` 配方类型的关系**：既然 `firmalife:drying` 的 schema 是 `{ingredient, result}`，
🆕 **我们的干燥架可以直接复用这个配方类型**（不必新造）⇒ **零新配方类型**，只要方块能"读 drying 配方"即可。

### 13.11 ⇒ **第二次修正后的方块总账**

| 类别 | 数量 | 明细 |
|---|---|---|
| **§9.2 原有设备** | 18 台 | （见 §9.2） |
| 🆕 **§十三 保留的新方块** | **5 个** | **案板** · **面包模** · **派盘** · **方盘** · **干燥架**（+ 可选：干燥器） |
| ❌ **从 §13.3 撤销** | **3 个** | ~~搅拌碗~~（Firmalife 有）· ~~挂晒架~~（改为"干燥架"）· ~~糖果碗/巧克力模~~（⚠️ 待核实 Firmalife 是否已有巧克力链） |
| 🆕 **重制（覆盖资源，不是新方块）** | **1 个** | **Firmalife `drying_mat`**（保留其 16 条配方） |
| 🆕 **手持工具**（**物品，不是方块**） | **4 个** | **石臼+杵** · **簸箕** · **筛** · **连枷**（刀复用 TFC `knife`） |
| 🆕 **动力设备**（`SinkNode`） | **3~5 个** | **动力磨** · **动力榨油机** · **动力脱粒机**（+ 可选：动力筛 / 动力搅拌） |
| **♻️ 复用 TFC / Firmalife** | **8+** | `quern` · `loom` · `pot` · `barrel_sealed` · `heating` · **`mixing_bowl`** · **`stovetop_pot/grill`** · **`barrel_press`** · **`jarring_station`** · **`drying_mat`** |

⇒ **本节结论 = 净新增 5 个**（案板 · 面包模 · 派盘 · 方盘 · 干燥架）
🛑 **但该结论已被 §十四 第三次修正** —— 用户口径「**方块和工序还不够多**」⇒ **最终为 15 个方块 + 9 个新配方类型**。
⇒ 但**加工深度反而增加**：因为多了 **4 个手持工具** + **3~5 台动力设备**。

🛑 **一句话总结这次修正**：
**"深化食品加工"不靠堆方块，靠"手持工具（低技术）+ 动力设备（高技术）"两端延伸，中间复用 Firmalife 已有的台面。**

---

## 十四、🛑 第三次修正：方块与工序**系统性扩充**（用户口径：「方块和工序还不够多」）

> 用户口径（2026-09-29 三次）：「**方块和工序还不够多，继续学习 extradelight**」
> ⇒ 我上一轮收敛到 5 个方块**过头了**。本节**系统对照 extradelight 的全部 29 个设备**，把缺口一次补齐。

### 14.1 ⚠️ 首先：**extradelight 的协议是 `CC BY-NC-SA 4.0`**（必须写进硬性要求）

| 项 | 值 |
|---|---|
| 协议 | **`CC BY-NC-SA 4.0`**（署名 · **非商业性使用** · 相同方式共享） |
| 与我们（MIT）的冲突 | 🛑 **MIT 允许商业使用，CC BY-NC-SA 不允许** ⇒ **两者不兼容** |

⇒ 🛑 **硬性要求（与 §2.8 对 DragN / Aquaculture2 的处理一致）**：

> **extradelight 与 CC BY-NC-SA 协议模组：只能借鉴「玩法与设计思路」，不得复制其代码、资源、数据文件。**
> 理由：① 协议含**非商业**限制，与我们的 MIT 冲突；② "相同方式共享"会传染。
> ✅ **可以做的**：学它的**设备清单 · 工序划分 · 配方结构思路**（游戏机制不受版权保护）。
> ❌ **不可以做的**：抄 JSON 配方、抄贴图、抄 Java 代码。

### 14.2 extradelight 的**全部 29 个设备** → 逐项对照

| # | extradelight 设备 | 中文 | 我们的状态 | 🆕 动作 |
|---|---|---|---|---|
| 1 | `oven` | 烤箱 | B4 覆盖 Firmalife | ✅ 已有 |
| 2 | **`baking_stone`** | **烘焙石** | ❌ **无** | 🆕 **补**（**平面烘焙**：烤饼 · 薄饼 · 馕） |
| 3 | `bbq` | 烧烤架 | TFC `firepit` / `grill` | ♻️ 复用 |
| 4 | `chiller` | 冷藏柜 | §9.2 **#8** 保冷设施 | ✅ 已有 |
| 5 | `dough_shaping` | 面团成型台 | §9.2 **#3** | ✅ 已有 |
| 6 | `drying_rack` | 干燥架 | Firmalife `drying_mat` + 我们的干燥架 | ✅ 已有 |
| 7 | `evaporator` | 蒸发器 | §9.2 **#2** | ✅ 已有 |
| 8 | `funnel` | 漏斗 | §9.2 **#12** | ✅ 已有 |
| 9 | `jar` | 罐 | TFC `jar` | ♻️ 复用 |
| 10 | `juicer` | 榨汁机 | §9.2 **#9** 榨油机（可兼） | ✅ 已有 |
| 11 | `keg_block` | 小桶 | Firmalife `keg` | ♻️ 复用 |
| 12 | `melting_pot` | 熔化锅 | §9.2 **#4** | ✅ 已有 |
| 13 | `mixing_bowl` | 搅拌碗 | Firmalife `mixing_bowl` | ♻️ 复用 |
| 14 | `mortar_stone` | 研钵 | §9.2 **#10** | ✅ 已有 |
| 15 | `serving_pot` | 上菜锅 | §9.2 **#11** 大餐方块 | ✅ 已有 |
| 16 | `tap` | 龙头 | §9.2 **#12** | ✅ 已有 |
| 17 | `vat` | 发酵桶 | Firmalife `vat` | ♻️ 复用 |
| 18 | ⭐ **`vinegar_pot`** | **醋母罐** | ❌ **无** | 🆕 **补**（⭐ **醋母的"传代培养"**） |
| 19 | ⭐ **`yeast_pot`** | **酵母罐** | ❌ **无** | 🆕 **补**（⭐ **酵母的"传代培养"**） |
| 20 | ⭐ **`candy_bowl`** | **糖果碗** | ❌ **无** | 🆕 **补**（糖艺：糖果 · 蜜饯 · 糖霜） |
| 21 | ⭐ **`charcuterie_board`** | **熟食板** | ❌ **无** | 🆕 **补**（风干熟食：火腿 · 香肠 · 腊肉） |
| 22 | `jar_display_block` | 罐展示 | ❌ | ❌ 装饰，不做 |
| 23 | ⭐ **`sink`**（11 材质） | **水槽** | ❌ **无** | 🆕 **补**（**清洗工位**：洗菜 · 洗果 · 洗手） |
| 24 | `spice_rack`（11 材质） | 香料架 | §9.2 **#5** | ✅ 已有 |
| 25 | ⭐ **`knife_block`**（11 材质） | **刀具架** | ❌ **无** | 🆕 **补**（与**案板**配套：放刀 · 取刀） |
| 26 | `step_stool`（11 材质） | 踏凳 | ❌ | ❌ 纯家具 |
| 27 | `food_display`（11 材质） | 食品展示 | ❌ | ❌ 装饰（§2.8 已定**不借鉴装饰体系**） |
| 28 | ⭐ **模具 8 个** | — | 我们只有 **3** 个 | 🆕 **扩到 6 个**（见 §14.3） |
| 29 | `mint_lamb` 等 | 食物方块 | — | （feast 类，非设备） |

⇒ 🆕 **识别出 8 个真正的缺口**：**烘焙石 · 醋母罐 · 酵母罐 · 糖果碗 · 熟食板 · 水槽 · 刀具架 + 3 个模具**。

### 14.3 🆕 模具体系扩充（3 → **6 个**）

extradelight 有 **8 个模具/容器**：`loaf_pan` · `pie_dish` · `square_pan` · `muffin_tin` · `sheet_tray` · `baking_tray` · `bar_mold` · `lid`（`lid` 是发酵桶盖，不算模具）。

⇒ 我们扩到 **6 个**（去掉重复的 `baking_tray`，加上 `bar_mold`）：

| # | 模具 | 现实对应 | 产物类型 |
|---|---|---|---|
| 1 | **面包模**（loaf_pan） | 长条模 | 面包 · 磅蛋糕 |
| 2 | **派盘**（pie_dish） | 圆盘 | 各种**派**（⭐ 用户点名的"派重做"） |
| 3 | **方盘**（square_pan） | 方模 | 布朗尼 · 方糕 |
| 4 | 🆕 **松饼连模**（muffin_tin） | 多孔连模 | **松饼 · 小蛋糕**（**一次多个**） |
| 5 | 🆕 **平烤盘**（sheet_tray） | 平盘 | 饼干 · 曲奇 · **薄脆** |
| 6 | 🆕 **条模**（bar_mold） | 条状模 | **巧克力条 · 糖条 · 肥皂**？ |

⇒ ⭐ **"一份面糊 + 6 种模具 = 6 种食物"** —— 这就是 §13.2 手法 1 的完整落地。

### 14.4 ⭐⭐ 最值得学的两个：**酵母罐 / 醋母罐**（**"发酵引子"的传代培养**）

> 这是 extradelight 里**最有设计感的两个方块**，而且**TFC / Firmalife 都没有**。

**现实依据**：
- **酵母**（老面 / 酸面团 starter）：面粉 + 水 → 每天喂 → **长期养着**，越养越香
- **醋母**（mother of vinegar）：酒 + 醋酸菌 → **一层菌膜** → 不断产出醋

⇒ 🎯 **游戏设计**：

| 方块 | 机制 | 产物 |
|---|---|---|
| **酵母罐** | 放入面粉 + 水 → **培养** → 得到**酵母**（引子）；**喂食可维持**（不喂会死） | 酵母（→ 面包发酵） |
| **醋母罐** | 放入酒 → **醋酸菌作用** → **醋**；**醋母留在罐里**（可继续用） | 醋（→ 腌制 · 保存） |

⭐ **为什么这两个设计好**：
1. **"引子"是"活的"** —— 需要维护（TFC 的 `FoodTrait`/腐坏机制天然适配）
2. **一次投入，长期受益** —— 与"一次性配方"完全不同
3. **产生"传家宝"体验** —— 玩家的老面可以一直用下去（现实里也有百年老面）

⚠️ **与既有内容的关系**：TFC 有 `barrel_sealed`（发酵）· Firmalife 有 `vat` —— 
但它们都是**"放进去等结果"**；**酵母罐/醋母罐是"养一个引子"** ⇒ **不是重复，是补充**。

### 14.5 🆕 扩充后的**完整方块清单**（15 个）

| # | 方块 | 类别 | 来源 |
|---|---|---|---|
| 1 | **案板** | 处理 | §13.1 保留 |
| 2 | **刀具架** | 处理（配套） | 🆕 §14.2 #25 |
| 3 | **水槽** | 处理（清洗） | 🆕 §14.2 #23 |
| 4 | **烘焙石** | 加热 | 🆕 §14.2 #2 |
| 5 | **面包模** | 模具 | §13.3 |
| 6 | **派盘** | 模具 | §13.3 |
| 7 | **方盘** | 模具 | §13.3 |
| 8 | **松饼连模** | 模具 | 🆕 §14.3 |
| 9 | **平烤盘** | 模具 | 🆕 §14.3 |
| 10 | **条模** | 模具 | 🆕 §14.3 |
| 11 | **干燥架** | 干燥 | §13.10 |
| 12 | **酵母罐** | ⭐ 发酵引子 | 🆕 §14.4 |
| 13 | **醋母罐** | ⭐ 发酵引子 | 🆕 §14.4 |
| 14 | **糖果碗** | 糖艺 | 🆕 §14.2 #20 |
| 15 | **熟食板** | 风干熟食 | 🆕 §14.2 #21 |

⇒ **15 个方块**（§9.2 的 18 台设备**之外**）⇒ **B 的方块总数 ≈ 33 个**。

⚠️ **实现要点**：**6 个模具建议共用 1 个方块类**（只换形状与配方）⇒ 实际开发量 ≈ **10 个方块类**。

### 14.6 🆕 工序（配方类型）扩充

**现状**：TFC **27 种** · Firmalife **29 种** · extradelight **19 种**（实测）。

**我们要的配方类型**：

| # | 配方类型 | 状态 | 用途 |
|---|---|---|---|
| 1 | `tfc:barrel_sealed` | ♻️ 复用 | 发酵 · 腌制 · 浸泡 |
| 2 | `tfc:pot` / `pot_jam` / `pot_soup` | ♻️ 复用 | 煮 · 熬 · 汤 |
| 3 | `tfc:heating` | ♻️ 复用 | 加热 · 烟熏 · 烘干 |
| 4 | `tfc:quern` | ♻️ 复用 | 磨粉 |
| 5 | `tfc:loom` | ♻️ 复用 | 织布 |
| 6 | `firmalife:drying` | ♻️ 复用 | **干燥**（含我们的干燥架） |
| 7 | `firmalife:smoking` | ♻️ 复用 | **烟熏**（用 `firmalife:smoked` trait） |
| 8 | `firmalife:mixing_bowl` | ♻️ 复用 | **搅拌**（支持流体+物品） |
| 9 | `firmalife:oven` | ♻️ 复用（B4 覆盖资源） | **烘焙** |
| 10 | `firmalife:vat` | ♻️ 复用 | 发酵 |
| 11 | `firmalife:stomping` | ♻️ 复用 | 踩踏 |
| 12 | `firmalife:centrifuge` | ♻️ 复用 | 离心 |
| 13 | **`tfcagricultureplus:in_world`** | 🆕 **新建** | **手持物品 + 方块**（案板 · 干燥架 · 模具等全靠它） |
| 14 | **`tfcagricultureplus:feast`** | 🆕 **新建** | **大餐**（一道菜 = 方块，§9.2 #11） |
| 15 | **`tfcagricultureplus:mortar`** | 🆕 **新建** | **研磨**（研钵 §9.2 #10） |
| 16 | **`tfcagricultureplus:dough_shaping`** | 🆕 **新建** | **面团成型**（§9.2 #3） |
| 17 | **`tfcagricultureplus:melting`** | 🆕 **新建** | **熔化**（§9.2 #4） |
| 18 | **`tfcagricultureplus:juicing`** | 🆕 **新建** | **榨汁**（§9.2 #9 兼） |
| 19 | **`tfcagricultureplus:evaporating`** | 🆕 **新建** | **蒸发浓缩**（§9.2 #2） |
| 20 | **`tfcagricultureplus:chilling`** | 🆕 **新建** | **冷藏**（§9.2 #8） |
| 21 | **`tfcagricultureplus:starter`** | 🆕 **新建** | ⭐ **发酵引子**（酵母罐 / 醋母罐**共用**） |
| 22 | 🆕 **`tfcagricultureplus:bottle_fluid`** | 🆕 **新建**（学 1.20.1 版，37 条） | ⭐ **把流体装进瓶子**（果汁 · 酱汁 · 油 —— 可携带/保存/交易） |
| 23 | 🆕 **`tfcagricultureplus:dynamic_jam`** | 🆕 **新建**（学 1.20.1 版，12 条） | **动态果酱**（按原料算营养与颜色） |
| 24 | 🆕 **`tfcagricultureplus:flour_dough`** | 🆕 **新建**（学 1.20.1 版） | **面粉 + 水 → 面团**（TFC 有 `food/*_dough` 但无通用转换） |
| 25 | ♻️ **TFC `anvil`** | ♻️ **复用** | ⭐ **模具不是合成的，是"打"出来的**（学 `extradelighttfc`，§18.1 手法 5） |

⇒ 🆕 **新建 12 个配方类型**（#13~#24），复用 **13 个**。

🛑 **配方类型的设计原则**（照 §3.3 的 `in_world` 骨架）：
每类都要 **`RecipeType` + `RecipeSerializer`（MapCodec）+ `StreamCodec`** 三件套，
且**优先照 TFC 现有类型的 schema**（如 `mortar` 照 `quern`、`chilling` 照 `heating`）。

### 14.7 ⇒ **"工序还不够多"的最终答案**

**从 6 段工序链 → 扩到 9 段**（§12.1 的六段 + 新增三段）：

```
田间 → ①后处理 → ②清选 → ③干燥 → ④储存
                                    ↓
        ⑤预处理（🆕 清洗 · 切配 · 研磨）
                                    ↓
        ⑥转化（发酵 · 腌制 · 烟熏 · 糖渍 · 油浸）
                                    ↓
        ⑦成型（🆕 搅拌 · 面团成型 · 模具 · 挤条）
                                    ↓
        ⑧热处理（🆕 烘焙 · 蒸煮 · 熔化 · 熬糖 · 冷藏）
                                    ↓
        ⑨成品（食物 · 酱汁 · 饮品 · 大餐）
```

⇒ **新增的三段（⑤预处理 / ⑦成型 / ⑧热处理）正是 extradelight 最强的地方**，
⇒ 也是"**丰富食品**"的真正来源：**同样的原料，经过这三段的不同组合，产出成倍的食物种类。**

---

## 十五、🆕 新品类拓展（用户口径：「**不要局限于已有内容，应当拓展新的品类**」）

> 用户口径（2026-09-29 四次）：「**学习的点很好，但是还是单薄**，你可以基于此**适当填充内容**（依旧是参考 extradelight），
> **不要局限于已有内容，应当拓展新的品类**」

### 15.1 方法：先查**家底空白**，再定品类（**实测，不凭空**）

实测 TFC 的原料清单后，发现**六处"有原料、没产品"的空白** —— 它们就是新品类的落点：

| TFC 已有原料 | TFC 却没有的产品 | ⇒ 新品类 |
|---|---|---|
| **`food/sugarcane`**（甘蔗） | 🛑 **完全没有糖**（无 sugar / syrup / molasses） | ⭐ **糖与甜味剂** |
| **枫树**（`wood/*/maple` 全套木材） | 🛑 **没有枫糖浆** | ⭐ **树液糖** |
| **`food/cheese` · `curdled_milk` · `bucket/milk`** | 🛑 **没有黄油 / 奶油 / 酸奶** | ⭐ **奶制品加工** |
| **`food/cooked_egg` · `boiled_egg`** | 🛑 **只有煮蛋**（无蛋黄酱 / 蛋白霜 / 蛋奶冻） | ⭐ **蛋制品** |
| **`food/soybean`** | 🛑 **完全没有豆制品**（无豆浆 / 豆腐 / 酱油 / 味噌） | ⭐⭐ **大豆制品** |
| **`food/fresh_seaweed` · `dried_seaweed` · `dried_kelp`** | 🛑 **只有干海藻**（无海苔 / 琼脂） | ⭐ **藻类制品** |

⚠️ **同时确认已有的基础**（可直接扩展，不用重建）：
- ✅ **面粉 / 面团 / 面包体系完整**：`barley` · `maize` · `oat` · `rye` · `rice` · `wheat` **各 3 件套**（面粉 / 面团 / 面包）= **18 个物品**
- ✅ **花生酱已有**（`jar.peanut` + `peanut_jam`）⇒ ⭐ **TFC 已有"坚果加工"的先例**，可照此扩展
- ✅ **醋已有**（`bucket/vinegar`）· **盐已有**（`powder/salt`）· **奶酪已有**
- ✅ **A 层已有**：可可 · 茶 · 咖啡 · 86 种作物 · 48 果树

### 15.2 🆕 十二个新品类（逐类设计）

#### 品类 1 ⭐⭐ **糖与甜味剂**（**TFC 完全空白**）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **压榨** | **榨油机/榨汁机**（§9.2 #9 兼） | **蔗汁**（流体） |
| 2 | **澄清** | `pot` 加热 + 石灰 | 澄清蔗汁 |
| 3 | **熬煮浓缩** | **§9.2 #2 蒸发浓缩器** | **糖浆**（流体） |
| 4 | **结晶** | 冷却 + 搅拌 | **粗糖**（黄糖） |
| 5 | **精炼** | 反复煮 + 滤 | **白糖** · **糖粉**（研磨） |
| 6 | **副产品** | 分出的母液 | **糖蜜**（molasses）⇒ **深色面包 / 朗姆酒 / 烧烤酱** |

⇒ **产物 6 项**：蔗汁 · 糖浆 · 粗糖（红糖）· 白糖 · 糖粉 · 糖蜜
⇒ 🆕 **枫树支线**：枫树**打孔取汁**（`in_world`）→ 熬煮 → **枫糖浆** → 继续熬 → **枫糖块**
⇒ ⭐ **糖是"下游品类的钥匙"**：糖果 · 巧克力 · 甜点 · 酱料**全都需要它**。

#### 品类 2 ⭐⭐ **奶制品加工**（TFC 只有奶酪）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **搅乳（churning）** | `barrel` 反复搅动 | **黄油** + **酪乳** |
| 2 | **澄清** | `pot` 慢熬去水 | **酥油**（ghee，耐储存） |
| 3 | **静置分离** | `jar` 静置 | **奶油**（上层） |
| 4 | **打发** | **§9.2 #3 搅拌/打发** | **打发奶油** |
| 5 | **发酵** | `barrel_sealed` + 菌种 | **酸奶** |
| 6 | **滤乳清** | 布袋过滤 | **希腊酸奶** · **乳清**（→ 饮料/饲料） |
| 7 | **冷冻 + 搅打** | **§9.2 #8 保冷设施** | **冰淇淋** |
| 8 | **乳清再煮** | `pot` | **里科塔奶酪** |

⇒ **产物 9 项**：黄油 · 酪乳 · 酥油 · 奶油 · 打发奶油 · 酸奶 · 希腊酸奶 · 乳清 · 冰淇淋 · 里科塔
⚠️ **奶源在 D 模块**（畜牧）⇒ 但**加工链在 B** ✅

#### 品类 3 ⭐⭐ **大豆制品**（**最大空白，中国农业的核心**）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **浸泡** | `barrel`（水 + 时间） | 泡发大豆 |
| 2 | **磨浆** | `quern` + 水 | **豆浆**（流体） |
| 3 | **煮浆** | `pot` | 熟豆浆 |
| 4 | **点卤** | **§14.2 #23 水槽 / 或专用点卤** | **豆腐脑** → 压制 → **豆腐** |
| 5 | **压制程度** | 压得越久越硬 | **嫩豆腐 · 老豆腐 · 豆干** |
| 6 | **油炸** | `pot` + 油 | **油豆腐** |
| 7 | **发酵** | **§14.4 曲房/引子罐** | **腐乳** |
| 8 | ⭐ **制曲（koji）** | **酵母罐**（§14.4 的 `starter` 配方类型） | **米曲 / 豆曲** |
| 9 | **下缸发酵** | `barrel_sealed` + 曲 + 盐水 | **酱油** · **豆酱** · **味噌** |

⇒ **产物 10 项**：豆浆 · 豆腐脑 · 嫩豆腐 · 老豆腐 · 豆干 · 油豆腐 · 腐乳 · 米曲 · 酱油 · 豆酱 · 味噌
⭐ **这一条链同时产出"食材 + 调料"**（酱油/味噌是调料 ⇒ 接 §6.5 的 `umami` trait）
⭐ **并且它是"引子"机制（§14.4）的最佳用例** —— 曲是可以"养"的。

#### 品类 4 ⭐ **蛋制品**（TFC 只有煮蛋）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **分离蛋黄/蛋白** | **案板**（`in_world`） | 蛋黄 · 蛋白 |
| 2 | **乳化** | **搅拌/打发** + 油 + 醋 | **蛋黄酱**（流体） |
| 3 | **打发** | 搅拌/打发 | **蛋白霜** |
| 4 | **低温烘** | `oven` 低温 | **马林糖** |
| 5 | **混合 + 蒸** | `pot` | **蛋奶冻**（custard） |
| 6 | **焦糖化** | 撒糖 + 火烤 | **焦糖布丁** |
| 7 | **盐渍/腌制** | `barrel_sealed`（盐/灰） | **咸蛋** · **皮蛋**？ |

⇒ **产物 7 项**：蛋黄 · 蛋白 · 蛋黄酱 · 蛋白霜 · 马林糖 · 蛋奶冻 · 布丁 · 咸蛋

#### 品类 5 ⭐⭐ **巧克力**（A 层有可可）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **烘烤** | `oven` / 炒锅 | 烘焙可可豆 |
| 2 | **去壳** | **案板** | 可可碎（nibs）+ 壳（→ 肥料/覆盖物） |
| 3 | **研磨** | `quern` / 研钵（长时间） | **可可液块**（流体） |
| 4 | **压榨分离** | **榨油机** | **可可脂** + **可可饼** → 磨 → **可可粉** |
| 5 | **调配** | **§9.2 #4 熔化锅** | 可可液块 + 糖 + 奶 = **黑/牛奶/白巧克力** |
| 6 | **浇模** | **§14.3 条模**（`bar_mold`） | **巧克力条** |
| 7 | **手工成型** | 案板 | **松露巧克力** |
| 8 | **冲调** | `pot` + 奶 | **热可可** |

⇒ **产物 9 项**：烘焙可可豆 · 可可碎 · 可可液块 · 可可脂 · 可可粉 · 黑巧 · 牛奶巧 · 白巧 · 巧克力条 · 热可可
⭐ **§14.3 的"条模"就是为它设计的**（extradelight 的 `bar_mold` 正是巧克力/糖条模）。

#### 品类 6 ⭐ **糖艺与糖果**（空白）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **熬糖**（分温度档） | `pot` + 温度控制 | **糖浆（软球/硬球/焦糖档）** |
| 2 | **浇模** | 模具（多种） | **硬糖** · **软糖** · **太妃糖** |
| 3 | **充气** | 搅拌/打发 | **棉花糖** · **牛轧糖** |
| 4 | **加坚果** | 搅拌 | **坚果糖** |
| 5 | **加果胶** | 果汁 + 糖 + 琼脂/果胶 | **果冻** · **软糖** |
| 6 | **裹糖/挂霜** | `barrel` 滚动 | **糖霜球** · **蜜饯** |

⇒ **产物 8 项**：硬糖 · 软糖 · 太妃糖 · 棉花糖 · 牛轧糖 · 坚果糖 · 果冻 · 蜜饯

#### 品类 7 ⭐ **肉制品与熟食**（C/D 有畜牧）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **绞碎** | **案板**（`in_world`） | 绞肉 |
| 2 | **灌肠** | 案板 + 肠衣 | **生香肠** |
| 3 | **风干** | **§13.10 干燥架** | **腊肠** · **萨拉米** |
| 4 | **烟熏** | `firmalife:smoking` | **熏肠** · **熏肉** |
| 5 | **盐渍 + 风干** | `barrel` + 干燥架 | **火腿**（长期） |
| 6 | **盐渍 + 熏** | 同上 | **培根** |
| 7 | **切薄片 + 摆盘** | **§14.2 #21 熟食板** | **熟食拼盘**（feast 类） |
| 8 | **熬骨** | `pot` 长时间 | **高汤**（broth，流体） |
| 9 | **浓缩** | 蒸发浓缩器 | **肉汁**（gravy） |

⇒ **产物 10 项**：绞肉 · 生香肠 · 腊肠 · 萨拉米 · 熏肠 · 熏肉 · 火腿 · 培根 · 熟食拼盘 · 高汤 · 肉汁

#### 品类 8 ⭐ **酱料与调味汁**（空白）

| 酱 | 配方构成 | 用途 |
|---|---|---|
| **番茄酱**（ketchup） | 番茄 + 糖 + 醋 + 香料 | 蘸料 |
| **蛋黄酱**（mayo） | 蛋黄 + 油 + 醋 | 蘸料 / 沙拉酱 |
| **芥末酱** | 芥末籽 + 醋 + 盐 | 蘸料 |
| **烧烤酱**（BBQ） | 番茄 + **糖蜜** + 醋 + 烟熏味 | 涂抹 |
| **辣椒酱** | 辣椒 + 醋 + 盐 + 蒜 | 蘸料 |
| **甜辣酱** | 辣椒酱 + 糖 | 蘸料 |
| **酱油**（品类 3） | 大豆 + 曲 + 盐 | 中式调味 |
| **鱼露**？ | 鱼 + 盐 + 长期发酵 | 东南亚调味 |

⇒ **产物 8 项**（全为**流体** ⇒ 接 §13.4 手法 1）
⭐ **酱料是"丰富食品"的倍增器** —— 同一种主食配不同酱 = 不同体验。

#### 品类 9 ⭐ **饮品**（TFC 有酒 / 水 / 奶）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **榨汁** | 榨汁机 | **果汁**（多种，流体） |
| 2 | **发酵** | `barrel_sealed` | **果酒** |
| 3 | **加曲/蒸馏** | `pot` | **白兰地 / 果渣酒** |
| 4 | **加奶** | 混合 | **奶茶** · **拿铁**（A 层茶/咖啡 + 奶） |
| 5 | **加冰 + 搅打** | 保冷设施 | **奶昔** · **冰沙** |
| 6 | **加糖 + 碳酸**？ | — | （⚠️ 碳酸不做，超出前工业设定） |
| 7 | **热饮** | `pot` | **热可可** · **热茶** · **热牛奶** |

⇒ **产物 10 项**：果汁（多种）· 果酒 · 白兰地 · 奶茶 · 拿铁 · 奶昔 · 冰沙 · 热可可 · 热茶 · 热牛奶

#### 品类 10 ⭐⭐ **面食与烘焙拓展**（TFC 有 18 个基础物品）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **和面** | `mixing_bowl`（Firmalife） | 面团（6 种谷物已有） |
| 2 | **发酵** | **酵母罐**（§14.4） | 发面 |
| 3 | **成型** | **§9.2 #3 面团成型台** | 面坯 |
| 4 | **浇模** | **6 种模具**（§14.3） | **面包 · 蛋糕 · 派 · 挞 · 松饼 · 饼干 · 布朗尼** |
| 5 | **烤** | `oven`（B4 覆盖） | 成品 |
| 6 | **组装** | 案板 | **三明治** · **汉堡** · **披萨**（面团 + 番茄酱 + 奶酪） |
| 7 | **煮** | `pot` | **面条** · **饺子**？· **馒头**（蒸） |

⇒ **产物 15+ 项**：面包（6 种已有）× 模具形态 + 蛋糕 · 派 · 挞 · 松饼 · 饼干 · 布朗尼 · 披萨 · 三明治 · 汉堡 · 面条 · 馒头
⭐ **"一份面糊 × 6 种模具"** 在这里充分体现 ⇒ **同一个面团能出 6 类食物**。

#### 品类 11 ⭐ **腌渍与发酵蔬菜**（Firmalife 有 `vat`）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **盐渍** | `barrel` | 盐渍菜 |
| 2 | **乳酸发酵** | `barrel_sealed` | **酸菜** · **泡菜** |
| 3 | **醋渍** | `barrel` + 醋 | **酸黄瓜** · **腌洋葱** · **腌蒜** |
| 4 | **晒干** | 干燥架 | **萝卜干** · **干豇豆** |
| 5 | **糖渍** | `barrel` + 糖 | **蜜饯** |
| 6 | **油浸** | `jar` + 油 | **油浸蔬菜**（保质期长） |

⇒ **产物 8 项**（全部接 `FoodTrait`：`salted` / `pickled` / `vinegar` / 我们的 `sweet`）
⭐ **这是"过冬"的核心**（§12.11.1 已论证：叶菜的价值在能不能存）。

#### 品类 12 ⭐ **藻类制品**（TFC 只有干海藻）

| 序 | 工序 | 实现 | 产物 |
|---|---|---|---|
| 1 | **晒干** | 干燥架 | **海苔**（薄片） |
| 2 | **烘烤** | 烘焙石 | **烤海苔** |
| 3 | **熬煮 + 冷却** | `pot` + 冷却 | **琼脂**（凝固剂） |
| 4 | **加果汁 + 凝固** | 模具 | **果冻** · **羊羹** |
| 5 | **包饭** | 案板 | **饭团**（海苔 + 米饭） |

⇒ **产物 5 项**：海苔 · 烤海苔 · 琼脂 · 果冻 · 羊羹
⭐ **琼脂是"素食凝固剂"** ⇒ 让"果冻/软糖"不依赖动物明胶。

### 15.3 ⇒ 品类矩阵汇总

| # | 新品类 | 产物数 | 主要方块 | 主要配方类型 | TFC 空白度 |
|---|---|---|---|---|---|
| 1 | **糖与甜味剂** | 6 | 榨汁机 · 蒸发器 · 炒锅 | `juicing` `evaporating` | 🛑 **完全空白** |
| 2 | **奶制品加工** | 10 | `barrel` · `pot` · 保冷设施 | `tfc:barrel_*` `chilling` | 🛑 **完全空白** |
| 3 | **大豆制品** | 11 | `quern` · `pot` · 引子罐 · `barrel_sealed` | `starter` `tfc:barrel_sealed` | 🛑 **完全空白** |
| 4 | **蛋制品** | 8 | 案板 · 搅拌/打发 · `oven` | `in_world` `mixing_bowl` | 🛑 **完全空白** |
| 5 | **巧克力** | 10 | `oven` · `quern` · 熔化锅 · 条模 | `melting` | ✅ A 层有可可 |
| 6 | **糖艺与糖果** | 8 | `pot` · 模具 · 糖果碗 | `melting` | 🛑 **完全空白** |
| 7 | **肉制品与熟食** | 11 | 案板 · 干燥架 · 熟食板 · `pot` | `smoking` `drying` | 🟡 部分（C/D 供肉） |
| 8 | **酱料与调味汁** | 8 | `pot` · `barrel` · 引子罐 | `tfc:barrel_*` | 🟡 部分（TFC 有醋） |
| 9 | **饮品** | 10 | 榨汁机 · `pot` · 保冷设施 | `juicing` `tfc:pot` | 🟡 部分（TFC 有酒） |
| 10 | **面食与烘焙拓展** | 15+ | `mixing_bowl` · 模具 · `oven` | `firmalife:oven` `mixing_bowl` | ✅ **基础完整** |
| 11 | **腌渍与发酵蔬菜** | 8 | `barrel` · 干燥架 · `jar` | `tfc:barrel_*` `drying` | 🟡 部分（TFC 有 pickled trait） |
| 12 | **藻类制品** | 5 | 干燥架 · 烘焙石 · `pot` | `drying` `heating` | 🟡 部分（TFC 有干海藻） |
| | **合计** | **≈ 110 项产物** | **15 个方块**（§14.5） | **9 个新配方类型**（§14.6） | — |

### 15.4 🆕 三个"贯穿性"的设计（让品类之间产生联动）

| # | 设计 | 说明 | 例子 |
|---|---|---|---|
| **1** | ⭐ **糖是钥匙** | 糖（品类 1）是**糖果 / 巧克力 / 甜点 / 酱料 / 饮品**的共同前置 | 没有糖 ⇒ 后 5 个品类全都做不出来 ⇒ **糖应当是早期可达的**（甘蔗易种） |
| **2** | ⭐ **引子是活的** | **酵母罐 / 醋母罐 / 曲**（§14.4）是**跨品类**的：面包（10）· 大豆（3）· 酱料（8）· 酒（9）**都靠它** | 玩家养一罐老面 ⇒ 面包 + 酱 + 酒都能做 |
| **3** | ⭐ **酱料是倍增器** | 同一主食 + 不同酱 = 不同食物（§13.4 手法 4 的延伸） | 面包 + 番茄酱/蛋黄酱/芥末 = 3 种三明治 |

### 15.5 与 extradelight 的对照（**学结构，不抄内容**）

| 维度 | extradelight | 我们 |
|---|---|---|
| 设备 | **29 个**（含 8 模具 + 11 材质家具） | **15 个**（含 6 模具）—— 去掉其装饰/家具 |
| 配方类型 | 19 种 | **9 个新建 + 12 个复用** |
| 物品 | **1,441 个** | **≈ 110 个新产物**（聚焦，不灌水） |
| 品类 | 西式为主（派 · 蛋糕 · 芝士 · 巧克力 · 烧烤） | 🆕 **加入中式与东亚品类**（**大豆制品 · 腌渍 · 海苔 · 馒头**）⭐ |
| 协议 | 🛑 CC BY-NC-SA | ✅ **MIT**（我们自己的实现） |

⭐ **我们的差异化**：extradelight 是**西式食品为主**；
🆕 **我们加入"大豆制品（豆腐/酱油/味噌）· 腌渍发酵（酸菜/泡菜）· 海苔"这些东亚品类** ——
它们**既符合 TFC 的前工业设定**（都是古法），**又是 extradelight 没有覆盖的空白**。

⇒ 🎯 **这就是"不局限于已有内容、拓展新品类"的答案**。

---

## 十六、🍰 extradelight 的「**可放置食物方块**」体系（🆕 用户提醒补上）

> 用户口径（2026-09-29 五次）：「**别忘了 extradelight 的加工方块**」
> ⚠️ **我确实漏了整整一类** —— §14.2 只对照了 29 个"设备"，而 extradelight 还有
> **≈280 个"可放置的食物方块"**（实测），这是它"丰富食品"的**主要展示面**。

### 16.1 实测：extradelight 的食物方块（**8 类 / ≈280 个**）

| # | 类别 | 数量 | 代表 | ⭐ 学到的点 |
|---|---|---|---|---|
| **①** | **整品（派 / 蛋糕 / 甜点）** | **29** | `cheesecake` · `pumpkin_pie` · `apple_crisp` · `christmas_pudding` · `baked_alaska` · `tarte_tatin` · `pavlova` | ⭐⭐ **烤好的"整块"是可放置方块，可切分** |
| **②** | **大餐 / 炖菜（feast）** | ~100 | `beef_stew_block` · `lasagna_block` · `meatloaf_block` · `potroast_block` · `curry_block` · `stirfry_block` · `salad_block` | ⭐ 一锅菜放桌上，**多人共享** |
| **③** | **腌渍方块** | **10** | `pickled_beets` · `pickled_carrots` · `pickled_eggs` · `pickled_fish` · `pickled_ginger` · `pickled_onions` · `pickled_sausage` · `preserved_lemons` | ⭐ **腌好的菜装坛放置** |
| **④** | **挂晒串** | **7** | `hanging_chili` · `hanging_corn` · `hanging_garlic` · `hanging_onions` · `hanging_mint` · `hanging_ham` | ⭐ **风干是"挂起来"的实体** |
| **⑤** | **原料块** | **11** | `cheese_block` · `butter_block` · `salt_block` · `flour` · `cornmeal` · `breadcrumbs` · `stuffing` · `marshmallow_block` | ⭐⭐ **黄油/奶酪是"大块"，用时切** |
| **⑥** | **果冻 / 糖果** | **24** | `jelly_*_block`（**16 色**）· `candy_cane_*`（3 色）· `fudge` · `blondies` · `brownies` | ⭐ **果冻/糖也是方块** |
| **⑦** | **巧克力 / 姜饼** | **36** | `*_chocolate_box`（16 色）· `*_frosted_gingerbread_block`（16 色）· `*_fondue` | ⚠️ 大量是**颜色变体 + 装饰** ⇒ 🛑 **不学**（§2.8 已定不借鉴装饰） |
| **⑧** | **展示 / 摆盘** | **18** | `food_display`（11 材质）· `fruit_bowl` · `candy_bowl` · `charcuterie_board` · `jar_display` | 🟡 **只取"熟食板"与"糖果碗"**（§14.2 #20/#21） |

🛑 **剔除装饰后**，真正值得学的是 **①②③④⑤⑥** 六类（**≈180 个**）。

### 16.2 ⭐⭐ 核心机制：**可切分食物方块**（`CuttableFoodBlock`）

①⑤⑥ 三类共享**同一个机制**，这是 extradelight 最值得学的结构：

```
制作（烤 / 压 / 凝固）→ 产出「整块」（一个可放置方块）
                              ↓ 放置
                        右键切分 → 切成 N 份（每份是一个食物物品）
```

**现实依据**（这一步在现实里就是这么做的）：

| 场景 | 现实 | 游戏 |
|---|---|---|
| 烤好一整盘派 | 放桌上，**切一块吃** | 整派方块 → 切成 6 块派 |
| 做了一整块奶酪 | 放架上，**切着用** | 奶酪块 → 切成 8 片 |
| 打出一大块黄油 | 同上 | 黄油块 → 切成 8 份 |
| 熬好的糖/果冻 | 浇模冷却成块 | 糖块/果冻块 → 切分 |
| 一锅炖菜 | 端上桌大家吃 | **feast 方块** → 盛 N 碗 |

⇒ ⭐ **我们的 §9.2 #11「大餐方块」其实就是这个机制** —— 现在把它**推广成通类**。

**技术设计**（照 §3.3 的 `in_world` 骨架）：

| 项 | 设计 |
|---|---|
| 方块类 | **1 个 `CuttableFoodBlock`**（含 BE 存"剩余份数"） |
| 状态 | `servings`(1~8) × `facing`(可选) —— ⚠️ ⚠️ **状态数 = 8 × 4 = 32 ⇒ 超标！**（§7.2.4 要求 ≤8）<br>⇒ 🆕 **解法**：**份数存 BE 不存 blockstate**（方块只有"有/无"两态）—— 这与 §13.4-1 的"连作计数存 `SavedData`"是同一思路 |
| 交互 | 手持刀右键 ⇒ 减 1 份 + 掉落 1 份物品（走 `in_world`） |
| 放置 | 制作产出的"整块"物品 ⇒ 右键放置 |
| 共享 | 多人可各切一份（**feast 的核心体验**） |

### 16.3 🆕 我们的应用：**8 种"整块"食物**

| # | 整块 | 来源品类（§十五） | 切分份数 | 对应 extradelight |
|---|---|---|---|---|
| 1 | ⭐ **整派** | 面食烘焙（品类 10） | 6 | `*_pie`（29 个里的主力） |
| 2 | ⭐ **整蛋糕** | 面食烘焙 | 8 | `cheesecake` / `chocolate_cake` |
| 3 | ⭐ **奶酪块** | 奶制品（品类 2） | 8 | `cheese_block` |
| 4 | ⭐ **黄油块** | 奶制品 | 8 | `butter_block` |
| 5 | ⭐ **糖块** | 糖（品类 1） | 8 | `salt_block` 的同类 |
| 6 | ⭐ **果冻块** | 藻类/糖果（品类 12/6） | 6 | `jelly_*_block`（16 色 → 我们**只做原味 + 果味几种，不做 16 色**） |
| 7 | ⭐ **大餐锅** | 全部 | 4~6 | `*_block`（feast，§9.2 #11） |
| 8 | ⭐ **熟食拼盘** | 肉制品（品类 7） | 6 | `charcuterie_board` |

⇒ 🆕 **净新增方块 = 1 个类 + 8 个注册项**（⚠️ 因为**共用 `CuttableFoodBlock`**）
⇒ 或者**更省**：**8 个整块共用 1 个方块类 + 1 个 BE**，靠**物品 ID 区分**。

### 16.4 🆕 **腌渍坛 / 挂晒串**（③④ 两类的落地）

#### 腌渍坛（学 extradelight 的 `pickled_*_block`）

| 项 | 设计 |
|---|---|
| 为什么做 | ⚠️ `barrel_sealed` 产出的是**物品**（散装）；而**"一坛腌菜放在架子上"**是现实里的样子，**视觉与玩法都更好** |
| 方块 | ⭐ **腌渍坛**（`pickling_crock`）：1 个方块 + **内容物由物品决定**（不新增 8 个方块） |
| 交互 | 放入蔬菜 + 盐/醋 → 密封 → 计时 → **坛里变成腌菜** → 右键取用 |
| 与 `barrel` 的分工 | 桶 = **大批量**（工业）；坛 = **小批量 + 可放置展示**（家庭）✅ **不重复** |

#### 挂晒串（学 extradelight 的 `hanging_*`）

| 项 | 设计 |
|---|---|
| 方块 | ⭐ **挂晒串**（`hanging_dryer`）：**挂在方块下方**（顶部/侧面） |
| 可挂物 | **辣椒 · 蒜 · 洋葱 · 玉米 · 香草 · 肉条 · 鱼** |
| 状态 | ⚠️ **≤8**：用**"内容物类型"存 BE**，方块只有 `dried`(bool) 两态 |
| 产出 | 干燥后取用（**比干燥架更适合小件**） |
| 与干燥架的分工 | 干燥架 = **平铺大批量**；挂晒串 = **悬挂小件 + 装饰性** ✅ |

### 16.5 ⇒ **第五次修正后的方块总账**

| 类别 | 数量 | 明细 |
|---|---|---|
| **§9.2 原有设备** | 18 | — |
| **§十四 扩充** | 15 | 案板 · 刀具架 · 水槽 · 烘焙石 · 6 模具 · 干燥架 · 酵母罐 · 醋母罐 · 糖果碗 · 熟食板 |
| 🆕 **§十六 可放置食物** | **10** | **整派 · 整蛋糕 · 奶酪块 · 黄油块 · 糖块 · 果冻块 · 大餐锅 · 熟食拼盘 · 腌渍坛 · 挂晒串** |
| 🆕 **手持工具**（物品） | 4 | 石臼+杵 · 簸箕 · 筛 · 连枷 |
| 🆕 **动力设备** | 3~5 | 动力磨 · 动力榨油机 · 动力脱粒机 |
| **♻️ 复用** | 12+ | `quern` `loom` `pot` `barrel_*` `heating` `mixing_bowl` `stovetop_*` `barrel_press` `jarring_station` `drying_mat` `oven` `vat` |

⇒ **B 的方块总数 ≈ 43 个**（18 + 15 + 10），其中**约 30 个需要 BE**。

⚠️ **实现要点（三条，直接决定工作量）**：
1. ⭐ **8 种整块共用 `CuttableFoodBlock` + 1 个 BE**（靠物品 ID 区分）⇒ 实际方块类 **1 个**
2. ⭐ **份数/内容物存 BE，不存 blockstate**（否则状态数爆表，违反 §7.2.4）
3. ⭐ **腌渍坛与 `barrel` 分工明确**（坛=小批量展示，桶=大批量）⇒ 不是重复建设

### 16.6 ⭐ 这条体系的**真正价值**

| 维度 | 没有"可放置食物" | 有了之后 |
|---|---|---|
| **视觉** | 食物只存在于背包/物品栏 | ⭐ **厨房/餐桌/酒窖真的"有东西"** |
| **社交** | 各吃各的 | ⭐ **一锅菜/一个蛋糕，多人分食**（TFC 是慢节奏多人模组） |
| **仪式感** | 右键吃掉 | ⭐ **端上桌 → 切分 → 分食** |
| **储存展示** | 全塞箱子里 | ⭐ **奶酪架、腌菜坛、挂晒串 = 可视化的储藏** |

🛑 **一句话**：**这是"从能吃饱到像在过日子"的一步** ——
也是 extradelight 相比 TFC 原生食品系统**最有价值的增量**，我上一轮漏掉的正是它。

---

## 十七、🏠 extradelight 的「**厨房功能方块**」体系（🆕 用户第二次提醒补上）

> 用户口径（2026-09-29 六次）：「**你还是缺了其他一些加工方块，回去翻看技术文档和模组**」
> ✅ 这次翻到位了：我**把一整族"厨房家具"当装饰排除了** —— 但实测它们**全都有 BE + Menu + Screen**，
> **是真功能方块，不是装饰**。

### 17.1 实测：被我从"装饰"里误排除的功能方块

| # | 方块 | 实测类（**有 GUI 的证据**） | 真实功能 | 我上一轮的错误 |
|---|---|---|---|---|
| 1 | ⭐⭐ **`counter_cabinet`** | **`CounterCabinetBlock` + `CounterCabinetBlockEntity` + `CounterCabinetMenu` + `CounterCabinetScreen`** | **带台面的橱柜**（`facing` × `open`）—— ⭐ **储物 + 台面** | ❌ **完全没提** |
| 2 | ⭐⭐ **`half_cabinet`** | `HalfCabinetBlock`（`facing` × `open`） | **半高橱柜**（储物） | ❌ **完全没提** |
| 3 | ⭐⭐ **`sink`**（12 材质） | **`SinkCabinetBlock` + BE + `SinkCabinetMenu` + `SinkCabinetScreen`** | **水槽柜**（**清洗 + 储物**） | 🟡 当成"清洗工位"，**漏了它的储物面** |
| 4 | ⭐ **`knife_block`**（12 材质） | **`KnifeBlock` + BE + `KnifeBlockMenu` + `KnifeBlockScreen`** | **刀具架**（**有 GUI 库存**） | 🟡 提了，但没意识到它有 Menu |
| 5 | ⭐ **`spice_rack`**（12 材质） | **`SpiceRackBlock` + `SpiceRackEntity` + Menu + Screen**（+ `_full` 变体） | **香料架**（**可视化取用**） | 🟡 同上 |
| 6 | ⭐ **`food_display`**（12 材质） | **`FoodDisplayBlock` + BE + Menu + Screen** | **食品展示柜**（**展示 + 取用**） | ❌ 直接判为"装饰，不做" |
| 7 | ⭐ **`jar_display`** | `JarDisplayBlock` + `JarDisplayBlockEntity` | **罐展示架**（摆罐子） | ❌ 判为装饰 |
| 8 | ⭐ **`fruit_bowl`** | **`FruitBowlBlock` + `FruitBowlBlockEntity`** | **果盘**（放水果） | ❌ **没提** |
| 9 | **`wreath`**（多色） | `WreathBlock` + `WreathEntity` + **Menu + Screen** | ⚠️ **花环有 GUI**（可插花） | ❌ 判为装饰 |
| 10 | **`picnic_basket`**（16 色） | **`PicnicBasketBlockEntity`** | **野餐篮**（**可放置的储物**） | ❌ 判为装饰 |
| 11 | **`chocolate_box`**（16 色） | **`ChocolateBoxBlockEntity`** | **巧克力盒**（储物） | ❌ 判为装饰 |
| 12 | ⭐⭐ **`fondue`**（4 种） | **`RecipeFondueFeastBlock`** | **巧克力火锅**（⭐ **是 feast 类**，可蘸食） | ❌ **完全没提** |

⇒ 🎯 **12 个真功能方块被我误判为装饰** —— 因为它们名字像家具，但**都有 BE/Menu/Screen**。

### 17.2 ⭐⭐ 其中最重要的是「**橱柜台面体系**」（`counter_cabinet` + `half_cabinet`）

**实测证据**（blockstate 结构）：
```jsonc
// oak_counter_cabinet.json —— 引用的是 farmersdelight 的模型！
{"variants":{
  "facing=east,open=false": {"model":"farmersdelight:block/oak_cabinet","y":90},
  "facing=east,open=true":  {"model":"farmersdelight:block/oak_cabinet_open","y":90}, …}}
```

| 项 | 含义 |
|---|---|
| **来源** | ⭐ **来自 Farmer's Delight 的"橱柜"概念**（extradelight 依赖它） |
| 状态 | `facing`(4) × `open`(2) = **8 个状态** ✅ **正好在 §7.2.4 的 ≤8 红线内** |
| 功能 | **下半 = 储物柜**（有 Menu/Screen）· **上半 = 台面**（可放物品/当工作台面） |
| 材质 | **12 种**（11 木材 + `fruit` 果木） |

⭐ **为什么这对我们特别重要**：
- **TFC 有 `food_shelf` / `barrel_rack`**（Firmalife）⇒ 但**没有"厨房橱柜 + 台面"**
- **我们的 15 个加工方块（§14.5）全都需要"放的地方"** —— 案板、模具、搅拌碗……
- ⇒ ⭐ **橱柜台面就是"厨房的骨架"**：把加工设备摆在台面上、把原料放进柜子里

### 17.3 🆕 我们的设计：**厨房家具家族**（7 个方块）

| # | 方块 | 承载 | 状态设计（⚠️ ≤8） | 材质 |
|---|---|---|---|---|
| **1** | ⭐⭐ **橱柜台面**（`counter`） | **下储上作**：柜内存物 + 台面可放/操作 | `facing`(4) × `open`(2) = **8** ✅ | **按 TFC 的 20 树种？** ⇒ ⚠️ 建议 **6 种**（主流木材，控制美术量） |
| **2** | ⭐ **半高柜**（`half_cabinet`） | 纯储物（省空间、可叠） | `facing`(4) × `open`(2) = **8** ✅ | 同上 6 种 |
| **3** | ⭐ **水槽柜**（`sink`） | **清洗 + 储物**（接 §14.2 #23） | `facing`(4) = **4** ✅ | 同上 6 种 |
| **4** | ⭐ **刀具架**（`knife_block`） | 放刀具（可视化取用） | `facing`(4) = **4** ✅ | 1 种（通用） |
| **5** | ⭐ **香料架**（`spice_rack`） | 放调料（§9.2 **#5** 已规划，此处**补 full/空 两态**） | `facing`(4) × `full`(2) = **8** ✅ | 1 种 |
| **6** | ⭐ **食品展示柜**（`food_display`） | **展示 + 保鲜**（接 §5.6 的保鲜容器） | `facing`(4) × `open`(2) = **8** ✅ | 6 种 |
| **7** | ⭐ **果盘 / 糖果碗**（`fruit_bowl`） | 小件展示（桌上摆盘） | **无朝向**（1 态）✅ | 1 种 |

⚠️ **材质数量 —— 🛑 已按用户口径推翻我的旧建议：必须覆盖「全部木材与石材」**

> 用户口径（2026-09-29 八次）：「**需要注意添加的家具要对应 tfc（以及附属模组）的全部木材和石材种类**」

#### 实测：材质清单（**不许只做几种**）

| 类别 | 数量 | 清单 |
|---|---|---|
| **TFC 木材** | **20** | `acacia` · `ash` · `aspen` · `birch` · `blackwood` · `chestnut` · `douglas_fir` · `hickory` · `kapok` · `mangrove` · `maple` · `oak` · `palm` · `pine` · `rosewood` · `sequoia` · `spruce` · `sycamore` · `white_cedar` · `willow` |
| 🆕 **afc 追加木材** | **14** | `araucaria` · `baobab` · `beech` · `cypress` · `eucalyptus` · `fig` · `ginkgo` · `hevea` · `ipe` · `ironwood` · `mahoe` · `mahogany` · `teak` · `tualang` |
| **木材合计** | **34** | ⚠️ 实际可运行的整合包里 = TFC 20 + afc 14 |
| **TFC 岩石** | **21** | `andesite` · `basalt` · `chalk` · `chert` · `claystone` · `conglomerate` · `dacite` · `diorite` · `dolomite` · `gabbro` · `gneiss` · `granite` · `limestone` · `marble` · `phyllite` · `quartzite` · `rhyolite` · `schist` · `shale` · `slate` · `tuff` |
| **岩石形态** | **19** | `raw` · `cobble` · `mossy_cobble` · `bricks` · `mossy_bricks` · `cracked_bricks` · `chiseled` · `smooth` · `hardened` · `loose` · `mossy_loose` · `gravel` · `magma` · `spike` · `anvil` · `aqueduct` · `rope_anchor` · `button` · `pressure_plate` |

#### 为什么必须全做（三条理由）

| # | 理由 |
|---|---|
| **1** | ⭐ **这是 TFC 的既定惯例**：实测 **TFC 有 41 类木制方块，全部是"20 树种"**（`axle` · `barrel` · `bookshelf` · `chest` · `crate` · `door` · `loom` · `shelf` · `tool_rack` · `workbench`…）⇒ **41 × 20 = 820 个 blockstate** |
| **2** | ⭐ **Firmalife 也是全树种**：实测它有 **8 类全树种家具**（`barrel_press` · `food_shelf` · `hanger` · `jarbnet` · `keg` · `keg_sub` · `stomping_barrel` · `wine_shelf`）⇒ **8 × 20 = 160 个 blockstate** |
| **3** | 🛑 **一致性**：如果我们的橱柜只有 6 种木材，玩家会看到"**20 种木板，6 种橱柜**" —— 这在 TFC 的体系里是**明显缺陷**（TFC 玩家会按木材搭配建筑） |

#### ⭐ 关键：**全树种 ≠ 全贴图**（成本远低于想象）

**实测证据**：
| 观察 | 数据 |
|---|---|
| Firmalife 的 `keg` **专属贴图数** | **0 张** ⇒ **它复用 TFC 的木材贴图** |
| Firmalife 的**全部**木材贴图 | 仅 **242 张**（而它的全树种方块有 160 个 + 其它） |

⇒ 🎯 **结论**：**木制家具的贴图 = "形状模型"用一套 + 木材部分复用 TFC 的 `tfc:block/wood/planks/<wood>` 等**。
⇒ ⭐ **所以"7 类家具 × 34 树种 = 238 方块"的真实美术成本是**：
- **自带形状贴图**：**7 类 × 2~4 张 ≈ 20~30 张**（金属件 · 玻璃 · 细节）
- **木材贴图**：**0 张**（复用 TFC / afc 的）
- ⚠️ **但模型文件是 238 个**（每个树种一个 json，可通过**生成器批量产出**）

#### 🆕 修正后的**材质方案**

| 类别 | 覆盖 | 说明 |
|---|---|---|
| **木制家具**（橱柜台面 · 半高柜 · 水槽柜 · 刀具架 · 香料架 · 展示柜 · 果盘） | ⭐ **全部 34 树种** | 7 类 × 34 = **238 方块** |
| **石制家具**（可选：**研磨台 · 石灶 · 石槽 · 石案板**） | ⭐ **全部 21 岩石** | 🆕 见下 |
| **金属设备**（熔化锅 · 蒸发器 · 榨油机 · 炒锅…） | 按**金属 tier**（TFC 的铜/青铜/锻铁/钢…） | ⚠️ 不是按材质种类 |

🆕 **石材家具的补充建议**（用户点名"石材"）：
| 家具 | 现实对应 | 岩石变体 |
|---|---|---|
| **石案板**（切菜/研磨用） | 石台面 | ⭐ **21 岩石** |
| **石磨台**（放研钵/石臼） | 石臼座 | ⭐ **21 岩石** |
| **石水槽**（清洗） | 石槽 | ⭐ **21 岩石** |
| **石灶**（架锅） | 石灶 | ⭐ **21 岩石** |

⚠️ **TFC 已有可复用的石材块**：`rock/<form>/<rock>` 的 **19 种形态**里已有 `bricks` · `chiseled` · `smooth` · `slab` · `stairs` · `wall` ⇒
🆕 **石制家具可参考它们的贴图组织方式**（同样复用 `tfc:block/rock/...` 的贴图）。

#### ⚠️ 规模重算（**这是本方案最大的一次数字变化**）

| 项 | 原（只做 6 木材） | 🆕 **修正后（全材质）** |
|---|---|---|
| 木制家具方块 | 6 × 7 = **42** | **34 × 7 = 238** |
| 石制家具方块 | 0 | **21 × 4 = 84**（🆕 可选） |
| 家具合计 | 42 | **238 ~ 322** |
| 家具**自有贴图** | ~126（我算错了） | ⭐ **20~30 张**（复用木材贴图） |
| 家具**模型文件** | 42 | 238~322（**生成器批量产出**） |

⇒ 🛑 **结论：方块数量大幅上升（+200~280），但贴图成本反而下降** ——
**这是本次修正最有价值的一点**：**全材质不是"美术灾难"，因为木材贴图可以复用**。

### 17.4 🆕 另外三个值得补的（§17.1 里的 9~12）

| # | 方块 | 设计 | 优先级 |
|---|---|---|---|
| **1** | ⭐ **巧克力火锅**（`fondue`） | **`RecipeFondueFeastBlock` 的思路**：火锅 = **feast 方块**，可**反复蘸食**（不消耗锅本身） | **P2**（趣味向，但很出彩） |
| **2** | ⭐ **野餐篮**（`picnic_basket`） | **可放置的便携储物**（提着走 → 放下当箱子） | **P2** |
| **3** | **巧克力盒**（`chocolate_box`） | 16 色储物盒 —— ⚠️ **颜色变体是装饰向** ⇒ 🛑 **不做 16 色**，**只做 1 种**（送礼/装巧克力） | **P3** |

🛑 **不做的**（明确划掉）：**`wreath`（花环）** —— 纯装饰用途，与食品加工无关。

### 17.5 ⇒ **第六次修正后的方块总账**

| 类别 | 数量 | 明细 |
|---|---|---|
| **§9.2 原有设备** | 18 | — |
| **§十四 加工扩充** | 15 | 案板 · 刀具架 · 水槽 · 烘焙石 · 6 模具 · 干燥架 · 酵母罐 · 醋母罐 · 糖果碗 · 熟食板 |
| **§十六 可放置食物** | 10 | 整派 · 整蛋糕 · 奶酪块 · 黄油块 · 糖块 · 果冻块 · 大餐锅 · 熟食拼盘 · 腌渍坛 · 挂晒串 |
| 🆕 **§十七 厨房家具** | **7** | **橱柜台面 · 半高柜 · 水槽柜 · 刀具架 · 香料架 · 食品展示柜 · 果盘** |
| 🆕 **§十七 补充** | 3 | **巧克力火锅 · 野餐篮 · 巧克力盒**（P2/P3） |
| 🆕 **手持工具**（物品） | 4 | 石臼+杵 · 簸箕 · 筛 · 连枷 |
| 🆕 **动力设备** | 3~5 | 动力磨 · 动力榨油机 · 动力脱粒机 |
| **♻️ 复用** | 12+ | `quern` `loom` `pot` `barrel_*` `heating` `mixing_bowl` `stovetop_*` `barrel_press` `jarring_station` `drying_mat` `oven` `vat` |

⇒ 🛑 **但必须区分「方块类」与「注册项」——这是本方案最容易误算的一处**：

| 口径 | 数量 | 说明 |
|---|---|---|
| **方块类**（Java class） | **≈ 18~20 个** | 6 模具共用 1 类（§16.5）· 8 整块共用 1 类（`CuttableFoodBlock`，§16.2）· 7 厨房家具共用 1~2 类（`KitchenFurnitureBlock` + 通用容器 BE） |
| **单例方块注册项** | **53 个** | 18 设备 + 15 加工 + 10 食物 + 7 家具 + 3 补充（**各 1 个**） |
| 🆕 **全材质展开后的注册项** | **≈ 375+ 个** | ⚠️ **7 类木制家具 × 34 树种 = 238** · 🆕 4 类石制家具 × 21 岩石 = **84** · 加上单例 53 ⇒ **≈ 375** |
| **blockstate / 模型文件** | **≈ 375** | 每个注册项 1 个 blockstate（**生成器批量产出**） |
| ⭐ **自有贴图** | **≈ 130~160 张** | ⚠️ **木材/石材部分复用 TFC 与 afc 的贴图**（§17.3 实测依据） |

⇒ ⭐ **一句话**：**注册项从 53 涨到 ≈375，但"方块类"仍是 ≈20 个、"自有贴图"只增 20~30 张** ——
**这就是"全材质"可行的原因**（Firmalife 的 `keg` 专属贴图是 **0 张**，全靠复用）。

### 17.6 📌 这次遗漏的教训（写下来防再犯）

| 观察 | 教训 |
|---|---|
| 我按"名字像不像装饰"筛，把 `counter_cabinet` / `half_cabinet` / `sink` / `food_display` / `picnic_basket` / `wreath` / `chocolate_box` **全划掉了** | 🛑 **判断"是不是功能方块"要看它有没有 `BlockEntity` / `Menu` / `Screen`，不是看名字** |
| 我在 §14.2 用"11 材质"当"这是装饰"的理由 | 🛑 **错**：**材质多恰恰说明它是"基础家具"**（像 TFC 的 20 树种传动轴） |
| 我漏了 `fondue`（4 种，是 feast 类） | 🛑 **要看配方类型**：`RecipeFondueFeastBlock` 明确说它是**可食用方块** |

⇒ 🆕 **方法修正**：**排查一个模组的方块时，先提取"有 BE/Menu/Screen 的类"，再回推方块清单** ——
这比按名字筛选**可靠得多**（本次就是这么找到的）。

---

## 十八、⭐ 「**食品模组 × TFC**」的现成范例：`extradelighttfc`（🆕 用户指示翻 1.20.1 版）

> 用户口径（2026-09-29 七次）：「**extradelight 还有其他内容被你忽视，翻看 1.20.1 版本**」
> ✅ 翻到了**两个关键东西**：
> ① **`extradelight-1.1.5-all`（1.20.1）** —— 配方类型 **26 种**，比 1.21.1 版的 19 种**多 5 种**
> ② ⭐⭐ **`extradelighttfc-0.5.0-beta`（0.11 MB）** —— **一个专门做「extradelight × TFC」整合的模组**，
> **它就是我们 B 层要干的事情的现成范例**。

### 18.1 ⭐⭐ `extradelighttfc` 实测（122 条目，全清单已读）

| 项 | 实测 |
|---|---|
| 协议 | 🛑 **`Attribution-NonCommercial-ShareAlike 4.0`**（同 CC BY-NC-SA）⇒ **同样只可借鉴玩法** |
| 定位 | **Compat layer**（兼容层）—— 把 extradelight 的食物/流体**接进 TFC 的体系** |
| 独有 modId | `extradelighttfc` |

**它做的五件事**（⭐ 每一件都是我们 B 层要做的）：

#### 手法 1 ⭐⭐⭐ **动态食物适配器**（`DynamicFoodCalculator`）

```
adapter/dynamic/DynamicFoodAdapter
adapter/dynamic/DynamicFoodCalculator$ProcessedFood
adapter/dynamic/DynamicFoodContext$Phase
adapter/dynamic/FoodModifierRegistry$FoodModifier
adapter/dynamic/workstation/MixingDynamicFoodAdapter     ← 搅拌碗的食物计算
adapter/dynamic/workstation/OvenDynamicFoodAdapter        ← 烤箱的食物计算
```

⇒ 🎯 **它把 extradelight 的食物"翻译"成 TFC 的营养体系**（TFC 的食物是**动态**的：营养按成分算）。
⇒ 🆕 **对我们的启示**：**§十五 的 ≈110 项新食物，每一项都要"接进 TFC 营养"** ——
这正是 §10.2 A3 要解决的问题，而**他们已经趟过一遍**。
⚠️ **但注意**：他们的做法是**运行时计算**（adapter + calculator），
而我们的 A3 方案是**静态数据 + `FoodTrait`**（§10.2）⇒ ⭐ **我们的更简单**（不需要运行时适配器）。

#### 手法 2 ⭐⭐ **`data/<mod>/tfc/food_items/*.json`（15 个）** —— 注册 TFC 食物数据

`bbq_sauce` · `breadcrumbs` · `butter` · `extradelight_dynamic_food` · **`feast_items`** · **`feasts`** ·
`grated_carrot/garlic/potato` · `potato_sticks` · `sliced_apple/onion/potato/tomato`

⇒ 🆕 **这是"外来食物接入 TFC"的标准做法** ⇒ **§十五 的 110 项全都需要这个文件**。
⭐ **`feasts`（大餐）/ `feast_items`（大餐切分后的份）分两个文件** —— **这个区分很重要**（§16.2 的可切分方块）。

#### 手法 3 ⭐ **`data/<mod>/tfc/drinkables/*.json`（4 个）** —— 注册 TFC 饮料

`bbq_sauce` · `lemon` · `orange` · `tomato`
⇒ 🆕 **连"酱汁"都能注册成 TFC 的 `drinkable`**（可喝！）⇒ 与 §5.6 的 `tfc:drinkable` 对应。

#### 手法 4 ⭐⭐ **mixin 改 TFC 的设备**（11 个）

| mixin | 目标 | 意图 |
|---|---|---|
| **`BarrelBlockEntityMixin`** | ⭐ **TFC 的桶** | 让桶能处理新食材 |
| `EDMixingBowlBlockEntityMixin` | extradelight 的搅拌碗 | 让它认 TFC 的流体 |
| `EDOvenBlockEntityMixin` | extradelight 的烤箱 | 同上 |
| `JuicerBlockMixin` | extradelight 的榨汁机 | 同上 |
| **`RecipeFeastMixin`** | ⭐ **feast 方块** | 让大餐用 TFC 的营养 |
| `RecipeManager_FDFilterMixin` | **配方管理器** | 过滤外来配方 |
| `SDTempFoodContainerMixin` | 温度食物容器 | — |
| `fancy_tank/*`（3 个） | 流体槽 | 接 TFC 流体 |

⇒ ⭐ **关键启示**：**他们 mixin 了 TFC 的 `BarrelBlockEntity`** ——
这与我们 §10.2 **A3 的"地窖延长保质期"**（也要 mixin 腐坏推进）是**同一类操作**。
⇒ 🆕 **可以借鉴它的注入点选择**（但代码不能抄）。

#### 手法 5 ⭐⭐⭐ **用 TFC 的砧（`anvil`）打造模具**

```
data/extradelighttfc/recipes/anvil/baking_tray.json
data/extradelighttfc/recipes/anvil/loaf_pan.json
data/extradelighttfc/recipes/anvil/pie_dish.json
data/extradelighttfc/recipes/anvil/sheet.json
data/extradelighttfc/recipes/anvil/square_pan.json
```

⇒ 🎯 **模具不是工作台合成的，是"打"出来的**（用 TFC 的砧 + 锤）。
⇒ 🆕 **对我们的启示**：**§14.3 的 6 个模具应当走 TFC 的 `anvil` 配方** ⭐
**理由**：① 完全符合 TFC 的设定（金属器具要打）② 零新配方类型 ③ 让"打铁"与"做饭"产生联系。

**它还有的配方**：
| 目录 | 条数 | 内容 |
|---|---|---|
| `recipes/cutting/*` | **8** | **用砧板切 TFC 食材**（面包糠 · 擦胡萝卜/蒜/土豆丝 · 苹果/洋葱/土豆/番茄片） |
| `recipes/juicer/*` | 8 | 榨汁（发光浆果 · 柠檬 · 西瓜 · 橙 · 番茄） |
| `recipes/cooking/*` | 4 | **用 TFC/FD 的锅做菜**（烧烤糖 · 炒肝 · 肝配洋葱 · 牛尾汤） |
| `recipes/mixing/*` | 3 | 搅拌（**黄油** · 手撕猪肉 · **打发奶油**） |
| `recipes/oven/*` | 9 | 烤箱做大餐 |

### 18.2 ⭐ 1.20.1 独有的配方类型（**1.21.1 版没有的**）

| 配方类型 | 1.20.1 条数 | 1.21.1 有？ | 🆕 对我们的价值 |
|---|---|---|---|
| ⭐⭐ **`bottle_fluid`** | **37** | ❌ **没有** | ⭐ **把流体装进瓶子** —— 正是 §6.1.2「果汁装瓶」需要的类型 |
| ⭐ **`dynamic_jam`** | **12** | ❌ **没有** | 动态果酱（按原料算） |
| ⭐ **`flour_dough`** | 1 | ❌ **没有** | **面粉 + 水 → 面团**（TFC 有 `food/*_dough` 但**没有通用转换**） |
| `chiller` | **74**（1.21.1 只 12） | ✅ | 冷藏配方**多 6 倍** ⇒ 说明这是**重要品类** |
| `dough_shaping` | **37**（1.21.1 只 21） | ✅ | 面团成型 |
| `farmersdelight:cooking` | **132** | ❌（1.21.1 用自家锅） | 借 FD 的锅 |

⇒ 🆕 **三个要补进 §14.6 配方类型的**：**`bottle_fluid` · `dynamic_jam` · `flour_dough`**。
⇒ ⭐ **`bottle_fluid` 尤其重要** —— 它让"果汁/酱汁/油"能**装瓶**（可携带 · 可保存 · 可交易）。

### 18.3 ⇒ **对我们的 6 条直接启示**（已并入本文档）

| # | 启示 | 落到哪一节 |
|---|---|---|
| **1** | ⭐ **模具走 TFC `anvil` 打造**（不是工作台合成） | §14.3 的 6 个模具 |
| **2** | ⭐ **每项新食物要注册 `tfc/food_items/*.json`**；**大餐与"份"分两个文件** | §15.3 的 ≈110 项 |
| **3** | ⭐ **酱汁也能注册成 `tfc:drinkable`**（可喝） | §15.2 品类 8 |
| **4** | 🆕 补 `bottle_fluid`（装瓶）· `dynamic_jam` · `flour_dough` 三个配方类型 | §14.6 |
| **5** | ⭐ **已有第三方 mixin 过 TFC `BarrelBlockEntity`** ⇒ 我们的 A3 注入点可参考它的选择 | §10.2 A3 |
| **6** | ⚠️ **不要学它的"运行时动态食物适配器"** —— 我们用**静态 `FoodTrait`**（§10.2 A3）**更简单** | §10.2 A3 |

### 18.4 🛑 协议提醒（第三次）

| 模组 | 协议 | 可借鉴程度 |
|---|---|---|
| `extradelight` | 🛑 **CC BY-NC-SA 4.0** | **只借鉴玩法** |
| **`extradelighttfc`** | 🛑 **CC BY-NC-SA 4.0**（`Attribution-NonCommercial-ShareAlike`） | **只借鉴玩法** |
| `FarmersDelight` | ⚠️ 需核实（MIT？） | 待查 |
| `FarmersDelightTFC` | ⚠️ 需核实 | 待查 |

⇒ 🆕 **建议把 `extradelighttfc` 也加进主方案 §2.8 的协议红线表**。

### 18.5 📌 这次遗漏的教训（第二次同类）

| 观察 | 教训 |
|---|---|
| 我只看了 **1.21.1 版**（10.45 MB），漏了 **1.20.1 版**（9.93 MB） | 🛑 **同一模组的不同 MC 版本，内容可能不同**（1.20.1 多 3 个配方类型） |
| 我完全没注意 `extradelighttfc`（**0.11 MB 的小模组**） | 🛑 **"兼容层"小模组往往信息密度最高** —— 它专门解决"如何与邻居结合"，而这正是我们的核心问题 |
| 我一直自己设计"怎么与 TFC 结合" | 🛑 **先查有没有人做过** —— 第三方已经趟过一遍，**借鉴它的方案比自创可靠** |

⇒ 🆕 **方法修正（第二条）**：
> **分析一个模组时，要同时看**：① **它的所有 MC 版本** ② **它的兼容/附属模组** ③ **它的 `data/<mod>/tfc/**`（如果有）**。

---

## 十九、⚖️ 协议合规专章（🆕 用户口径：「**强调证书要求防止代码和资源的过度挪用**」）

> 用户口径（2026-09-29 九次）：「**整理计划，并且强调证书要求防止代码和资源的过度挪用**」
>
> 🛑 **本章是法律级约束，优先级仅次于主方案 §用户口径**。
> **所有结论来自实测**（读每个 jar 的 `META-INF/mods.toml` 的 `license` 字段或 `LICENSE` 文件）。

### 19.1 ⭐ 完整协议总表（**我们接触到的每一个模组**）

#### 🛑 第一级：**只可借鉴玩法**（不得复制任何代码 / 资源 / 数据）

| 模组 | 实测协议 | 我们与它的关系 | 约束 |
|---|---|---|---|
| **extradelight**（Extra Delight） | 🛑 **`CC BY-NC-SA 4.0`** | **主要灵感来源** | 学**设备清单 · 工序划分 · 配方结构思路**；🛑 **不抄 JSON / 贴图 / 代码** |
| **extradelighttfc** | 🛑 **`Attribution-NonCommercial-ShareAlike 4.0`** | **整合范例** | 学**方案思路**；🛑 不抄 |
| **extradelight unofficial port** | 🛑 同 CC BY-NC-SA 4.0 | — | 同上 |
| **DragN 系列**（livestock / pets / permafrost / compat） | 🛑 **`All Rights Reserved, DragN0007`** | C/D 的灵感 | 🛑 **只借鉴玩法**（主方案 §2.8 已定） |
| **Aquaculture 2** | 🛑 **`All Rights Reserved`** | C 的灵感 | 🛑 只借鉴玩法 |
| **Cuisine TFC** | 🛑 **`All Rights Reserved`** | 食品参考 | 🛑 只借鉴玩法 |
| **FirmalifeEnhance** | 🛑 **`All Rights Reserved`** | — | 🛑 只借鉴玩法 |
| **Untamed Wilds** | 🛑 **`GNU General Public License`** | C 的生态灵感 | 🛑⚠️ **GPL 有传染性** ⇒ **代码与资源一律不得拷贝** |
| **Survivor's Delight** | 🛑 **`GNU GPL v3`** | 食品参考 | 🛑 同上（GPL 传染） |
| **Survivor's Butchery** | 🛑 **`CC-BY-NC-SA 4.0`** | C 的灵感 | 🛑 只借鉴玩法 |

#### ⚠️ 第二级：**需要谨慎**（有 copyleft 或非商业条款）

| 模组 | 实测协议 | ⚠️ 风险点 | 我们的应对 |
|---|---|---|---|
| ⭐ **TerraFirmaCraft** | ⚠️ **`EUPL-1.2`** | 🆕 **不是 MIT！** EUPL 是**弱 copyleft**：**衍生作品必须以 EUPL 发布** | 🛑 **见 §19.2 风险 1** |
| ⭐ **Patchouli** | ⚠️ **`CC BY-NC-SA 3.0`** | 🆕 **含"非商业"条款** | 🛑 **见 §19.2 风险 2** |
| **Farmer's Delight TFC** | ⚠️ **`Academic Free License v3.0`** | 需署名 + 专利条款 | 🟡 只参考配方思路 |
| **Cuisine Delight** | ⚠️ `LGPL-2.1` | 弱 copyleft | 🟡 不链接其代码 |
| **Jade** | ⚠️ `CC BY-NC-SA 4.0` | 非商业 | 🟡 仅运行时装了它 |
| **Create** | ✅ `MIT` | — | ✅ 但**我们不做 Create 联动** |
| **ModernFix / FerriteCore / KubeJS** | ⚠️ LGPL-3.0 | 弱 copyleft | 🟡 **运行时环境**，不链接 |

#### ✅ 第三级：**宽松**（MIT / 同类）

| 模组 | 实测协议 | 我们与它的关系 |
|---|---|---|
| **Firmalife** | ✅ **`MIT`** | ⭐ **主要邻居**（覆盖它的资源 + 复用它的设备） |
| **FirmaLife HardCore** | ✅ **`MIT`** | ⭐ **条件让位组的对手方**（§3.5） |
| **afc**（ArborFirmaCraft） | ✅ **`MIT`** | ⭐ 木材来源（14 树种） |
| **TFC Woodworking** | ✅ **`MIT`** | ⭐ `in_world` 的反编译对象（§7.2） |
| **Farmer's Delight** | ✅ **`MIT License`** | 参考 |
| **Crabber's Delight / TFC** | ✅ **`MIT`** | 参考 |
| **Fowl Play** | ✅ **`MIT`** | 参考 |
| **Butchercraft** | ✅ **`MIT`** | C/D 参考 |
| **Firma: Civilization / FirmaCiv+** | ✅ **`MIT`** | 参考 |
| **TFC Farming Plus**（= **我们的 A 层**） | ✅ **`MIT`** | 我们自己的 |
| **B 层 `tfcagricultureplus`** | ✅ **`MIT`**（**应当与 A 一致**） | 我们自己的 |

### 19.2 🆕 **三个我之前漏掉的风险**（本次实测发现）

#### 风险 1 ⭐⭐ **TFC 是 `EUPL-1.2`，不是 MIT**

| 项 | 内容 |
|---|---|
| **实测** | `TerraFirmaCraft` → **`license="EUPL-1.2"`** |
| **EUPL 的性质** | **欧洲公共许可证**，属**弱 copyleft**（类似 LGPL）：<br>① 允许**链接/调用**（我们的模组调 TFC 的 API）✅<br>② **衍生作品必须以 EUPL 发布** ⚠️<br>③ 允许商业使用 ✅ |
| **对我们的影响** | 🛑 **我们做了三件"贴近 TFC"的事**：<br>① **覆盖 TFC 的资源**（256 个文件级覆盖，主方案 §5.5）<br>② **mixin TFC 的类**（§12.6.2）<br>③ **复用 TFC 的方块类**（A 层已做） |
| **实务判断**（⚠️ **非法律意见**） | ① **覆盖资源** = 我们提供**同名文件**在**更高优先级的数据包**里 ⇒ 这是**Minecraft 资源包的正常机制**，**不是修改 TFC 的 jar** ⇒ 通常**不构成衍生**<br>② **mixin** = **运行时注入**，不改 TFC 源码 ⇒ 实务上**普遍认为不构成衍生**（但**无判例**）<br>③ **调用 API** = EUPL 明确允许 ✅ |
| 🆕 **我们的应对** | ① **不修改 TFC 的 jar**（我们本来就没做）<br>② **mixin 只注入、不复制 TFC 的代码**（写自己的逻辑）<br>③ **在 B 的 README / 手册里注明**"基于 TerraFirmaCraft（EUPL-1.2）开发"<br>④ ⚠️ **若未来要"改 TFC 的源码"，必须先评估 EUPL 传染** |

#### 风险 2 ⭐ **Patchouli 是 `CC BY-NC-SA 3.0`**（含非商业条款）

| 项 | 内容 |
|---|---|
| **实测** | `Patchouli` → **`license="CC BY-NC-SA 3.0"`** |
| **我们的用法** | A 层已用 Patchouli 做**游戏内手册**（`verify-book.ps1` 校验的 784 页） |
| ⚠️ **风险** | **CC BY-NC-SA 有"非商业"限制** ⇒ ⚠️ 如果我们的整合包/模组**用于商业**（如付费服务器），**手册部分可能受限** |
| 🆕 **我们的应对** | ① **Patchouli 是"运行时依赖"**（玩家自己装）⇒ **我们不分发它**<br>② **我们写的是"手册内容"（JSON），不是 Patchouli 的代码**<br>③ ⚠️ **建议**：在分发说明里注明"**本模组的手册依赖 Patchouli（CC BY-NC-SA 3.0）**" |

#### 风险 3 **`All Rights Reserved` 的食品模组不止 extradelight**

| 模组 | 协议 | 我之前的处理 |
|---|---|---|
| **Cuisine TFC** | 🛑 ARR | ❌ **我从未提及它的协议** |
| **FirmalifeEnhance** | 🛑 ARR | ❌ 同上 |
| **Farmer's DragN** | 🛑 ARR | ✅ 已在主方案 §2.8 |

⇒ 🆕 **已补进 §19.1 与主方案 §2.8**。

### 19.3 🛑 **"过度挪用"的可操作判据**（**这一节是最重要的**）

> 用户口径：「**防止代码和资源的过度挪用**」
> ⇒ 下面是**可逐条检查**的判据，**违反任一条即返工**。

#### ✅ **可以做的**（借鉴的正当范围）

| # | 允许 | 例子 |
|---|---|---|
| 1 | **学"做什么"**（功能 · 工序 · 玩法） | "extradelight 有榨汁机，我们也做一个榨汁环节" |
| 2 | **学"为什么这么做"**（设计理由） | "它用 trait 标记'已熏制'，我们也用 trait" |
| 3 | **学"结构/清单"**（有哪些设备 · 有哪些标签） | §14.2 的 29 设备对照表 |
| 4 | **学"数据组织方式"**（schema 形状） | "`{ingredient, result}` 两字段的极简配方" |
| 5 | **调用公开 API** | 用 TFC 的 `SinkNode` · `FoodTraits.TRAITS` |
| 6 | **复用协议宽松模组的类** | `new MyDecayingBlock(...)`（A 层已在做） |

#### 🛑 **不可以做的**（过度挪用）

| # | 禁止 | 判据（**怎么查**） |
|---|---|---|
| **1** | 🛑 **复制贴图 / 模型 / 音频文件** | 逐文件比对**哈希**：我们的资源里**不得有**任何来自受限模组的文件 |
| **2** | 🛑 **复制 JSON 配方 / 标签 / 数据** | 比对**文件名 + 内容结构**：配方可以**相似**（都是"面粉+水=面团"），但**不得逐字相同** |
| **3** | 🛑 **复制 Java 代码** | ① **不得反编译后粘贴** ② **不得照抄类名/方法名/变量名序列** ③ **不得复制注释** |
| **4** | 🛑 **模仿到"可识别"的程度** | ⚠️ **判据**：如果**把两个模组并排放**，玩家能说"这是抄的" ⇒ **过度** |
| **5** | 🛑 **使用受限模组的命名空间 ID** | 我们的 ID 一律 `tfcagricultureplus:*`，**不得出现** `extradelight:*` 等 |
| **6** | 🛑 **把受限模组列为依赖** | B 的 `mods.toml` 依赖**只能是 MIT/宽松**的（A · TFC · Firmalife · afc） |

#### ⚠️ **灰色地带（必须逐案判断）**

| 情形 | 判断 |
|---|---|
| **"照着做一遍"（clean-room）** | ✅ **允许** —— 只要**不看它的代码/资源**，只**基于功能描述**自己实现 |
| **反编译后"理解机制"再自己写** | 🟡 **有条件允许** —— 用于**理解 API / 行为**（如 §7.2 反编译 woodwork 的 MIT 代码）；<br>🛑 **若来源是 CC BY-NC-SA / ARR，则只看"它做了什么"，不看"它怎么写的"** |
| **两个模组都实现了同一个现实工序**（如"磨面粉"） | ✅ **允许** —— **现实工序不受版权保护**（TFC 有 `quern`，我们也可以有磨） |
| **贴图风格相似**（都是像素风） | ✅ **允许** —— **风格不受版权保护**；但 🛑 **不得逐像素相同** |

### 19.4 🆕 我们的**执行策略**（三条）

| # | 策略 | 做法 |
|---|---|---|
| **1** | ⭐ **写代码前先查协议** | 新增"参考某模组"时，**先跑一遍 §19.1 的表**；不在表里的**当场查** |
| **2** | ⭐ **来源标注** | 每个**借鉴来的设计**，在代码注释与文档里写清**来源 + 只借鉴了什么**<br>例：`// 设计参考 extradelight 的 drying_rack（CC BY-NC-SA，仅借鉴玩法，未复制任何代码/数据）` |
| **3** | 🛑 **门禁脚本** | 在 `check-boundaries.ps1`（§1.7）里加一段：<br>① 扫我们的资源，**不得出现受限模组的命名空间**（`extradelight` / `dragn` / `aquaculture` / `cuisine` / `untamedwilds` / `survivorsdelight`）<br>② 扫 `mods.toml` 的依赖，**不得依赖受限模组**<br>③ 扫 Java 注释，**每个"参考"都要带协议标注** |

```powershell
# 🆕 §19.4 门禁：协议合规检查（加进 check-boundaries.ps1）
$restricted = 'extradelight|extradelighttfc|dragn|aquaculture|cuisine|untamedwilds|survivorsdelight|firmalifeenhance|butchery'
# ① 资源里不得出现受限命名空间
$hit = Get-ChildItem "$B\src\main\resources" -Recurse -File |
       Where-Object { $_.FullName -match "\\(assets|data)\\($restricted)\\" }
if ($hit) { Write-Host "🛑 协议违规：资源里出现受限模组命名空间"; $hit | ForEach-Object { $_.FullName }; exit 1 }
# ② mods.toml 依赖不得含受限模组
$toml = Get-Content "$B\src\main\templates\META-INF\neoforge.mods.toml" -Raw
if ($toml -match "modId\s*=\s*`"($restricted)`"") { Write-Host "🛑 协议违规：依赖了受限模组"; exit 1 }
Write-Host "✅ 协议合规检查通过"
```

### 19.5 📌 一句话总结

> ⭐ **学"做什么"、不学"怎么写的"；学"结构"，不抄"文件"。**
> 🛑 **凡来源是 `CC BY-NC-SA` 或 `ARR` 的，只允许"读过它的说明书"，不允许"看过它的图纸"。**

### 19.6 本章的**局限声明**

⚠️ **本章不是法律意见**。实务判断（尤其 §19.2 风险 1 的"mixin 是否构成衍生"）**无判例**，
本章给的是**保守的工程实践**，不是法律结论。
🆕 **建议**：若本项目要**商业化分发**（付费整合包 / 服务器），**应咨询专业意见**；
若只是**免费开源分发**（当前定位），**§19.3 的判据足以覆盖绝大多数风险**。

### 4.12 ✅ **迁移第二批：34 树种配方全量 + 石砖分解**（2026-10-05）

> 承接 §4.11。用户口径：「**补全对 arborcraft 木材的支持**」+「案板……其次也能**处理原木或者分解石砖块**」

#### ⭐ 核心成果：**34 树种 × 2 = 68 个配方**（TFC 20 + afc 14 全覆盖）

先**核实 ID**（生成配方前必做）：
| 命名空间 | `wood/log/<w>` | `wood/wood/<w>` | `wood/stripped_log/<w>` | `wood/lumber/<w>` |
|---|---|---|---|---|
| **tfc** | ✅ 20 | ✅ 20 | ✅ 20 | ✅ 20 |
| **afc** | ✅ 14 | ✅ 14 | ✅ 14 | ✅ 14 |

**每个树种 2 条链路**：
| 配方 | 链路 | 工具 | 掉落 |
|---|---|---|---|
| `axe_debark_<wood>.json` | `log` --(斧)--> `stripped_log` | `axe` | 2× `lumber` · **`drop_above`** |
| `saw_planks_<wood>.json` | `stripped_log` --(锯)--> `planks` | `saw` | 4× `lumber` · **`drop_cardinal`** |

⇒ 🎯 **这就是"迁移过来的木材加工流程"**（用户口径 ⑥ 要求的"案板配方测试"用的正是这条链）。

#### 案板"分解石砖"（用户口径 ⑤ 的次要功能）

| 配方 | 链路 |
|---|---|
| `break_bricks_granite.json` | `tfc:rock/bricks/granite` --(工具)--> `tfc:rock/cobble/granite` + 1× `tfc:rock/loose/granite` |

⚠️ **"切食材"为什么没有用 `in_world` 做**：切食材的语义是"**案板上摊着一份食材**"，
用 `in_world`（"对着方块用工具"）表达不自然 ⇒ **应由案板自己的交互（BE 的 `onBoard` + `knife` 判定）承载**，
这部分**留待下一批**（骨架已就位：`Tool.KNIFE` + 执行器）。

#### 验收（**全过**）

| # | 判据 | 实测 |
|---|---|---|
| 1 | `gradle build` | ✅ **BUILD SUCCESSFUL** |
| 2 | ⭐⭐ **69 个配方全部加载** | ✅ **`Loaded 9249 recipes`**<br>（上版 9182 ⇒ **+67** = 删 2 个旧测试配方 + 加 69 个新配方 ⇒ **账目完全对上**） |
| 3 | ⭐ **配方解析** | ✅ **`Parsing error loading recipe` 0 处** |
| 4 | B 渲染层自检 | ✅ `已注册方块 138 个` |
| 5 | registry 类错误 + 本模组 ERROR | ✅ **全部 0 处** |

#### 📌 迁移**总进度**

| 步骤 | 状态 |
|---|---|
| 1. 迁 `recipes/inworld/` ⇒ `in_world` 配方类型 | ✅ **完成**（4 文件，零 mixin） |
| 2. ⭐ **34 树种配方全量**（含 afc 补全） | ✅ **完成**（68 + 1 = 69 个配方） |
| 3. 迁 `DebarkedLog/Half/Quarter` 方块 + 模型 | ⬜ **待做**（需为新方块写模型，工作量较大） |
| 4. 迁 `LogPileExBlock` + 2 个 BE | ⬜ 待做 |
| 5. 迁 JEI 分类 ⇒ 接进 `MyJeiPlugin` | ⬜ 待做（**优先级高**：让 69 个配方在 JEI 里可见） |
| 6. 案板"切食材"交互（BE + `knife` 判定） | ⬜ 待做（骨架已就位） |

---

## 2026-10-10 用户新增执行约束

### 养蚕明确归属 B 模组

养蚕不再按旧主方案中 C 侧的历史排期解释，后续作为 B 的长期内容实施。沿用本文件 §12.14 的极简设计：`firmalife:fruit_leaf` / A 的桑树叶 → 蚕架喂养 → 结茧 → TFC pot 煮茧缫丝 → 丝线 → TFC loom / TFC `silk_cloth`。不做育种、遗传病、品种能力或复杂蜂群系统。

### 可放置物品方块统一使用 TFC 容器接口

石臼、干燥架、案板、刀架、蚕架和今后所有能够放置/存储物品的方块，施工时必须先核对当前 TFC jar 的公开容器接口，优先采用 `InventoryBlockEntity` / `TickableInventoryBlockEntity`、TFC 菜单/`ItemStackContainer`、公开 item handler 和同步机制。不得继续为每个方块单独维护不兼容的 `content` 字段、手写库存协议或只支持单一路径的临时交互。

每个此类方块都必须验收：服务器权威库存、插入/取出原子性、拒绝输入不消耗、保存/加载、客户端同步、满背包、破坏/爆炸/替换掉落、多人操作和渲染只读容器状态。业务状态机可以独立实现，但不得直接复制 TFC 业务代码；实施记录必须写明使用的公开接口和兼容影响。
