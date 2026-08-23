Describe("Secret-safe cast durations", function()
    It("passes the casting duration object through without inspecting it", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local duration = {}

        -- When
        local result = castDuration:GetUnitDuration(
            "nameplate1",
            false,
            function()
                return duration
            end,
            function()
                return nil
            end
        )

        -- Then
        ExpectEqual(result, duration)
    end)

    It("uses the channel duration object for channeled spells", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local duration = {}

        -- When
        local result = castDuration:GetUnitDuration(
            "nameplate1",
            true,
            function()
                return nil
            end,
            function()
                return duration
            end
        )

        -- Then
        ExpectEqual(result, duration)
    end)

    It("uses remaining duration so every cast drains from full", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local duration = {
            GetRemainingDuration = function()
                return 2.5
            end,
        }

        -- When
        local progress = castDuration:GetProgress(duration)

        -- Then
        ExpectEqual(progress, 2.5)
    end)

    It("binds status bars to the requested timer direction", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local duration = {}
        local receivedDuration
        local receivedInterpolation
        local receivedDirection
        local statusBar = {
            SetTimerDuration = function(
                _,
                value,
                interpolation,
                direction
            )
                receivedDuration = value
                receivedInterpolation = interpolation
                receivedDirection = direction
            end,
        }

        -- When
        castDuration:BindRemainingTime(
            statusBar,
            duration,
            0,
            1
        )

        -- Then
        ExpectEqual(receivedDuration, duration)
        ExpectEqual(receivedInterpolation, 0)
        ExpectEqual(receivedDirection, 1)
    end)

    It("selects elapsed time so casts fill from left to right", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local timerDirections = {
            ElapsedTime = 0,
            RemainingTime = 1,
        }

        -- When
        local direction = castDuration:GetTimerDirection(timerDirections)

        -- Then
        ExpectEqual(direction, timerDirections.ElapsedTime)
    end)

    It("lays out the cooldown timeline from left to right", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)

        -- When
        local layout = castDuration:GetCooldownOverlayLayout()

        -- Then
        ExpectEqual(layout.reverseFill, false)
        ExpectEqual(layout.markerAnchor, "CENTER")
        ExpectEqual(layout.markerPoint, "RIGHT")
    end)

    It("snapshots the kick-ready marker position", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)
        local minimum
        local maximum
        local markerValue
        local markerTrack = {
            SetMinMaxValues = function(_, receivedMinimum, receivedMaximum)
                minimum = receivedMinimum
                maximum = receivedMaximum
            end,
            SetValue = function(_, receivedValue)
                markerValue = receivedValue
            end,
        }
        local cooldown = {
            GetRemainingDuration = function()
                return 2
            end,
        }

        -- When
        castDuration:PlaceCooldownMarker(
            markerTrack,
            5,
            cooldown
        )

        -- Then
        ExpectEqual(minimum, 0)
        ExpectEqual(maximum, 5)
        ExpectEqual(markerValue, 2)
    end)

    It("places kick markers only when a cast starts", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)

        -- When
        local atCastStart = castDuration:ShouldPlaceCooldownMarker(
            "UNIT_SPELLCAST_START"
        )
        local duringCooldownRefresh =
            castDuration:ShouldPlaceCooldownMarker(
                "SPELL_UPDATE_COOLDOWN"
            )

        -- Then
        ExpectEqual(atCastStart, true)
        ExpectEqual(duringCooldownRefresh, false)
    end)
end)

Describe("Cast time formatting", function()
    It("uses a numeric-only tenths formatter", function()
        -- Given
        local namespace = {}
        local castDuration = LoadAddonFile("CastDuration.lua", namespace)

        -- When
        local breakpoint = castDuration:GetTimeBreakpoint()

        -- Then
        ExpectEqual(breakpoint.threshold, 0)
        ExpectEqual(breakpoint.step, 0.1)
        ExpectEqual(breakpoint.format, "%.1f")
    end)
end)
