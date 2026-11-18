-- Lower Blackrock Spire: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("lbrs", {
	intro = "The lower floors of the Spire, held by the Blackrock orcs and their ogre allies.",
	lore = "Lower Blackrock Spire holds the Blackrock orcs and the ogres who serve them, in the upper reaches of Blackrock Mountain. The Dark Horde is gathering here under Warchief Rend Blackhand, and the black dragons pull the strings from above.",
	route = "Lower Spire branches out widely. Highlord Omokk guards the start, and the troll leaders and Mother Smolderweb hold their own rooms. Halycon and Gizrul wait near the end, and Overlord Wyrmthalak guards the top.",
	tips = {
		"Pick up the seal for Upper Spire here: it's a quest reward.",
		"Many rare elites (the Spirestone trio, Bannok, Ghok) can appear. Kill them for loot.",
		"Mother Smolderweb's spiderlings come in big waves.",
	},
	bosses = {
		{
			name = "Highlord Omokk",
			overview = "The two-headed ogre leader.",
			lore = "The two-headed ogre leader.",
			strategy = { summary = "He knocks the tank back." },
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him.", spellID = 5532 },
			},
		},
		{
			name = "Shadow Hunter Vosh'gajin",
			overview = "A troll shadow hunter.",
			lore = "A troll shadow hunter.",
			strategy = { summary = "She curses and hexes players." },
			abilities = {
				{ name = "Hex", alerts = { "magic" }, text = "Turns a player into a frog." },
			},
		},
		{
			name = "War Master Voone",
			overview = "A troll warrior.",
			lore = "A troll warrior.",
			strategy = { summary = "A fast melee fight with many attacks." },
		},
		{
			name = "Mother Smolderweb",
			overview = "A giant spider in her nest.",
			lore = "A giant spider in her nest.",
			strategy = { summary = "She stuns players and calls spiderlings.", dps = "Kill the spiderlings." },
			abilities = {
				{ name = "Crystallize", alerts = { "magic" }, text = "Stuns a player." },
			},
		},
		{
			name = "Urok Doomhowl",
			overview = "Summoned with a challenge banner.",
			lore = "Summoned with a challenge banner.",
			strategy = { summary = "Waves of ogres come before him." },
		},
		{
			name = "Quartermaster Zigris",
			overview = "Keeps the orcs supplied.",
			lore = "The supply officer of the Dark Horde.",
			strategy = { summary = "He nets players and drinks healing potions." },
		},
		{
			name = "Halycon",
			overview = "A worg mother.",
			lore = "A worg mother.",
			strategy = { summary = "A melee fight. Her mate Gizrul comes after she falls." },
		},
		{
			name = "Gizrul the Slavener",
			overview = "Halycon's mate, who comes after she falls.",
			lore = "Halycon's mate.",
			strategy = { summary = "He arrives after Halycon dies and enrages." },
		},
		{
			name = "Overlord Wyrmthalak",
			overview = "The orc overlord. The last boss.",
			lore = "The orc overlord.",
			strategy = { summary = "He calls guards at low health.", dps = "Burn him down before they arrive." },
			abilities = {
				{ name = "Call Guards", alerts = { "dps", "important" }, text = "Calls guards at low health." },
			},
		},
		{
			name = "Burning Felguard",
			overview = "A rare demon summoned in the Spire.",
			lore = "A rare demon guard.",
			strategy = { summary = "He has a fire shield and stomps nearby players." },
		},
		{
			name = "Spirestone Battle Lord",
			overview = "A rare ogre warrior.",
			lore = "A rare ogre warrior of the Spirestone clan.",
			strategy = { summary = "An easy rare fight." },
		},
		{
			name = "Spirestone Butcher",
			overview = "A rare ogre butcher.",
			lore = "A rare ogre butcher.",
			strategy = { summary = "An easy rare fight." },
		},
		{
			name = "Bannok Grimaxe",
			overview = "A rare orc warrior.",
			lore = "A rare Blackrock warrior.",
			strategy = { summary = "An easy rare fight." },
		},
		{
			name = "Spirestone Lord Magus",
			overview = "A rare ogre mage.",
			lore = "A rare ogre mage.",
			strategy = { summary = "He polymorphs players. Interrupt him." },
		},
		{
			name = "Ghok Bashguud",
			overview = "A rare ogre brute.",
			lore = "A rare ogre brute.",
			strategy = { summary = "An easy rare fight." },
		},
		{
			name = "Crystal Fang",
			overview = "A rare giant spider.",
			lore = "A rare spider.",
			strategy = { summary = "She calls spiderlings." },
		},
	},
})
