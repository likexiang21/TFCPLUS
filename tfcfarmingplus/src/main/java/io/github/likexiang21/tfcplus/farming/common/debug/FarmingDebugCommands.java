package io.github.likexiang21.tfcplus.farming.common.debug;

import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.arguments.LongArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import io.github.likexiang21.tfcplus.farming.common.tree.FarmingFruitTrees;
import net.dries007.tfc.common.blockentities.TickCounterBlockEntity;
import net.dries007.tfc.common.blocks.plant.fruit.SeasonalPlantBlock;
import net.dries007.tfc.util.calendar.Calendars;
import net.dries007.tfc.util.calendar.Month;
import net.dries007.tfc.util.climate.Climate;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.coordinates.BlockPosArgument;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

/**
 * 开发期自检命令 —— <b>默认不注册</b>，只有带 JVM 参数 {@code -Dtfcfarmingplus.debug=true}
 * 时才挂载（{@code launch-client.ps1} 已经带上）。正式打包的模组里这些命令不存在。
 *
 * <h2>为什么需要它</h2>
 * 「种下 → 8 天 → 开花 → 结果 → 采摘」这条链的每一环都只存在于运行期，
 * 编译与静态校验（{@code verify.ps1}）都覆盖不到；而这个项目已经反复证明
 * 「构建成功 ≠ 能跑 ≠ 效果正确」。
 *
 * <candidatePos>为什么不用别的办法：
 * <ul>
 *   <li><b>数据包函数</b>：函数执行时 Minecraft 会 {@code withSuppressedOutput()}，
 *       {@code data get} 之类命令的输出**不会进日志**；而这个命令同时写模组 LOGGER，
 *       所以「用数据包函数调用本命令」是可行的（见 {@code saves/tfctest/datapacks/tfcdbg}）；</li>
 *   <li><b>靠等随机刻</b>：命中密度是 {@code randomTickSpeed / 4096} 每 tick，
 *       默认 3 时单个方块期望要等约 68 秒，根本测不到关键路径；</li>
 *   <li><b>调高 {@code randomTickSpeed}</b>：会把整个世界一起加速，属于**改测试环境**，
 *       测完还得还原 —— 不如只点名触发那一个方块。</li>
 * </ul>
 *
 * <h2>用法</h2>
 * <pre>
 * /tfcfarmingplus calendar                                    查看 TFC 日历刻与月份（物候按月份门控）
 * /tfcfarmingplus plant &lt;tree&gt; &lt;pos&gt;                          从 pos 向下找地面，把树苗种在地面上方，并记住位置
 * /tfcfarmingplus probe [pos]                                 打印方块、方块实体、计时器（省略 pos 用上次种植位置）
 * /tfcfarmingplus randomtick &lt;n&gt; | &lt;pos&gt; &lt;n&gt;                   手动触发 n 次随机刻
 * /tfcfarmingplus setcounter &lt;ticks&gt; | &lt;pos&gt; &lt;ticks&gt;           把计时器设成「已过去 ticks」＝跳过等待
 * /tfcfarmingplus tree &lt;tree&gt; [pos]                           报告该树种在此处能否生长（气候判定）
 * </pre>
 */
public final class FarmingDebugCommands {

    private static final String DEBUG_PREFIX = "[TFCDBG] ";

    /**
     * 上一次 {@code plant} 实际放置的位置。
     * <candidatePos>
     * 有了它，后续的 {@code probe / randomtick / setcounter} 可以省略坐标 ——
     * 这很重要：{@code plant} 是「向下扫描找地面」后才决定放哪里的，
     * 调用方事先并不知道那个 y，而数据包函数又没法把上一条命令的结果传给下一条。
     */
    private static BlockPos lastPlacedPosition = null;

