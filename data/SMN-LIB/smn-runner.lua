-- ===================================================================================================================
--  SMN-LIB: automation engine (skill-up, Ward rotation, Conduit, siphon, resummon, gs c pact)
--
--  GearSwap replaces coroutine.sleep / coroutine.yield in the job file environment
--  (user_functions.lua) and those versions loop on themselves (stack overflow). So we never
--  use sleep: each wait is scheduled with coroutine.schedule, then calls the continuation
--  (function k). A step is written like this:
--      smn_wait_until(gen, condition, timeout, function(ok) ... continuation ... end)
--
--  Only one automation at a time. Each start increments smn_auto.gen; a scheduled step
--  only runs if gen hasn't changed in the meantime (Stop, another start, zone, KO, reload).
--
--  NO PACKETS: all actions go through 'input /...' (same as a typed command)
--  and state is read through the windower.ffxi.get_* memory APIs.
-- ===================================================================================================================

smn_auto = {
    gen     = 0,
    task    = nil,   -- name of the running automation ('skill', 'ward', 'conduit'...) or nil
    on_stop = nil,   -- function(reason) called on stop
}

local function cfg() return SMN_AUTO or {} end

function smn_auto_alive(gen) return smn_auto.gen == gen end
function smn_auto_running() return smn_auto.task ~= nil end

function smn_me()  return windower.ffxi.get_player() end
function smn_pet() return windower.ffxi.get_mob_by_target('pet') end

-- Runs fn after `seconds`, only if automation gen is still running.
-- A Lua error in a step (e.g. player data missing during a disconnect) stops the automation cleanly
-- instead of leaving it "running" with a dead chain.
function smn_after(gen, seconds, fn)
    coroutine.schedule(function()
        if not smn_auto_alive(gen) then return end
        local ok, err = pcall(fn)
        if not ok and smn_auto_alive(gen) then
            smn_warn('Automation error: ' .. tostring(err))
            smn_auto_stop('error')
        end
    end, seconds)
end

