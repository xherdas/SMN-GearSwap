-- ===================================================================================================================
--  SMN - entry point (rename this file to <YourCharacter>_SMN.lua)
--  Configuration and sets: SMN-USER/user.lua      Logic: SMN-LIB/
--  In-game help: //gs c help
--
--  Credits
--    Pergatory      - the SMN GearSwap this is built on: sets, set-selection logic and GearSwap hooks
--                     (precast / midcast / aftercast / pet_midcast, idle set syntax, BP categories)
--                     http://pastebin.com/u/pergatory
--    PUP GearSwap   - PUP.lua / PUP-LIB / PUP-USER: most of the HUD, the logic / config split and the keybind
--                     system come from it. Originally created by Faloun; programmers Arrchie, Kuroganashi,
--                     Byrne, Tuna; contributors Xilkk, Byrne, Blackhalo714
--    Mote           - Modes.lua (M{} modes), from the Mote GearSwap libraries
--    Papesse (Carbuncle) - Avatar's Favor 670-skill tier compromise (see user.lua)
--    Thaylia        - smnSkill (merged in as SMN-LIB/smn-skill.lua), automation engine, Ward / Rage /
--                     Conduit / Treasure Hunter / lag modules, HUD
-- ===================================================================================================================
-- Per-character config: SMN-USER/<Character>.lua if it exists (several SMNs on one install), otherwise
-- SMN-USER/user.lua
local function smn_user_file()
	local p = windower.ffxi.get_player()
	if p and p.name then
		local f = io.open(windower.addon_path .. 'data/SMN-USER/' .. p.name .. '.lua', 'r')
		if f then
			f:close()
			return 'SMN-USER/' .. p.name .. '.lua'
		end
	end
	return 'SMN-USER/user.lua'
end
SMN_USER_FILE = smn_user_file()
include(SMN_USER_FILE)
include('SMN-LIB/smn-data.lua')
include('SMN-LIB/smn-modes.lua')
include('SMN-LIB/smn-main.lua')
include('SMN-LIB/smn-th.lua')
include('SMN-LIB/smn-keybinds.lua')
include('SMN-LIB/smn-gui.lua')
include('SMN-LIB/smn-commands.lua')
include('SMN-LIB/smn-runner.lua')
include('SMN-LIB/smn-lag.lua')
include('SMN-LIB/smn-skill.lua')
include('SMN-LIB/smn-ward.lua')
include('SMN-LIB/smn-rage.lua')
include('SMN-LIB/smn-avatar.lua')
-- Optional debug tools (not in the release package): loaded last, only if the file is there
local dbg = io.open(windower.addon_path .. 'data/SMN-LIB/smn-debug.lua', 'r')
if dbg then
	dbg:close()
	include('SMN-LIB/smn-debug.lua')
end

function get_sets()
	enable(unpack(SMN_ALL_SLOTS))
	smn_setup_modes()
	user_sets()
	-- SMN_DEFAULTS.CustomMode = 'Opashoro': weapons equipped and locked from the start
	if state.CustomMode.value == 'Opashoro' then smn_sync_weapons('CustomMode', 'None') end
	smn_apply_keybinds(SMN_KEYBINDS)
	smn_ward_setup()
	smn_setup_hud()
	-- Macro book and page on load (SMN_MACROS in user.lua)
	if SMN_MACROS and SMN_MACROS.book then
		send_command(('wait 1;input /macro book %d;wait .2;input /macro set %d'):format(SMN_MACROS.book, SMN_MACROS.set or 1))
	end
	smn_lockstyle()   -- SMN_LOCKSTYLE: sent once the game is ready
end

function file_unload()
	-- Stop the running loop: otherwise it would keep going with the old file after gs reload / gs load
	smn_auto_stop('reload')
	smn_lockstyle_stop()
	smn_unbind_keys()
	enable(unpack(SMN_ALL_SLOTS))
end
