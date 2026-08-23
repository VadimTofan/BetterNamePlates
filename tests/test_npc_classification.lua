Describe("Jundies NPC classification", function()
    local namespace = {}
    local npcClassification = LoadAddonFile(
        "NpcClassification.lua",
        namespace
    )

    It("classifies units with the mana power type as casters", function()
        -- Given
        local unit = {
            powerType = 0,
            manaPowerType = 0,
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "caster")
    end)

    It("does not classify a unit as a caster from observed casts alone", function()
        -- Given
        local unit = {
            isKnownCaster = true,
            powerType = 2,
            manaPowerType = 0,
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "safe")
    end)

    It("keeps Fel Infusion NPCs out of the caster classification", function()
        -- Given
        local unit = {
            isKnownCaster = true,
            powerToken = "POWER_TYPE_FEL_INFUSION",
            manaPowerType = 0,
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "safe")
    end)

    It("classifies units one level above the player as lieutenants", function()
        -- Given
        local unit = {
            playerLevel = 80,
            effectiveLevel = 81,
            manaMaximum = 100,
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "miniboss")
    end)

    It("classifies units two levels above the player as bosses", function()
        -- Given
        local unit = {
            playerLevel = 80,
            effectiveLevel = 82,
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "boss")
    end)

    It("does not compare restricted classification inputs", function()
        -- Given
        local unit = {
            playerLevel = nil,
            effectiveLevel = nil,
            manaMaximum = nil,
            classification = "normal",
        }

        -- When
        local result = npcClassification:GetColorKey(unit)

        -- Then
        ExpectEqual(result, "safe")
    end)
end)
