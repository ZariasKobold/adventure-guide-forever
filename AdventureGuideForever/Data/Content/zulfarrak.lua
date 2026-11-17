-- Zul'Farrak: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("zulfarrak", {
	intro = "The Sandfury trolls rule from this sun-baked city in Tanaris.",
	bosses = {
		{
			name = "Antu'sul",
			overview = "The trolls' basilisk keeper.",
			abilities = {
				{ name = "Summon Basilisks", alerts = { "dps" }, text = "Calls basilisks to help at low health." },
			},
		},
		{
			name = "Theka the Martyr",
			overview = "Turns into a scarab beetle that takes no physical damage.",
			abilities = {
				{ name = "Theka Transform", alerts = { "important" }, text = "As a beetle he's immune to physical damage. Use spells." },
			},
		},
		{
			name = "Witch Doctor Zum'rah",
			overview = "Raises zombies from the graveyard.",
			abilities = {
				{ name = "Zombies", alerts = { "dps" }, text = "Zombies climb out of graves." },
				{ name = "Shadow Bolt Volley", alerts = { "healer" }, text = "Shadow damage on everyone." },
			},
		},
		{ name = "Sergeant Bly", overview = "Leads the prisoners on the pyramid steps. Part of the stair event." },
		{ name = "Nekrum Gutchewer", overview = "Joins the fight after the stair event." },
		{
			name = "Shadowpriest Sezz'ziz",
			overview = "A priest at the top of the stairs.",
			abilities = {
				{ name = "Heal", alerts = { "interrupt" }, text = "Heals allies. Interrupt it." },
			},
		},
		{
			name = "Hydromancer Velratha",
			overview = "A troll water caster at the sacred pool.",
			abilities = {
				{ name = "Healing Wave", alerts = { "interrupt" }, text = "Heals herself." },
			},
		},
		{
			name = "Gahz'rilla",
			optional = true,
			overview = "A giant hydra, summoned at the pool with a special mallet.",
			abilities = {
				{ name = "Freeze Solid", alerts = { "tank" }, text = "Freezes the tank in place." },
				{ name = "Gahz'rilla Slam", alerts = { "important" }, text = "Throws players into the air." },
			},
		},
		{
			name = "Chief Ukorz Sandscalp",
			overview = "The Sandfury chief, fighting beside his bodyguard Ruuzlu.",
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him." },
				{ name = "Enrage", alerts = { "enrage" }, text = "Enrages at low health." },
			},
		},
	},
})
