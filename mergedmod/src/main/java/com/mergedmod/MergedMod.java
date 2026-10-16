package com.mergedmod;

import com.mergedmod.command.*;
import com.mergedmod.fling.FlingFallProtection;
import com.mergedmod.fling.FlingPadManager;
import com.mergedmod.login.LoginMsgManager;
import com.mergedmod.tnt.TntSettings;
import com.mergedmod.performance.PerformanceEngine;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MergedMod implements ModInitializer {
    public static final String MOD_ID = "mergedmod";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        LOGGER.info("MergedMod initialized for Minecraft 1.21.11 Fabric Server");

        // 1. Register all commands
        CommandRegistrationCallback.EVENT.register((dispatcher, buildContext, environment) -> {
            FillCircleCommand.register(dispatcher, buildContext, environment);
            FlingCommand.register(dispatcher, buildContext, environment);
            LoginMsgCommand.register(dispatcher, buildContext, environment);
            TntCommand.register(dispatcher, buildContext, environment);
            BackupCommand.register(dispatcher, buildContext, environment);
            PerformanceCommands.register(dispatcher, buildContext, environment);
        });

        // 2. Initialize feature modules
        FlingFallProtection.init();
        LoginMsgManager.init();
        TntSettings.init();
        PerformanceEngine.init();

        // 3. Server tick events
        ServerTickEvents.START_SERVER_TICK.register(PerformanceEngine::onServerTickStart);

        ServerTickEvents.END_SERVER_TICK.register(server -> {
            FlingFallProtection.tick();
            FlingPadManager.tick(server);
            TntSettings.tick(server);
            PerformanceEngine.onServerTickEnd(server);
        });

        // 4. Server lifecycle events
        ServerLifecycleEvents.SERVER_STARTED.register(server -> {
            FlingPadManager.load(server);
            LoginMsgManager.load();
            TntSettings.load();
        });

        ServerLifecycleEvents.SERVER_STOPPING.register(server -> {
            FlingPadManager.save();
            LoginMsgManager.save();
            TntSettings.save();
            if (PerformanceEngine.getConfig() != null) {
                PerformanceEngine.getConfig().save();
            }
            if (PerformanceEngine.getWorkerPool() != null) {
                PerformanceEngine.getWorkerPool().shutdown();
            }
        });
    }
}
