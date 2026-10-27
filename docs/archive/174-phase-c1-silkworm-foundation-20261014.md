# C1：B 养蚕基础链交接

**日期：** 2026-10-14  
**状态：** 基础代码、资源和静态门禁完成；等待用户统一进行 Minecraft 实机测试。  
**范围：** B 模组 `tfcagricultureplus`

已部署 JAR：`mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`  
SHA-256：`F2377F6A306D11739B8673EAE71A360F6D387FD768426D7AF954EA7AB886C4D2`

## 本阶段已完成

### 养蚕内容

- 注册 B 自有的 `silkworm_rack`、`silkworm_egg`、`silkworm` 和 `cocoon`。
- 养蚕架使用三个方块状态：`stage=0` 空、`stage=1` 养蚕中、`stage=2` 已结茧。
- 空架右键使用蚕进入养蚕中；养蚕中接受 Firmalife `fruit_leaf` 和 A 的 `tfcfarmingplus:plant/mulberry_leaves`；消耗八份饲料后进入已结茧；空手或自动化取出蚕茧后回到空架。
- 蚕种通过 B 侧 `BlockDropsEvent` 对 A 桑树叶掉落做 5% 稀有追加，不改写 A 的源码或掉落表，也不让 A 反向依赖 B。
- 蚕种可以通过 B 的 `recipe/crafting/silkworm_hatch.json` 转为蚕。配方文件已放入当前项目实际读取的 `data/tfcagricultureplus/recipe/crafting/` 目录。

### TFC 容器接口

- `SilkwormRackBlockEntity` 继承 TFC `TickableInventoryBlockEntity<ItemStackHandler>`。
- 有明确的单槽容量、输入白名单、服务器端成长状态、保存/加载字段、客户端同步、公开 item handler 和自动化插入/取出路径。
- 养蚕架破坏时会掉落内部饲料或蚕茧；养蚕中状态还会返还一只蚕。
- 养蚕架已经加入 `MyBlockEntities.validBlocks` 和 `Capabilities.ItemHandler.BLOCK` 注册。
- 新增的 `verify-container-contract.ps1` 条目会检查养蚕架的 TFC 基类、容量策略、输入校验、注册和破坏钩子。

### 显示和说明

- 方块状态、三个阶段模型、方块物品模型和物品模型已加入 B 资源。
- 中英文语言键已加入。
- TFC Patchouli 手册新增中英文养蚕分类和基础链说明。
- B 覆盖台账已从 205 项更新为 209 项，新增四个养蚕手册文件。

## 静态验证结果

- B 边界和许可证门禁：通过。
- 工作台配方门禁：69 条木工配方通过。
- TFC 容器契约门禁：通过，包含养蚕架。
- 可选 TFC Woodworking 兼容门禁：通过。
- 34 种木工流程门禁：通过。
- 覆盖台账：209/209，通过；标签仍为 `replace: false`。
- B 资源 JSON 解析：全部通过。
- B 离线 Gradle build：成功。

## 用户实机测试清单

本阶段没有把静态结果当成实机结论。统一测试时请覆盖：

1. 创造页、JEI 和 Patchouli 是否能看到养蚕架、蚕种、蚕和蚕茧。
2. 桑树叶破坏时的蚕种稀有掉落；同时确认普通叶子、剪刀和精准采集路径没有重复或异常掉落。
3. 蚕种合成蚕；蚕对空养蚕架右键后，架子是否进入 `stage=1` 且生存模式正确消耗蚕。
4. Firmalife 果树叶和 A 桑叶是否都能喂入；错误物品是否被拒绝且不消耗。
5. 八份饲料消耗完成后是否进入 `stage=2`，模型是否切换为结茧状态。
6. 空手收茧、自动化取茧、满背包、破坏、爆炸/替换、区块卸载重载和保存重进是否保持一致。
7. 养蚕中阶段中断后重新加入饲料是否继续成长，而不是重置或重复计数。

## 已知边界和下一步

- 本阶段只完成“蚕种 → 蚕 → 养蚕架 → 蚕茧”基础链；煮茧、生丝、丝线和织绸留到养蚕实机确认后再做。
- 没有加入育种、遗传、病害、品种能力或复杂蜂群系统。
- 所有实机项目完成前，不把 C1 标记为最终发布完成；发现问题时先保留本 JAR 和复现步骤，再进入修复批次。
