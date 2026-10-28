# AR1-B：可可产物统一与旧树兼容收口（2026-10-23）

## 完成状态

本批完成源码和资源修改、静态检查、A/B 离线构建，以及工作区与 `PCL_TFC` 测试目录的成对部署。**没有启动游戏，盆栽产物、旧树续长、JEI 隐藏和手册显示仍待用户实机确认。**

任务预期复杂度为高（约 4/5），实际工作量与估计相符：涉及盆栽数据、旧树生命周期兼容、创造栏与 JEI、手册、旧生成器防回退，以及 B 构建路径修正。

## 当前问题的重新核实

1. `cupuacu` 正常枝干采收已通过注册时的产物 supplier 使用 `firmalife:food/cocoa_beans`，树叶掉落表也指向这一物品；本次保护这条既有主路径。
2. `fpt_cupuacu.json` 的盆栽产物仍为 `tfcfarmingplus:food/cupuacu`，与普通采收不一致，这是本次确认修复的实际旁路。
3. 旧 `cocoa` 有完整树苗、生长枝、成熟枝和树叶注册，树苗与树叶仍进入创造栏，JEI 只隐藏了旧果实。**但它当前的叶片季节表没有 FRUITING，成熟枝也不属于枝干结果类型。**218 号初版把它笼统称为正常可收获的第二条可可链并不严谨：它能继续种出旧树，但常规生长不产生果实；旧掉落表和存档中的已有结果态仍可能产出项目旧可可。
4. 现有中英文大花可可手册把它描述成“树叶结果”，跳转仍映射已隐藏的 `food/cupuacu`；展示图也轮播不存在于正常大花可可叶片季节表中的结果态。
5. B 干燥、发酵、烘焙、研磨已使用 Firmalife 基础产物，只有 `fermented_cocoa_beans` 是项目保留的活跃中间物。本次没有改这些配方。

## 已采用的兼容方式

不注销旧 ID，不在区块加载时批量替换方块，也不重新设计大花可可树体。

| 对象 | 本批行为 |
|---|---|
| 正常大花可可枝干采收、已有树叶掉落 | 继续使用 Firmalife 可可豆 |
| 大花可可盆景种植盆 | 改产 Firmalife 可可豆；产量、种子、营养、等级、额外树苗概率与贴图配置保留 |
| 旧 `cocoa_sapling` 注册与库存 | 保留并可读；创造栏和 JEI 隐藏；种下后沿原有树苗计时流程长成大花可可生长枝 |
| 旧 `cocoa_growing_branch` | 保留类型、状态和计时器；其成熟枝与叶片目标改为大花可可部件，后续按原生生长流程续长 |
| 已有旧成熟枝、旧树叶 | 原方块和状态保持可读；树枝砍下的树苗、树苗自身掉落和剪下的叶片改为大花可可对应物品 |
| 旧树叶保存的结果态 | 采收 supplier 和破坏掉落均指向 Firmalife 可可豆，不再产生项目旧可可果实 |
| A 的旧 cupuacu/cocoa 果实和 B 的重复基础可可物品 | 保留兼容注册、模型与食品数据，继续隐藏；不把旧存量物品自动转换、清空或重置腐烂时间 |
| B 发酵中间物 | 继续保留 `tfcagricultureplus:food/fermented_cocoa_beans` 为活跃物品 |

旧树苗和生长枝的目标切换只通过已有构造器的 `Supplier<? extends Block>` 参数完成。旧区块读取所用的方块 ID、类、方块状态属性、方块实体类型与 NBT 格式均保留；所有 49 个树种的注册名称和顺序也保持不变。实际旧树续长是否符合预期仍须用旧存档副本确认。

## 文件与权威来源

### Java 与资源

- A `common/MyFruitTrees.java`：为旧 cocoa 指定大花可可的续长目标；旧结果态的产物与 cupuacu 一样读取 Firmalife 原版可可豆。
- A `common/MyCreativeTab.java`：将旧 cocoa 树苗和树叶列入隐藏集合。
- B `compat/jei/MyJeiPlugin.java`：在既有兼容隐藏清单中追加旧树苗与树叶，沿用现有 JEI 原料可见性接口。
- A `data/firmalife/firmalife/plantable/fpt_cupuacu.json`：只改盆栽产物 ID。
- A `data/tfcfarmingplus/loot_table/blocks/plant/cocoa_{sapling,branch,leaves}.json`：只改实际产出物品，匹配旧方块的条件、工具条件、数量与爆炸规则保留。
- A 中英文 `entries/farming_plus/fruit_trees.json`：只改 cupuacu 的说明页、相邻展示页和两个退休果实映射。展示下方裸露主干的 `none → unripe → ripe`，不再把大花可可叶片画成正常结果态；其他树的页面和页码不变。

