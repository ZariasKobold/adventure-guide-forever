-- Ruins of Lordaeron: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ruinslordaeron", {
	intro = "The Scourge stirs again in the broken halls of Lordaeron, above the Undercity.",
	bosses = {
		{ name = "Witherfang" },
		{ name = "The Baron" },
		{ name = "Viktor the Vile" },
		{ name = "The Abandoned" },
		{ name = "Bjork" },
		{ name = "Rath'mael", overview = "The last boss of the Ruins." },
		{
			name = "Lordaeron Captain",
			optional = true,
			overview = "A rare spirit that may appear in the Ruins.",
			loot = {
				{ name = "Haunting Blade", slot = "Two-Hand Sword" },
				{ name = "Phantom Armor", slot = "Plate Chest" },
			},
		},
	},
})
