package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CookingPanBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.item.SpatulaItem;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.material.Fluid;
import net.neoforged.neoforge.fluids.FluidStack;
import net.neoforged.neoforge.fluids.FluidUtil;

/** Direct interaction flow for the multi-ingredient pan. */
public final class PanInteractions {
    private static final TagKey<Fluid> OIL = TagKey.create(Registries.FLUID,
        ResourceLocation.fromNamespaceAndPath("c", "plantoil"));
    private static final TagKey<Fluid> FIRMALIFE_OIL = TagKey.create(Registries.FLUID,
        ResourceLocation.fromNamespaceAndPath("firmalife", "oils"));

    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof CookingPanBlockEntity pan)) return;
        final ItemStack held = player.getItemInHand(hand);
        if (held.isEmpty()) {
            if (pan.ingredientCount() > 0) {
                player.displayClientMessage(pan.status(), true);
                return;
            }
            player.displayClientMessage(pan.status(), true);
            return;
        }
        if (held.getItem() instanceof SpatulaItem) {
            if (scoopOil(player, pan)) {
                pan.refreshOilType();
                level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }
            if (pan.addSolidOil(held)) {
                if (!player.isCreative()) held.shrink(1);
                level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }
            if (pan.stir((SpatulaItem) held.getItem(), held, player)) {
                level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.4F, 1.4F);
            } else {
                message(player, "no_heat");
            }
            return;
        }
        if (pan.addSolidOil(held)) {
            if (!player.isCreative()) held.shrink(1);
            level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.5F, 1.1F);
            return;
        }
        if (held.getItem() instanceof io.github.likexiang21.tfcplus.agriculture.common.item.ServingPlateItem) {
            final ItemStack dish = pan.serve(held);
            if (!dish.isEmpty()) {
                if (!player.isCreative()) held.shrink(1);
                if (!player.getInventory().add(dish)) player.drop(dish, false);
                level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.7F, 0.9F);
            } else {
                message(player, "not_ready");
            }
            return;
        }
        if (FluidUtil.getFluidHandler(held).isPresent()) {
            final FluidStack contained = FluidUtil.getFluidContained(held).orElse(FluidStack.EMPTY);
            if (!contained.isEmpty() && !isOil(contained)) {
                message(player, "no_oil");
                return;
            }
            if (FluidUtil.interactWithFluidHandler(player, hand, pan.oilTank())) {
                pan.refreshOilType();
                level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }
            message(player, "no_oil");
            return;
        }
        if (FoodCapability.has(held)) {
            if (pan.addIngredient(held)) {
                if (!player.isCreative()) held.shrink(1);
                level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.5F, 1.2F);
            } else {
                message(player, pan.hasHeat() ? (pan.hasOil() ? "full" : "no_oil") : "no_heat");
            }
            return;
        }
        message(player, "not_ingredient");
    }

    /** Scoops exactly one 5 mB oil dose from the off-hand container into the pan. */
    private static boolean scoopOil(Player player, CookingPanBlockEntity pan) {
        if (pan.hasOil()) return false;
        final ItemStack offhand = player.getOffhandItem();
        final var handler = FluidUtil.getFluidHandler(offhand).orElse(null);
        if (handler == null) return false;
        final FluidStack contained = handler.getFluidInTank(0);
        if (contained.isEmpty() || !isOil(contained)) return false;
        final FluidStack moved = FluidUtil.tryFluidTransfer(handler, pan.oilTank(), CookingPanBlockEntity.OIL_REQUIRED, false);
        return !moved.isEmpty();
    }

    private static boolean isOil(FluidStack stack) {
        return stack.is(OIL) || stack.is(FIRMALIFE_OIL);
    }

    private static void message(Player player, String key) {
        player.displayClientMessage(Component.translatable("message.tfcagricultureplus.pan." + key), true);
    }

    private PanInteractions() {}
}
