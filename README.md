# SMN GearSwap (beta)

A Summoner GearSwap for Windower 4, built on **Pergatory's** SMN GearSwap, with an on-screen HUD and
automation for Blood Pact: Ward rotations, Rages by macro, the Astral Conduit sequence, summoning skill-up,
Treasure Hunter tagging and live lag adjustment.

> **Beta version (0.9.0-beta).** Please report issues (see *Reporting a problem* below).

---

## ⚠ Before you use it

- **Automation.** Ward rotations, the Conduit sequence, skill-up and Auto Favor send game commands for you.
  Any automation, like Windower itself, is against Square Enix's Terms of Service. Use at your own risk.
- **No packets.** This file never sends or injects game packets. Everything goes through normal commands
  (`/pet`, `/ja`, `/ma`, `/item`), GearSwap's own hooks, chat text, Windower memory reads, and Windower's
  `action` events read only (enemy buffs for Atomos, Refresh cast on you).

---

## Installation

1. Copy the contents of `data/` into `Windower/addons/GearSwap/data/`:
   - `SMN.lua`
   - `SMN-LIB/` (the logic: don't put gear in it)
   - `SMN-USER/` (your configuration and sets)
2. Rename `SMN.lua` to `<YourCharacter>_SMN.lua` (e.g. `Thaylia_SMN.lua`).
3. Open `SMN-USER/user.lua` and replace the example gear (Pergatory's sets) with yours.
   Pieces you don't own are simply ignored by GearSwap; `//gs validate` lists them.
4. In game: `//gs reload` (or change job to SMN). `//gs c help` lists the keys and commands.

**Several SMN characters on one install:** copy `SMN-USER/user.lua` to `SMN-USER/<Character>.lua`.
That file is used for that character, `user.lua` for the others.

Requires the standard GearSwap libraries (`Modes.lua` from Mote's libs, shipped with GearSwap).

---

## Default keys

`^` = Ctrl, `!` = Alt, `~` = Shift. Change or remove any key in `SMN_KEYBINDS` (top of `user.lua`).

| Key | Action |
|---|---|
| F9 / Alt+F9 | Idle Mode: quick cycle (`SMN_IDLE_QUICK`) forward / back |
| Ctrl+F9 | Weapon Lock |
| F10 | Treasure Hunter **Tag** on / off (your first spell / JA / WS on each mob gets TH gear) |
| Alt+F10 | Treasure Hunter **Persistent** on / off |
| Ctrl+F10 | Kiting (movement gear also while engaged) |
| Ctrl+F11 | **Conduit sequence** |
| Alt+F11 | Lag Mode (crowded zones) |
| F12 | **Stop** all automation |
| Ctrl+F12 / Alt+F12 | Skill-up in combat / in town |
| Alt+Home / Alt+End | Ward list: cursor up / down |
| Alt+Insert / Alt+Delete | Ward list: check / clear |
| Ctrl+End | Run the checked wards |
| Ctrl+Home | Run the ward under the cursor |
| Ctrl+Shift+Home | Same, then keep that avatar out |
| Ctrl+Insert / Ctrl+Delete | Auto Favor / Smart Buff |
| Ctrl+PageUp | Resummon the last avatar |
| Ctrl+PageDown | Show / hide the keys in the HUD |

---

## Main features

### HUD
Avatar (HP, TP, MP, Favor, live lag estimate), recasts, Rages of the avatar out, the Ward list,
skill-up status, modes and options. Drag it with the mouse (position saved). `gs c hub lite` gives a
compact one-line version with its own position. Sections can be hidden: `gs c hub avatar | recasts |
rage | wards | auto | modes | options | all | keybinds | lite`.

### Blood Pact: Ward
- Check wards in the HUD list, then **Run**: avatars are summoned in turn, every checked ward is cast,
  and your previous avatar comes back at the end (`stay` keeps the last ward's avatar out).
- **Smart Buff**: skips wards that will still have more than `smart_threshold` seconds left when the
  rotation ends (`smart_ward_time` per ward cast); casts `smart_priority`
  first (Hastega II), then the longest buffs first, so short ones are fresh when the fight starts.
- In combat, your fighting avatar keeps fighting until just before the Ward recast.
- `gs c pact <name> [<target>] [stay]`: any Blood Pact from a macro, summoning if needed.

### Blood Pact: Rage
- `gs c rage 1 | 2 | 3 | 4`: Rage n of the avatar out (`SMN_RAGE.pacts`). The HUD shows the first 3;
  a 4th is for macros only (it may be a Ward on `<t>`, e.g. Mewing Lullaby).
- **Conduit sequence** (Ctrl+F11): Astral Flow, Apogee, Rage ×2, Astral Conduit, then Rage #1 on a loop
  while the buff lasts. MP via Convert (/RDM) then items. If the avatar dies, it is resummoned and the
  loop resumes. One line per sequence in `SMN-USER/conduit-log.txt`.

### Lag
Every Blood Pact is timed (command → avatar starts it). The estimate (HUD: "Lag 0.90 s") adjusts the
Conduit loop before and during the sequence: the wait before resending a pact follows the lag, a refused
pact ("Unable to use job ability") is resent quickly, and a refused or dropped pact adds a little delay
between the next ones. Reset on zone change. Tune it in `SMN_AUTO.lag`.
Lag Mode (Alt+F11) switches the Conduit loop to a safer timing (`SMN_RAGE.conduit.lag`).

### Elemental Siphon and Atomos
- `gs c siphon`: summons the spirit of the weather / day (learned spirits only), Elemental Siphon, then
  your previous avatar comes back. HUD hint: `Siphon ● +<MP>` (estimated return) blinks gold when it's a
  good time, steady gold while your avatar fights with a Rage almost ready (`SMN_SIPHON`).
- `gs c atomos`: Release, Atomos on your target (its two Blood Pacts steal a buff for the party), then
  your previous avatar comes back. The HUD `Dispel :` line lists the buffs seen on your target, most
  recent first; `Atomos ●` turns gold when it's ready and the target has one (`SMN_ATOMOS`).

### Skill-up
Summoning skill-up in combat (Ctrl+F12) or in town (Alt+F12), from the smnSkill addon. MP between cycles:
Elemental Siphon, Convert, Siphon again, then resting (Siphon is skipped without any spirit learned).
`gs c skill status` shows a summary.

### Other
Resummon and avatar death alert, low MP alert, Refresh (Gishdubar Sash only on yourself; a Refresh
received set while another player casts Refresh on you), Treasure Hunter (Tag / Persistent), movement
gear while moving (always in towns), Councilor's Garb in Adoulin, optional Town set (equipped over your
idle set).

---

## Configuration

Everything you may want to change is in `SMN-USER/user.lua`, commented:
keys, macro book, HUD, Idle Modes, default values, merits, automation timings, alerts, Ward list,
Rage lists, Conduit, skill-up, then your sets in `user_sets()`.
Idle sets follow `sets.aftercast.{IdleMode}.{PetName|Spirit|Avatar}.{Status}.{LowMP}.{ForceIlvl}.{CustomMode}`.

---

## Known issues and testing

- [KNOWN-ISSUES.md](KNOWN-ISSUES.md): accepted limits of this beta (please check it before reporting).
- [TESTING.md](TESTING.md): the test checklist used before each release.

---

## Reporting a problem

Please include:
1. what you did and what happened (chat messages, especially red `[SMN]` lines or Lua errors);
2. `//gs c help` first line (version and config file);
3. for the Conduit sequence: the last lines of `SMN-USER/conduit-log.txt` (one line per sequence: pacts,
   average interval, resends, refusals, lag). A detailed trace module (`smn-debug.lua`) is not part of the
   package; ask for it if a problem needs a closer look.

---

## Credits

- **Pergatory** — the SMN GearSwap this is built on: sets, set-selection logic and GearSwap hooks.
  <http://pastebin.com/u/pergatory>
- **PUP GearSwap** (PUP.lua / PUP-LIB / PUP-USER) — most of the HUD, the logic / config split and the keybind
  system come from it. Originally created by **Faloun**; programmers **Arrchie, Kuroganashi, Byrne, Tuna**;
  contributors **Xilkk, Byrne, Blackhalo714**.
- **Mote** — `Modes.lua`.
- **Papesse (Carbuncle)** — Avatar's Favor skill tier advice.
- **Thaylia** — smnSkill, automation engine, Ward / Rage / Conduit / Treasure Hunter / lag modules, HUD.

---

## License

MIT for Xherdas' own code ([LICENSE](LICENSE)). The parts based on Pergatory's SMN GearSwap and the PUP
GearSwap were published without a license; credit goes to their authors (see above).
