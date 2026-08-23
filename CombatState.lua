local _, namespace = ...

local CombatState = {}

function CombatState:CanReadAuras(inCombat)
    return not inCombat
end

function CombatState:GetThreatState(role, threatStatus)
    local hasAggro = threatStatus and threatStatus >= 2

    if role == "TANK" then
        if threatStatus == nil then
            return "safe"
        end

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

function CombatState:IsIdleNeutral(
    reaction,
    neutralReaction,
    threatStatus
)
    return reaction ~= nil and reaction == neutralReaction and
        threatStatus == nil
end

function CombatState:ResolvePlayerRole(assignedRole, specializationRole)
    if assignedRole and assignedRole ~= "NONE" then
        return assignedRole
    end

    return specializationRole or "NONE"
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

function CombatState:GetMarkerInterruptibility(event, currentState)
    if event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        return true
    end

    if event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" or
        event == "UNIT_SPELLCAST_START" or
        event == "UNIT_SPELLCAST_CHANNEL_START" then
        return false
    end

    return currentState or false
end

namespace.CombatState = CombatState

return CombatState
