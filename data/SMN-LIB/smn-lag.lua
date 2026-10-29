-- ===================================================================================================================
--  SMN-LIB: live lag estimate (no packets)
--    Every Blood Pact you send (by hand, macro, Ward rotation, Conduit...) is timed: from the command (precast)
--    to the avatar starting it (pet_midcast). The estimate is ready BEFORE Astral Conduit, from your normal play.
--      - higher sample (spike): the estimate rises fast (SMN_AUTO.lag.rise, 60 % of the gap)
--      - lower sample: it comes down slowly (SMN_AUTO.lag.fall, 15 % of the gap)
--    Used by the Conduit sequence (smn-rage):
--      - wait before resending a pact = max(accept_wait, estimate x accept_mult + accept_add)
--      - "Unable to use job ability" or no answer at all during Conduit (pact sent too early): +0.1 s between
--        pacts (max +0.5),
--        -0.02 s per pact accepted
--    Reset on zone change.
-- ===================================================================================================================

smn_lag = {est = nil, pending = nil, extra = 0}

local function cfg() return (SMN_AUTO or {}).lag or {} end

-- precast of a Blood Pact: command sent (the clock starts at the latest send)
-- A command sent again before the avatar started (resend): we can't tell which send was accepted, so that pact
-- gives no sample (a silently dropped first send would otherwise read as a huge lag).
function smn_lag_on_send()
    local now = os.clock()
    smn_lag.resent = smn_lag.pending ~= nil and now - smn_lag.pending < 5
    smn_lag.pending = now
end

-- pet_midcast: the avatar starts the pact -> one sample
function smn_lag_on_pet_start()
    local sent, resent = smn_lag.pending, smn_lag.resent
    smn_lag.pending, smn_lag.resent = nil, false
    if smn_lag.extra > 0 then smn_lag.extra = math.max(0, smn_lag.extra - 0.02) end
    if not sent or resent then return end
    local s = os.clock() - sent
    if s <= 0 or s > 5 then return end
    local e = smn_lag.est
    if not e then
        e = s
    elseif s > e then
        e = e + (cfg().rise or 0.6) * (s - e)
    else
        e = e + (cfg().fall or 0.15) * (s - e)
    end
    smn_lag.est = e
    return s   -- the sample, for the Conduit trace
end

-- Conduit: wait for the pact to start before resending it
function smn_lag_accept_wait(base)
    base = base or 1.5
    if not smn_lag.est or cfg().adaptive == false then return base end
    return math.max(base, smn_lag.est * (cfg().accept_mult or 2) + (cfg().accept_add or 0.3))
end

-- Conduit ('pet_start'): delay after the start of a pact before sending the next one.
-- The next pact leaves when you SEE the previous one start, so the lag adds up on every cycle
-- (interval ~ start_delay + lag). The delay is never shortened for lag: the lag varies a lot from one pact to
-- the next in crowded zones, and a pact that arrives too early is dropped by the game. A pact refused
-- ("Unable...") or dropped (no answer): +extra_step right away (smn_lag.extra).
function smn_lag_start_delay(base)
    if cfg().adaptive == false then return base end
    return base + smn_lag.extra
end

-- Conduit: a pact got no answer at all (sent too early, dropped by the game without any message): same as
-- an "Unable...": a little more delay between pacts
function smn_lag_on_drop()
    smn_lag.extra = math.min(cfg().extra_max or 0.5, smn_lag.extra + (cfg().extra_step or 0.1))
end

windower.register_event('incoming text', function(original)
    if not original then return end
    if original:find('Unable to use job ability') and not original:find('%[SMN%]') then
        smn_lag.pending = nil   -- that command was refused: not a lag sample
        if smn_conduit_trace then smn_conduit_trace('unable_msg', '') end
        if smn_rage and smn_rage.seq then
            smn_lag.extra = math.min(cfg().extra_max or 0.5, smn_lag.extra + (cfg().extra_step or 0.1))
        end
    end
end)

windower.register_event('zone change', function()
    smn_lag.est, smn_lag.pending, smn_lag.extra = nil, nil, 0
end)
