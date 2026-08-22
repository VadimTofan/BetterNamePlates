Describe("Profile health formatting", function()
    local namespace = {}
    local healthFormat = LoadAddonFile("HealthFormat.lua", namespace)

    It("formats millions with one decimal and percent", function()
        -- Given
        local health = 2400000
        local maximum = 2400000

        -- When
        local text = healthFormat:Format(health, maximum)

        -- Then
        ExpectEqual(text, "2.4M 100.0%")
    end)

    It("formats thousands without unnecessary precision", function()
        -- Given
        local health = 87500
        local maximum = 100000

        -- When
        local text = healthFormat:Format(health, maximum)

        -- Then
        ExpectEqual(text, "87.5K 87.5%")
    end)

    It("does not perform arithmetic on secret health values", function()
        -- Given
        local health = 87500
        local maximum = 100000
        local function isSecret(value)
            return value == health
        end

        -- When
        local text = healthFormat:Format(health, maximum, isSecret)

        -- Then
        ExpectEqual(text, nil)
    end)

    It("formats restricted health through Blizzard-safe values", function()
        -- Given
        local health = 2400000
        local percentage = 100
        local function abbreviate(value)
            ExpectEqual(value, health)
            return "2.4M"
        end

        -- When
        local text = healthFormat:FormatRestricted(
            health,
            percentage,
            abbreviate
        )

        -- Then
        ExpectEqual(text, "2.4M 100.0%")
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
