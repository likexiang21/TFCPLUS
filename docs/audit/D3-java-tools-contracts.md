# D3 — Java / 工具 / 合同规范审查报告

> 审查对象：`mod_rebuild`（A `tfcfarmingplus` / B `tfcagricultureplus` 的 Java 源码、构建配置、`tools/`、`_refactor/`）
> 审查日期：2026-10-28　审查方式：**只读**（除本报告与 `docs/audit/` 下的临时脚本/CSV/日志外，未修改任何源码、资源、构建文件或既有文档）
> 关联报告：[D1 文档与计划](D1-docs-and-plans.md)、[D2 资源与数据协议](D2-resources-and-protocols.md)（资源侧 P0 以 D2 为准，本文不重复判定）
>
> **修订记录（2026-10-28，v2）**：初稿曾把 4 处“工具断链”列为当前缺陷。Lead 已修复：
> ① `audit-soil-contracts.ps1:21`、`audit-bush-contracts.ps1:40` 改读 `tools/scripts/generate/...`；
> ② `audit-branch-fruit-contracts.ps1:23` 同时接受 `now|currentState`；
> ③ B `verify-vegetable-beverage-processing.ps1:12` 改读 `tools/contracts/crops-manifest.json`、`:50` 改读 A 的 `FarmingItems.java`。
> 本报告已复跑并回填：三项 A 审计现均 `findings=0` 通过；B vegetable 现 `findings=0` 通过；A `verify.ps1` 由 177 FAIL 变为 **0 FAIL / 5 OK**（仅在缺 asset jar 处按原设计中止）。**这 4 项不再列为真实内容缺陷，改列为“工具断链已修复”**（见 §5.4-A 与 §6.2 复测行）；其余 B loot/工具环境问题保留。

---

## 一、范围与方法

### 1.1 审查范围

| 范围 | 内容 |
|---|---|
| A Java | 37 个文件 / 5,003 行 / 11 个包 |
| B Java | 86 个文件 / 7,504 行 / 18 个包 |
| 构建 | 两个模块的 `build.gradle.kts`、`gradle.properties`、`settings.gradle`、`templates/META-INF/neoforge.mods.toml`、B 的 `tfcagricultureplus.mixins.json` |
| 工具 | A `tools/`（66 根级 `.ps1`：49 wrapper + 17 活动 helper；`scripts/{generate,audit,verify}` 49 个实现；`contracts/` 13 JSON；`data/` 18 JSON；`java/` 3 Java；`archive/` 2 个历史工具；`_tags-baseline/` 14 JSON）、B `tools/`（18 根级 `.ps1`：17 wrapper + `build-local.ps1`；`scripts/` 17 个实现；1 个 Python 生成器）、共享 `mod_rebuild/tools/` 9 个脚本 |
| 重构脚本 | `_refactor/` 21 个 Python + `java-mapping.csv` + `legacy/` |
| 产物 | `mod_rebuild/artifacts/*.jar`、两模块 `build/libs/*.jar`、实例 `mods/` 中已部署的 A/B jar |

### 1.2 方法（全部可复现）

1. 复用仓库自带检查：`python _refactor/check_java.py`、`check_braces.py`、`check_resource_refs.py`；
2. 自写只读脚本（均在 `docs/audit/`）：
   - `audit_java_deep.py`：import / 类型 / 方法 / 字段引用计数、相似文件初筛；
   - `audit_tools_contracts.py`：wrapper 目标、contracts 哈希与路径、`data/*.json` 引用、脚本内绝对路径；
   - `d3_imports.py`：未使用 import 分类；`d3_mapping_and_jar.py`：映射完整性 + jar class 逐字节比对；`d3_stats.py`：包/类型统计；
3. 实际运行：A/B `gradle build --offline`（JDK 21，见 §6）、A `audit-crop-contracts` / `audit-rosette-dead-consumers` / `verify.ps1` / `healthcheck.ps1` / `verify-book.ps1`、B 全部 16 个 verify 脚本；
4. 反汇编/字节码核验：`javap` 校验 Firmalife 混入目标成员、TFC 依赖版本；`javac -Xlint:deprecation` 定位 A 的过时 API。

### 1.3 环境限制

- 本机是 **Windows PowerShell 5.1**（非 7），工作区 `.tooling/` **不存在**（`Test-Path .tooling` = False，`D:\TFC农业重置` 也不存在）；
- 因此依赖 `.tooling/game`、`.tooling/jdk21`、Minecraft client asset jar 的工具**无法完整运行**（属环境错误，不计为代码错误）；
- 所有构建使用 `~/.gradle/jdks/eclipse_adoptium-21-amd64-windows.2` + 全局 Gradle 8.13，`--offline` 成功（缓存已齐）。

---

## 二、结构统计

### 2.1 Java 规模

| 指标 | A | B | 合计 |
|---|---:|---:|---:|
| `.java` 文件 | 37 | 86 | 123 |
| 行数（`ReadAllLines`，LF 计） | 5,003 | 7,504 | 12,507 |
| 顶层 public 类型 | 37 | 86 | 123 |
| 包数 | 11 | 18 | 29 |
| jar 内 `.class`（含嵌套/匿名） | 44 | 103 | 147 |
| 文件/类型/包路径不一致 | 0 | 0 | 0 |
| `TODO/FIXME/XXX` | 0 | 0 | 0 |
| `My*` / `com.example` / `BlockBlock` | 0 | 0 | 0 |
| 重复顶层简单类名 | 0 | 0 | 0 |

最大文件：`FarmingCrops.java` 1,089 行（另有 348 个 `public static final DeferredHolder`）、`FarmingFruitTrees.java` 406、`AgricultureBlocks.java` 406、`AgricultureItems.java` 319、`SilkwormRackBlockEntity.java` 283、`FarmingDebugCommands.java` 266。A 平均 135 行/文件，B 平均 87 行/文件；A 的注册集中度明显偏高。

### 2.2 工具与数据规模

| 指标 | 数量 | 状态 |
|---|---:|---|
| A/B 根级 wrapper | 49 + 17 = **66** | 66/66 目标脚本存在（`D3-wrapper-targets.csv`） |
| A/B 活动实现脚本 | 49 + 17 = **66** | 全部经 wrapper 调用；脚本自身依赖 `TFC_TOOLS_ROOT` |
| `.ps1` BOM | 160/160 | 全部 UTF-8 BOM（符合工作区硬约束，正面结论） |
| A `contracts/*.json` | 13 | 哈希条目 **416/416 匹配** |
| A `data/*.json` | 18 | 引用路径 4,382 OK / 819 MISSING / 3 外部缺失（§5.3） |
| A `_tags-baseline/*.json` | 14（30 KB） | **零消费者** |
| `_refactor/java-mapping.csv` | 112 行 | 当前 Java 123 个 → **12 个未映射**（§5.5） |

### 2.3 资源侧数字（仅引用，不重复判定）

A 资源 5,922 个 / B 资源 3,031 个，与 `docs/274` 记录一致。A `blockstates/crop` 87、`wild_crop` 87、`dead_crop` 82；缺的 5 个（agave/cardoon/kale/purslane/sisal）是莲座作物共用共享枯死模型，不算缺失（`dead_rosette{,_young}` + 7 个顶层 blockstate 已覆盖）。B blockstates 492 个文件；`OVERRIDE-REGISTRY.md` 台账 418 行，`verify-coverage-ledger.ps1` 通过。

