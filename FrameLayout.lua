local _, namespace = ...

local FrameLayout = {}

local function scaleDimension(value, scale)
    return math.floor(value * scale * 100 + 0.5) / 100
end

function FrameLayout:GetOverlayLevel(blizzardFrameLevel)
    return math.max(0, blizzardFrameLevel or 0) + 1
end

function FrameLayout:GetAuraLevel()
    return 0
end

function FrameLayout:GetAuraStrata()
    return "BACKGROUND"
end

function FrameLayout:GetCastForegroundLevel(castFrameLevel)
    return math.max(0, castFrameLevel or 0) + 2
end

function FrameLayout:GetCastMarkerLevel(castFrameLevel)
    return math.max(0, castFrameLevel or 0) + 3
end

function FrameLayout:GetCastTextAnchor(leftPadding, bottomPadding)
    return {
        point = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x = leftPadding,
        y = bottomPadding,
    }
end

function FrameLayout:ShouldClipHealthChildren()
    return false
end

function FrameLayout:GetLightweightLayout(config)
    local scale = config.lightweightScale

    return {
        width = scaleDimension(config.healthWidth, scale),
        height = scaleDimension(config.healthHeight, scale),
        fontSize = scaleDimension(config.nameFontSize, scale),
        padding = scaleDimension(config.contentPadding, scale),
        borderThickness = scaleDimension(config.borderThickness, scale),
    }
end

namespace.FrameLayout = FrameLayout

return FrameLayout
