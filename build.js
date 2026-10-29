// Builds the release folder data/ from the live files (run: node build.js, from this folder).
//   ../data/SMN-LIB/*.lua        -> data/SMN-LIB/
//   ../data/Thaylia_SMN.lua      -> data/SMN.lua          (generic header)
//   ../data/SMN-USER/user.lua    -> data/SMN-USER/user.lua (config part, personal values removed)
//   + template/sets-pergatory.lua   (Pergatory's sets, in user_sets())
// Personal files (positions, logs, Thaylia's user.lua) and SMN-LIB/smn-debug.lua are never copied.
const fs = require('fs');
const path = require('path');

const here = __dirname;
const live = path.join(here, '..', 'data');
const out = path.join(here, 'data');

function reset(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
}

reset(out);
fs.mkdirSync(path.join(out, 'SMN-LIB'));
fs.mkdirSync(path.join(out, 'SMN-USER'));

let n = 0;
for (const f of fs.readdirSync(path.join(live, 'SMN-LIB'))) {
  if (!f.endsWith('.lua') || f === 'smn-debug.lua') continue;   // debug tools: not in the release
  fs.copyFileSync(path.join(live, 'SMN-LIB', f), path.join(out, 'SMN-LIB', f));
  n++;
}

// Never ship temporary diagnostics (TEMP / [SMN diag] lines) left in the live code
for (const f of ['Thaylia_SMN.lua', ...fs.readdirSync(path.join(live, 'SMN-LIB')).filter(f => f.endsWith('.lua') && f !== 'smn-debug.lua').map(f => 'SMN-LIB/' + f)]) {
  if (/\[SMN diag\]|TEMP diagnostic/.test(fs.readFileSync(path.join(live, f), 'utf8')))
    throw new Error('temporary diagnostic left in ' + f + ': remove it before building');
}

const entry = fs.readFileSync(path.join(live, 'Thaylia_SMN.lua'), 'utf8')
  .replace('--  SMN (Thaylia) - entry point', '--  SMN - entry point (rename this file to <YourCharacter>_SMN.lua)');
fs.writeFileSync(path.join(out, 'SMN.lua'), entry);

// Template user.lua = the config part of the live user.lua (always up to date with new options), personal values
// neutralized, + Pergatory's sets (template/sets-pergatory.lua) in user_sets()
const liveUser = fs.readFileSync(path.join(live, 'SMN-USER', 'user.lua'), 'utf8');
const cut = liveUser.indexOf('function user_sets()');
if (cut < 0) throw new Error('function user_sets() not found in the live user.lua');
let config = liveUser.slice(0, cut)
  .replace('--  SMN - personal configuration', '--  SMN - configuration (copy to SMN-USER/<Character>.lua for a per-character config)')
  .replace(/SMN_MACROS = \{book = \d+, set = \d+\}/, 'SMN_MACROS = {book = nil, set = 1}   -- e.g. {book = 7, set = 1}')
  // Siphon skill: the player's own value (nil = skill without gear, read from the game)
  .replace(/^(\s*skill\s*=\s*)\d+,(\s*)/m, '$1nil,$2')
  // 'Move' idle mode: kept in the package for players with SMN_AUTO_MOVE = false (removed from the live list)
  .replace(/^(SMN_IDLE_MODES = \{[^}\n]*?)\}/m, (m, list) => list.includes("'Move'") ? m : list + ",'Move'}")
  // debug flags always off in the package (the debug module isn't shipped anyway)
  .replace(/^(\s*debug\s*=\s*)true(\s*,)/gm, '$1false$2');
for (const check of ['SMN_MACROS = {book = nil']) {
  if (!config.includes(check)) throw new Error('template: could not neutralize ' + check);
}
const sets = fs.readFileSync(path.join(here, 'template', 'sets-pergatory.lua'), 'utf8');
fs.writeFileSync(path.join(out, 'SMN-USER', 'user.lua'), config + 'function user_sets()\n' + sets + 'end\n');

const version = (fs.readFileSync(path.join(live, 'SMN-LIB', 'smn-data.lua'), 'utf8').match(/SMN_VERSION = '([^']+)'/) || [])[1];
console.log(`Built ${version || '?'}: ${n} SMN-LIB files, SMN.lua, SMN-USER/user.lua`);
