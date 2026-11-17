-- Zul'Farrak: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("zulfarrak", {
	intro = "The Sandfury trolls rule from this sun-baked city in Tanaris.",
	lore = "Zul'Farrak is the sun-baked city of the Sandfury trolls in Tanaris. The Sandfury hold prisoners for sacrifice and dark rituals, and their chief Ukorz rules from the pyramid at the city's heart.",
	route = "Enter the city and pass Antu'sul and Theka. Then free the prisoners on top of the pyramid. That starts a huge wave of trolls up the stairs, ending with Nekrum and Sezz'ziz. Afterward, go into the city to fight Ukorz and Ruuzlu, and Hydromancer Velratha at the sacred pool.",
	tips = {
		"The pyramid stair event is the hardest part. Stand together at the top and let the trolls come to you.",
		"You need a special mallet to summon Gahz'rilla at the sacred pool.",
		"The dead come back from the graveyard, so clear quickly.",
	},
	bosses = {
		{
			name = "Antu'sul",
			overview = "The trolls' basilisk keeper.",
			lore = "The Sandfury's basilisk keeper.",
			strategy = { summary = "He calls basilisks at low health and heals himself.", dps = "Kill the basilisks, and interrupt his heals." },
			abilities = {
				{ name = "Summon Basilisks", alerts = { "dps" }, text = "Calls basilisks to help at low health." },
			},
		},
		{
			name = "Theka the Martyr",
			overview = "Turns into a scarab beetle that takes no physical damage.",
			lore = "A troll who becomes a scarab beetle.",
			strategy = { summary = "As a beetle he takes no physical damage. Use spells to finish him." },
			abilities = {
				{ name = "Theka Transform", alerts = { "important" }, text = "As a beetle he's immune to physical damage. Use spells." },
			},
		},
		{
			name = "Witch Doctor Zum'rah",
			overview = "Raises zombies from the graveyard.",
			lore = "A witch doctor who raises zombies from the graves.",
			strategy = { summary = "Zombies climb out of the graves around him, and he shoots shadow bolts.", dps = "Kill his ward first." },
			abilities = {
				{ name = "Zombies", alerts = { "dps" }, text = "Zombies climb out of graves." },
				{ name = "Shadow Bolt Volley", alerts = { "healer" }, text = "Shadow damage on everyone." },
			},
		},
		{
			name = "Sergeant Bly",
			overview = "Leads the prisoners on the pyramid steps. Part of the stair event.",
			lore = "A prisoner who joins the stair event.",
			strategy = { summary = "Part of the pyramid event. A melee fight." },
		},
		{
			name = "Nekrum Gutchewer",
			overview = "Joins the fight after the stair event.",
			lore = "A troll who joins after the stair event.",
			strategy = { summary = "He fights alongside Sezz'ziz. A melee fight." },
		},
		{
			name = "Shadowpriest Sezz'ziz",
			overview = "A priest at the top of the stairs.",
			lore = "A priest at the top of the stairs.",
			strategy = { summary = "He heals and fears.", dps = "Interrupt his heals." },
			abilities = {
				{ name = "Heal", alerts = { "interrupt" }, text = "Heals allies. Interrupt it." },
			},
		},
		{
			name = "Hydromancer Velratha",
			overview = "A troll water caster at the sacred pool.",
			lore = "A troll water caster at the sacred pool.",
			strategy = { summary = "She heals herself. Interrupt her." },
			abilities = {
				{ name = "Healing Wave", alerts = { "interrupt" }, text = "Heals herself." },
			},
		},
		{
			name = "Gahz'rilla",
			optional = true,
			overview = "A giant hydra, summoned at the pool with a special mallet.",
			lore = "A giant hydra, summoned with a special mallet.",
			strategy = { summary = "He freezes the tank and throws players into the air.", healer = "Heal through the freezes." },
			abilities = {
				{ name = "Freeze Solid", alerts = { "tank" }, text = "Freezes the tank in place." },
				{ name = "Gahz'rilla Slam", alerts = { "important" }, text = "Throws players into the air." },
			},
		},
		{
			name = "Chief Ukorz Sandscalp",
			overview = "The Sandfury chief, fighting beside his bodyguard Ruuzlu.",
			lore = "The Sandfury chief, fighting beside his bodyguard Ruuzlu.",
			strategy = { summary = "He cleaves and enrages at low health.", tank = "Turn him away from the group." },
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him." },
				{ name = "Enrage", alerts = { "enrage" }, text = "Enrages at low health." },
			},
		},
		{
			name = "Dustwraith",
			overview = "A rare desert spirit that roams Zul'Farrak.",
			lore = "A rare desert spirit.",
			strategy = { summary = "It poisons its target. Cure the poison if you can." },
		},
		{
			name = "Sandarr Dunereaver",
			overview = "A rare Sandfury warrior.",
			lore = "A rare Sandfury warrior.",
			strategy = { summary = "A melee fight. He interrupts casters." },
		},
		{
			name = "Zerillis",
			overview = "A rare troll hunter.",
			lore = "A rare troll hunter.",
			strategy = { summary = "He nets players and shoots frost arrows." },
		},
	},
})
