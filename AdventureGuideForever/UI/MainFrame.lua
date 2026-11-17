-- The main window: a Blizzard-style portrait frame with bottom tabs, like the retail
-- Adventure Guide. Holds two views: the instance list and an instance's page.

local _, AG = ...
local UI = AG.UI

local WIDTH, HEIGHT = 880, 580

AG.TABS = {
	{ key = "suggested", label = "Suggested Content" },
	{ key = "dungeons",  label = "Dungeons" },
	{ key = "raids",     label = "Raids" },
}

local function setPortrait(frame)
	local icon = "Interface\\Icons\\INV_Misc_Book_09"
	if frame.SetPortraitToAsset then
		pcall(frame.SetPortraitToAsset, frame, icon)
	elseif frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture(icon)
	end
end

local function setTitle(frame, text)
	if frame.SetTitle then
		frame:SetTitle(text)
	elseif frame.TitleContainer and frame.TitleContainer.TitleText then
		frame.TitleContainer.TitleText:SetText(text)
	else
		frame.fallbackTitle = frame.fallbackTitle or UI.Text(frame, "GameFontNormal", "CENTER")
		frame.fallbackTitle:SetPoint("TOP", 0, -6)
		frame.fallbackTitle:SetText(text)
	end
end

local function createTabs(frame)
	frame.Tabs = {}
	for i, info in ipairs(AG.TABS) do
		local tab = UI.CreateFrame("Button", frame:GetName() .. "Tab" .. i, frame, "PanelTabButtonTemplate", "CharacterFrameTabButtonTemplate")
		tab:SetID(i)
		tab:SetText(info.label)
		if i == 1 then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 2)
		else
			tab:SetPoint("TOPLEFT", frame.Tabs[i - 1], "TOPRIGHT", 3, 0)
		end
		if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 10) end
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB or 841)
			AG:SelectTab(i)
		end)
		frame.Tabs[i] = tab
	end
	if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(frame, #AG.TABS) end
end

function AG:CreateMainFrame()
	local frame = UI.CreateFrame("Frame", "AdventureGuideForeverFrame", UIParent, "PortraitFrameTemplate", "BasicFrameTemplateWithInset")
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	setPortrait(frame)
	setTitle(frame, "Adventure Guide")

	-- Close on Escape, like Blizzard panels.
	table.insert(UISpecialFrames, frame:GetName())

	-- Content area below the title bar.
	local content = UI.CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
	content:SetPoint("TOPLEFT", 10, -60)
	content:SetPoint("BOTTOMRIGHT", -8, 8)
	frame.content = content

	-- Header line: current view title on the left, learning status on the right.
	frame.header = UI.Text(frame, "GameFontNormalLarge")
	frame.header:SetPoint("TOPLEFT", 64, -34)
	frame.learnStatus = UI.Text(frame, "GameFontDisableSmall", "RIGHT")
	frame.learnStatus:SetPoint("TOPRIGHT", -14, -38)

	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN or 839)
		AG:Refresh()
		-- Redraw once layout has settled, so wrapped text measures at its real width.
		C_Timer.After(0, function() AG:Refresh() end)
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_CLOSE or 840)
		if AG.bossPage then AG.bossPage.model.shownKey = nil end -- reload the model next time
	end)

	createTabs(frame)
	self.frame = frame
	self:CreateInstanceList(content)
	self:CreateInstancePage(content)

	-- Open on the tab that fits: your current instance, else Suggested Content.
	self.view = { tab = 1 }
	local here = self:GetCurrentInstanceKey()
	if here then
		local inst = self:GetInstance(here)
		self.view.tab = inst.isRaid and 3 or 2
		self.view.instKey = here
	end
end

function AG:SelectTab(index)
	self.view.tab = index
	self.view.instKey = nil
	self.view.bossKey = nil
	self:Refresh()
end

function AG:ShowInstance(instKey, bossKey)
	local inst = self:GetInstance(instKey)
	if not inst then return end
	self.view.instKey = instKey
	self.view.bossKey = bossKey
	if self.view.tab == 1 then
		-- keep Suggested selected so "back" returns there
	else
		self.view.tab = inst.isRaid and 3 or 2
	end
	self:Refresh()
end

function AG:Refresh()
	local frame = self.frame
	if not frame then return end
	if PanelTemplates_SetTab then PanelTemplates_SetTab(frame, self.view.tab) end
	frame.learnStatus:SetText(self.db.learn and "Learning mode: on" or "Learning mode: off")

	if self.view.instKey then
		self.instanceList:Hide()
		self.instancePage:Show()
		self:RenderInstancePage(self.view.instKey, self.view.bossKey)
	else
		self.instancePage:Hide()
		self.instanceList:Show()
		self:RenderInstanceList(AG.TABS[self.view.tab].key)
	end
end
