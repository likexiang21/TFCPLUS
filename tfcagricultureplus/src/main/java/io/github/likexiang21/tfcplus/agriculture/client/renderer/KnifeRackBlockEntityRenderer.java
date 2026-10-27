package io.github.likexiang21.tfcplus.agriculture.client.renderer;

import com.mojang.blaze3d.vertex.PoseStack;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.entity.ItemRenderer;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.core.Direction;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;

/** Direct rendering at this project's four local rack anchors, rotated by the rack facing.
 * Coordinates differ from the TFC example; the public ItemRenderer API supplies item models. See docs/131. */
public final class KnifeRackBlockEntityRenderer implements BlockEntityRenderer<KnifeRackBlockEntity> {

    /** 本项目的物品显示比例：0.5 倍。 */
    private static final float ITEM_SCALE = 0.5F;

    /**
     * 4 个格子的位置（**架面局部坐标**，north 朝向）。
     * 布局：2×2 —— 上排 2 把刀、下排 2 个调料罐（未来的调料罐正好放下面）。
     * <p>架面在 z≈0.375~0.75（见几何），物品挂在 z≈0.45 那一层。
     */
    private static final float[][] SLOT_LOCATION = {
        //  x,      y,      z
        {0.3125F, 0.6875F, 0.44F},   // 槽 0：左上
        {0.6875F, 0.6875F, 0.44F},   // 槽 1：右上
        {0.3125F, 0.3125F, 0.44F},   // 槽 2：左下
        {0.6875F, 0.3125F, 0.44F},   // 槽 3：右下
    };

    public KnifeRackBlockEntityRenderer(BlockEntityRendererProvider.Context context) {
        // 公共 ItemRenderer 由 Minecraft 客户端提供。
    }

    @Override
    public void render(KnifeRackBlockEntity be, float partialTick, PoseStack pose,
                       MultiBufferSource buffers, int packedLight, int packedOverlay) {

        if (be.getLevel() == null) {
            return;
        }

        final Direction facing = be.getBlockState().hasProperty(HorizontalDirectionalBlock.FACING)
            ? be.getBlockState().getValue(HorizontalDirectionalBlock.FACING)
            : Direction.NORTH;

        final ItemRenderer itemRenderer = Minecraft.getInstance().getItemRenderer();

        for (int slot = 0; slot < KnifeRackBlockEntity.SLOTS; slot++) {
            final ItemStack stack = be.getInventory().getStackInSlot(slot);
            if (stack.isEmpty()) {
                continue;
            }

            pose.pushPose();

            // ① 先按方块朝向旋转（把"架面局部坐标"转成世界朝向）
            pose.translate(0.5D, 0.5D, 0.5D);
            pose.mulPose(com.mojang.math.Axis.YP.rotationDegrees(-facing.toYRot()));
            pose.translate(-0.5D, -0.5D, -0.5D);

            // ② 移到本项目的局部槽位坐标
            final float[] textureOffset = SLOT_LOCATION[slot];
            pose.translate(textureOffset[0], textureOffset[1], textureOffset[2]);
            pose.scale(ITEM_SCALE, ITEM_SCALE, ITEM_SCALE);

            // ③ 画物品（用 GUI 视角最稳：工具的正面朝外）
            itemRenderer.renderStatic(stack, ItemDisplayContext.FIXED,
                packedLight, OverlayTexture.NO_OVERLAY, pose, buffers, be.getLevel(), slot);

            pose.popPose();
        }
    }
}
