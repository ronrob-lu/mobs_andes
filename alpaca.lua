
-- ============================================================
-- Alpaca - Vicugna pacos
-- A domesticated South American camelid, highly valued for
-- its fibre (fleece / wool).
-- Author: ronrob-lu
-- ============================================================
--
-- COLOUR / TEXTURE NOTES
-- ---------------------------------------------------------------
-- Alpacas come in 16 officially recognised natural colours.
-- This file currently registers only ONE colour: "light_fawn",
-- which is the natural fawn (beige/tan) colour of this model.
--
-- To add more colour variants:
--
--  1. Add the colour key to the `alpaca_colours` table below.
--     Format: { "colour_key", "Human Name", "wool_item_name" }
--     The wool_item_name is the full item name for the wool drop,
--     e.g. "mobs_andes:wool_light_fawn"  OR  "wool:white" if you
--     want to reuse items from another mod.
--
--  2. Make sure a texture file exists for each colour:
--       textures/texture_alpaca_<colour_key>.png
--     (currently only texture_alpaca.png exists for light_fawn)
--     The texture is applied to the alpaca model.
--
--  3. Make sure the corresponding wool texture/item exists:
--       textures/wool_<colour_key>.png
--     This is used as the spawn egg overlay and as the drop.
--
--  4. If you register multiple colour variants, update the
--     spawn section (mobs:spawn call) to spread spawning across
--     the colour table, similar to how mobs_animal/sheep.lua does.
--
-- The 16 official alpaca colours recognised by most breed registries
-- (add these in future):
--   white, light_fawn, medium_fawn, dark_fawn, light_brown,
--   medium_brown, dark_brown, bay_black, true_black,
--   silver_grey, medium_silver_grey, dark_silver_grey,
--   light_rose_grey, medium_rose_grey, dark_rose_grey, roan
-- ---------------------------------------------------------------

-- Translator (kept matching modname for future translation files)
local S = core.get_translator("mobs_andes")

-- ============================================================
-- Grass eating config - mirrors the cow/sheep behaviour
-- Should the alpaca eat grass blocks and remove them?
-- Set  mobs_andes.eat_grass_block = true  in minetest.conf
-- ============================================================
local eat_gb = core.settings:get_bool("mobs_andes.eat_grass_block")

-- replace_what: { {node_to_replace, replace_with, y_offset} }
-- Alpacas nibble grass tufts; optionally also strip dirt_with_grass
local replace_what = { {"group:grass", "air", 0} }

if eat_gb then
	table.insert(replace_what, {"default:dirt_with_grass", "default:dirt", -1})
end

-- ============================================================
-- Colour table
-- Each entry: { colour_key, display_name, texture_file, wool_item }
--
-- colour_key   : used in the mob name  "mobs_andes:alpaca_<key>"
-- display_name : shown in spawn egg tooltip
-- texture_file : texture applied to the 3-D model
-- wool_item    : item dropped on kill / shearing (future feature)
--
-- ADDING COLOURS: add a row here and provide matching assets.
-- ============================================================
local alpaca_colours = {
	-- currently only the natural light-fawn colour is implemented
	-- texture file: textures/texture_alpaca.png
	-- wool texture: textures/wool_light_fawn.png
	{"light_fawn", S("Light Fawn Alpaca"), "texture_alpaca.png", "mobs_andes:wool_light_fawn"},
	{"dark_fawn",  S("Dark Fawn Alpaca"),  "texture_alpaca_dark_fawn.png", "mobs_andes:wool_dark_fawn", "mobs_alpaca_dark_fawn_inv.png"},
	{"light_silver_grey", S("Light Silver Gray Alpaca"), "texture_alpaca_light_silver_gray.png", "mobs_andes:wool_light_silver_grey", "mobs_alpaca_light_silver_grey.png"},

	-- Future examples (assets not yet created):
	-- {"white",        S("White Alpaca"),        "texture_alpaca_white.png",        "wool:white"},
	-- {"dark_brown",   S("Dark Brown Alpaca"),   "texture_alpaca_dark_brown.png",   "mobs_andes:wool_dark_brown"},
	-- {"true_black",   S("Black Alpaca"),        "texture_alpaca_true_black.png",   "mobs_andes:wool_true_black"},
}

