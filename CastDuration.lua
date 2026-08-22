local _, namespace = ...

local CastDuration = {}

function CastDuration:GetUnitDuration(
    unit,
    isChannel,
    getCastingDuration,
    getChannelDuration
)
    if isChannel then
        return getChannelDuration(unit)
    end

    return getCastingDuration(unit)
end

function CastDuration:GetProgress(duration)
    return duration:GetRemainingDuration()
end

namespace.CastDuration = CastDuration

return CastDuration
