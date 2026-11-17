-- Blackmaw Hold: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("blackmaw", {
	intro = "A stronghold hidden in the wilds of Azshara.",
	lore = "In the wilds of Azshara, the Blackmaw furbolgs have fallen to dark powers. Their hold now shelters demons, spirits and worse.",
	route = "Bonesnout the Unbroken, Elder Shaman Bloodmane, Impaan the Imprisoner, the Unbound Spirit and Varrox Bleakhoof lead to Withermaw. The Moontouched Wanderer, Tunnelweb Matriarch and Gortek the Apprentice are rares.",
	tips = {
		"Quests start at level 45; the final boss is level 57.",
		"Impaan casts many kinds of shadowbolts. Expect heavy shadow damage.",
		"Strategy here is early notes from each boss's abilities.",
	},
	bosses = {
		{
			name = "Bonesnout the Unbroken",
			overview = "A massive furbolg.",
			lore = "A huge furbolg who has never lost a fight.",
			strategy = { summary = "Early notes: he tramples, stomps and shields himself with Profane Bulwark." },
		},
		{
			name = "Elder Shaman Bloodmane",
			overview = "A furbolg shaman.",
			lore = "A furbolg shaman gone over to darkness.",
			strategy = { summary = "Early notes: he casts chain lightning, calls a feral spirit and purges buffs.", dps = "Kill the feral spirit." },
		},
		{
			name = "Impaan the Imprisoner",
			overview = "An imp who loves shadowbolts.",
			lore = "An imp with a talent for shadowbolts.",
			strategy = { summary = "Early notes: he casts many kinds of shadowbolts.", dps = "Interrupt his casts." },
		},
		{
			name = "Unbound Spirit",
			overview = "A fire spirit set free.",
			lore = "A fire spirit set free.",
			strategy = { summary = "Early notes: he casts fire nova and fireballs, and devours players." },
		},
		{
			name = "Varrox Bleakhoof",
			overview = "A demon of nightmares.",
			lore = "A demon who feeds on nightmares.",
			strategy = { summary = "Early notes: he casts shadow bolt volleys, fear and Nightmare Detonation.", healer = "Expect heavy group shadow damage." },
		},
		{
			name = "Withermaw",
			lore = "The beast that rules Blackmaw Hold.",
			strategy = { summary = "Early notes: he mauls, roars, summons players and spawns a writhing mass.", dps = "Kill the writhing mass." },
		},
		{
			name = "Moontouched Wanderer",
			optional = true,
			overview = "A rare wanderer in the hold.",
			lore = "A rare wanderer touched by the moon.",
			strategy = { summary = "She enrages and casts moonfire." },
		},
		{
			name = "Tunnelweb Matriarch",
			optional = true,
			overview = "A rare spider in the tunnels.",
			lore = "A rare spider in the tunnels.",
			strategy = { summary = "She webs and poisons players." },
		},
		{
			name = "Gortek the Apprentice",
			overview = "A rare apprentice shaman.",
			lore = "A shaman's apprentice.",
			strategy = { summary = "He casts lightning bolts and earth shocks." },
		},
	},
})
