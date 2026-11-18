-- "Drops from" on item tooltips: hover any item anywhere (bags, chat links, the auction
-- house, a friend's gear) to see which bosses drop it and how often, and whether it's on
-- your wishlist. Uses the item index built in Data\Registry.lua.

local _, AG = ...
local UI = AG.UI

local MAX_SOURCES = 3

local function addLines(tooltip, itemID)
	if not AG.db or not AG:Option("tooltips") or type(itemID) ~= "number" then return end
	local sources = AG:ItemSources(itemID)
	local wished = AG:IsWished(itemID)
	if #sources == 0 and not wished then return end

	tooltip:AddLine(" ")
	if #sources > 0 then
		local anyQuest = false
		for _, s in ipairs(sources) do anyQuest = anyQuest or s.questID ~= nil end
		tooltip:AddLine(anyQuest and "Where to get it:" or "Drops from:", 0.4, 0.8, 1)
		for i = 1, math.min(MAX_SOURCES, #sources) do
			local s = sources[i]
			local inst = AG:GetInstance(s.instKey)
			local chance = s.questID and "quest reward"
				or s.dropChance and string.format(s.dropChance >= 10 and "%.0f%%" or "%.1f%%", s.dropChance) or ""
			tooltip:AddDoubleLine(string.format("%s, %s", s.bossName, inst and inst.name or s.instKey), chance,
				1, 0.82, 0, 0.8, 0.8, 0.8)
		end
		if #sources > MAX_SOURCES then
			tooltip:AddLine(string.format("...and %d more", #sources - MAX_SOURCES), 0.6, 0.6, 0.6)
		end
	end
	if wished then tooltip:AddLine(UI.STAR .. " On your wishlist", 1, 0.82, 0) end
	tooltip:Show() -- resize to fit the new lines
end

-- Modern clients hand every item tooltip to TooltipDataProcessor; older ones fire
-- OnTooltipSetItem. Use whichever exists.
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if not data then return end
		local ok, err = pcall(addLines, tooltip, AG:Readable(data.id))
		if not ok and AG.debug then AG:Print("Tooltip error: %s", tostring(err)) end
	end)
elseif GameTooltip and GameTooltip.HookScript then
	local function onSetItem(tooltip)
		local _, link = tooltip:GetItem()
		if AG:IsUsable(link) and link then pcall(addLines, tooltip, C_Item.GetItemInfoInstant(link)) end
	end
	for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
		if tip then tip:HookScript("OnTooltipSetItem", onSetItem) end
	end
end
