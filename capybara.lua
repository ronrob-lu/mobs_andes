-- ============================================================
-- Capybara - Hydrochoerus hydrochaeris
-- The largest extant rodent in the world, native to South America.
-- Author: ronrob-lu
-- ============================================================

local S = core.get_translator and core.get_translator("mobs_andes") or function(s) return s end

-- Check setting for eating grass block
local eat_gb = core.settings:get_bool("mobs_andes.eat_grass_block")

-- Plants capybara eats naturally in the wild (with reach = 1 for adjacent node checking)
local replace_what = {
	{"default:junglegrass", "air", 0, 1},
	{"default:grass_1", "air", 0, 1},
	{"default:grass_2", "air", 0, 1},
	{"default:grass_3", "air", 0, 1},
	{"default:grass_4", "air", 0, 1},
	{"default:grass_5", "air", 0, 1},
	{"default:papyrus", "air", 0, 1},
	{"mcl_flowers:tallgrass", "air", 0, 1},
	{"mcl_core:papyrus", "air", 0, 1},
	{"mcl_core:reeds", "air", 0, 1},
}

if eat_gb then
	table.insert(replace_what, {"default:dirt_with_grass", "default:dirt", -1, 1})
	table.insert(replace_what, {"mcl_core:dirt_with_grass", "mcl_core:dirt", -1, 1})
end

