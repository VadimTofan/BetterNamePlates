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
end)
