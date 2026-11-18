-- Blackfathom Deeps: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("blackfathom", {
	intro = "An ancient temple of the night elves, now flooded and claimed by the Twilight's Hammer.",
	lore = "Blackfathom Deeps was once a temple to Elune on the Ashenvale coast, sunk beneath the waves when the world was sundered. Ages later, the Twilight's Hammer cult found it and dug in. Lured by whispers from the deep, they serve Aku'mai, a hydra of the Old Gods, and guard something precious far below.",
	route = "Swim and climb through the flooded entrance past Ghamoo-ra and Lady Sarevess. Gelihast holds the murloc caves. The Twilight's Hammer camp leads to Twilight Lord Kelris, whose shrine opens the way to Old Serra'kis and finally Aku'mai.",
	tips = {
		"Much of the dungeon is underwater. Watch your breath bar.",
		"Light the four braziers at Kelris's shrine to open the final door. Expect waves of enemies while you do.",
		"Baron Aquanis is summoned from an altar as part of a quest.",
	},
	bosses = {
		{
			name = "Ghamoo-ra",
			overview = "A giant turtle in the flooded entrance.",
			lore = "A giant turtle that has made the flooded entrance its home.",
			strategy = { summary = "A slow, armored melee fight with no surprises." },
			abilities = {
				{ name = "Trample", alerts = { "tank" }, text = "Hits everything in front of him." },
			},
		},
		{
			name = "Lady Sarevess",
			overview = "A naga sorceress who shoots arrows and frost.",
			lore = "A naga sorceress who serves the temple's new masters.",
			strategy = {
				summary = "She roots players with frost and shoots lightning in a cone.",
				dps = "Ranged players should spread out so the cone hits fewer of you.",
			},
			abilities = {
				{ name = "Forked Lightning", alerts = { "healer" }, text = "Hits several players in front of her." },
				{ name = "Slow", alerts = { "magic" }, text = "Slows a player's movement." },
			},
		},
		{
			name = "Gelihast",
			overview = "The murloc king of the caves.",
			lore = "The murloc king of the deep caves.",
			strategy = { summary = "A simple melee fight. He can net a player in place." },
			abilities = {
				{ name = "Net", alerts = { "magic" }, text = "Roots a player in place." },
			},
		},
		{
			name = "Lorgus Jett",
			optional = true,
			overview = "A Twilight's Hammer leader in the depths. Only sometimes present.",
			lore = "A Twilight's Hammer captain who doesn't always appear.",
			strategy = { summary = "He shields himself with lightning. Interrupt his casts." },
			abilities = {
				{ name = "Lightning Shield", alerts = { "magic" }, text = "Shields himself with lightning." },
			},
		},
		{
			name = "Baron Aquanis",
			optional = true,
			npcID = 12876,
			overview = "A water spirit summoned from the altar (part of a quest).",
			lore = "A water elemental called up from the temple's altar.",
			strategy = { summary = "He fires frostbolts. Interrupt them." },
			abilities = {
				{ name = "Frostbolt", alerts = { "interrupt" }, text = "A strong frost bolt." },
			},
		},
		{
			name = "Twilight Lord Kelris",
			overview = "Leader of the Twilight's Hammer here.",
			lore = "The leader of the Twilight's Hammer in Blackfathom, who hears Aku'mai's voice in his dreams.",
			strategy = {
				summary = "He puts players to sleep and blasts them with shadow.",
				healer = "Keep the tank up while others are asleep.",
				dps = "Interrupt his Mind Blast.",
			},
			abilities = {
				{ name = "Sleep", alerts = { "magic", "healer" }, text = "Puts a player to sleep." },
				{ name = "Mind Blast", alerts = { "interrupt" }, text = "Shadow damage on a player." },
			},
		},
		{
			name = "The Fires of Aku'mai",
			overview = "Light the four braziers by the Azshara statue to open the way to Aku'mai.",
			lore = "Kelris's cult guards the fires that seal Aku'mai's lair, and each one calls up more of the old god's servants.",
			strategy = {
				summary = "After Kelris, clear the room and have the tank light one brazier at a time. Each brazier calls one wave: snapjaws, servants, crustaceans, or a swarm of Murkshallow Softshells. Kill each wave before lighting the next. All four open the door to Aku'mai.",
				tank = "Light each brazier yourself so the wave comes to you. The turtle wave hits hardest; an off-tank, a kiter or a pet should take one.",
				healer = "Rest between waves; the turtles are the hard part.",
				dps = "Area attacks shine on the softshells.",
			},
		},
		{
			name = "Old Serra'kis",
			overview = "A giant shark in the underwater tunnel.",
			lore = "An enormous shark that circles the flooded tunnel.",
			strategy = { summary = "The fight happens underwater, so keep an eye on your breath." },
		},
		{
			name = "Aku'mai",
			overview = "The hydra the Twilight's Hammer worships. The last boss.",
			lore = "The hydra the Twilight's Hammer worships, a servant of the Old Gods.",
			strategy = {
				summary = "A poison cloud surrounds her, and she frenzies at low health.",
				tank = "Use your cooldowns when she frenzies below about 30%.",
				healer = "The poison hits everyone near her. Melee players take the most damage.",
			},
			abilities = {
				{ name = "Poison Cloud", alerts = { "poison", "healer" }, text = "Poison around her." },
				{ name = "Frenzied Rage", alerts = { "enrage", "tank" }, text = "Hits much harder below about 30% health." },
			},
		},
	},
})
