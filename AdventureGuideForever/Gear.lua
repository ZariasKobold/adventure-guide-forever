-- Gear: every item the guide knows (boss drops and quest rewards) joined with its level and
-- stats (AG.Items), with filters for the Gear tab: slot, armor or weapon type, stat, level,
-- quality, and "what my class can use".

local _, AG = ...

-- Slots, by the item's inventory type.
AG.GEAR_SLOTS = {
	{ key = "head",     label = "Head",      inv = { 1 } },
	{ key = "neck",     label = "Neck",      inv = { 2 } },
	{ key = "shoulder", label = "Shoulder",  inv = { 3 } },
	{ key = "back",     label = "Back",      inv = { 16 } },
	{ key = "chest",    label = "Chest",     inv = { 5, 20 } },
	{ key = "wrist",    label = "Wrist",     inv = { 9 } },
	{ key = "hands",    label = "Hands",     inv = { 10 } },
	{ key = "waist",    label = "Waist",     inv = { 6 } },
	{ key = "legs",     label = "Legs",      inv = { 7 } },
	{ key = "feet",     label = "Feet",      inv = { 8 } },
	{ key = "finger",   label = "Finger",    inv = { 11 } },
	{ key = "trinket",  label = "Trinket",   inv = { 12 } },
	{ key = "onehand",  label = "One-Hand",  inv = { 13, 21 } },
	{ key = "twohand",  label = "Two-Hand",  inv = { 17 } },
	{ key = "offhand",  label = "Off Hand",  inv = { 14, 22, 23 } },
	{ key = "ranged",   label = "Ranged",    inv = { 15, 25, 26, 28 } },
}

local ARMOR, WEAPON = 4, 2

-- Armor and weapon types: item class + subclasses.
AG.GEAR_TYPES = {
	{ key = "cloth",    label = "Cloth",       class = ARMOR,  sub = { 1 } },
	{ key = "leather",  label = "Leather",     class = ARMOR,  sub = { 2 } },
	{ key = "mail",     label = "Mail",        class = ARMOR,  sub = { 3 } },
	{ key = "plate",    label = "Plate",       class = ARMOR,  sub = { 4 } },
	{ key = "shield",   label = "Shield",      class = ARMOR,  sub = { 6 } },
	{ key = "relic",    label = "Relic",       class = ARMOR,  sub = { 7, 8, 9 } },
	{ key = "axe",      label = "Axe",         class = WEAPON, sub = { 0, 1 } },
	{ key = "mace",     label = "Mace",        class = WEAPON, sub = { 4, 5 } },
	{ key = "sword",    label = "Sword",       class = WEAPON, sub = { 7, 8 } },
	{ key = "dagger",   label = "Dagger",      class = WEAPON, sub = { 15 } },
	{ key = "fist",     label = "Fist Weapon", class = WEAPON, sub = { 13 } },
	{ key = "polearm",  label = "Polearm",     class = WEAPON, sub = { 6 } },
	{ key = "staff",    label = "Staff",       class = WEAPON, sub = { 10 } },
	{ key = "bow",      label = "Bow",         class = WEAPON, sub = { 2 } },
	{ key = "gun",      label = "Gun",         class = WEAPON, sub = { 3 } },
	{ key = "crossbow", label = "Crossbow",    class = WEAPON, sub = { 18 } },
	{ key = "wand",     label = "Wand",        class = WEAPON, sub = { 19 } },
	{ key = "thrown",   label = "Thrown",      class = WEAPON, sub = { 16 } },
}

-- Stats worth filtering and sorting by, in menu order.
AG.GEAR_STATS = { "str", "agi", "sta", "int", "spi", "ap", "rap", "sp", "heal", "hit", "crit",
	"mp5", "def", "dodge", "parry", "blockValue", "fireRes", "frostRes", "natureRes", "shadowRes",
	"arcaneRes" }

