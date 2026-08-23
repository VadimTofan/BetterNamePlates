Describe("Enemy absorb prediction", function()
    It("keeps real health visible while absorb drains from its snapshot", function()
        -- Given
        local namespace = {}
        local absorbPrediction = LoadAddonFile(
            "AbsorbPrediction.lua",
            namespace
        )
        local calls = {}
        local currentAbsorb = "initial-absorb"
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
            GetMaximumHealth = function()
                return "secret-maximum-health"
            end,
            GetTotalDamageAbsorbs = function()
                return currentAbsorb
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
                defaultMaximumHealth = "default-health",
                maximumHealthClamp = "maximum-health",
                missingHealthClamp = "missing-health",
                healAbsorbMaximumHealth = "heal-maximum",
                healAbsorbTotal = "heal-total",
                incomingHealMissingHealth = "incoming-missing",
                immediate = "immediate",
            },
        }
        local snapshot = {}

        -- When
        absorbPrediction:Configure(calculator, api.enums)
        absorbPrediction:Update(
            "nameplate4",
            calculator,
            healthBar,
            absorbBar,
            api,
            snapshot,
            true
        )
        currentAbsorb = "remaining-absorb"
        absorbPrediction:Update(
            "nameplate4",
            calculator,
            healthBar,
            absorbBar,
            api,
            snapshot,
            false
        )

        -- Then
        ExpectEqual(calls.prediction[1], "nameplate4")
        ExpectEqual(calls.prediction[3], calculator)
        ExpectEqual(calls.maximumMode, "default-health")
        ExpectEqual(calls.damageClamp, "missing-health")
        ExpectEqual(calls.healthRange[2], "secret-maximum-health")
        ExpectEqual(calls.healthValue[1], "secret-health")
        ExpectEqual(calls.absorbRange[2], "initial-absorb")
        ExpectEqual(calls.absorbValue[1], "remaining-absorb")
        ExpectEqual(calls.absorbAlpha, "remaining-absorb")
        ExpectEqual(snapshot.maximum, "initial-absorb")
        ExpectEqual(snapshot.captured, true)
    end)
end)
