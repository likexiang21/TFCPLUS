# 阶段 2 P2：草莓世界生成、可可和调味入口修复

**日期：** 2026-10-12  
**范围：** 用户要求执行的前两项修复  
**状态：** 源码修改完成，A/B clean build 完成，JAR 已部署；尚未替代用户进行 L4 实机验收。

## 本批重新核对的依据

- `README.md`
- `AGENTS.md`
- `DEVELOPMENT_RULES.md`
- `HANDOVER.md`
- `INBOX.md`
- `docs/154-global-defect-audit-and-development-plan-20261010.md`
- `docs/155-phase1-tooling-baseline-20261010.md`
- `docs/156-phase2-p0-canonical-cleanup-20261010.md`
- `docs/157-phase2-p1-tfc-inventory-refactor-20261010.md`
- `C:\Users\asus\Desktop\修改建议.txt`

本批没有复制示例模组业务代码；只修改数据入口和项目已有 JEI 隐藏列表。

## 修复内容

### 1. 草莓自然生成标签

当前 Minecraft 1.21.1 的标签加载器不接受此前使用的 `remove` 字段。启动日志曾报：

```text
Couldn't read tag list tfc:feature/berry_bushes
No key values in MapLike[{"replace":false,"remove":[...]}]
```

已将项目覆盖文件改为可解析的完整标签：

- `replace: true`
- 保留当前 TFC 的其他十项浆果生成入口
- 保留当前 Firmalife 的夜影草莓与菠萝灌木入口
- 排除 `tfc:plant/strawberry_bush_patch`

草莓灌木注册 ID 没有删除，旧存档兼容策略不变。该修改只控制新世界自然生成入口。

### 2. 汤调味入口

`seasonable_soups.json` 现在同时列出当前 TFC 的五种汤，并保留 `#c:foods/soup` 作为扩展入口：

- `grain_soup`
- `fruit_soup`
- `vegetables_soup`
- `protein_soup`
- `dairy_soup`

调味配方仍然复制原汤并追加 `tfcagricultureplus:seasoned` 特性，不创建新的“调味汤”物品。

### 3. 可可和重复入口

- `cupuacu` 继续作为大花可可树的唯一产豆树，产出 `firmalife:food/cocoa_beans`。
- 干燥入口继续使用 Firmalife 的 `firmalife:dried` 特性。
- 密封桶发酵仍保留，发酵后的项目中间物仍是本项目独有的流程节点。
- 烘焙和研磨输出继续使用 `firmalife:food/roasted_cocoa_beans`、`firmalife:food/cocoa_powder`。
- 旧项目可可物品注册暂时保留用于旧存档读取，但不作为新的创造页或 JEI 入口；本批补充隐藏 `tfcagricultureplus:food/cocoa_nibs`。

干燥架状态机和项目自有干燥物品的全面清理属于下一项设备修复，本批没有宣称完成。

## 检查与构建

- A `verify.ps1`：通过，模型 16,444、贴图 7,122；交叉引用全部有效。
- B `verify-coverage-ledger.ps1`：通过，台账 201 行与资源文件 201 项一致。
- A `clean build`：成功。
- B `clean build --offline`：成功；只有既有 JEI `getIngredientVisibility()` 弃用警告。
- A 构建 JAR SHA-256：`48C909CEBB76FDA7A1740812A185FC2ED028F766E653554C04F66C48BA5268D7`
- B 构建 JAR SHA-256：`0AC2BDAB6A4B1D0693B75A8706270AB16ECC7B3A2C0206932A7D5503F639A7EA`
- 构建 JAR 与 `mods` 中部署 JAR 的 SHA-256 已逐一比对一致。

部署前旧 JAR 和本批定向修改的原始资源备份在：

```text
moddev/backups/defect-remediation-20261012-first-two-deploy/
moddev/backups/defect-remediation-20261012-first-two-preedit/
```

## 留给用户的实机验收

1. 新建世界并前往未生成区块，确认自然环境中不再出现 TFC 草莓灌木；旧存档中的已有方块仍可读取。
2. 创造模式、JEI 和 Patchouli 中确认草莓灌木隐藏，原版草莓果实和项目草莓种子仍可获得。
3. 使用蔬菜汤、水果汤、谷物汤、蛋白质汤和乳制汤分别加入姜、姜黄、黑胡椒粉，确认原汤被保留并获得 `seasoned` 特性。
4. 沿 `cupuacu → Firmalife 可可豆 → Firmalife dried → 密封桶发酵 → Firmalife 烘焙豆/可可粉` 路径逐步验证。

未完成的干燥架全面重构、木工和封窑不属于本批验收范围。
