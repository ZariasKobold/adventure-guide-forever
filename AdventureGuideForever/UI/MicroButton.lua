-- Our own Adventure Guide button on the menu bar (the micro menu).
-- Forever keeps Blizzard's EJMicroButton but leaves it off the bar, so we add a button of
-- our own, styled like its neighbours, right after the Collections button. It opens the
-- guide, shows a tooltip with the keybind, and looks pressed while the guide is open.

local _, AG = ...

-- Blizzard's micro menu art (Dragonflight and later). Each is checked before use.
local ATLAS = {
	normal    = "UI-HUD-MicroMenu-AdventureGuide-Up",
	pushed    = "UI-HUD-MicroMenu-AdventureGuide-Down",
	highlight = "UI-HUD-MicroMenu-AdventureGuide-Mouseover",
	disabled  = "UI-HUD-MicroMenu-AdventureGuide-Disabled",
}
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Book_09"

local function atlasExists(name)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function title()
	return ADVENTURE_JOURNAL or "Adventure Guide"
end

local function keyText()
	local key = GetBindingKey("TOGGLEENCOUNTERJOURNAL") or "SHIFT-J"
	return GetBindingText and GetBindingText(key) or key
end

local function showTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(string.format("%s %s(%s)|r", title(), NORMAL_FONT_COLOR_CODE or "", keyText()), 1, 1, 1)
	GameTooltip:AddLine("Dungeon and raid journal: bosses, strategy, and loot.", nil, nil, nil, true)
	GameTooltip:Show()
end

-- Forever's bar uses the older micro button art: each button is one picture with its frame
-- baked in. Texture:SetTexture accepts missing files, so only a file ID proves a file exists.
local probe = UIParent:CreateTexture()
local function fileExists(path)
	probe:SetTexture(nil)
	probe:SetTexture(path)
	local id = probe:GetTextureFileID()
	return type(id) == "number" and id > 0
end

local LEGACY_EJ = "Interface\\Buttons\\UI-MicroButton-EJ-"

-- A texture's look: its atlas, or its file and tex coords.
local function look(tex)
	if not tex then return nil end
	local atlas = tex.GetAtlas and tex:GetAtlas()
	if atlas and atlasExists(atlas) then return { atlas = atlas } end
	local file = tex:GetTextureFileID() or tex:GetTexture()
	if not file then return nil end
	return { file = file, coords = { tex:GetTexCoord() }, blend = tex:GetBlendMode() }
end

local function apply(tex, l)
	if l.atlas then
		tex:SetAtlas(l.atlas)
	else
		tex:SetTexture(l.file)
		if l.coords and #l.coords == 8 then tex:SetTexCoord(unpack(l.coords)) end
	end
end

local function setState(button, state, l)
	if not l then return end
	local setter = button["Set" .. state .. "Texture"]
	setter(button, l.atlas and "Interface\\Buttons\\WHITE8x8" or l.file)
	apply(button["Get" .. state .. "Texture"](button), l)
	if state == "Highlight" then button:GetHighlightTexture():SetBlendMode(l.blend or "ADD") end
end

local function copyButton(button, source)
	setState(button, "Normal", look(source:GetNormalTexture()))
	setState(button, "Pushed", look(source:GetPushedTexture()))
	setState(button, "Disabled", look(source:GetDisabledTexture()))
end

-- Dragonflight-style micro buttons draw their frame as two textures, Background and
-- PushedBackground. Copy them from a neighbour (same layer, size, and anchors), or fall
-- back to Blizzard's atlases by name.
local BACKGROUNDS = {
	Background = "UI-HUD-MicroMenu-ButtonBG-Up",
	PushedBackground = "UI-HUD-MicroMenu-ButtonBG-Down",
}

local function copyRegion(button, source, region, layer)
	local tex = button:CreateTexture(nil, layer or "BACKGROUND")
	if region then
		local l = look(region)
		if l then apply(tex, l) end
		tex:SetDrawLayer(region:GetDrawLayer())
		tex:SetSize(region:GetSize())
		for i = 1, region:GetNumPoints() do
			local point, rel, relPoint, x, y = region:GetPoint(i)
			tex:SetPoint(point, rel == source and button or rel, relPoint, x, y)
		end
		if tex:GetNumPoints() == 0 then tex:SetAllPoints() end
	end
	return tex
end

local function addBackgrounds(button, neighbour)
	for key, atlas in pairs(BACKGROUNDS) do
		local region = neighbour and neighbour[key]
		local tex
		if region and region.GetTexture then
			tex = copyRegion(button, neighbour, region)
		elseif atlasExists(atlas) then
			tex = button:CreateTexture(nil, "BACKGROUND")
			tex:SetAtlas(atlas)
			tex:SetAllPoints()
		end
		button[key] = tex
	end
	if not button.Background then return end
	if button.PushedBackground then button.PushedBackground:Hide() end
	-- Swap backgrounds while pressed, as Blizzard's buttons do.
	local function pressed(down)
		button.Background:SetShown(not down)
		if button.PushedBackground then button.PushedBackground:SetShown(down) end
	end
	button.SetPressedLook = function(_, down) pressed(down) end
	button:HookScript("OnMouseDown", function() pressed(true) end)
	button:HookScript("OnMouseUp", function() pressed(AG.frame and AG.frame:IsShown() or false) end)
end

