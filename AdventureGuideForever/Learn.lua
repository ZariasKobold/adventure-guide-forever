-- Learning mode: fills in what the guide doesn't know yet, from your own play.
--
--   * Loot:    what drops from each boss (boss loot events plus the loot window).
--   * Models:  the boss's NPC ID and display ID, captured when you target it.
--   * Spells:  spell IDs bosses cast (cast events on target, focus, and boss frames).
--
-- It never reads the combat log, which Forever blocks for addons, and it skips any
-- value the client marks as secret. Data is saved per account in AdventureGuideForeverDB.

local _, AG = ...

local MIN_QUALITY = 2           -- uncommon and better; skips trash vendor items
local KILL_WINDOW = 120         -- seconds after a kill that loot counts for that boss

local current = {
	instKey = nil,              -- our key for the instance you're in, if we know it
	lastBoss = nil,             -- { instKey, bossKey, name, time }
	recorded = {},              -- itemIDs already counted for the current kill
	encounters = {},            -- [encounterID] = boss name, from ENCOUNTER_START
}

------------------------------------------------------------------------
-- Storage helpers
------------------------------------------------------------------------

-- Returns the learned record for a boss, creating it if needed.
-- Bosses the guide doesn't list yet are stored under their normalized name.
function AG:GetLearned(instKey, bossKey, create)
	local db = self.db and self.db.learned
	if not db or not instKey or not bossKey then return nil end
	if not db[instKey] then
		if not create then return nil end
		db[instKey] = { bosses = {} }
	end
	local bosses = db[instKey].bosses
	if not bosses[bossKey] and create then
		bosses[bossKey] = { kills = 0, loot = {}, spells = {} }
	end
	return bosses[bossKey]
end

-- Resolves a unit or encounter name to (instKey, bossKey, displayName).
local function resolveBoss(name)
	if not AG:IsUsable(name) then return nil end
	local boss, instKey = AG:FindBoss(name, current.instKey)
	if boss then return instKey, boss.key, boss.name end
	-- Unknown boss inside a known instance: learn it under its own name.
	if current.instKey then return current.instKey, AG:Normalize(name), name end
end

-- Is this unit a boss worth learning? True for bosses the guide lists, bosses already
-- learned from a boss kill, boss frames, and skull-level units. Keeps trash out.
local function isBossUnit(unit, instKey, bossKey, display)
	if AG:FindBoss(display, instKey) then return true end
	if AG:GetLearned(instKey, bossKey, false) then return true end
	if unit:match("^boss%d$") then return true end
	-- Unit info may be secret inside instances; unreadable counts as "not a boss".
	return AG:Readable(UnitLevel(unit)) == -1 or AG:Readable(UnitClassification(unit)) == "worldboss"
end

local function refreshUI()
	if AG.frame and AG.frame:IsShown() and AG.Refresh then AG:Refresh() end
end

------------------------------------------------------------------------
-- Where are we?
------------------------------------------------------------------------

local function updateInstance()
	local name, instanceType = GetInstanceInfo()
	if instanceType == "party" or instanceType == "raid" then
		local inst = AG:FindInstanceByName(name)
		current.instKey = inst and inst.key or nil
	else
		current.instKey = nil
	end
end

------------------------------------------------------------------------
-- Kills and loot
------------------------------------------------------------------------

local function markKill(name)
	local instKey, bossKey, display = resolveBoss(name)
	if not instKey then return end
	current.lastBoss = { instKey = instKey, bossKey = bossKey, name = display, time = GetTime() }
	wipe(current.recorded)
	local rec = AG:GetLearned(instKey, bossKey, true)
	rec.name = display
	rec.kills = (rec.kills or 0) + 1
end

local function recordLoot(itemID, quality)
	local boss = current.lastBoss
	if not boss or not itemID then return end
	if GetTime() - boss.time > KILL_WINDOW then return end
	quality = AG:Readable(quality)
	if quality and quality < MIN_QUALITY then return end
	if current.recorded[itemID] then return end
	current.recorded[itemID] = true

	local rec = AG:GetLearned(boss.instKey, boss.bossKey, true)
	local isNew = not rec.loot[itemID]
	rec.loot[itemID] = (rec.loot[itemID] or 0) + 1
	if isNew then
		local link = select(2, C_Item.GetItemInfo(itemID)) or ("item " .. itemID)
		AG:Print("Learned: %s drops %s.", boss.name, link)
	end
	refreshUI()
end

local function npcIDFromGUID(guid)
	if not AG:IsUsable(guid) or type(guid) ~= "string" then return nil end
	local unitType, _, _, _, _, npcID = strsplit("-", guid)
	if unitType == "Creature" or unitType == "Vehicle" then return tonumber(npcID) end
end

-- Is this NPC ID a boss we know (from the guide or from learning) in this instance?
local function bossByNPC(npcID)
	if not npcID or not current.instKey then return nil end
	local guide = AG.Guides[current.instKey]
	for _, boss in ipairs(guide and guide.bosses or {}) do
		if boss.npcID == npcID then return boss.name end
	end
	local learned = AG.db.learned[current.instKey]
	for _, rec in pairs(learned and learned.bosses or {}) do
		if rec.npcID == npcID then return rec.name end
	end
