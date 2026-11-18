-- Suggested gear: the best item per slot from dungeon drops and quest rewards for a class,
-- spec, and level, scored with simple stat weights. The weights are a starting point, not
-- gospel: they're shown on the page so players can see why an item was picked.

local _, AG = ...

-- Stat weights per role. Ratings (hit, crit) count per point of rating; dps is weapon DPS.
local W = {}
W.strMelee = { str = 1, agi = 0.6, sta = 0.4, ap = 0.45, hit = 0.9, crit = 0.8, haste = 0.6, expertise = 0.7, dps = 3 }
W.agiMelee = { agi = 1, str = 0.5, sta = 0.35, ap = 0.5, hit = 0.9, crit = 0.8, haste = 0.6, expertise = 0.7, dps = 3 }
W.hybridMelee = { str = 0.9, agi = 0.9, sta = 0.35, int = 0.25, ap = 0.5, hit = 0.9, crit = 0.8, haste = 0.6, dps = 3 }
W.hunter = { agi = 1, int = 0.35, sta = 0.35, ap = 0.45, rap = 0.5, hit = 0.9, crit = 0.8, haste = 0.5, rangedDps = 3 }
W.tank = { sta = 1, def = 1, dodge = 0.8, parry = 0.8, block = 0.5, blockValue = 0.3, str = 0.6, agi = 0.5,
	bonusArmor = 0.05, armor = 0.02, hit = 0.4, dps = 1 }
W.bear = { sta = 1, agi = 0.8, def = 0.8, dodge = 0.8, str = 0.4, bonusArmor = 0.05, armor = 0.03, hit = 0.4 }
W.caster = { sp = 1, int = 0.55, crit = 0.8, hit = 0.9, haste = 0.7, sta = 0.3, spi = 0.15, spellPen = 0.2, rangedDps = 0.5 }
W.healer = { heal = 1, sp = 0.85, int = 0.6, spi = 0.45, mp5 = 1.2, crit = 0.5, haste = 0.5, sta = 0.2, rangedDps = 0.3 }

local function with(base, extra)
	local out = {}
	for k, v in pairs(base) do out[k] = v end
	for k, v in pairs(extra or {}) do out[k] = v end
	return out
end

-- Specs per classID, in talent-tree order. key is ours; name matches the game's spec name.
AG.SPECS = {
	[1] = { { key = "arms", name = "Arms", w = W.strMelee }, { key = "fury", name = "Fury", w = W.strMelee },
		{ key = "protection", name = "Protection", w = W.tank } },
	[2] = { { key = "holy", name = "Holy", w = W.healer }, { key = "protection", name = "Protection", w = W.tank },
		{ key = "retribution", name = "Retribution", w = with(W.strMelee, { int = 0.2 }) } },
	[3] = { { key = "beastmastery", name = "Beast Mastery", w = W.hunter },
		{ key = "marksmanship", name = "Marksmanship", w = W.hunter }, { key = "survival", name = "Survival", w = W.hunter } },
	[4] = { { key = "assassination", name = "Assassination", w = W.agiMelee }, { key = "combat", name = "Combat", w = W.agiMelee },
		{ key = "subtlety", name = "Subtlety", w = W.agiMelee } },
	[5] = { { key = "discipline", name = "Discipline", w = W.healer }, { key = "holy", name = "Holy", w = W.healer },
		{ key = "shadow", name = "Shadow", w = with(W.caster, { shadowSp = 0.95, spi = 0.25 }) } },
	[7] = { { key = "elemental", name = "Elemental", w = with(W.caster, { natureSp = 0.95, fireSp = 0.3 }) },
		{ key = "enhancement", name = "Enhancement", w = W.hybridMelee }, { key = "restoration", name = "Restoration", w = W.healer } },
	[8] = { { key = "arcane", name = "Arcane", w = with(W.caster, { arcaneSp = 0.95, spi = 0.25 }) },
		{ key = "fire", name = "Fire", w = with(W.caster, { fireSp = 0.95 }) },
		{ key = "frost", name = "Frost", w = with(W.caster, { frostSp = 0.95 }) } },
	[9] = { { key = "affliction", name = "Affliction", w = with(W.caster, { shadowSp = 0.95 }) },
		{ key = "demonology", name = "Demonology", w = with(W.caster, { shadowSp = 0.8, sta = 0.45 }) },
		{ key = "destruction", name = "Destruction", w = with(W.caster, { shadowSp = 0.7, fireSp = 0.7 }) } },
	[11] = { { key = "balance", name = "Balance", w = with(W.caster, { natureSp = 0.7, arcaneSp = 0.7 }) },
		{ key = "feral", name = "Feral", w = with(W.agiMelee, { feral = 0.5, str = 0.6 }) },
		{ key = "guardian", name = "Guardian", w = W.bear },
		{ key = "restoration", name = "Restoration", w = W.healer } },
}

