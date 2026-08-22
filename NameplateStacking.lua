local _, namespace = ...

local NameplateStacking = {}

local SETTINGS = {
    nameplateOverlapH = "2.0",
    nameplateOverlapV = "1.6",
}

function NameplateStacking:GetSettings()
    return SETTINGS
end

function NameplateStacking:GetDebugState(getCVar)
    return {
        overlapH = getCVar("nameplateOverlapH"),
        overlapV = getCVar("nameplateOverlapV"),
    }
end

function NameplateStacking:ApplyBounds(basePlate, customView)
    if not basePlate.SetStackingBoundsFrame then
        return false
    end

    basePlate:SetStackingBoundsFrame(customView)

    return true
end

function NameplateStacking:Apply(setCVar, inCombat)
    if inCombat then
        return false
    end

    for name, value in pairs(SETTINGS) do
        setCVar(name, value)
    end

    return true
end

namespace.NameplateStacking = NameplateStacking

return NameplateStacking
