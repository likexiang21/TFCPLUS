package io.github.likexiang21.tfcplus.agriculture.common.timber;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import java.util.*;
import java.util.stream.Stream;
import net.dries007.tfc.util.InteractionManager;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class TimberBlocks {
    public static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(TFCAgriculturePlus.MOD_ID);
    public static final Map<String, DeferredHolder<Block, ? extends Block>> ALL = new LinkedHashMap<>();
    /** B-owned TFC wood pieces retained under stable IDs for the independent migration. */
    public static final Set<String> LEGACY_TFC_PIECES = new LinkedHashSet<>();

    /** One block holds one full stack (64) of TFC lumber. */
    public static final DeferredHolder<Block, LumberPileBlock> LUMBER_PILE =
        BLOCKS.register("lumber_pile", () -> new LumberPileBlock(
            net.minecraft.world.level.block.state.BlockBehaviour.Properties.of()
                .strength(0.5F).noOcclusion()));

    static {
        Stream.concat(AgricultureBlocks.TFC_WOODS.stream(), AgricultureBlocks.AFC_WOODS.stream()).forEach(wood -> {
            for (int kind = 0; kind < 3; kind++) {
                final int part = kind;
                String name = List.of("debarked_log/", "debarked_half/", "debarked_quarter/").get(kind) + wood;
                var block = BLOCKS.register(name, () -> new TimberPieceBlock(AgricultureBlocks.woodProps().strength(7).requiresCorrectToolForDrops(), part));
                ALL.put(name, block);
                if (AgricultureBlocks.TFC_WOODS.contains(wood)) LEGACY_TFC_PIECES.add(name);
                AgricultureItems.ITEMS.register(name, () -> new PieceItem(block.get(), new Item.Properties()));
            }
        });
    }

    public static int weight(net.minecraft.world.item.ItemStack stack) {
        return stack.getItem() instanceof BlockItem bi && bi.getBlock() instanceof TimberPieceBlock piece ? 4 >> piece.pieceKind : 4;
    }

    /** Normalize TFC/AFC logs and B's split pieces to their shared tree species. */
    public static String woodIdentity(net.minecraft.world.item.ItemStack stack) {
        var id = BuiltInRegistries.ITEM.getKey(stack.getItem());
        String path = id.getPath();
        String species = path.substring(path.lastIndexOf('/') + 1);
        if (AgricultureBlocks.TFC_WOODS.contains(species) || AgricultureBlocks.AFC_WOODS.contains(species)) return species;
        return id.toString();
    }

    public static boolean isLegacyTfcPiece(String name) { return LEGACY_TFC_PIECES.contains(name); }

    /** Shift-use any tfc:lumber item to place one lumber into a pile, like a TFC log pile. */
    public static void registerPlacement() {
        InteractionManager.registerBlock(Ingredient.of(LumberPileBlock.LUMBER), TimberBlocks::placeLumberPile);
    }

    private static InteractionResult placeLumberPile(ItemStack stack, UseOnContext context) {
        final var player = context.getPlayer();
        if (player == null || !player.isShiftKeyDown()) return InteractionResult.PASS;
        final Level level = context.getLevel();
        final BlockPos clicked = context.getClickedPos();

        if (level.getBlockEntity(clicked) instanceof LumberPileBlockEntity pile) {
            if (level.isClientSide) return InteractionResult.SUCCESS;
            if (pile.insert(stack, false) > 0) {
                if (!player.isCreative()) stack.shrink(1);
                return InteractionResult.SUCCESS;
            }
            return InteractionResult.PASS;
        }

        final BlockPlaceContext place = new BlockPlaceContext(context);
        if (!place.canPlace()) return InteractionResult.PASS;
        final BlockPos pos = level.getBlockState(clicked).canBeReplaced(place)
            ? clicked : clicked.relative(context.getClickedFace());
        BlockState state = LUMBER_PILE.get().getStateForPlacement(place);
        if (state == null) return InteractionResult.PASS;
        state = state.setValue(LumberPileBlock.WOOD, LumberPileBlock.woodOf(stack));

        if (level.isClientSide) return InteractionResult.SUCCESS;
        level.setBlock(pos, state, Block.UPDATE_ALL);
        if (level.getBlockEntity(pos) instanceof LumberPileBlockEntity pile) {
            pile.insert(stack, false);
        }
        if (!player.isCreative()) stack.shrink(1);
        level.playSound(null, pos, net.minecraft.sounds.SoundEvents.WOOD_PLACE,
            net.minecraft.sounds.SoundSource.BLOCKS, 0.8F, 1.0F);
        return InteractionResult.SUCCESS;
    }

    public static void register(IEventBus bus) { BLOCKS.register(bus); }

    private static final class PieceItem extends BlockItem {
        PieceItem(Block block, Item.Properties properties) { super(block, properties); }
        @Override public void appendHoverText(net.minecraft.world.item.ItemStack stack, Item.TooltipContext context, java.util.List<net.minecraft.network.chat.Component> lines, net.minecraft.world.item.TooltipFlag flag) {
            super.appendHoverText(stack, context, lines, flag);
            lines.add(net.minecraft.network.chat.Component.translatable("tooltip.tfcagricultureplus.timber.pile"));
        }
    }

    private TimberBlocks() {}
}
