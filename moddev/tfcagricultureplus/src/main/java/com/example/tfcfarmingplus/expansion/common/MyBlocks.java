package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.level.material.PushReaction;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.BlockGetter;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * B 层的方块注册表。
 *
 * <h2>🆕 批次 1 修订（2026-10-05，按用户口径）</h2>
 *
 * 用户口径：「**方块模型过于不可辨认，碰撞箱和实际模型不贴切，材质更多要复用 tfc（和附属模组）已有材质，
 * 涉及到木材或者石材的物品记得添加等同的材质变种**」
 *
 * <table border="1">
 *   <tr><th>问题</th><th>修法</th></tr>
 *   <tr><td>模型不可辨认</td><td>重做几何：案板 = 厚板 + 四边挡边（像真砧板）；刀架 = 背板 + 底座 + 插刀槽</td></tr>
 *   <tr><td>碰撞箱不贴合</td><td><b>每个方块实现 {@code getShape()}</b>，返回与几何一致的 {@link VoxelShape}</td></tr>
 *   <tr><td>贴图没复用 TFC</td><td>全部改用 <b>{@code tfc:block/wood/planks/&lt;wood&gt;}</b> 与 <b>{@code tfc:block/rock/&lt;form&gt;/&lt;rock&gt;}</b></td></tr>
 *   <tr><td>缺材质变种</td><td><b>木制：34 树种</b>（TFC 20 + afc 14）· <b>石制：21 岩石</b> —— 程序化注册</td></tr>
 * </table>
 *
 * <p>🛑 三条约束（126 §3.1）：
 * <ol>
 *   <li>**只放 B 自己的方块**；A 的方块从 A 的注册表**读**</li>
 *   <li>新增方块族**必须**显式接进 {@code client/TFCAgriculturePlusClient} 的渲染层清单（红线 9）</li>
 *   <li>沿用 TFC 的 BE 类的新方块，**必须**在 {@link MyBlockEntities} 登记 {@code validBlocks}</li>
 * </ol>
 */
public final class MyBlocks {

    public static final DeferredRegister.Blocks BLOCKS =
        DeferredRegister.createBlocks(TFCAgriculturePlus.MOD_ID);

    public static final DirectionProperty FACING = HorizontalDirectionalBlock.FACING;

    // ==================================================================
    // 🆕 材质清单（TFC 20 + afc 14 = 34 树种 · TFC 21 岩石）
    // ==================================================================

    /** TFC 的 20 树种。 */
    public static final List<String> TFC_WOODS = List.of(
        "acacia", "ash", "aspen", "birch", "blackwood", "chestnut", "douglas_fir", "hickory",
        "kapok", "mangrove", "maple", "oak", "palm", "pine", "rosewood", "sequoia",
        "spruce", "sycamore", "white_cedar", "willow");

    /** afc（ArborFirmaCraft）追加的 14 树种。 */
    public static final List<String> AFC_WOODS = List.of(
        "araucaria", "baobab", "beech", "cypress", "eucalyptus", "fig", "ginkgo", "hevea",
        "ipe", "ironwood", "mahoe", "mahogany", "teak", "tualang");

    /** TFC 的 21 岩石。 */
    public static final List<String> TFC_ROCKS = List.of(
        "andesite", "basalt", "chalk", "chert", "claystone", "conglomerate", "dacite", "diorite",
        "dolomite", "gabbro", "gneiss", "granite", "limestone", "marble", "phyllite", "quartzite",
        "rhyolite", "schist", "shale", "slate", "tuff");

