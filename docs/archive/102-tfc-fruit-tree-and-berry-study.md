# 第 47 轮 P2：TFC 果树（9 物种）与浆果灌木（12 物种）贴图通读

> 用户指令：本轮选择的第二条工作线 —— **「继续学 TFC」**（`docs/99` §5-P2：果树 39 种 + 浆果灌木 12 种的贴图尚未系统通读）。
> 素材：`%TEMP%\tfcx\assets\tfc\textures\block\{fruit_tree,berry_bush}`（116 张）。
> 产物（肉眼通读用，子代理排图 + 本人逐张看）：
> - `px/TFC-FRUITTREE-STUDY.png`（1712×2518，54 格 = 9 物种 × 6 变体）
> - `px/TFC-BERRY-STUDY-1.png`（30 格：blackberry / blueberry / bunchberry / cloudberry / cranberry / dead）
> - `px/TFC-BERRY-STUDY-2.png`（32 格：elderberry / gooseberry / raspberry / snowberry / strawberry / wintergreen）
> 排图脚本：`.probe/texture-design/study-fruit-berry.ps1`（UTF-8 with BOM / 全 ASCII，`[Parser]::ParseFile` 0 错误）

---

## 一、TFC 的变体体系（这是它真正的"状态机"）

| 类别 | 变体 | 说明 |
|---|---|---|
| **果树**（9 物种） | `_branch` · `_leaves` · `_dry_leaves` · `_flowering_leaves` · `_fruiting_leaves` · `_sapling` | **六态齐全**，每物种一套 |
| **浆果灌木**（12 物种） | `_bush` / `_cane` × {∅, `dry_`, `flowering_`, `fruiting_`} | 只有 blackberry / blueberry / elderberry / raspberry **有 `_cane`**（藤枝），其余 7 种只有 `_bush` |
| **通用件** | `dead_bush` / `dead_cane` | 不分物种，只有褐色枝干线条 |

⇒ **玩家的视觉预期是被这套矩阵喂出来的**：同一棵树/丛，季节与状态变化时**换的是同一套六态中的一张**。
⇒ 我方果树/浆果若要接进去，**必须先把这套六态补齐**，而不是只画"成熟态"。

---

## 二、我看到的（逐物种，只写"看到了什么"）

### 果树（每行 6 张：branch / dry_leaves / flowering_leaves / fruiting_leaves / leaves / sapling）
- **banana**：树皮棕褐；叶子是 **32×32 的大图**（TFC 里唯一的例外）——`leaves` 是一片**带裂口的深绿宽叶**，
  `flowering_leaves` 是两三片绿大叶 + 顶部黄绿苞，`fruiting_leaves` 是三四片张开的绿大叶，`leaves_dead` 是**一片枯黄下垂的叶**；`sapling` 是绿茎小叶的小苗
- **cherry**：树皮**深紫褐**；`flowering_leaves` 是**撒满整张的亮粉色花团**；`fruiting_leaves` 绿底 +几颗**红樱桃**；`sapling` 也是粉色花团的小树
- **green_apple**：花是**浅紫白**；果是**一颗亮绿大苹果**（约 5×5，很跳）；`sapling` 是完整小树（棕干 + 绿叶 + 绿苹果）
- **lemon**：白花；果是**两颗亮黄柠檬**
- **olive**：树皮**银灰白**（一眼可辨）；花白色小点；**果与叶同色系**（灰绿底上的橄榄，几乎看不出果）——9 种里唯一"果不跳"的
- **orange**：白花；果是**两颗橙色橙子**
- **peach**：树皮灰褐；花是**桃粉色花团**；果是**橙黄桃子**
- **plum**：白花；`fruiting_leaves` 的**底色整体偏紫**（不是绿底！）+ 深紫李子
- **red_apple**：白花；果是**两颗红苹果**

**果树的六条读数**：
1. **`_flowering_leaves` 是"整张撒满花"**（不是几朵），花用物种标志色：樱桃粉 / 桃粉 / 苹果白 / 橄榄白
2. **`_fruiting_leaves` = 叶底 + 1~2 颗大果**，果**大而高饱和**（柠檬黄 / 橙 / 红 / 紫），
   例外是 **olive 的果与叶同色**（写实：橄榄本来就是灰绿）
3. **`plum` 连底色都换成紫**⇒ 变体可以改**底色**，不只是加器官
4. **`_dry_leaves` = 整张换枯褐色、形状保留**
5. **`_sapling` 是"完整的小树"**（有干、有冠、有果），**不是一株苗的点** —— 与作物苗期的语法完全不同
6. **`_branch` 是树皮纹理**，每物种一色（banana 棕褐 / cherry 深紫 / olive 银灰 / peach 灰褐）

