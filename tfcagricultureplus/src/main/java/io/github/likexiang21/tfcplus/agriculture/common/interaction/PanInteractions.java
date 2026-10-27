package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CookingPanBlockEntity;
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

/** Direct mouse flow for the K2 pan; every path uses the same BE validation. */
public final class PanInteractions {
    public static final TagKey<net.minecraft.world.item.Item> PAN_FOODS = TagKey.create(
        Registries.ITEM, ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "foods/pan_inputs"));
    public static final TagKey<net.minecraft.world.item.Item> PAN_SPICES = TagKey.create(
        Registries.ITEM, ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "foods/ground_spices"));
    private static final String MESSAGE = "message.tfcagricultureplus.pan.";

    public static boolean isPanFood(ItemStack stack) { return !stack.isEmpty() && stack.is(PAN_FOODS); }
    public static boolean isPanSpice(ItemStack stack) { return !stack.isEmpty() && stack.is(PAN_SPICES); }

    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof CookingPanBlockEntity pan)) return;
        final ItemStack held = player.getItemInHand(hand);
        if (held.isEmpty()) {
            final ItemStack output = pan.extractOutput();
            if (!output.isEmpty()) {
                if (!player.getInventory().add(output)) player.drop(output, false);
                level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.7F, 1.0F);
                return;
            }
            if (!pan.stir()) message(player, "not_ready");
            else level.playSound(null, pos, SoundEvents.GENERIC_EAT, SoundSource.BLOCKS, 0.5F, 1.2F);
            return;
        }
        if (isPanFood(held) && pan.insertFood(held)) {
            if (!player.isCreative()) held.shrink(1);
            level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.6F, 1.1F);
            return;
        }
        if (isPanSpice(held) && pan.insertSpice(held)) {
            if (!player.isCreative()) held.shrink(1);
            level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.6F, 1.1F);
            return;
        }
        if (FoodCapability.isRotten(held)) message(player, "rotten");
        else message(player, "occupied");
    }

    private static void message(Player player, String key) {
        player.displayClientMessage(Component.translatable(MESSAGE + key), true);
    }

    private PanInteractions() {}
}
