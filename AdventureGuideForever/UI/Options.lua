-- The Options panel: a small window of checkboxes, opened from the guide's Options button
-- or /ag options.

local _, AG = ...
local UI = AG.UI

local SETTINGS = {
	{ label = "Learning mode (record loot, spells, and models while you play)",
		get = function() return AG.db.learn end, set = function(v) AG.db.learn = v; if AG.frame then AG:Refresh() end end },
	{ label = "Show a briefing card when I enter a dungeon or raid", option = "zoneCard" },
	{ label = "Show a boss card when I target a boss", option = "bossCard" },
	{ label = "Show my step counter by the minimap's calendar", option = "stepCounter" },
	{ label = "Add \"Drops from\" to item tooltips", option = "tooltips" },
	{ label = "Alert me when a wishlist item drops", option = "wishAlerts" },
	{ label = "Share what learning mode finds with my group", option = "sync" },
	{ label = "Remind me now and then to share my finds with the guide", option = "shareReminder" },
}

local function create()
	local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	UI.Backdrop(panel, 0.96)
	panel:SetSize(440, 72 + #SETTINGS * 28 + 78)
	panel:SetFrameStrata("DIALOG")
	panel:SetToplevel(true)
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:SetClampedToScreen(true)

	local title = UI.Text(panel, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -14)
	title:SetText("Adventure Guide options")

	local close = UI.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() panel:Hide() end)

	panel.boxes = {}
	for i, s in ipairs(SETTINGS) do
		local get = s.get or function() return AG:Option(s.option) end
		local set = s.set or function(v) AG:SetOption(s.option, v) end
		local box = UI.CheckBox(panel, s.label, get, set)
		box:SetPoint("TOPLEFT", 14, -40 - (i - 1) * 28)
		panel.boxes[i] = box
	end

	local note = UI.Text(panel, "GameFontHighlightSmall")
	note:SetPoint("TOPLEFT", 18, -48 - #SETTINGS * 28)
	note:SetPoint("RIGHT", -18, 0)
	note:SetTextColor(0.75, 0.75, 0.75)
	note:SetText("Help the guide grow: share what your learning mode found, and it gets added "
		.. "to the addon for everyone.")

	local share = UI.CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	share:SetSize(200, 24)
	share:SetPoint("BOTTOMLEFT", 16, 14)
	share:SetText("Share with the guide...")
	share:SetScript("OnClick", function() panel:Hide(); AG:ShowShare() end)

	panel:SetScript("OnShow", function(self)
		for _, box in ipairs(self.boxes) do box:Sync() end
	end)
	panel:Hide()
	return panel
end

function AG:ToggleOptions()
	self.optionsPanel = self.optionsPanel or create()
	local panel = self.optionsPanel
	if panel:IsShown() then panel:Hide(); return end
	panel:ClearAllPoints()
	if self.frame and self.frame:IsShown() then
		panel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -60)
	else
		panel:SetPoint("CENTER")
	end
	panel:Show()
end
