# 284 动态炒锅、盘子与分餐系统

> 日期：2026-10-28
> 设计基准：用户确认的三点（Cuisine Delight 参考、TFC 热源、多材料锅铲）+ 六条额外要求。
> 实现方式：只参考 Cuisine Delight 的公开行为，独立实现 B 的代码/数据；未复制其 LGPL 源码。

## 1. 用户确认的规则

1. 按食材组成生成菜品，兼容并动态调整 TFC 营养值；
2. 炒锅使用 TFC 热源；
3. 新增锅铲，多种材料；
4. 炒菜前必须加油；
5. 菜品相对丰富；
6. 菜品可摆出，方块保留保质期；
7. 盘子分木盘/陶盘，陶盘 16 色；
8. 份量由原料决定，一份对应一碗/一口；
9. 右键吃一份，潜行右键放置，打掉保留数据；
10. 木碗/陶碗可右键承装分装食用。

## 2. 已完成实现

### 2.1 炒锅

`CookingPanBlockEntity` 已重写为 Cuisine Delight 式动态状态机：

- **热源**：检查锅下方是否为 TFC `IHeatable`，温度 ≥ 200°C；无热源不能加料/翻动。
- **油**：内置 1000 mB 油罐，油类来自 `c:plantoil` 或 `firmalife:oils`；加入 100 mB 后才允许加料。
- **多食材**：最多 8 个食材槽，逐份加入；不再使用固定两输入配方。
- **每食材独立状态**：记录加入时间、上次翻炒时间，按 `c:foods/*` 标签配置生/熟/过熟/焦糊时间。
- **锅铲翻炒**：右键锅用锅铲翻动，重置所有食材的焦糊计时，消耗锅铲耐久。
- **动态评分**：raw/overcooked/burnt 扣分；食材种类提供少量多样性加成；总分 0–100。
- **动态营养**：把每个食材的 TFC `FoodData` 按份数汇总，乘质量系数，生成每份的 `FoodData`。
- **份量**：一份 = 一个加入的食材单位；菜品总份数 = 食材条目数。
- **盘子取餐**：手持盘子右键锅，把菜品写入盘子数据并清空锅内容。
- **TFC 营养**：盘子/碗食用时调用 `IPlayerInfo.eat(FoodData)`；盘子同时设置 TFC `FoodComponent` 以获得保质期。

### 2.2 锅铲

新增 6 种材料：

```text
copper / bismuth_bronze / bronze / wrought_iron / steel / black_steel
```

- 物品 ID：`tfcagricultureplus:spatula/<material>`；
- 不同耐久；
- 右击锅执行翻炒；
- 配方：对应 TFC 金属锭 + `#tfc:lumber`。

### 2.3 盘子

新增 `serving_plate` 方块，17 个变体：

```text
plate/wood
plate/ceramic_white ... plate/ceramic_black（16 色）
```

- 每盘保存完整盘子的 ItemStack（含菜品组件、TFC FoodComponent/保质期）；
- 右键盘子方块：吃一份；
- 盘子物品：右键吃一份，潜行+右键放置；
- 打掉方块：从 BE 取出盘子 ItemStack，保留菜品数据；
- 盘子内容吃空后保留空盘。

### 2.4 碗

新增两种碗：

```text
tfcagricultureplus:bowl/wood
tfcagricultureplus:bowl/ceramic
```

- 空碗/装菜碗共用同一 ID，菜品数据在组件中；
- 右键摆出的盘子，取走一份到碗中；
- 装菜碗右键食用一份，吃空后变回空碗。

### 2.5 动态菜品数据

- `PanDishData`：份数、评分、每份 `FoodData`、菜品类别、原料列表；
- 类别：meat / fish / vegetable / grain / fruit / dairy / mixed；
- 名称按类别动态翻译；
- 品质评分与 servings 显示在 tooltip；
- TFC 保质期由盘子的 `FoodComponent` 保存。

## 3. 数字

- 盘子变体：17（木 1 + 陶 16）；
- 碗：2；
- 锅铲材料：6；
- 炒锅食材槽：8；
- 油需求：100 mB；
- 热源：TFC `IHeatable` ≥ 200°C；
- 动态菜品类别：7。

## 4. 验证

- Gradle `clean build`：**BUILD SUCCESSFUL**；
- 静态合同脚本 `tools/verify_pan_system.py`：通过；
- 全资源 JSON：0 解析失败；
- 17 个盘子的 blockstate/model/texture 均存在；
- 6 个锅铲模型、2 个碗模型存在；
- 旧静态 `pan` 配方类型与配方数据已删除。

## 5. 仍未完成 / 限制

- **没有 Minecraft 实机验证**：当前环境缺少 `.tooling` 运行时，无法启动验证客户端；因此不宣称实际可用。
- 盘子食物没有独立 3D 食物层；当前只显示盘子模型（菜品数据在 tooltip/方块中）。
- 盘子/碗配方是临时配方（木盘来自 `#tfc:lumber`；陶盘/碗来自 TFC 碗转换），后续应重做。
- 炒锅没有 GUI、没有油量/食材可视层；交互全为右键。
- 没有 JEI 动态配方分类（动态成菜无法用固定配方目录展示）。
- 没有自动化输入输出、没有锅具耐久/燃料消耗。
- 没有使用 Cuisine Delight 源码；仅参考其行为。

## 6. 产物

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,565,831 bytes
SHA-256 AE2F3FECCCE390A5115BB1D937815BA084E97555C954A8556E940BDEC05124C4
```

B 当前资源：490 blockstate、520 block model、644 item model、780 recipe、489 loot、51 TFC food 定义、737 语言键。
