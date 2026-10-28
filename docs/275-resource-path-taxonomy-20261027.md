# 275 资源路径分层（A/B models 与 textures）

> 日期：2026-10-27
> 状态：**静态完成，待实机视觉验收**。
> 范围：只移动 `models/block` 与 `textures/block`；**不动 `blockstates/` 和注册 ID**。

## 1. 约束

- `blockstates/<id-path>.json` 的查找路径由方块注册 ID 决定，移动它会改变方块状态解析路径；本批不移动。
- 模型与贴图路径不参与注册 ID，可在更新所有引用后分层。
- 本批没有改任何 `mod id`、注册 ID、资源 ID、NBT 字段或数据包 ID。

## 2. A `tfcfarmingplus`

### models/block

```text
models/block/
├── crop/          # 作物 age 模型
├── dead_crop/     # 普通作物枯死模型
├── melon/         # 整瓜 / 腐烂瓜模型（本轮从顶层移入）
├── plant/         # 果树、灌木、共享死莲座（本轮移入 dead_rosette*）
└── wild_crop/     # 野生作物模型
```

### textures/block

```text
textures/block/
├── crop/
├── dead_crop/
├── fruit_tree/
├── melon/         # 瓜类果皮贴图（本轮从顶层移入）
├── plant/
└── wild_crop/
```

### 本轮移动

- `models/block/{bottle_gourd,cantaloupe,rotten_bottle_gourd,rotten_cantaloupe,rotten_winter_melon,winter_melon}.json` → `models/block/melon/`
- `models/block/{dead_rosette,dead_rosette_young}.json` → `models/block/plant/`
- `textures/block/*_fruit_{side,top}.png`（12 张）→ `textures/block/melon/`
- 同步更新 blockstate 的 `model`、item model 的 `parent`、生成器输出路径（`gen-crops`）、死莲座共享策略/审计路径。

## 3. B `tfcagricultureplus`

```text
models/block/
├── cooking_pan/
├── cutting_board/
├── debarked_half/
├── debarked_log/
├── debarked_quarter/
├── dough_forming_table/
├── drying_rack/
├── food/
├── kitchen_storage/
├── knife_block/
├── log_cutting_board/
├── melting_pot/
├── mortar/
├── silkworm_rack/
└── timber/
```

- 顶层 18 个模型全部移入上述族目录；
- `models/item` 的 `parent`、blockstate 的 `model` 引用已同步；
- B 没有自有 `textures/block`，方块贴图仍复用 TFC/vanilla。

## 4. 验证

```powershell
python mod_rebuild\_refactor\check_resource_refs.py
# A: missing model/texture refs: 0

# B 资源引用另跑同类扫描：0 missing
```

构建：

```powershell
gradle build --console=plain --offline
```

A/B 均构建成功；A 在资源移动后重新构建。

## 5. 未做

- 资源**重命名**（如统一 `*_fruit_side` → 新命名）；
- blockstate 路径分层（受注册 ID 约束，需另做 ID 迁移）；
- 实机模型加载与视觉验收。
