package com.mergedmod.mixin;

import com.mergedmod.tnt.TntSettings;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.vehicle.minecart.MinecartTNT;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(MinecartTNT.class)
public class MinecartTntMixin {
    @Inject(method = "explode(Lnet/minecraft/world/damagesource/DamageSource;D)V", at = @At("HEAD"), cancellable = true)
    private void cancelExplode(DamageSource damageSource, double radius, CallbackInfo ci) {
        if (!TntSettings.isTntEnabled()) {
            ci.cancel();
        }
    }
}