---

## 三、死代码与命名问题

### 3.1 无消费者 / 仅自引用的类与 API

**① `SpeciesLookup`（A，164 行）——目前是死代码（P2，需决策）**

- 全仓引用只有自身文件（`grep SpeciesLookup` 命中 7 行全在同一文件）；A 的 `FarmingDebugCommands` 也不使用；
- **B 没有任何 `io.github.likexiang21.tfcplus.farming.*` import**（`grep tfcplus.farming` 在 B Java 中 0 命中），因此“B API”目前不成立；
- 其 javadoc 第 19 行写“`tfcagricultureplus` 依赖本类”，与事实不符；
- `OVERRIDE-REGISTRY.md` L243 自己承认：“B 读取 A｜**尚未接入业务调用**；当前仅通过构建依赖 A jar”；
- `docs/274` L162 把它定性为“保留，不算死代码”。结论：**保留可以，但必须当作“预留 API”处理**——修正 javadoc，且要么在 B 加一处真实调用（哪怕编译期自检）以冻结契约，要么归档；不能既保留 164 行又声称它已被依赖。

**② `FarmingCrops` 的公开注册字段几乎没有外部消费者**

- 348 个 `public static final DeferredHolder`；A 内部外部文件对 `FarmingCrops.*` 的引用只有 5 处，且全是 `init()/cropBlocks()/fruitBlocks()` 之类方法，**不是字段**；
- 食物/种子字段（如 `SPINACH`、`SPINACH_SEEDS`）除本文件 seed lambda 外无引用；按“静态 final 字段模块内引用 ≤1”统计约 171 个（多为物品字段）；
- 结论：这是 TFC 风格的注册 API 表面，本身可保留，但它与 `SpeciesLookup` 一样说明 **A→B 的 Java API 面目前没有实际调用方**。

**③ `DebugValidation`（B，184 行，编进生产 jar）**

- `@EventBusSubscriber` 无条件注册（L33-40），仅当 `-Dtfcagricultureplus.debug=true` 时才注册命令；
- **内容已过期**：L58 `require(recipes.size()==12,"12 cutting recipes loaded")`，当前 `data/tfcagricultureplus/recipe/cutting_board/` 有 **15** 个配方 → 一旦按文档启动该命令，第一条硬检查就失败；
- 其余假设也与数据绑定：固定坐标 `(-1016,110,13500)`、`codex-validation-*` 存档名、34 种木材、12 项检查等；
- 启动入口 `tools/launch-validation-client.ps1` 依赖 `.tooling`（本机不存在），当前**无法运行**；
- 处置建议：**修好配方数断言并保留为 dev-only harness**，或整体归档到 `tools/`（不编进 jar）。不建议“维持现状 + 文档说已清理”——`README.md` L137 的“`DebugValidation` 已清理”只指变量改名，容易误读为已移除。

**④ B 的 JEI 兼容残留（死代码）**

`AgricultureJeiPlugin.java` L65-69 注释“Compatibility types retained for old category classes; no recipes or catalysts are registered”，且 L88-93 `registerCategories` 只注册 4 个类别（Mortar/InWorld/CuttingBoard/Pan）。因此：

- `compat/jei/DoughRecipeCategory.java`（36 行）、`MeltingRecipeCategory.java`（35 行）**无人实例化**；
- `AgricultureJeiPlugin.DOUGH` / `MELTING` 两个 `RecipeType` 常量无人使用；
- `AgricultureRecipeSerializers` 仍注册 `dough`/`melting` 序列化器，`AgricultureRecipeTypes` 仍注册类型（Melting 被 `MeltingPotBlockEntity` 使用，Dough 是否还有 gameplay 使用需业务确认）→ JEI 展示缺失属功能缺口，不是死代码；但两个 category 类与两个常量应删或恢复注册。

**⑤ 空实现 / 只为将来预留的挂点**

- `TFCFarmingPlus.java` L86-90 `setup(FMLCommonSetupEvent)` 为 `enqueueWork(() -> {})` 空 lambda，仍在 L52 注册监听（纯死代码）；
- `TFCAgriculturePlus.java` L96-100 `commonSetup` 同样为空，L64 注册；
- B `AgricultureRecipeSerializers` L18、L34 有提取脚本留下的空行/尾随空格（外观残留）；
- B `verify-registry.ps1` 的 `[WARN] registered but has no blockstate` 把物品/配方注册名当方块（见 §5.4），属工具误报而非代码问题。

### 3.2 过时 API（编译期实证）

| 位置 | 警告原文 | 处置 |
|---|---|---|
| A `FarmingFruitingBranchBlock.java:78` | `javac -Xlint:deprecation`：`LevelReader 中的 hasChunkAt(BlockPos) 已过时` | 换成非过时 API（如 `isLoaded`/区块存在性判断），或集中 `@SuppressWarnings` 并注明理由 |
| A `TFCFarmingPlusClient.java:103` | `@SuppressWarnings("deprecation") // 与 TFC 4.2.10 一致：NeoForge 仍支持该 API`（`ItemBlockRenderTypes.setRenderLayer`） | 注释版本号已过期（现装 4.2.11）；建议改为按 NeoForge 版本说明 |
| B `ClientEvents.java:12` | `警告: [removal] EventBusSubscriber 中的 bus() / Bus 已过时, 且标记为待删除` | 删除 `bus = EventBusSubscriber.Bus.MOD`（该事件本就在 mod 总线） |
| B `AgricultureJeiPlugin.java:162` | `警告: [removal] IRecipeRegistration 中的 getIngredientVisibility() 已过时, 且标记为待删除` | 跟进 JEI 新 API（或封装 + 降级） |

A 的 `gradle build` 只有 1 条 deprecation 汇总提示；B 有 3 个 `[removal]` 警告（见 `D3-build-B-compile.log`）。

### 3.3 命名与结构（对照 `docs/273` §2）

**做得好的（正面）**：`My*` 0、`BlockBlock` 0、泛化顶层类型（`Tree/Kind/Input/Action/Motion/SoundInstance/Serializer`）0、文件=类型=包路径 0 错、`TODO` 0。

**问题项**：

