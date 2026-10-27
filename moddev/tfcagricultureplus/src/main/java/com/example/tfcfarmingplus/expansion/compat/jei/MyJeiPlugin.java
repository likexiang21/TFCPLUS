package com.example.tfcfarmingplus.expansion.compat.jei;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.recipe.MortarRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import com.example.tfcfarmingplus.expansion.common.recipe.inworld.InWorldRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.CuttingBoardRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.PanRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.DoughRecipe;
import com.example.tfcfarmingplus.expansion.common.recipe.MeltingRecipe;
import mezz.jei.api.IModPlugin;
import mezz.jei.api.JeiPlugin;
import mezz.jei.api.recipe.RecipeType;
import mezz.jei.api.registration.IRecipeCatalystRegistration;
import mezz.jei.api.registration.IRecipeCategoryRegistration;
import mezz.jei.api.registration.IRecipeRegistration;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.ingredients.subtypes.UidContext;
import net.minecraft.client.Minecraft;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.crafting.RecipeManager;

import java.util.List;
import java.util.ArrayList;

/**
 * 🆕 <b>JEI 适配插件</b> —— 为后续所有加工配方打基础（用户口径：
 * 「**先为后续的加工配方引入和 jei 适配做好代码基础**」）。
 *
 * <h2>关键约束（照 TFC 的做法，实测）</h2>
 * <ul>
 *   <li>🛑 <b>JEI 是 optional 依赖</b>：`mods.toml` 里 `type = "optional"`、`side = "CLIENT"`，
 *       gradle 里用 <b>{@code compileOnly}</b> —— 本模组**没有 JEI 也必须能正常加载**</li>
 *   <li>本类**只在客户端加载**（{@code @JeiPlugin} 由 JEI 自己发现，没有 JEI 时这个类不会被触碰）</li>
 *   <li>⚠️ <b>不要</b>在 common 代码里 import JEI 的类（会变成硬依赖）</li>
 * </ul>
 *
 * <p>新增配方类型时的**三步**：
 * <ol>
 *   <li>{@link MyRecipeTypes} + {@code MyRecipeSerializers} 各注册一次</li>
 *   <li>本类里加一个 {@code mezz.jei.api.recipe.RecipeType} 常量</li>
 *   <li>写一个 {@code *RecipeCategory} 并在 {@link #registerCategories} 注册</li>
 * </ol>
 */
@JeiPlugin
public final class MyJeiPlugin implements IModPlugin {

