-- The Suggested Gear tab: the best piece per slot you can get from dungeon bosses and
-- quests at a level, for a class and spec (yours by default), compared with what you're
-- wearing. Settings live in AdventureGuideForeverDB.plan; blank means "yours".

local _, AG = ...
local UI = AG.UI

local function settings()
	return AG.db.plan
end

-- The class, spec, and level being planned for, and whether that's you as you are now.
local function target()
	local myClass, myLevel = AG:PlayerClassAndLevel()
	local p = settings()
	local classID = p.classID or myClass or 1
	local level = p.level or myLevel or 60
	local spec = p.spec
	if not spec or not AG:GetSpec(classID, spec) or AG:GetSpec(classID, spec).key ~= spec then
		spec = (classID == myClass and AG:DetectSpec(classID)) or AG:GetSpec(classID).key
	end
	local isMe = classID == myClass and level == myLevel
	return classID, spec, level, isMe
end

local function refresh()
	if AG.frame and AG.frame:IsShown() then AG:Refresh() end
end

local function classOptions()
	local mine = AG:PlayerClassAndLevel()
	local out = { { value = nil, text = "Mine" .. (mine and (" (" .. AG.CLASS_NAMES[mine] .. ")") or "") } }
	for _, id in ipairs(AG.CLASS_ORDER) do out[#out + 1] = { value = id, text = AG.CLASS_NAMES[id] } end
	return out
end

local function specOptions()
	local classID = target()
	local detected = AG:DetectSpec(classID)
	local auto = detected and AG:GetSpec(classID, detected)
	local out = { { value = nil, text = "Auto" .. (auto and (" (" .. auto.name .. ")") or "") } }
	for _, spec in ipairs(AG.SPECS[classID] or {}) do out[#out + 1] = { value = spec.key, text = spec.name } end
	return out
end

function AG:CreatePlanBar(docPage)
	local bar = CreateFrame("Frame", nil, docPage)
	bar:SetPoint("TOPLEFT", 12, -8)
	bar:SetPoint("TOPRIGHT", -12, -8)
	bar:SetHeight(AG.DOC_BAR_HEIGHT)
	bar:Hide()

	bar.class = UI.Dropdown(bar, 170, "Class", classOptions,
		function() return settings().classID end,
		function(v) settings().classID = v; settings().spec = nil; refresh() end)
	bar.class:SetPoint("TOPLEFT", 0, 0)
	bar.spec = UI.Dropdown(bar, 190, "Spec", specOptions,
		function() return settings().spec end,
		function(v) settings().spec = v; refresh() end)
	bar.spec:SetPoint("LEFT", bar.class, "RIGHT", 6, 0)

	bar.levelLabel = UI.Text(bar, "GameFontNormal")
	bar.levelLabel:SetPoint("LEFT", bar.spec, "RIGHT", 14, 0)
	bar.levelLabel:SetText("Level")
	bar.level = UI.CreateFrame("EditBox", nil, bar, "InputBoxTemplate")
	bar.level:SetSize(32, 20)
	bar.level:SetPoint("LEFT", bar.levelLabel, "RIGHT", 10, 0)
	bar.level:SetAutoFocus(false)
	bar.level:SetNumeric(true)
	bar.level:SetMaxLetters(2)
	local function commit(self)
		local n = tonumber(self:GetText())
		local _, myLevel = AG:PlayerClassAndLevel()
		n = n and math.max(1, math.min(60, n)) or nil
		settings().level = (n ~= myLevel) and n or nil
		self:ClearFocus()
		refresh()
	end
	bar.level:SetScript("OnEnterPressed", commit)
	bar.level:SetScript("OnEditFocusLost", commit)
	bar.level:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	bar.quests = UI.CheckBox(bar, "Include quest rewards",
		function() return settings().quests end,
		function(v) settings().quests = v; refresh() end)
	bar.quests:SetPoint("TOPLEFT", bar.class, "BOTTOMLEFT", 0, -6)

	bar.wishAll = UI.CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
	bar.wishAll:SetSize(170, 22)
	bar.wishAll:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -30)
	bar.wishAll:SetText("Wishlist the whole set")
	bar.wishAll:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local added = 0
		for _, item in ipairs(AG.planPicks or {}) do
			if not AG:IsWished(item) then AG:ToggleWish(item); added = added + 1 end
		end
		AG:Print("Added %d item%s to your wishlist. You'll get an alert when one drops.", added, added == 1 and "" or "s")
		refresh()
	end)

	bar.Sync = function(self)
		self.class:Sync()
		self.spec:Sync()
		self.quests:Sync()
		local _, _, level = target()
		if not self.level:HasFocus() then self.level:SetText(tostring(level)) end
	end
	docPage.planBar = bar
