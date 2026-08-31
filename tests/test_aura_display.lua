Describe("Player debuff display", function()
    It("filters native aura containers to player harmful auras", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local filter = auraDisplay:GetFilter()

        -- Then
        ExpectEqual(filter, "HARMFUL|PLAYER|!CROWD_CONTROL")
    end)

    It("selects engine-classified crowd control from every source", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local filter = auraDisplay:GetCrowdControlFilter()

        -- Then
        ExpectEqual(filter, "HARMFUL|CROWD_CONTROL")
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

    It("scales player debuff icons spacing and text uniformly", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local layout = auraDisplay:GetDebuffLayout({
            auraIconSize = 18,
            auraIconSpacing = 2,
            auraFontSize = 10,
            debuffScale = 0.5,
        })

        -- Then
        ExpectEqual(layout.iconSize, 9)
        ExpectEqual(layout.iconSpacing, 1)
        ExpectEqual(layout.fontSize, 5)
    end)

    It("anchors debuffs at the top right and grows them left", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local anchor = auraDisplay:GetAnchorLayout()

        -- Then
        ExpectEqual(anchor.layerPoint, "BOTTOMRIGHT")
        ExpectEqual(anchor.platePoint, "TOPRIGHT")
        ExpectEqual(anchor.y, 0)
        ExpectEqual(anchor.itemPoint, "BOTTOMRIGHT")
        ExpectEqual(anchor.horizontalStep, -1)
        ExpectEqual(anchor.flowDirection, "Left")
    end)

    It("selects non-overlapping defensive and important enemy buffs", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local filters = auraDisplay:GetImportantBuffFilters()

        -- Then
        ExpectEqual(
            filters[1],
            "HELPFUL|BIG_DEFENSIVE|!RAID_PLAYER_DISPELLABLE"
        )
        ExpectEqual(
            filters[2],
            "HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE" ..
                "|!RAID_PLAYER_DISPELLABLE"
        )
        ExpectEqual(
            filters[3],
            "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE" ..
                "|!RAID_PLAYER_DISPELLABLE"
        )
        ExpectEqual(#filters, 3)
    end)

    It("selects only enemy buffs the current player can purge", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local filter = auraDisplay:GetPurgeableBuffFilter()

        -- Then
        ExpectEqual(filter, "HELPFUL|RAID_PLAYER_DISPELLABLE")
    end)

    It("places purgeable buffs first in the right aura row", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local groups = auraDisplay:GetRightAuraGroups()

        -- Then
        ExpectEqual(groups[1].key, "purgeableBuffs")
        ExpectEqual(
            groups[1].filter,
            "HELPFUL|RAID_PLAYER_DISPELLABLE"
        )
        ExpectEqual(groups[3].key, "crowdControl")
        ExpectEqual(#groups, 6)
    end)

    It("places important enemy buffs beyond the target arrow width", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local anchor = auraDisplay:GetImportantBuffAnchorLayout(2, 27)

        -- Then
        ExpectEqual(anchor.layerPoint, "LEFT")
        ExpectEqual(anchor.platePoint, "RIGHT")
        ExpectEqual(anchor.x, 19)
        ExpectEqual(anchor.y, 0)
        ExpectEqual(anchor.itemPoint, "LEFT")
        ExpectEqual(anchor.flowDirection, "Right")
    end)

    It("uses a one pixel bright red border for important enemy buffs", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local border = auraDisplay:GetImportantBuffBorder()

        -- Then
        ExpectEqual(border.thickness, 1)
        ExpectEqual(border.color[1], 1)
        ExpectEqual(border.color[2], 0)
        ExpectEqual(border.color[3], 0)
        ExpectEqual(border.color[4], 1)
    end)

    It("uses a one pixel light blue border for crowd control", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local border = auraDisplay:GetCrowdControlBorder()

        -- Then
        ExpectEqual(border.thickness, 1)
        ExpectEqual(border.color[1], 0)
        ExpectEqual(border.color[2], 0.8196)
        ExpectEqual(border.color[3], 1)
        ExpectEqual(border.color[4], 1)
    end)

    It("uses the base size for important enemy buff and crowd-control icons", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local iconSize = auraDisplay:GetImportantBuffIconSize(18)

        -- Then
        ExpectEqual(iconSize, 18)
    end)

    It("enables mouseover tooltips only for important enemy buffs", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local interaction = auraDisplay:GetImportantBuffInteraction()

        -- Then
        ExpectEqual(interaction.enableMouse, true)
        ExpectEqual(interaction.enableClicks, false)
        ExpectEqual(interaction.hideTooltipInCombat, false)
        ExpectEqual(interaction.useNativeTooltip, true)
        ExpectEqual(interaction.tooltipAnchor, "ANCHOR_RIGHT")
    end)

    It("keeps crowd control and important buffs on one horizontal row", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local maximumLineSize = auraDisplay:GetRightAuraMaximumLineSize({
            iconSize = 18,
            iconSpacing = 2,
            maxCount = 5,
        })

        -- Then
        ExpectEqual(maximumLineSize, 600)
    end)

    It("formats aura durations as seconds minutes and hours", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local breakpoints = auraDisplay:GetDurationBreakpoints()
        local seconds = breakpoints[1]
        local minutes = breakpoints[2]
        local hours = breakpoints[3]

        -- Then
        ExpectEqual(seconds.threshold, 0)
        ExpectEqual(seconds.step, 1)
        ExpectEqual(seconds.rounding, 2)
        ExpectEqual(seconds.format, "%d")

        ExpectEqual(minutes.threshold, 60)
        ExpectEqual(minutes.format, "%d:%02d")
        ExpectEqual(minutes.components[1].div, 60)
        ExpectEqual(minutes.components[1].rounding, 2)
        ExpectEqual(minutes.components[2].mod, 60)
        ExpectEqual(minutes.components[2].rounding, 2)

        ExpectEqual(hours.threshold, 3600)
        ExpectEqual(hours.format, "%dh")
        ExpectEqual(hours.components[1].div, 3600)
        ExpectEqual(hours.components[1].rounding, 2)
    end)

    It("uses the Expressway presentation for bold aura timers", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)
        local config = {
            expresswayFontFlags = "OUTLINE",
            nameFont = "Expressway.ttf",
        }

        -- When
        local presentation = auraDisplay:GetBoldTimerPresentation(config)

        -- Then
        ExpectEqual(presentation.font, "Expressway.ttf")
        ExpectEqual(presentation.fontFlags, "OUTLINE")
    end)

    It("uses white bold text above the swipe for right-side aura timers", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)
        local config = {
            expresswayFontFlags = "OUTLINE",
            nameFont = "Expressway.ttf",
        }

        -- When
        local presentation =
            auraDisplay:GetRightAuraTimerPresentation(config)

        -- Then
        ExpectEqual(presentation.font, "Expressway.ttf")
        ExpectEqual(presentation.fontFlags, "OUTLINE")
        ExpectEqual(presentation.color[1], 1)
        ExpectEqual(presentation.color[2], 1)
        ExpectEqual(presentation.color[3], 1)
        ExpectEqual(presentation.color[4], 1)
        ExpectEqual(presentation.aboveSwipe, true)
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

    It("places debuff text above the cooldown swipe", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)
        local cooldownFrameLevel = 12

        -- When
        local textFrameLevel =
            auraDisplay:GetTextOverlayFrameLevel(cooldownFrameLevel)

        -- Then
        ExpectEqual(textFrameLevel, 13)
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

    It("defines one longest-duration icon for duplicate DK debuffs", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local groups = auraDisplay:GetPlayerDebuffGroups()
        local excludedSpellIDs = auraDisplay:GetExcludedSpellIDs()

        -- Then
        ExpectEqual(groups[1].key, "deduplicatedPlayerDebuff55078")
        ExpectEqual(groups[1].candidateFilters.includeSpellIDs[55078], true)
        ExpectEqual(groups[1].maxFrameCount, 1)
        ExpectEqual(groups[1].keepLongest, true)
        ExpectEqual(groups[2].key, "deduplicatedPlayerDebuff206930")
        ExpectEqual(groups[2].candidateFilters.includeSpellIDs[206930], true)
        ExpectEqual(groups[2].candidateFilters.includeSpellIDs[228645], true)
        ExpectEqual(groups[2].maxFrameCount, 1)
        ExpectEqual(groups[2].keepLongest, true)
        ExpectEqual(groups[3].key, "playerDebuffs")
        ExpectEqual(groups[3].excludeSpellIDs, true)
        ExpectEqual(excludedSpellIDs[55078], true)
        ExpectEqual(excludedSpellIDs[206930], true)
        ExpectEqual(excludedSpellIDs[228645], true)
    end)

    It("deduplicates Heart Strike inside the crowd-control row", function()
        -- Given
        local namespace = {}
        local auraDisplay = LoadAddonFile("AuraDisplay.lua", namespace)

        -- When
        local groups = auraDisplay:GetRightAuraGroups()

        -- Then
        ExpectEqual(groups[2].key, "deduplicatedHeartStrike")
        ExpectEqual(groups[2].candidateFilters.includeSpellIDs[206930], true)
        ExpectEqual(groups[2].candidateFilters.includeSpellIDs[228645], true)
        ExpectEqual(groups[2].maxFrameCount, 1)
        ExpectEqual(groups[2].keepLongest, true)
        ExpectEqual(groups[2].crowdControl, true)
        ExpectEqual(groups[3].key, "crowdControl")
        ExpectEqual(groups[3].candidateFilters.excludeSpellIDs[206930], true)
        ExpectEqual(groups[3].candidateFilters.excludeSpellIDs[228645], true)
    end)
end)
