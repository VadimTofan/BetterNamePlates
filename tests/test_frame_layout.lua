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

    It("places cast text and borders above progress overlays", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)
        local castFrameLevel = 9

        -- When
        local foregroundLevel = frameLayout:GetCastForegroundLevel(
            castFrameLevel
        )

        -- Then
        ExpectEqual(foregroundLevel, 11)
    end)

    It("places the kick marker above the cast foreground", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)
        local castFrameLevel = 9

        -- When
        local markerLevel = frameLayout:GetCastMarkerLevel(castFrameLevel)

        -- Then
        ExpectEqual(markerLevel, 12)
    end)

    It("anchors cast text from the padded bottom-left edge", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local anchor = frameLayout:GetCastTextAnchor(4, 2)

        -- Then
        ExpectEqual(anchor.point, "BOTTOMLEFT")
        ExpectEqual(anchor.relativePoint, "BOTTOMLEFT")
        ExpectEqual(anchor.x, 4)
        ExpectEqual(anchor.y, 2)
    end)
end)
