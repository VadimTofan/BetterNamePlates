local _, namespace = ...

local CombatState = {}

function CombatState:GetThreatState(role, threatStatus)
    local hasAggro = threatStatus and threatStatus >= 2

    if role == "TANK" then
        if threatStatus == 3 then
            return "secure"
        end

        if hasAggro then
            return "contested"
        end

        return "lost"
    end

    if hasAggro then
        return "aggro"
    end

    return "safe"
end

function CombatState:GetCastState(isImportant, isInterruptible)
    if not isInterruptible then
        return "protected"
    end

    if isImportant then
        return "priority"
    end

    return "normal"
end

namespace.CombatState = CombatState

return CombatState
