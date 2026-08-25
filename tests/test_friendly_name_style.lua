Describe("FriendlyNameStyle", function()
    local namespace = {
        Config = {
            nameFont = "Expressway.ttf",
            nameFontSize = 10,
            friendlyNameFontScale = 2,
            expresswayFontFlags = "OUTLINE",
        },
        DisplayText = {
            SafeValue = function(_, value, fallback)
                if value == nil then
                    return fallback
                end

                return value
            end,
        },
    }
    local style = LoadAddonFile("FriendlyNameStyle.lua", namespace)

    It("selects only friendly player nameplates", function()
        -- Given
        local friendlyPlayer = {isPlayer = true, canAttack = false}
        local hostilePlayer = {isPlayer = true, canAttack = true}
        local friendlyNpc = {isPlayer = false, canAttack = false}

        -- When
        local shouldStyleFriendly = style:ShouldStyle(friendlyPlayer)
        local shouldStyleHostile = style:ShouldStyle(hostilePlayer)
        local shouldStyleNpc = style:ShouldStyle(friendlyNpc)

        -- Then
        ExpectEqual(shouldStyleFriendly, true)
        ExpectEqual(shouldStyleHostile, false)
        ExpectEqual(shouldStyleNpc, false)
    end)

    It("uses the configured Expressway presentation", function()
        -- Given
        local expectedFont = namespace.Config.nameFont

        -- When
        local presentation = style:GetPresentation()

        -- Then
        ExpectEqual(presentation.font, expectedFont)
        ExpectEqual(presentation.fontSize, 20)
        ExpectEqual(presentation.fontFlags, "OUTLINE")
    end)

    It("uses Blizzard name-only class-colored friendly player CVars", function()
        -- Given
        local applied = {}

        -- When
        style:ApplyNativeCVars(function(name, value)
            applied[name] = value
        end)

        -- Then
        ExpectEqual(
            applied.nameplateShowOnlyNameForFriendlyPlayerUnits,
            1
        )
        ExpectEqual(
            applied.nameplateUseClassColorForFriendlyPlayerUnitNames,
            1
        )
        ExpectEqual(applied.nameplateShowFriendlyRealmName, 0)
    end)

    It("applies and restores Expressway through shared font objects", function()
        -- Given
        local currentFont = "Blizzard.ttf"
        local currentSize = 9
        local currentFlags = ""
        local fontObject = {
            GetFont = function()
                return currentFont, currentSize, currentFlags
            end,
            SetFont = function(_, font, size, flags)
                currentFont = font
                currentSize = size
                currentFlags = flags
            end,
        }

        -- When
        style:ApplyFontObjects({fontObject})
        local appliedFont = currentFont
        local appliedSize = currentSize
        local appliedFlags = currentFlags
        style:RestoreFontObjects()

        -- Then
        ExpectEqual(appliedFont, "Expressway.ttf")
        ExpectEqual(appliedSize, 20)
        ExpectEqual(appliedFlags, "OUTLINE")
        ExpectEqual(currentFont, "Blizzard.ttf")
        ExpectEqual(currentSize, 9)
        ExpectEqual(currentFlags, "")
    end)
end)
