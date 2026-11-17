-- Lower Blackrock Spire: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("lbrs", {
	intro = "The lower floors of the Spire, held by the Blackrock orcs and their ogre allies.",
	bosses = {
		{
			name = "Highlord Omokk",
			overview = "The two-headed ogre leader.",
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Shadow Hunter Vosh'gajin",
			overview = "A troll shadow hunter.",
			abilities = {
				{ name = "Hex", alerts = { "magic" }, text = "Turns a player into a frog." },
			},
		},
		{ name = "War Master Voone", overview = "A troll warrior." },
		{
			name = "Mother Smolderweb",
			overview = "A giant spider in her nest.",
			abilities = {
				{ name = "Crystallize", alerts = { "magic" }, text = "Stuns a player." },
			},
		},
		{ name = "Urok Doomhowl", overview = "Summoned with a challenge banner." },
		{ name = "Quartermaster Zigris", overview = "Keeps the orcs supplied." },
		{ name = "Halycon", overview = "A worg mother." },
		{ name = "Gizrul the Slavener", overview = "Halycon's mate, who comes after she falls." },
		{
			name = "Overlord Wyrmthalak",
			overview = "The orc overlord. The last boss.",
			abilities = {
				{ name = "Call Guards", alerts = { "dps", "important" }, text = "Calls guards at low health." },
			},
		},
	},
})
