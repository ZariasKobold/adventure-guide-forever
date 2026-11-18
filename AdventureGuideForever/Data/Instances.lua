-- Every dungeon and raid in WoW Forever (patch 1.60.1), in level order.
-- Source: the Forever dungeon and raid tables on warcraft.wiki.gg, November 2026. Where a
-- dungeon's own wiki page gives a newer level range, that one is used.
-- Level ranges come from each dungeon's Wowhead Forever guide where it has one (Nov 18, 2026).
-- isNew = added in Forever. Raids unlock December 9, 2026.

local _, AG = ...

local function D(key, name, abbr, zone, minL, maxL, isNew, aliases)
	table.insert(AG.Instances, {
		key = key, name = name, abbr = abbr, zone = zone,
		minLevel = minL, maxLevel = maxL, isNew = isNew,
		isRaid = false, players = 5, aliases = aliases,
	})
end

local function R(key, name, abbr, zone, players, isNew)
	table.insert(AG.Instances, {
		key = key, name = name, abbr = abbr, zone = zone,
		minLevel = 60, maxLevel = 60, isNew = isNew,
		isRaid = true, players = players,
	})
end

-- Dungeons, levels 10-39
D("hallofthanes",   "The Hall of Thanes",          "HoT",     "Ironforge",          13, 18, true)
D("ragefire",       "Ragefire Chasm",              "RFC",     "Orgrimmar",          13, 18, false)
D("wailing",        "Wailing Caverns",             "WC",      "The Barrens",        15, 25, false)
D("ruinslordaeron", "Ruins of Lordaeron",          "RoL",     "Undercity",          16, 22, true)
D("deadmines",      "Deadmines",                   "DM",      "Westfall",           18, 23, false, { "The Deadmines" })
D("shadowfang",     "Shadowfang Keep",             "SFK",     "Silverpine Forest",  22, 30, false)
D("stockade",       "Stormwind Stockade",          "Stocks",  "Stormwind City",     24, 30, false, { "The Stockade" })
D("blackfathom",    "Blackfathom Deeps",           "BFD",     "Ashenvale",          24, 32, false)
D("excavation",     "Excavation Site: Wetlands",   "ESW",     "Wetlands",           26, 32, true)
D("smgraveyard",    "Scarlet Monastery Graveyard", "SM GY",   "Tirisfal Glades",    26, 36, false)
D("dalaran",        "City of Dalaran",             "Dal",     "Alterac Mountains",  28, 34, true)
D("gnomeregan",     "Gnomeregan",                  "Gnomer",  "Dun Morogh",         29, 38, false)
D("smlibrary",      "Scarlet Monastery Library",   "SM Lib",  "Tirisfal Glades",    29, 39, false)
D("razorfenkraul",  "Razorfen Kraul",              "RFK",     "The Barrens",        30, 40, false)
D("smarmory",       "Scarlet Monastery Armory",    "SM Arm",  "Tirisfal Glades",    32, 42, false)
D("drownedcity",    "The Drowned City",            "DC",      "Stranglethorn Vale", 35, 42, true)
D("smcathedral",    "Scarlet Monastery Cathedral", "SM Cath", "Tirisfal Glades",    35, 45, false)
D("razorfendowns",  "Razorfen Downs",              "RFD",     "The Barrens",        37, 43, false)

-- Dungeons, levels 40-60
D("kroldok",        "Krol'dok Stronghold",         "KS",      "Riverglades",        40, 45, true)
D("uldaman",        "Uldaman",                     "Uld",     "Badlands",           40, 45, false)
D("zulfarrak",      "Zul'Farrak",                  "ZF",      "Tanaris",            44, 54, false)
D("maraudon",       "Maraudon",                    "Mara",    "Desolace",           45, 52, false)
D("alcaz",          "Alcaz Prison",                "AP",      "Dustwallow Marsh",   49, 54, true)
D("sunkentemple",   "Temple of Atal'Hakkar",       "ST",      "Swamp of Sorrows",   52, 58, false, { "Sunken Temple" })
D("brd",            "Blackrock Depths",            "BRD",     "Blackrock Mountain", 52, 60, false)
D("dmeast",         "Warpwood Quarter",            "DME",     "Feralas",            55, 60, false, { "Dire Maul East", "Dire Maul - Warpwood Quarter" })
D("blackmaw",       "Blackmaw Hold",               "BMH",     "Azshara",            55, 60, true)
D("lbrs",           "Lower Blackrock Spire",       "LBRS",    "Blackrock Mountain", 55, 60, false)
D("ubrs",           "Upper Blackrock Spire",       "UBRS",    "Blackrock Mountain", 55, 60, false)
D("scholomance",    "Scholomance",                 "Scholo",  "Western Plaguelands", 55, 60, false)
D("dmwest",         "Capital Gardens",             "DMW",     "Feralas",            58, 60, false, { "Dire Maul West", "Dire Maul - Capital Gardens" })
D("shaperterrace",  "Shaper's Terrace",            "ShT",     "Un'Goro Crater",     58, 60, true)
D("stratholme",     "Stratholme",                  "Strat",   "Eastern Plaguelands", 58, 60, false)
D("dmnorth",        "Gordok Commons",              "DMN",     "Feralas",            58, 60, false, { "Dire Maul North", "Dire Maul - Gordok Commons" })

-- Raids (all level 60)
R("barrowdeeps",    "Barrow Deeps",                "BD",      "Mount Hyjal",        10, true)
R("hyjalsummit",    "Hyjal Summit",                "HS",      "Mount Hyjal",        20, true)
R("onyxia",         "Onyxia's Lair",               "Ony",     "Dustwallow Marsh",   40, false)
