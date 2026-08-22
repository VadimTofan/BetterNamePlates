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
