-- ===================================================================================================================
--  SMN-LIB : Blood Pact: Rage
--    Macros: gs c rage 1 | 2 | 3 ... casts Rage n of the avatar out (SMN_RAGE.pacts), on <t>.
--    Numbered list of the avatar's Rages in the HUD.
--    Conduit sequence: Astral Flow, Apogee, Rage x2, Astral Conduit, then main Rage on a loop
--    until Conduit ends. A JA on recast is skipped. F12 stops.
--
--  Loop timing (SMN_RAGE.conduit.trigger):
--    'player' : the next pact goes off as soon as YOUR animation ends (Blood Pact aftercast, smn_player_bp counters);
--    'pet'    : it goes off when the avatar has finished the previous one (pet_midcast / pet_aftercast, smn_pet_actions counters).
--  These hooks are called by GearSwap, which reads the action packets itself. This file neither reads nor sends any packet.
--
--  MP: right after each accepted pact, while the avatar acts, if MP doesn't cover the next pact:
--  Convert (/RDM), then the first available item in SMN_RAGE.conduit.mp_items. Nothing left: stop.
--  Commands: gs c rage 1 | 2 | 3 ... (number in the list of the avatar out) | conduit
-- ===================================================================================================================

local RAGE_RECAST = 173

smn_rage = {
    seq    = nil,  -- Conduit sequence in progress (phase, pact, avatar, counters, gear lock...), nil otherwise
}
local R = smn_rage

local function cfg()  return SMN_RAGE or {} end
-- Conduit settings. Lag Mode ON (gs c lagmode): the values of SMN_RAGE.conduit.lag replace the normal ones
-- (crowded zones such as Domain Invasion: slower signals -> safer timing, longer waits before a resend).
local function base_ccfg() return (SMN_RAGE or {}).conduit or {} end
local lag_view = setmetatable({}, {__index = function(_, k)
    local c = base_ccfg()
    local v = (c.lag or {})[k]
    if v ~= nil then return v end
    return c[k]
end})
local function ccfg()
    local c = base_ccfg()
    if c.lag and state and state.LagMode and state.LagMode.value then return lag_view end
    return c
end

