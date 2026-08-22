Describe("Combat state presentation", function()
    local namespace = {}
    local combatState = LoadAddonFile("CombatState.lua", namespace)

    It("marks secure tank threat as controlled", function()
        -- Given
        local role = "TANK"
        local threatStatus = 3

        -- When
        local state = combatState:GetThreatState(role, threatStatus)

        -- Then
        ExpectEqual(state, "secure")
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
