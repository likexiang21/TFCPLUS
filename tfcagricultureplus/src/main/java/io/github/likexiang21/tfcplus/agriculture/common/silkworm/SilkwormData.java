package io.github.likexiang21.tfcplus.agriculture.common.silkworm;

import io.github.likexiang21.tfcplus.agriculture.common.item.AdultSilkwormItem;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import net.dries007.tfc.util.calendar.Calendars;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.component.CustomData;
import net.minecraft.world.level.Level;

/** Small, namespaced data helpers for per-stack silkworm lifecycle state. */
public final class SilkwormData {
    private static final String BIRTH_DAY = "tfcagricultureplus_birth_day";
    private static final String GROWTH = "tfcagricultureplus_growth";
    private static final String HUNGER = "tfcagricultureplus_hunger";

    public static long currentDay(Level level) {
        return Calendars.get(level).getTotalCalendarDays();
    }

    public static void initialize(ItemStack stack, Level level) {
        initialize(stack, currentDay(level));
    }

    public static void initialize(ItemStack stack, long currentDay) {
        if (stack.isEmpty() || stack.getOrDefault(net.minecraft.core.component.DataComponents.CUSTOM_DATA, CustomData.EMPTY)
            .copyTag().contains(BIRTH_DAY)) return;
        CompoundTag compoundTag = copy(stack);
        compoundTag.putLong(BIRTH_DAY, currentDay);
        write(stack, compoundTag);
    }

    public static long ageDays(ItemStack stack, Level level) {
        return ageDays(stack, currentDay(level));
    }

    public static long ageDays(ItemStack stack, long currentDay) {
        initialize(stack, currentDay);
        return Math.max(0L, currentDay - copy(stack).getLong(BIRTH_DAY));
    }

    public static int growth(ItemStack stack) { return copy(stack).getInt(GROWTH); }
    public static int hunger(ItemStack stack) { return copy(stack).getInt(HUNGER); }

    public static void setGrowth(ItemStack stack, int value) {
        CompoundTag compoundTag = copy(stack);
        compoundTag.putInt(GROWTH, Math.max(0, value));
        write(stack, compoundTag);
    }

    public static void setHunger(ItemStack stack, int value) {
        CompoundTag compoundTag = copy(stack);
        compoundTag.putInt(HUNGER, Math.max(0, value));
        write(stack, compoundTag);
    }

    public static ItemStack adult(Level level) {
        return adult(currentDay(level));
    }

    public static ItemStack adult(long currentDay) {
        ItemStack stack = new ItemStack(AgricultureItems.ADULT_SILKWORM.get());
        initialize(stack, currentDay);
        return stack;
    }

    public static boolean ageAdult(ItemStack stack, Level level) {
        return ageAdult(stack, currentDay(level));
    }

    public static boolean ageAdult(ItemStack stack, long currentDay) {
        if (stack.isEmpty() || !stack.is(AgricultureItems.ADULT_SILKWORM.get())) return false;
        long age = ageDays(stack, currentDay);
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

    private static void write(ItemStack stack, CompoundTag compoundTag) {
        stack.set(net.minecraft.core.component.DataComponents.CUSTOM_DATA, CustomData.of(compoundTag));
    }

    private SilkwormData() {}
}
