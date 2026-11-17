-- A scrolling "document": the layout engine behind the instance overview and the boss
-- pages. Content is laid out top to bottom from typed blocks (headings, paragraphs,
-- images, bullet lists, role tips, rows). Frames are pooled per block type, so redraws
-- don't create new frames.
--
--   local doc = UI.CreateDocument(parent)
--   doc:Begin("page-key")          -- key decides when to reset the scroll position
--   doc:Heading("The story")
--   doc:Paragraph(text)
--   doc:Finish()

local _, AG = ...
local UI = AG.UI

local ICON = 30
local GAP = 6

-- Role icons from the Dungeon Finder role texture (64x64, three 19px icons).
local ROLE_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
UI.ROLES = {
	tank   = { label = "Tank",   color = "4499ff", coords = "0:19:22:41" },
	healer = { label = "Healer", color = "33dd66", coords = "20:39:1:20" },
	dps    = { label = "Damage", color = "ff6655", coords = "20:39:22:41" },
}

function UI.RoleIcon(role, size)
	local r = UI.ROLES[role]
	return string.format("|T%s:%d:%d:0:0:64:64:%s|t", ROLE_TEXTURE, size or 16, size or 16, r.coords)
end

------------------------------------------------------------------------
-- Redraws when item or spell data arrives (debounced; shared by all pages)
------------------------------------------------------------------------

local refreshQueued
function UI.QueueRefresh()
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0.2, function()
		refreshQueued = false
		if AG.frame and AG.frame:IsShown() then AG:Refresh() end
	end)
end

------------------------------------------------------------------------
-- Block frames
------------------------------------------------------------------------

local function createRow(owner)
	local row = CreateFrame("Button", nil, owner)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON, ICON)
	row.icon:SetPoint("TOPLEFT", 4, -4)
	row.title = UI.Text(row, "GameFontNormal")
	row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
	row.note = UI.Text(row, "GameFontHighlightSmall", "RIGHT")
	row.note:SetPoint("TOPRIGHT", -6, -2)
	row.title:SetPoint("RIGHT", row.note, "LEFT", -6, 0)
	row.body = UI.Text(row, "GameFontHighlightSmall")
	row.body:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
	row.body:SetPoint("RIGHT", -6, 0)
	row.body:SetTextColor(0.85, 0.82, 0.75)
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

	row:SetScript("OnEnter", function(self)
		if not self.itemID and not self.spellID then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.itemID then GameTooltip:SetItemByID(self.itemID) else GameTooltip:SetSpellByID(self.spellID) end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	row:SetScript("OnClick", function(self)
		if self.onClick then
			self.onClick()
		elseif self.link then
			-- Shift-click links the item in chat, Ctrl-click previews it, like Blizzard's loot lists.
			HandleModifiedItemClick(self.link)
		end
	end)
	return row
end

local function createHeading(owner)
	local fs = UI.Text(owner, "GameFontNormalLarge")
	fs.rule = owner:CreateTexture(nil, "ARTWORK")
	fs.rule:SetHeight(1)
	fs.rule:SetColorTexture(0.6, 0.48, 0.25, 0.6)
	local show, hide = fs.Show, fs.Hide
	fs.Show = function(self) show(self); self.rule:Show() end
	fs.Hide = function(self) hide(self); self.rule:Hide() end
	return fs
end

local function createParagraph(owner)
	return UI.Text(owner, "GameFontHighlight")
end

local function createImage(owner)
	local frame = CreateFrame("Frame", nil, owner, "BackdropTemplate")
	frame.tex = frame:CreateTexture(nil, "ARTWORK")
	frame.tex:SetPoint("TOPLEFT", 1, -1)
	frame.tex:SetPoint("BOTTOMRIGHT", -1, 1)
	frame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
	frame.shade = frame:CreateTexture(nil, "OVERLAY")
	frame.shade:SetPoint("BOTTOMLEFT", 1, 1)
	frame.shade:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.shade:SetHeight(46)
	frame.shade:SetTexture("Interface\\Buttons\\WHITE8x8")
	frame.shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0))
	frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	frame.caption:SetPoint("BOTTOMLEFT", 12, 10)
	frame.caption:SetShadowOffset(1, -1)
	return frame
end

------------------------------------------------------------------------
-- Document
------------------------------------------------------------------------

local Document = {}
Document.__index = Document

