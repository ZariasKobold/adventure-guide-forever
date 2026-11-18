-- Dungeon quests: your faction's quests for each instance (Data\Generated\Quests.lua, from
-- Wowhead's dungeon guides), and whether you've done them or have them in your log. The
-- instance page lists them, and the dungeon card says how many are still open.

local _, AG = ...

-- "Horde" or "Alliance", or nil if the game won't say (then every quest is shown).
function AG:PlayerFaction()
	local faction = UnitFactionGroup and self:Readable(UnitFactionGroup("player"))
	if faction == "Horde" or faction == "Alliance" then return faction end
	return nil
end

-- "done", "active" (in your quest log), or nil.
function AG:QuestStatus(questID)
	local log = C_QuestLog
	if not log or not questID then return nil end
	if log.IsQuestFlaggedCompleted and self:Readable(log.IsQuestFlaggedCompleted(questID)) == true then
		return "done"
	end
	if log.GetLogIndexForQuestID then
		local index = self:Readable(log.GetLogIndexForQuestID(questID))
		if type(index) == "number" and index > 0 then return "active" end
	end
	return nil
end

-- Your faction's quests for an instance, how many belong to the other faction, and how many
-- of yours you haven't finished.
function AG:QuestsFor(instKey)
	local quests, other = self:GetQuests(instKey, self:PlayerFaction())
	local open = 0
	for _, q in ipairs(quests) do
		if self:QuestStatus(q.questID) ~= "done" then open = open + 1 end
	end
	return quests, other, open
end

-- Redraw the guide when a quest changes, so its check marks stay current.
local handlers = {}
local function refresh()
	if AG.frame and AG.frame:IsShown() then AG:Refresh() end
end
handlers.QUEST_ACCEPTED = refresh
handlers.QUEST_TURNED_IN = refresh
handlers.QUEST_REMOVED = refresh

local events = CreateFrame("Frame")
for event in pairs(handlers) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Quest error in %s: %s", event, tostring(err)) end
end)
