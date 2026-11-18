-- Shadowfang Keep: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("shadowfang", {
	intro = "Archmage Arugal's worgen haunt Shadowfang Keep, a fortress above Silverpine.",
	lore = "Shadowfang Keep was once Baron Silverlaine's fortress. During the Third War, the mad archmage Arugal summoned worgen from another world to fight the Scourge. They turned on everyone, and the keep fell to Arugal and his pack. Now it looms over Silverpine Forest, full of worgen and the cursed dead of Silverlaine's house.",
	route = "Start in the courtyard and free the prisoners in the dungeon. Fight up through the kitchen, the halls and the courtyard, then climb the towers to Arugal's lair at the top.",
	tips = {
		"Bring a way to deal with curses if you can; several bosses use them.",
		"The worgen packs hit hard and come in groups. Pull one at a time.",
		"Arugal teleports around his room, so be ready to chase him.",
	},
	bosses = {
		{
			name = "Rethilgore",
			overview = "The jailer of the keep's dungeon.",
			lore = "The keep's jailer, a worgen who keeps the prisoners locked up.",
			strategy = { summary = "A simple melee fight. Free the prisoners afterward." },
		},
		{
			name = "Fel Steeds",
			optional = true,
			npcID = 3864,
			overview = "Three demonic horses in the stables: pull one and you pull them all.",
			lore = "Arugal's servants keep fel-touched horses in the keep's stables, and they're as vicious as their masters.",
			strategy = {
				summary = "Two Fel Steeds and a Shadow Charger come together however carefully you pull, and all three hit very hard. Polymorph one, let a hunter or warlock pet hold another, and kill the third, then move to the next.",
				tank = "Hold one horse at a time and keep the others controlled.",
				healer = "Expect heavy damage while more than one horse is loose.",
				dps = "Focus the same horse as the tank, and refresh crowd control.",
			},
			abilities = {
				{ name = "Fel Stomp", alerts = { "tank", "healer" }, text = "A heavy stomp." },
			},
		},
		{
			name = "Razorclaw the Butcher",
			overview = "The keep's butcher, in the kitchen.",
			lore = "The worgen butcher who runs the keep's kitchen.",
			strategy = { summary = "He drains health from his target.", healer = "Keep the tank topped up through his drains." },
			abilities = {
				{ name = "Butcher Drain", alerts = { "healer" }, text = "Drains health from a player." },
			},
		},
		{
			name = "Baron Silverlaine",
			overview = "The cursed lord of the keep.",
			lore = "The cursed lord of the keep, risen from his grave.",
			strategy = { summary = "He weakens healing on the tank.", healer = "The tank takes more healing than usual. Stay focused." },
			abilities = {
				{ name = "Veil of Shadow", alerts = { "curse", "tank" }, text = "Weakens healing on the tank." },
			},
		},
		{
			name = "Commander Springvale",
			overview = "A fallen paladin who still uses holy powers.",
			lore = "A fallen paladin who once defended the keep.",
			strategy = { summary = "He stuns the tank and heals himself.", dps = "Interrupt his Holy Light." },
			abilities = {
				{ name = "Hammer of Justice", alerts = { "tank" }, text = "Stuns the tank." },
				{ name = "Holy Light", alerts = { "interrupt" }, text = "Heals himself. Interrupt it." },
			},
		},
		{
			name = "Odo the Blindwatcher",
			overview = "A worgen who calls his packmates when he howls.",
			lore = "A blind worgen who listens for intruders.",
			strategy = { summary = "He grows angrier and hits harder as the fight goes on.", dps = "Kill him fast." },
			abilities = {
				{ name = "Howling Rage", alerts = { "enrage" }, text = "Hits harder as the fight goes on." },
			},
		},
		{
			name = "Deathsworn Captain",
			optional = true,
			npcID = 3872,
			overview = "A rare elite with a punishing cleave.",
			lore = "A captain of Gilneas who died at his post and kept standing guard.",
			strategy = {
				summary = "Tank him away from the group: his cleave hurts. If Wailing Guardsmen come with him, keep him at least 10 yards from them, out of their silence.",
				tank = "Face him away from everyone.",
				dps = "Stay behind him.",
			},
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him." },
				{ name = "Hamstring", alerts = { "tank" }, text = "Slows the tank." },
			},
		},
		{
			name = "Fenrus the Devourer",
			overview = "A giant wolf, bound by Arugal.",
			lore = "A giant wolf bound to Arugal's will.",
			strategy = { summary = "His saliva poisons the tank.", healer = "Cure the poison if you can." },
			abilities = {
				{ name = "Toxic Saliva", alerts = { "poison", "healer" }, text = "Poison damage over time." },
			},
		},
		{
			name = "Wolf Master Nandos",
			overview = "Keeps a pack of worgen that join the fight.",
			lore = "The master of the keep's worgen kennels.",
			strategy = { summary = "He calls worgen to join the fight.", dps = "Kill the worgen he calls, then Nandos." },
		},
		{
			name = "Archmage Arugal",
			overview = "The mad archmage who brought the worgen to this world.",
			lore = "The mad archmage who brought the worgen to Azeroth and then went mad.",
			strategy = {
				summary = "He teleports around the room, casts shadow bolts and turns players into worgen that attack their friends.",
				tank = "Follow him when he teleports.",
				healer = "His Void Bolt hits very hard. Watch out for it.",
				dps = "Break players out of his worgen curse as fast as you can.",
			},
			abilities = {
				{ name = "Shadow Bolt", alerts = { "healer" }, text = "Hits a random player with shadow." },
				{ name = "Void Bolt", alerts = { "deadly" }, text = "A massive shadow bolt." },
				{ name = "Arugal's Curse", alerts = { "curse" }, text = "Turns a player into a worgen and makes them attack allies." },
				{ name = "Teleport", alerts = { "important" }, text = "Blinks around the room. Chase him." },
				{ name = "Shadow Port", alerts = { "important" }, text = "He teleports to another ledge in the room; follow him.", spellID = 7587 },
			},
		},
	},
})
