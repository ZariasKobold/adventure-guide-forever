-- A boss's page, laid out like a bestiary entry. Four sections:
--   Overview   the 3D model beside who the boss is, its lore, how to beat it (by role),
--              key abilities, and notable loot
--   Abilities  every ability, with role alerts and the spell's own tooltip text
--   Loot       the loot table with drop chances
--   Model      the model, full size

local _, AG = ...
local UI = AG.UI

local SECTIONS = { "Overview", "Abilities", "Loot", "Model" }
local MODEL_COLUMN = 220          -- width of the model panel beside the Overview text
local KEY_ABILITIES = 4           -- abilities shown on the Overview
local NOTABLE_LOOT = 3            -- items shown on the Overview

local QUALITY_COLOR = { [0] = "9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000" }
local IMPORTANT_ALERTS = { deadly = true, important = true }

------------------------------------------------------------------------
-- Abilities
------------------------------------------------------------------------

local function buildAbilities(entry)
	local rows = {}
	for _, ab in ipairs(entry.guide and entry.guide.abilities or {}) do
		table.insert(rows, { name = ab.name, text = ab.text, alerts = ab.alerts, spellID = ab.spellID })
	end
	return rows
end

-- The abilities worth calling out first: written-up ones, deadly/important ones first.
local function keyAbilities(rows)
	local picked = {}
	for _, ab in ipairs(rows) do
		for _, alert in ipairs(ab.alerts or {}) do
			if IMPORTANT_ALERTS[alert] then table.insert(picked, ab); break end
		end
	end
	for _, ab in ipairs(rows) do
		if #picked >= KEY_ABILITIES then break end
		if ab.text and not tContains(picked, ab) then table.insert(picked, ab) end
	end
	while #picked > KEY_ABILITIES do table.remove(picked) end
	return picked
end

local function dropText(chance)
	if not chance then return nil end
	-- Whole percents from 10% up; one decimal below that, where it matters.
	return string.format(chance >= 10 and "|cffcccccc%.0f%% drop|r" or "|cffcccccc%.1f%% drop|r", chance)
end

------------------------------------------------------------------------
-- Frame
------------------------------------------------------------------------

function AG:CreateBossPage(parent)
	local bp = CreateFrame("Frame", nil, parent)
	bp:SetAllPoints()

	bp.title = UI.Text(bp, "GameFontNormalHuge")
	bp.title:SetPoint("TOPLEFT", 14, -12)
	bp.title:SetPoint("RIGHT", -14, 0)
	bp.title:SetWordWrap(false)

	bp.buttons = {}
	for i, label in ipairs(SECTIONS) do
		local b = UI.CreateFrame("Button", nil, bp, "UIPanelButtonTemplate")
		b:SetSize(96, 22)
		if i == 1 then b:SetPoint("TOPLEFT", bp.title, "BOTTOMLEFT", -2, -8)
		else b:SetPoint("LEFT", bp.buttons[i - 1], "RIGHT", 4, 0) end
		b:SetText(label)
		b:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			AG.view.section = i
			AG:Refresh()
		end)
		bp.buttons[i] = b
	end

	bp.doc = UI.CreateDocument(bp)

	-- Model panel: beside the text on the Overview, full size on the Model tab.
	-- Drag to turn, scroll to zoom.
	local box = CreateFrame("Frame", nil, bp, "BackdropTemplate")
	box:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
	})
	box:SetBackdropColor(0, 0, 0, 0.35)
	box:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
	local model = CreateFrame("PlayerModel", nil, box)
	model:SetPoint("TOPLEFT", 1, -1)
	model:SetPoint("BOTTOMRIGHT", -1, 1)
	model.facing, model.zoom = 0, 1
	model:EnableMouse(true)
	model:EnableMouseWheel(true)
	-- The per-frame handler only exists while dragging, so an idle model costs nothing.
	local function turnWithCursor(self)
		local x = GetCursorPosition()
		self.facing = self.facing + (x - self.dragX) / 80
		self.dragX = x
		self:SetFacing(self.facing)
	end
	model:SetScript("OnMouseDown", function(self)
		self.dragX = GetCursorPosition()
		self:SetScript("OnUpdate", turnWithCursor)
	end)
	model:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
		self.dragX = nil
	end)
	model:SetScript("OnMouseWheel", function(self, delta)
		self.zoom = math.min(2, math.max(0.4, self.zoom - delta * 0.1))
		pcall(self.SetCamDistanceScale, self, self.zoom)
	end)
	model.hint = UI.Text(box, "GameFontDisable", "CENTER")
	model.hint:SetPoint("LEFT", 10, 0)
	model.hint:SetPoint("RIGHT", -10, 0)
	bp.modelBox, bp.model = box, model

	self.bossPage = bp
end

-- Arranges the text and model for a section.
local function placeContent(bp, section)
	local top = bp.buttons[1]
	local doc, box = bp.doc, bp.modelBox
	doc.scroll:ClearAllPoints()
	box:ClearAllPoints()
	if section == 1 then
		-- Top edge level with the text: the title's bottom, plus the section buttons' row.
		box:SetPoint("TOPRIGHT", bp.title, "BOTTOMRIGHT", 4, -(8 + top:GetHeight() + 10))
		box:SetPoint("BOTTOMRIGHT", -10, 10)
		box:SetWidth(MODEL_COLUMN)
		doc.scroll:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 2, -10)
		doc.scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMLEFT", -26, 0)
	elseif section == 4 then
		box:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 2, -10)
		box:SetPoint("BOTTOMRIGHT", -10, 10)
	else
		doc.scroll:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 2, -10)
		doc.scroll:SetPoint("BOTTOMRIGHT", -28, 10)
	end
	doc:SetShown(section ~= 4)
	box:SetShown(section == 1 or section == 4)
