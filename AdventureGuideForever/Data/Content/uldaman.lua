-- Uldaman: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("uldaman", {
	intro = "A titan vault in the Badlands, where Ironforge's explorers dig for the dwarves' origins.",
	lore = "Uldaman is an ancient titan vault buried under the Badlands. Explorers from Ironforge dig here for proof of where the dwarves came from, while the Dark Iron dwarves and the troggs fight them for it. Deep inside, the titan keeper Archaedas still guards the vault's secrets.",
	route = "Enter from the Badlands. Go through the dig site past Revelosh and the Lost Dwarves, then open the vault to wake Ironaya. Further in are Galgann, Grimlok and the Obsidian Sentinel, with Archaedas waiting in the deepest hall.",
	tips = {
		"Uldaman is long and has two entrances. Plan your route.",
		"The Staff of Prehistoria (from a quest chain) opens a shortcut.",
		"Archaedas wakes stone guardians during his fight. Kill them as they come.",
	},
	bosses = {
		{
			name = "Revelosh",
			overview = "A troll caster leading the Shadowforge's allies.",
			lore = "A troll caster allied with the Dark Irons.",
			strategy = { summary = "He throws chain lightning. Interrupt it." },
			abilities = {
				{ name = "Chain Lightning", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "The Lost Dwarves",
			alsoNamed = { "Baelog", "Eric \"The Swift\"", "Olaf" },
			overview = "Baelog, Eric, and Olaf fight together.",
			lore = "Baelog, Eric and Olaf: three dwarf adventurers lost in the dig.",
			strategy = { summary = "All three fight at once: a warrior, a hunter and a rogue.", dps = "Kill them one at a time." },
			abilities = {
				{
					name = "Three at Once",
					alerts = { "important" },
					text = "Three dwarves: a warrior, a hunter, and a rogue. Kill them one at a time.",
				},
			},
		},
		{
			name = "Ironaya",
			overview = "A titan watcher woken by opening the vault.",
			lore = "A titan watcher woken when you open the vault.",
			strategy = { summary = "She knocks the tank back and stuns the group.", tank = "Stand with your back to a wall to limit the knockback." },
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
				{ name = "Arcing Smash", alerts = { "tank", "dps" }, text = "Hits everyone in front of her." },
				{ name = "War Stomp", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
		{
			name = "Obsidian Sentinel",
			overview = "A stone guardian that spawns smaller sentinels.",
			lore = "A stone guardian of the vault.",
			strategy = { summary = "He splits off small copies of himself. Kill the shards as they come." },
			abilities = {
				{ name = "Summon Obsidian Shard", alerts = { "dps" }, text = "Splits off small copies of itself." },
			},
		},
		{
			name = "Ancient Stone Keeper",
			overview = "A titan construct of stone.",
			lore = "A titan construct made of stone.",
			strategy = { summary = "Sandstorms move around the room. Dodge them." },
			abilities = {
				{ name = "Sand Storms", alerts = { "healer" }, text = "Damaging storms move around the room." },
			},
		},
		{
			name = "Galgann Firehammer",
			overview = "A Dark Iron leader at the dig site.",
			lore = "A Dark Iron leader at the dig site.",
			strategy = { summary = "He casts fire nova and flame shock.", healer = "Heal the group through the fire." },
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Grimlok",
			overview = "A trogg chieftain who rides a basilisk.",
			lore = "A trogg chieftain who rides a basilisk.",
			strategy = { summary = "He shrinks players and throws chain lightning.", dps = "Interrupt his lightning." },
			abilities = {
				{ name = "Shrink", alerts = { "magic" }, text = "Shrinks a player, lowering their strength." },
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "Archaedas",
			overview = "The titan keeper of the vault. The last boss.",
			lore = "The titan keeper of the vault.",
			strategy = {
				summary = "He wakes stone dwarves around the room, then two big Vault Warders late in the fight.",
				tank = "Pick up the Vault Warders when they wake.",
				dps = "Kill the adds as they come, then focus Archaedas.",
			},
			abilities = {
				{ name = "Awaken Earthen Guardians", alerts = { "dps" }, text = "Wakes stone dwarves around the room." },
				{ name = "Awaken Vault Warder", alerts = { "dps", "important" }, text = "Wakes two big Vault Warders late in the fight." },
				{ name = "Ground Tremor", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
	},
})
