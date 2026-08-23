local _, namespace = ...

local CastDuration = {}

local TIME_BREAKPOINT = {
    threshold = 0,
    step = 0.1,
    format = "%.1f",
}

function CastDuration:GetTimeBreakpoint()
    return TIME_BREAKPOINT
end

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

function CastDuration:GetTimerDirection(timerDirections)
    return timerDirections.ElapsedTime
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
        reverseFill = false,
        markerAnchor = "CENTER",
        markerPoint = "RIGHT",
    }
end

function CastDuration:PlaceCooldownMarker(
    markerTrack,
    totalDuration,
    cooldown
)
    local remainingDuration = cooldown:GetRemainingDuration()

    markerTrack:SetMinMaxValues(0, totalDuration)
    markerTrack:SetValue(remainingDuration)
end

function CastDuration:ShouldPlaceCooldownMarker(event)
    return event == nil or event == "UNIT_SPELLCAST_START" or
        event == "UNIT_SPELLCAST_CHANNEL_START"
end

namespace.CastDuration = CastDuration

return CastDuration
