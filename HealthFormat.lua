local _, namespace = ...

local HealthFormat = {}

local function abbreviate(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    end

    if value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end

    return tostring(value)
end

function HealthFormat:Format(health, maximum, secretCheck)
    secretCheck = secretCheck or issecretvalue

    if secretCheck and (secretCheck(health) or secretCheck(maximum)) then
        return nil
    end

    local percentage = maximum > 0 and health / maximum * 100 or 0

    return string.format(
        "%s %.1f%%",
        abbreviate(health),
        percentage
    )
end

function HealthFormat:FormatRestricted(health, percentage, abbreviator)
    return string.format(
        "%s %.1f%%",
        abbreviator(health),
        percentage
    )
end

function HealthFormat:GetRestrictedPercentage(
    unit,
    unitHealthPercent,
    scaleCurve
)
    return unitHealthPercent(unit, true, scaleCurve)
end

namespace.HealthFormat = HealthFormat

return HealthFormat
