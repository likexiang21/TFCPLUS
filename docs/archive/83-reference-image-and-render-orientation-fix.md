# 83 — 参考图失真与渲染器朝向错误（本轮纠正）

> 触发：用户两次质疑 ——「你的参考图很可能不是 tfc 原版资源」「你的渲染有问题，贴图朝向是错的」。
> **两条都成立。** 本文件记录证据、根因、已修内容，以及由此被推翻的旧结论。
> 全部结论来自 TFC jar 原始文件 + 离线渲染器标定实验，**未启动游戏**。

---

## 一、结论速览

| # | 问题 | 判定 | 状态 |
|---|---|---|---|
| 1 | 参考资源本身 | `.probe/tfc-crop/` 339 张 **SHA256 与 jar 100% 一致** → 是真原版 | 无需修 |
| 2 | 「参考图不是原版」的真因 A | TFC 大量 plant 贴图是**灰度 + `tintindex` 群系染色**，旧渲染器**忽略 tintindex** → 渲染成灰白 | **已修** |
| 3 | 「参考图不是原版」的真因 B | 旧渲染器 6 个面顶点顺序从**左下角**起，MC 规范从**左上角**起 → 4 个竖直面 + down 的 V 轴全部翻转 | **已修** |
| 4 | 权威参考 | 新建 `.probe/ref-tfc/`（自包含、可哈希核对）+ 支持 tint/face.rotation/bbox 审计的渲染器 | **已完成** |
| 5 | TFC 官方几何 | 从 jar 直接读出：fern 是**整板**、作物是 **2D X-cross**、**TFC 自己全部大幅越界** | **已确认** |
| 6 | 我方几何 | **6/27 越界、27/27 UV 非 1:1**（独立复核子代理数据，一致） | 待修（见 §5） |

---

## 二、问题 2：`tintindex` —— 灰白参考的根因

TFC 的植物贴图**大多不是彩色图**，而是灰度图，游戏里由 `tintindex:0` 乘上群系草色。

实测（`.probe/ref-tfc/assets/tfc/textures/block/plant/`）：

| 贴图 | 尺寸 | opaque | 色数 | LUM | **饱和度** | tintindex |
|---|---|---|---|---|---|---|
| `bird_nest_fern/bird_nest_fern.png` | 16×16 | 116 | 5 | 123.3 | **0.634** | 无 |
| `lady_fern/fern_single.png` | 16×16 | 88 | 25 | 140.2 | **0.000** 纯灰 | 0（8 处） |
| `sword_fern/sword_fern.png` | 32×32 | 262 | 4 | 155.0 | **0.013** | 0（24 处） |
| `ostrich_fern/ostrich_fern_fronds.png` | 32×32 | 146 | 4 | 137.8 | **0.018** | 0（20 处） |
| `athyrium_fern/single.png` | 16×16 | 70 | 21 | 151.7 | 0.308 | 无 |

- 旧渲染器 `preview-model.ps1` 完全不读 `tintindex` → 上述 3 张渲染成**灰白**。
- 我拿这张灰白图当作「TFC 蕨类风格参考」 → 用户判断「这不可能是 TFC 原版的资源」。**判断正确。**
- 对照图：`.probe/ref-tfc/out/TINT-CHECK-raw-vs-ingame.png`（左灰白 / 右草色 `#91BD59` 染色）。
- **注意**：`block/crop/*`（339 张）是**彩色**且 vanilla crop 未注册 color handler → 作物**不染色**；只有 `plant/*` 的一部分染色。两者不能混为一谈。

---

## 三、问题 3：UV 朝向 —— 渲染器把贴图上下颠倒了

### 根因
`preview-model.ps1` 原表（两个脚本同源）：
```powershell
north = @(0, 1, 5, 4);  south = @(3, 2, 6, 7)
west  = @(0, 3, 7, 4);  east  = @(1, 2, 6, 5)
up    = @(4, 5, 6, 7);  down  = @(0, 3, 2, 1)
```
每个四边形都从**左下角**开始排 uv，而 MC 的约定是**每个面从外侧看：u 向右、v 向下，`uv[0,1]` 是左上角**。

