package io.github.likexiang21.tfcplus.farming.common.block;

import io.github.likexiang21.tfcplus.farming.common.debug.FastGrow;
import java.util.function.Supplier;
import net.dries007.tfc.common.blockentities.CropBlockEntity;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.CropBlock;
import net.dries007.tfc.common.blocks.crop.DeadCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/**
 * 莲座式作物 —— <b>本模组的新机制 ①</b>。
 * <p>
 * 与 TFC 现有 6 种作物形态的差异：
 * <ul>
 *   <li>TFC 作物：age 0→7 表示「长得更高」，成熟时整株就是可收状态；</li>
 *   <li>莲座植物：{@code AGE} 表示「叶片轮数」（横向规模），另有一个独立的
 *       {@link #FRUITING} 状态表示「中心是否已结出果实」。</li>
 * </ul>
 * 现实依据：菠萝、龙舌兰、剑麻、芦荟都是「叶片自中心向外轮生、果实从植株中心长出」的形态，
 * TFC 的线性拔高模型表达不了。
 * <p>
 * 用法：6 个 AGE 模型 × 2 个 FRUITING 状态 = 12 个模型；
 * 掉落表按 {@code fruiting: true} 判条件给果实，并必定掉 1~2 个侧芽（侧芽即该作物的"种子"）。
 */
public class RosetteCropBlock extends CropBlock {
    /** 六个视觉阶段；生长时长由 TFC 历法、气候、养分及配置共同决定。 */
    private static final IntegerProperty AGE = TFCBlockStateProperties.getAgeProperty(5);
    /** 中心是否已结果 —— 与 TFC 作物的唯一结构差异 */
    public static final BooleanProperty FRUITING = BooleanProperty.create("fruiting");

    public RosetteCropBlock(ExtendedProperties properties,
                            Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                            float nitrogen, float phosphorous, float potassium,
                            Supplier<ClimateRange> climateRange) {
        super(properties, 5, dead, seeds, nitrogen, phosphorous, potassium, climateRange);
        registerDefaultState(defaultBlockState().setValue(AGE, 0).setValue(FRUITING, false));
    }

    @Override
    public IntegerProperty getAgeProperty() {
        return AGE;
    }

    /** 必须覆写：父类只注册了 ageProperty，这里补上 FRUITING */
    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(AGE, FRUITING);
    }

    @Override
    protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop) {
        // 显式启用的调试开关；正常启动不启用，基础生长仍由 TFC 处理。
        float growth = crop.getGrowth();
        if (io.github.likexiang21.tfcplus.farming.common.debug.FastGrow.ENABLED) {
            growth = Math.min(1.0f, growth * io.github.likexiang21.tfcplus.farming.common.debug.FastGrow.CROP_MULTIPLIER);
            crop.setGrowth(growth);
        }
        // 两个显示属性始终来自同一份进度，也纠正旧幼苗遗留的 fruiting=true。
        BlockState updated = state.setValue(AGE, (int) (growth * 5))
            .setValue(FRUITING, growth >= 1.0f);
        if (updated != state) {
            level.setBlockAndUpdate(pos, updated);
        }
    }

    /** 共享死株不保存物种；仅在服务端成功换成死株后返还一份对应侧芽。 */
    @Override
    public void die(Level level, BlockPos pos, BlockState state, boolean fullyGrown) {
        if (level.isClientSide() || !level.getBlockState(pos).is(this)) {
            return;
        }
        if (level.setBlockAndUpdate(pos, dead.get().defaultBlockState()
            .setValue(DeadCropBlock.MATURE, fullyGrown))) {
            Block.popResource(level, pos, new ItemStack(seeds.get()));
        }
    }
}
