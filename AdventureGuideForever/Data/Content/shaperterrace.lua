-- Shaper's Terrace: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("shaperterrace", {
	intro = "A titan site in Un'Goro Crater, new in Forever. Its guide will grow as it's explored.",
	lore = "Un'Goro Crater was shaped by the titans, and the Shaper's Terrace is one of their places. Little is known yet about what waits inside.",
	tips = { "No guide has been published for this dungeon yet.", "Run it with learning mode on: bosses, loot and abilities will fill in as you play." },
})
