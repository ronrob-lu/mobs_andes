-- ============================================================
-- Donkey - Equus asinus
-- A domesticated member of the horse family (Equidae).
-- ============================================================

local S = core.get_translator("mobs_andes")

-- ============================================================
-- Grass eating config - mirrors the alpaca behaviour
-- ============================================================
local eat_gb = core.settings:get_bool("mobs_andes.eat_grass_block")

-- replace_what: { {node_to_replace, replace_with, y_offset} }
local replace_what = { {"group:grass", "air", 0} }

if eat_gb then
	table.insert(replace_what, {"default:dirt_with_grass", "default:dirt", -1})
end

-- ============================================================
-- Register the Donkey Mob
-- ============================================================
mobs:register_mob("mobs_andes:donkey", {

	-- Basic type / behaviour
	type            = "animal",
	passive         = true,   -- flees instead of fighting back
	runaway         = true,
	hp_min          = 10,
	hp_max          = 22,
	armor           = 100,

	-- Physics
	collisionbox    = {-0.4, -0.01, -0.4, 0.4, 1.6, 0.4},
	stepheight      = 0.6,
	walk_velocity   = 1.2,
	run_velocity    = 3.0,
	jump            = true,
	jump_height     = 4,
	pushable        = true,
	fear_height     = 3,

	-- Visuals
	visual          = "mesh",
	mesh            = "donkey.gltf",
	textures        = { {"texture_donkey.png"} },
	visual_size     = {x = 6, y = 6},
	rotate          = 180,

	-- Sounds
	sounds = {},
	makes_footstep_sound = true,

	-- -------------------------------------------------------
	-- Animation table — single merged gltf timeline
	--
	--   eat   :  0.0 → 1.0 s
	--   walk  :  1.0 → 2.0 s
	--   run   :  2.0 → 3.0 s
	--   stand :  3.0 → 4.0 s
	--
	-- speed_normal = 1.0
	-- -------------------------------------------------------
	animation = {
		speed_normal  = 1.0,

		-- stand: 3.0 → 4.0 s
		stand_start   = 3.0,
		stand_end     = 4.0,
		stand_speed   = 1.0,

		-- walk: 1.0 → 2.0 s
		walk_start    = 1.0,
		walk_end      = 2.0,
		walk_speed    = 1.0,

		-- run: 2.0 → 3.0 s
		run_start     = 2.0,
		run_end       = 3.0,
		run_speed     = 1.0,

		-- eat: 0.0 → 1.0 s
		eat_start     = 0.0,
		eat_end       = 1.0,
		eat_speed     = 1.0,
	},

	-- Damage / environment
	water_damage  = 0.01,
	lava_damage   = 5,
	light_damage  = 0,

	-- Drop table (killed donkey does not bring meat or wool)
	drops = {},

	-- -------------------------------------------------------
	-- Feeding / taming
	-- Donkeys follow player holding grass or wheat.
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
	-- -------------------------------------------------------
	replace_rate  = 10,
	replace_what  = replace_what,

	on_replace = function(self, pos, oldnode, newnode)
		self.food = (self.food or 0) + 1
		-- Only graze visually when the donkey is calm.
		if self.state == "stand" or self.state == "walk" then
			self.eating_timer = 1.0  -- Lock animation for 1.0 second
			self.state = "stand"
			self:set_velocity(0)
			self:set_animation("eat", true)
		end
		if self.food >= 8 then
			self.food = 0
		end
	end,

	-- -------------------------------------------------------
	-- Run animation workaround
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
	-- -------------------------------------------------------
	on_rightclick = function(self, clicker)
		if mobs:feed_tame(self, clicker, 8, true, true) then return end
		if mobs:protect(self, clicker) then return end
		if mobs:capture_mob(self, clicker, 0, 5, 60, false, nil) then return end
	end,
})

-- ============================================================
-- Spawn egg
-- ============================================================
mobs:register_egg(
	"mobs_andes:donkey",
	S("Donkey"),
	"mobs_donkey_inv.png"
)

-- ============================================================
-- Spawning
-- ============================================================
if not mobs.custom_spawn_andes then

	local spawn_nodes = {"default:dirt_with_grass"}

	-- Also spawn on ethereal green dirt if present
	if core.get_modpath("ethereal") then
		table.insert(spawn_nodes, "ethereal:green_dirt")
	end

	mobs:spawn({
		name          = "mobs_andes:donkey",
		nodes         = spawn_nodes,
		neighbors     = {"group:grass"},
		min_light     = 14,
		interval      = 60,
		chance        = 9000,   -- slightly rarer than alpaca
		min_height    = 5,
		max_height    = 200,
		day_toggle    = true,
	})

end

-- ============================================================
-- END OF FILE
-- ============================================================
