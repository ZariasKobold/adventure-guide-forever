-- A boss's page, with the Adventure Guide's four sections: Overview, Abilities, Loot,
-- and Model. Guide data and learned data are merged here.

local _, AG = ...
local UI = AG.UI

local SECTIONS = { "Overview", "Abilities", "Loot", "Model" }
local ICON = 30

------------------------------------------------------------------------
-- Rows: icon, title, body text, and a note on the right. Height fits the text.
------------------------------------------------------------------------

local function createRow(owner)
	local row = CreateFrame("Button", nil, owner)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON, ICON)
	row.icon:SetPoint("TOPLEFT", 4, -4)
	row.title = UI.Text(row, "GameFontNormal")
	row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
	row.note = UI.Text(row, "GameFontHighlightSmall", "RIGHT")
	row.note:SetPoint("TOPRIGHT", -6, -2)
	row.title:SetPoint("RIGHT", row.note, "LEFT", -6, 0)
	row.body = UI.Text(row, "GameFontHighlightSmall")
	row.body:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
	row.body:SetPoint("RIGHT", -6, 0)
	row.body:SetTextColor(0.85, 0.82, 0.75)
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

	row:SetScript("OnEnter", function(self)
		if not self.itemID and not self.spellID then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.itemID then GameTooltip:SetItemByID(self.itemID) else GameTooltip:SetSpellByID(self.spellID) end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	-- Shift-click links the item in chat, Ctrl-click previews it, like Blizzard's loot lists.
	row:SetScript("OnClick", function(self)
		if self.link and HandleModifiedItemClick then HandleModifiedItemClick(self.link) end
	end)
	return row
end

-- Fills a row and returns its height.
local function setRow(row, width, icon, title, body, note)
	row:SetWidth(width)
	row.icon:SetTexture(icon)
	row.icon:SetShown(icon ~= nil)
	row.icon:SetWidth(icon and ICON or 1) -- no icon: text starts at the left edge
	row.title:SetText(title or "")
	row.body:SetText(body or "")
	row.note:SetText(note or "")
	local h = row.title:GetStringHeight() + 3 + (body and body ~= "" and row.body:GetStringHeight() or 0) + 10
	if icon then h = math.max(h, ICON + 10) end
	row:SetHeight(h)
	return h
end

local function createHeading(owner)
	return UI.Text(owner, "GameFontNormalLarge")
end

------------------------------------------------------------------------
-- Redraw when item data arrives from the server (debounced)
------------------------------------------------------------------------

local refreshQueued
local function queueRefresh()
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0.2, function()
		refreshQueued = false
		if AG.frame and AG.frame:IsShown() then AG:Refresh() end
	end)
end

------------------------------------------------------------------------
-- Merging guide data with learned data
------------------------------------------------------------------------

-- After this many recorded kills, a documented item that never dropped is probably
-- not in Forever's loot table anymore.
local LIKELY_REMOVED_AFTER = 5

-- Merges the documented loot table (Wowhead's Forever data, or hand-written content where
-- Wowhead has none) with what learning saw drop. Returns two lists:
--   confirmed:  items seen dropping, documented or not (isNew = not in the loot table)
--   documented: documented items not seen yet (likelyRemoved after enough kills)
local function buildLoot(entry)
	local learned = entry.learned and entry.learned.loot or {}
	local kills = entry.learned and entry.learned.kills or 0
	local hasDocs = entry.guide and entry.guide.loot and #entry.guide.loot > 0
	local learnedByName, used = {}, {}
	for itemID, count in pairs(learned) do
		local name = UI.ItemInfo(itemID, queueRefresh)
		if name then learnedByName[AG:Normalize(name)] = itemID end
	end

	local confirmed, documented = {}, {}
	for _, item in ipairs(entry.guide and entry.guide.loot or {}) do
		local id = item.itemID
		if id then
			local realName = UI.ItemInfo(id, queueRefresh)
			if realName and AG:Normalize(realName) ~= AG:Normalize(item.name) then id = nil end
		end
		-- Seen in Forever? Match by ID first, then by name.
		local seenID = (id and learned[id] and id) or learnedByName[AG:Normalize(item.name)]
		if seenID then
			used[seenID] = true
			table.insert(confirmed, {
				itemID = seenID, slot = item.slot, quality = item.quality, count = learned[seenID],
			})
		else
			table.insert(documented, {
				name = item.name, itemID = id, slot = item.slot, quality = item.quality,
				likelyRemoved = kills >= LIKELY_REMOVED_AFTER,
			})
		end
	end

	for itemID, count in pairs(learned) do
		if not used[itemID] then
			table.insert(confirmed, { itemID = itemID, count = count, isNew = hasDocs })
		end
	end
	table.sort(confirmed, function(a, b) return (a.count or 0) > (b.count or 0) end)
	return confirmed, documented, kills