1. **短变量残留 11 处违反 `273 §2.2.4`**（白名单只允许 `level/pos/state/...`，不含 `be/s/r`）：`CuttingBoardBlockEntityRenderer:47`、`KnifeRackBlockEntityRenderer:41`、`TimberPileBlockEntityRenderer:21` 的 `be`；`DoughFormingTableBlockEntity:41/52`、`MeltingPotBlockEntity:44/54/65` 的 `s`/`r`。`id` 属白名单，可保留（详见 `D3-short-vars.csv`）。`docs/274` L124 的“只剩 id/key 等惯用局部名”说法偏乐观。
2. **未使用 import 31 条**（`D3-unused-imports.csv`）：全部是“正文改用全限定名后 import 变冗余（FQCN-ONLY）”，不是编译错误。典型：A `FarmingGrowingFruitTreeBranchBlock:3`、`RosetteCropBlock:3` 的 `FastGrow`（正文写 `io.github...FastGrow.ENABLED`）；B `AgricultureBlocks:15-18,29,32`、`CuttingBoardBlock/…`、`AgricultureRecipeSerializers:4` 与 `AgricultureRecipeTypes:4`（`InWorldRecipe` import 又在正文写 FQCN）、`MortarRecipe:3/5`（仅在 javadoc 使用）。`274` L118 声称已清理 54 个，实际仍有 31 条残留。
3. **通配 import 只集中在 B**：B 25 条 / 13 个文件（timber 包 8 个文件 + `DebugValidation` + `TimberPileBlockEntityRenderer`），A 为 0。建议收敛到显式 import，至少 timber 包内保持一致。
4. **注册职责与类名不匹配**：`FarmingBlocks.java` 名为“方块注册总入口”（类注释 L33），实际只有 3 个方块 + 2 个 `ExtendedProperties` helper；87 种作物的方块/枯死方块注册在 `FarmingCrops`，浆果在 `FarmingBushes`，果树在 `FarmingFruitTrees`，野生在 `FarmingWildCrops`；`FarmingItems` 只注册 13 个灌木产物，crop 的 food/seed 物品却在 `FarmingCrops`。可读性上建议：或改类名（`FarmingDeadBlocks`/`FarmingItemRegistry`），或把 `FarmingCrops` 拆成 `FarmingCropBlocks` + `FarmingCropItems`（当前 1,089 行 / 348 注册，是结构上最大单点）。
5. **A/B 客户端入口结构不对称**：A 只有 `client/TFCFarmingPlusClient`（主类显式调用 `register(bus)`）；B 拆成 `client/TFCAgriculturePlusClient`（渲染器，自动订阅）+ `client/ClientEvents`（菜单屏幕，自动订阅），主类不引用二者。两者都能工作，但同一职责两个入口类，增加“新增方块族要登记哪里”的歧义（`AgricultureBlocks` 注释还写“必须接进 `TFCAgriculturePlusClient`”）。
6. **公共嵌套类型违反 `273 §2.1.6`**（公共类型应顶层化）：`InWorldComponents.InWorldInput/SoundSpec/BlockStatePredicate/Tool`（L37/45/70/…）、`CuttingBoardRecipe.CuttingBoardInput`（L21）、`MeltingRecipe.MeltingInput`（L20）、`PanRecipe.PanInput`（L30）。私有 `InWorldAction.InWorldMotion`（L76）合规。
7. **陈旧 javadoc/注释**：A `TFCFarmingPlus.java:29` 仍叫“TFC Flora”、L32 指向旧树 `moddev/docs/70-...`；B `TFCAgriculturePlus.java:26` 指向 `moddev/docs/126-...`（均在 `docs/archive/`）；B 主类 L29 “A 的 86 物种”与现状 87 不符。全 Java 树共 9 处 `docs/` 引用，均未按新树路径重写。
8. **资源命名 `_vN` 残留**：A `src/main/resources` 下 **69 张** PNG 文件名带 `_v1`（celery/celtuce/… 的 `_stalks_v1`/`_stem_v1` 等），违反 `273 §2.3.3`“运行时资源不带版本后缀”；`docs/273` 记录整理前只有 25 张，现状更多。按 D2 结论这批属死贴图/待重绘范围，清理时需同步 contracts 中的 `ProtectedTextureSha256`。

### 3.4 重复实现

- A 的 7 个作物方块类（`FarmingCropBlock` 等）各自重复“构造器 + `create()` + final 属性捕获”约 20~30 行样板；这是 TFC 私有 `Crop` 枚举/`protected` 构造器逼出来的合法重复，且注释完整，**不建议盲抽**；若要抽，只抽 `create` 的公共模板。
- B 的 7 个 `*Serializer` 都是 11~37 行薄包装，职责不同，属正常样板，不是重复业务实现。
- 未发现 A/B 之间、或模块内两份相同的业务实现（顶层类型无重名；`_refactor/check_java.py` 的“重复简单名”检查是死代码，见 §5.5）。

---

## 四、协议与构建问题

### 4.1 A/B 依赖边界

| 项 | 实测 | 判定 |
|---|---|---|
| B Java → A Java import | **0 处** | 边界干净 |
| A Java → B Java import | **0 处** | 边界干净 |
| B 资源 → A 注册 ID | 28 处（`tfcfarmingplus:` 的 item/recipe/model 引用） | 真实运行时耦合在数据层 |
| B `build.gradle.kts` L28-36 | 编译依赖 `../tfcfarmingplus/build/libs` 的 A jar | **当前无编译收益**（B 不用 A 类）；保留只会让 B 无法独立构建 |
| B `neoforge.mods.toml` L24-27 | `tfcfarmingplus` 为 required，`[0.1.0,)` | 运行时依赖真实存在（A 物品 ID） |
| B `TFCAgriculturePlus.java:44-48` | 构造器 `ModList.isLoaded(A)` 硬失败 | 与 mods.toml required 重复；FML 已保证依赖加载，这段基本不可达 |

结论：**“B 依赖 A 的 Java API”目前是纸面契约**。建议二选一：(a) 去掉 `implementation(files(aJar))`，B 只依赖 A 的运行时 mod + 数据 ID；(b) 保留并在 B 里加 1 处真实 `SpeciesLookup` 使用 + 编译期自检，让契约可验证。当前“编译依赖 A jar + B 零 import + 文档称是 B 的 API”三者互相矛盾。

### 4.2 元数据 / mixin / 注册 ID

- A `neoforge.mods.toml`（模板）：`modId=tfcfarmingplus`、required `tfc/patchouli/neoforge/minecraft`，与 TFC 自身对 patchouli 的 required 声明一致；A 无 mixin（正确，A 无 mixin 类）。
- B `neoforge.mods.toml`：`[[mixins]] config = "tfcagricultureplus.mixins.json"`；required `tfcfarmingplus/tfc/firmalife/patchouli`；JEI 为 `type=optional, side=CLIENT`，与 gradle `compileOnly` 一致（正面）。
- B mixin：`tfcagricultureplus.mixins.json` 已打进 jar 根；`package` 与 `mixin/OvenTopBlockEntityMixin.java` 一致；`javap` 确认目标 `OvenTopBlockEntity` 有 `private int[] cookTicks` 与 `public static void serverTick(Level,BlockPos,BlockState,OvenTopBlockEntity)`，`@Shadow/@Inject` 目标存在（正面）。
- 注册 ID 一致性：A `crop` 87 / `wild_crop` 87 / manifest 87 / `audit-crop-contracts` 通过；B `verify-coverage-ledger` 418 行台账与资源树一致（正面）。
- **协议风险**：A 的 `mods.toml` 模板 L10-14 注释写“必须纯 ASCII”，但 L15 `description` 直接含中文“TFC农业+”。实测 jar 内 UTF-8 解码正确（因为 `filteringCharset=UTF-8`），但规则与文件自相矛盾，换工具链/未设 UTF-8 时会重现历史 `MalformedInputException`；建议把中文移入 lang 或删掉该行中文。
- `authors = "dsh"` 是占位符；`license = "MIT"` 但 `mod_rebuild` 与两个模块内**没有任何 LICENSE/COPYING 文件**，A jar 内也无 license 条目（B 只有两份第三方 notice）。发布前需补（P2）。
- B `tfcagricultureplus.mixins.json` 为 `required:true` + Firmalife 目标；mods.toml 把 firmalife 标 required，两者一致（若将来想让 B 在无 Firmalife 时降级，mixin 需改 optional，属设计决策）。

