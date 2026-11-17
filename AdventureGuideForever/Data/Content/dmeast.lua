-- Warpwood Quarter: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dmeast", {
	intro = "Warpwood Quarter: the eastern wing of Dire Maul, overrun by satyrs and corrupted treants.",
	lore = "Dire Maul is the ruin of Eldre'Thalas, an ancient Highborne city in Feralas. Its eastern wing, the Warpwood Quarter, has been overrun by satyrs and corrupted treants, all serving the satyr Alzzin the Wildshaper.",
	route = "Chase the imp Pusillin through the wing to get his key. Go past Zevrim, Hydrospawn and Lethtendris, then up to Alzzin at the end. Isalien can be summoned with a special brazier.",
	tips = {
		"Pusillin runs away when you talk to him. Chase him to the end of his path for the key.",
		"The key Pusillin drops opens other parts of Dire Maul.",
		"Lethtendris drains the pylons. Kill her quickly.",
	},
	bosses = {
		{
			name = "Pusillin",
			overview = "An imp you chase through the wing. He holds a key.",
			lore = "An imp with a key, who leads you on a chase.",
			strategy = { summary = "Talk to him and chase him. When he finally stops, he fights with fire spells." },
		},
		{
			name = "Zevrim Thornhoof",
			overview = "A satyr who sacrifices to his demonic masters.",
			lore = "A satyr who sacrifices to his demonic masters.",
			strategy = { summary = "He sacrifices a player, draining them. Heal the sacrificed player." },
			abilities = {
				{ name = "Sacrifice", alerts = { "important" }, text = "Takes a player and drains them." },
			},
		},
		{
			name = "Hydrospawn",
			overview = "A water elemental in the pool.",
			lore = "A water elemental in the pool.",
			strategy = { summary = "He throws players into the air and summons smaller water elementals." },
			abilities = {
				{ name = "Massive Geyser", alerts = { "dps" }, text = "Throws players into the air." },
			},
		},
		{
			name = "Lethtendris",
			overview = "A night elf sorceress draining the pylons.",
			lore = "A night elf sorceress draining the pylons.",
			strategy = { summary = "She casts shadow bolt volleys and curses. Interrupt her." },
			abilities = {
				{ name = "Void Bolt", alerts = { "interrupt" }, text = "A strong shadow bolt." },
			},
		},
		{
			name = "Alzzin the Wildshaper",
			overview = "The satyr who leads Warpwood. The last boss.",
			lore = "The satyr who rules the Warpwood Quarter.",
			strategy = { summary = "He changes between wolf and tree forms, and calls vines.", tank = "Each form hits differently. Keep your cooldowns ready." },
			abilities = {
				{ name = "Wildshape", alerts = { "important" }, text = "Changes into different forms." },
				{ name = "Summon Wildlings", alerts = { "dps" }, text = "Calls vines." },
			},
		},
		{
			name = "Isalien",
			overview = "A night elf spirit summoned with a special brazier.",
			lore = "A night elf priestess's spirit, called back to Dire Maul.",
			strategy = { summary = "A hunter-style fight: she shoots and calls a pet." },
		},
	},
})
