-- Warpwood Quarter: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmeast", {
	intro = "Warpwood Quarter: the eastern wing of Dire Maul, overrun by satyrs and corrupted treants.",
	bosses = {
		{ name = "Pusillin", overview = "An imp you chase through the wing. He holds a key." },
		{
			name = "Zevrim Thornhoof",
			overview = "A satyr who sacrifices to his demonic masters.",
			abilities = {
				{ name = "Sacrifice", alerts = { "important" }, text = "Takes a player and drains them." },
			},
		},
		{
			name = "Hydrospawn",
			overview = "A water elemental in the pool.",
			abilities = {
				{ name = "Massive Geyser", alerts = { "dps" }, text = "Throws players into the air." },
			},
		},
		{
			name = "Lethtendris",
			overview = "A night elf sorceress draining the pylons.",
			abilities = {
				{ name = "Void Bolt", alerts = { "interrupt" }, text = "A strong shadow bolt." },
			},
		},
		{
			name = "Alzzin the Wildshaper",
			overview = "The satyr who leads Warpwood. The last boss.",
			abilities = {
				{ name = "Wildshape", alerts = { "important" }, text = "Changes into different forms." },
				{ name = "Summon Wildlings", alerts = { "dps" }, text = "Calls vines." },
			},
		},
	},
})
