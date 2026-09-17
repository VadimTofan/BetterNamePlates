local _, namespace = ...

local Compatibility = {}
local FOREVER_INTERFACE = 11601
local FLAVOR_BY_INTERFACE = {
    [11509] = "vanilla",
    [11601] = "forever",
    [20506] = "tbc",
    [50504] = "mists",
}
local UNSUPPORTED_EVENTS = {
    forever = {
        PLAYER_SPECIALIZATION_CHANGED = true,
        TRAIT_CONFIG_UPDATED = true,
    },
    vanilla = {
        PLAYER_SPECIALIZATION_CHANGED = true,
        TRAIT_CONFIG_UPDATED = true,
        UNIT_SPELLCAST_EMPOWER_START = true,
        UNIT_SPELLCAST_EMPOWER_STOP = true,
    },
    tbc = {
        PLAYER_SPECIALIZATION_CHANGED = true,
        TRAIT_CONFIG_UPDATED = true,
        UNIT_SPELLCAST_EMPOWER_START = true,
        UNIT_SPELLCAST_EMPOWER_STOP = true,
    },
    mists = {
        TRAIT_CONFIG_UPDATED = true,
        UNIT_SPELLCAST_EMPOWER_START = true,
        UNIT_SPELLCAST_EMPOWER_STOP = true,
    },
}

function Compatibility:DetectFlavor(version, interfaceVersion)
    if interfaceVersion == FOREVER_INTERFACE or
        type(version) == "string" and version:match("^1%.60%.") then
        return "forever"
    end

    return FLAVOR_BY_INTERFACE[interfaceVersion] or "retail"
end

function Compatibility:FilterEvents(events, flavor)
    local selected = {}
    local unsupported = UNSUPPORTED_EVENTS[flavor] or {}

    for _, event in ipairs(events) do
        if not unsupported[event] then
            selected[#selected + 1] = event
        end
    end

    return selected
end

function Compatibility:ResolvePlayerRole(assignedRole, specializationRole)
    if assignedRole and assignedRole ~= "NONE" then
        return assignedRole
    end

    return specializationRole or "DAMAGER"
end

function Compatibility:NormalizeCooldown(startTime, duration, enabled)
    if not startTime then
        return nil
    end

    return {
        startTime = startTime,
        duration = duration,
        isEnabled = enabled == 1 or enabled == true,
    }
end

function Compatibility:CreateLegacyDuration(startTimeMS, endTimeMS, getTime)
    if not startTimeMS or not endTimeMS then
        return nil
    end

    local startTime = startTimeMS / 1000
    local endTime = endTimeMS / 1000
    local duration = {
        legacy = true,
    }

    function duration:GetTotalDuration()
        return math.max(0, endTime - startTime)
    end

    function duration:GetRemainingDuration()
        return math.max(0, endTime - getTime())
    end

    function duration:IsZero()
        return self:GetRemainingDuration() <= 0
    end

    return duration
end

function Compatibility:CreateNumericFormatter(createFormatter)
    if createFormatter then
        return createFormatter()
    end

    return {
        AddBreakpoint = function() end,
    }
end

function Compatibility:IsSpellKnown(spellID, spellBook, legacyIsKnown)
    if spellBook and spellBook.IsSpellKnown then
        return spellBook.IsSpellKnown(spellID)
    end

    return legacyIsKnown and legacyIsKnown(spellID) or false
end

function Compatibility:GetSpellTexture(spellID, spellAPI, legacyGetTexture)
    if spellAPI and spellAPI.GetSpellTexture then
        return spellAPI.GetSpellTexture(spellID)
    end

    return legacyGetTexture and legacyGetTexture(spellID) or nil
end

function Compatibility:GetHealthPercent(health, maximum)
    if not maximum or maximum <= 0 then
        return 0
    end

    return health / maximum
end

function Compatibility:GetHealthMarkerAlpha(
    unit,
    health,
    maximum,
    unitHealthPercent,
    alphaCurve
)
    if unitHealthPercent and alphaCurve then
        return unitHealthPercent(unit, true, alphaCurve)
    end

    local percentage = self:GetHealthPercent(health, maximum)

    if percentage >= 0.99 then
        return 0
    end

    return 1
end

function Compatibility:EvaluateBoolean(value, trueValue, falseValue)
    if C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
        return C_CurveUtil.EvaluateColorValueFromBoolean(
            value,
            trueValue,
            falseValue
        )
    end

    if value then
        return trueValue
    end

    return falseValue
end

function Compatibility:GetCurrentFlavor(getBuildInfo)
    getBuildInfo = getBuildInfo or GetBuildInfo

    if not getBuildInfo then
        return "retail"
    end

    local version, _, _, interfaceVersion = getBuildInfo()

    return self:DetectFlavor(version, interfaceVersion)
end

namespace.Compatibility = Compatibility

return Compatibility