    /** 由 {@code TFCFarmingPlus} 在调试模式下挂到游戏总线上 */
    public static void register(RegisterCommandsEvent event) {
        event.getDispatcher().register(
            Commands.literal("tfcfarmingplus")
                .requires(src -> src.hasPermission(2))
                .then(Commands.literal("calendar")
                    .executes(FarmingDebugCommands::calendar))
                .then(Commands.literal("plant")
                    .then(Commands.argument("tree", StringArgumentType.word())
                        .then(Commands.argument("pos", BlockPosArgument.blockPos())
                            .executes(FarmingDebugCommands::plant))))
                .then(Commands.literal("tree")
                    .then(Commands.argument("tree", StringArgumentType.word())
                        .executes(ctx -> tree(ctx, StringArgumentType.getString(ctx, "tree"), requireRemembered(ctx)))
                        .then(Commands.argument("pos", BlockPosArgument.blockPos())
                            .executes(ctx -> tree(ctx, StringArgumentType.getString(ctx, "tree"),
                                BlockPosArgument.getLoadedBlockPos(ctx, "pos"))))))
                .then(Commands.literal("probe")
                    .executes(ctx -> probe(ctx, requireRemembered(ctx)))
                    .then(Commands.argument("pos", BlockPosArgument.blockPos())
                        .executes(ctx -> probe(ctx, BlockPosArgument.getLoadedBlockPos(ctx, "pos")))))
                .then(Commands.literal("randomtick")
                    .then(Commands.argument("count", IntegerArgumentType.integer(1, 100000))
                        .executes(ctx -> randomTick(ctx, requireRemembered(ctx), IntegerArgumentType.getInteger(ctx, "count"))))
                    .then(Commands.argument("pos", BlockPosArgument.blockPos())
                        .then(Commands.argument("count", IntegerArgumentType.integer(1, 100000))
                            .executes(ctx -> randomTick(ctx, BlockPosArgument.getLoadedBlockPos(ctx, "pos"),
                                IntegerArgumentType.getInteger(ctx, "count"))))))
                .then(Commands.literal("setcounter")
                    .then(Commands.argument("ticks", LongArgumentType.longArg(0L))
                        .executes(ctx -> setCounter(ctx, requireRemembered(ctx), LongArgumentType.getLong(ctx, "ticks"))))
                    .then(Commands.argument("pos", BlockPosArgument.blockPos())
                        .then(Commands.argument("ticks", LongArgumentType.longArg(0L))
                            .executes(ctx -> setCounter(ctx, BlockPosArgument.getLoadedBlockPos(ctx, "pos"),
                                LongArgumentType.getLong(ctx, "ticks"))))))
        );
    }

    // ---------------------------------------------------------------- 子命令

    private static int calendar(CommandContext<CommandSourceStack> ctx) {
        final long ticks = Calendars.SERVER.getTicks();
        // 果树的物候是按月份门控的：FruitTreeSaplingBlock.randomTick 的第一步就是
        // stages[当月].active()，不成立就整段跳过 —— 所以验证前必须先知道当前是哪个月。
        final Month month = Calendars.SERVER.getHemispheralCalendarMonthOfYear(true);
        sendMessage(ctx, "calendar ticks=" + ticks + " month=" + month + " ordinal=" + month.ordinal());
        return 1;
    }

