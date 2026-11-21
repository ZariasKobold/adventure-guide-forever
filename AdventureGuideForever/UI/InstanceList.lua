-- The instance list: a grid of picture cards, like the retail Adventure Guide's Dungeons
-- and Raids tabs. Cards use Blizzard's journal art (Data\Art.lua); instances without art
-- get a drawn card. Suggested Content shows instances that fit your level.

local _, AG = ...
local UI = AG.UI

local COLUMNS = 4
local CARD_W, CARD_H, GAP = 196, 108, 10

-- How much the guide knows about an instance, for the card's tooltip.
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
	return "|cff888888No guide yet|r"
end

-- Level range color relative to the player, like quest difficulty colors.
function AG:LevelColor(inst)
	local lvl = UnitLevel("player")
	if lvl < inst.minLevel - 2 then return "ff4040" end   -- too hard
	if lvl < inst.minLevel then return "ff9933" end
	if lvl <= inst.maxLevel then return "ffff00" end     -- right on level
	if lvl <= inst.maxLevel + 5 then return "40c040" end
	return "909090"                                     -- trivial
end

local function showTooltip(card)
	local inst = AG:GetInstance(card.instKey)
	GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
	GameTooltip:AddLine(inst.name)
	GameTooltip:AddLine(inst.zone, 1, 1, 1)
	if inst.isRaid then
		GameTooltip:AddLine(string.format("Raid, %d players", inst.players), 1, 1, 1)
	else
		GameTooltip:AddLine(string.format("|cff%sLevels %d-%d|r", AG:LevelColor(inst), inst.minLevel, inst.maxLevel))
	end
	GameTooltip:AddLine(AG:GuideStatus(inst.key))
	local wishes = AG:WishesIn(inst.key)
	if #wishes > 0 then
		GameTooltip:AddLine(string.format("%s %d wishlist item%s here", AG.UI.STAR, #wishes, #wishes == 1 and "" or "s"), 1, 0.82, 0)
	end
	local guide = AG.Guides[inst.key]
	if guide and guide.intro then GameTooltip:AddLine(guide.intro, 0.85, 0.8, 0.7, true) end
	GameTooltip:Show()
end

local function createCard(owner)
	local card = CreateFrame("Button", nil, owner)
	card:SetSize(CARD_W, CARD_H)

	-- Picture, or a drawn background for instances without art.
	card.art = card:CreateTexture(nil, "BACKGROUND")
	card.art:SetAllPoints()
	card.fallback = card:CreateTexture(nil, "BACKGROUND", nil, 1)
	card.fallback:SetAllPoints()
	card.fallback:SetTexture("Interface\\Buttons\\WHITE8x8")
	-- Centered emblem in a thin gold frame, so every drawn card looks alike.
	card.emblemFrame = card:CreateTexture(nil, "BORDER", nil, 0)
	card.emblemFrame:SetSize(50, 50)
	card.emblemFrame:SetPoint("CENTER", 0, -4)
	card.emblemFrame:SetColorTexture(0.55, 0.45, 0.25, 1)
	card.emblem = card:CreateTexture(nil, "BORDER", nil, 1)
	card.emblem:SetSize(48, 48)
	card.emblem:SetPoint("CENTER", card.emblemFrame)
	card.emblem:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Shading at top and bottom keeps text readable over any picture.
	card.topShade = card:CreateTexture(nil, "ARTWORK")
	card.topShade:SetPoint("TOPLEFT")
	card.topShade:SetPoint("TOPRIGHT")
	card.topShade:SetHeight(34)
	card.topShade:SetTexture("Interface\\Buttons\\WHITE8x8")
	card.topShade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.75))
	card.bottomShade = card:CreateTexture(nil, "ARTWORK")
	card.bottomShade:SetPoint("BOTTOMLEFT")
	card.bottomShade:SetPoint("BOTTOMRIGHT")
	card.bottomShade:SetHeight(26)
	card.bottomShade:SetTexture("Interface\\Buttons\\WHITE8x8")
	card.bottomShade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.8), CreateColor(0, 0, 0, 0))

	-- Thin gold frame.
	card.frame = CreateFrame("Frame", nil, card, "BackdropTemplate")
	card.frame:SetAllPoints()
	card.frame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	card.frame:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)

	card.name = card.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	card.name:SetPoint("TOPLEFT", 6, -6)
	card.name:SetPoint("TOPRIGHT", -6, -6)
	card.name:SetJustifyH("CENTER")
	card.name:SetShadowOffset(1, -1)
	card.name:SetWordWrap(true)
	card.name:SetMaxLines(2)

	card.info = card.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	card.info:SetPoint("BOTTOMLEFT", 6, 5)
	card.badge = card.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	card.badge:SetPoint("BOTTOMRIGHT", -6, 5)

	card:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
	card:GetHighlightTexture():SetVertexColor(1, 0.85, 0.5, 0.12)
	card:SetScript("OnEnter", showTooltip)
	card:SetScript("OnLeave", GameTooltip_Hide)
	card:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		AG:ShowInstance(self.instKey)
	end)
	return card