-- Capybara Mob Registration
mobs:register_mob("mobs_andes:capybara", {
	type = "animal",
	passive = true,
	hp_min = 10,
	hp_max = 18,
	armor = 100,

	-- Collision box Y offset calibrated so standing feet rest flat on ground nodes (ymin = 0.0 prevents ground clipping/suffocation)
	collisionbox = {-0.24, 0.0, -0.24, 0.24, 0.48, 0.24},

	-- Visual model and 60% scaling
	visual = "mesh",
	mesh = "capybara.gltf",
	textures = {{"texture_capybara.png"}},
	visual_size = {x = 6.0, y = 6.0},

	-- Items capybaras follow and eat from player's hand
	follow = {
		"group:grass", "default:junglegrass", "default:grass_1", "default:grass_2",
		"default:grass_3", "default:papyrus", "default:apple", "mcl_flowers:tallgrass",
		"mcl_core:apple", "group:flora", "group:food"
	},

	-- Sounds
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_cow"
	},

	-- Velocities
	walk_velocity = 0.8,
	run_velocity = 1.6,
	jump = true,
	jump_height = 4,

	-- Drops nothing on death
	drops = {},

	-- Standard mob despawn lifetimer (180s)
	lifetimer = 180,

	-- Damage & Suffocation
	suffocation = 0,
	water_damage = 0,
	lava_damage = 4,
	light_damage = 0,

	-- Native Mobs Redo liquid buoyancy (floats naturally without CPU packet spam)
	floats = 1,

	-- GLTF Animation Table (Padded timeline ranges to prevent boundary keyframe flickers)
	animation = {
		speed_normal = 1,
		stand_start = 0.00, stand_end = 0.95, stand_speed = 1,  -- Stand / Idle (0.00s - 0.95s)
		walk_start = 1.05,  walk_end = 1.95,  walk_speed = 1,   -- Walk (1.05s - 1.95s)
		run_start = 1.05,   run_end = 1.95,   run_speed = 1,    -- Run (1.05s - 1.95s)
		fly_start = 2.05,   fly_end = 2.95,   fly_speed = 1,    -- Swim in water (2.05s - 2.95s)
		lay_start = 3.05,   lay_end = 3.95,   lay_speed = 1,    -- Chill / Lay (3.05s - 3.95s)
	},

	-- Custom animation state machine & chill logic (Protected against Mobs Redo interference & multi-mob shared table corruption)
	do_custom = function(self, dtime)
		local pos = self.object and self.object:get_pos()
		if not pos then return end

		-- Ensure each mob instance has its own unique animation table copy (prevents multi-mob shared table corruption)
		if not self._anim_cloned then
			self._anim_cloned = true
			if self.animation then
				local anim_copy = {}
				for k, v in pairs(self.animation) do
					anim_copy[k] = v
				end
				self.animation = anim_copy
			end
		end

		-- Hook set_animation on entity instance to strictly block Mobs Redo do_states/flight_check interference
		if not self._anim_hooked then
			self._anim_hooked = true
			local orig_set_anim = self.set_animation
			self.set_animation = function(mob_self, anim, force)
				if force ~= "capybara_custom" and force ~= true and not mob_self._forced_anim then
					return
				end
				local cur = mob_self.animation_current or (mob_self.animation and mob_self.animation.current) or ""
				if cur == anim and force ~= "capybara_force" then
					return
				end
				mob_self.animation_current = anim
				if mob_self.animation then
					mob_self.animation.current = anim
				end
				return orig_set_anim(mob_self, anim, true)
			end
		end

		local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
		local h_speed = math.sqrt(vel.x * vel.x + vel.z * vel.z)
		local current_anim = self.animation_current or (self.animation and self.animation.current) or ""

		-- Water level check:
		local node_at_body = core.get_node({x = pos.x, y = pos.y + 0.05, z = pos.z}).name
		local body_in_water = core.get_item_group(node_at_body, "water") > 0
		self._in_water = body_in_water

		-- 1. WATER STATE: If in water, float naturally submerged and swim! (2.05s - 2.95s: fly)
		if body_in_water then
			self._chill_timer = 0
			self._is_chilling = false

			-- Dampen upward floating velocity slightly so body stays submerged in water
			if vel.y > 0.05 then
				self.object:set_velocity({x = vel.x, y = 0.05, z = vel.z})
			end

			if current_anim ~= "fly" then
				self:set_animation("fly", "capybara_custom")
			end

		-- 2. MOVING STATE: If moving on land, always walk! (1.05s - 1.95s: walk)
		elseif h_speed > 0.08 then
			self._chill_timer = 0
			self._is_chilling = false

			if current_anim ~= "walk" then
				self:set_animation("walk", "capybara_custom")
			end

		-- 3. STATIONARY ON LAND STATE: Standing still on land (h_speed <= 0.08)
		else
			if self._is_chilling then
				self._chill_duration = (self._chill_duration or 0) + dtime

				-- Maintain lay animation smoothly (3.05s - 3.95s: lay)
				if current_anim ~= "lay" then
					self:set_animation("lay", "capybara_custom")
				end

				-- After 20 seconds of chilling, finish break and stand up
				if self._chill_duration >= 20.0 then
					self._is_chilling = false
					self._chill_timer = 0
					self._chill_duration = 0
					if current_anim ~= "stand" then
						self:set_animation("stand", "capybara_custom")
					end
				end
			else
				self._chill_timer = (self._chill_timer or 0) + dtime

				if self._chill_timer >= 2.5 then
					-- Transition to chilling
					self._is_chilling = true
					self._chill_duration = 0
					if current_anim ~= "lay" then
						self:set_animation("lay", "capybara_custom")
					end
				else
					if current_anim ~= "stand" then
						self:set_animation("stand", "capybara_custom")
					end
				end
			end
		end
	end,

	-- Natural grazing (eats grass & plants every ~2-3 seconds)
	replace_rate = 2,
	replace_what = replace_what,

	-- Autonomous grazing callback (heals & breeds when capybaras eat grass on their own)
	on_replace = function(self, pos, oldnode, newnode)
		if self.object and self.object.get_hp then
			local hp = self.object:get_hp()
			if hp and self.hp_max and hp < self.hp_max then
				self.object:set_hp(math.min(self.hp_max, hp + 2))
			end
		end

		-- Increase food count from natural self-grazing
		self.food = (self.food or 0) + 1
		if self.food >= 4 then
			self.food = 0
			if not self.hornytimer or self.hornytimer == 0 then
				self.horny = true
			end
		end
	end,

	-- Safe breeding callback (elevates baby spawn position so it never clips ground nodes)
	on_breed = function(self, parent2)
		local pos = self.object and self.object:get_pos()
		if pos then
			pos.y = pos.y + 0.5
		end
	end,

	-- Stays near wooden structures when near water
	stay_near = {
		{"group:wood", "group:fence", "default:wood", "mcl_core:wood"},
		10
	},
	fear_height = 3,
	view_range = 8,

	-- Right click to feed (with breeding enabled), tame, or capture
	on_rightclick = function(self, clicker)
		if mobs:feed_tame(self, clicker, 4, true, true) then return end
		if mobs:protect(self, clicker) then return end
		if mobs:capture_mob(self, clicker, 0, 5, 50, false, nil) then return end
	end,
})

