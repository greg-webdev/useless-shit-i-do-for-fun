package com.mergedmod.login;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import net.fabricmc.fabric.api.entity.event.v1.ServerPlayerEvents;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Reader;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;

public class LoginMsgManager {
    private static final Logger LOGGER = LoggerFactory.getLogger("login-msg");
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static String loginMessage = null;

    public static void init() {
        // Broadcast custom login message when any player connects to the server
        ServerPlayerEvents.JOIN.register((ServerPlayer player) -> {
            sendLoginMessage(player);
        });
    }

    public static void sendLoginMessage(ServerPlayer player) {
        if (loginMessage != null && !loginMessage.isBlank()) {
            player.sendSystemMessage(Component.literal(formatColors(loginMessage)));
        }
    }

    public static String formatColors(String text) {
        if (text == null) return "";
        return text.replace('&', '§');
    }

    public static void setMessage(String msg) {
        loginMessage = msg;
        save();
    }

    public static String getMessage() {
        return loginMessage;
    }

    public static void clearMessage() {
        loginMessage = null;
        save();
    }

    public static void load() {
        try {
            Path file = FabricLoader.getInstance().getConfigDir().resolve("login_message.json");
            if (Files.exists(file)) {
                try (Reader reader = Files.newBufferedReader(file)) {
                    JsonObject obj = GSON.fromJson(reader, JsonObject.class);
                    if (obj != null && obj.has("message")) {
                        loginMessage = obj.get("message").getAsString();
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Failed to load login message", e);
        }
    }

    public static void save() {
        try {
            Path dir = FabricLoader.getInstance().getConfigDir();
            Files.createDirectories(dir);
            Path file = dir.resolve("login_message.json");
            JsonObject obj = new JsonObject();
            if (loginMessage != null) {
                obj.addProperty("message", loginMessage);
            }
            try (Writer writer = Files.newBufferedWriter(file)) {
                GSON.toJson(obj, writer);
            }
        } catch (Exception e) {
            LOGGER.error("Failed to save login message", e);
        }
    }
}
