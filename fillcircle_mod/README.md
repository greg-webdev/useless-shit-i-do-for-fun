# FillCircle Mod - Minecraft 1.21.11 (Fabric Server)

A server-side Fabric mod for **Minecraft 1.21.11** that adds the `/fillcircle` command.

Because this is a server-side mod, **clients do NOT need to install this mod**—players connecting to your Fabric 1.21.11 server automatically receive the command and auto-completion via vanilla Brigadier packet synchronization.

---

## Command Syntax

```mcfunction
/fillcircle <radius> <hollow> <howtall> <usewhatblock> [center]
```

### Arguments:
1. **`<radius>`** *(integer, 1 - 1024)*: The radius of the circle in blocks.
2. **`<hollow>`** *(boolean, `true` or `false`)*:
   - `true`: Generates a hollow perimeter ring / tube (1-block thick sealed walls).
   - `false`: Generates a completely filled solid disk / solid cylinder.
3. **`<howtall>`** *(integer, 1 - 384)*:
   - `1`: Creates a flat horizontal circle (1 block thick).
   - `> 1`: Extrudes the circle upwards to create a cylinder of the specified height.
4. **`<usewhatblock>`** *(block identifier)*:
   - Any valid Minecraft block with auto-complete and block state support (e.g., `minecraft:stone`, `glass`, `oak_planks`, `sea_lantern`, `smooth_quartz[axis=y]`).
5. **`[center]`** *(optional block coordinates)*:
   - The center coordinates of the circle. If omitted, defaults to the executing player's position (or command source position).

---

## Examples

* **Flat solid stone circle (radius 5, 1 block tall):**
  ```mcfunction
  /fillcircle 5 false 1 minecraft:stone
  ```

* **Hollow glass cylinder / tower (radius 10, 15 blocks tall):**
  ```mcfunction
  /fillcircle 10 true 15 minecraft:glass
  ```

* **Flat hollow ring of sea lanterns (radius 8):**
  ```mcfunction
  /fillcircle 8 true 1 minecraft:sea_lantern
  ```

* **Solid gold cylinder centered at specific coordinates:**
  ```mcfunction
  /fillcircle 6 false 3 minecraft:gold_block 100 64 200
  ```

---

## Installation on Fabric Server

1. Ensure your Fabric server is running **Minecraft 1.21.11** with **Fabric Loader** (`0.19.5+` or `0.16.x+`) and **Fabric API** installed in the server's `mods` folder.
2. Drop `fillcircle-1.0.0.jar` into your server's `mods/` directory:
   - A pre-compiled copy has been placed in your user directory:
     `C:\Users\GREG GAMING PC\fillcircle-1.0.0.jar`
   - And also in:
     `C:\Users\GREG GAMING PC\Downloads\fillcircle-1.0.0.jar`
3. Restart or start your server.
4. Op players (permission level 2+) or console can now use `/fillcircle`.

---

## Mathematical Implementation

The mod uses a discrete grid rasterization formula:
$$\text{dist}^2 = \Delta x^2 + \Delta z^2 \le (R + 0.25)^2$$

- Produces a smooth, symmetrical circular outline with cleanly trimmed corners across all radii.
- The `hollow` algorithm evaluates discrete 4-way orthogonal boundary topology, ensuring that all hollow cylinders are completely continuous (leak-proof and airtight) with exactly 1-block thickness.
- Respects the server's `commandModificationBlockLimit` gamerule to protect against runaway block operations.
