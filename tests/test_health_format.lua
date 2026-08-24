Describe("Profile health formatting", function()
    local namespace = {}
    local healthFormat = LoadAddonFile("HealthFormat.lua", namespace)

    It("delegates NPC health to Blizzard's abbreviator", function()
        -- Given
        local health = 6500000
        local function abbreviate(value)
            ExpectEqual(value, health)
            return "6.5M"
        end

        -- When
        local displayedHealth = healthFormat:FormatHealth(
            health,
            abbreviate
        )

        -- Then
        ExpectEqual(displayedHealth, "6.5M")
    end)

    It("formats health percentages separately", function()
        -- Given
        local health = 87500
        local maximum = 100000

        -- When
        local text = healthFormat:FormatPercentage(health, maximum)

        -- Then
        ExpectEqual(text, "87.5%")
    end)

    It("delegates protected health without inspecting it", function()
        -- Given
        local health = 87500
        local maximum = 100000
        local function abbreviate(value)
            ExpectEqual(value, health)
            return "87.5K"
        end

        -- When
        local text = healthFormat:FormatHealth(health, abbreviate)

        -- Then
        ExpectEqual(text, "87.5K")
    end)

    It("formats restricted percentages separately", function()
        -- Given
        local percentage = 100

        -- When
        local text = healthFormat:FormatRestrictedPercentage(percentage)

        -- Then
        ExpectEqual(text, "100.0%")
    end)

    It("requests restricted percentages with the scale-to-100 curve", function()
        -- Given
        local requestedUnit
        local requestedPredicted
        local requestedCurve
        local scaleCurve = {}
        local function unitHealthPercent(unit, predicted, curve)
            requestedUnit = unit
            requestedPredicted = predicted
            requestedCurve = curve
            return 100
        end

        -- When
        local percentage = healthFormat:GetRestrictedPercentage(
            "nameplate1",
            unitHealthPercent,
            scaleCurve
        )

        -- Then
        ExpectEqual(percentage, 100)
        ExpectEqual(requestedUnit, "nameplate1")
        ExpectEqual(requestedPredicted, true)
        ExpectEqual(requestedCurve, scaleCurve)
    end)
end)
