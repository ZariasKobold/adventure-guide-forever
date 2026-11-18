// Wowhead Forever guide extractor: the dungeon and raid overview guides
// (e.g. wowhead.com/forever/guide/ragefire-chasm-dungeon-overview-location-rewards).
// Produces tools/wowhead/guides.json, which tools/compare_guides.py reads.
//
// guides.json holds Wowhead's own guide text, so it is git-ignored and never committed.
// We use it as a fact source (levels, bosses, abilities, quests) and to check our guide
// against; anything players read is written in our own words, crediting Wowhead.
//
// How to run (in your own browser, on any wowhead.com page, e.g. wowhead.com/forever):
//   1. Open the developer console (F12, then the Console tab).
//   2. Paste this whole file and press Enter.
//   3. Run:   await whGuides()
//      It finds the guides through each dungeon's zone page, then reads one guide every
//      few seconds. Leave the tab open.
//   4. If it stops with "human verification", reload the page, complete Wowhead's check
//      as normal, then paste the file and run   await whGuides()   again. It remembers what
//      it already read and carries on from there.
//   5. When it prints "Done", run:   copy(whGuidesResult())
//      and paste the clipboard into tools/wowhead/guides.json (replace the whole file).
//
// whGuidesReset() forgets saved progress if you want to start over.

// Dungeon and raid zone pages (the same list as extract.js). Each lists its guides.
const ZONES = [
  209, 491, 616, 717, 718, 719, 721, 722, 796, 1176, 1337, 1417, 1477, 1581, 1583, 1584,
  2017, 2057, 2100, 2159, 2437, 2557, 16004, 16544, 16550, 16554, 16560, 16611, 16620,
  16667, 16732, 16842, 16919,
];

// Every instance's names, for guessing a guide's address when no zone page links it.
// Wowhead's slugs follow the title: "Scarlet Monastery: Library" ->
// scarlet-monastery-library-dungeon-overview-location-rewards.
const INSTANCES = [
  ['hallofthanes', 'The Hall of Thanes'], ['ragefire', 'Ragefire Chasm'],
  ['ruinslordaeron', 'Ruins of Lordaeron'], ['deadmines', 'The Deadmines'],
  ['wailing', 'Wailing Caverns'], ['shadowfang', 'Shadowfang Keep'],
  ['excavation', 'Excavation Site: Wetlands', 'Excavation Site'],
  ['blackfathom', 'Blackfathom Deeps'], ['stockade', 'The Stockade', 'Stormwind Stockade'],
  ['dalaran', 'City of Dalaran', 'Dalaran'], ['razorfenkraul', 'Razorfen Kraul'],
  ['gnomeregan', 'Gnomeregan'], ['smgraveyard', 'Scarlet Monastery: Graveyard'],
  ['smlibrary', 'Scarlet Monastery: Library'], ['drownedcity', 'The Drowned City'],
  ['smarmory', 'Scarlet Monastery: Armory'], ['razorfendowns', 'Razorfen Downs'],
  ['smcathedral', 'Scarlet Monastery: Cathedral'],
  ['kroldok', "Krol'dok Stronghold", 'Kroldok Stronghold'], ['uldaman', 'Uldaman'],
  ['zulfarrak', "Zul'Farrak"], ['alcaz', 'Alcaz Prison'], ['maraudon', 'Maraudon'],
  ['sunkentemple', "Temple of Atal'Hakkar", 'Sunken Temple'],
  ['brd', 'Blackrock Depths'], ['dmeast', 'Dire Maul: East', 'Dire Maul East', 'Warpwood Quarter'],
  ['blackmaw', 'Blackmaw Hold'], ['lbrs', 'Lower Blackrock Spire'],
  ['ubrs', 'Upper Blackrock Spire'], ['dmwest', 'Dire Maul: West', 'Dire Maul West', 'Capital Gardens'],
  ['scholomance', 'Scholomance'], ['shaperterrace', "Shaper's Terrace"],
  ['stratholme', 'Stratholme'], ['dmnorth', 'Dire Maul: North', 'Dire Maul North', 'Gordok Commons'],
  ['barrowdeeps', 'Barrow Deeps', 'raid'], ['hyjalsummit', 'Hyjal Summit', 'raid'],
  ['onyxia', "Onyxia's Lair", 'raid'],
];

// Overview pages that cover every dungeon or raid at once (level and location tables).
const HUBS = [
  'https://www.wowhead.com/forever/guide/dungeons-overview-locations-details',
  'https://www.wowhead.com/forever/guide/raids-overview-hub-dates-locations',
];

