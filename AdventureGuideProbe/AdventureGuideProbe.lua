-- Adventure Guide Probe
-- Finds out how much of Blizzard's Adventure Guide (Encounter Journal) exists in
-- the WoW Forever client. It reads only and changes nothing. Results print to chat
-- and save to WTF\Account\<ACCOUNT>\SavedVariables\AdventureGuideProbe.lua.

local ADDON = ...
local report = {}

local function log(fmt, ...)
	local line = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	table.insert(report, line)
	print("|cff66ccffAGProbe|r " .. line)
end

local function exists(name)
	local v = _G
	for part in string.gmatch(name, "[^%.]+") do
		if type(v) ~= "table" then return false end
		v = v[part]
	end
	return v ~= nil
end

local function safe(fn, ...)
	local ok, a, b, c, d, e, f = pcall(fn, ...)
	if not ok then return nil, "ERROR: " .. tostring(a) end
	return a, b, c, d, e, f
end

local function getAddOnInfo(name)
	if C_AddOns and C_AddOns.GetAddOnInfo then return C_AddOns.GetAddOnInfo(name) end
	if GetAddOnInfo then return GetAddOnInfo(name) end
end

local function loadAddOn(name)
	if C_AddOns and C_AddOns.LoadAddOn then return C_AddOns.LoadAddOn(name) end
	if LoadAddOn then return LoadAddOn(name) end
end

