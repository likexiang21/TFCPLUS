package com.example.tfcfarmingplus.expansion.common.recipe.inworld;

import com.mojang.serialization.Codec;
import io.netty.buffer.ByteBuf;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.chat.Component;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.Vec3;

import java.util.List;

/** Project-defined item emissions; motion and wire contracts are recorded in docs/131. */
public enum Action implements StringRepresentable {
    // Declaration order is the existing network contract.
    DROP_CENTER("drop_center", new Motion(0.5, 0, 0, 0.2)),
    DROP_CARDINAL("drop_cardinal", new Motion(0.35, 0.35, 0.06, 0.12)),
    DROP_ABOVE("drop_above", new Motion(1.15, 0, 0, 0.1)),
    SHOOT_AS_BLOCK("shoot_as_block", new Motion(0.75, 0, 0.22, 0.16));

    public static final Action[] VALUES = values();
    public static final Codec<Action> CODEC = StringRepresentable.fromEnum(Action::values);
    public static final StreamCodec<ByteBuf, Action> STREAM_CODEC =
        ByteBufCodecs.VAR_INT.map(Action::fromNetworkId, Action::ordinal);
    private static final List<Direction> HORIZONTAL =
        List.of(Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST);

    private final String key;
    private final Motion motion;

    Action(String key, Motion motion) {
        this.key = key;
        this.motion = motion;
    }

    public static Action fromNetworkId(int id) {
        if (id < 0 || id >= VALUES.length) throw new IllegalArgumentException("Unknown emission id: " + id);
        return VALUES[id];
    }

    @Override public String getSerializedName() { return key; }
    public Component getPrettyName() { return Component.translatable("tfcagricultureplus.itemstack_action." + key); }
    public int getCountFactor() {
        return this == DROP_CARDINAL ? HORIZONTAL.size() : this == SHOOT_AS_BLOCK ? 2 : 1;
    }

    public void accept(Level level, BlockPos pos, ItemStack output, Direction facing) {
        if (output.isEmpty()) return;
        if (this == SHOOT_AS_BLOCK) {
            final Direction axis = facing.getAxis().isHorizontal() ? facing : Direction.NORTH;
            final double offsetX = axis.getAxis() == Direction.Axis.Z ? 0.18 : 0.0;
            final double offsetZ = axis.getAxis() == Direction.Axis.X ? 0.18 : 0.0;
            final double speedX = axis.getAxis() == Direction.Axis.Z ? 0.05 * axis.getStepZ() : 0.0;
            final double speedZ = axis.getAxis() == Direction.Axis.X ? 0.05 * axis.getStepX() : 0.0;
            for (int side : new int[] {-1, 1}) {
                level.addFreshEntity(new ItemEntity(level, pos.getX() + 0.5 + side * offsetX,
                    pos.getY() + 0.5, pos.getZ() + 0.5 + side * offsetZ,
                    output.copy(), side * speedX, 0.18, side * speedZ));
            }
            return;
        }
        List<Direction> directions = this == DROP_CARDINAL ? HORIZONTAL : List.of(facing);
        Vec3 origin = Vec3.atLowerCornerOf(pos);
        for (Direction direction : directions) {
            Vec3 location = origin.add(motion.offset(direction));
            Vec3 velocity = motion.velocity(direction);
            level.addFreshEntity(new ItemEntity(level, location.x, location.y, location.z,
                output.copy(), velocity.x, velocity.y, velocity.z));
        }
    }

    private record Motion(double height, double spread, double speed, double lift) {
        Vec3 offset(Direction direction) {
            return new Vec3(0.5 + spread * direction.getStepX(), height,
                0.5 + spread * direction.getStepZ());
        }
        Vec3 velocity(Direction direction) {
            return new Vec3(speed * direction.getStepX(), lift, speed * direction.getStepZ());
        }
    }
}
