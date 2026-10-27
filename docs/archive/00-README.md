# TFC 附属模组开发技术文档库（索引）

> **这是什么**：一套面向 AI 代理与人类开发者的 TerraFirmaCraft 附属模组开发参考资料。
> 内容全部来自**本机实际安装的模组 jar 与对应版本的官方源码**（经过反编译/克隆获取），
> 不是网上抄来的通用教程。目标：让后续任何一次「给这个整合包写一个 TFC 附属模组」的任务
> 都能直接查到确切的类名、方法签名、JSON 字段与目录路径。
>
> **生成时间**：2026-09（工具链：CFR 0.152 + javap (JDK 17/25) + git + PowerShell）。

---

## 0. 环境事实（一切结论的前提）

| 项目 | 值 | 来源 |
|---|---|---|
| 整合包目录 | `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)` | 工作目录 |
| Minecraft | 1.21.1 | `logs/latest.log` |
| NeoForge | **21.1.248**（`--fml.neoForgeVersion`） | `logs/latest.log` |
| FML | 4.0.43 | `logs/latest.log` |
| Java（运行） | Microsoft OpenJDK **21.0.3** | `logs/latest.log` |
| TFC | **4.2.10**，modId `tfc`，硬依赖 `patchouli >= 1.21.1-92-NEOFORGE`、`neoforge >= 21.1.234` | `mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar!/META-INF/neoforge.mods.toml` |
| Firmalife | **3.0.14**，modId `firmalife`，硬依赖 `tfc >= 4.2.8` | `mods/Firmalife-NeoForge-1.21.1-3.0.14.jar!/META-INF/neoforge.mods.toml` |
| Patchouli | **1.21.1-93**，modId `patchouli` | `mods/Patchouli-1.21.1-93-NEOFORGE.jar` |
| 其它相关 | JEI 19.56、Jade 15.10、KubeJS 2101.7.2 + `kubejs_tfc` 2.1.0、ProbeJS 8.0.3、Curios 9.5.1 | `mods/` |

**三条硬结论**：
1. 做这个整合包的附属模组，`patchouli` 可以直接当成硬依赖（TFC 自己就强制要求它）。
2. NeoForge 版本区间写 `[21.1.234,)`、MC 写 `[1.21.1]` 即可。
3. 实例里的 TFC/Firmalife jar 内的类名是 **mojmap 官方名**（`net.minecraft.world.level.block.Block`），
   因此可以直接 `javap` 或当作编译依赖使用，无需重新映射。

---

## 1. 文档地图

