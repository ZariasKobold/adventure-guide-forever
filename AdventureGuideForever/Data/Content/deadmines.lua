-- Deadmines: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("deadmines", {
	intro = "Under Moonbrook, the Defias Brotherhood has turned an old goblin mine into a shipyard. Edwin VanCleef is building a juggernaut there, and the brotherhood means to sail it against Stormwind.",
	lore = "The Defias Brotherhood began as the stonemasons who rebuilt Stormwind and were never paid for it. Led by Edwin VanCleef, they turned to banditry and now hide in an old goblin mine beneath Moonbrook. Down there, deep under Westfall, they are building a juggernaut: a warship they mean to sail against the kingdom that wronged them.",
	route = "Enter through the mine in Moonbrook. Fight through the tunnels past Rhahk'Zor, Sneed and Gilnid's foundry. Then blast open the cave doors with the cannon to reach the hidden cove, where Mr. Smite, Captain Greenskin and VanCleef wait aboard the ship. Cookie hides below deck.",
	tips = {
		"Pick up the Westfall quests from Sentinel Hill first. Many of them end inside.",
		"Goblin engineers summon bombs and adds; kill them quickly.",
		"The cove has many packs on the ship's decks. Pull carefully on the narrow planks.",
	},
	bosses = {
		{
			name = "Rhahk'Zor",
			overview = "The ogre foreman guards the first stretch of the mine. He hits hard but has no tricks.",
			lore = "The ogre foreman of the Defias miners, hired muscle who keeps the workers in line.",
			strategy = {
				summary = "A tank-and-spank fight with no tricks, just heavy hits.",
				tank = "His slam stuns you briefly. Have the healer ready for the follow-up hit.",
			},
			abilities = {
				{ name = "Rhahk'Zor Slam", alerts = { "tank" }, text = "A heavy blow that briefly stuns the tank." },
			},
		},
		{
			name = "Sneed's Shredder",
			alsoNamed = { "Sneed" },
			overview = "Sneed pilots a lumber shredder. Destroy the shredder and Sneed jumps out to finish the fight himself.",
			lore = "Sneed is a goblin lumberjack the Defias pay to work their timber. He rides into battle in his shredder.",
			strategy = {
				summary = "Two parts: destroy the shredder, then Sneed jumps out and fights on foot.",
				tank = "Grab Sneed the moment he ejects, before he runs to a caster.",
				healer = "The shredder's fear can scatter the group. Stay calm and heal whoever is still in reach.",
			},
			abilities = {
				{ name = "Terrify", alerts = { "healer" }, text = "The shredder sends a player fleeing in fear." },
				{ name = "Distracting Pain", alerts = { "tank" }, text = "Makes the tank less able to avoid attacks for a short time." },
				{ name = "Eject Sneed", alerts = { "important" }, text = "When the shredder dies, Sneed leaps out. Pick him up right away." },
			},
		},
		{
			name = "Gilnid",
			overview = "The goblin smelter works the foundry, surrounded by goblin workers. Clear the workers first.",
			lore = "Gilnid runs the goblin foundry that forges the juggernaut's parts, and he doesn't like visitors.",
			strategy = {
				summary = "Clear the goblin workers around the foundry first, then fight Gilnid alone.",
				healer = "His molten metal splashes the group for fire damage.",
			},
			abilities = {
				{ name = "Molten Metal", alerts = { "healer" }, text = "Splashes molten metal for fire damage." },
				{ name = "Melt Ore", alerts = { "tank" }, text = "Burns the target with fire damage over time." },
			},
		},
		{
			name = "Mr. Smite",
			overview = "VanCleef's first mate fights on the dock. He changes weapons twice during the fight, stopping to re-arm each time.",
			lore = "VanCleef's first mate, a tauren who swaps weapons as the fight turns.",
			strategy = {
				summary = "At about two thirds and one third health he stomps, stunning the group, then rushes to his chest to change weapons.",
				tank = "Each weapon swap resets his position. Pick him up again quickly when he returns.",
				dps = "Stop damage briefly when he walks to his chest, then hit hard with the new weapon.",
			},
			abilities = {
				{
					name = "Smite Stomp",
					alerts = { "important" },
					text = "Stuns everyone nearby while he swaps weapons. He changes weapons at about two thirds and one third health.",
				},
				{ name = "Smite Slam", alerts = { "tank" }, text = "Hits the tank hard." },
			},
		},
		{
			name = "Captain Greenskin",
			overview = "The goblin captain guards the ship's deck with his crew.",
			lore = "The goblin captain of the juggernaut, who stands guard over the ship's deck.",
			strategy = {
				summary = "He fights alongside his crew. Kill the crew first if you can.",
				tank = "Turn him away from the group. His cleave hits everyone in front of him.",
				healer = "His poisoned harpoon puts a damage-over-time effect on its target.",
			},
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him. Melee should stand behind him." },
				{ name = "Poisoned Harpoon", alerts = { "healer", "poison" }, text = "Poisons a target for nature damage over time." },
			},
		},
		{
			name = "Edwin VanCleef",
			overview = "The leader of the Defias Brotherhood makes his last stand on the deck of his juggernaut.",
			lore = "The master stonemason who rebuilt Stormwind, then was cheated of his pay. His Defias Brotherhood is his revenge.",
			strategy = {
				summary = "A fast melee duelist. Near the end of the fight he calls Defias Blackguards to his side.",
				tank = "His Thrash lands several hits at once; use a cooldown when it comes.",
				healer = "Save mana for the end, when the Blackguards arrive.",
				dps = "When the Blackguards appear, burn them or crowd-control them, then finish VanCleef.",
			},
			abilities = {
				{
					name = "VanCleef's Allies",
					alerts = { "important", "dps" },
					text = "Near the end of the fight, VanCleef calls Defias Blackguards to his side. Kill or control them quickly.",
				},
				{ name = "Thrash", alerts = { "tank" }, text = "Strikes the tank several times in quick succession." },
			},
		},
		{
			name = "Cookie",
			optional = true,
			overview = "The ship's murloc cook waits below deck. He's optional.",
			lore = "The ship's murloc cook, still stirring his pot below deck.",
			strategy = { summary = "An optional boss. He heals himself by eating his own cooking, so finish him quickly." },
			abilities = {
				{ name = "Cookie's Cooking", alerts = { "dps" }, text = "Cookie heals himself with a bite of his own cooking." },
			},
		},
		{
			name = "Miner Johnson",
			overview = "A rare Defias miner who sometimes works the tunnels.",
			lore = "A Defias miner with a nose for gold. He only appears on some visits.",
			strategy = { summary = "Easy if you spot him. Kill him for his rare drops." },
			abilities = {
				{ name = "Pierce Armor", alerts = { "tank" }, text = "Lowers the tank's armor.", spellID = 12097 },
			},
		},
	},
})
