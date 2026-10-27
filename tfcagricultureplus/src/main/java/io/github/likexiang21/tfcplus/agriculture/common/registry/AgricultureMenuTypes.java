package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KitchenStorageBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.SilkwormRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.menu.KitchenStorageMenu;
import io.github.likexiang21.tfcplus.agriculture.common.menu.SilkwormRackMenu;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.inventory.MenuType;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** B-owned menu registrations using TFC's block-entity container factory. */
public final class AgricultureMenuTypes {
    public static final DeferredRegister<MenuType<?>> MENUS =
        DeferredRegister.create(Registries.MENU, TFCAgriculturePlus.MOD_ID);

    public static final DeferredHolder<MenuType<?>, MenuType<SilkwormRackMenu>> SILKWORM_RACK =
        RegistrationHelpers.<SilkwormRackBlockEntity, SilkwormRackMenu>registerBlockEntityContainer(
            MENUS, "silkworm_rack", AgricultureBlockEntities.SILKWORM_RACK,
            (rack, playerInventory, windowId) -> SilkwormRackMenu.create(rack, playerInventory, windowId));

    public static final DeferredHolder<MenuType<?>, MenuType<KitchenStorageMenu>> KITCHEN_STORAGE =
        RegistrationHelpers.<KitchenStorageBlockEntity, KitchenStorageMenu>registerBlockEntityContainer(
            MENUS, "kitchen_storage", AgricultureBlockEntities.KITCHEN_STORAGE,
            (storage, playerInventory, windowId) -> KitchenStorageMenu.create(storage, playerInventory, windowId));

    private AgricultureMenuTypes() {}
}
