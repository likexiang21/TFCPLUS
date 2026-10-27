package io.github.likexiang21.tfcplus.agriculture.compat.jei;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.PanRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.gui.builder.IRecipeLayoutBuilder;
import mezz.jei.api.gui.drawable.IDrawable;
import mezz.jei.api.gui.ingredient.IRecipeSlotsView;
import mezz.jei.api.helpers.IGuiHelper;
import mezz.jei.api.recipe.IFocusGroup;
import mezz.jei.api.recipe.category.IRecipeCategory;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

/** JEI view for the K2 two-input pan state machine. */
public final class PanRecipeCategory implements IRecipeCategory<PanRecipe> {
    private final IDrawable icon;
    private final IDrawable arrow;

    public PanRecipeCategory(IGuiHelper helper) {
        icon = helper.createDrawableIngredient(VanillaTypes.ITEM_STACK, new ItemStack(AgricultureBlocks.COOKING_PAN.get()));
        arrow = helper.getRecipeArrow();
    }

    @Override public mezz.jei.api.recipe.RecipeType<PanRecipe> getRecipeType() { return AgricultureJeiPlugin.PAN; }
    @Override public Component getTitle() { return Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".category.pan"); }
    @Override public int getWidth() { return 140; }
    @Override public int getHeight() { return 58; }
    @Override public IDrawable getIcon() { return icon; }

    @Override public void setRecipe(IRecipeLayoutBuilder builder, PanRecipe recipe, IFocusGroup focuses) {
        builder.addInputSlot(8, 12).setStandardSlotBackground().addIngredients(recipe.food());
        builder.addInputSlot(34, 12).setStandardSlotBackground().addIngredients(recipe.spice());
        builder.addOutputSlot(106, 12).setOutputSlotBackground().addItemStack(recipe.result());
    }

    @Override public void draw(PanRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics, double mouseX, double mouseY) {
        arrow.draw(graphics, 63, 12);
        final var font = Minecraft.getInstance().font;
        graphics.drawString(font, Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".pan.time", recipe.cookTicks()),
            5, 38, 0x404040, false);
        graphics.drawString(font, Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".pan.stirs", recipe.requiredStirs()),
            78, 38, 0x404040, false);
    }
}
