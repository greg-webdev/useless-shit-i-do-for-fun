package com.mergedmod.mixin;

import com.mergedmod.performance.PerformanceEngine;
import net.minecraft.world.entity.Mob;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Mob.class)
public abstract class MobAiMixin {
    @Inject(method = "serverAiStep", at = @At("HEAD"), cancellable = true)
    private void throttleAiStep(CallbackInfo ci) {
        Mob mob = (Mob) (Object) this;
        if (PerformanceEngine.shouldSkipAiStep(mob)) {
            ci.cancel();
        }
    }
}
