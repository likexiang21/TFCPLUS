# 84 — 莲座宽板几何落盘 + cardoon 贴图重绘（2026-09-24 05:55~09:00 轮次）

> 前置：用户要求「参考 TFC 的**空间结构和艺术风格**重绘贴图；每种先画代表性贴图、多轮迭代到视觉满意；
> 之后逐步推进全部；每个贴图都要用识图功能反复检查；不缩放 uv；持续运行到 09:00」。
> 本文件记录该轮次的产出、验证方式与遗留问题。贴图逐轮记录见
> `.probe/texture-design/px/CARDOON-REPORT.md`。

---

## 一、这一轮真正改掉的东西

### 1. 莲座几何：从「8 片 4 宽半板」改为「4(+4) 片 16 宽宽板」

| | 之前 | 现在 |
|---|---|---|
| 板宽 | **4** | **16** |
| 板长 | 12（越界到 −3.09~19.09） | 4→7（**bbox 严格 0~16**） |
| uv | `[0,0,4,16]`（沿长度压缩 0.75） | **`[0, 7-L1, 16, 7]` / `[0, 15-L2, 16, 15]`，严格 1:1** |
| down 面 | 与 up 相同的 uv 窗口 | **v 反转**（见 §三-1） |
| 阶段表达 | 板长 12 固定 | L1 = 4/5/6/7/7/7，L2 = 0/0/0/0/5/7 |

结构依据 `tfc:block/plant/bird_nest_fern`（4 片整板 + `face.rotation` 对齐），但把板长收到
8 以内以换取「不越界」——**TFC 自己是越界的**（`bird_nest_fern` X/Z −7.78~23.78、
`sword_fern` 高 17.52、`ostrich_fern` 高 32）。用户要求「尽可能控制在一个方块以内」，
所以本模组比 TFC 更严格。

### 2. 用户 5 条要求的落实位置

| 用户要求 | 落实 |
|---|---|
| ①每个贴图都用识图反复检查 | cardoon 迭代 13 轮，**每轮都 `read_image` 并写下"图里实际看到了什么"**（见 CARDOON-REPORT §二） |
| ②符合现实原型 + TFC 风格 | 形态按刺菜蓟（宽大斜展叶）/龙舌兰（剑叶+黑刺）/马齿苋（圆钝肉质叶+红褐茎）分别设计；量化对齐 TFC `bird_nest_fern` 基准 116 / 5 色 / LUM 123.3 |
| ③平面贴图与 3D 渲染的差距 | `render-check.ps1` 每次同时出 **2D×16 + 6 阶段 p28 + 平视 p8 + 俯视 p70**；正是靠俯视图才发现"亮十字"和"实心盘"两个纯指标看不出的问题 |
| ④不缩放 uv | 板 16 宽 ↔ uv 跨 16；板长 L ↔ uv 跨 L。**像素密度与普通方块一致** |
| ⑤子代理并行 | 派出 agave / purslane 两个子代理（同一套工具与布局规范） |

---

## 二、落盘清单（`src/main/resources`）

| 文件 | 说明 |
|---|---|
| `models/block/crop/rosette_age_0..5.json` | 宽板几何，`#0` 槽，uv 1:1，down 面 v 反转 |
| `models/block/crop/rosette_age_5_fruiting.json` | age_5 + 中心果实体块（`#1` 槽，4×4×4 @ `[6,0,6]~[10,4,10]`） |
| `models/block/crop/rosette_dead.json` / `rosette_dead_young.json` | 同结构，L1 = 5 / 3 |
| `textures/block/crop/cardoon_rosette_0..5.png` + `cardoon_rosette_5_fruiting.png` | 全部为 v13 图（**阶段差异由几何表达，贴图共用**） |

备份：`.probe/backup-rosette-20260924-060321/`（9 个旧模型）

**落盘后已从 `src` 直接渲染验证**：6 个阶段逐级生长、俯视有层次、结果态出现果实体块、
枯死态呈橙黄枯叶。证据 `.probe/ref-tfc/out/LANDED-cardoon-verify.png`。

