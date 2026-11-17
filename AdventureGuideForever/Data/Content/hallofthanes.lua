-- The Hall of Thanes: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("hallofthanes", {
	intro = "Beneath Ironforge lie the tombs of the dwarven thanes. Something has woken the dead, and a disgraced thane walks among them.",
	bosses = {
		{ name = "Faldrim Anvilmar" },
		{ name = "Magmatus" },
		{ name = "Plunder" },
		{ name = "Durgen Dirgehammer" },
	},
})