end

-- Ability rows: guide abilities (matched to learned spell IDs by name), then spells
-- learning saw the boss cast that the guide doesn't cover.
local function buildAbilities(entry)
	local guideAbilities = entry.guide and entry.guide.abilities or {}
	local learned = entry.learned and entry.learned.spells or {}
	local byName, used = {}, {}
	for spellID in pairs(learned) do
		local name = UI.SpellInfo(spellID, queueRefresh)
		if name then byName[AG:Normalize(name)] = spellID end
	end

	local rows = {}
	for _, ab in ipairs(guideAbilities) do
		local spellID = ab.spellID or byName[AG:Normalize(ab.name)]
		if spellID then used[spellID] = true end
		table.insert(rows, { name = ab.name, text = ab.text, alerts = ab.alerts, spellID = spellID })
	end
	local seen = {}
	for spellID, count in pairs(learned) do
		if not used[spellID] then table.insert(seen, { spellID = spellID, count = count }) end
	end
	table.sort(seen, function(a, b) return a.count > b.count end)
	return rows, seen
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
			PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
			AG.view.section = i
			AG:Refresh()
		end)
		bp.buttons[i] = b
	end

	bp.scroll, bp.child = UI.CreateScroll(bp)
	bp.scroll:SetPoint("TOPLEFT", bp.buttons[1], "BOTTOMLEFT", 2, -10)
	bp.scroll:SetPoint("BOTTOMRIGHT", -28, 10)

	-- Model viewer. Drag to turn, scroll to zoom.
	local model = CreateFrame("PlayerModel", nil, bp)
	model:SetPoint("TOPLEFT", bp.buttons[1], "BOTTOMLEFT", 2, -10)
	model:SetPoint("BOTTOMRIGHT", -10, 10)
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
	model.hint = UI.Text(bp, "GameFontDisable", "CENTER")
	model.hint:SetPoint("CENTER", model, "CENTER")
	model.hint:SetWidth(320)
	bp.model = model

	bp.empty = UI.Text(bp, "GameFontDisableLarge", "CENTER")
	bp.empty:SetPoint("CENTER")
	bp.empty:SetWidth(380)

	self.bossPage = bp
end

------------------------------------------------------------------------
-- Rendering each section into the scroll child
------------------------------------------------------------------------

local function layout(bp)
	return {
		y = 0,
		row = 0,
		heading = 0,
		width = math.max(200, bp.scroll:GetWidth() - 4),
	}
end

local function addHeading(bp, L, text)
	L.heading = L.heading + 1
	local fs = UI.Acquire(bp.child, "headings", L.heading, createHeading)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", 4, -L.y - (L.y > 0 and 10 or 0))
	fs:SetWidth(L.width - 8)
	fs:SetText(text)
	L.y = L.y + (L.y > 0 and 10 or 0) + fs:GetStringHeight() + 6
end

local function addRow(bp, L, icon, title, body, note, opts)
	L.row = L.row + 1
	local row = UI.Acquire(bp.child, "rows", L.row, createRow)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 0, -L.y)
	row.itemID = opts and opts.itemID
	row.spellID = opts and opts.spellID
	row.link = opts and opts.link
	row:SetAlpha(opts and opts.alpha or 1)
	L.y = L.y + setRow(row, L.width, icon, title, body, note) + 2
end

local function finish(bp, L)
	UI.HideFrom(bp.child, "rows", L.row + 1)
	UI.HideFrom(bp.child, "headings", L.heading + 1)
	bp.child:SetHeight(math.max(1, L.y))
	-- Jump to the top only when the page changed, not when item data trickles in.
	if bp.shownKey ~= L.key then
		bp.scroll:SetVerticalScroll(0)
		bp.shownKey = L.key
	end
end

local function renderOverview(bp, L, entry)
	local g, rec = entry.guide or {}, entry.learned
	addHeading(bp, L, "Overview")
	addRow(bp, L, nil, nil, g.overview or "No write-up for this boss yet. Learning mode still records its loot, model, and spells.")
	if rec then
		addHeading(bp, L, "Your group's history")
		local loot, spells = 0, 0
		for _ in pairs(rec.loot or {}) do loot = loot + 1 end
		for _ in pairs(rec.spells or {}) do spells = spells + 1 end
		addRow(bp, L, "Interface\\Icons\\INV_Misc_Book_11", "Learned from play",
			string.format("Kills recorded: %d\nDifferent drops seen: %d\nSpells seen: %d",
				rec.kills or 0, loot, spells))
	end
end

