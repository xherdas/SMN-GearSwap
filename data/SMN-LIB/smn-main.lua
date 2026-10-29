-- ===================================================================================================================
--  SMN-LIB: GearSwap hooks
--  Based on Pergatory's hooks and set selection (http://pastebin.com/u/pergatory), with the modes in
--  state.<Name>, plus: Conduit gear lock, Treasure Hunter, lag timing, action counters, movement gear, town,
--  Refresh received (sets.RefreshReceived when another player casts Refresh on you), style lock on load.
-- ===================================================================================================================

function pretarget(spell,action)
	if not buffactive['Muddle'] then
		-- Auto Remedy --
		if state.AutoRemedy.value and (spell.action_type == 'Magic' or spell.type == 'JobAbility') then
			if buffactive['Paralysis'] or (buffactive['Silence'] and not state.AutoEcho.value) then
				cancel_spell()
				send_command('input /item "Remedy" <me>')
			end
		end
		-- Auto Echo Drop --
		if state.AutoEcho.value and spell.action_type == 'Magic' and buffactive['Silence'] then
			cancel_spell()
			send_command('input /item "Echo Drops" <me>')
		end
	end
end

function precast(spell)
	-- Lag estimate (smn-lag): time from a Blood Pact command to the avatar starting it
	if spell.type=="BloodPactRage" or spell.type=="BloodPactWard" then smn_lag_on_send() end
	-- Release (macro or engine): recorded so the avatar death alert ignores it (smn-avatar)
	if spell.english == "Release" then smn_release_at = os.clock() end
    if (pet.isvalid and pet_midaction() and spell.type ~= "SummonerPact") or spell.type=="Item" then
		-- Do not swap if pet is mid-action. Summons are excepted: when the avatar dies mid-BP,
		-- pet.isvalid and pet_midaction() can stay true for a brief time.
		return
	end
	-- Spell fast cast
	if sets.precast[spell.english] then
        equip(sets.precast[spell.english])
    elseif spell.action_type=="Magic" then
		if spell.name=="Stoneskin" then
			equip(sets.precast.FC,{waist="Siegel Sash"})
		else
			equip(sets.precast.FC)
		end
    end
end

function midcast(spell)
    if (pet.isvalid and pet_midaction()) or spell.type=="Item" then
        return
    end
	-- BP Timer gear needs to swap here
	if (spell.type=="BloodPactWard" or spell.type=="BloodPactRage") then
		if not buffactive["Astral Conduit"] and not smn_conduit_gear_locked() then
			local equipSet = sets.midcast.BP
			if equipSet[spell.name] then
				equipSet = equipSet[spell.name]
			end
			equip(equipSet)
		end
		-- Lag Mode (gs c lagmode): also equip the BP gear 0.5 s later, in case the server signal comes late.
		if state.LagMode.value then
			send_command('wait 0.5;gs c EquipBP '..spell.name)
		end
	-- Spell Midcast & Potency Stuff
    elseif sets.midcast[spell.english] then
        -- .Self variant: gear that only works on yourself (e.g. Gishdubar Sash for Refresh)
        local s = sets.midcast[spell.english]
        equip(spell.target.type == 'SELF' and s.Self or s)
	elseif spell.name=="Elemental Siphon" then
		if pet.element==world.day_element and ZodiacElements:contains(pet.element) then
			if pet.element==world.weather_element then
				equip(sets.midcast.SiphonWeatherZodiac)
			else
				equip(sets.midcast.SiphonZodiac)
			end
		else
			if pet.element==world.weather_element then
				equip(sets.midcast.SiphonWeather)
			else
				equip(sets.midcast.Siphon)
			end
		end
	elseif spell.type=="SummonerPact" then
		equip(sets.midcast.Summon)
	elseif string.find(spell.name,"Cure") or string.find(spell.name,"Curaga") then
		equip(sets.midcast.Cure)
	elseif string.find(spell.name,"Protect") or string.find(spell.name,"Shell") then
		equip(sets.midcast.Enhancing,{ring2="Sheltered Ring"})
	elseif spell.skill=="Enfeebling Magic" then
		equip(sets.midcast.Enfeeble)
	elseif spell.skill=="Enhancing Magic" then
		equip(sets.midcast.Enhancing)
	elseif spell.skill=="Elemental Magic" then
		equip(sets.midcast.Nuke)
	elseif spell.action_type=="Magic" then
		equip(sets.midcast.EnmityRecast)
	elseif spell.type=="WeaponSkill" then
		equip(sets.Weaponskill)
    else
        idle()
    end
	-- Treasure Hunter (TreasureMode, smn-th.lua): your next offensive action (Tag), or every one (Persistent)
	if smn_th_wanted(spell) then
		smn_th_equip()
	end
	-- Auto-cancel existing buffs
	if spell.name=="Stoneskin" and buffactive["Stoneskin"] then
		windower.send_command('cancel 37;')
	elseif spell.name=="Sneak" and buffactive["Sneak"] and spell.target.type=="SELF" then
		windower.send_command('cancel 71;')
	elseif spell.name=="Utsusemi: Ichi" and buffactive["Copy Image"] then
		windower.send_command('wait 1;cancel 66;')
	end
