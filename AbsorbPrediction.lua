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
    api
)
    api.predict(unit, nil, calculator)

    calculator:SetMaximumHealthMode(
        api.enums.maximumHealthWithAbsorbs
    )
    calculator:SetDamageAbsorbClampMode(
        api.enums.maximumHealthClamp
    )

    local currentHealth = calculator:GetCurrentHealth()
    local maximumHealthWithAbsorbs =
        calculator:GetMaximumDamageAbsorbs()

    healthBar:SetMinMaxValues(
        0,
        maximumHealthWithAbsorbs,
        api.enums.immediate
    )
    healthBar:SetValue(currentHealth, api.enums.immediate)

    calculator:SetDamageAbsorbClampMode(
        api.enums.missingHealthClamp
    )

    local absorbAmount = calculator:GetDamageAbsorbs()

    absorbBar:SetAlpha(absorbAmount)
    absorbBar:SetMinMaxValues(
        0,
        maximumHealthWithAbsorbs,
        api.enums.immediate
    )
    absorbBar:SetValue(absorbAmount, api.enums.immediate)
end

namespace.AbsorbPrediction = AbsorbPrediction

return AbsorbPrediction
