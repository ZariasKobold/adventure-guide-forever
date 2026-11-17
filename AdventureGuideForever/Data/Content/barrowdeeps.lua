-- Barrow Deeps: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("barrowdeeps", {
	intro = "Barrow Deeps lies beneath Mount Hyjal. Opens December 9.",
	lore = "Beneath Mount Hyjal, the Barrow Deeps hold the druids' sacred barrow dens, where druids sleep in the Emerald Dream. Something has gone wrong in the Dream, and the Deeps are no longer safe.",
	tips = { "This raid opens on December 9, 2026.", "Bosses, loot and abilities will be added as players learn the raid." },
	bosses = {
		{ name = "Deepscar Matriarch" },
		{ name = "Khalith the Dreadspinner" },
		{ name = "Amethrax" },
		{ name = "Ravus and Darlissa" },
		{ name = "Elder Tangleclaw" },
		{ name = "Well of Sorrow" },
		{ name = "Del'lynar Songwood" },
		{ name = "Sonya Darkhallow" },
	},
})
