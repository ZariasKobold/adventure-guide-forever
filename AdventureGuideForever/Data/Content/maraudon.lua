-- Maraudon: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("maraudon", {
	intro = "The centaur's sacred grounds hide the tomb of Zaetar and his mother, the earth elemental Theradras.",
	bosses = {
		{
			name = "Noxxion",
			overview = "A poison elemental that splits into small slimes.",
			abilities = {
				{ name = "Summon Noxxion's Spawns", alerts = { "dps" }, text = "Splits into many small slimes." },
			},
		},
		{
			name = "Razorlash",
			overview = "A thorny creature in the tunnels.",
			abilities = {
				{ name = "Cleave", alerts = { "tank" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Lord Vyletongue",
			overview = "A satyr lord who blinks around.",
			abilities = {
				{ name = "Smoke Bomb", alerts = { "tank" }, text = "Stuns nearby players." },
			},
		},
		{
			name = "Celebras the Cursed",
			overview = "The cursed son of Zaetar.",
			abilities = {
				{ name = "Entangling Roots", alerts = { "magic" }, text = "Roots a player in place." },
			},
		},
		{
			name = "Landslide",
			overview = "A huge rock giant.",
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
				{ name = "Summon Shardlings", alerts = { "dps" }, text = "Calls small rock elementals." },
			},
		},
		{ name = "Tinkerer Gizlock", overview = "A goblin with gadgets and bombs." },
		{
			name = "Rotgrip",
			overview = "A giant crocolisk.",
			abilities = {
				{ name = "Puncture", alerts = { "tank" }, text = "Lowers the tank's armor." },
			},
		},
		{
			name = "Princess Theradras",
			overview = "The earth elemental who brought Zaetar's curse. The last boss.",
			abilities = {
				{ name = "Dust Field", alerts = { "dps" }, text = "Damage around her." },
				{ name = "Boulder", alerts = { "healer" }, text = "Throws a boulder at a player." },
				{ name = "Knockdown", alerts = { "tank" }, text = "Knocks the tank to the ground." },
			},
		},
	},
})
