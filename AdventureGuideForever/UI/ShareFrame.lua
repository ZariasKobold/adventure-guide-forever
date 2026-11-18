-- The Share window (/ag share): the export text and the GitHub link, ready to copy.
-- Addons can't open a browser or reach the internet, so the player copies both.

local _, AG = ...
local UI = AG.UI

local function readOnly(box, getText)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then self:SetText(getText()); self:HighlightText() end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:GetParent():Hide() end)
	box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
end

local function create()
	local f = CreateFrame("Frame", "AdventureGuideForeverShareFrame", UIParent, "BackdropTemplate")
	UI.Backdrop(f, 0.97)
	f:SetSize(560, 440)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	table.insert(UISpecialFrames, f:GetName())

	local close = UI.CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	local title = UI.Text(f, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -14)
	title:SetText("Share what you learned")

	local steps = UI.Text(f, "GameFontHighlight")
	steps:SetPoint("TOPLEFT", 16, -40)
	steps:SetPoint("RIGHT", -16, 0)
	steps:SetText("1. Copy this link (Ctrl+C) and open it in your web browser:")

	local url = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	url:SetPoint("TOPLEFT", steps, "BOTTOMLEFT", 6, -6)
	url:SetPoint("RIGHT", -20, 0)
	url:SetHeight(22)
	url:SetAutoFocus(false)
	readOnly(url, function() return AG.SHARE_URL end)
	f.url = url

	local step2 = UI.Text(f, "GameFontHighlight")
	step2:SetPoint("TOPLEFT", url, "BOTTOMLEFT", -6, -10)
	step2:SetPoint("RIGHT", -16, 0)
	step2:SetText("2. Click in the box below, press Ctrl+C, and paste it into the form. Then submit.")

	local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
	box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	box:SetBackdropColor(0, 0, 0, 0.5)
	box:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
	box:SetPoint("TOPLEFT", step2, "BOTTOMLEFT", 0, -8)
	box:SetPoint("BOTTOMRIGHT", -16, 58)

	local scroll = UI.CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate", "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -26, 6)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetAutoFocus(false)
	edit:SetWidth(480)
	scroll:SetScrollChild(edit)
	scroll:HookScript("OnSizeChanged", function(_, w) edit:SetWidth(w) end)
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function() edit:SetFocus() end)
	readOnly(edit, function() return f.text or "" end)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
	f.edit = edit

	local privacy = UI.Text(f, "GameFontHighlightSmall")
	privacy:SetPoint("BOTTOMLEFT", 16, 16)
	privacy:SetPoint("RIGHT", -16, 0)
	privacy:SetTextColor(0.7, 0.7, 0.7)
	privacy:SetText("This posts publicly on GitHub (you'll need a free account). It holds only boss, item, "
		.. "and spell IDs, kill counts, and a random ID. No character names. A maintainer reviews it "
		.. "before it joins the addon.")
	f.summary = UI.Text(f, "GameFontNormalSmall")
	f.summary:SetPoint("BOTTOMLEFT", privacy, "TOPLEFT", 0, 6)

	f:Hide()
	return f
end

function AG:ShowShare()
	local text, bosses = self:BuildExport()
	if bosses == 0 then
		self:Print("Learning mode hasn't recorded anything yet. Run a dungeon with it on, then share.")
		return
	end
	self.shareFrame = self.shareFrame or create()
	local f = self.shareFrame
	f.text = text
	f.url:SetText(self.SHARE_URL)
	f.edit:SetText(text)
	f.summary:SetText(string.format("Ready to share: %d boss%s.", bosses, bosses == 1 and "" or "es"))
	f:Show()
	f.edit:SetFocus()
	f.edit:HighlightText()
	-- Counted as shared once the window opens; the next nudge waits for new finds.
	self.db.unshared = 0
end
