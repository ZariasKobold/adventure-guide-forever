-- Capital Gardens: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmwest", {
	intro = "Capital Gardens: the western wing of Dire Maul, where the Shen'dralar elves keep their dark secret.",
	bosses = {
		{
			name = "Tendris Warpwood",
			overview = "A corrupted treant.",
			abilities = {
				{ name = "Entangle", alerts = { "magic" }, text = "Roots players in place." },
			},
		},
		{ name = "Illyanna Ravenoak", overview = "An elf hunter with her bear." },
		{
			name = "Magister Kalendris",
			overview = "An elf shadow caster.",
			abilities = {
				{ name = "Mind Blast", alerts = { "interrupt" }, text = "Shadow damage." },
			},
		},
		{
			name = "Immol'thar",
			overview = "A demon the Shen'dralar keep imprisoned for power.",
			abilities = {
				{ name = "Eye of Immol'thar", alerts = { "dps" }, text = "Spawns eyes around the room." },
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Prince Tortheldrin",
			overview = "The prince of the Shen'dralar. The last boss.",
			abilities = {
				{ name = "Whirlwind", alerts = { "dps" }, text = "Spins and hits everyone nearby." },
				{ name = "Arcane Blast", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{ name = "Tsu'zee", optional = true, overview = "A rare stealthed elf in the gardens." },
	},
})