end

-- The note for a CompareToEquipped result (the Gear tab uses it too).
function AG.UpgradeNote(diff)
	if diff == "equipped" then return "|cff20ff20Equipped|r" end
	if type(diff) ~= "number" then return "|cff20ff20New slot!|r" end
	if diff > 0.5 then return string.format("|cff20ff20+%.0f upgrade|r", diff) end
	return "|cff888888Yours is as good|r"
end
local upgradeNote = AG.UpgradeNote

local function sourceText(s)
	local inst = AG:GetInstance(s.instKey)
	local where = string.format("%s, %s", s.bossName, inst and inst.name or s.instKey)
	if s.dropChance then where = where .. string.format(" (%.0f%%)", s.dropChance) end
	return where
end

function AG:RenderPlan(doc)
	self.frame.header:SetText("Suggested Gear")
	local classID, specKey, level, isMe = target()
	local spec = self:GetSpec(classID, specKey)
	local plan, weights = self:SuggestGear(classID, specKey, level,
		{ quests = settings().quests, faction = self:PlayerFaction() })

	doc:Paragraph(string.format("Best dungeon gear for a level %d %s %s: boss drops%s you can use at that level.",
		level, spec and spec.name or "", self.CLASS_NAMES[classID] or "",
		settings().quests and " and quest rewards" or ""), { font = "GameFontNormal", color = { 1, 1, 1 } })
	doc:Paragraph("Scored by: " .. self:WeightLine(weights) .. ". These are simple suggestions, not the last word.",
		{ font = "GameFontHighlightSmall", color = { 0.6, 0.6, 0.6 } })

	self.planPicks = {}
	local upgrades = 0
	for _, slot in ipairs(plan) do
		if #slot.picks == 0 then
			doc:Row(nil, "|cff888888" .. (slot.label or slot.slot) .. "|r", "Nothing from dungeons yet at this level.", nil)
		end
		for _, pick in ipairs(slot.picks) do
			self.planPicks[#self.planPicks + 1] = pick.itemID
			local stats = self:StatLine(pick.item)
			local body = (stats ~= "" and ("|cff20ff20" .. stats .. "|r\n") or "")
				.. "|cff888888From:|r " .. sourceText(pick.source)
			if #slot.alternatives > 0 and pick == slot.picks[#slot.picks] then
				local names = {}
				for i, alt in ipairs(slot.alternatives) do names[i] = UI.QualityText(alt.name, alt.quality) end
				body = body .. "\n|cff888888Also good:|r " .. table.concat(names, ", ")
			end
			local note = string.format("|cffffd100Level %d|r", pick.item.reqLevel or 1)
			if isMe then
				local diff = self:CompareToEquipped(pick, slot.equip, weights)
				if diff == "equipped" or (type(diff) == "number" and diff <= 0.5) then
					note = upgradeNote(diff)
				else
					upgrades = upgrades + 1
					note = upgradeNote(diff) .. "\n" .. note
				end
			end
			doc:Row(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(pick.itemID) or UI.UNKNOWN_ICON,
				string.format("|cffffd100%s:|r %s", slot.label or slot.slot, UI.QualityText(pick.name, pick.quality)),
				body, note, {
					itemID = pick.itemID, star = true,
					onClick = function()
						PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
						AG:ShowInstance(pick.source.instKey, pick.source.bossKey)
					end,
				})
		end
	end
	if isMe then
		doc:Paragraph(upgrades > 0 and string.format("%d upgrade%s over what you're wearing.", upgrades, upgrades == 1 and "" or "s")
			or "You're already wearing the best of it. Nice.", { font = "GameFontHighlightSmall", color = { 0.7, 0.7, 0.7 } })
	end
	doc:Paragraph("Two-Hand and One-Hand are alternatives: pick a two-hander, or a one-hander with an off hand.",
		{ font = "GameFontHighlightSmall", color = { 0.6, 0.6, 0.6 } })
end
