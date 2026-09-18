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

    It("ignores the realm returned alongside a unit name", function()
        -- Given
        local function getCrossRealmName()
            return "Softcore", "Dragonmaw"
        end

        -- When
        local result = displayText:ShortenName(getCrossRealmName())

        -- Then
        ExpectEqual(result, "Soft…")
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

    It("appends compact classification suffixes on Classic clients", function()
        -- Given
        local flavors = {"vanilla", "forever", "tbc", "mists"}
        local classifications = {
            elite = " (E)",
            rare = " (R)",
            rareelite = " (RE)",
        }

        -- When
        local results = {}

        for _, flavor in ipairs(flavors) do
            results[flavor] = {}

            for classification in pairs(classifications) do
                results[flavor][classification] =
                    displayText:AppendClassification(
                        "Blackrock Worg",
                        classification,
                        flavor,
                        function()
                            return false
                        end
                    )
            end
        end

        -- Then
        for _, flavor in ipairs(flavors) do
            for classification, suffix in pairs(classifications) do
                ExpectEqual(
                    results[flavor][classification],
                    "Blackrock Worg" .. suffix
                )
            end
        end
    end)

    It("keeps other classifications unchanged on Classic clients", function()
        -- Given
        local name = "Blackrock Worg"

        -- When
        local normal = displayText:AppendClassification(
            name,
            "normal",
            "vanilla"
        )
        local worldboss = displayText:AppendClassification(
            name,
            "worldboss",
            "vanilla"
        )

        -- Then
        ExpectEqual(normal, name)
        ExpectEqual(worldboss, name)
    end)

    It("keeps Retail names unchanged", function()
        -- Given
        local name = "Blackrock Worg"

        -- When
        local result = displayText:AppendClassification(
            name,
            "elite",
            "retail"
        )

        -- Then
        ExpectEqual(result, name)
    end)
end)
