-- ===================================================================================================================
--  SMN-LIB: HUD
--  The text is rebuilt every second (and after each command), then sent only if it changed.
--  Sections: Avatar, Recasts, Rage, Wards, Skill-up, Options. Can be hidden
--  (gs c hub avatar|recasts|rage|wards|auto|modes|options|all),
--  compact version (gs c hub lite), keys shown or not (gs c hub keybinds).
-- ===================================================================================================================
texts = require('texts')
res = require('resources')

local C_TITLE = '\\cs(255, 115, 0)'
local C_LABEL = '\\cs(125, 125, 0)'
local C_KEY   = '\\cs(150, 150, 150)'
local C_ON    = '\\cs(32, 255, 32)'
local C_OFF   = '\\cs(255, 32, 32)'
local C_DIM   = '\\cs(125, 125, 125)'
local C_EFFECT = '\\cs(230, 200, 130)'  -- ward effect (Haste, Blink...)
local C_GOLD  = '\\cs(255, 200, 0)'     -- Siphon hint

-- Color of each avatar, based on its element
local AVATAR_COLORS = {
    ['Garuda']    = '\\cs(90, 230, 90)',    -- wind
    ['Siren']     = '\\cs(90, 220, 180)',   -- wind
    ['Ifrit']     = '\\cs(255, 85, 60)',    -- fire
    ['Titan']     = '\\cs(220, 175, 70)',   -- earth
    ['Leviathan'] = '\\cs(70, 140, 255)',   -- water
    ['Shiva']     = '\\cs(150, 225, 255)',  -- ice
    ['Ramuh']     = '\\cs(190, 120, 255)',  -- lightning
    ['Carbuncle'] = '\\cs(255, 255, 210)',  -- light
    ['Cait Sith'] = '\\cs(255, 165, 210)',  -- light
    ['Fenrir']    = '\\cs(200, 200, 225)',  -- dark (moon)
    ['Diabolos']  = '\\cs(165, 115, 210)',  -- dark
}

local function avatar_name(name)
    return (AVATAR_COLORS[name] or '\\cs(130, 190, 255)') .. name .. '\\cr'
end
local C_END   = '\\cr'

