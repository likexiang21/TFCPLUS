package io.github.likexiang21.tfcplus.farming.common.registry;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 创造模式标签页。
 * <p>
 * <b>为什么必须有</b>：MC 的物品除非被某个 {@link CreativeModeTab} 收录，否则在创造模式物品栏里
 * 根本查不到（物品仍然存在于注册表中，但没有任何入口）。TFC 是把内容塞进它自己的标签页，
 * 附属模组塞不进去，所以必须自建一个。
 * <p>
 * 收纳方式：直接遍历 {@link FarmingItems#ITEMS} 的全部条目 —— 包括通过
 * {@code RegistrationHelpers.registerBlock(blocks, items, ...)} 注册的方块物品
 * （浆果灌木、野生作物），因此以后新增物品无需再改这个文件。
 */
public final class FarmingCreativeTab {
    public static final DeferredRegister<CreativeModeTab> TABS =
        DeferredRegister.create(Registries.CREATIVE_MODE_TAB, TFCFarmingPlus.MOD_ID);

    public static final DeferredHolder<CreativeModeTab, CreativeModeTab> MAIN = TABS.register("main",
        () -> CreativeModeTab.builder()
            .title(Component.translatable("itemGroup.tfcfarmingplus.main"))
            .icon(() -> new ItemStack(FarmingItems.LINGONBERRY.get()))
            .displayItems((params, output) -> FarmingItems.ITEMS.getEntries().stream()
                .filter(reg -> !java.util.Set.of("food/strawberry", "food/cupuacu", "food/cocoa",
                    "plant/cocoa_sapling", "plant/cocoa_leaves")
                    .contains(reg.getId().getPath()))
                .forEach(reg -> output.accept(reg.get())))
            .build());

    /** 触发静态初始化 —— 主类必须调用一次 */
    public static void init() {}

    private FarmingCreativeTab() {}
}
