-- Alcaz Prison: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("alcaz", {
	intro = "A prison on Alcaz Island, off the coast of Dustwallow Marsh.",
	lore = "Alcaz Island, off the coast of Dustwallow Marsh, holds a prison of the Defias Brotherhood. Its jailers hold secrets, and its prisoners know things that both factions want.",
	route = "The Questioner, Tidemistress Ca'zass, Overseer Wrex, Katerina the Cleaner and Blazeroar guard the prison.",
	tips = {
		"Quests start at level 48; the final boss is level 51.",
		"Blazeroar reveals his true form during the fight.",
		"Strategy here is early notes from each boss's abilities.",
	},
	bosses = {
		{
			name = "The Questioner",
			overview = "The prison's interrogator.",
			lore = "The Defias interrogator who runs the prison.",
			strategy = { summary = "Early notes: he causes bleeds and drains life." },
		},
		{
			name = "Tidemistress Ca'zass",
			overview = "A naga frost caster.",
			lore = "A naga sea witch who serves the prison's masters.",
			strategy = { summary = "Early notes: she freezes players and fills the room with blizzards.", dps = "Move out of the Blizzard." },
		},
		{
			name = "Overseer Wrex",
			overview = "The prison's overseer.",
			lore = "The overseer who keeps the prisoners in line.",
			strategy = {
				summary = "Early notes: he hits with Mortal Strike, which lowers healing.",
				healer = "The tank takes less healing while Mortal Strike is on them.",
			},
		},
		{
			name = "Katerina the Cleaner",
			overview = "The prison's assassin.",
			lore = "An assassin who cleans up the prison's loose ends.",
			strategy = { summary = "Early notes: she poisons and garrotes players.", healer = "Cure poisons if you can." },
		},
		{
			name = "Blazeroar",
			overview = "A fire beast with a secret form.",
			lore = "A fire beast with a secret form.",
			strategy = {
				summary = "Early notes: a busy fight. Fire breath, fireballs, flamestrike, fear and an enrage, and he reveals his true form partway through.",
				dps = "Move out of the Flamestrike.",
			},
		},
	},
})
