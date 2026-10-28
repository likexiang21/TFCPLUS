package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.block.ServingPlateBlock;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.ServingPlateBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.item.ServingPlateItem;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PlateVariant;
import java.util.LinkedHashMap;
import java.util.Map;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** One plate block family with seventeen visual variants and per-variant items. */
public final class AgriculturePlates {
    public static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(TFCAgriculturePlus.MOD_ID);
    public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(TFCAgriculturePlus.MOD_ID);
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, TFCAgriculturePlus.MOD_ID);

    public static final EnumProperty<PlateVariant> VARIANT =
        EnumProperty.create("variant", PlateVariant.class);

    public static final Map<PlateVariant, DeferredHolder<Item, Item>> ITEMS_BY_VARIANT = new LinkedHashMap<>();
    public static final Map<PlateVariant, DeferredHolder<Item, Item>> UNFIRED_BY_VARIANT = new LinkedHashMap<>();

    public static final DeferredHolder<Block, Block> PLATE = BLOCKS.register("serving_plate",
        () -> new ServingPlateBlock(net.minecraft.world.level.block.state.BlockBehaviour.Properties.of()
            .strength(0.3F).noOcclusion()));

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ServingPlateBlockEntity>> PLATE_BE =
        BLOCK_ENTITIES.register("serving_plate", () -> BlockEntityType.Builder
            .of(ServingPlateBlockEntity::new, PLATE.get()).build(null));

    public static void register(IEventBus bus) {
        for (final PlateVariant variant : PlateVariant.values()) {
            final DeferredHolder<Item, Item> holder = ITEMS.register("plate/" + variant.id(),
                () -> new ServingPlateItem(PLATE.get(), variant, new Item.Properties().stacksTo(16)));
            ITEMS_BY_VARIANT.put(variant, holder);
            if (variant != PlateVariant.WOOD) {
                final String color = variant == PlateVariant.CERAMIC_CLEAR
                    ? null : variant.id().substring("ceramic_".length());
                final String id = color == null ? "ceramic/unfired_plate" : "ceramic/" + color + "_unfired_plate";
                UNFIRED_BY_VARIANT.put(variant, ITEMS.register(id, () -> new Item(new Item.Properties())));
            }
        }
        BLOCKS.register(bus);
        ITEMS.register(bus);
        BLOCK_ENTITIES.register(bus);
    }

    public static DeferredHolder<Item, Item> itemFor(PlateVariant variant) {
        return ITEMS_BY_VARIANT.get(variant);
    }

    public static PlateVariant variantFor(Item item) {
        for (final var entry : ITEMS_BY_VARIANT.entrySet()) {
            if (entry.getValue().get() == item) return entry.getKey();
        }
        return PlateVariant.WOOD;
    }

    private AgriculturePlates() {}
}