local function run()
	wipe(report)
	local version, build, _, toc = GetBuildInfo()
	log("Client %s build %s, interface %s", tostring(version), tostring(build), tostring(toc))

	-- 1. Is the Blizzard UI addon shipped, and can it load?
	local name, title, _, loadable, reason = getAddOnInfo("Blizzard_EncounterJournal")
	log("Blizzard_EncounterJournal: name=%s loadable=%s reason=%s",
		tostring(name), tostring(loadable), tostring(reason))
	local loaded, why = safe(loadAddOn, "Blizzard_EncounterJournal")
	log("LoadAddOn result: %s %s", tostring(loaded), tostring(why))
	log("EncounterJournal frame exists: %s", tostring(exists("EncounterJournal")))

	-- 2. Which API functions exist?
	local apis = {
		"EJ_GetNumTiers", "EJ_GetTierInfo", "EJ_SelectTier", "EJ_GetInstanceByIndex",
		"EJ_GetInstanceInfo", "EJ_SelectInstance", "EJ_GetEncounterInfoByIndex",
		"EJ_GetSectionInfo", "EJ_SetDifficulty", "EJ_GetNumLoot",
		"C_EncounterJournal", "C_EncounterJournal.GetLootInfoByIndex",
		"C_EncounterJournal.GetSectionInfo", "C_EncounterJournal.GetDungeonEntrancesForMap",
		"ToggleEncounterJournal", "EJMicroButton", "C_LFGInfo", "C_LFGList",
		"GetSavedInstanceInfo", "C_RaidLocks",
	}
	local missing = {}
	for _, api in ipairs(apis) do
		if not exists(api) then table.insert(missing, api) end
	end
	log("APIs missing (%d of %d): %s", #missing, #apis,
		#missing > 0 and table.concat(missing, ", ") or "none")

	-- 3. Is there journal DATA? Walk tiers -> instances -> encounters.
	if exists("EJ_GetNumTiers") then
		local numTiers = safe(EJ_GetNumTiers) or 0
		log("Journal tiers: %s", tostring(numTiers))
		for t = 1, numTiers do
			safe(EJ_SelectTier, t)
			local tierName = safe(EJ_GetTierInfo, t)
			for _, isRaid in ipairs({ false, true }) do
				local i, names = 1, {}
				while i < 80 do
					local instanceID, instName = safe(EJ_GetInstanceByIndex, i, isRaid)
					if not instanceID then break end
					local bosses = 0
					safe(EJ_SelectInstance, instanceID)
					while exists("EJ_GetEncounterInfoByIndex")
						and safe(EJ_GetEncounterInfoByIndex, bosses + 1, instanceID) do
						bosses = bosses + 1
						if bosses > 40 then break end
					end
					table.insert(names, string.format("%s[%s, %d bosses]",
						tostring(instName), tostring(instanceID), bosses))
					i = i + 1
				end
				log("  Tier %d %s %s: %s", t, tostring(tierName),
					isRaid and "raids" or "dungeons",
					#names > 0 and table.concat(names, "; ") or "(none)")
			end
		end
	end

	-- 4. Keybind and micro menu
	if exists("GetBindingKey") then
		log("Keybind for TOGGLEENCOUNTERJOURNAL: %s", tostring(GetBindingKey("TOGGLEENCOUNTERJOURNAL")))
	end
	if EJMicroButton then
		log("EJMicroButton shown=%s enabled=%s", tostring(EJMicroButton:IsShown()),
			tostring(EJMicroButton:IsEnabled()))
	end

	-- Each scan saves into its own section, so running one never erases another's results.
	AGProbeDB = AGProbeDB or {}
	AGProbeDB.when = date("%Y-%m-%d %H:%M")
	AGProbeDB.lines = CopyTable and CopyTable(report) or report
	log("Done. /reload or log out to write the SavedVariables file.")
end

-- Deep probe: the browse lists are empty, but do direct lookups by ID still work?
local function deep()
	wipe(report)

	-- Journal instances by ID (Classic ones are in the 60s-800 range, e.g. Deadmines 63).
	local found = {}
	for id = 1, 3000 do
		local name = safe(EJ_GetInstanceInfo, id)
		if type(name) == "string" and name ~= "" then
			table.insert(found, id .. "=" .. name)
		end
	end
	log("EJ_GetInstanceInfo hits: %d", #found)
	for i = 1, math.min(#found, 25) do log("  %s", found[i]) end

	-- Encounters by ID (Onyxia is 1084; Ragefire/Deadmines bosses are in the 80s-100s).
	local enc, sample = 0, {}
	local firstEncounter
	for id = 1, 4000 do
		local name, desc, encID, rootSection = safe(EJ_GetEncounterInfo, id)
		if type(name) == "string" and name ~= "" then
			enc = enc + 1
			if #sample < 15 then table.insert(sample, id .. "=" .. name) end
			if not firstEncounter and rootSection and rootSection ~= 0 then
				firstEncounter = { id = id, name = name, root = rootSection, desc = desc }
			end
		end
	end
	log("EJ_GetEncounterInfo hits: %d. Sample: %s", enc, table.concat(sample, ", "))

	-- Ability sections for one boss, if any.
	if firstEncounter and C_EncounterJournal and C_EncounterJournal.GetSectionInfo then
		local info = safe(C_EncounterJournal.GetSectionInfo, firstEncounter.root)
		log("Boss %s description: %s", firstEncounter.name, tostring(firstEncounter.desc):sub(1, 80))
		log("Root ability section: %s", type(info) == "table" and tostring(info.title) or tostring(info))
	end

	-- Loot for Onyxia (encounter 1084), the one old raid boss Forever keeps.
	if EJ_SelectEncounter and EJ_GetNumLoot then
		safe(EJ_SelectInstance, 760)
		safe(EJ_SelectEncounter, 1084)
		log("Onyxia loot count via journal: %s", tostring(safe(EJ_GetNumLoot)))
	end

	-- Dungeon entrance pins on a few zone maps (Westfall 52, Barrens 10, Dustwallow 70).
	if C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap then
		for _, mapID in ipairs({ 52, 10, 70 }) do
			local list = safe(C_EncounterJournal.GetDungeonEntrancesForMap, mapID)
			log("Entrances on map %d: %s", mapID, type(list) == "table" and #list or tostring(list))
		end
	end

	-- Lockouts and what the micro button does.
	log("Saved instances: %s", tostring(safe(GetNumSavedInstances)))
	if EJMicroButton then
		log("EJMicroButton OnClick handler: %s, tooltip: %s",
			tostring(EJMicroButton:GetScript("OnClick") ~= nil), tostring(EJMicroButton.tooltipText))
	end

	-- Can addons show 3D creature models? (Hogger's display ID is 384.)
	local ok, err = pcall(function()
		local m = CreateFrame("PlayerModel")
		m:SetDisplayInfo(384)
	end)
	log("PlayerModel SetDisplayInfo works: %s %s", tostring(ok), tostring(err or ""))

	AGProbeDB = AGProbeDB or {}
	AGProbeDB.deep = { when = date("%Y-%m-%d %H:%M"), lines = CopyTable and CopyTable(report) or report }
	log("Deep scan done. /reload to save it.")
end

------------------------------------------------------------------------
-- /agprobe art: which dungeon artwork files exist in this client?
-- Tries Blizzard's naming patterns for journal buttons, journal lore art, LFG
-- backgrounds/icons, and loading screens, for every instance name variant.
------------------------------------------------------------------------

-- Instance key -> name variants Blizzard has used in art file names.
local ART_NAMES = {
	hallofthanes = { "HallofThanes", "TheHallofThanes", "HallsofThanes" },
	ragefire = { "RagefireChasm", "Ragefire" },
	ruinslordaeron = { "RuinsofLordaeron", "Lordaeron" },
	deadmines = { "Deadmines", "TheDeadmines" },
	wailing = { "WailingCaverns" },
	shadowfang = { "ShadowfangKeep", "Shadowfang" },
	excavation = { "ExcavationSite", "ExcavationSiteWetlands", "Wetlands" },
	blackfathom = { "BlackfathomDeeps", "Blackfathom" },
	stockade = { "Stockade", "TheStockade", "StormwindStockade", "StormwindJail" },
	dalaran = { "Dalaran", "CityofDalaran", "DalaranSewers" },
	razorfenkraul = { "RazorfenKraul" },
	gnomeregan = { "Gnomeregan" },
	scarlet = { "ScarletMonastery", "Monastery", "ScarletHalls", "ScarletGraveyard",
		"ScarletLibrary", "ScarletArmory", "ScarletCathedral" },
	drownedcity = { "DrownedCity", "TheDrownedCity" },
	razorfendowns = { "RazorfenDowns" },
	kroldok = { "KroldokStronghold", "Kroldok" },
	uldaman = { "Uldaman" },
	zulfarrak = { "ZulFarrak", "Zulfarrak" },
	alcaz = { "AlcazPrison", "Alcaz" },
	maraudon = { "Maraudon" },
	sunkentemple = { "SunkenTemple", "TempleofAtalHakkar", "TempleOfAtalHakkar" },
	brd = { "BlackrockDepths" },
	diremaul = { "DireMaul", "DireMaulEast", "DireMaulWest", "DireMaulNorth" },
	blackmaw = { "BlackmawHold", "Blackmaw" },
	lbrs = { "LowerBlackrockSpire", "BlackrockSpire" },
	ubrs = { "UpperBlackrockSpire" },
	scholomance = { "Scholomance" },
	shaperterrace = { "ShapersTerrace", "TheShapersTerrace" },
	stratholme = { "Stratholme" },
	barrowdeeps = { "BarrowDeeps" },
	hyjalsummit = { "HyjalSummit", "MountHyjal", "Hyjal" },
	onyxia = { "OnyxiasLair", "Onyxia" },
}

local ART_PATTERNS = {
	"Interface\\EncounterJournal\\UI-EJ-DUNGEONBUTTON-%s",
	"Interface\\EncounterJournal\\UI-EJ-LOREBG-%s",
	"Interface\\LFGFrame\\UI-LFG-BACKGROUND-%s",
	"Interface\\LFGFrame\\LFGIcon-%s",
	"Interface\\Glues\\LoadingScreens\\LoadScreen%s",
	"Interface\\Glues\\LoadingScreens\\LoadingScreen_%s",
}

local function textureExists(tex, path)
	tex:SetTexture(nil)
	local ok, result = pcall(tex.SetTexture, tex, path)
	local fileID = tex.GetTextureFileID and tex:GetTextureFileID()
	-- SetTexture returns true even for missing files here, so only a file ID counts.
	return ok and type(fileID) == "number" and fileID > 0, fileID
end

local function art()
	wipe(report)
	local probeFrame = CreateFrame("Frame")
	local tex = probeFrame:CreateTexture()
	-- Sanity check: one file that must exist, one that must not.
	local real = textureExists(tex, "Interface\\Icons\\INV_Misc_QuestionMark")
	local fake = textureExists(tex, "Interface\\Icons\\AGProbe_DoesNotExist")
	log("Detector check: real file %s, fake file %s (want true, false)", tostring(real), tostring(fake))

	local found, total = {}, 0
	for key, names in pairs(ART_NAMES) do
		for _, name in ipairs(names) do
			for _, pattern in ipairs(ART_PATTERNS) do
				local path = pattern:format(name)
				total = total + 1
				local ok, fileID = textureExists(tex, path)
				if ok then
					table.insert(found, string.format("%s|%s|%s", key, path, tostring(fileID)))
				end
			end
		end
	end
	table.sort(found)
	log("Art: %d of %d candidate files exist", #found, total)
	for _, line in ipairs(found) do log("  %s", line) end
	AGProbeDB = AGProbeDB or {}
	AGProbeDB.art = { when = date("%Y-%m-%d %H:%M"), found = found, total = total, detector = { real, fake } }
	log("Art scan done. /reload to save it.")
end

------------------------------------------------------------------------
-- /agprobe maps: which in-game maps exist for dungeons and raids?
------------------------------------------------------------------------

-- Words that appear in our instances' map names (matched case-insensitively).
local MAP_WORDS = {
	"thane", "ragefire", "lordaeron", "deadmines", "wailing", "shadowfang", "excavation",
	"blackfathom", "stockade", "dalaran", "razorfen", "gnomeregan", "scarlet", "drowned",
	"krol", "uldaman", "farrak", "alcaz", "maraudon", "hakkar", "sunken", "blackrock",
	"dire maul", "warpwood", "gardens", "gordok", "blackmaw", "scholomance", "shaper",
	"stratholme", "barrow", "hyjal", "onyxia",
}

local function maps()
	wipe(report)
	local rows, typeCounts, total = {}, {}, 0
	for id = 1, 30000 do
		local info = C_Map.GetMapInfo(id)
		if info then
			total = total + 1
			typeCounts[info.mapType] = (typeCounts[info.mapType] or 0) + 1
			local lname = (info.name or ""):lower()
			for _, word in ipairs(MAP_WORDS) do
				if lname:find(word, 1, true) then
					local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(id)
					local group = C_Map.GetMapGroupID and C_Map.GetMapGroupID(id)
					table.insert(rows, string.format("%d|%s|type=%s|parent=%s|group=%s|layers=%s",
						id, info.name, tostring(info.mapType), tostring(info.parentMapID),
						tostring(group), tostring(layers and #layers or 0)))
					break
				end
			end
		end
	end
	local types = {}
	for t, n in pairs(typeCounts) do table.insert(types, t .. "=" .. n) end
	log("Maps found: %d total; by type: %s", total, table.concat(types, ", "))
	log("Maps matching our instances: %d", #rows)
	for i = 1, math.min(#rows, 10) do log("  %s", rows[i]) end
	-- Where am I right now? Useful when standing inside a dungeon.
	local here = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	log("Your current map: %s", tostring(here))
	AGProbeDB = AGProbeDB or {}
	AGProbeDB.maps = { when = date("%Y-%m-%d %H:%M"), rows = rows, total = total, types = types, here = here }
	log("Map scan done. /reload to save it (the full list is in the saved file).")
end

------------------------------------------------------------------------
-- /agprobe newart: find the client's own art for Forever-new instances, so the
-- addon can use file IDs instead of bundling pictures. Two approaches:
--   1. The Dungeon Finder: GetLFGDungeonInfo returns each dungeon's texture name
--      (or file ID), which Blizzard's UI turns into the finder icon and background.
--   2. Wider path guesses: more loading-screen folders and name spellings.
------------------------------------------------------------------------

local NEW_INSTANCE_NAMES = {
	hallofthanes = { "HallofThanes", "HallOfThanes", "TheHallofThanes", "Thanes", "HallofThanesDungeon" },
	ruinslordaeron = { "RuinsofLordaeron", "RuinsOfLordaeron", "LordaeronRuins", "Lordaeron", "Undercity" },
	excavation = { "ExcavationSite", "ExcavationSiteWetlands", "WetlandsExcavation", "Excavation", "Wetlands" },
	dalaran = { "Dalaran", "CityofDalaran", "CityOfDalaran", "DalaranCity", "DalaranCrater", "Dalaran_Crater" },
	drownedcity = { "DrownedCity", "TheDrownedCity", "Drowned", "DrownedCityDungeon" },
	kroldok = { "KroldokStronghold", "KrolDokStronghold", "Kroldok", "KrolDok" },
	alcaz = { "AlcazPrison", "AlcazIsland", "Alcaz" },
	blackmaw = { "BlackmawHold", "Blackmaw", "BlackmawFortress" },
	shaperterrace = { "ShapersTerrace", "TheShapersTerrace", "ShaperTerrace", "Shapers" },
}

local NEW_ART_PATTERNS = {
	"Interface\\Glues\\LoadingScreens\\LoadScreen%s",
	"Interface\\Glues\\LoadingScreens\\LoadingScreen_%s",
	"Interface\\Glues\\LoadingScreens\\LoadScreen_%s",
	"Interface\\Glues\\LoadingScreens\\LoadingScreen%s",
	"Interface\\Glues\\LoadingScreens\\LoadScreen%sDungeon",
	"Interface\\Glues\\LoadingScreens\\LoadScreen%s_Wide",
	"Interface\\Glues\\LoadingScreens\\LoadScreen%sWide",
	"Interface\\Glues\\LoadingScreens\\Forever\\LoadScreen%s",
	"Interface\\Glues\\LoadingScreens\\Forever\\%s",
	"Interface\\Glues\\LoadingScreens\\Expansion10\\LoadScreen%s",
	"Interface\\Forever\\LoadScreen%s",
	"Interface\\Forever\\%s",
	"Interface\\EncounterJournal\\UI-EJ-DUNGEONBUTTON-%s",
	"Interface\\EncounterJournal\\UI-EJ-LOREBG-%s",
	"Interface\\LFGFrame\\UI-LFG-BACKGROUND-%s",
	"Interface\\LFGFrame\\LFGIcon-%s",
}

local function readable(v)
	return not (issecretvalue and issecretvalue(v))
end

local function newart()
	wipe(report)
	local probeFrame = CreateFrame("Frame")
	local tex = probeFrame:CreateTexture()
	local found, lfg = {}, {}

	-- 1. Dungeon Finder entries whose names match our instances.
	if GetLFGDungeonInfo then
		for id = 1, 5000 do
			local ok, name, typeID, _, minLevel, maxLevel, _, _, _, _, _, texture = pcall(GetLFGDungeonInfo, id)
			if ok and name and readable(name) and readable(texture) then
				local lname = tostring(name):lower()
				for _, word in ipairs(MAP_WORDS) do
					if lname:find(word, 1, true) then
						local row = string.format("%d|%s|type=%s|levels=%s-%s|texture=%s",
							id, tostring(name), tostring(typeID), tostring(minLevel), tostring(maxLevel), tostring(texture))
						-- Blizzard's UI builds the finder art from a texture name.
						if type(texture) == "string" and texture ~= "" then
							local finderArt = {
								icon = "Interface\\LFGFrame\\LFGIcon-%s",
								background = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-%s",
							}
							for label, pattern in pairs(finderArt) do
								local hit, fileID = textureExists(tex, pattern:format(texture))
								if hit then row = row .. string.format("|%s=%s", label, tostring(fileID)) end
							end
						end
						table.insert(lfg, row)
						break
					end
				end
			end
		end
	else
		log("GetLFGDungeonInfo does not exist in this client.")
	end
	log("Dungeon Finder entries matching our instances: %d", #lfg)
	for _, row in ipairs(lfg) do log("  %s", row) end

	-- 2. Wider path guesses for the Forever-new instances.
	local total = 0
	for key, names in pairs(NEW_INSTANCE_NAMES) do
		for _, name in ipairs(names) do
			for _, pattern in ipairs(NEW_ART_PATTERNS) do
				local path = pattern:format(name)
				total = total + 1
				local ok, fileID = textureExists(tex, path)
				if ok then table.insert(found, string.format("%s|%s|%s", key, path, tostring(fileID))) end
			end
		end
	end
	table.sort(found)
	log("New-instance art: %d of %d candidate files exist", #found, total)
	for _, line in ipairs(found) do log("  %s", line) end

	AGProbeDB = AGProbeDB or {}
	AGProbeDB.newart = { when = date("%Y-%m-%d %H:%M"), lfg = lfg, found = found, total = total }
	log("New-art scan done. /reload to save it.")
end

------------------------------------------------------------------------
-- /agprobe lfg: every value GetLFGDungeonInfo returns for a classic dungeon and the
-- Forever-new ones (IDs 3267-3275, found by /agprobe newart). The texture isn't in the
-- slot retail uses, so this shows where it is, then checks each string as finder art.
------------------------------------------------------------------------

local LFG_IDS = { 5, 3267, 3268, 3269, 3270, 3271, 3272, 3273, 3274, 3275 }

local function describe(v)
	if not readable(v) then return "secret" end
	if type(v) == "string" then return string.format("%q", v) end
	return tostring(v)
end

local function lfg()
	wipe(report)
	local probeFrame = CreateFrame("Frame")
	local tex = probeFrame:CreateTexture()
	local rows = {}
	for _, id in ipairs(LFG_IDS) do
		local values = { pcall(GetLFGDungeonInfo, id) }
		local parts = {}
		for i = 2, #values do
			local v = values[i]
			local part = (i - 1) .. "=" .. describe(v)
			if type(v) == "string" and readable(v) and v ~= "" then
				for label, pattern in pairs({ icon = "Interface\\LFGFrame\\LFGIcon-%s",
					background = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-%s",
					loading = "Interface\\Glues\\LoadingScreens\\LoadScreen%s" }) do
					local hit, fileID = textureExists(tex, pattern:format(v))
					if hit then part = part .. string.format("[%s=%d]", label, fileID) end
				end
			end
			table.insert(parts, part)
		end
		local row = id .. " | " .. table.concat(parts, " ")
		table.insert(rows, row)
		log("%s", row)
	end
	AGProbeDB = AGProbeDB or {}
	AGProbeDB.lfg = { when = date("%Y-%m-%d %H:%M"), rows = rows }
	log("LFG scan done. /reload to save it.")
end

SLASH_AGPROBE1 = "/agprobe"
SlashCmdList.AGPROBE = function(msg)
	if msg == "art" then
		art()
	elseif msg == "newart" then
		newart()
	elseif msg == "lfg" then
		lfg()
	elseif msg == "maps" then
		maps()
	elseif msg == "deep" then
		deep()
	elseif msg == "open" then
		if ToggleEncounterJournal then
			local ok, err = pcall(ToggleEncounterJournal)
			log("ToggleEncounterJournal: %s %s", tostring(ok), tostring(err or ""))
		else
			log("ToggleEncounterJournal does not exist.")
		end
	else
		run()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	print("|cff66ccffAGProbe|r loaded. Type /agprobe art, /agprobe newart, /agprobe lfg, or /agprobe maps (then /reload), /agprobe to scan, /agprobe deep for ID lookups, /agprobe open to try opening the guide.")
end)
