package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.SilkwormRackBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;

/** Opens the TFC-style menu; all slot rules live in the block entity callback. */
public final class SilkwormRackInteractions {
    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(player instanceof ServerPlayer serverPlayer)) return;
        if (level.getBlockEntity(pos) instanceof SilkwormRackBlockEntity rack) {
            serverPlayer.openMenu(rack, pos);
        }
    }

    private SilkwormRackInteractions() {}
}
