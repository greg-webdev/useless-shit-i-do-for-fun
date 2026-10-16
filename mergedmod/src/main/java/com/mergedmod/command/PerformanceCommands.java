package com.mergedmod.command;

import com.mergedmod.PermissionHelper;
import com.mergedmod.performance.GpuAccelerator;
import com.mergedmod.performance.PerformanceConfig;
import com.mergedmod.performance.PerformanceEngine;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.DoubleArgumentType;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.network.chat.ClickEvent;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.HoverEvent;
import net.minecraft.network.chat.MutableComponent;
import net.minecraft.server.MinecraftServer;

import java.io.File;
import java.io.FileWriter;
import java.util.List;

public class PerformanceCommands {

    public static void register(CommandDispatcher<CommandSourceStack> dispatcher, CommandBuildContext buildContext, Commands.CommandSelection environment) {
        var lagCmd = Commands.literal("lag")
                .executes(ctx -> showStatus(ctx.getSource()))
                .then(Commands.literal("status").executes(ctx -> showStatus(ctx.getSource())))
                .then(Commands.literal("mode")
                        .then(Commands.literal("balanced").executes(ctx -> setMode(ctx.getSource(), PerformanceConfig.Mode.BALANCED)))
                        .then(Commands.literal("turbo").executes(ctx -> setMode(ctx.getSource(), PerformanceConfig.Mode.TURBO)))
                        .then(Commands.literal("ultra").executes(ctx -> setMode(ctx.getSource(), PerformanceConfig.Mode.ULTRA)))
                        .then(Commands.literal("extreme").executes(ctx -> setMode(ctx.getSource(), PerformanceConfig.Mode.EXTREME)))
                        .executes(ctx -> showModes(ctx.getSource()))
                )
                .then(Commands.literal("purge")
                        .executes(ctx -> purge(ctx.getSource(), "items"))
                        .then(Commands.literal("items").executes(ctx -> purge(ctx.getSource(), "items")))
                        .then(Commands.literal("mobs").executes(ctx -> purge(ctx.getSource(), "mobs")))
                        .then(Commands.literal("all").executes(ctx -> purge(ctx.getSource(), "all")))
                )
                .then(Commands.literal("gc").executes(ctx -> runGc(ctx.getSource())))
                .then(Commands.literal("gpu").executes(ctx -> showGpu(ctx.getSource())))
                .then(Commands.literal("tune").executes(ctx -> generateTuneScript(ctx.getSource())))
                .then(Commands.literal("config")
                        .then(Commands.literal("maxcollisions")
                                .then(Commands.argument("value", IntegerArgumentType.integer(1, 64))
                                        .executes(ctx -> setMaxCollisions(ctx.getSource(), IntegerArgumentType.getInteger(ctx, "value")))))
                        .then(Commands.literal("targetmspt")
                                .then(Commands.argument("value", DoubleArgumentType.doubleArg(10.0, 50.0))
                                        .executes(ctx -> setTargetMspt(ctx.getSource(), DoubleArgumentType.getDouble(ctx, "value")))))
                        .then(Commands.literal("dynamicdist")
                                .then(Commands.argument("enabled", StringArgumentType.word())
                                        .executes(ctx -> toggleDynamicDist(ctx.getSource(), StringArgumentType.getString(ctx, "enabled")))))
                );

        dispatcher.register(lagCmd);
        // Also register alias /perf
        dispatcher.register(Commands.literal("perf").redirect(dispatcher.getRoot().getChild("lag")));
    }

