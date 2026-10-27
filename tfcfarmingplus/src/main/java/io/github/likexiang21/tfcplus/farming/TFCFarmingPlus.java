package io.github.likexiang21.tfcplus.farming;

import com.mojang.logging.LogUtils;
import io.github.likexiang21.tfcplus.farming.client.TFCFarmingPlusClient;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingBushes;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingWildCrops;
import io.github.likexiang21.tfcplus.farming.common.debug.FarmingDebugCommands;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlockEntities;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingCreativeTab;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingItems;
import io.github.likexiang21.tfcplus.farming.common.tree.FarmingFruitTrees;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.event.BuildCreativeModeTabContentsEvent;
import org.slf4j.Logger;

/**
 * TFC Flora —— TerraFirmaCraft 作物扩展模组。
 * <p>
 * 注册体系完全照抄 TFC 的形态：所有 DeferredRegister 在 {@code @Mod} 构造器内注册到模组总线。
 * 详见文档 {@code moddev/docs/70-crop-implementation-plan.md}。
 */
@Mod(TFCFarmingPlus.MOD_ID)
public final class TFCFarmingPlus {
    public static final String MOD_ID = "tfcfarmingplus";
    public static final Logger LOGGER = LogUtils.getLogger();

    public TFCFarmingPlus(ModContainer mod, IEventBus bus) {
        // ⚠️ 必须先触发各内容类的静态初始化，否则它们的 BLOCKS.register(...) 不会执行
        FarmingBushes.init();
        FarmingFruitTrees.init();
        FarmingCrops.init();
        FarmingWildCrops.init();
        FarmingCreativeTab.init();
        FarmingBlockEntities.init();

        FarmingBlocks.BLOCKS.register(bus);
        FarmingItems.ITEMS.register(bus);
        FarmingBlockEntities.BLOCK_ENTITIES.register(bus);
        FarmingCreativeTab.TABS.register(bus);
        bus.addListener(this::setup);
        // The original TFC strawberry bush remains registered for save compatibility,
        // but its natural generation and all creative/search entries are suppressed.
        bus.addListener(this::hideTfcStrawberryBush);

        // 客户端专属注册（渲染层 + 草色着色）。
        // ⚠️ 一个 mod 在同一加载端只能有一个 @Mod 类，所以这里是唯一的客户端挂接点：
        //    服务端下 isClient() 为 false，这行不会执行，JVM 也就不会去解析/加载
        //    TFCFarmingPlusClient（它引用了 net.minecraft.client.*）——这是安全的惰性解析。
        if (FMLEnvironment.dist == Dist.CLIENT) {
            TFCFarmingPlusClient.register(bus);
        }

        // 开发期自检命令（/tfcfarmingplus probe|randomtick|setcounter|calendar）。
        // 默认**不注册**：正式打包的模组里这几个命令不存在，玩家侧零感知。
        // 需要时用 JVM 参数 -Dtfcfarmingplus.debug=true 打开（launch-client.ps1 已带）。
        if (!FMLEnvironment.production || Boolean.getBoolean("tfcfarmingplus.debug")) {
            NeoForge.EVENT_BUS.addListener(FarmingDebugCommands::register);
            LOGGER.info("已注册 /tfcfarmingplus 自检命令（调试模式）");
        }
    }

    private void hideTfcStrawberryBush(BuildCreativeModeTabContentsEvent event) {
        final ResourceLocation floraTab = ResourceLocation.fromNamespaceAndPath("tfc", "03_tfc_flora_crops");
        if (!event.getTabKey().location().equals(floraTab)) {
            return;
        }
        final var bush = BuiltInRegistries.ITEM.get(
            ResourceLocation.fromNamespaceAndPath("tfc", "plant/strawberry_bush"));
        if (bush != net.minecraft.world.item.Items.AIR) {
            event.remove(new ItemStack(bush), CreativeModeTab.TabVisibility.PARENT_AND_SEARCH_TABS);
        }
    }

    private void setup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> {
            // 跨模组、触碰原版注册表的工作放这里
        });
    }
}