### 4.3 Gradle / 工具链 / 可复现性

1. **没有 gradle wrapper**：两个模块均无 `gradlew`/`gradle/wrapper/*`，依赖系统 PATH 上的 Gradle 8.13（本机来自 `~/.gradle/wrapper/dists/gradle-8.13-bin/...`）。换机器/CI 必须预装同一版本。
2. **JDK 依赖自动下载**：`java { toolchain.languageVersion = 21 }`，但本机 `JAVA_HOME` 默认是 **JDK 17**；离线构建成功只因 `~/.gradle/jdks/eclipse_adoptium-21-amd64-windows.2` 已缓存。新环境首次构建需要网络（或预置 toolchain）。
3. **`latestJar()` 的“字典序=语义序”假设是错的**（A `build.gradle.kts:17-25`，B 同）：`TerraFirmaCraft-NeoForge-1.21.1-4.2.9.jar` 的字典序 **大于** `...-4.2.11.jar`（`'9' > '1'`）。mods 目录里若同时存在新旧两个版本，会静默选中旧版。当前 mods 只有 4.2.11，属**潜在**缺陷，但注释把它当规则写死，建议改为解析版本号或显式白名单。
4. **依赖来源在仓库外**：`modsDir = rootProject.projectDir.resolve("../../mods")`，即实例 `mods/`（当前 50+ 个 jar，含与构建无关的 mod）；版本不锁定、内容不随仓库复制。A 依赖 TFC/Patchouli，B 再加 Firmalife/afc/JEI，全部靠“目录里有什么”。
5. **B 依赖 A 的构建产物**：A jar 在 `build/libs`，但 `docs/274` L151 明确“构建后已删除 A/B 的 `build/` 中间产物，仅保留 `artifacts/`”。→ **全新检出时 B 无法构建（缺 A build/libs），必须先构建 A**；没有 composite build 或 artifact 指针。已验证当前顺序构建可行，但这属于文档化的人工前置条件，不是工程化保证。
6. **部署态严重滞后**：实例 `mods/` 里是 **10-05 的旧 jar**（A 2,209,146 B / B 258,502 B），而 `artifacts/` 是 10-28 的新 jar（A 2,416,956 B / B 1,407,338 B）。任何“启动游戏看效果”的操作都会**加载旧代码**，这是当前最容易造成误判的状态问题（见 P0）。
7. `gradle.properties`：`-Xmx1G`、`daemon=false`，构建每个模块约 1 分 10 秒~1 分 20 秒（首次），重编译 19~21 秒；`--offline` 可用。
8. `settings.gradle` 的 `pluginManagement` 仍列网络 maven（neoforged、bmclapi2）；离线构建能过是因为 Gradle 缓存已有 `net.neoforged.moddev:2.0.111`。
9. 产物可复现性（正面）：`artifacts/` 两个 jar 与本次重新构建的 `build/libs` jar **147 个 class 逐字节一致（0 差异）**，仅 zip 时间戳不同 → 产物与当前源码一致，`274` 的构建声明可信。

---

## 五、工具 / 合同问题

### 5.1 wrapper 体系

- 49（A）+ 17（B）= **66 个根级 wrapper 全部指向存在的 `scripts/...` 实现**（`D3-wrapper-targets.csv` 66/66 OK，wrapper 190~215 字节），没有死 wrapper。
- 设计脆弱点：`group_tool_scripts.py` 把实现脚本里的 `$PSScriptRoot` 全部替换成 `$env:TFC_TOOLS_ROOT`，由 wrapper 注入。**直接运行 `scripts/...`（不经 wrapper）会拿到空 `TFC_TOOLS_ROOT`**，`Split-Path $null -Parent` 等会报错；这对 IDE/CI 直接调用不友好。
- 断链点（**已修，见 §5.4-A**）：重组后有两个审计脚本仍按旧布局读 `tools/gen-*.ps1`，读到的是 wrapper 而不是实现，曾导致 A `verify.ps1` 177 条假失败；另有一个 B verify 脚本读错 A 的 manifest 路径。修复后 4 项全部通过。
- 建议：短期保留 wrapper（它已是唯一稳定入口），把两个审计脚本改成读 `tools/scripts/generate/*.ps1`；中期若要删 wrapper，先统一实现脚本的根目录解析方式（例：脚本内自行向上查找 `tools/contracts` 或接受 `-ToolsRoot` 参数）。

### 5.2 保护合同（contracts）

**结论：合同本身是可信的，416/416 条哈希全部匹配当前文件**（`D3-contract-hashes.csv`），包括：

- 8 个 `*-display-contract.json` 的 `ReviewedJsonSha256` / `ProtectedTextureSha256` / `ProtectedGameplaySha256`（其中含 `FarmingCrops.java` 等源码哈希）；
- `NativeDependency.Files` 两个 TFC jar 内条目哈希（8EF3…/F1AA…）匹配；
- `strawberry-guide-policy.json` 的 `source_sha256` 与 `mods/TerraFirmaCraft-…4.2.11.jar` 匹配；
- `reviewed-item-icon-routes.json` 的大量行哈希/贴图哈希全部匹配；
- 所有合同路径都能解析到模块内文件（`CONTRACT-PATH-MISSING` = 0）。

同时合同自述状态与事实一致：8 个 display 合同均为 `VisualAccepted=false`、`RuntimeVerified=false`，`Scope` 明确写“artwork/runtime approval pending”。→ **不能把“合同通过”当成“视觉/实机验收通过”**。

### 5.3 `data/` 18 个 JSON 的真实状态

按消费者分类（实测引用）：

| 文件 | 消费者 | 状态 |
|---|---|---|
| `*-display-files.json` ×8（各 17~21 条） | `scripts/generate/gen-crops.ps1:144`（活动生成器） | 全部路径存在（152/152 OK） |
| `texture-jobs.json`（851 jobs） | `localize-textures.ps1`（一次性历史迁移） | 1,077 OK / **625 dst 缺失**（旧命名 `X_N` vs 现 `X_age_N`） |
| `texture-jobs-items.json`（1249） | `localize-all-models.ps1`（历史） | 2,405 OK / **90 缺失** / 3 外部缺失 |
| `texture-jobs-trees.json`（288） | `localize-fruit-tree-models.ps1`（历史） | 576 OK（全一致） |
| `texture-jobs-final.json`（75） | **无消费者** | 76 OK / 74 缺失 → 死数据 |
| `texture-jobs-bushes.json`（10）/`-rosefix`（3）/`-rosette`（30）/`-trunk`（9） | **无消费者** | 各有部分/全部缺失 → 死数据 |
| `fruit-texture-jobs.json`（12）/`-rosette`（4） | 仅 `tools/archive/20260923-generate-trunk-fruit-models.ps1` | `out` 为**绝对路径** `D:/111/...`（机器绑定）；12 条 out 已不存在 → 死数据 |

另：A `tools/_tags-baseline/`（14 个 JSON，30 KB）在全部工具/文档中**零引用**（`grep baseline` 无命中），README 也未登记该目录 → 死数据。