### 浆果灌木
| 物种 | 我看到的 |
|---|---|
| **blackberry** | 绿叶丛 + 成簇**白花**；`fruiting` 是**深紫黑浆果**成串；`cane` 是细长藤枝串 |
| **blueberry** | `dry_*` 是**红褐色**（其他物种多半黄褐）；花**淡紫白**；果是**亮蓝色**（12 种里最跳的之一） |
| **bunchberry** | `bush` 是一大团深绿；花是**4 朵明显的白色大花（四瓣）**；果是**红色果簇** |
| **cloudberry** | 浅绿碎叶；`flowering` 是**大片白花几乎盖满**；果橙红 |
| **cranberry** | 深绿叶丛；**紫色小花**；果**深红** |
| **elderberry** | `flowering_bush` **大片白花**；`fruiting` 是**深紫近黑**的果 |
| **gooseberry** | 花是**品红/粉**（带黄花蕊）；果是**亮黄色大果**（几颗，极跳） |
| **raspberry** | 花**紫色**；果**红色**；`cane` 上是"枝 + 花/果"的组合 |
| **snowberry** | `dry_*` **红褐色**；花**粉色小点**；果是**白色果点**（名副其实） |
| **strawberry** | 花是**粉色四瓣花**（很明显）；果是**红色草莓** |
| **wintergreen** | 深绿叶；花**小白点**；果**鲜红** |
| **dead**（通用） | 只有**褐色枝干线条**，无叶 |

**浆果的五条读数**：
1. **`_bush` = 团状叶丛；`_cane` = 细长的藤/枝**（同一物种两种形态，不是同图换色）
2. **`flowering_*` 撒花**（数量大、成簇或盖满），**`fruiting_*` 挂果**（果大、颜色极跳）
3. **果色是物种标志**：深紫黑 / 亮蓝 / 红 / 橙红 / 深红 / 深紫 / **亮黄** / 红 / **白** / 鲜红
4. **`dry_*` 的枯色也分物种**：blueberry、snowberry 偏红褐，elderberry、gooseberry 偏黄褐，wintergreen 偏深灰绿
5. **叶丛语法与作物贴图完全一致**：深浅绿碎块 + 大量 1px 洞（"密而透"）

---

## 三、可复用的画法规律（与我方工作直接相关）

1. **变体矩阵先行**：先定"这个物种有哪几种状态"，再画 —— 每种状态都是一张**完整贴图**（不是叠加层）。
2. **花与果的"分量"要足**：TFC 的 `flowering` 是**整张撒花**、`fruiting` 的果**大而高饱和**，
   这正是我在 chili 上与 TFC 并排时看到的差距（`docs/101` §四：我方孤立 1px 白点 / 1px 细红条分量不足）。
3. **枯死 = 换色不换形**（`_dry_leaves` / `dry_*`），但**果树的 `_sapling` 枯萎后仍是小树**。
4. **同一物种的两种形态（`bush`/`cane`）要各画一张**，不能靠缩放同一张图。
5. **写实例外是允许的**：`olive` 的果与叶同色 —— TFC 并非一律"果必须跳"，**该写实的物种就写实**。
6. **`_branch`/树皮是独立贴图**：每物种一个色系（这与我方树干模型的自有几何对应）。

---

## 四、还没看的（诚实记录）
- `afc` / `Firmalife` 的同族贴图（项目硬约束：新增物种必须**三方对照**）。
- `_wild_top` / `_wild_bottom`、`melon_side` / `pumpkin_side` 等少数特殊件。
- 果树 39 种只覆盖了 TFC 自己的 9 种；其余在我方/其它模组。

---

## 五、子代理报告的两条技术发现（值得记录）

1. **素材不是全部 16×16**：`banana_leaves.png` 与 `banana_leaves_dead.png` 实为 **32×32**
   （TFC 香蕉叶本来就是大图）。⇒ **不能假设"作物/植物贴图都是 16×16"**。
2. 🐛 **PowerShell 7 的静默炸弹**：**`@($list)` 包裹 `System.Collections.Generic.List[object]` 会抛
   `ArgumentException: Argument types do not match`**（`List[string]` 与 `ArrayList` 正常）。
   项目里其它 `.ps1` 若同时用 `List[object]` + `@()` 会中招 ⇒ 改用 `ArrayList` 或 `.ToArray()`。
   （另：`ArrayList.Add()` 返回 int，必须 `[void]` 吞掉，否则污染函数返回值。）
