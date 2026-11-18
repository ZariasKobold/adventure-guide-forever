-- Guide registry: merges the two data sources into AG.Guides, the one structure the UI
-- and learning mode read.
--
--   Content   (Data\Content\*.lua)       Hand-written: intros, boss overviews, ability
--                                         notes and role alerts. Edit freely.
--   Generated (Data\Generated\*.lua)     Built from Wowhead's Forever database by
--                                         tools\build_wowhead.py: NPC, display, spell,
--                                         and item IDs. Never edit by hand.
--   Community (Data\Generated\Community.lua)  What players' learning mode found, sent with
--                                         /ag share and merged by tools\learned_intake.py.
--                                         It is shaped like learned data and joins it (see
--                                         AG:GetLearnedBosses), not the guide text.
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
AG.Community = AG.Community or {}          -- [instKey] = { bosses = { {...} } }, as registered
AG.CommunityLearned = {}                   -- [instKey] = { [bossKey] = learned-shaped record }
AG.ItemIndex = {}                          -- [itemID] = { { instKey, bossKey, bossName, dropChance } }
AG.Quests = AG.Quests or {}                -- [instKey] = { { questID, name, level, side, start, x, y, ... } }

local MIN_KILLS_FOR_CHANCE = 5             -- kills needed before a learned drop chance shows

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

-- Community schema (generated, Data\Generated\Community.lua):
--   bosses = { { key, name, npcID, displayID, kills, reports,
--                loot = { { itemID, count } }, spells = { { spellID, count } } } }
function AG:RegisterCommunity(instKey, data)
	assert(type(instKey) == "string" and type(data) == "table", "RegisterCommunity(instKey, table)")
	assert(not self.Community[instKey], "community data registered twice: " .. instKey)
	self.Community[instKey] = data
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

-- Every other name the boss may show up under in game (used by learning mode).
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

-- Community records in the same shape as learning mode's own records.
local function buildCommunity(instKey)
	local out = {}
	for _, b in ipairs(AG.Community[instKey] and AG.Community[instKey].bosses or {}) do
		local rec = {
			name = b.name, npcID = b.npcID, displayID = b.displayID, kills = b.kills or 0,
			reports = b.reports, loot = {}, spells = {}, community = true,
		}
		for _, item in ipairs(b.loot or {}) do rec.loot[item.itemID] = item.count end
		for _, spell in ipairs(b.spells or {}) do rec.spells[spell.spellID] = spell.count end
		out[b.key] = rec
	end
	return out
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

local function chanceFrom(count, kills)
	if kills and kills >= MIN_KILLS_FOR_CHANCE and count then
		return math.min(100, count / kills * 100)
	end
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
		for bossKey, rec in pairs(AG.CommunityLearned[inst.key] or {}) do
			for itemID, count in pairs(rec.loot) do
				addSource(index, itemID, { instKey = inst.key, bossKey = bossKey,
					bossName = rec.name or bossKey, dropChance = chanceFrom(count, rec.kills) })
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
	wipe(self.CommunityLearned)
	for _, inst in ipairs(self.Instances) do
		self.Guides[inst.key] = buildGuide(inst.key)
		self.CommunityLearned[inst.key] = buildCommunity(inst.key)
	end
	for key in pairs(self.Content) do
		assert(self:GetInstance(key), "content for unknown instance: " .. key)
	end
	for key in pairs(self.Generated) do
		assert(self:GetInstance(key), "generated data for unknown instance: " .. key)
	end
	for key in pairs(self.Community) do
		assert(self:GetInstance(key), "community data for unknown instance: " .. key)
	end
	for key in pairs(self.Quests) do
		assert(self:GetInstance(key), "quests for unknown instance: " .. key)
	end
	self.ItemIndex = buildItemIndex()
	if self.ResetSearch then self:ResetSearch() end
end

------------------------------------------------------------------------
-- Learned data: your own, joined with the community's
------------------------------------------------------------------------

local function mergeCounts(a, b)
	local out = {}
	for id, n in pairs(a or {}) do out[id] = n end
	for id, n in pairs(b or {}) do out[id] = math.max(out[id] or 0, n) end
	return out
end

-- Your records and the community's for one instance, keyed by boss. Where both exist, each
-- count is the larger of the two: the community total may already include your own share.
function AG:GetLearnedBosses(instKey)
	local out = {}
	local own = self.db and self.db.learned[instKey]
	for key, rec in pairs(own and own.bosses or {}) do out[key] = rec end
	for key, crec in pairs(self.CommunityLearned[instKey] or {}) do
		local rec = out[key]
		if rec then
			out[key] = {
				name = rec.name or crec.name, npcID = rec.npcID or crec.npcID,
				displayID = rec.displayID or crec.displayID,
				kills = math.max(rec.kills or 0, crec.kills or 0),
				loot = mergeCounts(rec.loot, crec.loot), spells = mergeCounts(rec.spells, crec.spells),
				ownKills = rec.kills or 0, community = true,
			}
		else
			out[key] = crec
		end
	end
	return out
end

-- Where an item drops: the guide and community index, plus your own learned drops.
-- Sorted by drop chance, best first.
function AG:ItemSources(itemID)
	local out, seen = {}, {}
	for _, s in ipairs(self.ItemIndex[itemID] or {}) do
		out[#out + 1] = s
		if s.bossKey then seen[s.instKey .. ":" .. s.bossKey] = true end
	end
	for instKey, inst in pairs(self.db and self.db.learned or {}) do
		for bossKey, rec in pairs(inst.bosses or {}) do
			local count = rec.loot and rec.loot[itemID]
			if count and not seen[instKey .. ":" .. bossKey] and self:GetInstance(instKey) then
				out[#out + 1] = { instKey = instKey, bossKey = bossKey, bossName = rec.name or bossKey,
					dropChance = chanceFrom(count, rec.kills) }
			end
		end
	end
	table.sort(out, function(a, b) return (a.dropChance or 0) > (b.dropChance or 0) end)
	return out
end
