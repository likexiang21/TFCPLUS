package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;

/**
 * B 层的 <b>tag</b> 常量。
 *
 * <h2>🆕 rev7：白名单机制（学 TFC 的工具架）</h2>
 * 实测 TFC 的 {@code ToolRackBlockEntity#isItemValid} **内部查 tag**
 * {@code tfc:usable_on_tool_rack}（实测内容：{@code ["#c:tools","#tfc:sewing_needles","tfc:sandpaper","minecraft:spyglass"]}）。
 *
 * <p>⇒ 我们照同一套做法，给刀具架定义 {@link Items#USABLE_ON_KNIFE_BLOCK}。
 * 🎯 <b>用 tag 而不是硬编码清单的好处</b>：
 * <ul>
 *   <li>**玩家 / 整合包作者可以自己改**（数据包覆盖 json 即可）</li>
 *   <li>**其它模组可以主动加入**（把自己的刀加进我们的 tag）</li>
 *   <li>**不依赖具体物品 ID** ⇒ 兼容性最好</li>
 * </ul>
 *
 * <p>⚠️ tag 文件必须写进**我们自己的命名空间**（`data/tfcagricultureplus/tags/...`）
 * —— 遵守红线 2/7（不覆盖邻居命名空间；改写邻居 tag 时必须 `replace: false`）。
 */
public final class AgricultureTags {

    /** 物品 tag。 */
    public static final class Items {

        /**
         * 🆕 <b>可以挂在刀具架上的物品</b>。
         *
         * <p>实测 TFC 的对应 tag 内容是 {@code ["#c:tools","#tfc:sewing_needles","tfc:sandpaper","minecraft:spyglass"]}
         * —— 即"**各类工具 + 少量小物件**"。
         *
         * <p>我们的内容（见 {@code data/tfcagricultureplus/tags/item/usable_on_knife_block.json}）：
         * <ul>
         *   <li>{@code #c:tools} —— 通用工具（含 TFC 的 9 种金属刀）</li>
         *   <li>{@code #tfc:usable_on_tool_rack} ⭐ —— **直接继承 TFC 的白名单**（TFC 加了什么我们就有什么）</li>
         *   <li>🆕 未来的**调料罐**（批次 9 加入时直接改 json，不用改代码）</li>
         * </ul>
         */
        public static final TagKey<Item> USABLE_ON_KNIFE_BLOCK =
            ItemTags.create(ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "usable_on_knife_block"));

        /** Canonical feed inputs for the B silkworm rack. */
        public static final TagKey<Item> SILKWORM_FEED =
            ItemTags.create(ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "silkworm_feed"));

        private Items() {}
    }

    /** 方块 tag。 */
    public static final class Blocks {

        /** 未来的方块 tag 放这里（v1 暂空）。 */
        public static final TagKey<Block> NONE =
            BlockTags.create(ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "none"));

        private Blocks() {}
    }

    private AgricultureTags() {}
}
