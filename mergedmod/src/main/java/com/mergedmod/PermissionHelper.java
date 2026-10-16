package com.mergedmod;

import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;

public class PermissionHelper {
    public static final String GEG_USERNAME = "geg";

    public static boolean isGeg(CommandSourceStack source) {
        if (source.getEntity() instanceof ServerPlayer player) {
            return player.getScoreboardName().equalsIgnoreCase(GEG_USERNAME);
        }
        // Console / RCON / Command Blocks with owner permission
        return Commands.hasPermission(Commands.LEVEL_OWNERS).test(source);
    }

    public static boolean checkGeg(CommandSourceStack source) {
        if (!isGeg(source)) {
            source.sendFailure(Component.literal("§cOnly geg has permission to execute this command!"));
            return false;
        }
        return true;
    }
}
