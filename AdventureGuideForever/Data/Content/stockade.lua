-- Stormwind Stockade: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("stockade", {
	intro = "Stormwind's prison has fallen to a riot led by the Defias.",
	bosses = {
		{
			name = "Targorr the Dread",
			overview = "A brutal prisoner who enrages when hurt.",
			abilities = {
				{ name = "Enrage", alerts = { "enrage", "tank" }, text = "Hits faster at low health." },
			},
		},
		{
			name = "Kam Deepfury",
			overview = "A Dark Iron prisoner.",
			abilities = {
				{ name = "Shield Slam", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "Hamhock",
			overview = "An ogre who throws chains of lightning.",
			abilities = {
				{ name = "Chain Lightning", alerts = { "healer" }, text = "Lightning that jumps between players." },
				{ name = "Bloodlust", alerts = { "enrage" }, text = "Speeds up his attacks." },
			},
		},
		{
			name = "Bazil Thredd",
			overview = "The Defias leader of the riot.",
			abilities = {
				{ name = "Smoke Bomb", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "Dextren Ward",
			overview = "A mad prisoner who fears and stabs.",
			abilities = {
				{ name = "Intimidating Shout", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{ name = "Bruegal Ironknuckle", optional = true, overview = "A rare prisoner hidden in the stockade." },
	},
})
