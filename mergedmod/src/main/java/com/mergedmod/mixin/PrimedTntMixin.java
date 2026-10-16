package com.mergedmod.mixin;

import com.mergedmod.tnt.TntSettings;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.item.PrimedTnt;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(PrimedTnt.class)
public class PrimedTntMixin {
    @Inject(method = "explode", at = @At("HEAD"), cancellable = true)
    private void cancelExplode(CallbackInfo ci) {
        if (!TntSettings.isTntEnabled()) {
            ci.cancel();
            PrimedTnt tnt = (PrimedTnt) (Object) this;
            if (tnt.level() instanceof ServerLevel serverLevel) {
                serverLevel.sendParticles(ParticleTypes.LARGE_SMOKE, tnt.getX(), tnt.getY() + 0.5, tnt.getZ(), 10, 0.2, 0.2, 0.2, 0.05);
                serverLevel.playSound(null, tnt.getX(), tnt.getY(), tnt.getZ(), SoundEvents.FIRE_EXTINGUISH, SoundSource.BLOCKS, 1.0f, 1.0f);
            }
        }
    }
}
