-- ===================================================================================================================
--  SMN-LIB: commands (gs c ...)
--  gs c help lists the keys and macro commands. Also: gs c <IdleMode> (gs c DT), gs c <toggle> (gs c AccMode),
--  gs c MeteorStrike3 (merits, until reload), gs c cycle | cycleback | toggle | set <Mode> [value],
--  gs c hub avatar|recasts|rage|wards|auto|modes|options|all|keybinds|lite.
--  Internal (sent by the file itself): gs c EquipBP <pact>, gs c idle.
-- ===================================================================================================================

function smn_echo(text)
    add_to_chat(207, '[SMN] ' .. text)
end

function smn_warn(text)
    add_to_chat(167, '[SMN] ' .. text)
end

-- gs c help: bound keys and macro commands
function smn_help()
	local keys = {
		{'idle_quick', 'Idle mode (quick cycle)'}, {'idle_quick_back', 'Idle mode (quick cycle, back)'}, {'weapon_lock', 'Weapon Lock'}, {'force_ilvl', 'Force iLvl'}, {'kiting', 'Kiting (Movement gear while engaged)'}, {'lag_mode', 'Lag Mode (crowded zones)'},
		{'th', 'Treasure Hunter: Tag on / off'}, {'th_persistent', 'Treasure Hunter: Persistent on / off'}, {'auto_favor', 'Auto Favor'}, {'smart_buff', 'Smart Buff'},
		{'ward_up', 'Ward cursor up'}, {'ward_down', 'Ward cursor down'}, {'ward_check', 'Ward check'},
		{'ward_clear', 'Ward clear'}, {'ward_run', 'Ward run checked'}, {'ward_one', 'Ward under cursor'},
		{'ward_one_stay', 'Ward under cursor, keep its avatar'},
		{'rage_conduit', 'Conduit sequence'}, {'skill_pact', 'Skill-up (combat)'}, {'skill_summon', 'Skill-up (town)'},
		{'resummon', 'Resummon last avatar'}, {'stop', 'Stop automation'}, {'hub_keybinds', 'Show/hide keybinds in HUD'},
	}
	smn_echo(('SMN GearSwap %s - config: %s'):format(SMN_VERSION or '?', SMN_USER_FILE or 'SMN-USER/user.lua'))
	smn_echo('Keys:')
	local listed = {}
	for _, k in ipairs(keys) do
		listed[k[1]] = true
		local label = smn_key_labels[k[1]]
		if label then add_to_chat(207, ('  %s %s'):format(label, k[2])) end
	end
	-- Other bound actions (keys added in SMN_KEYBINDS: acc_mode, siphon, custom_mode...), by action name
	local others = {}
	for action in pairs(smn_key_labels) do
		if not listed[action] then others[#others + 1] = action end
	end
	table.sort(others)
	for _, action in ipairs(others) do
		add_to_chat(207, ('  %s %s'):format(smn_key_labels[action], action))
	end
	smn_echo('Macros (/console ...):')
	for _, line in ipairs({
		'gs c rage 1 | 2 | 3 | 4    Rage n of the avatar out, on <t> (4: macros only)',
		'gs c rage conduit | debug  Conduit sequence / diagnostic on-off',
		'gs c pact <name> [<target>] [stay]  any Blood Pact (summons if needed)',
		'gs c ward run [stay] | one [stay] | toggle <name>',
		'gs c siphon                Elemental Siphon (spirit of weather / day)',
		'gs c atomos                Atomos on <t> (steals a buff), then the previous avatar',
		'gs c resummon              resummon the last avatar',
		'gs c skill pact | summon | status   gs c stop',
		'gs c hub avatar|recasts|rage|wards|auto|modes|options|all|keybinds|lite',
		'gs c opa | custom <mode> | autofavor | smartbuff | weaponlock | kiting',
		'gs c th tag | persistent   Treasure Hunter (Tag: once per mob; gs c th: cycle None / Tag / Persistent)',
		'gs c cycle | cycleback | set | toggle <mode> [value]   e.g. gs c set IdleMode DT',
		'gs c <IdleMode> (gs c DT)  |  gs c <toggle> (accmode, impactmode, empy, forceilvl, lagmode, sactorque,',
		'  autoremedy, autoecho)  |  gs c MeteorStrike3 (merits)  |  gs c lowhp  |  gs c debug, gs c rage debug',
	}) do
		add_to_chat(207, '  ' .. line)
	end
end

local function handle_skill(arg)
	arg = (arg or ''):lower()
	if arg == 'pact' or arg == 'summon' then
		smn_skill_start(arg)
	elseif arg == 'stop' then
		if not smn_auto_stop() then smn_echo('Already stopped.') end
	elseif arg == 'status' then
		smn_skill_report()
	else
		smn_echo('gs c skill pact | summon | stop | status')
	end
end

-- Value of a list mode, case-insensitive (nil if not found)
local function match_value(m, str)
	if not str then return nil end
	str = str:lower()
	for i = 1, m._track._count do
		if type(m[i]) == 'string' and m[i]:lower() == str then return m[i] end
	end
	return nil
end

local function echo_state(m)
    local value = m.value
    if type(value) == 'boolean' then value = value and 'ON' or 'OFF' end
    smn_echo(('%s: %s'):format(m.description or '?', tostring(value)))
end

-- Weapons follow the modes, whatever the command (weaponlock, opa, cycle/set/toggle WeaponLock or CustomMode):
--   CustomMode Opashoro -> SMN_OPASHORO_LOCK equipped and locked (WeaponLock ON)
--   WeaponLock ON       -> SMN_WEAPON_LOCK equipped and locked
--   otherwise           -> main/sub free
-- changed: 'WeaponLock' or 'CustomMode' (the mode just changed), old_custom: CustomMode before the change.
function smn_sync_weapons(changed, old_custom)
	local opa = state.CustomMode.value == 'Opashoro'
	if changed == 'CustomMode' then
		if opa then state.WeaponLock:set(true)
		elseif old_custom == 'Opashoro' then state.WeaponLock:set(false) end
	elseif changed == 'WeaponLock' and opa and not state.WeaponLock.value then
		state.CustomMode:set('None')   -- unlocking the weapons leaves Opashoro mode
		opa = false
	end
	enable("main","sub")
	if opa then
		equip(SMN_OPASHORO_LOCK)
		disable("main","sub")
	elseif state.WeaponLock.value then
		equip(SMN_WEAPON_LOCK)
		disable("main","sub")
	end
end

local function toggle_weapon_lock()
	state.WeaponLock:set(not state.WeaponLock.value)
	smn_sync_weapons('WeaponLock')
	echo_state(state.WeaponLock)
end

local function toggle_opashoro()
	local old = state.CustomMode.value
	state.CustomMode:set(old == 'Opashoro' and 'None' or 'Opashoro')
	smn_sync_weapons('CustomMode', old)
	smn_echo('Opashoro Mode: ' .. (state.CustomMode.value == 'Opashoro' and 'ON' or 'OFF'))
end

-- F9: quick cycle through SMN_IDLE_QUICK (ALT+F9, back = true: same list backwards);
-- if the current mode isn't in the list, goes back to the first
local function toggle_idle_quick(back)
	local quick = SMN_IDLE_QUICK or {'Refresh'}
	local next_mode = quick[1]
	for i, v in ipairs(quick) do
		if v == state.IdleMode.value then
			next_mode = back and quick[(i - 2) % #quick + 1] or quick[i % #quick + 1]
			break
		end
	end
	state.IdleMode:set(next_mode)
	echo_state(state.IdleMode)
end

local function handle_hub(section)
	section = (section or ''):lower()
	local map = {
		avatar = state.HudHideAvatar, recasts = state.HudHideRecasts, modes = state.HudHideModes,
		options = state.HudHideOptions, auto = state.HudHideAuto, wards = state.HudHideWards, rage = state.HudHideRage,
		all = state.HudHide, keybinds = state.HudKeybinds, lite = state.HudLite,
	}
	if map[section] then
		map[section]:toggle()
	else
		smn_echo('gs c hub avatar | recasts | rage | wards | auto | modes | options | all | keybinds | lite')
	end
	smn_hud_update()
end

-- Returns true if the command is valid (idle gear and HUD are then refreshed)
local function dispatch(command)
	local args = {}
	for w in command:gmatch('%S+') do args[#args + 1] = w end
	local cmd = (args[1] or ''):lower()

	if cmd == 'idle' then
		return true
	elseif cmd == 'toggleidle' then
		toggle_idle_quick((args[2] or ''):lower() == 'back')
		return true
	elseif cmd == 'th' or cmd == 'treasure' then
		-- Treasure Hunter (smn-th.lua): th tag | th persistent = that mode ON / OFF, th = cycle
		local sub = (args[2] or ''):lower()
		if sub == 'tag' or sub == 'persistent' then
			local v = sub == 'tag' and 'Tag' or 'Persistent'
			state.TreasureMode:set(state.TreasureMode.value == v and 'None' or v)
			echo_state(state.TreasureMode)
		else
			state.TreasureMode:cycle()
			echo_state(state.TreasureMode)
		end
		return true
	elseif cmd == 'weaponlock' then
		toggle_weapon_lock()
		return true
	elseif cmd == 'opa' then
		toggle_opashoro()
		return true
	elseif cmd == 'custom' then
		local value = match_value(state.CustomMode, args[2])
		if value then
			local old = state.CustomMode.value
			state.CustomMode:set(value)
			smn_sync_weapons('CustomMode', old)
			echo_state(state.CustomMode)
			return true
		end
		return false
	elseif cmd == 'cycle' or cmd == 'cycleback' or cmd == 'toggle' or cmd == 'set' then
		local m, key = smn_find_state(args[2])
		if not m then return false end
		local old_custom = state.CustomMode.value
		if cmd == 'cycle' then m:cycle()
		elseif cmd == 'cycleback' then m:cycleback()
		elseif cmd == 'toggle' then
			if m._track._type ~= 'boolean' then return false end
			m:toggle()
		else
			if not args[3] then return false end
			if not pcall(m.set, m, args[3]) then return false end
		end
		if key == 'WeaponLock' or key == 'CustomMode' then smn_sync_weapons(key, old_custom) end
		echo_state(m)
		return true
	elseif cmd == 'hub' or cmd == 'hide' or cmd == 'gui' then
		handle_hub(args[2])
		return 'silent'
	elseif cmd == 'skill' then
		handle_skill(args[2])
		return 'silent'
	elseif cmd == 'ward' then
		smn_ward_command(args)
		return 'silent'
	elseif cmd == 'rage' then
		smn_rage_command(args)
		return 'silent'
	elseif cmd == 'pact' then
		smn_pact_command(args)
		return 'silent'
	elseif cmd == 'siphon' then
		smn_siphon()
		return 'silent'
	elseif cmd == 'atomos' then
		smn_atomos()
		return 'silent'
	elseif cmd == 'resummon' then
		smn_resummon()
		return 'silent'
	elseif cmd == 'debug' then
		SMN_AUTO.debug = not SMN_AUTO.debug
		smn_echo('Debug (automation steps, BP recast): ' .. (SMN_AUTO.debug and 'ON' or 'OFF') .. ' (until reload).'
			.. (smn_debug_loaded and '' or ' SMN-LIB/smn-debug.lua is not installed: nothing is shown.'))
		return 'silent'
	elseif cmd == 'help' then
		smn_help()
		return 'silent'
	elseif cmd == 'stop' then
		if not smn_auto_stop() then smn_echo('Nothing running.') end
		return 'silent'
	end

	-- Idle Mode by name (gs c DT)
	local idle_mode = match_value(state.IdleMode, cmd)
	if idle_mode then
		state.IdleMode:set(idle_mode)
		echo_state(state.IdleMode)
		return true
	end

	-- Toggles by command name (gs c AccMode, gs c smartbuff, ...: SMN_TOGGLES)
	for _, t in ipairs(SMN_TOGGLES) do
		if cmd == t.command or cmd == t.key:lower() then
			state[t.key]:toggle()
			echo_state(state[t.key])
			return true
		end
	end

	-- Merits (gs c MeteorStrike3)
	local merit, value = cmd:match('^(%a+)([0-5])$')   -- 0 to 5 merits
	if merit then
		for key in pairs(SMN_MERITS) do
			if key:lower() == merit then
				SMN_MERITS[key] = tonumber(value)
				smn_echo(('%s: %d/5'):format(key, SMN_MERITS[key]))
				return true
			end
		end
	end

	return false
end

-- This command is called whenever you input "gs c <command>"
function self_command(command)
	if string.sub(command,1,7)=="EquipBP" then
		equipBPGear(string.sub(command,9,string.len(command)))
		return
	end
	if command:lower() == 'lowhp' then
		-- Use for "Cure 500 HP" objectives in Omen
		equip(sets.LowHP)
		return
	end

	local result = dispatch(command)
	if result == true then
		if not midaction() and not pet_midaction() then
			idle()
		end
		smn_hud_update()
	elseif not result then
		smn_echo('Unknown command: ' .. command:gsub('"', ''))
	end
end
