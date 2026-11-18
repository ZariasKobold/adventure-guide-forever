-- Wishlist: items you're hoping for. Star them on any boss's loot; the dungeon cards show
-- how many are inside, the Wishlist tab lists them, and you get an alert when one drops.
-- Saved per account in AdventureGuideForeverDB.wishlist ([itemID] = true).

local _, AG = ...

local ALERT_COOLDOWN = 60 -- seconds before the same item can alert again

function AG:IsWished(itemID)
	return self.db ~= nil and itemID ~= nil and self.db.wishlist[itemID] == true
end

function AG:ToggleWish(itemID)
	if not itemID then return end
	local on = not self:IsWished(itemID)
	self.db.wishlist[itemID] = on or nil
	PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	if self.frame and self.frame:IsShown() then self:Refresh() end
end

-- Every wished item, with where it drops: { { itemID, sources = {...} } }.
function AG:GetWishlist()
	local out = {}
	for itemID in pairs(self.db.wishlist) do
		table.insert(out, { itemID = itemID, sources = self:ItemSources(itemID) })
	end
	table.sort(out, function(a, b) return a.itemID < b.itemID end)
	return out
end

-- Wished items that drop in one instance (or from one boss there).
function AG:WishesIn(instKey, bossKey)
	local out = {}
	for itemID in pairs(self.db and self.db.wishlist or {}) do
		for _, s in ipairs(self:ItemSources(itemID)) do
			if s.instKey == instKey and (not bossKey or s.bossKey == bossKey) then
				table.insert(out, itemID)
				break
			end
		end
	end
	table.sort(out)
	return out
end

------------------------------------------------------------------------
-- "It dropped!" alerts
------------------------------------------------------------------------

local lastAlert = {}

local function alert(itemID, who)
	if not AG:Option("wishAlerts") or not AG:IsWished(itemID) then return end
	local now = GetTime()
	if lastAlert[itemID] and now - lastAlert[itemID] < ALERT_COOLDOWN then return end
	lastAlert[itemID] = now
	local link = select(2, C_Item.GetItemInfo(itemID)) or ("item " .. itemID)
	local msg = string.format("%s Wishlist item dropped: %s%s", AG.UI.STAR, link,
		who and (" (looted by " .. who .. ")") or "")
	if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
		RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo.RAID_WARNING)
	end
	PlaySound(SOUNDKIT.RAID_WARNING)
	AG:Print(msg)
end

local handlers = {
	LOOT_OPENED = function()
		for slot = 1, GetNumLootItems() do
			local link = GetLootSlotLink(slot)
			if AG:IsUsable(link) and link then alert(C_Item.GetItemInfoInstant(link)) end
		end
	end,
	-- Boss loot handed out to the group (personal loot): tells you who got it.
	ENCOUNTER_LOOT_RECEIVED = function(_, itemID, _, _, playerName)
		if AG:IsUsable(itemID) then alert(itemID, AG:Readable(playerName)) end
	end,
}

local events = CreateFrame("Frame")
for event in pairs(handlers) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, ...)
	if not AG.db then return end
	local ok, err = pcall(handlers[event], ...)
	if not ok and AG.debug then AG:Print("Wishlist error in %s: %s", event, tostring(err)) end
end)
