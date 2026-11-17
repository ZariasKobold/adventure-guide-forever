-- Alcaz Prison: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("alcaz", {
	intro = "A prison on Alcaz Island, off the coast of Dustwallow Marsh.",
	bosses = {
		{ name = "The Questioner" },
		{ name = "Tidemistress Ca'zass" },
		{ name = "Overseer Wrex" },
		{ name = "Katerina the Cleaner" },
		{ name = "Blazeroar" },
	},
})
