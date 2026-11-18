-- Search: find dungeons, bosses, items, quests, and boss abilities by name. The index is
-- built from the guide (AG.Guides, AG.Quests) the first time you search, and rebuilt when
-- the guide data changes. UI\SearchPage.lua shows the results.

local _, AG = ...

local MAX_PER_KIND = 25
AG.SEARCH_KINDS = {
	{ key = "instance", label = "Dungeons and raids" },
	{ key = "boss",     label = "Bosses" },
	{ key = "item",     label = "Items" },
	{ key = "quest",    label = "Quests" },
	{ key = "ability",  label = "Abilities" },
}

local index

-- Lowercase, with punctuation removed, so "Zul'Farrak" matches "zulfarrak" and "zul farrak".
local function fold(text)
	return (tostring(text or ""):lower():gsub("[%p]", ""))
end

local function add(entry, ...)
	entry.keys = {}
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if name and name ~= "" then entry.keys[#entry.keys + 1] = fold(name) end
	end
	index[#index + 1] = entry
end

local function build()
	index = {}
	local seenItem = {}
	for _, inst in ipairs(AG.Instances) do
		add({ kind = "instance", name = inst.name, instKey = inst.key,
			sub = string.format("%s, levels %d-%d", inst.zone, inst.minLevel, inst.maxLevel) },
			inst.name, inst.abbr, unpack(inst.aliases or {}))
		local guide = AG.Guides[inst.key]
		for _, boss in ipairs(guide and guide.bosses or {}) do
			add({ kind = "boss", name = boss.name, instKey = inst.key, bossKey = boss.key, sub = inst.name },
				boss.name, unpack(boss.alsoNamed or {}))
			for _, ab in ipairs(boss.abilities or {}) do
				add({ kind = "ability", name = ab.name, instKey = inst.key, bossKey = boss.key,
					spellID = ab.spellID, sub = boss.name .. ", " .. inst.name }, ab.name)
			end
			for _, item in ipairs(boss.loot or {}) do
				if item.itemID and item.name and not seenItem[item.itemID] then
					seenItem[item.itemID] = true
					add({ kind = "item", name = item.name, itemID = item.itemID, quality = item.quality,
						slot = item.slot, instKey = inst.key, bossKey = boss.key,
						sub = boss.name .. ", " .. inst.name }, item.name)
				end
			end
		end
		for _, q in ipairs(AG.Quests[inst.key] or {}) do
			if q.name then
				add({ kind = "quest", name = q.name, questID = q.questID, instKey = inst.key, level = q.level,
					side = q.side, sub = inst.name }, q.name)
			end
			for _, r in ipairs(q.rewards or {}) do
				if r.name and not seenItem[r.itemID] then
					seenItem[r.itemID] = true
					add({ kind = "item", name = r.name, itemID = r.itemID, quality = r.quality,
						instKey = inst.key, sub = "Quest: " .. (q.name or "?") .. ", " .. inst.name }, r.name)
				end
			end
		end
	end
end

-- Forget the index; the next search rebuilds it (call after the guide data changes).
function AG:ResetSearch()
	index = nil
end

-- How well a folded name matches the folded query words: 0 = no match. Every word must
-- appear; a whole-name match beats a prefix, which beats a word start, then anywhere.
local function score(key, words, query)
	for _, w in ipairs(words) do
		if not key:find(w, 1, true) then return 0 end
	end
	if key == query then return 100 end
	if key:sub(1, #query) == query then return 60 end
	if key:find(" " .. words[1], 1, true) then return 30 end
	return 10
end

-- Results for a query, grouped by kind in AG.SEARCH_KINDS order:
-- { { key, label, results = { entry, ... }, more = n }, ... } (empty groups left out).
function AG:Search(query)
	query = fold(query):match("^%s*(.-)%s*$")
	if #query < 2 then return {} end
	if not index then build() end
	local words = {}
	for w in query:gmatch("%S+") do words[#words + 1] = w end

	local byKind = {}
	for _, entry in ipairs(index) do
		local best = 0
		for _, key in ipairs(entry.keys) do best = math.max(best, score(key, words, query)) end
		if best > 0 then
			local list = byKind[entry.kind] or {}
			list[#list + 1] = { entry = entry, score = best }
			byKind[entry.kind] = list
		end
	end

	local groups = {}
	for _, kind in ipairs(self.SEARCH_KINDS) do
		local list = byKind[kind.key]
		if list then
			table.sort(list, function(a, b)
				if a.score ~= b.score then return a.score > b.score end
				return a.entry.name < b.entry.name
			end)
			local results = {}
			for i = 1, math.min(MAX_PER_KIND, #list) do results[i] = list[i].entry end
			groups[#groups + 1] = { key = kind.key, label = kind.label, results = results,
				more = math.max(0, #list - MAX_PER_KIND) }
		end
	end
	return groups
end
