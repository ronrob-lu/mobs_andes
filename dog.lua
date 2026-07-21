-- ============================================================
-- Dog - Canis lupus familiaris
-- A domesticated watchdog that follows its owner and attacks intruders.
-- ============================================================

local S = core.get_translator("mobs_andes")

local damage_enabled = core.settings:get_bool("enable_damage") ~= false

-- Helper: calculate distance between two positions
local function get_distance(a, b)
	if not a or not b then return 50 end
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Helper: check if a player is in peaceful mode
local function is_peaceful_player(player)
	local name = player:get_player_name()
	if not name then return false end
	if core.settings:get_bool("enable_peaceful_player") or core.check_player_privs(name, "peaceful_player") then
		return true
	end
	return false
end

-- Follow / food item list for compatibility
local dog_follow = {
	"group:food_meat_raw",
	"group:food_meat",
	"mobs:meat_raw",
	"mobs:meat",
	-- Voxelibre / Mineclonia compatibility
	"mcl_mobitems:beef",
	"mcl_mobitems:cooked_beef",
	"mcl_mobitems:mutton",
	"mcl_mobitems:cooked_mutton",
	"mcl_mobitems:porkchop",
	"mcl_mobitems:cooked_porkchop",
	"mcl_mobitems:chicken",
	"mcl_mobitems:cooked_chicken",
	"mcl_mobitems:rabbit",
	"mcl_mobitems:cooked_rabbit"
}

-- Helper: check if watchdog should attack the target
local function should_attack(self, target)
	-- Do not attack if dog is not tamed or has no owner
	if not self.tamed or not self.owner or self.owner == "" then
		return false
	end

	-- Do not attack itself
	if target == self.object then
		return false
	end

	-- Check player target
	if target:is_player() then
		local target_name = target:get_player_name()
		-- Do not attack owner
		if target_name == self.owner then
			return false
		end
		-- Do not attack if player is invisible or peaceful
		if mobs:is_invisible(self, target_name) or is_peaceful_player(target) then
			return false
		end
		-- Do not attack if damage is disabled or target is dead
		if not damage_enabled or target:get_hp() <= 0 then
			return false
		end
		return true
	end

	-- Check mob target
	local ent = target:get_luaentity()
	if ent then
		-- Do not attack other dogs
		if ent.name == self.name then
			return false
		end

		-- Is it a mob/monster/npc/animal?
		local is_mob = ent._cmi_is_mob or ent.type == "monster" or ent.type == "npc" or ent.type == "animal"
		if is_mob and ent.health and ent.health > 0 then
			-- Check if it shares the same owner
			if ent.owner and ent.owner ~= "" and ent.owner == self.owner then
				return false
			end
			return true
		end
	end

	return false
end

