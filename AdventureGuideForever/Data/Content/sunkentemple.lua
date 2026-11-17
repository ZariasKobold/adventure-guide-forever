-- Temple of Atal'Hakkar: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("sunkentemple", {
	intro = "The Atal'ai trolls built this temple to summon Hakkar. It sank into the swamp, and the green dragonflight guards it.",
	lore = "The Temple of Atal'Hakkar was built by the Atal'ai trolls to summon Hakkar the Soulflayer. When the green dragonflight saw what they were doing, they sank the temple into the Swamp of Sorrows. The Atal'ai still worship in its drowned halls, and green dragons guard the temple so Hakkar can never return.",
	route = "Go down through the temple's flooded rings to its lower floors. Light the statues to wake Atal'alarion. Then climb to fight the Atal'ai and the green dragons, with Jammal'an, Ogom and the Shade of Eranikus at the top.",
	tips = {
		"The temple is easy to get lost in. Follow the outer ring.",
		"Lighting the statues in the right order is a puzzle. Look it up or take your time.",
		"The Avatar of Hakkar is optional; you can summon him with a quest item.",
	},
	bosses = {
		{
			name = "Atal'alarion",
			overview = "A stone guardian summoned on the temple's lower floor.",
			lore = "A stone guardian awoken on the temple's lower floor.",
			strategy = { summary = "He sweeps in front of him and shakes the ground.", tank = "Turn him away from the group." },
			abilities = {
				{ name = "Sweeping Slam", alerts = { "tank", "dps" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Jammal'an the Prophet",
			overview = "The Atal'ai prophet, beside Ogom.",
			lore = "The Atal'ai prophet who leads the cult.",
			strategy = { summary = "He turns players into frogs and drops totems.", dps = "Destroy his Earthgrab Totem." },
			abilities = {
				{ name = "Hex of Jammal'an", alerts = { "magic" }, text = "Turns a player into a frog." },
				{ name = "Earthgrab Totem", alerts = { "dps" }, text = "Roots nearby players. Destroy the totem." },
			},
		},
		{
			name = "Ogom the Wretched",
			overview = "A cursed troll fighting with Jammal'an.",
			lore = "A cursed troll who fights beside Jammal'an.",
			strategy = { summary = "He casts shadow spells and curses." },
		},
		{
			name = "Dreamscythe",
			npcID = 5721,
			overview = "A green dragon guarding the temple.",
			lore = "A green dragon guarding the temple.",
			strategy = { summary = "He breathes acid on the tank. Turn him away from the group." },
			abilities = {
				{ name = "Acid Breath", alerts = { "tank" }, text = "Damages and weakens the tank." },
			},
		},
		{
			name = "Weaver",
			npcID = 5720,
			overview = "A green dragon guarding the temple.",
			lore = "A green dragon guarding the temple.",
			strategy = { summary = "His wing flaps knock players back. Stand with your backs to a wall." },
			abilities = {
				{ name = "Wing Flap", alerts = { "tank" }, text = "Knocks players back." },
			},
		},
		{
			name = "Morphaz",
			npcID = 5719,
			overview = "A green dragon guarding the temple.",
			lore = "A green dragon guarding the temple.",
			strategy = { summary = "A dragon fight. Turn him away from the group." },
		},
		{
			name = "Hazzas",
			npcID = 5722,
			overview = "A green dragon guarding the temple.",
			lore = "A green dragon guarding the temple.",
			strategy = { summary = "A dragon fight. Turn him away from the group." },
		},
		{
			name = "Shade of Eranikus",
			overview = "The ghost of a green dragon trapped in the temple.",
			lore = "The ghost of a green dragon trapped in the temple.",
			strategy = { summary = "He puts everyone to sleep and breathes acid.", tank = "Turn him away from the group." },
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
			lore = "An avatar of the blood god, summoned by stopping the Atal'ai ritual.",
			strategy = { summary = "He curses players. It's an optional fight." },
			abilities = {
				{ name = "Curse of Tongues", alerts = { "curse" }, text = "Slows casting." },
			},
		},
	},
})