> ⚠️ **wrapper 未改动**：`cardoon_age_*.json` / `agave_*.json` / `purslane_*.json` 只做
> `parent: rosette_age_N` + 覆盖 `#0` 贴图名。所以 **agave / purslane 目前是"新几何 + 旧贴图"，
> 显示会错位，属已知中间状态**，需按各自物种重画贴图后收口。
>
> ✅ 顺带发现：`lettuce_age_*.json` / `broccoli_age_*.json` **早在 02:57 就已经是同一套宽板方案**
> （uv `[0,L,16,8]` 1:1、down 面已反转），所以叶子几何在两类作物间已经统一，无需再改。

---

## 三、三条硬教训（用真实渲染验证，不是推理）

### 1. 零厚度板的 `down` 面必须反转 v
板 `from.to` 的 y 相同 ⇒ up 与 down 四边形**共面**，而 MC 的 down 面 v 沿 **−z**（与 up 相反）。
两边窗口一样时，down 面显示的是"叶尖↔叶根对调"的图案；在两者 z-fighting 的方块中心，
渲染出来就是一个**亮"X"十字**。为此连续误改了 4 轮贴图内容才定位到几何。
→ `down.uv = [0, V1, 16, V0]`。

### 2. 外层 uv 的 `v2` 必须是 7
采样公式 `sy = v1 + (v2−v1)·t`，`t=1` 落在板的**内端（方块中心）**。贴图分区是
y0..7 外层 / y8..15 内层，所以 `v2=8` 会**采到内层第 1 行**。故 L1、L2 上限都是 7。

### 3. 贴图必须画「稀疏细叶」，不能画「实心宽叶」
4 片板共用同一个 uv 窗口并靠 `face.rotation` 旋转到位。画实心宽叶 ⇒ 四份重复拼成
**实心圆盘**；TFC `bird_nest_fern` 俯视之所以是"星芒"，就因为它的贴图是**一丛细叶 + 叶间透明**。
这一点是靠与 TFC 原版**同角度对比**（`out/DIAG2-inner-vs-outer.png`）才发现的。

---

## 四、遗留问题（诚实记录）

1. **agave / purslane 贴图未完成** —— 两个子代理仍在迭代（purslane 已到 v3，agave 在标定），
   本轮结束时未收到它们的最终回报。它们用的是同一套工具与布局规范。
2. **cardoon 色数只有 3**（TFC 基准 5）。内层若要加最暗档会把 LUM 压到 110 以下，需要同时抬亮外层高光。
3. **叶片仍偏"折纸感"** —— 板长 8 意味着纵向只有 8 行承载一片叶；TFC 用板长 16 换来了更舒展的叶形，
   代价是越界。这是"不越界"的取舍。
4. **`verify.ps1` 有 4 条预先存在的警告**：`贴图 不存在: tfcfarmingplus:`（名字为空）。
   已用 A/B 实验确认（恢复落盘前备份后错误数不变），**不是本轮落盘引入的**，但值得单独查一次。
5. **未跑 gradle build、未启动游戏**（用户此前要求）。落盘后**必须** `gradle clean build`
   再实机复核，因为资源文件有过替换。

---

## 五、工具与产物地图

| 路径 | 用途 |
|---|---|
| `.probe/texture-design/draw-px.ps1` | 逐像素字符表 → 16×16 PNG（校验行长、打印 opaque/色数/LUM） |
| `.probe/texture-design/render-check.ps1` | 一键出验收图：2D×16 + 6 阶段 p28 + p8 + p70 |
| `.probe/texture-design/gen-lab-rosette.ps1` | 生成 6 阶段宽板 lab 模型（**含 §三 两条 uv 口径的注释**） |
| `.probe/texture-design/px/*.txt` | 各物种的逐像素设计稿（cardoon/agave/purslane/…） |
| `.probe/texture-design/px/CARDOON-REPORT.md` | cardoon 13 轮逐轮记录 |
| `.probe/ref-tfc/` | 自包含权威 TFC 参考（模型 + 贴图 + 渲染器） |
| `.probe/ref-tfc/out/DIAG-uv-direction.png` · `DIAG2-inner-vs-outer.png` | UV 方向与 TFC 形态对比的诊断图 |
| `.probe/ref-tfc/out/LANDED-cardoon-verify.png` | 落盘后从 src 渲染的验证图 |
