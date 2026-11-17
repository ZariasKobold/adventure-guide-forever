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

local function paint(button)
	if atlasExists(ATLAS.normal) then
		button:SetNormalAtlas(ATLAS.normal)
		button:SetPushedAtlas(atlasExists(ATLAS.pushed) and ATLAS.pushed or ATLAS.normal)
		button:SetDisabledAtlas(atlasExists(ATLAS.disabled) and ATLAS.disabled or ATLAS.normal)
		if atlasExists(ATLAS.highlight) then
			button:SetHighlightAtlas(ATLAS.highlight, "ADD")
		else
			button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		end
	else
		-- No micro menu art: a framed book icon, sized to the bar.
		button:SetNormalTexture(FALLBACK_ICON)
		button:SetPushedTexture(FALLBACK_ICON)
		button:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
		button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		for _, tex in ipairs({ button:GetNormalTexture(), button:GetPushedTexture() }) do
			tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end
	end
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
	if button then button:SetButtonState(open and "PUSHED" or "NORMAL", open) end
end