-- ============================================================
-- Register the wool BLOCKS
--
-- Registered as a node so it can be placed and built with.
-- The inventory_image is used when the block is in hand/inventory.
--
-- ADDING COLOURS: register a core.register_node for each new colour.
-- Use the matching wool_<colour>.png texture on all six sides.
-- If reusing a block from another mod (e.g. wool:white), skip this.
-- ============================================================
core.register_node("mobs_andes:wool_light_fawn", {
	description = S("Light Fawn Alpaca Wool"),
	tiles = {"wool_light_fawn.png"},
	is_ground_content = false,
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, wool = 1},
	sounds = core.get_modpath("default") and
		default and default.node_sound_defaults and
		default.node_sound_defaults() or nil,
})

core.register_node("mobs_andes:wool_dark_fawn", {
	description = S("Dark Fawn Alpaca Wool"),
	tiles = {"wool_dark_fawn.png"},
	is_ground_content = false,
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, wool = 1},
	sounds = core.get_modpath("default") and
		default and default.node_sound_defaults and
		default.node_sound_defaults() or nil,
})

core.register_node("mobs_andes:wool_light_silver_grey", {
	description = S("Light Silver Gray Alpaca Wool"),
	tiles = {"wool_light_silver_grey.png"},
	is_ground_content = false,
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, wool = 1},
	sounds = core.get_modpath("default") and
		default and default.node_sound_defaults and
		default.node_sound_defaults() or nil,
})

