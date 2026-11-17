-- Scarlet Monastery Graveyard: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smgraveyard", {
	intro = "The Scarlet Crusade buries its dead here, though not all of them rest.",
	bosses = {
		{
			name = "Interrogator Vishas",
			overview = "A Scarlet interrogator who weakens players.",
			abilities = {
				{ name = "Shadow Word: Pain", alerts = { "magic", "healer" }, text = "Shadow damage over time." },
			},
		},
		{
			name = "Bloodmage Thalnos",
			overview = "An undead mage at the back of the graveyard.",
			abilities = {
				{ name = "Flame Spike", alerts = { "dps" }, text = "Fire on the ground. Step out." },
				{ name = "Shadow Bolt", alerts = { "interrupt" }, text = "A strong shadow bolt." },
			},
		},
		{ name = "Ironspine", optional = true, overview = "A rare skeleton." },
		{ name = "Azshir the Sleepless", optional = true, overview = "A rare ghost." },
		{ name = "Fallen Champion", optional = true, overview = "A rare undead champion." },
	},
})
