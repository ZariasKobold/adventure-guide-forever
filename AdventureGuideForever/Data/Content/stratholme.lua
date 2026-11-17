-- Stratholme: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("stratholme", {
	intro = "The city where Arthas purged the plague. The Scarlet Crusade holds one side, the Scourge the other.",
	bosses = {
		{ name = "Ezra Grimm", overview = "A tobacco merchant turned undead." },
		{
			name = "The Unforgiven",
			overview = "A vengeful ghost.",
			abilities = {
				{ name = "Frost Nova", alerts = { "healer" }, text = "Freezes nearby players in place." },
			},
		},
		{ name = "Timmy the Cruel", overview = "A huge ghoul in the market square." },
		{ name = "Cannon Master Willey", overview = "A Scarlet cannon master." },
		{
			name = "Archivist Galford",
			overview = "Guards the Crusade's records.",
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Balnazzar",
			alsoNamed = { "Grand Crusader Dathrohan" },
			overview = "Disguised as Grand Crusader Dathrohan. The Scarlet side's last boss.",
			abilities = {
				{ name = "Mind Control", alerts = { "important" }, text = "Takes control of a player." },
				{ name = "Psychic Scream", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{ name = "Magistrate Barthilas", overview = "The magistrate turned undead." },
		{ name = "Nerub'enkan", overview = "A crypt fiend." },
		{
			name = "Baroness Anastari",
			overview = "A banshee who possesses players.",
			abilities = {
				{ name = "Possess", alerts = { "important" }, text = "Takes control of a player." },
			},
		},
		{ name = "Maleki the Pallid", overview = "A lich who drains mana." },
		{
			name = "Ramstein the Gorger",
			overview = "A huge abomination.",
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Baron Rivendare",
			overview = "Lord of the Scourge's Stratholme. The last boss.",
			abilities = {
				{ name = "Death Pact", alerts = { "important" }, text = "Raises skeletons, then eats them to heal." },
				{ name = "Unholy Aura", alerts = { "healer" }, text = "Shadow damage on everyone." },
			},
		},
		{ name = "Postmaster Malown", optional = true, overview = "Summoned by opening the mailboxes." },
		{ name = "Hearthsinger Forresten", optional = true, overview = "A rare undead bard." },
		{ name = "Stonespine", optional = true, overview = "A rare gargoyle." },
	},
})
