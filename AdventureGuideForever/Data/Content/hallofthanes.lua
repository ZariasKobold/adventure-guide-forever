-- The Hall of Thanes: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("hallofthanes", {
	intro = "Beneath Ironforge lie the tombs of the dwarven thanes. Something has woken the dead, and a disgraced thane walks among them.",
	lore = "Below Ironforge's High Seat lie the tombs of the dwarven thanes, the honored dead of Khaz Modan. Now something has woken them. Restless spirits walk the halls, and a disgraced thane has come back to claim what he lost, with Dark Iron help.",
	route = "Enter beneath the High Seat, southwest of the Great Forge. Go left by the tunnel near Deliana and head down to the instance. Inside: Faldrim Anvilmar, Magmatus, the golem Plunder, and finally Durgen Dirgehammer at the Reliquary of Kings, flanked by two stone golems.",
	tips = {
		"Pick up the quests in Kharanos and near the entrance first.",
		"Horde can reach it, but it's a long, dangerous trip through Ironforge.",
		"Strategy here is early notes from each boss's abilities. Learning mode will fill in more.",
	},
	bosses = {
		{
			name = "Faldrim Anvilmar",
			overview = "A thane's restless spirit.",
			lore = "A dwarven thane who can't rest, bound to the halls by an ancient grudge.",
			strategy = {
				summary = "Early notes: he casts Mind Blast and curses his target with Anvilmar's Curse.",
				healer = "Remove the curse if you can.",
				dps = "Interrupt his Mind Blast.",
			},
		},
		{
			name = "Magmatus",
			overview = "A fire elemental loose in the tombs.",
			lore = "A living mass of magma that has crept up from the deep forges.",
			strategy = {
				summary = "Early notes: Fire Nova burns everyone close to him, and Combust adds extra fire damage.",
				healer = "Expect group-wide fire damage.",
				dps = "Ranged players can stand back from the nova.",
			},
		},
		{
			name = "Plunder",
			overview = "A golem that guards the treasure.",
			lore = "A treasure golem, built to guard the thanes' riches and now gone rogue.",
			strategy = {
				summary = "Early notes: he charges, knocks players away and weakens the tank's armor.",
				tank = "Crush Armor stacks on you; use cooldowns as it builds.",
				healer = "Watch for his charge on random players.",
			},
		},
		{
			name = "Durgen Dirgehammer",
			overview = "The disgraced thane, back for revenge.",
			lore = "A dwarven thane who was cast out in disgrace. Now he returns with Dark Iron allies to take what he believes is his.",
			strategy = {
				summary = "He fights with two Lesser Stone Golems. Expect Heroic Strike, a Rend bleed, and Intimidating Shout, which stuns one player and fears the rest.",
				tank = "Gather the golems with him.",
				healer = "Heal the Rend bleed, and be ready to fall back after his shout.",
				dps = "Kill the golems first, or crowd-control them.",
			},
		},
	},
})
