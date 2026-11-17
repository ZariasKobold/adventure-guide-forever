-- Guide registry: merges the two data sources into AG.Guides, the one structure the UI
-- and learning mode read.
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
-- Runtime boss schema (AG.Guides[instKey].bosses[i]):
--   key, name, npcID, displayID, overview, optional, alsoNamed,
--   abilities = { { name, text, alerts, spellID } },
--   loot      = { { name, itemID, slot, quality } }

local _, AG = ...

AG.Content = AG.Content or {}
AG.Generated = AG.Generated or {}

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
	return { intro = content.intro, bosses = bosses }
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
end