end

------------------------------------------------------------------------
-- Sections
------------------------------------------------------------------------

local function lootRow(doc, item, note, dim)
	local name, link, quality, icon = UI.ItemInfo(item.itemID, UI.QueueRefresh)
	-- Until the client caches the item, show the guide's name and quality.
	name = name or item.name or ("Item " .. tostring(item.itemID))
	quality = quality or item.quality or 1
	local title = dim and ("|cff808080" .. name .. "|r")
		or string.format("|cff%s%s|r", QUALITY_COLOR[quality] or "ffffff", name)
	doc:Row(icon or UI.UNKNOWN_ICON, title, item.slot, note,
		{ itemID = item.itemID, link = link, alpha = dim and 0.6 or 1, star = true })
end

local function renderOverview(doc, entry)
	local g = entry.guide or {}
	doc:Paragraph(g.overview, { font = "GameFontNormal", color = { 1, 0.82, 0 } })

	if g.lore then
		doc:Heading("Lore")
		doc:Paragraph(g.lore)
	end

	local s = g.strategy
	if s then
		doc:Heading("How to beat it")
		doc:Paragraph(s.summary)
		doc:RoleTip("tank", s.tank)
		doc:RoleTip("healer", s.healer)
		doc:RoleTip("dps", s.dps)
	end

	local rows = buildAbilities(entry)
	local picks = keyAbilities(rows)
	if #picks > 0 then
		doc:Heading("Key abilities")
		for _, ab in ipairs(picks) do
			local _, icon, desc = UI.SpellInfo(ab.spellID, UI.QueueRefresh)
			doc:Row(icon or UI.UNKNOWN_ICON, ab.name, ab.text or desc, UI.FormatAlerts(ab.alerts), { spellID = ab.spellID })
		end
	end

	local loot = {}
	for _, item in ipairs(g.loot or {}) do table.insert(loot, item) end
	table.sort(loot, function(a, b)
		if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) > (b.quality or 0) end
		return (a.dropChance or 0) > (b.dropChance or 0)
	end)
	if #loot > 0 then
		doc:Heading("Notable loot")
		for i = 1, math.min(NOTABLE_LOOT, #loot) do lootRow(doc, loot[i], dropText(loot[i].dropChance)) end
	end

	if not (g.overview or g.lore or s) then
		doc:Paragraph("No write-up for this boss yet. Its abilities and loot are on the other tabs.",
			{ color = { 0.6, 0.6, 0.6 } })
	end
end

local function renderAbilities(doc, entry)
	local rows = buildAbilities(entry)
	if #rows > 0 then doc:Heading("Abilities") end
	for _, ab in ipairs(rows) do
		local _, icon, desc = UI.SpellInfo(ab.spellID, UI.QueueRefresh)
		-- Hand-written notes first; otherwise the spell's own description from the game.
		doc:Row(icon or UI.UNKNOWN_ICON, ab.name, ab.text or desc, UI.FormatAlerts(ab.alerts), { spellID = ab.spellID })
	end
	if #rows == 0 then
		doc:Paragraph("No abilities written up for this boss yet. They'll be added once they're "
			.. "documented.", { color = { 0.6, 0.6, 0.6 } })
	end
end

local function renderLoot(doc, entry)
	local loot = entry.guide and entry.guide.loot or {}
	if #loot == 0 then
		doc:Paragraph("No loot known for this boss yet.", { color = { 0.6, 0.6, 0.6 } })
		return
	end
	doc:Heading("Loot")
	for _, item in ipairs(loot) do lootRow(doc, item, dropText(item.dropChance)) end
end

local function showModel(bp, entry)
	local model = bp.model
	local g = entry.guide or {}
	local displayID, npcID = g.displayID, g.npcID
	local key = tostring(displayID) .. ":" .. tostring(npcID)
	if model.shownKey == key then return end -- already showing; keep the user's rotation
	model.shownKey = key
	model:ClearModel()
	model.facing, model.zoom = 0, 1
	model.hint:SetText("")
	if displayID then
		pcall(model.SetDisplayInfo, model, displayID)
	elseif npcID then
		pcall(model.SetCreature, model, npcID)
	end
	model:SetFacing(0)
	pcall(model.SetCamDistanceScale, model, 1)
	-- If nothing loaded, say so.
	C_Timer.After(1, function()
		if model.shownKey ~= key then return end -- switched bosses meanwhile
		local ok, fileID = pcall(model.GetModelFileID, model)
		if not (ok and fileID) then
			model.hint:SetText("No model for this boss yet.")
		end
	end)
end

local RENDER = { renderOverview, renderAbilities, renderLoot }

function AG:RenderBossPage(instKey, entry)
	local bp = self.bossPage
	local section = self.view.section or 1

	bp.title:SetText(entry.name)
	for i, b in ipairs(bp.buttons) do
		if i == section then b:LockHighlight() else b:UnlockHighlight() end
	end
	placeContent(bp, section)

	if section == 1 or section == 4 then showModel(bp, entry) end
	if section ~= 4 then
		bp.doc:Begin(instKey .. ":" .. entry.key .. ":" .. section)
		RENDER[section](bp.doc, entry)
		bp.doc:Finish()
	end
end

-- The model reloads after the window was hidden (models clear while hidden).
function AG:ResetBossModel()
	if self.bossPage then self.bossPage.model.shownKey = nil end
end
