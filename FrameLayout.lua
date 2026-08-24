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

function FrameLayout:GetInterruptMarkerClipWidth(
    castWidth,
    maximumProgress,
    markerWidth
)
    return math.max(0, castWidth * maximumProgress - markerWidth / 2)
end

function FrameLayout:GetCastTextAnchor(leftPadding, bottomPadding)
    return {
        point = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x = leftPadding,
        y = bottomPadding,
    }
end

function FrameLayout:GetCastTimeAnchor(rightPadding, bottomPadding)
    return {
        point = "BOTTOMRIGHT",
        relativePoint = "BOTTOMRIGHT",
        x = -rightPadding,
        y = bottomPadding,
    }
end

function FrameLayout:GetNameAnchor(gap)
    return {
        point = "BOTTOMLEFT",
        relativePoint = "TOPLEFT",
        x = 0,
        y = gap,
    }
end

function FrameLayout:GetNameOutlineOffsets(thickness)
    return {
        {x = -thickness, y = 0},
        {x = thickness, y = 0},
        {x = 0, y = -thickness},
        {x = 0, y = thickness},
    }
end

function FrameLayout:GetNameBoldOffset(offset)
    return {x = offset, y = 0}
end

function FrameLayout:GetHealthTextAnchors(padding)
    return {
        health = {
            point = "LEFT",
            relativePoint = "LEFT",
            x = padding,
            y = 0,
        },
        percentage = {
            point = "RIGHT",
            relativePoint = "RIGHT",
            x = -padding,
            y = 0,
        },
    }
end

function FrameLayout:ShouldClipHealthChildren()
    return false
end

function FrameLayout:GetHealthLayerLevels(baseLevel)
    local level = math.max(0, baseLevel or 0)

    return {
        empty = level,
        health = level + 1,
        absorb = level + 2,
        foreground = level + 3,
    }
end

function FrameLayout:GetInsetDimensions(width, height, inset)
    return {
        width = width - inset * 2,
        height = height - inset * 2,
    }
end

function FrameLayout:GetHealthDimensions(
    width,
    height,
    inset,
    rightExtension
)
    return {
        width = width - inset * 2 + rightExtension,
        height = height - inset * 2,
        leftInset = inset,
    }
end

function FrameLayout:GetTargetHealthHeight(height, targetScale, isTarget)
    if isTarget then
        return height * targetScale
    end

    return height
end

function FrameLayout:GetAbsorbPlacement()
    return {
        point = "LEFT",
        relativePoint = "RIGHT",
        clipsChildren = true,
    }
end

function FrameLayout:GetHealthMarkerPlacement()
    return {
        point = "CENTER",
        relativePoint = "RIGHT",
    }
end

function FrameLayout:ShouldShowHealthMarker(isTarget)
    return isTarget
end

function FrameLayout:GetHealthMarkerAlphaCurvePoints()
    return {
        {x = 0, y = 1},
        {x = 0.99, y = 0},
    }
end

namespace.FrameLayout = FrameLayout

return FrameLayout
