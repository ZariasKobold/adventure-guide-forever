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

	AGProbeDB = { when = date("%Y-%m-%d %H:%M"), lines = CopyTable and CopyTable(report) or report }
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

SLASH_AGPROBE1 = "/agprobe"
SlashCmdList.AGPROBE = function(msg)
	if msg == "deep" then
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
	print("|cff66ccffAGProbe|r loaded. Type /agprobe to scan, /agprobe deep for ID lookups, /agprobe open to try opening the guide.")
end)
