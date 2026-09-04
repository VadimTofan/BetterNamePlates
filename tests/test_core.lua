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

    It("persists dimension commands and resizes active plates", function()
        -- Given
        local resizeCount = 0
        local namespace = {
            Config = {healthWidth = 135, healthHeight = 13.6},
            PlateDimensions = LoadAddonFile("PlateDimensions.lua", {}),
        }
        local core = LoadAddonFile("Core.lua", namespace)
        local saved = {}

        core:SetRuntime({
            ApplyDimensions = function()
                resizeCount = resizeCount + 1
            end,
        })
        core:SetDatabase(saved)
        core:InitializeDimensions()

        -- When
        local result = core:HandleDimensionCommand("width 150")

        -- Then
        ExpectEqual(result.changed, true)
        ExpectEqual(saved.width, 150)
        ExpectEqual(namespace.Config.healthWidth, 150)
        ExpectEqual(resizeCount, 1)
    end)

    It("persists name size commands and refreshes active plates", function()
        -- Given
        local resizeCount = 0
        local namespace = {
            Config = {
                healthWidth = 135,
                healthHeight = 13.6,
                nameFontSize = 10,
            },
            PlateDimensions = LoadAddonFile("PlateDimensions.lua", {}),
        }
        local core = LoadAddonFile("Core.lua", namespace)
        local saved = {}

        core:SetRuntime({
            ApplyDimensions = function()
                resizeCount = resizeCount + 1
            end,
        })
        core:SetDatabase(saved)
        core:InitializeDimensions()

        -- When
        local result = core:HandleDimensionCommand("name 8")

        -- Then
        ExpectEqual(result.changed, true)
        ExpectEqual(saved.name, 8)
        ExpectEqual(namespace.Config.nameFontSize, 13)
        ExpectEqual(resizeCount, 1)
    end)

    It("persists target style changes and refreshes active plates", function()
        -- Given
        local refreshCount = 0
        local namespace = {
            Config = {},
            PlateDimensions = {},
            TargetIndicator = LoadAddonFile("TargetIndicator.lua", {}),
        }
        local core = LoadAddonFile("Core.lua", namespace)
        local saved = {}

        core:SetRuntime({
            UpdateSelectionIndicators = function()
                refreshCount = refreshCount + 1
            end,
        })
        core:SetDatabase(saved)
        core:InitializeTargetStyle()

        -- When
        local firstStyle = core:HandleTargetStyleCommand()
        local secondStyle = core:HandleTargetStyleCommand()

        -- Then
        ExpectEqual(firstStyle, "scratched")
        ExpectEqual(secondStyle, "arrows")
        ExpectEqual(saved.targetStyle, "arrows")
        ExpectEqual(namespace.Config.targetStyle, "arrows")
        ExpectEqual(refreshCount, 2)
    end)

end)
