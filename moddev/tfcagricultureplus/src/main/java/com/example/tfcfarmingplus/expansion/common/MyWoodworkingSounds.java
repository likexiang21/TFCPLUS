package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundEvent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** B-owned sound events used by the migrated woodwork recipes. */
public final class MyWoodworkingSounds {
    public static final DeferredRegister<SoundEvent> SOUNDS =
        DeferredRegister.create(BuiltInRegistries.SOUND_EVENT.key(), TFCAgriculturePlus.MOD_ID);
    public static final DeferredHolder<SoundEvent, SoundEvent> WOOD_CHOP = register("wood_chop");
    public static final DeferredHolder<SoundEvent, SoundEvent> WOOD_SAWED = register("wood_sawed");
    public static final DeferredHolder<SoundEvent, SoundEvent> WOOD_HIT_GROUND = register("wood_hit_ground");

    private static DeferredHolder<SoundEvent, SoundEvent> register(String name) {
        return SOUNDS.register(name, () -> SoundEvent.createVariableRangeEvent(
            ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, name)));
    }

    public static void register(IEventBus bus) { SOUNDS.register(bus); }
    private MyWoodworkingSounds() {}
}
