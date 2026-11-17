-- Stratholme: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("stratholme", {
	intro = "The city where Arthas purged the plague. The Scarlet Crusade holds one side, the Scourge the other.",
	lore = "Stratholme was a proud city of Lordaeron until Arthas purged it to stop the plague. Now the Scarlet Crusade holds one side and the Scourge holds the other, and their war goes on in the ruins.",
	route = "Stratholme has two sides. The live side, held by the Scarlet Crusade, has Timmy, Willey, Galford and Balnazzar. The undead side has the Barthilas, Nerub'enkan, Anastari, Maleki, Ramstein and finally Baron Rivendare.",
	tips = {
		"You need the Key to the City for the undead side.",
		"Baron Rivendare can drop the Deathcharger mount.",
		"The undead side is a race against time if you're doing the timed run.",
	},
	bosses = {
		{
			name = "Ezra Grimm",
			overview = "A merchant turned undead, summoned in the city.",
			lore = "A tobacco merchant turned undead.",
			strategy = { summary = "He throws smoke bombs and breathes fire." },
		},
		{
			name = "The Unforgiven",
			overview = "A vengeful ghost.",
			lore = "A vengeful ghost.",
			strategy = { summary = "He freezes nearby players." },
			abilities = {
				{ name = "Frost Nova", alerts = { "healer" }, text = "Freezes nearby players in place." },
			},
		},
		{
			name = "Timmy the Cruel",
			overview = "A huge ghoul in the market square.",
			lore = "A huge ghoul in the market square.",
			strategy = { summary = "He enrages. Kill him fast." },
		},
		{
			name = "Cannon Master Willey",
			overview = "A Scarlet cannon master.",
			lore = "A Scarlet cannon master.",
			strategy = { summary = "He calls riflemen. Kill them." },
		},
		{
			name = "Archivist Galford",
			overview = "Guards the Crusade's records.",
			lore = "Guards the Crusade's records.",
			strategy = { summary = "He casts pyroblasts and fire." },
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Balnazzar",
			alsoNamed = { "Grand Crusader Dathrohan" },
			overview = "Disguised as Grand Crusader Dathrohan. The Scarlet side's last boss.",
			lore = "A dreadlord disguised as Grand Crusader Dathrohan.",
			strategy = { summary = "He mind-controls and fears players." },
			abilities = {
				{ name = "Mind Control", alerts = { "important" }, text = "Takes control of a player." },
				{ name = "Psychic Scream", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{
			name = "Magistrate Barthilas",
			overview = "The magistrate turned undead.",
			lore = "The magistrate turned undead.",
			strategy = { summary = "He hits hard and drains players." },
		},
		{
			name = "Nerub'enkan",
			overview = "A crypt fiend.",
			lore = "A crypt fiend.",
			strategy = { summary = "He webs players and calls scarabs." },
		},
		{
			name = "Baroness Anastari",
			overview = "A banshee who possesses players.",
			lore = "A banshee who possesses players.",
			strategy = { summary = "She takes control of a player." },
			abilities = {
				{ name = "Possess", alerts = { "important" }, text = "Takes control of a player." },
			},
		},
		{
			name = "Maleki the Pallid",
			overview = "A lich who drains mana.",
			lore = "A lich who drains mana.",
			strategy = { summary = "He freezes and drains players." },
		},
		{
			name = "Ramstein the Gorger",
			overview = "A huge abomination.",
			lore = "A huge abomination.",
			strategy = { summary = "He knocks out players and hits hard." },
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Baron Rivendare",
			overview = "Lord of the Scourge's Stratholme. The last boss.",
			lore = "The lord of the Scourge in Stratholme.",
			strategy = { summary = "He raises skeletons, then eats them to heal.", dps = "Kill the skeletons first." },
			abilities = {
				{ name = "Death Pact", alerts = { "important" }, text = "Raises skeletons, then eats them to heal." },
				{ name = "Unholy Aura", alerts = { "healer" }, text = "Shadow damage on everyone." },
			},
		},
		{
			name = "Postmaster Malown",
			optional = true,
			overview = "Summoned by opening the mailboxes.",
			lore = "Summoned by opening the mailboxes.",
			strategy = { summary = "He fears and curses players." },
		},
		{
			name = "Hearthsinger Forresten",
			optional = true,
			overview = "A rare undead bard.",
			lore = "A rare undead bard.",
			strategy = { summary = "He puts players to sleep with a lullaby." },
		},
		{
			name = "Stonespine",
			optional = true,
			overview = "A rare gargoyle.",
			lore = "A rare gargoyle.",
			strategy = { summary = "An easy rare." },
		},
		{
			name = "Black Guard Swordsmith",
			overview = "A smith summoned for a blacksmithing quest.",
			lore = "A Scourge swordsmith.",
			strategy = { summary = "A melee fight." },
		},
		{
			name = "Crimson Hammersmith",
			overview = "A smith summoned for a blacksmithing quest.",
			lore = "A Scarlet blacksmith.",
			strategy = { summary = "A melee fight." },
		},
		{
			name = "Malor the Zealous",
			overview = "A Scarlet paladin.",
			lore = "A zealous Scarlet paladin.",
			strategy = { summary = "He heals himself. Interrupt him." },
		},
		{
			name = "Skul",
			overview = "A rare skeletal caster.",
			lore = "A rare skeletal mage.",
			strategy = { summary = "He freezes and slows players." },
		},
	},
})
