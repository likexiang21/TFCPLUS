package io.github.likexiang21.tfcplus.agriculture.compat.jei;

import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldRecipe;
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
import net.minecraft.world.item.Items;
import net.minecraft.world.level.block.state.BlockState;

/** Displays the world block, retained tool, replacement block and every side output. */
public final class InWorldRecipeCategory implements IRecipeCategory<InWorldRecipe> {
    private static final String PREFIX = "jei.tfcagricultureplus.in_world.";
    private static final int COLUMNS = 8;
    private final IDrawable icon;
    private final IDrawable arrow;
    private final int height;

    public InWorldRecipeCategory(IGuiHelper guiHelper, int maxOutputs) {
        icon = guiHelper.createDrawableIngredient(VanillaTypes.ITEM_STACK, new ItemStack(Items.IRON_AXE));
        arrow = guiHelper.getRecipeArrow();
        height = 70 + Math.max(1, (maxOutputs + COLUMNS - 1) / COLUMNS) * 20;
    }

    @Override
    public RecipeType<InWorldRecipe> getRecipeType() {
        return AgricultureJeiPlugin.IN_WORLD;
    }

    @Override
    public Component getTitle() {
        return Component.translatable("jei.tfcagricultureplus.category.in_world");
    }

    @Override
    public IDrawable getIcon() {
        return icon;
    }

    @Override
    public int getWidth() {
        return 176;
    }

    @Override
    public int getHeight() {
        return height;
    }

    @Override
    public void setRecipe(IRecipeLayoutBuilder builder, InWorldRecipe recipe, IFocusGroup focuses) {
        builder.addInputSlot(8, 18).setStandardSlotBackground()
            .addItemStack(new ItemStack(recipe.inputState().getBlock()))
            .addRichTooltipCallback((slot, tooltip) -> {
                tooltip.add(Component.translatable(PREFIX + "target_hint"));
                for (final BlockState state : recipe.inputState().getAcceptableStates()) {
                    tooltip.add(Component.literal(state.toString()));
                }
            });

        // CATALYST makes it clear that the tool is retained rather than consumed.
        builder.addSlot(RecipeIngredientRole.CATALYST, 54, 18).setStandardSlotBackground()
            .addIngredients(recipe.tool().getInputItem())
            .addRichTooltipCallback((slot, tooltip) ->
                tooltip.add(Component.translatable(PREFIX + "tool_hint")));

        final ItemStack replacement = new ItemStack(recipe.resultState().getBlock());
        if (!replacement.isEmpty()) {
            builder.addOutputSlot(138, 18).setOutputSlotBackground()
                .addItemStack(replacement)
                .addRichTooltipCallback((slot, tooltip) -> {
                    tooltip.add(Component.translatable(PREFIX + "replacement_hint"));
                    if (!recipe.resultState().getValues().isEmpty()) {
                        tooltip.add(Component.literal(recipe.resultState().toString()));
                    }
                });
        }

        // Each side output gets its own slot; simultaneous drops are not alternatives.
        for (int i = 0; i < recipe.resultItems().size(); i++) {
            final var output = recipe.resultItems().get(i);
            final int piles = output.getSecond().getCountFactor();
            final int countPerPile = output.getFirst().getCount();
            final ItemStack total = output.getFirst().copyWithCount(countPerPile * piles);
            builder.addOutputSlot(8 + (i % COLUMNS) * 20, 70 + (i / COLUMNS) * 20)
                .setStandardSlotBackground().addItemStack(total)
                .addRichTooltipCallback((slot, tooltip) -> {
                    tooltip.add(output.getSecond().getPrettyName());
                    tooltip.add(Component.translatable(PREFIX + "drops", countPerPile, piles, total.getCount()));
                });
        }
    }

    @Override
    public void draw(InWorldRecipe recipe, IRecipeSlotsView slots, GuiGraphics graphics,
                     double mouseX, double mouseY) {
        final var font = Minecraft.getInstance().font;
        graphics.drawString(font, Component.translatable(PREFIX + "target"), 5, 3, 0x404040, false);
        graphics.drawString(font, Component.translatable(PREFIX + "tool"), 48, 3, 0x404040, false);
        graphics.drawString(font, Component.translatable(PREFIX + "replacement"), 132, 3, 0x404040, false);
        arrow.draw(graphics, 94, 18);
        if (new ItemStack(recipe.resultState().getBlock()).isEmpty()) {
            graphics.drawString(font, Component.translatable(PREFIX + "removed"), 132, 21, 0x404040, false);
        }
        graphics.drawString(font, Component.translatable(PREFIX + "interaction"), 5, 43, 0x404040, false);
        graphics.drawString(font, Component.translatable(PREFIX + "side_outputs"), 5, 57, 0x404040, false);
        if (recipe.resultItems().isEmpty()) {
            graphics.drawString(font, Component.translatable(PREFIX + "none"), 8, 74, 0x808080, false);
        }
    }
}
