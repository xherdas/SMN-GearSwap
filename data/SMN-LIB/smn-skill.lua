-- ===================================================================================================================
--  SMN-LIB: Summoning Magic / Blood Pacts skill-up (former smnSkill addon v2.0)
--    gs c skill pact     Combat: summons a random avatar, Assault, then Blood Pact on <t>
--    gs c skill summon   Town  : summon / release on a loop (summoning skill-up)
--    gs c skill status   Summary  |  gs c stop (or gs c skill stop) to stop
--  Settings: SMN_SKILL and SMN_AUTO in SMN-USER/user.lua. No packets (see smn-runner.lua).
-- ===================================================================================================================

local BUFF_FOOD = 251

if not smn_random_seeded then
    math.randomseed(os.time())
    math.random()
    smn_random_seeded = true
end

smn_skill = {
    mode        = nil,   -- 'pact' | 'summon' | nil
    cycles      = 0,
    skill_start = nil,
    last_avatar = nil,
    avatar_idx  = 0,
    food_id     = nil,   -- resolved id of the food item
    food_off    = false, -- disabled for the session (no more items in inventory)
    wards_used  = 0,
    converts    = 0,
    siphons     = 0,
    siphon_fails = 0,    -- Elemental Siphon failed in a row (off for the session at 2)
    heal_pending  = false, -- heal to do after Convert
    heal_notified = false,
    convert_ja  = nil,   -- {id, recast_id}
    heals       = {},    -- resolved: {avatar, spell_id, mp, pact, recast_id, disabled}
    rotations   = {},    -- resolved: {avatar, spell_id, mp, pact, recast_id}
    avatars     = {},    -- resolved : {name, spell_id, mp}
}
local st = smn_skill

local function settings() return SMN_SKILL end

function smn_skill_level()
    local p = smn_me()
    return p and p.skills and p.skills.summoning_magic or 0
end

