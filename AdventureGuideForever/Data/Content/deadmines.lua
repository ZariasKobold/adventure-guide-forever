-- Deadmines: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("deadmines", {
	intro = "Under Moonbrook, the Defias Brotherhood has turned an old goblin mine into a shipyard. Edwin VanCleef is building a juggernaut there, and the brotherhood means to sail it against Stormwind.",
	bosses = {
		{
			name = "Rhahk'Zor",
			overview = "The ogre foreman guards the first stretch of the mine. He hits hard but has no tricks.",
			abilities = {
				{ name = "Rhahk'Zor Slam", alerts = { "tank" }, text = "A heavy blow that briefly stuns the tank." },
			},
		},
		{
			name = "Sneed's Shredder",
			alsoNamed = { "Sneed" },
			overview = "Sneed pilots a lumber shredder. Destroy the shredder and Sneed jumps out to finish the fight himself.",
			abilities = {
				{ name = "Terrify", alerts = { "healer" }, text = "The shredder sends a player fleeing in fear." },
				{ name = "Distracting Pain", alerts = { "tank" }, text = "Makes the tank less able to avoid attacks for a short time." },
				{ name = "Eject Sneed", alerts = { "important" }, text = "When the shredder dies, Sneed leaps out. Pick him up right away." },
			},
		},
		{
			name = "Gilnid",
			overview = "The goblin smelter works the foundry, surrounded by goblin workers. Clear the workers first.",
			abilities = {
				{ name = "Molten Metal", alerts = { "healer" }, text = "Splashes molten metal for fire damage." },
				{ name = "Melt Ore", alerts = { "tank" }, text = "Burns the target with fire damage over time." },
			},
		},
		{
			name = "Mr. Smite",
			overview = "VanCleef's first mate fights on the dock. He changes weapons twice during the fight, stopping to re-arm each time.",
			abilities = {
				{ name = "Smite Stomp", alerts = { "important" }, text = "Stuns everyone nearby while he swaps weapons. He changes weapons at about two thirds and one third health." },
				{ name = "Smite Slam", alerts = { "tank" }, text = "Hits the tank hard." },
			},
		},
		{
			name = "Captain Greenskin",
			overview = "The goblin captain guards the ship's deck with his crew.",
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him. Melee should stand behind him." },
				{ name = "Poisoned Harpoon", alerts = { "healer", "poison" }, text = "Poisons a target for nature damage over time." },
			},
		},
		{
			name = "Edwin VanCleef",
			overview = "The leader of the Defias Brotherhood makes his last stand on the deck of his juggernaut.",
			abilities = {
				{ name = "VanCleef's Allies", alerts = { "important", "dps" }, text = "Near the end of the fight, VanCleef calls Defias Blackguards to his side. Kill or control them quickly." },
				{ name = "Thrash", alerts = { "tank" }, text = "Strikes the tank several times in quick succession." },
			},
		},
		{
			name = "Cookie",
			optional = true,
			overview = "The ship's murloc cook waits below deck. He's optional.",
			abilities = {
				{ name = "Cookie's Cooking", alerts = { "dps" }, text = "Cookie heals himself with a bite of his own cooking." },
			},
		},
	},
})
