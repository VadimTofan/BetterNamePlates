Describe("Nameplate stacking", function()
    It("uses generous vertical row separation", function()
        -- Given
        local namespace = {}
        local stacking = LoadAddonFile("NameplateStacking.lua", namespace)

        -- When
        local settings = stacking:GetSettings()

        -- Then
        ExpectEqual(settings.nameplateOverlapH, "2.0")
        ExpectEqual(settings.nameplateOverlapV, "1.6")
    end)

    It("registers the custom view as the stacking boundary", function()
        -- Given
        local namespace = {}
        local stacking = LoadAddonFile("NameplateStacking.lua", namespace)
        local receivedBounds
        local basePlate = {
            SetStackingBoundsFrame = function(_, bounds)
                receivedBounds = bounds
            end,
        }
        local customView = {}

        -- When
        local wasApplied = stacking:ApplyBounds(basePlate, customView)

        -- Then
        ExpectEqual(wasApplied, true)
        ExpectEqual(receivedBounds, customView)
    end)

    It("defers protected CVar changes during combat", function()
        -- Given
        local namespace = {}
        local stacking = LoadAddonFile("NameplateStacking.lua", namespace)
        local appliedCount = 0

        -- When
        local applied = stacking:Apply(
            function()
                appliedCount = appliedCount + 1
            end,
            true
        )

        -- Then
        ExpectEqual(applied, false)
        ExpectEqual(appliedCount, 0)
    end)

    It("applies every stacking CVar outside combat", function()
        -- Given
        local namespace = {}
        local stacking = LoadAddonFile("NameplateStacking.lua", namespace)
        local applied = {}

        -- When
        local wasApplied = stacking:Apply(
            function(name, value)
                applied[name] = value
            end,
            false
        )

        -- Then
        ExpectEqual(wasApplied, true)
        ExpectEqual(applied.nameplateOverlapH, "2.0")
        ExpectEqual(applied.nameplateOverlapV, "1.6")
    end)

    It("reports the live stacking state for diagnostics", function()
        -- Given
        local namespace = {}
        local stacking = LoadAddonFile("NameplateStacking.lua", namespace)
        local values = {
            nameplateOverlapH = "2.0",
            nameplateOverlapV = "1.6",
        }

        -- When
        local state = stacking:GetDebugState(
            function(name)
                return values[name]
            end
        )

        -- Then
        ExpectEqual(state.overlapH, "2.0")
        ExpectEqual(state.overlapV, "1.6")
    end)
end)
