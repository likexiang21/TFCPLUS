package io.github.likexiang21.tfcplus.agriculture.common.item;

import net.dries007.tfc.common.blocks.TFCBlocks;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.neoforged.neoforge.items.ItemHandlerHelper;

/** B-owned copy of the licensed sawdust soup bowl return behavior. */
public final class SawdustSoupBowlItem extends Item {
    public SawdustSoupBowlItem(Properties properties) { super(properties); }

    @Override
    public ItemStack finishUsingItem(ItemStack stack, Level level, LivingEntity entity) {
        if (entity instanceof Player player) {
            ItemHandlerHelper.giveItemToPlayer(player, new ItemStack(TFCBlocks.CERAMIC_BOWL.get().asItem()));
        }
        return super.finishUsingItem(stack, level, entity);
    }
}
