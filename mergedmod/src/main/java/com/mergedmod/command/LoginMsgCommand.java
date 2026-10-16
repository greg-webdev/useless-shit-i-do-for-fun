package com.mergedmod.command;

import com.mergedmod.PermissionHelper;
import com.mergedmod.login.LoginMsgManager;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.StringArgumentType;
import net.minecraft.ChatFormatting;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.Component;

public class LoginMsgCommand {
    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        dispatcher.register(
            Commands.literal("loginmsg")
                .requires(PermissionHelper::isGeg)
                .then(Commands.literal("clear")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        LoginMsgManager.clearMessage();
                        ctx.getSource().sendSuccess(() -> Component.literal("[LoginMsg] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                            .append(Component.literal("Cleared server login message.").withStyle(ChatFormatting.YELLOW)), false);
                        return 1;
                    })
                )
                .then(Commands.literal("show")
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        String current = LoginMsgManager.getMessage();
                        if (current == null || current.isBlank()) {
                            ctx.getSource().sendSuccess(() -> Component.literal("[LoginMsg] No login message is currently set.").withStyle(ChatFormatting.GRAY), false);
                        } else {
                            ctx.getSource().sendSuccess(() -> Component.literal("[LoginMsg] Current login message:\n").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                                .append(Component.literal(LoginMsgManager.formatColors(current))), false);
                        }
                        return 1;
                    })
                )
                .then(Commands.argument("msg", StringArgumentType.greedyString())
                    .executes(ctx -> {
                        if (!PermissionHelper.checkGeg(ctx.getSource())) return 0;
                        String msg = StringArgumentType.getString(ctx, "msg");
                        LoginMsgManager.setMessage(msg);
                        ctx.getSource().sendSuccess(() -> Component.literal("[LoginMsg] ").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD)
                            .append(Component.literal("Login message updated!\nPreview: ").withStyle(ChatFormatting.GREEN))
                            .append(Component.literal(LoginMsgManager.formatColors(msg))), false);
                        return 1;
                    })
                )
        );
    }
}
