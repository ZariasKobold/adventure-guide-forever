-- Scholomance: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("scholomance", {
	intro = "The Cult of the Damned trains necromancers in the Barovs' old crypts.",
	bosses = {
		{
			name = "Kirtonos the Herald",
			overview = "A vampire bat summoned with a blood offering.",
			abilities = {
				{ name = "Swoop", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Jandice Barov",
			overview = "Splits into many illusions.",
			abilities = {
				{ name = "Illusions", alerts = { "dps" }, text = "Many copies appear. Find the real one." },
			},
		},
		{ name = "Rattlegore", overview = "A huge bone construct." },
		{
			name = "Ras Frostwhisper",
			overview = "A lich who freezes his foes.",
			abilities = {
				{ name = "Chill Nova", alerts = { "tank" }, text = "Freezes everyone nearby." },
			},
		},
		{ name = "Instructor Malicia", npcID = 10505, overview = "A Scholomance teacher." },
		{ name = "Doctor Theolen Krastinov", overview = "The Butcher of Scholomance." },
		{ name = "Lorekeeper Polkelt", overview = "Keeper of the school's lore." },
		{
			name = "The Ravenian",
			npcID = 10507,
			overview = "An abomination in the classroom.",
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{ name = "Lord Alexei Barov", npcID = 10504, overview = "A Barov noble turned undead." },
		{
			name = "Lady Illucia Barov",
			npcID = 10502,
			overview = "A Barov noble turned undead.",
			abilities = {
				{ name = "Dominate Mind", alerts = { "important" }, text = "Takes control of a player." },
			},
		},
		{
			name = "Darkmaster Gandling",
			overview = "The headmaster. The last boss.",
			abilities = {
				{ name = "Shadow Portal", alerts = { "important" }, text = "Teleports a player into a side room full of undead." },
				{ name = "Arcane Missiles", alerts = { "healer" }, text = "Arcane damage." },
			},
		},
	},
})