---------------------------------------------------------------------------
-- DATA
---------------------------------------------------------------------------
local pact_cache = {}
local function pact_info(name)
    if pact_cache[name] == nil then
        local ja = res.job_abilities:with('en', name)
        -- Rage or Ward: a Ward on <t> works too as an extra entry (e.g. Mewing Lullaby as Cait Sith #4)
        pact_cache[name] = (ja and (ja.type == 'BloodPactRage' or ja.type == 'BloodPactWard')) and ja or false
        if not pact_cache[name] then smn_warn('Unknown Blood Pact: "' .. tostring(name) .. '".') end
    end
    return pact_cache[name] or nil
end

-- Avatar out and its Rage list: name, list (nil if not configured); nil if no avatar
function smn_rage_list()
    local mob = smn_pet()
    if not mob then return nil end
    local list = (cfg().pacts or {})[mob.name]
    if not list or #list == 0 then return mob.name, nil end
    return mob.name, list
end

-- MP cost (x1.5 under Apogee)
function smn_rage_cost(name)
    local ja = pact_info(name)
    if not ja then return 0 end
    local cost = ja.mp_cost or 0
    if smn_buff_active('Apogee') then cost = math.ceil(cost * 1.5) end
    return cost
end


local function valid_target()
    local t = windower.ffxi.get_mob_by_target('t')
    return t and t.spawn_type == 16 and t.hpp > 0 and t.valid_target
end

-- Conduit trace (SMN_RAGE.conduit.debug = true): no-op here, defined by the optional SMN-LIB/smn-debug.lua.
smn_conduit_trace = function() end

local function fire(pact)
    smn_conduit_trace('send', pact)
    send_command(('input /pet "%s" <t>'):format(pact))
end

---------------------------------------------------------------------------
-- MP: Convert then items
---------------------------------------------------------------------------
local item_ids = {}
local function item_count(name)
    if item_ids[name] == nil then
        local it = res.items:with('en', name)
        item_ids[name] = it and it.id or false
        if not it then smn_warn('Unknown item: "' .. name .. '".') end
    end
    local id = item_ids[name]
    if not id then return 0 end
    local n = 0
    for _, bag_id in ipairs({0, 3}) do  -- inventory, temporary items
        local bag = windower.ffxi.get_items(bag_id)
        for i = 1, (bag and bag.max or 0) do
            local slot = bag[i]
            if slot and slot.id == id then n = n + slot.count end
        end
    end
    return n
end

local function next_item()
    for _, name in ipairs(ccfg().mp_items or {}) do
        if not R.seq.failed_items[name] and item_count(name) > 0 then return name end
    end
    return nil
end

-- Convert usable now? (convert option, /RDM, recast ready, not already failed)
local function convert_ready()
    local cv = smn_convert_ja()
    return ccfg().convert ~= false and R.seq and not R.seq.convert_failed and smn_convert_known()
        and cv and smn_ability_recast(cv.recast_id) == 0
end

-- Makes sure we have `need` MP, then k(ok). ok = false if nothing is left to recover it.
local function ensure_mp(gen, need, k)
    local p = smn_me()
    if p.vitals.mp >= need then return smn_next(gen, k, true) end

    -- Convert
    local cv = smn_convert_ja()
    if ccfg().convert ~= false and not R.seq.convert_failed and smn_convert_known()
            and smn_ability_recast(cv.recast_id) == 0 and p.vitals.hp > p.vitals.mp then
        R.seq.phase = 'Convert'
        smn_send_confirmed(gen, 'input /ja "Convert" <me>',
            function() return smn_ability_recast(cv.recast_id) > 0 end, function(ok)
            if ok then
                R.seq.converts = R.seq.converts + 1
                smn_echo(('Convert: MP %d -> %d.'):format(p.vitals.mp, smn_me().vitals.mp))
            else
                R.seq.convert_failed = true
                smn_warn('Convert not executed.')
            end
            smn_after(gen, 0.5, function() ensure_mp(gen, need, k) end)
        end)
        return
    end

    -- Items
    local item = next_item()
    if not item then
        smn_warn(('Not enough MP (%d/%d): no Convert or item left.'):format(p.vitals.mp, need))
        return smn_next(gen, k, false)
    end
    R.seq.phase = item
    local mp_before = p.vitals.mp
    local done_before, ok_before = smn_item_actions.done, smn_item_actions.ok
    smn_conduit_trace('item', item)
    send_command(('input /item "%s" <me>'):format(item))
    -- End of the item signaled by aftercast (smn-main), or MP going up. Right after a Blood Pact, your
    -- character is still busy: the item may go off a little late, hence item_wait.
    smn_wait_until(gen, function()
        return smn_item_actions.done ~= done_before or smn_me().vitals.mp > mp_before
    end, ccfg().item_wait or 5, function()
        if smn_item_actions.ok ~= ok_before or smn_me().vitals.mp > mp_before then
            R.seq.items = R.seq.items + 1
            -- MP may arrive a moment after the item ends: wait for it before rechecking
            -- Don't recheck right away: if the MP reading is slow to rise, we would waste a 2nd item.
            -- If MP is really short, the pact will be rejected and retry_after will restart the recovery.
            return smn_wait_until(gen, function() return smn_me().vitals.mp > mp_before end, 2, function()
                smn_echo(('%s: MP %d -> %d (%d left).'):format(item, mp_before, smn_me().vitals.mp, item_count(item)))
                k(true)
            end)
        end
        R.seq.failed_items[item] = true
        smn_warn(item .. ': not used, skipped from now on.')
        ensure_mp(gen, need, k)
    end)
end

---------------------------------------------------------------------------
-- PACTS
---------------------------------------------------------------------------
-- Before resending a rejected pact: if MP is short, recover first (Convert / item) instead of
-- resending blindly. k(false) if nothing is left to recover.
local function retry_after(gen, pact, attempt, k)
    local cost = smn_rage_cost(pact)
    if smn_me().vitals.mp < cost then
        return ensure_mp(gen, cost, function(ok)
            if not ok then return k(false) end
            attempt()
        end)
    end
    -- Resend without an MP shortage: the pact arrived too early (dropped by the game without a message)
    smn_conduit_trace('resend', pact)
    if R.seq and smn_buff_active('Astral Conduit') then smn_lag_on_drop() end
    if R.seq then R.seq.resends = R.seq.resends + 1 end
    smn_after(gen, 0.3, attempt)
end

-- "Unable to use job ability" received after this send (pact arrived too early): quick resend instead of
-- waiting for the whole accept wait (long with lag). At most 8 per pact.
local function refused_since(sent_at) return smn_unable_at ~= nil and smn_unable_at >= sent_at end
local function on_unable(gen, attempt)
    if R.seq then R.seq.unable = (R.seq.unable or 0) + 1 end
    smn_conduit_trace('unable', 'quick resend')
    smn_after(gen, (SMN_AUTO and SMN_AUTO.refused_retry) or 0.5, attempt)
end

-- Sends the pact and waits for it to be accepted (pet_midcast); resends if rejected. k(accepted)
local function send_pact(gen, pact, k)
    local tries, unables = 0, 0
    local function attempt()
        tries = tries + 1
        local before = smn_pet_actions.started
        local sent_at = os.clock()
        fire(pact)
        smn_wait_until(gen, function()
            return smn_pet_actions.started ~= before or refused_since(sent_at)
        end, smn_lag_accept_wait(ccfg().accept_wait or 1.5), function()
            local ok = smn_pet_actions.started ~= before
            if not ok and refused_since(sent_at) and unables < 8 and smn_pet() and valid_target() then
                unables, tries = unables + 1, tries - 1
                return on_unable(gen, attempt)
            end
            if ok then
                -- Pact accepted: it will be charged when the avatar has finished it (end of action no. done + 1)
                if R.seq then R.seq.inflight_done = smn_pet_actions.done + 1 end
                return k(true)
            end
            if tries > (ccfg().resend or 4) or not smn_pet() or not valid_target() then return k(false) end
            retry_after(gen, pact, attempt, k)
        end)
    end
    attempt()
end

-- 'player' mode: sends the pact and waits for the end of YOUR animation (Blood Pact aftercast), without waiting for
-- the avatar. Pact rejected (interrupted, or no end of animation): resend. k(accepted)
local function send_pact_player(gen, pact, k)
    local tries, unables = 0, 0
    local function attempt()
        tries = tries + 1
        local done_before, ok_before = smn_player_bp.done, smn_player_bp.ok
        local sent_at = os.clock()
        fire(pact)
        smn_wait_until(gen, function()
            return smn_player_bp.done ~= done_before or refused_since(sent_at)
        end, smn_lag_accept_wait(ccfg().accept_wait or 1.5), function()
            if smn_player_bp.ok ~= ok_before then return k(true) end
            if smn_player_bp.done == done_before and refused_since(sent_at) and unables < 8 and smn_pet() and valid_target() then
                unables, tries = unables + 1, tries - 1
                return on_unable(gen, attempt)
            end
            if tries > (ccfg().resend or 4) or not smn_pet() or not valid_target() then return k(false) end
            retry_after(gen, pact, attempt, k)
        end)
    end
    attempt()
end

-- Avatar ready and recast allowed (at 0, or Apogee / Astral Conduit active)
local function can_pact()
    return smn_pet() ~= nil and not pet_midaction()
        and (smn_ability_recast(RAGE_RECAST) == 0 or smn_buff_active('Apogee') or smn_buff_active('Astral Conduit'))
end

local function pet_free()
    return smn_pet() ~= nil and not pet_midaction()
end

-- One prep pact (before Conduit): wait for the avatar, MP, send, end of the action, then k().
-- Apogee sets the recast to 0 for the next pact (x1.5 MP) and that pact doesn't restart the recast: both
-- pacts go off without waiting. If the recast isn't at 0 (Apogee on recast), don't wait for it:
-- Astral Conduit will reset it to 0 right after. A failure is reported and we continue.
local function rage_step(gen, pact, k)
    R.seq.phase = pact
    smn_wait_until(gen, pet_free, ccfg().done_wait or 10, function(free)
        if not free then
            smn_warn(pact .. ': avatar not ready, skipped.')
            return k()
        end
        if not can_pact() then
            smn_echo(pact .. ': Rage recast not at 0, moving on to Astral Conduit.')
            return k()
        end
        ensure_mp(gen, smn_rage_cost(pact), function(has_mp)
            if not has_mp then return smn_auto_stop('out of MP') end
            R.seq.phase = pact
            local done_before = smn_pet_actions.done
            send_pact(gen, pact, function(accepted)
                if not accepted then
                    smn_warn(pact .. ': refused.')
                    if R.seq then R.seq.refused = R.seq.refused + 1 end
                    return k()
                end
                R.seq.pacts = R.seq.pacts + 1
                smn_wait_until(gen, function() return smn_pet_actions.done ~= done_before or not smn_pet() end, ccfg().done_wait or 10, k)
            end)
        end)
    end)
end

-- JA on self, confirmed by its buff, then k(ok). Skipped if on recast; ok if the buff is already there.
local function use_ja(gen, name, k)
    if smn_buff_active(name) then return smn_next(gen, k, true) end
    local ja = res.job_abilities:with('en', name)
    if not ja then return smn_next(gen, k, false) end
    if smn_ability_recast(ja.recast_id) > 0 then
        smn_echo(name .. ': on recast, skipped.')
        return smn_next(gen, k, false)
    end
    R.seq.phase = name
    smn_conduit_trace('ja', name)
    smn_send_confirmed(gen, ('input /ja "%s" <me>'):format(name), function() return smn_buff_active(name) end, function(ok)
        smn_conduit_trace(ok and 'ja_ok' or 'ja_fail', name)
        if not ok then smn_warn(name .. ': not executed.') end
        -- Conduit started: damage set of the loop pact, kept until the buff ends (lock_gear)
        -- (gs c EquipBP: an equip() called outside a GearSwap hook would not be applied)
        if ok and name == 'Astral Conduit' and ccfg().lock_gear ~= false and R.seq and R.seq.pact then
            send_command('gs c EquipBP ' .. R.seq.pact)
        end
        smn_pause(gen, 0.2, 0.3, function() k(ok) end)
    end)
end

---------------------------------------------------------------------------
-- CONDUIT SEQUENCE
---------------------------------------------------------------------------
-- Start of each avatar pact during the sequence (called by pet_midcast, smn-main):
-- time of pacts under Conduit (average interval) and MP spent.
function smn_conduit_on_pet_start(pact)
    local s = R.seq
    if not s then return end
    s.mp_spent = s.mp_spent + smn_rage_cost(pact)
    if smn_buff_active('Astral Conduit') then s.starts[#s.starts + 1] = os.clock() end
end

-- Damage of the sequence pact, read from the chat (no packets): Battlemod's "[Ramuh] 18479 Volt Strike -> Mob",
-- or the game's own "Ramuh uses Volt Strike." followed by "Mob takes 18479 points of damage.". Battle messages
-- must be shown in the chat (chat filters).
local function strip_codes(text)
    return (text:gsub('[\30\31].', ''):gsub('[%z\1-\31\127]', ''))
end
local function add_damage(s, dmg)
    s.dmg = s.dmg or {total = 0, n = 0, zero = 0}
    local d = s.dmg
    d.total, d.n = d.total + dmg, d.n + 1
    if dmg == 0 then d.zero = d.zero + 1 end
    d.min = d.min and math.min(d.min, dmg) or dmg
    d.max = d.max and math.max(d.max, dmg) or dmg
end
windower.register_event('incoming text', function(original)
    local s = R.seq
    if not s or not original or original:find('%[SMN%]') then return end
    local pet = smn_pet()
    if not pet then return end
    local text = strip_codes(original)
    local pact = s.pact:gsub('(%p)', '%%%1')
    local name = pet.name:gsub('(%p)', '%%%1')
    -- Battlemod: [Ramuh] 18479 Volt Strike ...
    local dmg = text:match('%[' .. name .. '%]%s*(%d+)%s+' .. pact)
    if dmg then return add_damage(s, tonumber(dmg)) end
    -- Game messages: "Ramuh uses Volt Strike." then "<mob> takes 18479 points of damage."
    if text:find(name .. ' uses ' .. pact) then
        s.dmg_wait = os.clock()
        return
    end
    if s.dmg_wait and os.clock() - s.dmg_wait < 3 then
        dmg = text:match('takes (%d+) points? of damage')
        if dmg then
            s.dmg_wait = nil
            add_damage(s, tonumber(dmg))
        end
    end
end)

local function summary()
    local s = R.seq
    if not s then return '' end
    local n = #s.starts
    local avg = n > 1 and ((s.starts[n] - s.starts[1]) / (n - 1)) or 0
    local d = s.dmg
    local dmg = d and d.n > 0
        and (', damage %d (%d hits, avg %d, min %d, max %d%s)'):format(d.total, d.n, math.floor(d.total / d.n),
            d.min, d.max, d.zero > 0 and (', ' .. d.zero .. ' at 0') or '')
        or ''
    return ('%d pacts (%d under Conduit, avg %.2f s), %d resend, %d unable, %d refused, %d Convert, %d item, %d resummon, ~%d MP, lag %s%s.')
        :format(s.pacts, n, avg, s.resends, s.unable or 0, s.refused, s.converts, s.items, s.revives or 0, s.mp_spent,
            smn_lag.est and ('%.2f s'):format(smn_lag.est) or '?', dmg)
end

-- History: one line per sequence in SMN-USER/conduit-log.txt, to compare Conduits with each other
local LOG_FILE = windower.addon_path .. 'data/SMN-USER/conduit-log.txt'
local function write_log(reason)
    if not R.seq then return end
    local f = io.open(LOG_FILE, 'a')
    if not f then return end
    f:write(('%s | %s %s | %s | %s\n'):format(os.date('%Y-%m-%d %H:%M'), R.seq.avatar or '?', R.seq.pact or '?',
        summary(), reason or ''))
    f:close()
    -- Debug module (smn-debug.lua): writes the full trace of this sequence
    if smn_debug_conduit_end then smn_debug_conduit_end(summary(), reason) end
end

-- End of the sequence: if the set was locked and Conduit no longer is, back to the idle set
local function release_gear()
    local locked = R.seq and R.seq.locked
    R.seq = nil
    smn_auto.poll = nil
    if locked and not smn_buff_active('Astral Conduit') then send_command('gs c idle') end
end

local function finish(gen, reason)
    smn_echo('Conduit done' .. (reason and (' (' .. reason .. ')') or '') .. ': ' .. summary())
    write_log(reason)
    release_gear()
    smn_auto_finish(gen)
end

local function on_stop(reason)
    smn_echo('Conduit sequence stopped' .. (reason and (': ' .. reason) or '') .. '. ' .. summary())
    write_log('stopped: ' .. tostring(reason))
    release_gear()
end

local finisher   -- defined further down (after prep_send)

-- Avatar dead during Astral Conduit (DI boss AoE...): resummon the same avatar, Assault, then resume the loop
-- while the buff lasts. SMN_RAGE.conduit.revive = false to stop instead; revive_max resummons per sequence.
local function revive(gen, pact, k)
    local c, s = ccfg(), R.seq
    if c.revive == false or not smn_buff_active('Astral Conduit') then return finish(gen, 'avatar lost') end
    s.revives = (s.revives or 0) + 1
    if s.revives > (c.revive_max or 2) then return finish(gen, 'avatar lost again') end
    local sp = res.spells:with('en', s.avatar)
    if not sp then return finish(gen, 'avatar lost') end
    smn_warn(('%s lost during Conduit: resummoning.'):format(s.avatar))
    s.phase = 'Resummon ' .. s.avatar
    -- Summon right away; if the game still counts the dead avatar as your pet for a moment, one retry 1 s later
    local tries = 0
    local function attempt()
        tries = tries + 1
        smn_summon(gen, sp.id, sp.en, sp.mp_cost or 0, function(ok)
            if not ok then
                if tries < 2 and smn_buff_active('Astral Conduit') then return smn_after(gen, 1.0, attempt) end
                return finish(gen, 'resummon failed')
            end
            -- Summon set left on by the gear lock: back to the pact set
            if c.lock_gear ~= false then send_command('gs c EquipBP ' .. pact) end
            if c.assault ~= false and valid_target() then
                send_command('input /pet "Assault" <t>')
                return smn_after(gen, c.ja_gap or 1.1, k)
            end
            k()
        end, true, true)   -- no_rest, fast (waits for the end of the summon + ready_after_cast)
    end
    -- Normally the dead avatar is no longer your pet at once: immediate. Otherwise at most 1.5 s, so the
    -- summon doesn't mistake the dead one for the new avatar.
    smn_wait_until(gen, function() return smn_pet() == nil end, 1.5, function() attempt() end)
end

local function conduit_loop(gen, pact, refused, starting)
    refused = refused or 0
    -- starting: 1st pact, sent before Conduit is confirmed (see fast_prep)
    if not starting and not smn_buff_active('Astral Conduit') then
        -- Astral Conduit never went up (refused even after resends): say so instead of "wore off"
        if R.seq.conduit_ok == false then return finish(gen, 'Astral Conduit not active') end
        -- JA sent but not confirmed yet (lag: the buff shows up late): wait for the result, don't end the sequence
        if R.seq.conduit_ok == nil and R.seq.conduit_sent then
            smn_conduit_trace('wait_buff', 'Astral Conduit not up yet')
            return smn_wait_until(gen, function()
                return R.seq.conduit_ok ~= nil or smn_buff_active('Astral Conduit')
            end, 6, function() conduit_loop(gen, pact, refused, smn_buff_active('Astral Conduit')) end)
        end
        return finisher(gen, pact)
    end
    local pet = smn_pet()
    if not pet or (pet.hpp or 0) == 0 then
        return revive(gen, pact, function() conduit_loop(gen, pact, 0) end)
    end
    -- Target lost for a moment (boss untargetable during an animation / phase, target switched...): wait up to
    -- target_wait seconds for a valid <t> before giving up
    if not valid_target() then
        -- Mob dead: the sequence is over (normal end)
        local t = windower.ffxi.get_mob_by_target('t')
        if t and t.spawn_type == 16 and (t.hpp or 0) == 0 then return finish(gen, 'target defeated') end
        smn_conduit_trace('wait_target', '')
        R.seq.phase = 'waiting for a target'
        return smn_wait_until(gen, valid_target, ccfg().target_wait or 3, function(ok)
            if not ok then return smn_auto_stop('no target') end
            conduit_loop(gen, pact, refused, starting)
        end)
    end
    if refused >= 3 then return smn_auto_stop('pact refused 3 times in a row') end

    local trigger = ccfg().trigger or 'pet'
    local cost = smn_rage_cost(pact)
    -- In 'player' / 'pet_start', the previous pact isn't charged yet when the next one is sent:
    -- keep enough to pay for both (unless nothing is left to recover with).
    local need = (trigger == 'pet' or R.seq.no_recovery) and cost or cost * 2

    -- Convert as late as possible: it swaps HP and MP, so all remaining MP is lost. If MP doesn't
    -- cover two pacts and Convert is ready, wait for the current pact to be charged (end of
    -- the avatar's action); then only convert if the remaining MP no longer covers one pact.
    -- With lag, the MP is charged a moment AFTER the end of the avatar's action: wait for the MP to actually drop
    -- (at most lag + 0.5 s). Not dropped by then: the pact is still to be paid, so keep the two-pact need
    -- (Convert now if MP doesn't cover it) instead of sending a pact the game would drop for lack of MP.
    if R.seq.convert_late then
        if R.seq.convert_late == 'debited' then need = cost end
        R.seq.convert_late = nil
    elseif ccfg().convert_late ~= false and need > cost and smn_me().vitals.mp < need and convert_ready()
            and R.seq.inflight_done and smn_pet_actions.done < R.seq.inflight_done then
        R.seq.phase = 'waiting MP debit'
        local mp_before = smn_me().vitals.mp
        return smn_wait_until(gen, function() return smn_pet_actions.done >= R.seq.inflight_done end, 2.5, function()
            local debit_wait = math.max(0.5, (smn_lag.est or 0.5) + 0.5)
            smn_wait_until(gen, function() return smn_me().vitals.mp <= mp_before - cost * 0.5 end, debit_wait,
                function(debited)
                    smn_conduit_trace('mp_debit', debited and 'charged' or 'not charged yet: keep 2 pacts')
                    R.seq.convert_late = debited and 'debited' or 'pending'
                    conduit_loop(gen, pact, refused, starting)
                end)
        end)
    end

    ensure_mp(gen, need, function(has_mp)
        if not has_mp then
            if smn_me().vitals.mp < cost then return smn_auto_stop('out of MP') end
            R.seq.no_recovery = true   -- no more Convert or items: keep going as long as a pact goes through
        end
        R.seq.phase = 'Conduit'
        local function on_refused()
            smn_warn(pact .. ': refused.')
            if R.seq then R.seq.refused = R.seq.refused + 1 end
            -- keep "starting": a refused 1st pact may be retried before Conduit is confirmed
            return conduit_loop(gen, pact, refused + 1, starting)
        end
        local function next_loop() conduit_loop(gen, pact, 0) end

        -- 'player' mode: next pact as soon as YOUR animation ends (+ player_delay)
        if trigger == 'player' then
            return send_pact_player(gen, pact, function(accepted)
                if not accepted then return on_refused() end
                R.seq.pacts = R.seq.pacts + 1
                smn_after(gen, ccfg().player_delay or 0, next_loop)
            end)
        end

        local done_before = smn_pet_actions.done
        send_pact(gen, pact, function(accepted)
            if not accepted then return on_refused() end
            R.seq.pacts = R.seq.pacts + 1

            -- 'pet_start' mode: next pact start_delay seconds after the START of the avatar's pact
            if trigger == 'pet_start' then
                return smn_after(gen, smn_lag_start_delay(ccfg().start_delay or 1.0), next_loop)
            end

            -- 'pet' mode: while the avatar acts, MP for the next pact, then wait for its action to end.
            -- The current pact is only charged at the end of the avatar's action: cover both now, so
            -- Convert / item happen during the action. Not enough and nothing to recover with: the next
            -- loop decides (stops if the remaining MP no longer covers a pact).
            ensure_mp(gen, cost * 2, function()
                smn_wait_until(gen, function() return smn_pet_actions.done ~= done_before or not smn_pet() end,
                    ccfg().done_wait or 10, next_loop)
            end)
        end)
    end)
end

-- Rage recast allowed (at 0, or Apogee / Astral Conduit active), without checking whether the avatar is busy
local function recast_ok()
    return smn_ability_recast(RAGE_RECAST) == 0 or smn_buff_active('Apogee') or smn_buff_active('Astral Conduit')
end

-- Prep pact in 'pet_start' mode: send, then k(true) as soon as it is accepted (the avatar starts it),
-- without waiting for its action to end. wait_free: first wait for the avatar to be free (1st Rage).
local function prep_send(gen, pact, wait_free, k)
    local function go()
        if not recast_ok() then
            smn_echo(pact .. ': Rage recast not at 0, moving on to Astral Conduit.')
            return k(false)
        end
        local cost = smn_rage_cost(pact)
        ensure_mp(gen, cost * 2, function(has_mp)
            if not has_mp and smn_me().vitals.mp < cost then return smn_auto_stop('out of MP') end
            R.seq.phase = pact
            send_pact(gen, pact, function(accepted)
                if not accepted then
                    smn_warn(pact .. ': refused.')
                    if R.seq then R.seq.refused = R.seq.refused + 1 end
                    return k(false)
                end
                R.seq.pacts = R.seq.pacts + 1
                k(true)
            end)
        end)
    end
    if not wait_free then return go() end
    smn_wait_until(gen, pet_free, ccfg().done_wait or 10, function(free)
        if not free then
            smn_warn(pact .. ': avatar not ready, skipped.')
            return k(false)
        end
        go()
    end)
end

-- Fast prep ('pet_start' mode): Rage 1; Rage 2 start_delay after Rage 1 starts (Apogee leaves
-- the recast at 0); Astral Conduit as soon as Rage 2 is accepted, while the avatar executes it; then the loop,
-- start_delay after Rage 2 starts. An impossible Rage (recast) is skipped: Conduit resets the recast to 0.
local function fast_prep(gen, pact)
    local delay = smn_lag_start_delay(ccfg().start_delay or 0.7)
    local last_start = nil   -- os.clock() of the start of the last accepted pact

    -- Astral Conduit, then the 1st pact without waiting for buff confirmation: as soon as the global delay
    -- between two JAs has passed (SMN_RAGE.conduit.ja_gap, ~1 s) and no earlier than start_delay after the start of
    -- Rage 2. Confirmation is monitored in parallel (diagnostics, locking the damage set).
    local function to_conduit()
        if smn_buff_active('Astral Conduit') then return conduit_loop(gen, pact) end
        local ja = res.job_abilities:with('en', 'Astral Conduit')
        if not ja or smn_ability_recast(ja.recast_id) > 0 then
            smn_echo('Astral Conduit: on recast, skipped.')
            return finish(gen, 'Astral Conduit unavailable')
        end
        R.seq.phase = 'Astral Conduit'
        smn_conduit_trace('ja', 'Astral Conduit')
        send_command('input /ja "Astral Conduit" <me>')
        R.seq.conduit_sent = true
        local t_ja = os.clock()
        local ja_sent, ja_tries = t_ja, 1

        -- Confirmation: buff up. Refused by the game ("Unable to use job ability", e.g. your Blood Pact
        -- animation still running): resent, up to 4 tries, while the 1st pact goes ahead.
        smn_wait_until(gen, function()
            if smn_buff_active('Astral Conduit') then return true end
            if smn_unable_at and smn_unable_at >= ja_sent and ja_tries < 4 and os.clock() - ja_sent > 0.4 then
                ja_tries, ja_sent = ja_tries + 1, os.clock()
                smn_conduit_trace('ja', 'Astral Conduit (resend ' .. ja_tries .. ')')
                send_command('input /ja "Astral Conduit" <me>')
            end
            return false
        end, 5, function(ok)
            smn_conduit_trace(ok and 'ja_ok' or 'ja_fail', 'Astral Conduit')
            if R.seq then R.seq.conduit_ok = ok end
            if not ok then return smn_warn('Astral Conduit: not confirmed.') end
            if ccfg().lock_gear ~= false then send_command('gs c EquipBP ' .. pact) end
        end)

        local after_ja = (ccfg().ja_gap or 1.1) - (os.clock() - t_ja)
        local after_start = last_start and (delay - (os.clock() - last_start)) or 0
        smn_after(gen, math.max(0, after_ja, after_start), function() conduit_loop(gen, pact, 0, true) end)
    end

    prep_send(gen, pact, true, function(ok1)
        if not ok1 then return to_conduit() end
        last_start = os.clock()
        smn_after(gen, delay, function()
            prep_send(gen, pact, false, function(ok2)
                if ok2 then last_start = os.clock() end
                to_conduit()
            end)
        end)
    end)
end

-- Finisher (SMN_RAGE.conduit.finisher, OFF by default): when Conduit wears off and the mob is still alive,
-- Super Revitalizer (resets JA recasts to zero, including Apogee and Convert), Apogee, then Rage x2.
-- Without finisher, without Super Revitalizer or without a target: normal end.
finisher = function(gen, pact)
    local item = ccfg().finisher_item or 'Super Revitalizer'
    if not ccfg().finisher or not valid_target() or item_count(item) == 0 then
        return finish(gen, 'buff wore off')
    end
    R.seq.phase = item
    local done_before, ok_before = smn_item_actions.done, smn_item_actions.ok
    smn_conduit_trace('item', item)
    send_command(('input /item "%s" <me>'):format(item))
    smn_wait_until(gen, function() return smn_item_actions.done ~= done_before end, ccfg().item_wait or 5, function()
        if smn_item_actions.ok == ok_before then
            smn_warn(item .. ': not used.')
            return finish(gen, 'buff wore off')
        end
        smn_echo(item .. ': job ability recasts reset.')
        use_ja(gen, 'Apogee', function(ok)
            if not ok then return finish(gen, 'finisher: Apogee unavailable') end
            local delay = smn_lag_start_delay(ccfg().start_delay or 0.7)
            prep_send(gen, pact, true, function(ok1)
                if not ok1 then return finish(gen, 'finisher') end
                smn_after(gen, delay, function()
                    prep_send(gen, pact, false, function() finish(gen, 'finisher done') end)
                end)
            end)
        end)
    end)
end

local function start_conduit()
    local avatar, list = smn_rage_list()
    if not avatar then return smn_warn('No avatar out.') end
    if not list then return smn_warn('No Rage configured for ' .. avatar .. ' (SMN_RAGE.pacts).') end
    if not valid_target() then return smn_warn('No enemy target (<t>).') end
    local pact = list[1]
    local info = pact_info(pact)
    if not info then return end
    if info.type ~= 'BloodPactRage' then return smn_warn(pact .. ' is not a Rage: the Conduit sequence needs a Rage as #1.') end

    smn_auto_stop('replaced by Conduit')
    R.seq = {phase = '', pact = pact, avatar = avatar, pacts = 0, converts = 0, items = 0, failed_items = {},
             convert_failed = false, t0 = os.clock(), starts = {}, resends = 0, refused = 0, mp_spent = 0}
    smn_auto.poll = ccfg().poll or 0.05   -- checks every 0.05 s during the sequence
    smn_echo(('Conduit sequence: %s, %s.'):format(avatar, pact))
    smn_auto_start('conduit', function(gen)
        use_ja(gen, 'Astral Flow', function()
            use_ja(gen, 'Apogee', function()
                -- Damage set equipped and locked right now (lock_gear), until Conduit ends
                if ccfg().lock_gear ~= false then
                    R.seq.locked = true
                    send_command('gs c EquipBP ' .. pact)
                end
                if (ccfg().trigger or 'pet') == 'pet_start' then return fast_prep(gen, pact) end
                rage_step(gen, pact, function()
                    rage_step(gen, pact, function()
                        use_ja(gen, 'Astral Conduit', function(ok)
                            if not ok then return finish(gen, 'Astral Conduit unavailable') end
                            conduit_loop(gen, pact)
                        end)
                    end)
                end)
            end)
        end)
    end, on_stop)
end

---------------------------------------------------------------------------
-- COMMANDS
---------------------------------------------------------------------------
function smn_rage_command(args)
    local sub = (args[2] or ''):lower()
    if sub == 'conduit' then
        start_conduit()
        return smn_hud_update()
    end
    if sub == 'debug' then
        SMN_RAGE.conduit = SMN_RAGE.conduit or {}
        SMN_RAGE.conduit.debug = not SMN_RAGE.conduit.debug
        return smn_echo('Conduit debug: ' .. (SMN_RAGE.conduit.debug and 'ON' or 'OFF') .. ' (until reload).'
            .. (smn_debug_loaded and '' or ' SMN-LIB/smn-debug.lua is not installed: no trace.'))
    end

    local avatar, list = smn_rage_list()
    if not avatar then return smn_warn('No avatar out.') end
    if not list then return smn_warn('No Rage configured for ' .. avatar .. ' (SMN_RAGE.pacts).') end
    -- Number in the list of the avatar out (main = 1, second = 2)
    local n = tonumber(sub) or (sub == 'main' and 1) or (sub == 'second' and 2) or nil
    if n then
        if list[n] then fire(list[n]) else smn_warn(('No Rage (%d) for %s.'):format(n, avatar)) end
    else
        smn_echo('gs c rage 1 | 2 | 3 ... | conduit | debug')
    end
    smn_hud_update()
end
