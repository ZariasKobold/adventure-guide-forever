-- Krol'dok Stronghold: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("kroldok", {
	intro = "Twilight's Hammer ogres hold this fortress in the Riverglades, north of Sunnyglade.",
	lore = "During the siege of Farholde, the Horde's leaders were assassinated and their army was broken by the Brotherhood of the Horse. What was left fled to Krol'dok, an ogre stronghold in the Riverglades. Its ogres serve the Twilight's Hammer.",
	route = "The stronghold is north of Sunnyglade, near the passes from the Badlands and Redridge Mountains. Slavecrusher Grox, Twilight Commander Zarmok, War Handler Ashka, Nar'gurk and Bossman Toof lead to Overlord Mugg.",
	tips = {
		"The nearest flight points are Rog'mar (Horde) and Farholde Keep (Alliance).",
		"Mugg drops a Krol'dok Ogre Key.",
		"Strategy here is still being learned.",
	},
	bosses = {
		{
			name = "Slavecrusher Grox",
			overview = "An ogre who works the slaves.",
			lore = "The ogre in charge of the stronghold's slaves.",
			loot = {
				{ name = "Chain of Binding", slot = "Mail Waist" },
				{ name = "Resistance Breaker Spaulder", slot = "Mail Shoulder" },
				{ name = "Slavecrusher Scepter", slot = "One-Hand Mace" },
				{ name = "Blueprint: Expert Campfire", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Twilight Commander Zarmok",
			overview = "A Twilight's Hammer commander.",
			lore = "A commander of the Twilight's Hammer.",
			loot = {
				{ name = "Shadecaster's Leggings", slot = "Cloth Legs" },
				{ name = "Shadowlight Athame", slot = "Main Hand Dagger" },
				{ name = "Zarmok's Plated Signet", slot = "Finger" },
			},
		},
		{
			name = "War Handler Ashka",
			overview = "The keeper of the war beasts.",
			lore = "The ogre who trains the stronghold's war beasts.",
			loot = {
				{ name = "Bloodied Gutsclier", slot = "Two-Hand Sword" },
				{ name = "War Handler's Gaze", slot = "Leather Head" },
				{ name = "Worgbinder's Treads", slot = "Plate Feet" },
			},
		},
		{
			name = "Nar'gurk",
			overview = "A Twilight's Hammer ogre.",
			lore = "A corrupted ogre of the Twilight's Hammer.",
			loot = {
				{ name = "Chain of the Corruptor", slot = "Neck" },
				{ name = "Krol'dok Warplate Chest", slot = "Plate Chest" },
				{ name = "Krol'dok Warplate Helmet", slot = "Plate Head" },
			},
		},
		{
			name = "Bossman Toof",
			overview = "The ogres' foreman.",
			lore = "An ogre boss who likes his job a little too much.",
			loot = {
				{ name = "Band of Bossman", slot = "Finger" },
				{ name = "Big-Belly Belt", slot = "Cloth Waist" },
				{ name = "Toofbreaker", slot = "One-Hand Mace" },
			},
		},
		{
			name = "Overlord Mugg",
			overview = "The ogre overlord of Krol'dok.",
			lore = "The ogre overlord of Krol'dok.",
			loot = {
				{ name = "Emblem of Slamming", slot = "Trinket" },
				{ name = "Mugg's Jabber", slot = "Fist Weapon" },
				{ name = "Mugg's Crosser", slot = "Fist Weapon" },
				{ name = "Strongly Scented Hood", slot = "Cloth Head" },
			},
		},
	},
})
