-- Shared UI helpers: safe template creation, scroll areas, row pools, alert tags,
-- and item/spell lookups that cope with data the client hasn't cached yet.

local _, AG = ...

AG.UI = AG.UI or {}
local UI = AG.UI

-- Some Blizzard templates may not exist in Forever. Try each, fall back to a plain frame.
function UI.CreateFrame(frameType, name, parent, ...)
	for i = 1, select("#", ...) do
		local template = select(i, ...)
		local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
		if ok and frame then return frame, template end
	end
	return CreateFrame(frameType, name, parent)
end

function UI.Backdrop(frame, alpha)
	if not frame.SetBackdrop then
		-- Same as inheriting BackdropTemplate: mix in, then keep the border sized.
		Mixin(frame, BackdropTemplateMixin)
		frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged)
	end
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0.06, 0.05, 0.04, alpha or 0.9)
	frame:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
end

-- A vertical scroll area. Returns scrollFrame, child. Set child height after filling it.
function UI.CreateScroll(parent)
	local scroll = UI.CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate", "UIPanelScrollFrameTemplate")
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(1, 1)
	scroll:SetScrollChild(child)
	scroll:HookScript("OnSizeChanged", function(_, w) child:SetWidth(w) end)
	scroll:EnableMouseWheel(true)
	return scroll, child
end

-- Row pools: reuse frames by index so redraws don't leak frames.
function UI.Acquire(owner, poolName, index, create)
	owner[poolName] = owner[poolName] or {}
	local pool = owner[poolName]
	if not pool[index] then pool[index] = create(owner) end
	pool[index]:Show()
	return pool[index]
end

function UI.HideFrom(owner, poolName, firstUnused)
	local pool = owner[poolName]
	if not pool then return end
	for i = firstUnused, #pool do pool[i]:Hide() end
end

function UI.Text(parent, font, justify)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
	fs:SetJustifyH(justify or "LEFT")
	fs:SetJustifyV("TOP")
	fs:SetWordWrap(true)
	return fs
end

------------------------------------------------------------------------
-- Alert tags, styled after the Adventure Guide's ability icons
------------------------------------------------------------------------

UI.ALERTS = {
	tank      = { "Tank",          "4499ff" },
	healer    = { "Healer",        "33dd66" },
	dps       = { "Damage",        "ff6655" },
	deadly    = { "Deadly",        "ff2222" },
	important = { "Important",     "ffcc00" },
	interrupt = { "Interruptible", "aaaaff" },
	magic     = { "Magic",         "3388ff" },
	curse     = { "Curse",         "bb55ff" },
	poison    = { "Poison",        "33cc33" },
	disease   = { "Disease",       "cc9955" },
	enrage    = { "Enrage",        "ff7700" },
}

function UI.FormatAlerts(alerts)
	if not alerts or #alerts == 0 then return "" end
	local parts = {}
	for _, key in ipairs(alerts) do
		local a = UI.ALERTS[key]
		if a then table.insert(parts, string.format("|cff%s[%s]|r", a[2], a[1])) end
	end
	return table.concat(parts, " ")
end

------------------------------------------------------------------------
-- Instance artwork
------------------------------------------------------------------------

-- Where the picture sits inside each kind of art file, and the file's pixel size.
-- button: retail journal buttons are 256x128 files with a 175x95 picture in the corner.
-- lore/finder: assumed to fill their files; adjust here if they look cropped in game.
local ART_SOURCES = {
	button  = { w = 256,  h = 128, l = 0, r = 175 / 256, t = 0, b = 95 / 128 },
	loading = { w = 1024, h = 768, l = 0, r = 1, t = 0, b = 1 },
	lore    = { w = 512,  h = 256, l = 0, r = 1, t = 0, b = 1 },
	finder  = { w = 512,  h = 256, l = 0, r = 1, t = 0, b = 1 },
	-- Bundled art (Art\*.tga): a ~1600x613 picture stretched into a 1024x512 texture.
	image   = { w = 1600, h = 613, l = 0, r = 1, t = 0, b = 1 },
	-- Small square icons: trim the edge so a stretched icon has no border lines.
	icon    = { w = 64,   h = 64,  l = 0.08, r = 0.92, t = 0.08, b = 0.92 },
}

-- Shows an art file in a texture, center-cropped to fill the texture's shape (no stretching).
function UI.SetArt(texture, fileID, kind, width, height)
	local src = ART_SOURCES[kind] or ART_SOURCES.loading
	local l, r, t, b = src.l, src.r, src.t, src.b
	local srcAspect = ((r - l) * src.w) / ((b - t) * src.h)
	local targetAspect = width / height
	if srcAspect > targetAspect then
		local keep = (r - l) * targetAspect / srcAspect
		local trim = ((r - l) - keep) / 2
		l, r = l + trim, r - trim
	else
		local keep = (b - t) * srcAspect / targetAspect
		local trim = ((b - t) - keep) / 2
		t, b = t + trim, b - trim
	end
	texture:SetTexture(fileID)
	texture:SetTexCoord(l, r, t, b)