Firmalife 自己的可可豆手册映射继续归其原条目负责；A 通过大花可可树苗/树叶进入树木说明，避免争抢基础可可豆的手册跳转。

### 生成与检查工具

新增 `tools/cocoa-chain-policy.json`、`cocoa-data-policy.ps1`、`sync-cocoa-data.ps1`。policy 记录本项目认可的可可产物 ID、旧编号和中英文说明；sync 是本轮六份数据资源的定向维护入口：

```powershell
# 在 A 模块 tools 目录中执行；三种方式分别使用
.\sync-cocoa-data.ps1 -DryRun
.\sync-cocoa-data.ps1
.\sync-cocoa-data.ps1 -Check
```

先检查只会涉及六份目标文件，再写入并检查；不重新生成整批作物、模型或贴图。若出现使用旧 cocoa 树苗的盆栽数据，工具会停止并要求复核。

四个历史工具 `gen-fruit-trees.ps1`、`gen-firmalife-plantable.ps1`、`gen-patchouli-book.ps1`、`polish-book.ps1` 的旧电脑路径已移除，并加了输出边界：默认停止；显式 `-OutputRoot` 也只能指向 `moddev/.probe/generator-output` 下的独立目录。指向活跃源码、保护快照或经过符号链接/目录联接的路径会拒绝。旧果树生成器的清单输出也改到草稿目录，不再覆盖活跃 `fruit-trees-manifest.json`。

这些历史工具仅是受限的草稿工具，**没有在本批做全量生成，也不被认定为当前全部内容的可直接发布重建流水线**。其中可可规则已统一到 policy：果树/盆栽使用原版豆、排除旧 cocoa 新入口、手册使用主干结果说明。不能把其旧物种表或整批输出覆盖回用户已有资源。

既有 `verify.ps1` 对旧 cocoa 的掉落表比较增加了明确的 cupuacu 别名归一化，仅用于允许本次已审核的兼容产出；其余条件仍逐字段与 TFC 果树机制对照。

### B 构建路径

首次 B 构建通过项目根目录的 `-p` 指定子工程时，`File("../tfcfarmingplus/build/libs")` 仍按调用进程目录解析，错误地报告 A 产物不存在。已先备份，再改为 `rootProject.projectDir.resolve("../tfcfarmingplus/build/libs")`。再次从项目根目录执行同样方式的离线构建已成功。

## 检查证据

- 施工前备份 24 个文件；B 构建路径问题发现后追加构建脚本备份，合计 25 项。另记录 A/B 共 8,963 个源码/资源的哈希快照。
- 快照对比只有 9 个源码/资源变化：三份 Java、六份 JSON。6,946 个受保护的模型、贴图、方块状态、配方、方块实体登记及结果季节表文件没有变化。
- 树种注册列表 49 项保持不变；活动盆栽、掉落和 B 配方目录中没有项目重复可可基础物品作为入口或产物；没有盆栽接受旧 cocoa 树苗。
- 数据同步 dry-run 列出六份目标；写入后 `-Check` 零差异，并在 Windows PowerShell 中通过。
- 七个本批涉及的 PowerShell 文件语法检查通过；脚本使用 UTF-8 with BOM，游戏 JSON 使用 UTF-8 无 BOM。
- 四个历史生成器均已实际检查会拒绝活跃资源目录；未启动其批量写入阶段。
- A 资源检查通过：481 个 blockstate、2,073 个模型、481 个掉落表、246 个 configured feature、246 个 placed feature、435 个物品模型；196 个果树掉落表和 49 个 Firmalife 树叶 modifier 一致性检查通过。
- A 手册检查通过：十份草莓覆盖仍符合上一切片规则，24 个各语言条目实例、1,368 页的类别/物品/跳转/跨页检查通过。
- 跨命名空间台账仍为 223 项，与资源树一致；本次只修改既有跨命名空间文件，没有新增覆盖路径。
- A 与 B 离线 `jar` 均成功。B 有一条既有 JEI `getIngredientVisibility()` 待删除 API 警告，当前版本编译成功。
- 对比旧、新运行 JAR 的每个条目：A 只变动两份编译类和六份资源，B 只变动 JEI 插件编译类；未增删其他运行条目。六份 JSON 逐份与源码哈希一致。

