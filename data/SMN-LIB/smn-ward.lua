-- ===================================================================================================================
--  SMN-LIB: Blood Pact: Ward
--    Ward list in the HUD (SMN_WARD.list), cursor and checkboxes via keyboard.
--    Rotation: avatars in list order (Smart Buff: smart_priority first, then longest ward first); each avatar is summoned as soon as the
--    previous ward is done (summon_early) and waits for the Ward recast, then casts all its checked wards.
--    At the end, the previous avatar comes back (or Release if there was none; "stay": the last ward's avatar
--    stays out). In combat (previous avatar engaged), it keeps fighting until just before the Ward recast.
--    MP check includes bringing the previous avatar back. Never /heal: skipped if no MP.
--    Target: <me> for area wards, <stal> for single-target ones (<me> when solo), <t> / <stnpc> for offensive ones.
--    Auto Favor: recasts Avatar's Favor when an avatar is out without the buff, outside automation.
--  Commands: gs c ward up | down | check | clear | run [stay] | one [stay] | toggle <ward name>
--             gs c pact <pact name> [<target>] [stay]  (any pact, for game macros)
--  No packets (see smn-runner.lua).
-- ===================================================================================================================

local SEL_FILE = windower.addon_path .. 'data/SMN-USER/ward-selection.txt'
-- Your last wards (last_cast / own_end), kept across gs reload: otherwise every buff on you shows as someone else's (grey)
local TIMES_FILE = windower.addon_path .. 'data/SMN-USER/ward-timers.txt'

smn_ward = {
    entries   = {},   -- resolved: {avatar, pact, spell_id, summon_mp, mp, target, duration, known}
    cursor    = 1,
    checked   = {},   -- [pact] = true
    last_cast = {},   -- [pact] = os.time() of the last successful cast (saved in TIMES_FILE)
    own_end   = {},   -- [pact] = os.time() at which YOUR ward's buff ends (to tell it from the same buff cast by someone else)
    run       = nil,  -- rotation in progress: {index, total, done, pact, phase}
}
local W = smn_ward

local function cfg() return SMN_WARD or {} end

-- Can the ward target this type of target? (targets in resources: 1 Self, 4 Party, 32 Enemy)
local function targets_has(ja, flag, name)
    local t = ja.targets
    if type(t) == 'number' then return math.floor(t / flag) % 2 == 1 end
    if type(t) == 'table' then
        if t[name] or t[name:lower()] then return true end
        for _, v in pairs(t) do
            if type(v) == 'string' and v:lower() == name:lower() then return true end
        end
    end
    return false
end

-- Default target. Rage: <t>. Ward: <stnpc> if offensive (Mewing Lullaby), <stal> if single-target
-- (Healing Ruby, Reraise II), <me> if area. <stnpc> and <stal> open target selection.
local function default_target(ja)
    if ja.type == 'BloodPactRage' then return '<t>' end
    if targets_has(ja, 32, 'Enemy') then return '<stnpc>' end
    if targets_has(ja, 4, 'Party') then return '<stal>' end
    return '<me>'
end

