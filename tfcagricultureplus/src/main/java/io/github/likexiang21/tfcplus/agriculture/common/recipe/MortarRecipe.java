package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.item.crafting.SingleRecipeInput;
import net.minecraft.world.level.Level;

/**
 * 🆕 <b>研磨配方</b>（石臼）—— 本模组的**第一个配方类型**，用于打通整条链路：
 * <b>Java 类型 → 数据包 JSON → 配方管理器 → JEI 展示</b>。
 *
 * <h2>为什么先做这一个</h2>
 * 用户口径：「**先为后续的加工配方引入和 jei 适配做好代码基础**」⇒
 * 后面的 12 个配方类型（126 §14.6）都要照这个骨架复制，所以**第一个必须把坑踩完**。
 *
 * <h2>Schema（数据包）</h2>
 * <pre>
 * data/&lt;ns&gt;/recipe/mortar/&lt;name&gt;.json
 * {
 *   "type": "tfcagricultureplus:mortar",
 *   "ingredient": { "item": "tfc:food/wheat" },     // 或 { "tag": "..." }
 *   "result":     { "id": "tfc:food/wheat_flour", "count": 1 },
 *   "grind_time": 4                                  // 可选，默认 4 次敲击
 * }
 * </pre>
 *
 * <p>⚠️ 三件套缺一不可（照 TFC 的 {@code TFCRecipeSerializers}）：
 * {@code MapCodec}（数据包读取）+ {@code StreamCodec}（网络同步）+ {@link RecipeType}。
 */
public record MortarRecipe(Ingredient ingredient, ItemStack result, int grindTime)
    implements Recipe<SingleRecipeInput> {

    public MortarRecipe {
        if (grindTime < 1) {
            throw new IllegalArgumentException("grind_time must be at least 1");
        }
        result = result.copy();
    }

    /** 默认研磨敲击次数。 */
    public static final int DEFAULT_GRIND_TIME = 4;

    @Override
    public boolean matches(SingleRecipeInput input, Level level) {
        return !FoodCapability.isRotten(input.item()) && ingredient.test(input.item());
    }

    @Override
    public ItemStack assemble(SingleRecipeInput input, net.minecraft.core.HolderLookup.Provider registries) {
        final ItemStack output = result.copy();
        return FoodCapability.has(input.item())
            ? FoodCapability.updateFoodFromPrevious(input.item(), output)
            : FoodCapability.setCreatedNow(output);
    }

    @Override
    public boolean canCraftInDimensions(int width, int height) {
        return true;   // 非网格配方
    }

    @Override
    public ItemStack getResultItem(net.minecraft.core.HolderLookup.Provider registries) {
        return result.copy();
    }

    @Override
    public RecipeSerializer<?> getSerializer() {
        return AgricultureRecipeSerializers.MORTAR.get();
    }

    @Override
    public RecipeType<?> getType() {
        return AgricultureRecipeTypes.MORTAR.get();
    }

    // ==================================================================
    // 序列化器（照 TFC 的 record + MapCodec + StreamCodec 双编解码器）
    // ==================================================================

    
}
