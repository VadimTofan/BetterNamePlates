Describe("Runtime diagnostics", function()
    It("reports active plate count and the last admission result", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        runtime.activePlates = {
            nameplate1 = {},
            nameplate2 = {},
        }
        runtime.lastAddResult = "not-attackable:nameplate3"

        -- When
        local state = runtime:GetDebugState()

        -- Then
        ExpectEqual(state.activePlateCount, 2)
        ExpectEqual(state.lastAddResult, "not-attackable:nameplate3")
    end)

    It("hides and restores Blizzard unit and aura frames", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local unitAlpha = 0.8
        local auraAlpha = 0.6
        local view = {
            blizzardUnitFrame = {
                GetAlpha = function()
                    return unitAlpha
                end,
                SetAlpha = function(_, value)
                    unitAlpha = value
                end,
                AurasFrame = {
                    GetAlpha = function()
                        return auraAlpha
                    end,
                    SetAlpha = function(_, value)
                        auraAlpha = value
                    end,
                },
            },
        }

        -- When
        runtime:SetBlizzardFrameHidden(view, true)
        local hiddenUnitAlpha = unitAlpha
        local hiddenAuraAlpha = auraAlpha
        runtime:SetBlizzardFrameHidden(view, false)

        -- Then
        ExpectEqual(hiddenUnitAlpha, 0)
        ExpectEqual(hiddenAuraAlpha, 0)
        ExpectEqual(unitAlpha, 0.8)
        ExpectEqual(auraAlpha, 0.6)
    end)
end)
