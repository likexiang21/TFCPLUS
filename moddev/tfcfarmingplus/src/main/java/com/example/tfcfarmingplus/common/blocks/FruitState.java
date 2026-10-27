package com.example.tfcfarmingplus.common.blocks;

import net.minecraft.util.StringRepresentable;

/**
 * 果树枝干上的**果实状态** —— 作为枝干方块的一个 blockstate 属性。
 *
 * <p>它取代了早期那套「独立的树干果实方块」（{@code plant/<n>_trunk_fruit}）：
 * 用户指出树干不是完整方块（截面 8×8），在它侧面再挂一个独立方块很别扭，
 * 果实应该是**主干自身的一个状态**。
 */
public enum FruitState implements StringRepresentable {
    /** 没有果实 */
    NONE("none"),
    /** 已坐果、尚未成熟（不可采） */
    UNRIPE("unripe"),
    /** 成熟（右键可采） */
    RIPE("ripe");

    private final String name;

    FruitState(final String name) {
        this.name = name;
    }

    @Override
    public String getSerializedName() {
        return this.name;
    }
}
