-- Adventure Guide: Forever
-- Core: namespace, saved variables, slash commands, and the Shift+J / micro menu hook.

-- Globals this addon creates, on purpose (everything else lives on the namespace AG):
--   AdventureGuideForeverDB                      saved variables
--   SLASH_ADVENTUREGUIDEFOREVER1/2, SlashCmdList  the /ag command
--   AdventureGuideForever_OnCompartmentClick      addon compartment entry (TOC)
--   ToggleEncounterJournal                        only if Blizzard's is missing
--   AdventureGuideForeverFrame, ...ToggleButton   named frames (Escape-to-close, bindings)

local ADDON, AG = ...

AG.version = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"
AG.Instances = {}   -- ordered list, filled by Data\Instances.lua
AG.Guides = {}      -- merged guide data keyed by instance key, built by Data\Registry.lua

local PREFIX = "|cff66ccffAdventure Guide|r "

function AG:Print(fmt, ...)
	local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	print(PREFIX .. msg)
end

-- Secret values (Midnight-era addon restrictions, active on Forever) can be passed around
-- but not compared, truth-tested, used as table keys, or stored. Check before using one.
local function isSecret(value)
	return type(issecretvalue) == "function" and issecretvalue(value) == true
end

-- True when a value exists and can be read.
function AG:IsUsable(value)
	return value ~= nil and not isSecret(value)
end

-- The value itself when readable, otherwise nil. Use it on API returns before testing
-- them, e.g. `if AG:Readable(UnitExists("target")) then`; a secret boolean would error.
function AG:Readable(value)
	if isSecret(value) then return nil end
	return value
end

-- Lowercase, strip punctuation and a leading "The " so "The Deadmines" matches "Deadmines".
function AG:Normalize(name)
	if not self:IsUsable(name) or type(name) ~= "string" then return nil end
	name = name:lower():gsub("^the ", ""):gsub("[^%w]", "")
	return name
end

function AG:GetInstance(key)
	for _, inst in ipairs(self.Instances) do
		if inst.key == key then return inst end
	end
end

function AG:FindInstanceByName(name)
	local norm = self:Normalize(name)
	if not norm then return nil end
	for _, inst in ipairs(self.Instances) do
		if self:Normalize(inst.name) == norm then return inst end
		for _, alias in ipairs(inst.aliases or {}) do
			if self:Normalize(alias) == norm then return inst end
		end
	end
end

-- Finds a boss by name, within one instance or across every guide.
function AG:FindBoss(name, instKey)
	local norm = self:Normalize(name)
	if not norm then return nil end
	for key, guide in pairs(self.Guides) do
		if not instKey or key == instKey then
			for _, boss in ipairs(guide.bosses or {}) do
				if self:Normalize(boss.name) == norm then return boss, key end
				for _, extra in ipairs(boss.alsoNamed or {}) do
					if self:Normalize(extra) == norm then return boss, key end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Saved variables
------------------------------------------------------------------------

local defaults = {
	learn = true,        -- record loot, models, and boss spells while playing
	learned = {},        -- [instKey] = { bosses = { [bossKey] = {...} } }
}

local function applyDefaults(db, defs)
	for k, v in pairs(defs) do
		if db[k] == nil then
			db[k] = type(v) == "table" and CopyTable(v) or v
		end
	end
end

------------------------------------------------------------------------
-- Opening the guide: Shift+J, the micro menu button, and /ag
------------------------------------------------------------------------

function AG:Toggle()
	if not self.frame then self:CreateMainFrame() end
	self.frame:SetShown(not self.frame:IsShown())
end

function AG:Open(instKey, bossKey)
	if not self.frame then self:CreateMainFrame() end
	self.frame:Show()
	if instKey then self:ShowInstance(instKey, bossKey) end
end

-- Forever keeps Shift+J bound to TOGGLEENCOUNTERJOURNAL and keeps the micro button, but
-- reroutes them (Shift+J opens Guild & Communities). So we claim them directly:
--   * an override binding sends the guide's key(s) to a hidden button of ours, and
--   * the micro button's click opens our guide instead.
local toggleButton = CreateFrame("Button", "AdventureGuideForeverToggleButton", UIParent)
toggleButton:SetScript("OnClick", function() AG:Toggle() end)

local boundKeys = ""
local bindingsPending = false

local function guideKeys()
	local keys = { GetBindingKey("TOGGLEENCOUNTERJOURNAL") }
	if #keys == 0 then
		-- Nothing bound to the guide: use Shift+J, unless the player put something else there.
		local action = GetBindingAction("SHIFT-J")
		if action == nil or action == "" or action == "TOGGLEENCOUNTERJOURNAL" then keys = { "SHIFT-J" } end
	end
	return keys
end

