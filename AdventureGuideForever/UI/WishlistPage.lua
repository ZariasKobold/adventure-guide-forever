-- The Wishlist tab: every starred item, where it drops, and whether you have it yet.

local _, AG = ...
local UI = AG.UI

local QUALITY_COLOR = { [0] = "9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000" }

local function sourceText(s)
	local inst = AG:GetInstance(s.instKey)
	local where = string.format("%s, %s", s.bossName, inst and inst.name or s.instKey)
	if s.dropChance then where = where .. string.format("  |cffcccccc%.0f%%|r", s.dropChance) end
	return where
end

function AG:RenderWishlist(doc)
	self.frame.header:SetText(UI.STAR .. " Wishlist")
	local list = self:GetWishlist()

	if #list == 0 then
		doc:Heading("Nothing on your wishlist yet")
		doc:Paragraph("Click the star next to any item on a boss's loot to add it here. Then:")
		doc:Bullets({
			"Dungeon cards show how many wishlist items are inside.",
			"You get an alert when one drops.",
			"Item tooltips everywhere say it's on your wishlist.",
		})
		return
	end

	doc:Heading(string.format("%d item%s", #list, #list == 1 and "" or "s"))
	-- Items sorted by where they drop, so a dungeon's items sit together.
	table.sort(list, function(a, b)
		local sa, sb = a.sources[1], b.sources[1]
		local ka = sa and (sa.instKey .. sa.bossName) or "~"
		local kb = sb and (sb.instKey .. sb.bossName) or "~"
		if ka ~= kb then return ka < kb end
		return a.itemID < b.itemID
	end)

	for _, entry in ipairs(list) do
		local name, link, quality, icon = UI.ItemInfo(entry.itemID, UI.QueueRefresh)
		local title = string.format("|cff%s%s|r", QUALITY_COLOR[quality or 1] or "ffffff", name or ("Item " .. entry.itemID))
		local lines = {}
		for i = 1, math.min(3, #entry.sources) do lines[i] = sourceText(entry.sources[i]) end
		if #entry.sources == 0 then lines[1] = "|cff888888Where it drops isn't known yet.|r" end
		local owned = C_Item.GetItemCount and C_Item.GetItemCount(entry.itemID, true) or 0
		local note = owned > 0 and "|cff20ff20You have it!|r" or nil
		local first = entry.sources[1]
		doc:Row(icon or UI.UNKNOWN_ICON, title, table.concat(lines, "\n"), note, {
			itemID = entry.itemID, link = link, star = true,
			onClick = first and function()
				if IsModifiedClick() and link then HandleModifiedItemClick(link); return end
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				AG.view.section = 3 -- the Loot section
				AG:ShowInstance(first.instKey, first.bossKey)
			end or nil,
		})
	end
	doc:Paragraph("Click an item to open its boss. Click the star to take it off your wishlist.",
		{ font = "GameFontHighlightSmall", color = { 0.55, 0.55, 0.55 } })
end