    private static int showStatus(CommandSourceStack source) {
        MinecraftServer server = source.getServer();
        double mspt = PerformanceEngine.getRollingMspt();
        double tps = PerformanceEngine.getRollingTps();

        String tpsColor = tps >= 19.5 ? "§a" : (tps >= 15.0 ? "§e" : "§c");
        String msptColor = mspt <= 30.0 ? "§a" : (mspt <= 45.0 ? "§e" : "§c");

        Runtime rt = Runtime.getRuntime();
        long maxMem = rt.maxMemory() / (1024 * 1024);
        long allocatedMem = rt.totalMemory() / (1024 * 1024);
        long freeMem = rt.freeMemory() / (1024 * 1024);
        long usedMem = allocatedMem - freeMem;
        int memPercent = (int) ((usedMem * 100) / maxMem);

        // Build visual RAM bar
        StringBuilder ramBar = new StringBuilder("§a[");
        int filled = memPercent / 5;
        for (int i = 0; i < 20; i++) {
            if (i == filled) ramBar.append("§7");
            ramBar.append("|");
        }
        ramBar.append("§a]");

        double cpuProcess = PerformanceEngine.getCpuProcessLoad();
        double cpuSystem = PerformanceEngine.getCpuSystemLoad();
        int cores = Runtime.getRuntime().availableProcessors();
        PerformanceConfig config = PerformanceEngine.getConfig();

        source.sendSuccess(() -> Component.literal("§6§l================[ §e§lSERVER PERFORMANCE §6§l]================"), false);
        source.sendSuccess(() -> Component.literal("§7⚡ Server TPS: " + tpsColor + String.format("%.2f", tps) + " §7| MSPT: " + msptColor + String.format("%.1f ms", mspt) + " §8(Max 50.0ms)"), false);
        source.sendSuccess(() -> Component.literal("§7🧠 CPU Cores: §b" + cores + " Logical Threads §7| Server Load: §b" + String.format("%.1f%%", cpuProcess) + " §8(System: " + String.format("%.1f%%", cpuSystem) + ")"), false);
        source.sendSuccess(() -> Component.literal("§7⚙ Multi-Threading: §aACTIVE §7(" + config.getWorkerThreads() + " worker threads handling spatial AI & distance)"), false);
        source.sendSuccess(() -> Component.literal("§7💾 RAM Heap: §e" + (usedMem / 1024.0 >= 1.0 ? String.format("%.2f GB", usedMem / 1024.0) : usedMem + " MB")
                + " §7/ §e" + String.format("%.2f GB", maxMem / 1024.0) + " §7(" + memPercent + "%) " + ramBar), false);
        source.sendSuccess(() -> Component.literal("§7🎮 GPU Pipeline: §b" + GpuAccelerator.getGpuName() + " §7| " + (GpuAccelerator.isHardwareAccelerationActive() ? "§aDirect3D/OpenGL Hardware Active" : "§cSoftware")), false);
        source.sendSuccess(() -> Component.literal("§7🌍 World Stats: §e" + PerformanceEngine.getTotalChunksCount() + " §7Chunks | §e" + PerformanceEngine.getTotalEntitiesCount()
                + " §7Entities (§a" + PerformanceEngine.getThrottledCount() + " Throttled§7) | §e" + PerformanceEngine.getTotalItemsCount() + " §7Items"), false);

        int simDist = server.getPlayerList().getSimulationDistance();
        source.sendSuccess(() -> Component.literal("§7🔭 Sim Distance: §b" + simDist + " chunks §7| Target MSPT: §b" + config.getTargetMspt() + "ms §8(Dynamic Governor: " + (config.isDynamicSimulationDistance() ? "§aON" : "§cOFF") + "§8)"), false);
        source.sendSuccess(() -> Component.literal("§7🚀 Mode: §e§l" + config.getMode().getName() + " §7- §f" + config.getMode().getDescription()), false);

        // Clickable interactive action buttons
        MutableComponent actions = Component.literal("§6Quick Actions: ");
        actions.append(makeButton("§e[Change Mode]", "/lag mode", "Switch performance optimization profiles"));
        actions.append(Component.literal(" "));
        actions.append(makeButton("§c[Purge Items]", "/lag purge items", "Remove floating ground items"));
        actions.append(Component.literal(" "));
        actions.append(makeButton("§a[Clean RAM]", "/lag gc", "Run garbage collection and reclaim RAM"));
        actions.append(Component.literal(" "));
        actions.append(makeButton("§b[GPU Info]", "/lag gpu", "Display GPU and rendering acceleration"));
        actions.append(Component.literal(" "));
        actions.append(makeButton("§d[Tune Script]", "/lag tune", "Generate high-performance server start script"));

        source.sendSuccess(() -> actions, false);
        source.sendSuccess(() -> Component.literal("§6§l====================================================="), false);
        return 1;
    }

    private static MutableComponent makeButton(String label, String command, String hoverText) {
        return Component.literal(label).withStyle(style -> style
                .withClickEvent(new ClickEvent.RunCommand(command))
                .withHoverEvent(new HoverEvent.ShowText(Component.literal("§7Click to execute: §b" + command + "\n§8" + hoverText)))
        );
    }

    private static int showModes(CommandSourceStack source) {
        source.sendSuccess(() -> Component.literal("§6§lSelect Performance Profile:"), false);
        for (PerformanceConfig.Mode mode : PerformanceConfig.Mode.values()) {
            boolean active = PerformanceEngine.getConfig().getMode() == mode;
            MutableComponent comp = Component.literal((active ? "§a§l▶ " : "  ") + "§e[" + mode.getName() + "] §7- §f" + mode.getDescription());
            comp.withStyle(style -> style
                    .withClickEvent(new ClickEvent.RunCommand("/lag mode " + mode.name().toLowerCase()))
                    .withHoverEvent(new HoverEvent.ShowText(Component.literal("§7Click to activate §e" + mode.getName() + " §7mode")))
            );
            source.sendSuccess(() -> comp, false);
        }
        return 1;
    }

