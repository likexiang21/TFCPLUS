package io.github.likexiang21.tfcplus.agriculture.common.pan;

import net.minecraft.util.StringRepresentable;

public enum PlateVariant implements StringRepresentable {
    WOOD("wood"),
    CERAMIC_CLEAR("ceramic"),
    CERAMIC_WHITE("ceramic_white"),
    CERAMIC_ORANGE("ceramic_orange"),
    CERAMIC_MAGENTA("ceramic_magenta"),
    CERAMIC_LIGHT_BLUE("ceramic_light_blue"),
    CERAMIC_YELLOW("ceramic_yellow"),
    CERAMIC_LIME("ceramic_lime"),
    CERAMIC_PINK("ceramic_pink"),
    CERAMIC_GRAY("ceramic_gray"),
    CERAMIC_LIGHT_GRAY("ceramic_light_gray"),
    CERAMIC_CYAN("ceramic_cyan"),
    CERAMIC_PURPLE("ceramic_purple"),
    CERAMIC_BLUE("ceramic_blue"),
    CERAMIC_BROWN("ceramic_brown"),
    CERAMIC_GREEN("ceramic_green"),
    CERAMIC_RED("ceramic_red"),
    CERAMIC_BLACK("ceramic_black");

    private final String id;

    PlateVariant(String id) { this.id = id; }

    @Override public String getSerializedName() { return id; }
    public String id() { return id; }
    public String texture() { return "tfcagricultureplus:block/plate/" + id; }
    public String translationKey() { return "block.tfcagricultureplus.serving_plate." + id; }
    public boolean wooden() { return this == WOOD; }
}
