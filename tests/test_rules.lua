Describe("Mythic+ rules", function()
    local namespace = {}
    local rules = LoadAddonFile("Rules.lua", namespace)

    It("falls back to generic behavior for unknown spells", function()
        -- Given
        local spellID = 999999999

        -- When
        local rule = rules:GetCast(spellID)

        -- Then
        ExpectEqual(rule.priority, false)
    end)

    It("keeps explicit priority casts interruptible", function()
        -- Given
        rules:RegisterSeason({
            casts = {
                [12345] = {priority = true},
            },
        })

        -- When
        local rule = rules:GetCast(12345)

        -- Then
        ExpectEqual(rule.priority, true)
    end)

    It("shows only actionable auras", function()
        -- Given
        rules:RegisterSeason({
            auras = {
                [54321] = {priority = 2},
            },
        })

        -- When
        local knownAura = rules:GetAura(54321)
        local unknownAura = rules:GetAura(99999)

        -- Then
        ExpectEqual(knownAura.priority, 2)
        ExpectEqual(unknownAura, nil)
    end)
end)
