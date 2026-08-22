Describe("Addon identity", function()
    It("uses the BetterNamePlates name and slash command", function()
        -- Given
        local namespace = {}

        -- When
        local identity = LoadAddonFile("Identity.lua", namespace)

        -- Then
        ExpectEqual(identity.name, "BetterNamePlates")
        ExpectEqual(identity.slashCommand, "/bnp")
        ExpectEqual(identity.slashKey, "BETTERNAMEPLATES")
    end)
end)
