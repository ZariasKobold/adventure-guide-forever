-- The Drowned City: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("drownedcity", {
	intro = "A sunken city off the coast of Stranglethorn Vale, entered south of the Haunted Isle.",
	bosses = {
		{ name = "Zul'Alai" },
		{ name = "Var'Taka" },
		{ name = "Primeval Elemental" },
		{ name = "Captain Dreadrise" },
		{ name = "Deathless Marrow" },
		{ name = "Min'loth the Serpent" },
		{ name = "Umbra", optional = true, overview = "A rare creature of the depths." },
		{ name = "Gill", optional = true, overview = "A rare creature of the depths." },
	},
})