end

function aftercast(spell)
	-- Treasure Hunter Tag: your action went off on a mob -> tagged (smn-th.lua)
	smn_th_on_action(spell)
	-- End of a summon: smn_summon (smn-runner) sees an interruption there right away.
	-- spell.interrupted comes from GearSwap (its own reading of action packets); nothing is read here.
	if spell.type=="SummonerPact" then
		smn_last_summon = {name = spell.english, interrupted = spell.interrupted and true or false}
		if smn_trace then smn_trace(spell.interrupted and 'cast_int' or 'cast_end', spell.english) end
	end
	-- End of an item use (MP recovery in the Conduit loop): done = any end, ok = succeeded
	if spell.type=="Item" then
		smn_item_actions.done = smn_item_actions.done + 1
		if not spell.interrupted then smn_item_actions.ok = smn_item_actions.ok + 1 end
		if smn_conduit_trace then smn_conduit_trace('item_done', spell.english .. (spell.interrupted and ' (interrupted)' or '')) end
	end
	-- End of YOUR animation for a Blood Pact (the "green flash"): signal for the Conduit loop in 'player' mode.
	-- done: any end of action; ok: pact accepted (not interrupted).
	if spell.type=="BloodPactRage" or spell.type=="BloodPactWard" then
		-- Debug module (SMN_AUTO.debug): recast of the next pact of this type
		if smn_debug_bp_recast then smn_debug_bp_recast(spell) end
		smn_player_bp.done = smn_player_bp.done + 1
		if smn_conduit_trace then smn_conduit_trace('me_after', spell.english .. (spell.interrupted and ' (interrupted)' or '')) end
		if not spell.interrupted then smn_player_bp.ok = smn_player_bp.ok + 1 end
	end
    if pet_midaction() then
        return
    end
	-- Item: no swap for the item itself, but the idle set is refreshed (e.g. Movement gear to remove
	-- if you stopped moving while using it)
	if spell.type=="Item" then
		return idle()
	end
	if not string.find(spell.type,"BloodPact") then
        idle()
    end
end

function pet_change(pet,gain)
	if (not (gain and pet_midaction())) then
		idle()
	end
	smn_hud_update()
end

function status_change(new,old)
	if not midaction() and not pet_midaction() then
        idle()
	end
end

function buff_change(name,gain)
	-- Debug module: buffs / debuffs gained or lost during a Conduit sequence go to the trace (Terror, Stun...)
	if smn_debug_buff then smn_debug_buff(name, gain) end
    if name=="quickening" and not pet_midaction() then
        idle()
    end
	-- End of Astral Conduit: back to the idle set (locked while the buff is up)
	if name:lower()=="astral conduit" and not gain and not pet_midaction() then
		smn_conduit_unlock = true  -- buffactive may still contain the buff at this point
		idle()
		smn_conduit_unlock = nil
	end
	if state.SacTorque.value and name=="sleep" and gain and pet.isvalid then
		equip({neck="Sacrifice Torque"})
		disable("neck")
		if buffactive["Stoneskin"] then
			windower.send_command('cancel 37;')
		end
	end
	if state.SacTorque.value and name=="sleep" and not gain then
		enable("neck")
	end