**建议**：`texture-jobs.json` / `-items` / `-trees` 与 `localize-*` 是同一批一次性迁移资产，**要么一起归档到 `tools/archive/`，要么一起修命名后重跑**；`final/bushes/rosefix/rosette/trunk/fruit-*` 与 `_tags-baseline` 直接归档/删除。

### 5.4 脚本路径 / 环境问题（按“工具断链（已修） vs 环境限制 vs 历史工具”分类）

**A. tools 重组引入的工具断链——已由 Lead 修复，本审查复跑确认（不再算缺陷）**

| 文件:行 | 原症状 | 修复 | 复测（2026-10-28 v2） |
|---|---|---|---|
| `scripts/audit/audit-soil-contracts.ps1:21` | 读 `tools/gen-crops.ps1` / `tools/gen-patchouli-book.ps1`（重组后只剩 wrapper，无 `n='...' npk='...'` 表）→ 模板表为空，报 174 条 `Generator nutrient drift` | 改为 `tools/scripts/generate/$tool` | `audit-soil-contracts`：`nutrient crops=87 … findings=0`，EXIT 0 |
| `scripts/audit/audit-bush-contracts.ps1:40` | 读 `tools/gen-wild-injection.ps1` / `gen-dead-and-wild-bushes.ps1`（wrapper）→ 2 条 generator 契约 FAIL | 改为 `tools/scripts/generate/$tool` | `audit-bush-contracts`：`bushes=12; blocks=20; findings=0`，EXIT 0 |
| `scripts/audit/audit-branch-fruit-contracts.ps1:23` | 文本契约只匹配旧变量名 `now.getValue(FRUIT)`，重构后源码为 `state/currentState` → 1 条 `Harvest must commit...` FAIL | 契约改为 `(?:now|currentState)` | `audit-branch-fruit-contracts`：`trunk species=7 … findings=0`，EXIT 0；源码顺序 L134 setBlock → L137 giveItemToPlayer 本就正确 |
| B `scripts/verify/verify-vegetable-beverage-processing.ps1:12` | 读 A 的 `tools/crops-manifest.json`（已移到 `tools/contracts/`）→ `$manifest=null` → `$crops=@($null)` → 空名走非灌木分支 → `$loot` 为 null，崩溃 “You cannot call a method on a null-valued expression” | 改读 `tools/contracts/crops-manifest.json` | 复跑 EXIT 0：`remaining crops=50; bush products=2; prepared vegetables=3; findings=0` |
| B 同文件 `:50` | 读 A 的 `.../registry\AgricultureItems.java`（模块与类名都不对） | 改读 A 的 `.../registry/FarmingItems.java`（正斜杠） | 同上，通过 |

> 该断链的根因是 `group_tool_scripts.py` 只把实现脚本内部 `$PSScriptRoot` 换成 `$env:TFC_TOOLS_ROOT`，没有替换“脚本里引用其它脚本路径”的字符串；`update_tools.py` 也只做 Java 路径/类名替换。**修复已生效**，但这类“脚本互引路径”仍建议加一条静态检查，防止下次重组再断。
> 初稿记录的“A `verify.ps1` 177 FAIL（= 174 soil + 2 bush + 1 branch）”**已随上述修复消失**：复跑结果为 **0 FAIL / 5 OK**，仅在 `audit-leaf-vegetable-models.ps1` 缺 asset jar 处按原逻辑中止（环境问题，见 B 段）。

**B. 环境限制（非代码错误，保留）**


- A `scripts/audit/audit-leaf-vegetable-models.ps1:10-11`：向上查找 `.tooling/game/versions/1.21.1/1.21.1.jar`，本机无 `.tooling` → `verify.ps1` 在 428 行处抛 “Minecraft 1.21.1 client asset jar not found under workspace tooling”；`healthcheck.ps1` 因其调用 verify.ps1 同样失败。
- B `verify-agricultural-materials.ps1:69`：向上查找 `.tooling`，空字符串传入 `Join-Path` → 失败。
- B `build-local.ps1`：要求 `.tooling/gradle-8.13` + `.tooling/jdk21`（本机都不存在）→ 官方“本地构建辅助”不可用；实际构建只能用系统 Gradle（本文用这种方式成功）。
- B `verify-registry.ps1` 静态模式：脚本自己已标注 “loop-generated variants are NOT visible, prefer -FromLog”。实测静态模式把 34 种木材 × 14 类方块（≈440 个循环生成 ID）判成 “NOT registered”，又把物品/配方注册名判成 “registered but has no blockstate”，**退出码 1**。这是工具设计缺陷（静态模式不应 fail，或应默认需要 `-FromLog`）；且当前没有启动器设置 `-Dtfagricultureplus.dumpBlockIds=true`（B 客户端 L51-59 支持），所以仓库内**没有可用的权威模式路径**。附注：A 客户端**没有** `[BLOCK-ID]` dump（grep 无命中），而 `verify-registry.ps1` 的用法注释写的是 `-Dtfcfarmingplus.dumpBlockIds=true`，说明文档与实现不一致。
- 共享 `tools/launch-client.ps1`、`launch-validation-client.ps1`、`stop-*`：全部以 `<version>/../..` 为 workspace，要求 `.minecraft/.tooling/{game,jdk21}`，本机不存在 → 整套启动/验证工具当前不可用。
- 共享 `tools/readjar.ps1:9-10`：硬编码 `TFC_ROOT` 与 **4.2.10** jar（实际 4.2.11）→ 命中即 FileNotFound。
- 共享 `tools/verify-k1-runtime.ps1:2`：默认日志 `D:\TFC农业重置\.tooling\...`（该盘符目录不存在）→ 死工具。
- 共享 `tools/stop-own-client.ps1:15`：硬编码 `options.txt` 路径（当前实例路径恰好一致，但不可迁移）。

**C. 一次性/历史工具仍在“活动目录”**

- A `localize-textures.ps1`（L30 硬编码 `C:\Users\Lenovo\.gradle\jdks\...\bin\java.exe`，L31 依赖 `%TEMP%\tfcx` 缓存，L53 把模型名 `_age_` 还原成旧的 `X_N` 贴图名）——**如果今天重跑，会把模型重新指向已死的 `X_N` 贴图**（与 D2 P0 的 949 个模型引用问题同源）。`localize-all-models.ps1:44`、`localize-fruit-tree-models.ps1:21` 同样硬编码本机 JDK 路径。
- `repair-food-item-models.ps1:17-18`、`repair-wild-crop-placement.ps1:23`、`finalize-resource-set.ps1:12`、`gen-high-bushes.ps1:42`、`scripts/generate/generate-wild-crop-patches.ps1:19` 硬编码 `D:\111\最强服务器\...` 绝对路径；`repair-food-item-models.ps1:18` 还硬编码 **4.2.10** jar。
- 共同点：这些脚本都是“一次性修正/迁移”，却被 `tools/README.md` 列在“根目录活动 helper”并保留可执行入口。建议移到 `tools/archive/` 或加显式 `# DEPRECATED` 头。
- 另：`tools/README.md` 把 `_tags-baseline/` 整目录漏登记；`tools/java/README.md` 未说明 `TintTextures` 只服务历史 localize 脚本。

### 5.5 `_refactor/` 与映射/检查脚本

