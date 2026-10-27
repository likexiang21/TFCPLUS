package io.github.likexiang21.tfcplus.agriculture.common.interaction;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeTypes;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.CuttingBoardRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;

/** Independent board interaction state machine for dough and ordinary cutting. */
public final class CuttingBoardInteractions {
    private static final String MESSAGE = "message.tfcagricultureplus.cutting_board.";
    private static final String CAKE_DOUGH = "tfcagricultureplus:food/cake_dough";

    public static void interact(Level level, BlockPos pos, Player player, InteractionHand hand) {
        if (level.isClientSide) return;
        if (!(level.getBlockEntity(pos) instanceof CuttingBoardBlockEntity board)) return;
        final ItemStack held = player.getItemInHand(hand);

        if (held.isEmpty() && board.isDoughProcessing()) {
            if (player.isShiftKeyDown()) confirmDough(level, pos, player, board);
            else {
                board.incrementKnead();
                level.playSound(null, pos, SoundEvents.WOOL_HIT, SoundSource.BLOCKS, 0.45F, 1.2F);
            }
            return;
        }

        if (held.isEmpty()) {
            final ItemStack output = board.takeFromBoard();
            if (output.isEmpty()) message(player, "durability", board.getUsesLeft());
            else if (!player.getInventory().add(output)) player.drop(output, false);
            return;
        }

        if (processCakeDecoration(level, pos, player, hand, board, held)) return;

        final boolean cuttingTool = held.is(TFCTags.Items.TOOLS_KNIFE)
            || level.getRecipeManager().getAllRecipesFor(AgricultureRecipeTypes.CUTTING_BOARD.get())
                .stream().anyMatch(holder -> holder.value().tool().test(held));
        if (cuttingTool) {
            if ((board.isDoughProcessing() || isRawCakeBase(board.getOnBoard()))
                && processDoughWithKnife(level, pos, player, hand, board, held)) return;
            processCuttingRecipe(level, pos, player, hand, board, held);
            return;
        }

        if (!board.placeOnBoard(held)) { message(player, "occupied"); return; }
        if (!player.isCreative()) held.shrink(1);
        level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.7F, 1.1F);
        if (board.isDoughProcessing()) message(player, "dough_controls");
    }

    /** Called by the NeoForge left-click event before normal block breaking. */
    public static boolean handleLeftClick(Level level, BlockPos pos, Player player) {
        if (!(level.getBlockEntity(pos) instanceof CuttingBoardBlockEntity board)
            || !board.isDoughProcessing() || !player.getMainHandItem().isEmpty()) return false;
        if (level.isClientSide) return true;
        if (player.isShiftKeyDown()) {
            final ItemStack output = board.takeFromBoard();
            if (!output.isEmpty()) {
                if (!player.getInventory().add(output)) player.drop(output, false);
                level.playSound(null, pos, SoundEvents.WOOD_HIT, SoundSource.BLOCKS, 0.6F, 0.9F);
            }
        } else {
            board.incrementPress();
            level.playSound(null, pos, SoundEvents.WOOD_HIT, SoundSource.BLOCKS, 0.45F, 1.25F);
        }
        return true;
    }

    private static void confirmDough(Level level, BlockPos pos, Player player, CuttingBoardBlockEntity board) {
        final ItemStack output = matchingDoughOutput(board.getOnBoard(), board.getPressCount(), board.getKneadCount());
        if (output.isEmpty()) {
            message(player, "dough_not_formed");
            return;
        }
        board.takeFromBoard();
        giveOrDrop(player, output);
        finishProcessing(level, pos, board);
        level.playSound(null, pos, SoundEvents.WOOL_HIT, SoundSource.BLOCKS, 0.8F, 1.1F);
    }

    private static ItemStack matchingDoughOutput(ItemStack input, int presses, int kneads) {
        if (input.isEmpty()) return ItemStack.EMPTY;
        final String id = BuiltInRegistries.ITEM.getKey(input.getItem()).toString();
        if (id.equals(CAKE_DOUGH)) {
            if (presses == 3 && kneads == 3) return foodResult(input, AgricultureItems.RAW_CAKE_BASE.get(), 1);
            if (presses == 2 && kneads == 1) return foodResult(input, AgricultureItems.RAW_SWEET_PANCAKE.get(), 2);
            return ItemStack.EMPTY;
        }
        final String grain = grainFromDoughId(id);
        if (grain == null) return ItemStack.EMPTY;
        if (presses == 3 && kneads == 0) return foodResult(input, AgricultureItems.RAW_PIZZA.get(), 1);
        if (presses == 4 && kneads == 2) {
            final var holder = AgricultureItems.RAW_NAAN.get(grain);
            return holder == null ? ItemStack.EMPTY : foodResult(input, holder.get(), 1);
        }
        return ItemStack.EMPTY;
    }

    private static boolean processDoughWithKnife(Level level, BlockPos pos, Player player,
                                                 InteractionHand hand, CuttingBoardBlockEntity board,
                                                 ItemStack held) {
        final String id = BuiltInRegistries.ITEM.getKey(board.getOnBoard().getItem()).toString();
        final int presses = board.getPressCount();
        final int kneads = board.getKneadCount();
        ItemStack output = ItemStack.EMPTY;
        if (id.equals(CAKE_DOUGH) && presses == 0 && kneads == 0) {
            output = foodResult(board.getOnBoard(), AgricultureItems.RAW_BAGEL.get(), 8);
        } else if (id.endsWith(":food/raw_cake_base")) {
            output = foodResult(board.getOnBoard(), AgricultureItems.RAW_CUPCAKE.get(), 4);
        } else {
            final String grain = grainFromDoughId(id);
            if (grain != null && presses == 0 && kneads == 3) {
                final var holder = AgricultureItems.RAW_BUN.get(grain);
                if (holder != null) output = foodResult(board.getOnBoard(), holder.get(), 4);
            } else if (grain != null && presses == 0 && kneads == 0) {
                output = foodResult(board.getOnBoard(), AgricultureItems.NOODLES.get(), 1);
            }
        }
        if (output.isEmpty()) return false;
        board.takeFromBoard();
        giveOrDrop(player, output);
        damageTool(player, held, hand);
        finishProcessing(level, pos, board);
        level.playSound(null, pos, SoundEvents.AXE_STRIP, SoundSource.BLOCKS, 0.7F, 1.3F);
        return true;
    }

    private static boolean isRawCakeBase(ItemStack stack) {
        return !stack.isEmpty()
            && BuiltInRegistries.ITEM.getKey(stack.getItem()).toString()
                .equals("tfcagricultureplus:food/raw_cake_base");
    }

    private static boolean processCakeDecoration(Level level, BlockPos pos, Player player,
                                                 InteractionHand hand, CuttingBoardBlockEntity board,
                                                 ItemStack held) {
        final String id = BuiltInRegistries.ITEM.getKey(board.getOnBoard().getItem()).toString();
        if (!id.equals("tfcagricultureplus:food/cake_base")) return false;

        final TagKey<Item> chocolateTag = TagKey.create(Registries.ITEM,
            net.minecraft.resources.ResourceLocation.parse("firmalife:foods/chocolate_blends"));
        if (held.is(chocolateTag)) {
            board.takeFromBoard();
            giveOrDrop(player, new ItemStack(AgricultureBlocks.CHOCOLATE_CAKE.get().asItem()));
            if (!player.isCreative()) held.shrink(1);
            finishProcessing(level, pos, board);
            level.playSound(null, pos, SoundEvents.WOOL_HIT, SoundSource.BLOCKS, 0.8F, 1.0F);
            return true;
        }

        if (!held.is(AgricultureBlocks.BUTTER_BLOCK.get().asItem())) return false;
        board.takeFromBoard();
        giveOrDrop(player, new ItemStack(AgricultureBlocks.CREAM_CAKE.get().asItem()));
        if (!player.isCreative()) held.shrink(1);
        finishProcessing(level, pos, board);
        level.playSound(null, pos, SoundEvents.WOOL_HIT, SoundSource.BLOCKS, 0.8F, 1.15F);
        return true;
    }

    private static void processCuttingRecipe(Level level, BlockPos pos, Player player,
                                              InteractionHand hand, CuttingBoardBlockEntity board,
                                              ItemStack held) {
        if (board.isBoardEmpty()) { message(player, "empty"); return; }
        if (board.getUsesLeft() <= 0) { message(player, "worn"); return; }
        if (FoodCapability.isRotten(board.getOnBoard())) { message(player, "rotten"); return; }
        final var input = new CuttingBoardRecipe.CuttingBoardInput(board.getOnBoard().copyWithCount(1), held);
        final var holder = level.getRecipeManager().getRecipeFor(AgricultureRecipeTypes.CUTTING_BOARD.get(), input, level);
        if (holder.isEmpty()) { message(player, "no_recipe"); return; }
        final var recipe = holder.get().value();
        final ItemStack result = recipe.assemble(input, level.registryAccess());
        if (result.isEmpty()) { message(player, "no_recipe"); return; }
        final ItemStack remainder = board.getOnBoard().copy();
        remainder.shrink(1);
        board.setOnBoard(remainder.isEmpty() ? result : remainder);
        if (!remainder.isEmpty()) Block.popResource(level, pos.above(), result);
        for (final var provider : recipe.byproducts()) {
            final ItemStack byproduct = provider.getSingleStack(input.ingredient());
            if (!byproduct.isEmpty()) Block.popResource(level, pos.above(), byproduct);
        }
        damageTool(player, held, hand);
        level.playSound(null, pos, SoundEvents.AXE_STRIP, SoundSource.BLOCKS, 0.7F, 1.3F);
        if (!board.consume()) {
            final ItemStack remaining = board.takeFromBoard();
            level.destroyBlock(pos, false);
            if (!remaining.isEmpty()) Block.popResource(level, pos, remaining);
        }
    }

    private static String grainFromDoughId(String id) {
        for (final String grain : java.util.List.of("wheat", "oat", "barley", "maize", "rye", "rice")) {
            if (id.endsWith(":food/" + grain + "_dough")) return grain;
        }
        return null;
    }

    private static ItemStack foodResult(ItemStack input, Item item, int count) {
        final ItemStack output = new ItemStack(item, count);
        return FoodCapability.has(input)
            ? FoodCapability.updateFoodFromPrevious(input, output)
            : FoodCapability.setCreatedNow(output);
    }

    private static void finishProcessing(Level level, BlockPos pos, CuttingBoardBlockEntity board) {
        if (!board.consume()) level.destroyBlock(pos, false);
    }

    private static void giveOrDrop(Player player, ItemStack stack) {
        if (!player.getInventory().add(stack)) player.drop(stack, false);
    }

    private static void damageTool(Player player, ItemStack held, InteractionHand hand) {
        if (!player.isCreative()) {
            held.hurtAndBreak(1, player, hand == InteractionHand.MAIN_HAND
                ? EquipmentSlot.MAINHAND : EquipmentSlot.OFFHAND);
        }
    }

    private static void message(Player player, String key, Object... args) {
        player.displayClientMessage(Component.translatable(MESSAGE + key, args), true);
    }

    private CuttingBoardInteractions() {}
}
