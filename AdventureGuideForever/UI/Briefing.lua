-- Briefing cards: the guide comes to you.
--
--   * Dungeon card: when you enter a dungeon or raid (counted by Journey.lua), a small card
--     with the route's first step, the boss count, a tip, and your wishlist items there.
--     It fades after a while unless your mouse is on it.
--   * Boss card: when you target a boss, its overview, the tip for your role, the abilities
--     to watch for, and its wishlist items. Shown once per boss per visit, and hidden when
--     you target something else.
--
-- Both can be turned off in /ag options (or with the "Turn off" link on the card).

local _, AG = ...
local UI = AG.UI

local WIDTH = 340
local ZONE_CARD_SECONDS = 25
local WATCH_FOR = 2 -- abilities listed on the boss card

local card
local shownBosses = {}  -- boss keys already shown this visit
local hideToken = 0

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }

-- Your role: the one assigned in the group, else your spec's role.
local function playerRole()
	local role = UnitGroupRolesAssigned and AG:Readable(UnitGroupRolesAssigned("player"))
	if (not role or role == "NONE") and GetSpecialization and GetSpecializationRole then
		local spec = GetSpecialization()
		if spec then role = GetSpecializationRole(spec) end
	end
	return ROLE_KEYS[role]
end

local function firstSentence(text)
	if not text then return nil end
	return text:match("^(.-[%.!?])%s") or text
end

