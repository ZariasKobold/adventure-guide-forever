-- Excavation Site: Wetlands: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("excavation", {
	intro = "The Explorers' League dug into something titan-made in the Wetlands hills, and the raptors and relics there aren't happy about it.",
	lore = "For years the Explorers' League has dug in the Wetlands at Whelgar's Excavation Site, hunting for the origins of the dwarves while fending off raptors. When strange activity turned up to the southeast, they opened a new camp and found titan works beneath the hills. Something down there is still awake to guard them.",
	route = "Follow the dig past the crocolisk cove to Saltspine, then through the thick grass of the raptor thicket to Shadetooth. The titan vault at the bottom holds the Relic Guardian.",
	tips = {
		"You can pick up the quests at 24, but wait until closer to 30: the last boss is level 31.",
		"Stay out of the tall grass in the raptor thicket. Walk through it long enough and Thicket Lurkers jump out.",
		"Thicket Matriarchs screech for Lurkers when they get low. Kill everything else in the pull first, so fewer enemies are up when the Lurkers arrive.",
		"Fight in open ground so nobody backs into the grass mid-pull.",
	},
	bosses = {
		{
			name = "Saltspine",
			overview = "A giant crocolisk lurking in the cove at the dig site.",
			lore = "The cove's biggest crocolisk, who has decided the dig belongs to him.",
			strategy = {
				summary = "Easy once the area around it is cleared. It slows the tank and kicks up a Dust Storm that makes nearby attacks miss.",
				tank = "Tendon Rip slows you a lot, but the fight doesn't ask you to move.",
				healer = "Stand back out of the Dust Storm.",
				dps = "Casters: don't stand in melee range.",
			},
			abilities = {
				{ name = "Dust Storm", alerts = { "dps" }, text = "Players within 10 yards get 25% less chance to hit.", spellID = 1316382 },
				{ name = "Tendon Rip", alerts = { "tank" }, text = "Slows the tank heavily.", spellID = 3604 },
			},
		},
		{
			name = "Shadetooth",
			overview = "The raptor alpha of the thicket, with two Thicket Hunters at his side.",
			lore = "The pack leader of the thicket raptors, and very protective of his hunting ground.",
			strategy = {
				summary = "Unforgiving if you rush it. Crowd-control both Thicket Hunters, or control one and kill the other first. His Terrifying Roar fears everyone for 5 seconds and can't be dispelled, which is how groups get chased into the grass and fresh raptors. Clear the crocolisk cove first and fight him there. Don't use the water, since the Hunters can't swim and the fight resets.",
				tank = "Rend adds steady damage. Below 30% he enrages; slows and stuns work on him.",
				healer = "Dispel Infected Wound from the Hunters' targets quickly.",
				dps = "Hunters under control first. Save your stuns for his enrage at 30%.",
			},
			abilities = {
				{
					name = "Terrifying Roar",
					alerts = { "important" },
					text = "A 5-second fear that can't be dispelled. Watch where you run.",
					spellID = 14100,
				},
				{ name = "Enrage", alerts = { "enrage" }, text = "Hits much harder below 30% health.", spellID = 18501 },
				{ name = "Rend", alerts = { "tank" }, text = "A bleed on the tank.", spellID = 12054 },
			},
		},
		{
			name = "Relic Guardian",
			overview = "The titan construct at the bottom of the dig. The last boss.",
			lore = "A titan watcher left to guard the vault, woken by the League's digging.",
			strategy = {
				summary = "Press the Archival Panel to the right of the dormant guardian to start. It's a gear and level check: lots of health and hard hits on the tank. Thunderclap slows and damages everyone within 10 yards. It can be stunned and slowed, so use crowd control often.",
				tank = "Expect knockbacks and 5-second stuns. Use the nearby structures to kite it if things go badly.",
				healer = "The tank takes heavy damage, especially while stunned.",
				dps = "Ranged stay out of Thunderclap range. Rotate your stuns and slows.",
			},
			abilities = {
				{
					name = "Thunderclap",
					alerts = { "healer", "dps" },
					text = "Damages everyone within 10 yards and slows their movement and attacks.",
					spellID = 15588,
				},
			},
		},
	},
})
