local _, namespace = ...

local FrameLayout = {}

function FrameLayout:GetOverlayLevel(blizzardFrameLevel)
    return math.max(0, blizzardFrameLevel or 0) + 1
end

namespace.FrameLayout = FrameLayout

return FrameLayout