    /** JEI 插件 ID —— 必须与 mod id 同命名空间。 */
    public static final ResourceLocation UID =
        ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "jei_plugin");

    /** 🆕 研磨配方在 JEI 里的类型。 */
    public static final RecipeType<MortarRecipe> MORTAR =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "mortar", MortarRecipe.class);

    public static final RecipeType<InWorldRecipe> IN_WORLD =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "in_world", InWorldRecipe.class);

    public static final RecipeType<CuttingBoardRecipe> CUTTING_BOARD =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "cutting_board", CuttingBoardRecipe.class);

    public static final RecipeType<PanRecipe> PAN =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "pan", PanRecipe.class);

    /** Compatibility types retained for old category classes; no recipes or catalysts are registered. */
    public static final RecipeType<DoughRecipe> DOUGH =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "dough", DoughRecipe.class);
    public static final RecipeType<MeltingRecipe> MELTING =
        RecipeType.create(TFCAgriculturePlus.MOD_ID, "melting", MeltingRecipe.class);


    @Override
    public ResourceLocation getPluginUid() {
        return UID;
    }

    @Override
    public void registerCategories(IRecipeCategoryRegistration registration) {
        final var guiHelper = registration.getJeiHelpers().getGuiHelper();
        final var level = Minecraft.getInstance().level;
        final var manager = level == null ? null : level.getRecipeManager();
        final int maxOutputs = manager == null ? 0 : manager.getAllRecipesFor(MyRecipeTypes.IN_WORLD.get()).stream()
            .map(net.minecraft.world.item.crafting.RecipeHolder::value)
            .mapToInt(recipe -> recipe.resultItems().size()).max().orElse(0);
        final int maxByproducts = manager == null ? 0 : manager
            .getAllRecipesFor(MyRecipeTypes.CUTTING_BOARD.get()).stream()
            .mapToInt(holder -> holder.value().byproducts().size()).max().orElse(0);
        registration.addRecipeCategories(
            new MortarRecipeCategory(guiHelper),
            new InWorldRecipeCategory(guiHelper, maxOutputs),
            new CuttingBoardRecipeCategory(guiHelper, maxByproducts),
            new PanRecipeCategory(guiHelper));
    }

    @Override
    public void registerRecipes(IRecipeRegistration registration) {
        // 从客户端的 RecipeManager 取本模组的所有研磨配方
        final var level = Minecraft.getInstance().level;
        if (level == null) {
            TFCAgriculturePlus.LOGGER.warn("[JEI] Client level is not ready; registering no dynamic recipes yet");
            return;
        }
        final RecipeManager manager = level.getRecipeManager();
        // ⚠️ getAllRecipesFor 返回的是 List<RecipeHolder<T>>，JEI 要的是 List<T>
        //    ⇒ 必须 .map(RecipeHolder::value)（TFC 的 JEIIntegration 也是这么做的）
        registration.addRecipes(MORTAR,
            manager.getAllRecipesFor(MyRecipeTypes.MORTAR.get())
                .stream()
                .map(net.minecraft.world.item.crafting.RecipeHolder::value)
                .toList());
        final List<InWorldRecipe> inWorldRecipes = getInWorldRecipes();
        registration.addRecipes(IN_WORLD, inWorldRecipes);
        TFCAgriculturePlus.LOGGER.info("[JEI] Registered {} in-world recipes", inWorldRecipes.size());
        final var cuttingRecipes = manager.getAllRecipesFor(MyRecipeTypes.CUTTING_BOARD.get()).stream()
            .map(net.minecraft.world.item.crafting.RecipeHolder::value).toList();
        registration.addRecipes(CUTTING_BOARD, cuttingRecipes);
        TFCAgriculturePlus.LOGGER.info("[JEI] Registered {} cutting-board recipes", cuttingRecipes.size());
        final List<PanRecipe> panRecipes = manager.getAllRecipesFor(MyRecipeTypes.PAN.get()).stream()
            .map(net.minecraft.world.item.crafting.RecipeHolder::value).toList();
        registration.addRecipes(PAN, panRecipes);
        TFCAgriculturePlus.LOGGER.info("[JEI] Registered {} pan recipes", panRecipes.size());
        // Hide compatibility-only entries and the disabled TFC strawberry bush from
        // both the item list and recipe ingredient lookups. The registry entries stay
        // available for old saved stacks, while all new gameplay points to canonical IDs.
        final List<net.minecraft.world.item.ItemStack> hidden = new ArrayList<>();
        for (final String id : List.of(
            "tfc:plant/strawberry_bush",
            "tfcfarmingplus:food/strawberry",
            "tfcfarmingplus:food/cupuacu",
            "tfcfarmingplus:food/cocoa",
            "tfcfarmingplus:plant/cocoa_sapling",
            "tfcfarmingplus:plant/cocoa_leaves",
            "tfcagricultureplus:food/dried_strawberry",
            "tfcagricultureplus:food/cocoa_beans",
            "tfcagricultureplus:food/dried_cocoa_beans",
            "tfcagricultureplus:food/dried_ginger",
            "tfcagricultureplus:food/dried_turmeric",
            "tfcagricultureplus:food/dried_napa_cabbage",
            "tfcagricultureplus:food/roasted_cocoa_beans",
            "tfcagricultureplus:food/cocoa_powder",
            "tfcagricultureplus:food/cocoa_nibs",
            "tfcagricultureplus:food/dark_chocolate",
            "tfcagricultureplus:material/dough",
            "tfcagricultureplus:dough_forming_table",
            "tfcagricultureplus:melting_pot",
            "tfcagricultureplus:food/butter_slice")) {
            final var item = net.minecraft.core.registries.BuiltInRegistries.ITEM.get(ResourceLocation.parse(id));
            if (item != net.minecraft.world.item.Items.AIR) {
                hidden.add(new net.minecraft.world.item.ItemStack(item));
            }
        }
        // TFC Woodworking is an optional migration source. If it is installed for
        // comparison, hide its registered item/block entries from JEI so the B-owned
        // recipes remain the only visible woodwork surface. B's high-priority world
        // handler remains authoritative for the actual interaction.
        for (final var item : net.minecraft.core.registries.BuiltInRegistries.ITEM) {
            final var key = net.minecraft.core.registries.BuiltInRegistries.ITEM.getKey(item);
            if (key != null && key.getNamespace().equals("tfcwoodwork")) {
                hidden.add(new net.minecraft.world.item.ItemStack(item));
            }
        }
        registration.getIngredientVisibility().hideIngredients(
            VanillaTypes.ITEM_STACK, hidden, List.of(UidContext.Ingredient, UidContext.Recipe));
    }

    @Override
    public void registerRecipeCatalysts(IRecipeCatalystRegistration registration) {
        for (final var family : List.of(
            com.example.tfcfarmingplus.expansion.common.MyBlocks.WOODEN_CUTTING_BOARDS,
            com.example.tfcfarmingplus.expansion.common.MyBlocks.STONE_CUTTING_BOARDS,
            com.example.tfcfarmingplus.expansion.common.MyBlocks.LOG_CUTTING_BOARDS)) {
            for (final var block : family.values()) {
                registration.addRecipeCatalyst(new net.minecraft.world.item.ItemStack(block.get()), CUTTING_BOARD);
            }
        }
        // 石臼的 15 种岩石变体都是"催化剂"（JEI 里点配方能看到"用哪个方块做"）
        for (final String rock : com.example.tfcfarmingplus.expansion.common.MyBlocks.MORTAR_ROCKS) {
            registration.addRecipeCatalyst(
                new net.minecraft.world.item.ItemStack(
                    com.example.tfcfarmingplus.expansion.common.MyBlocks.MORTARS.get("mortar/" + rock).get()),
                MORTAR);
        }
        registration.addRecipeCatalyst(new net.minecraft.world.item.ItemStack(
            com.example.tfcfarmingplus.expansion.common.MyBlocks.COOKING_PAN.get()), PAN);
    }

    private static List<InWorldRecipe> getInWorldRecipes() {
        final var level = Minecraft.getInstance().level;
        if (level == null) return List.of();
        return level.getRecipeManager()
            .getAllRecipesFor(MyRecipeTypes.IN_WORLD.get()).stream()
            .map(net.minecraft.world.item.crafting.RecipeHolder::value)
            .toList();
    }

    @Override
    public void onRuntimeAvailable(mezz.jei.api.runtime.IJeiRuntime runtime) {
        if (!Boolean.getBoolean("tfcagricultureplus.debug")) return;
        final var manager = runtime.getRecipeManager();
        TFCAgriculturePlus.LOGGER.info("[JEI-VERIFY] visible cutting={} in_world={}",
            manager.createRecipeLookup(CUTTING_BOARD).get().count(), manager.createRecipeLookup(IN_WORLD).get().count());
        final var item = net.minecraft.core.registries.BuiltInRegistries.ITEM.get(ResourceLocation.parse("firmalife:food/wheat_slice"));
        runtime.getIngredientManager().getAllIngredients(mezz.jei.api.constants.VanillaTypes.ITEM_STACK).stream()
            .filter(stack -> stack.is(item)).findFirst().ifPresent(stack -> {
                final var focus = runtime.getJeiHelpers().getFocusFactory().createFocus(
                    mezz.jei.api.recipe.RecipeIngredientRole.OUTPUT, mezz.jei.api.constants.VanillaTypes.ITEM_STACK, stack);
                TFCAgriculturePlus.LOGGER.info("[JEI-VERIFY] wheat slice source matches={}",
                    manager.createRecipeLookup(CUTTING_BOARD).limitFocus(List.of(focus)).get().count());
            });
    }
}
