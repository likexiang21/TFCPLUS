package com.example.tfcfarmingplus.expansion;

import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.example.tfcfarmingplus.expansion.common.MyBlocks;
import com.example.tfcfarmingplus.expansion.common.MyCreativeTab;
import com.example.tfcfarmingplus.expansion.common.MyItems;
import com.example.tfcfarmingplus.expansion.common.MyFoodTraits;
import com.example.tfcfarmingplus.expansion.common.MyWoodworkingSounds;
import com.example.tfcfarmingplus.expansion.common.container.MyMenuTypes;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeSerializers;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.ModList;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.neoforge.capabilities.Capabilities;
import net.neoforged.neoforge.capabilities.RegisterCapabilitiesEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * B 层入口 —— TFC Agriculture Plus（`tfcagricultureplus`）。
 *
 * <p>定位：建立在 A 层（TFC Farming Plus）之上的**食品加工重制层**。
 * 设计文档：`moddev/docs/126-b-module-implementation.md`。
 *
 * <p>🛑 红线 5（126 §〇.3）：**检测不到 A 时硬失败**，不静默降级 ——
 * B 的绝大多数内容都建立在 A 的 86 物种与方块之上，缺了 A 会得到一堆无意义的内容。
 *
 * <p>⚠️ 日志一律 ASCII：本机控制台是 GBK，中文会乱码（A 层踩过）。
 */
@Mod(TFCAgriculturePlus.MOD_ID)
public final class TFCAgriculturePlus {

    public static final String MOD_ID = "tfcagricultureplus";
    public static final Logger LOGGER = LoggerFactory.getLogger("TFC Agriculture Plus");

    /** A 层的 mod id —— B 的硬前置。 */
    public static final String A_MOD_ID = "tfcfarmingplus";

    public TFCAgriculturePlus(IEventBus modBus, ModContainer container) {
        // 🛑 红线 5：硬失败（不静默降级）
        if (!ModList.get().isLoaded(A_MOD_ID)) {
            throw new IllegalStateException(
                "[tfcagricultureplus] Missing required dependency: tfcfarmingplus (TFC Farming Plus). "
                    + "Do NOT install this mod standalone.");
        }

        // 注册表：**顺序敏感**（与 A 的既有顺序一致：Blocks -> Items -> BEs -> CreativeTab）
        MyBlocks.register(modBus);
        MyItems.register(modBus);
        MyWoodworkingSounds.register(modBus);
        MyFoodTraits.register(modBus);
        MyBlockEntities.register(modBus);
        MyMenuTypes.MENUS.register(modBus);
        MyCreativeTab.register(modBus);

        // 🆕 配方基建（批次 1 rev3：为后续加工配方 + JEI 适配打基础）
        // 顺序：Serializer 先于 Type（类型被引用时 serializer 必须已存在）
        MyRecipeSerializers.register(modBus);
        MyRecipeTypes.register(modBus);

        modBus.addListener(this::commonSetup);
        modBus.addListener(this::registerCapabilities);

        LOGGER.info("[TFC Agriculture Plus] loaded, dependency A version = {}",
            ModList.get().getModContainerById(A_MOD_ID)
                .map(c -> c.getModInfo().getVersion().toString()).orElse("?"));
    }

    /** Expose every TFC InventoryBlockEntity through the standard item capability. */
    private void registerCapabilities(RegisterCapabilitiesEvent event) {
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.CUTTING_BOARD.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.LOG_CUTTING_BOARD.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.MORTAR.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.DRYING_RACK.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.KNIFE_BLOCK.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.TIMBER_PILE.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.SILKWORM_RACK.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.DOUGH_TABLE.get(),
            (be, side) -> be.getSidedInventory(side));
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.PLACEABLE_FOOD.get(),
            (be, side) -> be.getInventory());
        event.registerBlockEntity(Capabilities.ItemHandler.BLOCK, MyBlockEntities.MELTING_POT.get(),
            (be, side) -> be.getSidedInventory(side));
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> {
            // Later batches hook in here: override registry self-check / recipe type registration / in_world handler
        });
    }
}