-- ============================================================
-- Register one mob per colour entry
-- ============================================================
for _, col in ipairs(alpaca_colours) do

	local col_key   = col[1]  -- e.g. "light_fawn"
	local col_name  = col[2]  -- e.g. "Light Fawn Alpaca"
	local col_tex   = col[3]  -- e.g. "texture_alpaca.png"
	local wool_item = col[4]  -- e.g. "mobs_andes:wool_light_fawn"

	-- ---------------------------------------------------------
	-- Drop table: raw meat + wool when killed
	-- mobs:meat_raw is registered by the mobs base mod (crafts.lua).
	-- It cooks into mobs:meat in a furnace.
	-- If your mobs version uses a different name, change it here.
	-- ---------------------------------------------------------
	local drops = {
		{name = "mobs:meat_raw", chance = 1, min = 1, max = 2},
		{name = wool_item,       chance = 1, min = 1, max = 2},
	}

	-- ---------------------------------------------------------
	-- Register the mob
	-- ---------------------------------------------------------
	mobs:register_mob("mobs_andes:alpaca_" .. col_key, {

		-- Basic type / behaviour
		type            = "animal",
		passive         = true,   -- flees instead of fighting back
		runaway         = true,
		hp_min          = 8,
		hp_max          = 16,
		armor           = 100,

		-- Physics
		collisionbox    = {-0.4, -0.01, -0.4, 0.4, 1.8, 0.4},
		stepheight      = 0.6,
		walk_velocity   = 1.2,
		run_velocity    = 3.5,   -- alpacas can sprint at ~56 km/h
		jump            = true,
		jump_height     = 4,
		pushable        = true,
		fear_height     = 3,

		-- Visuals
		-- TEXTURE CHANGE:
		--   To swap the texture, change col_tex above or the entry in alpaca_colours.
		--   The gltf already embeds the texture, but the engine uses the registered
		--   texture from the textures/ folder at runtime.
		visual          = "mesh",
		mesh            = "alpaca.gltf",
		textures        = { {col_tex} },

		-- SIZE NOTE:
		-- Blockbench's generic gltf exporter uses 1 pixel = 1 unit, whereas
		-- Luanti expects 1 block = 1 unit. Because 1 Minetest block = 16 pixels,
		-- the raw model is 16× too small. visual_size scales it back up.
		-- An alpaca stands ~1.0 m at shoulder, ~1.5 m to top of head.
		-- A Luanti player is 1.8 blocks tall, so {x=6,y=6} gives a realistic size.
		-- Increase to 7 or 8 if still too small; decrease to 5 if too large.
		visual_size     = {x = 6, y = 6},

		-- ROTATION NOTE:
		-- rotate=0  → model faces its natural direction (was: walking backwards)
		-- rotate=90 → 90° clockwise (sideways left)
		-- rotate=180→ model faces opposite (fixes the "walking backwards" issue)
		-- rotate=270→ 270° clockwise (sideways right)
		-- If it still looks sideways after 180, swap to 90 or 270.
		rotate          = 180,

		-- Sounds
		sounds = {
			random = "mobs_andes_alpaca_cough",
			replace = "mobs_andes_alpaca_eating",
		},
		makes_footstep_sound = true,

		-- -------------------------------------------------------
		-- Animation table — single merged gltf timeline
		--
		-- The gltf has one combined animation track (exported from
		-- Blockbench with all actions baked into a single timeline):
		--
		--   eat   :  0.0 → 1.0 s   (alpaca grazes / lowers head)
		--   walk  :  1.0 → 2.0 s
		--   run   :  2.5 → 3.5 s
		--   stand :  4.0 → 4.5 s
		--
		-- speed_normal = 1.0  (gltf uses real seconds, not frame numbers)
		-- -------------------------------------------------------
		animation = {
			speed_normal  = 1.0,

			-- stand: 4.0 → 4.5 s
			stand_start   = 4.0,
			stand_end     = 4.5,
			stand_speed   = 1.0,

			-- walk: 1.0 → 2.0 s
			walk_start    = 1.0,
			walk_end      = 2.0,
			walk_speed    = 1.0,

			-- run: 2.5 → 3.5 s
			run_start     = 2.5,
			run_end       = 3.5,
			run_speed     = 1.0,

			-- eat: 0.0 → 1.0 s
			-- NOTE: NOT registered as stand1.
			-- If stand1_start/stand1_end are defined the mobs API randomly
			-- picks them on EVERY set_animation("stand") call — including
			-- at the end of a runaway, making the alpaca look like it eats
			-- while still moving. Instead we use a custom "eat" name that
			-- is only ever triggered manually from on_replace.
			eat_start     = 0.0,
			eat_end       = 1.0,
			eat_speed     = 1.0,
		},

		-- Damage / environment
		water_damage  = 0.01,
		lava_damage   = 5,
		light_damage  = 0,

		-- Drop table
		drops = drops,

		-- -------------------------------------------------------
		-- Feeding / taming
		-- Alpacas follow player holding grass or wheat.
		-- Feed 8× to tame; they can also be bred.
		-- -------------------------------------------------------
		follow = {
			"farming:wheat",
			"default:grass_1",
			"farming:barley",
			"farming:oat",
			"farming:rye",
		},
		view_range = 10,

		-- -------------------------------------------------------
		-- Custom Step / Tick Logic (do_custom)
		--
		-- We use this hook to perform two critical runtime overrides:
		--  1. Overriding the entity instance's `set_animation` function
		--     so that we can lock the "eat" animation, and redirect
		--     "walk" to "run" during the "runaway" state.
		--  2. Decrementing the `eating_timer` every tick.
		-- -------------------------------------------------------
		do_custom = function(self, dtime, moveresult)
			-- One-time initialization of instance overrides
			if not self.custom_init_done then
				self.custom_init_done = true

				-- Capture the inherited set_animation function
				local orig_set_anim = self.set_animation
				self.set_animation = function(s, anim, force)
					-- Lock the eat animation until its timer expires
					if s.eating_timer and s.eating_timer > 0 then
						if anim ~= "eat" and force ~= true then
							return
						end
					end

					-- Map walk to run during runaway state
					if anim == "walk" and s.state == "runaway" then
						anim = "run"
					end

					orig_set_anim(s, anim, force)
				end
			end

			-- Tick the eating timer
			if self.eating_timer and self.eating_timer > 0 then
				self.eating_timer = self.eating_timer - dtime
				if self.eating_timer <= 0 then
					self.eating_timer = nil
				end
			end
		end,

		-- -------------------------------------------------------
		-- Grass eating (node replacement)
		-- The alpaca nibbles grass as it wanders, like cow/sheep.
		-- on_replace fires each time a grass node is consumed.
		-- We explicitly trigger the eat animation and freeze the alpaca.
		-- -------------------------------------------------------
		replace_rate  = 10,
		replace_what  = replace_what,

		on_replace = function(self, pos, oldnode, newnode)
			self.food = (self.food or 0) + 1
			-- Only graze visually when the alpaca is calm.
			-- Explicit whitelist: eat ONLY during stand or walk states.
			if self.state == "stand" or self.state == "walk" then
				self.eating_timer = 1.0  -- Lock animation for 1.0 second
				self.state = "stand"
				self:set_velocity(0)
				self:set_animation("eat", true)
			end
			if self.food >= 8 then
				self.food = 0
				-- Future: trigger wool-regrowth here if shearing is added
			end
		end,

		-- -------------------------------------------------------
		-- Run animation workaround
		-- The mobs API runaway state hardcodes set_animation("walk")
		-- and never calls "run", even when run_start is defined.
		-- We override on_punch to manually force "run" when the
		-- alpaca is hit and enters the runaway state.
		-- -------------------------------------------------------
		on_punch = function(self, hitter, tflp, tool_capabilities, dir)
			-- Let the default mobs punch handler run first
			mobs.mob_class.on_punch(self, hitter, tflp, tool_capabilities, dir)
			-- Then immediately override the animation to "run"
			if self.state == "runaway" then
				self:set_animation("run", true)
			end
		end,

		-- -------------------------------------------------------
		-- Right-click interaction
		-- Currently: feed/tame + protect + capture.
		-- Future: add shearing with scissors to yield wool without
		-- killing, similar to sheep.lua  (self.gotten pattern).
		-- -------------------------------------------------------
		on_rightclick = function(self, clicker)
			if mobs:feed_tame(self, clicker, 8, true, true) then return end
			if mobs:protect(self, clicker) then return end
			if mobs:capture_mob(self, clicker, 0, 5, 60, false, nil) then return end
		end,
	})

	-- ---------------------------------------------------------
	-- Spawn egg
	-- Uses mobs_alpaca_inv.png as the base icon.
	-- The wool texture is overlaid on top so each colour variant
	-- gets a unique-looking egg in the inventory.
	-- ---------------------------------------------------------
	local egg_overlay = col[5] or "mobs_alpaca_inv.png"
	mobs:register_egg(
		"mobs_andes:alpaca_" .. col_key,
		col_name,
		"wool_" .. col_key .. ".png^" .. egg_overlay,
		0
	)

	-- Compatibility alias (in case we rename later)
	-- mobs:alias_mob("mobs_andes:alpaca", "mobs_andes:alpaca_" .. col_key)

