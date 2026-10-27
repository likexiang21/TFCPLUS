package io.github.likexiang21.tfcplus.agriculture.client.screen;

import io.github.likexiang21.tfcplus.agriculture.common.menu.KitchenStorageMenu;
import net.dries007.tfc.client.screen.TFCContainerScreen;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.player.Inventory;

/** Minimal K1 screen; later kitchen batches can add per-kind labels without changing storage. */
public final class KitchenStorageScreen extends TFCContainerScreen<KitchenStorageMenu> {
    private static final ResourceLocation SLOT_TEXTURE =
        ResourceLocation.fromNamespaceAndPath("tfcagricultureplus", "textures/gui/silkworm_slot.png");

    public KitchenStorageScreen(KitchenStorageMenu menu, Inventory inventory, Component title) {
        super(menu, inventory, title, TFCContainerScreen.INVENTORY_1x1);
        this.imageWidth = 176;
        this.imageHeight = 168;
    }

    @Override
    protected void renderBg(GuiGraphics graphics, float partialTick, int mouseX, int mouseY) {
        graphics.fill(this.leftPos, this.topPos, this.leftPos + this.imageWidth,
            this.topPos + this.imageHeight, 0xffc6c6c6);
        for (int slot = 0; slot < 9; slot++) {
            drawSlotBackground(graphics, this.leftPos + 8 + slot * 18, this.topPos + 18);
        }
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
        graphics.drawString(this.font, this.title, 8, 4, 0x404040, false);
        graphics.drawString(this.font, Component.translatable("gui.tfcagricultureplus.player_inventory"),
            8, 40, 0x404040, false);
    }

    private static void drawSlotBackground(GuiGraphics graphics, int x, int y) {
        graphics.blit(SLOT_TEXTURE, x, y, 0.0f, 0.0f, 18, 18, 18, 18);
    }
}
