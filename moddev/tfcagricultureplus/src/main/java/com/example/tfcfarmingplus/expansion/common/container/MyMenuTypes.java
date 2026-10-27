package com.example.tfcfarmingplus.expansion.common.container;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.example.tfcfarmingplus.expansion.common.blockentities.SilkwormRackBlockEntity;
import com.example.tfcfarmingplus.expansion.common.blockentities.KitchenStorageBlockEntity;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.inventory.MenuType;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** B-owned menu registrations using TFC's block-entity container factory. */
public final class MyMenuTypes {
    public static final DeferredRegister<MenuType<?>> MENUS =
        DeferredRegister.create(Registries.MENU, TFCAgriculturePlus.MOD_ID);

    public static final DeferredHolder<MenuType<?>, MenuType<SilkwormRackMenu>> SILKWORM_RACK =
        RegistrationHelpers.<SilkwormRackBlockEntity, SilkwormRackMenu>registerBlockEntityContainer(
            MENUS, "silkworm_rack", MyBlockEntities.SILKWORM_RACK,
            (rack, playerInventory, windowId) -> SilkwormRackMenu.create(rack, playerInventory, windowId));

    public static final DeferredHolder<MenuType<?>, MenuType<KitchenStorageMenu>> KITCHEN_STORAGE =
        RegistrationHelpers.<KitchenStorageBlockEntity, KitchenStorageMenu>registerBlockEntityContainer(
            MENUS, "kitchen_storage", MyBlockEntities.KITCHEN_STORAGE,
            (storage, playerInventory, windowId) -> KitchenStorageMenu.create(storage, playerInventory, windowId));

    private MyMenuTypes() {}
}
