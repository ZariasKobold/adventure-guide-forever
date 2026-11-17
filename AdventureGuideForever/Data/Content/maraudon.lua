-- Maraudon: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("maraudon", {
	intro = "The centaur's sacred grounds hide the tomb of Zaetar and his mother, the earth elemental Theradras.",
	lore = "Maraudon is the holy burial ground of the centaur in Desolace. Zaetar, the son of the demigod Cenarius, was killed here, and his lover, the earth elemental Theradras, cursed the land. Their children became the centaur, and the caves are now poisoned with her rage.",
	route = "Maraudon has an orange side and a purple side, which meet before the inner caves. The orange side has Noxxion and Razorlash; the purple side has Lord Vyletongue and Celebras. Inside, fight Landslide, Tinkerer Gizlock and Rotgrip, then Princess Theradras at the end.",
	tips = {
		"Maraudon is huge. Pick a side and stick to it.",
		"Celebras's quest gives you a scepter that opens a shortcut later.",
		"Theradras hits hard. Bring your best healer.",
	},
	bosses = {
		{
			name = "Noxxion",
			overview = "A poison elemental that splits into small slimes.",
			lore = "A poison elemental.",
			strategy = { summary = "He splits into many small slimes. Kill them fast." },
			abilities = {
				{ name = "Summon Noxxion's Spawns", alerts = { "dps" }, text = "Splits into many small slimes." },
			},
		},
		{
			name = "Razorlash",
			overview = "A thorny creature in the tunnels.",
			lore = "A thorny creature in the tunnels.",
			strategy = { summary = "A melee fight. He punctures the tank's armor." },
			abilities = {
				{ name = "Cleave", alerts = { "tank" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Lord Vyletongue",
			overview = "A satyr lord who blinks around.",
			lore = "A satyr lord who serves the Burning Legion.",
			strategy = { summary = "He blinks around the room and stuns." },
			abilities = {
				{ name = "Smoke Bomb", alerts = { "tank" }, text = "Stuns nearby players." },
			},
		},
		{
			name = "Celebras the Cursed",
			overview = "The cursed son of Zaetar.",
			lore = "The cursed son of Zaetar.",
			strategy = { summary = "He roots players and casts nature spells. Interrupt him." },
			abilities = {
				{ name = "Entangling Roots", alerts = { "magic" }, text = "Roots a player in place." },
			},
		},
		{
			name = "Landslide",
			overview = "A huge rock giant.",
			lore = "A huge rock giant.",
			strategy = { summary = "He knocks the tank back and summons rock elementals.", dps = "Kill the elementals first." },
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
				{ name = "Summon Shardlings", alerts = { "dps" }, text = "Calls small rock elementals." },
			},
		},
		{
			name = "Tinkerer Gizlock",
			overview = "A goblin with gadgets and bombs.",
			lore = "A goblin with gadgets and bombs.",
			strategy = { summary = "He throws bombs and flashes. Spread out." },
		},
		{
			name = "Rotgrip",
			overview = "A giant crocolisk.",
			lore = "A giant crocolisk.",
			strategy = { summary = "He punctures the tank's armor." },
			abilities = {
				{ name = "Puncture", alerts = { "tank" }, text = "Lowers the tank's armor." },
			},
		},
		{
			name = "Princess Theradras",
			overview = "The earth elemental who brought Zaetar's curse. The last boss.",
			lore = "The earth elemental who cursed Zaetar's children.",
			strategy = {
				summary = "She knocks the tank back and throws boulders.",
				tank = "Keep your back to a wall.",
				healer = "Watch out for boulders on random players.",
			},
			abilities = {
				{ name = "Dust Field", alerts = { "dps" }, text = "Damage around her." },
				{ name = "Boulder", alerts = { "healer" }, text = "Throws a boulder at a player." },
				{ name = "Knockdown", alerts = { "tank" }, text = "Knocks the tank to the ground." },
			},
		},
		{
			name = "Meshlok the Harvester",
			overview = "A rare earthen giant in the caves.",
			lore = "A rare earth giant that roams Maraudon.",
			strategy = { summary = "He stomps and stuns nearby players." },
		},
	},
})
