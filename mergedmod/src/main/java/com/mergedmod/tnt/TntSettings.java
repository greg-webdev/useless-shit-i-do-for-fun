package com.mergedmod.tnt;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.item.PrimedTnt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Reader;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;

public class TntSettings {
    private static final Logger LOGGER = LoggerFactory.getLogger("tnt-control");
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static boolean tntEnabled = true;

    public static void init() {
        load();
    }

    public static boolean isTntEnabled() {
        return tntEnabled;
    }

    public static void setTntEnabled(boolean enabled) {
        tntEnabled = enabled;
        save();
    }

    public static void tick(MinecraftServer server) {
        if (tntEnabled) {
            return;
        }

        // Active guardian: if TNT explosions are disabled, extinguish any primed TNT about to detonate
        for (ServerLevel level : server.getAllLevels()) {
            for (Entity entity : level.getAllEntities()) {
                if (entity instanceof PrimedTnt tnt) {
                    if (tnt.getFuse() <= 2) {
                        tnt.discard();
                        level.sendParticles(ParticleTypes.LARGE_SMOKE, tnt.getX(), tnt.getY() + 0.5, tnt.getZ(), 10, 0.2, 0.2, 0.2, 0.05);
                        level.playSound(null, tnt.getX(), tnt.getY(), tnt.getZ(), SoundEvents.FIRE_EXTINGUISH, SoundSource.BLOCKS, 1.0f, 1.0f);
                    }
                }
            }
        }
    }

    public static void load() {
        try {
            Path file = FabricLoader.getInstance().getConfigDir().resolve("tnt_settings.json");
            if (Files.exists(file)) {
                try (Reader reader = Files.newBufferedReader(file)) {
                    JsonObject obj = GSON.fromJson(reader, JsonObject.class);
                    if (obj != null && obj.has("tntEnabled")) {
                        tntEnabled = obj.get("tntEnabled").getAsBoolean();
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Failed to load tnt settings", e);
        }
    }

    public static void save() {
        try {
            Path dir = FabricLoader.getInstance().getConfigDir();
            Files.createDirectories(dir);
            Path file = dir.resolve("tnt_settings.json");
            JsonObject obj = new JsonObject();
            obj.addProperty("tntEnabled", tntEnabled);
            try (Writer writer = Files.newBufferedWriter(file)) {
                GSON.toJson(obj, writer);
            }
        } catch (Exception e) {
            LOGGER.error("Failed to save tnt settings", e);
        }
    }
}
