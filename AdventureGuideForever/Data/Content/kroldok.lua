-- Krol'dok Stronghold: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("kroldok", {
	intro = "Twilight's Hammer ogres hold this fortress in the Riverglades, north of Sunnyglade.",
	bosses = {
		{
			name = "Slavecrusher Grox",
			loot = {
				{ name = "Chain of Binding", slot = "Mail Waist" },
				{ name = "Resistance Breaker Spaulder", slot = "Mail Shoulder" },
				{ name = "Slavecrusher Scepter", slot = "One-Hand Mace" },
				{ name = "Blueprint: Expert Campfire", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Twilight Commander Zarmok",
			loot = {
				{ name = "Shadecaster's Leggings", slot = "Cloth Legs" },
				{ name = "Shadowlight Athame", slot = "Main Hand Dagger" },
				{ name = "Zarmok's Plated Signet", slot = "Finger" },
			},
		},
		{
			name = "War Handler Ashka",
			loot = {
				{ name = "Bloodied Gutsclier", slot = "Two-Hand Sword" },
				{ name = "War Handler's Gaze", slot = "Leather Head" },
				{ name = "Worgbinder's Treads", slot = "Plate Feet" },
			},
		},
		{
			name = "Nar'gurk",
			loot = {
				{ name = "Chain of the Corruptor", slot = "Neck" },
				{ name = "Krol'dok Warplate Chest", slot = "Plate Chest" },
				{ name = "Krol'dok Warplate Helmet", slot = "Plate Head" },
			},
		},
		{
			name = "Bossman Toof",
			loot = {
				{ name = "Band of Bossman", slot = "Finger" },
				{ name = "Big-Belly Belt", slot = "Cloth Waist" },
				{ name = "Toofbreaker", slot = "One-Hand Mace" },
			},
		},
		{
			name = "Overlord Mugg",
			overview = "The ogre overlord of Krol'dok.",
			loot = {
				{ name = "Emblem of Slamming", slot = "Trinket" },
				{ name = "Mugg's Jabber", slot = "Fist Weapon" },
				{ name = "Mugg's Crosser", slot = "Fist Weapon" },
				{ name = "Strongly Scented Hood", slot = "Cloth Head" },
			},
		},
	},
})