function AG:ApplyBindings()
	if InCombatLockdown() then
		bindingsPending = true -- bindings can't change in combat; retry when it ends
		return
	end
	bindingsPending = false
	local keys = guideKeys()
	local signature = table.concat(keys, ",")
	if signature == boundKeys then return end -- unchanged; also stops UPDATE_BINDINGS loops
	boundKeys = signature
	ClearOverrideBindings(toggleButton)
	for _, key in ipairs(keys) do
		SetOverrideBindingClick(toggleButton, true, key, toggleButton:GetName())
	end
end

-- The Adventure Guide micro button (the book on the menu bar). Forever keeps it, but
-- Blizzard's own code greys it out because their guide can't load here, and a greyed
-- button ignores clicks. So we keep it enabled, give it our tooltip, and show it pressed
-- while the guide is open. Blizzard's update methods run often; we re-apply after each.
local MICRO_UPDATES = { "UpdateMicroButton", "UpdateDisplay", "EvaluateAlertVisibility", "Disable" }

local function microTooltip()
	local title = ADVENTURE_JOURNAL or "Adventure Guide"
	if MicroButtonTooltipText then return MicroButtonTooltipText(title, "TOGGLEENCOUNTERJOURNAL") end
	return title
end

function AG:UpdateMicroButton()
	local button = EJMicroButton
	if not button then return end
	if not button:IsEnabled() then button:Enable() end
	button.tooltipText = microTooltip()
	button.disabledTooltip = nil
	local open = self.frame and self.frame:IsShown()
	if open then
		if button.SetPushed then button:SetPushed() else button:SetButtonState("PUSHED", true) end
	else
		if button.SetNormal then button:SetNormal() else button:SetButtonState("NORMAL") end
	end
end

local function hookMicroButton()
	local button = EJMicroButton
	if not button or AG.microHooked then return end
	AG.microHooked = true
	button:SetScript("OnClick", function() AG:Toggle() end)
	for _, method in ipairs(MICRO_UPDATES) do
		if type(button[method]) == "function" then
			hooksecurefunc(button, method, function() AG:UpdateMicroButton() end)
		end
	end
	-- If the menu bar left it out, put it back in.
	if not button:IsShown() then
		button:Show()
		if MicroMenu and MicroMenu.Layout then MicroMenu:Layout() end
	end
	AG:UpdateMicroButton()
end

local function installOpeners()
	-- Anything else that calls Blizzard's toggle (other addons, macros) opens ours too.
	if not ToggleEncounterJournal then
		ToggleEncounterJournal = function() AG:Toggle() end
	end
	AG:ApplyBindings()
	hookMicroButton()
end

-- Addon compartment (the addon list button by the minimap), declared in the TOC.
function AdventureGuideForever_OnCompartmentClick()
	AG:Toggle()
end

------------------------------------------------------------------------
-- Slash command
------------------------------------------------------------------------

local USAGE = "/ag opens the guide.  /ag learn turns learning mode on or off.  "
	.. "/ag reset learned forgets what learning mode recorded."

local commands = {
	[""] = function() AG:Toggle() end,
	help = function() AG:Print(USAGE) end,
	learn = function()
		AG.db.learn = not AG.db.learn
		AG:Print("Learning mode is now %s.", AG.db.learn and "|cff20ff20on|r" or "|cffff2020off|r")
	end,
	["reset learned"] = function()
		wipe(AG.db.learned)
		AG:Print("Forgot everything learned so far.")
	end,
}

SLASH_ADVENTUREGUIDEFOREVER1 = "/ag"
SLASH_ADVENTUREGUIDEFOREVER2 = "/advguide"
SlashCmdList.ADVENTUREGUIDEFOREVER = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	local command = commands[msg]
	if command then
		command()
	else
		AG:Print("Unknown command %q. %s", msg, USAGE)
	end
end

------------------------------------------------------------------------
-- Startup: one frame, one handler per event
------------------------------------------------------------------------

local handlers = {
	ADDON_LOADED = function(name)
		if name ~= ADDON then return end
		-- Saved variables are only valid from here on, never at file scope.
		AdventureGuideForeverDB = AdventureGuideForeverDB or {}
		applyDefaults(AdventureGuideForeverDB, defaults)
		AG.db = AdventureGuideForeverDB
		AG:BuildGuides() -- every data file has loaded by now
	end,
	PLAYER_LOGIN = function()
		installOpeners()
		AG:InitLearning()
	end,
	UPDATE_BINDINGS = function()
		-- The player changed key bindings: follow the guide's key to its new place.
		if AG.db then AG:ApplyBindings() end
	end,
	PLAYER_REGEN_ENABLED = function()
		if bindingsPending then AG:ApplyBindings() end
	end,
}

local loader = CreateFrame("Frame")
for event in pairs(handlers) do loader:RegisterEvent(event) end
loader:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)