-- Are there other players in the party or alliance? (trusts don't count)
function smn_has_party_players()
    local party = windower.ffxi.get_party() or {}
    local me = smn_me()
    for _, slot in ipairs({'p1', 'p2', 'p3', 'p4', 'p5', 'a10', 'a11', 'a12', 'a13', 'a14', 'a15',
                           'a20', 'a21', 'a22', 'a23', 'a24', 'a25'}) do
        local m = party[slot]
        if m and m.name and (not me or m.name ~= me.name) then
            -- Trust: spawn_type 14 (same rule as the Bars addon). A player out of zone has no mob: they count.
            local trust = m.mob and (m.mob.spawn_type == 14 or m.mob.is_npc)
            if not trust then return true end
        end
    end
    return false
end

-- Pact after which the avatar stays out (SMN_WARD.keep_avatar), e.g. Mewing Lullaby
function smn_pact_keeps(pact)
    for _, name in ipairs(cfg().keep_avatar or {}) do
        if name:lower() == pact:lower() then return true end
    end
    return false
end

-- Builds a pact entry (Ward or Rage) from its name; nil + message if unknown.
-- opts: target, status, duration (see SMN_WARD.list). The avatar comes from SMN_PACTS (smn-data).
-- Learned spells (windower.ffxi.get_spells). In the Mog House (or right after a job change), the list may
-- be empty: if no avatar is in it, we return false = "unknown", and the wards are assumed learned.
local AVATAR_SPELLS = {'Carbuncle', 'Ifrit', 'Titan', 'Leviathan', 'Garuda', 'Shiva', 'Ramuh', 'Fenrir',
                       'Diabolos', 'Cait Sith', 'Siren'}
function smn_known_spells()
    local known = windower.ffxi.get_spells()
    if type(known) ~= 'table' then return false end
    for _, name in ipairs(AVATAR_SPELLS) do
        local s = res.spells:with('en', name)
        if s and known[s.id] then return known end
    end
    return false
end

function smn_pact_entry(name, opts, known)
    opts = opts or {}
    local info = SMN_PACTS[(name or ''):lower()]
    if not info then
        smn_warn('Unknown pact: "' .. tostring(name) .. '".')
        return nil
    end
    local s  = res.spells:with('en', info.avatar)
    local ja = res.job_abilities:with('en', info.pact)
    if not s or not ja then
        smn_warn('Pact not found in resources: "' .. info.pact .. '".')
        return nil
    end
    if known == nil then known = smn_known_spells() end
    -- Status left on you. A buff named exactly like the pact wins over the resource data, which is wrong for
    -- some wards (Wind's Blessing: status 152 "Magic Shield" in the data, real buff 624 "Wind's Blessing").
    local same_name = res.buffs:with('en', ja.en)
    local status = same_name and same_name.id or ja.status
    return {
        avatar = s.en, pact = ja.en, spell_id = s.id, kind = ja.type,
        summon_mp = s.mp_cost or 0, mp = ja.mp_cost or 0, recast_id = ja.recast_id,
        target = opts.target or default_target(ja),
        status = status,          -- status left on you (Haste, Warcry, Phalanx...), nil if none
        status_name = opts.status and opts.status:lower() or nil, -- status entered by hand (by its name)
        duration = opts.duration, -- duration entered by hand, for wards without a status
        base_duration = opts.duration or ja.duration or 0, -- for the Smart Buff order (longest first)
        -- Effect name shown in the HUD, e.g. Aerial Armor -> Blink
        effect = (opts.label or opts.status or (status and res.buffs[status] and res.buffs[status].en) or ''):gsub('^%l', string.upper),
        known = (known == false) or (known[s.id] and true or false),   -- list unavailable: assumed learned
        keep = smn_pact_keeps(ja.en),  -- the avatar stays out after this pact (SMN_WARD.keep_avatar)
    }
end

---------------------------------------------------------------------------
-- LIST AND SELECTION
---------------------------------------------------------------------------
function smn_ward_resolve()
    local known = smn_known_spells()
    W.entries = {}
    for _, e in ipairs(cfg().list or {}) do
        local entry = smn_pact_entry(e.pact, e, known)
        if entry and entry.kind ~= 'BloodPactWard' then
            smn_warn('Ward: "' .. entry.pact .. '" is not a Blood Pact: Ward.')
        elseif entry then
            W.entries[#W.entries + 1] = entry
        end
    end
    if W.cursor > #W.entries then W.cursor = math.max(#W.entries, 1) end
end

local function save_selection()
    local f = io.open(SEL_FILE, 'w')
    if not f then return end
    for _, e in ipairs(W.entries) do
        if W.checked[e.pact] then f:write(e.pact .. '\n') end
    end
    f:close()
end

local function load_selection()
    W.checked = {}
    local f = io.open(SEL_FILE, 'r')
    if not f then return end
    for line in f:lines() do
        line = line:gsub('%s+$', '')
        if line ~= '' then W.checked[line] = true end
    end
    f:close()
end

local function save_times()
    local f = io.open(TIMES_FILE, 'w')
    if not f then return end
    for pact, t in pairs(W.last_cast) do
        f:write(('%s|%d|%d\n'):format(pact, t, W.own_end[pact] or 0))
    end
    f:close()
end

-- Only wards cast within the last hour: older ones have worn off anyway
local function load_times()
    local f = io.open(TIMES_FILE, 'r')
    if not f then return end
    local now = os.time()
    for line in f:lines() do
        local pact, t, own = line:match('^(.-)|(%d+)|(%d+)')
        if pact and now - tonumber(t) < 3600 then
            W.last_cast[pact] = tonumber(t)
            if tonumber(own) > 0 then W.own_end[pact] = tonumber(own) end
        end
    end
    f:close()
end

local function find_entry(name)
    name = (name or ''):lower()
    for i, e in ipairs(W.entries) do
        if e.pact:lower() == name then return i, e end
    end
    return nil
end

function smn_ward_checked_count()
    local n = 0
    for _, e in ipairs(W.entries) do
        if W.checked[e.pact] then n = n + 1 end
    end
    return n
end

-- Time remaining on the buff, nil if unknown or absent.
--  * Ward with a status: actual time of the buff on you, read from player.buff_details. This table is filled
--    by GearSwap itself (reading incoming packet 0x063); this file neither reads nor sends any packet.
--    The status may come from another source (e.g. Haste from a WHM for Hastega II).
--  * Ward without a status (Ecliptic Growl, Glittering Ruby...): duration entered in SMN_WARD.list
--    (duration = ...), counted from the last cast this session.
-- pet_aftercast of a Ward (smn-main): cast by your avatar, by hand, macro or rotation -> its timer starts over
function smn_ward_on_pact_done(name)
    W.last_cast[name] = os.time()
    W.own_end[name] = nil
    save_times()
    -- Note the end of YOUR buff without depending on the HUD (compact HUD or Wards section hidden): a few reads
    -- in the first 15 s (smn_ward_remaining records it).
    local entry
    for _, e in ipairs(W.entries) do if e.pact == name then entry = e end end
    if not entry then return end
    for _, t in ipairs({3, 8, 14}) do
        coroutine.schedule(function() pcall(smn_ward_remaining, entry) end, t)
    end
end

function smn_ward_remaining(e)
    if e.status or e.status_name then
        for _, b in pairs(player.buff_details or {}) do
            local match
            if e.status_name then
                match = b.name and b.name:lower() == e.status_name
            else
                match = b.id == e.status
            end
            if match then
                local d = b.duration
                if not (d and d > 0) then return nil end
                -- The same status may come from someone else (Haste / Haste II from a WHM / RDM for Hastega II):
                -- it still counts for Smart Buff (no need to recast over it), but the HUD shows where it comes
                -- from. Second value: true = your ward, false = someone else's. Your ward's end time is noted
                -- once, ~2 s after your avatar cast it; a buff that doesn't end then (within 5 s) isn't yours.
                local last = W.last_cast[e.pact]
                if not last then return d, false end
                local now, own = os.time(), W.own_end[e.pact]
                -- First 15 s after your ward: the buff list may still show the previous buff of the same status
                -- (recast of an active ward, lag): the end time follows each refresh of the buff, the last one
                -- in that window being yours. After that, it's fixed.
                if now - last <= 15 then
                    if not own or now + d > own + 5 then
                        W.own_end[e.pact] = now + d
                        save_times()
                    end
                    return d, true
                end
                if not own then return d, false end
                return d, math.abs(now + d - own) <= 5
            end
        end
        return nil
    end
    local t = W.last_cast[e.pact]
    if not t or not e.duration then return nil end
    local rem = e.duration - (os.time() - t)
    return rem > 0 and rem or nil
end

---------------------------------------------------------------------------
-- ROTATION
---------------------------------------------------------------------------
-- Avatar's Favor: the buff stays on you from one avatar to the next. A rotation makes sure it's active before its
-- first pact (ensure_favor); after that Auto Favor (further down) recasts it on the recalled avatar if needed.
local favor_ja = res.job_abilities:with('en', "Avatar's Favor")

-- Casts Avatar's Favor if missing (Auto Favor ON, avatar out, JA ready), then k() after the 1 s global
-- delay between two JAs. Otherwise k() right away.
local function ensure_favor(gen, k)
    if not state.AutoFavor.value or not favor_ja or smn_favor_active() then return smn_next(gen, k) end
    local p, mob = smn_me(), smn_pet()
    if not p or p.main_job_level < 55 or not mob or not smn_is_avatar(mob.name)
            or smn_ability_recast(favor_ja.recast_id) > 0 then
        return smn_next(gen, k)
    end
    if W.run then W.run.phase = "Avatar's Favor" end
    -- Confirmed by the recast too: Favor is a toggle, resending it on a late buff update would turn it off
    smn_send_confirmed(gen, 'input /ja "Avatar\'s Favor" <me>', function()
        return smn_favor_active() or smn_ability_recast(favor_ja.recast_id) > 0
    end, function(ok)
        if not ok then smn_warn("Avatar's Favor not executed.") end
        smn_after(gen, 1.0, k)
    end)
end

local function phase(text)
    if W.run then W.run.phase = text end
    smn_hud_update()
end

local function finish(gen)
    if W.run then
        smn_echo(('%s: %d/%d done.'):format(W.run.label, W.run.done, W.run.total))
    end
    W.run = nil
    smn_auto.poll = nil
    smn_auto_finish(gen)
end

-- Is the group's avatar out? Otherwise wait until the Ward recast is nearly done,
-- then Release the current avatar and summon. k(ok)
local function ensure_avatar(gen, g, k)
    local cur = smn_pet()
    if cur and cur.name == g.avatar then return smn_next(gen, k, true) end

    phase(g.avatar .. ': wait recast')
    local recast_id = g.wards[1].recast_id   -- Ward (174) or Rage (173)
    -- summon_early (default): the next avatar is summoned right away and waits out the recast itself;
    -- Avatar's Favor charges up meanwhile (its potency starts over from zero on each Release).
    -- Otherwise: summon summon_lead seconds before the end of the recast.
    local lead = cfg().summon_early ~= false and math.huge or (cfg().summon_lead or 7)
    -- In combat (the avatar that was out at the start is engaged): it keeps fighting, and the ward's avatar
    -- is only summoned just in time = its cast time + the post-summon lock + a margin.
    if W.run.combat and cur and cur.name == W.run.prev then
        local s = res.spells[g.spell_id]
        lead = (s and s.cast_time or 3) + (SMN_AUTO.ready_after_cast or 2.2) + (cfg().combat_margin or 0.5)
        phase(cur.name .. ' fighting')
    end
    smn_wait_until(gen, function() return smn_ability_recast(recast_id) <= lead end,
        cfg().recast_wait or 120, function(ready)
        if not ready then
            smn_warn('Recast too long: ' .. g.avatar .. ' skipped.')
            return k(false)
        end
        -- MP: this avatar + its first pact, + bringing back the previous avatar at the end (W.run.return_mp),
        -- so the rotation never ends without an avatar in combat.
        local need = g.summon_mp + g.wards[1].mp + (W.run.return_mp or 0)
        if smn_me().vitals.mp < need then
            smn_warn(('%s: not enough MP (%d/%d%s), skipped.'):format(g.avatar, smn_me().vitals.mp, need,
                (W.run.return_mp or 0) > 0 and (', incl. ' .. W.run.prev .. ' back') or ''))
            return k(false)
        end
        -- An interrupted summon (hit taken, movement) is retried SMN_WARD.summon_retries times
        local tries = 0
        local function attempt()
            tries = tries + 1
            phase('Summon ' .. g.avatar .. (tries > 1 and (' (' .. tries .. ')') or ''))
            smn_summon(gen, g.spell_id, g.avatar, g.summon_mp, function(ok)
                if ok then return k(true) end
                if tries > (cfg().summon_retries or 1) then return k(false) end
                smn_echo(g.avatar .. ': retrying summon.')
                smn_pause(gen, 1.0, 1.5, attempt)
            end, true, true)   -- no_rest, fast
        end
        smn_release(gen, function(released)
            if not released then
                smn_warn(g.avatar .. ': Release failed, skipped.')
                return k(false)
            end
            attempt()
        end)
    end)
end

local function run_wards(gen, wards, i, k)
    local w = wards[i]
    if not w then return smn_next(gen, k) end
    W.run.index = W.run.index + 1
    W.run.pact = w.pact
    local function next_ward() run_wards(gen, wards, i + 1, k) end

    phase('Wait recast')
    smn_wait_until(gen, function() return smn_ability_recast(w.recast_id) == 0 end, cfg().recast_wait or 120, function(ready)
        if not ready then
            smn_warn(w.pact .. ': recast too long, skipped.')
            return next_ward()
        end
        local cur = smn_pet()
        if not cur or cur.name ~= w.avatar then
            smn_warn(w.pact .. ': ' .. w.avatar .. ' not out, skipped.')
            return next_ward()
        end
        -- Keep the MP needed to bring the previous avatar back at the end (W.run.return_mp)
        local need = w.mp + (W.run.return_mp or 0)
        if smn_me().vitals.mp < need then
            smn_warn(('%s: not enough MP (%d/%d), skipped.'):format(w.pact, smn_me().vitals.mp, need))
            return next_ward()
        end
        -- Effective target: an offensive <stnpc> ward goes straight to <t> if a mob is already targeted
        -- (otherwise the <stnpc> selection would start on the avatar).
        local function enemy_targeted()
            local t = windower.ffxi.get_mob_by_target('t')
            return t and t.spawn_type == 16 and t.hpp > 0 and t.valid_target
        end
        local target = w.target
        if target == '<stnpc>' and enemy_targeted() then target = '<t>' end
        -- Single-target ward (Reraise II, Healing Ruby...): when alone (no other player, trusts not counted), on <me>
        -- Raise II revives a dead member: never on self, always the selection.
        if target == '<stal>' and w.pact ~= 'Raise II' and not smn_has_party_players() then target = '<me>' end
        if target == '<t>' and not enemy_targeted() then
            smn_warn(w.pact .. ': no enemy target (<t>), skipped.')
            return next_ward()
        end

        local pet_done_before = smn_pet_actions.done   -- end of the pact = next action finished
        local function done(ok)
            if ok then
                W.last_cast[w.pact] = os.time()
                W.run.done = W.run.done + 1
                -- Release as soon as the avatar has finished the pact (pet_aftercast), at the latest after pact_linger
                return smn_wait_until(gen, function() return smn_pet_actions.done ~= pet_done_before end,
                    SMN_AUTO.pact_linger + 1, function() smn_after(gen, 0.3, next_ward) end)
            end
            smn_warn(w.pact .. ': not executed.')
            next_ward()
        end
        local started = function() return smn_ability_recast(w.recast_id) > 0 end
        local command = ('input /pet "%s" %s'):format(w.pact, target)

        if buffactive['Astral Conduit'] then
            -- No recast under Astral Conduit: can't confirm, so send only once.
            phase(w.pact)
            send_command(command)
            smn_pause(gen, SMN_AUTO.pact_linger, SMN_AUTO.pact_linger + 0.5, function() done(true) end)
        elseif target:sub(1, 3) == '<st' then
            -- Target selection (<stal>, <stnpc>...): send only once, wait for the player to confirm
            phase('Select target')
            smn_echo(w.pact .. ': select the target (Enter), Escape to skip.')
            send_command(command)
            smn_wait_until(gen, started, cfg().stal_timeout or 20, function(ok)
                if ok then return done(true) end
                -- Skipped (Escape / timeout): let the target cursor close before the next command
                smn_warn(w.pact .. ': no target selected, skipped.')
                smn_after(gen, 1.0, next_ward)
            end)
        else
            phase(w.pact)
            smn_send_confirmed(gen, command, started, done)
        end
    end)
end

local function run_groups(gen, groups, gi, prev)
    local g = groups[gi]
    if not g then
        -- End: back to the previous avatar, or Release if there wasn't one
        phase('Returning')
        local cur = smn_pet()
        if prev and cur and cur.name == prev then return finish(gen) end
        -- Last avatar of a "keep_avatar" pact (e.g. Mewing Lullaby), or "stay" option: it stays out
        if W.run and W.run.keep and cur and cur.name == W.run.keep then return finish(gen) end
        return smn_release(gen, function()
            local s = prev and res.spells:with('en', prev)
            if not s then return finish(gen) end
            phase('Summon ' .. s.en)
            -- Previous avatar returning: hand back control as soon as it appears (no command follows);
            -- Auto Favor recasts it on its own after the summon lock.
            -- Retried like the group summons (SMN_WARD.summon_retries): an interrupted summon in combat
            -- would otherwise end the rotation without an avatar.
            local tries = 0
            local function back()
                tries = tries + 1
                smn_summon(gen, s.id, s.en, s.mp_cost or 0, function(ok)
                    if ok or tries > (cfg().summon_retries or 1) then return finish(gen) end
                    smn_echo(s.en .. ': retrying summon.')
                    smn_pause(gen, 1.0, 1.5, back)
                end, true, true, true)   -- no_rest, fast, no_lock
            end
            back()
        end)
    end

    local names = {}
    for _, w in ipairs(g.wards) do names[#names + 1] = w.pact end
    smn_echo(('%s: %s (%s).'):format(W.run.label, g.avatar, table.concat(names, ', ')))

    -- 1st avatar of the rotation: Avatar's Favor active before the first pact (Auto Favor ON). The buff stays
    -- on you from one avatar to the next, so the following wards benefit too (−3 s of recast at the start).
    local favor = (gi == 1) and ensure_favor or function(_, k) smn_next(gen, k) end
    favor(gen, function()
        ensure_avatar(gen, g, function(ok)
            if not ok then
                W.run.index = W.run.index + #g.wards
                return run_groups(gen, groups, gi + 1, prev)
            end
            favor(gen, function()
                run_wards(gen, g.wards, 1, function() run_groups(gen, groups, gi + 1, prev) end)
            end)
        end)
    end)
end

local function on_stop(reason)
    smn_echo('Ward rotation stopped' .. (reason and (': ' .. reason) or '') .. '.')
    smn_auto.poll = nil
    W.run = nil
end

-- Groups by avatar, in order of first appearance
local function group_by_avatar(list)
    local groups, by_name = {}, {}
    for _, e in ipairs(list) do
        local g = by_name[e.avatar]
        if not g then
            g = {avatar = e.avatar, spell_id = e.spell_id, summon_mp = e.summon_mp, wards = {}}
            by_name[e.avatar] = g
            groups[#groups + 1] = g
        end
        g.wards[#g.wards + 1] = e
    end
    return groups
end

-- stay: the last ward's avatar stays out at the end instead of bringing back the previous one
-- (gs c ward one stay, gs c ward run stay, gs c pact <name> stay).
local function start_rotation(list, label, stay)
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' then return smn_warn('SMN required.') end

    local usable = {}
    for _, e in ipairs(list) do
        if e.known then usable[#usable + 1] = e
        else smn_warn(e.pact .. ': ' .. e.avatar .. ' not learned, skipped.') end
    end
    if #usable == 0 then return smn_warn('No ward to cast.') end

    local cur = smn_pet()
    local prev = cur and cur.name or nil
    local groups = group_by_avatar(usable)
    local keep = nil   -- name of the avatar to keep out at the end, if its group has a "keep_avatar" pact
    for _, e in ipairs(groups[#groups].wards) do
        if e.keep then keep = groups[#groups].avatar end
    end
    if stay then keep = groups[#groups].avatar end

    -- MP kept aside to bring back the previous avatar at the end (none if it stays replaced)
    local return_mp = 0
    if prev and not keep and prev ~= groups[#groups].avatar then
        local s = res.spells:with('en', prev)
        return_mp = s and s.mp_cost or 0
    end

    smn_auto_stop('replaced by Ward rotation')
    W.run = {index = 0, total = #usable, done = 0, pact = nil, phase = '', label = label or 'Wards', keep = keep,
             prev = prev, return_mp = return_mp,
             combat = cur ~= nil and cur.status == 1}   -- previous avatar engaged: it keeps fighting (ensure_avatar)
    smn_auto.poll = 0.05   -- finer checks during the rotation (faster reaction)
    if #usable > 1 then
        smn_echo(('Wards: %d to cast (%d avatar%s).'):format(#usable, #groups, #groups > 1 and 's' or ''))
    end
    smn_auto_start('ward', function(gen) run_groups(gen, groups, 1, prev) end, on_stop)
end

---------------------------------------------------------------------------
-- SMART BUFF
---------------------------------------------------------------------------
-- Wards with more than SMN_WARD.smart_threshold seconds left AT THE END of the rotation are skipped: the time
-- left is compared to threshold + the rotation's length (smart_ward_time per ward cast), so a Hastega II with
-- 1:30 left isn't skipped from a 5-ward rotation it wouldn't outlast. The others go longest duration
-- first (base duration from the game data, or the one entered in SMN_WARD.list), list order for equal
-- durations: the shortest buffs (Crimson Howl 60 s) are cast last, so they are fresh when the fight starts.
-- Grouping by avatar (group_by_avatar) keeps the order of first appearance: an avatar casts all its wards
-- at its first ward's turn (one summon per avatar).
local function smart_order(list)
    local threshold = cfg().smart_threshold or 60
    local ward_time = cfg().smart_ward_time or 25
    local rems = {}
    for i, e in ipairs(list) do rems[i] = smn_ward_remaining(e) or 0 end
    -- Each ward taken in makes the rotation longer, which may take in another one: repeat until stable
    local take, n = {}, 0
    repeat
        local added = false
        for i in ipairs(list) do
            if not take[i] and rems[i] <= threshold + n * ward_time then
                take[i] = true
                n = n + 1
                added = true
            end
        end
    until not added
    local keep, skipped = {}, {}
    for i, e in ipairs(list) do
        if take[i] then
            keep[#keep + 1] = {e = e, rem = rems[i], i = i}
        else
            skipped[#skipped + 1] = e.pact
        end
    end
    -- Shared buff slot (SMN_SHARED_SLOTS, ascending priority): a ward is useless if a higher one of its group is
    -- active on you, or will be cast in this rotation (it would replace it right after). Shining Ruby is skipped
    -- under Wind's Blessing; Wind's Blessing still goes over Shining Ruby.
    local casting = {}
    for _, k in ipairs(keep) do casting[k.e.pact] = true end
    local function status_of(pact)
        for _, x in ipairs(W.entries) do if x.pact == pact then return x.status end end
        local b = res.buffs:with('en', pact)
        return b and b.id
    end
    local blocked = {}
    for _, group in ipairs(SMN_SHARED_SLOTS or {}) do
        for i, low in ipairs(group) do
            for j = i + 1, #group do
                local high = group[j]
                if casting[low] and (casting[high] or smn_buff_id_active(status_of(high))) then
                    blocked[low] = high
                end
            end
        end
    end
    local kept = {}
    for _, k in ipairs(keep) do
        if blocked[k.e.pact] then
            smn_echo(('Smart Buff: %s skipped (%s holds the buff slot).'):format(k.e.pact, blocked[k.e.pact]))
        else
            kept[#kept + 1] = k
        end
    end
    keep = kept

    -- SMN_WARD.smart_priority: these wards first (in that order) when they need a recast, e.g. Hastega II:
    -- recast it even with 15 s left before a ward that is down, or the Ward recast won't be ready for it.
    -- A ward still active with more than smart_threshold left (taken in only because the rotation outlasts it)
    -- isn't at risk yet: no priority, it goes as late as possible but before it wears off (5 s margin).
    local prio = {}
    for n, name in ipairs(cfg().smart_priority or {}) do prio[name:lower()] = n end
    local normal, late = {}, {}
    for _, k in ipairs(keep) do
        if k.rem > threshold then late[#late + 1] = k else normal[#normal + 1] = k end
    end
    table.sort(normal, function(a, b)
        local pa, pb = prio[a.e.pact:lower()] or math.huge, prio[b.e.pact:lower()] or math.huge
        if pa ~= pb then return pa < pb end
        local da, db = a.e.base_duration or 0, b.e.base_duration or 0
        if da ~= db then return da > db end
        return a.i < b.i
    end)
    table.sort(late, function(a, b) return a.rem < b.rem end)
    keep = normal
    local last = 0
    for _, k in ipairs(late) do
        local slot = math.floor((k.rem - 5) / ward_time) + 1   -- latest position cast before it wears off
        slot = math.max(last + 1, math.min(slot, #keep + 1))   -- after the previous late one (it wears off sooner)
        table.insert(keep, slot, k)
        last = slot
    end
    if #skipped > 0 then
        smn_echo(('Smart Buff: more than %d s left after this rotation, skipped: %s.'):format(threshold,
            table.concat(skipped, ', ')))
    end
    if #keep == 0 then
        smn_echo('Smart Buff: nothing to recast.')
    end
    local out = {}
    for _, k in ipairs(keep) do out[#out + 1] = k.e end
    return out
end

---------------------------------------------------------------------------
-- COMMANDS
---------------------------------------------------------------------------
function smn_ward_command(args)
    local sub = (args[2] or ''):lower()
    local stay = (args[3] or ''):lower() == 'stay'   -- run / one: keep the ward's avatar out at the end
    local n = #W.entries
    if sub == 'up' and n > 0 then
        W.cursor = (W.cursor - 2) % n + 1
    elseif sub == 'down' and n > 0 then
        W.cursor = W.cursor % n + 1
    elseif sub == 'check' and n > 0 then
        local e = W.entries[W.cursor]
        W.checked[e.pact] = not W.checked[e.pact] or nil
        save_selection()
    elseif sub == 'toggle' then
        local name = table.concat(args, ' ', 3)
        local i, e = find_entry(name)
        if not e then return smn_warn('Ward not in the list: ' .. name) end
        W.cursor = i
        W.checked[e.pact] = not W.checked[e.pact] or nil
        save_selection()
    elseif sub == 'clear' then
        W.checked = {}
        save_selection()
    elseif sub == 'run' then
        smn_ward_resolve()
        local list = {}
        for _, e in ipairs(W.entries) do
            if W.checked[e.pact] then list[#list + 1] = e end
        end
        if state.SmartBuff.value then list = smart_order(list) end
        if #list > 0 then start_rotation(list, nil, stay) end
    elseif sub == 'one' and n > 0 then
        smn_ward_resolve()
        start_rotation({W.entries[W.cursor]}, nil, stay)
    else
        smn_echo('gs c ward up | down | check | clear | run [stay] | one [stay] | toggle <ward name>')
    end
    smn_hud_update()
end

-- gs c pact <pact name> [<target>]: any Blood Pact (Ward or Rage), even outside the list.
-- Same flow as "This ward": the pact's avatar is summoned if needed, the pact goes off, then
-- the previous avatar comes back. Designed for game macros: /console gs c pact Spring Water
function smn_pact_command(args)
    local target, words, stay = nil, {}, false
    for i = 2, #args do
        local a = args[i]:gsub('"', '')
        if a:sub(1, 1) == '<' then target = a
        elseif a:lower() == 'stay' then stay = true   -- keep the pact's avatar out at the end
        elseif a ~= '' then words[#words + 1] = a end
    end
    local name = table.concat(words, ' ')
    if name == '' then
        return smn_echo('gs c pact <pact name> [<target>] [stay]   e.g. /console gs c pact Hastega II stay')
    end

    -- A pact from the Ward list keeps its settings (status, duration, target)
    local opts = {target = target}
    for _, e in ipairs(cfg().list or {}) do
        if (e.pact or ''):lower() == name:lower() then
            opts = {target = target or e.target, status = e.status, duration = e.duration, label = e.label}
        end
    end
    local entry = smn_pact_entry(name, opts)
    if not entry then return end
    start_rotation({entry}, 'Pact', stay)
    smn_hud_update()
end

---------------------------------------------------------------------------
-- AUTO FAVOR
---------------------------------------------------------------------------
local last_favor_try = 0
local pet_seen_id, pet_seen_at = nil, 0

-- As soon as an avatar is summoned (by hand or by a rotation), Avatar's Favor is cast,
-- after the SMN_AUTO.after_summon lock (otherwise "Unable to use job ability").
local function favor_tick()
    local mob = smn_pet()
    if not mob then
        pet_seen_id = nil
        return
    end
    if mob.id ~= pet_seen_id then
        pet_seen_id, pet_seen_at = mob.id, os.time()
    end

    if not state.AutoFavor.value or smn_auto_running() or not favor_ja then return end
    if os.time() - pet_seen_at < math.ceil(SMN_AUTO.after_summon or 3) then return end
    if os.time() - last_favor_try < 5 then return end      -- no burst if the JA fails
    if smn_favor_active() then return end
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' or p.main_job_level < 55 then return end
    if p.status ~= 0 and p.status ~= 1 then return end      -- standing or engaged only
    if not smn_is_avatar(mob.name) then return end      -- avatar only (no spirit, no Atomos)
    if smn_ability_recast(favor_ja.recast_id) > 0 then return end
    if buffactive['Invisible'] or midaction() or pet_midaction() then return end

    last_favor_try = os.time()
    send_command('input /ja "Avatar\'s Favor" <me>')
end

local last_tick = 0
windower.register_event('prerender', function()
    local now = os.time()
    if now ~= last_tick then
        last_tick = now
        favor_tick()
    end
end)

-- On load
function smn_ward_setup()
    smn_ward_resolve()
    load_selection()
    load_times()
end

-- After a zone change (leaving the Mog House, etc.), re-read the learned avatars: the spell list
-- may be incomplete when the file loads.
windower.register_event('zone change', function()
    -- pcall: after a gs reload within these 5 s, the old HUD no longer exists
    coroutine.schedule(function()
        pcall(function()
            smn_ward_resolve()
            smn_hud_update()
        end)
    end, 5)
end)
