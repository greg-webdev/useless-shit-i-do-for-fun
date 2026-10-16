package com.mergedmod.fling;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.core.BlockPos;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.phys.Vec3;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Reader;
import java.io.Writer;
import java.lang.reflect.Type;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class FlingPadManager {
    private static final Logger LOGGER = LoggerFactory.getLogger("fling-pads");
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final Map<String, FlingPad> pads = new ConcurrentHashMap<>();
    private static final Map<UUID, Long> playerCooldowns = new ConcurrentHashMap<>();
    private static long currentTick = 0;

    public record FlingPad(String dimension, int x, int y, int z, double vx, double vy, double vz) {
        public BlockPos pos() {
            return new BlockPos(x, y, z);
        }

        public Vec3 velocity() {
            return new Vec3(vx, vy, vz);
        }
    }

    public static String makeKey(String dimension, int x, int y, int z) {
        return dimension + ":" + x + "," + y + "," + z;
    }

    public static String makeKey(String dimension, BlockPos pos) {
        return makeKey(dimension, pos.getX(), pos.getY(), pos.getZ());
    }

    public static boolean checkAndSetCooldown(UUID uuid, long cooldownTicks) {
        Long nextAllowed = playerCooldowns.get(uuid);
        if (nextAllowed != null && currentTick < nextAllowed) {
            return false;
        }
        playerCooldowns.put(uuid, currentTick + cooldownTicks);
        return true;
    }

    public static void addPad(String dimension, BlockPos pos, Vec3 velocity) {
        String key = makeKey(dimension, pos);
        pads.put(key, new FlingPad(dimension, pos.getX(), pos.getY(), pos.getZ(), velocity.x, velocity.y, velocity.z));
        save();
    }

    public static boolean removePad(String dimension, BlockPos pos) {
        String key = makeKey(dimension, pos);
        boolean removed = pads.remove(key) != null;
        if (removed) {
            save();
        }
        return removed;
    }

    public static void clearPads() {
        pads.clear();
        save();
    }

    public static Collection<FlingPad> getPads() {
        return Collections.unmodifiableCollection(pads.values());
    }

    public static void tick(MinecraftServer server) {
        currentTick++;
        if (currentTick % 200 == 0) {
            playerCooldowns.entrySet().removeIf(e -> e.getValue() < currentTick);
        }

        if (pads.isEmpty()) {
            return;
        }

        for (ServerLevel level : server.getAllLevels()) {
            String dim = level.dimension().identifier().toString();
            for (ServerPlayer player : level.players()) {
                if (player.isSpectator()) {
                    continue;
                }

                BlockPos pPos = player.blockPosition();
                BlockPos onPos = player.getOnPos();
                BlockPos feetPos = BlockPos.containing(player.getX(), player.getY() - 0.2, player.getZ());

                FlingPad pad = pads.get(makeKey(dim, pPos));
                if (pad == null) pad = pads.get(makeKey(dim, onPos));
                if (pad == null) pad = pads.get(makeKey(dim, feetPos));

                if (pad != null) {
                    if (checkAndSetCooldown(player.getUUID(), 12)) {
                        FlingHelper.fling(player, pad.velocity(), true);
                    }
                }
            }
        }
    }

    public static void load(MinecraftServer server) {
        try {
            Path file = FabricLoader.getInstance().getConfigDir().resolve("fling_pads.json");
            if (Files.exists(file)) {
                try (Reader reader = Files.newBufferedReader(file)) {
                    Type type = new TypeToken<List<FlingPad>>() {}.getType();
                    List<FlingPad> list = GSON.fromJson(reader, type);
                    pads.clear();
                    if (list != null) {
                        for (FlingPad pad : list) {
                            pads.put(makeKey(pad.dimension(), pad.x(), pad.y(), pad.z()), pad);
                        }
                    }
                    LOGGER.info("Loaded {} fling pads from config/fling_pads.json", pads.size());
                }
            }
        } catch (Exception e) {
            LOGGER.error("Failed to load fling pads", e);
        }
    }

    public static void save() {
        try {
            Path dir = FabricLoader.getInstance().getConfigDir();
            Files.createDirectories(dir);
            Path file = dir.resolve("fling_pads.json");
            try (Writer writer = Files.newBufferedWriter(file)) {
                GSON.toJson(new ArrayList<>(pads.values()), writer);
            }
        } catch (Exception e) {
            LOGGER.error("Failed to save fling pads", e);
        }
    }
}