    private static int setMode(CommandSourceStack source, PerformanceConfig.Mode mode) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        PerformanceEngine.getConfig().setMode(mode);
        source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Performance profile switched to: §e§l" + mode.getName() + "§7! (" + mode.getDescription() + ")"), true);
        return 1;
    }

    private static int purge(CommandSourceStack source, String type) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        MinecraftServer server = source.getServer();
        if ("items".equalsIgnoreCase(type)) {
            int count = PerformanceEngine.purgeItems(server);
            source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Purged §e" + count + " §7floating ground items!"), true);
        } else if ("mobs".equalsIgnoreCase(type)) {
            int count = PerformanceEngine.purgeMobs(server, true);
            source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Purged §e" + count + " §7hostile / un-named mobs!"), true);
        } else {
            int items = PerformanceEngine.purgeItems(server);
            int mobs = PerformanceEngine.purgeMobs(server, true);
            source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Purged §e" + items + " §7ground items and §e" + mobs + " §7hostile mobs!"), true);
        }
        return 1;
    }

    private static int runGc(CommandSourceStack source) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        Runtime rt = Runtime.getRuntime();
        long beforeUsed = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);

        System.gc();

        long afterUsed = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);
        long freed = Math.max(0, beforeUsed - afterUsed);
        long max = rt.maxMemory() / (1024 * 1024);

        source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Memory cleanup complete! Reclaimed: §e" + freed + " MB§7. Current Heap: §b" + afterUsed + " MB / " + max + " MB"), true);
        return 1;
    }

    private static int showGpu(CommandSourceStack source) {
        List<Component> report = GpuAccelerator.getGpuReportComponents();
        for (Component comp : report) {
            source.sendSuccess(() -> comp, false);
        }
        return 1;
    }

    private static int generateTuneScript(CommandSourceStack source) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        int cores = Runtime.getRuntime().availableProcessors();
        File file = new File("run_optimized_server.bat");

        final int recommendedRamGb = (cores <= 4) ? 6 : 8;

        String scriptContent = "@echo off\r\n"
                + "title Minecraft Fabric Optimized Server\r\n"
                + "echo ================================================================\r\n"
                + "echo  Launching Fabric 1.21.11 with Multi-Core CPU & GPU Acceleration\r\n"
                + "echo ================================================================\r\n"
                + "java -Xms" + recommendedRamGb + "G -Xmx" + recommendedRamGb + "G "
                + "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 "
                + "-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch "
                + "-XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1ReservePercent=20 "
                + "-XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 "
                + "-XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 "
                + "-XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 "
                + "-Dsun.java2d.opengl=true -Dsun.java2d.d3d=true -Dsun.java2d.noddraw=true "
                + "-jar fabric-server-launch.jar nogui\r\n"
                + "pause\r\n";

        try (FileWriter writer = new FileWriter(file)) {
            writer.write(scriptContent);
            source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Generated optimized launch script: §e" + file.getAbsolutePath()), true);
            source.sendSuccess(() -> Component.literal("§7Configured for: §b" + cores + " CPU Threads§7, §b" + recommendedRamGb + " GB RAM Heap§7, and §bDirect3D/OpenGL GPU acceleration§7!"), false);
        } catch (Exception e) {
            source.sendFailure(Component.literal("§cFailed to write script: " + e.getMessage()));
        }
        return 1;
    }

    private static int setMaxCollisions(CommandSourceStack source, int val) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        PerformanceEngine.getConfig().setMaxCollisionsPerTick(val);
        source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Max collisions per tick set to: §e" + val), true);
        return 1;
    }

    private static int setTargetMspt(CommandSourceStack source, double val) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        PerformanceEngine.getConfig().setTargetMspt(val);
        source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Target MSPT set to: §e" + val + " ms"), true);
        return 1;
    }

    private static int toggleDynamicDist(CommandSourceStack source, String enabled) {
        if (!PermissionHelper.checkGeg(source)) return 0;
        boolean val = "true".equalsIgnoreCase(enabled) || "on".equalsIgnoreCase(enabled) || "1".equalsIgnoreCase(enabled);
        PerformanceEngine.getConfig().setDynamicSimulationDistance(val);
        source.sendSuccess(() -> Component.literal("§a§l[LagGuard] §7Dynamic simulation distance is now: " + (val ? "§aENABLED" : "§cDISABLED")), true);
        return 1;
    }
}
