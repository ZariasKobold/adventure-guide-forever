-- Journey: a pedometer and a visit log, per character.
--
--   * Distance: how far you've traveled on foot, mounted, flying, swimming, and by flight
--     path. In the open world it measures how far you actually moved (UnitPosition, in
--     yards), which works for flight paths and swimming, where the movement events and the
--     reported speed can't be trusted. Inside dungeons the game hides your position, so it
--     samples your speed instead, only while you move.
--   * Visits: how many times you've entered each dungeon and raid, and each zone.
--   * This session: the same distances since you logged in (a /reload keeps counting).
--
-- Fights skew a speed-based pedometer, so combat has its own rules (see AG.JourneyPace):
-- charges and leaps spike your speed, knockbacks fling you without a single step, and the
-- game may hide your speed as a secret value mid-fight. Combat yards are also kept as their
-- own total, for the "in combat" line on the Journey page.
--
-- Saved in AdventureGuideForeverDB.journey[character]. This stays on your computer: it is
-- never sent to your group or included in /ag share.

local _, AG = ...

local TICK = 0.5               -- seconds between samples
local MAX_STEP_SPEED = 120     -- yards per second; anything faster is a teleport, not travel
local MIN_STEP = 0.05          -- yards; less is standing still
local YARDS_PER_STEP = 0.85    -- a walking stride
local RUN_SPEED = 7            -- yards per second, the normal run speed
local COMBAT_MAX_SPEED = 14    -- faster than this in a fight is a charge or leap, not steps

