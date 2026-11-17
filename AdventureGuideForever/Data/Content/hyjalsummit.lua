-- Hyjal Summit: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("hyjalsummit", {
	intro = "Hyjal Summit sits atop Mount Hyjal. Opens December 9.",
	lore = "Hyjal Summit is the sacred mountain where the night elves planted their World Tree. Now a nightmare has taken root on the summit, and Nythus the Dreambound waits at its top.",
	tips = { "This raid opens on December 9, 2026.", "Bosses, loot and abilities will be added as players learn the raid." },
	bosses = {
		{ name = "Bandalar" },
		{ name = "Time-Lost Battalion" },
		{ name = "Old Gloomlurker" },
		{ name = "Kathris the Haunted" },
		{ name = "Elder Minderel" },
		{ name = "Council of Thorns" },
		{ name = "The Wild King" },
		{ name = "Ancient of Decay" },
		{ name = "Sylvesteris Dusksong" },
		{ name = "Gharalis the Abyssal" },
		{ name = "Anara Chillwind" },
		{ name = "Tracker Stillwind" },
		{ name = "Nythus the Dreambound" },
	},
})
