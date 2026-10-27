package com.example.tfcfarmingplus.common.blockentities;

import com.example.tfcfarmingplus.common.MyBlockEntities;
import net.dries007.tfc.common.blockentities.DecayingBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;

/**
 * 结果方块（瓜类整瓜与腐烂瓜）的方块实体。
 * <p>
 * 存在的唯一理由与 {@link MyBerryBushBlockEntity} 相同：TFC 的 {@link DecayingBlockEntity}
 * 里带类型参数的构造器是 {@code protected}，而公开构造器把类型写死成
 * {@code TFCBlockEntities.DECAYING}，一用就会触发原版的
 * {@code BlockEntity.validateBlockState} 校验失败：
 *
 * <pre>
 * java.lang.IllegalStateException: Invalid block entity tfc:decaying
 *     // net.dries007.tfc.common.blockentities.DecayingBlockEntity state at BlockPos{...},
 *     got Block{tfcfarmingplus:chayote}
 * </pre>
 *
 * <b>这个异常是在放下整瓜的那一刻才触发的</b> —— 只在世界里生成资源、不实际放置方块，
 * 是发现不了的（哈密瓜就是这么漏过去的，直到佛手瓜的世界生成把整瓜放到地上才暴露）。
 */
public class MyDecayingBlockEntity extends DecayingBlockEntity {

    public MyDecayingBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.DECAYING.get(), pos, state);
    }

    @Override
    public void setStack(ItemStack stack) {
        super.setStack(stack);
        setChanged();
    }
}
