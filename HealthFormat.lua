local _, namespace = ...

local HealthFormat = {}

function HealthFormat:FormatHealth(health, formatter)
    return formatter(health)
end

function HealthFormat:FormatPercentage(health, maximum, secretCheck)
    secretCheck = secretCheck or issecretvalue

    if secretCheck and (secretCheck(health) or secretCheck(maximum)) then
        return nil
    end

    local percentage = maximum > 0 and health / maximum * 100 or 0

    return string.format("%.1f%%", percentage)
end

function HealthFormat:FormatRestrictedPercentage(percentage)
    return string.format("%.1f%%", percentage)
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
