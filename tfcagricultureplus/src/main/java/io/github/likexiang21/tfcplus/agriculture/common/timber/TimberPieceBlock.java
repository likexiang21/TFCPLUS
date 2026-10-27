package io.github.likexiang21.tfcplus.agriculture.common.timber;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.*;
import net.minecraft.world.level.block.*;
import net.minecraft.world.level.block.state.*;
import net.minecraft.world.phys.shapes.*;

/** Geometry adapted from TFC Woodworking 1.2.4 (MIT, copyright uTa4u). */
public final class TimberPieceBlock extends HorizontalDirectionalBlock {
    public final int pieceKind;
    public TimberPieceBlock(Properties properties, int pieceKind) {
        super(properties); this.pieceKind = pieceKind;
        registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
    }
    @Override protected MapCodec<? extends HorizontalDirectionalBlock> codec() { return simpleCodec(p -> new TimberPieceBlock(p, pieceKind)); }
    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) { builder.add(FACING); }
    @Override public BlockState getStateForPlacement(BlockPlaceContext context) { return defaultBlockState().setValue(FACING, context.getHorizontalDirection().getOpposite()); }
    @Override protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        if (pieceKind == 0) return Block.box(1, 0, 1, 15, 16, 15);
        if (pieceKind == 2) return Block.box(5, 0, 5, 11, 16, 11);
        return state.getValue(FACING).getAxis() == Direction.Axis.Z ? Block.box(1, 0, 5, 15, 16, 11) : Block.box(5, 0, 1, 11, 16, 15);
    }
    @Override protected boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return level.getBlockState(pos.below()).getBlock() instanceof TimberPieceBlock || Block.canSupportCenter(level, pos.below(), Direction.UP);
    }
    @Override protected BlockState updateShape(BlockState state, Direction direction, BlockState neighbor, LevelAccessor level, BlockPos pos, BlockPos neighborPos) {
        return direction == Direction.DOWN && !canSurvive(state, level, pos) ? Blocks.AIR.defaultBlockState() : state;
    }
}