AG.CLASS_NAMES = { [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue", [5] = "Priest",
	[7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid" }
AG.CLASS_ORDER = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }

function AG:GetSpec(classID, specKey)
	for _, spec in ipairs(self.SPECS[classID] or {}) do
		if spec.key == specKey then return spec end
	end
	return (self.SPECS[classID] or {})[1]
end

-- Your current spec key: the game's specialization if it has one, else the talent tree
-- with the most points, else nil.
function AG:DetectSpec(classID)
	local specs = self.SPECS[classID]
	if not specs then return nil end
	if GetSpecialization and GetSpecializationInfo then
		local index = self:Readable(GetSpecialization())
		if type(index) == "number" and index > 0 then
			local _, name = GetSpecializationInfo(index)
			name = self:Readable(name)
			for _, spec in ipairs(specs) do
				if spec.name == name then return spec.key end
			end
		end
	end
	if GetNumTalentTabs and GetTalentTabInfo then
		local best, bestPoints = nil, 0
		for tab = 1, math.min(GetNumTalentTabs() or 0, #specs) do
			local _, _, points = GetTalentTabInfo(tab)
			points = self:Readable(points)
			if type(points) == "number" and points > bestPoints then best, bestPoints = tab, points end
		end
		if best then return specs[best].key end
	end
	return nil
end

local function isWeapon(item) return item.class == 2 end
local function isRanged(item) return item.slot == 15 or item.slot == 25 or item.slot == 26 end

-- An item's score for a set of weights.
function AG:ScoreItem(item, weights)
	local score = 0
	for stat, value in pairs(item.stats or {}) do
		score = score + value * (weights[stat] or 0)
	end
	if item.armor and weights.armor then score = score + item.armor * weights.armor end
	if item.dps and isWeapon(item) then
		local w = isRanged(item) and (weights.rangedDps or 0) or (weights.dps or 0)
		score = score + item.dps * w
	end
	return score
end

-- The slots a set fills, and how many picks each gets (two rings, two trinkets).
AG.PLAN_SLOTS = {
	{ key = "head", count = 1, equip = { 1 } }, { key = "neck", count = 1, equip = { 2 } },
	{ key = "shoulder", count = 1, equip = { 3 } }, { key = "back", count = 1, equip = { 15 } },
	{ key = "chest", count = 1, equip = { 5 } }, { key = "wrist", count = 1, equip = { 9 } },
	{ key = "hands", count = 1, equip = { 10 } }, { key = "waist", count = 1, equip = { 6 } },
	{ key = "legs", count = 1, equip = { 7 } }, { key = "feet", count = 1, equip = { 8 } },
	{ key = "finger", count = 2, equip = { 11, 12 } }, { key = "trinket", count = 2, equip = { 13, 14 } },
	{ key = "twohand", count = 1, equip = { 16 } }, { key = "onehand", count = 1, equip = { 16 } },
	{ key = "offhand", count = 1, equip = { 17 } }, { key = "ranged", count = 1, equip = { 18 } },
}

-- Best picks for a class, spec, and level. opts: { quests = false } leaves quest rewards out.
-- Returns { { slot, label, picks = { { itemID, name, quality, item, score, source } }, alternatives } }.
function AG:SuggestGear(classID, specKey, level, opts)
	opts = opts or {}
	local spec = self:GetSpec(classID, specKey)
	local weights = spec and spec.w or W.strMelee
	local out = {}
	for _, plan in ipairs(self.PLAN_SLOTS) do
		local candidates = {}
		for _, g in ipairs(self:FilterGear({ slot = plan.key, maxLevel = level, usable = true, classID = classID, level = level })) do
			local sources = self:ItemSources(g.itemID)
			local keep = {}
			for _, s in ipairs(sources) do
				if opts.quests ~= false or not s.questID then
					if not (s.side and opts.faction and s.side ~= opts.faction) then keep[#keep + 1] = s end
				end
			end
			if #keep > 0 then
				local score = self:ScoreItem(g.item, weights)
				if score > 0 then
					candidates[#candidates + 1] = { itemID = g.itemID, name = g.name, quality = g.quality,
						item = g.item, score = score, source = keep[1] }
				end
			end
		end
		table.sort(candidates, function(a, b)
			if a.score ~= b.score then return a.score > b.score end
			return (a.item.itemLevel or 0) > (b.item.itemLevel or 0)
		end)
		local picks, alternatives = {}, {}
		for i, c in ipairs(candidates) do
			if i <= plan.count then picks[#picks + 1] = c elseif #alternatives < 3 then alternatives[#alternatives + 1] = c end
		end
		local label
		for _, s in ipairs(self.GEAR_SLOTS) do if s.key == plan.key then label = s.label end end
		out[#out + 1] = { slot = plan.key, label = label, equip = plan.equip, picks = picks, alternatives = alternatives }
	end
	return out, weights
end

-- The weights as text, biggest first: "Strength x1, Hit x0.9, ...".
function AG:WeightLine(weights)
	local parts = {}
	for stat, w in pairs(weights) do parts[#parts + 1] = { stat = stat, w = w } end
	table.sort(parts, function(a, b)
		if a.w ~= b.w then return a.w > b.w end
		return a.stat < b.stat
	end)
	local labels = { dps = "Weapon DPS", rangedDps = "Ranged weapon DPS", armor = "Armor" }
	for i, p in ipairs(parts) do
		parts[i] = string.format("%s x%s", labels[p.stat] or self.STAT_LABELS[p.stat] or p.stat, tostring(p.w))
	end
	return table.concat(parts, ", ")
end

------------------------------------------------------------------------
-- What you're wearing, scored the same way (for the upgrade arrows)
------------------------------------------------------------------------

-- The game's stat names (C_Item.GetItemStats) -> ours.
local GAME_STATS = {
	ITEM_MOD_STRENGTH_SHORT = "str", ITEM_MOD_AGILITY_SHORT = "agi", ITEM_MOD_STAMINA_SHORT = "sta",
	ITEM_MOD_INTELLECT_SHORT = "int", ITEM_MOD_SPIRIT_SHORT = "spi", ITEM_MOD_ATTACK_POWER_SHORT = "ap",
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "rap", ITEM_MOD_SPELL_POWER_SHORT = "sp",
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "heal", ITEM_MOD_CRIT_RATING_SHORT = "crit",
	ITEM_MOD_HIT_RATING_SHORT = "hit", ITEM_MOD_HASTE_RATING_SHORT = "haste",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "def", ITEM_MOD_DODGE_RATING_SHORT = "dodge",
	ITEM_MOD_PARRY_RATING_SHORT = "parry", ITEM_MOD_BLOCK_RATING_SHORT = "block",
	ITEM_MOD_BLOCK_VALUE_SHORT = "blockValue", ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
	ITEM_MOD_EXPERTISE_RATING_SHORT = "expertise", ITEM_MOD_SPELL_PENETRATION_SHORT = "spellPen",
}
local RANGED_EQUIP = { INVTYPE_RANGED = 15, INVTYPE_RANGEDRIGHT = 26, INVTYPE_THROWN = 25 }

-- The item in an equipment slot, as { itemID, item } shaped like AG.Items records, or nil.
-- Guide items use our data; anything else is read from the game.
function AG:EquippedItem(slotID)
	local itemID = GetInventoryItemID and self:Readable(GetInventoryItemID("player", slotID))
	if type(itemID) ~= "number" then return nil end
	if self.Items[itemID] then return { itemID = itemID, item = self.Items[itemID] } end
	local link = GetInventoryItemLink and self:Readable(GetInventoryItemLink("player", slotID))
	local raw = link and C_Item and C_Item.GetItemStats and C_Item.GetItemStats(link)
	local item = { stats = {} }
	for key, value in pairs(type(raw) == "table" and raw or {}) do
		if GAME_STATS[key] and type(value) == "number" then
			item.stats[GAME_STATS[key]] = value
		elseif key == "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" and type(value) == "number" then
			item.dps = value
		end
	end
	if C_Item and C_Item.GetItemInfoInstant then
		local _, _, _, equipLoc, _, classID = C_Item.GetItemInfoInstant(itemID)
		item.class = classID
		item.slot = RANGED_EQUIP[equipLoc] or 0
	end
	return { itemID = itemID, item = item }
end

-- Compares a pick with what you wear in its slots. Returns "equipped", or the score gained
-- over the weaker of your items in those slots (negative if yours is better), or nil if
-- the slots are empty.
function AG:CompareToEquipped(pick, equipSlots, weights)
	local weakest, empty
	for _, slotID in ipairs(equipSlots) do
		local worn = self:EquippedItem(slotID)
		if worn and worn.itemID == pick.itemID then return "equipped" end
		if worn then
			local score = self:ScoreItem(worn.item, weights)
			if not weakest or score < weakest then weakest = score end
		else
			empty = true
		end
	end
	if empty or weakest == nil then return nil end -- an empty slot: anything is an upgrade
	return pick.score - weakest
end
