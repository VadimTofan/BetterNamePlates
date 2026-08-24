Describe("Restricted display text", function()
    local namespace = {
        Config = {
            nameMaxLength = 5,
        },
    }
    local displayText = LoadAddonFile("DisplayText.lua", namespace)

    It("passes secret names through without inspecting them", function()
        -- Given
        local name = "Restricted Name"
        local function isSecret(value)
            return value == name
        end

        -- When
        local result = displayText:ShortenName(name, isSecret)

        -- Then
        ExpectEqual(result, name)
    end)

    It("keeps names within the configured length unchanged", function()
        -- Given
        local name = "Imp"

        -- When
        local result = displayText:ShortenName(name, function()
            return false
        end)

        -- Then
        ExpectEqual(result, "Imp")
    end)

    It("shortens ordinary names to the configured length", function()
        -- Given
        local name = "Ordinary Name"

        -- When
        local result = displayText:ShortenName(name, function()
            return false
        end)

        -- Then
        ExpectEqual(result, "Ordi…")
    end)

    It("replaces secret decision values with a safe fallback", function()
        -- Given
        local value = 3
        local function isSecret(candidate)
            return candidate == value
        end

        -- When
        local result = displayText:SafeValue(value, nil, isSecret)

        -- Then
        ExpectEqual(result, nil)
    end)
end)
