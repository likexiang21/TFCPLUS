package io.github.likexiang21.tfcplus.agriculture.common.item;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.ServingPlateBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.pan.DishEating;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishBuilder;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PlateVariant;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgriculturePlates;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.food.FoodProperties;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.item.UseAnim;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;

/** Plate item; an empty plate is a block item, a filled plate carries dynamic dish data. */
public final class ServingPlateItem extends BlockItem {
    private final PlateVariant variant;

    public ServingPlateItem(Block block, PlateVariant variant, Properties properties) {
        super(block, properties);
        this.variant = variant;
    }

    public PlateVariant variant() { return variant; }

    @Override public BlockState getPlacementState(BlockPlaceContext context) {
        return getBlock().defaultBlockState().setValue(AgriculturePlates.VARIANT, variant);
    }

    @Override public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
        final ItemStack stack = player.getItemInHand(hand);
        if (PanDishData.read(stack) == null) return InteractionResultHolder.pass(stack);
        player.startUsingItem(hand);
        return InteractionResultHolder.consume(stack);
    }

    @Override public InteractionResult useOn(UseOnContext context) {
        final ItemStack stack = context.getItemInHand();
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) return super.useOn(context);
        final Player player = context.getPlayer();
        if (player == null) return InteractionResult.PASS;
        if (!player.isShiftKeyDown()) {
            player.startUsingItem(context.getHand());
            return InteractionResult.sidedSuccess(context.getLevel().isClientSide());
        }
        final Level level = context.getLevel();
        final BlockPos pos = context.getClickedPos().relative(context.getClickedFace());
        final BlockState state = getBlock().defaultBlockState().setValue(AgriculturePlates.VARIANT, variant);
        if (!level.setBlock(pos, state, Block.UPDATE_ALL)) return InteractionResult.FAIL;
        if (!level.isClientSide() && level.getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
            plate.setPlateStack(stack.copyWithCount(1));
        }
        if (!player.isCreative()) stack.shrink(1);
        return InteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override public FoodProperties getFoodProperties(ItemStack stack, LivingEntity entity) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) return null;
        return new FoodProperties.Builder()
            .nutrition(Math.max(1, dish.food().hunger()))
            .saturationModifier(dish.food().saturation())
            .build();
    }

    @Override public int getUseDuration(ItemStack stack, LivingEntity entity) { return 24; }
    @Override public UseAnim getUseAnimation(ItemStack stack) { return UseAnim.EAT; }

    @Override public ItemStack finishUsingItem(ItemStack stack, Level level, LivingEntity entity) {
        if (level.isClientSide() || !(entity instanceof Player player)) return stack;
        return DishEating.finishItemUse(player, stack);
    }

    @Override public Component getName(ItemStack stack) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) return super.getName(stack);
        return Component.translatable(PanDishBuilder.categoryTranslationKey(dish));
    }

    @Override public void appendHoverText(ItemStack stack, TooltipContext context, List<Component> tooltip, TooltipFlag flag) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) {
            super.appendHoverText(stack, context, tooltip, flag);
            return;
        }
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.dish.servings", dish.servings()));
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.dish.score", dish.score()));
        tooltip.add(Component.translatable(PanDishBuilder.qualityTranslationKey(dish)));
        for (int i = 0; i < Math.min(4, dish.ingredients().size()); i++) {
            tooltip.add(Component.literal(" - ").append(dish.ingredients().get(i).getHoverName()));
        }
        if (dish.ingredients().size() > 4) {
            tooltip.add(Component.translatable("tooltip.tfcagricultureplus.dish.more", dish.ingredients().size() - 4));
        }
    }
}