---------------------------------------------------------------------------
-- LIST RESOLUTION (via resources + learned spells)
---------------------------------------------------------------------------
local function resolve()
    local s_cfg = settings()
    local known = windower.ffxi.get_spells() or {}
    st.rotations, st.avatars, st.heals = {}, {}, {}

    -- Convert + heals
    local cv = res.job_abilities:with('en', 'Convert')
    st.convert_ja = cv and {id = cv.id, recast_id = cv.recast_id} or nil
    for _, h in ipairs(s_cfg.convert.heals) do
        local s  = res.spells:with('en', h.avatar)
        local ja = res.job_abilities:with('en', h.pact)
        if s and known[s.id] and ja and ja.type == 'BloodPactWard' then
            st.heals[#st.heals + 1] = {
                avatar = s.en, spell_id = s.id, mp = s.mp_cost or 0,
                pact = ja.en, recast_id = ja.recast_id,
            }
        end
    end

    local function spell(name)
        local s = res.spells:with('en', name)
        if not s then smn_warn('Unknown spell: ' .. name) return nil end
        if not known[s.id] then return nil end
        return s
    end

    for _, r in ipairs(s_cfg.rotations) do
        local s  = spell(r.avatar)
        local ja = res.job_abilities:with('en', r.pact)
        if s and ja and (ja.type == 'BloodPactRage' or ja.type == 'BloodPactWard') then
            st.rotations[#st.rotations + 1] = {
                avatar = s.en, spell_id = s.id, mp = s.mp_cost or 0,
                pact = ja.en, recast_id = ja.recast_id,
            }
        elseif not ja then
            smn_warn('Unknown Blood Pact: ' .. r.pact)
        end
    end

    -- Food
    st.food_id, st.food_off = nil, false
    if s_cfg.food.enabled then
        local name = s_cfg.food.item:lower()
        for id, it in pairs(res.items) do
            if (it.en and it.en:lower() == name) or (it.enl and it.enl:lower() == name) then
                st.food_id = id
                break
            end
        end
        if not st.food_id then
            smn_warn('"' .. s_cfg.food.item .. '" not found in resources: /item tried anyway, without counting stock.')
        end
    end

    for _, name in ipairs(s_cfg.avatars) do
        local s = spell(name)
        if s then
            local entry = {name = s.en, spell_id = s.id, mp = s.mp_cost or 0}
            local wname = s_cfg.town_ward.pacts[s.en]
            local ja = wname and res.job_abilities:with('en', wname)
            if ja and ja.type == 'BloodPactWard' then
                entry.ward = {pact = ja.en, recast_id = ja.recast_id, mp = ja.mp_cost or 0}
            elseif wname then
                smn_warn('Unknown Ward: ' .. wname)
            end
            st.avatars[#st.avatars + 1] = entry
        end
    end
end

-- Random pick, avoiding the same avatar twice in a row
local function pick(list, key)
    if #list == 1 then return list[1] end
    -- Only entries of another avatar (if all are the same avatar, any of them: no endless loop)
    local others = {}
    for _, e in ipairs(list) do
        if e[key] ~= st.last_avatar then others[#others + 1] = e end
    end
    if #others == 0 then others = list end
    local choice = others[math.random(#others)]
    st.last_avatar = choice[key]
    return choice
end

---------------------------------------------------------------------------
-- FOOD
---------------------------------------------------------------------------
local function has_food_buff()
    for _, b in ipairs(smn_me().buffs or {}) do
        if b == BUFF_FOOD then return true end
    end
    return false
end

local function food_count()
    local n = 0
    local bag = windower.ffxi.get_items(0) -- inventory
    for i = 1, (bag and bag.max or 0) do
        local slot = bag[i]
        if slot and slot.id == st.food_id then n = n + slot.count end
    end
    return n
end

-- Eats if no Food buff, then k(). Never blocks the loop on failure.
local function try_food(gen, k)
    local food = settings().food
    if not food.enabled or st.food_off or has_food_buff() then return smn_next(gen, k) end
    if smn_me().status == 33 then return smn_next(gen, k) end -- impossible during /heal

    local n = st.food_id and food_count() or nil  -- nil = unknown stock
    if n == 0 then
        smn_warn(food.item .. ': none in inventory. Food disabled for this session.')
        st.food_off = true
        return smn_next(gen, k)
    end

    smn_pause(gen, nil, nil, function()
        send_command(('input /item "%s" <me>'):format(food.item))
        smn_wait_until(gen, has_food_buff, food.timeout, function(eaten)
            if eaten then
                smn_echo(n and ('%s eaten (%d left).'):format(food.item, n - 1)
                      or (food.item .. ' eaten.'))
            else
                smn_warn(food.item .. ': not eaten, retrying next cycle.')
            end
            smn_pause(gen, nil, nil, k)
        end)
    end)
end

---------------------------------------------------------------------------
-- TARGET / ASSAULT
---------------------------------------------------------------------------
local function valid_target()
    local t = windower.ffxi.get_mob_by_target('t')
    return t and t.spawn_type == 16 and t.hpp > 0 and t.valid_target
end

-- Distance (yalms) between the avatar and the <t> target, nil if either is missing
local function pet_target_distance()
    local p, t = smn_pet(), windower.ffxi.get_mob_by_target('t')
    if not p or not t then return nil end
    local dx, dy = p.x - t.x, p.y - t.y
    return math.sqrt(dx * dx + dy * dy)
end

local function pet_in_range()
    local d = pet_target_distance()
    return d ~= nil and d <= settings().assault_range
end

-- /pet "Assault" <t> then wait for the avatar to reach the target, then k()
local function assault(gen, k)
    if pet_in_range() then return smn_next(gen, k) end

    smn_send_confirmed(gen, 'input /pet "Assault" <t>', function()
        local p = smn_pet()
        return p ~= nil and (p.status == 1 or pet_in_range())
    end, function(engaged)
        if not engaged then
            smn_warn('Assault not confirmed, trying the pact anyway.')
            return k()
        end
        smn_wait_until(gen, pet_in_range, settings().timeout.assault, function(in_range)
            if in_range then return smn_pause(gen, 0.5, 1.0, k) end
            local d = pet_target_distance()
            smn_warn(('Avatar not in range (%.1f y), trying the pact anyway.'):format(d or -1))
            k()
        end)
    end)
end

---------------------------------------------------------------------------
-- CONVERT + WARD HEALING
---------------------------------------------------------------------------
local convert_known = smn_convert_known  -- shared with the Conduit loop (smn-runner)

-- Pending heal after Convert: tried at the start of each cycle when the Ward
-- recast is ready, then k(). Never blocks the loop. A Ward that fails is
-- disabled for the session and we move on to the next one.
local function try_heal(gen, k)
    if not st.heal_pending then return smn_next(gen, k) end

    if smn_me().vitals.hpp >= settings().convert.heal_done_pct then
        st.heal_pending = false
        return smn_next(gen, k)
    end

    local i = 0
    local function next_heal()
        i = i + 1
        local h = st.heals[i]
        if not h then
            smn_warn('No healing Ward usable after Convert.')
            st.heal_pending = false
            return k()
        end
        if h.disabled then return next_heal() end

        if smn_ability_recast(h.recast_id) > 0 then
            if not st.heal_notified then
                smn_echo(('Heal waiting for Ward recast (%ds), loop continues.')
                    :format(smn_ability_recast(h.recast_id)))
                st.heal_notified = true
            end
            return k()
        end

        local function do_pact()
            local hp_before = smn_me().vitals.hp
            smn_send_confirmed(gen, ('input /pet "%s" <me>'):format(h.pact),
                function() return smn_ability_recast(h.recast_id) > 0 end, function(ok)
                if ok then
                    smn_pause(gen, SMN_AUTO.pact_linger, SMN_AUTO.pact_linger + 1, function()
                        smn_echo(('%s: HP %d -> %d.'):format(h.pact, hp_before, smn_me().vitals.hp))
                        smn_release(gen, function()
                            st.heal_pending = false
                            k()
                        end)
                    end)
                else
                    h.disabled = true
                    smn_warn(('Heal "%s" not executed (level?), disabled for this session.'):format(h.pact))
                    smn_release(gen, next_heal)
                end
            end)
        end

        -- Healing avatar (release the current avatar if it's a different one)
        local function with_healer()
            if smn_pet() then return do_pact() end
            smn_summon(gen, h.spell_id, h.avatar, h.mp, function(ok)
                if ok then do_pact() else smn_release(gen, next_heal) end
            end)
        end

        local cur = smn_pet()
        if cur and cur.name ~= h.avatar then
            smn_release(gen, with_healer)
        else
            with_healer()
        end
    end
    next_heal()
end

-- Convert when MP <= threshold (heal afterwards), then k(). Never blocks the loop on failure.
local function try_convert(gen, k)
    if not settings().convert.enabled or not convert_known() then return smn_next(gen, k) end
    local p = smn_me()
    if p.vitals.mp > settings().convert.mp_at then return smn_next(gen, k) end
    if p.vitals.hp <= p.vitals.mp then return smn_next(gen, k) end             -- no gain
    if smn_ability_recast(st.convert_ja.recast_id) > 0 then return smn_next(gen, k) end

    local mp_before = p.vitals.mp
    local function go()
        smn_pause(gen, nil, nil, function()
            smn_send_confirmed(gen, 'input /ja "Convert" <me>',
                function() return smn_ability_recast(st.convert_ja.recast_id) > 0 end, function(ok)
                if not ok then
                    smn_warn('Convert not executed.')
                    return k()
                end
                st.converts = st.converts + 1
                smn_after(gen, 1, function()
                    local q = smn_me()
                    smn_echo(('Convert: MP %d -> %d | HP %d.'):format(mp_before, q.vitals.mp, q.vitals.hp))
                    st.heal_pending, st.heal_notified = true, false
                    smn_pause(gen, nil, nil, k)
                end)
            end)
        end)
    end

    if p.status == 33 then                                   -- get out of /heal
        send_command('input /heal off')
        smn_wait_until(gen, function() return smn_me().status ~= 33 end, 5, go)
    else
        go()
    end
end

-- Elemental Siphon (free MP) when it's ready and the whole estimate fits in the missing MP, then k().
-- The spirit is released afterwards; the cycle summons its own avatar. Never blocks the loop on failure.
local siphon_ja = res.job_abilities:with('en', 'Elemental Siphon')
local function siphon_known()
    if not siphon_ja then return false end
    local list = (windower.ffxi.get_abilities() or {}).job_abilities or {}
    if list[siphon_ja.id] == true then return true end
    for _, id in pairs(list) do
        if id == siphon_ja.id then return true end
    end
    return false
end

local function try_siphon(gen, k)
    local c = settings().siphon
    if not c or not c.enabled or st.siphon_fails >= 2 or not siphon_known() then return smn_next(gen, k) end
    if smn_ability_recast(siphon_ja.recast_id) > 0 then return smn_next(gen, k) end
    local p = smn_me()
    local est = smn_siphon_estimate and smn_siphon_estimate()
    if not est or p.vitals.max_mp - p.vitals.mp < est then return smn_next(gen, k) end

    local function go()
        smn_siphon_steps(gen, function(ok)
            if ok then
                st.siphons, st.siphon_fails = st.siphons + 1, 0
            else
                st.siphon_fails = st.siphon_fails + 1
                if st.siphon_fails >= 2 then smn_warn('Elemental Siphon: off for this skill-up session.') end
            end
            smn_release(gen, function() smn_pause(gen, nil, nil, k) end)
        end)
    end
    if p.status == 33 then                                   -- get out of /heal
        send_command('input /heal off')
        smn_wait_until(gen, function() return smn_me().status ~= 33 end, 5, go)
    else
        go()
    end
end

-- Start of each cycle: food, Siphon, Convert, Siphon again if it became worth it, heal, then k().
-- MP sources in order: Elemental Siphon (free), Convert, /heal (in smn_summon, when MP is short).
local function prelude(gen, k)
    try_food(gen, function()
        try_siphon(gen, function()
            try_convert(gen, function()
                try_siphon(gen, function()
                    try_heal(gen, k)
                end)
            end)
        end)
    end)
end

---------------------------------------------------------------------------
-- CYCLES (each cycle ends with k())
---------------------------------------------------------------------------
local function cycle_pact(gen, k)
    local function finish()
        smn_release(gen, function()
            st.cycles = st.cycles + 1
            smn_pause(gen, nil, nil, k)
        end)
    end

    local function run()
        prelude(gen, function()
            local r = pick(st.rotations, 'avatar')

            -- Wait for the Rage/Ward recast BEFORE summoning (avoids wasting MP)
            smn_wait_until(gen, function() return smn_ability_recast(r.recast_id) == 0 end, 180, function(ready)
                if not ready then return k() end

                smn_summon(gen, r.spell_id, r.avatar, r.mp, function(out)
                    if not out then
                        -- Not enough MP and no way to rest (engaged): stop instead of retrying forever
                        local p = smn_me()
                        if p and p.vitals.mp < r.mp then return smn_auto_stop('not enough MP') end
                        -- in case the avatar came out despite the timeout
                        return smn_release(gen, function() smn_pause(gen, 2, 3, k) end)
                    end

                    local function do_pact()
                        if not valid_target() then return finish() end
                        -- The pact went off when the recast starts
                        smn_send_confirmed(gen, ('input /pet "%s" <t>'):format(r.pact),
                            function() return smn_ability_recast(r.recast_id) > 0 end, function(ok)
                            if ok then
                                smn_pause(gen, SMN_AUTO.pact_linger, SMN_AUTO.pact_linger + 1, finish)
                            else
                                smn_warn(r.pact .. ': not executed (distance / target / level?).')
                                finish()
                            end
                        end)
                    end

                    -- Send the avatar into contact before the pact (otherwise "too far")
                    if valid_target() then assault(gen, do_pact) else do_pact() end
                end)
            end)
        end)
    end

    if valid_target() then return run() end
    smn_warn('No valid enemy target (<t>). Waiting...')
    smn_wait_until(gen, valid_target, 120, function(found)
        if not found then return smn_auto_stop('no target') end
        run()
    end)
end

-- TOWN mode: if the Ward recast is ready, cast the avatar's Ward on self
-- (extra skill-up chance), then k(). A Ward that fails is disabled for the session.
local function town_ward(gen, a, k)
    local w = a.ward
    if not settings().town_ward.enabled or not w or w.disabled then return smn_next(gen, k) end
    if st.heal_pending then return smn_next(gen, k) end -- keep the Ward recast for healing
    if smn_ability_recast(w.recast_id) > 0 then return smn_next(gen, k) end
    if smn_me().vitals.mp < w.mp + a.mp then return smn_next(gen, k) end -- keep enough to summon the next one

    smn_send_confirmed(gen, ('input /pet "%s" <me>'):format(w.pact),
        function() return smn_ability_recast(w.recast_id) > 0 end, function(ok)
        if ok then
            st.wards_used = st.wards_used + 1
            return smn_pause(gen, SMN_AUTO.pact_linger, SMN_AUTO.pact_linger + 1, k)
        end
        w.disabled = true
        smn_warn(('%s: Ward "%s" not executed (level / zone?), disabled for this session.')
            :format(a.name, w.pact))
        k()
    end)
end

local function cycle_summon(gen, k)
    prelude(gen, function()
        local a
        if settings().summon_order == 'random' then
            a = pick(st.avatars, 'name')
        else
            st.avatar_idx = st.avatar_idx % #st.avatars + 1
            a = st.avatars[st.avatar_idx]
        end
        smn_summon(gen, a.spell_id, a.name, a.mp, function(out)
            if not out then return smn_pause(gen, nil, nil, k) end
            town_ward(gen, a, function()
                smn_release(gen, function()
                    st.cycles = st.cycles + 1
                    smn_pause(gen, nil, nil, k)
                end)
            end)
        end)
    end)
end

local function loop(gen)
    local p = smn_me()
    if not p or p.main_job ~= 'SMN' then return smn_auto_stop('SMN required') end
    if p.status == 2 or p.status == 3 then return smn_auto_stop('KO') end

    local cycle = st.mode == 'pact' and cycle_pact or cycle_summon
    cycle(gen, function() loop(gen) end)
end

---------------------------------------------------------------------------
-- START / STOP / STATUS
---------------------------------------------------------------------------
local MODE_LABELS = {pact = 'COMBAT', summon = 'TOWN'}

function smn_skill_mode_label()
    return st.mode and MODE_LABELS[st.mode] or nil
end

function smn_skill_report()
    local gained = st.skill_start and (smn_skill_level() - st.skill_start) or 0
    smn_echo(('Skill %s | Cycles: %d | Wards: %d | Siphons: %d | Converts: %d | Summoning skill: %d (%+d)')
        :format(smn_skill_mode_label() or 'stopped', st.cycles, st.wards_used, st.siphons, st.converts,
            smn_skill_level(), gained))
end

local function on_stop(reason)
    smn_echo('Skill-up stopped' .. (reason and (': ' .. reason) or '') .. '.')
    smn_skill_report()
    st.mode = nil
end

function smn_skill_start(mode)
    resolve()
    local list = mode == 'pact' and st.rotations or st.avatars
    if #list == 0 then
        smn_warn('No usable avatar/pact for this mode (spells not learned?).')
        return
    end

    smn_auto_stop('mode change')
    st.mode        = mode
    st.cycles      = 0
    st.skill_start = smn_skill_level()
    st.last_avatar = nil
    st.avatar_idx  = 0
    st.wards_used  = 0
    st.converts    = 0
    st.siphons, st.siphon_fails = 0, 0
    st.heal_pending, st.heal_notified = false, false

    smn_echo(('Skill-up: starting %s mode (%d entries). %s / gs c stop to stop.')
        :format(MODE_LABELS[mode], #list, smn_key_labels.stop or 'gs c stop'))
    smn_auto_start('skill', function(gen)
        smn_release(gen, function() loop(gen) end)
    end, on_stop)
end
