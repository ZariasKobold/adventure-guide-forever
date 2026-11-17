-- Barrow Deeps: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("barrowdeeps", {
	intro = "Barrow Deeps lies beneath Mount Hyjal. Opens December 9.",
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
