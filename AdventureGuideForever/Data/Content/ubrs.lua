-- Upper Blackrock Spire: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ubrs", {
	intro = "The upper Spire, where the Black Dragonflight and the Dark Horde gather.",
	bosses = {
		{
			name = "Pyroguard Emberseer",
			overview = "A fire elemental held in place by Blackhand Incarcerators.",
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{ name = "Solakar Flamewreath", overview = "Guards the rookery. Appears after you disturb the eggs." },
		{
			name = "Warchief Rend Blackhand",
			alsoNamed = { "Gyth" },
			overview = "The warchief of the Dark Horde, riding Gyth into the arena.",
			abilities = {
				{ name = "Waves", alerts = { "important" }, text = "Waves of orcs and dragonkin first, then Gyth and Rend." },
				{ name = "Whirlwind", alerts = { "dps" }, text = "Rend spins and hits everyone nearby." },
			},
		},
		{
			name = "The Beast",
			overview = "A huge core hound.",
			abilities = {
				{ name = "Fire Blast", alerts = { "healer" }, text = "Fire damage." },
				{ name = "Terrifying Roar", alerts = { "important" }, text = "Fears everyone nearby." },
			},
		},
		{
			name = "General Drakkisath",
			overview = "The black dragonkin general. The last boss.",
			abilities = {
				{ name = "Flamestrike", alerts = { "dps" }, text = "Fire on the ground. Step out." },
				{ name = "Cleave", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{ name = "Jed Runewatcher", optional = true, overview = "A rare orc." },
		{ name = "Goraluk Anvilcrack", optional = true, overview = "The Spire's blacksmith." },
	},
})
