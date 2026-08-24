Describe("Fixed Jundies presentation", function()
    It("uses the exported hostile plate dimensions", function()
        -- Given
        local namespace = {}

        -- When
        local config = LoadAddonFile("Config.lua", namespace)

        -- Then
        ExpectEqual(config.healthWidth, 135)
        ExpectEqual(config.healthHeight, 13.6)
        ExpectEqual(config.targetHealthScale, 1.25)
        ExpectEqual(config.plateOffsetY, -20)
        ExpectEqual(config.contentPadding, 3)
        ExpectEqual(config.targetBorderThickness, 2)
        ExpectEqual(config.targetArrowWidth, 20)
        ExpectEqual(config.targetArrowHeight, 20)
        ExpectEqual(config.targetArrowX, -10)
        ExpectEqual(config.targetArrowScale, 0.7)
        ExpectEqual(config.targetArrowHeightScale, 1.36)
        ExpectEqual(
            config.targetArrowTexture,
            "Interface\\AddOns\\BetterNamePlates\\media\\arrow_double_right_64"
        )
        ExpectEqual(config.colors.target[1], 0.9921568627451)
        ExpectEqual(config.castHeight, 11.2)
        ExpectEqual(config.castGap, 0)
        ExpectEqual(config.castRefreshInterval, 0.05)
        ExpectEqual(config.frameSuppressionInterval, 0.3)
        ExpectEqual(config.castIconSize, 11.2)
        ExpectEqual(config.castIconGap, 1)
        ExpectEqual(config.castMarkerWidth, 2)
        ExpectEqual(config.castMarkerMaximumProgress, 0.95)
        ExpectEqual(config.castTextLeftPadding, 4)
        ExpectEqual(config.castTextBottomPadding, 2)
        ExpectEqual(config.castTimeRightPadding, 1)
        ExpectEqual(config.castTimeBottomPadding, 2)
        ExpectEqual(config.castFontSize, 8.1)
        ExpectEqual(config.auraIconSize, 18)
        ExpectEqual(config.debuffScale, 1.0)
        ExpectEqual(config.auraFontSize, 10)
        ExpectEqual(config.colors.auraTimer[1], 1)
        ExpectEqual(config.colors.auraTimer[2], 0.960784)
        ExpectEqual(config.colors.auraTimer[3], 0.070588)
        ExpectEqual(config.colors.interruptReadyCast[1], 1)
        ExpectEqual(config.colors.interruptReadyCast[2], 0.96078437566757)
        ExpectEqual(config.colors.interruptUnavailableCast[2], 0.49411767721176)
        ExpectEqual(config.colors.interruptMarker[2], 1)
        ExpectEqual(config.colors.protectedCast[1], 0.5)
        ExpectEqual(config.colors.protectedCast[2], 0.5)
        ExpectEqual(config.colors.protectedCast[3], 0.5)
        ExpectEqual(config.scale, 1.1)
        ExpectEqual(config.nameMaxLength, 16)
        ExpectEqual(config.nameFontSize, 10)
        ExpectEqual(config.nameFontFlags, "")
        ExpectEqual(config.nameBoldOffset, 0.5)
        ExpectEqual(config.nameOutlineThickness, 0.5)
        ExpectEqual(config.nameOutlineColor[1], 0)
        ExpectEqual(config.nameOutlineColor[4], 1)
        ExpectEqual(
            config.nameFont,
            "Interface\\AddOns\\BetterNamePlates\\media\\fonts\\Expressway.ttf"
        )
        ExpectEqual(
            config.healthFont,
            "Interface\\AddOns\\BetterNamePlates\\media\\fonts\\Expressway.ttf"
        )
        ExpectEqual(
            config.castFont,
            "Interface\\AddOns\\BetterNamePlates\\media\\fonts\\Expressway.ttf"
        )
        ExpectEqual(config.borderThickness, 1.2)
        ExpectEqual(config.healthOutlineThickness, 1)
        ExpectEqual(config.healthInset, 1)
        ExpectEqual(config.healthRightExtension, 1)
        ExpectEqual(config.healthOrientation, "HORIZONTAL")
        ExpectEqual(config.healthReverseFill, false)
        ExpectEqual(config.absorbInset, 1)
        ExpectEqual(config.absorbOrientation, "HORIZONTAL")
        ExpectEqual(config.absorbReverseFill, false)
        ExpectEqual(config.absorbOpacity, 0.75)
        ExpectEqual(config.healthMarkerWidth, 1)
        ExpectEqual(config.colors.healthMarker[1], 1)
        ExpectEqual(config.colors.healthMarker[2], 1)
        ExpectEqual(config.colors.healthMarker[3], 1)
        ExpectEqual(config.colors.healthMarker[4], 1)
        ExpectEqual(config.absorbMaximumHealthMode, "WithAbsorbs")
        ExpectEqual(
            config.absorbTexture,
            "Interface\\AddOns\\BetterNamePlates\\media\\absorb_gradient"
        )
        ExpectEqual(config.texture, "Interface\\Buttons\\WHITE8X8")
        ExpectEqual(config.font, "Fonts\\ARIALN.TTF")
        ExpectEqual(config.hideBlizzardFrame, true)
        ExpectEqual(config.colors.safe[1], 0.745098)
        ExpectEqual(config.colors.safe[2], 0.188235)
        ExpectEqual(config.colors.neutral[1], 1)
        ExpectEqual(config.colors.neutral[2], 0.82)
        ExpectEqual(config.colors.neutral[3], 0)
        ExpectEqual(config.colors.caster[2], 0.8196)
        ExpectEqual(config.colors.miniboss[1], 0.576471)
    end)

end)
