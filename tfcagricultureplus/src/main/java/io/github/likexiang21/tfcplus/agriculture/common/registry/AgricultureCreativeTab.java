package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks;
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
public final class AgricultureCreativeTab {

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
                for (final String wood : AgricultureBlocks.TFC_WOODS) {
                    output.accept(AgricultureBlocks.LOG_CUTTING_BOARDS.get("log_cutting_board/" + wood).get());
                }
                for (final String wood : AgricultureBlocks.AFC_WOODS) {
                    output.accept(AgricultureBlocks.LOG_CUTTING_BOARDS.get("log_cutting_board/" + wood).get());
                }

                // ② 木制案板（TFC 20 + afc 14）
                for (final String wood : AgricultureBlocks.TFC_WOODS) {
                    output.accept(AgricultureBlocks.WOODEN_CUTTING_BOARDS.get("cutting_board/" + wood).get());
                }
                for (final String wood : AgricultureBlocks.AFC_WOODS) {
                    output.accept(AgricultureBlocks.WOODEN_CUTTING_BOARDS.get("cutting_board/" + wood).get());
                }

                // ③ 石制案板（21 岩石）
                for (final String rock : AgricultureBlocks.TFC_ROCKS) {
                    output.accept(AgricultureBlocks.STONE_CUTTING_BOARDS.get("cutting_board/" + rock).get());
                }

                // ④ 刀具架（TFC 20 + afc 14）
                for (final String wood : AgricultureBlocks.TFC_WOODS) {
                    output.accept(AgricultureBlocks.KNIFE_BLOCKS.get("knife_block/" + wood).get());
                }
                for (final String wood : AgricultureBlocks.AFC_WOODS) {
                    output.accept(AgricultureBlocks.KNIFE_BLOCKS.get("knife_block/" + wood).get());
                }

                // ⑤ 石臼（14 种硬质岩石 —— 已按用户口径排除燧石）
                for (final String rock : AgricultureBlocks.MORTAR_ROCKS) {
                    output.accept(AgricultureBlocks.MORTARS.get("mortar/" + rock).get());
                }
                // ⑥ 第一台持续加工设备：木制干燥架（34）
                for (final String wood : AgricultureBlocks.TFC_WOODS) {
                    output.accept(AgricultureBlocks.DRYING_RACKS.get("drying_rack/" + wood).get());
                }
                for (final String wood : AgricultureBlocks.AFC_WOODS) {
                    output.accept(AgricultureBlocks.DRYING_RACKS.get("drying_rack/" + wood).get());
                }

                // ⑦ K1 厨房骨架：六类家具各覆盖 34 种木材
                for (final String wood : AgricultureBlocks.TFC_WOODS) addKitchenWood(output, wood);
                for (final String wood : AgricultureBlocks.AFC_WOODS) addKitchenWood(output, wood);