### 标定实验（决定性）
`minecraft:block/crop`（vanilla 十字几何）+ TFC `beet_5`（贴图是**下红根、上绿叶**）：
- 修复前：**红根在上、绿叶在下** → 颠倒。证据 `out/CALIB-vanilla-crop-beet5-p28.png`
- 修复后：**绿叶在上、红根在下** → 正确。证据 `out/CALIB-before-after-fix.png`

### 修复
```powershell
north = @(4, 5, 1, 0);  south = @(6, 7, 3, 2)
west  = @(4, 7, 3, 0);  east  = @(6, 5, 1, 2)
up    = @(4, 5, 6, 7);  down  = @(3, 2, 1, 0)
```
同时修了两个文件：
- `.probe/ref-tfc/render-tfc.ps1`（权威参考渲染器）
- `moddev/tfcfarmingplus/tools/preview-model.ps1`（**正式工具，一直在产出误导性预览**）

### 回归标定
四象限标定贴图（`_calib_uv.png`：UL 洋红 / UR 红 / LL 蓝 / LR 绿，`(0,0)` 白点、`(15,0)` 黑点）：
- `out/CALIB2-up-face.png`：白点在左上 → up 面 **u→+x，v→+z**（v=0 朝北）✓ 与 MC 一致
- `out/CALIB2-north-face.png`：白点在左上 → north 面 **u→+x，v→−y**（v=0 在顶）✓ 与 MC 一致

### 影响范围（必须知道）
- **受影响**：所有含**竖直面**的渲染 —— TFC `sword_fern`/`athyrium_fern`/`ostrich_fern`、**30 个 vanilla-cross 单层作物**、以及历史上任何用该工具看过的竖直面预览。
- **不受影响**：**水平板**模型（TFC `bird_nest_fern`/`lady_fern`、我方 `rosette_*`/`leafball_*`）的 up 面本来就是对的 —— 这些结论仍成立。
- ⚠️ 本轮之前所有「竖直面预览」的视觉结论**全部作废**，需用修复后的渲染器重看。

---

## 四、TFC 官方几何：从 jar 直接读出的事实

模型 JSON 由 `.probe/verify-jar/models/` 从 `mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` 原样导出，
再放入自包含参考资产 `.probe/ref-tfc/assets/tfc/models/block/`。

| 模型 | 几何 | 片数 | UV | 染色 | 旋转后包围盒 |
|---|---|---|---|---|---|
| `plant/bird_nest_fern` | **完整 16×16 水平板**，origin 在**板边缘** | 4 | `[0,0,16,16]` **1:1** | 无 | X/Z **−7.78~23.78**，Y 0~6.12 |
| `plant/lady_fern` | 完整 16×16 水平板，origin 在中心 | 4 | `[0,0,16,16]` 1:1 | 0 | X −3.31~19.31，**Y −0.71**~12.02 |
| `plant/sword_fern` | **竖直面片** 32×8 | 12 | `[16,12,0,16]` 等条带 | 0 | **Y 0~17.52** |
| `plant/athyrium_fern` | **竖直面片** 16×16 | 4 | `[0,0,16,16]` | 无 | X/Z −3.31~19.31，Y 0~11.31 |
| `plant/ostrich_fern_0` | 竖直面片 | 10 | — | 0 | X/Z −8~24，**Y 0~32**（两个方块高） |
| `crop/cabbage_age_*` | **`parent: block/crop`（vanilla 2 片对角竖直面片）** | 2 | `[0,0,16,16]` | 无 | X/Z 2.34~13.66，Y 0~16 |

**三条必须记住的推论：**
1. **TFC 的 fern 是整板，不是竖直面片** —— `bird_nest_fern` / `lady_fern` 都是 4 片整板 + **整张贴图（UV 1:1，不切条）**，靠 `face.rotation` 让每片板的贴图朝向各自外侧。
   我此前「TFC 是竖直面片、我方水平板不匹配」的结论**对 bird_nest/lady 是错的**（对 sword/athyrium 才成立）。
2. **我此前「整板会 Y<0 所以必须用半板」的实验是错的** —— 错在把 `origin` 放在板**中心**。TFC 把 origin 放在板**边缘**（`origin:[8,0,7]`，板 z 范围 −9~7），旋转后整块板只**向上**抬 0~6.12。
3. **「模型必须在 0~16 内」比 TFC 自身严格得多** —— TFC 官方模型**全部大幅越界**（最大到高 32）。用户要求「尽可能控制在一个方块以内」，我方应当做得比 TFC 干净，但不必以 TFC 为反例否定 3D 几何。

