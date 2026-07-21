# Mobs Andes 🦙

**Bring the vibrant, rugged spirit of the South American Andes to your Luanti (Minetest) world!**

*Mobs Andes* is a high-quality companion animal mod built for the `mobs_redo` framework. Unlike heavy, monolithic animal packs, it is designed from the ground up to be lightweight, modular, and perfectly compatible with your favorite world generators and mods.

Whether you are looking for a loyal protector for your home, a hardy mount to cross mountain peaks, or a source of luxuriously soft wool, *Mobs Andes* adds life, utility, and charm to your adventures.

---

## Meet the Animals

### 🦙 The Alpaca (*Vicugna pacos*)
Prized worldwide for their soft, warm fleece, these peaceful grazers roam the grassy high plains. Tame them with wheat or grass, shear them, and build with their beautiful wool!
- **Natural Colors**: Alpacas spawn in three gorgeous, natural coat colors:
  - 🟤 **Light Fawn** — the classic, warm beige-tan
  - 🟫 **Dark Fawn** — a rich, deep earthy brown
  - 🪙 **Light Silver Gray** — a sleek, modern silver-gray
- **Behavior**: They peacefully graze on grass, flee when attacked, and can be tamed, bred, and captured with a lasso to guide them home.

### 🫏 The Donkey (*Equus asinus*)
The ultimate high-altitude travel partner. Donkeys are exceptionally hardy pack animals that make traversing steep terrain a breeze.
- **Riding & Autopilot**: Equip a donkey with a saddle to ride them! If you want to sit back and take in the view, enable the built-in **autopilot mode** (press your special/aux1 key) to let your mount navigate the path automatically.
- **Behavior**: They wander grassy biomes, graze calmly, and follow players holding grass or wheat.

### 🐕 The Domestic Guard Dog (*Canis lupus familiaris*)
A loyal guardian for your homestead. The domestic guard dog is more than just a pet—it is a fierce protector.
- **Homestead Protection**: Once tamed with raw meat, your guard dog will follow you faithfully. If hostile mobs or intruders threaten you, your companion will immediately leap to your defense!
- **Commands & Care**: Right-click your dog to order them to "stay" (guarding a specific spot) or "follow". Feed them meat to heal their wounds and permanently increase their maximum health.

---

## Installation & Setup

1. Make sure you have the [mobs (mobs_redo)](https://content.luanti.org/packages/TenPlus1/mobs/) mod installed and enabled.
2. Download or clone this repository and place the folder inside your Luanti `mods/` directory.
3. Rename the directory to **`mobs_andes`**.
4. Enable `mobs_andes` in your world configuration.

### Configuration
You can tweak settings directly in your `minetest.conf` file:
```ini
# Prevent animals from eating grass blocks (disabling keeps the grass green!)
mobs_andes.eat_grass_block = false

# Enable or disable individual mobs
mobs_andes.alpaca = true
mobs_andes.donkey = true
mobs_andes.dog = true
```

---

## Licenses & Credits

- **Code**: Licensed under the MIT License (see [LICENCE.md](LICENCE.md)).
- **Graphics (Models & Textures)**: Created by **ronrob-lu** and released under the **Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA 4.0)** license.
- **Mod Framework**: Built on [mobs_redo](https://content.luanti.org/packages/TenPlus1/mobs/) by TenPlus1.
- **Inspiration**: Inspired by the classic *mobs_animal* mod.