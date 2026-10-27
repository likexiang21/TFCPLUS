package io.github.likexiang21.tfcplus.agriculture.common.debug;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeTypes;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.timber.*;
import io.github.likexiang21.tfcplus.agriculture.common.timber.BurningTimberPileBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlockEntity;
import net.dries007.tfc.common.blocks.TFCBlocks;
import net.dries007.tfc.common.component.TFCComponents;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.config.TFCConfig;
import net.minecraft.commands.Commands;
import net.minecraft.core.*;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.*;
import net.minecraft.world.*;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.item.*;
import net.minecraft.world.level.GameType;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.phys.*;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

/** Opt-in live-server verification. Uses the player's normal item-use and destruction paths. */
@EventBusSubscriber(modid=TFCAgriculturePlus.MOD_ID)
public final class DebugValidation {
    private static int passedChecks;
    @SubscribeEvent public static void register(RegisterCommandsEvent event) {
        if (!Boolean.getBoolean("tfcagricultureplus.debug")) return;
        event.getDispatcher().register(Commands.literal("tfcagricultureplus_verify").requires(source->source.hasPermission(2))
            .executes(context->runChecks(context.getSource().getPlayerOrException())));
    }
    private static int runChecks(ServerPlayer player) {
        ServerLevel level=player.serverLevel();
        if (!level.getServer().getWorldPath(net.minecraft.world.level.storage.LevelResource.ROOT).toAbsolutePath().normalize().getFileName().toString().startsWith("codex-validation-")) {
            player.sendSystemMessage(Component.literal("Verification is restricted to codex-validation-* save copies.")); return 0;
        }
        GameType originalGameType=player.gameMode.getGameModeForPlayer();
        ItemStack previousMainHand=player.getMainHandItem().copy(), previousOffHand=player.getOffhandItem().copy();
        passedChecks=0;
        try {
            player.setGameMode(GameType.SURVIVAL);
            player.setItemInHand(InteractionHand.OFF_HAND,ItemStack.EMPTY);
            player.setShiftKeyDown(false);
            BlockPos pos=new BlockPos(-1016,110,13500);
            // The support is a fixture; each tested block is placed using its actual BlockItem.
            level.setBlockAndUpdate(pos.below(),Blocks.SEA_LANTERN.defaultBlockState());
            level.removeBlock(pos,false); level.removeBlock(pos.above(),false);
            var recipes=level.getRecipeManager().getAllRecipesFor(AgricultureRecipeTypes.CUTTING_BOARD.get());
            require(recipes.size()==15,"15 cutting recipes loaded");
            for(var holder:recipes) {
                level.removeBlock(pos,false);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:cutting_board/oak"));
                ItemStack input=FoodCapability.setCreatedNow(holder.value().ingredient().getItems()[0].copyWithCount(2));
                simulateUse(player,pos,input);
                require(input.getCount()==1,"one ingredient consumed: "+holder.id());
                ItemStack knife=createItemStack("tfc:metal/knife/copper"); simulateUse(player,pos,knife);
                CuttingBoardBlockEntity cuttingBoard=getCuttingBoard(level,pos);
                require(cuttingBoard.getOnBoard().is(holder.value().result().stack().getItem()) && cuttingBoard.getOnBoard().getCount()==holder.value().result().stack().getCount(),"cut output: "+holder.id());
                require(cuttingBoard.getUsesLeft()==127 && knife.getDamageValue()==1,"cuttingBoard and knife wear: "+holder.id());
                var foodStack=cuttingBoard.getOnBoard().get(TFCComponents.FOOD);
                require(foodStack==null || foodStack.getCreationDate()>=0,"real output has a creation date: "+holder.id());
                var savedTag=cuttingBoard.saveWithoutMetadata(level.registryAccess()); cuttingBoard.loadWithComponents(savedTag,level.registryAccess());
                require(cuttingBoard.getUsesLeft()==127 && cuttingBoard.getOnBoard().getCount()==holder.value().result().stack().getCount(),"cuttingBoard save round-trip: "+holder.id());
                simulateUse(player,pos,ItemStack.EMPTY); require(cuttingBoard.isBoardEmpty(),"empty hand retrieves output: "+holder.id());
            }
            for(String id:java.util.List.of("cutting_board/oak","cutting_board/granite","log_cutting_board/hevea")) {
                level.removeBlock(pos,false); simulatePlace(player,pos,createItemStack("tfcagricultureplus:"+id));
                simulateUse(player,pos,FoodCapability.setRotten(createItemStack("tfc:food/wheat_bread")));
                ItemStack knife=createItemStack("tfc:metal/knife/copper"); simulateUse(player,pos,knife);
                require(getCuttingBoard(level,pos).getUsesLeft()==128 && knife.getDamageValue()==0 && FoodCapability.isRotten(getCuttingBoard(level,pos).getOnBoard()),"rotten rejected: "+id);
                simulateUse(player,pos,ItemStack.EMPTY); simulateUse(player,pos,createItemStack("minecraft:stick")); simulateUse(player,pos,knife);
                require(getCuttingBoard(level,pos).getUsesLeft()==128 && knife.getDamageValue()==0,"invalid recipe unchanged: "+id);
                simulateUse(player,pos,ItemStack.EMPTY); simulateUse(player,pos,FoodCapability.setCreatedNow(createItemStack("tfc:food/wheat_bread")));
                var savedTag=getCuttingBoard(level,pos).saveWithoutMetadata(level.registryAccess()); savedTag.putInt("uses_left",1); getCuttingBoard(level,pos).loadWithComponents(savedTag,level.registryAccess());
                int previousCount=countDrops(level,pos,"firmalife:food/wheat_slice"); simulateUse(player,pos,knife);
                require(level.isEmptyBlock(pos) && countDrops(level,pos,"firmalife:food/wheat_slice")==previousCount+2,"last use retains two slices: "+id);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:"+id)); simulateUse(player,pos,createItemStack("minecraft:stick"));
                previousCount=countDrops(level,pos,"minecraft:stick"); player.gameMode.destroyBlock(pos);
                require(countDrops(level,pos,"minecraft:stick")==previousCount+1,"destruction drops content once: "+id);
            }
            for(var holder:TimberBlocks.ALL.values()) {
                require(holder.get().getStateDefinition().getPossibleStates().size()<=8,"state budget: "+holder.getId());
            }
            for(String wood:java.util.stream.Stream.concat(AgricultureBlocks.TFC_WOODS.stream(),AgricultureBlocks.AFC_WOODS.stream()).toList()) {
                String origin=AgricultureBlocks.TFC_WOODS.contains(wood)?"tfc":"afc";
                for (String source : java.util.List.of("log", "wood")) {
                    level.removeBlock(pos,false);
                    simulatePlace(player,pos,createItemStack(origin+":wood/"+source+"/"+wood));
                    simulateUse(player,pos,createItemStack("tfc:metal/axe/copper"));
                    String stripped = source.equals("log") ? "stripped_log" : "stripped_wood";
                    require(level.getBlockState(pos).is(BuiltInRegistries.BLOCK.get(ResourceLocation.parse(origin+":wood/"+stripped+"/"+wood))),"strip "+source+" "+wood+": "+level.getBlockState(pos));
                    simulateUse(player,pos,createItemStack("tfc:metal/axe/copper"));
                    require(level.getBlockState(pos).is(BuiltInRegistries.BLOCK.get(ResourceLocation.parse("tfcagricultureplus:debarked_log/"+wood))),"debark "+source+" "+wood+": "+level.getBlockState(pos));
                }
                level.removeBlock(pos,false);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_log/"+wood));
                int previousCount=countDrops(level,pos,"tfcagricultureplus:debarked_half/"+wood);
                simulateUse(player,pos,createItemStack("tfc:metal/axe/copper"));
                require(level.isEmptyBlock(pos) && countDrops(level,pos,"tfcagricultureplus:debarked_half/"+wood)==previousCount+2,"split log "+wood);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_half/"+wood));
                previousCount=countDrops(level,pos,"tfcagricultureplus:debarked_quarter/"+wood); simulateUse(player,pos,createItemStack("tfc:metal/axe/copper"));
                require(countDrops(level,pos,"tfcagricultureplus:debarked_quarter/"+wood)==previousCount+2,"split half "+wood);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_quarter/"+wood));
                previousCount=countDrops(level,pos,origin+":wood/lumber/"+wood); simulateUse(player,pos,createItemStack("tfc:metal/saw/copper"));
                require(countDrops(level,pos,origin+":wood/lumber/"+wood)==previousCount+2,"saw quarter "+wood);
                simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_half/"+wood));
                previousCount=countDrops(level,pos,origin+":wood/support/"+wood); simulateUse(player,pos,createItemStack("tfc:metal/saw/copper"));
                require(countDrops(level,pos,origin+":wood/support/"+wood)==previousCount+4,"saw half "+wood);
            }
            for(String kind:java.util.List.of("debarked_log","debarked_half","debarked_quarter")) {
                level.removeBlock(pos,false); level.removeBlock(pos.above(),false);
                player.setShiftKeyDown(true); simulatePlace(player,pos,createItemStack("tfcagricultureplus:"+kind+"/oak")); player.setShiftKeyDown(false);
                require(level.getBlockEntity(pos) instanceof TimberPileBlockEntity,"sneak places pile: "+kind);
                TimberPileBlockEntity pile=(TimberPileBlockEntity)level.getBlockEntity(pos);
                int capacity=64/TimberBlocks.weight(createItemStack("tfcagricultureplus:"+kind+"/oak"));
                for(int i=1;i<capacity;i++) simulateUse(player,pos,createItemStack("tfcagricultureplus:"+kind+"/oak"));
                require(pile.units()==64 && pile.isFull(),"weighted capacity: "+kind);
                var savedTag=pile.saveWithoutMetadata(level.registryAccess()); pile.loadWithComponents(savedTag,level.registryAccess()); require(pile.units()==64,"pile save round-trip: "+kind);
                simulateUse(player,pos,createItemStack("tfcagricultureplus:"+kind+"/oak"));
                require(level.getBlockEntity(pos.above()) instanceof TimberPileBlockEntity above && above.units()==TimberBlocks.weight(createItemStack("tfcagricultureplus:"+kind+"/oak")),"overflow above: "+kind);
                simulateUse(player,pos,ItemStack.EMPTY); require(level.isEmptyBlock(pos.above()),"extract upper pile: "+kind);
                for(int i=0;i<capacity;i++) simulateUse(player,pos,ItemStack.EMPTY);
                require(level.isEmptyBlock(pos),"extract whole pile: "+kind);
            }
            // A covered pit, lit normally with flint and steel; only its timer is advanced.
            level.removeBlock(pos,false); player.setShiftKeyDown(true); simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_log/oak")); player.setShiftKeyDown(false);
            for(int i=1;i<16;i++) simulateUse(player,pos,createItemStack("tfcagricultureplus:debarked_log/oak"));
            for(Direction direction:Direction.values()) if(direction!=Direction.UP) level.setBlockAndUpdate(pos.relative(direction),Blocks.SMOOTH_STONE.defaultBlockState());
            simulateUse(player,pos,createItemStack("minecraft:flint_and_steel"));
            require(level.getBlockEntity(pos) instanceof BurningTimberPileBlockEntity,"ignition creates burning BE");
            BurningTimberPileBlockEntity burning=(BurningTimberPileBlockEntity)level.getBlockEntity(pos);
            require(burning.getTicksSinceUpdate()>=0 && burning.getTicksSinceUpdate()<100,"burning counter initialized");
            burning.checkBurning(level);
            require(level.getBlockEntity(pos)==burning,"unsealed ignition survives during sealing grace");
            simulateUse(player,pos,createItemStack("minecraft:smooth_stone"));
            require(level.getBlockState(pos.above()).is(Blocks.SMOOTH_STONE),"player item-use seals the burning pile");
            burning.increaseCounter(TFCConfig.SERVER.charcoalTicks.get()+1L);
            burning.checkBurning(level);
            require(level.getBlockState(pos).is(TFCBlocks.CHARCOAL_PILE.get()) && level.getBlockState(pos).getValue(BlockStateProperties.LAYERS)>=4 && level.getBlockState(pos).getValue(BlockStateProperties.LAYERS)<=8,"covered pit produces 4-8 charcoal layers");
            level.removeBlock(pos,false);
            for(Direction direction:Direction.values()) if(direction!=Direction.DOWN) level.removeBlock(pos.relative(direction),false);
            player.setShiftKeyDown(true); simulatePlace(player,pos,createItemStack("tfcagricultureplus:debarked_log/oak")); player.setShiftKeyDown(false);
            simulateUse(player,pos,createItemStack("minecraft:flint_and_steel"));
            BurningTimberPileBlockEntity exposed=(BurningTimberPileBlockEntity)level.getBlockEntity(pos);
            exposed.checkBurning(level); require(level.getBlockEntity(pos)==exposed,"open pile initially permits sealing");
            exposed.increaseCounter(201L); exposed.checkBurning(level);
            require(level.isEmptyBlock(pos),"unsealed pile burns away after the grace period");
            TFCAgriculturePlus.LOGGER.info("[VERIFY] PASS {} live checks: boards, 34 woods, weighted piles and charcoal",passedChecks);
            player.sendSystemMessage(Component.literal("[VERIFY] PASS "+passedChecks+" live checks"));
            return passedChecks;
        } catch(Exception exception) {
            TFCAgriculturePlus.LOGGER.error("[VERIFY] FAIL after {} checks",passedChecks,exception);
            player.sendSystemMessage(Component.literal("[VERIFY] FAIL: "+exception.getMessage())); return 0;
        } finally {
            player.setShiftKeyDown(false); player.setGameMode(originalGameType);
            player.setItemInHand(InteractionHand.MAIN_HAND,previousMainHand); player.setItemInHand(InteractionHand.OFF_HAND,previousOffHand);
        }
    }
    private static void require(boolean success,String label) { if(!success) throw new IllegalStateException(label); passedChecks++; }
    private static ItemStack createItemStack(String id) { ItemStack stack=new ItemStack(BuiltInRegistries.ITEM.get(ResourceLocation.parse(id))); if(stack.isEmpty()) throw new IllegalStateException("Missing item "+id); return stack; }
    private static CuttingBoardBlockEntity getCuttingBoard(ServerLevel level,BlockPos pos) { return (CuttingBoardBlockEntity)level.getBlockEntity(pos); }
    private static void simulateUse(ServerPlayer player,BlockPos pos,ItemStack stack) {
        player.setItemInHand(InteractionHand.MAIN_HAND,stack);
        player.gameMode.useItemOn(player,player.serverLevel(),stack,InteractionHand.MAIN_HAND,new BlockHitResult(Vec3.atCenterOf(pos),Direction.UP,pos,false));
    }
    private static void simulatePlace(ServerPlayer player,BlockPos pos,ItemStack stack) {
        simulateUse(player,pos.below(),stack);
        require(!player.serverLevel().isEmptyBlock(pos),"normal placement: "+stack.getItem());
    }
    private static int countDrops(ServerLevel level,BlockPos pos,String id) {
        Item target=BuiltInRegistries.ITEM.get(ResourceLocation.parse(id));
        return level.getEntitiesOfClass(ItemEntity.class,new AABB(pos).inflate(2)).stream().filter(entity->entity.getItem().is(target)).mapToInt(entity->entity.getItem().getCount()).sum();
    }
    private DebugValidation() {}
}
