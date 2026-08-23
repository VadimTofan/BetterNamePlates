Describe("Profile unit coloring", function()
    local namespace = {}
    local appearance = LoadAddonFile("Appearance.lua", namespace)

    It("uses the caster color for known casters without aggro", function()
        -- Given
        local classification = "elite"
        local isKnownCaster = true
        local threatState = "safe"

        -- When
        local colorKey = appearance:GetHealthColorKey(
            classification,
            isKnownCaster,
            threatState
        )

        -- Then
        ExpectEqual(colorKey, "caster")
    end)

    It("uses red for ordinary hostile mobs without aggro", function()
        -- Given
        local classification = "normal"
        local isKnownCaster = false
        local threatState = "safe"

        -- When
        local colorKey = appearance:GetHealthColorKey(
            classification,
            isKnownCaster,
            threatState
        )

        -- Then
        ExpectEqual(colorKey, "safe")
    end)

    It("uses neutral yellow before existing classification colors", function()
        -- Given
        local isIdleNeutral = true

        -- When
        local colorKey = appearance:GetHealthColorKey(
            "rareelite",
            true,
            "safe",
            isIdleNeutral
        )

        -- Then
        ExpectEqual(colorKey, "neutral")
    end)

    It("keeps the caster color under secure tank threat", function()
        -- Given
        local classification = "normal"
        local isKnownCaster = true
        local threatState = "secure"

        -- When
        local colorKey = appearance:GetHealthColorKey(
            classification,
            isKnownCaster,
            threatState
        )

        -- Then
        ExpectEqual(colorKey, "caster")
    end)

    It("uses the miniboss color for rare elites", function()
        -- Given
        local classification = "rareelite"

        -- When
        local colorKey = appearance:GetHealthColorKey(
            classification,
            false,
            "safe"
        )

        -- Then
        ExpectEqual(colorKey, "miniboss")
    end)

    It("keeps threat colors when the unit has aggro", function()
        -- Given
        local threatState = "aggro"

        -- When
        local colorKey = appearance:GetHealthColorKey(
            "normal",
            true,
            threatState
        )

        -- Then
        ExpectEqual(colorKey, "aggro")
    end)

    It("keeps non-targeted plates fully opaque", function()
        -- Given
        local isTarget = false

        -- When
        local alpha = appearance:GetTargetAlpha(isTarget)

        -- Then
        ExpectEqual(alpha, 1)
    end)

    It("matches the profile focus overlay without resizing or fading", function()
        -- Given
        local isFocus = true

        -- When
        local style = appearance:GetFocusStyle(isFocus)

        -- Then
        ExpectEqual(style.alpha, 1)
        ExpectEqual(style.overlayAlpha, 1)
        ExpectEqual(style.borderColorKey, "focus")
        ExpectEqual(style.desaturated, false)
    end)

    It("keeps ordinary units visually unchanged by focus styling", function()
        -- Given
        local isFocus = false

        -- When
        local style = appearance:GetFocusStyle(isFocus)

        -- Then
        ExpectEqual(style.alpha, 1)
        ExpectEqual(style.overlayAlpha, 0)
        ExpectEqual(style.borderColorKey, "border")
        ExpectEqual(style.desaturated, false)
    end)

    It("lets current target styling override focus styling", function()
        -- Given
        local isFocus = true
        local isTarget = true

        -- When
        local style = appearance:GetFocusStyle(isFocus, isTarget)

        -- Then
        ExpectEqual(style.alpha, 1)
        ExpectEqual(style.overlayAlpha, 0)
        ExpectEqual(style.borderColorKey, "border")
        ExpectEqual(style.desaturated, false)
    end)
end)