-- Calls k(...) at the next opportunity (never directly: the stack doesn't grow from one cycle to the next)
function smn_next(gen, k, ...)
    local args = {...}
    smn_after(gen, 0, function() k(unpack(args)) end)
end

-- Step trace (SMN_AUTO.debug, gs c debug): no-op here, defined by the optional SMN-LIB/smn-debug.lua.
smn_trace = function() end

-- Starts fn(gen). Stops the running automation first.
function smn_auto_start(task, fn, on_stop)
    if smn_auto.task then smn_auto_stop('replaced by ' .. task) end
    smn_auto.gen = smn_auto.gen + 1
    smn_auto.task = task
    smn_auto.on_stop = on_stop
    smn_auto.t0 = os.clock()
    local gen = smn_auto.gen
    smn_after(gen, 0, function() fn(gen) end)
    smn_hud_update()
end

-- Normal end of an automation (without Stop)
function smn_auto_finish(gen)
    if not smn_auto_alive(gen) then return end
    smn_auto.gen = smn_auto.gen + 1
    smn_auto.task, smn_auto.on_stop = nil, nil
    smn_hud_update()
end

function smn_auto_stop(reason)
    if not smn_auto.task then return false end
    smn_auto.gen = smn_auto.gen + 1
    local on_stop = smn_auto.on_stop
    smn_auto.task, smn_auto.on_stop = nil, nil
    if on_stop then on_stop(reason) end
    smn_hud_update()
    return true
end

-- Checks cond every `step` seconds (0.25 by default); k(true) as soon as it is true, k(false) after timeout.
function smn_wait_until(gen, cond, timeout, k, step)
    step = step or smn_auto.poll or 0.25   -- smn_auto.poll: finer interval during Conduit / Ward rotations
    local elapsed = 0
    local function check()
        if cond() then return k(true) end
        if elapsed >= timeout then return k(false) end
        elapsed = elapsed + step
        smn_after(gen, step, check)
    end
    smn_after(gen, 0, check)
end

-- "Human" pause: random delay between a and b (SMN_AUTO.delay by default), then k()
function smn_pause(gen, a, b, k)
    a, b = a or cfg().delay[1], b or cfg().delay[2]
    smn_after(gen, a + math.random() * (b - a), k)
end

function smn_spell_ready(id)
    local r = windower.ffxi.get_spell_recasts()
    return (r[id] or 0) == 0
end

function smn_ability_recast(id)
    local r = windower.ffxi.get_ability_recasts()
    return r[id] or 0
end

-- Game rejection read from the chat: time of the last rejection (os.clock). Reads chat text only, no packets.
--   "Unable to use job ability."                  : sent too early (action lock)
--   "<your name> cannot perform that action."      : you can't act right now (Terror, Stun...)
-- Both mean a quick resend; only the first one is a timing problem (smn-lag adds delay for it, not for the other).
smn_unable_at = nil
-- "You cannot use <avatar> in this area." (Mhaura, Mog House...): time of the last one, the summon stops everything
smn_no_summon_at = nil
windower.register_event('incoming text', function(original)
    -- Our own chat lines ([SMN] traces quoting the message) must not count as a refusal
    if not original or original:find('%[SMN%]') then return end
    if original:find('You cannot use .- in this area') then
        smn_no_summon_at = os.clock()
        return
    end
    if original:find('Unable to use job ability') then
        smn_unable_at = os.clock()
        smn_trace('unable')
        return
    end
    local p = windower.ffxi.get_player()
    if p and p.name and original:find(p.name .. ' cannot perform that action', 1, true) then
        smn_unable_at = os.clock()
        smn_trace('unable', 'cannot perform that action')
    end
end)

-- Sends a command and waits for its confirmation; resends up to SMN_AUTO.retries times, then k(ok).
-- Rejection reported in the chat (action lock): resend 0.5 s later instead of waiting retry_wait.
function smn_send_confirmed(gen, command, confirmed, k)
    local tries, refusals = 0, 0
    local function attempt()
        tries = tries + 1
        local sent_at = os.clock()
        local function refused() return smn_unable_at ~= nil and smn_unable_at >= sent_at end
        send_command(command)
        smn_trace('send', (command:gsub('^input ', '')))
        -- Confirmation wait: retry_wait, longer with lag (smn-lag: a buff shows up one round trip later)
        local wait = cfg().retry_wait or 2.5
        if smn_lag_accept_wait then wait = math.max(wait, smn_lag_accept_wait(wait)) end
        smn_wait_until(gen, function() return confirmed() or refused() end, wait, function()
            if confirmed() then
                smn_trace('ok', (command:gsub('^input ', '')))
                return k(true)
            end
            -- Action lock rejection: quick resend, not counted in retries (at most 15 rejections)
            if refused() and refusals < 15 then
                refusals, tries = refusals + 1, tries - 1
                return smn_after(gen, cfg().refused_retry or 0.5, attempt)
            end
            if tries >= cfg().retries then return k(false) end
            smn_pause(gen, 1.0, 1.5, attempt)
        end)
    end
    attempt()
end

function smn_release(gen, k)
    if not smn_pet() then return smn_next(gen, k, true) end
    smn_send_confirmed(gen, 'input /pet "Release" <me>', function() return smn_pet() == nil end, function(ok)
        if not ok then smn_warn('Release failed after ' .. cfg().retries .. ' tries.') end
        k(ok)
    end)
end

-- Rest if MP is insufficient, then k(ok). ok = false if impossible.
-- no_rest: never /heal (Ward rotation in combat), k(false) if MP is short.
function smn_ensure_mp(gen, cost, k, no_rest)
    local p = smn_me()
    if p.vitals.mp >= cost then return smn_next(gen, k, true) end

    if no_rest then
        smn_warn(('Not enough MP (%d/%d).'):format(p.vitals.mp, cost))
        return smn_next(gen, k, false)
    end

    if p.status == 1 then
        smn_warn('Not enough MP while engaged: cannot /heal.')
        return smn_next(gen, k, false)
    end

    smn_release(gen, function()
        smn_echo(('Low MP (%d/%d) -> resting.'):format(p.vitals.mp, cost))
        send_command('input /heal on')

        smn_wait_until(gen, function() return smn_me().status == 33 end, cfg().timeout.rest_start, function(resting)
            if not resting then
                smn_warn('Cannot rest.')
                return k(false)
            end

            local target = math.max(cost, math.floor(p.vitals.max_mp * cfg().rest_to_pct / 100))
            smn_wait_until(gen, function()
                local q = smn_me()
                return q.vitals.mp >= target or q.status ~= 33
            end, cfg().timeout.rest, function()
                if smn_me().status == 33 then send_command('input /heal off') end
                smn_after(gen, 1.5, function() k(smn_me().vitals.mp >= cost) end)
            end)
        end)
    end)
end

-- Summons an avatar, then k(ok). no_rest: see smn_ensure_mp.
-- fast (wards, gs c pact): no "human" pause before the summon; post-summon lock = actual end
-- of the cast + ready_after_cast. no_lock: k(true) as soon as the avatar appears (no command follows).
function smn_summon(gen, spell_id, name, mp, k, no_rest, fast, no_lock)
    smn_ensure_mp(gen, mp, function(has_mp)
        if not has_mp then return k(false) end
        smn_wait_until(gen, function() return smn_spell_ready(spell_id) end, 60, function(ready)
            if not ready then return k(false) end
            local pre = fast and function(f) smn_next(gen, f) end or function(f) smn_pause(gen, nil, nil, f) end
            pre(function()
                -- Interruption signaled by aftercast (smn-main): don't wait for the timeout to end
                smn_last_summon = nil
                local sent_at = os.clock()
                local function no_summon() return smn_no_summon_at ~= nil and smn_no_summon_at >= sent_at end
                local function interrupted()
                    return smn_last_summon and smn_last_summon.interrupted and smn_last_summon.name == name
                end
                send_command(('input /ma "%s" <me>'):format(name))
                smn_trace('summon', name)
                smn_wait_until(gen, function() return smn_pet() ~= nil or interrupted() or no_summon() end,
                    cfg().timeout.cast, function()
                    if not smn_pet() then
                        -- The area message may come a moment after the interruption signal
                        return smn_after(gen, 0.5, function()
                            if no_summon() then return smn_auto_stop('summoning not allowed in this area') end
                            smn_warn(name .. (interrupted() and ': summon interrupted.'
                                or ': summon failed (recast / MP?).'))
                            k(false)
                        end)
                    end
                    -- The avatar appears in memory before the casting lock ends:
                    -- wait before any /pet (Release or Blood Pact).
                    smn_trace('pet_seen', name)
                    if no_lock then return k(true) end
                    local lock = cfg().after_summon
                    if fast then
                        -- Actual end of the cast (summon aftercast, smn-main), then ready_after_cast
                        -- seconds before any /pet; without a signal, at the latest after the after_summon lock.
                        return smn_wait_until(gen, function()
                            return smn_last_summon and smn_last_summon.name == name
                        end, lock, function(seen)
                            smn_after(gen, seen and (cfg().ready_after_cast or 1.0) or 0, function() k(true) end)
                        end)
                    end
                    smn_pause(gen, lock, lock + 0.8, function() k(true) end)
                end)
            end)
        end)
    end, no_rest)
end

-- Buff active on self, by its English name (buff list in memory)
function smn_buff_active(name)
    local p = smn_me()
    if not p then return false end
    for _, id in ipairs(p.buffs or {}) do
        local b = res.buffs[id]
        if b and b.en == name then return true end
    end
    return false
end

-- Buff active on self, by its id
function smn_buff_id_active(id)
    local p = smn_me()
    if not p or not id then return false end
    for _, b in ipairs(p.buffs or {}) do
        if b == id then return true end
    end
    return false
end

-- Convert available? (RDM sub: this file is only loaded with SMN main; JA learned)
local convert_ja = res.job_abilities:with('en', 'Convert')
function smn_convert_ja() return convert_ja end
function smn_convert_known()
    if not convert_ja then return false end
    local p = smn_me()
    if not p or p.sub_job ~= 'RDM' then return false end
    local ab = windower.ffxi.get_abilities() or {}
    local list = ab.job_abilities or {}
    if list[convert_ja.id] == true then return true end
    for _, id in pairs(list) do
        if id == convert_ja.id then return true end
    end
    return false
end

-- Automatic stops
windower.register_event('zone change', function() smn_auto_stop('zone change') end)
windower.register_event('logout', function() smn_auto_stop('logout') end)
windower.register_event('status change', function(new)
    if new == 2 or new == 3 then smn_auto_stop('KO') end
end)
