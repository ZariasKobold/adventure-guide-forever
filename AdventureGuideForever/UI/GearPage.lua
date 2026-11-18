-- The Gear tab: every boss drop and quest reward the guide knows, filtered by slot, armor or
-- weapon type, stat, quality, and required level, and (by default) only what your class can
-- use. Filters live in AdventureGuideForeverDB.gear; levels left blank follow your level.

local _, AG = ...
local UI = AG.UI

local MAX_ROWS = 100
local BAR_HEIGHT = 58

local function filters()
	return AG.db.gear
end

-- Levels to show: what you typed, or your level and the ten below it.
local function levelRange()
	local _, level = AG:PlayerClassAndLevel()
	level = level or 60
	local f = filters()
	return f.minLevel or math.max(1, level - 10), f.maxLevel or level
end

local function optionList(list, labelOf)
	return function()
		local out = { { value = nil, text = "Any" } }
		for _, entry in ipairs(list) do
			local value, text = labelOf(entry)
			out[#out + 1] = { value = value, text = text }
		end
		return out
	end
end

local function refreshResults()
	if AG.frame and AG.frame:IsShown() then AG:Refresh() end
end

local function setFilter(key)
	return function(value)
		filters()[key] = value
		refreshResults()
	end
end

local function levelBox(bar, key, anchor, x)
	local box = UI.CreateFrame("EditBox", nil, bar, "InputBoxTemplate")
	box:SetSize(32, 20)
	box:SetPoint("LEFT", anchor, "RIGHT", x, 0)
	box:SetAutoFocus(false)
	box:SetNumeric(true)
	box:SetMaxLetters(2)
	local function commit(self)
		local n = tonumber(self:GetText())
		filters()[key] = n and math.max(1, math.min(60, n)) or nil
		self:ClearFocus()
		refreshResults()
	end
	box:SetScript("OnEnterPressed", commit)
	box:SetScript("OnEditFocusLost", commit)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	return box
end

function AG:CreateGearBar(docPage)
	local bar = CreateFrame("Frame", nil, docPage)
	bar:SetPoint("TOPLEFT", 12, -8)
	bar:SetPoint("TOPRIGHT", -12, -8)
	bar:SetHeight(BAR_HEIGHT)
	bar:Hide()

	bar.slot = UI.Dropdown(bar, 150, "Slot", optionList(AG.GEAR_SLOTS, function(s) return s.key, s.label end),
		function() return filters().slot end, setFilter("slot"))
	bar.slot:SetPoint("TOPLEFT", 0, 0)
	bar.type = UI.Dropdown(bar, 160, "Type", optionList(AG.GEAR_TYPES, function(t) return t.key, t.label end),
		function() return filters().type end, setFilter("type"))
	bar.type:SetPoint("LEFT", bar.slot, "RIGHT", 6, 0)
	bar.stat = UI.Dropdown(bar, 190, "Stat", optionList(AG.GEAR_STATS, function(k) return k, AG.STAT_LABELS[k] or k end),
		function() return filters().stat end, setFilter("stat"))
	bar.stat:SetPoint("LEFT", bar.type, "RIGHT", 6, 0)
	local qualities = {}
	for q = 1, 5 do qualities[#qualities + 1] = q end
	bar.quality = UI.Dropdown(bar, 170, "Quality", optionList(qualities, function(q)
		return q, UI.QualityText(AG.QUALITY_NAMES[q], q) .. (q < 5 and " and up" or "")
	end), function() return filters().minQuality end, setFilter("minQuality"))
	bar.quality:SetPoint("LEFT", bar.stat, "RIGHT", 6, 0)

	bar.levelLabel = UI.Text(bar, "GameFontNormal")
	bar.levelLabel:SetPoint("TOPLEFT", bar.slot, "BOTTOMLEFT", 2, -12)
	bar.levelLabel:SetText("Required level")
	bar.minLevel = levelBox(bar, "minLevel", bar.levelLabel, 12)
	bar.toLabel = UI.Text(bar, "GameFontHighlight")
	bar.toLabel:SetPoint("LEFT", bar.minLevel, "RIGHT", 4, 0)
	bar.toLabel:SetText("to")
	bar.maxLevel = levelBox(bar, "maxLevel", bar.toLabel, 10)

	bar.usable = UI.CheckBox(bar, "Only what my class can use",
		function() return filters().usable end,
		function(v) filters().usable = v; refreshResults() end)
	bar.usable:SetPoint("LEFT", bar.maxLevel, "RIGHT", 18, 0)

	bar.reset = UI.CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
	bar.reset:SetSize(110, 22)
	bar.reset:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -30)
	bar.reset:SetText("Clear filters")
	bar.reset:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local g = filters()
		g.slot, g.type, g.stat, g.minLevel, g.maxLevel = nil, nil, nil, nil, nil
		g.minQuality, g.usable = 2, true
		refreshResults()
	end)

	bar.Sync = function(self)
		for _, key in ipairs({ "slot", "type", "stat", "quality", "usable" }) do self[key]:Sync() end
		local lo, hi = levelRange()
		if not self.minLevel:HasFocus() then self.minLevel:SetText(tostring(lo)) end
		if not self.maxLevel:HasFocus() then self.maxLevel:SetText(tostring(hi)) end
	end
	docPage.gearBar = bar