end

local function paintCard(card, inst)
	local fileID, kind = AG:GetArt(inst.key, "card")
	local hasArt = fileID ~= nil
	local art = AG.Art[inst.key]
	local icon = not hasArt and art and art.icon
	card.art:SetShown(hasArt or icon ~= nil)
	card.fallback:SetShown(not hasArt)
	if hasArt then
		card.art:SetVertexColor(1, 1, 1)
		UI.SetArt(card.art, fileID, kind, CARD_W, CARD_H)
	elseif icon then
		-- Only a small icon: stretch it, dimmed, behind a translucent wash as the background,
		-- and show it sharp in the center.
		card.art:SetVertexColor(0.6, 0.6, 0.6)
		UI.SetArt(card.art, icon, "icon", CARD_W, CARD_H)
		card.fallback:SetGradient("VERTICAL", CreateColor(0.12, 0.08, 0.02, 0.85), CreateColor(0.36, 0.26, 0.08, 0.45))
	elseif inst.isNew then
		-- New Forever content: warm gold, with the instance's finder icon if it has one.
		card.fallback:SetGradient("VERTICAL", CreateColor(0.12, 0.08, 0.02, 1), CreateColor(0.36, 0.26, 0.08, 1))
	else
		card.fallback:SetGradient("VERTICAL", CreateColor(0.04, 0.05, 0.08, 1), CreateColor(0.14, 0.16, 0.22, 1))
	end
	local emblem = not hasArt and (icon
		or (inst.isRaid and "Interface\\Icons\\INV_Misc_Head_Dragon_Black" or "Interface\\Icons\\INV_Misc_Map_01"))
	card.emblem:SetShown(emblem ~= false)
	card.emblemFrame:SetShown(emblem ~= false)
	if emblem then card.emblem:SetTexture(emblem) end
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
	local here = self:DetectInstance()
	self.frame.header:SetText(HEADERS[tabKey]())

	local items = instancesFor(tabKey)
	for i, inst in ipairs(items) do
		local card = UI.Acquire(list.child, "cards", i, createCard)
		local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", col * (CARD_W + GAP), -row * (CARD_H + GAP))
		card.instKey = inst.key
		paintCard(card, inst)
		card.name:SetText(inst.name)

		if inst.isRaid then
			card.info:SetText(string.format("%d players", inst.players))
		else
			card.info:SetText(string.format("|cff%s%d-%d|r", self:LevelColor(inst), inst.minLevel, inst.maxLevel))
		end
		local badges = {}
		if inst.key == here then table.insert(badges, "|cff20ff20You are here|r") end
		if inst.isNew then table.insert(badges, "|cffffd100NEW|r") end
		local wishes = #self:WishesIn(inst.key)
		if wishes > 0 then table.insert(badges, UI.STAR .. " " .. wishes) end
		card.badge:SetText(table.concat(badges, "  "))
	end
	UI.HideFrom(list.child, "cards", #items + 1)

	local rows = math.ceil(#items / COLUMNS)
	list.child:SetHeight(math.max(1, rows * (CARD_H + GAP)))
	list.empty:SetText(#items == 0 and "Nothing here for your level yet." or "")
end
