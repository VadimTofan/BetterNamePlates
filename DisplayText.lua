local _, namespace = ...

local DisplayText = {}

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

namespace.DisplayText = DisplayText

return DisplayText
