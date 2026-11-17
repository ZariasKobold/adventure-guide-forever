-- Stormwind Stockade: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("stockade", {
	intro = "Stormwind's prison has fallen to a riot led by the Defias.",
	lore = "The Stockade is Stormwind's prison, set in the canals at the heart of the city. A riot has broken out: the inmates, led by Defias Brotherhood agents, have taken over the cell blocks. The city guard has sealed the gates and is looking for help to take it back.",
	route = "The prison is a hub with three wings. Clear each wing and its boss in whatever order you like: Targorr, Kam Deepfury, Hamhock, Bazil Thredd and Dextren Ward. Bruegal Ironknuckle sometimes lurks in one of the cells.",
	tips = {
		"Pick up the Stockade quests in Stormwind and Westfall before you go in.",
		"The halls are tight and packs aggro easily. Pull slowly.",
		"It's a short dungeon, so it's good for a quick run.",
	},
	bosses = {
		{
			name = "Targorr the Dread",
			overview = "A brutal prisoner who enrages when hurt.",
			lore = "A brutal inmate who now runs his corner of the prison.",
			strategy = { summary = "He frenzies at low health.", tank = "Save a cooldown for his frenzy." },
			abilities = {
				{ name = "Enrage", alerts = { "enrage", "tank" }, text = "Hits faster at low health." },
			},
		},
		{
			name = "Kam Deepfury",
			overview = "A Dark Iron prisoner.",
			lore = "A Dark Iron dwarf prisoner who leads the dwarven inmates.",
			strategy = { summary = "He blocks and stuns like a warrior. A straightforward fight." },
			abilities = {
				{ name = "Shield Slam", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "Hamhock",
			overview = "An ogre who throws chains of lightning.",
			lore = "An ogre inmate who throws lightning.",
			strategy = { summary = "His chain lightning jumps between players, and he can speed himself up.", dps = "Spread out to limit the chain lightning." },
			abilities = {
				{ name = "Chain Lightning", alerts = { "healer" }, text = "Lightning that jumps between players." },
				{ name = "Bloodlust", alerts = { "enrage" }, text = "Speeds up his attacks." },
			},
		},
		{
			name = "Bazil Thredd",
			overview = "The Defias leader of the riot.",
			lore = "The Defias agent who started the riot.",
			strategy = { summary = "He throws smoke bombs that stun the tank." },
			abilities = {
				{ name = "Smoke Bomb", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "Dextren Ward",
			overview = "A mad prisoner who fears and stabs.",
			lore = "A deranged prisoner who loves a fight.",
			strategy = { summary = "He fears nearby players.", healer = "Stand back so his shout doesn't reach you." },
			abilities = {
				{ name = "Intimidating Shout", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{
			name = "Bruegal Ironknuckle",
			optional = true,
			overview = "A rare prisoner hidden in the stockade.",
			lore = "A rare dwarf prisoner hiding in a cell.",
			strategy = { summary = "An easy rare fight with good loot." },
		},
	},
})
