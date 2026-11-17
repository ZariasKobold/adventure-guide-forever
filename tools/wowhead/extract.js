// Wowhead Forever extractor. Produces tools/wowhead/snapshot.json.
//
// How to run: open https://www.wowhead.com/forever/zones/dungeons in a normal browser,
// paste this file into the developer console, then run:
//
//     copy(await whExtract())        // copies the snapshot JSON to the clipboard
//
// and save the clipboard as tools/wowhead/snapshot.json. Then run tools/build_wowhead.py.
//
// Be polite: it fetches one zone page at a time with a pause between requests, and it
// stops at once if Wowhead shows its human-verification page. Never automate past that.

const ZONES = [
  209, 491, 616, 717, 718, 719, 721, 722, 796, 1176, 1337, 1417, 1477, 1581, 1583, 1584,
  2017, 2057, 2100, 2159, 2437, 2557, 16004, 16544, 16550, 16554, 16560, 16611, 16620,
  16667, 16732, 16842, 16919,
];
const PAUSE_MS = 1500;

// Pulls the data array out of one `new Listview({ id: '<id>', ... data: [...] })` block.
function extractListview(html, id) {
  const marker = html.indexOf("id: '" + id + "'");
  if (marker < 0) return null;
  const re = /data:\s*\[/g;
  re.lastIndex = marker;
  const m = re.exec(html);
  const nextLv = html.indexOf('new Listview(', marker);
  if (!m || (nextLv > 0 && m.index > nextLv)) return null;
  const start = m.index + m[0].length - 1;
  let depth = 0, inStr = false, quote = '', esc = false;
  for (let j = start; j < html.length; j++) {
    const c = html[j];
    if (inStr) {
      if (esc) esc = false; else if (c === '\\') esc = true; else if (c === quote) inStr = false;
      continue;
    }
    if (c === '"' || c === "'") { inStr = true; quote = c; }
    else if (c === '[') depth++;
    else if (c === ']' && --depth === 0) return parseLiteral(html.slice(start, j + 1));
  }
  return null;
}

// Wowhead writes most listview data as JSON, but some pages use JavaScript object
// notation (unquoted keys). Try JSON first; otherwise evaluate the array literal, the same
// way the page itself does when it renders.
function parseLiteral(text) {
  try { return JSON.parse(text); } catch (e) { return Function('"use strict"; return (' + text + ');')(); }
}

async function fetchZone(zoneID) {
  const res = await fetch('/forever/zone=' + zoneID);
  const html = await res.text();
  if (res.status !== 200 || /<title>Human Verification/.test(html)) {
    throw new Error('Wowhead asked for human verification at zone ' + zoneID + '. Stopping.');
  }
  const title = ((html.match(/<title>([^<]*)<\/title>/) || [])[1] || '').replace(/ - Zone - WoW Forever$/, '');
  const drops = [], names = {};
  for (const x of extractListview(html, 'drops') || []) {
    const s = (x.sourcemore || [])[0] || {};
    if (s.t !== 1 || x.quality < 2) continue; // NPC drops, uncommon and better
    drops.push([x.id, x.name, x.quality, x.slot, x.classs, x.subclass, x.reqlevel || 0, s.ti]);
    names[s.ti] = s.n;
  }
  return { title, drops, names };
}

async function whExtract() {
  const zones = {}, npcNames = {};
  for (const id of ZONES) {
    const z = await fetchZone(id);
    zones[id] = { title: z.title, drops: z.drops };
    Object.assign(npcNames, z.names);
    await new Promise(r => setTimeout(r, PAUSE_MS));
  }
  return JSON.stringify({
    source: "https://www.wowhead.com/forever (zone pages, 'drops' listview)",
    fetched: new Date().toISOString().slice(0, 10),
    format: {
      drop: ['itemID', 'name', 'quality', 'inventoryType', 'itemClass', 'itemSubclass', 'requiredLevel', 'sourceNpcID'],
      npcNames: 'npcID -> name, for drop sources',
    },
    zones, npcNames,
  }, null, 1);
}