AG.DISTANCE_KINDS = {
	{ key = "foot",    label = "On foot",      icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
	{ key = "mounted", label = "Mounted",      icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
	{ key = "flying",  label = "Flying",       icon = "Interface\\Icons\\Ability_Mount_Gryphon_01" },
	{ key = "swim",    label = "Swimming",     icon = "Interface\\Icons\\Ability_Druid_AquaticForm" },
	{ key = "taxi",    label = "Flight paths", icon = "Interface\\Icons\\Ability_Mount_Wyvern_01" },
}

local function newDistance()
	return { foot = 0, mounted = 0, flying = 0, swim = 0, taxi = 0 }
end

local function newSession()
	return { distance = newDistance(), combat = 0, started = time() }
end

local function newRecord()
	return { distance = newDistance(), combat = 0, session = newSession(), instances = {}, zones = {} }
end

-- All the yards in a distance table, every way of traveling added up.
function AG:TotalYards(distance)
	local total = 0
	for _, yards in pairs(distance or {}) do total = total + yards end
	return total
end

-- Adds travel to a record: all time, and this session.
function AG:AddTravel(rec, kind, yards, inCombat)
	rec.session = rec.session or newSession()
	for _, t in ipairs({ rec, rec.session }) do
		t.distance[kind] = (t.distance[kind] or 0) + yards
		if inCombat then t.combat = (t.combat or 0) + yards end
	end
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
	rec.name = rec.name or key
	rec.session = rec.session or newSession()
	rec.class = rec.class or select(2, UnitClass("player"))
	return rec
end

-- Every character's records added together, for the "All characters" view.
function AG:GetJourneyTotals()
	local total = newRecord()
	for _, rec in pairs(self.db.journey) do
		for kind, yards in pairs(rec.distance or {}) do
			total.distance[kind] = (total.distance[kind] or 0) + yards
		end
		total.combat = total.combat + (rec.combat or 0)
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

function AG:StepsFrom(yards)
	return math.floor((yards or 0) / YARDS_PER_STEP)
end

------------------------------------------------------------------------
-- Pedometer
------------------------------------------------------------------------

local ticker, lastTick
local moving = false
local inCombat = false
local lastPace = RUN_SPEED     -- your last trustworthy speed, for when a fight hides it

-- How many yards per second to count, given the raw speed (nil when the game hides it) and
-- s = { combat, airborne, moving, lastPace }. Outside combat the speed is used as is. In a
-- fight:
--   * a hidden speed counts as your last normal pace while you're moving (you're still
--     running, we just can't see how fast);
--   * speed is capped at COMBAT_MAX_SPEED, so a charge or leap counts like running, not
--     like a 40-yard stride;
--   * in the air (knockbacks, leaps, disengages) only steering at your normal pace counts,
--     and nothing counts if you aren't pressing a movement key.
function AG.JourneyPace(speed, s)
	if not s.combat then return speed or 0 end
	local pace = s.lastPace or RUN_SPEED
	if speed == nil then return s.moving and pace or 0 end
	if s.airborne then return s.moving and math.min(speed, pace) or 0 end
	return math.min(speed, COMBAT_MAX_SPEED)
end

-- Yards moved between two positions ({ x, y, z, map }) over dt seconds, or nil when the
-- move doesn't count: a different map (loading screen, portal), a bad interval, or a jump
-- too fast to be travel (hearthstone, summons).
function AG.JourneyStep(prev, cur, dt)
	if not prev or not cur or prev.map ~= cur.map or not dt or dt <= 0 or dt > 5 then return nil end
	local dx, dy, dz = cur.x - prev.x, cur.y - prev.y, (cur.z or 0) - (prev.z or 0)
	local d = math.sqrt(dx * dx + dy * dy + dz * dz)
	if d < MIN_STEP then return 0 end
	if d / dt > MAX_STEP_SPEED then return nil end
	return d
end

-- Your position in yards, or nil where the game hides it (dungeons, raids).
local function readPosition()
	if not UnitPosition then return nil end
	local y, x, z, map = UnitPosition("player")
	y, x, z, map = AG:Readable(y), AG:Readable(x), AG:Readable(z), AG:Readable(map)
	if type(x) ~= "number" or type(y) ~= "number" then return nil end
	return { x = x, y = y, z = type(z) == "number" and z or 0, map = map }
end

local lastPos

local function travelKind()
	if AG:Readable(UnitOnTaxi("player")) then return "taxi" end
	if IsSwimming and AG:Readable(IsSwimming()) then return "swim" end
	if IsFlying and AG:Readable(IsFlying()) then return "flying" end
	if AG:Readable(IsMounted()) then return "mounted" end
	return "foot"
end

local function stopTicker()
	if ticker then ticker:Cancel() end
	ticker = nil
end

local function sample()
	local now = GetTime()
	local dt = now - (lastTick or now)
	lastTick = now
	local onTaxi = AG:Readable(UnitOnTaxi("player"))
	local airborne = IsFalling and AG:Readable(IsFalling()) == true
	local pos = readPosition()

	-- Measured distance where we have a position; the reported speed elsewhere.
	local speed
	if pos then
		local step = AG.JourneyStep(lastPos, pos, dt)
		speed = step and dt > 0 and step / dt or 0
	else
		speed = AG:Readable(GetUnitSpeed("player"))
		if type(speed) ~= "number" then speed = nil end
	end
	lastPos = pos

	if speed and speed > 0 and not airborne and not onTaxi and (not inCombat or speed <= COMBAT_MAX_SPEED) then
		lastPace = speed
	end
	local pace = AG.JourneyPace(speed, { combat = inCombat, airborne = airborne, moving = moving, lastPace = lastPace })
	if pace > 0 and dt > 0 and dt < 5 then
		local rec = AG:GetJourney()
		if rec then
			AG:AddTravel(rec, travelKind(), pace * dt, inCombat)
			if AG.UpdateStepCounter then AG:UpdateStepCounter() end
		end
	elseif not pos and not moving and not onTaxi and not inCombat then
		stopTicker() -- in a dungeon and standing still: wait for the next move
	end
end

-- What the pedometer sees right now (/ag pedometer), for checking it in game.
function AG:PedometerStatus()
	local pos = readPosition()
	local speed = self:Readable(GetUnitSpeed("player"))
	return {
		mode = pos and "position" or "speed",
		ticking = ticker ~= nil,
		kind = travelKind(),
		speed = type(speed) == "number" and speed or nil,
		onTaxi = self:Readable(UnitOnTaxi("player")) and true or false,
		swimming = IsSwimming and self:Readable(IsSwimming()) and true or false,
		position = pos,
	}
end

local function startTicker()
	if ticker then return end
	lastTick = GetTime()
	ticker = C_Timer.NewTicker(TICK, sample)
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
	PLAYER_ENTERING_WORLD = function(isInitialLogin)
		-- A fresh login starts a new session; a /reload or loading screen doesn't.
		local rec = AG:GetJourney()
		if rec and isInitialLogin then rec.session = newSession() end
		arrive()
		-- A loading screen moves you without traveling. In the open world the ticker runs
		-- all the time (one position check per tick), so swims and flights always count.
		lastPos = nil
		startTicker()
	end,
	ZONE_CHANGED_NEW_AREA = arrive,
	PLAYER_STARTED_MOVING = function() moving = true; startTicker() end,
	PLAYER_STOPPED_MOVING = function() moving = false end,
	-- In a fight, keep sampling: the movement events can lag behind strafing and dodging.
	PLAYER_REGEN_DISABLED = function() inCombat = true; startTicker() end,
	PLAYER_REGEN_ENABLED = function() inCombat = false end,
	-- Flight paths take control away instead of firing the movement events.
	PLAYER_CONTROL_LOST = function() C_Timer.After(1, function() if AG:Readable(UnitOnTaxi("player")) then startTicker() end end) end,
	PLAYER_CONTROL_GAINED = startTicker,
}

local events = CreateFrame("Frame")
for event in pairs(handlers) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Journey error in %s: %s", event, tostring(err)) end
end)
