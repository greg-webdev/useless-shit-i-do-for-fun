package com.mergedmod.command;

import com.mergedmod.PermissionHelper;
import com.mergedmod.tnt.TntMenu;
import com.mergedmod.tnt.TntMenuHelper;
import com.mergedmod.tnt.TntSettings;
import com.mojang.brigadier.CommandDispatcher;
import net.minecraft.ChatFormatting;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.SimpleMenuProvider;

public class TntCommand {
    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        dispatcher.register(
            Commands.literal("tnt")
                .requires(PermissionHelper::isGeg)
                .executes(ctx -> {
                    CommandSourceStack source = ctx.getSource();
                    if (!PermissionHelper.checkGeg(source)) return 0;

                    if (source.getEntity() instanceof ServerPlayer player) {
                        // Open interactive Server GUI
                        MenuProvider provider = new SimpleMenuProvider(
                            (syncId, inv, p) -> new TntMenu(syncId, inv, TntMenuHelper.createContainer()),
                            Component.literal("§4§lTNT Explosions Control")
                        );
                        player.openMenu(provider);
                        return 1;
                    }

                    // Console fallback
                    boolean current = TntSettings.isTntEnabled();
                    source.sendSuccess(() -> Component.literal("[TNT Control] TNT Explosions are currently: " + (current ? "ENABLED" : "DISABLED")), false);
                    return 1;
                })
                .then(Commands.literal("toggle")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        boolean newState = !TntSettings.isTntEnabled();
                        TntSettings.setTntEnabled(newState);
                        ctx.getSource().sendSuccess(() -> Component.literal("[TNT Control] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                            .append(Component.literal("TNT explosions are now: " + (newState ? "§cENABLED" : "§aDISABLED"))), false);
                        return 1;
                    })
                )
                .then(Commands.literal("enable")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        TntSettings.setTntEnabled(true);
                        ctx.getSource().sendSuccess(() -> Component.literal("[TNT Control] TNT explosions are now §cENABLED").withStyle(ChatFormatting.GOLD), false);
                        return 1;
                    })
                )
                .then(Commands.literal("disable")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        TntSettings.setTntEnabled(false);
                        ctx.getSource().sendSuccess(() -> Component.literal("[TNT Control] TNT explosions are now §aDISABLED").withStyle(ChatFormatting.GOLD), false);
                        return 1;
                    })
                )
                .then(Commands.literal("status")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        boolean current = TntSettings.isTntEnabled();
                        ctx.getSource().sendSuccess(() -> Component.literal("[TNT Control] TNT explosions are currently: " + (current ? "§cENABLED" : "§aDISABLED")), false);
                        return 1;
                    })
                )
        );
    }
}