    /**
     * 从起点**向下找真实地面**，把指定树苗种在它正上方，并记住这个位置。
     *
     * <h2>为什么不能直接 setblock 到「玩家旁边」</h2>
     * 那样很容易落在**悬空**位置：方块即使放下去了，也会因为缺少支撑而消失
     * （TFC 的塌落机制 + 方块自身的 {@code canSurvive}），表现为「树苗凭空不见」，
     * 把实验结论带偏。所以先扫描到实心地面再放。
     *
     * <candidatePos>另一个容易踩的点：树苗的 {@code canSurvive} 走 {@code BushBlock}（接受 {@code #minecraft:dirt}），
     * 而长大后换上的 {@code growing_branch} 走 {@code PipePlantBlock.canSurvive}，
     * 后者只认「下方是果树枝干，或 {@code tfc:bush_plantable_on} 里的土壤」——
     * **原版泥土能种树苗、却撑不住枝条**，枝条会在第一次 {@code PipePlantBlock.tick}
     * 被 {@code destroyBlock} 清掉。
     */
    private static int plant(CommandContext<CommandSourceStack> ctx) throws CommandSyntaxException {
        final String name = StringArgumentType.getString(ctx, "tree");
        final ServerLevel level = ctx.getSource().getLevel();
        final BlockPos from = BlockPosArgument.getLoadedBlockPos(ctx, "pos");

        final var holder = FarmingFruitTrees.SAPLINGS.get(name);
        if (holder == null) {
            sendMessage(ctx, "plant 未知树种: " + name);
            return 0;
        }

        BlockPos ground = null;
        for (int y = from.getY(); y > from.getY() - 64 && y > level.getMinBuildHeight(); y--) {
            final BlockPos candidatePos = new BlockPos(from.getX(), y, from.getZ());
            // 只认「顶面结实」的方块 —— 不能只看 !isAir()：植物类方块（树苗、枝干、草）
            // 也不是空气，但它们撑不住树苗，会被当成地面而把树苗种到半空里。
            if (level.getBlockState(candidatePos).isFaceSturdy(level, candidatePos, net.minecraft.core.Direction.UP)) {
                ground = candidatePos;
                break;
            }
        }
        if (ground == null) {
            sendMessage(ctx, "plant 在 " + from.getX() + " " + from.getY() + " " + from.getZ() + " 下方 64 格内没有地面");
            return 0;
        }

        final BlockPos target = ground.above();
        level.setBlockAndUpdate(target, holder.get().defaultBlockState());
        lastPlacedPosition = target;
        sendMessage(ctx, "plant " + name + " ground=" + ground.getY() + "(" + level.getBlockState(ground) + ")"
            + " -> sapling at " + target.getX() + " " + target.getY() + " " + target.getZ()
            + " = " + level.getBlockState(target));
        return 1;
    }

    private static int probe(CommandContext<CommandSourceStack> ctx, BlockPos pos) {
        final ServerLevel level = ctx.getSource().getLevel();
        final String positionLabel = pos.getX() + " " + pos.getY() + " " + pos.getZ();

        sendMessage(ctx, "probe " + positionLabel + " block=" + level.getBlockState(pos));

        final BlockEntity blockEntity = level.getBlockEntity(pos);
        if (blockEntity == null) {
            sendMessage(ctx, "probe " + positionLabel + " BE=<none>");
            return 1;
        }
        sendMessage(ctx, "probe " + positionLabel + " BE=" + blockEntity.getType());

        if (blockEntity instanceof TickCounterBlockEntity counter) {
            final long last = counter.getLastUpdateTick();
            sendMessage(ctx, "probe " + positionLabel + " lastUpdateTick=" + last
                + " sinceUpdate=" + counter.getTicksSinceUpdate()
                + (last == -2147483648L ? "  <-- 哨兵值：计时器从未被播种！" : ""));
        }
        final Object stem = invokeNoArg(blockEntity, "getStemPos");
        if (stem != null) {
            sendMessage(ctx, "probe " + positionLabel + " stemPos=" + stem);
        }
        return 1;
    }

    private static int randomTick(CommandContext<CommandSourceStack> ctx, BlockPos pos, int count) {
        final ServerLevel level = ctx.getSource().getLevel();
        final RandomSource random = RandomSource.create();
        for (int i = 0; i < count; i++) {
            // 每次都重新取 state —— 随机刻可能已经把方块换掉了
            level.getBlockState(pos).randomTick(level, pos, random);
        }
        sendMessage(ctx, "randomtick " + pos.getX() + " " + pos.getY() + " " + pos.getZ()
            + " x" + count + " -> block=" + level.getBlockState(pos));
        return 1;
    }

    private static int setCounter(CommandContext<CommandSourceStack> ctx, BlockPos pos, long ticks) {
        final ServerLevel level = ctx.getSource().getLevel();
        final BlockEntity blockEntity = level.getBlockEntity(pos);
        if (!(blockEntity instanceof TickCounterBlockEntity counter)) {
            sendMessage(ctx, "setcounter 失败：该位置没有计时用方块实体");
            return 0;
        }
        // 「已经过去 ticks」＝ 把上次更新时间往前推 ticks
        counter.setLastUpdateTick(Calendars.SERVER.getTicks() - ticks);
        sendMessage(ctx, "setcounter " + pos.getX() + " " + pos.getY() + " " + pos.getZ()
            + " ticks=" + ticks + " -> lastUpdateTick=" + counter.getLastUpdateTick()
            + " sinceUpdate=" + counter.getTicksSinceUpdate());
        return 1;
    }