-- Register Spawn Egg
mobs:register_egg("mobs_andes:capybara", S("Capybara"), "mobs_capybara_inv.png", 0)

-- Automatic natural world spawning ENABLED
if not mobs.custom_spawn_andes then
	local spawn_on = {
		"default:dirt_with_grass", "default:dirt_with_jungle_grass",
		"default:dirt", "mcl_core:dirt_with_grass", "mcl_core:dirt"
	}

	if core.get_modpath("ethereal") then
		table.insert(spawn_on, "ethereal:green_dirt")
		table.insert(spawn_on, "ethereal:prairie_dirt")
		table.insert(spawn_on, "ethereal:jungle_dirt")
	end

	local spawn_near = {
		"default:water_source", "default:water_flowing",
		"mcl_core:water_source", "mcl_core:water_flowing", "group:water"
	}

	mobs:spawn({
		name = "mobs_andes:capybara",
		nodes = spawn_on,
		neighbors = spawn_near,
		min_light = 12,
		interval = 60,
		chance = 8000,
		min_height = 0,
		max_height = 200,
		day_toggle = true
	})
end

-- Compatibility Aliases
mobs:alias_mob("mob_capybara:capybara", "mobs_andes:capybara")
mobs:alias_mob("mobs:capybara", "mobs_andes:capybara")
mobs:alias_mob("mobs_animal:capybara", "mobs_andes:capybara")

core.register_alias("mob_capybara:capybara", "mobs_andes:capybara")
core.register_alias("mob_capybara:capybara_set", "mobs_andes:capybara_set")
core.register_alias("mobs:capybara", "mobs_andes:capybara")
core.register_alias("mobs:capybara_set", "mobs_andes:capybara_set")
core.register_alias("mobs_animal:capybara", "mobs_andes:capybara")
core.register_alias("mobs_animal:capybara_set", "mobs_andes:capybara_set")

----------------------------------------------------
-- Chat Commands (/count_capybara, /remove_capybara)
----------------------------------------------------

local function count_capybara_func(name, param)
	local count = 0
	local positions = {}
	for _, obj in pairs(core.luaentities) do
		if (obj.name == "mobs_andes:capybara" or obj.name == "mob_capybara:capybara") and obj.object then
			count = count + 1
			local pos = obj.object:get_pos()
			if pos then
				table.insert(positions, string.format("(%.1f, %.1f, %.1f)", pos.x, pos.y, pos.z))
			end
		end
	end
	local pos_str = #positions > 0 and (" Positions: " .. table.concat(positions, ", ")) or ""
	return true, string.format("[Capybara] Counted %d capybara entity/entities in loaded world.%s", count, pos_str)
end

core.register_chatcommand("count_capybara", {
	description = "Count all capybaras in the loaded world and list their positions",
	func = count_capybara_func
})

core.register_chatcommand("capybara_count", {
	description = "Count all capybaras in the loaded world",
	func = count_capybara_func
})

core.register_chatcommand("count_capybaras", {
	description = "Count all capybaras in the loaded world",
	func = count_capybara_func
})

core.register_chatcommand("remove_capybara", {
	description = "Remove all capybaras from the loaded world",
	func = function(name, param)
		local count = 0
		for _, obj in pairs(core.luaentities) do
			if obj.name == "mobs_andes:capybara" or obj.name == "mob_capybara:capybara" then
				obj.object:remove()
				count = count + 1
			end
		end
		return true, "[Capybara] Removed " .. count .. " capybara entities from world."
	end
})
