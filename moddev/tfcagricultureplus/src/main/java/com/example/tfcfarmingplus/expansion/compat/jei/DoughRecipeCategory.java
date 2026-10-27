package com.example.tfcfarmingplus.expansion.compat.jei;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.MyBlocks;
import com.example.tfcfarmingplus.expansion.common.recipe.DoughRecipe;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.gui.builder.IRecipeLayoutBuilder;
import mezz.jei.api.gui.drawable.IDrawable;
import mezz.jei.api.gui.ingredient.IRecipeSlotsView;
import mezz.jei.api.helpers.IGuiHelper;
import mezz.jei.api.recipe.IFocusGroup;
import mezz.jei.api.recipe.category.IRecipeCategory;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

/** JEI view for the K3 flour -> dough table step. */
public final class DoughRecipeCategory implements IRecipeCategory<DoughRecipe> {
    private final IDrawable icon;
    private final IDrawable arrow;
    public DoughRecipeCategory(IGuiHelper helper) {
        icon = helper.createDrawableIngredient(VanillaTypes.ITEM_STACK, new ItemStack(MyBlocks.DOUGH_FORMING_TABLE.get()));
        arrow = helper.getRecipeArrow();
    }
    @Override public mezz.jei.api.recipe.RecipeType<DoughRecipe> getRecipeType() { return MyJeiPlugin.DOUGH; }
    @Override public Component getTitle() { return Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".category.dough"); }
    @Override public int getWidth() { return 140; }
    @Override public int getHeight() { return 40; }
    @Override public IDrawable getIcon() { return icon; }
    @Override public void setRecipe(IRecipeLayoutBuilder builder, DoughRecipe recipe, IFocusGroup focuses) {
        builder.addInputSlot(20, 10).setStandardSlotBackground().addIngredients(recipe.ingredient());
        builder.addOutputSlot(106, 10).setOutputSlotBackground().addItemStack(recipe.result());
    }
    @Override public void draw(DoughRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics, double mouseX, double mouseY) { arrow.draw(graphics, 62, 10); }
}
