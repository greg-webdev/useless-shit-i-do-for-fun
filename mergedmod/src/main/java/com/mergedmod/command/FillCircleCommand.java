package com.mergedmod.command;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import com.mojang.brigadier.exceptions.Dynamic2CommandExceptionType;
import com.mojang.brigadier.exceptions.SimpleCommandExceptionType;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.Commands;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.arguments.coordinates.BlockPosArgument;
import net.minecraft.commands.arguments.blocks.BlockStateArgument;
import net.minecraft.commands.arguments.blocks.BlockInput;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.gamerules.GameRules;

import java.util.ArrayList;
import java.util.List;

public class FillCircleCommand {
    private static final SimpleCommandExceptionType ERROR_FAILED = new SimpleCommandExceptionType(
        Component.literal("Could not place any blocks (all blocks may already be of that type or outside world bounds)")
    );
    private static final Dynamic2CommandExceptionType ERROR_TOO_MANY_BLOCKS = new Dynamic2CommandExceptionType(
        (max, count) -> Component.literal(String.format("Too many blocks in the specified area (maximum %s, specified %s)", max, count))
    );

    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        dispatcher.register(
            Commands.literal("fillcircle")
                .requires(Commands.hasPermission(Commands.LEVEL_GAMEMASTERS))
                .then(Commands.argument("radius", IntegerArgumentType.integer(1, 1024))
                    .then(Commands.argument("hollow", BoolArgumentType.bool())
                        .then(Commands.argument("howtall", IntegerArgumentType.integer(1, 384))
                            .then(Commands.argument("usewhatblock", BlockStateArgument.block(buildContext))
                                .executes(ctx -> execute(ctx, null))
                                .then(Commands.argument("center", BlockPosArgument.blockPos())
                                    .executes(ctx -> execute(ctx, BlockPosArgument.getLoadedBlockPos(ctx, "center")))
                                )
                            )
                        )
                    )
                )
        );
    }

    private static int execute(CommandContext<CommandSourceStack> context, BlockPos customCenter) throws CommandSyntaxException {
        CommandSourceStack source = context.getSource();
        int radius = IntegerArgumentType.getInteger(context, "radius");
        boolean hollow = BoolArgumentType.getBool(context, "hollow");
        int height = IntegerArgumentType.getInteger(context, "howtall");
        BlockInput blockInput = BlockStateArgument.getBlock(context, "usewhatblock");

        ServerLevel level = source.getLevel();
        BlockPos center = customCenter != null ? customCenter : BlockPos.containing(source.getPosition());

        int cx = center.getX();
        int startY = center.getY();
        int cz = center.getZ();

        int minY = startY;
        int maxY = startY + height - 1;

        double rSq = (radius + 0.25) * (radius + 0.25);

        List<int[]> offsets = new ArrayList<>();
        for (int dx = -radius; dx <= radius; dx++) {
            for (int dz = -radius; dz <= radius; dz++) {
                if (isInside(dx, dz, rSq)) {
                    if (!hollow || isBorder(dx, dz, rSq)) {
                        offsets.add(new int[]{dx, dz});
                    }
                }
            }
        }

        long totalBlocks = (long) offsets.size() * height;
        int maxModifications = level.getGameRules().get(GameRules.MAX_BLOCK_MODIFICATIONS);
        if (totalBlocks > maxModifications) {
            throw ERROR_TOO_MANY_BLOCKS.create(maxModifications, totalBlocks);
        }

        int placedCount = 0;
        BlockPos.MutableBlockPos mutablePos = new BlockPos.MutableBlockPos();

        for (int y = minY; y <= maxY; y++) {
            if (y < level.getMinY() || y > level.getMaxY()) {
                continue;
            }
            for (int[] offset : offsets) {
                mutablePos.set(cx + offset[0], y, cz + offset[1]);
                if (level.isInWorldBounds(mutablePos)) {
                    if (blockInput.place(level, mutablePos.immutable(), Block.UPDATE_ALL)) {
                        placedCount++;
                    }
                }
            }
        }

        if (placedCount == 0) {
            throw ERROR_FAILED.create();
        }

        final int count = placedCount;
        source.sendSuccess(() -> Component.literal(
            String.format("Successfully placed %d blocks in a circle (radius: %d, height: %d, hollow: %b)",
                count, radius, height, hollow)
        ), true);

        return placedCount;
    }

    private static boolean isInside(int dx, int dz, double rSq) {
        return (dx * dx + dz * dz) <= rSq;
    }

    private static boolean isBorder(int dx, int dz, double rSq) {
        return !isInside(dx + 1, dz, rSq)
            || !isInside(dx - 1, dz, rSq)
            || !isInside(dx, dz + 1, rSq)
            || !isInside(dx, dz - 1, rSq);
    }
}
