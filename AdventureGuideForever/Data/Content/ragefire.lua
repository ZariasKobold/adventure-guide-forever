-- Ragefire Chasm: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ragefire", {
	intro = "Beneath Orgrimmar, the Searing Blade cult and its troggs plot in tunnels of molten rock.",
	lore = "Beneath Orgrimmar runs a network of volcanic caverns the orcs call Ragefire Chasm. The Burning Blade, a cult of demon worshippers, has taken root there with the troglodytes who already called the tunnels home. Their goal is to weaken the Horde from inside its own capital, and Thrall's people would rather the matter be settled quietly by adventurers than by an army in the streets.",
	route = "The chasm is one winding loop. Clear the troggs at the entrance to reach Oggleflint, then follow the lava river down to Taragaman. Jergosh waits in the cultists' chamber further on, and Bazzalan holds the deepest room at the end of the path.",
	tips = {
		"It's a short run: a full clear rarely takes more than half an hour.",
		"Cultist casters hit hard at this level. Interrupt or crowd-control them first.",
		"Most Horde quests for the chasm start in Orgrimmar itself, so pick them up before you zone in.",
	},
	bosses = {
		{
			name = "Oggleflint",
			overview = "The trogg chieftain leads the first pack you meet.",
			lore = "Oggleflint leads the chasm's troggs, a brutish chieftain who has thrown in his lot with the Burning Blade.",
			strategy = {
				summary = "A straightforward melee fight. Pull him away from the trogg packs nearby so they don't join in.",
				tank = "Face him away from the group so his cleave only hits you.",
				dps = "Stay behind him.",
			},
			abilities = {
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him." },
			},
		},
		{
			name = "Taragaman the Hungerer",
			overview = "A huge demon who feeds on the fires of the chasm.",
			lore = "A demon called up by the Burning Blade, Taragaman feeds on the chasm's fires and on anything foolish enough to come near.",
			strategy = {
				summary = "His Fire Nova burns everyone close by, and his Uppercut knocks the tank around.",
				tank = "Expect to be knocked back. Step back in quickly so he doesn't wander toward the healer.",
				healer = "Keep the whole group topped up through the fire pulses.",
				dps = "Ranged damage dealers can stay out of the nova range.",
			},
			abilities = {
				{ name = "Fire Nova", alerts = { "healer" }, text = "Burns everyone nearby with fire." },
				{ name = "Uppercut", alerts = { "tank" }, text = "Knocks the tank back." },
			},
		},
		{
			name = "Jergosh the Invoker",
			overview = "A Searing Blade warlock who channels shadow curses.",
			lore = "A Burning Blade warlock who gives the cult its dark magic.",
			strategy = {
				summary = "A caster who curses and burns his targets.",
				healer = "Remove his curse from the tank if you can, and heal through the burning damage.",
				dps = "Interrupt his casts when they come up.",
			},
			abilities = {
				{ name = "Curse of Weakness", alerts = { "curse", "tank" }, text = "Lowers the tank's damage." },
				{ name = "Immolate", alerts = { "magic", "healer" }, text = "Burns a target over time." },
			},
		},
		{
			name = "Bazzalan",
			overview = "The satyr leader of the Searing Blade.",
			lore = "The satyr who leads the Burning Blade in Ragefire, and the real power behind the cult beneath Orgrimmar.",
			strategy = {
				summary = "A quick, poisonous melee fighter. Kill him and the cult in the chasm is broken.",
				tank = "His strikes come fast, so keep your defensive cooldowns ready.",
				healer = "Cure the poison on the tank if you can.",
			},
			abilities = {
				{ name = "Poison", alerts = { "poison", "healer" }, text = "Poisons the tank for nature damage over time." },
				{ name = "Sinister Strike", alerts = { "tank" }, text = "A quick, hard strike." },
				{ name = "Deadly Poison", alerts = { "poison", "tank" }, text = "Poisons his target. Cure it.", spellID = 2818 },
			},
		},
	},
})