    /**
     * 🆕 <b>适合做石臼的 15 种岩石</b>（用户口径：「查找并查证适合作为"石臼"的岩石种类」）。
     *
     * <p><b>现实依据</b>：石臼靠**研磨与撞击**工作 ⇒ 要求**硬度高、耐磨、无孔隙**。
     * <table border="1">
     *   <tr><th>类别</th><th>岩石</th><th>适合？</th><th>原因</th></tr>
     *   <tr><td><b>火成岩</b></td><td>granite · diorite · gabbro · andesite · dacite · rhyolite · basalt · tuff</td><td>✅</td><td>硬度高、结晶致密（<b>basalt 是传统石臼的主力材质</b>）</td></tr>
     *   <tr><td><b>变质岩</b></td><td>gneiss · schist · phyllite · slate · marble · quartzite</td><td>✅</td><td>变质重结晶 ⇒ 致密耐磨（<b>quartzite 硬度接近石英</b>）</td></tr>
     *   <tr><td><b>硅质岩</b></td><td>chert</td><td>✅</td><td><b>硬度 7</b>（SiO₂ 质）⇒ 最耐磨。⚠️ 中文译名是 <b>硅质岩</b>，不是"燧石"<br>（用户 2026-10-05 澄清：「chert 在 tfc 里面是硅质岩」）</td></tr>
     *   <tr><td><b>软质沉积岩</b></td><td>chalk · claystone · conglomerate · dolomite · limestone · shale</td><td>❌ <b>排除</b></td><td>硬度低 / 有孔隙 / 易碎裂 ⇒ 研磨时会掉渣（<b>现实里也不用它们做臼</b>）</td></tr>
     * </table>
     * ⇒ <b>15 种</b> = 8 火成 + 6 变质 + 1 硅质。
     */
    public static final List<String> MORTAR_ROCKS = List.of(
        // 火成岩（8）—— basalt 是传统石臼主力
        "basalt", "andesite", "dacite", "rhyolite", "granite", "diorite", "gabbro", "tuff",
        // 变质岩（6）
        "gneiss", "schist", "phyllite", "slate", "marble", "quartzite",
        // 🆕 硅质岩（1）—— 用户澄清：「chert 在 tfc 里面是硅质岩」
        //    ⚠️ 我上一版把它当"燧石"并按用户口径移除了，是**译名误解**：
        //      TFC 的 chert = **硅质岩**（SiO₂ 质沉积岩，硬度 7）⇒ 完全够格做石臼，**加回**。
        //      真正的"燧石"（flint）在 TFC 里是 `minecraft:flint`（见 groundcover/flint 的掉落表）。
        "chert");

    /** 全部注册的方块（供渲染层自检与创造页遍历）。 */
    private static final Map<String, DeferredHolder<Block, ? extends Block>> ALL = new LinkedHashMap<>();

    // ==================================================================
    // 批次 1 内容：案板（木 34 + 石 21）+ 刀具架（木 34）
    // ==================================================================

    /** 木制案板：{@code cutting_board/<wood>}。 */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> WOODEN_CUTTING_BOARDS = new LinkedHashMap<>();

    /**
     * 🆕 <b>原木案板</b>：{@code log_cutting_board/<wood>}（34 树种）。
     *
     * <p>用户口径：「**案板添加原木材质的版本以供早期使用**」
     * ⇒ 早期玩家**没有锯 / 木板**（TFC 的木板需要锯），但**原木是可得的** ⇒
     * 用**原木侧面贴图**（{@code tfc:block/wood/log/<wood>}）做一块"垫木"当案板。
     * <p>⚠️ 它与"木板案板"是**两个不同的方块 ID**（材质与配方都不同），不是同一方块的变体。
     */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> LOG_CUTTING_BOARDS = new LinkedHashMap<>();
    /** 石制案板：{@code cutting_board/<rock>}。 */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> STONE_CUTTING_BOARDS = new LinkedHashMap<>();

    /** 刀具架：{@code knife_block/<wood>}。 */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KNIFE_BLOCKS = new LinkedHashMap<>();

    /**
     * 🆕 <b>石臼方块</b>：{@code mortar/<rock>}（15 种硬质岩石）。
     *
     * <p>🛑 修订原因（用户口径：「**石臼根本不能放出，进行修复**」）：
     * 批次 1 把石臼做成了**纯物品** ⇒ **无法放置**。现在改为**方块**（可放置 · 可交互）。
     */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> MORTARS = new LinkedHashMap<>();

    /** 第一台持续加工设备：34 个木材变体共用一个干燥架方块实体。 */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> DRYING_RACKS = new LinkedHashMap<>();

    /** B-owned three-state silkworm rack. */
    public static final DeferredHolder<Block, Block> SILKWORM_RACK;

    /** K1 kitchen furniture: all six families share the TFC inventory contract. */
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_COUNTER_CABINETS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_HALF_CABINETS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_SINK_CABINETS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_SPICE_RACKS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_FOOD_DISPLAYS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, ? extends Block>> KITCHEN_FRUIT_BOWLS = new LinkedHashMap<>();
    /** K2 independent cooking device; one low-profile pan uses a TFC BE. */
    public static final DeferredHolder<Block, Block> COOKING_PAN;
    /** K3 dough forming table and a whole pie that stores servings in its BE. */
    public static final DeferredHolder<Block, Block> DOUGH_FORMING_TABLE;
    public static final DeferredHolder<Block, Block> WHOLE_PIE;
    public static final DeferredHolder<Block, Block> MELTING_POT;
    public static final DeferredHolder<Block, Block> WHOLE_CAKE;
    public static final DeferredHolder<Block, Block> CREAM_CAKE;
    public static final DeferredHolder<Block, Block> CHOCOLATE_CAKE;
    public static final DeferredHolder<Block, Block> WHOLE_CHEESE;
    public static final DeferredHolder<Block, Block> BUTTER_BLOCK;
    public static final DeferredHolder<Block, Block> JELLY_BLOCK;
    public static final DeferredHolder<Block, Block> SUGAR_BLOCK;

