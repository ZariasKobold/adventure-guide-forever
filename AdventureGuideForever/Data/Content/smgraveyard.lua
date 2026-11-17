-- Scarlet Monastery Graveyard: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smgraveyard", {
	intro = "The Scarlet Crusade buries its dead here, though not all of them rest.",
	lore = "The Scarlet Monastery is the stronghold of the Scarlet Crusade, zealots sworn to purge the undead from Lordaeron. They trust no one and see enemies everywhere. Their graveyard holds the Crusade's dead, but the restless ones don't stay buried for long.",
	route = "The graveyard is a short loop. Interrogator Vishas waits in a side room, and Bloodmage Thalnos is in the crypt at the end. Three rare undead bosses can appear in the graveyard along the way.",
	tips = { "This is the shortest Scarlet wing: good for a quick run.", "The Crusaders call for help, so pull carefully." },
	bosses = {
		{
			name = "Interrogator Vishas",
			overview = "A Scarlet interrogator who weakens players.",
			lore = "The Crusade's torturer, who questions the captured.",
			strategy = { summary = "He burns his target with shadow damage over time." },
			abilities = {
				{ name = "Shadow Word: Pain", alerts = { "magic", "healer" }, text = "Shadow damage over time." },
			},
		},
		{
			name = "Bloodmage Thalnos",
			overview = "An undead mage at the back of the graveyard.",
			lore = "A Crusade mage, turned to undeath and left in the crypt.",
			strategy = { summary = "He sets fire under players and shoots flame shock.", dps = "Move out of the fire on the ground." },
			abilities = {
				{ name = "Flame Spike", alerts = { "dps" }, text = "Fire on the ground. Step out." },
				{ name = "Shadow Bolt", alerts = { "interrupt" }, text = "A strong shadow bolt." },
			},
		},
		{
			name = "Ironspine",
			optional = true,
			overview = "A rare skeleton.",
			lore = "A rare skeletal giant.",
			strategy = { summary = "He poisons and weakens the group. An easy rare." },
		},
		{
			name = "Azshir the Sleepless",
			optional = true,
			overview = "A rare ghost.",
			lore = "A rare ghost who wanders the graves.",
			strategy = { summary = "He fears players and drains their life." },
		},
		{
			name = "Fallen Champion",
			optional = true,
			overview = "A rare undead champion.",
			lore = "A rare undead knight.",
			strategy = { summary = "A melee fight with cleaves and executes." },
		},
	},
})
