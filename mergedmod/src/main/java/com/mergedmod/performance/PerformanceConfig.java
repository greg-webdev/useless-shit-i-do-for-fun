package com.mergedmod.performance;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.mergedmod.MergedMod;
import net.fabricmc.loader.api.FabricLoader;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;

public class PerformanceConfig {
    public enum Mode {
        BALANCED("Balanced", "Standard safe optimizations with multi-core assistance"),
        TURBO("Turbo", "High-performance multi-threading, collision capping & AI throttling"),
        ULTRA("Ultra", "Aggressive multi-core ticking, dynamic view/sim distance & RAM caching"),
        EXTREME("Extreme", "Maximum lag salvation mode for heavy servers & huge mob farms");

        private final String name;
        private final String description;

        Mode(String name, String description) {
            this.name = name;
            this.description = description;
        }

        public String getName() {
            return name;
        }

        public String getDescription() {
            return description;
        }
    }

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final File CONFIG_FILE = new File(FabricLoader.getInstance().getConfigDir().toFile(), "mergedmod_performance.json");

    // Config fields
    private Mode mode = Mode.TURBO;
    private int maxCollisionsPerTick = 8;
    private boolean aiThrottleEnabled = true;
    private double aiThrottleDistance = 32.0;
    private int aiThrottleInterval = 4;
    private boolean itemMergeThrottleEnabled = true;
    private int itemMergeInterval = 10;
    private boolean dynamicSimulationDistance = true;
    private int minSimulationDistance = 4;
    private int maxSimulationDistance = 10;
    private double targetMspt = 40.0;
    private boolean autoMemoryPurgeEnabled = true;
    private double emergencyTpsThreshold = 14.0;
    private int workerThreads = Math.max(2, Runtime.getRuntime().availableProcessors());

    public static PerformanceConfig load() {
        if (CONFIG_FILE.exists()) {
            try (FileReader reader = new FileReader(CONFIG_FILE)) {
                PerformanceConfig config = GSON.fromJson(reader, PerformanceConfig.class);
                if (config != null) {
                    config.validate();
                    return config;
                }
            } catch (Exception e) {
                MergedMod.LOGGER.error("Failed to load performance config, using defaults", e);
            }
        }
        PerformanceConfig config = new PerformanceConfig();
        config.save();
        return config;
    }

    public void save() {
        try {
            File parent = CONFIG_FILE.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            try (FileWriter writer = new FileWriter(CONFIG_FILE)) {
                GSON.toJson(this, writer);
            }
        } catch (Exception e) {
            MergedMod.LOGGER.error("Failed to save performance config", e);
        }
    }

    public void validate() {
        if (mode == null) mode = Mode.TURBO;
        if (maxCollisionsPerTick < 1) maxCollisionsPerTick = 8;
        if (aiThrottleDistance < 8.0) aiThrottleDistance = 32.0;
        if (aiThrottleInterval < 2) aiThrottleInterval = 4;
        if (itemMergeInterval < 2) itemMergeInterval = 10;
        if (minSimulationDistance < 2) minSimulationDistance = 4;
        if (maxSimulationDistance < minSimulationDistance) maxSimulationDistance = minSimulationDistance + 4;
        if (targetMspt < 10.0 || targetMspt > 50.0) targetMspt = 40.0;
        if (workerThreads < 1) workerThreads = Math.max(2, Runtime.getRuntime().availableProcessors());
    }

    public void setMode(Mode mode) {
        this.mode = mode;
        switch (mode) {
            case BALANCED -> {
                this.maxCollisionsPerTick = 16;
                this.aiThrottleEnabled = true;
                this.aiThrottleDistance = 48.0;
                this.aiThrottleInterval = 2;
                this.itemMergeInterval = 5;
                this.dynamicSimulationDistance = false;
            }
            case TURBO -> {
                this.maxCollisionsPerTick = 8;
                this.aiThrottleEnabled = true;
                this.aiThrottleDistance = 32.0;
                this.aiThrottleInterval = 4;
                this.itemMergeInterval = 10;
                this.dynamicSimulationDistance = true;
            }
            case ULTRA -> {
                this.maxCollisionsPerTick = 4;
                this.aiThrottleEnabled = true;
                this.aiThrottleDistance = 24.0;
                this.aiThrottleInterval = 6;
                this.itemMergeInterval = 15;
                this.dynamicSimulationDistance = true;
            }
            case EXTREME -> {
                this.maxCollisionsPerTick = 2;
                this.aiThrottleEnabled = true;
                this.aiThrottleDistance = 16.0;
                this.aiThrottleInterval = 8;
                this.itemMergeInterval = 20;
                this.dynamicSimulationDistance = true;
            }
        }
        save();
    }

    // Getters and setters
    public Mode getMode() { return mode; }
    public int getMaxCollisionsPerTick() { return maxCollisionsPerTick; }
    public void setMaxCollisionsPerTick(int val) { this.maxCollisionsPerTick = val; save(); }
    public boolean isAiThrottleEnabled() { return aiThrottleEnabled; }
    public void setAiThrottleEnabled(boolean val) { this.aiThrottleEnabled = val; save(); }
    public double getAiThrottleDistance() { return aiThrottleDistance; }
    public void setAiThrottleDistance(double val) { this.aiThrottleDistance = val; save(); }
    public int getAiThrottleInterval() { return aiThrottleInterval; }
    public void setAiThrottleInterval(int val) { this.aiThrottleInterval = val; save(); }
    public boolean isItemMergeThrottleEnabled() { return itemMergeThrottleEnabled; }
    public void setItemMergeThrottleEnabled(boolean val) { this.itemMergeThrottleEnabled = val; save(); }
    public int getItemMergeInterval() { return itemMergeInterval; }
    public void setItemMergeInterval(int val) { this.itemMergeInterval = val; save(); }
    public boolean isDynamicSimulationDistance() { return dynamicSimulationDistance; }
    public void setDynamicSimulationDistance(boolean val) { this.dynamicSimulationDistance = val; save(); }
    public int getMinSimulationDistance() { return minSimulationDistance; }
    public void setMinSimulationDistance(int val) { this.minSimulationDistance = val; save(); }
    public int getMaxSimulationDistance() { return maxSimulationDistance; }
    public void setMaxSimulationDistance(int val) { this.maxSimulationDistance = val; save(); }
    public double getTargetMspt() { return targetMspt; }
    public void setTargetMspt(double val) { this.targetMspt = val; save(); }
    public boolean isAutoMemoryPurgeEnabled() { return autoMemoryPurgeEnabled; }
    public void setAutoMemoryPurgeEnabled(boolean val) { this.autoMemoryPurgeEnabled = val; save(); }
    public double getEmergencyTpsThreshold() { return emergencyTpsThreshold; }
    public void setEmergencyTpsThreshold(double val) { this.emergencyTpsThreshold = val; save(); }
    public int getWorkerThreads() { return workerThreads; }
}
