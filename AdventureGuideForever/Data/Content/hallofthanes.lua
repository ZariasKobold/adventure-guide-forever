-- The Hall of Thanes: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("hallofthanes", {
	intro = "Old Ironforge, sealed for ages, is open at last, and the Dark Irons have broken into the tombs of the dwarven thanes beneath it.",
	lore = "Beneath the High Seat lies Old Ironforge, a part of the city no one has walked in living memory. Its Hall of Thanes is where Khaz Modan's legendary dwarves were laid to rest. Now Dark Iron raiders have tunneled in to loot the honored dead, led by Durgen Dirgehammer, and the tombs' guardians are stirring.",
	route = "In the High Seat, take the open door on your left as you walk in and follow the path all the way down through Old Ironforge to the portal. Inside: Faldrim Anvilmar patrols Anvilmar's Rest, Magmatus burns with a Dark Iron Summoner, the golem Plunder walks his hallway, and Durgen Dirgehammer waits at the end with two stone golems.",
	tips = {
		"Pick up the quests in Kharanos and near the entrance before you go down.",
		"Horde have a long trek: from Tarren Mill through Arathi, the Wetlands and Loch Modan into Ironforge, past the guards. Take your gear off before you get close so deaths don't cost durability.",
		"Dark Iron Engineers pick a spot before they throw their bombs. Watch for it and step away; the damage is completely avoidable.",
		"Dark Iron Looters hit fast. Don't pull too many at once at this level.",
		"Break line of sight on Dark Iron Summoners to drag them to you instead of eating Fireballs.",
	},
	bosses = {
		{
			name = "Faldrim Anvilmar",
			overview = "A thane's restless spirit, patrolling the middle of Anvilmar's Rest.",
			lore = "A thane of the Anvilmar line who can't rest while thieves walk his halls.",
			strategy = {
				summary = "A simple fight. The real danger is pulling him along with trash as he walks past. Clear one side of the room, wait for him to come to you, then pull.",
				tank = "He'll lay a 10-minute Anvilmar's Curse on you. Ask for a decurse if your group has one.",
				healer = "Mind Blast adds some burst on his target.",
				dps = "Interrupt Mind Blast if you can.",
			},
			abilities = {
				{ name = "Anvilmar's Curse", alerts = { "curse", "tank" }, text = "A 10-minute curse on the tank.", spellID = 1292602 },
				{ name = "Mind Blast", alerts = { "interrupt" }, text = "Shadow damage on his target.", spellID = 26048 },
			},
		},
		{
			name = "Magmatus",
			overview = "A fire elemental loose in the tombs, with a Dark Iron Summoner beside it.",
			lore = "A living mass of magma, called up from the deep forges by the Dark Irons' summoners.",
			strategy = {
				summary = "A healing check. Kill the Dark Iron Summoner first. Magmatus pulses fire around itself every so often and Combusts a random player.",
				tank = "Pull Magmatus away from the group as soon as you engage, so its fire pulses only hit you.",
				healer = "Combust can land on anyone; keep everyone topped up.",
				dps = "Summoner first, then the elemental. Ranged stay back.",
			},
			abilities = {
				{ name = "Combust", alerts = { "healer" }, text = "Fire damage on a random player.", spellID = 1293228 },
			},
		},
		{
			name = "Plunder",
			overview = "A treasure golem that patrols its hallway.",
			lore = "Built to guard the thanes' riches, Plunder no longer cares who the treasure belongs to.",
			strategy = {
				summary = "His only trick is a knockback. Pull him somewhere you won't be thrown into other packs.",
				tank = "Put your back to a wall or a corner so Knock Away barely moves you.",
				healer = "An easy fight; keep the tank up.",
				dps = "Stay behind him, near the wall.",
			},
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Throws the tank back.", spellID = 10101 },
			},
		},
		{
			name = "Durgen Dirgehammer",
			overview = "The Dark Iron leader at the end of the halls, with two stone golems.",
			lore = "A Dark Iron who came to plunder the tombs of the thanes, and plans to keep everything he finds.",
			strategy = {
				summary = "Clear the Dark Iron Looters around the edge of the room first. He fights with two Lesser Stone Golems; take them down one at a time, using stuns and fears to keep the damage under control.",
				tank = "Rend and the golems add up to a lot of damage on you. Pull carefully.",
				healer = "Heal through the Rend bleed, and expect a group fear.",
				dps = "One golem at a time, then the boss.",
			},
			abilities = {
				{ name = "Fear", alerts = { "important" }, text = "Sends nearby players running in terror.", spellID = 26070 },
				{ name = "Rend", alerts = { "tank", "healer" }, text = "A bleed on the tank.", spellID = 12054 },
			},
		},
	},
})
