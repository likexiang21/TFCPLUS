package io.github.likexiang21.tfcplus.agriculture.client.renderer;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CookingPanBlockEntity;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;

/** Renders pan ingredients so the player can read the contents without a GUI. */
public final class CookingPanBlockEntityRenderer implements BlockEntityRenderer<CookingPanBlockEntity> {
    public CookingPanBlockEntityRenderer(BlockEntityRendererProvider.Context context) {}

    @Override public void render(CookingPanBlockEntity be, float partialTick, PoseStack pose,
                                 MultiBufferSource buffers, int packedLight, int packedOverlay) {
        if (be.getLevel() == null) return;
        final var renderer = Minecraft.getInstance().getItemRenderer();
        for (int slot = 0; slot < CookingPanBlockEntity.INGREDIENT_SLOTS; slot++) {
            final ItemStack stack = be.renderStack(slot);
            if (stack.isEmpty()) continue;
            pose.pushPose();
            final double x = 0.28D + (slot % 3) * 0.22D;
            final double z = 0.28D + (slot / 3) * 0.22D;
            pose.translate(x, 0.18D, z);
            pose.mulPose(Axis.XP.rotationDegrees(90.0F));
            pose.mulPose(Axis.ZP.rotationDegrees((slot * 47) % 360));
            pose.scale(0.24F, 0.24F, 0.24F);
            renderer.renderStatic(stack, ItemDisplayContext.FIXED, packedLight,
                OverlayTexture.NO_OVERLAY, pose, buffers, be.getLevel(), slot);
            pose.popPose();
        }
    }
}
