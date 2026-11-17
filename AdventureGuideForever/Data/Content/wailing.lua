-- Wailing Caverns: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("wailing", {
	intro = "Druids of the Fang twisted their dreams in these caves, and the land turned with them.",
	bosses = {
		{
			name = "Lady Anacondra",
			overview = "A Druid of the Fang who guards the outer caverns.",
			abilities = {
				{ name = "Sleep", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Lightning Bolt", alerts = { "interrupt" }, text = "A strong nature bolt." },
			},
		},
		{
			name = "Lord Cobrahn",
			overview = "Turns into a giant serpent partway through the fight.",
			abilities = {
				{ name = "Cobrahn Serpent Form", alerts = { "important" }, text = "Becomes a snake, hitting harder." },
				{ name = "Poison", alerts = { "poison", "healer" }, text = "Nature damage over time." },
			},
		},
		{ name = "Kresh", overview = "A huge turtle that wanders the waters." },
		{
			name = "Lord Pythas",
			overview = "Another Druid of the Fang, deep in the caves.",
			abilities = {
				{ name = "Thunderclap", alerts = { "tank" }, text = "Damages and slows everyone nearby." },
				{ name = "Healing Touch", alerts = { "interrupt" }, text = "Heals himself. Interrupt it." },
			},
		},
		{
			name = "Skum",
			overview = "A big thunder lizard in the underground river.",
			abilities = {
				{ name = "Chained Bolt", alerts = { "healer" }, text = "Lightning that jumps between players." },
			},
		},
		{
			name = "Lord Serpentis",
			overview = "The last Druid of the Fang before the end.",
			abilities = {
				{ name = "Lightning Bolt", alerts = { "interrupt" }, text = "A strong nature bolt." },
				{ name = "Sleep", alerts = { "magic" }, text = "Puts a player to sleep." },
			},
		},
		{
			name = "Verdan the Everliving",
			overview = "A giant plant creature twisted by the Nightmare.",
			abilities = {
				{ name = "Grasping Vines", alerts = { "important" }, text = "Knocks down everyone nearby." },
			},
		},
		{
			name = "Mutanus the Devourer",
			overview = "Appears when the Naralex escort finishes. The last boss.",
			abilities = {
				{ name = "Naralex's Nightmare", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Thundercrack", alerts = { "tank" }, text = "Stuns everyone nearby." },
			},
		},
		{
			name = "Deviate Faerie Dragon",
			optional = true,
			overview = "A rare faerie dragon that may appear in the caves.",
			abilities = {
				{ name = "Sleep", alerts = { "magic" }, text = "Puts a player to sleep." },
			},
		},
	},
})