以上是源码、静态检查和构建证据，不是游戏内交互或旧存档兼容已经验收的证明。

## 构建与部署

| 模组 | 文件 | SHA-256 |
|---|---|---|
| A | `TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` | `9032ED8147E4B356B2FC88B138F0FB0881F7C58A6FEA6270A09B06CBC69D37A7` |
| B | `TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar` | `D2483E0444B8BEA84F6A8980C238F8358E79ABDEE8F7E8BE92661596F3A1B217` |

构建产物分别在：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\build\libs
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tfcagricultureplus\build\libs
```

两份新 JAR 均已复制并核对哈希：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\mods
D:\TFC农业重置\PCL_TFC\mods
```

未重做 PCL 压缩包，也未替换其他已导入实例。若在另一个 PCL 实例验收，需成对换入上述 A/B JAR，并避免同一模组保留两份。

## 实机清单

建议在测试存档或旧存档副本中逐项确认：

1. 正常大花可可的模型、树苗生长和主干右键采收仍按此前已确认的玩法运行，产物为 Firmalife 可可豆。
2. 使用大花可可树苗的盆景种植盆，确认一次成熟产出的豆与普通采收为同一物品，额外树苗规则正常。
3. 创造栏与 JEI 搜索不出现项目旧 cocoa 树苗、旧树叶和旧基础可可果实；大花可可树苗和 Firmalife 可可豆仍可查找。
4. 原有旧树、旧树苗与旧物品库存载入无丢失；旧树苗正常计时后长出大花可可，新长成的枝干/叶片逐步接入大花可可流程。重进世界后观察续长状态。
5. 用斧头砍符合原规则的旧 cocoa 分枝，应获得大花可可树苗；直接打掉旧树苗保持原株数掉落。用剪刀取得旧树叶时，产物改为大花可可树叶。
6. 如旧存档已有结果态 cocoa 叶片，采收或破坏后得到原版可可豆，不再得到项目旧果实。
7. 两种语言的大花可可手册介绍主干采收，展示图显示下方主干果实；其他树的跳转和页面未错位。手册实际排版仍需画面确认。
8. 回归已认可加工链：原版豆干燥后带 dried 特质；250 mL 水密封一天发酵得到项目发酵豆；随后烘焙、研磨得到 Firmalife 烤豆/可可粉。该链配方本批未改，待实际回归。

## 回滚、参考与后续

完整回滚目录：

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\backups\ar1b-cocoa-20261023
```

`backup-manifest.json` 记录旧文件和哈希；`source-hashes.csv` 与 `changed-source-files.csv` 记录源码边界；构建日志保留首次 B 路径失败和修正后成功；`delivery-manifest.json` 记录交付包、两个部署目录及 JAR 内部变化清单。回滚时按备份恢复旧 Java/JSON/工具/构建脚本和成对旧 JAR，再移除本轮三份新增可可工具文件；不删除注册、存档或其他美术快照。

API/格式核对依据为本地 TFC 4.2.11 的果树构造参数、当前 Firmalife 3.0.15 的 Plantable 数据与已安装物品编号；公开接口参考 [Firmalife Plantable 的 crop/seed 数据格式及产物语义](https://github.com/eerussianguy/firmalife/blob/1.21.x/src/main/java/com/eerussianguy/firmalife/common/util/Plantable.java)。本批只调用既有构造器参数、注册表查询及已有 JEI 接口；新兼容规则和资源维护逻辑由本项目独立编写，没有搬运第三方业务代码。

AR1-B 状态：**代码与资源已完成、检查与构建通过、已部署；实机待确认。**

下一步为 **AR1-C：单格与可重复采收作物的闭环审查及修复**，任务预期复杂度 **高（约 4/5）**。从当前作物清单补齐形态矩阵，核对 TFC 历法/土壤/养分、生长成熟、采收掉落和重载延续，依证据修实际问题，不恢复已经作废的农业机制。开始前按用户要求报告复杂度，供用户配置模型。
