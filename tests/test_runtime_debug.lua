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
end)
