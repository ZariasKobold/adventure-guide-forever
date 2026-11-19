-- Sharing with the guide: /ag share turns what learning mode recorded into a block of
-- text that players paste into the share page (worker/, no account needed), which files it
-- as a GitHub issue. A GitHub Action reads it, merges it into tools/learned/community.json,
-- rebuilds Data/Generated/Community.lua, and opens a pull request. (Addons can't go online,
-- so the paste is the bridge.) Without the share page, it falls back to the GitHub issue form.
--
-- Export format (one record per line; read by tools/learned_intake.py):
--   AGF1 version=<addon version> id=<random share ID>
--   B <instKey> <bossKey> kills=<n> npc=<id> display=<id> name=<boss name>
--   L <instKey> <bossKey> <itemID>:<count> <itemID>:<count> ...
--   S <instKey> <bossKey> <spellID>:<count> ...
--   END <number of B, L, and S lines>
--
-- Only boss data is shared: no character names, no Journey stats, no wishlist. The share
-- ID is random, so repeat shares from one player replace each other instead of adding up.

local _, AG = ...

-- The share page (worker/README.md), where players paste with no account. If it's ever set
-- to nil, the Share window points to the GitHub issue form instead (which needs an account).
AG.SHARE_PAGE_URL = "https://agf-share.draconicdesigns.workers.dev"
AG.SHARE_ISSUE_URL = "https://github.com/ZariasKobold/adventure-guide-forever/issues/new?template=learned-data.yml"
AG.SHARE_URL = AG.SHARE_PAGE_URL or AG.SHARE_ISSUE_URL

local function sortedKeys(map)
	local keys = {}
	for k in pairs(map or {}) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	return keys
end

local function pairsLine(map)
	local ids, parts = {}, {}
	for id in pairs(map) do ids[#ids + 1] = id end
	table.sort(ids)
	for i, id in ipairs(ids) do parts[i] = id .. ":" .. map[id] end
	return table.concat(parts, " ")
end

-- A random ID that stays with this install, so the intake can replace older shares.
function AG:ShareID()
	if not self.db.shareID then
		local hex = {}
		for i = 1, 4 do hex[i] = string.format("%04x", math.random(0, 65535)) end
		self.db.shareID = table.concat(hex)
	end
	return self.db.shareID
end

-- The export text, and how many bosses it covers.
function AG:BuildExport()
	local lines = { string.format("AGF1 version=%s id=%s", tostring(self.version), self:ShareID()) }
	local bosses = 0
	for _, instKey in ipairs(sortedKeys(self.db.learned)) do
		if self:GetInstance(instKey) then
			local inst = self.db.learned[instKey]
			for _, bossKey in ipairs(sortedKeys(inst.bosses)) do
				local rec = inst.bosses[bossKey]
				if bossKey:match("^%w+$") and #bossKey <= 64 then
					bosses = bosses + 1
					local name = tostring(rec.name or bossKey):gsub("[|%c]", "")
					lines[#lines + 1] = string.format("B %s %s kills=%d npc=%d display=%d name=%s",
						instKey, bossKey, rec.kills or 0, rec.npcID or 0, rec.displayID or 0, name)
					if rec.loot and next(rec.loot) then
						lines[#lines + 1] = string.format("L %s %s %s", instKey, bossKey, pairsLine(rec.loot))
					end
					if rec.spells and next(rec.spells) then
						lines[#lines + 1] = string.format("S %s %s %s", instKey, bossKey, pairsLine(rec.spells))
					end
				end
			end
		end
	end
	lines[#lines + 1] = "END " .. (#lines - 1)
	return table.concat(lines, "\n"), bosses
end

------------------------------------------------------------------------
-- A gentle nudge, back in the open world: only once a few things have piled up, at most
-- every few days, and never if you turned it off in Options.
------------------------------------------------------------------------

AG.SHARE_NUDGE_MIN = 10                 -- new finds before we mention it
AG.SHARE_NUDGE_GAP = 3 * 24 * 60 * 60   -- seconds between reminders (3 days)

local nudged = false

-- Whether to remind you now (now = time()).
function AG:ShouldNudgeShare(now)
	if not self.db or not self:Option("shareReminder") then return false end
	if (self.db.unshared or 0) < self.SHARE_NUDGE_MIN then return false end
	local last = self.db.lastShareNudge
	return not (type(last) == "number" and now - last < self.SHARE_NUDGE_GAP)
end

local function nudge()
	if nudged or AG:DetectInstance() or not AG:ShouldNudgeShare(time()) then return end
	nudged = true
	AG.db.lastShareNudge = time()
	AG:Print("Learning mode found %d new things since you last shared. If you'd like to add them to "
		.. "the guide for everyone, type |cffffd100/ag share|r%s. (You can turn this reminder off in Options.)",
		AG.db.unshared, AG.SHARE_PAGE_URL and ": it takes a few seconds, no account needed" or "")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
	C_Timer.After(8, function() pcall(nudge) end)
end)
