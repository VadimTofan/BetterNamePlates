local _, namespace = ...

local Appearance = {}

function Appearance:GetTargetAlpha()
    return 1
end

function Appearance:GetHealthColorKey(
    classification,
    isKnownCaster,
    threatState
)
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
