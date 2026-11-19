-- Learning mode: fills in what the guide doesn't know yet, from your own play.
--
--   * Loot:    what drops from each boss (boss loot events plus the loot window).
--   * Models:  the boss's NPC ID and display ID, captured when you target it.
--   * Spells:  spell IDs bosses cast (cast events on target, focus, boss frames, and
--              nameplates). /ag learn status shows what it saw and skipped.
--
-- What it learns can travel two ways: to your group in game (Sync.lua) and, when you
-- choose, to the guide on GitHub (/ag share, Share.lua).
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

-- Counts something new, so /ag share can say how much is waiting to be shared.
function AG:NoteDiscovery()
	self.db.unshared = (self.db.unshared or 0) + 1
end

-- Merges a record learned elsewhere (a group member, via Sync.lua). Group members mostly
-- see the same kills, so counts take the larger of the two instead of adding up.
function AG:MergeLearned(instKey, bossKey, data)
	local rec = self:GetLearned(instKey, bossKey, true)
	local changed = false
	local function keep(field)
		if rec[field] == nil and data[field] ~= nil then rec[field] = data[field]; changed = true end
	end
	keep("name"); keep("npcID"); keep("displayID")
	if (data.kills or 0) > (rec.kills or 0) then rec.kills = data.kills; changed = true end
	for _, list in ipairs({ "loot", "spells" }) do
		for id, n in pairs(data[list] or {}) do
			if n > (rec[list][id] or 0) then rec[list][id] = n; changed = true end
		end
	end
	return changed
end

local function refreshUI()
	if AG.frame and AG.frame:IsShown() and AG.Refresh then AG:Refresh() end
end

------------------------------------------------------------------------
-- Where are we?
------------------------------------------------------------------------

local function updateInstance()
	current.instKey = AG:DetectInstance()
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
	AG:NoteDiscovery()
	if AG.QueueSync then AG:QueueSync(instKey, bossKey) end
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
		AG:NoteDiscovery()
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

	local npcID = npcIDFromGUID(UnitGUID("target"))
	if npcID and npcID ~= rec.npcID then
		rec.npcID = npcID
		AG:NoteDiscovery()
	end

	if not rec.displayID then
		probeModel = probeModel or CreateFrame("PlayerModel")
		probeModel:SetUnit("target")
		C_Timer.After(0.5, function()
			local ok, displayID = pcall(probeModel.GetDisplayInfo, probeModel)
			if ok and AG:IsUsable(displayID) and displayID and displayID > 0 then
				rec.displayID = displayID
				AG:NoteDiscovery()
				refreshUI()
			end
		end)
	end
end

------------------------------------------------------------------------
-- Spells bosses cast
------------------------------------------------------------------------

-- What happened to casts this session, for /ag learn status. Forever hides some combat
-- values (secret values), so this shows whether casts are seen at all and why any were
-- skipped.
AG.spellStats = { seen = 0, recorded = 0, hiddenSpell = 0, hiddenCaster = 0, notBoss = 0, errors = 0 }

-- Units whose casts we read: target, focus, boss frames, and nameplates (so a boss's casts
-- count even while you're healing or targeting an add).
local function watched(unit)
	return type(unit) == "string" and (unit == "target" or unit == "focus"
		or unit:match("^boss%d$") ~= nil or unit:match("^nameplate%d+$") ~= nil)
end

-- Who cast it: the unit's name, else its NPC ID, else (for boss frames) the encounter in
-- progress. Names can be hidden in combat; the other two often aren't.
local function casterName(unit)
	local name = UnitName(unit)
	if AG:IsUsable(name) and name then return name end
	local byNPC = bossByNPC(npcIDFromGUID(UnitGUID(unit)))
	if byNPC then return byNPC end
	if unit:match("^boss%d$") then return current.encounter end
end

-- One cast fires for every unit token that shows the caster (target, nameplate, boss1),
-- and both START and SUCCEEDED fire for cast-time spells, so each cast counts once.
local seenCasts, seenCount = {}, 0
local function firstTime(castGUID, bossKey, spellID)
	local key = AG:IsUsable(castGUID) and castGUID
		or (bossKey .. ":" .. spellID .. ":" .. math.floor(GetTime() * 2))
	if seenCasts[key] then return false end
	if seenCount > 500 then wipe(seenCasts); seenCount = 0 end
	seenCasts[key] = true
	seenCount = seenCount + 1
	return true
end

local function onSpellcast(unit, castGUID, spellID)
	if not watched(unit) or not current.instKey then return end
	if AG:Readable(UnitPlayerControlled(unit)) then return end -- players and pets
	local s = AG.spellStats
	s.seen = s.seen + 1
	if not AG:IsUsable(spellID) or type(spellID) ~= "number" then s.hiddenSpell = s.hiddenSpell + 1; return end
	local name = casterName(unit)
	if not name then s.hiddenCaster = s.hiddenCaster + 1; return end
	local instKey, bossKey, display = resolveBoss(name)
	if not instKey or not isBossUnit(unit, instKey, bossKey, display) then s.notBoss = s.notBoss + 1; return end
	if not firstTime(castGUID, bossKey, spellID) then return end
	s.recorded = s.recorded + 1
	local rec = AG:GetLearned(instKey, bossKey, true)
	rec.name = display
	if not rec.spells[spellID] then AG:NoteDiscovery() end
	rec.spells[spellID] = (rec.spells[spellID] or 0) + 1
end

-- /ag learn status: what learning mode can see right now.
function AG:LearnStatus()
	local s = self.spellStats
	local inst = current.instKey and self:GetInstance(current.instKey)
	return {
		string.format("Learning mode is %s%s.", self.db.learn and "on" or "off",
			inst and (", in " .. inst.name) or ", not in a dungeon or raid it knows"),
		string.format("Boss casts this session: %d seen, %d recorded.", s.seen, s.recorded),
		string.format("Skipped: %d with the spell hidden, %d with the caster hidden, %d not from a boss.",
			s.hiddenSpell, s.hiddenCaster, s.notBoss),
		s.errors > 0 and string.format("Errors: %d (last: %s)", s.errors, tostring(s.lastError)) or nil,
	}
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local events = CreateFrame("Frame")

local handlers = {
	PLAYER_ENTERING_WORLD = updateInstance,
	ZONE_CHANGED_NEW_AREA = updateInstance,
	ENCOUNTER_START = function(encounterID, name)
		if AG:IsUsable(name) then current.encounter = name end
		if AG:IsUsable(encounterID) and AG:IsUsable(name) then current.encounters[encounterID] = name end
	end,
	ENCOUNTER_END = function(encounterID, name, _, _, success)
		current.encounter = nil
		if AG:Readable(success) == 1 and AG:IsUsable(name) then markKill(name) end
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
	UNIT_SPELLCAST_START = onSpellcast,
	UNIT_SPELLCAST_CHANNEL_START = onSpellcast,
	UNIT_SPELLCAST_SUCCEEDED = onSpellcast,
}

-- For the tests, which can't fire real events.
AG.LearnHandlers = handlers
AG.LearnState = current

events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db or (not AG.db.learn and event ~= "PLAYER_ENTERING_WORLD" and event ~= "ZONE_CHANGED_NEW_AREA") then
		return
	end
	local ok, err = pcall(handlers[event], ...)
	if not ok then
		AG.spellStats.errors = AG.spellStats.errors + 1
		AG.spellStats.lastError = event .. ": " .. tostring(err)
		if AG.debug then AG:Print("Learning error in %s: %s", event, tostring(err)) end
	end
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