-- ============================================================
-- Register the Dog Mob
-- ============================================================
mobs:register_mob("mobs_andes:dog", {

	-- Basic type / behaviour
	type            = "animal",
	passive         = false,
	attack_type     = "dogfight",
	reach           = 2,
	damage          = 4,
	hp_min          = 15,
	hp_max          = 15,
	armor           = 100,

	-- Physics
	collisionbox    = {-0.3, 0.0, -0.3, 0.3, 0.75, 0.3}, -- Small size to traverse 1-block holes
	stepheight      = 0.6,
	walk_velocity   = 1.5,
	run_velocity    = 3.2,
	jump            = true,
	jump_height     = 4,
	pushable        = true,
	fear_height     = 3,

	-- Visuals
	visual          = "mesh",
	mesh            = "perro.gltf",
	textures        = { {"dogface.png"} },
	visual_size     = {x = 5.5, y = 5.5},
	rotate          = 0,

	-- Sounds
	sounds = {
		random  = "mobs_andes_dog-bark",
		attack  = "mobs_andes_dog-biting",
		damage  = "mobs_andes_dog-bark-grrr",
		death   = "mobs_andes_dog-bark-grrr",
		war_cry = "mobs_andes_dog-bark-grrr",
	},
	makes_footstep_sound = true,

	-- Animation range mapping
	animation = {
		speed_normal = 1.0,
		stand_start  = 1.0,
		stand_end    = 2.0,
		stand_speed  = 1.0,
		walk_start   = 0.0,
		walk_end     = 1.0,
		walk_speed   = 1.0,
		run_start    = 0.0,
		run_end      = 1.0,
		run_speed    = 1.8,
	},

	-- Damage / environment
	water_damage  = 0,
	lava_damage   = 5,
	light_damage  = 0,

	drops = {},

	follow = dog_follow,
	view_range = 35,

	-- -------------------------------------------------------
	-- Custom Step / Tick Logic (do_custom)
	-- -------------------------------------------------------
	do_custom = function(self, dtime, moveresult)
		-- One-time initialization of instance overrides
		if not self.custom_init_done then
			self.custom_init_done = true
			self.walk_velocity_default = self.walk_velocity or 1.5

			-- Capture/override set_animation to map walk to run at higher speeds
			local orig_set_anim = self.set_animation
			self.set_animation = function(s, anim, force)
				if anim == "walk" and s.walk_velocity == s.run_velocity then
					anim = "run"
				end
				orig_set_anim(s, anim, force)
			end

			-- Custom watchdog target selection overriding the default AI target scanning
			self.general_attack = function(s)
				if s.passive or s.state == "runaway" or s.state == "attack" or s:day_docile() then
					return
				end

				local s_pos = s.object:get_pos()
				if not s_pos then return end

				-- Scan for nearby targets inside view range
				local objs = core.get_objects_inside_radius(s_pos, s.view_range or 15)
				local closest_target = nil
				local closest_dist = (s.view_range or 15) + 1

				for _, obj in ipairs(objs) do
					if obj and should_attack(s, obj) then
						local t_pos = obj:get_pos()
						if t_pos then
							local dist = get_distance(t_pos, s_pos)
							if dist < closest_dist and s:line_of_sight(s_pos, t_pos) then
								closest_dist = dist
								closest_target = obj
							end
						end
					end
				end

				if closest_target then
					-- Play bark-grrr sound when targeting/starting attack
					core.sound_play("mobs_andes_dog-bark-grrr", {object = s.object, gain = 1.0, max_hear_distance = 15}, true)
					s:do_attack(closest_target, true)
				end
			end
		end

		-- Stop attacking if the target is no longer valid (e.g. gets tamed by owner)
		if self.state == "attack" and self.attack then
			if not should_attack(self, self.attack) then
				self:stop_attack()
			end
		end

		-- Periodically play growling sound when attacking
		if self.state == "attack" and self.attack then
			self.growl_timer = (self.growl_timer or 0) + dtime
			if self.growl_timer >= 3.0 then
				self.growl_timer = 0
				local target_pos = self.attack:get_pos()
				local self_pos = self.object:get_pos()
				if target_pos and self_pos and get_distance(target_pos, self_pos) < 10 then
					core.sound_play("mobs_andes_dog-bark-grrr", {object = self.object, gain = 1.0, max_hear_distance = 15}, true)
				end
			end
		else
			self.growl_timer = nil
		end

		-- Follow owner logic
		if self.tamed and self.owner and self.owner ~= "" then
			local owner_player = core.get_player_by_name(self.owner)
			if owner_player then
				local o_pos = owner_player:get_pos()
				local s_pos = self.object:get_pos()
				if o_pos and s_pos then
					local dist = get_distance(o_pos, s_pos)

					-- If the dog is not ordered to stay (not in a kennel) and not currently attacking
					if self.order ~= "stand" and self.state ~= "attack" then
						if dist > 30 then
							-- Owner is far away: catch up at run velocity
							self.following = owner_player
							self.walk_velocity = self.run_velocity
						elseif dist > 15 then
							-- Continue following if already following
							if self.following == owner_player then
								self.walk_velocity = self.run_velocity
							else
								self.following = nil
								self.walk_velocity = self.walk_velocity_default or 1.5
							end
						elseif dist <= 8 then
							-- Close enough: stop following and wander locally
							if self.following == owner_player then
								self.following = nil
								self:set_velocity(0)
								self:set_animation("stand")
							end
							self.walk_velocity = self.walk_velocity_default or 1.5
						else
							self.walk_velocity = self.walk_velocity_default or 1.5
						end
					end
				end
			else
				-- Owner went offline
				if self.following and self.following:is_player() then
					self.following = nil
				end
			end
		end
	end,

	-- -------------------------------------------------------
	-- Right-click interaction
	-- -------------------------------------------------------
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end

		local item = clicker:get_wielded_item()
		local item_name = item:get_name()
		local player_name = clicker:get_player_name()

		-- Check if player is holding a valid meat item
		local is_food = false
		local is_raw = false
		for _, name in ipairs(dog_follow) do
			if item_name == name or core.get_item_group(item_name, "food_meat_raw") > 0 or core.get_item_group(item_name, "food_meat") > 0 then
				is_food = true
				-- Detect if raw meat (required for taming)
				if name:find("raw") or item_name:find("raw") or item_name == "mobs:meat_raw" or item_name == "mcl_mobitems:beef" or item_name == "mcl_mobitems:mutton" or item_name == "mcl_mobitems:porkchop" or item_name == "mcl_mobitems:chicken" or item_name == "mcl_mobitems:rabbit" then
					is_raw = true
				end
				break
			end
		end

		if is_food then
			-- Taming: requires 4 raw meats
			if not self.tamed then
				if is_raw then
					-- Take food item
					if not mobs.is_creative(player_name) then
						item:take_item()
						clicker:set_wielded_item(item)
					end

					self.food = (self.food or 0) + 1
					-- Play a random bark when fed
					core.sound_play("mobs_andes_dog-bark", {object = self.object, gain = 1.0, max_hear_distance = 10}, true)

					if self.food >= 4 then
						self.food = 0
						self.tamed = true
						self.owner = player_name
						self.static_save = true
						self.order = "follow"
						self:update_tag()
						core.chat_send_player(player_name, S("Dog has been tamed!"))
					end
					return
				else
					return
				end
			else
				-- Already tamed: eating meat heals and increases Max HP (up to 30)
				local prop = self.object:get_properties()
				local current_max = prop.hp_max or 15

				if self.health < current_max or current_max < 30 then
					-- Take food item
					if not mobs.is_creative(player_name) then
						item:take_item()
						clicker:set_wielded_item(item)
					end

					-- Grow Max HP
					if current_max < 30 then
						current_max = math.min(current_max + 2, 30)
						self.hp_max = current_max
						self.object:set_properties({hp_max = current_max})
					end

					-- Heal by 4 HP
					self.health = math.min(self.health + 4, current_max)
					self.object:set_hp(self.health)

					-- Play bark sound
					core.sound_play("mobs_andes_dog-bark", {object = self.object, gain = 1.0, max_hear_distance = 10}, true)
					self:update_tag()
					return
				end
			end
		end

		-- Standard protection and capture rules
		if mobs:protect(self, clicker) then return end
		if mobs:capture_mob(self, clicker, 0, 5, 80, false, nil) then return end

		-- Right click by owner toggles stay/follow states (staying in its kennel)
		if self.owner and self.owner == player_name then
			if self.order == "stand" then
				self.order = "follow"
				core.chat_send_player(player_name, S("Dog is now following you."))
			else
				self.order = "stand"
				self.state = "stand"
				self.object:set_velocity({x = 0, y = 0, z = 0})
				self:set_animation("stand")
				core.chat_send_player(player_name, S("Dog is now staying here."))
			end
		end
	end
})

-- ============================================================
-- Spawn Egg
-- ============================================================
mobs:register_egg(
	"mobs_andes:dog",
	S("Dog"),
	"dogface.png",
	1
)

-- ============================================================
-- Spawning configuration
-- ============================================================
if not mobs.custom_spawn_andes then

	local spawn_nodes = {}

	if core.get_modpath("default") then
		table.insert(spawn_nodes, "default:dirt_with_grass")
	end
	if core.get_modpath("mcl_core") then
		table.insert(spawn_nodes, "mcl_core:dirt_with_grass")
	end
	if core.get_modpath("ethereal") then
		table.insert(spawn_nodes, "ethereal:green_dirt")
	end

	mobs:spawn({
		name          = "mobs_andes:dog",
		nodes         = spawn_nodes,
		neighbors     = {"group:grass"},
		min_light     = 14,
		interval      = 60,
		chance        = 9000,
		min_height    = 5,
		max_height    = 150,
		day_toggle    = true,
	})

end

-- ============================================================
-- END OF FILE
-- ============================================================
