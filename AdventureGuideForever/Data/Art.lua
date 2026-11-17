-- Artwork for each instance: Blizzard's own retail Adventure Guide and Dungeon Finder art,
-- which ships in the Forever client. File IDs were confirmed in game with
-- `/agprobe art` (client 1.60.1, Nov 17, 2026).
--
--   button   journal dungeon button (the picture on retail's dungeon grid)
--   lore     journal lore background (the painted scene behind the instance story)
--   loading  loading screen
--   finder   Dungeon Finder background
--   icon     small round Dungeon Finder icon
--   image    a picture bundled with the addon (Art\<key>.tga), for Forever-new instances
--
-- Forever-new instances have no art under Blizzard's names, so the addon bundles their
-- loading-screen art: 1024x512 TGA, stretched from the ~2.6:1 original with the letterbox
-- bars trimmed (UI.SetArt undoes the stretch). Anything still missing gets a drawn card.
-- Scarlet Monastery, Dire Maul, and Blackrock Spire wings share their dungeon's art.

local addonName, AG = ...

local function bundled(key)
	return "Interface\\AddOns\\" .. addonName .. "\\Art\\" .. key
end

local ART = {
	ragefire       = { button = 608211, lore = 608250, loading = 131862, finder = 340682, icon = 136350 },
	deadmines      = { button = 522352, lore = 526404, loading = 131833, finder = 337488, icon = 136332 },
	wailing        = { button = 608229, lore = 608313, loading = 131882, finder = 340702, icon = 136364 },
	shadowfang     = { button = 522358, lore = 526410, loading = 131869, finder = 340687, icon = 136357 },
	blackfathom    = { button = 608195, lore = 608234, loading = 131823, finder = 340655, icon = 136325 },
	stockade       = { button = 608223, lore = 608262, loading = 131870 },
	razorfenkraul  = { button = 608213, lore = 608252, loading = 131865, finder = 340684, icon = 136353 },
	gnomeregan     = { button = 608202, lore = 608241, loading = 131841, finder = 340665, icon = 136336 },
	razorfendowns  = { button = 608212, lore = 608251, loading = 131864, finder = 340683, icon = 136352 },
	uldaman        = { button = 608225, lore = 608264, loading = 131876, finder = 340697, icon = 136363 },
	zulfarrak      = { button = 608230, lore = 608267, loading = 131885 },
	maraudon       = { button = 608209, lore = 608248, loading = 131850, finder = 340677, icon = 136345 },
	sunkentemple   = { button = 608217, lore = 608256, loading = 131872, finder = 340690, icon = 136360 },
	brd            = { button = 608196, lore = 608235, loading = 131824, finder = 340656, icon = 136326 },
	scholomance    = { button = 608215, lore = 608254, loading = 131868, finder = 340686, icon = 136355 },
	stratholme     = { button = 608216, lore = 608255, finder = 340689, icon = 136359 },
	ubrs           = { button = 1042000, lore = 1041990, loading = 1035275, finder = 1042050, icon = 1042065 },
	onyxia         = { button = 1396589 },

	-- Raids at Mount Hyjal share the Hyjal loading screen.
	barrowdeeps    = { loading = 131847 },
	hyjalsummit    = { loading = 131847 },

	-- Forever-new dungeons with only a Dungeon Finder icon from older content.
	ruinslordaeron = { icon = 460869 },
	dalaran        = { icon = 460862 },

	-- Forever-new instances with bundled loading-screen art.
	hallofthanes   = { image = bundled("hallofthanes") },
	excavation     = { image = bundled("excavation") },
	drownedcity    = { image = bundled("drownedcity") },
	kroldok        = { image = bundled("kroldok") },
	alcaz          = { image = bundled("alcaz") },
	blackmaw       = { image = bundled("blackmaw") },
	shaperterrace  = { image = bundled("shaperterrace") },
}

-- Wings that share their parent dungeon's art.
local SCARLET_HALLS = { button = 643262, lore = 643265, loading = 643908, finder = 649960, icon = 643268 }
local SCARLET_MONASTERY = { button = 608214, lore = 608253, loading = 131852, finder = 340685, icon = 136354 }
local DIRE_MAUL = { button = 608200, lore = 608239, loading = 131835, finder = 340663, icon = 136333 }
local BLACKROCK_SPIRE = { button = 608197, lore = 608236, loading = 131825, finder = 340657, icon = 136327 }

ART.smlibrary, ART.smarmory = SCARLET_HALLS, SCARLET_HALLS
ART.smgraveyard, ART.smcathedral = SCARLET_MONASTERY, SCARLET_MONASTERY
ART.dmeast, ART.dmwest, ART.dmnorth = DIRE_MAUL, DIRE_MAUL, DIRE_MAUL
ART.lbrs = BLACKROCK_SPIRE

AG.Art = ART

-- The best available picture for a use, falling back through related art.
local PREFERENCE = {
	card   = { "button", "image", "finder", "loading", "lore" },
	header = { "loading", "image", "lore", "finder", "button" },
}

function AG:GetArt(instKey, use)
	local art = ART[instKey]
	if not art then return nil end
	for _, kind in ipairs(PREFERENCE[use]) do
		if art[kind] then return art[kind], kind end
	end
end
