local _, namespace = ...

local Appearance = {}

function Appearance:GetTargetAlpha()
    return 1
end

function Appearance:GetFocusStyle(isFocus, isTarget)
    if isFocus and not isTarget then
        return {
            alpha = 1,
            overlayAlpha = 1,
            borderColorKey = "focus",
            desaturated = false,
        }
    end

    return {
        alpha = 1,
        overlayAlpha = 0,
        borderColorKey = "border",
        desaturated = false,
    }
end

function Appearance:GetHealthColorKey(
    classification,
    isKnownCaster,
    threatState,
    isIdleNeutral
)
    if isIdleNeutral then
        return "neutral"
    end

    if threatState == "aggro" or threatState == "contested" or
        threatState == "lost" then
        return threatState
    end

    if classification == "worldboss" then
        return "boss"
    end

    if classification == "rareelite" then
        return "miniboss"
    end

    if isKnownCaster then
        return "caster"
    end

    return threatState
end

namespace.Appearance = Appearance

return Appearance
