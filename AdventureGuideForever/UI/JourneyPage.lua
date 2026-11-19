-- The Journey tab: your visit log (Journey.lua), for this character or all of them together.
-- Distance traveled is in its own addon now, Adventure Forever Pedometer; this page points
-- to it.

local _, AG = ...

local TOP_ZONES = 15
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_Map_01"

local showAll = false

local function ago(stamp)
	if not stamp or stamp == 0 then return "never" end
	local secs = time() - stamp
	if secs < 3600 then return "just now" end
	if secs < 86400 then return string.format("%d hours ago", math.floor(secs / 3600)) end
	local days = math.floor(secs / 86400)
	return days == 1 and "yesterday" or string.format("%d days ago", days)
end

local function bossKills(instKey)
	local total = 0
	local learned = AG.db.learned[instKey]
	for _, rec in pairs(learned and learned.bosses or {}) do total = total + (rec.kills or 0) end
	return total
end

local function sortedVisits(list)
	local out = {}
	for key, v in pairs(list or {}) do out[#out + 1] = { key = key, visits = v.visits or 0, last = v.last } end
	table.sort(out, function(a, b)
		if a.visits ~= b.visits then return a.visits > b.visits end
		return tostring(a.key) < tostring(b.key)
	end)
	return out
end

local function characterCount()
	local n = 0
	for _ in pairs(AG.db.journey) do n = n + 1 end
	return n
end

function AG:RenderJourney(doc)
	self.frame.header:SetText("Your journey")
	local rec = showAll and self:GetJourneyTotals() or self:GetJourney()
	if not rec then
		doc:Paragraph("Your journey starts once you're logged in.")
		return
	end

	-- Switch between this character and everyone.
	local others = characterCount()
	if others > 1 then
		doc:Row(nil, showAll and "|cffffd100All characters|r  (click for this character only)"
			or "|cffffd100This character|r  (click to add up all characters)", nil, nil, {
			onClick = function()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				showAll = not showAll
				AG:Refresh()
			end,
		})
	end

	-- Distance traveled lives in Adventure Forever Pedometer.
	if self:HasPedometer() then
		doc:Paragraph("Your distance traveled and steps are in |cffffd100Adventure Forever Pedometer|r: type "
			.. "|cffffd100/pedometer|r or click the step counter by the minimap.", { color = { 0.75, 0.75, 0.75 } })
	else
		doc:Paragraph("Looking for distance traveled and steps? The pedometer is its own addon now, "
			.. "|cffffd100Adventure Forever Pedometer|r. Install it and it brings over everything counted so far.",
			{ color = { 0.75, 0.75, 0.75 } })
	end

	-- Dungeons and raids
	local visited = sortedVisits(rec.instances)
	doc:Heading(string.format("Dungeons and raids  |cff888888(%d of %d visited)|r", #visited, #self.Instances))
	if #visited == 0 then
		doc:Paragraph("No dungeons yet. Every time you step inside one, it's counted here.", { color = { 0.6, 0.6, 0.6 } })
	end
	for _, v in ipairs(visited) do
		local inst = self:GetInstance(v.key)
		if inst then
			local art = self.Art[v.key]
			local kills = bossKills(v.key)
			local body = "Last visit: " .. ago(v.last)
			if kills > 0 then body = body .. string.format("    Boss kills recorded: %d", kills) end
			doc:Row(art and art.icon or DEFAULT_ICON, inst.name, body,
				string.format("|cffffd100%d|r visit%s", v.visits, v.visits == 1 and "" or "s"), {
				onClick = function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					AG:ShowInstance(v.key)
				end,
			})
		end
	end

	-- Zones
	local zones = sortedVisits(rec.zones)
	doc:Heading(string.format("Zones  |cff888888(%d explored)|r", #zones))
	if #zones == 0 then
		doc:Paragraph("No zones yet. Each time you travel into a zone, it's counted here.", { color = { 0.6, 0.6, 0.6 } })
	end
	for i = 1, math.min(TOP_ZONES, #zones) do
		local z = zones[i]
		doc:Row(nil, z.key, nil, string.format("|cffffd100%d|r visit%s  |cff888888%s|r",
			z.visits, z.visits == 1 and "" or "s", ago(z.last)))
	end
	if #zones > TOP_ZONES then
		doc:Paragraph(string.format("...and %d more.", #zones - TOP_ZONES), { color = { 0.6, 0.6, 0.6 } })
	end

	-- Everyone, in the all-characters view.
	if showAll then
		doc:Heading("Characters")
		local chars = {}
		for key, r in pairs(self.db.journey) do
			local visits = 0
			for _, v in pairs(r.instances or {}) do visits = visits + (v.visits or 0) end
			chars[#chars + 1] = { name = r.name or key, visits = visits }
		end
		table.sort(chars, function(a, b) return a.visits > b.visits end)
		for _, c in ipairs(chars) do
			doc:Row(nil, c.name, nil, string.format("|cffffd100%d|r dungeon visit%s", c.visits, c.visits == 1 and "" or "s"))
		end
	end

	doc:Paragraph(" ")
	doc:Paragraph("Journey stats stay on your computer. They're never shared with your group or the guide.",
		{ font = "GameFontHighlightSmall", color = { 0.5, 0.5, 0.5 } })
end
