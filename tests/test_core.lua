Describe("Core lifecycle", function()
    It("starts the runtime without checking zone or difficulty", function()
        -- Given
        local namespace = {}
        local enableCount = 0
        local core = LoadAddonFile("Core.lua", namespace)
        core:SetRuntime({
            Enable = function()
                enableCount = enableCount + 1
            end,
            Disable = function()
            end,
        })

        -- When
        core:Start()
        core:Start()

        -- Then
        ExpectEqual(core:IsEnabled(), true)
        ExpectEqual(enableCount, 1)
    end)

    It("changes runtime state only when the requested state changes", function()
        -- Given
        local namespace = {}
        local enabledCount = 0
        local disabledCount = 0
        local core = LoadAddonFile("Core.lua", namespace)
        core:SetRuntime({
            Enable = function()
                enabledCount = enabledCount + 1
            end,
            Disable = function()
                disabledCount = disabledCount + 1
            end,
        })

        -- When
        core:Refresh(false)
        core:Refresh(true)
        core:Refresh(true)
        core:Refresh(false)

        -- Then
        ExpectEqual(enabledCount, 1)
        ExpectEqual(disabledCount, 1)
        ExpectEqual(core:IsEnabled(), false)
    end)

end)
