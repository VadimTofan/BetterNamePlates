local _, namespace = ...

local TargetIndicator = {}
local DEFAULT_STYLE = "arrows"

function TargetIndicator:NormalizeStyle(style)
    if style == "arrows" or style == "scratched" then
        return style
    end

    return DEFAULT_STYLE
end

function TargetIndicator:GetNextStyle(style)
    if self:NormalizeStyle(style) == "arrows" then
        return "scratched"
    end

    return "arrows"
end

function TargetIndicator:ShouldShowArrows(isTarget, style)
    return isTarget == true and self:NormalizeStyle(style) == "arrows"
end

function TargetIndicator:ShouldShowScratch(isTarget, style)
    return isTarget == true and self:NormalizeStyle(style) == "scratched"
end

function TargetIndicator:GetScratchColorKey(showTargetScratch)
    if showTargetScratch then
        return "targetScratchOverlay"
    end

    return "focusOverlay"
end

function TargetIndicator:ShouldShow(isTarget)
    return isTarget == true
end

function TargetIndicator:ShouldShowHover(isMouseover, isTarget)
    return isMouseover == true and isTarget ~= true
end

function TargetIndicator:GetHoverRefreshInterval()
    return 0.15
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
