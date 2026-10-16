# Merged Server Utility Mod (Fabric 1.21.11)

A unified, 100% server-side Fabric mod for Minecraft 1.21.11 (*Mounts of Mayhem*).
Clients connect using standard vanilla Minecraft 1.21.11 without needing any mods installed!

## Features Included
1. **`/fling`** - Directional launch, Click-to-copy chat buttons, 3D vectors, Launch Pads, Command block support (`/fling at`), and full fall protection.
2. **`/fillcircle`** - World-edit style horizontal filled circle generator with block replacement filters, undo/redo history, and safety limits.
3. **`/loginmsg <message>`** - Custom broadcast welcome message on player login. (*Restricted strictly to `geg`*).
4. **`/tnt`** - Server-side Interactive Chest GUI to toggle TNT explosions on/off server-wide with live feedback. (*Restricted strictly to `geg`*).
5. **`/backupworld [tag]`** - Instant, full server state backup (all dimensions, configs, and server files) compressed to `.zip` in `backups/`. (*Restricted strictly to `geg`*).
6. **`/backups [list|restore|delete]`** - Manage and restore backups. Restoring safely kicks all players and replaces files cleanly. (*Restricted strictly to `geg`*).
7. **`/lag` or `/perf`** - **Advanced Multi-Core Server Performance & Hardware Accelerator**:
   - 🧠 **Multi-Core CPU Engine**: Distributes heavy spatial entity tracking & distance scans across worker threads on all available CPU logical cores instead of bottlenecking on the single server thread.
   - 💥 **Anti-Lag Collision Cap**: Caps entity-to-entity push physics checks ($O(N^2)$) to prevent mob farm and entity-cramming lag freezes.
   - 🧟 **Intelligent Mob AI Throttling**: Safely throttles AI/pathfinding updates for faraway mobs (>32 blocks) while keeping combat and nearby mobs 100% responsive.
   - 📦 **Item Merge Throttler & Emergency Purger**: Throttles item search ticks by 90% and includes `/lag purge [items|mobs|all]`.
   - 🔭 **Dynamic Simulation Distance Governor**: Automatically adjusts simulation distance on-the-fly based on real-time server MSPT to prevent chunk loading lag spikes.
   - 💾 **RAM Memory Watchdog & `/lag gc`**: Monitors heap allocation, prevents Stop-The-World GC spikes, and allows on-demand memory reclamation.
   - 🎮 **GPU Hardware Acceleration & Diagnostics (`/lag gpu`)**: Automatically activates Direct3D/OpenGL graphics pipeline flags in the JVM and detects dedicated GPUs (e.g., NVIDIA GeForce GTX 1650 SUPER).
   - ⚡ **Automated Server Launch Tuner (`/lag tune`)**: Generates an optimized `run_optimized_server.bat` script tailored with Aikar G1GC flags, multi-threading, and hardware acceleration.
   - 🎛 **Modes**: `/lag mode [balanced|turbo|ultra|extreme]` to dial in the exact performance level needed.

---

## Jar Download & Installation
- Mod Jar location: `C:\Users\GREG GAMING PC\mergedmod-1.0.0.jar`
- Also copied to your `Downloads` folder: `C:\Users\GREG GAMING PC\Downloads\mergedmod-1.0.0.jar`
- Just place `mergedmod-1.0.0.jar` into your Fabric server's `mods/` directory along with Fabric API and restart the server!
