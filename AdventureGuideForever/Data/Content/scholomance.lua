-- Scholomance: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("scholomance", {
	intro = "The Cult of the Damned trains necromancers in the Barovs' old crypts.",
	lore = "Scholomance was once the Barov family's crypt. Now the Cult of the Damned runs it as a school for necromancers, teaching the dark arts to their students. Darkmaster Gandling, the headmaster, rules over all.",
	route = "Summon Kirtonos with a blood offering on the balcony. Go into the classrooms past Jandice and Rattlegore, then light the brazier rooms with their bosses: Malicia, Krastinov, Polkelt, the Ravenian and the Barovs. Gandling appears at the center once they all fall.",
	tips = {
		"You need the Skeleton Key to enter Scholomance.",
		"Kill the six room bosses to summon Gandling.",
		"Gandling teleports players into side rooms. Fight your way back out.",
	},
	bosses = {
		{
			name = "Kirtonos the Herald",
			overview = "A vampire bat summoned with a blood offering.",
			lore = "A vampire bat summoned with a blood offering.",
			strategy = { summary = "He knocks players back and controls minds." },
			abilities = {
				{ name = "Swoop", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Blood Steward of Kirtonos",
			optional = true,
			npcID = 14861,
			overview = "Kirtonos's steward, guarding the Reliquary.",
			lore = "A servant bound to Kirtonos, keeping his blood rites in the school's Reliquary.",
			strategy = {
				summary = "Her curses can be removed, and Paralyzing Poison stuns its target for 8 seconds. Cure both and burn her down.",
				healer = "Decurse, and cure the paralysis quickly.",
				dps = "A straightforward kill.",
			},
			abilities = {
				{ name = "Paralyzing Poison", alerts = { "poison", "important" }, text = "Stuns a player for 8 seconds.", spellID = 3609 },
				{ name = "Curse of Weakness", alerts = { "curse" }, text = "Lowers attack power.", spellID = 11708 },
				{ name = "Curse of Impotence", alerts = { "curse" }, text = "Lowers spell power.", spellID = 22371 },
			},
		},
		{
			name = "Jandice Barov",
			overview = "Splits into many illusions.",
			lore = "A Barov who splits into many illusions.",
			strategy = { summary = "Many copies appear. Find the real one." },
			abilities = {
				{ name = "Illusions", alerts = { "dps" }, text = "Many copies appear. Find the real one." },
				{ name = "Banish", alerts = { "magic" }, text = "Banishes a player for a few seconds.", spellID = 18647 },
			},
		},
		{
			name = "Rattlegore",
			overview = "A huge bone construct.",
			lore = "A huge bone construct.",
			strategy = { summary = "He knocks the tank back and stomps." },
			abilities = {
				{ name = "Sunder Armor", alerts = { "tank" }, text = "Stacks armor loss on the tank.", spellID = 11597 },
			},
		},
		{
			name = "Ras Frostwhisper",
			overview = "A lich who freezes his foes.",
			lore = "A lich who freezes his foes.",
			strategy = { summary = "He freezes players and fires frostbolt volleys." },
			abilities = {
				{ name = "Chill Nova", alerts = { "tank" }, text = "Freezes everyone nearby." },
			},
		},
		{
			name = "Instructor Malicia",
			npcID = 10505,
			overview = "A Scholomance teacher.",
			lore = "A Scholomance teacher.",
			strategy = { summary = "Light her brazier, then fight her." },
			abilities = {
				{ name = "Call of the Grave", alerts = { "curse" }, text = "A curse that hits hard when it runs out. Remove it.", spellID = 5137 },
				{ name = "Corruption", alerts = { "magic" }, text = "Shadow damage over time.", spellID = 25311 },
				{ name = "Heal", alerts = { "interrupt" }, text = "Heals herself. Interrupt it.", spellID = 6064 },
				{ name = "Renew", alerts = { "magic" }, text = "A heal over time. Dispel it.", spellID = 25315 },
				{ name = "Slow", alerts = { "magic" }, text = "Slows a player.", spellID = 6146 },
			},
		},
		{
			name = "Doctor Theolen Krastinov",
			overview = "The Butcher of Scholomance.",
			lore = "The Butcher of Scholomance.",
			strategy = { summary = "He enrages and hits hard." },
		},
		{
			name = "Lorekeeper Polkelt",
			overview = "Keeper of the school's lore.",
			lore = "Keeper of the school's lore.",
			strategy = { summary = "He poisons players." },
			abilities = {
				{ name = "Volatile Infection", alerts = { "disease" }, text = "A disease that spreads to nearby players.", spellID = 3586 },
				{ name = "Noxious Catalyst", alerts = { "disease" }, text = "Makes his diseases worse.", spellID = 5413 },
				{ name = "Corrosive Acid", alerts = { "tank" }, text = "Acid that eats at armor.", spellID = 8245 },
			},
		},
		{
			name = "The Ravenian",
			npcID = 10507,
			overview = "An abomination in the classroom.",
			lore = "An abomination in the classroom.",
			strategy = { summary = "He tramples everyone in front of him." },
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everyone in front of him." },
				{ name = "Sundering Cleave", alerts = { "tank", "dps" }, text = "Cleaves in front and lowers armor.", spellID = 25174 },
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him.", spellID = 20569 },
				{ name = "Knock Away", alerts = { "tank" }, text = "Throws the tank back and drops threat.", spellID = 11130 },
			},
		},
		{
			name = "Lord Alexei Barov",
			npcID = 10504,
			overview = "A Barov noble turned undead.",
			lore = "A Barov noble turned undead.",
			strategy = { summary = "He curses players." },
			abilities = {
				{ name = "Unholy Aura", alerts = { "healer" }, text = "Shadow damage to everyone near him.", spellID = 28340 },
				{ name = "Veil of Shadow", alerts = { "curse" }, text = "Reduces healing taken. Remove it.", spellID = 17820 },
				{ name = "Immolate", alerts = { "magic" }, text = "Fire damage over time.", spellID = 25309 },
			},
		},
		{
			name = "Lady Illucia Barov",
			npcID = 10502,
			overview = "A Barov noble turned undead.",
			lore = "A Barov noble turned undead.",
			strategy = { summary = "She takes control of a player." },
			abilities = {
				{ name = "Dominate Mind", alerts = { "important" }, text = "Takes control of a player." },
				{ name = "Fear", alerts = { "important" }, text = "Fears a player.", spellID = 6215 },
				{ name = "Silence", alerts = { "important" }, text = "Silences casters near her.", spellID = 12528 },
				{ name = "Shadow Shock", alerts = { "healer" }, text = "Shadow damage around her.", spellID = 17289 },
				{ name = "Bane of Agony", alerts = { "curse" }, text = "Shadow damage over time.", spellID = 11713 },
			},
		},
		{
			name = "Darkmaster Gandling",
			overview = "The headmaster. The last boss.",
			lore = "The headmaster of Scholomance.",
			strategy = { summary = "He teleports players into side rooms full of undead.", healer = "If you're teleported, fight your way back out." },
			abilities = {
				{ name = "Shadow Portal", alerts = { "important" }, text = "Teleports a player into a side room full of undead." },
				{ name = "Arcane Missiles", alerts = { "healer" }, text = "Arcane damage." },
			},
		},
		{
			name = "Marduk Blackpool",
			overview = "A death knight guarding the halls.",
			lore = "A death knight of the Scourge.",
			strategy = { summary = "He casts shadow bolt volleys and cleaves." },
		},
		{
			name = "Vectus",
			overview = "A fire caster guarding the halls.",
			lore = "A Scholomance student who mastered fire.",
			strategy = { summary = "He sets the ground on fire. Move out." },
		},
		{
			name = "Death Knight Darkreaver",
			overview = "A death knight summoned with a quest item.",
			lore = "A death knight summoned with a quest item.",
			strategy = { summary = "He cleaves, drains blood and mind-controls players." },
		},
		{
			name = "Kormok",
			overview = "An ogre necromancer summoned with a brazier.",
			lore = "An ogre necromancer.",
			strategy = { summary = "He summons bone minions and mages. Kill them." },
		},
	},
})
