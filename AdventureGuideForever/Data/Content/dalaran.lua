-- City of Dalaran: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dalaran", {
	intro = "Beneath Dalaran's walls, the city's sewers leak wild magic. You need a Dalaran Sewer Key to get in.",
	bosses = {
		{
			name = "Atrexis the Grave Knight",
			loot = {
				{ name = "Bonebinder's Signet", slot = "Finger" },
				{ name = "Gravespike Repeater", slot = "Crossbow" },
				{ name = "Graveweave Bindings", slot = "Cloth Wrist" },
			},
		},
		{
			name = "Arcane Anomaly",
			loot = {
				{ name = "Ephemeral Grips", slot = "Cloth Hands" },
				{ name = "Mana-Warped Chain Shirt", slot = "Mail Chest" },
				{ name = "Runemender's Seal", slot = "Finger" },
			},
		},
		{
			name = "Arcanic Enigma",
			loot = {
				{ name = "Drape of Shifting Energy", slot = "Back" },
				{ name = "Violet Sorcerer's Robes", slot = "Cloth Chest" },
				{ name = "Wand of Mana Concentration", slot = "Wand" },
			},
		},
		{
			name = "Unstable Sentinel",
			loot = {
				{ name = "Guardian's Dualblade", slot = "Two-Hand Axe" },
				{ name = "Refractory Scaleguards", slot = "Mail Legs" },
				{ name = "Unstable Crystalline Shoulderpads", slot = "Leather Shoulder" },
				{ name = "Blueprint: Spinning Wheel", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Mana Devourer",
			loot = {
				{ name = "Manascale Treads", slot = "Mail Feet" },
				{ name = "Slitherwrap Girdle", slot = "Leather Waist" },
				{ name = "Spine of the Devourer", slot = "Staff" },
			},
		},
		{
			name = "Fel Ancient",
			loot = {
				{ name = "Blightleaf Rope", slot = "Cloth Waist" },
				{ name = "Felbough Arm", slot = "Polearm" },
				{ name = "Garb of Fallen Felbark", slot = "Leather Chest" },
			},
		},
		{
			name = "Lyn the Ignored",
			loot = {
				{ name = "Bonepile Gaze", slot = "Shield" },
				{ name = "Cartilage Shapers", slot = "Leather Hands" },
				{ name = "Tendonscraper Dagger", slot = "Dagger" },
			},
		},
		{
			name = "Shade of the Archmage",
			overview = "The last boss of the Dalaran sewers.",
			loot = {
				{ name = "Archmagister's Faceted Pendant", slot = "Neck" },
				{ name = "Ponderous Orb", slot = "Off Hand" },
				{ name = "Violet Sorcerer's Mantle", slot = "Cloth Shoulder" },
				{ name = "Blueprint: Arcane Salvager", slot = "Campsite Recipe (Enchanting 140)" },
			},
		},
	},
})