| 文档 | 行数级别 | 作用 | 什么时候读 |
|---|---|---|---|
| `10-tfc-overview.md` | ~300 | TFC 架构总览、包结构、启动时序、**七大注册层**、`ExtendedProperties` 体系、时序规范 | **先读这份**，建立整体认知 |
| `11-tfc-registry-catalog.md` | ~250 | 注册名目录、5 大枚举维度（Metal/Wood/Rock/…）、命名规律、配方类型与数据表名速查 | 想知道「有没有现成的 id 可以复用」时 |
| `12-tfc-data-driven.md` | **~10450 行**（795 KB） | **28 种配方类型 + 16 类 `tfc/` 数据表 + worldgen/tags/loot/advancement 的完整字段字典**，含真实 JSON 样例与逐字段出处。每种类型独立成节（`R-01`~`R-29`、`D-1`~`D-17`、`W-1`~`W-11`、`T-1`~`T-4`），文末附录 Z 有中间片段索引与未核实项清单 | 要做数据驱动内容（不加 Java 代码就能加内容）时 |
| `13-tfc-api.md` | ~400 | 数据组件体系、Capability、8 个 TFC 事件 + 40 个全局事件清单、气候/日历 API、`Helpers` 方法速查、交互扩展 | 要写 Java 代码调用 TFC 时 |
| `20-addon-scaffold.md` | ~450 | **可落盘的工程脚手架**：Gradle 三件套、`neoforge.mods.toml`、主类、方块/物品/BE/菜单/屏幕/配方/组件/能力/网络注册模板 | **动手写模组时照抄这份** |
| `30-firmalife-api.md` | ~2800 | Firmalife 3.0.14 全量调研：注册清单、TFC 集成点、可复用与**不可复用**的扩展点、3 套可编译骨架 | 要扩展或参考 Firmalife 的实现时 |
| `40-patchouli-api.md` | ~2400 | Patchouli 1.21.1-93 全字段字典：book/category/entry、16 个内置 page 类型、模板系统、flag、多块、Java API | 要写游戏内手册时 |
| `50-tfc-patchouli-integration.md` | ~350 | TFC 的配方展示页与多块预览是怎么做的、**如何复刻**（模板 JSON + `patchouli:custom` + `registerMultiblock`） | 要做出 TFC 风格的书籍页面时 |
| `60-plants-crops-addon-guide.md` | ~700 | **在 TFC 中新增 作物 / 果树 / 灌木 / 棕榈式植物的完整方案**：TFC 五套植物体系剖析、构造器可见性实测表、五套已编译验证的代码骨架、BE 类型绑定陷阱、自然生成的 tag 挂载法 | 要往世界里加植物内容时 |
| `70-crop-implementation-plan.md` | ~460 | **⭐ 作物系统施工图**：132 种作物的完整数据表（NPK/阶段/温度/水合/产物/保质期）、6 个新方块类代码骨架、产物链模板、15 个从易到难的实施批次、15 条修正记录 | **动手加作物时照这份做** |
| `71-flora-implementation-log.md` | ~500 | **⭐ 施工日志**：`tfcflora`（TFC Farming Plus / TFC农业+）工程现状、批次 1~2.7 已实现内容、关键架构验证（为什么继承 `CropBlock` 不需要 `Crop` 枚举、**为什么 BE 类型必须自建**）、野生作物世界生成的注入链路、客户端渲染/草色/创造标签页三件必做事项、**Patchouli 农艺手册的实现与三条踩坑点**、**5 个只有实机才能发现的缺陷及其根因**、占位贴图映射表、验证记录与下一步 | **接手当前进度时先读这份** |

**推荐阅读顺序**：`10` → `11`（需要 id 时查）→ `20`（动手）→ `13`（写代码时查）→ `12`（加内容时查）
→ `70` + `60`（加作物时）→ **`71`（看当前实施进度与已验证结论）** → `50` + `40`（做手册时）。

---

## 2. 参考材料（源码与清单）

### 2.1 源码快照

| 路径 | 内容 | 获取方式 |
|---|---|---|
| `moddev/src-ref/TFC-decompiled/` | **TFC 4.2.10 完整源码**（1672 个 `.java`，8.4 MB），包结构 `net/dries007/tfc/...` | CFR 0.152 反编译实例内 jar |
| `moddev/src-ref/Firmalife/` | Firmalife v3.0.14 官方源码（git clone，detached HEAD `505bbb7253`） | `git clone --depth 1 --branch v3.0.14 https://github.com/eerussianguy/firmalife.git` |
| `moddev/src-ref/Patchouli/` | Patchouli `release-1.21.1-93` 官方源码（git clone） | `git clone --depth 1 --branch release-1.21.1-93 https://github.com/VazkiiMods/Patchouli.git` |
| `moddev/src-ref/TFC-decompiled/summary.txt` | CFR 反编译统计 | — |

> **为什么 TFC 是反编译的**：GitHub 到本机的链路实测极不稳定
> （`git clone` 三次失败于 `RPC failed / Operation too slow`，`codeload` zip 速率仅 24 KB/s，
> `raw.githubusercontent.com` 直接超时），而 Maven Central 正常（292 KB/s）。
> 因此改为从 Maven Central 下载 CFR 反编译本地 jar —— 结果是**与运行版本完全一致的源码**，
> 比拉取仓库 HEAD 更可靠。Firmalife/Patchouli 仓库较小，clone 成功，故使用官方源码。

### 2.2 清单文件（`moddev/inventory/`）

