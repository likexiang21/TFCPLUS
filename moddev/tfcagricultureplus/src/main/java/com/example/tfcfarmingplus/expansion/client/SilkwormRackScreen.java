package com.example.tfcfarmingplus.expansion.client;

import com.example.tfcfarmingplus.expansion.common.container.SilkwormRackMenu;
import net.dries007.tfc.client.screen.TFCContainerScreen;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.player.Inventory;

/** Lightweight B-owned screen; slot behavior remains in the TFC menu contract. */
public final class SilkwormRackScreen extends TFCContainerScreen<SilkwormRackMenu> {
    private static final ResourceLocation SLOT_TEXTURE =
        ResourceLocation.fromNamespaceAndPath("tfcagricultureplus", "textures/gui/silkworm_slot.png");

    public SilkwormRackScreen(SilkwormRackMenu menu, Inventory inventory, Component title) {
        super(menu, inventory, title, TFCContainerScreen.INVENTORY_1x1);
        this.imageWidth = 176;
        this.imageHeight = 168;
    }

    @Override
    protected void renderBg(GuiGraphics graphics, float partialTick, int mouseX, int mouseY) {
        graphics.fill(this.leftPos, this.topPos, this.leftPos + this.imageWidth,
            this.topPos + this.imageHeight, 0xffc6c6c6);
        // Draw the reference slot material only for real silkworm-box slots.
        // The unused positions remain plain background, so they are not
        // mistaken for additional storage slots.
        for (int column = 0; column < 8; column++) {
            drawSlotBackground(graphics, this.leftPos + 8 + column * 18,
                this.topPos + 18);
        }
        drawSlotBackground(graphics, this.leftPos + 8, this.topPos + 54);
        drawSlotBackground(graphics, this.leftPos + 26, this.topPos + 54);
        drawSlotBackground(graphics, this.leftPos + 152, this.topPos + 54);

        // The inherited TFC menu places the player's inventory at x=8,
        // y=84/102/120 and the hotbar at y=142. Draw the same material only
        // on those 36 real slots; the surrounding space stays plain.
        for (int row = 0; row < 3; row++) {
            for (int column = 0; column < 9; column++) {
                drawSlotBackground(graphics, this.leftPos + 8 + column * 18,
                    this.topPos + 84 + row * 18);
            }
        }
        for (int column = 0; column < 9; column++) {
            drawSlotBackground(graphics, this.leftPos + 8 + column * 18,
                this.topPos + 142);
        }
    }

    @Override
    protected void renderLabels(GuiGraphics graphics, int mouseX, int mouseY) {
        graphics.drawString(this.font, Component.translatable("gui.tfcagricultureplus.silkworm_biological"), 8, 4, 0x404040, false);
        graphics.drawString(this.font, Component.translatable("gui.tfcagricultureplus.silkworm_feed"), 8, 40, 0x404040, false);
        final Component outputLabel = Component.translatable("gui.tfcagricultureplus.silkworm_output");
        graphics.drawString(this.font, outputLabel, this.imageWidth - 8 - this.font.width(outputLabel), 40, 0x404040, false);
        graphics.drawString(this.font, Component.translatable("gui.tfcagricultureplus.player_inventory"), 8, 74, 0x404040, false);
    }

    private static void drawSlotBackground(GuiGraphics graphics, int x, int y) {
        graphics.blit(SLOT_TEXTURE, x, y, 0.0f, 0.0f, 18, 18, 18, 18);
    }
}
