package io.github.likexiang21.tfcplus.agriculture.client;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.client.renderer.CuttingBoardBlockEntityRenderer;
import io.github.likexiang21.tfcplus.agriculture.client.renderer.KnifeRackBlockEntityRenderer;
import io.github.likexiang21.tfcplus.agriculture.client.renderer.ServingPlateBlockEntityRenderer;
import io.github.likexiang21.tfcplus.agriculture.client.renderer.CookingPanBlockEntityRenderer;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgriculturePlates;
import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.world.level.block.Block;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;
import net.neoforged.neoforge.registries.DeferredHolder;

/**
 * B 层的客户端渲染层登记。
 *
 * <p>🛑 **红线 9（126 §〇.3）**：新增方块族**必须显式接进本清单**。
 *
 * <p>本类做四件事：
 * <ol>
 *   <li><b>渲染层</b>：全部方块走 {@code cutout}（带镂空/薄片）</li>
 *   <li><b>🆕 BER</b>：{@code knife_block} 的物品渲染器（用户口径：「刀架不渲染其上的物品，进行修复」）</li>
 *   <li><b>自检</b>：照 A 的 {@code [渲染层自检]} 打印方块数</li>
 *   <li><b>材质自检</b>：打印变种覆盖</li>
 * </ol>
 */
@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID, value = Dist.CLIENT)
public final class TFCAgriculturePlusClient {

    @SubscribeEvent
    public static void onClientSetup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> {
            // ① 渲染层登记：本批次的**全部**方块都要 cutout
            int cutout = 0;
            for (final DeferredHolder<Block, ? extends Block> holder : AgricultureBlocks.all()) {
                ItemBlockRenderTypes.setRenderLayer(holder.get(), RenderType.cutout());
                cutout++;
            }
            ItemBlockRenderTypes.setRenderLayer(AgriculturePlates.PLATE.get(), RenderType.cutout());

            // ② 渲染层自检
            final int total = AgricultureBlocks.all().size();
            TFCAgriculturePlus.LOGGER.info(
                "[渲染层自检] 已注册方块 {} 个，全部有归属（cutout {} / 无需登记 {}）",
                total, cutout, total - cutout);

            // ③ 运行时方块清单导出（供 tools/verify-registry.ps1 -FromLog 使用）
            //    为什么需要：材质变种是**循环生成**的，静态正则提取不到 ⇒ 运行时清单才是权威口径
            if (Boolean.getBoolean("tfcfarmingplus.dumpBlockIds")
                || Boolean.getBoolean("tfcagricultureplus.dumpBlockIds")) {
                for (final String id : AgricultureBlocks.allIds()) {
                    TFCAgriculturePlus.LOGGER.info("[BLOCK-ID] {}", id);
                }
                TFCAgriculturePlus.LOGGER.info("[BLOCK-ID] --- end of dump ({} ids) ---", total);
            }

            // ④ 材质覆盖自检
            TFCAgriculturePlus.LOGGER.info(
                "[材质自检] 木制案板 {}（TFC {} + afc {}）· 石制案板 {} · 刀具架 {} · 原木案板 {} · 石臼 {}",
                AgricultureBlocks.WOODEN_CUTTING_BOARDS.size(),
                AgricultureBlocks.TFC_WOODS.size(), AgricultureBlocks.AFC_WOODS.size(),
                AgricultureBlocks.STONE_CUTTING_BOARDS.size(),
                AgricultureBlocks.KNIFE_BLOCKS.size(),
                AgricultureBlocks.LOG_CUTTING_BOARDS.size(),
                AgricultureBlocks.MORTARS.size());
        });
    }

    /**
     * 🆕 <b>BER 注册</b> —— 用户口径：「刀架不渲染其上的物品，进行修复」。
     *
     * <p>⚠️ 这是 **mod 事件总线**（不是 forge 总线）的事件 ⇒ 本类已经挂在
     * {@code @EventBusSubscriber}（1.21.1 起自动判别总线）。
     */
    @SubscribeEvent
    public static void registerRenderers(EntityRenderersEvent.RegisterRenderers event) {
        // ① 刀具架：渲染挂在上面的工具/调料罐
        event.registerBlockEntityRenderer(
            AgricultureBlockEntities.KNIFE_BLOCK.get(),
            KnifeRackBlockEntityRenderer::new);
        // ② 🆕 案板：渲染摊在板面上的食材（用户口径：直接渲染，不是绘画/建模）
        event.registerBlockEntityRenderer(
            AgricultureBlockEntities.CUTTING_BOARD.get(),
            CuttingBoardBlockEntityRenderer::new);
        // ③ 🆕 原木案板（同一个 BE 类，另注册一次）
        event.registerBlockEntityRenderer(
            AgricultureBlockEntities.LOG_CUTTING_BOARD.get(),
            CuttingBoardBlockEntityRenderer::new);
        event.registerBlockEntityRenderer(AgriculturePlates.PLATE_BE.get(), ServingPlateBlockEntityRenderer::new);
        event.registerBlockEntityRenderer(AgricultureBlockEntities.COOKING_PAN.get(), CookingPanBlockEntityRenderer::new);
    }

    private TFCAgriculturePlusClient() {}
}