---

## 五、我方几何实测（独立复核，与子代理报告一致）

`.probe/ref-tfc/render-tfc.ps1` 逐元素 8 角点 + `rotation` 实测 27 个自有几何模型：

- **越界 6 个**：`leafball_age_4` X/Z −1.00~17.00、`leafball_age_5` −2.00~18.00、
  `rosette_age_3` −0.31~16.31、`rosette_age_4` −1.24~17.24、
  `rosette_age_5` 与 `rosette_age_5_fruiting` **−3.09~19.09**
- **UV 非 1:1：27/27**。例：`rosette_age_5` 板 **4 宽 × 12 长**，面用 `uv:[0,0,4,16]` → 沿长度压缩 12/16 = **0.75**。
- **视觉后果**（`out/AUTHORITATIVE-tfc-vs-ours.png`）：8 片 4 宽的细条在 3D 里是**深绿色的「刺」**，不是叶片；
  `lettuce_age_5` 的 head 是一个**大绿方块**，不是叶球。**这解释了「材质太简单」的一大半 —— 根因在几何，不在贴图分辨率。**

---

## 六、已验证的修复方向（实验件，未进 src）

`tfcfarmingplus:block/crop/lab_wide4_age_5`（`.probe/lab-assets/`）——
**照搬 TFC `bird_nest_fern` 结构**（4 片整板 + UV 1:1 + `face.rotation` 对齐），
但把板长 16 → **8**，使旋转后不越界：

- 结果：**bbox X[0,16] Y[0,3.06] Z[0,16] — inside-block OK**；**UV `[0,0,16,8]` 严格 1:1**
- 视觉：从「细刺」变成「叶片」。对照图 `out/LAB-wide-plate-experiment.png`
- 剩余差距：板长 8（半个方块）比 TFC 的 16 短，丛幅更紧凑 —— 这是「在方块内」的必然代价。

---

## 七、待用户拍板

1. **几何方案**：`rosette_*` / `leafball_*` 是否从「8 片 4 宽细条」改为「4+4 片 16 宽板」
   （TFC 同构、UV 严格 1:1、bbox 落在 0~16）？改则现有切条贴图设计全部作废。
2. **叶球形态**：TFC 的 `cabbage` 是 **2D X-cross + 一张彩色剪影贴图**（`out/AUTHORITATIVE-TFC-ORIGINAL-REFERENCE.png` 上排第 2 张）。
   我方给叶球加 **3D head 方块**属于**偏离 TFC 风格**。保留 3D head、还是回到 2D 剪影？
3. **30 个 vanilla-cross 单层作物**是否也换几何（换则贴图全部重画）。

---

## 八、本轮产出的工具与资产

| 路径 | 用途 |
|---|---|
| `.probe/ref-tfc/assets/` | 自包含权威参考（19 个 TFC 模型 JSON + 19 张贴图，jar 原样导出） |
| `.probe/ref-tfc/render-tfc.ps1` | 权威渲染器：`tintindex` 染色、`face.rotation`、bbox 审计、画布自适应 |
| `.probe/verify-jar/` | 从 jar 直接提取的贴图/模型，供 SHA256 核对 |
| `.probe/ref-tfc/out/AUTHORITATIVE-TFC-ORIGINAL-REFERENCE.png` | **真·TFC 原版参考**（上排作物 4 种 / 下排植物 4 种） |
| `.probe/ref-tfc/out/CALIB-before-after-fix.png` | 朝向修复前后对照 |
| `.probe/ref-tfc/out/LAB-wide-plate-experiment.png` | 宽板几何实验结果 |
| `moddev/tfcfarmingplus/tools/preview-model.ps1` | **正式工具，faceDefs 已修**（BOM 已还原，语法检查通过） |

> 两个 `.ps1` 的 BOM 均已在修改后还原，并通过 `[Parser]::ParseFile` 语法检查。
> **未启动游戏，未跑 gradle build，未改动 `src/main/resources` 任何文件。**
