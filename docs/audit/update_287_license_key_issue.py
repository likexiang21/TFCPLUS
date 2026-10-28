from pathlib import Path

p = Path("mod_rebuild/docs/287-crop-redo-requirements-20261028.md")
t = p.read_text(encoding="utf-8")

insert_after = "### 0.3 因此正确的第一步"
idx = t.find(insert_after)
if idx < 0:
    raise SystemExit("0.3 marker missing")

license_section = """### 0.4 第二个关键阻塞：TFC 资源覆盖的 EUPL 授权链

`277 §3.2` 和 `THIRD-PARTY-ASSETS.md §1` 已经指出：

- TFC 是 **EUPL-1.2**，不是 MIT；
- A 的 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json` 是“基于 TFC 模型的资源覆盖”；
- A 的 26 个 TFC 手册文件是对 TFC `field_guide` 的修改/补译；
- A 还有 8 张 strawberry 作物贴图与 TFC **逐像素相同**；
- 项目自身许可证文本/通知缺失，`mods.toml` 却写 MIT；
- 当前状态是 **EUPL 义务未履行**。

因此，B 的 A1“29 种作物资源覆盖”不只是画图任务：

1. 覆盖 TFC 的 blockstate/model/texture/loot_table 可能构成对 TFC 资产的**修改/衍生**；
2. 直接复制/改写 TFC 模型或贴图会触发 EUPL 的源码/许可证/通知义务；
3. 项目当前没有解决 MIT 与 EUPL 的冲突，也没有 TFC 的 LICENSE/NOTICE 与来源登记；
4. 在授权链解决前，把“覆盖 TFC 作物资源”做成发布内容，属于**许可证阻断项**，不是普通实现项。

**结论：作物重做的第一道门不是美术，也不是 29 个 ID 清单，而是“A 的 TFC 跨命名空间覆盖所有权 + TFC EUPL 授权链”这两个前置问题。**

### 0.5 实测审计

用 `tfcagricultureplus/tools/audit_crop_ownership.py` 对当前树实测：

```text
A TFC crop model files: 6
  assets/tfc/models/block/crop/cabbage_age_0..5.json
B TFC crop model files: 0
A TFC Patchouli files: 26; B TFC Patchouli files: 12
A TFC tag files: 19; B TFC tag files: 4
Current exact A/B crop-model path overlap: 0
Future B 29-crop target collision:
  assets/tfc/models/block/crop/cabbage_age_0..5.json: A owns, B target would collide
```

“当前精确重叠 0”只是因为 B 还没开始写作物资源；B 一旦按 A1 写 cabbage，6 个路径就会与 A **同路径冲突**。所以不能用“当前没有重复文件”掩盖这个前置冲突。

"""

t = t[:idx] + license_section + t[idx:]

# Add license decision to unresolved list.
needle = "8. **“野外生成/标签”是否属于 B 覆盖范围**：会触碰 TFC worldgen 和标签，影响存档/兼容，必须单独确认。"
if needle not in t:
    raise SystemExit("unresolved needle missing")
t = t.replace(needle, needle + "\n9. **TFC EUPL 授权链**：B 覆盖 TFC 作物资产前，必须先解决 `277 §3.2` 的 EUPL 通知/许可证/来源登记；否则该批次不应发布。")

p.write_text(t, encoding="utf-8")
print("287 license/ownership key issue added")
