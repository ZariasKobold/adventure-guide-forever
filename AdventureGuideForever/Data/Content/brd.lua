-- Blackrock Depths: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("brd", {
	intro = "The Dark Iron dwarves' capital, built under Blackrock Mountain and ruled by Emperor Dagran Thaurissan.",
	bosses = {
		{
			name = "High Interrogator Gerstahn",
			overview = "Runs the detention block.",
			abilities = {
				{ name = "Psychic Scream", alerts = { "important" }, text = "Fears nearby players." },
			},
		},
		{
			name = "Lord Roccor",
			overview = "A fire elemental.",
			abilities = {
				{ name = "Earth Shock", alerts = { "interrupt" }, text = "Nature damage." },
			},
		},
		{ name = "Houndmaster Grebmar", overview = "Fights with his hounds." },
		{
			name = "Ring of Law",
			overview = "The arena. Random beasts and fighters, then a final boss.",
			abilities = {
				{ name = "Random Champions", alerts = { "important" }, text = "The opponents change every time." },
			},
		},
		{
			name = "Pyromancer Loregrain",
			overview = "A Dark Iron fire caster.",
			abilities = {
				{ name = "Molten Blast", alerts = { "healer" }, text = "Fire damage." },
			},
		},
		{
			name = "Lord Incendius",
			overview = "A fire lord at the Black Anvil.",
			abilities = {
				{ name = "Fire Storm", alerts = { "healer" }, text = "Fire damage around him." },
			},
		},
		{ name = "Warder Stilgiss", overview = "Guards the vault." },
		{ name = "Fineous Darkvire", overview = "The chief architect of the city." },
		{ name = "Bael'Gar", overview = "A giant elemental summoned in the Lyceum." },
		{
			name = "General Angerforge",
			overview = "Calls for help at low health.",
			abilities = {
				{ name = "Call Reinforcements", alerts = { "dps", "important" }, text = "Dwarves pour in at low health." },
			},
		},
		{ name = "Golem Lord Argelmach", overview = "Wakes golems as you approach." },
		{ name = "Hurley Blackbreath", overview = "A brewer in the Grim Guzzler." },
		{ name = "Phalanx", overview = "A golem guard in the Grim Guzzler." },
		{ name = "Plugger Spazzring", overview = "The Grim Guzzler's barkeep." },
		{
			name = "Ambassador Flamelash",
			overview = "Summons fire spirits to the room.",
			abilities = {
				{ name = "Burning Spirit", alerts = { "dps" }, text = "Fire spirits run to him and empower him." },
			},
		},
		{ name = "The Seven", overview = "Seven dwarf spirits that fight one at a time." },
		{
			name = "Magmus",
			overview = "A giant golem guarding the throne room.",
			abilities = {
				{ name = "Fire Jets", alerts = { "important" }, text = "The room's statues breathe fire." },
			},
		},
		{
			name = "Emperor Dagran Thaurissan",
			overview = "The emperor, with Princess Moira at his side. The last boss.",
			abilities = {
				{ name = "Hand of Thaurissan", alerts = { "tank" }, text = "Stuns the tank." },
				{ name = "Avatar of Flame", alerts = { "important" }, text = "Fire damage around him." },
				{ name = "Princess Moira", alerts = { "interrupt" }, text = "Moira heals the emperor. Interrupt or control her." },
			},
		},
	},
})
