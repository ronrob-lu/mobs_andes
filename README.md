# Mobs Andes

**A Luanti / Minetest mod adding animals from the Andes region of South America.**

This is a mod for the [mobs (mobs_redo)](https://content.luanti.org/packages/TenPlus1/mobs/) framework. It is **not** a fork of *mobs_animal* — it depends only on the base `mobs` mod so it can be installed independently alongside (or without) other animal mods.

> **Current version (0.1):** Only the **Alpaca** is included.  
> More Andean animals are planned — see [Roadmap](#roadmap).

---

## Screenshot

*(No screenshot yet — spawn an alpaca with its egg and explore!)*

---

## Animals

### 🦙 Alpaca (*Vicugna pacos*)

The alpaca is a domesticated South American camelid, native to the high Andean plateau (altiplano). It is prized worldwide for its luxuriously soft **fleece**, which comes in 16 natural colours.

| Property         | Value |
|-----------------|-------|
| Health          | 8 – 16 HP |
| Passive         | Yes (flees when hit) |
| Walk speed      | 1.2 |
| Run speed       | 3.5 (alpacas are surprisingly fast!) |
| Drops on death  | 1–2× Raw Meat + 1–2× Light Fawn Wool |
| Taming food     | Wheat, grass, barley, oat, rye (8× to tame) |
| Spawns on       | `default:dirt_with_grass` (same biomes as cows) |

#### Behaviour
- Wanders peacefully and **grazes on grass** nodes as it walks.
- **Runs away** when attacked.
- Can be **tamed** and **bred** by feeding it wheat or grass 8 times.
- Can be **captured** with a magic lasso (mobs item).
- Right-click with a net / lasso item to capture a tamed alpaca.

#### Colour / Wool
The current alpaca has a **light fawn** coat — the most common natural colour. The wool item is `mobs_andes:wool_light_fawn`.

> See [Adding More Colours](#adding-more-alpaca-colours) for how to extend this.

---

## Dependencies

| Dependency | Required? | Notes |
|---|---|---|
| `mobs` (mobs_redo) | ✅ Required | Provides the mob API |
| `default` | Optional | Used for grass / dirt nodes |
| `ethereal` | Optional | Adds extra spawn biomes |
| `mobs_animal` | ❌ Not required | This mod is independent |

---

## Installation

1. Download or clone this repository.
2. Place the folder in your Luanti `mods/` directory.  
   The folder must be named **`mobs_andes`**.
3. Enable the mod in your world settings.
4. Make sure `mobs` (mobs_redo) is also enabled.

---

## Spawning

Alpacas spawn in the same conditions as cows:
- On `default:dirt_with_grass` (and `ethereal:green_dirt` if present).
- Need nearby grass (neighbour node in the `grass` group).
- Minimum light level 14.
- Daytime only.
- Height range: 5 – 200 nodes.

### Custom Spawn File

Create a `spawn.lua` file inside the `mobs_andes` mod folder to override all built-in spawn rules. The init will detect it automatically and skip the default spawn block.

### Settings (`minetest.conf`)

```ini
# Disable individual animals
mobs_andes.alpaca = false

# Allow alpacas (and cows/sheep) to eat grass *blocks* (dirt_with_grass)
# This can alter terrain — disabled by default
mobs_andes.eat_grass_block = false
```

---

## Adding More Alpaca Colours

The alpaca is designed so that multiple colour variants can be added with minimal effort.

### Steps

1. **Add an entry to `alpaca_colours`** in `alpaca.lua`:

   ```lua
   {"white", S("White Alpaca"), "texture_alpaca_white.png", "wool:white"},
   ```

   Format: `{ colour_key, display_name, texture_file, wool_item }`

2. **Add the model texture** to `textures/`:
   ```
   textures/texture_alpaca_white.png
   ```

3. **Add the wool inventory texture** (used on the spawn egg):
   ```
   textures/wool_white.png
   ```
   If the wool item is from another mod (e.g. `wool:white` from the *wool* mod), you still need the texture here for the spawn egg overlay — or use that mod's texture directly.

4. **Register the wool item** (if it doesn't already exist):
   ```lua
   core.register_craftitem("mobs_andes:wool_white", {
       description = S("White Alpaca Wool"),
       inventory_image = "wool_white.png",
       groups = {wool = 1},
   })
   ```
   Skip this step if you're reusing e.g. `wool:white`.

5. **Add spawning** for the new variant in the spawn section (or in `spawn.lua`).

### The 16 Official Alpaca Colours

```
white           light_fawn      medium_fawn     dark_fawn
light_brown     medium_brown    dark_brown      bay_black
true_black      silver_grey     medium_silver_grey  dark_silver_grey
light_rose_grey medium_rose_grey dark_rose_grey  roan
```

---

## Model & Animations

- **Model:** `models/alpaca.gltf` (Blockbench export)
- **Texture:** `textures/texture_alpaca.png` (light fawn colour)

The gltf model has four named animations. Because gltf uses **time (seconds)** instead of frame numbers:

| Animation | Duration | Used for |
|-----------|----------|----------|
| `stand`   | 0 – 2.0 s | Idle standing |
| `walk`    | 0 – 2.0 s | Walking |
| `run`     | 0 – 1.375 s | Running / fleeing |
| `eat`     | 0 – 2.5 s | Grazing (stand1 variant) |

> **Note for modders:** Set `speed_normal = 1.0` and `*_speed = 1.0` when working with gltf animations. The engine interprets the x/y values as seconds, not frame numbers.

---

## File Structure

```
mobs_andes/
├── init.lua              — Main entry point; loads animal files
├── mod.conf              — Mod metadata
├── alpaca.lua            — Alpaca mob definition
├── LICENCE.md            — Licence
├── README.md             — This file
├── models/
│   └── alpaca.gltf       — 3-D model with animations
└── textures/
    ├── texture_alpaca.png     — Alpaca body texture (light fawn)
    ├── wool_light_fawn.png    — Light fawn wool inventory icon
    └── mobs_alpaca_inv.png    — Spawn egg inventory image
```

---

## Roadmap

Animals planned for future releases (contributions welcome!):

- 🦙 **Llama** (*Lama glama*) — larger, used as a pack animal
- 🐾 **Vicuña** (*Vicugna vicugna*) — wild relative, very fine wool
- 🐾 **Guanaco** (*Lama guanicoe*) — wild, high-altitude
- 🦅 **Andean Condor** (*Vultur gryphus*) — flying mob
- 🐻 **Spectacled Bear** (*Tremarctos ornatus*) — rare passive/hostile
- 🦎 **Giant Andean Lizard** — passive mob

---

## Licence

See [LICENCE.md](LICENCE.md).

---

## Credits

- **Model & Textures:** ronrob-lu  
- **Mod framework:** based on [mobs_redo](https://notabug.org/TenPlus1/mobs_redo) by TenPlus1  
- Inspired by *mobs_animal* (sirrobzeroone, PilzAdam, KrupnoPavel and contributors)