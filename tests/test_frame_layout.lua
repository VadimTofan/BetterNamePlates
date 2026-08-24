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

    It("places debuffs below every custom nameplate", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local auraFrameLevel = frameLayout:GetAuraLevel()

        -- Then
        ExpectEqual(auraFrameLevel, 0)
    end)

    It("places detached debuffs in the background strata", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local auraFrameStrata = frameLayout:GetAuraStrata()

        -- Then
        ExpectEqual(auraFrameStrata, "BACKGROUND")
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

    It("clips kick markers before the final five percent of a cast", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local width = frameLayout:GetInterruptMarkerClipWidth(
            135,
            0.95,
            2
        )

        -- Then
        ExpectEqual(width, 127.25)
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

    It("anchors cast time from the padded bottom-right edge", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local anchor = frameLayout:GetCastTimeAnchor(1, 2)

        -- Then
        ExpectEqual(anchor.point, "BOTTOMRIGHT")
        ExpectEqual(anchor.relativePoint, "BOTTOMRIGHT")
        ExpectEqual(anchor.x, -1)
        ExpectEqual(anchor.y, 2)
    end)

    It("anchors NPC names above the left edge of the health bar", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local anchor = frameLayout:GetNameAnchor(2)

        -- Then
        ExpectEqual(anchor.point, "BOTTOMLEFT")
        ExpectEqual(anchor.relativePoint, "TOPLEFT")
        ExpectEqual(anchor.x, 0)
        ExpectEqual(anchor.y, 2)
    end)

    It("builds a half-pixel outline around NPC names", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local offsets = frameLayout:GetNameOutlineOffsets(0.5)

        -- Then
        ExpectEqual(#offsets, 4)
        ExpectEqual(offsets[1].x, -0.5)
        ExpectEqual(offsets[2].x, 0.5)
        ExpectEqual(offsets[3].y, -0.5)
        ExpectEqual(offsets[4].y, 0.5)
    end)

    It("offsets the duplicate NPC name layer for synthetic bold text", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local offset = frameLayout:GetNameBoldOffset(0.5)

        -- Then
        ExpectEqual(offset.x, 0.5)
        ExpectEqual(offset.y, 0)
    end)

    It("anchors health and percentage text to opposite plate edges", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local anchors = frameLayout:GetHealthTextAnchors(3)

        -- Then
        ExpectEqual(anchors.health.point, "LEFT")
        ExpectEqual(anchors.health.x, 3)
        ExpectEqual(anchors.percentage.point, "RIGHT")
        ExpectEqual(anchors.percentage.x, -3)
    end)

    It("does not clip raid markers at the health bar boundary", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local shouldClip = frameLayout:ShouldClipHealthChildren()

        -- Then
        ExpectEqual(shouldClip, false)
    end)

    It("orders empty health and absorb bars as three layers", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local levels = frameLayout:GetHealthLayerLevels(8)

        -- Then
        ExpectEqual(levels.empty, 8)
        ExpectEqual(levels.health, 9)
        ExpectEqual(levels.absorb, 10)
    end)

    It("insets health by the requested amount on every side", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local dimensions = frameLayout:GetInsetDimensions(135, 17, 1)

        -- Then
        ExpectEqual(dimensions.width, 133)
        ExpectEqual(dimensions.height, 15)
    end)

    It("extends only the right edge of the health layer", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local dimensions = frameLayout:GetHealthDimensions(135, 17, 1, 1)

        -- Then
        ExpectEqual(dimensions.width, 134)
        ExpectEqual(dimensions.height, 15)
        ExpectEqual(dimensions.leftInset, 1)
    end)

    It("places absorbs after health and clips them to the plate", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local placement = frameLayout:GetAbsorbPlacement()

        -- Then
        ExpectEqual(placement.point, "LEFT")
        ExpectEqual(placement.relativePoint, "RIGHT")
        ExpectEqual(placement.clipsChildren, true)
    end)

    It("anchors the health marker to the health fill edge", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local placement = frameLayout:GetHealthMarkerPlacement()

        -- Then
        ExpectEqual(placement.point, "CENTER")
        ExpectEqual(placement.relativePoint, "RIGHT")
    end)

    It("shows the health marker only for the current target", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local targetVisible = frameLayout:ShouldShowHealthMarker(true)
        local otherVisible = frameLayout:ShouldShowHealthMarker(false)

        -- Then
        ExpectEqual(targetVisible, true)
        ExpectEqual(otherVisible, false)
    end)

    It("hides the health marker at ninety-nine percent", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local points = frameLayout:GetHealthMarkerAlphaCurvePoints()

        -- Then
        ExpectEqual(points[1].x, 0)
        ExpectEqual(points[1].y, 1)
        ExpectEqual(points[2].x, 0.99)
        ExpectEqual(points[2].y, 0)
    end)

    It("makes only the current target health section taller", function()
        -- Given
        local namespace = {}
        local frameLayout = LoadAddonFile("FrameLayout.lua", namespace)

        -- When
        local targetHeight = frameLayout:GetTargetHealthHeight(
            17,
            1.25,
            true
        )
        local regularHeight = frameLayout:GetTargetHealthHeight(
            17,
            1.25,
            false
        )

        -- Then
        ExpectEqual(targetHeight, 21.25)
        ExpectEqual(regularHeight, 17)
    end)
end)
