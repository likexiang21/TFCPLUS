package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.common.blockentities.DryingRackBlockEntity;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;

/** Server-side insertion and extraction rules for the drying rack pilot. */
public final class DryingRackInteractions {
    private static final String MESSAGE = "message.tfcagricultureplus.drying_rack.";

    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof DryingRackBlockEntity rack)) return;
        final ItemStack held = player.getItemInHand(hand);
        if (held.isEmpty()) {
            if (rack.isEmpty()) { message(player, "empty"); return; }
            if (!rack.isFinished()) { message(player, "not_ready"); return; }
            final ItemStack output = rack.extract();
            if (!player.getInventory().add(output)) player.drop(output, false);
            level.playSound(null, pos, SoundEvents.ITEM_FRAME_REMOVE_ITEM, SoundSource.BLOCKS, 0.7F, 1.0F);
            return;
        }
        if (FoodCapability.isRotten(held)) { message(player, "rotten"); return; }
        final ItemStack inputStack = held.copyWithCount(1);
        if (!DryingRackBlockEntity.hasRecipe(inputStack)) {
            message(player, "no_recipe");
            return;
        }
        if (!rack.canAccept(inputStack)) {
            message(player, "full");
            return;
        }
        final int inserted = rack.insertCount(held);
        if (inserted <= 0) { message(player, "full"); return; }
        if (!player.isCreative()) held.shrink(inserted);
        level.playSound(null, pos, SoundEvents.ITEM_FRAME_ADD_ITEM, SoundSource.BLOCKS, 0.7F, 1.0F);
    }

    private static void message(Player player, String key) {
        player.displayClientMessage(Component.translatable(MESSAGE + key), true);
    }

    private DryingRackInteractions() {}
}
