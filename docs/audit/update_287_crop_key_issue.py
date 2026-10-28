from pathlib import Path

p = Path("mod_rebuild/docs/287-crop-redo-requirements-20261028.md")
t = p.read_text(encoding="utf-8")

section = """# 287 农作物重做要求归档（从既有文档提取）

> 日期：2026-10-28
> 性质：**要求摘录/归档**，不是新设计；本轮没有实现农作物重做。
> 来源：`126`（B 实现总方案，现已归档）、`117`（农业重设计计划，现已归档）、`280 §11`、`282 §5`。

## 0. 关键问题：A 已经占用了 TFC 作物资源，B 的 29 作物重做不是“从零开始”

这是上一版归档漏掉的真正关键点。

### 0.1 文档证据

`117 §〇.2.2` 明确记录：A 当前有 **6 个 TFC 作物模型覆盖**：

```text
assets/tfc/models/block/crop/cabbage_age_0.json
assets/tfc/models/block/crop/cabbage_age_1.json
assets/tfc/models/block/crop/cabbage_age_2.json
assets/tfc/models/block/crop/cabbage_age_3.json
assets/tfc/models/block/crop/cabbage_age_4.json
assets/tfc/models/block/crop/cabbage_age_5.json
```

这些文件在**当前源码里仍然存在**：

```text
mod_rebuild/tfcfarmingplus/src/main/resources/assets/tfc/models/block/crop/cabbage_age_0..5.json
```

`117 §5.5.2` 也把它们列为 A1 覆盖组（6 个），说明它们不是历史记录，而是**A 当前实际发布的资源覆盖**。

此外，A 当前还实际写入了：

- **26 个** `assets/tfc/patchouli_books/**` 手册文件（`117` 旧稿写 14，已漂移）；
- **19 个** `data/tfc/tags/**` 标签文件（`117` 旧稿写 21，已漂移）。

### 0.2 这为什么是 B 作物重做的关键阻塞

1. **TFC 的 29 种作物包含 `cabbage`（卷心菜）**。
2. B 的 A1 目标要求覆盖 `assets/tfc/models/block/crop/<name>_age_*.json`，其中 cabbage 的路径与 A 当前占用的 6 个文件**完全相同**。
3. 两个独立 jar 写同一路径时，谁生效取决于**资源包/mod 加载顺序**，不是由 B 的“A1”语义保证。可能出现：
   - A 的 cabbage 覆盖赢 ⇒ B 的 cabbage 重做看不见；
   - B 赢 ⇒ A 的 6 个 TFC 模型变成死资源，A 的“仅接入”行为被 B 隐式改变；
   - 两者在某些情况下都不完整 ⇒ TFC cabbage 回退到 TFC 原版十字模型。
4. `117 §〇.2` 的最高优先级是“先拆 A/B 包”，但**当前 A 仍拥有 TFC 作物模型**，说明拆分尚未真正完成；B 直接在 A 的路径上写资源，会破坏“A 可独立发布 / B 可独立卸载”的目标。
5. B 的 `assets/tfc` 当前只有 Patchouli（无作物模型），但 **A 的 6 个 TFC 模型不是“B 的 0”**：B 作物完成度是 0，**A 已经做了 cabbage 样板**，所以 B 的 29 作物重做不是 greenfield，而是**跨 jar 所有权迁移**。

### 0.3 因此正确的第一步

不是直接写 29 套 blockstate/model/texture，而是先决定并执行：

- A 的 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json` 是否：
  - **移交给 B**（A 删除，B 负责全部 29 种，包括 cabbage）；
  - 或 **A 保留 cabbage**（B 明确跳过 cabbage，依赖 A 作为 29 种之一）；
  - 或 **改为 B 只在无 A 时覆盖**（NeoForge 资源条件加载，复杂度高）。
- A 的 26 个 TFC Patchouli 文件与 B 的作物/浆果手册如何分家；
- A 的 19 个 TFC 标签文件与 B 的作物/浆果标签如何合并（必须 `replace=false`，不能清空 A 已有条目）。

**在这些所有权决定之前，B 的 29 作物重做不能算“已开始”，也不能直接铺资源。**

"""
# Replace the old front matter up to the first section after intro.
marker = "## 1. 归属与总目标"
idx = t.find(marker)
if idx < 0:
    raise SystemExit("marker missing")
t = section + t[idx:]

# Correct current state wording.
t = t.replace(
    "`280` §11.2 实测：\n\n- B 的 `assets/tfc/` 目前**只有 Patchouli 手册**；",
    "`280` §11.2 实测：\n\n- B 的 `assets/tfc/` 目前**只有 Patchouli 手册**；\n- 但 **A 已有 6 个 TFC cabbage 模型覆盖**、26 个 TFC 手册文件、19 个 TFC 标签文件（见 §0）；A 不是“无 TFC 资源”的干净态；",
)
t = t.replace(
    "- 没有对 `tfc:plant/*` / TFC 作物方块 ID 的注册覆盖；",
    "- 没有对 `tfc:plant/*` / TFC 作物方块 ID 的注册覆盖；\n- 但 A 已经在 TFC `assets/tfc/models/block/crop/` 中写入了 cabbage 6 个模型，所以 B 不能假设 TFC 资源是原始的；",
)
t = t.replace(
    "- **A2 要求没有进入 B 的任何已实现批次**。",
    "- **A2 要求没有进入 B 的任何已实现批次**；\n- 同时，A 的 6 个 TFC cabbage 模型是 B 29 作物重做的**同路径前置冲突**，不是无关历史。",
)

# Add ownership decisions to unresolved list.
t = t.replace(
    "1. **验收基线**：按 `126` A1 的“资源覆盖、方块类不变”，还是按 `280` 的“含野生生成/方块行为/标签/手册”系统级重做？",
    "1. **验收基线**：按 `126` A1 的“资源覆盖、方块类不变”，还是按 `280` 的“含野生生成/方块行为/标签/手册”系统级重做？\n2. **TFC cabbage 所有权**：A 现在已有 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json`；B 的 29 作物重做必须决定 A 删除移交、A 保留 B 跳过、还是做条件覆盖。\n3. **A 的 TFC 手册/标签如何与 B 合并**：A 当前有 26 个 TFC 手册文件、19 个 TFC 标签文件；B 的作物/浆果手册和标签不能直接覆盖清空。",
)
# renumber following items
for old, new in [
    ("2. **草莓命名空间**", "4. **草莓命名空间**"),
    ("3. **“6 龄”与实际变体冲突**", "5. **“6 龄”与实际变体冲突**"),
    ("4. **7 种形状的逐作物映射**", "6. **7 种形状的逐作物映射**"),
    ("5. **melon/pumpkin 特殊处理**", "7. **melon/pumpkin 特殊处理**"),
    ("6. **“野外生成/标签”是否属于 B 覆盖范围**", "8. **“野外生成/标签”是否属于 B 覆盖范围**"),
]:
    t = t.replace(old, new)

p.write_text(t, encoding="utf-8")
print("287 updated with ownership blocker")
