-- Razorfen Kraul: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("razorfenkraul", {
	intro = "A maze of thorny briars where the quilboar of the Barrens gather.",
	bosses = {
		{
			name = "Roogug",
			overview = "A quilboar geomancer who summons earth.",
			abilities = {
				{ name = "Summon Earth Rumbler", alerts = { "dps" }, text = "Calls an earth elemental." },
			},
		},
		{
			name = "Aggem Thorncurse",
			overview = "A quilboar shaman who calls boars.",
			abilities = {
				{ name = "Chain Heal", alerts = { "interrupt" }, text = "Heals himself and allies." },
			},
		},
		{
			name = "Death Speaker Jargba",
			overview = "A quilboar who controls minds.",
			abilities = {
				{ name = "Dominate Mind", alerts = { "important" }, text = "Takes control of a player." },
			},
		},
		{
			name = "Overlord Ramtusk",
			overview = "The quilboar war leader.",
			abilities = {
				{ name = "Battle Shout", alerts = { "tank" }, text = "Increases his attack power." },
			},
		},
		{
			name = "Agathelos the Raging",
			overview = "A huge boar spirit.",
			abilities = {
				{ name = "Rampage", alerts = { "enrage", "tank" }, text = "Gets angrier and hits harder." },
			},
		},
		{
			name = "Charlga Razorflank",
			overview = "The quilboar crone who leads Razorfen Kraul.",
			abilities = {
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Lightning that jumps between players." },
				{ name = "Purity", alerts = { "interrupt" }, text = "Heals herself. Interrupt it." },
			},
		},
		{ name = "Blind Hunter", optional = true, overview = "A rare bat deep in the warrens." },
		{ name = "Earthcaller Halmgar", optional = true, overview = "A rare quilboar earthcaller." },
	},
})