function UI.CreateDocument(parent)
	local scroll, child = UI.CreateScroll(parent)
	local doc = setmetatable({ scroll = scroll, child = child }, Document)
	return doc
end

function Document:Begin(key)
	self.y, self.width, self.key = 0, math.max(200, self.scroll:GetWidth() - 4), key
	self.used = { rows = 0, headings = 0, paragraphs = 0, images = 0 }
	return self
end

function Document:Take(pool, create)
	self.used[pool] = self.used[pool] + 1
	local f = UI.Acquire(self.child, pool, self.used[pool], create)
	f:ClearAllPoints()
	return f
end

function Document:Space(px)
	self.y = self.y + (px or GAP)
end

function Document:Heading(text)
	if self.y > 0 then self:Space(12) end
	local fs = self:Take("headings", createHeading)
	fs:SetPoint("TOPLEFT", 4, -self.y)
	fs:SetWidth(self.width - 8)
	fs:SetText(text)
	self.y = self.y + fs:GetStringHeight() + 3
	fs.rule:ClearAllPoints()
	fs.rule:SetPoint("TOPLEFT", self.child, "TOPLEFT", 4, -self.y)
	fs.rule:SetWidth(self.width - 8)
	self.y = self.y + 6
end

-- opts: font (font object name), color {r,g,b}, indent (px)
function Document:Paragraph(text, opts)
	if not text or text == "" then return end
	opts = opts or {}
	local fs = self:Take("paragraphs", createParagraph)
	fs:SetFontObject(opts.font or "GameFontHighlight")
	local c = opts.color or { 0.9, 0.86, 0.78 }
	fs:SetTextColor(c[1], c[2], c[3])
	local indent = opts.indent or 6
	fs:SetPoint("TOPLEFT", indent, -self.y)
	fs:SetWidth(self.width - indent - 6)
	fs:SetText(text)
	self.y = self.y + fs:GetStringHeight() + GAP
end

function Document:Bullets(items)
	for _, item in ipairs(items or {}) do
		self:Paragraph("|cffffd100-|r  " .. item, { indent = 12 })
	end
end

-- A strategy line for one role, with its icon and colored label.
function Document:RoleTip(role, text)
	if not text or text == "" then return end
	local r = UI.ROLES[role]
	self:Paragraph(string.format("%s |cff%s%s:|r %s", UI.RoleIcon(role), r.color, r.label, text), { indent = 10 })
end

-- A picture with an optional caption, cropped to the document's width.
function Document:Image(fileID, kind, height, caption)
	if not fileID then return end
	local img = self:Take("images", createImage)
	img:SetPoint("TOPLEFT", 2, -self.y)
	img:SetSize(self.width - 4, height)
	UI.SetArt(img.tex, fileID, kind, self.width - 6, height - 2)
	img.caption:SetText(caption or "")
	img.shade:SetShown(caption ~= nil)
	self.y = self.y + height + GAP + 4
end

-- A row: icon, title, body, and a right-hand note. opts: itemID, spellID, link, alpha, onClick.
function Document:Row(icon, title, body, note, opts)
	opts = opts or {}
	local row = self:Take("rows", createRow)
	row:SetPoint("TOPLEFT", 0, -self.y)
	row.itemID, row.spellID, row.link, row.onClick = opts.itemID, opts.spellID, opts.link, opts.onClick
	row:SetAlpha(opts.alpha or 1)
	row:SetWidth(self.width)
	row.icon:SetTexture(icon)
	row.icon:SetShown(icon ~= nil)
	row.icon:SetWidth(icon and ICON or 1) -- no icon: text starts at the left edge
	row.title:SetText(title or "")
	row.body:SetText(body or "")
	row.note:SetText(note or "")
	local h = row.title:GetStringHeight() + 3 + (body and body ~= "" and row.body:GetStringHeight() or 0) + 10
	if icon then h = math.max(h, ICON + 10) end
	row:SetHeight(h)
	self.y = self.y + h + 2
end

function Document:Finish()
	for pool, n in pairs(self.used) do UI.HideFrom(self.child, pool, n + 1) end
	self.child:SetHeight(math.max(1, self.y))
	-- Jump to the top only when the page changed, not when item data trickles in.
	if self.shownKey ~= self.key then
		self.scroll:SetVerticalScroll(0)
		self.shownKey = self.key
	end
end

function Document:SetShown(shown)
	self.scroll:SetShown(shown)
end