- `java-mapping.csv` **不完整且有一条坏行**：当前 123 个 Java、映射 112 行；缺 11 个（`extract_nested_blocks.py` / `extract_recipe_serializers.py` 新外移的 4 个方块类 + 7 个 `*Serializer`），另 1 行仍写 `.../inworld/Action.java`（实际已改 `InWorldAction.java`，`new_name` 仍是 `Action`）。`docs/274` L199 说可用它反向核对回滚，按现状会漏掉 11 个文件。
- `check_java.py`：errors=0/warnings=0 属实，但覆盖面小于其被引用的力度——它不检查 unused import、通配 import、命名、方法/字段引用；“重复简单名”那段代码实际是死逻辑（`simple_to_fqcn` 是 dict，`list(dict).count(name)` 永远 ≤1，永不告警）。
- `_refactor/` 内仍保留 `refactor_java.py`、`rename_*`、`extract_*`、`move_*` 等**会写源码/资源的重构脚本**。它们已完成使命，留在新树里有被误跑的风险；建议只保留 `check_*.py`（只读门禁）并把写操作脚本归档。
- `group_tool_scripts.py` 的 `$PSScriptRoot → $env:TFC_TOOLS_ROOT` 批量替换是本次多数工具断链的根源（只替换了脚本内部，没替换“脚本里引用其它脚本路径”的字符串）；`update_tools.py` 只做 Java 路径/类名替换，同样不覆盖 `tools/<name>.ps1` 引用。**该断链已于 2026-10-28 由 Lead 修复并复测通过**（§5.4-A），但修法属于逐文件修补，建议补一条“脚本互引路径”静态检查以防再犯。

### 5.6 死工具 / 重复 wrapper 处置建议（汇总）

| 对象 | 建议 |
|---|---|
| 66 个 wrapper | **保留**（稳定入口）；§5.4-A 的三处互引误用已修，后续删 wrapper 前需先统一实现脚本的根目录解析 |
| `localize-*`（3 个）、`repair-*`（2 个）、`sync-*`（2 个）、`finalize-resource-set`、`preview-model` | 迁移到 `tools/archive/`；`preview-model` 若仍用于审查可留但需去绝对路径 |
| `tools/archive/20260923-*.ps1` + `data/fruit-texture-jobs*.json` + `archive/GenFruitTexture.java` | 同属一套旧树干果实生成器，应一起归档到同一目录 |
| `data/texture-jobs-final|bushes|rosefix|rosette|trunk` | 无消费者，归档/删除 |
| `tools/_tags-baseline/` | 无消费者、未登记，归档/删除 |
| 共享 `verify-k1-runtime.ps1` | 死工具，归档 |
| 共享 `readjar.ps1` | 修版本号或改为从环境变量取 jar 路径 |
| 共享 launch/validation 工具 | 依赖 `.tooling`，要么恢复 `.tooling` 要么标注“需要旧工作区运行时” |
| `_refactor` 写操作脚本 | 归档，仅保留 `check_braces.py`/`check_java.py`/`check_resource_refs.py` |
| `DebugValidation` | 修配方数断言后保留（dev-only），或归档 |
| SpeciesLookup | 保持“预留 API”定位需修正 javadoc；否则归档 |
| JEI `DoughRecipeCategory`/`MeltingRecipeCategory` + 两个 RecipeType 常量 | 删除，或恢复类别注册 |

### 5.7 其他工具质量问题

- **`.`-source helper 的根目录**：`cocoa-data-policy.ps1`、`shared-dead-model-policy.ps1`、`crop-*-contracts.ps1` 仍是根级 dot-source helper（README 已说明），它们通过 `$env:TFC_TOOLS_ROOT` 被引用；如果 wrapper 机制改动，这会成为新的集中故障点。
- **编码**：27 处 `Get-Content` 未带 `-Encoding`（集中在 B verify 脚本、共享 launch 工具）。多数读取的是 ASCII JSON/源码，暂未出错；但工作区规则明确“文本读写一律字节+显式 UTF-8”，建议统一补齐，避免 GBK 环境下读中文注释/语言文件时静默错判。
- **BOM**：160/160 `.ps1` 均为 UTF-8 BOM，符合硬约束（正面）；`docs/274` L114 的 AST 全量解析声明未在本环境中复跑（PowerShell 5.1 的 AST 解析行为与 7 不同），本报告不采信/不否定。
- `tools/java/TintTextures.java` 只被 3 个历史 localize 脚本调用；`TextureAverage`/`TextureStats` 为人工分析辅助（README 已注明），可保留。
- `tools/README.md` 的目录清单与实际不一致（漏 `_tags-baseline/`、把一次性脚本列为活动工具），属文档问题（D1 负责）。

---

## 六、验证结果

### 6.1 构建（实测，2026-10-28 01:00~01:20）

| 命令 | 结果 | 证据 |
|---|---|---|
| `cd tfcfarmingplus && gradle build --console=plain --offline` | **BUILD SUCCESSFUL in 1m 17s**（重编译 19s） | 终端输出；`D3-build-A-compile.log` |
| `cd tfcagricultureplus && gradle build --console=plain --offline` | **BUILD SUCCESSFUL in 1m 10s**（重编译 21s） | 终端输出；`D3-build-B-compile.log` |
| A 编译告警 | 1 条汇总 deprecation（`FarmingFruitingBranchBlock.java:78` `hasChunkAt`） | `javac -Xlint:deprecation` 已定位 |
| B 编译告警 | 3 条：`ClientEvents.java:12`（Bus/bus()，removal）、`AgricultureJeiPlugin.java:162`（getIngredientVisibility，removal） | `D3-build-B-compile.log` |
| 产物一致性 | `artifacts/` vs 新 `build/libs/`：A 44 个 class、B 103 个 class **逐字节 0 差异** | `d3_mapping_and_jar.py` |
| 部署一致性 | 实例 `mods/` 里的 A/B jar 是 **10-05** 旧构建，与 `artifacts/` 不一致 | 文件大小/时间戳 |

构建结论：**代码没有编译错误**；A/B 均可在“已下载 JDK21 + 已准备 mods 缓存 + 离线 Gradle 缓存”的环境下复现。不复现因素见 §4.3。

### 6.2 验证脚本实测

