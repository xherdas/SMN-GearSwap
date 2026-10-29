-- ===================================================================================================================
--  SMN-LIB: game data (Blood Pact lists, zones, elements)
-- ===================================================================================================================

-- Version of this SMN GearSwap (shown by gs c help; see CHANGELOG.md)
SMN_VERSION = '0.9.0-beta'

Buff_BPs_Duration = S{'Shining Ruby','Aerial Armor','Frost Armor','Rolling Thunder','Crimson Howl','Lightning Armor','Ecliptic Growl','Glittering Ruby','Earthen Ward','Hastega','Noctoshield','Ecliptic Howl','Dream Shroud','Earthen Armor','Fleet Wind','Inferno Howl','Heavenward Howl','Hastega II','Soothing Current','Crystal Blessing','Katabatic Blades'}
Buff_BPs_Healing = S{'Healing Ruby','Healing Ruby II','Whispering Wind','Spring Water'}
Buff_BPs_MND = S{"Wind's Blessing"}
Debuff_BPs = S{'Mewing Lullaby','Eerie Eye','Lunar Cry','Lunar Roar','Nightmare','Pavor Nocturnus','Ultimate Terror','Somnolence','Slowga','Tidal Roar','Diamond Storm','Sleepga','Shock Squall','Bitter Elegy','Lunatic Voice'}
Debuff_Rage_BPs = S{'Moonlit Charge','Tail Whip'}

Magic_BPs_NoTP = S{'Holy Mist','Nether Blast','Aerial Blast','Searing Light','Diamond Dust','Earthen Fury','Zantetsuken','Tidal Wave','Judgment Bolt','Inferno','Howling Moon','Ruinous Omen','Night Terror','Thunderspark','Tornado II','Sonic Buffet'}
Magic_BPs_TP = S{'Impact','Conflag Strike','Level ? Holy','Lunar Bay'}
Merit_BPs = S{'Meteor Strike','Geocrush','Grand Fall','Wind Blade','Heavenly Strike','Thunderstorm'}
Physical_BPs_TP = S{'Rock Buster','Mountain Buster','Crescent Fang','Spinning Dive','Roundhouse'}

ZodiacElements = S{'Fire','Earth','Water','Wind','Ice','Lightning'}

TownIdle = S{"windurst woods","windurst waters","windurst walls","port windurst","bastok markets","bastok mines","port bastok","southern san d'oria","northern san d'oria","port san d'oria","upper jeuno","lower jeuno","port jeuno","ru'lude gardens","norg","kazham","tavnazian safehold","rabao","selbina","mhaura","aht urhgan whitegate","nashmau","western adoulin","eastern adoulin","chocobo circuit","mog garden","leafallia"}

-- Merit pact -> SMN_MERITS key
Merit_BP_Keys = {
    ['Meteor Strike'] = 'MeteorStrike',
    ['Geocrush'] = 'Geocrush',
    ['Grand Fall'] = 'GrandFall',
    ['Wind Blade'] = 'WindBlade',
    ['Heavenly Strike'] = 'HeavenlyStrike',
    ['Thunderstorm'] = 'Thunderstorm',
}

-- Avatar for each Blood Pact (Rage and Ward), for gs c pact and the Ward list
local pacts_by_avatar = {
    ['Carbuncle'] = {'Poison Nails','Meteorite','Searing Light','Holy Mist','Healing Ruby','Shining Ruby','Glittering Ruby',
                     'Healing Ruby II','Soothing Ruby','Pacifying Ruby'},
    ['Cait Sith'] = {'Regal Scratch','Regal Gash','Level ? Holy','Mewing Lullaby','Eerie Eye','Raise II','Reraise II',"Altana's Favor"},
    ['Fenrir']    = {'Moonlit Charge','Crescent Fang','Eclipse Bite','Howling Moon','Lunar Bay','Impact','Lunar Cry','Lunar Roar',
                     'Ecliptic Growl','Ecliptic Howl','Heavenward Howl'},
    ['Ifrit']     = {'Punch','Fire II','Burning Strike','Double Punch','Fire IV','Flaming Crush','Meteor Strike','Inferno',
                     'Conflag Strike','Crimson Howl','Inferno Howl'},
    ['Titan']     = {'Rock Throw','Stone II','Rock Buster','Megalith Throw','Stone IV','Mountain Buster','Geocrush','Earthen Fury',
                     'Crag Throw','Earthen Ward','Earthen Armor'},
    ['Leviathan'] = {'Barracuda Dive','Water II','Tail Whip','Water IV','Spinning Dive','Grand Fall','Tidal Wave','Spring Water',
                     'Slowga','Tidal Roar','Soothing Current'},
    ['Garuda']    = {'Claw','Aero II','Aero IV','Predator Claws','Wind Blade','Aerial Blast','Whispering Wind','Hastega',
                     'Aerial Armor','Fleet Wind','Hastega II'},
    ['Shiva']     = {'Axe Kick','Blizzard II','Double Slap','Blizzard IV','Rush','Heavenly Strike','Diamond Dust','Frost Armor',
                     'Sleepga','Diamond Storm','Crystal Blessing'},
    ['Ramuh']     = {'Shock Strike','Thunder II','Thunderspark','Thunder IV','Chaotic Strike','Thunderstorm','Judgment Bolt',
                     'Volt Strike','Rolling Thunder','Lightning Armor','Shock Squall'},
    ['Diabolos']  = {'Camisado','Nether Blast','Ruinous Omen','Night Terror','Blindside','Somnolence','Nightmare',
                     'Ultimate Terror','Noctoshield','Dream Shroud','Pavor Nocturnus'},
    ['Siren']     = {'Welt','Roundhouse','Sonic Buffet','Tornado II','Hysteric Assault','Katabatic Blades','Lunatic Voice',
                     'Chinook','Bitter Elegy',"Wind's Blessing",'Clarsach Call'},
}

-- [lowercase pact name] = {pact = exact name, avatar = avatar}
SMN_PACTS = {}
for avatar, pacts in pairs(pacts_by_avatar) do
    for _, pact in ipairs(pacts) do
        SMN_PACTS[pact:lower()] = {pact = pact, avatar = avatar}
    end
end

-- Wards sharing one buff slot, in ascending priority (a higher one replaces a lower one: BG-Wiki). In the HUD, a
-- ward blocked by the other has its name in the color of the avatar holding the slot; Smart Buff skips a ward
-- when a higher one of its group is active or cast in the same rotation.
SMN_SHARED_SLOTS = {
    {"Shining Ruby", "Wind's Blessing"},   -- Rampart < Shining Ruby < Wind's Blessing < One for All
}

SMN_ALL_SLOTS ={"main","sub","range","ammo","head","neck","ear1","ear2","body","hands","ring1","ring2","back","waist","legs","feet"}
