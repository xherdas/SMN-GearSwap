# Changelog

## 0.9.0-beta — first beta for testers

First version shared outside its author. Built on Pergatory's SMN GearSwap.

- HUD: avatar, recasts, Rage list, Ward list, skill-up, modes and options; compact mode; saved positions.
- Blood Pact: Ward rotations (Run, this ward, `stay`), Smart Buff (threshold, priority, longest first),
  combat mode, `gs c pact`.
- Blood Pact: Rage by number (`gs c rage 1..4`), Conduit sequence with MP recovery, resummon on death,
  log file.
- Live lag estimate and Conduit timing adjustment; Lag Mode.
- Summoning skill-up (from the smnSkill addon). MP between cycles: Elemental Siphon, Convert, Siphon again,
  then resting; Siphon uses learned spirits only and is skipped without any.
- Elemental Siphon (`gs c siphon`): HUD hint with MP estimate; blinks gold when it's a good time, steady gold
  while your avatar fights with Rage almost ready.
- Atomos (`gs c atomos`): Release, Atomos on the target, then the previous avatar comes back. HUD Dispel line
  with the target's buffs (most recent first) and an Atomos hint.
- Resummon last avatar, avatar death and low MP alerts.
- Refresh: Gishdubar Sash only on yourself (`.Self` midcast variant), Refresh received set when another
  player casts Refresh on you.
- Treasure Hunter Tag / Persistent; movement gear; Adoulin body; optional Town overlay set.
- Configurable keys, per-character config file (`SMN-USER/<Character>.lua`), macro book and style lock on load
  (sent once the game is ready, `gs c lockstyle`).

Not yet verified in game (feedback welcome): the Atomos Dispel line and hint, the Refresh received set, and
Elemental Siphon during skill-up.
