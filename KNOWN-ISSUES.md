# Known issues and limits

Accepted behaviors of this beta. They are not bugs to report again (unless they get worse).

## Ward timers
- **A buff from someone else counts as active for Smart Buff** (Haste from a WHM / RDM for Hastega II). Haste I
  (15 %) is weaker than Hastega II (30 %), but the game gives both the same "Haste" status, so the file can't
  tell them apart: check the grey timer and recast Hastega II by hand (Ctrl+Home) if needed.
- **The same buff cast by someone else within 15 s after your ward** is shown as yours.
- **Wards with a random effect** (Glittering Ruby) have no timer unless you give their `duration` in
  `SMN_WARD.list`.
- **Only Shining Ruby / Wind's Blessing are known to share a buff slot** (`SMN_SHARED_SLOTS`). Other probable
  conflicts (en-spell wards with each other, Frost / Lightning Armor) are not confirmed and not handled.

## Conduit sequence
- **In crowded zones the pace follows the lag**: about 0.7 s + your lag per pact (2.0-2.3 s in Domain Invasion,
  13-15 pacts) instead of ~1.6 s solo (~18 pacts). Each pact is sent when you see the previous one start.
- **A pact sent too early can be dropped by the game without any message**; it is resent after the wait
  (lag-based, ~2.5-3 s in DI) and the delay between pacts grows a little.
- **Terror, Stun and the like** ("<you> cannot perform that action") block every pact until they wear off.
- **No extra Rage after Conduit**: pacts under Astral Conduit restart the Rage recast, so it is never ready when
  the buff ends (~22 s left). Only the finisher (`finisher = true`, Super Revitalizer) gives Apogee + 2 more Rages.

## Elemental Siphon and Atomos
- **The Siphon MP estimate is approximate**: the weather bonus is assumed +10 % (single) / +15 % (double), and the
  spirit's own MP is not checked (a fresh spirit always has more than you can Siphon).
- **The Dispel line only knows buffs seen being gained** while you were nearby: buffs a mob had before you arrived,
  or before a zone change / `//gs reload`, are not listed.
- **Every buff gained is listed**, even ones Atomos can't steal: hide them with `SMN_ATOMOS.ignore`.
- **"<n> of <mob>'s effects disappear"** doesn't say which ones: the whole list for that mob is cleared.
- **Buffs that wear off without a message** stay listed until `SMN_ATOMOS.expire` (300 s by default).
- **Skill-up Siphon** needs level 50 and at least one learned spirit; after 2 failures in a row it is off until
  the next skill-up session.

## Refresh received
- **No swap while you are casting, your avatar is acting, or during Conduit**: your current gear has priority.
- **If the end of the caster's spell is missed**, your normal gear comes back after 8 s.

## Other
- **Treasure Hunter Tag** works with your own spells / JAs / WSs only. Melee hits don't tag, and the avatar's
  Blood Pacts never apply your TH.
- **Movement gear**: a jump of more than 40 yalms per second (warp) doesn't count as moving.
- **Saved HUD position off screen** (resolution changed): it is ignored and the HUD opens at `SMN_HUD.x / y`.
- **Automation sends game commands for you**: against Square Enix's Terms of Service, like Windower itself.