| 文件 | 内容 |
|---|---|
| `TFC.classes.txt` / `Firmalife.classes.txt` / `Patchouli.classes.txt` / `KubeJSTFC.classes.txt` | 各 jar 内全部类全名 |
| `TFC.resources.txt` / `Firmalife.resources.txt` / `Patchouli.resources.txt` | 各 jar 内全部资源路径 |
| `TFC.entries.txt` 等 | jar 条目全清单 |
| `TFC-block-ids.txt` | 4504 个 TFC 方块 id（从 blockstates 反推） |
| `TFC-item-ids.txt` | 5597 个 TFC 物品 id（从 item models 反推） |
| `api-dump/TFC-public-api.txt` | 284 个核心类的 `javap -public` 签名（371K 字符） |
| `api-dump/tfc-core-api.txt`、`tfc-recipes-registry.txt` | Firmalife 调研时额外导出的 TFC 签名 |

### 2.3 工具

| 工具 | 位置 | 用途 |
|---|---|---|
| CFR 反编译器 | `%TEMP%\cfr-0.152.jar`（可从 `https://repo1.maven.org/maven2/org/benf/cfr/0.152/cfr-0.152.jar` 重新下载） | 反编译任意模组 jar |
| `javap` | `C:\Program Files\Java\jdk-17\bin\javap.exe`（JDK 25 亦可） | 从 jar 直接读 public API 签名 |

**常用命令**：

```powershell
# 列出 jar 内某包的类
Select-String -Path moddev\inventory\TFC.classes.txt -Pattern '^net\.dries007\.tfc\.common\.recipes\.'

# 读某个类的 public API
javap -cp "mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar" -public net.dries007.tfc.util.Metal

# 反编译一个新 jar
java -Xmx3G -jar "$env:TEMP\cfr-0.152.jar" "mods\某模组.jar" --outputdir "moddev\src-ref\某模组-decompiled" --silent true
```

---

### 2.4 已验证的示例工程（`moddev/demo-mymod/`）

为验证「文档里的模板真的能编译」，按 `20-addon-scaffold.md` 的写法建了一个最小工程并**实际构建成功**：

```
demo-mymod/
├── settings.gradle            （含 BMCLAPI 镜像）
├── gradle.properties
├── build.gradle.kts           （ModDevGradle 2.0.111 + NeoForge 21.1.233 + 本地 jar 依赖 + UTF-8 编码）
└── src/main/
    ├── templates/META-INF/neoforge.mods.toml    （占位符由 ProcessResources 展开）
    └── java/com/example/mymod/
        ├── MyMod.java                            （@Mod(ModContainer, IEventBus) + DeferredRegister）
        ├── common/items/MyItems.java
        ├── common/blocks/MyBlocks.java           （RegistrationHelpers.registerBlock）
        ├── common/blocks/MyMachineBlock.java     （extends ExtendedBlock + ExtendedProperties）
        ├── common/blockentities/MyBlockEntities.java
        └── common/blockentities/MyMachineBlockEntity.java  （TickableInventoryBlockEntity）
```

**实测结果**：`gradle build` → `BUILD SUCCESSFUL in 2m 10s`，产出
`build/libs/MyMod-NeoForge-1.21.1-0.0.0-indev.jar`（8315 字节，含 6 个 class 与正确展开的 `neoforge.mods.toml`）。
这个过程确认了模板中的 `ExtendedProperties`、`RegistrationHelpers`、`TickableInventoryBlockEntity`
与 Gradle 配置均可直接使用；详见 `20-addon-scaffold.md` §3.4 的构建记录。

### 2.5 其它工作产物

| 路径 | 内容 |
|---|---|
| `moddev/jar-extract/` | TFC jar 的完整解包内容（真实 JSON/资源，可直接当普通文件读） |
| `moddev/tools/prepare-refs.ps1` | 一键重建 inventory 清单（可选反编译） |
| `moddev/tools/readjar.ps1` | 在 jar 内读/列/搜文件的辅助函数（UTF-8 已预置） |
| `moddev/docs/_work/`、`_research/` | 两份大文档的中间核查材料（更细的 JSON 全文与签名抄录） |

---

## 3. 关键结论速览（给赶时间的读者）

