-- Gnomeregan: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("gnomeregan", {
	intro = "The gnomes' capital, poisoned and overrun by troggs and leper gnomes.",
	lore = "Gnomeregan was the gnomes' wondrous capital under Dun Morogh, until troggs burst up from below. To save the city, High Tinker Mekkatorque flooded it with radiation on the advice of Mekgineer Thermaplugg. Most of the gnomes died, and the survivors turned into leper gnomes. Thermaplugg, the traitor who gave that advice, now rules the ruined city.",
	route = "Enter by the back door in Dun Morogh, or the Clean Zone near the front. Viscous Fallout and Grubbis are near the start. Electrocutioner 6000 and Crowd Pummeler 9-60 are in the machine halls, and Thermaplugg waits at the bottom.",
	tips = {
		"Bring good crowd control: the halls are full of robots and leper gnomes.",
		"Some quests need you to collect radioactive samples, so watch for them.",
		"The Dark Iron Ambassador is a rare boss; kill him if he appears.",
	},
	bosses = {
		{
			name = "Grubbis",
			overview = "A trogg who rides a crocolisk. Shows up during an escort.",
			lore = "A trogg who rides a crocolisk. He shows up during an escort.",
			strategy = { summary = "He fights alongside his crocolisk. Kill them both." },
		},
		{
			name = "Viscous Fallout",
			overview = "A blob of radioactive sludge.",
			lore = "A blob of radioactive sludge.",
			strategy = { summary = "His toxic volley poisons the group.", healer = "Cure poisons if you can." },
			abilities = {
				{ name = "Toxic Volley", alerts = { "poison", "healer" }, text = "Poisons everyone nearby." },
			},
		},
		{
			name = "Electrocutioner 6000",
			overview = "A security robot that chains lightning.",
			lore = "A security robot that guards the halls.",
			strategy = { summary = "His chain lightning jumps between players.", dps = "Spread out." },
			abilities = {
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "Crowd Pummeler 9-60",
			overview = "A robot built for crowd control, with a huge arm.",
			lore = "A robot built for crowd control.",
			strategy = { summary = "His arcing smash hits everyone in front of him.", tank = "Turn him away from the group." },
			abilities = {
				{ name = "Arcing Smash", alerts = { "tank", "dps" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Mekgineer Thermaplugg",
			overview = "The gnome who betrayed Gnomeregan. The last boss.",
			lore = "The traitor who doomed Gnomeregan.",
			strategy = {
				summary = "Bomb bots spill out of the vents around the room. Press the buttons next to each vent to close it.",
				dps = "One player should handle the buttons while the rest fight.",
			},
			abilities = {
				{ name = "Bomb Bots", alerts = { "dps", "important" }, text = "Bomb bots spill out of the vents. Press the buttons to close them." },
				{ name = "Knockaway", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Dark Iron Ambassador",
			overview = "A rare Dark Iron envoy who sometimes visits the city's ruins.",
			lore = "A Dark Iron dwarf envoy, here to make deals with the troggs.",
			strategy = { summary = "He fires fireballs and calls a fire servant. Interrupt his casts." },
		},
	},
})
