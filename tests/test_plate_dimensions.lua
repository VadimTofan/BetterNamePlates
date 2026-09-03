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

    It("maps persisted name level five to the default font size", function()
        -- Given
        local config = {
            healthWidth = 135,
            healthHeight = 13.6,
            nameFontSize = 10,
        }
        local saved = {name = 5}

        -- When
        dimensions:ApplySaved(saved, config)

        -- Then
        ExpectEqual(config.nameFontSize, 10)
    end)

    It("maps name levels one through ten around the default", function()
        -- Given
        local smallSaved = {}
        local largeSaved = {}

        -- When
        local small = dimensions:ApplyCommand("name 1", smallSaved)
        local large = dimensions:ApplyCommand("name 10", largeSaved)

        -- Then
        ExpectEqual(small.changed, true)
        ExpectEqual(large.changed, true)
        ExpectEqual(smallSaved.name, 1)
        ExpectEqual(largeSaved.name, 10)
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

    It("rejects invalid name levels", function()
        -- Given
        local saved = {}

        -- When
        local below = dimensions:ApplyCommand("name 0", saved)
        local above = dimensions:ApplyCommand("name 11", saved)
        local fraction = dimensions:ApplyCommand("name 5.5", saved)

        -- Then
        ExpectEqual(below.changed, false)
        ExpectEqual(above.changed, false)
        ExpectEqual(fraction.changed, false)
        ExpectEqual(saved.name, nil)
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
        local saved = {width = 150, height = 16, name = 8}

        -- When
        local result = dimensions:ApplyCommand("reset", saved)

        -- Then
        ExpectEqual(result.changed, true)
        ExpectEqual(saved.width, nil)
        ExpectEqual(saved.height, nil)
        ExpectEqual(saved.name, nil)
    end)
end)
