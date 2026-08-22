Describe("Profile unit coloring", function()
    local namespace = {}
    local appearance = LoadAddonFile("Appearance.lua", namespace)

    It("uses the caster color for known casters without aggro", function()
        -- Given
        local classification = "normal"
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
end)