| 脚本 | 初测（修复前） | 复测（2026-10-28 v2，Lead 修复后） | 分类 |
|---|---|---|---|
| A `audit-crop-contracts.ps1` | `species=87; detailed=87; findings=0`，EXIT 0 | — | 通过 |
| A `audit-soil-contracts.ps1` | 174 条 `Generator nutrient drift`（断链） | `nutrient crops=87; fertilizers=10; soils=8; findings=0`，EXIT 0 | **断链已修** |
| A `audit-bush-contracts.ps1` | 2 条 generator 契约 FAIL（断链） | `bushes=12; blocks=20; findings=0`，EXIT 0 | **断链已修** |
| A `audit-branch-fruit-contracts.ps1` | 1 条 `Harvest must commit...`（旧变量名） | `trunk species=7; cases=1920; findings=0`，EXIT 0 | **断链已修** |
| A `audit-rosette-dead-consumers.ps1` | `species=5; cases=10; states=2; findings=0`，EXIT 0 | — | 通过 |
| A `verify-book.ps1` | 10 语言、1,382 页、24 条目、跳转/分类通过，EXIT 0 | — | 通过 |
| A `verify.ps1` | 177 FAIL / 2 OK，随后在 asset jar 处中止，EXIT 1 | **0 FAIL / 5 OK**，随后仍在 asset jar 处按原设计中止，EXIT 1（环境） | 断链已修；剩余为环境限制 |
| A `healthcheck.ps1` | EXIT 1（调用 verify.ps1 同一原因） | 预期仍 EXIT 1（env：asset jar） | 环境限制 |
| B `check-boundaries` | OK | — | 通过 |
| B `verify-container-contract` | OK | — | 通过 |
| B `verify-coverage-ledger` | 418 行 / 418 文件 OK | — | 通过 |
| B `verify-fruit-processing` | findings=0 OK | — | 通过 |
| B `verify-grain-food-processing` | findings=0 OK | — | 通过 |
| B `verify-in-world-codec` | 408 in-world + 102 loot OK | — | 通过 |
| B `verify-silkworm-chain` / `lifecycle` | OK / OK | — | 通过 |
| B `verify-drying-batch` / `verify-kitchenware-ledger` | OK / OK | — | 通过 |
| B `verify-workbench-recipes` / `verify-woodwork-flow` / `verify-optional-woodwork-compat` | OK / OK / OK | — | 通过 |
| B `verify-vegetable-beverage-processing` | FAIL：manifest 路径失效 → null 崩溃（断链） | **EXIT 0**：`remaining crops=50; bush products=2; prepared vegetables=3; findings=0` | **断链已修** |
| B `verify-registry` | **FAIL（退出 1）**：静态模式把循环生成变体判缺失 | 未变（设计问题，非内容错误） | 工具设计缺陷（保留 P1） |
| B `verify-agricultural-materials` | FAIL：`.tooling` 缺失 → `Join-Path ''` | 未变（环境） | 环境错误（保留） |
| `_refactor/check_java.py` | `errors = 0, warnings = 0` | — | 通过（覆盖面有限，见 §5.5） |
| `_refactor/check_braces.py` | `brace issues: 0` | — | 通过 |
| `_refactor/check_resource_refs.py` | `missing model/texture refs: 0` | — | 通过（不含“模型引用 TFC 贴图”这类语义回归，D2 另行发现） |

### 6.3 未验证（必须如实标注）

- 未启动游戏（`.tooling` 缺失 + 部署 jar 是旧版）；**没有任何实机/视觉验收**；
- 未验证运行时注册表（B 的 `-FromLog` 模式缺日志）、未验证 mixin 实机注入；
- 未验证新 jar 与旧存档兼容；
- `artifacts/` 与新 `build/libs` class 一致，但**部署侧仍是旧 jar**，因此“能构建”不等于“游戏里跑的是这份代码”。

补充：工具断链修复后，A `verify.ps1` 的静态检查链已恢复到 **0 FAIL / 5 OK**（`D3-verify-A-after-fix.log`），唯一剩余中断是缺 Minecraft client asset jar（环境）；B `verify-vegetable-beverage-processing` 已 EXIT 0（`D3-verify-B-vegetable-after-fix.log`）。因此 §6.2 表中“断链已修”的 4 项不再构成内容或工具缺陷，仅作为历史记录保留。

---

## 七、P0 / P1 / P2 清单

### P0（在本轮验收/交接前必须处理）

1. **部署态与构建态不一致**：实例 `mods/TFCFarmingPlus…jar` / `TFCAgriculturePlus…jar` 是 **10-05** 旧版（2,209,146 / 258,502 B），当前源码产物是 `artifacts/` 的 10-28 新 jar（2,416,956 / 1,407,338 B）。任何按旧流程“启动游戏看效果”都会验证到旧代码；在替换前不得声称实机/视觉已验证。
2. （与 D2 联动）`localize-textures.ps1` 等历史工具仍在活动目录且具破坏性：重跑会把模型指回 `X_N` 死命名（D2 P0 的 949 个模型贴图引用问题同源）。在 D2 修复方案落地前，应把这些脚本移出活动工具链。

> 初稿 P0 中的“A `verify.ps1` 已失效（177 假失败）”**已在 2026-10-28 v2 撤销**：三项断链修复后复跑为 0 FAIL / 5 OK，仅剩 asset jar 环境限制（降级为 P1-5）。B `verify-vegetable` 崩溃同样已修复，从 P1 移除。

### P1（本迭代应处理）

1. **`DebugValidation` 与数据漂移**：配方数断言 12 vs 实际 15；其余检查绑定 34 木材/固定坐标/存档名前缀。要么修好并保留为 dev harness，要么归档；当前状态不能作为可用的验收工具。
2. **B `verify-registry` 不可用**：静态模式必然误报并 exit 1；需默认要求 `-FromLog`、在缺少日志时回退为 WARN（exit 0），并让启动器真的输出 `[BLOCK-ID]`；同时修正文档中 `-Dtfcfarmingplus.dumpBlockIds`（A 未实现）与 B 实现不一致的问题。
3. **构建可复现性**：补 gradle wrapper 或明确记录 Gradle 8.13/JDK21/mods 目录前置条件；修 `latestJar()` 字典序缺陷；给 B 的 A-build-output 依赖一个稳定方案（composite build 或“先建 A”的脚本门禁 + CI 顺序）。
4. **A/B API 契约矛盾**：B 无 A import，却保留 `implementation(files(aJar))`；`SpeciesLookup` 自述被 B 依赖但实际 0 消费者。二选一：加真实调用/编译期自检，或去掉 B 的 A jar 编译依赖并把 SpeciesLookup 标为预留 API/归档。
5. **A `verify.ps1` 的 env 依赖应降级为 SKIP（工具断链已修，此条保留）**：缺 `.tooling`/asset jar 时对应审计应以 “SKIP(env)” 计数而非中止全部验证；否则在无 tooling 的机器上永远无法用该入口。
6. **B 其余 verify 的环境依赖**：`verify-agricultural-materials`（`.tooling` 缺失 → `Join-Path ''` 崩溃）应改为清晰 env SKIP；`build-local.ps1` 同样依赖不存在的 `.tooling`。
7. **共享启动/验证工具链不可用**：`launch-client.ps1`、`launch-validation-client.ps1`、`stop-*`、`build-local.ps1` 全部依赖不存在的 `.tooling`；需要恢复运行时或明确标注“旧工作区遗产、当前不可用”。
8. **`_vN` 运行期资源 69 张** 违反 `273 §2.3.3`：与 D2 的死贴图清理合并处理，并同步 contracts 哈希。
9. **缺失命名/布局门禁**：`273 §0` 要求的 `verify-naming.ps1`、`verify-links.ps1`、`verify-layout.ps1` 均不存在 → “最终判据”没有自动化支撑。

### P2（择机处理）

