package io.github.likexiang21.tfcplus.agriculture.common.item;

import io.github.likexiang21.tfcplus.agriculture.common.pan.DishEating;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishBuilder;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import java.util.List;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.food.FoodProperties;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.item.UseAnim;
import net.minecraft.world.level.Level;

/** Wooden or ceramic serving bowl. Empty and filled states share one item ID. */
public final class ServingBowlItem extends Item {
    public ServingBowlItem(Properties properties) { super(properties); }

    @Override public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
        final ItemStack stack = player.getItemInHand(hand);
        if (PanDishData.read(stack) == null) return InteractionResultHolder.pass(stack);
        player.startUsingItem(hand);
        return InteractionResultHolder.consume(stack);
    }

    @Override public FoodProperties getFoodProperties(ItemStack stack, LivingEntity entity) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) return null;
        return new FoodProperties.Builder()
            .nutrition(Math.max(1, dish.food().hunger()))
            .saturationModifier(dish.food().saturation())
            .build();
    }

    @Override public int getUseDuration(ItemStack stack, LivingEntity entity) { return 20; }
    @Override public UseAnim getUseAnimation(ItemStack stack) { return UseAnim.EAT; }

    @Override public ItemStack finishUsingItem(ItemStack stack, Level level, LivingEntity entity) {
        if (level.isClientSide() || !(entity instanceof Player player)) return stack;
        return DishEating.finishItemUse(player, stack);
    }

    @Override public Component getName(ItemStack stack) {
        final PanDishData dish = PanDishData.read(stack);
        return dish == null ? super.getName(stack) : Component.translatable(PanDishBuilder.categoryTranslationKey(dish));
    }

    @Override public void appendHoverText(ItemStack stack, TooltipContext context, List<Component> tooltip, TooltipFlag flag) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null) {
            super.appendHoverText(stack, context, tooltip, flag);
            return;
        }
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.dish.servings", dish.servings()));
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.dish.score", dish.score()));
    }
}
