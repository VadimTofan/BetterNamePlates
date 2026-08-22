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

function CastDuration:BindRemainingTime(
    statusBar,
    duration,
    interpolation,
    direction
)
    statusBar:SetTimerDuration(
        duration,
        interpolation,
        direction
    )
end

function CastDuration:GetCooldownOverlayLayout()
    return {
        point = "RIGHT",
        relativePoint = "RIGHT",
        reverseFill = true,
        markerAnchor = "RIGHT",
        markerPoint = "LEFT",
    }
end

function CastDuration:PlaceCooldownMarker(
    markerTrack,
    totalDuration,
    cooldown
)
    markerTrack:SetMinMaxValues(0, totalDuration)
    markerTrack:SetValue(cooldown:GetRemainingDuration())
end

function CastDuration:ShouldPlaceCooldownMarker(event)
    return event == nil or event == "UNIT_SPELLCAST_START" or
        event == "UNIT_SPELLCAST_CHANNEL_START"
end

namespace.CastDuration = CastDuration

return CastDuration
