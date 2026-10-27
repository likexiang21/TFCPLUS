# K3 烤炉计时与黄油蛋糕修复记录（2026-10-22）

## 用户实机反馈

- 已有烤炉配方中的未烤制食品不能得到完全烤熟的对应产物。
- 烘烤应在达到“灼热”目标温度后连续计时；降到门槛以下就取消本次进度，再升温须重新开始。
- 奶油容器与其他模组交互有冲突；改用黄油块右键案板上的蛋糕坯制作奶油蛋糕。

## 排查结论

本项目的 15 个 `firmalife:oven` 配方本来已有 600/1200/2400 tick 的等待时间和 400°C 门槛，但其原料缺少 TFC `item_heat` 数据。Firmalife 3.0.15 烤炉的逐格服务器逻辑先取得物品的 `IHeat`，只有取得成功才会加热、累计 `cookTicks` 并生成产物。因此“有烤炉 JSON 配方”仍不足以让原料烤熟。

Firmalife 自带计时器在温度不足时暂停，不清除原进度。本次只对本模组这 15 种现有烤炉原料增加低温清零，不改 Firmalife 其他食品的规则。温度判断采用**物品自身温度 400°C**，与这 15 个配方的 `temperature` 一致；达到 400°C 时开始计时，低于 400°C 即归零。

## 修改内容

1. 为未烤制蛋糕坯、小蛋糕、甜煎饼，以及六种谷物各自的烤馕和小圆面包建立 15 份 TFC `item_heat` 数据，热容量采用 Firmalife 原版烤炉原料所用的 `1.0`。
2. 保留 Firmalife 烤炉配方与逐格计时、现有等待时长；用窄范围 Mixin 在其服务器 tick 后检查**本模组这 15 种**原料的温度，低于门槛时将对应槽位 `cookTicks` 清零并保存。其他原料、其他槽位不受影响。
3. 案板上有 `food/cake_base` 时，手持一块本模组 `butter_block` 右键，消耗一块并产出可放置的 `cream_cake`；创造模式不消耗。巧克力蛋糕交互保持现有规则，奶油流体容器分支移除。
4. 修正甜煎饼产量：案板本就一次给两份未烤制甜煎饼；烤炉每份原料应产出一份熟甜煎饼，避免两份原料烤出四份。
5. 更新中英文帕秋莉厨房页面中的烤炉规则与蛋糕装饰说明。

用户已确认：本轮只修复现有的 15 种烤制配方。生面圈 `raw_bagel` 和未烤制披萨饼 `raw_pizza` 先前被定义为后续功能的中间物，当前没有对应熟制物品或烤炉配方，继续留待后续开发。用户同时确认物品达到 **400°C**（“灼热***”阶段）开始计时，沿用现有配方门槛；低于 400°C 清零。

## 构建与交付范围

- 已执行 Gradle `classes` 与 `jar`（离线），均成功；构建输出有 3 条既有过时 API 警告，未阻断编译。
- 新 JAR：`moddev/tfcagricultureplus/build/libs/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`，SHA-256 `41B59906EB2836A9E3AAC935921566ED48777998E59E0FCB30A9E0C06C73B5A6`。
- 已替换工作区 `mods` 与 `D:\TFC农业重置\PCL_TFC\mods` 中的 B 模组 JAR；两份旧 JAR 备份在 `moddev/backups/oven-timer-butter-cake-20261022/`。
- 尚未生成新的 PCL 整合包，也没有改动用户已导入的 v6 实例。用户需在当前 PCL 实例的 `mods` 目录中将旧 B JAR 换为上述新 JAR，且保持目录中只有一份同名模组；以后若重新打包整合包，必须先读 215 号打包记录。
- 尚未进行 Minecraft 实机测试。Mixin 能否在用户完整整合包中正常加载、15 种物品是否逐一完成烤制、降温清零与黄油块消耗，均待实机验收；编译通过不等于运行通过。

## 下次实机确认顺序

1. 用更新后的 B JAR 启动至主菜单，确认没有 Mixin 加载错误。
2. 分别检查蛋糕坯、小蛋糕、甜煎饼、任一谷物烤馕、任一谷物小圆面包：能放进烤炉；物品温度到 400°C 后约 60/60/60/120/30 秒得到对应成品。
3. 在计时途中使物品温度跌破 400°C，再升温，确认时间从头计算；四个烤炉槽位分别处理。
4. 蛋糕坯放案板后用黄油块右键，确认消耗一块、得到奶油蛋糕；奶油容器不再触发该分支；巧克力糊仍能制作巧克力蛋糕。
5. 两份未烤制甜煎饼应最终得到两份熟甜煎饼，不应翻倍。

实现参考：[Firmalife 1.21.x 烤炉服务端计时逻辑](https://github.com/eerussianguy/firmalife/blob/1.21.x/src/main/java/com/eerussianguy/firmalife/common/blockentities/OvenTopBlockEntity.java)、[烤炉配方温度与时长接口](https://github.com/eerussianguy/firmalife/blob/1.21.x/src/main/java/com/eerussianguy/firmalife/common/recipes/OvenRecipe.java)、[NeoForge 1.21.1 Mixin 配置格式](https://docs.neoforged.net/docs/1.21.1/gettingstarted/modfiles/)。本模组仅按接口加入独立实现，没有复制 Firmalife 的烤炉代码。
