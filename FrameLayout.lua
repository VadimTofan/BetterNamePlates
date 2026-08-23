local _, namespace = ...

local FrameLayout = {}

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

namespace.FrameLayout = FrameLayout

return FrameLayout
