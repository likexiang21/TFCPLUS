package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * B 层自建的创造模式页。
 *
 * <p>🛑 约束（126 §2.2）：**A 的创造页不开钩子** —— B 不往 A 的页里塞东西，
 * 而是自建一页（这样 A 单独运行时完全无感，符合红线 4"A 不得为 B 预埋钩子"）。
 *
 * <p>⚠️ 材质变种很多（案板 55 + 刀具架 34）⇒ **按"材质组"分批加入**，
 * 否则创造页会被 89 个变种刷屏。当前做法：**TFC 木材全加 · afc 木材全加 · 岩石全加**，
 * 但用一个子页（后续批次做分组）—— 现阶段先全量加入，保证"能拿到"。
 */
public final class MyCreativeTab {

    public static final DeferredRegister<CreativeModeTab> CREATIVE_TABS =
        DeferredRegister.create(Registries.CREATIVE_MODE_TAB, TFCAgriculturePlus.MOD_ID);

    /** 主创造页。 */
    public static final DeferredHolder<CreativeModeTab, CreativeModeTab> MAIN =
        CREATIVE_TABS.register("main", () -> CreativeModeTab.builder()
            .title(Component.translatable("itemGroup." + TFCAgriculturePlus.MOD_ID + ".main"))
            // TODO 批次 5 起换成本模组的代表物（目前用原版面包占位）
            .icon(() -> new ItemStack(net.minecraft.world.item.Items.BREAD))
            .displayItems((params, output) -> {
                // ---------------- 批次 1：按材质组加入 ----------------

                // ① 🆕 原木案板（34）—— 早期使用（不需要锯）
                for (final String wood : MyBlocks.TFC_WOODS) {
                    output.accept(MyBlocks.LOG_CUTTING_BOARDS.get("log_cutting_board/" + wood).get());
                }
                for (final String wood : MyBlocks.AFC_WOODS) {
                    output.accept(MyBlocks.LOG_CUTTING_BOARDS.get("log_cutting_board/" + wood).get());
                }

                // ② 木制案板（TFC 20 + afc 14）
                for (final String wood : MyBlocks.TFC_WOODS) {
                    output.accept(MyBlocks.WOODEN_CUTTING_BOARDS.get("cutting_board/" + wood).get());
                }
                for (final String wood : MyBlocks.AFC_WOODS) {
                    output.accept(MyBlocks.WOODEN_CUTTING_BOARDS.get("cutting_board/" + wood).get());
                }

                // ③ 石制案板（21 岩石）
                for (final String rock : MyBlocks.TFC_ROCKS) {
                    output.accept(MyBlocks.STONE_CUTTING_BOARDS.get("cutting_board/" + rock).get());
                }

                // ④ 刀具架（TFC 20 + afc 14）
                for (final String wood : MyBlocks.TFC_WOODS) {
                    output.accept(MyBlocks.KNIFE_BLOCKS.get("knife_block/" + wood).get());
                }
                for (final String wood : MyBlocks.AFC_WOODS) {
                    output.accept(MyBlocks.KNIFE_BLOCKS.get("knife_block/" + wood).get());
                }

                // ⑤ 石臼（14 种硬质岩石 —— 已按用户口径排除燧石）
                for (final String rock : MyBlocks.MORTAR_ROCKS) {
                    output.accept(MyBlocks.MORTARS.get("mortar/" + rock).get());
                }
                // ⑥ 第一台持续加工设备：木制干燥架（34）
                for (final String wood : MyBlocks.TFC_WOODS) {
                    output.accept(MyBlocks.DRYING_RACKS.get("drying_rack/" + wood).get());
                }
                for (final String wood : MyBlocks.AFC_WOODS) {
                    output.accept(MyBlocks.DRYING_RACKS.get("drying_rack/" + wood).get());
                }

                // ⑦ K1 厨房骨架：六类家具各覆盖 34 种木材
                for (final String wood : MyBlocks.TFC_WOODS) addKitchenWood(output, wood);
                for (final String wood : MyBlocks.AFC_WOODS) addKitchenWood(output, wood);

                // ⑦ 🆕 石杵（打制工具：黑曜石 + 6 种硬质散石）
                output.accept(MyItems.OBSIDIAN_PESTLE.get());
                output.accept(MyItems.BASALT_PESTLE.get());
                output.accept(MyItems.GRANITE_PESTLE.get());
                output.accept(MyItems.DIORITE_PESTLE.get());
                output.accept(MyItems.GABBRO_PESTLE.get());
                output.accept(MyItems.QUARTZITE_PESTLE.get());
                output.accept(MyItems.SLATE_PESTLE.get());
                // ⑦ 第一批石臼产物
                for (final var spice : MyItems.allGroundSpices()) {
                    output.accept(spice.get());
                }
                // ⑧ 第一批案板预处理产物
                for (final var preparation : MyItems.allBoardPreparations()) {
                    output.accept(preparation.get());
                }
                output.accept(MyBlocks.COOKING_PAN.get());
                output.accept(MyItems.PAN_SEASONED_VEGETABLES.get());
                // K3 面团成型台和通用自定义面团已下线；加工入口统一迁移到案板。
                output.accept(MyItems.CAKE_DOUGH.get());
                output.accept(MyItems.RAW_CAKE_BASE.get());
                output.accept(MyItems.RAW_CUPCAKE.get());
                output.accept(MyItems.CAKE_BASE.get());
                output.accept(MyItems.CUPCAKE.get());
                output.accept(MyItems.RAW_SWEET_PANCAKE.get());
                output.accept(MyItems.SWEET_PANCAKE.get());
                output.accept(MyItems.RAW_BAGEL.get());
                output.accept(MyItems.RAW_PIZZA.get());
                output.accept(MyItems.NOODLES.get());
                for (final var item : MyItems.RAW_NAAN.values()) output.accept(item.get());
                for (final var item : MyItems.NAAN.values()) output.accept(item.get());
                for (final var item : MyItems.RAW_BUN.values()) output.accept(item.get());
                for (final var item : MyItems.BUN.values()) output.accept(item.get());
                output.accept(MyBlocks.WHOLE_PIE.get());
                output.accept(MyItems.PIE_SLICE.get());
                output.accept(MyBlocks.CREAM_CAKE.get());
                output.accept(MyBlocks.CHOCOLATE_CAKE.get());
                output.accept(MyItems.CAKE_SLICE.get());
                output.accept(MyBlocks.WHOLE_CHEESE.get());
                output.accept(MyItems.CHEESE_SLICE.get());
                output.accept(MyBlocks.BUTTER_BLOCK.get());
                output.accept(MyItems.BUTTER_SLICE.get());
                output.accept(MyBlocks.JELLY_BLOCK.get());
                output.accept(MyItems.JELLY_SLICE.get());
                output.accept(MyBlocks.SUGAR_BLOCK.get());
                output.accept(MyItems.SUGAR_PIECE.get());
                // ⑨ 干燥架试点产物
                for (final var dried : MyItems.allDriedFoods()) {
                    output.accept(dried.get());
                }
                for (final var cocoa : MyItems.allCocoaPreparations()) {
                    output.accept(cocoa.get());
                }
                for (final var bark : MyItems.WOOD_BARK.values()) output.accept(bark.get());
                for (final var bast : MyItems.WOOD_BAST.values()) output.accept(bast.get());
                output.accept(MyItems.SAWDUST.get());
                output.accept(MyItems.SAWDUST_SOUP.get());
                output.accept(MyItems.SAWDUST_DOUGH.get());
                output.accept(MyItems.SAWDUST_BREAD.get());
                for (final var entry : com.example.tfcfarmingplus.expansion.common.timber.TimberBlocks.ALL.entrySet()) {
                    if (entry.getValue().get().asItem() != net.minecraft.world.item.Items.AIR) {
                        output.accept(entry.getValue().get());
                    }
                }
                // C1 silkworm basics. Feed inputs remain owned by Firmalife/A.
                output.accept(MyBlocks.SILKWORM_RACK.get());
                output.accept(MyItems.SILKWORM_EGG.get());
                output.accept(MyItems.SILKWORM.get());
                output.accept(MyItems.COCOON.get());
                output.accept(MyItems.ADULT_SILKWORM.get());
                output.accept(MyItems.COOKED_SILKWORM.get());
                output.accept(MyItems.SILK_THREAD.get());
            })
            .build());

    public static void register(IEventBus bus) {
        CREATIVE_TABS.register(bus);
    }

    private static void addKitchenWood(net.minecraft.world.item.CreativeModeTab.Output output, String wood) {
        output.accept(MyBlocks.KITCHEN_COUNTER_CABINETS.get("counter_cabinet/" + wood).get());
        output.accept(MyBlocks.KITCHEN_HALF_CABINETS.get("half_cabinet/" + wood).get());
        output.accept(MyBlocks.KITCHEN_SINK_CABINETS.get("sink_cabinet/" + wood).get());
        output.accept(MyBlocks.KITCHEN_SPICE_RACKS.get("spice_rack/" + wood).get());
        output.accept(MyBlocks.KITCHEN_FOOD_DISPLAYS.get("food_display/" + wood).get());
        output.accept(MyBlocks.KITCHEN_FRUIT_BOWLS.get("fruit_bowl/" + wood).get());
    }

    private MyCreativeTab() {}
}
