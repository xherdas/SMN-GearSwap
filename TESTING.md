# Test checklist (before each beta release)

Run through it once, end to end, after `//gs reload`. Tick a box only when the expected result is seen.
For anything that fails: note what you did, the red `[SMN]` lines or Lua errors in the chat and, for Conduit,
the last line of `SMN-USER/conduit-log.txt` (with the debug module: `SMN-USER/conduit-trace.txt`).

Feature freeze while this list is in progress: fixes only, no new features.

## 1. Loading
- [x] `//gs reload`: no Lua error, the HUD appears.
- [x] `//gs c help`: first line shows the version and the config file in use; keys and commands are listed.
- [x] Per-character config: with `SMN-USER/<Character>.lua` present, `gs c help` shows that file.
- [x] Zoning: the HUD hides during the loading screen and comes back after.
- [ ] Style lock (`SMN_LOCKSTYLE.set`): applied a few seconds after login / `//gs reload` / job change, even with a
      warp or a menu open right after loading; `gs c lockstyle` applies it again.

## 2. Keys and HUD
- [x] Every default key in the *Available actions* table (top of `user.lua`) does what it says.
- [x] Ctrl+PageDown hides / shows the keys in the HUD (and the "Resummon last avatar" line).
- [x] `gs c hub lite`: compact HUD, its own saved position, back to the normal HUD at its own position.
- [x] Dragging the HUD saves its position (still there after `//gs reload`).
- [x] Section titles stretch to the HUD width; the width doesn't change during a Ward rotation.

## 3. Idle sets
- [x] F9 / Alt+F9 cycle the quick Idle Modes forward / back; the idle set changes accordingly.
- [x] Avatar out vs no avatar: the matching `.Avatar` set is used.
- [x] Movement: Shneddick Ring while moving, back to the idle ring 0.5 s after stopping; not while engaged
      unless Kiting (Ctrl+F10) is on; always on in towns.
- [x] Western / Eastern Adoulin: Councilor's Garb.
- [x] Weapon Lock (Ctrl+F9) and `gs c opa`: weapons equipped and locked; turning either off frees them.

## 4. Treasure Hunter
- [x] F10 (Tag) then Dia on a mob: TH gear, `TH tagged: <mob>`; Dia again on it: normal gear, no message;
      Dia on another mob: TH gear again. Tag stays on until F10 again.
- [x] Alt+F10 (Persistent): TH gear on every offensive action and while engaged; off again with Alt+F10.

## 5. Blood Pact: Ward
- [x] Ward list: Alt+Home / Alt+End move the cursor, Alt+Insert checks, Alt+Delete clears.
- [x] Ctrl+End runs the checked wards: one summon per avatar, the previous avatar comes back at the end.
- [x] Ctrl+Home / Ctrl+Shift+Home: the ward under the cursor (with `stay`, its avatar stays out).
- [x] Timers count down; orange under `warn_at`; a buff from someone else shows grey; still yours after `//gs reload`.
- [x] Smart Buff (Ctrl+Delete): skips wards with more than 60 s left after the rotation (+25 s per ward cast),
      Hastega II first when it has 60 s or less; still active with more: as late as possible before it wears off.
- [x] Shared slot: with Wind's Blessing active, Shining Ruby's name is in Siren's color and Smart Buff skips it.
- [x] In combat (your avatar engaged): it keeps fighting until just before the Ward recast.
- [x] `/console gs c pact Spring Water` (any pact, with summon and return).

## 6. Blood Pact: Rage
- [x] `gs c rage 1..3` with each avatar you use; `gs c rage 4` (macro-only pact) where configured.
- [x] Conduit solo (Ctrl+F11): ~18 pacts under Conduit, 0 resend, `buff wore off` (or another clear end reason).
- [x] Conduit in a crowded zone (DI), Lag Mode off: 13-15 pacts, 0 resend; Convert gap ~3 s.
- [x] Conduit with Lag Mode (Alt+F11): completes without stopping.
- [x] Avatar dying during Conduit: resummoned, Assault, the loop resumes.
- [x] Mob dying during Conduit: `target defeated`.

## 7. Avatar
- [x] Avatar death: chat alert with the resummon key; Ctrl+PageUp resummons it.
- [x] `gs c siphon`: spirit of the weather / day, Elemental Siphon, the previous avatar comes back.
- [x] Low MP alert once below `mp_low`, again only after MP went back up.
- [x] Siphon hint: with Siphon ready and enough MP missing, `Siphon ● +<MP>` blinks gold; not during a
      sequence; steady gold (no blinking) while your avatar fights with Rage almost ready. The MP returned is
      close to the estimate.
- [ ] Atomos: when a mob gains a buff, `Dispel : <buff>` shows under the recasts (target it, most recent first); gone
      when the buff wears off / is dispelled / stolen. `Atomos ●` blinks gold when ready with a buffed target.
- [x] `gs c atomos`: Release, Atomos on the target, its two Blood Pacts, it leaves (no death alert), then the
      previous avatar comes back. F12 during Atomos: no resummon.

- [x] Refresh on yourself: Gishdubar Sash in midcast (showswaps); on someone else: Embla Sash.
- [ ] Refresh cast on you by another player: "Refresh on you (<name>): Refresh received gear.", Gishdubar Sash
      during their cast, then back to the idle set.

## 8. Skill-up
- [x] Ctrl+F12 (combat) and Alt+F12 (town) start; F12 stops; `gs c skill status` shows a summary.
- [x] Not enough MP while engaged: it stops with a message instead of looping.
- [ ] MP low enough for the Siphon estimate: Elemental Siphon (spirit, Siphon, Release) at the start of a cycle,
      before Convert / resting; `gs c skill status` counts the Siphons. Without any spirit learned: skipped.

## 9. Stopping
- [x] F12 stops any automation (Ward rotation, Conduit, skill-up, siphon); gear back to the idle set.
- [x] Zoning, KO, logout and `//gs reload` stop it too.
