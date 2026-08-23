local _, namespace = ...

local NpcClassification = {}
local FEL_INFUSION_POWER_TOKEN = "POWER_TYPE_FEL_INFUSION"

function NpcClassification:ShouldShowNameplate(unit)
    if unit.classification == "elite" or
        unit.classification == "rareelite" or
        unit.classification == "worldboss" then
        return true
    end

    if unit.isLieutenant then
        return true
    end

    if unit.playerLevel and unit.effectiveLevel then
        return unit.effectiveLevel == -1 or
            unit.effectiveLevel == unit.playerLevel + 1 or
            unit.effectiveLevel == unit.playerLevel + 2
    end

    return false
end

function NpcClassification:GetColorKey(unit)
    if unit.playerLevel and unit.effectiveLevel then
        if unit.effectiveLevel == -1 or
            unit.effectiveLevel == unit.playerLevel + 2 then
            return "boss"
        end

        if unit.effectiveLevel == unit.playerLevel + 1 then
            return "miniboss"
        end
    end

    if unit.isLieutenant then
        return "miniboss"
    end

    if unit.classification == "normal" then
        return "safe"
    end

    if unit.powerToken == FEL_INFUSION_POWER_TOKEN then
        return "safe"
    end

    if unit.classBase == "PALADIN" or
        unit.powerType ~= nil and unit.powerType == unit.manaPowerType or
        unit.manaMaximum and unit.manaMaximum > 0 then
        return "caster"
    end

    if unit.classification == "rareelite" then
        return "miniboss"
    end

    return "safe"
end

namespace.NpcClassification = NpcClassification

return NpcClassification
