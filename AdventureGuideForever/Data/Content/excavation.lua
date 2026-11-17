-- Excavation Site: Wetlands: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("excavation", {
	intro = "Explorers dug too deep at the Wetlands excavation site and woke what guards the titans' relics.",
	lore = "In the Wetlands, Whelgar's Excavation Site has dug deeper than anyone planned. The diggers found titan relics, and the raptors, crocolisks and the relics' own guardian are not happy about it.",
	route = "The instance entrance is in the Wetlands, through Whelgar's Excavation Site. Saltspine and Shadetooth guard the way down to the Relic Guardian at the bottom of the dig.",
	tips = {
		"Wait until you're near level 26 before going in. The final boss is level 31.",
		"The Relic Guardian drops a Titan Relic that starts a quest.",
		"Strategy here is early notes from each boss's abilities.",
	},
	bosses = {
		{
			name = "Saltspine",
			overview = "A giant crocolisk at the dig site.",
			lore = "A huge crocolisk drawn to the dig site.",
			strategy = {
				summary = "Early notes: he tears tendons, bites hard and kicks up dust storms.",
				tank = "His Fatal Bite hits hard. Use cooldowns.",
				healer = "Tendon Rip slows players.",
			},
		},
		{
			name = "Shadetooth",
			overview = "A raptor alpha.",
			lore = "The leader of the raptors that have overrun the dig.",
			strategy = { summary = "Early notes: she causes bleeds, roars to fear players and enrages.", healer = "Heal through the bleed, and expect fear." },
		},
		{
			name = "Relic Guardian",
			overview = "The titan construct at the bottom of the dig. The last boss.",
			lore = "A titan guardian built to protect the relics buried here.",
			strategy = {
				summary = "Early notes: he slams the ground, knocks players away and puts players into stasis.",
				tank = "Keep your back to a wall to limit the knockback.",
				healer = "War Stomp stuns everyone near him.",
			},
		},
	},
})
