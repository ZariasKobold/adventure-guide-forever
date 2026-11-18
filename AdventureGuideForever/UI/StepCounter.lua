-- The step counter: a small badge beside the minimap's calendar button showing your steps
-- on foot (this character, all time). Hover for this session vs all time; click to open the
-- Journey page. Drag it anywhere; right-click puts it back by the calendar. Turn it off in
-- Options or with /ag steps.

local _, AG = ...
local UI = AG.UI

local ICON = "Interface\\Icons\\Ability_Tracking" -- a trail of footprints
local counter

-- Beside the calendar button, or wherever you dragged it.
local function place(f)
	f:ClearAllPoints()
	local saved = AG.db.options.stepPosition
	if type(saved) == "table" and saved.point then
		f:SetPoint(saved.point, UIParent, saved.relPoint or saved.point, saved.x or 0, saved.y or 0)
	elseif GameTimeFrame and GameTimeFrame:IsShown() then
		f:SetPoint("RIGHT", GameTimeFrame, "LEFT", -2, 0)
	elseif Minimap then
		f:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -6, 0)
	else
		f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -6)
	end
end

local function showTooltip(f)
	local rec = AG:GetJourney()
	if not rec then return end
	local session = rec.session or { distance = {} }
	GameTooltip:SetOwner(f, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText("Steps", 1, 1, 1)
	GameTooltip:AddDoubleLine("This session",
		string.format("%s steps", UI.Commas(AG:StepsFrom(session.distance.foot))), nil, nil, nil, 1, 0.82, 0)
	GameTooltip:AddDoubleLine("All time",
		string.format("%s steps", UI.Commas(AG:StepsFrom(rec.distance.foot))), nil, nil, nil, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Distance traveled, every way", 1, 1, 1)
	GameTooltip:AddDoubleLine("This session", UI.Distance(AG:TotalYards(session.distance)), nil, nil, nil, 1, 1, 1)
	GameTooltip:AddDoubleLine("All time", UI.Distance(AG:TotalYards(rec.distance)), nil, nil, nil, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to open your Journey. Drag to move it; right-click to put it back by the calendar.",
		0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

local function create()
	local f = CreateFrame("Button", nil, UIParent)
	UI.Backdrop(f, 0.85)
	f:SetSize(70, 22)
	f:SetFrameStrata("MEDIUM")
	f:SetFrameLevel(20)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", 5, 0)
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local text = UI.Text(f, "GameFontHighlightSmall")
	text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	f.text = text

	f:SetScript("OnDragStart", function(self)
		self.dragging = true
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		AG.db.options.stepPosition = { point = point, relPoint = relPoint, x = x, y = y }
		place(self)
		C_Timer.After(0, function() self.dragging = nil end) -- don't treat the drop as a click
	end)
	f:SetScript("OnClick", function(self, button)
		if self.dragging then return end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if button == "RightButton" then
			AG.db.options.stepPosition = nil
			place(self)
			return
		end
		AG:OpenTab("journey")
	end)
	f:SetScript("OnEnter", showTooltip)
	f:SetScript("OnLeave", GameTooltip_Hide)
	place(f)
	return f
end

-- Redraws the count (called as you move) and shows or hides it per the option.
function AG:UpdateStepCounter()
	if not self.db then return end
	if not self:Option("stepCounter") then
		if counter then counter:Hide() end
		return
	end
	local rec = self:GetJourney()
	if not rec then return end
	counter = counter or create()
	local text = UI.Commas(self:StepsFrom(rec.distance.foot))
	if counter.text:GetText() ~= text then
		counter.text:SetText(text)
		counter:SetWidth(math.max(50, counter.text:GetStringWidth() + 30))
	end
	counter:Show()
	if GameTooltip:IsOwned(counter) then showTooltip(counter) end
end

local handlers = {
	-- After Journey.lua has started this session's record, and after the minimap is laid out.
	PLAYER_ENTERING_WORLD = function() C_Timer.After(0, function() AG:UpdateStepCounter() end) end,
}

local events = CreateFrame("Frame")
for event in pairs(handlers) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Step counter error in %s: %s", event, tostring(err)) end
end)
