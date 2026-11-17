-- The instance list: a grid of dungeon or raid cards, like the Adventure Guide's
-- Dungeons and Raids tabs. Suggested Content shows instances that fit your level.

local _, AG = ...
local UI = AG.UI

local COLUMNS = 3
local CARD_W, CARD_H, GAP = 268, 92, 10

-- How much the guide knows about an instance, for the card's status line.
function AG:GuideStatus(instKey)
	local guide = self.Guides[instKey]
	if guide and guide.bosses and #guide.bosses > 0 then
		local hasLoot = false
		for _, boss in ipairs(guide.bosses) do
			if boss.abilities and #boss.abilities > 0 then return "|cff20ff20Full guide|r" end
			if boss.loot and #boss.loot > 0 then hasLoot = true end
		end
		return hasLoot and "|cffffd100Bosses and loot|r" or "|cffffd100Boss list|r"
	end
	local learned = self.db.learned[instKey]
	if learned and next(learned.bosses) then return "|cff66ccffLearned from play|r" end
	return "|cff888888No guide yet|r"
end

local function levelColor(inst)
	local lvl = UnitLevel("player")
	if lvl < inst.minLevel - 2 then return "ff4040" end   -- too hard
	if lvl < inst.minLevel then return "ff9933" end
	if lvl <= inst.maxLevel then return "ffff00" end     -- right on level
	if lvl <= inst.maxLevel + 5 then return "40c040" end
	return "909090"                                     -- trivial
end

local function createCard(owner)
	local card = CreateFrame("Button", nil, owner)
	card:SetSize(CARD_W, CARD_H)
	UI.Backdrop(card, 0.85)

	card.glow = card:CreateTexture(nil, "BACKGROUND", nil, 1)
	card.glow:SetPoint("TOPLEFT", 4, -4)
	card.glow:SetPoint("BOTTOMRIGHT", -4, 4)
	card.glow:SetTexture("Interface\\Buttons\\WHITE8x8")

	card.icon = card:CreateTexture(nil, "ARTWORK")
	card.icon:SetSize(52, 52)
	card.icon:SetPoint("LEFT", 12, 0)
	card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	card.name = UI.Text(card, "GameFontNormalLarge")
	card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, 0)
	card.name:SetPoint("RIGHT", -10, 0)
	card.name:SetWordWrap(false)

	card.info = UI.Text(card, "GameFontHighlightSmall")
	card.info:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
	card.info:SetPoint("RIGHT", -10, 0)

	card.status = UI.Text(card, "GameFontHighlightSmall")
	card.status:SetPoint("TOPLEFT", card.info, "BOTTOMLEFT", 0, -4)

	card.badge = UI.Text(card, "GameFontNormalSmall", "RIGHT")
	card.badge:SetPoint("BOTTOMRIGHT", -10, 8)

	card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	card:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
		AG:ShowInstance(self.instKey)
	end)
	return card
end

function AG:CreateInstanceList(parent)
	local list = CreateFrame("Frame", nil, parent)
	list:SetAllPoints()
	list.empty = UI.Text(list, "GameFontDisableLarge", "CENTER")
	list.empty:SetPoint("CENTER")
	list.scroll, list.child = UI.CreateScroll(list)
	list.scroll:SetPoint("TOPLEFT", 8, -8)
	list.scroll:SetPoint("BOTTOMRIGHT", -28, 8)
	self.instanceList = list
end

local function instancesFor(tabKey)
	local out, lvl = {}, UnitLevel("player")
	for _, inst in ipairs(AG.Instances) do
		if tabKey == "dungeons" and not inst.isRaid then
			table.insert(out, inst)
		elseif tabKey == "raids" and inst.isRaid then
			table.insert(out, inst)
		elseif tabKey == "suggested" and lvl >= inst.minLevel - 2 and lvl <= inst.maxLevel + 1 then
			table.insert(out, inst)
		end
	end
	return out
end

local HEADERS = {
	suggested = function() return string.format("Suggested for level %d", UnitLevel("player")) end,
	dungeons = function() return "Dungeons" end,
	raids = function() return "Raids" end,
}

function AG:RenderInstanceList(tabKey)
	local list = self.instanceList
	local here = self:GetCurrentInstanceKey()
	self.frame.header:SetText(HEADERS[tabKey]())

	local items = instancesFor(tabKey)
	for i, inst in ipairs(items) do
		local card = UI.Acquire(list.child, "cards", i, createCard)
		local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", col * (CARD_W + GAP), -row * (CARD_H + GAP))
		card.instKey = inst.key

		card.icon:SetTexture(inst.isRaid and "Interface\\Icons\\INV_Misc_Head_Dragon_Black"
			or "Interface\\Icons\\INV_Misc_Map_01")
		card.name:SetText(inst.name)
		if inst.isRaid then
			card.info:SetText(string.format("%s  |  %d players", inst.zone, inst.players))
		else
			card.info:SetText(string.format("%s  |  |cff%sLevels %d-%d|r",
				inst.zone, levelColor(inst), inst.minLevel, inst.maxLevel))
		end
		card.status:SetText(self:GuideStatus(inst.key))

		local badges = {}
		if inst.key == here then table.insert(badges, "|cff20ff20You are here|r") end
		if inst.isNew then table.insert(badges, "|cffffd100NEW|r") end
		card.badge:SetText(table.concat(badges, "  "))

		-- Tint: new content warm gold, classic content cool slate.
		if inst.isNew then
			card.glow:SetGradient("VERTICAL", CreateColor(0.10, 0.07, 0.02, 0.9), CreateColor(0.30, 0.22, 0.06, 0.9))
		else
			card.glow:SetGradient("VERTICAL", CreateColor(0.04, 0.05, 0.08, 0.9), CreateColor(0.12, 0.14, 0.20, 0.9))
		end
	end
	UI.HideFrom(list.child, "cards", #items + 1)

	local rows = math.ceil(#items / COLUMNS)
	list.child:SetHeight(math.max(1, rows * (CARD_H + GAP)))
	list.empty:SetText(#items == 0 and "Nothing here for your level yet." or "")
end
