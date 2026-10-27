# 93 · 代码级未完成清单（交接给另一个会话）

> **用途**：可直接开工的任务清单。只收录 **代码 / 数据 / 几何 / 打包** 层面的未完成项；
> **贴图美术本身不在本文档范围**（看 `docs/91` 交接、`docs/92` 第 41 轮记录）。
>
> **取证方式**：Lead 现场实测 + 一个**只读调研子代理独立复核**，两边结论**逐条对照**过；
> 冲突处已在 §9 标注（唯一一处是死贴图数量，以本文档为准）。所有命令可复现。
> 全程**未跑 gradle、未启动游戏**（沿用用户要求）⇒ 凡运行期结论**只给判据，不给结论**。

---

## 0. 30 秒版

| 优先级 | 项目 | 一句话 |
|---|---|---|
| 🔴 P0-1 | **jar 内容陈旧**（不是缺文件） | `build/libs` 与 `mods` 的 jar 都停在 **2026-09-23 21:44**：里面的 `rosette_age_5.json` 还是**越界旧版**（`to:[10,0,20]`、uv 竖条），`lettuce/broccoli_age_0.json` 还是 117 B 的旧 wrapper（src 已是 1915 B 内嵌 elements） |
| 🔴 P0-2 | **枝条长不高（`up=false`）** | 催熟后只有 1 格主干、上方全空气 ⇒ `canBearFruit` 的 `UP && DOWN` 不成立 ⇒ **永不结果** |
| 🔴 P0-3 | **真实种植路径的"整棵树"未验证** | 只验证过 `/setblock` 摆出来的单格枝干 |
| 🟠 P1-1 | **莲座几何仍是水平零厚度面片** | 实测 `rosette_age_5.json` 8/8 element `from.y==to.y`、仅 up/down 面 |
| 🟠 P1-2 | **果实体块只在 age5 出现** | 实测 15 对 `{agave,cardoon,purslane}_age_0..4_fruiting.json` 与其非 fruiting 版**逐字节相同** |
| 🟠 P1-3 | **kale 几何与行为错配** | 模型走莲座 `rosette_age_N`，但 [MyCrops.java:434](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyCrops.java#L434) 注册的是普通 `MyCropBlock` ⇒ 无 FRUITING、无结果态 |
| 🟡 P2 | **15 张死贴图** + 23 个 BOM json + 唯一率 12 组 DUP | 见 §4 |
| ⬜ P3 | 批次 11 / 多用作物体系 / 茶咖啡加工链 / 占位美术 | 均未开工，**明确暂缓** |

---

## 1. 项目坐标与前置约束

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
# Java 源码   $v\moddev\tfcfarmingplus\src\main\java\com\example\tfcfarmingplus\   (36 个 .java)
# 资源        $v\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\
# 生成/校验   $v\moddev\tfcfarmingplus\tools\*.ps1     (37 个脚本)
# 实机工具    $v\moddev\tools\{launch-client,stop-own-client,ingame-verify}.ps1
# 构建        cd $v\moddev\tfcfarmingplus ; gradle build --console=plain
# 一键体检    & "$v\moddev\tfcfarmingplus\tools\healthcheck.ps1"
```

**实测校验状态（2026-09-26，三个脚本都跑过）**

| 脚本 | 结果 |
|---|---|
| `verify.ps1` | **exit 0**：blockstate 413 / 模型 1745 / 掉落表 412 / configured_feature 217 / placed_feature 217 / 物品模型 375 —— 「全部交叉引用有效，未发现问题」 |
| `verify-book.ps1` | **exit 0**：同名覆盖冲突 0；条目 6；跨页类型 694 页 —— 「手册校验通过」 |
| `healthcheck.ps1` | **exit 0**：「健康检查：全部通过」（但它的 jar 一致性**只比大小/时间**，抓不到 P0-1） |

> `docs/84` §四-4 记的「verify.ps1 有 4 条空名贴图警告」——**现已不复现**。

**红线（每条都踩过）**

1. **动手前先与用户确认**是否允许 `gradle build` / 启动游戏（贴图轮次的要求是"不构建、不启动"）。
2. 从 `src/main/resources` **删除**文件后**必须** `gradle clean build`。
3. `.ps1` 必须 **UTF-8 with BOM**；`edit` 会剥离 BOM，改完补 + `[Parser]::ParseFile` 检查。
4. 外部标识符（方块 ID / 属性名 / 标签）**先查定义再动手**。
5. **实机判据 = 画面里看到预期的东西**，不是"日志没报错"；命令回执逐条核对。
6. 收尾必须跑 `stop-own-client.ps1`（还原 `pauseOnLostFocus`）；只停自建实例。
7. 新增方块族要接进 `TFCFarmingPlusClient`；新增物种要闭环（种子→可种→可长→可收→有用途）。
8. 启动游戏前**必须比对 `build/libs` 与 `mods` 的 jar 时间/大小**（曾读到残缺 jar，实机报一片 `FileNotFoundException`）。

---

## 2. 🔴 P0：打包与机制

### P0-1 · jar 内容陈旧（**先做这一条**）

| 项 | 实测 |
|---|---|
| `build/libs\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` | 2 026 515 B，**2026-09-23 21:44:54** |
| `mods\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` | 同大小、同时间 |
| 文件集合 | 模型 1745 = 1745、blockstate 413 = 413（**双向差集 0**）⇒ **不是缺文件，是同名文件内容陈旧** |
| jar 内 `crop/rosette_age_5.json` | 1766 B（2026-09-23 19:42）：`"from":[6,0,8],"to":[10,0,20]`（**z=20 越界**）、uv `[0,0,4,16]`（竖条）、credit 写 `sword_fern` |
| src 内同文件 | 1992 B（2026-09-24 06:10）：宽板 `4(+4) wide plates after bird_nest_fern, bbox 0..16, uv 1:1` |
| jar 内 `crop/lettuce_age_0.json` / `broccoli_age_0.json` | **117 B / 118 B**（旧 wrapper） |
| src 内同名 | **1915 B / 1917 B**（2026-09-25 14:41，内嵌 8 个 elements） |
| 贴图集合差异 | **src 有而 jar 无 7 张**（`kale_rosette_0..5` + `kale_rosette_5_fruiting`）；**jar 内含 14 张死贴图**（`kale_leafball_*` 7 + `leafball_leafball_*` 7） |

**含义**：现在启动游戏看到的仍是 9/23 的旧几何/旧资源；9/24~9/26 的全部改动（含 600+ 贴图）**从未进过 jar**。`docs/84` §四-5 与 `docs/86` §五-3 要求的 `gradle clean build` 至今未跑。

**验收判据**：`gradle clean build` 退出码 0 → `build/libs` 时间更新 → 复制到 `mods` 后大小/时间一致 → 启动日志出现 `[渲染层自检] 已注册方块 N 个，全部有归属`、TagLoader 错误 0、无本模组的 `Unable to load model`。

### P0-2 · 果树枝条"长不高"（`up=false`）

| 项 | 内容 |
|---|---|
| 证据 | `docs/80` §8.4：催熟（`setcounter 200000` + `randomtick x3`）后只得到**一格高**成熟枝干（`down=true, up=false`），上方 5 格空气 |
| 影响 | [MyFruitingBranchBlock.java:110](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/blocks/MyFruitingBranchBlock.java#L110) 的 `canBearFruit` 要求 `UP && DOWN` ⇒ 一格高主干**永不结果** |
| 待查 | 是**催熟手法**（一次跳太远）还是 [MyGrowingFruitTreeBranchBlock](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/blocks/MyGrowingFruitTreeBranchBlock.java)（82 行）的生长逻辑 |
| 建议做法 | 改成**少量多次推进**：`randomtick 1` → probe 观察 → 重复，画一张"每次推进后的 up/down/高度"表 |
| 验收判据 | 真实种植的树苗长到 **≥3 格主干**（存在 `up=true` 的中间段），该段在物候期能推进到 `fruit=ripe` 并被右键采收 |

### P0-3 · 真实种植路径下的"整棵树"从未走通

- 证据：`docs/80` §8.6（只验过 `/setblock` 摆出的单格枝干）；`docs/79` §10.3-4（连"把作物种下去看它长什么样"都没走通）。
- 另有三处**从未人工确认**的链：`docs/74` §6.1（手动放树苗的完整体验 / 结果期右键采摘与掉落）、§14.17（作物完整生长收获流程 / 破坏成熟作物的产物与种子数量 / 果树完整生长链）。
- 验收判据：一条完整实机链：①锄地成耕地 ②播种/种苗 ③长到成熟 ④结果/可采收 ⑤采收产物进背包。

---

## 3. 🟠 P1：几何与模型（**需用户决策**）

### P1-1 · 莲座几何仍是「水平零厚度面片」

| 模型 | elements | 水平零厚度（`from.y==to.y`） | 仅 up/down | 越界 |
|---|---|---|---|---|
| `rosette_age_5.json` | 8 | **8** | 8 | 0 |
| `rosette_age_0.json` | 4 | **4** | 4 | 0 |
| `rosette_dead.json` | 4 | **4** | 4 | 0 |
| `leafball_age_5.json` | 9 | **8** | 8 | 0（第 9 个是中心体块） |

- `docs/84` 的"宽板"解决的是**板宽 4→16 / uv 1:1 / 不越界**，**没有解决"y 相同 ⇒ 零厚度 / 只朝上下"**；`docs/80` §4-2 说的"剑叶型应改竖直面片"**未落地**。
- 使用 `rosette_age_*` 的模型（实测）：`agave_*`（含 `_fruiting`）、`cardoon_*`、`purslane_*`、**`kale_age_0..5`**。
- 使用 `leafball_age_5` 的（实测）：**`cabbage / cauliflower / napa_cabbage` 各 6 龄 = 18 个模型**（⚠️ `docs/80` §4 说"被 `lettuce` 等 6 个模型共用"**已过时**，`lettuce`/`broccoli` 早已换宽板）。
- `docs/80` §5 的三个选项**要用户拍板**：**A** 改 `sword_fern` 式竖直面片 / **B** 保留水平板 + uv `rotation` + `shade:false` / **C** 只改贴图（**已证明收益有限**）。

### P1-2 · 果实体块只在 age5 出现（15 对文件逐字节相同）

- 实测：`{agave,cardoon,purslane}_age_0..4_fruiting.json`（15 个）与其非 fruiting 版**逐字节相同**；只有 `*_age_5_fruiting.json` 真的多出果块 element。
- 含义：blockstate 声明了 12 个变体（age0~5 × fruiting），但 **age0~4 的 fruiting=true 与 false 渲染完全一样** —— 属占位行为，不是崩坏。
- 待办：确认"果实体块只在成熟期出现"是**有意**还是待补；若是待补，给 age0~4 补上（几何生成器 `gen-rosette-models.ps1`）。

### P1-3 · kale 的几何与方块行为错配

- `kale_age_5.json` = `{"parent":"…/rosette_age_5","textures":{"0":"…/kale_rosette_5"}}`（莲座几何）；
- 但 [MyCrops.java:434](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyCrops.java#L434) 的 `KALE_CROP` 是 `DeferredHolder<Block, MyCropBlock>`（普通作物，`crop("kale", 5, …)`），**不是** `RosetteCropBlock`。
- 后果：kale **没有 FRUITING 物候、没有结果态**，但贴图/几何却按莲座准备（`kale_rosette_5_fruiting.png` 因此成了死资源，见 P2-1）。
- 待办：二选一并与用户确认（改注册为莲座，或把几何换回普通作物）。

### P1-4 · `agave` / `purslane` 的"新几何 + 旧贴图"中间态

- 证据：`docs/84` §二注 + §四-1；`*_rosette_*.png` 均存在且被引用，但"显示会错位"这一中间态是否解除**未核实**（需读 `.probe` 下物种报告）。

---

## 4. 🟡 P2：资源卫生

### P2-1 · **15 张死贴图**（实测：文件存在、引用数 = 0）

| 贴图 | 数量 | json/java 引用 |
|---|---|---|
| `leafball_leafball_0..5` | 6 | **0** |
| `leafball_leafball_head` | 1 | **0** |
| `kale_leafball_0..5` | 6 | **0** |
| `kale_leafball_head` | 1 | **0** |
| `kale_rosette_5_fruiting` | 1 | **0** |
| **合计** | **15** | 全部 0 |

- 对照测试（证明方法能检出引用）：`kale_rosette_5` → 1 处、`leafball_head` → 30 处、`lettuce_leafball_5` → 1 处。
- ⚠️ `docs/91` §7.4 说"15 张（含 `_6`/`_7`）"——**清单不同**：`_6`/`_7` 根本不存在，真正存在的是上面这 15 张（含两张 `_head`）。
- **旁证**：healthcheck 报 `DUP: leafball_4.png, leafball_leafball_5.png`（**MD5 完全相同**）⇒ 死贴图是从在用贴图复制来的。
- 处置：删除后**必须** `gradle clean build`；或保留并登记为"已知死资源"。

### P2-2 · 唯一率 12 组 DUP（`healthcheck.ps1` 实测）

| 目录 | 结果 | DUP 组 |
|---|---|---|
| `block/crop` | 657 张 / **649 unique** | ①`celeriac_0`=`shallot_0` ②`celeriac_1`=`shallot_1` ③`emmer_6_bottom`=`emmer_7_bottom` ④`flax_0`=`sesame_0` ⑤`flax_1`=`sesame_1` ⑥`leafball_4`=`leafball_leafball_5`(死) ⑦`mustard_greens_0`=`swiss_chard_0` ⑧`mustard_greens_1`=`swiss_chard_1` |
| `block/plant` | 21 张 / **17 unique** | ⑨`dead_berry_bush_{0,1,2}_bush` ⑩`dead_berry_bush_{0,1,2}_cane` —— **照 TFC 设计（3 stage 共用），需给 `audit-texture-uniqueness.ps1` 加白名单**，否则永远报 DUP |

> 与 `docs/92` 的**剪影重复审计**（alpha 掩码口径：657 张 / 513 剪影 / 67 组）是**两个不同口径**：
> MD5 相同 = 完全一样的贴图；掩码相同 = 剪影相同但配色不同。两者都要看。

### P2-3 · 23 个 crop 模型 json 带 UTF-8 BOM

- 实测：`models/block/crop` 下 647 个 json 中 **23 个**带 BOM（`broccoli_age_2..5`、`leafball_age_0..5`、`lettuce_age_2..5`、`rosette_age_0..5`、`rosette_age_5_fruiting`、`rosette_dead{,_young}`）。
- 影响：MC 的 Gson 能容忍，但**严格 JSON 解析器直接失败**（Node 实测 SyntaxError）⇒ 自家校验/生成工具必须先剥 BOM。

### P2-4 · 两处 UV 非 1:1（其余已全部合规）

| 位置 | 数值 | 性质 |
|---|---|---|
| `rosette_age_5_fruiting.json` 第 9 个 element（果块） | `from[6,0,6]→to[10,4,10]`，6 个面 uv 全 `[0,0,16,16]`（16×16 压进 4×4） | **全项目 crop 几何唯一 UV 非 1:1 处**，需确认是否有意 |
| `leafball_age_5.json` head 块 | `from[5,0,5]→to[11,5,11]`，uv 6×5 / 6×6 | 同上 |

- ✅ 附带修正：`docs/83` 记的「6/27 越界、27/27 UV 非 1:1」**在现 src 已不成立** —— 实测 27/27 **无越界**、angle 全部合法。
- ⚠️ `leafball_age_0/1.json` 定义了纹理槽 `"1":"…/leafball_head"` 但**没有任何 element 引用它**（无用槽）。

---

## 5. ⬜ P3：未开工 / 明确暂缓

| # | 项 | 依据 | 备注 |
|---|---|---|---|
| 1 | **批次 11 · 树冠果实 2 种** | `docs/76` L246：「⏸️ 暂缓，**不要擅自开工**」 | 需"长在树冠顶部"的附着语义 |
| 2 | **多用作物体系深化**（亚麻/苎麻/棉花：一株多产物 + 多加工链） | `docs/74` §7.1-2、L559 | 产物 `fiber/flax`、`fiber/ramie`、`cotton_boll`（非食物） |
| 3 | **茶 / 咖啡的加工链**（萎凋 / 烘焙 / 冲泡） | [MyItems.java:29-31](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyItems.java#L29-L31)「先给一个可食用的占位产物，后续加工链另做」 | 现在是"占位可食用产物" |
| 4 | **占位借用美术收口** | [MyBushes.java:46-48](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyBushes.java#L46-L48)（蔓生形态借 TFC 藤蔓）、[MyFruitTrees.java:112](moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyFruitTrees.java#L112)（果树 donor 只有 8 套） | 换自有美术时只改那些 JSON |
| 5 | **批次 8 · 温带果树 14 种「未实测」** | `docs/74` §14.1 | 与 P0-2/P0-3 一起验 |

---

## 6. 建议执行顺序（有依赖）

```
P0-1  gradle clean build → 让 jar = src（否则后面验的都是旧资源）
   ↓
P0-2  树长不高（少量多次推进定位）
   ↓
P0-3  真实种植路径的整棵树 + 作物
   ↓
P1-*  几何方案（需用户先拍板）；P1-2/P1-3 可独立修
   ↓
P2-1 死贴图清理（随时可做，但必须 clean build 收尾）
P2-3 BOM 清理（纯卫生，风险低）
   ↓
P3    等用户明确开工
```

---

## 7. 复现命令（本文档所有实测）

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
$mdl = "$v\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\models\block\crop"

# ① 几何体检：水平零厚度 / 仅上下两面 / 越界
Get-ChildItem $mdl -Filter 'rosette_*.json' | ForEach-Object {
  $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
  $flat = @($j.elements | Where-Object { $_.from[1] -eq $_.to[1] }).Count
  Write-Host ("{0}: elements={1} flat={2}" -f $_.BaseName, @($j.elements).Count, $flat)
}

# ② 果实体块是否只在 age5：15 对逐字节比对
Get-ChildItem $mdl -Filter '*_fruiting.json' | ForEach-Object {
  $b = Join-Path $mdl ($_.Name -replace '_fruiting\.json$','.json')
  if(Test-Path $b){ Write-Host ("{0} == {1} : {2}" -f $_.Name,(Split-Path $b -Leaf),
    ((Get-FileHash $_.FullName -Algorithm MD5).Hash -eq (Get-FileHash $b -Algorithm MD5).Hash)) }
}

# ③ 死贴图（15 张）引用数
$root = "$v\moddev\tfcfarmingplus\src\main\resources"
$j = Get-ChildItem $root -Recurse -File -Include '*.json','*.java'
foreach($n in 'leafball_leafball_head','kale_leafball_head','kale_rosette_5_fruiting'){
  Write-Host ("{0}: refs={1}" -f $n, ($j | Select-String -Pattern $n -SimpleMatch -List | Measure-Object).Count)
}

# ④ 打包一致性 + **jar 内容是否陈旧**（光比大小抓不到）
Get-Item "$v\moddev\tfcfarmingplus\build\libs\TFCFarmingPlus-*.jar","$v\mods\TFCFarmingPlus-*.jar" |
  Select-Object Name,Length,LastWriteTime
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead("$v\build\libs\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar")
($z.Entries | Where-Object { $_.FullName -like '*crop/rosette_age_5.json' }) | ForEach-Object { Write-Host ("jar 内: " + $_.Length + " B, " + $_.LastWriteTime) }
$z.Dispose()

# ⑤ 唯一率 / BOM
& "$v\moddev\tfcfarmingplus\tools\healthcheck.ps1"
Get-ChildItem $mdl -Filter '*.json' | ForEach-Object {
  $b=[System.IO.File]::ReadAllBytes($_.FullName)
  if($b.Length -ge 3 -and $b[0] -eq 0xEF){ Write-Host ("BOM: " + $_.Name) }
}
```

---

## 8. ⚠️ 已确认"旧文档过时"之处（以本文档实测为准）

| 旧说法 | 出处 | 实测（2026-09-26） |
|---|---|---|
| 死贴图 15 张（含 `_6`/`_7`） | `docs/91` §7.4 | 数量对，**成员不同**：真正存在的是 `leafball_leafball_0..5`+`_head`、`kale_leafball_0..5`+`_head`、`kale_rosette_5_fruiting` |
| `leafball_age_5` 被 6 个模型共用（含 `lettuce`） | `docs/80` §4、`INBOX.md` L33 | **3 个物种 × 6 龄 = 18 个模型**（cabbage / cauliflower / napa_cabbage） |
| 莲座"第二版仿 `sword_fern` / 放射叶片式" | `AGENTS.md` §四、`docs/80` §4-2 | 模型里仍是**水平零厚度面片**（`docs/80` 自己也指出该说法与文件不符） |
| 「6/27 越界、27/27 UV 非 1:1」 | `docs/83` | 现 src **0 越界**，UV 非 1:1 只剩 2 处（P2-4） |
| `verify.ps1` 有 4 条空名贴图警告 | `docs/84` §四-4 | **已不复现**，实测 0 错误 |
| `gen-trunk-fruits.ps1` | `docs/71` L3998/4221/4350、`docs/74` L2368 | 磁盘上只有 `gen-trunk-fruits.ps1.deprecated-20260923`（**已改名，勿再跑**） |
| `docs/82` 说 lettuce/broccoli 是"4 片整块板 + 四象限 head" | `docs/82` | 现 src 是 **8 片 4/5 宽窄板**（1915 B / 1917 B，2026-09-25 14:41） |
| `FastGrow` javadoc："`launch-client.ps1` 已默认带上" | `FastGrow.java:17` | `launch-client.ps1:114` 实际**已注释掉**（用户要求还原）—— 属文档未同步 |

---

## 9. 交叉验证说明（本清单的可信度）

- **取证方式**：Lead 亲自实测（几何 / 死资源 / 构建 / verify）+ 一个**只读调研子代理**独立复核（Java 标记扫描 / 文档条目 / 工具链清单 / jar 内容比对）。
- **两边一致**：几何零厚度、死资源 0 引用、jar 停在 9/23、verify 全绿、P0/P1 判定。
- **子代理补充（Lead 复核后并入）**：jar 内**逐文件内容**比对；`*_fruiting` 逐字节比对；kale 注册类型；23 个 BOM json；`gen-trunk-fruits` 改名；茶/咖啡占位；占位借用美术；`_head` 两张死贴图。
- **Lead 修正子代理/旧文档**：死贴图**成员**（非 `_6`/`_7`）；`leafball_age_5` 引用者（3 物种 18 模型，非 6 模型）。
- **仍未确认**（接手者需自行判断）：
  1. **实机验证当前到底处于什么状态** —— `docs/79` §4 说"三次实机验证通过全是假的"，`docs/80` §8.5 说"修复已验证（21:56，日志可复核）"。按时间顺序两者**不矛盾**（§8.5 更晚），但需要读游戏日志/截图才能定论。
  2. `cardoon/agave/purslane` 的"新几何 + 旧贴图"中间态是否已解除（需读 `.probe` 下物种报告）。
  3. 增量构建能否自愈 jar 陈旧（本次按要求**未运行 gradle**）。
  4. Java 侧"功能被静默禁用"式的缺口（注册漏项 / 标签漏项）—— 本次只做了文本标记扫描 + 资源交叉引用（verify 全绿），**未做"注册 ↔ 资源 ↔ 玩法闭环"的逐物种核对**。
