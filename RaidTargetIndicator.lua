local _, namespace = ...

local RaidTargetIndicator = {}

local MARKER_SIZE = 20
local MARKER_TEXTURE =
    "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

function RaidTargetIndicator:GetLayout()
    return {
        size = MARKER_SIZE,
        point = "CENTER",
        relativePoint = "TOP",
        x = 0,
        y = 0,
        texture = MARKER_TEXTURE,
    }
end

function RaidTargetIndicator:Apply(icon, markerIndex, setIconTexture)
    if markerIndex then
        setIconTexture(icon, markerIndex)
        icon:Show()
        return
    end

    icon:Hide()
end

namespace.RaidTargetIndicator = RaidTargetIndicator

return RaidTargetIndicator
