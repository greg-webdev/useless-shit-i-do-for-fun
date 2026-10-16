package com.mergedmod.command;

import com.mergedmod.PermissionHelper;
import com.mergedmod.backup.BackupManager;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.StringArgumentType;
import net.minecraft.ChatFormatting;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.ClickEvent;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.HoverEvent;
import net.minecraft.server.MinecraftServer;

import java.util.List;

public class BackupCommand {
    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        // /backupworld [tag]
        dispatcher.register(
            Commands.literal("backupworld")
                .requires(PermissionHelper::isGeg)
                .executes(ctx -> runBackup(ctx.getSource(), null))
                .then(Commands.argument("tag", StringArgumentType.string())
                    .executes(ctx -> runBackup(ctx.getSource(), StringArgumentType.getString(ctx, "tag")))
                )
        );

        // /backups [list | restore [target] | delete <target>]
        dispatcher.register(
            Commands.literal("backups")
                .requires(PermissionHelper::isGeg)
                .executes(ctx -> showBackups(ctx.getSource()))
                .then(Commands.literal("list")
                    .executes(ctx -> showBackups(ctx.getSource()))
                )
                .then(Commands.literal("restore")
                    .executes(ctx -> runRestore(ctx.getSource(), "latest"))
                    .then(Commands.argument("file", StringArgumentType.greedyString())
                        .executes(ctx -> runRestore(ctx.getSource(), StringArgumentType.getString(ctx, "file")))
                    )
                )
                .then(Commands.literal("delete")
                    .then(Commands.argument("file", StringArgumentType.greedyString())
                        .executes(ctx -> {
                            if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                            String file = StringArgumentType.getString(ctx, "file");
                            boolean deleted = BackupManager.deleteBackup(ctx.getSource().getServer(), file);
                            if (deleted) {
                                ctx.getSource().sendSuccess(() -> Component.literal("[Backup] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                                    .append(Component.literal("Deleted backup: " + file).withStyle(ChatFormatting.GREEN)), false);
                                return 1;
                            } else {
                                ctx.getSource().sendFailure(Component.literal("Could not find or delete backup: " + file));
                                return 0;
                            }
                        })
                    )
                )
        );
    }

    private static int runBackup(CommandSourceStack source, String tag) {
        if (!PermissionHelper.checkGeg(source)) return 0;

        if (BackupManager.isBackupRunning()) {
            source.sendFailure(Component.literal("[Backup] A backup is already running in background. Please wait for it to finish!"));
            return 0;
        }

        source.sendSuccess(() -> Component.literal("[Backup] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("Starting zero-lag server backup in background...").withStyle(ChatFormatting.YELLOW)), false);

        MinecraftServer server = source.getServer();
        BackupManager.createBackup(
            server,
            tag,
            successMsg -> source.sendSuccess(() -> Component.literal("[Backup] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                .append(Component.literal("✔ " + successMsg).withStyle(ChatFormatting.GREEN, ChatFormatting.BOLD)), true),
            errorMsg -> source.sendFailure(Component.literal("[Backup Error] " + errorMsg))
        );

        return 1;
    }

    private static int showBackups(CommandSourceStack source) {
        if (!PermissionHelper.checkGeg(source)) return 0;

        MinecraftServer server = source.getServer();
        List<BackupManager.BackupFile> list = BackupManager.listBackups(server);

        if (list.isEmpty()) {
            source.sendSuccess(() -> Component.literal("[Backups] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                .append(Component.literal("No server backups found. Run /backupworld to create one!").withStyle(ChatFormatting.GRAY)), false);
            return 0;
        }

        source.sendSuccess(() -> Component.literal("\n=== Server Backups (" + list.size() + ") ===\n").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD), false);

        for (BackupManager.BackupFile bf : list) {
            String restoreCmd = "/backups restore " + bf.name();
            String deleteCmd = "/backups delete " + bf.name();

            Component entry = Component.literal("• ").withStyle(ChatFormatting.DARK_GRAY)
                .append(Component.literal(bf.name()).withStyle(ChatFormatting.WHITE, ChatFormatting.BOLD))
                .append(Component.literal(" (" + bf.formatSize() + " | " + bf.formatDate() + ") ").withStyle(ChatFormatting.GRAY))
                .append(Component.literal("[⚡ Restore]").withStyle(style -> style
                    .withColor(ChatFormatting.RED)
                    .withBold(true)
                    .withClickEvent(new ClickEvent.RunCommand(restoreCmd))
                    .withHoverEvent(new HoverEvent.ShowText(Component.literal("Click to restore: " + bf.name() + "\n§cWARNING: Kicks all players!")))
                ))
                .append(Component.literal(" "))
                .append(Component.literal("[✖]").withStyle(style -> style
                    .withColor(ChatFormatting.DARK_RED)
                    .withClickEvent(new ClickEvent.SuggestCommand(deleteCmd))
                    .withHoverEvent(new HoverEvent.ShowText(Component.literal("Click to delete " + bf.name())))
                ));

            source.sendSuccess(() -> entry, false);
        }

        source.sendSuccess(() -> Component.literal("\n§7Tip: Click §c[⚡ Restore] §7to kick all players and restore that exact server state."), false);
        return list.size();
    }

    private static int runRestore(CommandSourceStack source, String target) {
        if (!PermissionHelper.checkGeg(source)) return 0;

        MinecraftServer server = source.getServer();
        source.sendSuccess(() -> Component.literal("[Backup] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
            .append(Component.literal("Initiating server restore of: " + target + "...").withStyle(ChatFormatting.RED)), true);

        BackupManager.restoreBackup(
            server,
            target,
            info -> source.sendSuccess(() -> Component.literal("[Backup] " + info).withStyle(ChatFormatting.YELLOW), true),
            error -> source.sendFailure(Component.literal("[Restore Error] " + error))
        );

        return 1;
    }
}
