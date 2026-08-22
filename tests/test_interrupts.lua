Describe("Player interrupt discovery", function()
    It("selects the first learned interrupt for the player's class", function()
        -- Given
        local namespace = {}
        local interrupts = LoadAddonFile("Interrupts.lua", namespace)
        local learnedSpells = {
            [147362] = true,
        }

        -- When
        local spellID = interrupts:FindKnownSpell(3, function(candidateID)
            return learnedSpells[candidateID] == true
        end)

        -- Then
        ExpectEqual(spellID, 147362)
    end)

    It("returns nil when the class has no learned interrupt", function()
        -- Given
        local namespace = {}
        local interrupts = LoadAddonFile("Interrupts.lua", namespace)

        -- When
        local spellID = interrupts:FindKnownSpell(5, function()
            return false
        end)

        -- Then
        ExpectEqual(spellID, nil)
    end)

    It("refreshes castbars when spell cooldowns change", function()
        -- Given
        local namespace = {}
        local interrupts = LoadAddonFile("Interrupts.lua", namespace)
        local event = "SPELL_UPDATE_COOLDOWN"

        -- When
        local shouldRefresh = interrupts:IsCooldownEvent(event)

        -- Then
        ExpectEqual(shouldRefresh, true)
    end)

    It("recognizes when the player casts their interrupt", function()
        -- Given
        local namespace = {}
        local interrupts = LoadAddonFile("Interrupts.lua", namespace)

        -- When
        local interruptUsed = interrupts:IsPlayerInterruptCast(
            "UNIT_SPELLCAST_SUCCEEDED",
            "player",
            106839,
            106839
        )
        local otherSpellUsed = interrupts:IsPlayerInterruptCast(
            "UNIT_SPELLCAST_SUCCEEDED",
            "player",
            8921,
            106839
        )

        -- Then
        ExpectEqual(interruptUsed, true)
        ExpectEqual(otherSpellUsed, false)
    end)

end)