1. 未使用 import 31 条（全为 FQCN 冗余）+ 通配 import 25 条（B timber/DebugValidation）；按文件批量清理即可。
2. 空挂点：`TFCFarmingPlus.setup`、`TFCAgriculturePlus.commonSetup`（各 5 行 + 一个监听注册）。
3. JEI 死代码：`DoughRecipeCategory`、`MeltingRecipeCategory`、`AgricultureJeiPlugin.DOUGH/MELTING` 常量；或恢复类别注册。
4. 过时 API：A `hasChunkAt`（+ 已 `@SuppressWarnings` 的 render layer API 注释版本过期）、B `EventBusSubscriber.Bus`、B `getIngredientVisibility`（均为 `[removal]`）。
5. **`java-mapping.csv` 未覆盖 11 个外移类且含一条坏行**（`Action.java` 应为 `InWorldAction.java`）；`check_java.py` 的重复名检查是死代码。
6. `_refactor` 写操作脚本（refactor/rename/extract/move）留存在新树；建议归档，只保留只读检查。
7. 注册职责/类名对齐：`FarmingBlocks` 名不符实、`FarmingCrops` 1,089 行/348 注册建议拆分、`FarmingItems` 与 crop 物品分离；A/B 客户端入口结构不对称。
8. 公共嵌套 record 违 `273 §2.1.6`（`InWorldComponents` 4 个 + 3 个 recipe 的 `*Input`）。
9. `data/` 死数据 7 个 + `_tags-baseline/` 14 个 + 共享死工具 `verify-k1-runtime.ps1`；`readjar.ps1` 版本 4.2.10 过期。
10. 未使用注册字段（约 171 个 `static final`，多为 `FarmingCrops` 物品字段）：保留为注册 API 可以，但建议在文档中明确“这些字段不是供 Java 调用的稳定 API”。
11. 短变量 11 处 `be/s/r`（`273 §2.2.4`）。
12. 陈旧 javadoc/链接（`TFC Flora`、`moddev/docs/*` 3 处、B 主类“86 物种”）；`authors="dsh"`、缺 LICENSE 文件；A mods.toml 注释（纯 ASCII）与实现（含中文）矛盾。
13. 27 处 `Get-Content` 缺 `-Encoding`（潜在 GBK 误读）。
14. 脚本内绝对路径（`localize-*` 的 JDK、`repair-*`/`finalize`/`gen-high-bushes`/`generate-wild-crop-patches` 的 `D:\111\...`）应在归档前改为相对路径（若保留）。

---

## 八、总体建议与开发状态判断

### 8.1 保留（必须）

- A/B Java 主体（结构、命名、注释质量整体高于旧树；`My*`/泛化名/文件类型一致性问题已清零）；
- 66 个 wrapper 作为稳定入口（§5.4-A 的三处互引断链已修复，无需再改逻辑）；
- `contracts/` 13 份保护合同（416/416 哈希匹配，且如实标注未视觉/未实机）；
- A `audit-crop-contracts`、`audit-soil-contracts`、`audit-bush-contracts`、`audit-branch-fruit-contracts`（修复后）、`audit-rosette-dead-consumers`、`verify-book`，B 的 14 个通过脚本（新增 `verify-vegetable-beverage-processing`）；
- `_refactor/check_braces.py`、`check_resource_refs.py`（只读门禁）与 `_refactor/java-mapping.csv`（补全后）；
- B 的 mixin + mods.toml 元数据（目标成员已用 javap 核验），A/B 的 mods.toml 依赖声明。

### 8.2 归档 / 废弃

- 归档：`localize-*`（3）、`repair-*`（2）、`sync-*`（2）、`finalize-resource-set`、`gen-high-bushes`、`generate-wild-crop-patches`（若不再重跑）、`tools/archive/*` 与 `data/fruit-texture-jobs*` 合并归档、`data/texture-jobs-final/bushes/rosefix/rosette/trunk`、`_tags-baseline/`、`verify-k1-runtime.ps1`、`_refactor` 写操作脚本；
- 废弃（删）：JEI 两个死 category + 两个 dead RecipeType 常量、两个空 `setup/commonSetup`、31 条冗余 import、`FarmingCrops` 中确认为纯自引用的物品字段（谨慎，需先确认无计划用于 B 的 API）。

### 8.3 重写 / 修

- 已修（2026-10-28 v2，本报告复测确认）：`audit-soil-contracts` / `audit-bush-contracts` / `audit-branch-fruit-contracts` 的互引路径与旧变量名、B `verify-vegetable-beverage-processing` 的 manifest/模块路径；
- 仍需修：B `verify-registry` 降级策略、`verify.ps1` 与 B `verify-agricultural-materials`/`build-local` 的 env SKIP、`latestJar` 版本比较、`readjar` 版本；
- 重写/补：B 的构建依赖策略（去掉 A jar 或加真实 API 使用）、gradle wrapper + 依赖锁定、`verify-naming/layout/link` 三个门禁、共享启动工具链（或明确“不可用”）；
- 同步：`java-mapping.csv` 补 11 个外移类 + 修正 `InWorldAction` 行；`README/274/275` 中“verify 已通过”的表述需按本报告 §6 重新表述（A verify 静态检查 0 FAIL，但全套仍受 asset jar 环境限制）。

### 8.4 开发状态判断

- **Java 重构本身：静态质量中等偏上**。文件/类型/包一致、无旧命名、无 TODO、注释与设计意图清楚；A/B 边界在源码层干净；构建可复现（class 级一致）。
- **工程化闭环：仍未完成，但工具断链已修**。A `verify.ps1` 恢复为 0 FAIL / 5 OK（仅剩 asset jar 环境中断）、B `verify-vegetable` 通过；剩余阻塞是构建依赖机器本地化（mods 目录、无 wrapper、JDK 下载）、部署 jar 滞后、B `verify-registry` 设计缺陷与 `.tooling` 依赖、映射/文档部分失真。
- **不可称为“已验收”**：`contracts` 自己标 `VisualAccepted=false / RuntimeVerified=false`；本次审查也未做任何实机验证。可交付性取决于 D2 的资源 P0 + 本文 P0/P1 的修复。
- **建议的下一步顺序**：① 部署/替换 mods 内 jar 并明确“当前可玩基线”；② 归档历史 localize/repair/sync；③ 补构建 wrapper/依赖策略与 B 两条 env/design 修复；④ 再进入 D2 的资源修复与真正的实机/视觉验收。

---

## 附：本次审查产出的证据（均在 `mod_rebuild/docs/audit/`）

| 文件 | 内容 |
|---|---|
| `audit_java_deep.py` / `d3_imports.py` / `d3_mapping_and_jar.py` / `d3_stats.py` / `audit_tools_contracts.py` | 只读分析脚本（可删除/保留） |
| `D3-wrapper-targets.csv` | 66 wrapper → 目标存在性 |
| `D3-contract-hashes.csv` | 416 条合同哈希/路径核验（全 OK） |
| `D3-data-paths.csv` | `data/*.json` 逐引用路径存在性（4,382 OK / 819 MISSING / 3 外部） |
| `D3-unused-imports.csv` | 31 条冗余 import（FQCN-ONLY） |
| `D3-short-vars.csv` | 短变量清单（11 条非白名单 + `id`） |
| `D3-stale-paths.csv` | 脚本内绝对路径（14 条） |
| `D3-verify-A.log` / `D3-verify-B-vegetable.log` | **修复前** A verify.ps1（177 FAIL）与 B 崩溃脚本的原始输出（历史留证） |
| `D3-verify-A-after-fix.log` / `D3-verify-B-vegetable-after-fix.log` | **修复后**复测：A verify 0 FAIL / 5 OK（asset jar 处中止）、B vegetable EXIT 0 |
| `D3-build-A-compile.log` / `D3-build-B-compile.log` | 离线编译日志（含告警原文） |
