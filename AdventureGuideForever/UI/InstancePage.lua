-- An instance's page: header with a back button, the boss list on the left, and the
-- selected boss's page on the right. Bosses learned from play join the list too.

local _, AG = ...
local UI = AG.UI

local LIST_W = 230

-- Guide bosses in order, then any bosses learned from play that the guide lacks.
function AG:GetBossList(instKey)
	local out, seen = {}, {}
	local guide = self.Guides[instKey]
	local learned = self.db.learned[instKey]
	local learnedBosses = learned and learned.bosses or {}
	for _, boss in ipairs(guide and guide.bosses or {}) do
		table.insert(out, { key = boss.key, name = boss.name, guide = boss, learned = learnedBosses[boss.key] })
		seen[boss.key] = true
	end
	local extras = {}
	for key, rec in pairs(learnedBosses) do
		if not seen[key] then
			table.insert(extras, { key = key, name = rec.name or key, learned = rec, isLearnedOnly = true })
		end
	end
	table.sort(extras, function(a, b) return a.name < b.name end)
	for _, e in ipairs(extras) do table.insert(out, e) end
	return out
end

local function createBossButton(owner)
	local b = CreateFrame("Button", nil, owner)
	b:SetSize(LIST_W - 8, 34)
	UI.Backdrop(b, 0.7)
	b.label = UI.Text(b, "GameFontNormal")
	b.label:SetPoint("LEFT", 10, 0)
	b.label:SetPoint("RIGHT", -8, 0)
	b.label:SetWordWrap(false)
	b.selected = b:CreateTexture(nil, "BACKGROUND", nil, 2)
	b.selected:SetPoint("TOPLEFT", 4, -4)
	b.selected:SetPoint("BOTTOMRIGHT", -4, 4)
	b.selected:SetColorTexture(0.9, 0.7, 0.2, 0.25)
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	b:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		AG.view.bossKey = self.bossKey
		AG:Refresh()
	end)
	return b
end

function AG:CreateInstancePage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()
	page:Hide()

	page.back = UI.CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	page.back:SetSize(90, 22)
	page.back:SetPoint("TOPLEFT", 8, -8)
	page.back:SetText("< Back")
	page.back:SetScript("OnClick", function()
		AG.view.instKey, AG.view.bossKey = nil, nil
		AG:Refresh()
	end)

	page.subtitle = UI.Text(page, "GameFontHighlightSmall")
	page.subtitle:SetPoint("LEFT", page.back, "RIGHT", 12, 0)

	-- Overview and boss list on the left.
	local listBox = CreateFrame("Frame", nil, page)
	UI.Backdrop(listBox, 0.6)
	listBox:SetPoint("TOPLEFT", page.back, "BOTTOMLEFT", 0, -8)
	listBox:SetPoint("BOTTOMLEFT", 8, 8)
	listBox:SetWidth(LIST_W)
	page.listScroll, page.listChild = UI.CreateScroll(listBox)
	page.listScroll:SetPoint("TOPLEFT", 4, -4)
	page.listScroll:SetPoint("BOTTOMRIGHT", -4, 4)

	-- Boss page on the right.
	local bossBox = CreateFrame("Frame", nil, page)
	UI.Backdrop(bossBox, 0.6)
	bossBox:SetPoint("TOPLEFT", listBox, "TOPRIGHT", 8, 0)
	bossBox:SetPoint("BOTTOMRIGHT", -8, 8)
	page.bossBox = bossBox

	self.instancePage = page
	self:CreateBossPage(bossBox)
	self:CreateInstanceOverview(bossBox)
end

local OVERVIEW = "__overview" -- list entry key for the instance overview

function AG:RenderInstancePage(instKey, bossKey)
	local page = self.instancePage
	local inst = self:GetInstance(instKey)
	self.frame.header:SetText(inst.name .. (inst.isNew and "  |cffffd100NEW|r" or ""))

	if inst.isRaid then
		page.subtitle:SetText(string.format("%s  |  %d players  |  Level 60", inst.zone, inst.players))
	else
		page.subtitle:SetText(string.format("%s  |  Levels %d-%d  |  5 players", inst.zone, inst.minLevel, inst.maxLevel))
	end

	-- The list: "Overview" first (selected by default), then the bosses.
	local bosses = self:GetBossList(instKey)
	local entries = { { key = OVERVIEW, label = "|cffffd100Overview|r" } }
	for i, entry in ipairs(bosses) do
		local label = string.format("|cffffd100%d.|r %s", i, entry.name)
		if entry.guide and entry.guide.optional then label = label .. " |cff888888(optional)|r" end
		if entry.isLearnedOnly then label = label .. " |cff66ccff(learned)|r" end
		table.insert(entries, { key = entry.key, label = label, boss = entry })
	end

	local selectedKey = bossKey or OVERVIEW
	local selected
	for i, entry in ipairs(entries) do
		local b = UI.Acquire(page.listChild, "bossButtons", i, createBossButton)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", 0, -(i - 1) * 36)
		b.bossKey = entry.key ~= OVERVIEW and entry.key or nil
		b.label:SetText(entry.label)
		local isSel = entry.key == selectedKey
		b.selected:SetShown(isSel)
		if isSel then selected = entry end
	end
	UI.HideFrom(page.listChild, "bossButtons", #entries + 1)
	page.listChild:SetHeight(#entries * 36)

	local showOverview = not selected or selected.key == OVERVIEW
	self.instanceOverview:SetShown(showOverview)
	self.bossPage:SetShown(not showOverview)
	if showOverview then
		self:RenderInstanceOverview(instKey)
	else
		self:RenderBossPage(instKey, selected.boss)
	end
end
