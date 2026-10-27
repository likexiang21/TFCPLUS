package com.example.tfcfarmingplus.expansion.compat.jei;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.MyBlocks;
import com.example.tfcfarmingplus.expansion.common.recipe.MeltingRecipe;
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

/** JEI view for cocoa powder and sweetener entering the melting pot. */
public final class MeltingRecipeCategory implements IRecipeCategory<MeltingRecipe> {
    private final IDrawable icon;
    private final IDrawable arrow;
    public MeltingRecipeCategory(IGuiHelper helper) {
        icon = helper.createDrawableIngredient(VanillaTypes.ITEM_STACK, new ItemStack(MyBlocks.MELTING_POT.get()));
        arrow = helper.getRecipeArrow();
    }
    @Override public mezz.jei.api.recipe.RecipeType<MeltingRecipe> getRecipeType() { return MyJeiPlugin.MELTING; }
    @Override public Component getTitle() { return Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".category.melting"); }
    @Override public int getWidth() { return 140; }
    @Override public int getHeight() { return 40; }
    @Override public IDrawable getIcon() { return icon; }
    @Override public void setRecipe(IRecipeLayoutBuilder builder, MeltingRecipe recipe, IFocusGroup focuses) {
        builder.addInputSlot(8, 10).setStandardSlotBackground().addIngredients(recipe.powder());
        builder.addInputSlot(34, 10).setStandardSlotBackground().addIngredients(recipe.sweetener());
        builder.addOutputSlot(106, 10).setOutputSlotBackground().addItemStack(recipe.result());
    }
    @Override public void draw(MeltingRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics, double mouseX, double mouseY) { arrow.draw(graphics, 62, 10); }
}
