-- Blackrock Depths: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("brd", {
	intro = "The Dark Iron dwarves' capital, built under Blackrock Mountain and ruled by Emperor Dagran Thaurissan.",
	lore = "Blackrock Depths is the capital of the Dark Iron dwarves, carved deep inside Blackrock Mountain. Emperor Dagran Thaurissan rules here, serving the fire lord Ragnaros. He has taken Princess Moira Bronzebeard, daughter of Ironforge's king, as his bride.",
	route = "BRD is huge and full of branches. The detention block holds Gerstahn; the Ring of Law is the arena. Go through the city past the Lyceum, the Grim Guzzler tavern and the Black Anvil, then to the throne room with Magmus and Emperor Thaurissan.",
	tips = {
		"BRD is huge. Split it into several runs, or pick the wing you need.",
		"The Grim Guzzler is a tavern. Don't start a fight there unless you mean to.",
		"Many quests need you to reach the throne room.",
	},
	bosses = {
		{
			name = "High Interrogator Gerstahn",
			overview = "Runs the detention block.",
			lore = "The Dark Iron interrogator who runs the detention block.",
			strategy = { summary = "She shields herself, burns mana and casts shadow spells.", healer = "Watch your mana." },
			abilities = {
				{ name = "Psychic Scream", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{
			name = "Lord Roccor",
			overview = "A fire elemental.",
			lore = "A fire elemental lord.",
			strategy = { summary = "He shakes the ground and casts flame shock." },
			abilities = {
				{ name = "Earth Shock", alerts = { "interrupt" }, text = "Nature damage." },
			},
		},
		{
			name = "Houndmaster Grebmar",
			overview = "Fights with his hounds.",
			lore = "The keeper of the Dark Iron hounds.",
			strategy = { summary = "He boosts himself and his hounds. Kill the hounds." },
		},
		{
			name = "Ring of Law",
			overview = "The arena. Random beasts and fighters, then a final boss.",
			lore = "The arena of the Dark Irons, where prisoners fight for the crowd.",
			strategy = { summary = "Random beasts and fighters come into the arena. The opponents change every time." },
			abilities = {
				{ name = "Random Champions", alerts = { "important" }, text = "The opponents change every time." },
			},
		},
		{
			name = "Pyromancer Loregrain",
			overview = "A Dark Iron fire caster.",
			lore = "A Dark Iron fire caster.",
			strategy = { summary = "He drops fire totems. Destroy them." },
			abilities = {
				{ name = "Molten Blast", alerts = { "healer" }, text = "Fire damage." },
			},
		},
		{
			name = "Lord Incendius",
			overview = "A fire lord at the Black Anvil.",
			lore = "A fire lord at the Black Anvil.",
			strategy = { summary = "He curses players and blasts them with fire." },
			abilities = {
				{ name = "Fire Storm", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Warder Stilgiss",
			overview = "Guards the vault.",
			lore = "A frost caster guarding the vault.",
			strategy = { summary = "He freezes and slows players." },
		},
		{
			name = "Fineous Darkvire",
			overview = "The chief architect of the city.",
			lore = "The Dark Iron chief architect.",
			strategy = { summary = "He heals himself. Interrupt his Holy Light." },
		},
		{
			name = "Bael'Gar",
			overview = "A giant elemental summoned in the Lyceum.",
			lore = "A giant elemental summoned in the Lyceum.",
			strategy = { summary = "He summons spawns. Kill them." },
		},
		{
			name = "General Angerforge",
			overview = "Calls for help at low health.",
			lore = "The Dark Iron general.",
			strategy = { summary = "Dwarves pour in at low health.", dps = "Burn him down before the reinforcements arrive, or crowd-control them." },
			abilities = {
				{ name = "Call Reinforcements", alerts = { "dps", "important" }, text = "Dwarves pour in at low health." },
			},
		},
		{
			name = "Golem Lord Argelmach",
			overview = "Wakes golems as you approach.",
			lore = "The master of the Dark Iron golems.",
			strategy = { summary = "Golems join the fight as you approach. He casts chain lightning." },
		},
		{
			name = "Hurley Blackbreath",
			overview = "A brewer in the Grim Guzzler.",
			lore = "A brewer in the Grim Guzzler.",
			strategy = { summary = "He breathes fire and gets drunk and angry." },
		},
		{
			name = "Phalanx",
			overview = "A golem guard in the Grim Guzzler.",
			lore = "The Grim Guzzler's golem bouncer.",
			strategy = { summary = "He hits hard and throws fireballs." },
		},
		{
			name = "Plugger Spazzring",
			overview = "The Grim Guzzler's barkeep.",
			lore = "The Grim Guzzler's barkeep.",
			strategy = { summary = "He banishes and curses players." },
		},
		{
			name = "Ambassador Flamelash",
			overview = "Summons fire spirits to the room.",
			lore = "A fire ambassador from Ragnaros.",
			strategy = { summary = "Fire spirits run to him and empower him. Kill them before they reach him." },
			abilities = {
				{ name = "Burning Spirit", alerts = { "dps" }, text = "Fire spirits run to him and empower him." },
			},
		},
		{
			name = "The Seven",
			overview = "Seven dwarf spirits that fight one at a time.",
			lore = "Seven dwarf spirits who fight one at a time.",
			strategy = { summary = "Each spirit fights with its own skills. They come one at a time." },
		},
		{
			name = "Magmus",
			overview = "A giant golem guarding the throne room.",
			lore = "A giant golem guarding the throne room.",
			strategy = { summary = "The statues breathe fire on the room. Stay out of the jets." },
			abilities = {
				{ name = "Fire Jets", alerts = { "important" }, text = "The room's statues breathe fire." },
			},
		},
		{
			name = "Emperor Dagran Thaurissan",
			overview = "The emperor, with Princess Moira at his side. The last boss.",
			lore = "The Dark Iron emperor, with Princess Moira at his side.",
			strategy = { summary = "He stuns the tank and burns the room. Moira heals him.", dps = "Interrupt or control Moira." },
			abilities = {
				{ name = "Hand of Thaurissan", alerts = { "tank" }, text = "Stuns the tank." },
				{ name = "Avatar of Flame", alerts = { "important" }, text = "Fire damage around him." },
				{ name = "Princess Moira", alerts = { "interrupt" }, text = "Moira heals the emperor. Interrupt or control her." },
			},
		},
		{
			name = "Ribbly Screwspigot",
			overview = "A goblin hiding out in the Grim Guzzler.",
			lore = "A goblin with a price on his head.",
			strategy = { summary = "He gouges, hamstrings and can mind-control a player with a gnomish cap." },
		},
		{
			name = "Panzor the Invincible",
			overview = "A rare golem in the detention block.",
			lore = "A rare golem guard.",
			strategy = { summary = "An easy rare. Kill it for its loot." },
		},
		{
			name = "Verek",
			overview = "A giant Dark Iron dog.",
			lore = "A huge war hound.",
			strategy = { summary = "He curses players with Curse of Blood." },
		},
	},
})
