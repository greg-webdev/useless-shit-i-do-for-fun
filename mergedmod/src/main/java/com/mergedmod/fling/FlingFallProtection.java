package com.mergedmod.fling;

import net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.damagesource.DamageTypes;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class FlingFallProtection {
    private static final Map<UUID, Long> immunityMap = new ConcurrentHashMap<>();
    private static long currentServerTick = 0;

    public static void init() {
        ServerLivingEntityEvents.ALLOW_DAMAGE.register((entity, source, amount) -> {
            if (entity instanceof ServerPlayer player) {
                if (source.is(DamageTypes.FALL)) {
                    Long expireTick = immunityMap.get(player.getUUID());
                    if (expireTick != null && currentServerTick <= expireTick) {
                        immunityMap.remove(player.getUUID());
                        return false;
                    }
                }
            }
            return true;
        });
    }

    public static void tick() {
        currentServerTick++;
        if (currentServerTick % 100 == 0) {
            immunityMap.entrySet().removeIf(entry -> entry.getValue() < currentServerTick);
        }
    }

    public static void addImmunity(UUID uuid, long durationTicks) {
        immunityMap.put(uuid, currentServerTick + durationTicks);
    }
}
