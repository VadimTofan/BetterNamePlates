Describe("Combat state presentation", function()
    local namespace = {}
    local combatState = LoadAddonFile("CombatState.lua", namespace)

    It("does not inspect restricted enemy auras during combat", function()
        -- Given
        local inCombat = true

        -- When
        local canReadAuras = combatState:CanReadAuras(inCombat)

        -- Then
        ExpectEqual(canReadAuras, false)
    end)

    It("marks secure tank threat as controlled", function()
        -- Given
        local role = "TANK"
        local threatStatus = 3

        -- When
        local state = combatState:GetThreatState(role, threatStatus)

        -- Then
        ExpectEqual(state, "secure")
    end)

    It("treats a missing tank threat record as neutral", function()
        -- Given
        local role = "TANK"
        local threatStatus = nil

        -- When
        local state = combatState:GetThreatState(role, threatStatus)

        -- Then
        ExpectEqual(state, "safe")
    end)

    It("warns damage dealers when they gain threat", function()
        -- Given
        local role = "DAMAGER"
        local threatStatus = 2

        -- When
        local state = combatState:GetThreatState(role, threatStatus)

        -- Then
        ExpectEqual(state, "aggro")
    end)

    It("uses specialization role when no group role is assigned", function()
        -- Given
        local assignedRole = "NONE"
        local specializationRole = "TANK"

        -- When
        local role = combatState:ResolvePlayerRole(
            assignedRole,
            specializationRole
        )

        -- Then
        ExpectEqual(role, "TANK")
    end)

    It("keeps an explicitly assigned group role", function()
        -- Given
        local assignedRole = "DAMAGER"
        local specializationRole = "TANK"

        -- When
        local role = combatState:ResolvePlayerRole(
            assignedRole,
            specializationRole
        )

        -- Then
        ExpectEqual(role, "DAMAGER")
    end)

    It("gives uninterruptible casts the protected presentation", function()
        -- Given
        local isImportant = true
        local isInterruptible = false

        -- When
        local state = combatState:GetCastState(
            isImportant,
            isInterruptible
        )

        -- Then
        ExpectEqual(state, "protected")
    end)

    It("gives important interruptible casts the priority presentation", function()
        -- Given
        local isImportant = true
        local isInterruptible = true

        -- When
        local state = combatState:GetCastState(
            isImportant,
            isInterruptible
        )

        -- Then
        ExpectEqual(state, "priority")
    end)
end)
