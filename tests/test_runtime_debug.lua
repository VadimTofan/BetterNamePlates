Describe("Runtime diagnostics", function()
    It("updates lightweight healthbars directly", function()
        -- Given
        local minimum
        local maximum
        local value
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local view = {
            health = {
                SetMinMaxValues = function(_, receivedMinimum, receivedMaximum)
                    minimum = receivedMinimum
                    maximum = receivedMaximum
                end,
                SetValue = function(_, receivedValue)
                    value = receivedValue
                end,
            },
        }

        -- When
        runtime:UpdateHealthValues(
            "nameplate1",
            view,
            75,
            100
        )

        -- Then
        ExpectEqual(minimum, 0)
        ExpectEqual(maximum, 100)
        ExpectEqual(value, 75)
    end)

    It("reuses released lightweight nameplates", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local created = 0
        local pooledView = {
            blizzardAlpha = 0.75,
            blizzardAurasAlpha = 0.5,
            Hide = function()
            end,
            SetParent = function()
            end,
        }

        -- When
        runtime:ReleaseLightweightView(pooledView)
        local acquired = runtime:AcquireLightweightView(function()
            created = created + 1
            return {}
        end)

        -- Then
        ExpectEqual(acquired, pooledView)
        ExpectEqual(created, 0)
        ExpectEqual(#runtime.lightweightPool, 0)
        ExpectEqual(acquired.blizzardAlpha, nil)
        ExpectEqual(acquired.blizzardAurasAlpha, nil)
    end)

    It("releases all nameplate data for a loading screen", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local removed = {}
        local collected = false
        runtime.activePlates = {
            nameplate1 = {},
            nameplate2 = {},
        }
        runtime.activeCasts = {
            nameplate1 = {},
        }
        runtime.RemovePlate = function(self, unit)
            removed[unit] = true
            self.activePlates[unit] = nil
        end

        -- When
        runtime:ReleaseForLoadingScreen(function()
            collected = true
        end)

        -- Then
        ExpectEqual(removed.nameplate1, true)
        ExpectEqual(removed.nameplate2, true)
        ExpectEqual(next(runtime.activePlates), nil)
        ExpectEqual(next(runtime.activeCasts), nil)
        ExpectEqual(collected, true)
    end)

    It("tracks only nameplates with active casts", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local castingView = {}
        local idleView = {}

        -- When
        runtime:SetCastActive("nameplate1", castingView, true)
        runtime:SetCastActive("nameplate2", idleView, false)
        local activeBeforeStop = runtime.activeCasts.nameplate1
        runtime:SetCastActive("nameplate1", castingView, false)

        -- Then
        ExpectEqual(activeBeforeStop, castingView)
        ExpectEqual(runtime.activeCasts.nameplate1, nil)
        ExpectEqual(runtime.activeCasts.nameplate2, nil)
    end)

    It("runs the update driver only while nameplates are active", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local assignedHandler = false
        local updateHandler = function()
        end
        runtime.frame = {
            SetScript = function(_, scriptName, handler)
                if scriptName == "OnUpdate" then
                    assignedHandler = handler
                end
            end,
        }
        runtime.onUpdateHandler = updateHandler

        -- When
        runtime.activePlates = {}
        runtime:RefreshUpdateDriver()
        local handlerWithoutPlates = assignedHandler
        runtime.lightweightPlates.nameplate2 = {}
        runtime:RefreshUpdateDriver()
        local handlerWithLightweightPlate = assignedHandler
        runtime.lightweightPlates = {}
        runtime.activePlates.nameplate1 = {}
        runtime:RefreshUpdateDriver()

        -- Then
        ExpectEqual(handlerWithoutPlates, nil)
        ExpectEqual(handlerWithLightweightPlate, updateHandler)
        ExpectEqual(assignedHandler, updateHandler)
    end)

    It("does not expose dungeon completion cleanup", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)

        -- When
        local cleanupHandler = runtime.HandleDungeonCleanupEvent

        -- Then
        ExpectEqual(cleanupHandler, nil)
    end)

    It("runs maintenance only after its refresh interval", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)

        -- When
        local early, accumulated = runtime:AdvanceRefreshClock(
            0,
            0.02,
            0.05
        )
        local ready, remainder = runtime:AdvanceRefreshClock(
            accumulated,
            0.03,
            0.05
        )

        -- Then
        ExpectEqual(early, false)
        ExpectEqual(accumulated, 0.02)
        ExpectEqual(ready, true)
        ExpectEqual(remainder, 0)
    end)

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