1. **注册入口只有两个类**：`net.dries007.tfc.TerraFirmaCraft`（`@Mod` 主类，构造器注入
   `(ModContainer mod, IEventBus bus)`）与 `net.dries007.tfc.ForgeEventHandler`（全局事件）。
2. **TFC 有七层注册**：`DeferredRegister` → 自定义 `Registry`（`NewRegistryEvent`）→
   数据包注册表（`DataPackRegistryEvent`）→ `DataComponentType` → 数据驱动 `DataManager`
   → Capability（`RegisterCapabilitiesEvent`）→ 网络包（`RegisterPayloadHandlersEvent`）。
3. **1.21 的 TFC 用 DataComponent，不用旧 NBT capability**；核心是
   `TFCComponents`（16 个组件）+ `ComponentView` 可变视图 + `ItemStackHooks` 钩子。
4. **TFC 的方块属性用自研 DSL**：`ExtendedProperties` + `ExtendedBlock`
   （`.blockEntity(...)`、`.serverTicks(...)`、`.flammableLikeLogs()` 等），比原版 `Properties` 好用得多。
5. **数据驱动是加内容的最省力路径**：28 种配方类型 + 16 类 `tfc/` 数据表，全部可纯 JSON 扩展，
   路径是 `data/<你的命名空间>/tfc/<表名>/xxx.json`（**不是** `data/tfc/...`）。
6. **配方查找用 `RecipeHelpers.getHolder(level, Supplier<RecipeType<R>>, C)`**，
   配合 TFC 的 `IRecipePredicate`/`ISimpleRecipe`/`ItemRecipe`/`BlockRecipe` 基类，比原版样板少一半。
7. **TFC 自定义页面不是注册新 page 类型**（Patchouli 也没这 API），而是
   「模板 JSON + `patchouli:custom` + 自己写 `ICustomComponent`」；多块用 `PatchouliAPI.registerMultiblock`。
8. **Patchouli 的语言规则很坑**：只在 `en_us` 目录发现文件，其它语言只能覆盖同名文件——
   只写 `zh_cn` 的条目永远不会出现。
9. **客户端类加载隔离是硬性要求**：所有 import `net.minecraft.client.*` / `vazkii.patchouli.client.*`
   的类只能在 `FMLEnvironment.dist == Dist.CLIENT` 分支里引用，否则专用服务器崩溃。
10. **Firmalife 的两处「伪扩展点」**：`SimpleItemRecipeBlockEntity` 与 `BoilingBlockEntity`
    含包私有抽象方法，**包外无法继承**——详见 `30-firmalife-api.md`。
11. **本机构建可行，但必须换源**：`maven.neoforged.net`（NeoForge 官方 maven）在本机**超时**，
    而镜像 `https://bmclapi2.bangbang93.com/maven/` 实测可用；Gradle 插件门户、Parchment、
    Maven Central、blamejared、CurseMaven 均可达。配置见 `20-addon-scaffold.md` §3.4。
    GitHub 系域名（`github.com`/`raw.githubusercontent.com`）全部不可用，**不要依赖**。

---

## 3.1 构建可行性速查

| 需要的构件 | 可用来源 | 备注 |
|---|---|---|
| `net.neoforged.moddev` 插件 | `plugins.gradle.org` | 插件本体不在 BMCLAPI 镜像里 |
| NeoForge / NeoForm | `https://bmclapi2.bangbang93.com/maven/` | 官方源本机超时 |
| Parchment 映射 | `https://maven.parchmentmc.org` | 可选（但建议） |
| Patchouli 依赖 | `https://maven.blamejared.com` | `vazkii.patchouli:Patchouli:1.21.1-92-NEOFORGE` |
| TFC 依赖 | `https://www.cursemaven.com` 或**本地 jar** | `curse.maven:terrafirmacraft-302973:8666972` |
| MC 本体与依赖库 | `piston-meta.mojang.com` + `libraries.minecraft.net` | 可达 |
| 反编译工具 CFR | `https://repo1.maven.org/maven2/org/benf/cfr/0.152/cfr-0.152.jar` | 292 KB/s |

