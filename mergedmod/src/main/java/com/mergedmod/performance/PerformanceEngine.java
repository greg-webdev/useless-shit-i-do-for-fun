package com.mergedmod.performance;

import com.mergedmod.MergedMod;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.Mob;
import net.minecraft.world.entity.TamableAnimal;
import net.minecraft.world.entity.boss.enderdragon.EnderDragon;
import net.minecraft.world.entity.boss.wither.WitherBoss;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.phys.Vec3;

import java.lang.management.ManagementFactory;
import com.sun.management.OperatingSystemMXBean;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public class PerformanceEngine {
    private static PerformanceConfig config;
    private static ScheduledExecutorService workerPool;
    private static MinecraftServer currentServer;

    // Real-time metrics
    private static long lastTickStartNanos = System.nanoTime();
    private static double rollingMspt = 20.0;
    private static double rollingTps = 20.0;
    private static int totalEntitiesCount = 0;
    private static int totalMobsCount = 0;
    private static int totalItemsCount = 0;
    private static int totalChunksCount = 0;

    // Throttled entities set (swapped atomically from worker thread)
    private static volatile Set<Integer> throttledEntityIds = Collections.emptySet();

    // OS Bean for CPU metrics
    private static OperatingSystemMXBean osBean;

    public static void init() {
        config = PerformanceConfig.load();
        GpuAccelerator.init();

        int threads = config.getWorkerThreads();
        AtomicInteger threadId = new AtomicInteger(1);
        workerPool = Executors.newScheduledThreadPool(threads, r -> {
            Thread t = new Thread(r, "MergedMod-Performance-Worker-" + threadId.getAndIncrement());
            t.setDaemon(true);
            t.setPriority(Thread.NORM_PRIORITY - 1);
            return t;
        });

        try {
            if (ManagementFactory.getOperatingSystemMXBean() instanceof OperatingSystemMXBean sunBean) {
                osBean = sunBean;
            }
        } catch (Throwable ignored) {}

        MergedMod.LOGGER.info("[Performance] Multi-Core Engine initialized with {} worker threads. Mode: {}", threads, config.getMode().getName());
    }

    public static ScheduledExecutorService getWorkerPool() {
        return workerPool;
    }

    public static PerformanceConfig getConfig() {
        return config;
    }

    public static void onServerTickStart(MinecraftServer server) {
        currentServer = server;
        lastTickStartNanos = System.nanoTime();
    }

    public static void onServerTickEnd(MinecraftServer server) {
        long durationNanos = System.nanoTime() - lastTickStartNanos;
        double currentMspt = durationNanos / 1_000_000.0;

        // Exponential moving average (alpha = 0.05 for smooth rolling metric)
        rollingMspt = (rollingMspt * 0.95) + (currentMspt * 0.05);
        rollingTps = Math.min(20.0, 1000.0 / Math.max(50.0, rollingMspt));

        int tickCount = server.getTickCount();

        // Every 5 ticks: Offload spatial analysis & distance scanning to multi-core worker pool
        if (tickCount % 5 == 0 && workerPool != null && !workerPool.isShutdown()) {
            workerPool.execute(() -> scanEntitiesMultiThreaded(server));
        }

        // Every 20 ticks (1 second): Run dynamic governors (Distance & Memory)
        if (tickCount % 20 == 0) {
            runDynamicGovernors(server);
        }
    }

    /**
     * Heavy multi-core entity distance scanner:
     * Calculates distance to nearest player across CPU worker threads.
     * Prevents the main server thread from wasting any cycles on distance math!
     */
    private static void scanEntitiesMultiThreaded(MinecraftServer server) {
        try {
            List<ServerPlayer> players = server.getPlayerList().getPlayers();
            if (players.isEmpty()) {
                throttledEntityIds = Collections.emptySet();
                return;
            }

            // Cache player positions
            List<Vec3> playerPositions = new ArrayList<>(players.size());
            for (ServerPlayer player : players) {
                playerPositions.add(player.position());
            }

            double throttleDistanceSq = config.getAiThrottleDistance() * config.getAiThrottleDistance();
            Set<Integer> newThrottled = new HashSet<>();
            int entities = 0;
            int mobs = 0;
            int items = 0;
            int chunks = 0;

            for (ServerLevel level : server.getAllLevels()) {
                chunks += level.getChunkSource().getLoadedChunksCount();
                for (Entity entity : level.getAllEntities()) {
                    entities++;
                    if (entity instanceof ItemEntity) {
                        items++;
                    } else if (entity instanceof Mob mob) {
                        mobs++;
                        // Don't throttle bosses, mobs with targets, or mobs that took damage recently
                        if (mob instanceof EnderDragon || mob instanceof WitherBoss) continue;
                        if (mob.getTarget() != null || mob.hurtTime > 0) continue;
                        if (mob.hasCustomName()) continue;
                        if (mob instanceof TamableAnimal tamable && tamable.isTame()) continue;

                        // Check distance against cached player positions
                        Vec3 mobPos = mob.position();
                        boolean nearPlayer = false;
                        for (Vec3 pPos : playerPositions) {
                            if (mobPos.distanceToSqr(pPos) <= throttleDistanceSq) {
                                nearPlayer = true;
                                break;
                            }
                        }

                        if (!nearPlayer) {
                            newThrottled.add(mob.getId());
                        }
                    }
                }
            }

            throttledEntityIds = newThrottled;
            totalEntitiesCount = entities;
            totalMobsCount = mobs;
            totalItemsCount = items;
            totalChunksCount = chunks;
        } catch (Throwable t) {
            // Non-fatal background scan error
        }
    }

    /**
     * Dynamic governors for simulation distance and memory management.
     */
    private static void runDynamicGovernors(MinecraftServer server) {
        // 1. Dynamic Simulation Distance Governor
        if (config.isDynamicSimulationDistance()) {
            int currentSimDistance = server.getPlayerList().getSimulationDistance();
            if (rollingMspt > config.getTargetMspt()) {
                // Server is lagging, step down distance to relieve chunk ticking
                if (currentSimDistance > config.getMinSimulationDistance()) {
                    int newDist = currentSimDistance - 1;
                    server.getPlayerList().setSimulationDistance(newDist);
                    MergedMod.LOGGER.info("[Performance] High load detected (MSPT: {:.1f}ms). Reduced simulation distance to {}", rollingMspt, newDist);
                }
            } else if (rollingMspt < (config.getTargetMspt() - 12.0) && rollingTps >= 19.8) {
                // Headroom available, smoothly restore simulation distance
                if (currentSimDistance < config.getMaxSimulationDistance()) {
                    int newDist = currentSimDistance + 1;
                    server.getPlayerList().setSimulationDistance(newDist);
                    MergedMod.LOGGER.debug("[Performance] Server running smooth (MSPT: {:.1f}ms). Restored simulation distance to {}", rollingMspt, newDist);
                }
            }
        }

        // 2. Emergency Item Purge Watchdog
        if (rollingTps < config.getEmergencyTpsThreshold() && totalItemsCount > 600) {
            int purged = purgeItems(server);
            server.getPlayerList().broadcastSystemMessage(
                    Component.literal("§c§l[LagGuard] §eEmergency lag purge: Removed §c" + purged + " §eground items to restore server TPS!"),
                    false
            );
        }

        // 3. RAM Memory Pressure Watchdog
        Runtime runtime = Runtime.getRuntime();
        long maxMem = runtime.maxMemory();
        long allocatedMem = runtime.totalMemory();
        long freeMem = runtime.freeMemory();
        long usedMem = allocatedMem - freeMem;
        double usedPercent = ((double) usedMem / maxMem) * 100.0;

        if (config.isAutoMemoryPurgeEnabled() && usedPercent > 88.0 && rollingMspt < 35.0) {
            // Run gentle GC hint during calm tick to prevent a massive Stop-the-World freeze later
            System.gc();
        }
    }

    public static boolean isEntityThrottled(int entityId) {
        return throttledEntityIds.contains(entityId);
    }

    public static boolean shouldSkipAiStep(Mob mob) {
        if (!config.isAiThrottleEnabled()) return false;
        if (!isEntityThrottled(mob.getId())) return false;
        // Run only once every N ticks based on entity ID and tick count
        return (mob.tickCount + mob.getId()) % config.getAiThrottleInterval() != 0;
    }

    public static boolean shouldSkipItemMerge(ItemEntity item) {
        if (!config.isItemMergeThrottleEnabled()) return false;
        return (item.tickCount + item.getId()) % config.getItemMergeInterval() != 0;
    }

    public static int purgeItems(MinecraftServer server) {
        int count = 0;
        for (ServerLevel level : server.getAllLevels()) {
            for (Entity entity : level.getAllEntities()) {
                if (entity instanceof ItemEntity item && !item.isRemoved()) {
                    item.discard();
                    count++;
                }
            }
        }
        return count;
    }

    public static int purgeMobs(MinecraftServer server, boolean hostileOnly) {
        int count = 0;
        for (ServerLevel level : server.getAllLevels()) {
            for (Entity entity : level.getAllEntities()) {
                if (entity instanceof Mob mob && !mob.isRemoved()) {
                    if (mob instanceof EnderDragon || mob instanceof WitherBoss) continue;
                    if (mob.hasCustomName()) continue;
                    if (mob instanceof TamableAnimal tamable && tamable.isTame()) continue;

                    if (!hostileOnly || mob.getTarget() != null || mob.getType().getCategory().isFriendly() == false) {
                        mob.discard();
                        count++;
                    }
                }
            }
        }
        return count;
    }

    public static double getRollingMspt() {
        return rollingMspt;
    }

    public static double getRollingTps() {
        return rollingTps;
    }

    public static int getTotalEntitiesCount() {
        return totalEntitiesCount;
    }

    public static int getTotalMobsCount() {
        return totalMobsCount;
    }

    public static int getTotalItemsCount() {
        return totalItemsCount;
    }

    public static int getTotalChunksCount() {
        return totalChunksCount;
    }

    public static int getThrottledCount() {
        return throttledEntityIds.size();
    }

    public static double getCpuProcessLoad() {
        if (osBean != null) {
            double load = osBean.getProcessCpuLoad();
            if (load >= 0) return load * 100.0;
        }
        return 0.0;
    }

    public static double getCpuSystemLoad() {
        if (osBean != null) {
            double load = osBean.getCpuLoad();
            if (load >= 0) return load * 100.0;
        }
        return 0.0;
    }
}
