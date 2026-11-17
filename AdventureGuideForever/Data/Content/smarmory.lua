-- Scarlet Monastery Armory: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smarmory", {
	intro = "The Crusade's training grounds and weapon stores.",
	bosses = {
		{
			name = "Herod",
			overview = "The Scarlet Champion. He loves a good whirlwind.",
			abilities = {
				{ name = "Whirlwind", alerts = { "deadly", "dps" }, text = "Spins and hits everyone nearby. Melee should run out." },
				{ name = "Enrage", alerts = { "enrage" }, text = "Enrages at low health. More trainees rush in after he dies." },
			},
		},
	},
})
