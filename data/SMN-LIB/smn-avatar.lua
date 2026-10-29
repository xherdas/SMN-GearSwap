-- ===================================================================================================================
--  SMN-LIB: avatar tools
--    gs c siphon    Elemental Siphon in one command: spirit of the weather element (or the day's), Siphon,
--                   Release, then the previous avatar comes back. The Siphon set (day / weather) comes from smn-main.
--    gs c resummon  Resummons the last avatar (after its death or a Release).
--    Alerts (chat): avatar death, low MP with an avatar out (SMN_ALERTS in user.lua).
--    Siphon hint (HUD): the Siphon recast dot turns gold and blinks when it's a good time to Siphon (SMN_SIPHON).
--    gs c atomos    Atomos on the target (Deconstruction, Chronoshift, then it leaves), then the previous
--                   avatar comes back.
--    Atomos hint (HUD): buffs seen on the target ("Dispel: Haste, Protect"), the Atomos recast dot turns gold and
--                   blinks when Atomos is ready and the target has one (SMN_ATOMOS).
--  No packets sent. Enemy buffs come from Windower's 'action' / 'action message' events (read only, the data
--  Battlemod uses to write the chat).
-- ===================================================================================================================

local SPIRITS = {
    Fire = 'Fire Spirit', Ice = 'Ice Spirit', Wind = 'Air Spirit', Earth = 'Earth Spirit',
    Lightning = 'Thunder Spirit', Water = 'Water Spirit', Light = 'Light Spirit', Dark = 'Dark Spirit',
}

local function acfg() return SMN_ALERTS or {} end

smn_avatar = {
    last = nil,   -- last avatar (not spirits) seen out, for gs c resummon
}
local A = smn_avatar

-- Element that each element weakens (elemental cycle; Light and Dark oppose each other)
local WEAKENS = {
    Fire = 'Ice', Ice = 'Wind', Wind = 'Earth', Earth = 'Lightning', Lightning = 'Water', Water = 'Fire',
    Light = 'Dark', Dark = 'Light',
}
local ELEMENT_ORDER = {'Fire', 'Ice', 'Wind', 'Earth', 'Lightning', 'Water', 'Light', 'Dark'}

