-- Razorfen Downs: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("razorfendowns", {
	intro = "The Scourge has taken the quilboar's sacred burial grounds.",
	lore = "Razorfen Downs was the quilboar's holy burial ground. Now the Scourge has claimed it. The lich Amnennar the Coldbringer has raised the quilboar dead, and his followers spread his plague across the Barrens.",
	route = "Climb the thorny paths past Tuten'kash, who is summoned with the gong, and past Mordresh and Glutton. Then follow the trail up to Amnennar's lair at the top.",
	tips = {
		"Ring the gong to summon Tuten'kash. Waves of spiders come first.",
		"Undead quilboar and plague spreaders are everywhere. Bring disease cures if you can.",
	},
	bosses = {
		{
			name = "Tuten'kash",
			overview = "A giant spider summoned by ringing the gong.",
			lore = "A giant spider summoned by the gong.",
			strategy = { summary = "He curses players and webs them in place." },
			abilities = {
				{ name = "Web Spray", alerts = { "healer" }, text = "Webs players in place." },
				{ name = "Virulent Poison", alerts = { "poison", "tank" }, text = "Its attacks can poison the tank. Cure it.", spellID = 12254 },
			},
		},
		{
			name = "Mordresh Fire Eye",
			overview = "A quilboar undead caster.",
			lore = "A quilboar shaman turned to undeath.",
			strategy = { summary = "He fires fireballs and fire novas.", dps = "Interrupt his casts." },
			abilities = {
				{ name = "Fireball", alerts = { "interrupt" }, text = "Fire damage." },
			},
		},
		{
			name = "Glutton",
			overview = "A bloated undead quilboar.",
			lore = "A bloated undead quilboar.",
			strategy = { summary = "He enrages at low health.", healer = "His disease cloud hits everyone near him." },
			abilities = {
				{ name = "Disease Cloud", alerts = { "disease", "healer" }, text = "Diseases everyone nearby." },
			},
		},
		{
			name = "Amnennar the Coldbringer",
			overview = "The lich who leads the Scourge here.",
			lore = "The lich who rules the Downs for the Scourge.",
			strategy = { summary = "He freezes players and summons frost spectres at low health.", dps = "Kill the spectres when they appear." },
			abilities = {
				{ name = "Frost Nova", alerts = { "tank" }, text = "Freezes everyone nearby." },
				{ name = "Amnennar's Wrath", alerts = { "healer" }, text = "Frost damage around him." },
				{ name = "Summon Frost Spectres", alerts = { "dps" }, text = "Summons ghosts at low health." },
			},
		},
		{
			name = "Plaguemaw the Rotting",
			optional = true,
			overview = "A rare plague boar.",
			lore = "A rare plague boar.",
			strategy = { summary = "An easy rare fight." },
		},
		{
			name = "Ragglesnout",
			optional = true,
			overview = "A rare quilboar necromancer.",
			lore = "A rare quilboar necromancer.",
			strategy = { summary = "He can take control of a player and heals himself." },
		},
	},
})
