-- Krol'dok Stronghold: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("kroldok", {
	intro = "The Krol'dok ogres' capital overlooks the Riverglades, packed with Twilight's Hammer cultists and gnolls. It's huge, so set aside a long evening.",
	lore = "Krol'dok is the seat of the Krol'dok ogre clan. Their Twilight's Hammer allies and the Shadowhide gnolls have joined them here, and together they mean to crush the rival Bolderok clan and the Brotherhood of the Horse and take the Riverglades for themselves. Overlord Mugg rules it all from the top of the stronghold.",
	route = "The portal is just north of Sunnyglade, beside the city's sealed main gate. Start in the mines, where Slavecrusher Grox patrols, then work through the Twilight camp to Commander Zarmok, War Handler Ashka and Nar'gurk. Cross the bridge to Bossman Toof and climb to Overlord Mugg at the top.",
	tips = {
		"Horde can fly to Rog'mar, Alliance to Farholde Keep. Without those flight paths, walk in from the Badlands (Horde) or Redridge Mountains (Alliance).",
		"Twilight Grunts are the most dangerous trash: they Bladestorm everyone within 8 yards. Stun them, and polymorph extras when a pack has more than two.",
		"Twilight Outriders patrol the long roads in threes and net the tank in place. Pull them around a corner, and have a paladin free the tank.",
		"Twilight Peons run to fetch help. Kill or crowd-control them before they get away.",
		"Mugg drops a Krol'dok Ogre Key.",
	},
	bosses = {
		{
			name = "Slavecrusher Grox",
			overview = "The slave driver of the mines, who calls his prisoners to fight for him.",
			lore = "Grox keeps the stronghold's Redridge prisoners at work in the mines, and isn't above throwing them at intruders.",
			strategy = {
				summary = "He patrols the mines, so clear the gnolls along his path before you pull. During the fight he orders nearby prisoners to attack you; they're weak, so kill them fast and go back to Grox.",
				tank = "Expect short knockdowns, and a 30-second Bloodlust that speeds up his swings.",
				healer = "Bloodlust is when the tank takes the most damage.",
				dps = "Swap to prisoners as they arrive, then back to Grox.",
			},
			abilities = {
				{ name = "Force Compliance", alerts = { "dps" }, text = "Calls nearby prisoners into the fight.", spellID = 1280085 },
				{ name = "Bloodlust", alerts = { "tank", "healer" }, text = "30% faster attacks for 30 seconds.", spellID = 21049 },
				{ name = "Knockdown", alerts = { "tank" }, text = "Knocks the tank down for 2 seconds.", spellID = 11428 },
			},
			loot = {
				{ name = "Chain of Binding", slot = "Mail Waist" },
				{ name = "Resistance Breaker Spaulder", slot = "Mail Shoulder" },
				{ name = "Slavecrusher Scepter", slot = "One-Hand Mace" },
				{ name = "Blueprint: Expert Campfire", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Twilight Commander Zarmok",
			overview = "A Twilight's Hammer commander whose whirling blades shred anyone close.",
			lore = "The cult's man in Krol'dok, making sure the ogres stay pointed at the cult's enemies.",
			strategy = {
				summary = "He walks among Twilight's Hammer guards. Clear them until you can pull him alone, because his Rending Whirl hurts everyone within 8 yards and adds make it far worse.",
				tank = "Strike hits hard. Keep him where melee can step away from the Whirl.",
				healer = "Stay at range; heal through the spikes, and watch for an Enrage late in the fight.",
				dps = "Melee: step out when he starts to whirl.",
			},
			abilities = {
				{ name = "Rending Whirl", alerts = { "important", "dps" }, text = "Massive damage to everyone within 8 yards.", spellID = 1280011 },
				{ name = "Strike", alerts = { "tank" }, text = "A heavy hit on the tank.", spellID = 12057 },
				{ name = "Enrage", alerts = { "enrage" }, text = "He hits harder as he gets low.", spellID = 8599 },
			},
			loot = {
				{ name = "Shadecaster's Leggings", slot = "Cloth Legs" },
				{ name = "Shadowlight Athame", slot = "Main Hand Dagger" },
				{ name = "Zarmok's Plated Signet", slot = "Finger" },
			},
		},
		{
			name = "War Handler Ashka",
			overview = "The stronghold's beastmaster, with her wolves Snarlfang and Terrorhowl.",
			lore = "Ashka breeds and trains Krol'dok's war wolves, and keeps her two favorites at her side.",
			strategy = {
				summary = "Kill the wolves first, then Ashka. Without them this is an easy fight. Stuns (Hammer of Justice, Cheap Shot, Kidney Shot) keep the wolves under control.",
				tank = "Gather all three. When she sends the wolves after someone, taunt them back once Command: Kill! ends.",
				healer = "Command: Kill! sends both wolves at one player for 10 seconds; heal that player.",
				dps = "Wolves first, one at a time.",
			},
			abilities = {
				{
					name = "Command: Kill!",
					alerts = { "healer", "important" },
					text = "Both wolves attack one player for 10 seconds.",
					spellID = 1282076,
				},
				{ name = "Strike", alerts = { "tank" }, text = "A heavy hit on the tank.", spellID = 12057 },
			},
			loot = {
				{ name = "Bloodied Gutsclier", slot = "Two-Hand Sword" },
				{ name = "War Handler's Gaze", slot = "Leather Head" },
				{ name = "Worgbinder's Treads", slot = "Plate Feet" },
			},
		},
		{
			name = "Nar'gurk",
			overview = "An ogre shadowcaster who turns your own party against you.",
			lore = "Nar'gurk took the Twilight's Hammer's dark gifts gladly, and uses them to bend other minds to his will.",
			strategy = {
				summary = "He fights with a Shadowhide Curseweaver and two Twilight Warlocks. Crowd-control them (Polymorph, Sap, Fear) or kill them first. Convert takes control of a player, and only knocking them below 50% health breaks it.",
				tank = "Hold the boss while the group deals with the adds.",
				healer = "Shadow Bolt Volley hits everyone. When a Convert breaks, heal that player back up fast.",
				dps = "If someone is Converted, hit them gently until they're at half health, then go back to the boss.",
			},
			abilities = {
				{
					name = "Convert",
					alerts = { "important" },
					text = "Takes control of a player. Bring them below 50% health to break it.",
					spellID = 1280259,
				},
				{ name = "Shadow Bolt Volley", alerts = { "healer" }, text = "Shadow damage to the whole party.", spellID = 1280356 },
			},
			loot = {
				{ name = "Chain of the Corruptor", slot = "Neck" },
				{ name = "Krol'dok Warplate Chest", slot = "Plate Chest" },
				{ name = "Krol'dok Warplate Helmet", slot = "Plate Head" },
			},
		},
		{
			name = "Bossman Toof",
			overview = "The ogre warrior who holds the bridge, with brutes on call.",
			lore = "Toof runs the bridge crew and settles every argument the same way.",
			strategy = {
				summary = "Two parts. Once you pull the Centurions at the start of the bridge, Toof sends pairs of Krol'dok Brutes after you in waves. Clear the bridge packs between waves (a rogue's Distract buys time), then let one more wave come and kill it before you pull Toof and his two Shamans.",
				tank = "Mortal Strike cuts your healing, so don't take him with extra adds around.",
				healer = "Demoralizing Shout and Thunderclap hit everyone near him. Watch the tank during Mortal Strike.",
				dps = "Crowd-control the Shamans if you can; otherwise kill them before Toof.",
			},
			abilities = {
				{ name = "Mortal Strike", alerts = { "tank", "healer" }, text = "A heavy hit that reduces healing on the tank.", spellID = 16856 },
				{ name = "Thunderclap", alerts = { "dps" }, text = "Damages and slows everyone nearby.", spellID = 15548 },
				{ name = "Demoralizing Shout", alerts = { "tank" }, text = "Lowers the attack power of everyone nearby.", spellID = 16244 },
			},
			loot = {
				{ name = "Band of Bossman", slot = "Finger" },
				{ name = "Big-Belly Belt", slot = "Cloth Waist" },
				{ name = "Toofbreaker", slot = "One-Hand Mace" },
			},
		},
		{
			name = "Overlord Mugg",
			overview = "The ogre overlord of Krol'dok. He switches weapons and gets deadlier as the fight goes on.",
			lore = "Mugg rules the Krol'dok clan and means to rule the Riverglades too, with the Twilight's Hammer's help.",
			strategy = {
				summary = "Two Krol'dok Centurions fight with him; crowd-control them or kill them one by one before you push the boss. He leaps to random players with Crushing Slam, knocking them and anyone near them back. Mugg's Fury stacks up his attack speed until he changes weapons: first to a set of maces, then for the finish to a set of mauls that hit 50% harder.",
				tank = "His last weapon swap makes him hit far harder. Save your cooldowns for the mauls.",
				healer = "Spread out from the group so Crushing Slam only catches one person.",
				dps = "Kill the Centurions before you damage Mugg; the last stretch is the most dangerous.",
			},
			abilities = {
				{
					name = "Crushing Slam",
					alerts = { "important" },
					text = "Leaps to a random player, damaging and knocking back everyone nearby.",
					spellID = 1282397,
				},
				{ name = "Mugg's Fury", alerts = { "tank", "enrage" }, text = "Stacks attack speed until he changes weapons.", spellID = 1282387 },
				{ name = "Set of Maces", alerts = { "tank" }, text = "His first weapon swap.", spellID = 1282393 },
				{ name = "Set of Mauls", alerts = { "tank", "deadly" }, text = "His last weapon swap: 50% more damage.", spellID = 1282394 },
			},
			loot = {
				{ name = "Emblem of Slamming", slot = "Trinket" },
				{ name = "Mugg's Jabber", slot = "Fist Weapon" },
				{ name = "Mugg's Crosser", slot = "Fist Weapon" },
				{ name = "Strongly Scented Hood", slot = "Cloth Head" },
			},
		},
	},
})
