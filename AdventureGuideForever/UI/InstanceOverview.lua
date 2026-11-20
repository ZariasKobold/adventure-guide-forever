-- An instance's overview page: Blizzard's art for the instance as a header, then its story,
-- how to run it, tips, and a clickable boss summary. Shown when "Overview" is selected in
-- the instance page's boss list.

local _, AG = ...
local UI = AG.UI

local HEADER_HEIGHT = 170

function AG:CreateInstanceOverview(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel:Hide()
	panel.doc = UI.CreateDocument(panel)
	panel.doc.scroll:SetPoint("TOPLEFT", 10, -10)
	panel.doc.scroll:SetPoint("BOTTOMRIGHT", -28, 10)
	self.instanceOverview = panel
end

local function levelLine(inst)
	if inst.isRaid then
		return string.format("%s  |  Raid, %d players  |  Level 60", inst.zone, inst.players)
	end
	return string.format("%s  |  |cff%sLevels %d-%d|r  |  5 players", inst.zone, AG:LevelColor(inst), inst.minLevel, inst.maxLevel)
end

local QUEST_ICON = {
	done = "Interface\\RaidFrame\\ReadyCheck-Ready",
	active = "Interface\\GossipFrame\\ActiveQuestIcon",
	open = "Interface\\GossipFrame\\AvailableQuestIcon",
}

-- A quest's level in the game's difficulty color for you (grey, green, yellow, orange, red).
local function questLevel(level)
	if not level then return "" end
	local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
	if type(color) == "table" and color.r then
		return string.format("|cff%02x%02x%02x[%d]|r ", color.r * 255, color.g * 255, color.b * 255, level)
	end
	return string.format("[%d] ", level)
end

local function questBody(q)
	local body = q.start and ("Starts: " .. q.start) or nil
	if body and q.x and q.y then body = body .. string.format("  |cff888888(%.0f, %.0f)|r", q.x, q.y) end
	if q.chain then
		local chain = (q.chainName and q.chainName ~= q.name)
			and string.format("Part of a chain that starts with |cffffd100%s|r.", q.chainName)
			or "Part of a quest chain: earlier steps come first."
		body = body and (body .. "\n" .. chain) or chain
	end
	if q.rewards and #q.rewards > 0 then
		local names = {}
		for i, r in ipairs(q.rewards) do
			names[i] = UI.QualityText(r.name or ("item " .. r.itemID), r.quality)
		end
		local line = (q.choose and "Reward (choose one): " or "Reward: ") .. table.concat(names, ", ")
		body = body and (body .. "\n" .. line) or line
	end
	return body
end

-- The instance page's Quests section: your faction's quests, easiest first, with what
-- you've done checked off. Hover a quest for the game's own quest tooltip.
function AG:RenderQuestList(doc, instKey)
	local quests, other, open = self:QuestsFor(instKey)
	if #quests == 0 and other == 0 then return end
	doc:Heading(string.format("Quests  |cff888888(%d, %d not done)|r", #quests, open))
	for _, q in ipairs(quests) do
		local status = self:QuestStatus(q.questID)
		local note = status == "done" and "|cff20ff20Done|r"
			or status == "active" and "|cffffd100In your log|r"
			or (q.side and ("|cff888888" .. q.side .. "|r") or nil)
		doc:Row(QUEST_ICON[status or "open"], questLevel(q.level) .. (q.name or ("Quest " .. q.questID)),
			questBody(q), note, { questID = q.questID, alpha = status == "done" and 0.6 or 1 })
	end
	if other > 0 then
		local faction = self:PlayerFaction()
		local them = faction == "Horde" and "the Alliance" or faction == "Alliance" and "the Horde" or "the other faction"
		doc:Paragraph(string.format("%d more quest%s here for %s.", other, other == 1 and "" or "s", them),
			{ font = "GameFontHighlightSmall", color = { 0.6, 0.6, 0.6 } })
	end
end

-- Shown at the foot of every instance page.
AG.CREDITS = "Sources: levels, bosses, abilities, quests, and loot from Wowhead's WoW Forever "
	.. "database and dungeon guides (wowhead.com/forever). Guide text is written for this addon."

function AG:RenderInstanceOverview(instKey)
	local doc = self.instanceOverview.doc
	local inst = self:GetInstance(instKey)
	local guide = self.Guides[instKey] or {}
	doc:Begin("overview:" .. instKey)

	local fileID, kind = self:GetArt(instKey, "header")
	doc:Image(fileID, kind, HEADER_HEIGHT, inst.name)
	doc:Paragraph(levelLine(inst), { font = "GameFontHighlightSmall", color = { 0.75, 0.75, 0.75 } })
	doc:Paragraph(guide.intro, { font = "GameFontNormal", color = { 1, 0.82, 0 } })

	if guide.lore then
		doc:Heading("The story")
		doc:Paragraph(guide.lore)
	end
	if guide.route then
		doc:Heading("How to run it")
		doc:Paragraph(guide.route)
	end
	if guide.tips and #guide.tips > 0 then
		doc:Heading("Tips")
		doc:Bullets(guide.tips)
	end

	local bosses = self:GetBossList(instKey)
	if #bosses == 0 then
		doc:Heading("Bosses")
		doc:Paragraph("No bosses known yet. They'll be added once they're documented.",
			{ color = { 0.6, 0.6, 0.6 } })
	else
		doc:Heading("Bosses")
		for i, entry in ipairs(bosses) do
			local g = entry.guide or {}
			local name = string.format("|cffffd100%d.|r %s", i, entry.name)
			if g.optional then name = name .. "  |cff888888(optional)|r" end
			doc:Row(nil, name, g.overview, nil, {
				onClick = function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					AG.view.bossKey = entry.key
					AG:Refresh()
				end,
			})
		end
	end

	self:RenderQuestList(doc, instKey)

	if not (guide.lore or guide.route or guide.intro) then
		doc:Paragraph("No write-up for this instance yet. Its bosses and loot are still listed on the left.",
			{ color = { 0.6, 0.6, 0.6 } })
	end
	doc:Paragraph(AG.CREDITS, { font = "GameFontHighlightSmall", color = { 0.5, 0.5, 0.5 } })
	doc:Finish()
end
