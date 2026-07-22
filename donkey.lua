-- ============================================================
-- Donkey - Equus asinus
-- A domesticated member of the horse family (Equidae).
-- ============================================================

local S = core.get_translator("mobs_andes")

-- Safe ObjectRef metatable patch to prevent Luanti crashes on player detach (when mobs_redo passes 2D visual_size)
local orig_set_properties = nil
local function patch_objectref(obj)
	if not obj then return end
	local meta = getmetatable(obj)
	if meta and meta.__index and type(meta.__index) == "table" and not meta.__index.set_properties_overridden then
		orig_set_properties = meta.__index.set_properties
		if orig_set_properties then
			meta.__index.set_properties = function(self, props)
				if props and props.visual_size and not props.visual_size.z then
					props.visual_size.z = props.visual_size.x or 1
				end
				return orig_set_properties(self, props)
			end
			meta.__index.set_properties_overridden = true
		end
	end
end

core.register_on_joinplayer(function(player)
	patch_objectref(player)
end)

core.register_on_dieplayer(function(player)
	player:set_properties({visual_size = {x = 1, y = 1, z = 1}})
end)

core.register_on_respawnplayer(function(player)
	player:set_properties({visual_size = {x = 1, y = 1, z = 1}})
end)

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
-- Riding logic (workaround for mobs_redo rotate inversion bug)
-- ============================================================
local abs, cos, sin, sqrt, pi = math.abs, math.cos, math.sin, math.sqrt, math.pi

local function get_sign(i)
	if not i or i == 0 then return 0 end
	return i / abs(i)
end

local function get_velocity(v, yaw, y)
	local x = -sin(yaw) * v
	local z =  cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return sqrt(v.x * v.x + v.z * v.z)
end

local function node_is(entity)
	if not entity.standing_on then return "other" end
	if entity.standing_on == "air" then return "air" end
	local def = core.registered_nodes[entity.standing_on]
	if not def then return "other" end
	if def.groups and def.groups.lava then return "lava" end
	if def.groups and def.groups.liquid then return "liquid" end
	if def.groups and def.groups.walkable then return "walkable" end
	return "other"
end

