-- City of Dalaran: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dalaran", {
	intro = "Beneath Dalaran's walls, the city's sewers leak wild magic. You need a Dalaran Sewer Key to get in.",
	lore = "The great walls of Dalaran stand in the Alterac Mountains, sealed against the world after the city's fall. Below them, the sewers have filled with wild magic. Arcane creatures, spirits of the dead and a mage's lost ghost wander the tunnels and the old Violet Citadel.",
	route = "Enter through the sewer grate on Dalaran's western wall. At least one group member needs the Dalaran Sewer Key. Fight from the sewers up through the city, ending with the Shade of the Archmage in the Purple Parlor at the top of the Violet Citadel.",
	tips = {
		"Get the Dalaran Sewer Key from the Image of Archmage Modera on Lordamere Lake's southern shore in Silverpine.",
		"Wait until you're around level 28; the final boss is level 31.",
		"Strategy for most bosses here is still being learned.",
	},
	bosses = {
		{
			name = "Atrexis the Grave Knight",
			overview = "A death knight in the sewers.",
			lore = "A grave knight risen beneath Dalaran.",
			loot = {
				{ name = "Bonebinder's Signet", slot = "Finger" },
				{ name = "Gravespike Repeater", slot = "Crossbow" },
				{ name = "Graveweave Bindings", slot = "Cloth Wrist" },
			},
		},
		{
			name = "Arcane Anomaly",
			overview = "A living rift of arcane energy.",
			lore = "Wild magic given form.",
			loot = {
				{ name = "Ephemeral Grips", slot = "Cloth Hands" },
				{ name = "Mana-Warped Chain Shirt", slot = "Mail Chest" },
				{ name = "Runemender's Seal", slot = "Finger" },
			},
		},
		{
			name = "Arcanic Enigma",
			overview = "A puzzle of living arcane power.",
			lore = "An arcane being born from the city's leaking magic.",
			loot = {
				{ name = "Drape of Shifting Energy", slot = "Back" },
				{ name = "Violet Sorcerer's Robes", slot = "Cloth Chest" },
				{ name = "Wand of Mana Concentration", slot = "Wand" },
			},
		},
		{
			name = "Unstable Sentinel",
			overview = "A failing arcane construct.",
			lore = "A construct whose wards are breaking down.",
			loot = {
				{ name = "Guardian's Dualblade", slot = "Two-Hand Axe" },
				{ name = "Refractory Scaleguards", slot = "Mail Legs" },
				{ name = "Unstable Crystalline Shoulderpads", slot = "Leather Shoulder" },
				{ name = "Blueprint: Spinning Wheel", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Mana Devourer",
			overview = "A creature that feeds on magic.",
			lore = "A beast drawn to the city's magic, growing fat on it.",
			loot = {
				{ name = "Manascale Treads", slot = "Mail Feet" },
				{ name = "Slitherwrap Girdle", slot = "Leather Waist" },
				{ name = "Spine of the Devourer", slot = "Staff" },
			},
		},
		{
			name = "Fel Ancient",
			overview = "A treant twisted by fel magic.",
			lore = "A treant twisted by fel energy.",
			loot = {
				{ name = "Blightleaf Rope", slot = "Cloth Waist" },
				{ name = "Felbough Arm", slot = "Polearm" },
				{ name = "Garb of Fallen Felbark", slot = "Leather Chest" },
			},
		},
		{
			name = "Lyn the Ignored",
			overview = "A forgotten spirit.",
			lore = "A spirit no one remembers, haunting the sewers.",
			loot = {
				{ name = "Bonepile Gaze", slot = "Shield" },
				{ name = "Cartilage Shapers", slot = "Leather Hands" },
				{ name = "Tendonscraper Dagger", slot = "Dagger" },
			},
		},
		{
			name = "Shade of the Archmage",
			overview = "The last boss of the Dalaran sewers.",
			lore = "The ghost of a Kirin Tor archmage who still guards the Violet Citadel.",
			strategy = {
				summary = "He fires Arcane Bolts and Arcane Explosions, sends a Bounding Mana orb out and back through the group, polymorphs nearby players and slows everyone close to him.",
				tank = "Keep him away from the group so his Explosion and Slow only hit you.",
				healer = "Spread out from the tank to avoid his Mass Polymorph.",
				dps = "Watch for the mana orb; step out of its path on the way out and back.",
			},
			loot = {
				{ name = "Archmagister's Faceted Pendant", slot = "Neck" },
				{ name = "Ponderous Orb", slot = "Off Hand" },
				{ name = "Violet Sorcerer's Mantle", slot = "Cloth Shoulder" },
				{ name = "Blueprint: Arcane Salvager", slot = "Campsite Recipe (Enchanting 140)" },
			},
		},
	},
})
