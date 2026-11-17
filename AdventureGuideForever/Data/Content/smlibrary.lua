-- Scarlet Monastery Library: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smlibrary", {
	intro = "The Crusade keeps its forbidden lore in the Library.",
	bosses = {
		{
			name = "Houndmaster Loksey",
			overview = "Fights with his hounds.",
			abilities = {
				{ name = "Summon Hounds", alerts = { "dps" }, text = "Calls his dogs into the fight." },
			},
		},
		{
			name = "Arcanist Doan",
			overview = "The keeper of the Library.",
			abilities = {
				{ name = "Arcane Explosion", alerts = { "dps" }, text = "Arcane damage around him." },
				{ name = "Detonation", alerts = { "deadly" }, text = "He shields himself, then blows up. Run away." },
			},
		},
	},
})
