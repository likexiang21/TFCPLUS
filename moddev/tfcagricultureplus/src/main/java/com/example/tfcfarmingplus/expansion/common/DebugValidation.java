package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.blockentities.CuttingBoardBlockEntity;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import com.example.tfcfarmingplus.expansion.common.timber.*;
import net.dries007.tfc.common.component.TFCComponents;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.blocks.TFCBlocks;
import net.dries007.tfc.config.TFCConfig;
import net.minecraft.core.*;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.commands.Commands;
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
    private static int checks;
    @SubscribeEvent public static void register(RegisterCommandsEvent event) {
        if (!Boolean.getBoolean("tfcagricultureplus.debug")) return;
        event.getDispatcher().register(Commands.literal("tfcagricultureplus_verify").requires(source->source.hasPermission(2))
            .executes(context->run(context.getSource().getPlayerOrException())));
    }
    private static int run(ServerPlayer player) {
        ServerLevel level=player.serverLevel();
        if (!level.getServer().getWorldPath(net.minecraft.world.level.storage.LevelResource.ROOT).toAbsolutePath().normalize().getFileName().toString().startsWith("codex-validation-")) {
            player.sendSystemMessage(Component.literal("Verification is restricted to codex-validation-* save copies.")); return 0;
        }
        GameType original=player.gameMode.getGameModeForPlayer();
        ItemStack main=player.getMainHandItem().copy(), off=player.getOffhandItem().copy();
        checks=0;
        try {
            player.setGameMode(GameType.SURVIVAL);
            player.setItemInHand(InteractionHand.OFF_HAND,ItemStack.EMPTY);
            player.setShiftKeyDown(false);
            BlockPos pos=new BlockPos(-1016,110,13500);
            // The support is a fixture; each tested block is placed using its actual BlockItem.
            level.setBlockAndUpdate(pos.below(),Blocks.SEA_LANTERN.defaultBlockState());
            level.removeBlock(pos,false); level.removeBlock(pos.above(),false);
            var recipes=level.getRecipeManager().getAllRecipesFor(MyRecipeTypes.CUTTING_BOARD.get());
            check(recipes.size()==12,"12 cutting recipes loaded");
            for(var holder:recipes) {
                level.removeBlock(pos,false);
                place(player,pos,item("tfcagricultureplus:cutting_board/oak"));
                ItemStack input=FoodCapability.setCreatedNow(holder.value().ingredient().getItems()[0].copyWithCount(2));
                use(player,pos,input);
                check(input.getCount()==1,"one ingredient consumed: "+holder.id());
                ItemStack knife=item("tfc:metal/knife/copper"); use(player,pos,knife);
                CuttingBoardBlockEntity board=board(level,pos);
                check(board.getOnBoard().is(holder.value().result().stack().getItem()) && board.getOnBoard().getCount()==holder.value().result().stack().getCount(),"cut output: "+holder.id());
                check(board.getUsesLeft()==127 && knife.getDamageValue()==1,"board and knife wear: "+holder.id());
                var food=board.getOnBoard().get(TFCComponents.FOOD);
                check(food==null || food.getCreationDate()>=0,"real output has a creation date: "+holder.id());
                var nbt=board.saveWithoutMetadata(level.registryAccess()); board.loadWithComponents(nbt,level.registryAccess());
                check(board.getUsesLeft()==127 && board.getOnBoard().getCount()==holder.value().result().stack().getCount(),"board save round-trip: "+holder.id());
                use(player,pos,ItemStack.EMPTY); check(board.isBoardEmpty(),"empty hand retrieves output: "+holder.id());
            }
            for(String id:java.util.List.of("cutting_board/oak","cutting_board/granite","log_cutting_board/hevea")) {
                level.removeBlock(pos,false); place(player,pos,item("tfcagricultureplus:"+id));
                use(player,pos,FoodCapability.setRotten(item("tfc:food/wheat_bread")));
                ItemStack knife=item("tfc:metal/knife/copper"); use(player,pos,knife);
                check(board(level,pos).getUsesLeft()==128 && knife.getDamageValue()==0 && FoodCapability.isRotten(board(level,pos).getOnBoard()),"rotten rejected: "+id);
                use(player,pos,ItemStack.EMPTY); use(player,pos,item("minecraft:stick")); use(player,pos,knife);
                check(board(level,pos).getUsesLeft()==128 && knife.getDamageValue()==0,"invalid recipe unchanged: "+id);
                use(player,pos,ItemStack.EMPTY); use(player,pos,FoodCapability.setCreatedNow(item("tfc:food/wheat_bread")));
                var nbt=board(level,pos).saveWithoutMetadata(level.registryAccess()); nbt.putInt("uses_left",1); board(level,pos).loadWithComponents(nbt,level.registryAccess());
                int before=drops(level,pos,"firmalife:food/wheat_slice"); use(player,pos,knife);
                check(level.isEmptyBlock(pos) && drops(level,pos,"firmalife:food/wheat_slice")==before+2,"last use retains two slices: "+id);
                place(player,pos,item("tfcagricultureplus:"+id)); use(player,pos,item("minecraft:stick"));
                before=drops(level,pos,"minecraft:stick"); player.gameMode.destroyBlock(pos);
                check(drops(level,pos,"minecraft:stick")==before+1,"destruction drops content once: "+id);
            }
            for(var holder:TimberBlocks.ALL.values()) {
                check(holder.get().getStateDefinition().getPossibleStates().size()<=8,"state budget: "+holder.getId());
            }
            for(String wood:java.util.stream.Stream.concat(MyBlocks.TFC_WOODS.stream(),MyBlocks.AFC_WOODS.stream()).toList()) {
                String origin=MyBlocks.TFC_WOODS.contains(wood)?"tfc":"afc";
                for (String source : java.util.List.of("log", "wood")) {
                    level.removeBlock(pos,false);
                    place(player,pos,item(origin+":wood/"+source+"/"+wood));
                    use(player,pos,item("tfc:metal/axe/copper"));
                    String stripped = source.equals("log") ? "stripped_log" : "stripped_wood";
                    check(level.getBlockState(pos).is(BuiltInRegistries.BLOCK.get(ResourceLocation.parse(origin+":wood/"+stripped+"/"+wood))),"strip "+source+" "+wood+": "+level.getBlockState(pos));
                    use(player,pos,item("tfc:metal/axe/copper"));
                    check(level.getBlockState(pos).is(BuiltInRegistries.BLOCK.get(ResourceLocation.parse("tfcagricultureplus:debarked_log/"+wood))),"debark "+source+" "+wood+": "+level.getBlockState(pos));
                }
                level.removeBlock(pos,false);
                place(player,pos,item("tfcagricultureplus:debarked_log/"+wood));
                int before=drops(level,pos,"tfcagricultureplus:debarked_half/"+wood);
                use(player,pos,item("tfc:metal/axe/copper"));
                check(level.isEmptyBlock(pos) && drops(level,pos,"tfcagricultureplus:debarked_half/"+wood)==before+2,"split log "+wood);
                place(player,pos,item("tfcagricultureplus:debarked_half/"+wood));
                before=drops(level,pos,"tfcagricultureplus:debarked_quarter/"+wood); use(player,pos,item("tfc:metal/axe/copper"));
                check(drops(level,pos,"tfcagricultureplus:debarked_quarter/"+wood)==before+2,"split half "+wood);
                place(player,pos,item("tfcagricultureplus:debarked_quarter/"+wood));
                before=drops(level,pos,origin+":wood/lumber/"+wood); use(player,pos,item("tfc:metal/saw/copper"));
                check(drops(level,pos,origin+":wood/lumber/"+wood)==before+2,"saw quarter "+wood);
                place(player,pos,item("tfcagricultureplus:debarked_half/"+wood));
                before=drops(level,pos,origin+":wood/support/"+wood); use(player,pos,item("tfc:metal/saw/copper"));
                check(drops(level,pos,origin+":wood/support/"+wood)==before+4,"saw half "+wood);
            }
            for(String kind:java.util.List.of("debarked_log","debarked_half","debarked_quarter")) {
                level.removeBlock(pos,false); level.removeBlock(pos.above(),false);
                player.setShiftKeyDown(true); place(player,pos,item("tfcagricultureplus:"+kind+"/oak")); player.setShiftKeyDown(false);
                check(level.getBlockEntity(pos) instanceof TimberPileBlockEntity,"sneak places pile: "+kind);
                TimberPileBlockEntity pile=(TimberPileBlockEntity)level.getBlockEntity(pos);
                int capacity=64/TimberBlocks.weight(item("tfcagricultureplus:"+kind+"/oak"));
                for(int i=1;i<capacity;i++) use(player,pos,item("tfcagricultureplus:"+kind+"/oak"));
                check(pile.units()==64 && pile.isFull(),"weighted capacity: "+kind);
                var nbt=pile.saveWithoutMetadata(level.registryAccess()); pile.loadWithComponents(nbt,level.registryAccess()); check(pile.units()==64,"pile save round-trip: "+kind);
                use(player,pos,item("tfcagricultureplus:"+kind+"/oak"));
                check(level.getBlockEntity(pos.above()) instanceof TimberPileBlockEntity above && above.units()==TimberBlocks.weight(item("tfcagricultureplus:"+kind+"/oak")),"overflow above: "+kind);
                use(player,pos,ItemStack.EMPTY); check(level.isEmptyBlock(pos.above()),"extract upper pile: "+kind);
                for(int i=0;i<capacity;i++) use(player,pos,ItemStack.EMPTY);
                check(level.isEmptyBlock(pos),"extract whole pile: "+kind);
            }
            // A covered pit, lit normally with flint and steel; only its timer is advanced.
            level.removeBlock(pos,false); player.setShiftKeyDown(true); place(player,pos,item("tfcagricultureplus:debarked_log/oak")); player.setShiftKeyDown(false);
            for(int i=1;i<16;i++) use(player,pos,item("tfcagricultureplus:debarked_log/oak"));
            for(Direction direction:Direction.values()) if(direction!=Direction.UP) level.setBlockAndUpdate(pos.relative(direction),Blocks.SMOOTH_STONE.defaultBlockState());
            use(player,pos,item("minecraft:flint_and_steel"));
            check(level.getBlockEntity(pos) instanceof BurningTimberPileBlockEntity,"ignition creates burning BE");
            BurningTimberPileBlockEntity burning=(BurningTimberPileBlockEntity)level.getBlockEntity(pos);
            check(burning.getTicksSinceUpdate()>=0 && burning.getTicksSinceUpdate()<100,"burning counter initialized");
            burning.checkBurning(level);
            check(level.getBlockEntity(pos)==burning,"unsealed ignition survives during sealing grace");
            use(player,pos,item("minecraft:smooth_stone"));
            check(level.getBlockState(pos.above()).is(Blocks.SMOOTH_STONE),"player item-use seals the burning pile");
            burning.increaseCounter(TFCConfig.SERVER.charcoalTicks.get()+1L);
            burning.checkBurning(level);
            check(level.getBlockState(pos).is(TFCBlocks.CHARCOAL_PILE.get()) && level.getBlockState(pos).getValue(BlockStateProperties.LAYERS)>=4 && level.getBlockState(pos).getValue(BlockStateProperties.LAYERS)<=8,"covered pit produces 4-8 charcoal layers");
            level.removeBlock(pos,false);
            for(Direction direction:Direction.values()) if(direction!=Direction.DOWN) level.removeBlock(pos.relative(direction),false);
            player.setShiftKeyDown(true); place(player,pos,item("tfcagricultureplus:debarked_log/oak")); player.setShiftKeyDown(false);
            use(player,pos,item("minecraft:flint_and_steel"));
            BurningTimberPileBlockEntity exposed=(BurningTimberPileBlockEntity)level.getBlockEntity(pos);
            exposed.checkBurning(level); check(level.getBlockEntity(pos)==exposed,"open pile initially permits sealing");
            exposed.increaseCounter(201L); exposed.checkBurning(level);
            check(level.isEmptyBlock(pos),"unsealed pile burns away after the grace period");
            TFCAgriculturePlus.LOGGER.info("[VERIFY] PASS {} live checks: boards, 34 woods, weighted piles and charcoal",checks);
            player.sendSystemMessage(Component.literal("[VERIFY] PASS "+checks+" live checks"));
            return checks;
        } catch(Exception exception) {
            TFCAgriculturePlus.LOGGER.error("[VERIFY] FAIL after {} checks",checks,exception);
            player.sendSystemMessage(Component.literal("[VERIFY] FAIL: "+exception.getMessage())); return 0;
        } finally {
            player.setShiftKeyDown(false); player.setGameMode(original);
            player.setItemInHand(InteractionHand.MAIN_HAND,main); player.setItemInHand(InteractionHand.OFF_HAND,off);
        }
    }
    private static void check(boolean success,String label) { if(!success) throw new IllegalStateException(label); checks++; }
    private static ItemStack item(String id) { ItemStack stack=new ItemStack(BuiltInRegistries.ITEM.get(ResourceLocation.parse(id))); if(stack.isEmpty()) throw new IllegalStateException("Missing item "+id); return stack; }
    private static CuttingBoardBlockEntity board(ServerLevel level,BlockPos pos) { return (CuttingBoardBlockEntity)level.getBlockEntity(pos); }
    private static void use(ServerPlayer player,BlockPos pos,ItemStack stack) {
        player.setItemInHand(InteractionHand.MAIN_HAND,stack);
        player.gameMode.useItemOn(player,player.serverLevel(),stack,InteractionHand.MAIN_HAND,new BlockHitResult(Vec3.atCenterOf(pos),Direction.UP,pos,false));
    }
    private static void place(ServerPlayer player,BlockPos pos,ItemStack stack) {
        use(player,pos.below(),stack);
        check(!player.serverLevel().isEmptyBlock(pos),"normal placement: "+stack.getItem());
    }
    private static int drops(ServerLevel level,BlockPos pos,String id) {
        Item target=BuiltInRegistries.ITEM.get(ResourceLocation.parse(id));
        return level.getEntitiesOfClass(ItemEntity.class,new AABB(pos).inflate(2)).stream().filter(e->e.getItem().is(target)).mapToInt(e->e.getItem().getCount()).sum();
    }
    private DebugValidation() {}
}
