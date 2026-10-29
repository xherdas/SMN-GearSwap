	-- Sets from Pergatory's SMN GearSwap (http://pastebin.com/u/pergatory): replace with your own gear.
	-- Pieces you don't own are ignored by GearSwap (//gs validate lists them).

	-- Gear variables: change a piece here once, every set using it follows.
	-- (Pieces you don't own: keep the name, GearSwap simply skips it.)

	Artifact_Convoker = {}
	Artifact_Convoker.Body = "Convoker's Doublet +4"   -- BP sets

	Relic_Glyphic = {}
	Relic_Glyphic.Head = "Glyphic Horn +4"   -- Astral Flow
	Relic_Glyphic.Body = "Glyphic Doublet +4"   -- physical BP, PetDD
	Relic_Glyphic.Legs = "Glyphic Spats +4"   -- spirits

	Empyrean_Beckoner = {}
	Empyrean_Beckoner.Head = "Beckoner's Horn +3"   -- idle, Avatar's Favor, BP delay
	Empyrean_Beckoner.Body = "Beckoner's Doublet +3"   -- DT, Favor
	Empyrean_Beckoner.Hands = "Beckoner's Bracers +3"   -- Mana Cede
	Empyrean_Beckoner.Legs = "Beckoner's Spats +3"
	Empyrean_Beckoner.Feet = "Beckoner's Pigaches +3"   -- Elemental Siphon

	Apogee = {}
	Apogee.Head_Physical = {name="Apogee Crown +1", augments={'MP+80','Pet: Attack+35','Blood Pact Dmg.+8',}}   -- physical BP
	Apogee.Head_PetDT = {name="Apogee Crown +1", augments={'Pet: Accuracy+25','"Avatar perpetuation cost"+7','Pet: Damage taken -4%',}}   -- Pet: DT
	Apogee.Body_Magic = {name="Apo. Dalmatica +1", augments={'MP+80','Pet: "Mag.Atk.Bns."+35','Blood Pact Dmg.+8',}}   -- magic BP
	Apogee.Body_PetDT = {name="Apo. Dalmatica +1", augments={'Summoning magic skill +20','Enmity-6','Pet: Damage taken -4%',}}   -- skill, Pet: DT
	Apogee.Legs_Physical = {name="Apogee Slacks +1", augments={'Pet: STR+20','Blood Pact Dmg.+14','Pet: "Dbl. Atk."+4',}}   -- physical BP
	Apogee.Legs_Magic = {name="Apogee Slacks +1", augments={'MP+80','Pet: "Mag.Atk.Bns."+35','Blood Pact Dmg.+8',}}   -- magic BP
	Apogee.Feet_Physical = {name="Apogee Pumps +1", augments={'MP+80','Pet: Attack+35','Blood Pact Dmg.+8',}}   -- physical BP
	Apogee.Feet_Magic = {name="Apogee Pumps +1", augments={'MP+80','Pet: "Mag.Atk.Bns."+35','Blood Pact Dmg.+8',}}   -- magic BP

	Helios = {}
	Helios.Head = {name="Helios Band", augments={'Pet: Attack+30 Pet: Rng.Atk.+30','Pet: "Dbl. Atk."+8','Blood Pact Dmg.+7',}}   -- physical BP
	Helios.Hands = {name="Helios Gloves", augments={'Pet: Accuracy+22 Pet: Rng. Acc.+22','Pet: "Dbl. Atk."+8','Pet: Haste+6',}}   -- physical BP
	Helios.Feet_Attack = {name="Helios Boots", augments={'Pet: Attack+30 Pet: Rng.Atk.+30','Pet: "Dbl. Atk."+8','Blood Pact Dmg.+7',}}   -- physical BP
	Helios.Feet_Acc = {name="Helios Boots", augments={'Pet: Accuracy+21 Pet: Rng. Acc.+21','Pet: "Dbl. Atk."+8','Pet: Haste+6',}}   -- physical BP (accuracy)

	Campestres = {}
	Campestres.AvatarBP = {name="Campestres's Cape", augments={'Pet: Acc.+20 Pet: R.Acc.+20 Pet: Atk.+20 Pet: R.Atk.+20','Eva.+20 /Mag. Eva.+20','Pet: Attack+10 Pet: Rng.Atk.+10','Pet: "Regen"+10','Pet: Damage taken -5%',}}   -- physical BP, idle
	Campestres.SummonerFC = {name="Campestres's Cape", augments={'Pet: M.Acc.+20 Pet: M.Dmg.+20','Eva.+20 /Mag. Eva.+20','Pet: Mag. Acc.+10','"Fast Cast"+10','Damage taken-5%',}}   -- magic BP, Fast Cast
	Campestres.Melee = {name="Campestres's Cape", augments={'DEX+20','Accuracy+20 Attack+20','Accuracy+10','"Dbl.Atk."+10','Phys. dmg. taken-10%',}}   -- melee
	Campestres.Nuke = {name="Campestres's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','Mag. Acc.+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}}   -- your own magic, DT

	Merlinic = {}
	Merlinic.Hands_Physical = {name="Merlinic Dastanas", augments={'Pet: Attack+24 Pet: Rng.Atk.+24','Blood Pact Dmg.+9','Pet: STR+10','Pet: Mag. Acc.+7',}}   -- physical BP
	Merlinic.Hands_Refresh = {name="Merlinic Dastanas", augments={'Pet: Crit.hit rate +2','"Mag.Atk.Bns."+25','"Refresh"+2','Mag. Acc.+10 "Mag.Atk.Bns."+10',}}   -- idle
	Merlinic.Hands_Magic = {name="Merlinic Dastanas", augments={'Pet: Mag. Acc.+25 Pet: "Mag.Atk.Bns."+25','Blood Pact Dmg.+10','Pet: "Mag.Atk.Bns."+7',}}   -- magic BP
	Merlinic.Hands_MagicAcc = {name="Merlinic Dastanas", augments={'Pet: Mag. Acc.+29','Blood Pact Dmg.+10','Pet: INT+7','Pet: "Mag.Atk.Bns."+10',}}   -- magic BP (accuracy)
	Merlinic.Head = {name="Merlinic Hood", augments={'Pet: Mag. Acc.+21 Pet: "Mag.Atk.Bns."+21','Blood Pact Dmg.+7','Pet: INT+6','Pet: "Mag.Atk.Bns."+11',}}   -- magic BP (accuracy)
	Merlinic.Legs_FC = {name="Merlinic Shalwar", augments={'"Fast Cast"+6','CHR+6','Mag. Acc.+14','"Mag.Atk.Bns."+14',}}   -- Fast Cast

	-- Base Damage Taken Set - Mainly used when IdleMode is "DT"
	sets.DT_Base = {
		main="Nirvana",
		sub="Oneiros Grip",
		ammo="Epitaph",
		head=Empyrean_Beckoner.Head,
		neck="Summoner's Collar +2",
		ear1="Cath Palug Earring",
		ear2="Beckoner's Earring +1",
		body=Empyrean_Beckoner.Body,
		hands=Merlinic.Hands_Refresh,
		ring1="Inyanga Ring",
		ring2="Murky Ring",
		back=Campestres.Nuke,
		waist="Carrier's Sash",
		legs="Inyanga Shalwar +2",
		feet="Baayami Sabots +1"
	}

	-- Treasure Hunter set. Don't put anything in here except TH+ gear.
	-- It overwrites slots in other sets for TH Tag (F10, next offensive action) or Persistent (Alt+F10).
	sets.TH = {
		head="Volte Cap",
		waist="Chaac Belt",
		body="Nyame Mail", -- Because otherwise Cohort Cloak and such mess up the swap
		hands="Volte Bracers",
		feet="Volte Boots"
	}
	
	-- This gets equipped automatically when you have Sneak/Invis or Quickening such as from Fleet Wind.
	sets.Movement = {
		ring1="Shneddick Ring +1"
		--feet="Herald's Gaiters"
	}

	sets.precast = {}

	-- Fast Cast
	sets.precast.FC = {
		main={ name="Grioavolr", augments={'"Fast Cast"+6','INT+2','"Mag.Atk.Bns."+17',}}, -- +10
		sub="Clerisy Strap +1", -- +3
		--ammo="Sapience Orb",
		head="Amalric Coif +1", -- +11
		neck="Orunmila's Torque", -- +5
		ear1="Malignance Earring", -- +4
		ear2="Loquacious Earring", -- +2
		hands={ name="Telchine Gloves", augments={'Mag. Evasion+25','"Fast Cast"+5','Enh. Mag. eff. dur. +10',}},
		body="Inyanga Jubbah +2", -- +14
		ring1="Lebeche Ring",
		ring2="Kishar Ring", -- +4
		back=Campestres.SummonerFC,
		waist="Witful Belt", -- +3
		legs=Merlinic.Legs_FC,
		feet="Regal Pumps +1" -- +5~7
	}

	sets.precast["Dispelga"] = set_combine(sets.precast.FC, {
		main="Daybreak",
		sub="Ammurapi Shield"
	})

    sets.midcast = {}

	-- BP Timer Gear
	-- Use BP Recast Reduction here, along with Avatar's Favor gear.
	-- Avatar's Favor skill tiers are 512 / 575 / 670 / 735.
    sets.midcast.BP = {
		main={ name="Espiritus", augments={'Summoning magic skill +15','Pet: Mag. Acc.+30','Pet: Damage taken -4%',}},
		sub="Vox Grip",
		ammo="Sancus Sachet +1",
		head=Empyrean_Beckoner.Head, -- Always use Beckoner's Horn here.
		neck="Hoxne Torque",
		ear1="Cath Palug Earring",
		ear2="Lodurr Earring",
		body="Baayami Robe +1",
		hands="Baayami Cuffs +1",
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2="Evoker's Ring",
		back={ name="Conveyance Cape", augments={'Summoning magic skill +5','Pet: Enmity+12','Blood Pact Dmg.+2',}},
		waist="Kobo Obi",
		legs="Baayami Slops +1",
		feet="Baayami Sabots +1"
	}
	
	-- Shock Squall is too fast to swap gear in pet_midcast() or otherwise. It'll generally land in your BP timer set.
	-- I settle for the 670-skill favor tier so I can fit more Pet:MAcc, credit to Papesse of Carbuncle for suggesting this compromise
	sets.midcast.BP["Shock Squall"] = set_combine(sets.midcast.BP, {
		neck="Summoner's Collar +2",
		ear1="Enmerkar Earring",
		ear2="Lugalbanda Earring",
		ring1="Cath Palug Ring",
		ring2="Fickblix's Ring",
		back=Campestres.SummonerFC,
		waist="Incarnation Sash",
	})

	-- Elemental Siphon sets. Zodiac Ring is affected by day, Chatoyant Staff by weather, and Twilight Cape by both.
    sets.midcast.Siphon = {
		main={ name="Espiritus", augments={'Summoning magic skill +15','Pet: Mag. Acc.+30','Pet: Damage taken -4%',}},
		sub="Vox Grip",
		ammo="Esper Stone +1",
		head="Baayami Hat +1",
		neck="Hoxne Torque",
		ear1="Cath Palug Earring",
		ear2="Lodurr Earring",
		body="Baayami Robe +1",
		hands="Baayami Cuffs +1",
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2="Evoker's Ring",
		back={ name="Conveyance Cape", augments={'Summoning magic skill +5','Pet: Enmity+12','Blood Pact Dmg.+2',}},
		waist="Kobo Obi",
		legs="Baayami Slops +1",
		feet=Empyrean_Beckoner.Feet
	}

	sets.midcast.SiphonZodiac = set_combine(sets.midcast.Siphon, { ring1="Zodiac Ring" })

	sets.midcast.SiphonWeather = set_combine(sets.midcast.Siphon, { main="Chatoyant Staff" })
	
	sets.midcast.SiphonWeatherZodiac = set_combine(sets.midcast.SiphonZodiac, { main="Chatoyant Staff" })

	-- Summoning Midcast, cap spell interruption if possible (Baayami Robe gives 100, need 2 more)
	-- PDT isn't a bad idea either, so don't overwrite a lot from the DT set it inherits from.
	sets.midcast.Summon = set_combine(sets.DT_Base, {
		body="Baayami Robe +1",
		legs="Bunzi's Pants",
	})

	-- If you ever lock your weapon, keep that in mind when building cure potency set.
	sets.midcast.Cure = {
		main="Nirvana",
		sub="Clerisy Strap +1",
		head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},
		neck="Orunmila's Torque",
		ear1="Meili Earring",
		ear2="Novia Earring",
		body="Zendik Robe",
		hands={ name="Telchine Gloves", augments={'Mag. Evasion+25','"Fast Cast"+5','Enh. Mag. eff. dur. +10',}},
		ring1="Lebeche Ring",
		ring2="Menelaus's Ring",
		back="Tempered Cape +1",
		waist="Luminary Sash",
		legs=Empyrean_Beckoner.Legs,
		feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}
	}

	sets.midcast.Cursna = set_combine(sets.precast.FC, {
		neck="Debilis Medallion",
		ear1="Meili Earring",
		ear2="Beatific Earring",
		ring1="Menelaus's Ring",
		ring2="Haoma's Ring",
		back="Tempered Cape +1",
		waist="Bishop's Sash",
		feet={ name="Vanya Clogs", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}}
	})
	
	-- Just a standard set for spells that have no set
	sets.midcast.EnmityRecast = set_combine(sets.precast.FC, {
		main="Nirvana",
		ear1="Novia Earring",
		body=Apogee.Body_PetDT
	})

	-- Strong alternatives: Daybreak and Ammurapi Shield, Cath Crown, Gwati Earring
	sets.midcast.Enfeeble = {
		main="Contemplator +1",
		sub="Enki Strap",
		head=empty,
		neck="Null Loop",
		ear1="Malignance Earring",
		ear2="Dignitary's Earring",
		body="Cohort Cloak +1",
		hands="Inyanga Dastanas +2",
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2={name="Stikini Ring +1", bag="wardrobe4"},
		back="Aurist's Cape +1",
		waist="Null Belt",
		legs="Inyanga Shalwar +2",
		feet="Skaoi Boots"
	}
	sets.midcast.Enfeeble.INT = set_combine(sets.midcast.Enfeeble, {
		waist="Acuity Belt +1"
	})

	sets.midcast.Enhancing = {
		main={ name="Gada", augments={'Enh. Mag. eff. dur. +6','DEX+1','Mag. Acc.+5','"Mag.Atk.Bns."+18','DMG:+4',}},
		sub="Ammurapi Shield",
		head={ name="Telchine Cap", augments={'Mag. Evasion+24','"Conserve MP"+4','Enh. Mag. eff. dur. +10',}},
		neck="Hoxne Torque",
		ear1="Mimir Earring",
		ear2="Andoaa Earring",
		body={ name="Telchine Chas.", augments={'Mag. Evasion+25','"Conserve MP"+5','Enh. Mag. eff. dur. +10',}},
		hands={ name="Telchine Gloves", augments={'Mag. Evasion+25','"Fast Cast"+5','Enh. Mag. eff. dur. +10',}},
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2={name="Stikini Ring +1", bag="wardrobe4"},
		back="Merciful Cape",
		waist="Embla Sash",
		legs={ name="Telchine Braconi", augments={'Mag. Evasion+25','"Conserve MP"+4','Enh. Mag. eff. dur. +10',}},
		feet={ name="Telchine Pigaches", augments={'Mag. Evasion+24','"Conserve MP"+3','Enh. Mag. eff. dur. +10',}}
	}

	sets.midcast.Stoneskin = set_combine(sets.midcast.Enhancing, {
		neck="Nodens Gorget",
		ear2="Earthcry Earring",
		waist="Siegel Sash",
		--legs="Shedir Seraweels"
	})

	-- Alternatives: Cath Palug Crown, Amalric gear, Sanctity Necklace, Eschan Stone
	sets.midcast.Nuke = {
		main="Opashoro",
		sub="Enki Strap",
		head="Bunzi's Hat",
		neck="Sibyl Scarf",
		ear1="Malignance Earring",
		ear2="Friomisi Earring",
		body={ name="Amalric Doublet +1", augments={'MP+80','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},
		hands="Bunzi's Gloves",
		ring1="Freke Ring",
		ring2="Metamorph Ring +1",
		back=Campestres.Nuke,
		waist="Acuity Belt +1",
		legs="Bunzi's Pants",
		feet="Bunzi's Sabots"
	}

    -- Gishdubar Sash only counts on yourself: .Self is used when you are the target
    sets.midcast["Refresh"] = set_combine(sets.midcast.Enhancing, {
		head="Amalric Coif +1",
	})
    sets.midcast["Refresh"].Self = set_combine(sets.midcast["Refresh"], {waist="Gishdubar Sash"})

    -- Refresh received: equipped while another player casts Refresh on you, then back to idle
    sets.RefreshReceived = {waist="Gishdubar Sash"}

    sets.midcast["Aquaveil"] = set_combine(sets.midcast.Enhancing, {
		main="Vadose Rod",
		head="Amalric Coif +1",
		hands="Regal Cuffs",
		waist="Emphatikos Rope",
	})

	sets.midcast["Dispelga"] = set_combine(sets.midcast.Enfeeble, {
		main="Daybreak",
		sub="Ammurapi Shield"
	})

	sets.midcast["Mana Cede"] = { hands=Empyrean_Beckoner.Hands }

    sets.midcast["Astral Flow"] = { head=Relic_Glyphic.Head }
	
	-- ===================================================================================================================
	--	Weaponskills
	-- ===================================================================================================================

	-- Base weaponskill set, used when you don't have a specific set for the weaponskill.
	sets.Weaponskill = {
		head="Nyame Helm",
		neck="Fotia Gorget",
		ear1="Malignance Earring",
		ear2="Crepuscular Earring",
		body="Nyame Mail",
		hands="Nyame Gauntlets",
		ring1="Epaminondas's Ring",
		ring2="Metamorph Ring +1",
		back="Aurist's Cape +1",
		waist="Fotia Belt",
		legs="Nyame Flanchard",
		feet="Nyame Sollerets"
	}

	-- It's ok to just target accuracy & magic accuracy for this set, and use it to get AM3, apply defense down, and/or open skillchains.
	sets.midcast["Garland of Bliss"] = set_combine(sets.Weaponskill, {
		neck="Sanctity Necklace",
		ear2="Friomisi Earring",
		waist="Orpheus's Sash",
	})

	-- Shattersoul is a good weaponskill for skillchaining with Ifrit. If that's your intent, I suggest stacking accuracy.
	-- If you have access to Oshala, that's generally a better use.
	sets.midcast["Shattersoul"] = set_combine(sets.Weaponskill, {
		head=Empyrean_Beckoner.Head,
		ear1="Zennaroi Earring",
		ear2="Telos Earring",
		body="Tali'ah Manteel +2",
		hands=Empyrean_Beckoner.Hands,
		back=Campestres.Melee,
		waist="Fotia Belt",
		feet=Empyrean_Beckoner.Feet
	})

	sets.midcast["Cataclysm"] = set_combine(sets.midcast["Garland of Bliss"], {})
	
	-- Magic accuracy here to land defense down
	sets.midcast["Shell Crusher"] = set_combine(sets.Weaponskill, {
		head=Empyrean_Beckoner.Head,
		neck="Sanctity Necklace",
		ear1="Dignitary's Earring",
		body=Empyrean_Beckoner.Body,
		hands=Empyrean_Beckoner.Hands,
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		back=Campestres.Melee,
		waist="Null Belt",
		feet=Empyrean_Beckoner.Feet,
	})
	
	sets.midcast["Black Halo"] = set_combine(sets.Weaponskill, {
		neck="Republican Platinum Medal",
		waist="Grunfeld Rope",
	})
	
	sets.midcast["Oshala"] = set_combine(sets.Weaponskill, {
		ear2="Telos Earring",
		neck="Shulmanu Collar",
		ring1="Epaminondas's Ring",
		ring2="Metamorph Ring +1",
		waist="Acuity Belt +1",
	})
	
	sets.midcast["Rock Crusher"] = {	-- Low damage set used for SC in Omen (Punch>Rock Crusher)
		head="Baayami Hat +1",
		body="Baayami Robe +1",
		hands="Baayami Cuffs +1",
		legs="Baayami Slops +1",
		feet="Baayami Sabots +1"
	}

	sets.pet_midcast = {}

	-- Main physical pact set (Volt Strike, Pred Claws, etc.)
	-- Prioritize BP Damage & Pet: Double Attack
	-- Strong Alternatives:
	--   Nirvana, Gridarvor, Apogee Crown/Pumps/Dalmatica, AF body/hands, Empy Feet, Shulmanu Collar (equal to ~R15 Collar),
	--   Merlinic Dastanas or Helios Gloves (both equal to R20 Indomitable), Gelos Earring, Regal Belt, Varar Ring, Kyrene's Earring
	-- I find that between the head, hands, and feet augments you generally want two attack and one accuracy. Helios are easiest to change.
	sets.pet_midcast.Physical_BP = {
		main="Opashoro",
		sub="Elan Strap +1",
		ammo="Epitaph",
		head=Helios.Head,
		neck="Summoner's Collar +2",
		ear1="Lugalbanda Earring",
		ear2="Sroda Earring",
		body=Relic_Glyphic.Body,
		hands="Indomitable Gloves",
		ring1="Cath Palug Ring",
		ring2="Fickblix's Ring",
		back=Campestres.AvatarBP,
		waist="Incarnation Sash",
		legs=Apogee.Legs_Physical,
		feet=Helios.Feet_Attack
	}

	-- Physical Pact AM3 set, less emphasis on Pet:DA (can use the calculator on my Pastebin to fine tune BP Dmg versus Pet:DA)
	-- Indomitable Gloves generally surpasses well-augmented Merlinic only at max rank (R30)
	sets.pet_midcast.Physical_BP_AM3 = set_combine(sets.pet_midcast.Physical_BP, {
		body=Artifact_Convoker.Body,
		ring1="Varar Ring +1",
		feet=Apogee.Feet_Physical
	})

	-- Physical pacts which benefit more from TP than Pet:DA (like Spinning Dive and other pacts you never use except that one time)
	sets.pet_midcast.Physical_BP_TP = set_combine(sets.pet_midcast.Physical_BP, {
		head=Apogee.Head_Physical,
		body=Artifact_Convoker.Body,
		hands=Merlinic.Hands_Physical,
		ring1="Varar Ring +1",
		waist="Regal Belt",
		legs="Enticer's Pants",
		feet=Apogee.Feet_Physical
	})

	-- Used for all physical pacts when AccMode is true
	sets.pet_midcast.Physical_BP_Acc = set_combine(sets.pet_midcast.Physical_BP, {
		head=Apogee.Head_Physical,
		ear2="Beckoner's Earring +1",
		body=Artifact_Convoker.Body,
		feet=Empyrean_Beckoner.Feet
	})

	-- Base magic pact set
	-- Prioritize BP Damage & Pet:MAB
	-- Strong Alternatives:
	-- Espiritus, Apogee Crown/Slacks, Adad Amulet (equal to ~R12 Collar), Gelos Earring, Sancus Sachet
	sets.pet_midcast.Magic_BP_Base = {
		main={ name="Grioavolr", augments={'Blood Pact Dmg.+10','Pet: STR+5','Pet: Mag. Acc.+18','Pet: "Mag.Atk.Bns."+25',}},
		sub="Elan Strap +1",
		ammo="Epitaph",
		head="Cath Palug Crown",
		neck="Summoner's Collar +2",
		ear1="Lugalbanda Earring",
		ear2="Beckoner's Earring +1",
		body=Apogee.Body_Magic,
		hands=Merlinic.Hands_Magic,
		ring1={name="Varar Ring +1", bag="wardrobe2"},
		ring2="Fickblix's Ring",
		back=Campestres.SummonerFC,
		waist="Regal Belt",
		legs="Enticer's Pants",
		feet=Apogee.Feet_Magic
	}
	
	-- Some magic pacts benefit more from TP than others.
	-- Note: This set will only be used on merit pacts if you have less than 4 merits.
	--       Make sure to update your merit values at the top of this Lua.
	sets.pet_midcast.Magic_BP_TP = set_combine(sets.pet_midcast.Magic_BP_Base, {
	})

	-- NoTP set used when you don't need Enticer's
	sets.pet_midcast.Magic_BP_NoTP = set_combine(sets.pet_midcast.Magic_BP_Base, {
		legs=Apogee.Legs_Magic
	})

	sets.pet_midcast.Magic_BP_TP_Acc = set_combine(sets.pet_midcast.Magic_BP_TP, {
		head=Merlinic.Head,
		body=Artifact_Convoker.Body,
		hands=Merlinic.Hands_MagicAcc
	})

	sets.pet_midcast.Magic_BP_NoTP_Acc = set_combine(sets.pet_midcast.Magic_BP_NoTP, {
		head=Merlinic.Head,
		body=Artifact_Convoker.Body,
		hands=Merlinic.Hands_MagicAcc
	})

	-- Favor BP Damage above all. Pet:MAB also very strong.
	-- Pet: Accuracy, Attack, Magic Accuracy moderately important.
	-- Strong Alternatives:
	-- Nirvana, Keraunos, Grioavolr, Espiritus, Was, Apogee Crown, Apogee Dalmatica, Adad Amulet
	sets.pet_midcast.FlamingCrush = {
		main="Opashoro",
		sub="Elan Strap +1",
		ammo="Epitaph",
		head="Cath Palug Crown",
		neck="Summoner's Collar +2",
		ear1="Lugalbanda Earring",
		ear2="Beckoner's Earring +1",
		body=Artifact_Convoker.Body,
		hands=Merlinic.Hands_Magic,
		ring1={name="Varar Ring +1", bag="wardrobe2"},
		ring2="Fickblix's Ring",
		back=Campestres.AvatarBP,
		waist="Regal Belt",
		legs=Apogee.Legs_Magic,
		feet=Apogee.Feet_Magic
	}

	sets.pet_midcast.FlamingCrush_Acc = set_combine(sets.pet_midcast.FlamingCrush, {
		hands="Indomitable Gloves",
		feet=Empyrean_Beckoner.Feet
	})

	-- Pet: Magic Acc set - Mainly used for debuff pacts like Bitter Elegy
	sets.pet_midcast.MagicAcc_BP = {
		main="Opashoro",
		sub="Vox Grip",
		ammo="Epitaph",
		head=Empyrean_Beckoner.Head,
		neck="Summoner's Collar +2",
		ear1="Enmerkar Earring",
		ear2="Lugalbanda Earring",
		body=Empyrean_Beckoner.Body,
		hands="Lamassu Mitts +1",
		ring1="Cath Palug Ring",
		ring2="Fickblix's Ring",
		back=Campestres.SummonerFC,
		waist="Incarnation Sash",
		legs=Empyrean_Beckoner.Legs,
		feet="Bunzi's Sabots"
	}

	sets.pet_midcast.Debuff_Rage = sets.pet_midcast.MagicAcc_BP

	-- Pure summoning magic set, mainly used for buffs like Hastega II.
	-- Strong Alternatives:
	-- Andoaa Earring, Summoning Earring, Lamassu Mitts +1, Caller's Pendant
	sets.pet_midcast.SummoningMagic = {
		main={ name="Espiritus", augments={'Summoning magic skill +15','Pet: Mag. Acc.+30','Pet: Damage taken -4%',}},
		sub="Vox Grip",
		ammo="Epitaph",
		head="Baayami Hat +1",
		neck="Hoxne Torque",
		ear1="Cath Palug Earring",
		ear2="Lodurr Earring",
		body="Baayami Robe +1",
		hands="Baayami Cuffs +1",
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2="Evoker's Ring",
		back={ name="Conveyance Cape", augments={'Summoning magic skill +5','Pet: Enmity+12','Blood Pact Dmg.+2',}},
		waist="Kobo Obi",
		legs="Baayami Slops +1",
		feet="Baayami Sabots +1"
	}

	sets.pet_midcast.Buff = set_combine(sets.pet_midcast.SummoningMagic, {})
	
	-- Super optional set. I use it in 15-minute Odyssey fights where a proc at the start would save me from having to reapply it.
	sets.pet_midcast.Buff.Empy = set_combine(sets.pet_midcast.Buff, {
		head=Empyrean_Beckoner.Head, -- 8
		body=Empyrean_Beckoner.Body, -- 13
		--hands=Empyrean_Beckoner.Hands, -- 33
		legs=Empyrean_Beckoner.Legs, -- 5
		feet=Empyrean_Beckoner.Feet, -- 29
	})
	
	-- Wind's Blessing set. Pet:MND increases potency.
	sets.pet_midcast.Buff_MND = set_combine(sets.pet_midcast.Buff, {
		main="Opashoro",
		neck="Summoner's Collar +2",
		ear2="Beckoner's Earring +1",
		hands="Lamassu Mitts +1",
		back=Campestres.AvatarBP,
		legs="Assiduity Pants +1",
		feet="Bunzi's Sabots"
	})

	-- Don't drop Avatar level in this set if you can help it.
	-- You can use Avatar:HP+ gear to increase the HP recovered, but most of it will decrease your own max HP.
	sets.pet_midcast.Buff_Healing = set_combine(sets.pet_midcast.Buff, {
		main="Opashoro",
		back=Campestres.AvatarBP,
		--body=Apogee.Body_PetDT,
		--feet=Apogee.Feet_Magic
	})

	-- This set is used for certain blood pacts when ImpactDebuff mode is turned ON. (/console gs c ImpactDebuff)
	-- These pacts are normally used with magic damage gear, but they're also strong debuffs when enhanced by summoning skill.
	-- This set is safe to ignore.
	sets.pet_midcast.Impact = set_combine(sets.pet_midcast.SummoningMagic, {
		main="Opashoro",
		head=Empyrean_Beckoner.Head,
		ear1="Enmerkar Earring",
		ear2="Lugalbanda Earring",
		hands="Lamassu Mitts +1"
	})
	
	-- ===================================================================================================================
	-- Aftercast Sets
	-- ===================================================================================================================
	-- Syntax: sets.aftercast.{IdleMode}.{PetName|Spirit|Avatar}.{PlayerStatus}.{LowMP}.{ForceIlvl}.{CustomMode}

	-- Example: sets.aftercast.DT["Cait Sith"] will be a set used when IdleMode is "DT" and you have Cait Sith summoned.

	-- This is your default idle gear used as a baseline for most idle sets below. Put gear here and you won't have to repeat it over and over.
	-- I focus on refresh. Strong alternatives: Asteria Mitts, Convoker Horn, Shomonjijoe
	sets.aftercast = {
		main="Mpaca's Staff",
		sub="Oneiros Grip",
		ammo="Epitaph",
		head=Empyrean_Beckoner.Head,
		neck="Loricate Torque +1",
		ear1="Cath Palug Earring",
		ear2="Beckoner's Earring +1",
		body=Apogee.Body_Magic,
		hands=Merlinic.Hands_Refresh,
		ring1="Shneddick Ring +1",
		--ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2="Murky Ring",
		back=Campestres.Nuke,
		waist="Regal Belt",
		legs="Assiduity Pants +1",
		--feet="Herald's Gaiters"
		feet="Baayami Sabots +1"
	}
	
	-- sets.aftercast.ForceIlvl = set_combine(sets.aftercast, {
		-- feet="Baayami Sabots +1"
	-- })
	sets.aftercast.LowMP = set_combine(sets.aftercast, {
		waist="Fucho-no-obi"
	})
	-- sets.aftercast.LowMP.ForceIlvl = set_combine(sets.aftercast.LowMP, {
		-- feet="Baayami Sabots +1"
	-- })
	
	-- Main perpetuation set ~~ Strong Alternatives:
	-- Gridarvor, Asteria Mitts, Shomonjijoe, Convoker's Horn, Evans Earring, Isa Belt
	sets.aftercast.Avatar = {
		main="Nirvana",
		sub="Oneiros Grip",
		ammo="Epitaph",
		head=Empyrean_Beckoner.Head,
		neck="Caller's Pendant",
		ear1="Cath Palug Earring",
		ear2="Beckoner's Earring +1",
		body=Apogee.Body_PetDT,
		hands=Merlinic.Hands_Refresh,
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2="Evoker's Ring",
		back=Campestres.AvatarBP,
		waist="Lucidity Sash",
		legs="Assiduity Pants +1",
		feet="Baayami Sabots +1"
	}
	-- If you have Fucho and don't need Lucidity Sash for perp down, you can uncomment the belt here to enable using it.
	sets.aftercast.Avatar.LowMP = set_combine(sets.aftercast.Avatar, {
		--waist="Fucho-no-obi"
	})

	sets.aftercast.Avatar.Opashoro = set_combine(sets.aftercast.Avatar, {
		body=Empyrean_Beckoner.Body,
	})

	-- Damage Taken set
	sets.aftercast.DT = set_combine(sets.DT_Base, {
	})

	sets.aftercast.DT.Avatar = set_combine(sets.aftercast.DT, {
		waist="Isa Belt"
	})
	
	sets.aftercast.DT.Avatar.Opashoro = set_combine(sets.aftercast.DT.Avatar, {
		feet=Empyrean_Beckoner.Feet
	})

	-- You aren't likely to be in PetDT mode without an avatar for long, but I default to the DT set in that scenario.
	sets.aftercast.PetDT = set_combine(sets.aftercast.DT, { })

	-- Pet:DT build. Equipped when IdleMode is "PetDT".
	-- Strong alternatives:
	-- Selenian Cap, Enticer's Pants, Enmerkar Earring, Handler's Earring, Rimeice Earring, Tali'ah Seraweels
	sets.aftercast.PetDT.Avatar = {
		main="Nirvana",
		sub="Oneiros Grip",
		ammo="Epitaph",
		head=Apogee.Head_PetDT,
		neck="Summoner's Collar +2",
		ear1="Enmerkar Earring",
		ear2="Beckoner's Earring +1",
		body=Apogee.Body_PetDT,
		hands={ name="Telchine Gloves", augments={'Pet: DEF+17','Pet: "Regen"+3','Pet: Damage taken -4%',}},
		--ring1="Thurandaut Ring +1",
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2={name="Stikini Ring +1", bag="wardrobe4"},
		back=Campestres.AvatarBP,
		waist="Isa Belt",
		legs="Bunzi's Pants",
		feet={ name="Telchine Pigaches", augments={'Pet: DEF+14','Pet: "Regen"+3','Pet: Damage taken -4%',}}
	}

	-- ===================================================================================================================
	-- Sets below this point are extremely niche. If just getting set up, this is a good stopping point to save for later.
	
	-- Kite set. I just use this to gather up mobs in Escha Ru'Aun for merit farming.
	sets.aftercast.Kite = set_combine(sets.aftercast.DT, sets.Movement)
	sets.aftercast.Kite.Avatar = set_combine(sets.aftercast.DT.Avatar, sets.Movement)
	
	sets.aftercast.Move = set_combine(sets.aftercast, sets.Movement)
	sets.aftercast.Move.Avatar = set_combine(sets.aftercast.Avatar, sets.Movement)

	-- These 2 sets are for when you're in DD mode but not actually engaged to something.
	sets.aftercast.DD = set_combine(sets.aftercast, {
		head="Null Masque",
	})

	sets.aftercast.DD.Avatar = set_combine(sets.aftercast.Avatar, {
		head="Null Masque",
	})
	sets.aftercast.DD.Avatar.Opashoro = set_combine(sets.aftercast.DD.Avatar, {
		body=Empyrean_Beckoner.Body,
	})

	-- Main melee set
	-- If you want specific things equipped only when an avatar is out, modify "sets.aftercast.DD.Avatar.Engaged" below.
	sets.aftercast.DD.Engaged = set_combine(sets.aftercast.DD.Avatar, {
		--head=Empyrean_Beckoner.Head,
		head="Bunzi's Hat",
		neck="Shulmanu Collar",
		ear1="Telos Earring",
		ear2="Cessance Earring",
		body="Tali'ah Manteel +2",
		hands="Bunzi's Gloves",
		ring1={ name="Chirich Ring +1", bag="wardrobe2" },
		ring2="Fickblix's Ring",
		back=Campestres.Melee,
		waist="Cetl Belt",
		legs="Nyame Flanchard",
		feet=Empyrean_Beckoner.Feet
	})
	
	-- Main melee set when engaged with an avatar out. Usually doesn't have many changes from the above set.
	sets.aftercast.DD.Avatar.Engaged = set_combine(sets.aftercast.DD.Engaged, {
		ear2="Sroda Earring"
	})
	
	sets.aftercast.DD.Avatar.Engaged.Opashoro = set_combine(sets.aftercast.DD.Engaged, {
		body=Empyrean_Beckoner.Body,
	})

	sets.aftercast.Enspell = set_combine(sets.aftercast, { })
	sets.aftercast.Enspell.Avatar = set_combine(sets.aftercast.Avatar, { })
	
	-- Enspell set I mainly use for Peach Power. Load up on accuracy & magic accuracy. Doesn't seem to help much honestly, it's a work in progress.
	sets.aftercast.Enspell.Engaged = set_combine(sets.aftercast.DD.Avatar.Engaged, {
		ear1="Crepuscular Earring",
		ear2="Beckoner's Earring +1",
		body=Empyrean_Beckoner.Body, --replaces feet for perp cost
		ring1="Metamorph Ring +1",
		waist="Orpheus's Sash",
		feet="Nyame Sollerets",
	})
	sets.aftercast.Enspell.Avatar.Engaged = set_combine(sets.aftercast.Enspell.Engaged, {})
	
	sets.aftercast.Favor = set_combine(sets.aftercast, { })
	
	-- Used when IdleMode is "Favor" to maximize avatar's favor effect.
	-- Skill tiers are 512 / 575 / 670 / 735
	sets.aftercast.Favor.Avatar = set_combine(sets.aftercast.Avatar, {
		head=Empyrean_Beckoner.Head,
		--ear2="Lodurr Earring",
		body=Empyrean_Beckoner.Body,
		hands="Baayami Cuffs +1",
		legs="Baayami Slops +1",
		feet="Baayami Sabots +1"
	})

	sets.aftercast.PetDD = set_combine(sets.aftercast, { })

	-- Avatar Melee set. You really don't need this set. It's only here because I can't bring myself to throw it away.
	sets.aftercast.PetDD.Avatar = set_combine(sets.aftercast.Avatar, {
		ear2="Rimeice Earring",
		body=Relic_Glyphic.Body,
		hands=Helios.Hands,
		ring2="Fickblix's Ring",
		waist="Klouskap Sash",
		feet=Helios.Feet_Acc
	})

	sets.aftercast.Zendik = set_combine(sets.aftercast, {
		body="Zendik Robe"
	})
	-- sets.aftercast.Zendik.ForceIlvl = set_combine(sets.aftercast.Zendik, {
		-- feet="Baayami Sabots +1"
	-- })
	sets.aftercast.Zendik.LowMP = set_combine(sets.aftercast.Zendik, {
		waist="Fucho-no-obi"
	})
	-- sets.aftercast.Zendik.LowMP.ForceIlvl = set_combine(sets.aftercast.Zendik.LowMP, {
		-- feet="Baayami Sabots +1"
	-- })

	sets.aftercast.Zendik.Avatar = set_combine(sets.aftercast.Favor.Avatar, {
		body="Zendik Robe"
	})

	-- I use this mode for Mewing Lullaby duty in V20+ Gaol. Heaviest defense possible, less attention toward MP management.
	sets.aftercast.MEva = set_combine(sets.aftercast.DT, {
		sub="Khonsu",
		hands="Nyame Gauntlets",
		feet="Baayami Sabots +1"
	})

	sets.aftercast.MEva.Avatar = set_combine(sets.aftercast.MEva, {
		ear1="Enmerkar Earring",
		waist="Isa Belt",
		back=Campestres.AvatarBP,
	})
	
	-- MDB set for Limbus bosses
	sets.aftercast.MDB = set_combine(sets.aftercast.DT, {
		body="Adamantite Armor",
		hands="Bunzi's Gloves",
		ring1="Shneddick Ring +1",
		waist="Null Belt",
		feet=Empyrean_Beckoner.Feet,
	})

	sets.aftercast.MDB.Avatar = set_combine(sets.aftercast.MDB, {
		back=Campestres.AvatarBP,
	})

	-- Idle set used when you have a spirit summoned.
	-- Perp Down caps at 7. Glyphic Spats will make them cast more frequently, caps at ~20 seconds.
	sets.aftercast.Spirit = set_combine(sets.aftercast.Avatar, {
		ring1={name="Stikini Ring +1", bag="wardrobe2"},
		ring2={name="Stikini Ring +1", bag="wardrobe4"},
		waist="Fucho-no-obi",
		legs=Relic_Glyphic.Legs,
	})
	sets.aftercast.Favor.Spirit = set_combine(sets.aftercast.Spirit, {
	})
	sets.aftercast.Zendik.Spirit = set_combine(sets.aftercast.Favor.Spirit, {
	})
	
	-- Town (optional): equipped OVER your idle set in towns (which still follows the Idle Mode and the pet).
	-- Only the slots you list change, e.g. a look. With a pet out: sets.aftercast.Town.Avatar if defined.
	-- Pergatory's Town set, kept as an example (uncomment to use):
	--[[
	sets.aftercast.Town = set_combine(sets.aftercast.Avatar, {
		main="Opashoro",
		sub="Oneiros Grip",
		ammo="Sancus Sachet +1",
		head="Null Masque",
		neck="Summoner's Collar +2",
		hands="Indomitable Gloves",
		ring1="Shneddick Ring +1",
		ring2="Fickblix's Ring",
		waist="Ninurta's Sash",
		legs="Bunzi's Pants",
	})
	]]

	
	-- Set that I sometimes lock myself into when faced with Encumbrance (inability to swap gear)
	sets.LockGear = {
		head=Empyrean_Beckoner.Head, -- Favor+5 for BP recast
		neck="Summoner's Collar +2",
		ear1="Lugalbanda Earring",
		ear2="Sroda Earring",
		body=Artifact_Convoker.Body, -- 15 BP recast
		hands="Indomitable Gloves",
		ring1="Cath Palug Ring",
		ring2="Fickblix's Ring",
		back=Campestres.AvatarBP,
		waist="Incarnation Sash",
		legs=Apogee.Legs_Physical,
		feet=Empyrean_Beckoner.Feet, -- 9 perp down
	}
	
	

	-- Omen "Cure 500 HP": lowers max HP (gs c lowhp)
	sets.LowHP = {
		head="Apogee Crown +1",
		body=Apogee.Body_Magic,
		legs="Apogee Slacks +1",
		feet="Apogee Pumps +1",
		back="Campestres's Cape"
	}

	-- ===================================================================================================================
	--		End of Sets
