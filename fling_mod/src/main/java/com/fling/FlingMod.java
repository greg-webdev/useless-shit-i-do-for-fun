package com.fling;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FlingMod implements ModInitializer {
    public static final String MOD_ID = "fling";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        LOGGER.info("Fling mod initialized for Minecraft 1.21.11 Fabric");

        // Register /fling command
        CommandRegistrationCallback.EVENT.register(FlingCommand::register);

        // Initialize fall damage protection
        FlingFallProtection.init();

        // Server tick events: check walk-over fling pads and tick protection
        ServerTickEvents.END_SERVER_TICK.register(server -> {
            FlingFallProtection.tick();
            FlingPadManager.tick(server);
        });

        // Lifecycle events for persisting fling pads
        ServerLifecycleEvents.SERVER_STARTED.register(FlingPadManager::load);
        ServerLifecycleEvents.SERVER_STOPPING.register(server -> FlingPadManager.save());
    }
}
