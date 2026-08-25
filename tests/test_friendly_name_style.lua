Describe("FriendlyNameStyle", function()
    local namespace = {
        Config = {
            nameFont = "Expressway.ttf",
            nameFontSize = 10,
            friendlyNameFontScale = 2,
            nameFontFlags = "",
            expresswayFontFlags = "OUTLINE",
            nameBoldOffset = 0.5,
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
        local friendlyPlayer = {
            isPlayer = true,
            canAttack = false,
        }
        local hostilePlayer = {
            isPlayer = true,
            canAttack = true,
        }
        local friendlyNpc = {
            isPlayer = false,
            canAttack = false,
        }

        -- When
        local shouldStyleFriendly = style:ShouldStyle(friendlyPlayer)
        local shouldStyleHostile = style:ShouldStyle(hostilePlayer)
        local shouldStyleNpc = style:ShouldStyle(friendlyNpc)

        -- Then
        ExpectEqual(shouldStyleFriendly, true)
        ExpectEqual(shouldStyleHostile, false)
        ExpectEqual(shouldStyleNpc, false)
    end)

    It("uses the configured Expressway bold presentation", function()
        -- Given
        local expectedFont = namespace.Config.nameFont

        -- When
        local presentation = style:GetPresentation()

        -- Then
        ExpectEqual(presentation.font, expectedFont)
        ExpectEqual(presentation.fontSize, 20)
        ExpectEqual(presentation.fontFlags, "OUTLINE")
        ExpectEqual(presentation.boldOffset, 0.5)
    end)

    It("applies and restores friendly name typography", function()
        -- Given
        local nativeFont = "Blizzard.ttf"
        local nativeSize = 9
        local nativeFlags = "OUTLINE"
        local nativeAlpha = 0.8
        local appliedFont
        local appliedAlpha
        local boldHidden = false
        local boldText
        local name = {
            GetFont = function()
                return nativeFont, nativeSize, nativeFlags
            end,
            GetAlpha = function()
                return nativeAlpha
            end,
            GetJustifyH = function()
                return "CENTER"
            end,
            GetJustifyV = function()
                return "MIDDLE"
            end,
            GetTextColor = function()
                return 0.2, 0.4, 0.6, 1
            end,
            SetFont = function(_, font, size, flags)
                appliedFont = {font, size, flags}
            end,
            SetAlpha = function(_, alpha)
                appliedAlpha = alpha
            end,
        }
        local bold = {
            Hide = function()
                boldHidden = true
            end,
            SetFont = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetPoint = function() end,
            Show = function() end,
            SetText = function(_, text)
                boldText = text
            end,
            SetTextColor = function() end,
        }
        local unitFrame = {
            name = name,
            CreateFontString = function()
                return bold
            end,
        }

        -- When
        local view = style:Apply(unitFrame, "Friendly")
        local expresswayFont = appliedFont[1]
        local hiddenAlpha = appliedAlpha
        style:Restore(view)

        -- Then
        ExpectEqual(expresswayFont, namespace.Config.nameFont)
        ExpectEqual(hiddenAlpha, 0)
        ExpectEqual(appliedAlpha, nativeAlpha)
        ExpectEqual(boldText, "Friendly")
        ExpectEqual(appliedFont[1], nativeFont)
        ExpectEqual(appliedFont[2], nativeSize)
        ExpectEqual(appliedFont[3], nativeFlags)
        ExpectEqual(boldHidden, true)
    end)

    It("reuses the bold layer on recycled Blizzard frames", function()
        -- Given
        local created = 0
        local bold = {
            Hide = function() end,
            SetFont = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetPoint = function() end,
            SetText = function() end,
            SetTextColor = function() end,
            Show = function() end,
        }
        local name = {
            GetFont = function()
                return "Blizzard.ttf", 9, ""
            end,
            GetAlpha = function()
                return 1
            end,
            GetJustifyH = function()
                return "CENTER"
            end,
            GetJustifyV = function()
                return "MIDDLE"
            end,
            GetTextColor = function()
                return 1, 1, 1, 1
            end,
            SetFont = function() end,
            SetAlpha = function() end,
        }
        local unitFrame = {
            name = name,
            CreateFontString = function()
                created = created + 1
                return bold
            end,
        }

        -- When
        style:Apply(unitFrame, "First")
        style:Apply(unitFrame, "Second")

        -- Then
        ExpectEqual(created, 1)
    end)
end)
