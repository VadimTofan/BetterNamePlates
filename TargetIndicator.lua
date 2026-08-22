local _, namespace = ...

local TargetIndicator = {}

function TargetIndicator:ShouldShow(isTarget)
    return isTarget == true
end

local function roundToTenth(value)
    return math.floor(value * 10 + 0.5000001) / 10
end

function TargetIndicator:GetArrowLayout(
    healthBarHeight,
    arrowScale,
    arrowOffset,
    arrowWidthScale,
    arrowHeightScale
)
    local scale = healthBarHeight / 20 * (arrowScale or 1)
    local width = roundToTenth(20 * scale * 1.5)

    return {
        width = roundToTenth(width * (arrowWidthScale or 1)),
        height = roundToTenth(20 * scale * (arrowHeightScale or 2)),
        offset = roundToTenth((arrowOffset or 28) * scale),
    }
end

function TargetIndicator:GetArrowAnchors(offset)
    return {
        left = {
            point = "RIGHT",
            relativePoint = "LEFT",
            x = -offset,
        },
        right = {
            point = "LEFT",
            relativePoint = "RIGHT",
            x = offset,
        },
    }
end

namespace.TargetIndicator = TargetIndicator

return TargetIndicator
