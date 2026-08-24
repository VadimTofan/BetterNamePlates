Describe("Runtime diagnostics", function()
    It("resizes only the targeted health section", function()
        -- Given
        local healthSectionHeight
        local healthFillHeight
        local absorbHeight
        local markerHeight
        local leftArrowHeight
        local rightArrowHeight
        local castResizeCount = 0
        local iconResizeCount = 0
        local namespace = {
            Config = {
                absorbInset = 1,
                castHeight = 11.2,
                contentPadding = 3,
                healthHeight = 17,
                healthInset = 1,
                targetHealthScale = 1.25,
            },
            CombatState = {},
            FrameLayout = LoadAddonFile("FrameLayout.lua", {}),
            Rules = {},
            TargetIndicator = LoadAddonFile("TargetIndicator.lua", {}),
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local view = {
            SetHeight = function()
            end,
            emptyBar = {
                SetHeight = function(_, height)
                    healthSectionHeight = height
                end,
            },
            health = {
                SetHeight = function(_, height)
                    healthFillHeight = height
                end,
            },
            absorbBar = {
                SetHeight = function(_, height)
                    absorbHeight = height
                end,
            },
            healthForeground = {
                SetHeight = function()
                end,
            },
            healthMarker = {
                SetHeight = function(_, height)
                    markerHeight = height
                end,
            },
            name = {
                SetHeight = function()
                end,
            },
            healthText = {
                SetHeight = function()
                end,
            },
            healthPercentage = {
                SetHeight = function()
                end,
            },
            targetIndicator = {
                leftArrow = {
                    SetHeight = function(_, height)
                        leftArrowHeight = height
                    end,
                },
                rightArrow = {
                    SetHeight = function(_, height)
                        rightArrowHeight = height
                    end,
                },
            },
            cast = {
                SetHeight = function()
                    castResizeCount = castResizeCount + 1
                end,
            },
            castIconFrame = {
                SetHeight = function()
                    iconResizeCount = iconResizeCount + 1
                end,
            },
        }

        -- When
        runtime:ApplyTargetHealthHeight(view, true)

        -- Then
        ExpectEqual(healthSectionHeight, 21.25)
        ExpectEqual(healthFillHeight, 19.25)
        ExpectEqual(absorbHeight, 19.25)
        ExpectEqual(markerHeight, 19.25)
        ExpectEqual(leftArrowHeight, 21.25)
        ExpectEqual(rightArrowHeight, 21.25)
        ExpectEqual(castResizeCount, 0)
        ExpectEqual(iconResizeCount, 0)
    end)

    It("updates nameplate healthbars directly", function()
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

    It("updates a single HP text layer", function()
        -- Given
        local primaryText
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local primary = {
            SetText = function(_, text)
                primaryText = text
            end,
        }
        -- When
        runtime:SetHealthText(primary, "6.5M")

        -- Then
        ExpectEqual(primaryText, "6.5M")
    end)

    It("passes calculated absorb values directly to the absorb bar", function()
        -- Given
        local previousPrediction = UnitGetDetailedHealPrediction
        local populatedUnit
        local maximum = {}
        local absorbs = {}
        local receivedMinimum
        local receivedMaximum
        local receivedValue
        local receivedInterpolation
        local interpolation = {}
        local calculator = {
            GetMaximumHealth = function()
                return maximum
            end,
            GetDamageAbsorbs = function()
                return absorbs
            end,
        }
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local view = {
            absorbCalculator = calculator,
            absorbInterpolation = interpolation,
            absorbBar = {
                SetMinMaxValues = function(_, minimumValue, maximumValue)
                    receivedMinimum = minimumValue
                    receivedMaximum = maximumValue
                end,
                SetValue = function(_, value, interpolationMode)
                    receivedValue = value
                    receivedInterpolation = interpolationMode
                end,
            },
        }
        UnitGetDetailedHealPrediction = function(unit, _, receivedCalculator)
            populatedUnit = unit
            ExpectEqual(receivedCalculator, calculator)
        end

        -- When
        runtime:UpdateAbsorbValues("nameplate1", view)
        UnitGetDetailedHealPrediction = previousPrediction

        -- Then
        ExpectEqual(populatedUnit, "nameplate1")
        ExpectEqual(receivedMinimum, 0)
        ExpectEqual(receivedMaximum, maximum)
        ExpectEqual(receivedValue, absorbs)
        ExpectEqual(receivedInterpolation, interpolation)
    end)

    It("refreshes health when an absorb amount changes", function()
        -- Given
        local namespace = {
            Config = {},
            CombatState = {},
            FrameLayout = {},
            Interrupts = {
                IsPlayerInterruptCast = function()
                    return false
                end,
                IsCooldownEvent = function()
                    return false
                end,
            },
            NameplateStacking = {
                ShouldApplyOnEvent = function()
                    return false
                end,
            },
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)
        local refreshedUnit

        runtime.UpdateHealth = function(_, unit)
            refreshedUnit = unit
        end

        -- When
        runtime:OnEvent("UNIT_ABSORB_AMOUNT_CHANGED", "nameplate2")

        -- Then
        ExpectEqual(refreshedUnit, "nameplate2")
    end)

    It("forces the targeted absorb bar full for diagnostics", function()
        -- Given
        local previousUnitIsUnit = UnitIsUnit
        local minimum
        local maximum
        local value
        local namespace = {
            Config = {},
            CombatState = {},
            DisplayText = {
                SafeValue = function(value)
                    return value
                end,
            },
            FrameLayout = {},
            Rules = {},
        }
        local runtime = LoadAddonFile("Runtime.lua", namespace)

        runtime.activePlates.nameplate1 = {
            absorbBar = {
                SetMinMaxValues = function(_, receivedMinimum, receivedMaximum)
                    minimum = receivedMinimum
                    maximum = receivedMaximum
                end,
                SetValue = function(_, receivedValue)
                    value = receivedValue
                end,
            },
        }
        UnitIsUnit = function(unit, target)
            return unit == "nameplate1" and target == "target"
        end

        -- When
        local found = runtime:DebugForceTargetAbsorb()
        UnitIsUnit = previousUnitIsUnit

        -- Then
        ExpectEqual(found, true)
        ExpectEqual(minimum, 0)
        ExpectEqual(maximum, 1)
        ExpectEqual(value, 1)
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
        runtime.activePlates.nameplate1 = {}
        runtime:RefreshUpdateDriver()

        -- Then
        ExpectEqual(handlerWithoutPlates, nil)
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