> **离线最稳方案**：直接用 `mods/` 目录里的 `TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` 与
> `Patchouli-1.21.1-93-NEOFORGE.jar` 作为 `implementation(files(...))` 编译依赖。
> 这两个 jar 里的类名是 mojmap 官方名，可直接编译。
>
> **已实测（不是推测）**：按上述方案，配合 Gradle 缓存中已有的
> `net.neoforged:neoforge:21.1.233`、`neoform:1.21.1-20240808.144430`、`moddev-gradle:2.0.111`
> 与 `~/.gradle/jdks` 里的 Adoptium JDK 21，已在 `moddev/demo-mymod/` 跑通一次完整构建：
> `BUILD SUCCESSFUL in 2m 10s` → `build/libs/MyMod-NeoForge-1.21.1-0.0.0-indev.jar`。
> 结论：**本机的 TFC 附属模组开发链路是通的**，可以直接开始写模组。

---

## 4. 复现与维护

重新生成全部材料（假定网络可用）：

```powershell
# 1) 反编译 TFC（若已有 src-ref/TFC-decompiled 可跳过）
java -Xmx3G -jar "$env:TEMP\cfr-0.152.jar" `
  "mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar" `
  --outputdir "moddev\src-ref\TFC-decompiled" --silent true

# 2) 重新生成 id 清单
#    见 moddev/tools/prepare-refs.ps1
pwsh -File moddev\tools\prepare-refs.ps1

# 3) 重新导出 API 签名
javap -cp "mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar" -public <类全名>
```

**版本升级提醒**：TFC/Firmalife/Patchouli 每次大版本更新都可能改变
注册类字段名、组件字段、JSON 字段。若整合包升级，请以 `mods/` 里的新 jar 为准重新核对本文档，
不要沿用旧结论。

---

## 5. 文档目录一览

```
moddev/
├── docs/
│   ├── 00-README.md                        ← 本文件
│   ├── 10-tfc-overview.md
│   ├── 11-tfc-registry-catalog.md
│   ├── 12-tfc-data-driven.md
│   ├── 13-tfc-api.md
│   ├── 20-addon-scaffold.md
│   ├── 30-firmalife-api.md
│   ├── 40-patchouli-api.md
│   ├── 50-tfc-patchouli-integration.md
│   ├── 60-plants-crops-addon-guide.md
│   ├── 70-crop-implementation-plan.md     ← 作物施工图（要做什么）
│   ├── 71-flora-implementation-log.md     ← ★ 施工日志（已做了什么 + 验证证据）
│   ├── _research/                          ← 40 文档的原始签名抄录
│   └── _work/                              ← 中间材料：30 文档细表 + **12 文档的 9 个核查片段**
│                                               （00-frontmatter / d-recipe-A1~A5 / f-data-types /
│                                                e-worldgen / e-tags-misc，可逐节复核）
├── tfcflora/                               ← ★★ 正在开发的作物扩展模组（modId tfcflora）
│   ├── src/main/java/com/example/tfcflora/  （主类 / 客户端入口 / 内容注册 / 方块类）
│   ├── src/main/resources/                  （216 个 JSON：数据表 + 模型 + 语言）
│   └── tools/                              （资源生成与交叉引用校验脚本，可重复执行）
├── jar-extract/                            ← TFC jar 的完整解包内容（真实 JSON 与资源，可直接读）
├── demo-mymod/                             ← ★ 已实测构建成功的最小附属模组工程（含 build/libs/*.jar）
├── inventory/                              ← 类/资源/API 清单与数据转储
├── src-ref/                                ← 三方源码快照（TFC-decompiled / Firmalife / Patchouli）
└── tools/                                  ← 复现脚本（prepare-refs.ps1、readjar.ps1）
```

> `demo-mymod/build/` 约 78 MB，是 Gradle/NeoForm 的中间产物，**可安全删除**（下次构建会重新生成）；
> 想保留验证证据的话，只留 `build/libs/MyMod-NeoForge-1.21.1-0.0.0-indev.jar` 即可。
