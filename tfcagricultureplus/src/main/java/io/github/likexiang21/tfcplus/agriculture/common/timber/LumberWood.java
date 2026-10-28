package io.github.likexiang21.tfcplus.agriculture.common.timber;

/** Wood variants used by the lumber-pile blockstate; names match TFC plank paths. */
public enum LumberWood implements net.minecraft.util.StringRepresentable {
    ACACIA("acacia"), ASH("ash"), ASPEN("aspen"), BIRCH("birch"), BLACKWOOD("blackwood"),
    CHESTNUT("chestnut"), DOUGLAS_FIR("douglas_fir"), HICKORY("hickory"), KAPOK("kapok"),
    MANGROVE("mangrove"), MAPLE("maple"), OAK("oak"), PALM("palm"), PINE("pine"),
    ROSEWOOD("rosewood"), SEQUOIA("sequoia"), SPRUCE("spruce"), SYCAMORE("sycamore"),
    WHITE_CEDAR("white_cedar"), WILLOW("willow"),
    ARAUCARIA("araucaria"), BAOBAB("baobab"), BEECH("beech"), CYPRESS("cypress"),
    EUCALYPTUS("eucalyptus"), FIG("fig"), GINKGO("ginkgo"), HEVEA("hevea"), IPE("ipe"),
    IRONWOOD("ironwood"), MAHOE("mahoe"), MAHOGANY("mahogany"), TEAK("teak"), TUALANG("tualang");

    private final String id;
    LumberWood(String id) { this.id = id; }
    public String id() { return id; }
    @Override public String getSerializedName() { return id; }

    public static LumberWood byId(String id) {
        for (LumberWood value : values()) if (value.id.equals(id)) return value;
        return OAK;
    }
}
