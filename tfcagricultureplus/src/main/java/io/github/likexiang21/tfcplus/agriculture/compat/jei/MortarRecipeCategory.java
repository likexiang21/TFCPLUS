package io.github.likexiang21.tfcplus.agriculture.compat.jei;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.MortarRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.gui.builder.IRecipeLayoutBuilder;
import mezz.jei.api.gui.drawable.IDrawable;
import mezz.jei.api.gui.ingredient.IRecipeSlotsView;
import mezz.jei.api.helpers.IGuiHelper;
import mezz.jei.api.recipe.IFocusGroup;
import mezz.jei.api.recipe.RecipeIngredientRole;
import mezz.jei.api.recipe.category.IRecipeCategory;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

/**
 * 🆕 <b>研磨配方在 JEI 里的展示类</b> —— 后续 12 个配方类型的**模板**。
 *
 * <p>⚠️ 本类**只在装了 JEI 时**才会被加载（由 {@link AgricultureJeiPlugin} 引用）。
 */
public final class MortarRecipeCategory implements IRecipeCategory<MortarRecipe> {

    /** ⚠️ JEI 19.x 起 {@code getBackground()} 已过时（改为在 {@code createRecipeExtras} 里画）⇒ 不再实现。 */
    private final IDrawable icon;

    public MortarRecipeCategory(IGuiHelper guiHelper) {
        this.icon = guiHelper.createDrawableIngredient(VanillaTypes.ITEM_STACK,
            new ItemStack(io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks.MORTARS
                .get("mortar/basalt").get()));
    }

    @Override
    public mezz.jei.api.recipe.RecipeType<MortarRecipe> getRecipeType() {
        return AgricultureJeiPlugin.MORTAR;
    }

    @Override
    public Component getTitle() {
        return Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".category.mortar");
    }

    @Override
    public int getWidth() {
        return 120;
    }

    @Override
    public int getHeight() {
        return 40;
    }

    @Override
    public IDrawable getIcon() {
        return icon;
    }

    @Override
    public void setRecipe(IRecipeLayoutBuilder builder, MortarRecipe recipe, IFocusGroup focuses) {
        builder.addSlot(RecipeIngredientRole.INPUT, 8, 12).addIngredients(recipe.ingredient());
        builder.addSlot(RecipeIngredientRole.OUTPUT, 92, 12).addItemStack(recipe.result());
    }

    @Override
    public void draw(MortarRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics,
                     double mouseX, double mouseY) {
        // 研磨敲击次数（右下角小字）
        graphics.drawString(net.minecraft.client.Minecraft.getInstance().font,
            Component.translatable("jei." + TFCAgriculturePlus.MOD_ID + ".mortar.strikes",
                recipe.grindTime()), 84, 32, 0x808080, false);
    }
}
