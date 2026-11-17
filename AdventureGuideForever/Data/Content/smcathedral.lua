-- Scarlet Monastery Cathedral: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smcathedral", {
	intro = "The heart of the Scarlet Monastery, held by its highest leaders.",
	bosses = {
		{
			name = "High Inquisitor Fairbanks",
			optional = true,
			overview = "A secret held in the cathedral's back room.",
			abilities = {
				{ name = "Curse of Blood", alerts = { "curse" }, text = "Increases damage taken." },
			},
		},
		{
			name = "Scarlet Commander Mograine",
			overview = "The commander of the Crusade's forces here.",
			abilities = {
				{ name = "Divine Shield", alerts = { "important" }, text = "Becomes immune for a short time." },
				{ name = "Hammer of Justice", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "High Inquisitor Whitemane",
			overview = "Comes running when Mograine falls, and raises him back up.",
			abilities = {
				{ name = "Scarlet Resurrection", alerts = { "important" }, text = "She puts the group to sleep and resurrects Mograine." },
				{ name = "Holy Smite", alerts = { "interrupt" }, text = "Holy damage." },
				{ name = "Heal", alerts = { "interrupt" }, text = "Heals herself or Mograine. Interrupt it." },
			},
		},
	},
})
