-- Scarlet Monastery Armory: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smarmory", {
	intro = "The Crusade's training grounds and weapon stores.",
	lore = "The Armory is where the Crusade trains its soldiers and keeps its weapons. Its champion, Herod, is a legend among the Scarlet ranks.",
	route = "Fight through the training halls to Herod's chamber at the end. After he dies, a wave of trainees rushes in.",
	tips = { "Be ready for the trainees that charge in after Herod dies.", "Melee players should stay away from Herod's whirlwind." },
	bosses = {
		{
			name = "Herod",
			overview = "The Scarlet Champion. He loves a good whirlwind.",
			lore = "The Scarlet Champion, the Crusade's greatest warrior.",
			strategy = {
				summary = "He spins in a whirlwind, hitting everyone nearby.",
				tank = "Keep him in place.",
				dps = "Melee players should step out of the whirlwind.",
			},
			abilities = {
				{ name = "Whirlwind", alerts = { "deadly", "dps" }, text = "Spins and hits everyone nearby. Melee should run out." },
				{ name = "Enrage", alerts = { "enrage" }, text = "Enrages at low health. More trainees rush in after he dies." },
			},
		},
	},
})