const PAUSE_MS = 12000;              // one page every 12 seconds; 8 tripped Wowhead's check after ~30 pages
const STORE_KEY = 'agfGuideProgress1'; // progress survives page reloads
const GATHERER_TYPES = { 1: 'npc', 3: 'item', 5: 'quest', 6: 'spell', 7: 'zone' };

function loadProgress() {
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || { zones: {}, guides: {} }; }
  catch (e) { return { zones: {}, guides: {} }; }
}

function saveProgress(p) {
  localStorage.setItem(STORE_KEY, JSON.stringify(p));
}

const pause = () => new Promise(r => setTimeout(r, PAUSE_MS));

function slugify(text) {
  return text.toLowerCase().replace(/['’]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

// Pulls the data array out of one `new Listview({ id: '<id>', ... data: [...] })` block.
function extractListview(html, id) {
  const marker = html.indexOf("id: '" + id + "'");
  if (marker < 0) return null;
  const re = /data:\s*\[/g;
  re.lastIndex = marker;
  const m = re.exec(html);
  const nextLv = html.indexOf('new Listview(', marker);
  if (!m || (nextLv > 0 && m.index > nextLv)) return null;
  const end = matchBracket(html, m.index + m[0].length - 1);
  return end > 0 ? parseLiteral(html.slice(m.index + m[0].length - 1, end + 1)) : null;
}

// Index of the bracket or brace that closes the one at `start`, skipping strings.
function matchBracket(text, start) {
  const open = text[start], close = open === '[' ? ']' : '}';
  let depth = 0, inStr = false, quote = '', esc = false;
  for (let j = start; j < text.length; j++) {
    const c = text[j];
    if (inStr) {
      if (esc) esc = false; else if (c === '\\') esc = true; else if (c === quote) inStr = false;
      continue;
    }
    if (c === '"' || c === "'") { inStr = true; quote = c; }
    else if (c === open) depth++;
    else if (c === close && --depth === 0) return j;
  }
  return -1;
}

// Wowhead writes most data as JSON, but some pages use JavaScript object notation
// (unquoted keys). Try JSON first; otherwise evaluate the literal, as the page itself does.
function parseLiteral(text) {
  try { return JSON.parse(text); } catch (e) { return Function('"use strict"; return (' + text + ');')(); }
}

async function get(path) {
  const res = await fetch(path);
  const html = await res.text();
  if (/<title>Human Verification/.test(html) || res.status === 403 || res.status === 429) return { blocked: true };
  return { status: res.status, html };
}

// The guide body: Wowhead markup passed to WH.markup.printHtml("...").
function guideMarkup(html) {
  const m = html.match(/WH\.markup\.printHtml\("((?:[^"\\]|\\.)*)"/);
  return m ? JSON.parse('"' + m[1] + '"') : null;
}

// Names (and quest levels) for every [npc=], [spell=], [quest=], [item=], [zone=] tag.
function gathererNames(html) {
  const names = {};
  const re = /WH\.Gatherer\.addData\((\d+),\s*\d+,\s*\{/g;
  let m;
  while ((m = re.exec(html))) {
    const kind = GATHERER_TYPES[m[1]];
    const start = m.index + m[0].length - 1;
    const end = matchBracket(html, start);
    if (!kind || end < 0) continue;
    let data;
    try { data = parseLiteral(html.slice(start, end + 1)); } catch (e) { continue; }
    names[kind] = names[kind] || {};
    for (const [id, rec] of Object.entries(data)) {
      const entry = { name: rec.name_enus || rec.name || '' };
      for (const k of ['level', 'reqlevel', 'side', 'quality']) if (rec[k] !== undefined) entry[k] = rec[k];
      names[kind][id] = entry;
    }
  }
  return names;
}

async function readGuide(url) {
  const page = await get(url.replace(/^https?:\/\/[^/]+/, ''));
  if (page.blocked) return page;
  if (page.status !== 200) return { missing: true, status: page.status };
  const markup = guideMarkup(page.html);
  if (!markup) return { missing: true, status: page.status, error: 'no guide markup on the page' };
  const title = (page.html.match(/<title>([^<]*)/) || [])[1] || '';
  const updated = (page.html.match(/"lastEdit":"([^"]+)"/) || page.html.match(/Updated:?\s*<[^>]*>\s*([0-9/]+)/) || [])[1] || null;
  return { title: title.replace(/ - Wowhead$/, ''), updated, markup, names: gathererNames(page.html) };
}

// Guide addresses to try for an instance no zone page linked.
function guesses(names, isRaid) {
  const kind = isRaid ? 'raid' : 'dungeon';
  const out = [];
  for (const name of names) {
    for (const n of [name, name.replace(/^The /, '')]) {
      out.push(`https://www.wowhead.com/forever/guide/${slugify(n)}-${kind}-overview-location-rewards`);
    }
  }
  return [...new Set(out)];
}

function coveredBy(guideUrls, names) {
  const slugs = names.map(n => slugify(n.replace(/^The /, '')));
  return guideUrls.some(u => slugs.some(s => u.includes('/guide/' + s) || u.includes('/guide/the-' + s)));
}

async function whGuides() {
  const p = loadProgress();

  // 1. Zone pages: which guides each dungeon links.
  const zonesTodo = ZONES.filter(id => !(id in p.zones));
  if (zonesTodo.length) console.log(`Adventure Guide: checking ${zonesTodo.length} zone pages for guides (about ${Math.ceil(zonesTodo.length * PAUSE_MS / 60000)} min).`);
  for (const id of zonesTodo) {
    const page = await get('/forever/zone=' + id);
    if (page.blocked) return stopped();
    let guides = [];
    try {
      guides = (extractListview(page.html, 'guides') || [])
        .filter(g => /dungeons|raids/.test(g.categoryPath || '') || /dungeon|raid/i.test(g.url || ''))
        .map(g => g.url);
    } catch (e) { console.warn(`Adventure Guide: couldn't read zone ${id}: ${e}`); }
    p.zones[id] = guides;
    saveProgress(p);
    await pause();
  }

  // 2. Every guide found, the hub pages, and guesses for instances no zone page linked.
  const found = [...new Set(Object.values(p.zones).flat())];
  const urls = [...HUBS, ...found];
  for (const [key, ...rest] of INSTANCES) {
    const isRaid = rest.includes('raid');
    const names = rest.filter(n => n !== 'raid');
    const known = Object.entries(p.guides).filter(([, g]) => !g.missing).map(([u]) => u);
    if (!coveredBy([...found, ...known], names)) urls.push(...guesses(names, isRaid));
  }

  // 3. Read each guide, stopping guesses for an instance once one works.
  const todo = [...new Set(urls)].filter(u => !(u in p.guides));
  console.log(`Adventure Guide: ${Object.keys(p.guides).length} guides read, ${todo.length} to try (about ${Math.ceil(todo.length * PAUSE_MS / 60000)} min).`);
  for (const url of todo) {
    const known = Object.entries(p.guides).filter(([, g]) => !g.missing).map(([u]) => u);
    const inst = INSTANCES.find(([, ...names]) => guesses(names.filter(n => n !== 'raid'), names.includes('raid')).includes(url));
    if (inst && coveredBy(known, inst.slice(1).filter(n => n !== 'raid'))) continue; // already found another way
    const result = await readGuide(url);
    if (result.blocked) return stopped();
    p.guides[url] = result;
    saveProgress(p);
    console.log(`Adventure Guide: ${result.missing ? 'no guide at' : 'read'} ${url.replace(/.*\/guide\//, '')}`);
    await pause();
  }

  const read = Object.values(p.guides).filter(g => !g.missing).length;
  console.log(`Adventure Guide: Done. ${read} guides read. Now run  copy(whGuidesResult())  and paste it into tools/wowhead/guides.json`);
}

function stopped() {
  console.warn('Adventure Guide: Wowhead asked for human verification. Reload the page, complete the check, then paste this script and run  await whGuides()  again. Progress is saved.');
}

function whGuidesResult() {
  const p = loadProgress();
  const guides = {};
  for (const [url, g] of Object.entries(p.guides)) if (!g.missing) guides[url] = g;
  return JSON.stringify({
    source: 'https://www.wowhead.com/forever guides (dungeon and raid overviews). Wowhead\'s text: local reference only, never commit.',
    fetched: new Date().toISOString().slice(0, 10),
    format: { guides: 'url -> { title, updated, markup (Wowhead markup), names: { npc|spell|quest|item|zone: { id: { name, level?, reqlevel?, side? } } } }' },
    guides,
  }, null, 1);
}

function whGuidesReset() {
  localStorage.removeItem(STORE_KEY);
  console.log('Adventure Guide: progress cleared.');
}
