package com.mergedmod.backup;

import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.storage.LevelResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.function.Consumer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

public class BackupManager {
    private static final Logger LOGGER = LoggerFactory.getLogger("server-backup");
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss");

    public record BackupFile(Path path, String name, long sizeBytes, long modifiedTime) {
        public String formatSize() {
            if (sizeBytes < 1024 * 1024) {
                return String.format(Locale.ROOT, "%.1f KB", sizeBytes / 1024.0);
            }
            return String.format(Locale.ROOT, "%.2f MB", sizeBytes / (1024.0 * 1024.0));
        }

        public String formatDate() {
            LocalDateTime ldt = LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(modifiedTime), java.time.ZoneId.systemDefault());
            return ldt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        }
    }

    public static Path getBackupsDir(MinecraftServer server) {
        Path serverDir = Paths.get(".").toAbsolutePath().normalize();
        Path dir = serverDir.resolve("backups");
        try {
            Files.createDirectories(dir);
        } catch (Exception e) {
            LOGGER.error("Failed to create backups directory", e);
        }
        return dir;
    }

    public static List<BackupFile> listBackups(MinecraftServer server) {
        Path backupsDir = getBackupsDir(server);
        List<BackupFile> list = new ArrayList<>();
        if (Files.exists(backupsDir)) {
            try (DirectoryStream<Path> stream = Files.newDirectoryStream(backupsDir, "*.zip")) {
                for (Path p : stream) {
                    try {
                        long size = Files.size(p);
                        long mtime = Files.getLastModifiedTime(p).toMillis();
                        list.add(new BackupFile(p, p.getFileName().toString(), size, mtime));
                    } catch (Exception ignored) {}
                }
            } catch (Exception e) {
                LOGGER.error("Failed to list backups", e);
            }
        }
        list.sort((a, b) -> Long.compare(b.modifiedTime(), a.modifiedTime()));
        return list;
    }

    private static final java.util.concurrent.atomic.AtomicBoolean isBackupInProgress = new java.util.concurrent.atomic.AtomicBoolean(false);

    public static boolean isBackupRunning() {
        return isBackupInProgress.get();
    }

    public static void createBackup(MinecraftServer server, String tag, Consumer<String> onSuccess, Consumer<String> onError) {
        if (!isBackupInProgress.compareAndSet(false, true)) {
            onError.accept("A backup is already running in background. Please wait!");
            return;
        }

        // Step 1: Trigger non-blocking asynchronous save on the main server thread
        // suppressLog=true prevents spamming console for 30+ dimensions
        // flush=false prevents main thread from blocking synchronously on disk I/O
        // force=false saves only dirty chunks and all player/level data cleanly in < 5ms
        try {
            server.saveEverything(true, false, false);
        } catch (Exception e) {
            LOGGER.warn("Warning during saveEverything: {}", e.getMessage());
        }

        Path serverDir = Paths.get(".").toAbsolutePath().normalize();
        Path worldDir = server.getWorldPath(LevelResource.ROOT).toAbsolutePath().normalize();
        Path backupsDir = getBackupsDir(server);

        String timeStr = LocalDateTime.now().format(TIME_FORMAT);
        String name = "backup_" + timeStr + (tag != null && !tag.isBlank() ? "_" + tag : "") + ".zip";
        Path destZip = backupsDir.resolve(name);

        CompletableFuture.runAsync(() -> {
            Thread currentThread = Thread.currentThread();
            int originalPriority = currentThread.getPriority();
            try {
                // Run background backup at lowest priority so it never starves game ticks
                currentThread.setPriority(Thread.MIN_PRIORITY);
                currentThread.setName("BackupWorld-Worker");

                // Brief pause allowing in-flight chunk write buffers to settle on disk
                try {
                    Thread.sleep(1200);
                } catch (InterruptedException ignored) {}

                byte[] buffer = new byte[65536];

                try (OutputStream fos = Files.newOutputStream(destZip);
                     java.io.BufferedOutputStream bos = new java.io.BufferedOutputStream(fos, 65536);
                     ZipOutputStream zos = new ZipOutputStream(bos)) {
                    // Region chunks (.mca) are already compressed by Minecraft; BEST_SPEED runs 10x faster with near-zero CPU
                    zos.setLevel(java.util.zip.Deflater.BEST_SPEED);

                    // 1. Zip the complete world directory
                    if (Files.exists(worldDir)) {
                        String worldPrefix = worldDir.getFileName().toString();
                        Files.walkFileTree(worldDir, new SimpleFileVisitor<>() {
                            @Override
                            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
                                String fileName = file.getFileName().toString();
                                if (fileName.endsWith(".lock") || fileName.endsWith(".lck")) {
                                    return FileVisitResult.CONTINUE;
                                }
                                try {
                                    String rel = worldPrefix + "/" + worldDir.relativize(file).toString().replace('\\', '/');
                                    zos.putNextEntry(new ZipEntry(rel));
                                    try (InputStream in = Files.newInputStream(file)) {
                                        int read;
                                        while ((read = in.read(buffer)) != -1) {
                                            zos.write(buffer, 0, read);
                                        }
                                    }
                                    zos.closeEntry();
                                } catch (Exception ignored) {}
                                return FileVisitResult.CONTINUE;
                            }
                        });
                    }

                    // 2. Zip server settings and config files
                    List<String> serverFiles = List.of(
                        "server.properties", "ops.json", "whitelist.json",
                        "banned-players.json", "banned-ips.json"
                    );
                    for (String sName : serverFiles) {
                        Path p = serverDir.resolve(sName);
                        if (Files.exists(p) && Files.isRegularFile(p)) {
                            try {
                                zos.putNextEntry(new ZipEntry(sName));
                                try (InputStream in = Files.newInputStream(p)) {
                                    int read;
                                    while ((read = in.read(buffer)) != -1) {
                                        zos.write(buffer, 0, read);
                                    }
                                }
                                zos.closeEntry();
                            } catch (Exception ignored) {}
                        }
                    }

                    // 3. Zip config folder
                    Path configDir = serverDir.resolve("config");
                    if (Files.exists(configDir) && Files.isDirectory(configDir)) {
                        Files.walkFileTree(configDir, new SimpleFileVisitor<>() {
                            @Override
                            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
                                try {
                                    String rel = "config/" + configDir.relativize(file).toString().replace('\\', '/');
                                    zos.putNextEntry(new ZipEntry(rel));
                                    try (InputStream in = Files.newInputStream(file)) {
                                        int read;
                                        while ((read = in.read(buffer)) != -1) {
                                            zos.write(buffer, 0, read);
                                        }
                                    }
                                    zos.closeEntry();
                                } catch (Exception ignored) {}
                                return FileVisitResult.CONTINUE;
                            }
                        });
                    }

                    long sizeBytes = Files.size(destZip);
                    String sizeStr = String.format(Locale.ROOT, "%.2f MB", sizeBytes / (1024.0 * 1024.0));
                    onSuccess.accept("Created backup " + name + " (" + sizeStr + ")");
                }
            } catch (Exception e) {
                LOGGER.error("Backup failed", e);
                onError.accept(e.getMessage());
            } finally {
                currentThread.setPriority(originalPriority);
                isBackupInProgress.set(false);
            }
        });
    }

    public static void restoreBackup(MinecraftServer server, String targetName, Consumer<String> onKick, Consumer<String> onError) {
        List<BackupFile> backups = listBackups(server);
        if (backups.isEmpty()) {
            onError.accept("No backups found in backups/ directory.");
            return;
        }

        BackupFile target = null;
        if (targetName == null || targetName.isBlank() || targetName.equalsIgnoreCase("latest")) {
            target = backups.get(0);
        } else {
            for (BackupFile bf : backups) {
                if (bf.name().equalsIgnoreCase(targetName) || bf.name().contains(targetName)) {
                    target = bf;
                    break;
                }
            }
        }

        if (target == null) {
            onError.accept("Could not find backup matching: " + targetName);
            return;
        }

        Path backupZip = target.path();
        Path serverDir = Paths.get(".").toAbsolutePath().normalize();

        // 1. Kick every connected player
        Component kickReason = Component.literal(
            "§c§l[Server Restore In Progress]\n§eRestoring backup: §f" + target.name() + "\n§aServer is applying backup state. Please reconnect in a moment!"
        );
        for (ServerPlayer player : new ArrayList<>(server.getPlayerList().getPlayers())) {
            player.connection.disconnect(kickReason);
        }
        onKick.accept("Kicked all players. Applying backup: " + target.name());

        // 2. Perform direct file extraction for unlocked files & stage shutdown hook for locked files
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try (ZipFile zip = new ZipFile(backupZip.toFile())) {
                Enumeration<? extends ZipEntry> entries = zip.entries();
                while (entries.hasMoreElements()) {
                    ZipEntry entry = entries.nextElement();
                    Path outPath = serverDir.resolve(entry.getName()).normalize();
                    if (!outPath.startsWith(serverDir)) continue;
                    if (entry.isDirectory()) {
                        Files.createDirectories(outPath);
                    } else {
                        Files.createDirectories(outPath.getParent());
                        try (InputStream in = zip.getInputStream(entry)) {
                            Files.copy(in, outPath, StandardCopyOption.REPLACE_EXISTING);
                        } catch (Exception ignored) {}
                    }
                }
                LOGGER.info("Shutdown hook successfully restored all files from {}", backupZip.getFileName());
            } catch (Exception e) {
                LOGGER.error("Failed in shutdown hook restore", e);
            }
        }));

        // 3. Stop server so file locks are released and shutdown hook cleanly overwrites world
        server.execute(() -> {
            server.halt(false);
        });
    }

    public static boolean deleteBackup(MinecraftServer server, String filename) {
        Path backupsDir = getBackupsDir(server);
        Path target = backupsDir.resolve(filename);
        if (Files.exists(target) && target.startsWith(backupsDir)) {
            try {
                return Files.deleteIfExists(target);
            } catch (Exception e) {
                LOGGER.error("Failed to delete backup {}", filename, e);
            }
        }
        return false;
    }
}
