package io.github.likexiang21.tfcplus.agriculture.client.renderer;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import io.github.likexiang21.tfcplus.agriculture.common.timber.*;
import io.github.likexiang21.tfcplus.agriculture.common.timber.BurningTimberPileBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlock;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlockEntity;
import net.dries007.tfc.common.blocks.TFCBlocks;
import net.dries007.tfc.common.blocks.devices.LogPileBlock;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.*;
import net.minecraft.client.renderer.blockentity.*;
import net.minecraft.core.Direction;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.level.block.entity.BlockEntity;

public final class TimberPileBlockEntityRenderer<T extends BlockEntity> implements BlockEntityRenderer<T> {
    public TimberPileBlockEntityRenderer(BlockEntityRendererProvider.Context context) {}
    @Override public void render(T be,float partial,PoseStack pose,MultiBufferSource buffers,int light,int overlay) {
        var renderer=Minecraft.getInstance().getBlockRenderer();
        var axis=be.getBlockState().getValue(TimberPileBlock.AXIS);
        if(be instanceof BurningTimberPileBlockEntity) {
            var state=TFCBlocks.BURNING_LOG_PILE.get().defaultBlockState().setValue(LogPileBlock.AXIS,axis).setValue(LogPileBlock.COUNT,be.getBlockState().getValue(TimberPileBlock.LAYERS));
            renderer.renderSingleBlock(state,pose,buffers,light,overlay); return;
        }
        if(!(be instanceof TimberPileBlockEntity pile)) return;
        for(int slot=0;slot<16;slot++) {
            var stack=pile.get(slot);
            if(stack.isEmpty() || !(stack.getItem() instanceof BlockItem item)) continue;
            int weight=TimberBlocks.weight(stack);
            for(int part=0;part<stack.getCount();part++) {
                double cross=slot%4*.25+.125, height=slot/4*.25+.125;
                double offsetX=weight==1?(part%2==0?-.055:.055):0;
                double offsetY=weight==2?(part==0?-.055:.055):weight==1?(part/2==0?-.055:.055):0;
                pose.pushPose();
                if(axis==Direction.Axis.Z) { pose.translate(cross+offsetX,height+offsetY,.5); pose.mulPose(Axis.XP.rotationDegrees(90)); }
                else { pose.translate(.5,height+offsetY,cross+offsetX); pose.mulPose(Axis.ZP.rotationDegrees(-90)); }
                pose.scale(.25f,1,.25f); pose.translate(-.5,-.5,-.5);
                var state=item.getBlock().defaultBlockState();
                if(weight==2 && axis==Direction.Axis.X) state=state.setValue(net.minecraft.world.level.block.HorizontalDirectionalBlock.FACING,Direction.EAST);
                renderer.renderSingleBlock(state,pose,buffers,light,overlay); pose.popPose();
            }
        }
    }
}
