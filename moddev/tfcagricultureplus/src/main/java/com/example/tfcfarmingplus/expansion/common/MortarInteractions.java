package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.common.blockentities.MortarBlockEntity;
import com.example.tfcfarmingplus.expansion.common.recipe.MortarRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;

/** Server-side interaction flow for the one-slot mortar. */
public final class MortarInteractions {
    private static final String MESSAGE = "message.tfcagricultureplus.mortar.";

    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof MortarBlockEntity mortar)) {
            return;
        }
        final ItemStack held = player.getItemInHand(hand);

        if (MyItems.isPestle(held)) {
            grind(level, pos, player, hand, held, mortar);
            return;
        }
        if (!held.isEmpty()) {
            if (!mortar.insert(held)) {
                message(player, "full");
                return;
            }
            if (!player.isCreative()) {
                held.shrink(1);
            }
            level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.6F, 1.1F);
            return;
        }

        final ItemStack output = mortar.extract();
        if (output.isEmpty()) {
            message(player, "empty");
        } else if (!player.getInventory().add(output)) {
            player.drop(output, false);
        }
    }

    private static void grind(Level level, BlockPos pos, Player player, InteractionHand hand,
                              ItemStack pestle, MortarBlockEntity mortar) {
        if (mortar.isEmpty()) {
            message(player, "empty");
            return;
        }
        if (FoodCapability.isRotten(mortar.getContent())) {
            message(player, "rotten");
            return;
        }
        final var input = new net.minecraft.world.item.crafting.SingleRecipeInput(mortar.getContent());
        final var holder = level.getRecipeManager()
            .getRecipeFor(MyRecipeTypes.MORTAR.get(), input, level);
        if (holder.isEmpty()) {
            message(player, "no_recipe");
            return;
        }
        final MortarRecipe recipe = holder.get().value();
        final boolean complete = mortar.advanceGrinding(recipe.grindTime());
        if (!player.isCreative()) {
            pestle.hurtAndBreak(1, player,
                hand == InteractionHand.MAIN_HAND ? EquipmentSlot.MAINHAND : EquipmentSlot.OFFHAND);
        }
        level.playSound(null, pos, SoundEvents.GRINDSTONE_USE, SoundSource.BLOCKS, 0.7F,
            complete ? 0.9F : 1.1F);
        if (!complete) {
            message(player, "progress", mortar.getGrindProgress(), recipe.grindTime());
            return;
        }

        final ItemStack output = recipe.assemble(input, level.registryAccess());
        mortar.consumeContent();
        if (!player.getInventory().add(output)) {
            player.drop(output, false);
        }
    }

    private static void message(Player player, String key, Object... args) {
        player.displayClientMessage(Component.translatable(MESSAGE + key, args), true);
    }

    private MortarInteractions() {}
}
