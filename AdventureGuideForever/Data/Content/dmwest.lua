-- Capital Gardens: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmwest", {
	intro = "Capital Gardens: the western wing of Dire Maul, where the Shen'dralar elves keep their dark secret.",
	lore = "The western wing of Dire Maul, the Capital Gardens, holds the Shen'dralar: the last Highborne elves of Eldre'Thalas. They survived by draining a demon, Immol'thar, held prisoner by pylons, and they will do anything to keep their power.",
	route = "Disable the five pylons that hold Immol'thar, fighting their guardians. Then fight Immol'thar, and go on to Prince Tortheldrin in the library. Tendris, Illyanna and Kalendris guard the way.",
	tips = {
		"Each pylon is guarded by elementals. Clear them one at a time.",
		"Immol'thar spawns eyes around the room. Kill them fast.",
		"Prince Tortheldrin's library holds class books.",
	},
	bosses = {
		{
			name = "Tendris Warpwood",
			overview = "A corrupted treant.",
			lore = "A corrupted treant who guards the gardens.",
			strategy = { summary = "He roots players with vines. A tough melee fight." },
			abilities = {
				{ name = "Entangle", alerts = { "magic" }, text = "Roots players in place." },
			},
		},
		{
			name = "Illyanna Ravenoak",
			overview = "An elf hunter with her bear.",
			lore = "An elf hunter with her bear.",
			strategy = { summary = "She shoots and traps players. Kill her bear first." },
		},
		{
			name = "Magister Kalendris",
			overview = "An elf shadow caster.",
			lore = "An elf shadow caster.",
			strategy = { summary = "He mind-controls players and casts shadow spells." },
			abilities = {
				{ name = "Mind Blast", alerts = { "interrupt" }, text = "Shadow damage." },
			},
		},
		{
			name = "Immol'thar",
			overview = "A demon the Shen'dralar keep imprisoned for power.",
			lore = "A demon kept prisoner by the Shen'dralar to feed their magic.",
			strategy = { summary = "He spawns eyes around the room and tramples the tank.", dps = "Kill the eyes first." },
			abilities = {
				{ name = "Eye of Immol'thar", alerts = { "dps" }, text = "Spawns eyes around the room." },
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Prince Tortheldrin",
			overview = "The prince of the Shen'dralar. The last boss.",
			lore = "The prince of the Shen'dralar.",
			strategy = { summary = "He spins in a whirlwind and blasts the tank back.", dps = "Melee players should step out of the whirlwind." },
			abilities = {
				{ name = "Whirlwind", alerts = { "dps" }, text = "Spins and hits everyone nearby." },
				{ name = "Arcane Blast", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Tsu'zee",
			optional = true,
			overview = "A rare stealthed elf in the gardens.",
			lore = "A rare stealthy elf in the gardens.",
			strategy = { summary = "A rogue-style fight. She blinds players." },
		},
		{
			name = "Pimgib",
			overview = "An imp near Immol'thar's prison.",
			lore = "An imp lingering near the imprisoned demon.",
			strategy = { summary = "He casts fire spells and blast waves." },
		},
		{
			name = "Lord Hel'nurath",
			overview = "A dreadlord summoned with a warlock quest.",
			lore = "A dreadlord summoned by warlocks for their epic mount quest.",
			strategy = { summary = "He knocks the tank back and puts players to sleep." },
		},
	},
})