                // ⑦ 🆕 石杵（打制工具：黑曜石 + 6 种硬质散石）
                output.accept(AgricultureItems.OBSIDIAN_PESTLE.get());
                output.accept(AgricultureItems.BASALT_PESTLE.get());
                output.accept(AgricultureItems.GRANITE_PESTLE.get());
                output.accept(AgricultureItems.DIORITE_PESTLE.get());
                output.accept(AgricultureItems.GABBRO_PESTLE.get());
                output.accept(AgricultureItems.QUARTZITE_PESTLE.get());
                output.accept(AgricultureItems.SLATE_PESTLE.get());
                // ⑦ 第一批石臼产物
                for (final var spice : AgricultureItems.allGroundSpices()) {
                    output.accept(spice.get());
                }
                // ⑧ 第一批案板预处理产物
                for (final var preparation : AgricultureItems.allBoardPreparations()) {
                    output.accept(preparation.get());
                }
                output.accept(AgricultureBlocks.COOKING_PAN.get());
                // K3 面团成型台和通用自定义面团已下线；加工入口统一迁移到案板。
                output.accept(AgricultureItems.CAKE_DOUGH.get());
                output.accept(AgricultureItems.RAW_CAKE_BASE.get());
                output.accept(AgricultureItems.RAW_CUPCAKE.get());
                output.accept(AgricultureItems.CAKE_BASE.get());
                output.accept(AgricultureItems.CUPCAKE.get());
                output.accept(AgricultureItems.RAW_SWEET_PANCAKE.get());
                output.accept(AgricultureItems.SWEET_PANCAKE.get());
                output.accept(AgricultureItems.RAW_BAGEL.get());
                output.accept(AgricultureItems.RAW_PIZZA.get());
                output.accept(AgricultureItems.NOODLES.get());
                for (final var item : AgricultureItems.RAW_NAAN.values()) output.accept(item.get());
                for (final var item : AgricultureItems.NAAN.values()) output.accept(item.get());
                for (final var item : AgricultureItems.RAW_BUN.values()) output.accept(item.get());
                for (final var item : AgricultureItems.BUN.values()) output.accept(item.get());
                output.accept(AgricultureBlocks.WHOLE_PIE.get());
                output.accept(AgricultureItems.PIE_SLICE.get());
                output.accept(AgricultureBlocks.CREAM_CAKE.get());
                output.accept(AgricultureBlocks.CHOCOLATE_CAKE.get());
                output.accept(AgricultureBlocks.WHOLE_CHEESE.get());
                output.accept(AgricultureItems.CHEESE_SLICE.get());
                output.accept(AgricultureBlocks.BUTTER_BLOCK.get());
                output.accept(AgricultureBlocks.JELLY_BLOCK.get());
                output.accept(AgricultureItems.JELLY_SLICE.get());
                output.accept(AgricultureBlocks.SUGAR_BLOCK.get());
                output.accept(AgricultureItems.SUGAR_PIECE.get());
                for (final var cocoa : AgricultureItems.allCocoaPreparations()) {
                    output.accept(cocoa.get());
                }
                for (final var bark : AgricultureItems.WOOD_BARK.values()) output.accept(bark.get());
                for (final var bast : AgricultureItems.WOOD_BAST.values()) output.accept(bast.get());
                output.accept(AgricultureItems.SAWDUST.get());
                output.accept(AgricultureItems.SAWDUST_SOUP.get());
                output.accept(AgricultureItems.SAWDUST_DOUGH.get());
                output.accept(AgricultureItems.SAWDUST_BREAD.get());
                for (final var entry : io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks.ALL.entrySet()) {
                    if (entry.getValue().get().asItem() != net.minecraft.world.item.Items.AIR) {
                        output.accept(entry.getValue().get());
                    }
                }
                // C1 silkworm basics. Feed inputs remain owned by Firmalife/A.
                output.accept(AgricultureBlocks.SILKWORM_RACK.get());
                output.accept(AgricultureItems.SILKWORM_EGG.get());
                output.accept(AgricultureItems.SILKWORM.get());
                output.accept(AgricultureItems.COCOON.get());
                output.accept(AgricultureItems.ADULT_SILKWORM.get());
                output.accept(AgricultureItems.COOKED_SILKWORM.get());
                output.accept(AgricultureItems.SILK_THREAD.get());
                for (final var item : AgriculturePlates.ITEMS_BY_VARIANT.values()) output.accept(item.get());
                for (final var item : AgriculturePlates.UNFIRED_BY_VARIANT.values()) output.accept(item.get());
                output.accept(AgricultureBowls.WOOD_BOWL.get());
                output.accept(AgricultureBowls.CERAMIC_BOWL.get());
                for (final var item : AgricultureSpatulas.ALL.values()) output.accept(item.get());
                for (final var item : AgricultureSpatulas.HEADS.values()) output.accept(item.get());
                for (final var can : AgricultureItems.METAL_CANS.values()) output.accept(can.get());
            })
            .build());

    public static void register(IEventBus bus) {
        CREATIVE_TABS.register(bus);
    }

    private static void addKitchenWood(net.minecraft.world.item.CreativeModeTab.Output output, String wood) {
        output.accept(AgricultureBlocks.KITCHEN_COUNTER_CABINETS.get("counter_cabinet/" + wood).get());
        output.accept(AgricultureBlocks.KITCHEN_HALF_CABINETS.get("half_cabinet/" + wood).get());
        output.accept(AgricultureBlocks.KITCHEN_SINK_CABINETS.get("sink_cabinet/" + wood).get());
        output.accept(AgricultureBlocks.KITCHEN_SPICE_RACKS.get("spice_rack/" + wood).get());
        output.accept(AgricultureBlocks.KITCHEN_FOOD_DISPLAYS.get("food_display/" + wood).get());
        output.accept(AgricultureBlocks.KITCHEN_FRUIT_BOWLS.get("fruit_bowl/" + wood).get());
    }

    private AgricultureCreativeTab() {}
}
