-- Wailing Caverns: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("wailing", {
	intro = "Druids of the Fang twisted their dreams in these caves, and the land turned with them.",
	lore = "Naralex, a night elf druid, came to these caves to heal the Barrens through the Emerald Dream. Instead he fell into nightmare, and the caverns twisted with him. His disciples became the Druids of the Fang, who now guard the caves and use their power to change themselves and the beasts around them.",
	route = "The caves are a maze. The four Fang lords are spread through the outer caverns. Speak with the Disciple of Naralex near the entrance; once the Fang leaders fall, he leads an escort to wake Naralex, and Mutanus appears at the end.",
	tips = {
		"Kill the four Druids of the Fang (Anacondra, Cobrahn, Pythas, Serpentis) before starting the escort.",
		"The Druids' Sleep and Healing Touch are dangerous: interrupt the heals.",
		"Many players get lost here. Follow the paths toward the waterfall areas.",
	},
	bosses = {
		{
			name = "Lady Anacondra",
			overview = "A Druid of the Fang who guards the outer caverns.",
			lore = "The first of the Druids of the Fang, she guards the outer caves.",
			strategy = {
				summary = "She heals herself and puts players to sleep.",
				healer = "Watch for slept players and keep the tank up while they're out.",
				dps = "Interrupt her Healing Touch.",
			},
			abilities = {
				{ name = "Sleep", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Lightning Bolt", alerts = { "interrupt" }, text = "A strong nature bolt." },
			},
		},
		{
			name = "Lord Cobrahn",
			overview = "Turns into a giant serpent partway through the fight.",
			lore = "A Druid of the Fang who has gone so far into the nightmare that he can become a serpent.",
			strategy = {
				summary = "Partway through, he turns into a giant snake and hits much harder.",
				tank = "Use a cooldown when he transforms.",
				dps = "Interrupt his healing before he shifts.",
			},
			abilities = {
				{ name = "Cobrahn Serpent Form", alerts = { "important" }, text = "Becomes a snake, hitting harder." },
				{ name = "Poison", alerts = { "poison", "healer" }, text = "Nature damage over time." },
			},
		},
		{
			name = "Kresh",
			overview = "A huge turtle that wanders the waters.",
			lore = "A huge turtle who wanders the waters of the caverns.",
			strategy = { summary = "A simple fight. He has lots of armor, so be patient." },
		},
		{
			name = "Lord Pythas",
			overview = "Another Druid of the Fang, deep in the caves.",
			lore = "A Druid of the Fang who uses lightning and sleep.",
			strategy = { summary = "His Thunderclap slows nearby players and he heals himself.", dps = "Interrupt his Healing Touch and Lightning Bolt." },
			abilities = {
				{ name = "Thunderclap", alerts = { "tank" }, text = "Damages and slows everyone nearby." },
				{ name = "Healing Touch", alerts = { "interrupt" }, text = "Heals himself. Interrupt it." },
			},
		},
		{
			name = "Skum",
			overview = "A big thunder lizard in the underground river.",
			lore = "A thunder lizard grown huge and strange in the caves' tainted waters.",
			strategy = { summary = "He throws chain lightning that jumps between players.", dps = "Spread out so the lightning has fewer people to jump to." },
			abilities = {
				{ name = "Chained Bolt", alerts = { "healer" }, text = "Lightning that jumps between players." },
			},
		},
		{
			name = "Lord Serpentis",
			overview = "The last Druid of the Fang before the end.",
			lore = "The last of the Druids of the Fang.",
			strategy = { summary = "Like the other Fang lords, he heals himself and casts lightning.", dps = "Interrupt his heals." },
			abilities = {
				{ name = "Lightning Bolt", alerts = { "interrupt" }, text = "A strong nature bolt." },
				{ name = "Sleep", alerts = { "magic" }, text = "Puts a player to sleep." },
			},
		},
		{
			name = "Verdan the Everliving",
			overview = "A giant plant creature twisted by the Nightmare.",
			lore = "A huge plant creature born from the nightmare taint.",
			strategy = { summary = "His Grasping Vines knock everyone down.", healer = "Heal up after each knockdown." },
			abilities = {
				{ name = "Grasping Vines", alerts = { "important" }, text = "Knocks down everyone nearby." },
			},
		},
		{
			name = "Mutanus the Devourer",
			overview = "Appears when the Naralex escort finishes. The last boss.",
			lore = "The terror at the heart of Naralex's nightmare, a monster that tries to stop him from waking.",
			strategy = {
				summary = "He appears when the escort is complete. He puts players to sleep and stuns everyone nearby.",
				tank = "Expect stuns. Keep him faced away from the group.",
				healer = "Keep the group topped up through the stuns and sleeps.",
			},
			abilities = {
				{ name = "Naralex's Nightmare", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Thundercrack", alerts = { "tank" }, text = "Stuns everyone nearby." },
			},
		},
		{
			name = "Deviate Faerie Dragon",
			optional = true,
			overview = "A rare faerie dragon that may appear in the caves.",
			lore = "A rare faerie dragon twisted by the caves' corruption.",
			strategy = { summary = "He puts players to sleep. Easy if your group is careful." },
			abilities = {
				{ name = "Sleep", alerts = { "magic" }, text = "Puts a player to sleep." },
			},
		},
	},
})