AG.QUALITY_NAMES = { [0] = "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local SLOT_NAME, TYPE_OF = {}, {}
for _, slot in ipairs(AG.GEAR_SLOTS) do
	for _, inv in ipairs(slot.inv) do SLOT_NAME[inv] = slot end
end
for _, t in ipairs(AG.GEAR_TYPES) do
	for _, sub in ipairs(t.sub) do TYPE_OF[t.class * 100 + sub] = t end
end

-- What each class can wear and wield (classIDs from UnitClass). Mail and plate open up at
-- level 40 for hunters and shamans (mail) and warriors and paladins (plate).
local ARMOR_BY_CLASS = {
	[1] = { cloth = 1, leather = 1, mail = 1, plate = 40, shield = 1 },             -- Warrior
	[2] = { cloth = 1, leather = 1, mail = 1, plate = 40, shield = 1, relic = 1 },  -- Paladin
	[3] = { cloth = 1, leather = 1, mail = 40 },                                    -- Hunter
	[4] = { cloth = 1, leather = 1 },                                               -- Rogue
	[5] = { cloth = 1 },                                                            -- Priest
	[7] = { cloth = 1, leather = 1, mail = 40, shield = 1, relic = 1 },             -- Shaman
	[8] = { cloth = 1 },                                                            -- Mage
	[9] = { cloth = 1 },                                                            -- Warlock
	[11] = { cloth = 1, leather = 1, relic = 1 },                                   -- Druid
}
local WEAPONS_BY_CLASS = {
	[1] = { axe = 1, mace = 1, sword = 1, dagger = 1, fist = 1, polearm = 1, staff = 1, bow = 1, gun = 1, crossbow = 1, thrown = 1 },
	[2] = { axe = 1, mace = 1, sword = 1, polearm = 1 },
	[3] = { axe = 1, sword = 1, dagger = 1, fist = 1, polearm = 1, staff = 1, bow = 1, gun = 1, crossbow = 1, thrown = 1 },
	[4] = { mace = 1, sword = 1, dagger = 1, fist = 1, bow = 1, gun = 1, crossbow = 1, thrown = 1 },
	[5] = { mace = 1, staff = 1, dagger = 1, wand = 1 },
	[7] = { axe = 1, mace = 1, staff = 1, dagger = 1, fist = 1 },
	[8] = { sword = 1, staff = 1, dagger = 1, wand = 1 },
	[9] = { sword = 1, staff = 1, dagger = 1, wand = 1 },
	[11] = { mace = 1, staff = 1, dagger = 1, fist = 1 },
}
-- Some one-handers only come one-handed for some classes (priests can't use two-hand maces).
local ONE_HAND_ONLY = { [4] = { mace = true, sword = true }, [5] = { mace = true }, [8] = { sword = true }, [9] = { sword = true } }

function AG:GearSlotLabel(item)
	local slot = item and SLOT_NAME[item.slot or 0]
	return slot and slot.label or nil
end

function AG:GearType(item)
	return item and TYPE_OF[(item.class or 0) * 100 + (item.subclass or -1)] or nil
end

-- The player's classID and level, readable values only.
function AG:PlayerClassAndLevel()
	local classID = UnitClass and select(3, UnitClass("player"))
	classID = self:Readable(classID)
	local level = self:Readable(UnitLevel("player"))
	return type(classID) == "number" and classID or nil, type(level) == "number" and level or nil
end

local function hasBit(mask, bit)
	return math.floor(mask / 2 ^ (bit - 1)) % 2 == 1
end

-- Can this class wear or wield the item at this level? (Required level is checked
-- separately.) Unknown class: everything counts as usable.
function AG:CanUse(item, classID, level)
	if not classID or not item then return true end
	if item.classes and item.classes > 0 and not hasBit(item.classes, classID) then return false end
	local t = self:GearType(item)
	if not t then return true end
	if item.class == ARMOR then
		local from = (ARMOR_BY_CLASS[classID] or {})[t.key]
		return from ~= nil and (level or 60) >= from
	end
	if not (WEAPONS_BY_CLASS[classID] or {})[t.key] then return false end
	local oneHand = ONE_HAND_ONLY[classID]
	if oneHand and oneHand[t.key] and item.slot == 17 then return false end
	return true
end

-- Every guide item with known stats: { itemID, name, quality, item, sources }.
local gear
function AG:ResetGear()
	gear = nil
end

local function buildGear()
	local names = {}
	for _, guide in pairs(AG.Guides) do
		for _, boss in ipairs(guide.bosses or {}) do
			for _, loot in ipairs(boss.loot or {}) do
				if loot.itemID and loot.name then names[loot.itemID] = names[loot.itemID] or loot end
			end
		end
	end
	for _, quests in pairs(AG.Quests) do
		for _, q in ipairs(quests) do
			for _, r in ipairs(q.rewards or {}) do names[r.itemID] = names[r.itemID] or r end
		end
	end
	gear = {}
	for itemID, info in pairs(names) do
		local item = AG.Items[itemID]
		if item and AG:GearSlotLabel(item) then
			gear[#gear + 1] = { itemID = itemID, name = info.name, quality = item.quality or info.quality, item = item }
		end
	end
	return gear
end

local function inList(list, value)
	for _, v in ipairs(list or {}) do if v == value then return true end end
	return false
end

local function slotDef(key)
	for _, s in ipairs(AG.GEAR_SLOTS) do if s.key == key then return s end end
end

-- Filter: { slot, type, stat, minLevel, maxLevel, minQuality, usable, classID, level }.
-- Results are sorted by the chosen stat (highest first), then item level.
function AG:FilterGear(f)
	f = f or {}
	local slot = f.slot and slotDef(f.slot)
	local out = {}
	for _, g in ipairs(gear or buildGear()) do
		local item = g.item
		local req = item.reqLevel or 1
		local t = self:GearType(item)
		local ok = (not slot or inList(slot.inv, item.slot))
			and (not f.type or (t and t.key == f.type))
			and (not f.minLevel or req >= f.minLevel)
			and (not f.maxLevel or req <= f.maxLevel)
			and (not f.minQuality or (g.quality or 1) >= f.minQuality)
			and (not f.stat or (item.stats and (item.stats[f.stat] or 0) > 0))
			and (not f.usable or self:CanUse(item, f.classID, f.level))
		if ok then
			g.statValue = f.stat and item.stats and item.stats[f.stat] or nil
			out[#out + 1] = g
		end
	end
	table.sort(out, function(a, b)
		if (a.statValue or 0) ~= (b.statValue or 0) then return (a.statValue or 0) > (b.statValue or 0) end
		if (a.item.itemLevel or 0) ~= (b.item.itemLevel or 0) then return (a.item.itemLevel or 0) > (b.item.itemLevel or 0) end
		return (a.name or "") < (b.name or "")
	end)
	return out
end

-- "+5 Strength, +3 Stamina" (largest first), for a result row.
function AG:StatLine(item)
	local parts = {}
	for key, value in pairs(item and item.stats or {}) do
		parts[#parts + 1] = { key = key, value = value }
	end
	table.sort(parts, function(a, b)
		if a.value ~= b.value then return a.value > b.value end
		return a.key < b.key
	end)
	for i, p in ipairs(parts) do
		parts[i] = string.format("+%s %s", p.value, self.STAT_LABELS[p.key] or p.key)
	end
	return table.concat(parts, ", ")
end
