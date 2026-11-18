-- Upper Blackrock Spire: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ubrs", {
	intro = "The upper Spire, where the Black Dragonflight and the Dark Horde gather.",
	lore = "Upper Blackrock Spire is the stronghold of the Dark Horde and the black dragonflight. Warchief Rend Blackhand rules the arena, and General Drakkisath commands the black dragonkin who serve Nefarian.",
	route = "Free Pyroguard Emberseer, then disturb the eggs to draw out Solakar. Go into the arena to fight Rend, then past The Beast to Drakkisath's hall at the top.",
	tips = {
		"You need the Seal of Ascension to enter.",
		"The arena is a long fight: waves of orcs and dragonkin come before Rend.",
		"Drakkisath drops tier 0 armor.",
	},
	bosses = {
		{
			name = "Pyroguard Emberseer",
			overview = "A fire elemental held in place by Blackhand Incarcerators.",
			lore = "A fire elemental held in place by Blackhand Incarcerators.",
			strategy = { summary = "Kill the incarcerators, then fight him. He uses fire nova." },
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Solakar Flamewreath",
			overview = "Guards the rookery. Appears after you disturb the eggs.",
			lore = "The guardian of the rookery.",
			strategy = { summary = "Waves of dragonkin come when you disturb the eggs." },
		},
		{
			name = "Warchief Rend Blackhand",
			alsoNamed = { "Gyth" },
			overview = "The warchief of the Dark Horde, riding Gyth into the arena.",
			lore = "The warchief of the Dark Horde.",
			strategy = {
				summary = "Waves of orcs and dragonkin come first, then Gyth and Rend.",
				dps = "Rend spins in a whirlwind. Melee players should step out.",
			},
			abilities = {
				{ name = "Waves", alerts = { "important" }, text = "Waves of orcs and dragonkin first, then Gyth and Rend." },
				{ name = "Whirlwind", alerts = { "dps" }, text = "Rend spins and hits everyone nearby." },
				{ name = "Thunderclap", alerts = { "dps" }, text = "Damages and slows everyone nearby.", spellID = 15588 },
			},
		},
		{
			name = "The Beast",
			overview = "A huge core hound.",
			lore = "A huge core hound.",
			strategy = { summary = "He fears everyone nearby and throws fire.", tank = "Use a fear immunity if you can." },
			abilities = {
				{ name = "Fire Blast", alerts = { "healer" }, text = "Fire damage." },
				{ name = "Terrifying Roar", alerts = { "important" }, text = "Fears everyone nearby." },
				{ name = "Fear", alerts = { "important" }, text = "A roar that fears everyone nearby.", spellID = 5782 },
			},
		},
		{
			name = "General Drakkisath",
			overview = "The black dragonkin general. The last boss.",
			lore = "The black dragonkin general.",
			strategy = { summary = "He sets fire on the ground and cleaves.", tank = "Turn him away from the group.", dps = "Move out of the fire." },
			abilities = {
				{ name = "Flamestrike", alerts = { "dps" }, text = "Fire on the ground. Step out." },
				{ name = "Cleave", alerts = { "tank" }, text = "Hits everyone in front of him." },
				{
					name = "Conflagration",
					alerts = { "important" },
					text = "Sets a player ablaze and sends them running; stay away from them.",
					spellID = 16805,
				},
			},
		},
		{
			name = "Jed Runewatcher",
			optional = true,
			overview = "A rare orc.",
			lore = "A rare orc.",
			strategy = { summary = "An easy rare fight." },
			abilities = {
				{ name = "Charge", alerts = { "important" }, text = "Charges a player.", spellID = 100 },
				{ name = "Heroic Strike", alerts = { "tank" }, text = "A heavy hit on the tank.", spellID = 25710 },
			},
		},
		{
			name = "Goraluk Anvilcrack",
			optional = true,
			overview = "The Spire's blacksmith.",
			lore = "The Spire's blacksmith.",
			strategy = { summary = "A melee fight." },
			abilities = {
				{ name = "Heroic Strike", alerts = { "tank" }, text = "A heavy hit on the tank.", spellID = 25710 },
			},
		},
		{
			name = "Mor Grayhoof",
			overview = "A tauren druid's spirit, summoned with a brazier.",
			lore = "A tauren druid's spirit.",
			strategy = { summary = "He changes forms and heals himself." },
		},
		{
			name = "Lord Valthalak",
			overview = "A spirit summoned with a brazier.",
			lore = "An ancient spirit bound in the Spire.",
			strategy = { summary = "He summons assassins and casts shadow volleys." },
		},
	},
})
