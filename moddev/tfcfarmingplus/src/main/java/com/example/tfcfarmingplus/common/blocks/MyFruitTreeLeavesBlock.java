package com.example.tfcfarmingplus.common.blocks;

import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeLeavesBlock;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

import java.util.function.Supplier;

/**
 * 沿用原生季节、采收与叶片效果；项目仅补自建实体的计时接线和开花招蜂提示。
 * 粒子布局按项目的环绕花冠设计独立实现，历史来源核对见 226 号交接。
 */
public class MyFruitTreeLeavesBlock extends FruitTreeLeavesBlock {
    private static final TagKey<Block> BUZZING_LEAVES = TagKey.create(
        Registries.BLOCK, ResourceLocation.fromNamespaceAndPath("firmalife", "buzzing_leaves"));

    public MyFruitTreeLeavesBlock(ExtendedProperties properties, Supplier<? extends Item> productItem,
                                  Lifecycle[] stages, Supplier<ClimateRange> climateRange, int color) {
        super(properties, productItem, stages, climateRange, color);
    }

    @Override
    public void animateTick(BlockState state, Level level, BlockPos pos, RandomSource random) {
        // 保留依赖提供的落叶、雪花和滴雨效果。
        super.animateTick(state, level, pos, random);
        if (state.getValue(LIFECYCLE) != Lifecycle.FLOWERING
            || !state.is(BUZZING_LEAVES) || random.nextInt(100) != 0) {
            return;
        }
        int motes = 3 + random.nextInt(4);
        double phase = random.nextDouble() * Math.TAU;
        for (int i = 0; i < motes; i++) {
            double angle = phase + Math.TAU * i / motes;
            double radius = 0.25 + random.nextDouble() * 0.2;
            double dx = Math.cos(angle), dz = Math.sin(angle);
            level.addParticle(ParticleTypes.SMOKE,
                pos.getX() + 0.5 + radius * dx,
                pos.getY() + 0.3 + random.nextDouble() * 0.5,
                pos.getZ() + 0.5 + radius * dz,
                -0.025 * dz, 0.005, 0.025 * dx);
        }
    }

    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
                                              Player player, InteractionHand hand, BlockHitResult hit) {
        return MySeasonalPlantFix.afterUse(level, pos,
            super.useItemOn(stack, state, level, pos, player, hand, hit));
    }

    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        MySeasonalPlantFix.afterPlace(level, pos);
    }
}
