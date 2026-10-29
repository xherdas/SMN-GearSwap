-- ===================================================================================================================
--  SMN-LIB: keys
--  Default actions here, overrides in SMN_KEYBINDS (user.lua). Idea from the PUP GearSwap's keybinds.
--  smn_key_labels[action] gives the label shown in the HUD, e.g. "(Ctrl+F9)".
-- ===================================================================================================================

local default_actions = {
    idle_quick     = {key = "f9",  command = "gs c ToggleIdle"},
    idle_quick_back = {key = "!f9", command = "gs c ToggleIdle back"},
    idle_cycle     = {key = nil,   command = "gs c cycle IdleMode"},
    idle_cycleback = {key = nil,   command = "gs c cycleback IdleMode"},
    custom_mode    = {key = nil,   command = "gs c cycle CustomMode"},
    force_ilvl     = {key = nil,   command = "gs c ForceIlvl"},
    weapon_lock    = {key = "^f9", command = "gs c WeaponLock"},
    th             = {key = "f10",  command = "gs c th tag"},
    th_persistent  = {key = "!f10", command = "gs c th persistent"},
    acc_mode       = {key = nil,   command = "gs c AccMode"},
    impact         = {key = nil,   command = "gs c ImpactMode"},
    empy           = {key = nil,   command = "gs c Empy"},
    lag_mode       = {key = "!f11", command = "gs c LagMode"},
    opa            = {key = nil,   command = "gs c opa"},
    sac_torque     = {key = nil,   command = "gs c SacTorque"},
    auto_remedy    = {key = nil,   command = "gs c AutoRemedy"},
    auto_echo      = {key = nil,   command = "gs c AutoEcho"},
    kiting         = {key = "^f10", command = "gs c Kiting"},
    stop           = {key = "f12",  command = "gs c stop"},
    skill_pact     = {key = "^f12", command = "gs c skill pact"},
    skill_summon   = {key = "!f12", command = "gs c skill summon"},
    ward_up        = {key = "!home",   command = "gs c ward up"},
    ward_down      = {key = "!end",    command = "gs c ward down"},
    ward_check     = {key = "!insert", command = "gs c ward check"},
    ward_clear     = {key = "!delete", command = "gs c ward clear"},
    ward_run       = {key = "^end",    command = "gs c ward run"},
    ward_one       = {key = "^home",   command = "gs c ward one"},
    ward_one_stay  = {key = "^~home",  command = "gs c ward one stay"},
    auto_favor     = {key = "^insert", command = "gs c autofavor"},
    smart_buff     = {key = "^delete", command = "gs c smartbuff"},
    -- Rages by macro: /console gs c rage 1 | 2 | 3 ... (number in SMN_RAGE.pacts)
    resummon       = {key = "^pageup",   command = "gs c resummon"},
    siphon         = {key = nil,         command = "gs c siphon"},
    atomos         = {key = nil,         command = "gs c atomos"},
    rage_conduit   = {key = "^f11",      command = "gs c rage conduit"},
    hub_keybinds   = {key = "^pagedown", command = "gs c hub keybinds"},
    hub_lite       = {key = nil,   command = "gs c hub lite"},
}

smn_key_labels = {}
local bound_keys = {}

local function key_to_label(key)
    if not key or key == "" then return "" end
    local mods, rest = {}, key
    -- Short mixed-case labels (Ctrl+PgDn): narrower in the HUD than all caps
    local names = {['!'] = "Alt", ['^'] = "Ctrl", ['@'] = "Win", ['~'] = "Shift", ['#'] = "Apps"}
    local keys = {pageup = "PgUp", pagedown = "PgDn", insert = "Ins", delete = "Del", home = "Home", ["end"] = "End",
                  escape = "Esc", enter = "Enter", space = "Space", tab = "Tab", backspace = "Bksp"}
    while #rest > 1 and names[rest:sub(1, 1)] do
        mods[#mods + 1] = names[rest:sub(1, 1)]
        rest = rest:sub(2)
    end
    rest = rest:lower()
    mods[#mods + 1] = keys[rest] or (rest:match('^f%d+$') and rest:upper())
        or (rest:sub(1, 1):upper() .. rest:sub(2))
    return "(" .. table.concat(mods, "+") .. ")"
end

function smn_unbind_keys()
    for key in pairs(bound_keys) do
        send_command("unbind " .. key)
    end
    bound_keys = {}
end

function smn_apply_keybinds(config)
    config = config or {}
    local overrides = config.binds or {}
    smn_unbind_keys()
    smn_key_labels = {}

    -- Overrides: { key = "!f10" } or just "!f10"; unknown action names are reported
    for name, o in pairs(overrides) do
        if not default_actions[name] then
            smn_warn(('SMN_KEYBINDS: unknown action "%s" (ignored).'):format(tostring(name)))
        elseif type(o) ~= 'table' and type(o) ~= 'string' and o ~= false then
            smn_warn(('SMN_KEYBINDS: %s must be { key = "..." } (ignored).'):format(name))
        end
    end

    local actions = {}
    for name, default in pairs(default_actions) do
        local action = {key = default.key, command = default.command}
        local o = overrides[name]
        if type(o) == 'string' or o == false then o = {key = o} end
        if type(o) == 'table' then
            for k, v in pairs(o) do action[k] = v end
            action.overridden = o.key ~= nil
        end
        if action.key == false or action.key == "" then action.key = nil end
        if action.key then actions[name] = action end
    end

    -- Same key on two actions: the one set in SMN_KEYBINDS wins over a default; otherwise the first by name
    local by_key, names = {}, {}
    for name in pairs(actions) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        local oa, ob = actions[a].overridden and 0 or 1, actions[b].overridden and 0 or 1
        if oa ~= ob then return oa < ob end
        return a < b
    end)
    for _, name in ipairs(names) do
        local action = actions[name]
        local k = action.key:lower()
        if by_key[k] then
            smn_warn(('Key %s used by %s and %s: kept for %s.'):format(key_to_label(action.key), by_key[k], name, by_key[k]))
        else
            by_key[k] = name
            if config.enable_binds ~= false then
                -- Label only for keys really bound (enable_binds = false: no key shown in the HUD)
                smn_key_labels[name] = action.label and ("(" .. action.label .. ")") or key_to_label(action.key)
                send_command("bind " .. action.key .. " " .. action.command)
                bound_keys[action.key] = true
            end
        end
    end
end
