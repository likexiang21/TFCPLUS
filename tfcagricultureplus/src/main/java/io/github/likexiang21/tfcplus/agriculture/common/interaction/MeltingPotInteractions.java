package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.MeltingPotBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;

/** Input/output flow for the K3 melting pot. */
public final class MeltingPotInteractions {
    public static final TagKey<net.minecraft.world.item.Item> POWDERS = TagKey.create(
        Registries.ITEM, ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "foods/melting_powders"));
    public static final TagKey<net.minecraft.world.item.Item> SWEETENERS = TagKey.create(
        Registries.ITEM, ResourceLocation.fromNamespaceAndPath("tfc", "foods/sweeteners"));
    public static boolean isPowder(ItemStack stack) { return !stack.isEmpty() && stack.is(POWDERS); }
    public static boolean isSweetener(ItemStack stack) { return !stack.isEmpty() && stack.is(SWEETENERS); }
    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof MeltingPotBlockEntity pot)) return;
        final ItemStack held = player.getItemInHand(hand);
        if (held.isEmpty()) {
            final ItemStack output = pot.extractOutput();
            if (!output.isEmpty()) { give(player, output); return; }
            if (pot.startMelting()) { message(player, "started"); return; }
            final ItemStack input = pot.takeAnyInput();
            if (!input.isEmpty()) { give(player, input); return; }
            message(player, "empty");
            return;
        }
        if (pot.insertPowder(held) || pot.insertSweetener(held)) {
            if (!player.isCreative()) held.shrink(1);
            return;
        }
        message(player, "invalid");
    }
    private static void give(Player player, ItemStack stack) { if (!player.getInventory().add(stack)) player.drop(stack, false); }
    private static void message(Player player, String key) { player.displayClientMessage(Component.translatable("message.tfcagricultureplus.melting_pot." + key), true); }
    private MeltingPotInteractions() {}
}
