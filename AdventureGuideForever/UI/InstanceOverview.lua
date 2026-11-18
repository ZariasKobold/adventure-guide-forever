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

-- Shown at the foot of every instance page.
AG.CREDITS = "Sources: levels, bosses, abilities, quests, and loot from Wowhead's WoW Forever "
	.. "database and dungeon guides (wowhead.com/forever), plus what players' learning mode "
	.. "found. Guide text is written for this addon."

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
		doc:Paragraph("No bosses known yet. Run this instance with learning mode on, and bosses "
			.. "will appear here as you kill them.", { color = { 0.6, 0.6, 0.6 } })
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

	if not (guide.lore or guide.route or guide.intro) then
		doc:Paragraph("No write-up for this instance yet. Its bosses and loot are still listed on the left.",
			{ color = { 0.6, 0.6, 0.6 } })
	end
	doc:Paragraph(AG.CREDITS, { font = "GameFontHighlightSmall", color = { 0.5, 0.5, 0.5 } })
	doc:Finish()
end
