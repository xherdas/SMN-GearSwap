-- ===================================================================================================================
--  SMN-LIB: modes (M{} from Mote's Modes.lua)
--  Idle Mode, Custom Mode, Treasure Mode and the toggles (Pergatory's options + new ones) as state.<Name>.
-- ===================================================================================================================
include('Modes.lua')

state = state or {}

-- Toggles: state key, description, legacy command (gs c <command>)
SMN_TOGGLES = {
    {key = 'AutoFavor',      label = 'Auto Favor',       command = 'autofavor'}, -- not 'favor': it's an Idle Mode
    {key = 'SmartBuff',      label = 'Smart Buff',       command = 'smartbuff'},
    {key = 'AccMode',       label = 'Acc Mode',         command = 'accmode'},
    {key = 'ImpactDebuff',   label = 'Impact Debuff',    command = 'impactmode'},
    {key = 'Empy',           label = 'Empy Ward',        command = 'empy'},
    {key = 'ForceIlvl',      label = 'Force iLvl',       command = 'forceilvl'},
    {key = 'LagMode',        label = 'Lag Mode',         command = 'lagmode'},
    {key = 'SacTorque',      label = 'Sacrifice Torque', command = 'sactorque'},
    {key = 'AutoRemedy',     label = 'Auto Remedy',      command = 'autoremedy'},
    {key = 'AutoEcho',       label = 'Auto Echo',        command = 'autoecho'},
    {key = 'Kiting',         label = 'Kiting',           command = 'kiting'},  -- Movement gear while engaged
}

local function list_mode(values, description, default)
    local t = {description = description}
    for i, v in ipairs(values) do t[i] = v end
    local m = M(t)
    -- Default value, case-insensitive ('refresh' = 'Refresh')
    if default then
        for _, v in ipairs(values) do
            if v:lower() == tostring(default):lower() then m:set(v) break end
        end
    end
    return m
end

function smn_setup_modes()
    local d = SMN_DEFAULTS or {}

    state.IdleMode = list_mode(SMN_IDLE_MODES or {'Refresh'}, 'Idle Mode', d.IdleMode)
    state.CustomMode = list_mode(SMN_CUSTOM_MODES or {'None'}, 'Custom Mode', d.CustomMode)
    -- Treasure Hunter (smn-th.lua)
    state.TreasureMode = list_mode({'None', 'Tag', 'Persistent'}, 'Treasure Mode',
        d.TreasureMode or 'None')

    for _, t in ipairs(SMN_TOGGLES) do
        state[t.key] = M(d[t.key] == true, t.label)
    end

    -- WeaponLock has no default value: it equips and locks weapons.
    state.WeaponLock = M(false, 'Weapon Lock')

    -- HUD
    state.HudHide = M(false, 'Hide HUD')
    state.HudHideAvatar = M(false, 'Hide Avatar')
    state.HudHideRecasts = M(false, 'Hide Recasts')
    state.HudHideAuto = M(false, 'Hide Auto')
    state.HudHideWards = M(false, 'Hide Wards')
    state.HudHideRage = M(false, 'Hide Rage')
    state.HudHideModes = M(false, 'Hide Modes')
    state.HudHideOptions = M(false, 'Hide Options')
    state.HudKeybinds = M(not SMN_HUD or SMN_HUD.show_keybinds ~= false, 'Show Keybinds')
    state.HudLite = M(SMN_HUD and SMN_HUD.lite == true, 'Lite HUD')
end

-- Finds a mode by its key name, case-insensitive (gs c cycle idlemode)
function smn_find_state(name)
    if not name then return nil end
    name = name:lower()
    for k, v in pairs(state) do
        if type(k) == 'string' and k:lower() == name and type(v) == 'table' and v._track then
            return v, k
        end
    end
    return nil
end
