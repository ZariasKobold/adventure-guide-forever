-- Gnomeregan: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("gnomeregan", {
	intro = "The gnomes' capital, poisoned and overrun by troggs and leper gnomes.",
	bosses = {
		{ name = "Grubbis", overview = "A trogg who rides a crocolisk. Shows up during an escort." },
		{
			name = "Viscous Fallout",
			overview = "A blob of radioactive sludge.",
			abilities = {
				{ name = "Toxic Volley", alerts = { "poison", "healer" }, text = "Poisons everyone nearby." },
			},
		},
		{
			name = "Electrocutioner 6000",
			overview = "A security robot that chains lightning.",
			abilities = {
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "Crowd Pummeler 9-60",
			overview = "A robot built for crowd control, with a huge arm.",
			abilities = {
				{ name = "Arcing Smash", alerts = { "tank", "dps" }, text = "Hits everyone in front of it." },
			},
		},
		{
			name = "Mekgineer Thermaplugg",
			overview = "The gnome who betrayed Gnomeregan. The last boss.",
			abilities = {
				{ name = "Bomb Bots", alerts = { "dps", "important" }, text = "Bomb bots spill out of the vents. Press the buttons to close them." },
				{ name = "Knockaway", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
	},
})
