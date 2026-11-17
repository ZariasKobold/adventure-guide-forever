-- Ragefire Chasm: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ragefire", {
	intro = "Beneath Orgrimmar, the Searing Blade cult and its troggs plot in tunnels of molten rock.",
	bosses = {
		{
			name = "Oggleflint",
			overview = "The trogg chieftain leads the first pack you meet.",
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Taragaman the Hungerer",
			overview = "A huge demon who feeds on the fires of the chasm.",
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Burns everyone nearby with fire." },
				{ name = "Uppercut", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Jergosh the Invoker",
			overview = "A Searing Blade warlock who channels shadow curses.",
			abilities = {
				{ name = "Curse of Weakness", alerts = { "curse", "tank" }, text = "Lowers the tank's damage." },
				{ name = "Immolate", alerts = { "magic", "healer" }, text = "Burns a target over time." },
			},
		},
		{
			name = "Bazzalan",
			overview = "The satyr leader of the Searing Blade.",
			abilities = {
				{ name = "Poison", alerts = { "poison", "healer" }, text = "Poisons the tank for nature damage over time." },
				{ name = "Sinister Strike", alerts = { "tank" }, text = "A quick, hard strike." },
			},
		},
	},
})
