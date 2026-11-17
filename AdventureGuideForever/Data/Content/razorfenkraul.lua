-- Razorfen Kraul: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("razorfenkraul", {
	intro = "A maze of thorny briars where the quilboar of the Barrens gather.",
	lore = "Razorfen Kraul is a maze of giant thorny vines, sacred ground of the quilboar. The thorns grew from the blood of the demigod Agamaggan, and the quilboar gather here under Charlga Razorflank. She is a crone who means to raise a quilboar army to take back the Barrens.",
	route = "The briar paths wind in a loop. Roogug guards the start; Aggem Thorncurse and Death Speaker Jargba hold the middle. Overlord Ramtusk and Agathelos guard the way to Charlga's chamber at the end.",
	tips = {
		"Quilboar casters and spirit beasts come in big packs. Use crowd control.",
		"Some quests need Charlga's items, so finish the whole run.",
		"Earthcaller Halmgar and the Blind Hunter are rare bosses; kill them if you see them.",
	},
	bosses = {
		{
			name = "Roogug",
			overview = "A quilboar geomancer who summons earth.",
			lore = "A quilboar geomancer who calls earth spirits.",
			strategy = { summary = "He summons an earth elemental. Kill the elemental, then Roogug." },
			abilities = {
				{ name = "Summon Earth Rumbler", alerts = { "dps" }, text = "Calls an earth elemental." },
			},
		},
		{
			name = "Aggem Thorncurse",
			overview = "A quilboar shaman who calls boars.",
			lore = "A quilboar shaman who leads the boar handlers.",
			strategy = { summary = "He calls boar spirits and heals.", dps = "Interrupt his Chain Heal." },
			abilities = {
				{ name = "Chain Heal", alerts = { "interrupt" }, text = "Heals himself and allies." },
			},
		},
		{
			name = "Death Speaker Jargba",
			overview = "A quilboar who controls minds.",
			lore = "A quilboar necromancer who speaks with the dead.",
			strategy = { summary = "He can take control of a player's mind.", healer = "Be ready if a player turns on the group." },
			abilities = {
				{ name = "Dominate Mind", alerts = { "important" }, text = "Takes control of a player." },
			},
		},
		{
			name = "Overlord Ramtusk",
			overview = "The quilboar war leader.",
			lore = "The quilboar war chief of the Kraul.",
			strategy = { summary = "A melee fight. He boosts his own attack power with a shout." },
			abilities = {
				{ name = "Battle Shout", alerts = { "tank" }, text = "Increases his attack power." },
			},
		},
		{
			name = "Agathelos the Raging",
			overview = "A huge boar spirit.",
			lore = "A giant boar spirit, holy to the quilboar.",
			strategy = { summary = "He grows angrier and hits harder as the fight goes on.", dps = "Kill him fast before his rampage builds." },
			abilities = {
				{ name = "Rampage", alerts = { "enrage", "tank" }, text = "Gets angrier and hits harder." },
			},
		},
		{
			name = "Charlga Razorflank",
			overview = "The quilboar crone who leads Razorfen Kraul.",
			lore = "The crone who leads the quilboar of the Kraul.",
			strategy = { summary = "She heals herself and shoots chain lightning.", dps = "Interrupt her Purity heal." },
			abilities = {
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Lightning that jumps between players." },
				{ name = "Purity", alerts = { "interrupt" }, text = "Heals herself. Interrupt it." },
			},
		},
		{
			name = "Blind Hunter",
			optional = true,
			overview = "A rare bat deep in the warrens.",
			lore = "A rare bat that hunts the deep tunnels.",
			strategy = { summary = "An easy rare. Kill it for its loot." },
		},
		{
			name = "Earthcaller Halmgar",
			optional = true,
			overview = "A rare quilboar earthcaller.",
			lore = "A rare quilboar earthcaller.",
			strategy = { summary = "He calls an earth elemental and drops totems. Destroy the totems." },
		},
	},
})
