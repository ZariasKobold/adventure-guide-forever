-- Options: a page in the game's own settings (Esc > Options > AddOns > Adventure Guide
-- Forever), like other addons. The guide's Options button and /ag options open it there.
-- If the settings API is missing, the same page opens as a small window instead.
--
-- The key that opens the guide is the game's own "Toggle Adventure Guide" binding (also in
-- Esc > Options > Keybindings); the button here just sets it. Core.lua's ApplyBindings
-- follows that binding, and uses Shift+J when nothing is bound.

local _, AG = ...
local UI = AG.UI

local TITLE = "Adventure Guide Forever"
local BINDING = "TOGGLEENCOUNTERJOURNAL"

local SETTINGS = {
	{ label = "Show a briefing card when I enter a dungeon or raid", option = "zoneCard" },
	{ label = "Show a boss card when I target a boss", option = "bossCard" },
	{ label = "Show where to get items (drops and quest rewards) on their tooltips", option = "tooltips" },
	{ label = "Alert me when a wishlist item drops", option = "wishAlerts" },
}

-- Keys that only modify another key; pressing one alone keeps listening.
local MODIFIERS = {
	LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
	LMETA = true, RMETA = true,
}

-- The key that opens the guide now, as the game writes it ("Shift-J").
function AG:GuideKeyText()
	local key = GetBindingKey(BINDING)
	if not key then
		local action = GetBindingAction("SHIFT-J")
		if action == nil or action == "" or action == BINDING then key = "SHIFT-J" end
	end
	if not key then return "not set" end
	return GetBindingText and GetBindingText(key) or key
end

-- "ALT-CTRL-SHIFT-J": the order the game uses for binding names.
function AG.BindingName(key, alt, ctrl, shift)
	return (alt and "ALT-" or "") .. (ctrl and "CTRL-" or "") .. (shift and "SHIFT-" or "") .. key
end

-- Makes key the one that opens the guide, replacing whatever it did before. Returns false
-- in combat, when the game doesn't allow binding changes.
function AG:SetGuideKey(key)
	if InCombatLockdown() then return false end
	local before = GetBindingAction(key)
	for _, old in ipairs({ GetBindingKey(BINDING) }) do SetBinding(old) end
	SetBinding(key, BINDING)
	SaveBindings(GetCurrentBindingSet())
	self:ApplyBindings()
	if before and before ~= "" and before ~= BINDING then
		local label = _G["BINDING_NAME_" .. before] or before
		self:Print("%s opens the guide now. It used to do: %s.", GetBindingText and GetBindingText(key) or key, label)
	else
		self:Print("%s opens the guide now.", GetBindingText and GetBindingText(key) or key)
	end
	return true
end

-- A button that shows the guide's key; click it, then press the new key (Escape cancels).
local function keyButton(parent)
	local b = UI.CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(180, 24)
	local function show() b:SetText(AG:GuideKeyText()) end
	local function stop()
		b.listening = nil
		b:EnableKeyboard(false)
		b:SetScript("OnKeyDown", nil)
		show()
	end
	b:SetScript("OnClick", function()
		if InCombatLockdown() then
			AG:Print("Keys can't change during combat. Try again after the fight.")
			return
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		b.listening = true
		b:SetText("Press a key...")
		b:EnableKeyboard(true)
		b:SetPropagateKeyboardInput(false)
		b:SetScript("OnKeyDown", function(_, key)
			if MODIFIERS[key] then return end
			if key ~= "ESCAPE" then
				AG:SetGuideKey(AG.BindingName(key, IsAltKeyDown(), IsControlKeyDown(), IsShiftKeyDown()))
			end
			stop()
		end)
	end)
	b:SetScript("OnHide", function() if b.listening then stop() end end)
	b.Sync = show
	return b
end

-- Fills a frame with the options. Returns the controls to refresh when it's shown.
local function build(panel)
	local title = UI.Text(panel, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(TITLE)

	local controls = {}
	local y = -50
	for _, s in ipairs(SETTINGS) do
		local box = UI.CheckBox(panel, s.label,
			function() return AG:Option(s.option) end,
			function(v) AG:SetOption(s.option, v) end)
		box:SetPoint("TOPLEFT", 14, y)
		controls[#controls + 1] = box
		y = y - 30
	end

	local keyLabel = UI.Text(panel, "GameFontNormal")
	keyLabel:SetPoint("TOPLEFT", 18, y - 14)
	keyLabel:SetText("Key that opens the guide")
	local key = keyButton(panel)
	key:SetPoint("LEFT", keyLabel, "RIGHT", 12, 0)
	controls[#controls + 1] = key

	local hint = UI.Text(panel, "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -14)
	hint:SetWidth(520)
	hint:SetTextColor(0.7, 0.7, 0.7)
	hint:SetText("Click the button, then press the key you want (Escape cancels). It's the game's "
		.. "\"Toggle Adventure Guide\" binding, so you can also change it in Keybindings.")

	panel:HookScript("OnShow", function()
		for _, c in ipairs(controls) do c:Sync() end
	end)
	return controls
end

------------------------------------------------------------------------
-- In the game's settings
------------------------------------------------------------------------

local category
local function register()
	if category or not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")
	panel.name = TITLE
	build(panel)
	category = Settings.RegisterCanvasLayoutCategory(panel, TITLE)
	Settings.RegisterAddOnCategory(category)
end

------------------------------------------------------------------------
-- Fallback: a small window
------------------------------------------------------------------------

local function createWindow()
	local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	UI.Backdrop(panel, 0.96)
	panel:SetSize(560, 70 + #SETTINGS * 30 + 100)
	panel:SetFrameStrata("DIALOG")
	panel:SetToplevel(true)
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:SetClampedToScreen(true)
	local close = UI.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() panel:Hide() end)
	build(panel)
	panel:Hide()
	return panel
end

function AG:ToggleOptions()
	if category and Settings.OpenToCategory then
		if InCombatLockdown() then
			self:Print("The game's settings don't open during combat. Try again after the fight.")
			return
		end
		-- Our window sits on the same layer as the game's settings, so step aside.
		if self.frame and self.frame:IsShown() then self.frame:Hide() end
		Settings.OpenToCategory(category:GetID())
		return
	end
	self.optionsPanel = self.optionsPanel or createWindow()
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

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	local ok, err = pcall(register)
	if not ok and AG.debug then AG:Print("Options error: %s", tostring(err)) end
end)
