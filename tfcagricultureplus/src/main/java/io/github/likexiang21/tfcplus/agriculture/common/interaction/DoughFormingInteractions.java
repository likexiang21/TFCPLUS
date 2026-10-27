package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.DoughFormingTableBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;

/** Mouse flow for K3: insert flour, knead with an empty hand, then take dough. */
public final class DoughFormingInteractions {
    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof DoughFormingTableBlockEntity table)) return;
        final ItemStack held = player.getItemInHand(hand);
        if (held.isEmpty()) {
            final ItemStack output = table.takeOutput();
            if (!output.isEmpty()) { give(player, output); return; }
            if (table.formDough()) return;
            final ItemStack input = table.takeInput();
            if (!input.isEmpty()) { give(player, input); return; }
            message(player, "empty");
            return;
        }
        if (table.insertInput(held)) {
            if (!player.isCreative()) held.shrink(1);
            return;
        }
        message(player, "invalid");
    }
    private static void give(Player player, ItemStack stack) { if (!player.getInventory().add(stack)) player.drop(stack, false); }
    private static void message(Player player, String key) { player.displayClientMessage(Component.translatable("message.tfcagricultureplus.dough_table." + key), true); }
    private DoughFormingInteractions() {}
}
