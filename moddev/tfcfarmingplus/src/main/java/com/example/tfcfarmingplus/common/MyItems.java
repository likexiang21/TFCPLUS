package com.example.tfcfarmingplus.common;

import com.example.tfcfarmingplus.TFCFarmingPlus;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.Item;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 物品注册。产物食物统一走 {@code tfcfarmingplus:food/<name>}（照 TFC 的命名），
 * 种子走 {@code tfcfarmingplus:seeds/<name>}。
 */
public final class MyItems {
    public static final DeferredRegister<Item> ITEMS = DeferredRegister.create(Registries.ITEM, TFCFarmingPlus.MOD_ID);

    // ---------------- 批次 1：灌木浆果产物（10 种） ----------------

    public static final DeferredHolder<Item, Item> LINGONBERRY = food("lingonberry");
    public static final DeferredHolder<Item, Item> BEARBERRY = food("bearberry");
    public static final DeferredHolder<Item, Item> CROWBERRY = food("crowberry");
    public static final DeferredHolder<Item, Item> BILBERRY = food("bilberry");
    public static final DeferredHolder<Item, Item> BLACKCURRANT = food("blackcurrant");
    public static final DeferredHolder<Item, Item> REDCURRANT = food("redcurrant");
    public static final DeferredHolder<Item, Item> HASKAP = food("haskap");
    public static final DeferredHolder<Item, Item> GOJI = food("goji");
    public static final DeferredHolder<Item, Item> SERVICEBERRY = food("serviceberry");
    public static final DeferredHolder<Item, Item> ARONIA = food("aronia");

    // ---------------- 批次 4：茶树 / 咖啡树产物（占位） ----------------
    // 茶与咖啡都是**灌木**（不是耕地作物），这里先给一个可食用的占位产物，
    // 后续的加工链（萎凋 / 烘焙 / 冲泡）另做。
    public static final DeferredHolder<Item, Item> TEA_LEAF = food("tea_leaf");
    public static final DeferredHolder<Item, Item> COFFEE_BEAN = food("coffee_bean");
    /** 第 14 步：草莓普通作物产物。 */
    public static final DeferredHolder<Item, Item> STRAWBERRY = food("strawberry");

    /** 注册一个食物物品（营养与保质期由 data/tfcfarmingplus/tfc/food/*.json 提供） */
    private static DeferredHolder<Item, Item> food(String name) {
        return ITEMS.register("food/" + name, () -> new Item(new Item.Properties()));
    }

    private MyItems() {}
}
