-- Alcaz Prison: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("alcaz", {
	intro = "A secret prison on Alcaz Island. The Alliance hopes King Varian is inside, the Horde wants its Kor'kron back, and the naga want everyone gone.",
	lore = "Traitors in Theramore have been working with the Defias Brotherhood, and their hidden prison on Alcaz Island may hold the missing King Varian Wrynn. Alliance adventurers come for their king, Horde adventurers for their captured Kor'kron guards, and the Strashaz naga of the island resent every one of them.",
	route = "Tidemistress Ca'zass waits near the entrance with her enchantresses. Sneak past Overseer Wrex's patrol to clear his three cell blocks, then fight him. Katerina the Cleaner holds the next wing, and Zarla Ober, really the dragon Blazeroar, waits at the end. Leave The Questioner for last: clear the rest of the prison before you kill him.",
	tips = {
		"Don't kill The Questioner until everything else is cleared.",
		"Strashaz Soldiers charge anyone 8 or more yards away. Stack behind them. Interrupt the Enchantresses' Polymorph and Frostbolt Volley.",
		"Alcaz Chaplains heal. Kill them first, and polymorph extras.",
		"Alcaz Jailers cleave: tanks face them away.",
		"Kill Renegade Conjurers and their Arcane Servitors before they pile on spells.",
	},
	bosses = {
		{
			name = "The Questioner",
			overview = "The prison's interrogator. Kill him last.",
			lore = "The Defias interrogator who decides which prisoners talk, and which don't come back.",
			strategy = {
				summary = "Clear the rest of the dungeon before you kill him. The fight itself is easy: pull some of the adds in his chamber first. He has a Rend and a Drain Life.",
				tank = "Rend bleeds you; it's light.",
				healer = "Paladins and priests can dispel his Drain Life.",
				dps = "Pull a few adds early to make it easier.",
			},
			abilities = {
				{ name = "Drain Life", alerts = { "magic" }, text = "Drains a player's health. Dispel it.", spellID = 17620 },
				{ name = "Rend", alerts = { "tank" }, text = "A bleed on the tank.", spellID = 12054 },
			},
		},
		{
			name = "Tidemistress Ca'zass",
			overview = "A naga sea witch with two Strashaz Enchantresses.",
			lore = "The Strashaz naga's sorceress, furious at the humans who built a prison on her island.",
			strategy = {
				summary = "Kill or crowd-control the Enchantresses first. Frostbolt Volley hits everyone, Frost Nova roots players, and she drops Blizzard on herself. Drag her out of each Blizzard.",
				tank = "Move her out of her own Blizzard every time.",
				healer = "Paladins and priests: dispel Frost Nova so nobody is stuck in a Blizzard.",
				dps = "Adds first, then the boss. Interrupt the Volley if you can.",
			},
			abilities = {
				{ name = "Blizzard", alerts = { "important" }, text = "Ice storm on the ground around her. Move out.", spellID = 1271375 },
				{ name = "Frost Nova", alerts = { "magic", "healer" }, text = "Roots players in place. Dispel it.", spellID = 15532 },
				{ name = "Frostbolt Volley", alerts = { "interrupt", "healer" }, text = "Frost damage to the whole group.", spellID = 8398 },
			},
		},
		{
			name = "Overseer Wrex",
			overview = "The warden who patrols three cell blocks and calls them all to help.",
			lore = "The prison's overseer, who runs his wing with a heavy hand.",
			strategy = {
				summary = "If he spots you, every add in the three nearby cell blocks joins him. Sneak past his patrol and clear all three blocks before you pull. After that it's simple: one big Mortal Strike and a Battle Shout.",
				tank = "Mortal Strike hits hard and halves healing on you for 5 seconds.",
				healer = "Top the tank up between Mortal Strikes.",
				dps = "Nothing special once the cells are cleared.",
			},
			abilities = {
				{
					name = "Mortal Strike",
					alerts = { "tank", "healer" },
					text = "A heavy hit that halves healing on the tank for 5 seconds.",
					spellID = 16856,
				},
				{ name = "Battle Shout", alerts = { "tank" }, text = "Boosts the attack power of him and his allies.", spellID = 9128 },
			},
		},
		{
			name = "Katerina the Cleaner",
			overview = "A Defias assassin with two Alcaz Chaplains.",
			lore = "The Defias send Katerina when someone needs to disappear.",
			strategy = {
				summary = "Crowd-control the two Chaplains (Polymorph, Sap, Fear) or kill them first so they can't heal. Grievous Garrote hits a random player hard and keeps draining them until they're healed above 90%. Deadly Poison goes on the tank.",
				tank = "Get Deadly Poison cleansed quickly.",
				healer = "Heal Garrote targets above 90% to stop the bleed, and cure the tank's poison.",
				dps = "Chaplains first.",
			},
			abilities = {
				{
					name = "Grievous Garrote",
					alerts = { "healer", "important" },
					text = "Big damage on a random player, then more until they're healed above 90%.",
					spellID = 1271761,
				},
				{ name = "Deadly Poison", alerts = { "poison", "tank" }, text = "Poison on the tank. Cure it.", spellID = 3583 },
			},
		},
		{
			name = "Blazeroar",
			overview = "Zarla Ober, who is really the dragon Blazeroar. The last boss.",
			lore = "The prison's mistress wears a human face, but she is a dragon, and the true power behind Alcaz.",
			strategy = {
				summary = "Two phases. As Zarla she casts Fireball and Flamestrike, and keeps casting while you stand in the fire. At 30% she casts Reveal Form, becomes Blazeroar and heals to full. The dragon's Searing Scales burn the group all phase, Flame Breath and Thrash hit the tank hard, and she fears everyone but the tank.",
				tank = "Phase two is the danger: save a cooldown, a Major Healing Potion or a healthstone for when the group is feared. Shamans: drop a Tremor Totem.",
				healer = "Constant group damage from Searing Scales; keep the tank up through Flame Breath.",
				dps = "Get out of Flamestrike in phase one. Melee may have to take some of it.",
			},
			abilities = {
				{ name = "Flamestrike", alerts = { "important" }, text = "Phase one: fire on the ground. Move out.", spellID = 18399 },
				{ name = "Fireball", alerts = { "interrupt" }, text = "Phase one: fire damage on a target.", spellID = 12466 },
				{ name = "Reveal Form", alerts = { "important" }, text = "At 30%: becomes Blazeroar and heals to full.", spellID = 1275847 },
				{ name = "Flame Breath", alerts = { "tank", "deadly" }, text = "Phase two: very heavy fire damage on the tank.", spellID = 9573 },
				{ name = "Searing Scales", alerts = { "healer" }, text = "Phase two: constant fire damage to the group.", spellID = 1271604 },
				{ name = "Thrash", alerts = { "tank" }, text = "Phase two: several attacks at once.", spellID = 3391 },
				{ name = "Fear", alerts = { "important" }, text = "Phase two: fears everyone but the tank.", spellID = 1271593 },
			},
		},
	},
})
