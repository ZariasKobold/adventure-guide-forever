-- City of Dalaran: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("dalaran", {
	intro = "Dalaran's shield has finally come down, and the rebuilt city of mages is crawling with wild magic, undead and worse. Someone in your group needs a Dalaran Sewer Key.",
	lore = "Arthas razed Dalaran in the Third War, and Archimonde finished the job. The surviving Kirin Tor spent years rebuilding behind a violet dome in the Alterac Mountains. Now the dome is gone, and the city's leaking magic has drawn arcane horrors, restless dead and a fel-twisted ancient into its streets and sewers. The Kirin Tor need adventurers to take their city back.",
	route = "Open the sewer gate (only one person needs the key) and start below the city. Atrexis the Grave Knight waits early in the sewers. Climb out into the streets for the Arcane Anomaly, Arcanic Enigma and Unstable Sentinel, then head to the Violet Hold entrance for the Mana Devourer. The Fel Ancient can be fought at any point. Finish in the Violet Citadel with the Shade of the Archmage. Lyn the Ignored is a hidden boss you summon in the sewers.",
	tips = {
		"Alliance can ask the Image of Archmage Modera at the sewer entrance for a key. Horde earn theirs through a short quest chain from Magus Wordeen Voidglare in Tarren Mill.",
		"Nearly everything here is immune to Arcane. Mages and hunters should lean on other schools, and Counterspell won't land on most casters.",
		"Interrupt or kill Mana Phantoms quickly: their Mana Burn empties healers.",
		"A defeated Saturated Remnant leaves a pool that restores mana. Stand in it between pulls.",
		"The run back after a wipe is long, so rez where you can.",
	},
	bosses = {
		{
			name = "Atrexis the Grave Knight",
			overview = "A grave knight who guards the sewers with an army of risen skeletons.",
			lore = "Some fallen defender of Dalaran, raised in death and set to guard the dark under the city.",
			strategy = {
				summary = "An early, simple fight that mostly tests the tank. He keeps raising skeletons; kill them as they come.",
				tank = "Wear a shield: he hits hard, frenzies, and disarms you now and then. Build threat on him and grab the skeletons.",
				healer = "Expect spiky tank damage during Unholy Frenzy.",
				dps = "Hold big area attacks until the tank has the skeletons, then cleave them down.",
			},
			abilities = {
				{ name = "Raise Dead", alerts = { "dps" }, text = "Calls up skeletons that join the fight.", spellID = 1303266 },
				{ name = "Unholy Frenzy", alerts = { "tank", "healer" }, text = "Speeds up his attacks for a while.", spellID = 1303264 },
				{ name = "Disarm", alerts = { "tank" }, text = "Knocks the tank's weapon away briefly.", spellID = 6713 },
				{ name = "Thrash", alerts = { "tank" }, text = "A flurry of extra attacks.", spellID = 3391 },
				{ name = "Strike", alerts = { "tank" }, text = "A heavy melee hit.", spellID = 12057 },
			},
			loot = {
				{ name = "Bonebinder's Signet", slot = "Finger" },
				{ name = "Gravespike Repeater", slot = "Crossbow" },
				{ name = "Graveweave Bindings", slot = "Cloth Wrist" },
			},
		},
		{
			name = "Arcane Anomaly",
			overview = "A tear of raw arcane power with a beam that sweeps the whole room.",
			lore = "Wild magic from the fallen dome, pulled together into something that almost thinks.",
			strategy = {
				summary = "Everything is about Focal Blast: a beam that slices across the room and slowly turns counterclockwise. Keep moving ahead of it. Stay on the platform circle so you don't pull the small adds waiting at the edges.",
				tank = "Hold the boss in the middle so the group has room to walk around the beam.",
				healer = "Keep an eye on the beam first and heals second; nobody survives a full hit.",
				dps = "Keep your eyes on the beam's direction and rotate with it.",
			},
			abilities = {
				{
					name = "Focal Blast",
					alerts = { "deadly" },
					text = "A beam that cuts across the room and turns counterclockwise. Stay out of it.",
					spellID = 1241501,
				},
				{ name = "Arcane Bolt", alerts = { "tank" }, text = "Arcane damage on its target.", spellID = 15230 },
			},
			loot = {
				{ name = "Ephemeral Grips", slot = "Cloth Hands" },
				{ name = "Mana-Warped Chain Shirt", slot = "Mail Chest" },
				{ name = "Runemender's Seal", slot = "Finger" },
			},
		},
		{
			name = "Arcanic Enigma",
			overview = "A shifting arcane being that silences anyone who crowds it.",
			lore = "Something the city's spilled magic made on its own. Even the Kirin Tor can't say what it is.",
			strategy = {
				summary = "Two Mana Phantoms start the fight with it; kill them first. It keeps summoning small Manalings (cleave them down) and casts Manamorph on players.",
				tank = "Pick up the Phantoms and Manalings so the casters can burn them.",
				healer = "Stand well away from the boss so its Silence doesn't reach you, and dispel Manamorph.",
				dps = "Phantoms first, then cleave Manalings, then the boss.",
			},
			abilities = {
				{
					name = "Manamorph",
					alerts = { "magic", "healer" },
					text = "Takes a player out of the fight for 8 seconds. Dispel it.",
					spellID = 1240869,
				},
				{ name = "Silence", alerts = { "important" }, text = "Silences everyone close to the boss.", spellID = 1224125 },
				{ name = "Summon Manaling", alerts = { "dps" }, text = "Small arcane adds, all fight long.", spellID = 1304455 },
			},
			loot = {
				{ name = "Drape of Shifting Energy", slot = "Back" },
				{ name = "Violet Sorcerer's Robes", slot = "Cloth Chest" },
				{ name = "Wand of Mana Concentration", slot = "Wand" },
			},
		},
		{
			name = "Unstable Sentinel",
			overview = "A Kirin Tor guardian construct whose wards are failing.",
			lore = "Built to keep Dalaran safe, the Sentinel's enchantments have gone wrong, and it now lashes out at anything nearby.",
			strategy = {
				summary = "One mechanic: Malfunction winds up, then blasts everyone within 25 yards. Kill the Angry Tomes that fly out of the buildings before you pull.",
				tank = "You'll take Malfunction; use a cooldown if it hurts.",
				healer = "Stay at range and top up whoever was caught in Malfunction.",
				dps = "Ranged stay at max range. Melee step out when you see the wind-up.",
			},
			abilities = {
				{
					name = "Malfunction",
					alerts = { "important" },
					text = "After a short wind-up, heavy damage to everyone within 25 yards.",
					spellID = 1241329,
				},
			},
			loot = {
				{ name = "Guardian's Dualblade", slot = "Two-Hand Axe" },
				{ name = "Refractory Scaleguards", slot = "Mail Legs" },
				{ name = "Unstable Crystalline Shoulderpads", slot = "Leather Shoulder" },
				{ name = "Blueprint: Spinning Wheel", slot = "Campsite Recipe" },
			},
		},
		{
			name = "Mana Devourer",
			overview = "A magic-starved beast that drains your mana until you run dry.",
			lore = "Drawn by the magic pouring out of the city, it has made a nest by the Violet Hold and grown fat on it.",
			strategy = {
				summary = "A race against your mana bars. Debilitate hits the whole group and drains mana every time, so kill it quickly. Clear the trash around it first, or it joins the fight. It's immune to Arcane.",
				tank = "Drain Vitality hits you on impact and keeps ticking; save a cooldown for late in the fight.",
				healer = "Heal efficiently from the start. You'll be out of mana if the fight drags on.",
				dps = "Burn it fast; every extra Debilitate costs mana.",
			},
			abilities = {
				{ name = "Debilitate", alerts = { "healer" }, text = "Damages everyone within 45 yards and drains 200 mana.", spellID = 1240750 },
				{
					name = "Drain Vitality",
					alerts = { "tank", "magic" },
					text = "Arcane damage on its target, then more over 10 seconds.",
					spellID = 1240738,
				},
			},
			loot = {
				{ name = "Manascale Treads", slot = "Mail Feet" },
				{ name = "Slitherwrap Girdle", slot = "Leather Waist" },
				{ name = "Spine of the Devourer", slot = "Staff" },
			},
		},
		{
			name = "Fel Ancient",
			overview = "A great treant twisted by fel magic. You can fight it whenever you like.",
			lore = "An ancient that came too close to the Legion's corruption, now rooted in Dalaran and seeping fel into the ground.",
			strategy = {
				summary = "Entangle roots two players and hurts them over time, and Fel Timbers leaves green pools on the floor. Together they kill: someone rooted in a pool needs help fast.",
				tank = "Move the boss away from pools as they build up.",
				healer = "Watch rooted players, especially anyone stuck in green.",
				dps = "Never stand in green. Use Blessing of Freedom, Escape Artist or similar to break roots in a pool.",
			},
			abilities = {
				{ name = "Fel Timbers", alerts = { "important" }, text = "Leaves a green pool that hurts anyone standing in it.", spellID = 1240706 },
				{ name = "Entangle", alerts = { "magic", "healer" }, text = "Roots two players and damages them over time.", spellID = 22994 },
			},
			loot = {
				{ name = "Blightleaf Rope", slot = "Cloth Waist" },
				{ name = "Felbough Arm", slot = "Polearm" },
				{ name = "Garb of Fallen Felbark", slot = "Leather Chest" },
			},
		},
		{
			name = "Lyn the Ignored",
			optional = true,
			overview = "A hidden boss in the sewers, summoned rather than found.",
			lore = "Forgotten by everyone in the city above, Lyn has had a long time alone in the dark to grow bitter.",
			strategy = {
				summary = "Harder than he looks. Shadow Bolt Volley hits the whole group often, and Curse of Thorns makes his target's own attacks hurt them. He also raises skeletons like Atrexis.",
				tank = "Pick up the skeletons when they appear.",
				healer = "Remove Curse of Thorns quickly, especially from melee, and expect group damage from the volleys.",
				dps = "Melee (rogues most of all) suffer most from the curse; ask for a decurse.",
			},
			abilities = {
				{ name = "Shadow Bolt Volley", alerts = { "healer" }, text = "Shadow damage to the whole group.", spellID = 17228 },
				{ name = "Curse of Thorns", alerts = { "curse", "dps" }, text = "Your attacks can damage you. Remove it.", spellID = 1304473 },
				{ name = "Raise Dead", alerts = { "tank" }, text = "Summons two skeletons.", spellID = 1303266 },
			},
			loot = {
				{ name = "Bonepile Gaze", slot = "Shield" },
				{ name = "Cartilage Shapers", slot = "Leather Hands" },
				{ name = "Tendonscraper Dagger", slot = "Dagger" },
			},
		},
		{
			name = "Shade of the Archmage",
			overview = "The ghost of a Kirin Tor archmage, last guardian of the Violet Citadel.",
			lore = "Even in death, this archmage won't leave the Violet Citadel. To him, everyone who climbs its stairs is an invader.",
			strategy = {
				summary = "His spells run on mana. When he runs dry, he casts Mass Polymorph and Evocation to refill, and then the fight starts over. Spread out for Bounding Mana, an arcane boomerang thrown at one player that hurts everyone in its path.",
				tank = "Arcane Bolt is steady, heavy damage on you. Keep him in his room: if he leaves it, he resets.",
				healer = "Stay out of Arcane Explosion range (20 yards). You can hide behind the wall when he starts Mass Polymorph.",
				dps = "Casters stay at max range. Hiding behind the wall during Mass Polymorph keeps you casting.",
			},
			abilities = {
				{
					name = "Bounding Mana",
					alerts = { "important" },
					text = "An arcane boomerang thrown at one player; anyone in its path is hit. Spread out.",
					spellID = 1241515,
				},
				{ name = "Mass Polymorph", alerts = { "magic" }, text = "Polymorphs the group while he refills his mana.", spellID = 1303598 },
				{ name = "Evocation", alerts = { "important" }, text = "Restores all his mana. The cycle starts again.", spellID = 1303599 },
				{ name = "Arcane Explosion", alerts = { "dps", "healer" }, text = "Damages everyone within 20 yards.", spellID = 28450 },
				{ name = "Arcane Bolt", alerts = { "tank" }, text = "Steady, heavy arcane damage on the tank.", spellID = 15230 },
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
