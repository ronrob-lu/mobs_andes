
-- Mobs Andes - Animals from the Andes Region
-- Main init file
--
-- This mod adds Andean wildlife to your Luanti/Minetest world.
-- It only depends on 'mobs' (mobs_redo) and is structured so
-- additional animals can be added easily.

local path = core.get_modpath(core.get_current_modname()) .. "/"

-- Check for custom mob spawn file (allows server admins to override spawning)
local input = io.open(path .. "spawn.lua", "r")
if input then
	mobs.custom_spawn_andes = true
	input:close()
	input = nil
end

-- ============================================================
-- Helper: load an animal file unless disabled in settings
-- To disable an animal add to minetest.conf:
--   mobs_andes.<name> = false
-- ============================================================
local function load_animal(mob)
	if core.settings:get_bool("mobs_andes." .. mob) == false then
		print("[Mobs_Andes] " .. mob .. " disabled via settings.")
		return
	end
	dofile(path .. mob .. ".lua")
end

-- ============================================================
-- Animals
-- Add new animals here as they are created, e.g.:
--   load_animal("llama")
--   load_animal("vicuna")
--   load_animal("guanaco")
-- ============================================================
load_animal("alpaca")
load_animal("donkey")
load_animal("dog")

-- Load custom spawning override if found
if mobs.custom_spawn_andes then
	dofile(path .. "spawn.lua")
end

print("[MOD] Mobs Andes loaded")
