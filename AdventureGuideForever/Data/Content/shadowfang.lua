-- Shadowfang Keep: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("shadowfang", {
	intro = "Archmage Arugal's worgen haunt Shadowfang Keep, a fortress above Silverpine.",
	bosses = {
		{ name = "Rethilgore", overview = "The jailer of the keep's dungeon." },
		{
			name = "Razorclaw the Butcher",
			overview = "The keep's butcher, in the kitchen.",
			abilities = {
				{ name = "Butcher Drain", alerts = { "healer" }, text = "Drains health from a player." },
			},
		},
		{
			name = "Baron Silverlaine",
			overview = "The cursed lord of the keep.",
			abilities = {
				{ name = "Veil of Shadow", alerts = { "curse", "tank" }, text = "Weakens healing on the tank." },
			},
		},
		{
			name = "Commander Springvale",
			overview = "A fallen paladin who still uses holy powers.",
			abilities = {
				{ name = "Hammer of Justice", alerts = { "tank" }, text = "Stuns the tank." },
				{ name = "Holy Light", alerts = { "interrupt" }, text = "Heals himself. Interrupt it." },
			},
		},
		{
			name = "Odo the Blindwatcher",
			overview = "A worgen who calls his packmates when he howls.",
			abilities = {
				{ name = "Howling Rage", alerts = { "enrage" }, text = "Hits harder as the fight goes on." },
			},
		},
		{
			name = "Fenrus the Devourer",
			overview = "A giant wolf, bound by Arugal.",
			abilities = {
				{ name = "Toxic Saliva", alerts = { "poison", "healer" }, text = "Poison damage over time." },
			},
		},
		{ name = "Wolf Master Nandos", overview = "Keeps a pack of worgen that join the fight." },
		{
			name = "Archmage Arugal",
			overview = "The mad archmage who brought the worgen to this world.",
			abilities = {
				{ name = "Shadow Bolt", alerts = { "healer" }, text = "Hits a random player with shadow." },
				{ name = "Void Bolt", alerts = { "deadly" }, text = "A massive shadow bolt." },
				{ name = "Arugal's Curse", alerts = { "curse" }, text = "Turns a player into a worgen and makes them attack allies." },
				{ name = "Teleport", alerts = { "important" }, text = "Blinks around the room. Chase him." },
			},
		},
	},
})
