local _, namespace = ...

local AuraDisplay = {}

local EXCLUDED_SPELL_IDS = {
    [33917] = true,
    [1270065] = true,
    [1287555] = true,
    [1287663] = true,
    [1287665] = true,
}

function AuraDisplay:GetFilter()
    return "HARMFUL|PLAYER"
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
