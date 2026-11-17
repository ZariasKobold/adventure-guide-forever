-- Excavation Site: Wetlands: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("excavation", {
	intro = "Explorers dug too deep at the Wetlands excavation site and woke what guards the titans' relics.",
	bosses = {
		{ name = "Saltspine" },
		{ name = "Shadetooth" },
		{ name = "Relic Guardian", overview = "The titan construct at the bottom of the dig. The last boss." },
	},
})
