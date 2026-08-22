Describe("Nameplate frame layout", function()
    It("places the custom view above Blizzard's unit frame", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)
        local blizzardFrameLevel = 7

        -- When
        local customFrameLevel = frameLayout:GetOverlayLevel(
            blizzardFrameLevel
        )

        -- Then
        ExpectEqual(customFrameLevel, 8)
    end)
end)