local function drive_donkey(entity, moving_anim, stand_anim, dtime)
	local yaw = entity.object:get_yaw() or 0
	local rot_view = 0

	if entity.player_rotation and entity.player_rotation.y == 90 then
		rot_view = pi / 2
	end

	local acce_y = 0
	local velo = entity.object:get_velocity()
	if not velo then return end

	entity.v = get_v(velo) * get_sign(entity.v)

	-- process controls
	if entity.driver then
		local ctrl = entity.driver:get_player_control()

		if ctrl.up then -- move forwards
			entity.v = entity.v + entity.accel * dtime
		elseif ctrl.down then -- move backwards
			if entity.max_speed_reverse == 0 and entity.v == 0 then return end
			entity.v = entity.v - entity.accel * dtime
		end

		-- mob rotation
		local horz = entity.driver:get_look_horizontal() or 0
		entity.object:set_yaw(horz - entity.rotate)

		if ctrl.jump then -- jump (only when standing on solid surface)
			if velo.y == 0
			and entity.standing_on ~= "air" and entity.standing_on ~= "ignore"
			and (not entity.standing_on or core.get_item_group(entity.standing_on, "liquid") == 0) then
				velo.y = velo.y + entity.jump_height
				acce_y = acce_y + (acce_y * 3) + 1
			end
		end
	end

	local ni = node_is(entity)

	-- if not moving then set animation and return
	if entity.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		if stand_anim then entity:set_animation(stand_anim) end
		return
	end

	-- set moving animation
	if moving_anim then entity:set_animation(moving_anim) end

	-- Stop!
	local s = get_sign(entity.v)
	entity.v = entity.v - 0.02 * s

	if s ~= get_sign(entity.v) then
		entity.object:set_velocity({x = 0, y = 0, z = 0})
		entity.v = 0
		return
	end

	-- enforce speed limit forward and reverse
	if entity.v > entity.max_speed_forward then
		entity.v = entity.max_speed_forward
	elseif entity.v < -entity.max_speed_reverse then
		entity.v = -entity.max_speed_reverse
	end

	-- Set position, velocity and acceleration
	local p = entity.object:get_pos()
	if not p then return end

	local new_acce = {x = 0, y = entity.fall_speed or -10, z = 0}
	p.y = p.y - 0.5

	local v = entity.v

	if ni == "liquid" or ni == "lava" then
		v = v * 0.25
	end

	local new_velo = get_velocity(v, (entity.object:get_yaw() or 0) + entity.rotate - rot_view, velo.y)

	new_acce.y = new_acce.y + acce_y

	entity.object:set_velocity(new_velo)
	entity.object:set_acceleration(new_acce)

	entity.v2 = v
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
	sounds = {
		random = "mobs_andes_donkey_random",
		damage = "mobs_andes_donkey_scream",
		death = "mobs_andes_donkey_scream",
		replace = "default_dig_crumbly",
	},
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
			patch_objectref(self.object)

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

		-- Set required driving values unconditionally on every tick to override any stale database/staticdata
		self.max_speed_forward = 3.5
		self.max_speed_reverse = 1.0
		self.accel = 3.5
		-- Adjusted for donkey scale and model UV (Seat raised and shifted further back)
		self.driver_attach_at = {x = 0.05, y = 1.65, z = 0.2}
		self.driver_eye_offset = {x = 0, y = 9, z = 0}
		self.driver_scale = {x = 0.16, y = 0.16, z = 0.16}
		self.player_rotation = {x = 0, y = 180, z = 0}

		-- Set stepheight dynamically based on saddled status on change
		if self.stepheight_applied ~= self.saddle then
			self.stepheight_applied = self.saddle
			if self.saddle then
				self.object:set_properties({stepheight = 1.1})
			else
				self.object:set_properties({stepheight = 0.6})
			end
		end

		-- Check if the driver has detached (e.g. via sneak key)
		if self.driver then
			local attached = self.driver:get_attach()
			if not attached or attached ~= self.object then
				self.driver = nil
				self.autopilot = nil
			else
				-- Read Special key (E) to toggle autopilot
				local ctrl = self.driver:get_player_control()
				local aux1_pressed = ctrl.aux1
				if aux1_pressed and not self.prev_aux1_pressed then
					self.autopilot = not self.autopilot
					if self.autopilot then
						core.chat_send_player(self.driver:get_player_name(), S("Donkey autopilot: ENABLED (W/S/A/D to manual control)"))
					else
						core.chat_send_player(self.driver:get_player_name(), S("Donkey autopilot: DISABLED"))
					end
				end
				self.prev_aux1_pressed = aux1_pressed

				-- If player presses manual control keys, disable autopilot
				if ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump then
					if self.autopilot then
						self.autopilot = false
						core.chat_send_player(self.driver:get_player_name(), S("Donkey autopilot: DISABLED (Manual Override)"))
					end
				end

				if self.autopilot then
					-- Let the default AI pathfinding run (do not call drive_donkey or return false)
				else
					drive_donkey(self, "walk", "stand", dtime)
					return false -- Skip rest of mob functions (AI) while manual driving
				end
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

		-- Retrieve saddle if sneak-punched by non-driver player
		if hitter and hitter:is_player() and hitter ~= self.driver and hitter:get_player_control().sneak then
			if self.saddle then
				self.saddle = false
				self.object:set_properties({stepheight = 0.6})
				local pos = self.object:get_pos()
				if pos then
					minetest.add_item(pos, "mobs:saddle")
				end
			end
		end
	end,

	-- -------------------------------------------------------
	-- Right-click interaction
	-- -------------------------------------------------------
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end

		-- Detach player if already riding
		if self.driver and clicker == self.driver then
			mobs.detach(clicker, {x = 1, y = 0, z = 1})
			self:set_animation("stand")
			self.autopilot = nil
			return
		end

		-- Feed/tame/heal or protect
		if mobs:feed_tame(self, clicker, 8, true, true) then return end
		if mobs:protect(self, clicker) then return end

		local item = clicker:get_wielded_item():get_name()

		-- Equipping saddle (does not require taming!)
		if item == "mobs:saddle" and not self.saddle and not self.child then
			self.saddle = true
			self.object:set_properties({stepheight = 1.1})
			local inv = clicker:get_inventory()
			if inv then
				inv:remove_item("main", "mobs:saddle")
			end
			core.sound_play("default_place_node", {pos = self.object:get_pos()}, true)
			return
		end

		-- Capture mob using lasso / net
		if mobs:capture_mob(self, clicker, 0, 5, 60, false, nil) then return end

		-- Mount donkey if saddled (does not require taming!)
		if self.saddle and not self.child then
			mobs.attach(self, clicker)
		end
	end,

	-- -------------------------------------------------------
	-- Handle death: detach driver and drop saddle
	-- -------------------------------------------------------
	on_die = function(self, pos)
		if self.driver then
			mobs.detach(self.driver, {x = 1, y = 0, z = 1})
			self.autopilot = nil
		end
		if self.saddle then
			minetest.add_item(pos, "mobs:saddle")
		end
	end,
})

-- ============================================================
-- Spawn egg
-- ============================================================
mobs:register_egg(
	"mobs_andes:donkey",
	S("Donkey"),
	"mobs_donkey_inv.png",
	0
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
