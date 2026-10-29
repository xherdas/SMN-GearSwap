-- ===================================================================================================================
--  SMN-LIB: Treasure Hunter (state.TreasureMode: None / Tag / Persistent)
--    Tag (F10)        : once per mob. Your first offensive spell / JA / WS on each mob goes off with sets.TH
--                       (midcast); once it went off (aftercast, not interrupted) that mob is tagged and your later
--                       actions on it use your normal sets. Stays ON until turned off.
--                       No melee tagging: tag with a spell (Dia...).
--    Persistent (ALT+F10) : sets.TH on every offensive action and while engaged, until turned off.
--    The avatar's actions (Blood Pacts) never get TH and never tag.
--  Commands: gs c th tag | gs c th persistent (that mode ON / OFF), gs c th (cycle the modes)
--  No packets: GearSwap hooks only. Tagged mobs are remembered by id (spell.target.id) and forgotten once dead
--  or gone (windower.ffxi.get_mob_by_id, a memory read) or on zoning, so a respawn gets tagged again.
-- ===================================================================================================================

-- Modes created in get_sets (smn_setup_modes): hooks can run before that
local function th_mode() return state and state.TreasureMode and state.TreasureMode.value or 'None' end

-- Your own offensive action on a mob (the avatar's Blood Pacts excluded)
local function own_offensive(spell)
    return spell and spell.target and spell.target.type == 'MONSTER'
        and not (spell.type and spell.type:find('BloodPact'))
end

-- Mobs tagged in Tag mode: [mob id] = true
local tagged = {}

-- Forgets the mobs that are dead or gone
local function prune()
    for id in pairs(tagged) do
        local mob = windower.ffxi.get_mob_by_id(id)
        if not mob or mob.hpp == 0 or mob.status == 2 or mob.status == 3 then tagged[id] = nil end
    end
end

windower.register_event('zone change', function() tagged = {} end)

-- idle(): sets.TH over the idle / engaged set? (Persistent only)
function smn_th_idle()
    return th_mode() == 'Persistent' and player.status == 'Engaged'
end

-- midcast: sets.TH for this action?
function smn_th_wanted(spell)
    local mode = th_mode()
    if not own_offensive(spell) then return false end
    if mode == 'Persistent' then return true end
    if mode ~= 'Tag' then return false end
    prune()
    return not tagged[spell.target.id]
end

-- Equips sets.TH over the set already chosen. A hooded body (the set has head=empty, e.g. Cohort Cloak) would
-- knock the TH head off: sets.TH.Hood (a body) replaces it then, so TH stays complete.
function smn_th_equip()
    local head = gearswap.equip_list.head
    local hooded = type(head) == 'table' and head.name == 'empty' or head == 'empty'
    equip(sets.TH)
    if hooded and sets.TH.head and sets.TH.Hood then
        equip(sets.TH.Hood)
    end
end

-- aftercast: in Tag mode, the action went off on a new mob -> tagged
function smn_th_on_action(spell)
    if th_mode() ~= 'Tag' or spell.interrupted or not own_offensive(spell) then return end
    local id = spell.target.id
    if not id or tagged[id] then return end
    tagged[id] = true
    if not SMN_TH or SMN_TH.announce ~= false then
        smn_echo(('TH tagged: %s'):format(spell.target.name or '?'))
    end
end
