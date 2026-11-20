-- Guide registry: merges the two data sources into AG.Guides, the one structure the UI
-- reads.
--
--   Content   (Data\Content\*.lua)       Hand-written: intros, boss overviews, ability
--                                         notes and role alerts. Edit freely.
--   Generated (Data\Generated\*.lua)     Built from Wowhead's Forever database by
--                                         tools\build_wowhead.py: NPC, display, spell,
--                                         and item IDs. Never edit by hand.
--
-- Merge rules
--   * Bosses match by normalized name (or a content boss's alsoNamed list).
--   * Boss order follows content; generated bosses with no content are appended.
--   * Abilities: content abilities first, given the spell ID of the generated ability
--     with the same name. Remaining generated abilities follow, described in game by
--     the spell's own tooltip text.
--   * Loot: generated loot is Forever's real loot table, so it replaces content loot.
--     Content loot is only used for bosses Wowhead has no loot for yet.
--
-- Content schema (hand-written, Data\Content\<instance>.lua):
--   intro    one-line summary shown on the instance page
--   lore     the instance's story (a paragraph or two)
--   route    how to get through it: boss order, key turns, what to skip
--   tips     { "short practical tip", ... }
--   bosses   { { name, overview, lore, strategy, abilities, optional, alsoNamed } }
--     overview   one-line description of who the boss is
--     lore       the boss's story
--     strategy   { summary, tank, healer, dps } (each optional)
--
-- Runtime guide schema (AG.Guides[instKey]):
--   intro, lore, route, tips, bosses = {
--     { key, name, npcID, displayID, overview, lore, strategy, optional, alsoNamed,
--       abilities = { { name, text, alerts, spellID } },
--       loot      = { { name, itemID, slot, quality, dropChance } } } }

local _, AG = ...

AG.Content = AG.Content or {}
AG.Generated = AG.Generated or {}
AG.ItemIndex = {}                          -- [itemID] = { { instKey, bossKey, bossName, dropChance } }
AG.Quests = AG.Quests or {}                -- [instKey] = { { questID, name, level, side, start, x, y, ... } }

function AG:RegisterContent(instKey, content)
	assert(type(instKey) == "string" and type(content) == "table", "RegisterContent(instKey, table)")
	assert(not self.Content[instKey], "content registered twice: " .. instKey)
	self.Content[instKey] = content
end

function AG:RegisterGenerated(instKey, data)
	assert(type(instKey) == "string" and type(data) == "table", "RegisterGenerated(instKey, table)")
	assert(not self.Generated[instKey], "generated data registered twice: " .. instKey)
	self.Generated[instKey] = data
end

-- Quest schema (generated, Data\Generated\Quests.lua, from Wowhead's dungeon guides):
--   quests = { { questID, name, level, side ("Horde"/"Alliance", nil for both), start,
--                x, y (map coordinates where it starts), chain, chainName (the quest its
--                chain starts with), shareable } }
function AG:RegisterQuests(instKey, data)
	assert(type(instKey) == "string" and type(data) == "table", "RegisterQuests(instKey, table)")
	assert(not self.Quests[instKey], "quests registered twice: " .. instKey)
	self.Quests[instKey] = data.quests or {}
end

-- Item schema (generated, Data\Generated\Items.lua, from Wowhead's Forever database):
--   items = { { itemID, itemLevel, reqLevel, quality, class, subclass, slot (inventory
--               type), classes (class bitmask, nil = any), armor, dps, speed,
--               stats = { str, agi, sta, int, spi, ap, sp, crit, ... } } }
AG.Items = AG.Items or {}                  -- [itemID] = record above

AG.STAT_LABELS = {
	str = "Strength", agi = "Agility", sta = "Stamina", int = "Intellect", spi = "Spirit",
	ap = "Attack Power", rap = "Ranged Attack Power", feral = "Feral Attack Power",
	sp = "Spell Power", heal = "Healing", crit = "Critical Strike", hit = "Hit", haste = "Haste",
	def = "Defense", dodge = "Dodge", parry = "Parry", block = "Block", blockValue = "Block Value",
	mp5 = "Mana per 5 sec", hp5 = "Health per 5 sec", spellPen = "Spell Penetration",
	fireRes = "Fire Resistance", frostRes = "Frost Resistance", natureRes = "Nature Resistance",
	shadowRes = "Shadow Resistance", arcaneRes = "Arcane Resistance", holyRes = "Holy Resistance",
	bonusArmor = "Bonus Armor", expertise = "Expertise",
	critPct = "Critical Strike %", rangedCritPct = "Ranged Critical Strike %",
	spellCritPct = "Spell Critical Strike %", hitPct = "Hit %", rangedHitPct = "Ranged Hit %",
	rangedHastePct = "Ranged Haste %",
	fireSp = "Fire Spell Power", frostSp = "Frost Spell Power", natureSp = "Nature Spell Power",
	shadowSp = "Shadow Spell Power", arcaneSp = "Arcane Spell Power", holySp = "Holy Spell Power",
	daggerSkill = "Dagger Skill", unarmedSkill = "Unarmed Skill", feralSkill = "Feral Combat Skill",
}

function AG:RegisterItems(data)
	assert(type(data) == "table", "RegisterItems(table)")
	for _, item in ipairs(data.items or {}) do self.Items[item.itemID] = item end
end

-- An item's level, requirements, and stats, or nil if the guide doesn't know it.
function AG:GetItem(itemID)
	return self.Items[itemID]
end

-- An instance's quests for a faction ("Horde"/"Alliance"; nil = all), by level then name.
-- Also returns how many were left out for the other faction.
function AG:GetQuests(instKey, faction)
	local out, other = {}, 0
	for _, q in ipairs(self.Quests[instKey] or {}) do
		if not faction or not q.side or q.side == faction then
			out[#out + 1] = q
		else
			other = other + 1
		end
	end
	table.sort(out, function(a, b)
		if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
		return (a.name or "") < (b.name or "")
	end)
	return out, other
end

local function copyList(list)
	local out = {}
	for i, v in ipairs(list or {}) do out[i] = v end
	return out
end

local function mergeAbilities(contentAbilities, generatedAbilities)
	local byName = {}
	for _, ab in ipairs(generatedAbilities or {}) do
		byName[AG:Normalize(ab.name)] = ab
	end

	local out, used = {}, {}
	for _, ab in ipairs(contentAbilities or {}) do
		local gen = byName[AG:Normalize(ab.name)]
		if gen then used[gen] = true end
		out[#out + 1] = {
			name = ab.name, text = ab.text, alerts = copyList(ab.alerts),
			spellID = ab.spellID or (gen and gen.spellID),
		}
	end
	for _, gen in ipairs(generatedAbilities or {}) do
		if not used[gen] then
			out[#out + 1] = { name = gen.name, spellID = gen.spellID, alerts = {} }
		end
	end
	return out
end

-- Every other name the boss may show up under in game (target and encounter names).
local function mergeNames(content, generated)
	local out = copyList(content.alsoNamed)
	if content.name and generated.name and content.name ~= generated.name then
		out[#out + 1] = content.name
	end
	return out
end

local function mergeBoss(content, generated)
	content, generated = content or {}, generated or {}
	-- Generated names come from the live game data, so they win if Forever renamed a boss.
	local name = generated.name or content.name
	local loot = generated.loot and #generated.loot > 0 and generated.loot or content.loot
	return {
		key = AG:Normalize(name),
		name = name,
		npcID = generated.npcID or content.npcID,
		displayID = generated.displayID or content.displayID,
		overview = content.overview,
		lore = content.lore,
		strategy = content.strategy,
		optional = content.optional or generated.optional,
		alsoNamed = mergeNames(content, generated),
		abilities = mergeAbilities(content.abilities, generated.abilities),
		loot = copyList(loot),
	}
end

local function buildGuide(instKey)
	local content = AG.Content[instKey] or {}
	local generated = AG.Generated[instKey] or {}

	-- Index generated bosses by every name they could be matched on.
	local genByName, matched = {}, {}
	for _, gb in ipairs(generated.bosses or {}) do
		genByName[AG:Normalize(gb.name)] = gb
	end

	local bosses = {}
	for _, cb in ipairs(content.bosses or {}) do
		local gb = genByName[AG:Normalize(cb.name)]
		for _, alias in ipairs(cb.alsoNamed or {}) do
			gb = gb or genByName[AG:Normalize(alias)]
		end
		if gb then matched[gb] = true end
		bosses[#bosses + 1] = mergeBoss(cb, gb)
	end
	for _, gb in ipairs(generated.bosses or {}) do
		if not matched[gb] then bosses[#bosses + 1] = mergeBoss(nil, gb) end
	end

	if #bosses == 0 and not content.intro then return nil end
	return {
		intro = content.intro, lore = content.lore, route = content.route,
		tips = copyList(content.tips), bosses = bosses,
	}
end

local function addSource(index, itemID, source)
	index[itemID] = index[itemID] or {}
	for _, s in ipairs(index[itemID]) do
		if s.instKey == source.instKey and s.bossKey == source.bossKey then
			s.dropChance = s.dropChance or source.dropChance
			return
		end
	end
	table.insert(index[itemID], source)
end

-- Every boss each item drops from, for the "Drops from" tooltip lines.
local function buildItemIndex()
	local index = {}
	for _, inst in ipairs(AG.Instances) do
		local guide = AG.Guides[inst.key]
		for _, boss in ipairs(guide and guide.bosses or {}) do
			for _, item in ipairs(boss.loot or {}) do
				if item.itemID then
					addSource(index, item.itemID, { instKey = inst.key, bossKey = boss.key,
						bossName = boss.name, dropChance = item.dropChance })
				end
			end
		end
		-- Quest rewards: no boss, no drop chance; bossName reads "Quest: <name>" wherever
		-- a source is shown.
		for _, q in ipairs(AG.Quests[inst.key] or {}) do
			for _, reward in ipairs(q.rewards or {}) do
				addSource(index, reward.itemID, { instKey = inst.key, questID = q.questID,
					questName = q.name, side = q.side, bossName = "Quest: " .. (q.name or q.questID) })
			end
		end
	end
	return index
end

-- Rebuilds AG.Guides from everything registered. Runs once all data files are loaded.
function AG:BuildGuides()
	wipe(self.Guides)
	for _, inst in ipairs(self.Instances) do
		self.Guides[inst.key] = buildGuide(inst.key)
	end
	for key in pairs(self.Content) do
		assert(self:GetInstance(key), "content for unknown instance: " .. key)
	end
	for key in pairs(self.Generated) do
		assert(self:GetInstance(key), "generated data for unknown instance: " .. key)
	end
	for key in pairs(self.Quests) do
		assert(self:GetInstance(key), "quests for unknown instance: " .. key)
	end
	self.ItemIndex = buildItemIndex()
	if self.ResetSearch then self:ResetSearch() end
	if self.ResetGear then self:ResetGear() end
end

-- Where an item drops (bosses, and dungeon quests that reward it), best drop chance first.
-- Returns a new list each time.
function AG:ItemSources(itemID)
	local out = {}
	for _, s in ipairs(self.ItemIndex[itemID] or {}) do out[#out + 1] = s end
	table.sort(out, function(a, b) return (a.dropChance or 0) > (b.dropChance or 0) end)
	return out
end
