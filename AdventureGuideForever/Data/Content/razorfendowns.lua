-- Razorfen Downs: hand-written guide text.
-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.

local _, AG = ...

AG:RegisterContent("razorfendowns", {
	intro = "The Scourge has taken the quilboar's sacred burial grounds.",
	bosses = {
		{
			name = "Tuten'kash",
			overview = "A giant spider summoned by ringing the gong.",
			abilities = {
				{ name = "Web Spray", alerts = { "healer" }, text = "Webs players in place." },
			},
		},
		{
			name = "Mordresh Fire Eye",
			overview = "A quilboar undead caster.",
			abilities = {
				{ name = "Fireball", alerts = { "interrupt" }, text = "Fire damage." },
			},
		},
		{
			name = "Glutton",
			overview = "A bloated undead quilboar.",
			abilities = {
				{ name = "Disease Cloud", alerts = { "disease", "healer" }, text = "Diseases everyone nearby." },
			},
		},
		{
			name = "Amnennar the Coldbringer",
			overview = "The lich who leads the Scourge here.",
			abilities = {
				{ name = "Frost Nova", alerts = { "tank" }, text = "Freezes everyone nearby." },
				{ name = "Amnennar's Wrath", alerts = { "healer" }, text = "Frost damage around him." },
				{ name = "Summon Frost Spectres", alerts = { "dps" }, text = "Summons ghosts at low health." },
			},
		},
		{ name = "Plaguemaw the Rotting", optional = true, overview = "A rare plague boar." },
		{ name = "Ragglesnout", optional = true, overview = "A rare quilboar necromancer." },
	},
})
