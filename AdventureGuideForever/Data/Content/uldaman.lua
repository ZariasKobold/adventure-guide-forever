-- Uldaman: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("uldaman", {
	intro = "A titan vault in the Badlands, where Ironforge's explorers dig for the dwarves' origins.",
	bosses = {
		{
			name = "Revelosh",
			overview = "A troll caster leading the Shadowforge's allies.",
			abilities = {
				{ name = "Chain Lightning", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "The Lost Dwarves",
			alsoNamed = { "Baelog", "Eric \"The Swift\"", "Olaf" },
			overview = "Baelog, Eric, and Olaf fight together.",
			abilities = {
				{ name = "Three at Once", alerts = { "important" }, text = "Three dwarves: a warrior, a hunter, and a rogue. Kill them one at a time." },
			},
		},
		{
			name = "Ironaya",
			overview = "A titan watcher woken by opening the vault.",
			abilities = {
				{ name = "Knock Away", alerts = { "tank" }, text = "Knocks the tank back." },
				{ name = "Arcing Smash", alerts = { "tank", "dps" }, text = "Hits everyone in front of her." },
				{ name = "War Stomp", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
		{
			name = "Obsidian Sentinel",
			overview = "A stone guardian that spawns smaller sentinels.",
			abilities = {
				{ name = "Summon Obsidian Shard", alerts = { "dps" }, text = "Splits off small copies of itself." },
			},
		},
		{
			name = "Ancient Stone Keeper",
			overview = "A titan construct of stone.",
			abilities = {
				{ name = "Sand Storms", alerts = { "healer" }, text = "Damaging storms move around the room." },
			},
		},
		{
			name = "Galgann Firehammer",
			overview = "A Dark Iron leader at the dig site.",
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{
			name = "Grimlok",
			overview = "A trogg chieftain who rides a basilisk.",
			abilities = {
				{ name = "Shrink", alerts = { "magic" }, text = "Shrinks a player, lowering their strength." },
				{ name = "Chain Bolt", alerts = { "healer" }, text = "Jumps between players." },
			},
		},
		{
			name = "Archaedas",
			overview = "The titan keeper of the vault. The last boss.",
			abilities = {
				{ name = "Awaken Earthen Guardians", alerts = { "dps" }, text = "Wakes stone dwarves around the room." },
				{ name = "Awaken Vault Warder", alerts = { "dps", "important" }, text = "Wakes two big Vault Warders late in the fight." },
				{ name = "Ground Tremor", alerts = { "important" }, text = "Stuns everyone nearby." },
			},
		},
	},
})
