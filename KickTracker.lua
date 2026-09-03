local _, namespace = ...

local KickTracker = {}

local GENERIC_KICK_SPELL_ID = 1766
local PLAYER_KICK_TOLERANCE = 0.15
local DEFAULT_LOCKOUT_DURATION = 3

local LOCKOUT_DURATIONS = {
    [1766] = 3,
    [6552] = 3,
    [47528] = 3,
    [183752] = 3,
    [116705] = 3,
    [96231] = 3,
    [78675] = 5,
    [106839] = 3,
    [147362] = 3,
    [187707] = 3,
    [2139] = 6,
    [57994] = 2,
    [351338] = 3,
    [132409] = 5,
    [119910] = 5,
}

local CLASS_INTERRUPTS = {
    WARRIOR = 6552,
    PALADIN = 96231,
    HUNTER = 147362,
    ROGUE = 1766,
    PRIEST = 15487,
    DEATHKNIGHT = 47528,
    SHAMAN = 57994,
    MAGE = 2139,
    WARLOCK = 132409,
    MONK = 116705,
    DRUID = 106839,
    DEMONHUNTER = 183752,
    EVOKER = 351338,
}

local START_EVENTS = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_EMPOWER_START = true,
}

function KickTracker:IsStartEvent(event)
    return START_EVENTS[event] == true
end

function KickTracker:GetInterrupter(event, standardValue, empowerValue)
    if event == "UNIT_SPELLCAST_INTERRUPTED" or
        event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        return standardValue
    end

    if event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        return empowerValue
    end

    return nil
end

function KickTracker:ShouldShowInterrupt(alreadyShown, interruptedBy)
    return not alreadyShown and not not interruptedBy
end

function KickTracker:ResolveInterruptSpellID(
    now,
    pendingPlayerKick,
    allySpellID
)
    if pendingPlayerKick and
        now - pendingPlayerKick.time <= PLAYER_KICK_TOLERANCE then
        return pendingPlayerKick.spellID
    end

    return allySpellID or GENERIC_KICK_SPELL_ID
end

function KickTracker:InferAllyInterrupt(unitExists, unitClass)
    local onlySpellID
    local candidateCount = 0

    for index = 1, 4 do
        local unit = "party" .. index

        if unitExists(unit) then
            local _, classToken = unitClass(unit)
            local spellID = CLASS_INTERRUPTS[classToken]

            if spellID then
                candidateCount = candidateCount + 1
                onlySpellID = spellID
            end
        end
    end

    if candidateCount == 1 then
        return onlySpellID
    end

    return GENERIC_KICK_SPELL_ID
end

function KickTracker:GetLockoutDuration(spellID)
    return LOCKOUT_DURATIONS[spellID] or DEFAULT_LOCKOUT_DURATION
end

function KickTracker:GetGenericKickSpellID()
    return GENERIC_KICK_SPELL_ID
end

namespace.KickTracker = KickTracker

return KickTracker
