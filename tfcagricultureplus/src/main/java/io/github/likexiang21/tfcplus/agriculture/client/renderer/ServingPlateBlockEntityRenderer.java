package io.github.likexiang21.tfcplus.agriculture.client.renderer;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.ServingPlateBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;

/** Renders the ingredients of a plated dish on top of the plate model. */
public final class ServingPlateBlockEntityRenderer implements BlockEntityRenderer<ServingPlateBlockEntity> {
    private static final float SCALE = 0.3F;

    public ServingPlateBlockEntityRenderer(BlockEntityRendererProvider.Context context) {}

    @Override public void render(ServingPlateBlockEntity be, float partialTick, PoseStack pose,
                                 MultiBufferSource buffers, int packedLight, int packedOverlay) {
        if (be.getLevel() == null) return;
        final PanDishData dish = PanDishData.read(be.plateStack());
        if (dish == null) return;
        final var items = dish.ingredients();
        final var renderer = Minecraft.getInstance().getItemRenderer();
        for (int i = 0; i < Math.min(4, items.size()); i++) {
            final ItemStack stack = items.get(i);
            if (stack.isEmpty()) continue;
            pose.pushPose();
            pose.translate(0.5D + ((i % 2) - 0.5D) * 0.28D, 0.14D,
                0.5D + ((i / 2) - 0.5D) * 0.28D);
            pose.mulPose(Axis.XP.rotationDegrees(90.0F));
            pose.mulPose(Axis.ZP.rotationDegrees((i % 4) * 35.0F));
            pose.scale(SCALE, SCALE, SCALE);
            renderer.renderStatic(stack, ItemDisplayContext.FIXED, packedLight,
                OverlayTexture.NO_OVERLAY, pose, buffers, be.getLevel(), (int) be.getBlockPos().asLong());
            pose.popPose();
        }
    }
}