end

-- Avatar action counters, for the Conduit loop timing (smn-rage):
-- started increments when the avatar begins a pact (pact accepted), done when it has finished it.
-- pet_midcast / pet_aftercast are called by GearSwap (its own reading of action packets); nothing is read here.
smn_pet_actions = smn_pet_actions or {started = 0, done = 0}
smn_player_bp = smn_player_bp or {done = 0, ok = 0}
smn_item_actions = smn_item_actions or {done = 0, ok = 0}

function pet_midcast(spell)
	smn_pet_actions.started = smn_pet_actions.started + 1
	local lag_sample = smn_lag_on_pet_start()
	if smn_conduit_on_pet_start then smn_conduit_on_pet_start(spell.english) end
	if smn_conduit_trace then
		smn_conduit_trace('pet_start', spell.english .. (lag_sample and (' (%.2f s after send)'):format(lag_sample) or ''))
	end
	if smn_trace then smn_trace('pet_start', spell.english) end
	if not state.LagMode.value then
		equipBPGear(spell.name)
	end
end

function pet_aftercast(spell)
	smn_pet_actions.done = smn_pet_actions.done + 1
	-- Ward done by your avatar: HUD timer / Smart Buff follow YOUR buff (smn-ward)
	if spell.type == "BloodPactWard" and not spell.interrupted and smn_ward_on_pact_done then
		smn_ward_on_pact_done(spell.english)
	end
	if smn_conduit_trace then smn_conduit_trace('pet_done', spell.english) end
	if smn_trace then smn_trace('pet_done', spell.english) end
    idle()
end

-- Merit pact: with 5/5 merits, the NoTP set (Apogee Slacks) beats Enticer's Pants
local function merit_maxed(spell)
	local key = Merit_BP_Keys[spell]
	return key and (tonumber(SMN_MERITS[key]) or 0) > 4
end

