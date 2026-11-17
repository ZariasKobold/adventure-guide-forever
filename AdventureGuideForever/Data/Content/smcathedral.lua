-- Scarlet Monastery Cathedral: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("smcathedral", {
	intro = "The heart of the Scarlet Monastery, held by its highest leaders.",
	lore = "The Cathedral is the heart of the Scarlet Monastery. Scarlet Commander Mograine leads the Crusade's forces here with High Inquisitor Whitemane. Few in the Crusade know the dark secret behind them.",
	route = "Clear the courtyard and the Cathedral's nave, then fight Mograine at the altar. Whitemane arrives when he falls. Fairbanks hides in a side room.",
	tips = { "This is the hardest Scarlet wing: bring your best gear.", "Mograine and Whitemane fight together for part of the fight." },
	bosses = {
		{
			name = "High Inquisitor Fairbanks",
			optional = true,
			overview = "A secret held in the cathedral's back room.",
			lore = "A secret of the Crusade, locked away in a hidden room.",
			strategy = { summary = "He curses and fears players, and heals himself." },
			abilities = {
				{ name = "Curse of Blood", alerts = { "curse" }, text = "Increases damage taken." },
			},
		},
		{
			name = "Scarlet Commander Mograine",
			overview = "The commander of the Crusade's forces here.",
			lore = "The commander of the Crusade's forces in the Monastery.",
			strategy = { summary = "He stuns the tank and becomes immune for a short time.", tank = "Expect a stun. Keep your threat high." },
			abilities = {
				{ name = "Divine Shield", alerts = { "important" }, text = "Becomes immune for a short time." },
				{ name = "Hammer of Justice", alerts = { "tank" }, text = "Stuns the tank." },
			},
		},
		{
			name = "High Inquisitor Whitemane",
			overview = "Comes running when Mograine falls, and raises him back up.",
			lore = "The Crusade's spiritual leader, who rushes in when Mograine falls.",
			strategy = {
				summary = "She puts the group to sleep and raises Mograine. Then you fight them both.",
				dps = "Interrupt her heals. Kill her first once Mograine is back up.",
			},
			abilities = {
				{ name = "Scarlet Resurrection", alerts = { "important" }, text = "She puts the group to sleep and resurrects Mograine." },
				{ name = "Holy Smite", alerts = { "interrupt" }, text = "Holy damage." },
				{ name = "Heal", alerts = { "interrupt" }, text = "Heals herself or Mograine. Interrupt it." },
			},
		},
	},
})
