# Bundled art

Loading-screen art for Forever-new instances, which have no art under Blizzard's journal
file names. The artwork is Blizzard's, from World of Warcraft: Forever. Each file is
converted from the published screenshot: letterbox bars trimmed, then stretched to a
1024x512 RLE TGA (WoW textures must be power-of-two). `UI.SetArt` undoes the stretch.

| File | Source |
|---|---|
| `hallofthanes.tga` | wowforeverguides.com (client art) |
| `excavation.tga`, `drownedcity.tga`, `kroldok.tga`, `alcaz.tga`, `blackmaw.tga`, `shaperterrace.tga` | wowforevertalents.com (instance art) |

Fetched 2026-11-17. If Blizzard's own file IDs for these turn up (`/agprobe art`), prefer
those in `Data/Art.lua` and delete the bundled copy.
