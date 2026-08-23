Describe("Raid target indicator", function()
    local namespace = {}
    local raidTargetIndicator = LoadAddonFile(
        "RaidTargetIndicator.lua",
        namespace
    )

    It("centers a 20 pixel marker on the health bar top edge", function()
        -- Given
        local expectedSize = 20

        -- When
        local layout = raidTargetIndicator:GetLayout()

        -- Then
        ExpectEqual(layout.size, expectedSize)
        ExpectEqual(layout.point, "CENTER")
        ExpectEqual(layout.relativePoint, "TOP")
        ExpectEqual(layout.x, 0)
        ExpectEqual(layout.y, 0)
        ExpectEqual(
            layout.texture,
            "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
        )
    end)

    It("hides unassigned raid target markers", function()
        -- Given
        local wasHidden = false
        local icon = {
            Show = function() end,
            Hide = function()
                wasHidden = true
            end,
        }

        -- When
        raidTargetIndicator:Apply(
            icon,
            nil,
            function()
                error("an absent marker must not update the texture")
            end
        )

        -- Then
        ExpectEqual(wasHidden, true)
    end)

    It("passes opaque marker values to Blizzard unchanged", function()
        -- Given
        local markerValue = {}
        local receivedMarker
        local wasShown = false
        local icon = {
            Show = function()
                wasShown = true
            end,
            Hide = function() end,
        }

        -- When
        raidTargetIndicator:Apply(
            icon,
            markerValue,
            function(_, value)
                receivedMarker = value
            end
        )

        -- Then
        ExpectEqual(receivedMarker, markerValue)
        ExpectEqual(wasShown, true)
    end)
end)
