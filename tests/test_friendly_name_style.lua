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
        local nativeFrameAlpha = 0.7
        local appliedFont
        local appliedAlpha
        local frameAlpha = nativeFrameAlpha
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
            ClearAllPoints = function() end,
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
            GetAlpha = function()
                return frameAlpha
            end,
            SetAlpha = function(_, alpha)
                frameAlpha = alpha
            end,
        }
        local basePlate = {
            CreateFontString = function()
                return bold
            end,
        }

        -- When
        local view = style:Apply(basePlate, unitFrame, "Friendly")
        local expresswayFont = appliedFont[1]
        local hiddenAlpha = appliedAlpha
        local hiddenFrameAlpha = frameAlpha
        style:Restore(view)

        -- Then
        ExpectEqual(expresswayFont, namespace.Config.nameFont)
        ExpectEqual(hiddenAlpha, 0)
        ExpectEqual(hiddenFrameAlpha, 0)
        ExpectEqual(appliedAlpha, nativeAlpha)
        ExpectEqual(frameAlpha, nativeFrameAlpha)
        ExpectEqual(boldText, "Friendly")
        ExpectEqual(appliedFont[1], nativeFont)
        ExpectEqual(appliedFont[2], nativeSize)
        ExpectEqual(appliedFont[3], nativeFlags)
        ExpectEqual(boldHidden, true)
    end)

    It("centers the custom name on the base nameplate", function()
        -- Given
        local anchor
        local bold = {
            ClearAllPoints = function() end,
            SetFont = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetPoint = function(_, ...)
                anchor = {...}
            end,
            SetText = function() end,
            SetTextColor = function() end,
            Show = function() end,
        }
        local name = {
            GetAlpha = function()
                return 1
            end,
            GetFont = function()
                return "Blizzard.ttf", 9, ""
            end,
            GetJustifyH = function()
                return "LEFT"
            end,
            GetJustifyV = function()
                return "MIDDLE"
            end,
            GetTextColor = function()
                return 1, 1, 1, 1
            end,
            SetAlpha = function() end,
            SetFont = function() end,
        }
        local unitFrame = {
            name = name,
            GetAlpha = function()
                return 1
            end,
            SetAlpha = function() end,
        }
        local basePlate = {
            CreateFontString = function()
                return bold
            end,
        }

        -- When
        style:Apply(basePlate, unitFrame, "Friendly")

        -- Then
        ExpectEqual(anchor[1], "CENTER")
        ExpectEqual(anchor[2], basePlate)
        ExpectEqual(anchor[3], "CENTER")
        ExpectEqual(anchor[4], 0)
        ExpectEqual(anchor[5], 0)
    end)

    It("uses an explicit player class color", function()
        -- Given
        local appliedColor
        local bold = {
            ClearAllPoints = function() end,
            SetFont = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetPoint = function() end,
            SetText = function() end,
            SetTextColor = function(_, ...)
                appliedColor = {...}
            end,
            Show = function() end,
        }
        local name = {
            GetAlpha = function()
                return 1
            end,
            GetFont = function()
                return "Blizzard.ttf", 9, ""
            end,
            GetTextColor = function()
                return 1, 1, 1, 1
            end,
            SetAlpha = function() end,
            SetFont = function() end,
        }
        local unitFrame = {
            name = name,
            GetAlpha = function()
                return 1
            end,
            SetAlpha = function() end,
        }
        local basePlate = {
            CreateFontString = function()
                return bold
            end,
        }
        local classColor = {r = 0.2, g = 0.8, b = 0.4}

        -- When
        local view = style:Apply(
            basePlate,
            unitFrame,
            "Friendly",
            classColor
        )
        style:Suppress(view)

        -- Then
        ExpectEqual(appliedColor[1], 0.2)
        ExpectEqual(appliedColor[2], 0.8)
        ExpectEqual(appliedColor[3], 0.4)
        ExpectEqual(appliedColor[4], 1)
    end)

    It("re-hides a Blizzard friendly frame after it becomes visible", function()
        -- Given
        local frameAlpha = 1
        local appliedColor
        local view = {
            bold = {
                SetTextColor = function(_, ...)
                    appliedColor = {...}
                end,
            },
            name = {
                GetTextColor = function()
                    return 0.25, 0.5, 0.75, 1
                end,
            },
            unitFrame = {
                SetAlpha = function(_, alpha)
                    frameAlpha = alpha
                end,
            },
        }

        -- When
        style:Suppress(view)

        -- Then
        ExpectEqual(frameAlpha, 0)
        ExpectEqual(appliedColor[1], 0.25)
        ExpectEqual(appliedColor[2], 0.5)
        ExpectEqual(appliedColor[3], 0.75)
        ExpectEqual(appliedColor[4], 1)
    end)

    It("suppresses a replacement Blizzard unit frame", function()
        -- Given
        local originalAlpha = 0
        local replacementAlpha = 1
        local originalFrame = {
            SetAlpha = function(_, alpha)
                originalAlpha = alpha
            end,
        }
        local replacementFrame = {
            SetAlpha = function(_, alpha)
                replacementAlpha = alpha
            end,
        }
        local view = {
            basePlate = {
                UnitFrame = replacementFrame,
            },
            bold = {
                SetTextColor = function() end,
            },
            name = {
                GetTextColor = function()
                    return 1, 1, 1, 1
                end,
            },
            unitFrame = originalFrame,
        }

        -- When
        style:Suppress(view)

        -- Then
        ExpectEqual(originalAlpha, 0)
        ExpectEqual(replacementAlpha, 0)
    end)

    It("moves the Blizzard frame under a hidden parent and restores it", function()
        -- Given
        local originalParent = {}
        local hiddenParent = {}
        local currentParent = originalParent
        local widgetParent
        local widget = {
            SetParent = function(_, parent)
                widgetParent = parent
            end,
        }
        local name = {
            GetAlpha = function()
                return 1
            end,
            GetFont = function()
                return "Blizzard.ttf", 9, ""
            end,
            GetTextColor = function()
                return 0.2, 0.4, 0.6, 1
            end,
            SetAlpha = function() end,
            SetFont = function() end,
        }
        local unitFrame = {
            WidgetContainer = widget,
            name = name,
            GetAlpha = function()
                return 1
            end,
            GetParent = function()
                return currentParent
            end,
            SetAlpha = function() end,
            SetParent = function(_, parent)
                currentParent = parent
            end,
        }
        local bold = {
            ClearAllPoints = function() end,
            Hide = function() end,
            SetFont = function() end,
            SetJustifyH = function() end,
            SetJustifyV = function() end,
            SetPoint = function() end,
            SetText = function() end,
            SetTextColor = function() end,
            Show = function() end,
        }
        local basePlate = {
            CreateFontString = function()
                return bold
            end,
        }

        -- When
        local view = style:Apply(
            basePlate,
            unitFrame,
            "Friendly",
            nil,
            hiddenParent
        )
        local hiddenFrameParent = currentParent
        local visibleWidgetParent = widgetParent
        style:Restore(view)

        -- Then
        ExpectEqual(hiddenFrameParent, hiddenParent)
        ExpectEqual(visibleWidgetParent, basePlate)
        ExpectEqual(currentParent, originalParent)
        ExpectEqual(widgetParent, unitFrame)
    end)

    It("reuses the bold layer on recycled Blizzard frames", function()
        -- Given
        local created = 0
        local bold = {
            ClearAllPoints = function() end,
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
            GetAlpha = function()
                return 1
            end,
            SetAlpha = function() end,
        }
        local basePlate = {
            CreateFontString = function()
                created = created + 1
                return bold
            end,
        }

        -- When
        style:Apply(basePlate, unitFrame, "First")
        style:Apply(basePlate, unitFrame, "Second")

        -- Then
        ExpectEqual(created, 1)
    end)
end)