end

-- Document pages with a bar of controls above them: render function -> bar.
local BARS = {
	RenderGear = { field = "gearBar", create = "CreateGearBar" },
	RenderPlan = { field = "planBar", create = "CreatePlanBar" },
}

-- Show the bar that belongs to this document page (if any), and move the page below it.
function AG:ShowDocBar(render)
	local page = self.docPage
	local want = BARS[render]
	if want and not page[want.field] then self[want.create](self, page) end
	for _, bar in pairs(BARS) do
		if page[bar.field] then page[bar.field]:SetShown(bar == want) end
	end
	UI.CloseMenu()
	local scroll = page.doc.scroll
	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", 14, want and -(BAR_HEIGHT + 16) or -12)
	scroll:SetPoint("BOTTOMRIGHT", -30, 10)
	if want then page[want.field]:Sync() end
end
AG.DOC_BAR_HEIGHT = BAR_HEIGHT

local function sourceLine(itemID)
	local s = AG:ItemSources(itemID)[1]
	if not s then return nil, nil end
	local inst = AG:GetInstance(s.instKey)
	local where = string.format("%s, %s", s.bossName, inst and inst.name or s.instKey)
	if s.dropChance then where = where .. string.format(" (%.0f%%)", s.dropChance) end
	return "|cff888888From:|r " .. where, s
end

function AG:RenderGear(doc)
	self.frame.header:SetText("Gear")
	local classID, level = self:PlayerClassAndLevel()
	local f = filters()
	local lo, hi = levelRange()
	local results = self:FilterGear({
		slot = f.slot, type = f.type, stat = f.stat, minQuality = f.minQuality,
		minLevel = lo, maxLevel = hi, usable = f.usable, classID = classID, level = level,
	})

	local summary = string.format("%d item%s from dungeon bosses and quests", #results, #results == 1 and "" or "s")
	if f.stat then summary = summary .. ", most " .. (self.STAT_LABELS[f.stat] or f.stat) .. " first" end
	doc:Paragraph(summary .. ".", { font = "GameFontHighlightSmall", color = { 0.7, 0.7, 0.7 } })
	if #results == 0 then
		doc:Paragraph("Nothing matches. Try a wider level range, or clear a filter.", { color = { 0.6, 0.6, 0.6 } })
		return
	end

	for i = 1, math.min(MAX_ROWS, #results) do
		local g = results[i]
		local item = g.item
		local kind = self:GearType(item)
		local what = (kind and (kind.label .. " ") or "") .. (self:GearSlotLabel(item) or "")
		local levels = string.format("item level %d", item.itemLevel or 0)
		local stats = self:StatLine(item)
		local from, source = sourceLine(g.itemID)
		local body = what .. "  |cff888888" .. levels .. "|r"
		if stats ~= "" then body = body .. "\n|cff20ff20" .. stats .. "|r" end
		if from then body = body .. "\n" .. from end
		local req = item.reqLevel or 1
		local note = string.format("|cff%sLevel %d|r", (level and req > level) and "ff4040" or "ffd100", req)
		doc:Row(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(g.itemID) or UI.UNKNOWN_ICON,
			UI.QualityText(g.name, g.quality), body, note, {
				itemID = g.itemID, star = true,
				onClick = source and function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					AG:ShowInstance(source.instKey, source.bossKey)
				end or nil,
			})
	end
	if #results > MAX_ROWS then
		doc:Paragraph(string.format("...and %d more. Narrow it down with the filters above.", #results - MAX_ROWS),
			{ font = "GameFontHighlightSmall", color = { 0.6, 0.6, 0.6 } })
	end
end
