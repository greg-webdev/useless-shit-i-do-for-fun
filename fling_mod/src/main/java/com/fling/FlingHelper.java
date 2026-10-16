package com.fling;

import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.network.protocol.game.ClientboundSetEntityMotionPacket;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec3;

/**
 * Handles server-side velocity impulses, client packet synchronization,
 * fall distance resetting, and atmospheric audio-visual feedback.
 */
public class FlingHelper {
    public static void fling(Entity entity, Vec3 velocity, boolean playEffects) {
        // Reset fall distance on server
        entity.resetFallDistance();

        // Apply server velocity & mark entity motion updated
        entity.setDeltaMovement(velocity);
        entity.hurtMarked = true;

        // Synchronize with client movement prediction
        if (entity instanceof ServerPlayer player) {
            player.connection.send(new ClientboundSetEntityMotionPacket(player.getId(), velocity));
            FlingFallProtection.addImmunity(player.getUUID(), 100); // 5s protection
        }

        // Support ridden vehicles (e.g. horses, boats, minecarts)
        Entity rootVehicle = entity.getRootVehicle();
        if (rootVehicle != entity) {
            rootVehicle.resetFallDistance();
            rootVehicle.setDeltaMovement(velocity);
            rootVehicle.hurtMarked = true;
            if (rootVehicle instanceof ServerPlayer vPlayer) {
                vPlayer.connection.send(new ClientboundSetEntityMotionPacket(vPlayer.getId(), velocity));
            }
        }

        // Particle and sound effects
        if (playEffects && entity.level() instanceof ServerLevel serverLevel) {
            Vec3 pos = entity.position();
            serverLevel.sendParticles(
                ParticleTypes.GUST,
                pos.x, pos.y + 0.5, pos.z,
                4, 0.2, 0.2, 0.2, 0.05
            );
            serverLevel.sendParticles(
                ParticleTypes.CLOUD,
                pos.x, pos.y + 0.1, pos.z,
                6, 0.2, 0.1, 0.2, 0.02
            );
            serverLevel.playSound(
                null,
                pos.x, pos.y, pos.z,
                SoundEvents.WIND_CHARGE_BURST.value(),
                SoundSource.PLAYERS,
                1.0f,
                1.0f
            );
        }
    }
}