-- Which picture to use, best first. AG.microStyle records the choice (/ag micro).
local function paint(button)
	local neighbour = CollectionsMicroButton or CharacterMicroButton
	local highlight = neighbour and look(neighbour:GetHighlightTexture())

	-- 1. Blizzard's Dragonflight-style Adventure Guide art. Those icons sit on a separate
	--    button background (the dark rounded frame), which we borrow from a neighbour.
	if atlasExists(ATLAS.normal) then
		button:SetNormalAtlas(ATLAS.normal)
		button:SetPushedAtlas(atlasExists(ATLAS.pushed) and ATLAS.pushed or ATLAS.normal)
		button:SetDisabledAtlas(atlasExists(ATLAS.disabled) and ATLAS.disabled or ATLAS.normal)
		if highlight then
			setState(button, "Highlight", highlight)
		elseif atlasExists(ATLAS.highlight) then
			button:SetHighlightAtlas(ATLAS.highlight, "ADD")
		end
		addBackgrounds(button, neighbour)
		AG.microStyle = "atlas" .. (button.Background and " + frame" or "")
		return
	end

	-- 2. Whatever Blizzard's own (hidden) Adventure Guide button wears, if it's real art.
	local ej = EJMicroButton and look(EJMicroButton:GetNormalTexture())
	if ej and (ej.atlas or (type(ej.file) == "number" and ej.file > 0)) then
		copyButton(button, EJMicroButton)
		setState(button, "Highlight", look(EJMicroButton:GetHighlightTexture()) or highlight)
		AG.microStyle = "EJMicroButton"
		return
	end

	-- 3. The older Adventure Guide micro button files, cut like their neighbours.
	if fileExists(LEGACY_EJ .. "Up") then
		local coords = neighbour and { neighbour:GetNormalTexture():GetTexCoord() }
		for state, suffix in pairs({ Normal = "Up", Pushed = "Down", Disabled = "Disabled" }) do
			local file = fileExists(LEGACY_EJ .. suffix) and LEGACY_EJ .. suffix or LEGACY_EJ .. "Up"
			setState(button, state, { file = file, coords = coords })
		end
		setState(button, "Highlight", highlight)
		AG.microStyle = "legacy EJ"
		return
	end

	-- 4. The Character button's empty frame with a book where its portrait sits.
	if CharacterMicroButton then
		copyButton(button, CharacterMicroButton)
		setState(button, "Highlight", highlight)
		local icon = button:CreateTexture(nil, "OVERLAY")
		icon:SetTexture(FALLBACK_ICON)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		local portrait = MicroButtonPortrait
		if portrait and portrait:GetNumPoints() > 0 then
			icon:SetSize(portrait:GetSize())
			for i = 1, portrait:GetNumPoints() do
				local point, rel, relPoint, x, y = portrait:GetPoint(i)
				icon:SetPoint(point, rel == CharacterMicroButton and button or rel, relPoint, x, y)
			end
		else
			icon:SetPoint("CENTER")
			icon:SetSize(button:GetWidth() * 0.62, button:GetWidth() * 0.62)
		end
		button.icon = icon
		button:HookScript("OnMouseDown", function() icon:SetVertexColor(0.6, 0.6, 0.6) end)
		button:HookScript("OnMouseUp", function() icon:SetVertexColor(1, 1, 1) end)
		AG.microStyle = "character frame + book"
		return
	end

	-- 5. Just the book.
	button:SetNormalTexture(FALLBACK_ICON)
	button:SetPushedTexture(FALLBACK_ICON)
	button:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	AG.microStyle = "book icon"
end

-- The visible micro menu button furthest to the right (fallback anchor).
local function rightmostSibling(menu, except)
	local best, bestRight
	for _, child in ipairs({ menu:GetChildren() }) do
		if child ~= except and child:IsShown() and child:IsObjectType("Button") then
			local right = child:GetRight()
			if right and (not bestRight or right > bestRight) then best, bestRight = child, right end
		end
	end
	return best
end

local function place(button, menu)
	local after = CollectionsMicroButton
	if menu.Layout and after and after.layoutIndex then
		-- Join the bar's own layout, right after Collections.
		button.layoutIndex = after.layoutIndex + 0.5
		menu:Layout()
		if button:GetNumPoints() > 0 then return end
	end
	local anchor = after and after:IsShown() and after or rightmostSibling(menu, button)
	button:ClearAllPoints()
	if anchor then
		button:SetPoint("LEFT", anchor, "RIGHT", 1, 0)
	else
		button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -320, 4)
	end
end

function AG:CreateMicroButton()
	if self.microButton then return end
	local menu = MicroMenu
	if not menu then return end

	local button = CreateFrame("Button", nil, menu)
	local model = CollectionsMicroButton or CharacterMicroButton
	local w, h = 32, 40
	if model then w, h = model:GetSize() end
	button:SetSize(w, h)
	paint(button)

	button:RegisterForClicks("AnyUp")
	button:SetScript("OnClick", function() AG:Toggle() end)
	button:SetScript("OnEnter", showTooltip)
	button:SetScript("OnLeave", GameTooltip_Hide)

	self.microButton = button
	place(button, menu)
	self:UpdateMicroButton()
end

-- Pressed while the guide is open, like Blizzard's own micro buttons.
function AG:UpdateMicroButton()
	local open = self.frame and self.frame:IsShown()
	local button = self.microButton
	if not button then return end
	button:SetButtonState(open and "PUSHED" or "NORMAL", open)
	if button.SetPressedLook then button:SetPressedLook(open or false) end
end