local function wishLine(itemIDs)
	if #itemIDs == 0 then return nil end
	local names = {}
	for i = 1, math.min(3, #itemIDs) do
		names[i] = UI.ItemInfo(itemIDs[i], function() end) or ("item " .. itemIDs[i])
	end
	local more = #itemIDs > 3 and string.format(" and %d more", #itemIDs - 3) or ""
	return string.format("%s |cffffd100Wishlist:|r %s%s", UI.STAR, table.concat(names, ", "), more)
end

-- Abilities worth a warning: deadly and important ones first, then any with a write-up.
local function watchFor(boss)
	local picked = {}
	for _, ab in ipairs(boss.abilities or {}) do
		for _, alert in ipairs(ab.alerts or {}) do
			if alert == "deadly" or alert == "important" then table.insert(picked, ab); break end
		end
	end
	for _, ab in ipairs(boss.abilities or {}) do
		if #picked >= WATCH_FOR then break end
		if ab.text and not tContains(picked, ab) then table.insert(picked, ab) end
	end
	local lines = {}
	for i = 1, math.min(WATCH_FOR, #picked) do
		local ab = picked[i]
		local alerts = UI.FormatAlerts(ab.alerts)
		lines[i] = string.format("|cffffd100%s|r%s%s", ab.name, alerts ~= "" and (" " .. alerts) or "",
			ab.text and (": " .. firstSentence(ab.text)) or "")
	end
	return lines
end

------------------------------------------------------------------------
-- The card frame
------------------------------------------------------------------------

local function savePosition(f)
	local point, _, relPoint, x, y = f:GetPoint(1)
	AG.db.options.cardPosition = { point = point, relPoint = relPoint, x = x, y = y }
end

local function place(f)
	f:ClearAllPoints()
	local pos = AG.db.options.cardPosition
	if pos then
		f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
	else
		f:SetPoint("TOP", UIParent, "TOP", 0, -140)
	end
end

local function create()
	local f = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
	UI.Backdrop(f, 0.92)
	f:SetWidth(WIDTH)
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePosition(self) end)

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(40, 40)
	f.icon:SetPoint("TOPLEFT", 12, -12)

	f.title = UI.Text(f, "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 10, -1)
	f.title:SetPoint("RIGHT", -28, 0)
	f.title:SetWordWrap(false)
	f.subtitle = UI.Text(f, "GameFontHighlightSmall")
	f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.subtitle:SetPoint("RIGHT", -12, 0)
	f.subtitle:SetTextColor(0.75, 0.75, 0.75)

	f.body = UI.Text(f, "GameFontHighlight")
	f.body:SetPoint("TOPLEFT", 12, -60)
	f.body:SetWidth(WIDTH - 24)
	f.body:SetSpacing(2)

	local close = UI.CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() f:Hide() end)

	f.open = UI.CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.open:SetSize(110, 22)
	f.open:SetPoint("BOTTOMLEFT", 10, 10)
	f.open:SetText("Open guide")
	f.open:SetScript("OnClick", function()
		AG:Open(f.instKey, f.bossKey)
		f:Hide()
	end)

	f.turnOff = CreateFrame("Button", nil, f)
	f.turnOff:SetSize(120, 18)
	f.turnOff:SetPoint("BOTTOMRIGHT", -12, 12)
	f.turnOff.text = UI.Text(f.turnOff, "GameFontDisableSmall", "RIGHT")
	f.turnOff.text:SetAllPoints()
	f.turnOff:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
	f.turnOff:SetScript("OnLeave", function(self) self.text:SetTextColor(0.5, 0.5, 0.5) end)
	f.turnOff:SetScript("OnClick", function()
		AG:SetOption(f.option, false)
		f:Hide()
		AG:Print("Turned off. You can turn it back on in |cffffd100/ag options|r.")
	end)

	-- Fade timer pauses while the mouse is on the card.
	f:SetScript("OnEnter", function(self) self.hovered = true end)
	f:SetScript("OnLeave", function(self) self.hovered = false end)
	f:Hide()
	return f
end

local function show(kind, opts)
	card = card or create()
	place(card)
	card.kind, card.option = kind, opts.option
	card.instKey, card.bossKey = opts.instKey, opts.bossKey
	if opts.portraitUnit then
		SetPortraitTexture(card.icon, opts.portraitUnit)
		card.icon:SetTexCoord(0, 1, 0, 1)
	else
		card.icon:SetTexture(opts.icon or "Interface\\Icons\\INV_Misc_Book_09")
		card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	card.title:SetText(opts.title)
	card.subtitle:SetText(opts.subtitle or "")
	card.turnOff.text:SetText(opts.turnOffText)
	card.turnOff.text:SetTextColor(0.5, 0.5, 0.5)
	local lines = {}
	for _, line in ipairs(opts.lines) do if line and line ~= "" then lines[#lines + 1] = line end end
	card.body:SetText(table.concat(lines, "\n"))
	card:SetHeight(60 + card.body:GetStringHeight() + 44)
	card:Show()

	hideToken = hideToken + 1
	if opts.seconds then
		local token = hideToken
		local function check()
			if token ~= hideToken or not card:IsShown() then return end
			if card.hovered then C_Timer.After(3, check) else card:Hide() end
		end
		C_Timer.After(opts.seconds, check)
	end
end

------------------------------------------------------------------------
-- Dungeon card (called by Journey.lua when you enter an instance)
------------------------------------------------------------------------

function AG:ShowZoneCard(instKey, visits)
	wipe(shownBosses) -- a new visit: boss cards may show again
	if not self:Option("zoneCard") then return end
	local inst = self:GetInstance(instKey)
	local guide = self.Guides[instKey] or {}
	local art = self.Art[instKey]
	local bosses = self:GetBossList(instKey)

	local subtitle = inst.isRaid and string.format("Raid, %d players", inst.players)
		or string.format("|cff%sLevels %d-%d|r", self:LevelColor(inst), inst.minLevel, inst.maxLevel)
	subtitle = subtitle .. (visits == 1 and "  |  First visit!" or string.format("  |  Visit #%d", visits))

	local tip = guide.tips and #guide.tips > 0 and guide.tips[math.random(#guide.tips)]
	show("zone", {
		option = "zoneCard", instKey = instKey,
		icon = art and art.icon, title = inst.name, subtitle = subtitle,
		turnOffText = "Turn off dungeon cards",
		seconds = ZONE_CARD_SECONDS,
		lines = {
			guide.route and firstSentence(guide.route),
			#bosses > 0 and string.format("|cffffd100Bosses:|r %d, starting with %s.", #bosses, bosses[1].name),
			tip and ("|cffffd100Tip:|r " .. tip),
			wishLine(self:WishesIn(instKey)),
		},
	})
end

------------------------------------------------------------------------
-- Boss card (when you target a boss)
------------------------------------------------------------------------

local function onTargetChanged()
	if card and card:IsShown() and card.kind == "boss" then card:Hide() end
	if not AG:Option("bossCard") then return end
	local instKey = AG:DetectInstance()
	if not instKey or not AG:Readable(UnitExists("target")) or AG:Readable(UnitIsDead("target")) then return end
	if AG:Readable(UnitPlayerControlled("target")) then return end
	local name = AG:Readable(UnitName("target"))
	if type(name) ~= "string" then return end
	local boss = AG:FindBoss(name, instKey)
	if not boss or shownBosses[boss.key] then return end
	shownBosses[boss.key] = true

	local inst = AG:GetInstance(instKey)
	local s = boss.strategy or {}
	local role = playerRole()
	local roleTip = role and s[role] and string.format("%s |cff%s%s:|r %s", UI.RoleIcon(role),
		UI.ROLES[role].color, UI.ROLES[role].label, s[role])
	local lines = { boss.overview, roleTip or s.summary }
	for _, line in ipairs(watchFor(boss)) do lines[#lines + 1] = line end
	lines[#lines + 1] = wishLine(AG:WishesIn(instKey, boss.key))

	show("boss", {
		option = "bossCard", instKey = instKey, bossKey = boss.key, portraitUnit = "target",
		title = boss.name, subtitle = inst.name, turnOffText = "Turn off boss cards", lines = lines,
	})
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
	if not AG.db then return end
	local ok, err = pcall(onTargetChanged)
	if not ok and AG.debug then AG:Print("Boss card error: %s", tostring(err)) end
end)
