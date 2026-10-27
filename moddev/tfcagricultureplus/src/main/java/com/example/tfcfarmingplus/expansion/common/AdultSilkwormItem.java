package com.example.tfcfarmingplus.expansion.common;

import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.level.Level;

import java.util.List;

/** An unstackable adult whose seven-day lifespan is represented by durability. */
public final class AdultSilkwormItem extends Item {
    public static final int LIFE_DAYS = 7;

    public AdultSilkwormItem() {
        super(new Item.Properties().stacksTo(1).durability(LIFE_DAYS));
    }

    @Override
    public boolean isBarVisible(ItemStack stack) {
        return true;
    }

    @Override
    public int getBarWidth(ItemStack stack) {
        final int maxDamage = stack.getMaxDamage();
        return maxDamage <= 0 ? 0 : Math.max(0, 13 * (maxDamage - stack.getDamageValue()) / maxDamage);
    }

    @Override
    public int getBarColor(ItemStack stack) {
        return ChatFormatting.GREEN.getColor() == null ? 0x62B84A : ChatFormatting.GREEN.getColor();
    }

    @Override
    public void inventoryTick(ItemStack stack, Level level, Entity entity, int slotId, boolean selected) {
        if (!level.isClientSide()) SilkwormData.ageAdult(stack, level);
        super.inventoryTick(stack, level, entity, slotId, selected);
    }

    @Override
    public boolean onEntityItemUpdate(ItemStack stack, ItemEntity entity) {
        if (!entity.level().isClientSide()) {
            SilkwormData.ageAdult(stack, entity.level());
            if (stack.isEmpty()) entity.discard();
        }
        return false;
    }

    @Override
    public void appendHoverText(ItemStack stack, TooltipContext context, List<Component> tooltip, TooltipFlag flag) {
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.adult_silkworm_lifespan"));
        tooltip.add(Component.translatable("tooltip.tfcagricultureplus.adult_silkworm_remaining",
            Math.max(0, stack.getMaxDamage() - stack.getDamageValue())));
        super.appendHoverText(stack, context, tooltip, flag);
    }
}
