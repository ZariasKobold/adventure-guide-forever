-- Blackfathom Deeps: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("blackfathom", {
	intro = "An ancient temple of the night elves, now flooded and claimed by the Twilight's Hammer.",
	bosses = {
		{
			name = "Ghamoo-ra",
			overview = "A giant turtle in the flooded entrance.",
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everything in front of him." },
			},
		},
		{
			name = "Lady Sarevess",
			overview = "A naga sorceress who shoots arrows and frost.",
			abilities = {
				{ name = "Forked Lightning", alerts = { "healer" }, text = "Hits several players in front of her." },
				{ name = "Slow", alerts = { "magic" }, text = "Slows a player's movement." },
			},
		},
		{
			name = "Gelihast",
			overview = "The murloc king of the caves.",
			abilities = {
				{ name = "Net", alerts = { "magic" }, text = "Roots a player in place." },
			},
		},
		{
			name = "Lorgus Jett",
			optional = true,
			overview = "A Twilight's Hammer leader in the depths. Only sometimes present.",
			abilities = {
				{ name = "Lightning Shield", alerts = { "magic" }, text = "Shields himself with lightning." },
			},
		},
		{
			name = "Baron Aquanis",
			optional = true,
			npcID = 12876,
			overview = "A water spirit summoned from the altar (part of a quest).",
			abilities = {
				{ name = "Frostbolt", alerts = { "interrupt" }, text = "A strong frost bolt." },
			},
		},
		{
			name = "Twilight Lord Kelris",
			overview = "Leader of the Twilight's Hammer here.",
			abilities = {
				{ name = "Sleep", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Mind Blast", alerts = { "interrupt" }, text = "Shadow damage on a player." },
			},
		},
		{ name = "Old Serra'kis", overview = "A giant shark in the underwater tunnel." },
		{
			name = "Aku'mai",
			overview = "The hydra the Twilight's Hammer worships. The last boss.",
			abilities = {
				{ name = "Poison Cloud", alerts = { "poison", "healer" }, text = "Poison around her." },
				{ name = "Frenzied Rage", alerts = { "enrage", "tank" }, text = "Hits much harder below about 30% health." },
			},
		},
	},
})
