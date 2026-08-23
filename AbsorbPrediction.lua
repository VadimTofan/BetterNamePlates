local _, namespace = ...

local AbsorbPrediction = {}

function AbsorbPrediction:Configure(calculator, enums)
    calculator:SetDamageAbsorbClampMode(enums.maximumHealthClamp)
    calculator:SetHealAbsorbClampMode(enums.healAbsorbMaximumHealth)
    calculator:SetHealAbsorbMode(enums.healAbsorbTotal)
    calculator:SetIncomingHealClampMode(enums.incomingHealMissingHealth)
    calculator:SetIncomingHealOverflowPercent(1)
end

function AbsorbPrediction:Update(
    unit,
    calculator,
    healthBar,
    absorbBar,
    api,
    snapshot,
    shouldCapture
)
    api.predict(unit, nil, calculator)

    calculator:SetMaximumHealthMode(
        api.enums.defaultMaximumHealth
    )
    calculator:SetDamageAbsorbClampMode(
        api.enums.maximumHealthClamp
    )

    local currentHealth = calculator:GetCurrentHealth()
    local maximumHealth = calculator:GetMaximumHealth()

    healthBar:SetMinMaxValues(
        0,
        maximumHealth,
        api.enums.immediate
    )
    healthBar:SetValue(currentHealth, api.enums.immediate)

    calculator:SetDamageAbsorbClampMode(
        api.enums.missingHealthClamp
    )

    local absorbAmount = calculator:GetTotalDamageAbsorbs()

    if shouldCapture and not snapshot.captured then
        snapshot.maximum = absorbAmount
        snapshot.captured = true
    end

    local maximumAbsorb = snapshot.maximum or absorbAmount

    absorbBar:SetAlpha(absorbAmount)
    absorbBar:SetMinMaxValues(
        0,
        maximumAbsorb,
        api.enums.immediate
    )
    absorbBar:SetValue(absorbAmount, api.enums.immediate)
end

namespace.AbsorbPrediction = AbsorbPrediction

return AbsorbPrediction
