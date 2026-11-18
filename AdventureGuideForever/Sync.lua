-- Party sync: learning mode shares what it learns with your group, so everyone's guide
-- fills in together. Uses addon messages on the party, raid, or instance channel.
--
-- Sent after each boss kill (once out of combat), to new group members for the instance
-- you're in, and with /ag sync. Only learned boss data is sent: names, NPC and model IDs,
-- kill counts, and the item and spell IDs seen. Everything received is checked before it's
-- merged (AG:MergeLearned keeps the larger count, so repeats are harmless).
--
-- Message format, fields joined by "^" (protocol 1):
--   1^B^instKey^bossKey^kills^npcID^displayID^name
--   1^L^instKey^bossKey^itemID:count,itemID:count,...      (loot, chunked)
--   1^S^instKey^bossKey^spellID:count,...                  (spells, chunked)

local _, AG = ...

local PREFIX = "AGForever"
local PROTOCOL = "1"
local MAX_MESSAGE = 240       -- addon messages are limited to 255 bytes
local SEND_INTERVAL = 0.4     -- seconds between messages, to stay under the chat throttle
local MAX_NUMBER = 100000000
local MAX_ENTRIES = 300

AG.Sync = {}
local Sync = AG.Sync

------------------------------------------------------------------------
-- Encoding (pure functions, tested in tools/test_addon.py)
------------------------------------------------------------------------

local function clean(name)
	return (tostring(name or ""):gsub("[%^|%c]", ""):sub(1, 60))
end

