package com.example.tfcfarmingplus.expansion.common;

import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.component.CustomData;
import net.minecraft.world.level.Level;
import net.dries007.tfc.util.calendar.Calendars;

/** Small, namespaced data helpers for per-stack silkworm lifecycle state. */
public final class SilkwormData {
    private static final String BIRTH_DAY = "tfcagricultureplus_birth_day";
    private static final String GROWTH = "tfcagricultureplus_growth";
    private static final String HUNGER = "tfcagricultureplus_hunger";

    public static long day(Level level) {
        return Calendars.get(level).getTotalCalendarDays();
    }

    public static void initialize(ItemStack stack, Level level) {
        initialize(stack, day(level));
    }

    public static void initialize(ItemStack stack, long day) {
        if (stack.isEmpty() || stack.getOrDefault(net.minecraft.core.component.DataComponents.CUSTOM_DATA, CustomData.EMPTY)
            .copyTag().contains(BIRTH_DAY)) return;
        CompoundTag tag = copy(stack);
        tag.putLong(BIRTH_DAY, day);
        write(stack, tag);
    }

    public static long ageDays(ItemStack stack, Level level) {
        return ageDays(stack, day(level));
    }

    public static long ageDays(ItemStack stack, long day) {
        initialize(stack, day);
        return Math.max(0L, day - copy(stack).getLong(BIRTH_DAY));
    }

    public static int growth(ItemStack stack) { return copy(stack).getInt(GROWTH); }
    public static int hunger(ItemStack stack) { return copy(stack).getInt(HUNGER); }

    public static void setGrowth(ItemStack stack, int value) {
        CompoundTag tag = copy(stack);
        tag.putInt(GROWTH, Math.max(0, value));
        write(stack, tag);
    }

    public static void setHunger(ItemStack stack, int value) {
        CompoundTag tag = copy(stack);
        tag.putInt(HUNGER, Math.max(0, value));
        write(stack, tag);
    }

    public static ItemStack adult(Level level) {
        return adult(day(level));
    }

    public static ItemStack adult(long day) {
        ItemStack stack = new ItemStack(MyItems.ADULT_SILKWORM.get());
        initialize(stack, day);
        return stack;
    }

    public static boolean ageAdult(ItemStack stack, Level level) {
        return ageAdult(stack, day(level));
    }

    public static boolean ageAdult(ItemStack stack, long day) {
        if (stack.isEmpty() || !stack.is(MyItems.ADULT_SILKWORM.get())) return false;
        long age = ageDays(stack, day);
        if (age >= AdultSilkwormItem.LIFE_DAYS) {
            stack.setCount(0);
            return true;
        }
        final int damage = (int) age;
        if (stack.getDamageValue() == damage) return false;
        stack.setDamageValue(damage);
        return true;
    }

    private static CompoundTag copy(ItemStack stack) {
        return stack.getOrDefault(net.minecraft.core.component.DataComponents.CUSTOM_DATA, CustomData.EMPTY).copyTag();
    }

    private static void write(ItemStack stack, CompoundTag tag) {
        stack.set(net.minecraft.core.component.DataComponents.CUSTOM_DATA, CustomData.of(tag));
    }

    private SilkwormData() {}
}
