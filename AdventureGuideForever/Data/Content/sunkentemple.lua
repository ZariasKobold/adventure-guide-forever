-- Temple of Atal'Hakkar: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("sunkentemple", {
	intro = "The Atal'ai trolls built this temple to summon Hakkar. It sank into the swamp, and the green dragonflight guards it.",
	bosses = {
		{
			name = "Atal'alarion",
			overview = "A stone guardian summoned on the temple's lower floor.",
			abilities = {
				{ name = "Sweeping Slam", alerts = { "tank", "dps" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Jammal'an the Prophet",
			overview = "The Atal'ai prophet, beside Ogom.",
			abilities = {
				{ name = "Hex of Jammal'an", alerts = { "magic" }, text = "Turns a player into a frog." },
				{ name = "Earthgrab Totem", alerts = { "dps" }, text = "Roots nearby players. Destroy the totem." },
			},
		},
		{ name = "Ogom the Wretched", overview = "A cursed troll fighting with Jammal'an." },
		{
			name = "Dreamscythe",
			npcID = 5721,
			overview = "A green dragon guarding the temple.",
			abilities = {
				{ name = "Acid Breath", alerts = { "tank" }, text = "Damages and weakens the tank." },
			},
		},
		{
			name = "Weaver",
			npcID = 5720,
			overview = "A green dragon guarding the temple.",
			abilities = {
				{ name = "Wing Flap", alerts = { "tank" }, text = "Knocks players back." },
			},
		},
		{ name = "Morphaz", npcID = 5719, overview = "A green dragon guarding the temple." },
		{ name = "Hazzas", npcID = 5722, overview = "A green dragon guarding the temple." },
		{
			name = "Shade of Eranikus",
			overview = "The ghost of a green dragon trapped in the temple.",
			abilities = {
				{ name = "Deep Slumber", alerts = { "important" }, text = "Puts everyone to sleep." },
				{ name = "Acid Breath", alerts = { "tank" }, text = "Damages and weakens the tank." },
			},
		},
		{
			name = "Avatar of Hakkar",
			optional = true,
			npcID = 8443,
			overview = "Summoned by stopping the Atal'ai ritual. Optional.",
			abilities = {
				{ name = "Curse of Tongues", alerts = { "curse" }, text = "Slows casting." },
			},
		},
	},
})
