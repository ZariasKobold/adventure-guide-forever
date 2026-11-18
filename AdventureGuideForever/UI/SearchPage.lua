-- The search box in the guide's header and its results page. Type two or more letters to
-- search dungeons, bosses, items (boss drops and quest rewards), quests, and abilities;
-- click a result to jump to it. Escape or the box's clear button returns to the tab.

local _, AG = ...
local UI = AG.UI

local ICONS = {
	boss = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
	quest = "Interface\\GossipFrame\\AvailableQuestIcon",
	instance = "Interface\\Icons\\INV_Misc_Map_01",
	ability = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local function itemIcon(itemID)
	local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)
	return icon or UI.UNKNOWN_ICON
end

local function spellIcon(spellID)
	local info = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
	return info and info.iconID or ICONS.ability
end

local function open(entry)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	AG:SetSearch(nil)
	AG:ShowInstance(entry.instKey, entry.bossKey)
end

local function row(doc, entry)
	local opts = { onClick = function() open(entry) end }
	if entry.kind == "item" then
		opts.itemID, opts.star = entry.itemID, true
		doc:Row(itemIcon(entry.itemID), UI.QualityText(entry.name, entry.quality), entry.sub, entry.slot, opts)
	elseif entry.kind == "quest" then
		opts.questID = entry.questID
		local level = entry.level and string.format("[%d] ", entry.level) or ""
		doc:Row(ICONS.quest, level .. entry.name, entry.sub, entry.side and ("|cff888888" .. entry.side .. "|r"), opts)
	elseif entry.kind == "ability" then
		opts.spellID = entry.spellID
		doc:Row(spellIcon(entry.spellID), entry.name, entry.sub, nil, opts)
	elseif entry.kind == "instance" then
		local art = AG.Art[entry.instKey]
		doc:Row(art and art.icon or ICONS.instance, entry.name, entry.sub, nil, opts)
	else
		doc:Row(ICONS.boss, entry.name, entry.sub, nil, opts)
	end
end

function AG:RenderSearch(doc, query)
	self.frame.header:SetText("Search")
	local groups = self:Search(query)
	if #groups == 0 then
		doc:Paragraph(string.format("Nothing found for \"%s\".", query), { font = "GameFontNormalLarge", color = { 1, 1, 1 } })
		doc:Paragraph("Search looks through dungeon, boss, item, quest, and ability names. Try part of a name, like \"mugg\" or \"orgrimmar\".",
			{ color = { 0.6, 0.6, 0.6 } })
		return
	end
	for _, group in ipairs(groups) do
		doc:Heading(string.format("%s  |cff888888(%d%s)|r", group.label, #group.results,
			group.more > 0 and ("+" .. group.more) or ""))
		for _, entry in ipairs(group.results) do row(doc, entry) end
		if group.more > 0 then
			doc:Paragraph(string.format("...and %d more. Type more of the name to narrow it down.", group.more),
				{ font = "GameFontHighlightSmall", color = { 0.6, 0.6, 0.6 } })
		end
	end
end

-- Show results for a query (nil or "" goes back to the current tab).
function AG:SetSearch(query)
	query = query and query:match("^%s*(.-)%s*$") or ""
	if not self.frame then self:CreateMainFrame() end
	self.view.search = #query >= 2 and query or nil
	local box = self.frame.searchBox
	if box and box:GetText() ~= query then
		box.settingText = true
		box:SetText(query)
		box.settingText = nil
	end
	if query == "" and box then box:ClearFocus() end
	self:Refresh()
end

function AG:CreateSearchBox(frame)
	local box = UI.CreateFrame("EditBox", "AdventureGuideForeverSearchBox", frame, "SearchBoxTemplate", "InputBoxTemplate")
	box:SetSize(190, 20)
	box:SetPoint("TOPRIGHT", frame.optionsButton, "TOPLEFT", -10, -1)
	box:SetAutoFocus(false)
	box:SetMaxLetters(60)
	if box.Instructions then box.Instructions:SetText("Search bosses, gear, quests...") end
	box:HookScript("OnTextChanged", function(self, userInput)
		if self.settingText then return end
		-- Wait for a short pause in typing before searching.
		self.pending = (self.pending or 0) + 1
		local token = self.pending
		C_Timer.After(0.25, function()
			if token == self.pending then AG:SetSearch(self:GetText()) end
		end)
	end)
	box:HookScript("OnEscapePressed", function() AG:SetSearch(nil) end)
	box:HookScript("OnEnterPressed", function(self) self:ClearFocus() end)
	frame.searchBox = box
end
