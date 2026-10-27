package com.example.tfcfarmingplus.expansion.common.recipe.inworld;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import net.dries007.tfc.common.LevelTier;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.Holder;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemCooldowns;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Tier;
import net.minecraft.world.item.TieredItem;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.SupportType;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.bus.api.EventPriority;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.neoforge.common.util.TriState;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.player.PlayerInteractEvent;

import java.util.Random;

/** Input arbitration and server execution for this project's world-processing recipes. */
@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID)
public final class InWorldRecipeHandler {
    private static final Random RANDOM = new Random();
    private static final int[] TOOL_COOLDOWNS = {35, 25, 20, 15, 10, 5, 5};

    private InWorldRecipeHandler() {}

    @SubscribeEvent(priority = EventPriority.HIGH)
    public static void onRightClickBlock(PlayerInteractEvent.RightClickBlock interaction) {
        if (interaction.getHand() != InteractionHand.MAIN_HAND) return;
        Player player = interaction.getEntity();
        ItemStack held = player.getMainHandItem();
        if (held.isEmpty()) return;
        if (player.getCooldowns().isOnCooldown(held.getItem())) {
            interaction.setUseItem(TriState.FALSE);
            return;
        }

        Level level = interaction.getLevel();
        BlockPos target = interaction.getPos();
        if (!checkFiveDirections(level, target)) return;
        InWorldComponents.Input input = new InWorldComponents.Input(level.getBlockState(target), held);
        level.getRecipeManager().getRecipeFor(MyRecipeTypes.IN_WORLD.get(), input, level)
            .ifPresent(holder -> acceptInteraction(interaction, holder.value(), held));
    }

    private static void acceptInteraction(PlayerInteractEvent.RightClickBlock interaction,
                                          InWorldRecipe recipe, ItemStack held) {
        // Reserve the interaction on both sides before any server effects are applied.
        interaction.setCancellationResult(InteractionResult.SUCCESS);
        interaction.setCanceled(true);
        Level level = interaction.getLevel();
        if (level.isClientSide()) return;
        executeOnServer(level, interaction.getPos(), interaction.getEntity(), held, recipe);
    }

    private static void executeOnServer(Level level, BlockPos target, Player player,
                                         ItemStack held, InWorldRecipe recipe) {
        level.setBlockAndUpdate(target, recipe.resultState());
        recipe.soundInstance().ifPresent(sound -> sound.play(level, player, target));
        recipe.resultItems().forEach(output ->
            output.getSecond().accept(level, target, output.getFirst(), player.getDirection()));
        damageTool(player, held);
        setCooldownForItems(player, recipe.tool().getToolTagKey());
        player.swing(InteractionHand.MAIN_HAND, true);
    }

    private static void damageTool(Player player, ItemStack held) {
        if (player.isCreative() || !(held.getItem() instanceof TieredItem tiered)) return;
        int uses = Math.max(1, tiered.getTier().getUses());
        if (RANDOM.nextDouble() < 400.0 / uses) {
            held.hurtAndBreak(1, (LivingEntity) player, EquipmentSlot.MAINHAND);
        }
    }

    private static void setCooldownForItems(Player player, TagKey<Item> tag) {
        int level = 6;
        ItemStack held = player.getMainHandItem();
        if (held.getItem() instanceof TieredItem tiered) {
            Tier tier = tiered.getTier();
            if (tier instanceof LevelTier levelTier) level = Math.clamp(levelTier.level(), 0, 6);
        }
        int ticks = TOOL_COOLDOWNS[level];
        ItemCooldowns cooldowns = player.getCooldowns();
        for (Holder<Item> holder : BuiltInRegistries.ITEM.getOrCreateTag(tag)) {
            if (holder.value() instanceof TieredItem) cooldowns.addCooldown(holder.value(), ticks);
        }
    }

    /** Match TFC Woodworking's guard against processing a block embedded in a structure. */
    private static boolean checkFiveDirections(Level level, BlockPos pos) {
        for (int id = 1; id <= 5; id++) {
            Direction direction = Direction.from3DDataValue(id);
            BlockPos neighbour = pos.relative(direction);
            BlockState neighbourState = level.getBlockState(neighbour);
            if (neighbourState.isFaceSturdy(level, neighbour, direction.getOpposite(), SupportType.FULL)) {
                return false;
            }
        }
        return true;
    }
}
