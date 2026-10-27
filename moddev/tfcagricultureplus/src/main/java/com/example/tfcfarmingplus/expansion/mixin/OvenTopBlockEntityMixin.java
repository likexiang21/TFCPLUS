package com.example.tfcfarmingplus.expansion.mixin;

import com.eerussianguy.firmalife.common.blockentities.OvenTopBlockEntity;
import com.example.tfcfarmingplus.expansion.common.BakingOvenRules;
import net.dries007.tfc.common.component.heat.HeatCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Firmalife already cooks timed oven recipes; reset our slots when they cool. */
@Mixin(value = OvenTopBlockEntity.class, remap = false)
public abstract class OvenTopBlockEntityMixin {
    @Shadow private int[] cookTicks;

    @Inject(method = "serverTick", at = @At("TAIL"), remap = false)
    private static void tfcap$resetUnbakedProgress(Level level, BlockPos pos, BlockState state,
                                                   OvenTopBlockEntity oven, CallbackInfo callback) {
        final int[] ticks = ((OvenTopBlockEntityMixin) (Object) oven).cookTicks;
        for (int slot = OvenTopBlockEntity.SLOT_INPUT_START; slot <= OvenTopBlockEntity.SLOT_INPUT_END; slot++) {
            if (ticks[slot] == 0) continue;
            final var stack = oven.getInventory().getStackInSlot(slot);
            if (!BakingOvenRules.isOurUnbakedFood(stack)) continue;
            final var heat = HeatCapability.get(stack);
            if (heat == null || heat.getTemperature() < BakingOvenRules.BAKING_TEMPERATURE_C) {
                ticks[slot] = 0;
                oven.setChanged();
            }
        }
    }
}
