-- Onyxia's Lair: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("onyxia", {
	intro = "The black dragon Onyxia hides in a lair in Dustwallow Marsh.",
	lore = "Onyxia, daughter of the black dragon Deathwing, has hidden in Dustwallow Marsh for years under a mortal disguise, working to destroy the kingdoms of men. Her lair is a cavern of fire and whelps in the marsh.",
	route = "Walk through the tunnel past her whelp-guards to the main chamber. The fight happens in the round room at the end.",
	tips = {
		"Bring fear protection for phase 3 if your group has it.",
		"During phase 2, kill the whelps quickly before they overwhelm the group.",
		"Never stand in front of her head or behind her tail.",
	},
	bosses = {
		{
			name = "Onyxia",
			npcID = 10184,
			overview = "A three-phase fight. Onyxia fights on the ground, then takes to the air above a cave full of whelps, then lands again with her fear.",
			lore = "The daughter of Deathwing, who disguised herself as Lady Katrana Prestor to manipulate Stormwind's court.",
			strategy = {
				summary = "Three phases. On the ground, then flying while whelps pour from the side caves, then landed with her fear roar until she dies.",
				tank = "In phase 1, turn her side-on to the raid. In phase 3, pick her up quickly when she lands.",
				healer = "Expect heavy damage from her fireballs in phase 2 and fear in phase 3.",
				dps = "Kill the whelps during phase 2. Stay out of her Deep Breath path.",
			},
			abilities = {
				{
					name = "Phase 1: On the Ground",
					alerts = { "important" },
					text = "Tank her with her side to the raid. Everyone else stays away from her head and tail.",
				},
				{ name = "Flame Breath", alerts = { "tank", "deadly" }, text = "Breathes fire in a cone in front of her." },
				{ name = "Tail Sweep", alerts = { "dps" }, text = "Knocks back and damages anyone behind her." },
				{ name = "Wing Buffet", alerts = { "tank" }, text = "Knocks the tank back and lowers threat." },
				{ name = "Phase 2: In the Air", alerts = { "important" }, text = "At 65% health she takes off. Whelps pour out of the side caves." },
				{ name = "Deep Breath", alerts = { "deadly" }, text = "She breathes fire across the whole room. Get out of her path." },
				{ name = "Fireball", alerts = { "healer" }, text = "Hits a random player and anyone near them for fire damage." },
				{ name = "Phase 3: Landed", alerts = { "important" }, text = "At 40% health she lands. Floor vents start erupting." },
				{ name = "Bellowing Roar", alerts = { "healer", "important" }, text = "Fears the whole raid. Fear-immunity effects help a lot here." },
			},
		},
	},
})
