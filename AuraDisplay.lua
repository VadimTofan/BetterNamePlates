local _, namespace = ...

local AuraDisplay = {}

local IMPORTANT_BUFF_BORDER = {
    thickness = 1,
    color = {1, 0, 0, 1},
}
local PURGEABLE_BUFF_BORDER = {
    thickness = 1,
    color = {0, 1, 0, 1},
}
local IMPORTANT_BUFF_LEFT_ADJUSTMENT = 10
local IMPORTANT_BUFF_ICON_SCALE = 1
local PURGEABLE_BUFF_FILTER = "HELPFUL|RAID_PLAYER_DISPELLABLE"
local CROWD_CONTROL_FILTER = "HARMFUL|CROWD_CONTROL"

local IMPORTANT_BUFF_FILTERS = {
    "HELPFUL|BIG_DEFENSIVE|!RAID_PLAYER_DISPELLABLE",
    "HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE" ..
        "|!RAID_PLAYER_DISPELLABLE",
    "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE" ..
        "|!RAID_PLAYER_DISPELLABLE",
}

local RIGHT_AURA_GROUPS = {
    {
        key = "purgeableBuffs",
        filter = PURGEABLE_BUFF_FILTER,
    },
    {
        key = "crowdControl",
        filter = CROWD_CONTROL_FILTER,
    },
    {
        key = "importantBuff1",
        filter = IMPORTANT_BUFF_FILTERS[1],
    },
    {
        key = "importantBuff2",
        filter = IMPORTANT_BUFF_FILTERS[2],
    },
    {
        key = "importantBuff3",
        filter = IMPORTANT_BUFF_FILTERS[3],
    },
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
    return CROWD_CONTROL_FILTER
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

function AuraDisplay:GetPurgeableBuffFilter()
    return PURGEABLE_BUFF_FILTER
end

function AuraDisplay:GetRightAuraGroups()
    return RIGHT_AURA_GROUPS
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

function AuraDisplay:GetPurgeableBuffBorder()
    return PURGEABLE_BUFF_BORDER
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
    local filterCount = #RIGHT_AURA_GROUPS
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

function AuraDisplay:GetTextOverlayFrameLevel(cooldownFrameLevel)
    return cooldownFrameLevel + 1
end

function AuraDisplay:ShouldEnableMouse()
    return false
end

function AuraDisplay:ShouldHideTooltipInCombat()
    return true
end

namespace.AuraDisplay = AuraDisplay

return AuraDisplay
