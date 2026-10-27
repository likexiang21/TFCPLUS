package io.github.likexiang21.tfcplus.agriculture.compat.jei;

import io.github.likexiang21.tfcplus.agriculture.common.recipe.CuttingBoardRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.gui.builder.IRecipeLayoutBuilder;
import mezz.jei.api.gui.drawable.IDrawable;
import mezz.jei.api.gui.ingredient.IRecipeSlotsView;
import mezz.jei.api.helpers.IGuiHelper;
import mezz.jei.api.recipe.IFocusGroup;
import mezz.jei.api.recipe.RecipeIngredientRole;
import mezz.jei.api.recipe.RecipeType;
import mezz.jei.api.recipe.category.IRecipeCategory;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

public final class CuttingBoardRecipeCategory implements IRecipeCategory<CuttingBoardRecipe> {
    private static final String PREFIX = "jei.tfcagricultureplus.cutting_board.";
    private final IDrawable icon;
    private final IDrawable arrow;
    private final int height;

    public CuttingBoardRecipeCategory(IGuiHelper helper, int maxByproducts) {
        icon = helper.createDrawableIngredient(VanillaTypes.ITEM_STACK,
            new ItemStack(AgricultureBlocks.LOG_CUTTING_BOARDS.get("log_cutting_board/oak").get()));
        arrow = helper.getRecipeArrow();
        height = 70 + Math.max(1, Math.ceilDiv(maxByproducts, 8)) * 20;
    }

    @Override
    public RecipeType<CuttingBoardRecipe> getRecipeType() { return AgricultureJeiPlugin.CUTTING_BOARD; }

    @Override
    public Component getTitle() { return Component.translatable("jei.tfcagricultureplus.category.cutting_board"); }

    @Override
    public int getWidth() { return 176; }

    @Override
    public int getHeight() { return height; }

    @Override
    public IDrawable getIcon() { return icon; }

    @Override
    public void setRecipe(IRecipeLayoutBuilder builder, CuttingBoardRecipe recipe, IFocusGroup focuses) {
        builder.addInputSlot(8, 18).setStandardSlotBackground().addIngredients(recipe.ingredient());
        builder.addSlot(RecipeIngredientRole.CATALYST, 54, 18).setStandardSlotBackground()
            .addIngredients(recipe.tool()).addRichTooltipCallback((slot, tooltip) ->
                tooltip.add(Component.translatable("jei.tfcagricultureplus.in_world.tool_hint")));
        final var inputStacks = java.util.Arrays.asList(recipe.ingredient().getItems());
        builder.addOutputSlot(138, 18).setOutputSlotBackground().addItemStacks(
            inputStacks.stream().map(recipe.result()::getSingleStackDisplayOnly)
                .map(net.dries007.tfc.common.component.food.FoodCapability::setTransientNonDecaying).toList())
            .addRichTooltipCallback((slot, tooltip) -> tooltip.add(Component.translatable(PREFIX + "freshness")));
        for (int i = 0; i < recipe.byproducts().size(); i++) {
            builder.addOutputSlot(8 + i % 8 * 20, 70 + i / 8 * 20).setStandardSlotBackground()
                .addItemStack(recipe.byproducts().get(i).getEmptyStack());
        }
    }

    @Override
    public void draw(CuttingBoardRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics,
                     double mouseX, double mouseY) {
        final var font = Minecraft.getInstance().font;
        graphics.drawString(font, Component.translatable(PREFIX + "ingredient"), 5, 3, 0x404040, false);
        graphics.drawString(font, Component.translatable("jei.tfcagricultureplus.in_world.tool"), 48, 3, 0x404040, false);
        graphics.drawString(font, Component.translatable("jei.tfcagricultureplus.in_world.replacement"), 132, 3, 0x404040, false);
        arrow.draw(graphics, 94, 18);
        graphics.drawString(font, Component.translatable(PREFIX + "interaction"), 5, 43, 0x404040, false);
        graphics.drawString(font, Component.translatable("jei.tfcagricultureplus.in_world.side_outputs"), 5, 57, 0x404040, false);
        if (recipe.byproducts().isEmpty()) {
            graphics.drawString(font, Component.translatable("jei.tfcagricultureplus.in_world.none"), 8, 74, 0x808080, false);
        }
    }
}
