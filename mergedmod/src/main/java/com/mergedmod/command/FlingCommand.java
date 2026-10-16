package com.mergedmod.command;

import com.mergedmod.fling.FlingHelper;
import com.mergedmod.fling.FlingPadManager;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.DoubleArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import net.minecraft.ChatFormatting;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.commands.arguments.coordinates.BlockPosArgument;
import net.minecraft.commands.arguments.coordinates.Coordinates;
import net.minecraft.commands.arguments.coordinates.Vec3Argument;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.ClickEvent;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.HoverEvent;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

import java.util.Collection;
import java.util.List;
import java.util.Locale;

public class FlingCommand {
    private static final double DEFAULT_POWER = 1.8;
    private static final String[] DIRECTIONS = new String[]{
        "up", "down", "north", "south", "east", "west", "forward", "backward", "look"
    };

    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        var flingNode = Commands.literal("fling")
            .requires(Commands.hasPermission(Commands.LEVEL_GAMEMASTERS))
            .executes(ctx -> executeSelf(ctx.getSource()));

        flingNode.then(Commands.literal("help").executes(ctx -> sendHelp(ctx.getSource())));

        // /fling pad ...
        var padNode = Commands.literal("pad");
        padNode.then(Commands.literal("list").executes(ctx -> listPads(ctx.getSource())));
        padNode.then(Commands.literal("clear").executes(ctx -> clearPads(ctx.getSource())));
        padNode.then(Commands.literal("remove")
            .then(Commands.argument("pos", BlockPosArgument.blockPos())
                .executes(ctx -> removePad(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos")))
            )
        );

        var padAddNode = Commands.literal("add")
            .then(Commands.argument("pos", BlockPosArgument.blockPos())
                .then(Commands.argument("velocity", Vec3Argument.vec3())
                    .executes(ctx -> addPadVector(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), parseVec3(ctx, "velocity")))
                )
                .then(Commands.literal("thisway")
                    .executes(ctx -> addPadThisWay(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), DEFAULT_POWER))
                    .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                        .executes(ctx -> addPadThisWay(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), DoubleArgumentType.getDouble(ctx, "power")))
                    )
                )
            );

        for (String dir : DIRECTIONS) {
            padAddNode.then(Commands.argument("pos", BlockPosArgument.blockPos())
                .then(Commands.literal(dir)
                    .executes(ctx -> addPadDirection(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), dir, DEFAULT_POWER))
                    .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                        .executes(ctx -> addPadDirection(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), dir, DoubleArgumentType.getDouble(ctx, "power")))
                    )
                )
            );
        }
        padNode.then(padAddNode);
        flingNode.then(padNode);

        // /fling at <pos> ...
        var atNode = Commands.literal("at")
            .then(Commands.argument("pos", BlockPosArgument.blockPos())
                .then(Commands.argument("velocity", Vec3Argument.vec3())
                    .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), parseVec3(ctx, "velocity"), 0.0))
                )
                .then(Commands.literal("thisway")
                    .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), getSourceLookVector(ctx.getSource(), DEFAULT_POWER), 0.0))
                    .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                        .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), getSourceLookVector(ctx.getSource(), DoubleArgumentType.getDouble(ctx, "power")), 0.0))
                    )
                )
                .then(Commands.literal("radius")
                    .then(Commands.argument("radius", DoubleArgumentType.doubleArg(0.5, 32.0))
                        .then(Commands.argument("velocity", Vec3Argument.vec3())
                            .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), parseVec3(ctx, "velocity"), DoubleArgumentType.getDouble(ctx, "radius")))
                        )
                    )
                )
                .then(Commands.argument("targets", EntityArgument.entities())
                    .then(Commands.argument("velocity", Vec3Argument.vec3())
                        .executes(ctx -> executeAtTargets(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), EntityArgument.getEntities(ctx, "targets"), parseVec3(ctx, "velocity"), 0.0))
                    )
                    .then(Commands.literal("thisway")
                        .executes(ctx -> executeAtTargets(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), EntityArgument.getEntities(ctx, "targets"), getSourceLookVector(ctx.getSource(), DEFAULT_POWER), 0.0))
                        .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                            .executes(ctx -> executeAtTargets(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), EntityArgument.getEntities(ctx, "targets"), getSourceLookVector(ctx.getSource(), DoubleArgumentType.getDouble(ctx, "power")), 0.0))
                        )
                    )
                )
            );

        for (String dir : DIRECTIONS) {
            atNode.then(Commands.argument("pos", BlockPosArgument.blockPos())
                .then(Commands.literal(dir)
                    .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), getNamedDirectionVector(dir, DEFAULT_POWER, null), 0.0))
                    .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                        .executes(ctx -> executeAt(ctx.getSource(), BlockPosArgument.getLoadedBlockPos(ctx, "pos"), getNamedDirectionVector(dir, DoubleArgumentType.getDouble(ctx, "power"), null), 0.0))
                    )
                )
            );
        }
        flingNode.then(atNode);

        // /fling <targets> ...
        var targetsNode = Commands.argument("targets", EntityArgument.entities())
            .executes(ctx -> executeVector(ctx.getSource(), EntityArgument.getEntities(ctx, "targets"), new Vec3(0, DEFAULT_POWER, 0), "upwards"))
            .then(Commands.literal("thisway")
                .executes(ctx -> executeThisWay(ctx, EntityArgument.getEntities(ctx, "targets"), DEFAULT_POWER))
                .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                    .executes(ctx -> executeThisWay(ctx, EntityArgument.getEntities(ctx, "targets"), DoubleArgumentType.getDouble(ctx, "power")))
                )
            )
            .then(Commands.argument("velocity", Vec3Argument.vec3())
                .executes(ctx -> executeVector(ctx.getSource(), EntityArgument.getEntities(ctx, "targets"), parseVec3(ctx, "velocity"), null))
            );

        for (String dir : DIRECTIONS) {
            targetsNode.then(Commands.literal(dir)
                .executes(ctx -> executeNamedDirection(ctx.getSource(), EntityArgument.getEntities(ctx, "targets"), dir, DEFAULT_POWER))
                .then(Commands.argument("power", DoubleArgumentType.doubleArg(0.1, 50.0))
                    .executes(ctx -> executeNamedDirection(ctx.getSource(), EntityArgument.getEntities(ctx, "targets"), dir, DoubleArgumentType.getDouble(ctx, "power")))
                )
            );
        }

        flingNode.then(targetsNode);
        dispatcher.register(flingNode);
    }

    private static Vec3 parseVec3(CommandContext<CommandSourceStack> ctx, String argName) {
        Coordinates coords = Vec3Argument.getCoordinates(ctx, argName);
        return coords.getPosition(ctx.getSource().withPosition(Vec3.ZERO));
    }

    private static Vec3 getSourceLookVector(CommandSourceStack source, double power) {
        if (source.getEntity() != null) {
            return source.getEntity().getLookAngle().scale(power);
        }
        return Vec3.directionFromRotation(source.getRotation()).scale(power);
    }

    private static Vec3 getNamedDirectionVector(String dir, double power, Entity target) {
        return switch (dir.toLowerCase(Locale.ROOT)) {
            case "up" -> new Vec3(0, power, 0);
            case "down" -> new Vec3(0, -power, 0);
            case "north" -> new Vec3(0, power * 0.4, -power);
            case "south" -> new Vec3(0, power * 0.4, power);
            case "east" -> new Vec3(power, power * 0.4, 0);
            case "west" -> new Vec3(-power, power * 0.4, 0);
            case "forward" -> target != null 
                ? new Vec3(target.getLookAngle().x * power, Math.max(0.2, target.getLookAngle().y * power), target.getLookAngle().z * power)
                : new Vec3(0, power * 0.4, -power);
            case "backward" -> target != null 
                ? new Vec3(-target.getLookAngle().x * power, Math.max(0.2, -target.getLookAngle().y * power), -target.getLookAngle().z * power)
                : new Vec3(0, power * 0.4, power);
            case "look" -> target != null ? target.getLookAngle().scale(power) : new Vec3(0, power, 0);
            default -> new Vec3(0, power, 0);
        };
    }

    private static int executeSelf(CommandSourceStack source) throws CommandSyntaxException {
        if (source.getEntity() instanceof ServerPlayer player) {
            FlingHelper.fling(player, new Vec3(0, DEFAULT_POWER, 0), true);
            source.sendSuccess(() -> Component.literal("[Fling] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                .append(Component.literal("Flung yourself upwards!").withStyle(ChatFormatting.YELLOW)), false);
            return 1;
        }
        return sendHelp(source);
    }

    private static int executeThisWay(CommandContext<CommandSourceStack> ctx, Collection<? extends Entity> targets, double power) {
        CommandSourceStack source = ctx.getSource();
        Vec3 velocity = getSourceLookVector(source, power);

        for (Entity target : targets) {
            FlingHelper.fling(target, velocity, true);
        }

        String vxStr = String.format(Locale.ROOT, "%.2f", velocity.x);
        String vyStr = String.format(Locale.ROOT, "%.2f", velocity.y);
        String vzStr = String.format(Locale.ROOT, "%.2f", velocity.z);
        String dirStr = vxStr + " " + vyStr + " " + vzStr;

        String targetName = targets.size() == 1 
            ? targets.iterator().next().getScoreboardName() 
            : "@p";

        String copyCommand = "/fling " + targetName + " " + dirStr;

        Component message = Component.literal("[Fling] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("Flung " + (targets.size() == 1 ? targets.iterator().next().getDisplayName().getString() : targets.size() + " entities") + " ").withStyle(ChatFormatting.YELLOW))
            .append(Component.literal("thisway").withStyle(ChatFormatting.AQUA, ChatFormatting.BOLD))
            .append(Component.literal("!\n").withStyle(ChatFormatting.YELLOW))
            .append(Component.literal("Vector: ").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("[" + dirStr + "]").withStyle(style -> style
                .withColor(ChatFormatting.AQUA)
                .withUnderlined(true)
                .withClickEvent(new ClickEvent.CopyToClipboard(dirStr))
                .withHoverEvent(new HoverEvent.ShowText(Component.literal("Click to copy vector: " + dirStr)))
            ))
            .append(Component.literal(" "))
            .append(Component.literal("[📋 Copy Direction]").withStyle(style -> style
                .withColor(ChatFormatting.GREEN)
                .withBold(true)
                .withClickEvent(new ClickEvent.CopyToClipboard(dirStr))
                .withHoverEvent(new HoverEvent.ShowText(Component.literal("Click to copy: " + dirStr)))
            ))
            .append(Component.literal(" "))
            .append(Component.literal("[⚡ Copy Command]").withStyle(style -> style
                .withColor(ChatFormatting.LIGHT_PURPLE)
                .withBold(true)
                .withClickEvent(new ClickEvent.CopyToClipboard(copyCommand))
                .withHoverEvent(new HoverEvent.ShowText(Component.literal("Click to copy command: " + copyCommand)))
            ));

        source.sendSuccess(() -> message, false);
        return targets.size();
    }

    private static int executeNamedDirection(CommandSourceStack source, Collection<? extends Entity> targets, String dir, double power) {
        for (Entity target : targets) {
            Vec3 vel = getNamedDirectionVector(dir, power, target);
            FlingHelper.fling(target, vel, true);
        }

        source.sendSuccess(() -> Component.literal("[Fling] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("Flung " + targets.size() + " target(s) " + dir + " with power " + power).withStyle(ChatFormatting.YELLOW)), false);
        return targets.size();
    }

    private static int executeVector(CommandSourceStack source, Collection<? extends Entity> targets, Vec3 velocity, String customName) {
        for (Entity target : targets) {
            FlingHelper.fling(target, velocity, true);
        }

        String desc = customName != null ? customName : String.format(Locale.ROOT, "(%.2f, %.2f, %.2f)", velocity.x, velocity.y, velocity.z);
        source.sendSuccess(() -> Component.literal("[Fling] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("Flung " + targets.size() + " target(s) with velocity " + desc).withStyle(ChatFormatting.YELLOW)), false);
        return targets.size();
    }

    private static int executeAt(CommandSourceStack source, BlockPos pos, Vec3 velocity, double radius) {
        ServerLevel level = source.getLevel();
        AABB box = radius > 0 
            ? new AABB(pos).inflate(radius)
            : new AABB(pos.getX() - 0.2, pos.getY(), pos.getZ() - 0.2, pos.getX() + 1.2, pos.getY() + 1.5, pos.getZ() + 1.2);

        List<ServerPlayer> players = level.getEntitiesOfClass(ServerPlayer.class, box);
        if (players.isEmpty()) {
            return 0;
        }

        int count = 0;
        for (ServerPlayer player : players) {
            if (FlingPadManager.checkAndSetCooldown(player.getUUID(), 10)) {
                FlingHelper.fling(player, velocity, true);
                count++;
            }
        }
        return count;
    }

    private static int executeAtTargets(CommandSourceStack source, BlockPos pos, Collection<? extends Entity> targets, Vec3 velocity, double radius) {
        AABB box = radius > 0 
            ? new AABB(pos).inflate(radius)
            : new AABB(pos.getX() - 0.2, pos.getY(), pos.getZ() - 0.2, pos.getX() + 1.2, pos.getY() + 1.5, pos.getZ() + 1.2);

        int count = 0;
        for (Entity target : targets) {
            if (box.contains(target.position()) || box.intersects(target.getBoundingBox())) {
                if (target instanceof ServerPlayer player) {
                    if (!FlingPadManager.checkAndSetCooldown(player.getUUID(), 10)) {
                        continue;
                    }
                }
                FlingHelper.fling(target, velocity, true);
                count++;
            }
        }
        return count;
    }

    private static int addPadVector(CommandSourceStack source, BlockPos pos, Vec3 velocity) {
        String dim = source.getLevel().dimension().identifier().toString();
        FlingPadManager.addPad(dim, pos, velocity);
        source.sendSuccess(() -> Component.literal("[Fling Pad] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal(String.format(Locale.ROOT, "Added launch pad at (%d, %d, %d) with velocity (%.2f, %.2f, %.2f)",
                pos.getX(), pos.getY(), pos.getZ(), velocity.x, velocity.y, velocity.z)).withStyle(ChatFormatting.GREEN)), false);
        return 1;
    }

    private static int addPadThisWay(CommandSourceStack source, BlockPos pos, double power) {
        Vec3 vel = getSourceLookVector(source, power);
        return addPadVector(source, pos, vel);
    }

    private static int addPadDirection(CommandSourceStack source, BlockPos pos, String dir, double power) {
        Vec3 vel = getNamedDirectionVector(dir, power, null);
        return addPadVector(source, pos, vel);
    }

    private static int removePad(CommandSourceStack source, BlockPos pos) {
        String dim = source.getLevel().dimension().identifier().toString();
        boolean removed = FlingPadManager.removePad(dim, pos);
        if (removed) {
            source.sendSuccess(() -> Component.literal("[Fling Pad] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                .append(Component.literal(String.format("Removed launch pad at (%d, %d, %d)", pos.getX(), pos.getY(), pos.getZ())).withStyle(ChatFormatting.YELLOW)), false);
            return 1;
        } else {
            source.sendFailure(Component.literal(String.format("No launch pad found at (%d, %d, %d)", pos.getX(), pos.getY(), pos.getZ())));
            return 0;
        }
    }

    private static int listPads(CommandSourceStack source) {
        Collection<FlingPadManager.FlingPad> pads = FlingPadManager.getPads();
        if (pads.isEmpty()) {
            source.sendSuccess(() -> Component.literal("[Fling Pad] No launch pads registered.").withStyle(ChatFormatting.GRAY), false);
            return 0;
        }
        source.sendSuccess(() -> Component.literal("[Fling Pad] Registered launch pads (" + pads.size() + "):").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD), false);
        for (FlingPadManager.FlingPad pad : pads) {
            source.sendSuccess(() -> Component.literal(String.format(Locale.ROOT, " • [%s] (%d, %d, %d) -> (%.2f, %.2f, %.2f)",
                pad.dimension(), pad.x(), pad.y(), pad.z(), pad.vx(), pad.vy(), pad.vz())).withStyle(ChatFormatting.YELLOW), false);
        }
        return pads.size();
    }

    private static int clearPads(CommandSourceStack source) {
        int count = FlingPadManager.getPads().size();
        FlingPadManager.clearPads();
        source.sendSuccess(() -> Component.literal("[Fling Pad] Cleared all " + count + " launch pads.").withStyle(ChatFormatting.GREEN), false);
        return count;
    }

    private static int sendHelp(CommandSourceStack source) {
        Component help = Component.literal("\n=== /fling Command Guide (1.21.11 Fabric) ===\n").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("• /fling <player> thisway [power]\n").withStyle(ChatFormatting.YELLOW))
            .append(Component.literal("   Flings player in your look direction and gives click-to-copy chat buttons!\n").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("• /fling <player> <x> <y> <z>\n").withStyle(ChatFormatting.YELLOW))
            .append(Component.literal("   Flings player with exact 3D velocity vector (e.g. 0 2 0 or 1.5 1 -2).\n").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("• /fling <player> <up|down|north|south|east|west|forward|backward|look> [power]\n").withStyle(ChatFormatting.YELLOW))
            .append(Component.literal("   Flings player in a cardinal or relative direction.\n").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("• /fling at <x y z> <vx vy vz> (Command Blocks)\n").withStyle(ChatFormatting.AQUA))
            .append(Component.literal("   Detects when someone walks over block (x,y,z) and flings them!\n").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("• /fling pad add <x y z> <vx vy vz> | thisway | <dir>\n").withStyle(ChatFormatting.GREEN))
            .append(Component.literal("   Registers a permanent walk-over launch pad at coordinates.\n").withStyle(ChatFormatting.GRAY))
            .append(Component.literal("• /fling pad list | remove <pos> | clear\n").withStyle(ChatFormatting.GREEN))
            .append(Component.literal("   Manages saved launch pads.\n").withStyle(ChatFormatting.GRAY));

        source.sendSuccess(() -> help, false);
        return 1;
    }
}