    static {
        // ---- 木制案板（34） ----
        for (final String wood : TFC_WOODS) {
            registerVariant(WOODEN_CUTTING_BOARDS, "cutting_board/" + wood,
                () -> new CuttingBoardBlock(woodProps()));
        }
        for (final String wood : AFC_WOODS) {
            registerVariant(WOODEN_CUTTING_BOARDS, "cutting_board/" + wood,
                () -> new CuttingBoardBlock(woodProps()));
        }
        // ---- 🆕 原木案板（34）----
        for (final String wood : TFC_WOODS) {
            registerVariant(LOG_CUTTING_BOARDS, "log_cutting_board/" + wood,
                () -> new LogCuttingBoardBlock(woodProps()));
        }
        for (final String wood : AFC_WOODS) {
            registerVariant(LOG_CUTTING_BOARDS, "log_cutting_board/" + wood,
                () -> new LogCuttingBoardBlock(woodProps()));
        }
        // ---- 石制案板（21） ----
        for (final String rock : TFC_ROCKS) {
            registerVariant(STONE_CUTTING_BOARDS, "cutting_board/" + rock,
                () -> new CuttingBoardBlock(stoneProps()));
        }
        // ---- 刀具架（34） ----
        for (final String wood : TFC_WOODS) {
            registerVariant(KNIFE_BLOCKS, "knife_block/" + wood,
                () -> new KnifeBlockBlock(woodProps().noOcclusion()));
        }
        for (final String wood : AFC_WOODS) {
            registerVariant(KNIFE_BLOCKS, "knife_block/" + wood,
                () -> new KnifeBlockBlock(woodProps().noOcclusion()));
        }
        // ---- 🆕 石臼（15 种硬质岩石） ----
        for (final String rock : MORTAR_ROCKS) {
            registerVariant(MORTARS, "mortar/" + rock,
                () -> new MortarBlock(stoneProps().noOcclusion()));
        }
        // ---- 第一台持续加工设备：干燥架（34） ----
        for (final String wood : TFC_WOODS) {
            registerVariant(DRYING_RACKS, "drying_rack/" + wood,
                () -> new DryingRackBlock(woodProps()));
        }
        for (final String wood : AFC_WOODS) {
            registerVariant(DRYING_RACKS, "drying_rack/" + wood,
                () -> new DryingRackBlock(woodProps()));
        }

        // ---- K1 kitchen furniture (34 wood variants per family) ----
        registerKitchenFamily(KITCHEN_COUNTER_CABINETS, KitchenStorageBlock.Kind.COUNTER_CABINET);
        registerKitchenFamily(KITCHEN_HALF_CABINETS, KitchenStorageBlock.Kind.HALF_CABINET);
        registerKitchenFamily(KITCHEN_SINK_CABINETS, KitchenStorageBlock.Kind.SINK_CABINET);
        registerKitchenFamily(KITCHEN_SPICE_RACKS, KitchenStorageBlock.Kind.SPICE_RACK);
        registerKitchenFamily(KITCHEN_FOOD_DISPLAYS, KitchenStorageBlock.Kind.FOOD_DISPLAY);
        registerKitchenFamily(KITCHEN_FRUIT_BOWLS, KitchenStorageBlock.Kind.FRUIT_BOWL);

        SILKWORM_RACK = BLOCKS.register("silkworm_rack",
            () -> new SilkwormRackBlock(woodProps()));
        MyItems.ITEMS.registerSimpleBlockItem("silkworm_rack", SILKWORM_RACK);
        ALL.put("silkworm_rack", SILKWORM_RACK);

        COOKING_PAN = BLOCKS.register("cooking_pan", () -> new CookingPanBlock(panProps()));
        MyItems.ITEMS.registerSimpleBlockItem("cooking_pan", COOKING_PAN);
        ALL.put("cooking_pan", COOKING_PAN);

        DOUGH_FORMING_TABLE = BLOCKS.register("dough_forming_table",
            () -> new DoughFormingTableBlock(woodProps().strength(2.0F)));
        MyItems.ITEMS.registerSimpleBlockItem("dough_forming_table", DOUGH_FORMING_TABLE);
        ALL.put("dough_forming_table", DOUGH_FORMING_TABLE);

        WHOLE_PIE = BLOCKS.register("whole_pie",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("whole_pie", WHOLE_PIE);
        ALL.put("whole_pie", WHOLE_PIE);

        MELTING_POT = BLOCKS.register("melting_pot",
            () -> new MeltingPotBlock(BlockBehaviour.Properties.of().mapColor(MapColor.METAL)
                .strength(2.0F, 6.0F).sound(SoundType.METAL).noOcclusion().requiresCorrectToolForDrops()));
        MyItems.ITEMS.registerSimpleBlockItem("melting_pot", MELTING_POT);
        ALL.put("melting_pot", MELTING_POT);

        WHOLE_CAKE = BLOCKS.register("whole_cake",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("whole_cake", WHOLE_CAKE);
        ALL.put("whole_cake", WHOLE_CAKE);

        CREAM_CAKE = BLOCKS.register("cream_cake",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("cream_cake", CREAM_CAKE);
        ALL.put("cream_cake", CREAM_CAKE);

        CHOCOLATE_CAKE = BLOCKS.register("chocolate_cake",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_BROWN)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("chocolate_cake", CHOCOLATE_CAKE);
        ALL.put("chocolate_cake", CHOCOLATE_CAKE);

        WHOLE_CHEESE = BLOCKS.register("whole_cheese",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("whole_cheese", WHOLE_CHEESE);
        ALL.put("whole_cheese", WHOLE_CHEESE);

        BUTTER_BLOCK = BLOCKS.register("butter_block",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.WOOD).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("butter_block", BUTTER_BLOCK);
        ALL.put("butter_block", BUTTER_BLOCK);

        JELLY_BLOCK = BLOCKS.register("jelly_block",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_LIGHT_BLUE)
                .strength(0.5F).sound(SoundType.WOOL).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("jelly_block", JELLY_BLOCK);
        ALL.put("jelly_block", JELLY_BLOCK);

        SUGAR_BLOCK = BLOCKS.register("sugar_block",
            () -> new PlaceableFoodBlock(BlockBehaviour.Properties.of().mapColor(MapColor.COLOR_YELLOW)
                .strength(0.5F).sound(SoundType.STONE).noOcclusion()));
        MyItems.ITEMS.registerSimpleBlockItem("sugar_block", SUGAR_BLOCK);
        ALL.put("sugar_block", SUGAR_BLOCK);
    }

    // ==================================================================
    // 属性
    // ==================================================================

    /** 通用木制家具属性。 */
    public static BlockBehaviour.Properties woodProps() {
        return BlockBehaviour.Properties.of()
            .mapColor(MapColor.WOOD)
            .strength(1.5F, 3.0F)
            .sound(SoundType.WOOD)
            .noOcclusion();
    }

    /** 通用石制家具属性。 */
    public static BlockBehaviour.Properties stoneProps() {
        return BlockBehaviour.Properties.of()
            .mapColor(MapColor.STONE)
            .strength(1.5F, 6.0F)
            .sound(SoundType.STONE)
            .noOcclusion()
            .requiresCorrectToolForDrops();
    }

    /** A low-profile cast-iron cooking surface; no inventory is stored in blockstate. */
    public static BlockBehaviour.Properties panProps() {
        return BlockBehaviour.Properties.of()
            .mapColor(MapColor.METAL)
            .strength(2.0F, 6.0F)
            .sound(SoundType.METAL)
            .noOcclusion()
            .requiresCorrectToolForDrops();
    }

    // ==================================================================
    // 方块类
    // ==================================================================

    /**
     * <b>案板</b> —— 食品加工的第一道工序（切 · 剁 · 切片 · 去核 · 切丝）。
     *
     * <p>🆕 <b>几何与碰撞箱</b>（用户口径：「碰撞箱和实际模型不贴切」）：
     * <ul>
     *   <li>板身：{@code [0,0,0] → [16,2,16]}（2 像素厚）</li>
     *   <li><b>四周挡边</b>：{@code y=2→3} 的四条窄边（让它在视觉上是一块"砧板"而不是一张纸）</li>
     *   <li>碰撞箱：{@code box(0,0,0,16,2,16)}（**只到板身**，挡边不挡人）</li>
     * </ul>
     */
    public static class CuttingBoardBlock extends HorizontalDirectionalBlock
        implements net.minecraft.world.level.block.EntityBlock {

        /** 🆕 碰撞箱：台面 14×1×14 + 四周 1px 包边（顶到 y=2）。 */
        private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.125, 0.9375);

        public CuttingBoardBlock(BlockBehaviour.Properties props) {
            super(props);
            registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
        }

        @Override
        public BlockState getStateForPlacement(net.minecraft.world.item.context.BlockPlaceContext context) {
            return defaultBlockState().setValue(FACING, context.getHorizontalDirection().getOpposite());
        }

        @Override
        protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            builder.add(FACING);
        }

        @Override
        protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
            return SHAPE;
        }

        @Override
        protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
            return simpleCodec(CuttingBoardBlock::new);
        }
        /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
        @Override
        public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                            BlockState state, net.minecraft.world.entity.player.Player player) {
            dropContentsOnBreak(level, pos);
            return super.playerWillDestroy(level, pos, state, player);
        }

