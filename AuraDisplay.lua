local _, namespace = ...

local AuraDisplay = {}

local IMPORTANT_BUFF_BORDER = {
    thickness = 1,
    color = {1, 0, 0, 1},
}
local IMPORTANT_BUFF_LEFT_ADJUSTMENT = 10
local IMPORTANT_BUFF_ICON_SCALE = 1

local IMPORTANT_BUFF_FILTERS = {
    "HELPFUL|BIG_DEFENSIVE",
    "HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE",
    "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
}

local EXCLUDED_SPELL_IDS = {
    [33917] = true,
    [430589] = true,
    [1270065] = true,
    [1287555] = true,
    [1287663] = true,
    [1287665] = true,
}

function AuraDisplay:GetFilter()
    return "HARMFUL|PLAYER|!CROWD_CONTROL"
end

function AuraDisplay:GetCrowdControlFilter()
    return "HARMFUL|CROWD_CONTROL"
end

function AuraDisplay:GetGroupOptions(config)
    local elementSize = config.iconSize + config.iconSpacing

    return {
        maxFrameCount = config.maxCount,
        candidateFilters = {
            excludeSpellIDs = EXCLUDED_SPELL_IDS,
        },
        layout = {
            elementSpacing = config.iconSpacing,
            lineSpacing = config.iconSpacing,
            groupSpacing = config.iconSpacing,
            groupLineSpacing = config.iconSpacing,
            elementWidth = config.iconSize,
            elementHeight = config.iconSize,
            maximumLineSize = config.maxCount * elementSize,
        },
    }
end

function AuraDisplay:GetDebuffLayout(config)
    return {
        iconSize = config.auraIconSize * config.debuffScale,
        iconSpacing = config.auraIconSpacing * config.debuffScale,
        fontSize = config.auraFontSize * config.debuffScale,
    }
end

function AuraDisplay:GetAnchorLayout(iconSpacing)
    return {
        layerPoint = "BOTTOMRIGHT",
        platePoint = "TOPRIGHT",
        itemPoint = "BOTTOMRIGHT",
        x = 0,
        y = iconSpacing,
        horizontalStep = -1,
        flowDirection = "Left",
    }
end

function AuraDisplay:GetImportantBuffFilters()
    return IMPORTANT_BUFF_FILTERS
end

function AuraDisplay:GetImportantBuffAnchorLayout(iconSpacing, arrowWidth)
    return {
        layerPoint = "LEFT",
        platePoint = "RIGHT",
        itemPoint = "LEFT",
        x = iconSpacing + arrowWidth - IMPORTANT_BUFF_LEFT_ADJUSTMENT,
        y = 0,
        flowDirection = "Right",
    }
end

function AuraDisplay:GetImportantBuffBorder()
    return IMPORTANT_BUFF_BORDER
end

function AuraDisplay:GetImportantBuffIconSize(baseIconSize)
    return baseIconSize * IMPORTANT_BUFF_ICON_SCALE
end

function AuraDisplay:GetImportantBuffInteraction()
    return {
        enableMouse = true,
        enableClicks = false,
        hideTooltipInCombat = false,
        useNativeTooltip = true,
        tooltipAnchor = "ANCHOR_RIGHT",
    }
end

function AuraDisplay:GetRightAuraMaximumLineSize(config)
    local filterCount = #IMPORTANT_BUFF_FILTERS + 1
    local elementSize = config.iconSize + config.iconSpacing

    return config.maxCount * filterCount * elementSize
end

function AuraDisplay:GetExcludedSpellIDs()
    return EXCLUDED_SPELL_IDS
end

function AuraDisplay:GetDurationBreakpoint()
    return {
        threshold = 0,
        step = 1,
        format = "%d",
    }
end

function AuraDisplay:ShouldReverseCooldown()
    return true
end

function AuraDisplay:ShouldEnableMouse()
    return false
end

function AuraDisplay:ShouldHideTooltipInCombat()
    return true
end

namespace.AuraDisplay = AuraDisplay

return AuraDisplay
