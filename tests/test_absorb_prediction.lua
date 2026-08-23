Describe("Enemy absorb prediction", function()
    It("configures and applies absorb values without arithmetic", function()
        -- Given
        local namespace = {}
        local absorbPrediction = LoadAddonFile(
            "AbsorbPrediction.lua",
            namespace
        )
        local calls = {}
        local calculator = {
            SetDamageAbsorbClampMode = function(_, value)
                calls.damageClamp = value
            end,
            SetHealAbsorbClampMode = function(_, value)
                calls.healClamp = value
            end,
            SetHealAbsorbMode = function(_, value)
                calls.healMode = value
            end,
            SetIncomingHealClampMode = function(_, value)
                calls.incomingClamp = value
            end,
            SetIncomingHealOverflowPercent = function(_, value)
                calls.overflow = value
            end,
            SetMaximumHealthMode = function(_, value)
                calls.maximumMode = value
            end,
            GetCurrentHealth = function()
                return "secret-health"
            end,
            GetMaximumDamageAbsorbs = function()
                return "secret-maximum"
            end,
            GetDamageAbsorbs = function()
                return "secret-absorb"
            end,
        }
        local healthBar = {
            SetMinMaxValues = function(_, minimum, maximum, interpolation)
                calls.healthRange = {minimum, maximum, interpolation}
            end,
            SetValue = function(_, value, interpolation)
                calls.healthValue = {value, interpolation}
            end,
        }
        local absorbBar = {
            SetAlpha = function(_, value)
                calls.absorbAlpha = value
            end,
            SetMinMaxValues = function(_, minimum, maximum, interpolation)
                calls.absorbRange = {minimum, maximum, interpolation}
            end,
            SetValue = function(_, value, interpolation)
                calls.absorbValue = {value, interpolation}
            end,
        }
        local api = {
            predict = function(unit, healer, receivedCalculator)
                calls.prediction = {unit, healer, receivedCalculator}
            end,
            enums = {
                maximumHealthWithAbsorbs = "with-absorbs",
                maximumHealthClamp = "maximum-health",
                missingHealthClamp = "missing-health",
                healAbsorbMaximumHealth = "heal-maximum",
                healAbsorbTotal = "heal-total",
                incomingHealMissingHealth = "incoming-missing",
                immediate = "immediate",
            },
        }

        -- When
        absorbPrediction:Configure(calculator, api.enums)
        absorbPrediction:Update(
            "nameplate4",
            calculator,
            healthBar,
            absorbBar,
            api
        )

        -- Then
        ExpectEqual(calls.prediction[1], "nameplate4")
        ExpectEqual(calls.prediction[3], calculator)
        ExpectEqual(calls.maximumMode, "with-absorbs")
        ExpectEqual(calls.damageClamp, "missing-health")
        ExpectEqual(calls.healthRange[2], "secret-maximum")
        ExpectEqual(calls.healthValue[1], "secret-health")
        ExpectEqual(calls.absorbRange[2], "secret-maximum")
        ExpectEqual(calls.absorbValue[1], "secret-absorb")
        ExpectEqual(calls.absorbAlpha, "secret-absorb")
    end)
end)
