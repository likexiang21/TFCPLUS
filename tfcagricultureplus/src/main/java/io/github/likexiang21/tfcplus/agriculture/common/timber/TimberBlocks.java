package io.github.likexiang21.tfcplus.agriculture.common.timber;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import java.util.*;
import java.util.stream.Stream;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
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
    public static final DeferredHolder<Item, Item> LUMBER_PILE_ITEM =
        AgricultureItems.ITEMS.register("lumber_pile",
            () -> new BlockItem(LUMBER_PILE.get(), new Item.Properties()));

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
        ALL.put("lumber_pile", LUMBER_PILE);
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
