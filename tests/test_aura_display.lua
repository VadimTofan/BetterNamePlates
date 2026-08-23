Describe("Player debuff display", function()
    It("filters native aura containers to player harmful auras", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local filter = auraDisplay:GetFilter()

        -- Then
        ExpectEqual(filter, "HARMFUL|PLAYER")
    end)

    It("lays out five dot icons above the healthbar", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local options = auraDisplay:GetGroupOptions({
            iconSize = 22.5,
            iconSpacing = 2,
            maxCount = 5,
        })

        -- Then
        ExpectEqual(options.maxFrameCount, 5)
        ExpectEqual(options.layout.elementWidth, 22.5)
        ExpectEqual(options.layout.elementHeight, 22.5)
        ExpectEqual(options.layout.elementSpacing, 2)
        ExpectEqual(options.layout.maximumLineSize, 122.5)
    end)

    It("anchors debuffs at the top right and grows them left", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local anchor = auraDisplay:GetAnchorLayout(2)

        -- Then
        ExpectEqual(anchor.layerPoint, "BOTTOMRIGHT")
        ExpectEqual(anchor.platePoint, "TOPRIGHT")
        ExpectEqual(anchor.y, 2)
        ExpectEqual(anchor.itemPoint, "BOTTOMRIGHT")
        ExpectEqual(anchor.horizontalStep, -1)
        ExpectEqual(anchor.flowDirection, "Left")
    end)

    It("formats debuff durations as bare whole numbers", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local breakpoint = auraDisplay:GetDurationBreakpoint()

        -- Then
        ExpectEqual(breakpoint.threshold, 0)
        ExpectEqual(breakpoint.step, 1)
        ExpectEqual(breakpoint.format, "%d")
    end)

    It("reverses the debuff cooldown swipe", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local shouldReverse = auraDisplay:ShouldReverseCooldown()

        -- Then
        ExpectEqual(shouldReverse, true)
    end)

    It("disables debuff icon tooltips and mouse input", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local mouseEnabled = auraDisplay:ShouldEnableMouse()
        local hideTooltipInCombat =
            auraDisplay:ShouldHideTooltipInCombat()

        -- Then
        ExpectEqual(mouseEnabled, false)
        ExpectEqual(hideTooltipInCombat, true)
    end)

    It("excludes passive Rune of Lingering debuffs", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local excludedSpellIDs = auraDisplay:GetExcludedSpellIDs()

        -- Then
        ExpectEqual(excludedSpellIDs[1287555], true)
        ExpectEqual(excludedSpellIDs[1287663], true)
        ExpectEqual(excludedSpellIDs[1287665], true)
    end)

    It("excludes the Mangle debuff", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local excludedSpellIDs = auraDisplay:GetExcludedSpellIDs()

        -- Then
        ExpectEqual(excludedSpellIDs[33917], true)
    end)

    It("excludes the Vicious Brambles debuff", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local excludedSpellIDs = auraDisplay:GetExcludedSpellIDs()

        -- Then
        ExpectEqual(excludedSpellIDs[1270065], true)
    end)

    It("excludes the Atmospheric Exposure debuff", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local excludedSpellIDs = auraDisplay:GetExcludedSpellIDs()

        -- Then
        ExpectEqual(excludedSpellIDs[430589], true)
    end)
end)