        // ---------------- 🆕 耐久（BE） ----------------

        @Override
        public com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity newBlockEntity(
            BlockPos pos, BlockState state) {
            return new com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity(pos, state);
        }

        /** 🛑 返回 null ⇒ 不 tick。 */
        @Override
        public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
            net.minecraft.world.level.Level level, BlockState state,
            net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
            return null;
        }

        /**
         * 🆕 <b>右键：把食材摊到板上 / 从板上取回</b>
         * —— 用户口径：「砧板交互也要保证**物品的可见性**」（放上去的东西必须能看见）。
         * <ol>
         *   <li>手持物品 ⇒ **放到板上**（之后由 {@code CuttingBoardBlockEntityRenderer} **直接渲染**出来）</li>
         *   <li>空手 ⇒ **取回**板上的物品；板也是空的时候 ⇒ 提示剩余耐久</li>
         * </ol>
         * Cutting is handled by the board recipe type; block transformations use in_world.
         */
        @Override
        protected net.minecraft.world.InteractionResult useWithoutItem(
            BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
            net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {

            if (!level.isClientSide()) {
                CuttingBoardInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
            }
            return net.minecraft.world.InteractionResult.sidedSuccess(level.isClientSide());
        }

        @Override
        protected net.minecraft.world.ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack,
            BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
            net.minecraft.world.entity.player.Player player, net.minecraft.world.InteractionHand hand,
            net.minecraft.world.phys.BlockHitResult hit) {
            if (!level.isClientSide()) CuttingBoardInteractions.interact(level, pos, player, hand);
            return net.minecraft.world.ItemInteractionResult.sidedSuccess(level.isClientSide());
        }

        @Override
        protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                                BlockState replacement, boolean moving) {
            if (!state.is(replacement.getBlock())) dropContentsOnBreak(level, pos);
            super.onRemove(state, level, pos, replacement, moving);
        }
    }

    /**
     * 🆕 <b>原木案板</b> —— 用户口径：「原木类型的案板应该显示为一个"**木桩子**"」+「模型太高，**压扁**」。
     *
     * <p>所以它**不复用案板的几何**，而是**矮的一段原木（树桩）**：
     * <ul>
     *   <li>柱身：{@code [2,0,2] → [14,5,14]}（12×**5**×12 —— 已按用户口径从 10 压到 5）</li>
     *   <li><b>侧面 = 树皮</b>（{@code tfc/afc:block/wood/log/<wood>}）</li>
     *   <li><b>顶面 = 年轮截面</b>（{@code tfc/afc:block/wood/log_top/<wood>}）</li>
     *   <li>碰撞箱：{@code box(0.125, 0, 0.125, 0.875, 0.3125, 0.875)}</li>
     * </ul>
     * Shares cutting, storage and durability with the other boards, with a separate BE type.
     */
    public static class LogCuttingBoardBlock extends CuttingBoardBlock {

        /** 树桩的碰撞箱（与几何一致：12 宽 × 5 高）。 */
        private static final VoxelShape SHAPE = Shapes.box(0.125, 0.0, 0.125, 0.875, 0.3125, 0.875);

        public LogCuttingBoardBlock(BlockBehaviour.Properties props) {
            super(props);
            registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
        }

        @Override
        protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            builder.add(FACING);
        }

        @Override
        protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
            return SHAPE;
        }

        @Override
        protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
            return simpleCodec(LogCuttingBoardBlock::new);
        }
        /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
        @Override
        public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                            BlockState state, net.minecraft.world.entity.player.Player player) {
            dropContentsOnBreak(level, pos);
            return super.playerWillDestroy(level, pos, state, player);
        }

        // 🆕 耐久（用户口径：「原木案板也要做耐久」）
        // 🛑 必须用 **LOG_CUTTING_BOARD** 这个 BE 类型（不是 CUTTING_BOARD）——
        //    用错类型会立刻崩：IllegalStateException: Invalid block entity（本轮实测）
        @Override
        public com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity newBlockEntity(
            BlockPos pos, BlockState state) {
            return new com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity(
                MyBlockEntities.LOG_CUTTING_BOARD.get(), pos, state);
        }

        @Override
        public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
            net.minecraft.world.level.Level level, BlockState state,
            net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
            return null;
        }
    }

    /**
     * <b>刀具架</b> —— 与案板配套（放刀 / 取刀）。
     *
     * <p>🆕 <b>几何与碰撞箱</b>：
     * <ul>
     *   <li>背板：{@code [0,0,10] → [16,15,12]}（贴墙的立板）</li>
     *   <li>底座：{@code [0,0,6] → [16,3,12]}</li>
     *   <li>两道横档：{@code y=4→5} 与 {@code y=9→10}（视觉上"插着刀"）</li>
     *   <li>碰撞箱：{@code box(0,0,6/16,16,15/16,12/16)}（背板 + 底座的整体）</li>
     * </ul>
     */
    public static class KnifeBlockBlock extends HorizontalDirectionalBlock
        implements net.minecraft.world.level.block.EntityBlock {

        private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.3125, 0.9375, 0.875, 0.75);

        public KnifeBlockBlock(BlockBehaviour.Properties props) {
            super(props);
            registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
        }

        @Override
        protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            builder.add(FACING);
        }

        @Override
        protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
            return SHAPE;
        }

        @Override
        protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
            return simpleCodec(KnifeBlockBlock::new);
        }
        /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
        @Override
        public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                            BlockState state, net.minecraft.world.entity.player.Player player) {
            dropContentsOnBreak(level, pos);
            return super.playerWillDestroy(level, pos, state, player);
        }

        // ---------------- 🆕 存储功能（BE） ----------------

        @Override
        public com.example.tfcfarmingplus.expansion.common.blockentities.KnifeBlockBlockEntity newBlockEntity(
            BlockPos pos, BlockState state) {
            return new com.example.tfcfarmingplus.expansion.common.blockentities.KnifeBlockBlockEntity(pos, state);
        }

        /** 🛑 返回 null ⇒ **不 tick**（性能红线：空闲零开销）。 */
        @Override
        public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
            net.minecraft.world.level.Level level, BlockState state,
            net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
            return null;
        }

        /**
         * 🆕 右键交互（**第一版的"无 GUI 存取"**）：
         * <ul>
         *   <li>手持物品 ⇒ **存入**（放不下则提示）</li>
         *   <li>空手 ⇒ **取出**最后放入的一件</li>
         * </ul>
         * ⚠️ GUI 留到批次 9（调料系统）一起做。
         */
        @Override
        protected net.minecraft.world.InteractionResult useWithoutItem(
            BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
            net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {

            if (level.isClientSide()) {
                return net.minecraft.world.InteractionResult.SUCCESS;
            }
            if (!(level.getBlockEntity(pos)
                    instanceof com.example.tfcfarmingplus.expansion.common.blockentities.KnifeBlockBlockEntity be)) {
                return net.minecraft.world.InteractionResult.PASS;
            }

            final net.minecraft.world.item.ItemStack held = player.getMainHandItem();

            if (!held.isEmpty()) {
                // 存入（🆕 现在走**白名单**：只能放工具与调料罐，见 MyTags）
                if (be.store(held)) {
                    if (!player.isCreative()) {
                        held.shrink(1);
                    }
                    level.playSound(null, pos, net.minecraft.sounds.SoundEvents.ITEM_PICKUP,
                        net.minecraft.sounds.SoundSource.BLOCKS, 0.6F, 1.2F);
                    return net.minecraft.world.InteractionResult.CONSUME;
                }
                // 🆕 区分"满了"与"这个物品不能放"
                player.displayClientMessage(
                    net.minecraft.network.chat.Component.translatable(
                        be.isItemValid(held)
                            ? "message.tfcagricultureplus.knife_block.full"
                            : "message.tfcagricultureplus.knife_block.invalid"), true);
                return net.minecraft.world.InteractionResult.CONSUME;
            }

            // 取出
            final net.minecraft.world.item.ItemStack out = be.takeLast();
            if (out.isEmpty()) {
                player.displayClientMessage(
                    net.minecraft.network.chat.Component.translatable(
                        "message.tfcagricultureplus.knife_block.empty"), true);
                return net.minecraft.world.InteractionResult.CONSUME;
            }
            if (!player.getInventory().add(out)) {
                player.drop(out, false);
            }
            level.playSound(null, pos, net.minecraft.sounds.SoundEvents.ITEM_PICKUP,
                net.minecraft.sounds.SoundSource.BLOCKS, 0.6F, 0.9F);
            return net.minecraft.world.InteractionResult.CONSUME;
        }

        @Override
        protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                                BlockState replacement, boolean moving) {
            if (!state.is(replacement.getBlock())) dropContentsOnBreak(level, pos);
            super.onRemove(state, level, pos, replacement, moving);
        }
    }

    /**
     * 🆕 <b>石臼</b>（{@code mortar}）—— 手持研磨的**固定版**（磨香料 · 磨粉 · 捣碎）。
     *
     * <p>几何：底座 + 四周壁（中间凹），碰撞箱为**整方块**（玩家站上去/靠着都自然）。
     * <p>⚠️ 与 TFC {@code quern} 的分工见 {@link MyItems}（臼=小批量/粗磨，磨=大批量/细粉）。
     */
    public static class MortarBlock extends HorizontalDirectionalBlock
        implements net.minecraft.world.level.block.EntityBlock {

        /** 碰撞箱：整方块（凹槽只是视觉）。 */
        private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.5625, 0.9375);

        public MortarBlock(BlockBehaviour.Properties props) {
            super(props);
            registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
        }

        @Override
        protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            builder.add(FACING);
        }

        @Override
        protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
            return SHAPE;
        }

        @Override
        protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
            return simpleCodec(MortarBlock::new);
        }
        /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
        @Override
        public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                            BlockState state, net.minecraft.world.entity.player.Player player) {
            dropContentsOnBreak(level, pos);
            return super.playerWillDestroy(level, pos, state, player);
        }

        // ---------------- 🆕 容器（参考 Firmalife 的搅拌碗） ----------------

        @Override
        public com.example.tfcfarmingplus.expansion.common.blockentities.MortarBlockEntity newBlockEntity(
            BlockPos pos, BlockState state) {
            return new com.example.tfcfarmingplus.expansion.common.blockentities.MortarBlockEntity(pos, state);
        }

        /** 🛑 返回 null ⇒ 不 tick。 */
        @Override
        public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
            net.minecraft.world.level.Level level, BlockState state,
            net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
            return null;
        }

        /**
         * 🆕 右键交互（**无 GUI**，与刀架同一套思路）：
         * <ol>
         *   <li>手持<b>石杵</b> ⇒ <b>研磨</b>：按 {@code grind_time} 记录敲击次数，完成后
         *       ① 消耗内容物 ② <b>石杵每次敲击消耗 1 点耐久</b> ③ 产物直接给玩家</li>
         *   <li>手持<b>其他物品</b> ⇒ <b>放入</b>（石臼空时）</li>
         *   <li><b>空手</b> ⇒ 取出内容物</li>
         * </ol>
         */
        @Override
        protected net.minecraft.world.InteractionResult useWithoutItem(
            BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
            net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {
            com.example.tfcfarmingplus.expansion.common.MortarInteractions.interact(
                level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
            return net.minecraft.world.InteractionResult.sidedSuccess(level.isClientSide());
        }

        @Override
        protected net.minecraft.world.ItemInteractionResult useItemOn(
            net.minecraft.world.item.ItemStack stack, BlockState state,
            net.minecraft.world.level.Level level, BlockPos pos,
            net.minecraft.world.entity.player.Player player, net.minecraft.world.InteractionHand hand,
            net.minecraft.world.phys.BlockHitResult hit) {
            com.example.tfcfarmingplus.expansion.common.MortarInteractions.interact(level, pos, player, hand);
            return net.minecraft.world.ItemInteractionResult.sidedSuccess(level.isClientSide());
        }

        @Override
        protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                                BlockState replacement, boolean moving) {
            if (!state.is(replacement.getBlock())) dropContentsOnBreak(level, pos);
            super.onRemove(state, level, pos, replacement, moving);
        }
    }

    // ==================================================================
    // 🆕 通用：方块被破坏时掉落内部物品
    // ==================================================================

    /**
     * 🆕 <b>把 BE 里的内容物吐到地上</b> —— 用户口径：
     * 「**内部存储物品的方块被破坏时要掉落内部物品**」。
     *
     * <p>🛑 <b>为什么用 {@code playerWillDestroy} 而不是 {@code BlockEntity#preRemoveSideEffects}</b>：
     * 后者是 **1.21.2+** 才有的 API，在 1.21.1 上编译报"无法覆盖或实现超类型的方法"（本轮实测踩到）。
     * 1.21.1 的可用钩子是 {@code BlockBehaviour#playerWillDestroy(Level, BlockPos, BlockState, Player)}，
     * ⚠️ 它的返回类型是 **{@code BlockState}**（不是 void —— 这也是本轮踩到的第二个签名坑）。
     *
     * <p>⚠️ 覆盖范围：**只在玩家破坏时触发**（不含爆炸/活塞）—— 对"架子/案板"这类
     * 玩家手拆的方块够用；爆炸掉落留到后续批次（可用 `BlockEntity#setRemoved` 兜底）。
     */
    public static void dropContentsOnBreak(net.minecraft.world.level.Level level, BlockPos pos) {
        if (level.isClientSide()) {
            return;
        }
        final net.minecraft.world.level.block.entity.BlockEntity be = level.getBlockEntity(pos);
        if (be == null) {
            return;
        }
        if (be instanceof com.example.tfcfarmingplus.expansion.common.blockentities.KnifeBlockBlockEntity k) {
            final net.minecraft.world.item.ItemStack s = k.takeLast();
            while (!s.isEmpty()) {
                net.minecraft.world.Containers.dropItemStack(level, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, s);
                final net.minecraft.world.item.ItemStack next = k.takeLast();
                if (next.isEmpty()) {
                    break;
                }
                net.minecraft.world.Containers.dropItemStack(level, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, next);
            }
        } else if (be instanceof com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity c) {
            final net.minecraft.world.item.ItemStack s = c.takeFromBoard();
            if (!s.isEmpty()) {
                net.minecraft.world.Containers.dropItemStack(level, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, s);
            }
        } else if (be instanceof com.example.tfcfarmingplus.expansion.common.blockentities.MortarBlockEntity m) {
            final net.minecraft.world.item.ItemStack s = m.extract();
            if (!s.isEmpty()) {
                net.minecraft.world.Containers.dropItemStack(level, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, s);
            }
        }
    }

    // ==================================================================
    // 注册辅助
    // ==================================================================

    /**
     * 注册一个**材质变种**方块：{@code <name>} 已在调用处带上目录前缀（如 {@code cutting_board/oak}）。
     * ⚠️ {@code DeferredRegister} 的 name 里**允许斜杠**（TFC 的 {@code wood/planks/oak} 就是这种写法）。
     */
    private static void registerVariant(Map<String, DeferredHolder<Block, ? extends Block>> into,
                                        String name, Supplier<Block> factory) {
        final DeferredHolder<Block, Block> holder = BLOCKS.register(name, factory);
        MyItems.ITEMS.registerSimpleBlockItem(name, holder);
        into.put(name, holder);
        ALL.put(name, holder);
    }

    private static void registerKitchenFamily(Map<String, DeferredHolder<Block, ? extends Block>> into,
                                               KitchenStorageBlock.Kind kind) {
        for (final String wood : TFC_WOODS) {
            registerVariant(into, kind.id() + "/" + wood,
                () -> new KitchenStorageBlock(woodProps(), kind));
        }
        for (final String wood : AFC_WOODS) {
            registerVariant(into, kind.id() + "/" + wood,
                () -> new KitchenStorageBlock(woodProps(), kind));
        }
    }

    /** 全部方块（供渲染层自检 / 创造页）。 */
    public static List<DeferredHolder<Block, ? extends Block>> all() {
        var result = new ArrayList<>(ALL.values());
        result.addAll(DRYING_RACKS.values());
        result.addAll(com.example.tfcfarmingplus.expansion.common.timber.TimberBlocks.ALL.values());
        return result;
    }

    /** 全部方块的注册 ID（不含命名空间），供渲染层自检与台账。 */
    public static List<String> allIds() {
        var result = new ArrayList<>(ALL.keySet());
        result.addAll(DRYING_RACKS.keySet());
        result.addAll(com.example.tfcfarmingplus.expansion.common.timber.TimberBlocks.ALL.keySet());
        return result;
    }

    public static void register(IEventBus bus) {
        BLOCKS.register(bus);
        com.example.tfcfarmingplus.expansion.common.timber.TimberBlocks.register(bus);
    }

    private MyBlocks() {}
}
