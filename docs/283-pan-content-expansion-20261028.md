# 283 炒锅内容扩展与“完成”表述更正

> 日期：2026-10-28
> 触发：用户指出 K2 炒锅“只填充一个占位配方就谎称完成”不合格。
> 结论：**原 K2 确实只有 1 条垂直切片配方，不能算完成。** 本批扩展为 14 条真实配方，并明确仍不等同于最终完成。

## 1. 原实现问题

- 193 号记录只新增了 `seasoned_vegetable_pan.json` 一条配方；
- 输入标签 `pan_inputs` 只覆盖 3 种 TFC 汤；
- 唯一的输出是 `pan_seasoned_vegetables`；
- 此前的 280/汇报把它写成“K2 完成静态”，这是不合格的表述；
- 没有真实的内容量，也没有把“香料”变成有意义的流程。

## 2. 本批新增内容

### 2.1 配方

新增 13 条，合计 **14 条**：

| 输入 | 香料 | 输出 | 翻炒次数 | 时间 |
|---|---|---|---:|---:|
| 8 种生肉：beef / pork / chicken / mutton / venison / bison / rabbit / duck | 研磨香料标签 | 对应 TFC `cooked_*` | 4 | 120 tick |
| 4 种生鱼：cod / salmon / bluegill / lake_trout | 研磨香料标签 | 对应 TFC `cooked_*` | 2 | 80 tick |
| 5 种生蔬菜：carrot / cabbage / onion / potato / tomato | 研磨香料标签 | `pan_seasoned_vegetables` | 3 | 100 tick |
| 3 种 TFC 汤：vegetables / grain / fruit soup | 研磨香料标签 | `pan_seasoned_vegetables` | 3 | 100 tick |

### 2.2 标签

- `pan_inputs` 扩展为 20 个输入物品：
  - 8 生肉 + 4 生鱼 + 5 生蔬菜 + 3 汤；
- 新增：
  - `foods/pan_raw_meats`；
  - `foods/pan_raw_fish`；
  - `foods/pan_vegetables`；
- `ground_spices` 继续使用 B 的 3 种香料。

### 2.3 产出语义

- 肉类/鱼类直接输出 TFC 对应的 canonical 熟食，不新增重复物品/贴图；
- 蔬菜/汤输出 B 的 `pan_seasoned_vegetables`；
- `PanRecipe.assemble` 增加 `tfcagricultureplus:seasoned` trait，使“放香料”在产物上有实际标记；
- 输出继承输入食物的新鲜度/腐烂状态。

### 2.4 手册

- 中英文 Patchouli 厨房页新增“Pan cooking”页；
- 删掉旧页里“旧面团台/融化锅只是兼容注册”的过期说法；
- 当前说明包含：放食物 → 放香料 → 空手翻炒 → 达到次数/时间 → 空手取出。

## 3. 验证

新增 `tools/verify_pan_content.py`，检查：

- 配方数量 ≥14；实际 **14**；
- 输入物品 ≥15；实际 **20**；
- 不同输出 ≥10；实际 **13**；
- 每条配方字段完整、时间/翻搅次数为正；
- recipe food 必须被 `pan_inputs` 接受；
- spice 必须属于 `ground_spices`；
- 输入/输出物品在 B/TFC/Firmalife 中有 item model；
- 所有标签解析非空。

运行结果：

```text
pan recipes=14 inputs=20 results=13
pan_inputs=20 ground_spices=3
[OK] pan recipe contract passed; runtime cooking behavior remains unverified
```

其他 B 门禁：

- `verify-container-contract`：通过；
- `verify-grain-food-processing`：通过；
- `verify-vegetable-beverage-processing`：通过；
- `check-boundaries`：通过；
- Gradle build：**BUILD SUCCESSFUL**。

## 4. 仍不能称为完成

本批只解决“配方数量是 1 个占位”的问题，**不是最终完成**：

- 没有 Minecraft 实机验证；
- 锅没有热源/燃料/耐久等更完整状态机（当前设计是独立设备）；
- 没有烹饪品质、香料差异、失败料理等扩展；
- 配方仍复用 TFC canonical 食物，B 自己的炒锅菜品体系还很小；
- 贴图仍待合作者统一重绘。

因此 283 之后 K2 的状态是：

> **内容已从占位扩展为可验证的 14 条配方，但仍是未实机的开发中批次。**

## 5. 最终产物

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,513,040 bytes
SHA-256 7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374
```

## 6. 相关文档

- K2 原始垂直切片记录：`docs/archive/193-k2-pan-vertical-slice-20261018.md`；
- B 差距报告 K2 更正：`docs/280-b-implementation-gap-vs-tech-docs-20261028.md` §4.2；
- 旧内容清理：`docs/282-cleanup-legacy-kitchen-content-20261028.md`。