function equipBPGear(spell)
	-- Delayed call (gs c EquipBP, Lag Mode / Conduit): the avatar may be gone by now
	if not pet.isvalid or not pet.name then return end
	if spell=="Shock Squall" then
		return -- Don't bother for Shock Squall, it already went off by the time we get here
	end
    if spell=="Perfect Defense" then
        equip(sets.pet_midcast.SummoningMagic)
	elseif Debuff_BPs:contains(spell) then
		equip(sets.pet_midcast.MagicAcc_BP)
	elseif Buff_BPs_Healing:contains(spell) then
		equip(sets.pet_midcast.Buff_Healing)
	elseif Buff_BPs_Duration:contains(spell) then
		if state.Empy.value then
			equip(sets.pet_midcast.Buff.Empy)
		else
			equip(sets.pet_midcast.Buff)
		end
	elseif Buff_BPs_MND:contains(spell) then
		equip(sets.pet_midcast.Buff_MND)
	elseif spell=="Flaming Crush" then
		if state.AccMode.value then
			equip(sets.pet_midcast.FlamingCrush_Acc)
		else
			equip(sets.pet_midcast.FlamingCrush)
		end
	elseif state.ImpactDebuff.value and (spell=="Impact" or spell=="Conflag Strike") then
		equip(sets.pet_midcast.Impact)
	elseif Magic_BPs_NoTP:contains(spell) then
		if state.AccMode.value then
			equip(sets.pet_midcast.Magic_BP_NoTP_Acc)
		else
			equip(sets.pet_midcast.Magic_BP_NoTP)
		end
	elseif Magic_BPs_TP:contains(spell) or string.find(spell," II") or string.find(spell," IV") then
		if state.AccMode.value then
			equip(sets.pet_midcast.Magic_BP_TP_Acc)
		else
			equip(sets.pet_midcast.Magic_BP_TP)
		end
	elseif Merit_BPs:contains(spell) then
		if state.AccMode.value then
			equip(sets.pet_midcast.Magic_BP_TP_Acc)
		elseif merit_maxed(spell) then
			equip(sets.pet_midcast.Magic_BP_NoTP)
		else
			equip(sets.pet_midcast.Magic_BP_TP)
		end
	elseif Debuff_Rage_BPs:contains(spell) then
		equip(sets.pet_midcast.Debuff_Rage)
	else
		if string.find(pet.name,'Spirit') then
			return
		elseif state.AccMode.value then
			equip(sets.pet_midcast.Physical_BP_Acc)
		elseif Physical_BPs_TP:contains(spell) then
			equip(sets.pet_midcast.Physical_BP_TP)
		elseif buffactive["Aftermath: Lv.3"] and state.CustomMode.value ~= "Opashoro" then
			equip(sets.pet_midcast.Physical_BP_AM3)
		else
			equip(sets.pet_midcast.Physical_BP)
		end
	end
	-- Custom Timers
	if spell=="Mewing Lullaby" and string.find(world.area,"Walk of Echoes %[P") then
		send_command('timers create "Mewing Resist: can go @ 30s" 60 down') -- In Gaol, underperforms if used every 20s. 60s is full potency.
		-- (Pergatory's tip) Best to go again after 30 s: it doesn't fully drain them, but waiting the full 60 s costs too much.
		-- Use the time between this to use BP:Rages for additional damage! They feed no TP, as long as your avatar doesn't attack.
	end
end

-- This function is for returning to aftercast gear after an action/event.
-- Syntax: sets.aftercast.{IdleMode}.{PetName|Spirit|Avatar}.{PlayerStatus}.{LowMP}.{ForceIlvl}.{CustomMode}
-- During the Conduit sequence (from Apogee on) and while Astral Conduit is active, the damage set stays equipped
-- (SMN_RAGE.conduit.lock_gear, on by default): no return to the idle set between pacts, no BP recast
-- set. The idle set comes back when the buff wears off (buff_change) or at the end of the sequence (smn-rage).
function smn_conduit_gear_locked()
	local c = SMN_RAGE and SMN_RAGE.conduit or {}
	if c.lock_gear == false then return false end
	local seq_locked = smn_rage ~= nil and smn_rage.seq ~= nil and smn_rage.seq.locked == true
	-- Buff just wore off (buff_change): unlocked, unless the sequence still holds the lock (finisher, last pact)
	if smn_conduit_unlock then return seq_locked end
	return buffactive['Astral Conduit'] ~= nil or seq_locked
end

-- After zoning, refresh the idle set (Adoulin body, Town set). The wait lets world.area update
-- and the gear finish loading; 'gs c idle' goes through self_command, which calls idle().
windower.register_event('zone change', function()
	send_command('wait 3; gs c idle; wait 5; gs c idle')   -- second pass for slow zones
	smn_town_fix_tries, smn_town_ok = 0, false
end)

-- Town check (every 2 s): Movement gear should always be on in towns (SMN_TOWN_MOVEMENT). After zoning, the idle
-- set can be applied before the inventory has loaded (ignored by GearSwap): if a Movement piece is missing,
-- re-apply the idle set, at most 3 times per zone (a piece you don't own would loop forever otherwise). Once the
-- gear is in place, the check stops until the next zone change.
smn_town_fix_tries = 0
local EQUIP_KEYS = {ring1 = 'left_ring', ring2 = 'right_ring', ear1 = 'left_ear', ear2 = 'right_ear',
	lring = 'left_ring', rring = 'right_ring', lear = 'left_ear', rear = 'right_ear'}
local function movement_missing()
	for slot, item in pairs(sets.Movement or {}) do
		local name = type(item) == 'table' and item.name or item
		local worn = player.equipment[EQUIP_KEYS[slot] or slot]
		if type(name) == 'string' and (not worn or worn:lower() ~= name:lower()) then return true end
	end
	return false
end
local last_town_check = 0
windower.register_event('prerender', function()
	local now = os.clock()
	if now - last_town_check < 2 then return end
	last_town_check = now
	if SMN_TOWN_MOVEMENT == false or smn_town_ok or smn_town_fix_tries >= 3 or not state or not state.IdleMode then return end
	if not windower.ffxi.get_mob_by_target('me') or not smn_in_town() then return end
	if midaction() or pet_midaction() or smn_conduit_gear_locked() then return end
	if movement_missing() then
		smn_town_fix_tries = smn_town_fix_tries + 1
		send_command('gs c idle')
	else
		smn_town_ok = true   -- in place: no more checks until the next zone change
	end
end)

-- Movement detection (SMN_AUTO_MOVE in user.lua): own position read from memory every 0.25 s,
-- no packets (same method as the gearinfo addon). sets.Movement goes on while moving, and comes off
-- after 2 still checks (0.5 s). A jump of more than 10 yalms (warp, zoning) doesn't count as moving.
-- Engaged: no Movement gear while repositioning on the mob, unless Kiting is ON (gs c kiting).
smn_moving = false
function smn_move_gear_allowed()
	return player.status ~= 'Engaged' or state.Kiting.value
end
local move_last, move_still, move_check = nil, 0, 0
windower.register_event('prerender', function()
	if not SMN_AUTO_MOVE then return end
	local now = os.clock()
	if now - move_check < 0.25 then return end
	move_check = now
	local me = windower.ffxi.get_mob_by_target('me')
	if not me then move_last = nil return end
	local moved = false
	if move_last then
		local dx, dy = me.x - move_last.x, me.y - move_last.y
		local d2 = dx*dx + dy*dy
		-- Jump limit scaled to the time since the last sample (40 yalms/s, mount included):
		-- a frame stall doesn't count as a warp.
		local max = 40 * math.max(0.25, now - (move_last.t or now))
		moved = d2 > 0.0001 and d2 < max * max
	end
	move_last = {x = me.x, y = me.y, t = now}
	move_still = moved and 0 or move_still + 1
	local moving = moved or (smn_moving and move_still < 2)
	if moving ~= smn_moving then
		smn_moving = moving
		-- In town the Movement gear stays on anyway (SMN_TOWN_MOVEMENT): nothing to refresh
		if smn_move_gear_allowed() and not (smn_in_town() and SMN_TOWN_MOVEMENT ~= false) then
			send_command('gs c idle')
		end
	end
end)

-- In a town (TownIdle list in smn-data)?
function smn_in_town()
	return world.area ~= nil and TownIdle:contains(world.area:lower())
end

function idle()
	if smn_conduit_gear_locked() then return end
	local idleMode = state.IdleMode.value
	local equipSet = sets.aftercast
	if equipSet[idleMode] then
		equipSet = equipSet[idleMode]
	end
	if pet.isvalid then
		if equipSet[pet.name] then
			equipSet = equipSet[pet.name]
		elseif string.find(pet.name,'Spirit') and equipSet["Spirit"] then
			equipSet = equipSet["Spirit"]
		elseif equipSet["Avatar"] then
			equipSet = equipSet["Avatar"]
		end
	end
	if equipSet[player.status] then
		equipSet = equipSet[player.status]
	end
	if player.mpp < 50 and equipSet["LowMP"] then
		equipSet = equipSet["LowMP"]
	end
	if state.ForceIlvl.value and equipSet["ForceIlvl"] then
		equipSet = equipSet["ForceIlvl"]
	end
	if equipSet[state.CustomMode.value] then
		equipSet = equipSet[state.CustomMode.value]
	end
	equip(equipSet)

	-- Treasure Hunter: while engaged in Persistent mode (smn-th.lua)
	if smn_th_idle() then
		smn_th_equip()
	end

	-- Town (optional): sets.aftercast.Town is equipped OVER the set above (which still follows the Idle Mode
	-- and the pet), e.g. for a look in town. sets.aftercast.Town.Avatar (if defined) is used with a pet out.
	local town = smn_in_town()
	if town and type(sets.aftercast.Town) == 'table' then
		local t = sets.aftercast.Town
		if pet.isvalid and type(t.Avatar) == 'table' then t = t.Avatar end
		equip(t)
	end

	-- Adoulin city body (SMN_ADOULIN_BODY in user.lua, nil = off)
	if SMN_ADOULIN_BODY and world.area and world.area:endswith('Adoulin') then
		equip({body=SMN_ADOULIN_BODY})
	end

	-- Movement gear: always in town (SMN_TOWN_MOVEMENT), otherwise while moving (not engaged unless Kiting)
	-- or with Quickening / Sneak / Invisible; never in Idle Mode DT outside town.
	local moving = buffactive['Quickening'] or buffactive['Sneak'] or buffactive['Invisible']
		or (smn_moving and smn_move_gear_allowed())
	if (town and SMN_TOWN_MOVEMENT ~= false) or (moving and idleMode~='DT') then
		equip(sets.Movement)
	end
end

-- Refresh received: another player starts casting Refresh / Refresh II / III on you -> sets.RefreshReceived
-- (e.g. Gishdubar Sash), then back to the idle set when the cast ends (finished or interrupted, 8 s at most).
-- Read-only: Windower's 'action' event (the data GearSwap and Battlemod already use), nothing is sent.
-- No swap while you or your avatar are acting, or during the Conduit gear lock.
local REFRESH_SPELLS = S{109, 473, 894}
local refresh_from = nil   -- caster id while a Refresh on you is being cast
local function refresh_back()
	refresh_from = nil
	if not midaction() and not pet_midaction() then idle() end
end
windower.register_event('action', function(act)
	if not sets.RefreshReceived or act.category ~= 8 then return end
	local t = act.targets and act.targets[1]
	local a = t and t.actions and t.actions[1]
	if not a or not player or t.id ~= player.id or act.actor_id == player.id then return end
	if act.param == 28787 then   -- casting interrupted
		if refresh_from == act.actor_id then refresh_back() end
		return
	end
	if act.param ~= 24931 or not REFRESH_SPELLS:contains(a.param) then return end   -- 24931: casting starts
	if midaction() or pet_midaction() or smn_conduit_gear_locked() then return end
	refresh_from = act.actor_id
	equip(sets.RefreshReceived)
	local caster = windower.ffxi.get_mob_by_id(act.actor_id)
	smn_echo(('%s on you (%s): Refresh received gear.'):format(res.spells[a.param].en, caster and caster.name or '?'))
	local from = act.actor_id
	coroutine.schedule(function() if refresh_from == from then refresh_back() end end, 8)
end)
-- End of the cast (category 4: spell finished on you)
windower.register_event('action', function(act)
	if act.category == 4 and refresh_from and act.actor_id == refresh_from then refresh_back() end
end)

-- Style lock (SMN_LOCKSTYLE): /lockstyleset once the game is ready. Sent too early (loading, inventory not ready)
-- or during a warp, cutscene or menu, the game ignores it. So it waits until the character has been ready for
-- `steady` seconds in a row (in the zone, idle / engaged / resting, no menu open, `after_zone` seconds after
-- loading or zoning), then sends it once. A warp during the wait restarts the count. gs c lockstyle: send it again.
local lockstyle_gen, lockstyle_zoned = 0, os.clock()
local LOCKSTYLE_STATUS = S{0, 1, 33}   -- idle, engaged, resting
windower.register_event('zone change', function() lockstyle_zoned = os.clock() end)

local function lockstyle_ready(c)
	local info, p = windower.ffxi.get_info(), windower.ffxi.get_player()
	if not (info and info.logged_in and p and windower.ffxi.get_mob_by_target('me')) then return false end
	if p.main_job ~= 'SMN' or info.menu_open or not LOCKSTYLE_STATUS:contains(p.status) then return false end
	return os.clock() - lockstyle_zoned >= (c.after_zone or 10)
end

function smn_lockstyle_stop() lockstyle_gen = lockstyle_gen + 1 end

function smn_lockstyle(by_command)
	local c = type(SMN_LOCKSTYLE) == 'table' and SMN_LOCKSTYLE or {set = SMN_LOCKSTYLE}
	local set = c.set
	if type(set) == 'table' then set = set[math.random(#set)] end   -- a list: one at random
	set = tonumber(set)
	if not set then
		if by_command then smn_warn('Style lock: no set in SMN_LOCKSTYLE (user.lua).') end
		return
	end
	smn_lockstyle_stop()
	local gen, since, left = lockstyle_gen, nil, 600   -- gives up after 10 minutes
	local function tick()
		if gen ~= lockstyle_gen then return end
		if lockstyle_ready(c) then
			since = since or os.clock()
			if os.clock() - since >= (c.steady or 3) then
				send_command('input /lockstyleset ' .. set)
				return
			end
		else
			since = nil
		end
		left = left - 1
		if left > 0 then coroutine.schedule(tick, 1) end
	end
	tick()
end