    /**
     * 报告某树种在指定位置的气候判定结果。
     * <candidatePos>
     * 这正是 {@code FruitTreeSaplingBlock.randomTick} 决定「长成树」还是「枯死」的那一步：
     * {@code climateRange.checkBoth(hydration, temperature, false)}。
     * 判定不通过时树苗会变成 TFC 的枯死灌木 —— 而枯死灌木挂的是 TFC 自己的
     * {@code TICK_COUNTER}，其计时器同样从未被播种，于是被它自己的第一次随机刻立刻销毁，
     * 表现出来就像「树苗凭空消失」。
     */
    private static int tree(CommandContext<CommandSourceStack> ctx, String name, BlockPos pos) {
        final ServerLevel level = ctx.getSource().getLevel();

        final var climateReference = FarmingFruitTrees.CLIMATES.get(name);
        if (climateReference == null) {
            sendMessage(ctx, "tree 未知树种: " + name + "（可用值见 FarmingFruitTrees.TREES）");
            return 0;
        }
        final ClimateRange range = climateReference.get();
        if (range == null) {
            sendMessage(ctx, "tree " + name + " 气候数据未加载（检查 data/tfcfarmingplus/tfc/climate_range/plant/" + name + "_tree.json）");
            return 0;
        }
        final float temp = Climate.getAverageTemperature(level, pos);
        // 取法与 TFC 一致：FruitTreeSaplingBlock.randomTick 里是
        // getFruitBushHydrationFromRootPos(level, stemPos.below()) —— 传的是**树苗下方那一格**。
        final Integer hydration = hydrationFromRoot(level, pos.below());
        final boolean canGrow = hydration != null && range.checkBoth(hydration, temp, false);

        sendMessage(ctx, "tree " + name + " at " + pos.getX() + " " + pos.getY() + " " + pos.getZ()
            + " temperature=" + temp + " hydration=" + (hydration == null ? "N/A" : hydration)
            + " checkBoth=" + canGrow + (canGrow ? "  -> 可以生长" : "  -> 会枯死"));
        return 1;
    }

    // ---------------------------------------------------------------- 辅助

    /**
     * 取「以该位置为根部」的土壤水合度。
     * <candidatePos>
     * TFC 把 {@code SeasonalPlantBlock.getFruitBushHydrationFromRootPos} 定为
     * {@code protected static}，调试命令不是它的子类，所以这里反射调用 ——
     * 只出现在调试路径上，对正式包没有任何影响。
     */
    private static Integer hydrationFromRoot(ServerLevel level, BlockPos rootPos) {
        try {
            final var hydrationMethod = SeasonalPlantBlock.class.getDeclaredMethod(
                "getFruitBushHydrationFromRootPos", net.minecraft.world.level.Level.class, BlockPos.class);
            hydrationMethod.setAccessible(true);
            return (Integer) hydrationMethod.invoke(null, level, rootPos);
        } catch (ReflectiveOperationException e) {
            return null;
        }
    }

    private static Object invokeNoArg(Object target, String name) {
        try {
            return target.getClass().getMethod(name).invoke(target);
        } catch (ReflectiveOperationException e) {
            return null;
        }
    }

    private static BlockPos requireRemembered(CommandContext<CommandSourceStack> ctx) throws CommandSyntaxException {
        if (lastPlacedPosition == null) {
            throw new CommandSyntaxException(
                CommandSyntaxException.BUILT_IN_EXCEPTIONS.dispatcherUnknownArgument(),
                Component.literal("还没有目标位置：先执行一次 /tfcfarmingplus plant <tree> <pos>，或显式给出 pos"));
        }
        return lastPlacedPosition;
    }

    /** 同时写日志与命令反馈：日志保证无人值守时也拿得到结果 */
    private static void sendMessage(CommandContext<CommandSourceStack> ctx, String message) {
        TFCFarmingPlus.LOGGER.info(DEBUG_PREFIX + message);
        ctx.getSource().sendSuccess(() -> Component.literal(DEBUG_PREFIX + message), true);
    }

    private FarmingDebugCommands() {}
}
