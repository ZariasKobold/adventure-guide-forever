-- Ruins of Lordaeron: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("ruinslordaeron", {
	intro = "Scourge remnants still haunt the ruins of Lordaeron, right above the Forsaken capital.",
	lore = "The ruined capital above the Undercity never fully emptied of the Lich King's servants. Spiders, ghouls, abominations and a skeletal sorcerer still hold its streets, and the Forsaken want them gone from their doorstep for good.",
	route = "Start in the spider-filled King's Alley with Witherfang, then The Baron among the skeletal soldiers. In Lordamere Overlook, light the chimney fire in the southwest building to call Viktor the Vile. Entering Market Street wakes The Abandoned at the statue. Then Bjork, and finally Rath'mael.",
	tips = {
		"Spider packs patrol King's Alley; watch for patrols so you don't pull two packs at once.",
		"Shrieking Banshees silence casters. Stuns make the skeletal soldier packs much easier.",
		"Flesh Golems knock away and drop threat. Pull them carefully so you aren't thrown into another pack.",
		"Ghouls come in packs of three or four, close to other packs. Pull slowly.",
		"Alliance players: the grounds above Undercity flag you for PvP.",
	},
	bosses = {
		{
			name = "Witherfang",
			overview = "A plague-swollen spider that patrols King's Alley with two smaller spiders.",
			lore = "A spider grown huge on plague, nesting among the ruins.",
			strategy = {
				summary = "Kill the two spiders with it first, then tank and spank. Stuns help.",
				tank = "Leech Poison drains you; ask for a cure.",
				healer = "Cleanse Leech Poison off the tank.",
				dps = "Spiders first.",
			},
			abilities = {
				{ name = "Leech Poison", alerts = { "poison", "healer" }, text = "Drains the tank's health. Cure it.", spellID = 3358 },
			},
		},
		{
			name = "The Baron",
			overview = "A hard-hitting abomination with a knockout punch.",
			lore = "A stitched-together abomination left to guard the ruins.",
			strategy = {
				summary = "Knockout is everything: big instant damage that also drops threat. Stuns stop him from casting it.",
				tank = "Never fight him below full health; Knockout can kill you outright. Taunt back right after it.",
				healer = "Keep the tank topped off at all times.",
				dps = "Stun him when you can. Ease off right after a Knockout until the tank has him again.",
			},
			abilities = {
				{ name = "Knockout", alerts = { "tank", "deadly" }, text = "Heavy instant damage that also drops threat.", spellID = 17307 },
			},
		},
		{
			name = "Viktor the Vile",
			overview = "A Scourge servant you call out by lighting a chimney fire.",
			lore = "A servant of the Scourge who poisons his foes.",
			strategy = {
				summary = "Light the chimney fire in the southwest building of Lordamere Overlook, by the graveyard, then clear five waves of adds before Viktor shows up. He swings hard and poisons the tank.",
				tank = "Get firm threat before anyone attacks.",
				healer = "Cleanse Leech Poison off the tank.",
				dps = "Let the tank build threat first.",
			},
			abilities = {
				{ name = "Leech Poison", alerts = { "poison", "healer" }, text = "Drains the tank's health. Cure it.", spellID = 3358 },
			},
		},
		{
			name = "The Abandoned",
			overview = "A frost caster who appears at the Market Street statue.",
			lore = "A Scourge sorcerer left behind when the army moved on, still waiting for orders.",
			strategy = {
				summary = "Entering Market Street at the statue starts three waves of adds, then The Abandoned. He freezes players in place and chills anyone who hits him in melee.",
				tank = "He drains your life; keep him busy and away from casters.",
				healer = "Watch players frozen by Frost Nova.",
				dps = "Melee attacks get chilled; ranged have it easier.",
			},
			abilities = {
				{ name = "Frost Nova", alerts = { "magic" }, text = "Freezes nearby players in place.", spellID = 1220855 },
				{ name = "Life Drain", alerts = { "tank", "healer" }, text = "Drains the tank's health.", spellID = 1266011 },
			},
		},
		{
			name = "Bjork",
			overview = "A hulking undead brute who briefly shields himself from magic.",
			lore = "A huge undead warrior still guarding what's left of the city.",
			strategy = {
				summary = "A quick tank-and-spank. His only trick is a very short Anti-Magic Shield.",
				tank = "Nothing special; hold him still.",
				healer = "An easy fight.",
				dps = "Casters: pause for a moment while the shield is up.",
			},
			abilities = {
				{ name = "Anti-Magic Shield", alerts = { "dps" }, text = "Blocks spells for a few seconds.", spellID = 1301635 },
			},
		},
		{
			name = "Rath'mael",
			overview = "The skeletal sorcerer at the end of the Ruins.",
			lore = "A skeletal mage of the Scourge, in command of the ruins' restless dead.",
			strategy = {
				summary = "One ability: Flamestrike, always aimed where the tank stood when he started casting. Stuns stop the cast entirely.",
				tank = "Step out of the fire as soon as he starts channeling; he'll follow you.",
				healer = "Stand away from the tank so the fire doesn't catch you.",
				dps = "Stun him to stop Flamestrike.",
			},
			abilities = {
				{
					name = "Flamestrike",
					alerts = { "important", "interrupt" },
					text = "Fire on the ground where the tank was standing. Move out.",
					spellID = 1279983,
				},
			},
		},
		{
			name = "Lordaeron Captain",
			optional = true,
			overview = "A rare spirit that may appear in the Ruins.",
			lore = "A rare ghost of a captain who died defending the city.",
			strategy = { summary = "A rare fight. Kill him for his loot." },
			loot = {
				{ name = "Haunting Blade", slot = "Two-Hand Sword" },
				{ name = "Phantom Armor", slot = "Plate Chest" },
			},
		},
	},
})
