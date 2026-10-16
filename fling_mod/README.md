# Fling Mod - Minecraft 1.21.11 (Fabric Server)

A high-performance, **100% server-side Fabric mod** for **Minecraft 1.21.11** (Mounts of Mayhem update) that adds the `/fling` command and a coordinate-based launch pad system.

Because this mod is **strictly server-side**, **players connecting to your server do NOT need to install anything!** Vanilla Minecraft clients will automatically receive the command with full Brigadier tab auto-completion, tooltips, interactive click-to-copy chat buttons, and smooth synchronized physics.

---

## Pre-Compiled Jar Locations

A pre-compiled, remapped, and ready-to-use `.jar` file has been generated and placed in:
- `C:\Users\GREG GAMING PC\fling-1.0.0.jar`
- `C:\Users\GREG GAMING PC\Downloads\fling-1.0.0.jar`

Simply copy either file into your Fabric 1.21.11 server's `mods/` folder and restart the server!

---

## Features & Command Syntax

### 1. Flinging In Your Look Direction (`thisway`)
Flings the target player in the exact direction you are currently looking, and displays a clickable chat message with the exact velocity vector.
```mcfunction
/fling <player> thisway [power]
```
- **Click-to-Copy in Chat**: Clicking the vector or `[📋 Copy Direction]` copies the velocity vector (e.g. `0.45 1.20 -1.34`) directly to your clipboard.
- **Click-to-Copy Command**: Clicking `[⚡ Copy Command]` copies the full `/fling <player> <x> <y> <z>` command straight to your clipboard.

### 2. Direct 3D Velocity Vectors
Flings target(s) with an exact vector along X, Y, and Z axes. Supports decimals and negative values.
```mcfunction
/fling <player> <x> <y> <z>
```
**Examples:**
- Launch straight up 2.5 blocks/tick:
  ```mcfunction
  /fling @p 0 2.5 0
  ```
- Launch forward-north with upward arc:
  ```mcfunction
  /fling Steve 0 1.2 -1.8
  ```
- Launch all players:
  ```mcfunction
  /fling @a 1.0 1.5 0
  ```

### 3. Named Cardinal & Relative Directions
Quick directional flinging with optional speed/power argument:
```mcfunction
/fling <player> <direction> [power]
```
Supported directions:
- `up`, `down`, `north`, `south`, `east`, `west`
- `forward` (launches in target's facing direction)
- `backward` (launches backward from target's facing direction)
- `look` (launches along target's eye look vector)

**Examples:**
```mcfunction
/fling @p up 2.0
/fling @s forward 2.5
/fling Steve north 1.8
```

### 4. Command Block Walk-Over Activation (`/fling at`)
Designed specifically for command blocks and parkour/adventure maps. Activates when any player walks over or steps onto a specific block coordinate.
```mcfunction
/fling at <pos> <velocity>
/fling at <pos> thisway [power]
/fling at <pos> <direction> [power]
/fling at <pos> radius <r> <velocity>
```
**Command Block Examples:**
- Put this in a **Repeating Command Block (Always Active)**:
  ```mcfunction
  /fling at 100 64 200 0 2.0 1.5
  ```
  *Anyone walking over block (100, 64, 200) will be instantly launched! If nobody is there, it silently returns 0.*
- Relative coordinate command block (flings whoever walks on top of the command block):
  ```mcfunction
  /fling at ~ ~1 ~ 0 1.8 0
  ```

### 5. Persistent Server-Side Launch Pads (`/fling pad`)
If you prefer not using repeating command block clocks, you can register permanent walk-over launch pads at specific coordinates. The server monitors player footsteps and launches them with a smooth 0.6s cooldown:
```mcfunction
/fling pad add <x y z> <vx vy vz>
/fling pad add <x y z> thisway [power]
/fling pad add <x y z> <direction> [power]
/fling pad remove <x y z>
/fling pad list
/fling pad clear
```
- Saved to `config/fling_pads.json` across server restarts.

### 6. Default Fling & Self Launch
- `/fling <player>`: Launches player straight up into the air with default velocity (`1.8`).
- `/fling`: If executed by a player, launches yourself upward.
- `/fling help`: Displays the interactive in-game guide.

---

## Technical Details
- **Version Compatibility**: Minecraft Java Edition `1.21.11` (Fabric Loader `0.19.5+`, Fabric API `0.141.6+1.21.11`).
- **Fall Damage Safety**: The mod resets player fall distance on launch and includes automatic fall damage immunity on landing, preventing unfair deaths on jump pads.
- **Vehicle Support**: If a player is riding a horse, boat, or minecart, the vehicle is launched together with the rider.
- **Visual & Audio Feedback**: Plays vanilla wind charge burst sound effects and spawns breeze gust & cloud particles when triggered.