end

-- Works out which boss a loot window belongs to, or nil for trash.
local function lootSource()
	-- Best: the corpse's NPC ID, when the client doesn't hide it.
	local guid = GetLootSourceInfo and GetLootSourceInfo(1)
	local npcID = npcIDFromGUID(guid)
	if npcID then return bossByNPC(npcID), true end
	-- Next: a dead boss you're targeting.
	if AG:Readable(UnitExists("target")) and AG:Readable(UnitIsDead("target")) then
		local name = UnitName("target")
		local instKey, bossKey, display = resolveBoss(name)
		if instKey and isBossUnit("target", instKey, bossKey, display) then return display, true end
		return nil, true -- targeting dead trash
	end
	return nil, false -- unknown; fall back to the most recent kill
end

-- If you loot a dead boss, that counts as the kill even when no encounter event
-- fired (some older dungeons may not send one).
local function onLootOpened()
	local bossName, certain = lootSource()
	if certain and not bossName then return end -- trash loot
	if bossName then
		local last = current.lastBoss
		if not (last and last.name == bossName and GetTime() - last.time < KILL_WINDOW) then
			markKill(bossName)
		end
	elseif not current.lastBoss or GetTime() - current.lastBoss.time > 30 then
		return -- can't tell where this came from, so don't guess
	end
	for slot = 1, GetNumLootItems() do
		local link = GetLootSlotLink(slot)
		if AG:IsUsable(link) and link then
			local quality = select(5, GetLootSlotInfo(slot))
			local itemID = C_Item.GetItemInfoInstant(link)
			recordLoot(itemID, quality)
		end
	end
end

------------------------------------------------------------------------
-- Models: capture NPC ID and display ID when you target a boss
------------------------------------------------------------------------

local probeModel

local function captureTarget()
	if not AG:Readable(UnitExists("target")) or AG:Readable(UnitPlayerControlled("target")) then return end
	local instKey, bossKey, display = resolveBoss(UnitName("target"))
	if not instKey or not isBossUnit("target", instKey, bossKey, display) then return end
	local rec = AG:GetLearned(instKey, bossKey, true)
	rec.name = display

	rec.npcID = npcIDFromGUID(UnitGUID("target")) or rec.npcID

	if not rec.displayID then
		probeModel = probeModel or CreateFrame("PlayerModel")
		probeModel:SetUnit("target")
		C_Timer.After(0.5, function()
			local ok, displayID = pcall(probeModel.GetDisplayInfo, probeModel)
			if ok and AG:IsUsable(displayID) and displayID and displayID > 0 then
				rec.displayID = displayID
				refreshUI()
			end
		end)
	end
end

------------------------------------------------------------------------
-- Spells bosses cast
------------------------------------------------------------------------

local WATCHED = { target = true, focus = true, boss1 = true, boss2 = true, boss3 = true, boss4 = true, boss5 = true }

local function onSpellcast(unit, spellID)
	if not WATCHED[unit] or not AG:IsUsable(spellID) or not spellID then return end
	local name = UnitName(unit)
	if not AG:IsUsable(name) then return end
	local instKey, bossKey, display = resolveBoss(name)
	if not instKey or not isBossUnit(unit, instKey, bossKey, display) then return end
	local rec = AG:GetLearned(instKey, bossKey, true)
	rec.name = display
	rec.spells[spellID] = (rec.spells[spellID] or 0) + 1
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local events = CreateFrame("Frame")

local handlers = {
	PLAYER_ENTERING_WORLD = updateInstance,
	ZONE_CHANGED_NEW_AREA = updateInstance,
	ENCOUNTER_START = function(encounterID, name)
		if AG:IsUsable(encounterID) and AG:IsUsable(name) then current.encounters[encounterID] = name end
	end,
	ENCOUNTER_END = function(encounterID, name, _, _, success)
		if success == 1 and AG:IsUsable(name) then markKill(name) end
	end,
	ENCOUNTER_LOOT_RECEIVED = function(encounterID, itemID)
		if not AG:IsUsable(itemID) then return end
		local name = current.encounters[encounterID]
		local last = current.lastBoss
		if name and not (last and last.name == name) then markKill(name) end
		recordLoot(itemID)
	end,
	LOOT_OPENED = onLootOpened,
	PLAYER_TARGET_CHANGED = captureTarget,
	UNIT_SPELLCAST_START = function(unit, _, spellID) onSpellcast(unit, spellID) end,
	UNIT_SPELLCAST_SUCCEEDED = function(unit, _, spellID) onSpellcast(unit, spellID) end,
}

events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db or (not AG.db.learn and event ~= "PLAYER_ENTERING_WORLD" and event ~= "ZONE_CHANGED_NEW_AREA") then
		return
	end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Learning error in %s: %s", event, tostring(err)) end
end)

function AG:InitLearning()
	for event in pairs(handlers) do
		pcall(events.RegisterEvent, events, event) -- ignore events this client lacks
	end
	updateInstance()
end

function AG:GetCurrentInstanceKey()
	return current.instKey
end
