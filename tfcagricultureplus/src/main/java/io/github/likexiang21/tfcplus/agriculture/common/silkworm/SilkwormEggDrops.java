package io.github.likexiang21.tfcplus.agriculture.common.silkworm;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.item.ItemStack;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.level.BlockDropsEvent;

/** B adds a rare starter egg to A's mulberry leaves without changing A's loot table. */
@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID)
public final class SilkwormEggDrops {
    private static final ResourceLocation MULBERRY_LEAVES =
        ResourceLocation.parse("tfcfarmingplus:plant/mulberry_leaves");

    @SubscribeEvent
    public static void onDrops(BlockDropsEvent event) {
        if (!event.getState().is(BuiltInRegistries.BLOCK.get(MULBERRY_LEAVES))
            || event.getLevel().random.nextFloat() >= 0.05F) return;
        if (event.getDrops().stream().anyMatch(drop -> drop.getItem().is(AgricultureItems.SILKWORM_EGG.get()))) return;

        final var pos = event.getPos();
        event.getDrops().add(new ItemEntity(event.getLevel(),
            pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5,
            new ItemStack(AgricultureItems.SILKWORM_EGG.get())));
    }

    private SilkwormEggDrops() {}
}