local function renderAbilities(bp, L, entry)
	local rows, seen = buildAbilities(entry)
	if #rows > 0 then addHeading(bp, L, "Abilities") end
	for _, ab in ipairs(rows) do
		local _, icon, desc = UI.SpellInfo(ab.spellID, queueRefresh)
		-- Hand-written notes first; otherwise the spell's own description from the game.
		local body = ab.text or desc
		addRow(bp, L, icon or UI.UNKNOWN_ICON, ab.name, body, UI.FormatAlerts(ab.alerts), { spellID = ab.spellID })
	end
	if #seen > 0 then
		addHeading(bp, L, "Seen in your fights")
		for _, s in ipairs(seen) do
			local name, icon, desc = UI.SpellInfo(s.spellID, queueRefresh)
			addRow(bp, L, icon, name or ("Spell " .. s.spellID), desc,
				string.format("|cff888888cast %dx|r", s.count), { spellID = s.spellID })
		end
	end
	if #rows == 0 and #seen == 0 then
		addRow(bp, L, nil, nil, "No abilities known yet. With learning mode on, target the boss during the fight and its spells will show up here.")
	end
end

local QUALITY_COLOR = { [0] = "9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000" }

local function addLootRow(bp, L, item, note, dim)
	local name, link, quality, icon = UI.ItemInfo(item.itemID, queueRefresh)
	local title
	-- Until the client caches the item, show the guide's name and quality.
	name = name or item.name or ("Item " .. tostring(item.itemID))
	quality = quality or item.quality or 1
	if dim then
		title = "|cff808080" .. name .. "|r"
	else
		title = string.format("|cff%s%s|r", QUALITY_COLOR[quality] or "ffffff", name)
	end
	addRow(bp, L, icon or UI.UNKNOWN_ICON, title, item.slot, note,
		{ itemID = item.itemID, link = link, alpha = dim and 0.6 or 1 })
end

local function renderLoot(bp, L, entry)
	local confirmed, documented, kills = buildLoot(entry)

	if #confirmed > 0 then
		addHeading(bp, L, "Loot  |cff66ccff(seen in your runs)|r")
		for _, item in ipairs(confirmed) do
			local note = string.format("|cff66ccffdropped %dx|r", item.count or 1)
			if item.isNew then note = note .. "  |cff20ff20not in the loot table|r" end
			addLootRow(bp, L, item, note)
		end
	end

	if #documented > 0 then
		addHeading(bp, L, #confirmed > 0 and "Also in the loot table  |cff888888(not seen yet)|r" or "Loot")
		for _, item in ipairs(documented) do
			local note = item.likelyRemoved
				and string.format("|cffff8040not seen in %d kills|r", kills) or nil
			addLootRow(bp, L, item, note, item.likelyRemoved)
		end
	end

	if #confirmed == 0 and #documented == 0 then
		addRow(bp, L, nil, nil, "No loot known yet. Loot your group finds on this boss will be recorded here.")
	elseif kills > 0 then
		addRow(bp, L, nil, nil, string.format(
			"|cff888888Updated from %d recorded kill%s. Items that drop move to the top; "
			.. "listed items that never show up fade out.|r", kills, kills == 1 and "" or "s"))
	end
end

local function renderModel(bp, entry)
	local model = bp.model
	local g, rec = entry.guide or {}, entry.learned or {}
	local displayID = rec.displayID or g.displayID
	local npcID = rec.npcID or g.npcID
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
	-- If nothing loaded, explain how to capture it.
	C_Timer.After(1, function()
		if model.shownKey ~= key then return end -- switched bosses meanwhile
		local ok, fileID = pcall(model.GetModelFileID, model)
		if not (ok and fileID) then
			model.hint:SetText("No model yet.\n\nTarget this boss once with learning mode on and its model will be captured.")
		end
	end)
end

local RENDER = { renderOverview, renderAbilities, renderLoot }

function AG:RenderBossPage(instKey, entry)
	local bp = self.bossPage
	local section = self.view.section or 1
	local hasBoss = entry ~= nil

	bp.title:SetShown(hasBoss)
	for _, b in ipairs(bp.buttons) do b:SetShown(hasBoss) end
	bp.empty:SetText(hasBoss and "" or "Pick a boss on the left.")
	if not hasBoss then
		bp.scroll:Hide()
		bp.model:Hide()
		bp.model.hint:SetText("")
		bp.model.shownKey = nil
		return
	end

	bp.title:SetText(entry.name)
	for i, b in ipairs(bp.buttons) do
		if i == section then b:LockHighlight() else b:UnlockHighlight() end
	end

	if section == 4 then
		bp.scroll:Hide()
		bp.model:Show()
		renderModel(bp, entry)
	else
		bp.model:Hide()
		bp.model.hint:SetText("")
		bp.model.shownKey = nil
		bp.scroll:Show()
		local L = layout(bp)
		L.key = instKey .. ":" .. entry.key .. ":" .. section
		RENDER[section](bp, L, entry)
		finish(bp, L)
	end
end
