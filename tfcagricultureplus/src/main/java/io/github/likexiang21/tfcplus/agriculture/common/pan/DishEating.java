package io.github.likexiang21.tfcplus.agriculture.common.pan;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.ServingPlateBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.item.ServingBowlItem;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.player.IPlayerInfo;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;

/** Shared serving logic for plates and bowls. */
public final class DishEating {
    public static boolean eatFromPlateBlock(Player player, ServingPlateBlockEntity plate) {
        if (!(player instanceof ServerPlayer)) return true;
        final ItemStack stack = plate.plateStack();
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null || FoodCapability.isRotten(stack)) return false;
        consumeOne(player, dish);
        if (dish.servings() <= 1) {
            plate.clearPlate();
        } else {
            final PanDishData rest = new PanDishData(dish.servings() - 1, dish.score(), dish.food(),
                dish.category(), dish.ingredients());
            PanDishData.write(stack, rest);
            plate.setPlateStack(stack);
        }
        return true;
    }

    /** Called from Item.finishUsingItem. Returns the resulting stack (with one fewer serving). */
    public static ItemStack finishItemUse(Player player, ItemStack stack) {
        final PanDishData dish = PanDishData.read(stack);
        if (dish == null || FoodCapability.isRotten(stack)) return stack;
        consumeOne(player, dish);
        if (dish.servings() <= 1) {
            PanDishData.clear(stack);
            stack.setCount(1);
            return stack;
        }
        final PanDishData rest = new PanDishData(dish.servings() - 1, dish.score(), dish.food(),
            dish.category(), dish.ingredients());
        PanDishData.write(stack, rest);
        stack.setCount(1);
        return stack;
    }

    public static boolean transferToBowl(Player player, ServingPlateBlockEntity plate, InteractionHand hand) {
        if (!(player instanceof ServerPlayer)) return true;
        final ItemStack held = player.getItemInHand(hand);
        if (!(held.getItem() instanceof ServingBowlItem)) return false;
        final ItemStack food = plate.plateStack();
        final PanDishData dish = PanDishData.read(food);
        if (dish == null || FoodCapability.isRotten(food)) return false;
        final PanDishData one = new PanDishData(1, dish.score(), dish.food(), dish.category(), dish.ingredients());
        final ItemStack bowl = held.copyWithCount(1);
        PanDishData.write(bowl, one);
        if (!player.getInventory().add(bowl)) player.drop(bowl, false);
        if (!player.isCreative()) held.shrink(1);
        if (dish.servings() <= 1) {
            plate.clearPlate();
        } else {
            final PanDishData rest = new PanDishData(dish.servings() - 1, dish.score(), dish.food(),
                dish.category(), dish.ingredients());
            final ItemStack restStack = food.copyWithCount(1);
            PanDishData.write(restStack, rest);
            plate.setPlateStack(restStack);
        }
        return true;
    }

    private static void consumeOne(Player player, PanDishData dish) {
        if (player instanceof ServerPlayer serverPlayer && !serverPlayer.getAbilities().instabuild) {
            IPlayerInfo.get(serverPlayer).eat(dish.food());
        }
    }

    public static Item emptyPlateItem(ItemStack stack) {
        return stack.getItem();
    }

    private DishEating() {}
}
