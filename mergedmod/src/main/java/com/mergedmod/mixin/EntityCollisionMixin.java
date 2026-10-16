package com.mergedmod.mixin;

import com.mergedmod.performance.PerformanceEngine;
import net.minecraft.world.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.Unique;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Entity.class)
public abstract class EntityCollisionMixin {
    @Shadow public int tickCount;

    @Unique private int mergedmod$collisionCount = 0;
    @Unique private int mergedmod$lastCollisionTick = -1;

    @Inject(method = "push(Lnet/minecraft/world/entity/Entity;)V", at = @At("HEAD"), cancellable = true)
    private void limitCollisions(Entity other, CallbackInfo ci) {
        if (this.tickCount != this.mergedmod$lastCollisionTick) {
            this.mergedmod$collisionCount = 0;
            this.mergedmod$lastCollisionTick = this.tickCount;
        }

        int maxCollisions = (PerformanceEngine.getConfig() != null)
                ? PerformanceEngine.getConfig().getMaxCollisionsPerTick()
                : 8;

        if (this.mergedmod$collisionCount >= maxCollisions) {
            ci.cancel();
            return;
        }

        this.mergedmod$collisionCount++;
    }
}
