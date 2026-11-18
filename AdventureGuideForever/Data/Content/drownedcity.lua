-- The Drowned City: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("drownedcity", {
	intro = "The lost troll city of I'lalai lies beneath Stranglethorn's waves, overrun by Saltseer pirates and naga. Bring underwater breathing.",
	lore = "I'lalai was a troll city of legend, lost beneath the sea. Its last trolls still hold out there, alongside Saltseer pirates and Brinescale naga, and something in its depths is the source of the magic corrupting the Kurzen Compound. Now that adventurers have found the way down, they mean to put a stop to it.",
	route = "The entrance is underwater, west of Grom'gol Base Camp. Zul'Alai and Var'Taka come first; click the Glowing Pearl after Var'Taka to break the barrier. In the Deep Archives, a side passage through the water tunnels leads to the optional Primeval Elemental, past the rare Gill. Then Captain Dreadrise (another Pearl), Deathless Marrow, and Min'loth the Serpent at the end.",
	tips = {
		"Bring a warlock or shaman for water breathing: part of the dungeon is a long swim.",
		"Chasm Crawlers hit hard and Makrura Snappers stack Sunder Armor. Pull slowly and let the tank build threat.",
		"Risen Sentries charge and knock players back. Stack on them, kill the Profane Necros first (they summon spirits), and don't stand where a knockback throws you into another pack.",
		"The Glowing Pearls after Var'Taka and Dreadrise open the way forward.",
	},
	bosses = {
		{
			name = "Zul'Alai",
			overview = "The troll warlord at the gates, who refuses to die.",
			lore = "A troll champion of I'lalai, bound by an oath that keeps him fighting long after he should fall.",
			strategy = {
				summary = "Heavy damage on the tank. He stuns everyone near him with Monstrous Slam and slows them with Rotted Strike. At 30% his Undying Oath makes him attack faster and heal 3% every 5 seconds, so push hard at the end.",
				tank = "He stays still while casting Monstrous Slam, but you take the full hit. Save a cooldown for the 30% phase.",
				healer = "Dispel Rotted Strike from the tank first, then the others.",
				dps = "Melee: step out when he winds up Monstrous Slam. Burn him fast once he's below 30%.",
			},
			abilities = {
				{
					name = "Undying Oath",
					alerts = { "enrage", "important" },
					text = "Below 30%: 30% faster attacks, and he heals 3% every 5 seconds.",
					spellID = 1282511,
				},
				{
					name = "Monstrous Slam",
					alerts = { "dps" },
					text = "Stuns everyone near him for 3 seconds. He doesn't move, so step away.",
					spellID = 1282504,
				},
				{
					name = "Rotted Strike",
					alerts = { "healer", "tank" },
					text = "Slows movement and attack speed nearby. Dispel it.",
					spellID = 1282519,
				},
			},
		},
		{
			name = "Var'Taka",
			overview = "A naga warrior who harpoons stragglers, with two Brinescale Priestesses.",
			lore = "A Brinescale champion who hunts the drowned halls with a harpoon.",
			strategy = {
				summary = "Kill or crowd-control the two Priestesses first: they heal and throw Frostbolts. Var'Taka harpoons random players to him and cleaves in front. Watch the packs on both sides before you pull, and click the Glowing Pearl afterward.",
				tank = "Face him away from the group for the Cleave.",
				healer = "Harpooned players land next to him; heal them up.",
				dps = "Priestesses first. If you're harpooned, get out of the cleave.",
			},
			abilities = {
				{ name = "Harpoon", alerts = { "important" }, text = "Spears a random player and drags them to him.", spellID = 1282615 },
				{ name = "Cleave", alerts = { "tank", "dps" }, text = "Hits everyone in front of him.", spellID = 15284 },
			},
		},
		{
			name = "Primeval Elemental",
			optional = true,
			overview = "An optional water elemental hidden in the Deep Archives' flooded tunnels.",
			lore = "An ancient elemental the trolls kept sealed away and fed with offerings.",
			strategy = {
				summary = "From the Deep Archives, take the water tunnels on the right until you find the Undying Offerings. Kill the offerings to wake the elemental. An easy fight, but watch your breath and surface if you need to.",
				tank = "Waterbolt is his only single-target hit.",
				healer = "Freeze Water hits everyone.",
				dps = "Keep an eye on your breath bar.",
			},
			abilities = {
				{ name = "Freeze Water", alerts = { "healer" }, text = "Damages the whole group.", spellID = 1290983 },
				{ name = "Waterbolt", alerts = { "tank" }, text = "Water damage on the tank.", spellID = 1290978 },
			},
		},
		{
			name = "Captain Dreadrise",
			overview = "Captain of the Saltseer pirates who have moved into the troll city.",
			lore = "Dreadrise brought his Saltseer crew down to loot I'lalai, and liked it enough to stay.",
			strategy = {
				summary = "Clear the area completely so no patrol joins in. Embrine traps a random player (even the tank) in an Abyssal Bubble that drowns them; break the bubble fast. Interrupt Waterbolt Volley. Click the Glowing Pearl afterward.",
				tank = "If you're bubbled, the group needs to free you quickly. Get threat back after.",
				healer = "Interrupt or heal through Waterbolt Volley.",
				dps = "Swap to the bubble at once, then back to the captain.",
			},
			abilities = {
				{ name = "Embrine", alerts = { "deadly" }, text = "Traps a player in a drowning bubble. Destroy it.", spellID = 1282842 },
				{ name = "Waterbolt Volley", alerts = { "interrupt", "healer" }, text = "Damages the whole group. Interrupt it.", spellID = 1282860 },
			},
		},
		{
			name = "Deathless Marrow",
			overview = "A mass of undying bone that keeps raising guardians and sorcerers.",
			lore = "Bones of the city's dead, fused together by old troll magic and still raising its kin.",
			strategy = {
				summary = "A balance between adds and the boss. Deathless Guardians and Sorcerers keep coming until it dies, so don't get stuck on the adds: cleave them while you damage the boss. Bloodbolt hits everyone.",
				tank = "Grab the Guardians first: their Shield Slam stuns.",
				healer = "Steady group damage from Bloodbolt; save mana.",
				dps = "Cleave adds, focus the boss. Use fears and polymorph when adds pile up.",
			},
			abilities = {
				{ name = "Summon Adds", alerts = { "important" }, text = "More Guardians and Sorcerers all fight long." },
				{ name = "Bloodbolt", alerts = { "healer" }, text = "Damages the whole group.", spellID = 1283034 },
			},
		},
		{
			name = "Min'loth the Serpent",
			overview = "The last boss, a troll who rises again as a great serpent.",
			lore = "The power behind the drowned city, and the source of the corruption reaching Stranglethorn's shore.",
			strategy = {
				summary = "Two phases. First you fight his troll form: Drench hits the tank hard and Deluge is a channel that damages everyone. At 0% he becomes a serpent with full health and starts poisoning the whole group and fearing random players. The fight ends when the serpent reaches 0%.",
				tank = "Drench is big; use a cooldown when you see it coming.",
				healer = "Cure the Poison Bolt Volley poison quickly in phase two.",
				dps = "Pace yourself: the fight is really two full health bars.",
			},
			abilities = {
				{ name = "Deluge", alerts = { "healer" }, text = "Phase one: a channel that damages everyone.", spellID = 1283233 },
				{ name = "Drench", alerts = { "tank" }, text = "Phase one: heavy damage on the tank.", spellID = 1283250 },
				{ name = "Poison Bolt Volley", alerts = { "poison", "healer" }, text = "Phase two: poisons everyone. Cleanse it.", spellID = 1283313 },
				{ name = "Fear", alerts = { "important" }, text = "Phase two: fears a random player.", spellID = 1313471 },
			},
		},
		{
			name = "Umbra",
			optional = true,
			overview = "A rare that comes with five Saltscale murlocs.",
			lore = "A rare creature of the deep, surrounded by its murloc followers.",
			strategy = {
				summary = "No mechanics of its own, but the five murlocs all bleed their targets. Kill Umbra fast, then mop up the murlocs.",
				tank = "Hold everything together.",
				healer = "Bleeds add up quickly on whoever the murlocs hit.",
				dps = "Burn Umbra, then cleave.",
			},
			abilities = {
				{ name = "Bleed", alerts = { "healer" }, text = "The murlocs' bleeds stack up fast." },
			},
		},
		{
			name = "Gill",
			optional = true,
			overview = "A rare on the path to the Primeval Elemental.",
			lore = "A rare who has made the Deep Archives his own.",
			strategy = {
				summary = "Simple, as long as you don't pull him with the trash around him. He throws dynamite at the tank.",
				tank = "Pull him away from nearby packs.",
				dps = "Nothing special.",
			},
			abilities = {
				{ name = "Throw Dynamite", alerts = { "tank" }, text = "Explosive damage on the tank." },
			},
		},
		{
			name = "\"Pyromancer\" Braxton",
			overview = "A rare fire-happy rogue.",
			lore = "A self-styled pyromancer.",
			strategy = { summary = "He smashes heads. An easy rare." },
		},
	},
})