local function chunks(head, map)
	local out, parts, length = {}, {}, #head
	local ids = {}
	for id in pairs(map or {}) do ids[#ids + 1] = id end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local part = id .. ":" .. map[id]
		if #parts > 0 and length + #part + 1 > MAX_MESSAGE then
			out[#out + 1] = head .. table.concat(parts, ",")
			parts, length = {}, #head
		end
		parts[#parts + 1] = part
		length = length + #part + 1
	end
	if #parts > 0 then out[#out + 1] = head .. table.concat(parts, ",") end
	return out
end

-- The messages that carry one boss's learned record.
function Sync.Encode(instKey, bossKey, rec)
	local base = PROTOCOL .. "^%s^" .. instKey .. "^" .. bossKey .. "^"
	local out = {
		string.format(base, "B") .. table.concat({
			tostring(rec.kills or 0), tostring(rec.npcID or 0), tostring(rec.displayID or 0), clean(rec.name),
		}, "^"),
	}
	for _, m in ipairs(chunks(string.format(base, "L"), rec.loot)) do out[#out + 1] = m end
	for _, m in ipairs(chunks(string.format(base, "S"), rec.spells)) do out[#out + 1] = m end
	return out
end

local function number(text)
	local n = tonumber(text)
	if n and n >= 0 and n <= MAX_NUMBER and n == math.floor(n) then return n end
end

local function pairsList(text)
	local map, n = {}, 0
	for id, count in tostring(text):gmatch("(%d+):(%d+)") do
		id, count = number(id), number(count)
		if not id or not count or id == 0 then return nil end
		n = n + 1
		if n > MAX_ENTRIES then return nil end
		map[id] = count
	end
	return n > 0 and map or nil
end

-- Reads one message. Returns instKey, bossKey, partial record; nil if anything is off.
function Sync.Decode(text)
	if type(text) ~= "string" or #text > 255 then return nil end
	local fields = { strsplit("^", text) }
	if fields[1] ~= PROTOCOL then return nil end
	local kind, instKey, bossKey = fields[2], fields[3], fields[4]
	if not instKey or not AG:GetInstance(instKey) then return nil end
	if type(bossKey) ~= "string" or not bossKey:match("^%w+$") or #bossKey > 64 then return nil end
	if kind == "B" then
		local kills, npcID, displayID = number(fields[5]), number(fields[6]), number(fields[7])
		if not kills or not npcID or not displayID then return nil end
		local name = clean(fields[8])
		return instKey, bossKey, {
			kills = kills, npcID = npcID > 0 and npcID or nil,
			displayID = displayID > 0 and displayID or nil, name = name ~= "" and name or nil,
		}
	elseif kind == "L" or kind == "S" then
		local map = pairsList(fields[5])
		if not map then return nil end
		return instKey, bossKey, kind == "L" and { loot = map } or { spells = map }
	end
end

------------------------------------------------------------------------
-- Sending
------------------------------------------------------------------------

local queue, queued = {}, {}
local sender

local function channel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end
end

local function stopSender()
	if sender then sender:Cancel() end
	sender = nil
end

local function sendNext()
	-- Addon messages may be blocked during encounters; wait until combat ends.
	if InCombatLockdown() then stopSender(); return end
	local msg = table.remove(queue, 1)
	if not msg then stopSender(); return end
	local where = channel()
	if not where then wipe(queue); stopSender(); return end
	pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, where)
end

local function startSender()
	if sender or #queue == 0 then return end
	sender = C_Timer.NewTicker(SEND_INTERVAL, sendNext)
end

-- Queues one boss's record for the group (sent once out of combat).
function AG:QueueSync(instKey, bossKey)
	if not self:Option("sync") or not channel() or not C_ChatInfo then return end
	local id = instKey .. ":" .. bossKey
	if queued[id] then return end
	local rec = self:GetLearned(instKey, bossKey, false)
	if not rec then return end
	queued[id] = true
	-- Encode when sent would be nicer, but records only grow, so encoding now is fine.
	C_Timer.After(2, function()
		queued[id] = nil
		for _, msg in ipairs(Sync.Encode(instKey, bossKey, rec)) do queue[#queue + 1] = msg end
		startSender()
	end)
end

local function queueInstance(instKey)
	local learned = AG.db.learned[instKey]
	for bossKey in pairs(learned and learned.bosses or {}) do AG:QueueSync(instKey, bossKey) end
end

-- /ag sync: the instance you're in, or everything when you're outside.
function AG:SyncNow()
	if not self:Option("sync") then
		self:Print("Group sharing is off. Turn it on in /ag options.")
		return
	end
	if not channel() then
		self:Print("You're not in a group, so there's no one to share with.")
		return
	end
	local here = self:DetectInstance()
	if here then
		queueInstance(here)
	else
		for instKey in pairs(self.db.learned) do queueInstance(instKey) end
	end
	self:Print("Sharing what you've learned with your group.")
end

------------------------------------------------------------------------
-- Receiving
------------------------------------------------------------------------

local ACCEPTED = { PARTY = true, RAID = true, INSTANCE_CHAT = true }
local thanked = {}
local groupSize = 0

local function isMe(sender)
	local me = AG:Readable(UnitName("player"))
	return Ambiguate(sender, "none") == me
end

local function receive(prefix, text, chan, sender)
	if prefix ~= PREFIX or not ACCEPTED[chan] or not AG:Option("sync") then return end
	if not AG:IsUsable(sender) or not AG:IsUsable(text) or isMe(sender) then return end
	local instKey, bossKey, data = Sync.Decode(text)
	if not instKey then return end
	if AG:MergeLearned(instKey, bossKey, data) then
		local who = Ambiguate(sender, "none")
		if not thanked[who] then
			thanked[who] = true
			AG:Print("Got learned boss data from %s.", who)
		end
		if AG.frame and AG.frame:IsShown() then AG.UI.QueueRefresh() end
	end
end

local handlers = {
	PLAYER_LOGIN = function()
		if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
			C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
		end
		groupSize = GetNumGroupMembers()
	end,
	CHAT_MSG_ADDON = receive,
	-- Someone joined: share what you know about the instance you're in.
	GROUP_ROSTER_UPDATE = function()
		local size = GetNumGroupMembers()
		local grew = size > groupSize
		groupSize = size
		local here = AG:DetectInstance()
		if grew and here then queueInstance(here) end
	end,
	PLAYER_REGEN_ENABLED = startSender,
}

local events = CreateFrame("Frame")
for event in pairs(handlers) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Sync error in %s: %s", event, tostring(err)) end
end)
