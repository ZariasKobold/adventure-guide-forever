-- Blackmaw Hold: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("blackmaw", {
	intro = "A stronghold hidden in the wilds of Azshara.",
	bosses = {
		{ name = "Bonesnout the Unbroken" },
		{ name = "Elder Shaman Bloodmane" },
		{ name = "Impaan the Imprisoner" },
		{ name = "Unbound Spirit" },
		{ name = "Varrox Bleakhoof" },
		{ name = "Withermaw" },
		{ name = "Moontouched Wanderer", optional = true, overview = "A rare wanderer in the hold." },
		{ name = "Tunnelweb Matriarch", optional = true, overview = "A rare spider in the tunnels." },
	},
})