end

------------------------------------------------------------------------
-- Items and spells
------------------------------------------------------------------------

UI.UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Item and spell data arrive from the server on demand: lookups return nil until the
-- client has cached them. We request each missing ID once and run the waiting callbacks
-- when ITEM_DATA_LOAD_RESULT / SPELL_DATA_LOAD_RESULT reports it loaded.
local pending = { item = {}, spell = {} }

local function requestLoad(kind, id, onLoad)
	local waiting = pending[kind][id]
	if waiting then
		if onLoad then waiting[onLoad] = true end
		return -- already requested
	end
	pending[kind][id] = onLoad and { [onLoad] = true } or {}
	if kind == "item" then
		C_Item.RequestLoadItemDataByID(id)
	else
		C_Spell.RequestLoadSpellData(id)
	end
end

local loadEvents = CreateFrame("Frame")
loadEvents:RegisterEvent("ITEM_DATA_LOAD_RESULT")
loadEvents:RegisterEvent("SPELL_DATA_LOAD_RESULT")
loadEvents:SetScript("OnEvent", function(_, event, id)
	local kind = event == "ITEM_DATA_LOAD_RESULT" and "item" or "spell"
	local waiting = pending[kind][id]
	if not waiting then return end
	pending[kind][id] = nil
	for callback in pairs(waiting) do callback() end
end)

-- Returns name, link, quality, icon for an item, or just the icon if not cached yet.
-- onLoad (optional) runs once the item's data arrives.
function UI.ItemInfo(itemID, onLoad)
	if not itemID then return nil end
	local name, link, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
	if name then return name, link, quality, icon end
	requestLoad("item", itemID, onLoad)
	return nil, nil, nil, C_Item.GetItemIconByID(itemID)
end

-- Returns name, icon, description for a spell, or nil if not cached yet.
-- onLoad (optional) runs once the spell's data arrives.
function UI.SpellInfo(spellID, onLoad)
	if not spellID then return nil end
	local info = C_Spell.GetSpellInfo(spellID)
	if not info then
		requestLoad("spell", spellID, onLoad)
		return nil
	end
	return info.name, info.iconID, C_Spell.GetSpellDescription(spellID) or ""
end

------------------------------------------------------------------------
-- Wishlist star and checkboxes
------------------------------------------------------------------------

-- The raid marker star: in every client, and instantly recognisable.
UI.STAR_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
UI.STAR = "|T" .. UI.STAR_TEXTURE .. ":0|t"

-- Shows a star texture lit (on the wishlist) or dimmed grey (not on it).
function UI.SetStar(texture, on)
	texture:SetTexture(UI.STAR_TEXTURE)
	texture:SetDesaturated(not on)
	texture:SetAlpha(on and 1 or 0.45)
end

-- A labelled checkbox. get() returns the current value; set(value) stores a new one.
-- An item name in its quality color (grey, white, green, blue, purple, orange).
local QUALITY_HEX = { [0] = "9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000", "e6cc80" }
function UI.QualityText(name, quality)
	local hex = QUALITY_HEX[quality or 1] or "ffffff"
	return string.format("|cff%s%s|r", hex, name or "?")
end

-- 12345 -> "12,345".
function UI.Commas(n)
	local s = tostring(math.floor(n or 0))
	while true do
		local out, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = out
		if k == 0 then return s end
	end
end

UI.YARDS_PER_MILE = 1760

-- A distance for people: "84 yards", "2.35 miles", "31.0 miles".
function UI.Distance(yards)
	local m = (yards or 0) / UI.YARDS_PER_MILE
	if m < 0.1 then return string.format("%d yards", math.floor(yards or 0)) end
	return string.format(m < 10 and "%.2f miles" or "%.1f miles", m)
end

function UI.CheckBox(parent, label, get, set)
	local box = UI.CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate", "OptionsBaseCheckButtonTemplate")
	box:SetSize(24, 24)
	if not box:GetNormalTexture() then
		box:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		box:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
		box:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
		box:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	end
	box.label = UI.Text(box, "GameFontHighlight")
	box.label:SetPoint("LEFT", box, "RIGHT", 4, 0)
	box.label:SetWordWrap(false)
	box.label:SetText(label)
	box:SetScript("OnClick", function(self)
		PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		set(self:GetChecked() and true or false)
	end)
	box.Sync = function(self) self:SetChecked(get() and true or false) end
	return box
end
