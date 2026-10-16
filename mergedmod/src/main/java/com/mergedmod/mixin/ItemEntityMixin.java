package com.mergedmod.mixin;

import com.mergedmod.performance.PerformanceEngine;
import net.minecraft.world.entity.item.ItemEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ItemEntity.class)
public abstract class ItemEntityMixin {
    @Inject(method = "mergeWithNeighbours", at = @At("HEAD"), cancellable = true)
    private void throttleItemMerge(CallbackInfo ci) {
        ItemEntity item = (ItemEntity) (Object) this;
        if (PerformanceEngine.shouldSkipItemMerge(item)) {
            ci.cancel();
        }
    }
}