end  -- end colour loop

-- ============================================================
-- Spawning
--
-- Alpacas spawn in the same biomes as cows (grassy areas at
-- mid altitude), but a bit less frequently since they are exotic.
--
-- The spawn chance is deliberately the same as a cow (8000) so
-- an alpaca appears as often as a cow does: if cows spawn there,
-- alpacas can too. Adjust `chance` to taste.
--
-- To write a custom spawn file, create spawn.lua in this mod
-- directory — the init.lua will detect it and set
-- mobs.custom_spawn_andes = true to skip this block.
-- ============================================================
if not mobs.custom_spawn_andes then

	local spawn_nodes = {"default:dirt_with_grass"}

	-- Also spawn on ethereal green dirt if present
	if core.get_modpath("ethereal") then
		table.insert(spawn_nodes, "ethereal:green_dirt")
	end

	mobs:spawn({
		name          = "mobs_andes:alpaca_light_fawn",
		nodes         = spawn_nodes,
		neighbors     = {"group:grass"},
		min_light     = 14,
		interval      = 60,
		chance        = 8000,   -- same chance as cow; set higher to make rarer
		min_height    = 5,
		max_height    = 200,
		day_toggle    = true,
		on_spawn      = function(self, pos)
			local colors = {"light_fawn", "dark_fawn", "light_silver_grey"}
			local selected = colors[math.random(#colors)]
			if selected ~= "light_fawn" then
				self.object:remove()
				mobs:add_mob(pos, {name = "mobs_andes:alpaca_" .. selected})
			end
		end,
	})

end

-- ============================================================
-- END OF FILE
-- ============================================================
