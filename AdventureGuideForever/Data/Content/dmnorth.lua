-- Gordok Commons: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmnorth", {
	intro = "Gordok Commons: the northern wing of Dire Maul, ruled by the Gordok ogres.",
	lore = "The northern wing of Dire Maul, Gordok Commons, belongs to the Gordok ogres. They crown as king whoever kills their current one. Kill King Gordok without killing his guards first, and the ogres will make you their new king.",
	route = "Go through the commons past Guard Mol'dar, Stomper Kreeg, Guard Fengus and Guard Slip'kik. Then fight Captain Kromcrush and Cho'Rush, and finally King Gordok himself.",
	tips = {
		"For the tribute run, avoid killing the guards: sneak past them instead.",
		"Stomper Kreeg sells drinks if you talk to him first.",
		"If the guards live, the ogres give you a chest of loot after you kill the king.",
	},
	bosses = {
		{
			name = "Guard Mol'dar",
			npcID = 14326,
			overview = "An ogre guard.",
			lore = "An ogre guard of the commons.",
			strategy = { summary = "A melee fight. Skip him for the tribute run." },
		},
		{
			name = "Stomper Kreeg",
			overview = "The Gordok's drunken brewmaster.",
			lore = "The Gordok's drunken brewmaster.",
			strategy = { summary = "He spins and stomps. You can talk to him instead of fighting." },
		},
		{
			name = "Guard Fengus",
			npcID = 14321,
			overview = "An ogre guard.",
			lore = "An ogre guard of the commons.",
			strategy = { summary = "A melee fight. Skip him for the tribute run." },
		},
		{
			name = "Guard Slip'kik",
			npcID = 14323,
			overview = "An ogre guard.",
			lore = "An ogre guard of the commons.",
			strategy = { summary = "A melee fight. Skip him for the tribute run." },
		},
		{
			name = "Captain Kromcrush",
			overview = "The ogres' captain.",
			lore = "The captain of the Gordok guard.",
			strategy = { summary = "He fears players and calls reavers." },
			abilities = {
				{ name = "Intimidating Shout", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{
			name = "Cho'Rush the Observer",
			overview = "An ogre mage beside the king.",
			lore = "An ogre mage who serves the king.",
			strategy = { summary = "He heals and casts lightning. Interrupt him." },
		},
		{
			name = "King Gordok",
			overview = "The Gordok king. Kill him to rule the ogres in his place.",
			lore = "The ogre king of Dire Maul.",
			strategy = { summary = "He stuns nearby players and lowers healing on the tank.", tank = "Use cooldowns, since your healing is reduced." },
			abilities = {
				{ name = "Mortal Strike", alerts = { "tank" }, text = "Lowers healing on the tank." },
				{ name = "War Stomp", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
	},
})
