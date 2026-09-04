Describe("Target indicator", function()
    local namespace = {}
    local targetIndicator = LoadAddonFile(
        "TargetIndicator.lua",
        namespace
    )

    It("shows for the current target", function()
        -- Given
        local isTarget = true

        -- When
        local shouldShow = targetIndicator:ShouldShow(isTarget)

        -- Then
        ExpectEqual(shouldShow, true)
    end)

    It("hides for other units", function()
        -- Given
        local isTarget = false

        -- When
        local shouldShow = targetIndicator:ShouldShow(isTarget)

        -- Then
        ExpectEqual(shouldShow, false)
    end)

    It("shows a border without arrows for a hovered non-target", function()
        -- Given
        local isMouseover = true
        local isTarget = false

        -- When
        local shouldShow = targetIndicator:ShouldShowHover(
            isMouseover,
            isTarget
        )

        -- Then
        ExpectEqual(shouldShow, true)
    end)

    It("hides the hover border when the unit is already targeted", function()
        -- Given
        local isMouseover = true
        local isTarget = true

        -- When
        local shouldShow = targetIndicator:ShouldShowHover(
            isMouseover,
            isTarget
        )

        -- Then
        ExpectEqual(shouldShow, false)
    end)

    It("defaults invalid target styles to arrows", function()
        -- Given
        local missingStyle = nil
        local invalidStyle = "unknown"

        -- When
        local missingResult = targetIndicator:NormalizeStyle(missingStyle)
        local invalidResult = targetIndicator:NormalizeStyle(invalidStyle)

        -- Then
        ExpectEqual(missingResult, "arrows")
        ExpectEqual(invalidResult, "arrows")
    end)

    It("toggles between arrow and scratched target styles", function()
        -- Given
        local arrowStyle = "arrows"
        local scratchedStyle = "scratched"

        -- When
        local fromArrows = targetIndicator:GetNextStyle(arrowStyle)
        local fromScratched = targetIndicator:GetNextStyle(scratchedStyle)

        -- Then
        ExpectEqual(fromArrows, "scratched")
        ExpectEqual(fromScratched, "arrows")
    end)

    It("replaces target arrows with the scratched overlay", function()
        -- Given
        local isTarget = true
        local style = "scratched"

        -- When
        local showArrows = targetIndicator:ShouldShowArrows(
            isTarget,
            style
        )
        local showScratch = targetIndicator:ShouldShowScratch(
            isTarget,
            style
        )

        -- Then
        ExpectEqual(showArrows, false)
        ExpectEqual(showScratch, true)
    end)

    It("uses a white scratch for targets and a dark scratch for focus", function()
        -- Given
        local targetScratch = true
        local focusScratch = false

        -- When
        local targetColorKey = targetIndicator:GetScratchColorKey(
            targetScratch
        )
        local focusColorKey = targetIndicator:GetScratchColorKey(
            focusScratch
        )

        -- Then
        ExpectEqual(targetColorKey, "targetScratchOverlay")
        ExpectEqual(focusColorKey, "focusOverlay")
    end)

    It("refreshes hover state often enough to clear stale borders", function()
        -- Given
        local expectedInterval = 0.15

        -- When
        local interval = targetIndicator:GetHoverRefreshInterval()

        -- Then
        ExpectEqual(interval, expectedInterval)
    end)

    It("scales double arrows from the health bar height", function()
        -- Given
        local healthBarHeight = 17

        -- When
        local layout = targetIndicator:GetArrowLayout(
            healthBarHeight,
            0.7,
            5,
            1.5,
            1.36
        )

        -- Then
        ExpectEqual(layout.width, 26.9)
        ExpectEqual(layout.height, 16.2)
        ExpectEqual(layout.offset, 3)
    end)

    It("anchors arrow edges outside the health bar", function()
        -- Given
        local offset = 3

        -- When
        local anchors = targetIndicator:GetArrowAnchors(offset)

        -- Then
        ExpectEqual(anchors.left.point, "RIGHT")
        ExpectEqual(anchors.left.relativePoint, "LEFT")
        ExpectEqual(anchors.left.x, -3)
        ExpectEqual(anchors.right.point, "LEFT")
        ExpectEqual(anchors.right.relativePoint, "RIGHT")
        ExpectEqual(anchors.right.x, 3)
    end)
end)
