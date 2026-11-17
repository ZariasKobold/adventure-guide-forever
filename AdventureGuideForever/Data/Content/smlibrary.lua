-- Scarlet Monastery Library: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smlibrary", {
	intro = "The Crusade keeps its forbidden lore in the Library.",
	lore = "The Library holds the Crusade's forbidden knowledge: books they have gathered, and books they mean to burn. Arcanist Doan guards it jealously, and the Crusade's hounds patrol the halls.",
	route = "Pass Houndmaster Loksey in the main hall, then follow the shelves to Arcanist Doan's chamber at the end.",
	tips = {
		"The Library holds a key to the Armory and Cathedral wings. Finish here first.",
		"Doan's room has an arcane bubble trick. Read his strategy before pulling.",
	},
	bosses = {
		{
			name = "Houndmaster Loksey",
			overview = "Fights with his hounds.",
			lore = "The Crusade's dog handler.",
			strategy = { summary = "He calls his hounds and boosts himself.", dps = "Kill the hounds first." },
			abilities = {
				{ name = "Summon Hounds", alerts = { "dps" }, text = "Calls his dogs into the fight." },
			},
		},
		{
			name = "Arcanist Doan",
			overview = "The keeper of the Library.",
			lore = "The keeper of the Library's secrets.",
			strategy = {
				summary = "At low health he shields himself in an arcane bubble, then explodes. Run away from him.",
				dps = "When the bubble goes up, everyone should step back.",
			},
			abilities = {
				{ name = "Arcane Explosion", alerts = { "dps" }, text = "Arcane damage around him." },
				{ name = "Detonation", alerts = { "deadly" }, text = "He shields himself, then blows up. Run away." },
			},
		},
	},
})
