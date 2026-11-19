-- Journey: a visit log, per character: how many times you've entered each dungeon and raid,
-- and each zone. The dungeon card and the card grid show the counts.
--
-- Distance traveled used to live here too; it's now its own addon, Adventure Forever
-- Pedometer (the AdventureForeverPedometer folder). Older saved distance stays in each
-- record so the pedometer can bring it over on its first load.
--
-- Saved in AdventureGuideForeverDB.journey[character]. This stays on your computer: it is
-- never sent to your group or included in /ag share.

local _, AG = ...

AG.PEDOMETER_ADDON = "AdventureForeverPedometer"

local function newRecord()
	return { instances = {}, zones = {} }
end

local function characterKey()
	local name = AG:Readable(UnitName("player"))
	local realm = GetRealmName and AG:Readable(GetRealmName())
	if type(name) ~= "string" then return nil end
	return realm and (name .. "-" .. realm) or name
end

-- This character's journey record (nil before login).
function AG:GetJourney()
	if not self.db then return nil end
	local key = characterKey()
	if not key then return nil end
	local rec = self.db.journey[key]
	if not rec then
		rec = newRecord()
		self.db.journey[key] = rec
	end
	rec.instances = rec.instances or {}
	rec.zones = rec.zones or {}
	rec.name = rec.name or key
	rec.class = rec.class or select(2, UnitClass("player"))
	return rec
end

-- Every character's visits added together, for the "All characters" view.
function AG:GetJourneyTotals()
	local total = newRecord()
	for _, rec in pairs(self.db.journey) do
		for _, list in ipairs({ "instances", "zones" }) do
			for key, v in pairs(rec[list] or {}) do
				local t = total[list][key] or { visits = 0, last = 0 }
				t.visits = t.visits + (v.visits or 0)
				t.last = math.max(t.last, v.last or 0)
				total[list][key] = t
			end
		end
	end
	return total
end

-- Whether Adventure Forever Pedometer is installed and running.
function AG:HasPedometer()
	return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(self.PEDOMETER_ADDON) and true or false
end

------------------------------------------------------------------------
-- Visits
------------------------------------------------------------------------

local function count(list, key)
	local v = list[key] or { visits = 0 }
	v.visits = v.visits + 1
	v.last = time()
	list[key] = v
	return v.visits
end

-- Counts a visit when you arrive somewhere new. The last place is saved, so a reload or
-- relog in the same spot doesn't count again.
local function arrive()
	local rec = AG:GetJourney()
	if not rec then return end
	local instKey = AG:DetectInstance()
	if instKey then
		if rec.here ~= instKey then
			rec.here = instKey
			local visits = count(rec.instances, instKey)
			if AG.ShowZoneCard then AG:ShowZoneCard(instKey, visits) end
		end
		return
	end
	rec.here = nil
	local zone = AG:Readable(GetRealZoneText())
	if type(zone) == "string" and zone ~= "" and rec.lastZone ~= zone then
		rec.lastZone = zone
		count(rec.zones, zone)
	end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local handlers = {
	PLAYER_ENTERING_WORLD = arrive,
	ZONE_CHANGED_NEW_AREA = arrive,
}

local events = CreateFrame("Frame")
for event in pairs(handlers) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Journey error in %s: %s", event, tostring(err)) end
end)
