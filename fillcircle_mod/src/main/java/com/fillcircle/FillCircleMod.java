package com.fillcircle;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FillCircleMod implements ModInitializer {
    public static final String MOD_ID = "fillcircle";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        LOGGER.info("FillCircle mod initialized for Minecraft 1.21.11 Fabric");
        CommandRegistrationCallback.EVENT.register(FillCircleCommand::register);
    }
}