-- Spirit to summon, among those learned: weather element, otherwise the day's, otherwise a spirit the day
-- doesn't weaken, otherwise any. Returns spirit name, element (nil if none learned).
local function siphon_spirit()
    local known = windower.ffxi.get_spells() or {}
    local function learned(element)
        local s = SPIRITS[element] and res.spells:with('en', SPIRITS[element])
        return s and known[s.id]
    end
    local w, day = world.weather_element, world.day_element
    local choices = {}
    if w and w ~= 'None' then choices[#choices + 1] = w end
    choices[#choices + 1] = day
    for _, e in ipairs(ELEMENT_ORDER) do
        if e ~= WEAKENS[day] then choices[#choices + 1] = e end
    end
    for _, e in ipairs(ELEMENT_ORDER) do choices[#choices + 1] = e end
    for _, e in ipairs(choices) do
        if learned(e) then return SPIRITS[e], e end
    end
    return nil, nil
end

-- Avatar to bring back afterwards (not a spirit, nor Atomos which leaves on its own)
function smn_is_avatar(name)
    return name and not name:find('Spirit') and name ~= 'Atomos'
end

local function summon_back(gen, name, k)
    local s = name and res.spells:with('en', name)
    if not s then return smn_next(gen, k) end
    smn_summon(gen, s.id, s.en, s.mp_cost or 0, function() k() end, true, true, true)   -- no_rest, fast, no_lock
end

---------------------------------------------------------------------------
-- ELEMENTAL SIPHON
---------------------------------------------------------------------------
local siphon_ja = res.job_abilities:with('en', 'Elemental Siphon')

---------------------------------------------------------------------------
-- SIPHON HINT
---------------------------------------------------------------------------
local function scfg() return SMN_SIPHON or {} end

-- Day / weather bonus for an element: +10 % day, +10 % / +15 % single / double weather, the same as a penalty
-- when the day / weather element weakens it (cap 1.4)
local function siphon_multiplier(e)
    local m, day, w = 1, world.day_element, world.weather_element
    if day == e then m = m + 0.1 elseif WEAKENS[day] == e then m = m - 0.1 end
    local wb = (world.weather_intensity == 2) and 0.15 or 0.1
    if w == e then m = m + wb elseif w and WEAKENS[w] == e then m = m - wb end
    return math.min(m, 1.4)
end

-- Estimated MP returned by Elemental Siphon with the spirit gs c siphon would pick (bg-wiki formula):
-- floor(floor(min(skill, 700) * 1.05 - 55 + gear) * day / weather) + job points, at least 50.
-- Returns MP, spirit name (nil if no spirit learned).
function smn_siphon_estimate()
    local spirit, e = siphon_spirit()
    local p = windower.ffxi.get_player()
    if not spirit or not p then return nil end
    local c = scfg()
    local skill = c.skill or (p.skills and p.skills.summoning_magic) or 0
    local mp = math.floor(math.floor(math.min(skill, 700) * 1.05 - 55 + (c.gear or 0)) * siphon_multiplier(e))
        + (c.jp or 0)
    return math.max(mp, 50), spirit
end

-- Good time to Siphon? Siphon ready, nothing running, enough MP missing for the estimate (or part of it once
-- Siphon has been ready for a while: its recast is only 5 min), and in combat a Rage recast long enough for
-- the whole cycle (Release, spirit, Siphon, resummon). Returns true + estimate.
local siphon_ready_since = nil
function smn_siphon_hint()
    local c = scfg()
    if c.hint == false or not siphon_ja then return false end
    local p = windower.ffxi.get_player()
    if not p or p.main_job ~= 'SMN' then return false end
    if smn_ability_recast(siphon_ja.recast_id) > 0 then
        siphon_ready_since = nil
        return false
    end
    siphon_ready_since = siphon_ready_since or os.clock()
    if smn_auto.task or (smn_rage and smn_rage.seq) or buffactive['Apogee'] or buffactive['Astral Conduit'] then
        return false
    end
    -- window = false: Siphon is worth it, but a Rage is almost ready (steady gold instead of blinking)
    local window = not (pet.isvalid and pet.status == 'Engaged' and smn_ability_recast(173) < (c.cycle or 12))
    local est = smn_siphon_estimate()
    if not est then return false end
    local missing = p.vitals.max_mp - p.vitals.mp
    if missing >= est then return true, est, window end
    if os.clock() - siphon_ready_since >= (c.wait or 60) and missing >= est * (c.partial or 0.5) then
        return true, est, window
    end
    return false
end

-- Elemental Siphon steps inside a running automation (gs c siphon, skill-up loop): spirit out (Release of the
-- current pet first), Siphon, then k(ok) with the spirit still out (the caller releases it / resummons).
function smn_siphon_steps(gen, k)
    local spirit_name, element = siphon_spirit()
    local spirit = spirit_name and res.spells:with('en', spirit_name)
    if not spirit or not siphon_ja then
        smn_warn('Elemental Siphon: no elemental spirit learned.')
        return smn_next(gen, k, false)
    end
    smn_echo(('Elemental Siphon: %s (%s).'):format(spirit.en, element))
    local function do_siphon()
        local mp_before = smn_me().vitals.mp
        smn_send_confirmed(gen, 'input /ja "Elemental Siphon" <me>',
            function() return smn_ability_recast(siphon_ja.recast_id) > 0 end, function(ok)
            if not ok then
                smn_warn('Elemental Siphon: not executed.')
                return k(false)
            end
            smn_after(gen, 1, function()
                smn_echo(('Elemental Siphon: MP %d -> %d.'):format(mp_before, smn_me().vitals.mp))
                k(true)
            end)
        end)
    end
    local mob = smn_pet()
    if mob and mob.name == spirit.en then return do_siphon() end
    smn_release(gen, function()
        smn_summon(gen, spirit.id, spirit.en, spirit.mp_cost or 0, function(ok)
            if not ok then return k(false) end
            do_siphon()
        end, true, true)
    end)
end

function smn_siphon()
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' then return smn_warn('SMN required.') end
    if not siphon_ja then return end
    if smn_ability_recast(siphon_ja.recast_id) > 0 then
        return smn_warn(('Elemental Siphon: on recast (%ds).'):format(smn_ability_recast(siphon_ja.recast_id)))
    end
    if not siphon_spirit() then return smn_warn('Elemental Siphon: no elemental spirit learned.') end

    local cur = smn_pet()
    local prev = cur and smn_is_avatar(cur.name) and cur.name or A.last

    smn_auto_stop('replaced by Elemental Siphon')
    smn_auto_start('siphon', function(gen)
        smn_siphon_steps(gen, function()
            smn_release(gen, function()
                summon_back(gen, prev, function() smn_auto_finish(gen) end)
            end)
        end)
    end, function(reason)
        smn_echo('Elemental Siphon stopped' .. (reason and (': ' .. reason) or '') .. '.')
    end)
end

---------------------------------------------------------------------------
-- ATOMOS: buffs on enemies, HUD hint, gs c atomos
---------------------------------------------------------------------------
local atomos_spell = res.spells:with('en', 'Atomos')
local function tcfg() return SMN_ATOMOS or {} end

-- Action messages (res.action_messages) whose param is the buff gained / lost by the target
local GAINS = S{186, 194, 205, 230, 266, 280, 319}   -- "<target> gains the effect of <buff>"
local LOSES = S{64, 159, 168, 204, 206, 321, 322, 341, 342, 343, 344, 350, 378, 453, 531, 647, 805, 806}
-- "<n> of <target>'s effects disappear": which ones is unknown, the list is cleared
local LOSES_SOME = S{231, 401, 405, 757, 792}

local mob_buffs = {}   -- [enemy id] = {[buff id] = os.clock() when gained}

local function is_enemy(mob) return mob and mob.is_npc and mob.spawn_type == 16 end

local function on_message(id, msg, param)
    if GAINS:contains(msg) then
        if not is_enemy(windower.ffxi.get_mob_by_id(id)) then return end
        mob_buffs[id] = mob_buffs[id] or {}
        mob_buffs[id][param] = os.clock()
    elseif mob_buffs[id] and LOSES_SOME:contains(msg) then
        mob_buffs[id] = nil
    elseif mob_buffs[id] and LOSES:contains(msg) then
        mob_buffs[id][param] = nil
    end
end

windower.register_event('action', function(act)
    for _, t in ipairs(act.targets or {}) do
        for _, a in ipairs(t.actions or {}) do
            on_message(t.id, a.message, a.param)
            if a.has_add_effect then on_message(t.id, a.add_effect_message, a.add_effect_param) end
        end
    end
end)
windower.register_event('action message', function(actor_id, target_id, actor_index, target_index, msg, param)
    on_message(target_id, msg, param)
end)
windower.register_event('zone change', function() mob_buffs = {} end)

-- Dispellable buffs seen on an enemy (names, most recent first); forgets dead / gone enemies and old entries
function smn_enemy_buffs(id)
    local list = id and mob_buffs[id]
    if not list then return {} end
    local mob = windower.ffxi.get_mob_by_id(id)
    if not mob or mob.hpp == 0 or mob.status == 2 or mob.status == 3 then
        mob_buffs[id] = nil
        return {}
    end
    local ignore = S(tcfg().ignore or {})
    local expire, now, seen = tcfg().expire or 300, os.clock(), {}
    for buff, at in pairs(list) do
        local b = res.buffs[buff]
        if now - at > expire then list[buff] = nil
        elseif b and not ignore:contains(b.en) then seen[#seen + 1] = {name = b.en, at = at} end
    end
    table.sort(seen, function(x, y) return x.at > y.at end)
    local names = {}
    for i, e in ipairs(seen) do names[i] = e.name end
    return names
end

function smn_atomos_known()
    local known = windower.ffxi.get_spells() or {}
    return atomos_spell ~= nil and known[atomos_spell.id] == true
end

local function atomos_recast()
    return ((windower.ffxi.get_spell_recasts() or {})[atomos_spell.id] or 0) / 60
end

-- Good time for Atomos? Ready, enough MP, nothing running and the target has a dispellable buff.
-- Returns true + window (false: your avatar fights and a Rage is almost ready, see SMN_ATOMOS.cycle).
function smn_atomos_hint()
    local c = tcfg()
    if c.hint == false or not smn_atomos_known() then return false end
    local p = windower.ffxi.get_player()
    if not p or p.main_job ~= 'SMN' or p.vitals.mp < (atomos_spell.mp_cost or 50) or atomos_recast() > 0 then
        return false
    end
    if smn_auto.task or (smn_rage and smn_rage.seq) or buffactive['Apogee'] or buffactive['Astral Conduit'] then
        return false
    end
    local t = windower.ffxi.get_mob_by_target('t')
    if not is_enemy(t) or #smn_enemy_buffs(t.id) == 0 then return false end
    local window = not (pet.isvalid and pet.status == 'Engaged' and smn_ability_recast(173) < (c.cycle or 20))
    return true, window
end

function smn_atomos()
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' then return smn_warn('SMN required.') end
    if not smn_atomos_known() then return smn_warn('Atomos: not learned.') end
    local t = windower.ffxi.get_mob_by_target('t')
    if not is_enemy(t) then return smn_warn('Atomos: target an enemy.') end
    if atomos_recast() > 0 then return smn_warn(('Atomos: on recast (%ds).'):format(math.ceil(atomos_recast()))) end
    if p.vitals.mp < (atomos_spell.mp_cost or 50) then return smn_warn('Atomos: not enough MP.') end

    local cur = smn_pet()
    local prev = cur and smn_is_avatar(cur.name) and cur.name or A.last
    smn_auto_stop('replaced by Atomos')
    smn_echo(('Atomos on %s.'):format(t.name))
    smn_auto_start('atomos', function(gen)
        local function back()
            smn_release(gen, function()
                summon_back(gen, prev, function() smn_auto_finish(gen) end)
            end)
        end
        -- Release first: the cast works whether or not Atomos would replace the avatar on its own
        smn_release(gen, function()
            local now = windower.ffxi.get_mob_by_target('t')
            if not now or now.id ~= t.id then
                smn_warn('Atomos: target changed, cancelled.')
                return back()
            end
            smn_last_summon = nil
            send_command('input /ma "Atomos" <t>')
            smn_trace('summon', 'Atomos')
            -- End of the cast (summon aftercast, smn-main)
            smn_wait_until(gen, function() return smn_last_summon and smn_last_summon.name == 'Atomos' end,
                SMN_AUTO.timeout.cast, function(done)
                if not done or smn_last_summon.interrupted then
                    smn_warn('Atomos: ' .. (done and 'interrupted.' or 'not cast.'))
                    return back()
                end
                -- Atomos appears, uses its two Blood Pacts on its own and leaves: no Release, the previous
                -- avatar comes back once it's gone (F12 / another automation cancels the wait)
                local function is_atomos() local m = smn_pet() return m and m.name == 'Atomos' end
                smn_wait_until(gen, is_atomos, 5, function()
                    smn_wait_until(gen, function() return not is_atomos() end, 3600, back, 0.5)
                end)
            end)
        end)
    end, function(reason)
        smn_echo('Atomos stopped' .. (reason and (': ' .. reason) or '') .. '.')
    end)
end

---------------------------------------------------------------------------
-- RESUMMON
---------------------------------------------------------------------------
function smn_resummon()
    local cur = smn_pet()
    if cur then return smn_echo(cur.name .. ' is already out.') end
    if not A.last then return smn_warn('No avatar to resummon.') end
    local name = A.last
    smn_auto_stop('replaced by resummon')
    smn_auto_start('resummon', function(gen)
        summon_back(gen, name, function() smn_auto_finish(gen) end)
    end)
end

---------------------------------------------------------------------------
-- ALERTS (avatar death, low MP)
---------------------------------------------------------------------------
local seen = nil        -- {name, hpp, status} from the last pass with an avatar
local mp_alerted = false

local function check_alerts()
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' then return end
    local mob = smn_pet()

    if mob then
        if smn_is_avatar(mob.name) then A.last = mob.name end
        seen = {name = mob.name, hpp = mob.hpp or 100, status = mob.status}
    elseif seen then
        -- The avatar disappeared: at 0 % HP (or dead), it's a death, not a Release
        local released = smn_release_at and (os.clock() - smn_release_at) < 5
        if acfg().death ~= false and not released and seen.name ~= 'Atomos' and (seen.hpp == 0 or seen.status == 2 or seen.status == 3) then
            local key = smn_key_labels.resummon
            smn_warn(('%s died! %s'):format(seen.name, key and (key .. ' to resummon.') or '(gs c resummon)'))
        end
        seen = nil
    end

    -- Low MP with an avatar out: one alert, then nothing more until MP has recovered
    local low = acfg().mp_low or 300
    if mob and p.vitals.mp < low then
        if not mp_alerted then
            smn_warn(('Low MP: %d (%s out).'):format(p.vitals.mp, mob.name))
            mp_alerted = true
        end
    elseif p.vitals.mp >= low + (acfg().mp_margin or 100) then
        mp_alerted = false
    end
end

local last_check = 0
windower.register_event('prerender', function()
    local now = os.clock()
    if now - last_check >= 0.5 then   -- avatar death / low MP: within half a second
        last_check = now
        check_alerts()
    end
end)