-- Section titles: added as {title = label} (label may contain colors), then stretched with '=' to the
-- width of the widest line (fit_titles). The HUD font is Arial Bold (proportional): widths are
-- estimated from its character widths (1/1000 em), close enough for the titles to line up with the content.
local ARIAL = {
    [' '] = 278, ['='] = 584, ['+'] = 584, ['>'] = 584, ['<'] = 584, ['%'] = 889, ['('] = 333, [')'] = 333,
    ['-'] = 333, [':'] = 333, ['.'] = 278, [','] = 278, ['/'] = 278, ['['] = 333, [']'] = 333, ["'"] = 238,
    ['|'] = 280, ['*'] = 389, f = 333, i = 278, j = 278, l = 278, m = 889, r = 389, t = 333, w = 778,
    a = 556, c = 556, e = 556, k = 556, s = 556, v = 556, x = 556, y = 556, z = 500,
    ['0'] = 556, ['1'] = 556, ['2'] = 556, ['3'] = 556, ['4'] = 556, ['5'] = 556, ['6'] = 556, ['7'] = 556,
    ['8'] = 556, ['9'] = 556,
    A = 722, B = 722, C = 722, D = 722, E = 667, F = 611, G = 778, H = 722, I = 278, J = 556, K = 722,
    L = 611, M = 833, N = 722, O = 778, P = 667, Q = 778, R = 722, S = 667, T = 611, U = 722, V = 667,
    W = 944, X = 667, Y = 667, Z = 611,
}
local function text_width(s)
    s = s:gsub('\\cs%b()', ''):gsub('\\cr', '')
    local w = 0
    for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        w = w + (#ch > 1 and 600 or ARIAL[ch] or 611)   -- other letters: 611; multibyte (ready mark): ~600
    end
    return w
end

local function fit_titles(lines)
    local widest = 0
    for _, l in ipairs(lines) do
        if type(l) == 'string' then widest = math.max(widest, text_width(l)) end
    end
    for i, l in ipairs(lines) do
        if type(l) == 'table' then
            local free = widest - text_width(' ' .. l.title .. ' ')
            local n = math.max(5, math.floor(free / ARIAL['='] / 2))
            local bar = ('='):rep(n)
            lines[i] = C_TITLE .. bar .. ' ' .. l.title .. C_TITLE .. ' ' .. bar .. C_END
        end
    end
end

-- Key action (smn-keybinds) tied to each toggle, to show the key in the HUD
local toggle_actions = {
    AutoFavor = 'auto_favor', SmartBuff = 'smart_buff', AccMode = 'acc_mode', ImpactDebuff = 'impact', Empy = 'empy', ForceIlvl = 'force_ilvl',
    LagMode = 'lag_mode', TreasureMode = 'th', SacTorque = 'sac_torque',
    AutoRemedy = 'auto_remedy', AutoEcho = 'auto_echo', WeaponLock = 'weapon_lock', Kiting = 'kiting',
}

-- Tracked recasts: Rage and Ward have fixed recast_ids, the others are resolved from resources
-- (SMN_HUD.recasts_per_line per line, 3 by default: 4 gets too wide once the timers run)
local recast_list = {
    {label = 'Rage',      id = 173},
    {label = 'Ward',      id = 174},
    {label = 'Apogee',    ability = 'Apogee'},
    {label = 'Conduit',   ability = 'Astral Conduit'},
    {label = 'Flow',      id = 0},   -- Astral Flow (2-hour recast)
    {label = 'Mana Cede', ability = 'Mana Cede'},
    {label = 'Siphon',    ability = 'Elemental Siphon', hint = 'siphon'},   -- gold, blinking: good time (smn-avatar)
    {label = 'Atomos',    spell = 847, hint = 'atomos', when = function() return smn_atomos_known() end},
    {label = 'Convert',   ability = 'Convert', when = function() return smn_convert_known() end},  -- /RDM only
}
local RECASTS_PER_LINE = (SMN_HUD and SMN_HUD.recasts_per_line) or 3
for _, r in ipairs(recast_list) do
    if not r.id and r.ability then
        local ja = res.job_abilities:with('en', r.ability)
        r.id = ja and ja.recast_id
    end
end

local favor_buff = res.buffs:with('en', "Avatar's Favor")
local favor_buff_id = favor_buff and favor_buff.id

-- Avatar's Favor active? (buff list in memory)
function smn_favor_active()
    local p = windower.ffxi.get_player()
    if not p or not favor_buff_id then return false end
    for _, b in ipairs(p.buffs or {}) do
        if b == favor_buff_id then return true end
    end
    return false
end

local hud = nil
local last_text = nil

local function key_label(action)
    if not state.HudKeybinds.value or not action then return '' end
    local l = smn_key_labels[action]
    return l and (C_KEY .. l .. C_END .. ' ') or ''
end

local function on_off(value)
    return value and (C_ON .. 'ON' .. C_END) or (C_OFF .. 'OFF' .. C_END)
end

-- "Ready": a green dot (SMN_HUD.ready_mark to change the symbol)
local READY_MARK = (SMN_HUD and SMN_HUD.ready_mark) or '●'

local function fmt_recast(seconds)
    if not seconds or seconds <= 0 then return C_ON .. READY_MARK .. C_END end
    seconds = math.ceil(seconds)
    return ('%d:%02d'):format(math.floor(seconds / 60), seconds % 60)
end

local function avatar_info()
    local mob = windower.ffxi.get_mob_by_target('pet')
    if not mob then return nil end
    return {
        name = mob.name,
        hpp = mob.hpp or 0,
        tp = (pet and pet.isvalid and pet.tp) and math.floor(pet.tp) or 0,
    }
end

local function master_mp()
    local p = windower.ffxi.get_player()
    if not p then return 0, 0 end
    return p.vitals.mp, p.vitals.max_mp or 0
end

-- Sections ------------------------------------------------------------------------------------------------------------
local function section_avatar(lines)
    lines[#lines + 1] = {title = 'Avatar'}
    local a = avatar_info()
    if a then
        lines[#lines + 1] = (' %s  HP %d%%  TP %d'):format(avatar_name(a.name), a.hpp, a.tp)
    else
        lines[#lines + 1] = C_DIM .. ' No avatar' .. C_END
    end
    local mp, max_mp = master_mp()
    lines[#lines + 1] = (' MP %d/%d   %sFavor :%s %s'):format(mp, max_mp, C_LABEL, C_END, on_off(smn_favor_active()))
        -- Live lag estimate (smn-lag): known after a first Blood Pact in this zone
        .. (smn_lag and smn_lag.est and ('   ' .. C_DIM .. ('Lag %.2f s'):format(smn_lag.est) .. C_END) or '')
end

local function section_recasts(lines)
    lines[#lines + 1] = {title = 'Recasts'}
    local recasts = windower.ffxi.get_ability_recasts() or {}
    local spell_recasts = windower.ffxi.get_spell_recasts() or {}
    local row = {}
    for _, r in ipairs(recast_list) do
        if (r.id or r.spell) and (not r.when or r.when()) then
            local value = fmt_recast(r.spell and (spell_recasts[r.spell] or 0) / 60 or recasts[r.id])
            local good, est, window, blink = false, nil, false, true
            if r.hint == 'siphon' and smn_siphon_hint then
                good, est, window = smn_siphon_hint()
                blink = not (SMN_SIPHON and SMN_SIPHON.blink == false)
            elseif r.hint == 'atomos' and smn_atomos_hint then
                good, window = smn_atomos_hint()
                blink = not (SMN_ATOMOS and SMN_ATOMOS.blink == false)
            end
            if good then
                -- Blinks with the 1 s refresh when there is a window before the next Rage; steady gold otherwise
                -- (blink = false in SMN_SIPHON / SMN_ATOMOS: always steady gold)
                local lit = not window or not blink or os.time() % 2 == 0
                value = (lit and C_GOLD or C_DIM) .. READY_MARK .. C_END
                    .. (est and (C_GOLD .. (' +%d'):format(est) .. C_END) or '')
            end
            row[#row + 1] = ('%s%s%s %s'):format(C_LABEL, r.label, C_END, value)
            if #row == RECASTS_PER_LINE then
                lines[#lines + 1] = ' ' .. table.concat(row, '   ')
                row = {}
            end
        end
    end
    if #row > 0 then lines[#lines + 1] = ' ' .. table.concat(row, '   ') end
    -- Buffs seen on the target (smn-avatar: Atomos / Dispel). The first line is always there (dim when empty) so
    -- the HUD doesn't grow and shrink with the target's buffs; a long list goes on to extra lines.
    if smn_enemy_buffs and not (SMN_ATOMOS and SMN_ATOMOS.show_buffs == false) then
        local t = windower.ffxi.get_mob_by_target('t')
        local buffs = t and smn_enemy_buffs(t.id) or {}
        if #buffs == 0 then
            lines[#lines + 1] = C_DIM .. ' Dispel :' .. C_END
        else
            local per_line = (SMN_ATOMOS and SMN_ATOMOS.buffs_per_line) or 3
            for i = 1, #buffs, per_line do
                local part = table.concat(buffs, ', ', i, math.min(i + per_line - 1, #buffs))
                    .. (i + per_line <= #buffs and ',' or '')
                lines[#lines + 1] = i == 1 and (' %sDispel :%s %s'):format(C_LABEL, C_END, part)
                    or ('          ' .. part)
            end
        end
    end
end

-- Automation in progress (skill-up; the Ward rotation and Conduit have their own sections)
local function auto_status()
    if smn_auto.task == 'skill' then
        local gained = smn_skill.skill_start and (smn_skill_level() - smn_skill.skill_start) or 0
        return ('Skill %s : %d cycles, skill %d (%+d)')
            :format(smn_skill_mode_label() or '?', smn_skill.cycles, smn_skill_level(), gained)
    end
    return nil
end

-- Shown only during a skill-up
local function section_auto(lines, status)
    lines[#lines + 1] = {title = 'Skill-up'}
    lines[#lines + 1] = ' ' .. C_ON .. status .. C_END
    if state.HudKeybinds.value and smn_key_labels.stop then
        lines[#lines + 1] = (' %s%sStop%s'):format(key_label('stop'), C_LABEL, C_END)
    end
end

-- Time remaining on a buff on self (player.buff_details, filled by GearSwap), nil if absent
local function buff_remaining(name)
    for _, b in pairs(player.buff_details or {}) do
        if b.name == name then
            local d = b.duration
            return (d and d > 0) and d or nil
        end
    end
    return nil
end

local function hint_rows(lines, rows)
    for _, row in ipairs(rows) do
        local hints = {}
        for _, h in ipairs(row) do
            local l = key_label(h[1])
            if l ~= '' then hints[#hints + 1] = l .. C_LABEL .. h[2] .. C_END end
        end
        if #hints > 0 then lines[#lines + 1] = ' ' .. table.concat(hints, '  ') end
    end
end

-- Rage: list for the avatar out (shown only with an avatar), MP cost, Conduit sequence
-- Fixed height: as many lines as the longest list in SMN_RAGE.pacts, with or without an avatar,
-- so the HUD doesn't change size on every summon / Release.
-- The HUD shows only the first SMN_RAGE.hud_max pacts (3); the others are for macros (gs c rage 4)
local function rage_hud_max() return (SMN_RAGE and SMN_RAGE.hud_max) or 3 end

local function rage_rows()
    local n = 1
    for _, list in pairs((SMN_RAGE or {}).pacts or {}) do
        if #list > n then n = #list end
    end
    return math.min(n, rage_hud_max())
end

local function section_rage(lines)
    local avatar, list = smn_rage_list()
    local rows = rage_rows()
    local first = #lines + 1

    if not avatar then
        lines[#lines + 1] = {title = 'Rage'}
        lines[#lines + 1] = C_DIM .. ' No avatar' .. C_END
    elseif not list then
        lines[#lines + 1] = {title = 'Rage : ' .. avatar_name(avatar)}
        lines[#lines + 1] = C_DIM .. ' No Rage (SMN_RAGE.pacts)' .. C_END
    else
        lines[#lines + 1] = {title = 'Rage : ' .. avatar_name(avatar)}
        local mp = master_mp()
        -- (n) = macro number: /console gs c rage n
        for i, pact in ipairs(list) do
            if i > rage_hud_max() then break end
            local cost = smn_rage_cost(pact)
            local cost_s = (mp >= cost) and (C_DIM .. cost .. ' MP' .. C_END) or (C_OFF .. cost .. ' MP' .. C_END)
            lines[#lines + 1] = (' %s(%d)%s %s  %s'):format(C_LABEL, i, C_END, pact, cost_s)
        end
    end
    -- Blank lines up to the fixed height (title + rows)
    while #lines - first + 1 < rows + 1 do lines[#lines + 1] = ' ' end

    local s = smn_rage.seq
    if s then
        local rem = buff_remaining('Astral Conduit')
        lines[#lines + 1] = (' %sConduit :%s %s, %d pact%s%s'):format(C_LABEL, C_END, s.phase or '', s.pacts,
            s.pacts > 1 and 's' or '', rem and (' ' .. C_ON .. fmt_recast(rem) .. C_END) or '')
    end

    if state.HudKeybinds.value then
        hint_rows(lines, {
            {{'rage_conduit', 'Conduit'}, {'stop', 'Stop'}},
        })
    end
end

-- Wards: list with cursor and checkboxes, then the state of the running rotation
-- Ward blocked by another one sharing its buff slot (SMN_SHARED_SLOTS) that is active on you: that entry, or nil
local function slot_holder(e, entries)
    for _, group in ipairs(SMN_SHARED_SLOTS or {}) do
        local in_group = false
        for _, p in ipairs(group) do if p == e.pact then in_group = true end end
        if in_group then
            for _, other in ipairs(entries) do
                if other ~= e and other.status and other.pact ~= e.pact then
                    for _, p in ipairs(group) do
                        if p == other.pact and smn_buff_id_active(other.status) then return other end
                    end
                end
            end
        end
    end
    return nil
end

local function section_wards(lines)
    lines[#lines + 1] = {title = 'Wards' .. (state.SmartBuff.value and (' ' .. C_ON .. 'Smart' .. C_END) or '')}
    local W = smn_ward
    if #W.entries == 0 then
        lines[#lines + 1] = C_DIM .. ' No ward (SMN_WARD.list)' .. C_END
    end
    for i, e in ipairs(W.entries) do
        local cursor = (i == W.cursor) and (C_TITLE .. '>' .. C_END) or ' '
        local box = W.checked[e.pact] and (C_ON .. '[x]' .. C_END) or '[ ]'
        local running = W.run and W.run.pact == e.pact
        local name = running and (C_TITLE .. e.pact .. C_END) or e.pact
        -- Blocked by the ward holding the shared slot (Wind's Blessing over Shining Ruby): name in that avatar's color
        local holder = not running and slot_holder(e, W.entries)
        if holder then name = (AVATAR_COLORS[holder.avatar] or C_DIM) .. e.pact .. C_END end
        local extra = avatar_name(e.avatar)
            .. (e.effect ~= '' and (' ' .. C_EFFECT .. '(' .. e.effect .. ')' .. C_END) or '')
            .. (e.target ~= '<me>' and (' ' .. C_DIM .. e.target .. C_END) or '')
        local rem, own = smn_ward_remaining(e)
        if rem then
            if own == false then
                -- Same buff, from someone else (e.g. Haste II from a RDM for Hastega II): grey
                extra = extra .. ' ' .. C_DIM .. '~' .. fmt_recast(rem) .. C_END
            else
                -- Below SMN_WARD.warn_at seconds (30 by default): timer in orange, the ward needs recasting
                local col = rem < ((SMN_WARD and SMN_WARD.warn_at) or 30) and '\\cs(255, 140, 0)' or C_LABEL
                extra = extra .. ' ' .. col .. '~' .. fmt_recast(rem) .. C_END
            end
        end
        if not e.known then
            lines[#lines + 1] = (' %s %s %s%s  %s (not learned)%s'):format(cursor, box, C_DIM, e.pact, e.avatar, C_END)
        else
            lines[#lines + 1] = (' %s %s %s  %s'):format(cursor, box, name, extra)
        end
    end

    if W.run then
        local recasts = windower.ffxi.get_ability_recasts() or {}
        -- Two fixed lines (counter + recast, then the current phase) so the HUD doesn't change width/height
        -- with each phase; a long phase is cut (SMN_HUD.phase_max characters).
        lines[#lines + 1] = (' %sRotation %d/%d%s  %s(Ward %s)%s'):format(C_LABEL, W.run.index, W.run.total, C_END,
            C_DIM, fmt_recast(recasts[174]), C_END)
        local ph, max = W.run.phase or '', (SMN_HUD and SMN_HUD.phase_max) or 20
        if #ph > max then ph = ph:sub(1, max - 1) .. '.' end
        lines[#lines + 1] = ' ' .. C_ON .. '> ' .. ph .. C_END
    end

    if state.HudKeybinds.value then
        local function k(action, label)
            local l = key_label(action)
            return l ~= '' and (l .. C_LABEL .. label .. C_END) or nil
        end
        local rows = {
            {{'ward_up', 'Up'}, {'ward_down', 'Down'}},
            {{'ward_check', 'Check'}, {'ward_clear', 'Clear'}},
            {{'ward_run', 'Run'}, {'ward_one', 'This ward'}},
        }
        for _, row in ipairs(rows) do
            local hints = {}
            for _, h in ipairs(row) do hints[#hints + 1] = k(h[1], h[2]) end
            if #hints > 0 then lines[#lines + 1] = ' ' .. table.concat(hints, '  ') end
        end
    end
end

-- Modes, at the top of the Options section: Idle Mode, and Custom Mode only if it isn't None
local function section_modes(lines)
    lines[#lines + 1] = (' %s%sIdle Mode :%s %s'):format(key_label('idle_quick'), C_LABEL, C_END, state.IdleMode.value)
    if state.CustomMode.value ~= 'None' then
        lines[#lines + 1] = (' %s%sCustom Mode :%s %s'):format(key_label('custom_mode'), C_LABEL, C_END, state.CustomMode.value)
    end
end

-- Options: those in SMN_HUD.options_shown are always shown (one per line, with their key),
-- the others only when they are ON, grouped on an "Also ON" line.
local function section_options(lines)
    lines[#lines + 1] = {title = 'Options'}
    if not state.HudHideModes.value then section_modes(lines) end

    local labels = {WeaponLock = 'Weapon Lock'}
    local order = {'WeaponLock'}
    for _, t in ipairs(SMN_TOGGLES) do
        labels[t.key] = t.label
        order[#order + 1] = t.key
    end

    local shown = {}
    local default_shown = {'WeaponLock', 'AutoFavor', 'SmartBuff', 'TreasureMode'}
    for _, key in ipairs((SMN_HUD and SMN_HUD.options_shown) or default_shown) do
        if key == 'TreasureMode' then
            -- Treasure Hunter: a mode (None / Tag / Persistent), not ON / OFF
            shown[key] = true
            local v = state.TreasureMode.value
            lines[#lines + 1] = (' %s%sTreasure :%s %s'):format(key_label('th'), C_LABEL, C_END,
                v == 'None' and (C_OFF .. v .. C_END) or (C_ON .. v .. C_END))
        elseif labels[key] and state[key] then
            shown[key] = true
            lines[#lines + 1] = (' %s%s%s :%s %s'):format(key_label(toggle_actions[key]), C_LABEL, labels[key], C_END,
                on_off(state[key].value))
        end
    end

    local also = {}
    for _, key in ipairs(order) do
        if not shown[key] and state[key].value then also[#also + 1] = labels[key] end
    end
    if not shown.TreasureMode and state.TreasureMode.value ~= 'None' then
        also[#also + 1] = 'TH ' .. state.TreasureMode.value
    end
    if #also > 0 then
        lines[#lines + 1] = (' %sAlso ON :%s %s'):format(C_LABEL, C_END, C_ON .. table.concat(also, ', ') .. C_END)
    end
    -- Key-only actions: shown with the keys, hidden with them (Hide keybinds)
    if state.HudKeybinds.value and smn_key_labels.resummon then
        lines[#lines + 1] = (' %s%sResummon last avatar%s'):format(key_label('resummon'), C_LABEL, C_END)
    end
    if state.HudKeybinds.value and smn_key_labels.hub_keybinds then
        lines[#lines + 1] = (' %s%sHide keybinds%s'):format(key_label('hub_keybinds'), C_DIM, C_END)
    end
end

-- Compact version: a few short lines
local function build_lite()
    local parts = {}
    local a = avatar_info()
    if not state.HudHideAvatar.value then
        parts[#parts + 1] = (a and ('%s %d%% TP%d'):format(a.name, a.hpp, a.tp) or 'No avatar')
            .. (smn_favor_active() and (' ' .. C_ON .. 'Favor' .. C_END) or '')
    end
    if not state.HudHideRecasts.value then
        local recasts = windower.ffxi.get_ability_recasts() or {}
        parts[#parts + 1] = ('Rage %s Ward %s'):format(fmt_recast(recasts[173]), fmt_recast(recasts[174]))
    end
    if not state.HudHideRage.value and smn_rage.seq then
        parts[#parts + 1] = C_ON .. ('Conduit %d pacts'):format(smn_rage.seq.pacts) .. C_END
    end
    if not state.HudHideWards.value then
        local W = smn_ward
        if W.run then
            parts[#parts + 1] = C_ON .. ('Wards %d/%d %s'):format(W.run.index, W.run.total, W.run.pact or '') .. C_END
        else
            local e = W.entries[W.cursor]
            parts[#parts + 1] = ('Wards %d checked%s'):format(smn_ward_checked_count(),
                e and (' > ' .. e.pact) or '')
        end
    end
    if not state.HudHideAuto.value and auto_status() then
        parts[#parts + 1] = C_ON .. auto_status() .. C_END
    end
    if not state.HudHideModes.value then
        parts[#parts + 1] = 'Idle ' .. state.IdleMode.value
            .. (state.CustomMode.value ~= 'None' and (' / ' .. state.CustomMode.value) or '')
    end
    if not state.HudHideOptions.value then
        local on = {}
        if state.WeaponLock.value then on[#on + 1] = 'WLock' end
        if state.TreasureMode.value ~= 'None' then on[#on + 1] = 'TH ' .. state.TreasureMode.value end
        for _, t in ipairs(SMN_TOGGLES) do
            if state[t.key].value then on[#on + 1] = t.label end
        end
        parts[#parts + 1] = #on > 0 and (C_ON .. table.concat(on, ', ') .. C_END) or (C_DIM .. 'no option' .. C_END)
    end
    return table.concat(parts, C_DIM .. ' | ' .. C_END)
end

local function build_full()
    local lines = {}
    if not state.HudHideAvatar.value then section_avatar(lines) end
    if not state.HudHideRecasts.value then section_recasts(lines) end
    if not state.HudHideRage.value then section_rage(lines) end
    if not state.HudHideWards.value then section_wards(lines) end
    local status = auto_status()
    if status and not state.HudHideAuto.value then section_auto(lines, status) end
    if not state.HudHideOptions.value then section_options(lines) end
    fit_titles(lines)
    return table.concat(lines, '\n')
end

-- Saved position ------------------------------------------------------------------------------------------------------
-- After a mouse drag, the position is written to SMN-USER/hud-position.txt (normal HUD) or
-- hud-position-lite.txt (compact HUD), and restored on the next load and when switching mode
-- (SMN_HUD.x / y are then only used the first time; the compact HUD starts where the normal one is).
local POS_FILES = {
    full = windower.addon_path .. 'data/SMN-USER/hud-position.txt',
    lite = windower.addon_path .. 'data/SMN-USER/hud-position-lite.txt',
}
local saved = {}          -- saved[mode] = {x = , y = }
local shown_mode = nil    -- mode whose position the HUD is currently at
local PADDING = {full = 8, lite = 5}   -- px around the text, per mode
local moving_x, moving_y = nil, nil

local function hud_mode() return state.HudLite.value and 'lite' or 'full' end

local function load_position(mode)
    local f = io.open(POS_FILES[mode], 'r')
    if not f then return nil end
    local content = f:read('*a') or ''
    f:close()
    local x, y = content:match('(%-?%d+)%s+(%-?%d+)')
    x, y = tonumber(x), tonumber(y)
    return x and y and {x = x, y = y} or nil
end

local function save_position(mode, x, y)
    local f = io.open(POS_FILES[mode], 'w')
    if not f then return end
    f:write(('%d %d\n'):format(x, y))
    f:close()
    saved[mode] = {x = x, y = y}
end

-- Mode switch (gs c hub lite): move the HUD to that mode's position
local function apply_mode_position()
    local mode = hud_mode()
    if mode == shown_mode then return end
    shown_mode = mode
    local p = saved[mode] or saved.full
    hud:pos(p.x, p.y)
    hud:pad(PADDING[mode])
    moving_x, moving_y = nil, nil
end

-- Called every second: only write once the drag is over (same position two seconds in a row)
local function check_position()
    local x, y = hud:pos()
    x, y = math.floor(x), math.floor(y)
    local p = saved[shown_mode] or saved.full
    if x == p.x and y == p.y then
        moving_x, moving_y = nil, nil
    elseif x == moving_x and y == moving_y then
        save_position(shown_mode, x, y)
        moving_x, moving_y = nil, nil
    else
        moving_x, moving_y = x, y
    end
end

-- API -----------------------------------------------------------------------------------------------------------------
function smn_setup_hud()
    local cfg = SMN_HUD or {}
    -- A saved position off screen (resolution changed since) is ignored
    local ui = windower.get_windower_settings() or {}
    local function on_screen(p)
        if not p or not ui.ui_x_res or not ui.ui_y_res then return p end
        if p.x < 0 or p.y < 0 or p.x > ui.ui_x_res - 40 or p.y > ui.ui_y_res - 20 then return nil end
        return p
    end
    saved.full = on_screen(load_position('full')) or {x = cfg.x or 100, y = cfg.y or 300}
    saved.lite = on_screen(load_position('lite'))
    shown_mode = hud_mode()
    local p = saved[shown_mode] or saved.full
    hud = texts.new('', {
        pos = {x = p.x, y = p.y},
        bg = {alpha = 200, red = 40, green = 40, blue = 55, visible = true},
        flags = {right = false, bottom = false, bold = true, draggable = true, italic = false},
        padding = PADDING[shown_mode],
        text = {size = cfg.font_size or 11, font = 'Arial', alpha = 255, red = 147, green = 161, blue = 161,
                stroke = {width = 0, alpha = 255, red = 0, green = 0, blue = 0}},
    })
    last_text = nil
    smn_hud_update()
end

-- In game? (false on the login screen and at character selection)
-- Loading screen (zoning): your own character is missing from the entity list -> hidden, like the
-- other addons (they watch the zone-out packet; here: memory read only, no packets).
local function in_game()
    local info = windower.ffxi.get_info()
    return info and info.logged_in and windower.ffxi.get_player() ~= nil
        and windower.ffxi.get_mob_by_target('me') ~= nil
end

function smn_hud_update()
    if not hud then return end
    if state.HudHide.value or not in_game() then
        hud:hide()
        return
    end
    apply_mode_position()
    local str = state.HudLite.value and build_lite() or build_full()
    -- Every section hidden: no empty box on screen
    if str == '' then
        hud:hide()
        return
    end
    if str ~= last_text then
        hud:text(str)
        last_text = str
    end
    hud:show()
end

-- Refresh every second (recasts, avatar HP, MP)
local last_tick = 0
local last_vis_check = 0
windower.register_event('prerender', function()
    -- Hide quickly when the loading screen starts (every 0.25 s, not just on the 1 s refresh)
    local c = os.clock()
    if hud and c - last_vis_check >= 0.25 then
        last_vis_check = c
        if hud:visible() and not in_game() then hud:hide() end
    end
    local now = os.time()
    if now ~= last_tick then
        last_tick = now
        smn_hud_update()
        if hud and in_game() then check_position() end
    end
end)

-- Hidden immediately on logout (login screen, character selection)
windower.register_event('logout', function()
    if hud then hud:hide() end
end)
