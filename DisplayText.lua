local _, namespace = ...

local DisplayText = {}
local CLASSIC_FLAVORS = {
    forever = true,
    mists = true,
    tbc = true,
    vanilla = true,
}
local CLASSIFICATION_SUFFIXES = {
    elite = " (E)",
    rare = " (R)",
    rareelite = " (RE)",
}

local function defaultSecretCheck(value)
    return issecretvalue and issecretvalue(value)
end

function DisplayText:SafeValue(value, fallback, secretCheck)
    secretCheck = secretCheck or defaultSecretCheck

    if secretCheck(value) then
        return fallback
    end

    return value
end

function DisplayText:ShortenName(name, secretCheck)
    if not name then
        return ""
    end

    if type(secretCheck) ~= "function" then
        secretCheck = defaultSecretCheck
    end

    if secretCheck(name) then
        return name
    end

    if #name <= namespace.Config.nameMaxLength then
        return name
    end

    return name:sub(1, namespace.Config.nameMaxLength - 1) .. "…"
end

function DisplayText:AppendClassification(
    name,
    classification,
    flavor,
    secretCheck
)
    local suffix = CLASSIFICATION_SUFFIXES[classification]

    if not suffix or not CLASSIC_FLAVORS[flavor] then
        return name
    end

    secretCheck = secretCheck or defaultSecretCheck

    if secretCheck(name) then
        return name
    end

    return name .. suffix
end

namespace.DisplayText = DisplayText

return DisplayText
