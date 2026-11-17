-- Gordok Commons: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmnorth", {
	intro = "Gordok Commons: the northern wing of Dire Maul, ruled by the Gordok ogres.",
	bosses = {
		{ name = "Guard Mol'dar", npcID = 14326, overview = "An ogre guard." },
		{ name = "Stomper Kreeg", overview = "The Gordok's drunken brewmaster." },
		{ name = "Guard Fengus", npcID = 14321, overview = "An ogre guard." },
		{ name = "Guard Slip'kik", npcID = 14323, overview = "An ogre guard." },
		{
			name = "Captain Kromcrush",
			overview = "The ogres' captain.",
			abilities = {
				{ name = "Intimidating Shout", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{ name = "Cho'Rush the Observer", overview = "An ogre mage beside the king." },
		{
			name = "King Gordok",
			overview = "The Gordok king. Kill him to rule the ogres in his place.",
			abilities = {
				{ name = "Mortal Strike", alerts = { "tank" }, text = "Lowers healing on the tank." },
				{ name = "War Stomp", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
	},
})
