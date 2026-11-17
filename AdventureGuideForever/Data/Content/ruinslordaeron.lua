-- Ruins of Lordaeron: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ruinslordaeron", {
	intro = "The Scourge stirs again in the broken halls of Lordaeron, above the Undercity.",
	lore = "The ruins of Lordaeron's capital sit above the Undercity, a reminder of the kingdom that fell to the Scourge. Now the dead are stirring again in its broken courtyards, and the Forsaken below want to know who is behind it.",
	route = "The ruins are open-air above Undercity, near the entrance from Brill. Witherfang, The Baron, Viktor the Vile, The Abandoned and Bjork guard the way to Rath'mael, the skeletal mage at the end. The Lordaeron Captain is a rare ghost.",
	tips = {
		"Alliance players: entering Undercity's grounds flags you for PvP. Be careful.",
		"Horde quests start in Undercity, Silverpine and Tirisfal; Alliance quests start inside.",
		"Strategy here is early notes from each boss's abilities.",
	},
	bosses = {
		{
			name = "Witherfang",
			overview = "A giant undead spider.",
			lore = "A spider swollen with plague, nesting in the ruins.",
			strategy = { summary = "Early notes: his Leech Poison drains health. Cure it if you can." },
		},
		{
			name = "The Baron",
			overview = "An abomination of the Scourge.",
			lore = "A stitched-together abomination left to guard the ruins.",
			strategy = { summary = "Early notes: he tramples, knocks out players and casts Mind Blast.", tank = "Keep him faced away from the group." },
		},
		{
			name = "Viktor the Vile",
			overview = "A cruel Scourge servant.",
			lore = "A servant of the Scourge who poisons his foes.",
			strategy = { summary = "Early notes: his Leech Poison drains health." },
		},
		{
			name = "The Abandoned",
			overview = "A frost-wielding undead caster.",
			lore = "A forsaken caster left behind in the ruins.",
			strategy = { summary = "Early notes: he freezes players with Frost Nova and drains their life.", healer = "Watch for players stuck in his nova." },
		},
		{
			name = "Bjork",
			overview = "A hulking undead brute.",
			lore = "A huge undead warrior.",
			strategy = {
				summary = "Early notes: he hits hard with Mighty Blow and shields himself against magic.",
				dps = "Physical damage works best while his Anti-Magic Shield is up.",
			},
		},
		{
			name = "Rath'mael",
			overview = "The last boss of the Ruins.",
			lore = "A skeletal mage of the Scourge, in command of the ruins' restless dead.",
			strategy = {
				summary = "He shields himself with Fire Shield and casts Flamestrike: a pillar of fire on the ground that keeps burning for several seconds.",
				healer = "Flamestrike burns everyone who stays in it.",
				dps = "Move out of the Flamestrike zone at once.",
			},
		},
		{
			name = "Lordaeron Captain",
			optional = true,
			overview = "A rare spirit that may appear in the Ruins.",
			lore = "A rare ghost of a captain who died defending the city.",
			strategy = { summary = "A rare fight. Kill him for his loot." },
			loot = {
				{ name = "Haunting Blade", slot = "Two-Hand Sword" },
				{ name = "Phantom Armor", slot = "Plate Chest" },
			},
		},
	},
})
