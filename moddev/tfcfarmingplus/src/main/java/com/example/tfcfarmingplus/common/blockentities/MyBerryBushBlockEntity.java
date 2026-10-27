package com.example.tfcfarmingplus.common.blockentities;

import com.example.tfcfarmingplus.common.MyBlockEntities;
import net.dries007.tfc.common.blockentities.BerryBushBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.state.BlockState;

/**
 * 浆果灌木方块实体。
 * <p>
 * 存在的唯一理由：TFC 的 {@link BerryBushBlockEntity} 里，带类型参数的构造器是
 * {@code protected}，而公开构造器把 BE 类型写死成 {@code TFCBlockEntities.BERRY_BUSH}，
 * 一用就会触发原版的 {@code BlockEntity.validateBlockState} 校验失败。
 * 这里用子类把构造器转发出去，传入属于本模组自己的类型。
 *
 * @see MyBlockEntities 类注释里有完整的崩溃记录与权衡说明
 */
public class MyBerryBushBlockEntity extends BerryBushBlockEntity {

    public MyBerryBushBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.BERRY_BUSH.get(), pos, state);
    }
}
