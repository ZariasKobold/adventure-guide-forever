-- The Drowned City: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("drownedcity", {
	intro = "A sunken city off the coast of Stranglethorn Vale, entered south of the Haunted Isle.",
	lore = "Off the coast of Stranglethorn, south of the Haunted Isle, a city lies beneath the waves. Trolls, sea creatures and the undead have made it their home, and a great serpent rules from its depths.",
	route = "The entrance is underwater, west of Grom'gol Base Camp. Zul'Alai, Var'Taka, the Primeval Elemental, Captain Dreadrise and Deathless Marrow lead to Min'loth the Serpent. Umbra, Gill and the Pyromancer are rares.",
	tips = {
		"A Nov 9 hotfix fixed creatures here dealing about 30% too much damage.",
		"Non-boss enemies respawn after 2 hours (changed from 1 hour on Nov 13).",
		"Strategy here is early notes from each boss's abilities.",
	},
	bosses = {
		{
			name = "Zul'Alai",
			overview = "A troll warrior bound to an undying oath.",
			lore = "A troll warrior who swore an oath that won't let him die.",
			strategy = { summary = "Early notes: he slams hard and strikes with rot. Undying Oath may keep him going." },
		},
		{
			name = "Var'Taka",
			overview = "A harpoon-wielding sea warrior.",
			lore = "A sea warrior armed with a great harpoon.",
			strategy = { summary = "Early notes: he cleaves and pulls players in with his harpoon.", tank = "Turn him away from the group." },
		},
		{
			name = "Primeval Elemental",
			overview = "An ancient water elemental.",
			lore = "An ancient water elemental.",
			strategy = { summary = "Early notes: he fires water bolts and freezes water around players." },
		},
		{
			name = "Captain Dreadrise",
			overview = "A drowned ship's captain.",
			lore = "A captain who went down with his ship and came back up.",
			strategy = { summary = "Early notes: Embrine and Waterbolt Volley hit the whole group.", healer = "Keep the group topped up." },
		},
		{
			name = "Deathless Marrow",
			overview = "A creature of blood and bone.",
			lore = "A blood-soaked thing that will not die.",
			strategy = { summary = "Early notes: he poisons the blood and fires blood bolts." },
		},
		{
			name = "Min'loth the Serpent",
			overview = "The great serpent of the Drowned City.",
			lore = "The serpent who rules the Drowned City.",
			strategy = {
				summary = "Early notes: a busy fight. Floods, drains, poison volleys, fear and a fatal bite. He may transform partway through.",
				tank = "Use cooldowns for Fatal Bite.",
				healer = "Expect heavy group damage.",
			},
		},
		{
			name = "Umbra",
			optional = true,
			overview = "A rare creature of the depths.",
			lore = "A rare creature of the depths.",
			strategy = { summary = "It causes bleeds." },
		},
		{
			name = "Gill",
			optional = true,
			overview = "A rare creature of the depths.",
			lore = "A rare creature of the depths.",
			strategy = { summary = "He throws dynamite. Spread out." },
		},
		{
			name = "\"Pyromancer\" Braxton",
			overview = "A rare fire-happy rogue.",
			lore = "A self-styled pyromancer.",
			strategy = { summary = "He smashes heads. An easy rare." },
		},
	},
})
