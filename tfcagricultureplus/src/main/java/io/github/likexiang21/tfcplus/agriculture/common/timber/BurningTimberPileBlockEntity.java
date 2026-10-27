package io.github.likexiang21.tfcplus.agriculture.common.timber;

import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.blockentities.TickCounterBlockEntity;
import net.dries007.tfc.common.blocks.TFCBlocks;
import net.dries007.tfc.config.TFCConfig;
import net.minecraft.core.*;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.block.*;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;

/** TFC calendar and configured charcoal time; fractional pieces retain their mass. */
public final class BurningTimberPileBlockEntity extends TickCounterBlockEntity {
    private int units;
    public BurningTimberPileBlockEntity(BlockPos pos, BlockState state) { super(AgricultureBlockEntities.BURNING_TIMBER_PILE.get(),pos,state); }
    public void light(int count) { units=count; resetCounter(); setChanged(); }
    public void tick(ServerLevel level) {
        if(level.getGameTime()%20!=0) return;
        checkBurning(level);
    }
    public void checkBurning(ServerLevel level) {
        // Allow ten seconds to seal the ignition opening before checking insulation.
        if (getTicksSinceUpdate() < 200) return;
        for(Direction direction:Direction.values()) {
            BlockPos neighbor=worldPosition.relative(direction); BlockState state=level.getBlockState(neighbor);
            boolean covered=state.getBlock() instanceof TimberPileBlock || state.is(TFCTags.Blocks.CHARCOAL_PIT_INSULATION) || !state.isFlammable(level,neighbor,direction.getOpposite()) && state.isFaceSturdy(level,neighbor,direction.getOpposite());
            if(!covered) {
                if(state.isAir()) level.setBlockAndUpdate(neighbor,BaseFireBlock.getState(level,neighbor));
                level.removeBlock(worldPosition,false); return;
            }
        }
        if(getTicksSinceUpdate() >= TFCConfig.SERVER.charcoalTicks.get()) finish(level);
    }
    private void finish(ServerLevel level) {
        // One result is produced for the whole connected vertical batch. The top
        // segment is the coordinator so several ticking block entities cannot
        // settle the same batch twice.
        if (level.getBlockEntity(worldPosition.above()) instanceof BurningTimberPileBlockEntity) return;
        BlockPos bottom=worldPosition;
        for(int i=0;i<63 && level.getBlockEntity(bottom.below()) instanceof BurningTimberPileBlockEntity;i++) bottom=bottom.below();
        java.util.List<BlockPos> column=new java.util.ArrayList<>(); int total=0;
        for(int i=0;i<64;i++) {
            BlockPos pos=bottom.above(i);
            if(!(level.getBlockEntity(pos) instanceof BurningTimberPileBlockEntity be)) break;
            // Wait for the newest segment in this column, avoiding early completion after spread.
            if(be.getTicksSinceUpdate()<TFCConfig.SERVER.charcoalTicks.get()) return;
            total+=be.units; column.add(pos);
        }
        int charcoal=(int)Math.floor(total*(.0625+.0625*level.random.nextDouble()));
        final BlockPos belowPos = bottom.below();
        final BlockState belowState = level.getBlockState(belowPos);
        if (belowState.is(TFCBlocks.CHARCOAL_PILE.get())) {
            final int existing = belowState.getValue(BlockStateProperties.LAYERS);
            final int added = Math.min(8 - existing, charcoal);
            if (added > 0) {
                charcoal -= added;
                level.setBlockAndUpdate(belowPos, belowState.setValue(BlockStateProperties.LAYERS, existing + added));
            }
        }
        for(BlockPos pos:column) {
            int layers=Math.min(8,charcoal); charcoal-=layers;
            level.setBlockAndUpdate(pos,layers==0?Blocks.AIR.defaultBlockState():TFCBlocks.CHARCOAL_PILE.get().defaultBlockState().setValue(BlockStateProperties.LAYERS,layers));
        }
    }
    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.saveAdditional(tag,registries); tag.putInt("quarter_units",units); }
    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.loadAdditional(tag,registries); units=Math.clamp(tag.getInt("quarter_units"),0,64); }
}
