package com.example.tfcfarmingplus.expansion.client;

import com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity;
import com.mojang.blaze3d.vertex.PoseStack;
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

/**
 * 🆕 <b>案板的物品渲染器</b> —— 用户口径：
 * 「**砧板交互也要保证物品的可见性，而且是直接渲染不是绘画或者建模**」。
 *
 * <h2>🛑 为什么用 {@code ItemRenderer.renderStatic}</h2>
 * 用户明确区分了三件事：
 * <table border="1">
 *   <tr><th>做法</th><th>说明</th><th>用不用</th></tr>
 *   <tr><td><b>直接渲染</b></td><td>把物品**本身的三维模型**画出来
 *       （{@code Minecraft.getInstance().getItemRenderer().renderStatic(...)}）</td>
 *       <td>✅ <b>用这个</b></td></tr>
 *   <tr><td>绘制（2D）</td><td>把物品的**图标**贴上去（{@code GuiGraphics.blit}）</td><td>❌ 不用</td></tr>
 *   <tr><td>建模（自定义 block model）</td><td>给每种可放物品写一套方块模型（TFC 的 {@code ToolRackBlockEntityRenderer.MODELS} 就是这种，只覆盖锅/罐等少量物品）</td><td>❌ 不用（要穷举物品，不可扩展）</td></tr>
 * </table>
 * ⇒ **直接渲染**的好处：**任何物品都能自动显示**，不用为每种物品写模型，也不用管图标。
 *
 * <p>做法与 {@link KnifeBlockBlockEntityRenderer} 一致（都学 TFC 的 {@code ToolRackBlockEntityRenderer}）：
 * 按 {@code FACING} 旋转 ⇒ translate 到板面中心 ⇒ scale ⇒ {@code renderStatic}。
 */
public final class CuttingBoardBlockEntityRenderer implements BlockEntityRenderer<CuttingBoardBlockEntity> {

    /** 板面上的物品缩放（比工具架上的稍大一点，因为案板是"平放"的）。 */
    private static final float ITEM_SCALE = 0.5F;

    public CuttingBoardBlockEntityRenderer(BlockEntityRendererProvider.Context context) {
        // 默认构造即可（ItemRenderer 取单例，与 TFC 一致）
    }

    @Override
    public void render(CuttingBoardBlockEntity be, float partialTick, PoseStack pose,
                       MultiBufferSource buffers, int packedLight, int packedOverlay) {

        if (be.getLevel() == null || be.isBoardEmpty()) {
            return;
        }

        final ItemStack stack = be.getOnBoard();
        if (stack.isEmpty()) {
            return;
        }

        final Direction facing = be.getBlockState().hasProperty(HorizontalDirectionalBlock.FACING)
            ? be.getBlockState().getValue(HorizontalDirectionalBlock.FACING)
            : Direction.NORTH;

        final ItemRenderer itemRenderer = Minecraft.getInstance().getItemRenderer();

        pose.pushPose();

        // ① 转到方块朝向
        pose.translate(0.5D, 0.5D, 0.5D);
        pose.mulPose(com.mojang.math.Axis.YP.rotationDegrees(-facing.toYRot()));
        pose.translate(-0.5D, -0.5D, -0.5D);

        // ② 平放在板面上（y≈0.09 刚好在 1px 台面之上）+ 稍微倾斜，让人看清是什么
        final double surface = be.getBlockState().getBlock()
            instanceof com.example.tfcfarmingplus.expansion.common.MyBlocks.LogCuttingBoardBlock ? 0.3125D : 0.0625D;
        pose.translate(0.5D, surface + 0.03125D, 0.5D);
        pose.mulPose(com.mojang.math.Axis.XP.rotationDegrees(90.0F));
        pose.scale(ITEM_SCALE, ITEM_SCALE, ITEM_SCALE);

        // ③ **直接渲染**物品模型（不是画图标、不是自定义模型）
        itemRenderer.renderStatic(stack, ItemDisplayContext.FIXED,
            packedLight, OverlayTexture.NO_OVERLAY, pose, buffers, be.getLevel(), 0);

        pose.popPose();
    }
}
