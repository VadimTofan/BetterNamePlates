Describe("PlateDimensions", function()
    local namespace = {}
    local dimensions = LoadAddonFile("PlateDimensions.lua", namespace)

    It("applies persisted dimensions over profile defaults", function()
        -- Given
        local config = {healthWidth = 135, healthHeight = 13.6}
        local saved = {width = 150, height = 16}

        -- When
        dimensions:ApplySaved(saved, config)

        -- Then
        ExpectEqual(config.healthWidth, 150)
        ExpectEqual(config.healthHeight, 16)
    end)

    It("parses width and height commands within safe ranges", function()
        -- Given
        local saved = {}

        -- When
        local width = dimensions:ApplyCommand("width 150", saved)
        local height = dimensions:ApplyCommand("height 16", saved)

        -- Then
        ExpectEqual(width.changed, true)
        ExpectEqual(height.changed, true)
        ExpectEqual(saved.width, 150)
        ExpectEqual(saved.height, 16)
    end)

    It("rejects dimensions outside safe ranges", function()
        -- Given
        local saved = {}

        -- When
        local width = dimensions:ApplyCommand("width 20", saved)
        local height = dimensions:ApplyCommand("height 100", saved)

        -- Then
        ExpectEqual(width.changed, false)
        ExpectEqual(height.changed, false)
        ExpectEqual(saved.width, nil)
        ExpectEqual(saved.height, nil)
    end)

    It("discards invalid persisted dimensions", function()
        -- Given
        local config = {healthWidth = 135, healthHeight = 13.6}
        local saved = {width = "huge", height = 100}

        -- When
        dimensions:ApplySaved(saved, config)

        -- Then
        ExpectEqual(config.healthWidth, 135)
        ExpectEqual(config.healthHeight, 13.6)
        ExpectEqual(saved.width, nil)
        ExpectEqual(saved.height, nil)
    end)

    It("resets both dimensions to profile defaults", function()
        -- Given
        local saved = {width = 150, height = 16}

        -- When
        local result = dimensions:ApplyCommand("reset", saved)

        -- Then
        ExpectEqual(result.changed, true)
        ExpectEqual(saved.width, nil)
        ExpectEqual(saved.height, nil)
    end)
end)
